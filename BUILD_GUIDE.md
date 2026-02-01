# Build Guide - Creating Windows Installers

This guide covers how to build complete Windows installers (both x64 and ARM64) for Plezy.

## Table of Contents
- [Option 1: GitHub Actions (Recommended)](#option-1-github-actions-recommended)
- [Option 2: Local Build](#option-2-local-build)
- [Build Outputs](#build-outputs)

---

## Option 1: GitHub Actions (Recommended)

### Prerequisites
- Push access to the GitHub repository
- GitHub Actions enabled on the repository

### Steps

1. **Commit and push your changes**
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main
   ```

2. **Trigger the workflow**
   - Go to: https://github.com/edde746/plezy/actions
   - Click on "Full Build (with ARM64)" workflow (or "Build" for the existing workflow)
   - Click "Run workflow" button
   - Choose which architectures to build (x64, ARM64, or both)
   - Click "Run workflow"

3. **Download artifacts**
   - Wait for the workflow to complete (usually 10-20 minutes)
   - Scroll to the bottom of the workflow run page
   - Download the artifacts:
     - `windows-x64-portable` - Portable 7z archive for x64
     - `windows-x64-installer` - Installer exe for x64
     - `windows-arm64-portable` - Portable 7z archive for ARM64
     - `windows-arm64-installer` - Installer exe for ARM64

### Advantages
- ✅ No local dependencies required
- ✅ Consistent build environment
- ✅ Build attestation/provenance
- ✅ Cross-compile ARM64 on x64 runners
- ✅ Cached dependencies for faster builds

---

## Option 2: Local Build

### Prerequisites
Install the following tools:
- **Flutter SDK** - Already installed ✓
- **7-Zip** - [Download](https://www.7-zip.org/) or `choco install 7zip`
- **Inno Setup 6** - [Download](https://jrsoftware.org/isdl.php) or `choco install innosetup`

### For x64 Build

1. **Build the Flutter app**
   ```powershell
   flutter build windows --release --dart-define=ENABLE_UPDATE_CHECK=true
   ```

2. **Create installer packages**
   ```powershell
   .\windows\build-installer.ps1 -Architecture x64
   ```

3. **Find your build outputs** in the project root:
   - `plezy-windows-portable.7z` - Portable archive
   - `plezy-windows-installer.exe` - Installer

### For ARM64 Build

> **Note:** ARM64 builds can be cross-compiled on x64 Windows

1. **Build the Flutter app for ARM64**
   ```powershell
   flutter build windows --release --target-platform windows-arm64 --dart-define=ENABLE_UPDATE_CHECK=true
   ```

2. **Create installer packages**
   ```powershell
   .\windows\build-installer.ps1 -Architecture arm64
   ```

3. **Find your build outputs** in the project root:
   - `plezy-windows-arm64-portable.7z` - Portable archive
   - `plezy-windows-arm64-installer.exe` - Installer

### Troubleshooting Local Builds

#### 7-Zip not found
```powershell
choco install 7zip -y
```

#### Inno Setup not found
```powershell
choco install innosetup -y
```

#### Build directory not found
Make sure you run `flutter build windows` before running the installer script.

---

## Build Outputs

### Portable Archives (.7z)
- Contains all files needed to run Plezy
- Extract and run `plezy.exe`
- No installation required
- Highly compressed using 7-Zip

### Installers (.exe)
- Built with Inno Setup
- Provides:
  - Start Menu shortcuts
  - Optional desktop icon
  - Uninstaller
  - Windows integration
- Architecture-specific (x64 or ARM64)

### File Naming Convention
- `plezy-windows-portable.7z` - x64 portable
- `plezy-windows-installer.exe` - x64 installer
- `plezy-windows-arm64-portable.7z` - ARM64 portable
- `plezy-windows-arm64-installer.exe` - ARM64 installer

---

## Architecture Notes

### x64 (x86_64)
- Standard Windows architecture
- Compatible with most Windows PCs
- Runs on both Intel and AMD processors

### ARM64
- For Windows on ARM devices (e.g., Snapdragon laptops)
- Native performance on ARM64 devices
- Can be cross-compiled from x64 systems
- Uses `windows-arm64` target platform in Flutter

---

## Version Management

The version is defined in `pubspec.yaml`:
```yaml
version: 1.15.3+35
```

- **1.15.3** - Semantic version (MAJOR.MINOR.PATCH)
- **35** - Build number

Update this before creating releases.

---

## Additional Resources

- [Flutter Windows Desktop](https://docs.flutter.dev/platform-integration/windows/building)
- [Inno Setup Documentation](https://jrsoftware.org/isinfo.php)
- [7-Zip Documentation](https://www.7-zip.org/faq.html)
