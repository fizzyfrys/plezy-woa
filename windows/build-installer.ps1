#!/usr/bin/env pwsh
# Windows Installer Build Script
# This script creates both a portable archive and an installer for the Windows build

param(
    [string]$OutputDir = ".",
    [string]$Version = "1.0.0",
    [ValidateSet("x64", "arm64")]
    [string]$Architecture = "x64"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Windows installer packages for $Architecture..." -ForegroundColor Cyan

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Define paths based on architecture
$BuildDir = "build\windows\$Architecture\runner\Release"
$ArchSuffix = if ($Architecture -eq "arm64") { "-arm64" } else { "" }
$PortableZip = Join-Path (Resolve-Path $OutputDir) "plezy-windows$ArchSuffix-portable.7z"
$InstallerExe = Join-Path (Resolve-Path $OutputDir) "plezy-windows$ArchSuffix-installer.exe"
$SetupScript = "setup$ArchSuffix.iss"

# Check if build exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found at $BuildDir. Please run 'flutter build windows --release' first."
    exit 1
}

Write-Host "Found build at: $BuildDir" -ForegroundColor Green

# Check for 7-Zip
Write-Host "`nChecking for 7-Zip..." -ForegroundColor Cyan
$7zPath = $null

# Check standard install locations first
$7zLocations = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    (Get-Command 7z -ErrorAction SilentlyContinue).Source
)

foreach ($loc in $7zLocations) {
    if ($loc -and (Test-Path $loc)) {
        $7zPath = $loc
        Write-Host "Found 7-Zip at: $7zPath" -ForegroundColor Green
        break
    }
}

if (-not $7zPath) {
    Write-Host "7-Zip not found. Installing via Chocolatey..." -ForegroundColor Yellow

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey is not installed. Please install 7-Zip manually from https://www.7-zip.org/"
        exit 1
    }

    choco install 7zip -y
    refreshenv
    
    # Check again after install
    if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
        $7zPath = "C:\Program Files\7-Zip\7z.exe"
    }
    else {
        Write-Error "Failed to install 7-Zip"
        exit 1
    }
}

# Create Portable Archive
Write-Host "`nCreating portable archive..." -ForegroundColor Cyan
Push-Location $BuildDir
try {
    if (Test-Path $PortableZip) {
        Remove-Item $PortableZip -Force
    }
    & $7zPath a -mx=9 $PortableZip *
    Write-Host "Created: $PortableZip" -ForegroundColor Green
}
finally {
    Pop-Location
}

# Create Inno Setup Script
Write-Host "`nGenerating Inno Setup script..." -ForegroundColor Cyan

# Set architecture-specific Inno Setup values
$InnoArch = if ($Architecture -eq "arm64") { "arm64" } else { "x64" }
$InnoOutputFilename = "plezy-windows$ArchSuffix-installer"

@"
#define Name "Plezy"
#define Version "$Version"
#define Publisher "edde746"
#define ExeName "plezy.exe"

[Setup]
AppId={{4213385e-f7be-4f2b-95f9-54082a28bb8f}
AppName={#Name}
AppVersion={#Version}
AppPublisher={#Publisher}
DefaultDirName={autopf}\{#Name}
DefaultGroupName={#Name}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=$InnoOutputFilename
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=$InnoArch
ArchitecturesInstallIn64BitMode=$InnoArch

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\$Architecture\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#Name}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:UninstallProgram,{#Name}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#Name}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#Name}}"; Flags: nowait postinstall skipifsilent
"@ | Out-File -FilePath $SetupScript -Encoding ASCII

Write-Host "Created: $SetupScript" -ForegroundColor Green

# Check for Inno Setup
Write-Host "`nChecking for Inno Setup..." -ForegroundColor Cyan
$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "Inno Setup not found. Installing via Chocolatey..." -ForegroundColor Yellow

    # Check if choco is available
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey is not installed. Please install it from https://chocolatey.org/install"
        exit 1
    }

    choco install innosetup -y

    if (-not (Test-Path $InnoSetupPath)) {
        Write-Error "Failed to install Inno Setup"
        exit 1
    }
}

# Build Installer
Write-Host "`nBuilding installer with Inno Setup..." -ForegroundColor Cyan
& $InnoSetupPath $SetupScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed"
    exit 1
}

Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "Portable archive: $PortableZip" -ForegroundColor White
Write-Host "Installer: $InstallerExe" -ForegroundColor White
