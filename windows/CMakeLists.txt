# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(plezy LANGUAGES CXX)

# Download and extract mpv-dev (architecture-specific)
include(FetchContent)

# Detect target architecture
if(CMAKE_GENERATOR_PLATFORM)
  set(TARGET_ARCH "${CMAKE_GENERATOR_PLATFORM}")
elseif(CMAKE_VS_PLATFORM_NAME)
  set(TARGET_ARCH "${CMAKE_VS_PLATFORM_NAME}")
else()
  set(TARGET_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
endif()

message(STATUS "Detected target architecture: ${TARGET_ARCH}")

# Select MPV build based on architecture
if(TARGET_ARCH MATCHES "ARM64" OR TARGET_ARCH MATCHES "arm64" OR TARGET_ARCH MATCHES "aarch64")
  message(STATUS "Using ARM64 MPV build")
  
  # CMake's built-in extractor cannot handle the .7z codec used by this archive.
  # We use 7-Zip for extraction instead.
  set(MPV_ARM64_URL "https://github.com/minnyres/mpv-windows-arm64/releases/download/v0.40.0/mpv_0.40.0_arm64.7z")
  set(MPV_ARM64_ARCHIVE "${CMAKE_BINARY_DIR}/_deps/mpv_0.40.0_arm64.7z")
  set(MPV_ARM64_EXTRACT_DIR "${CMAKE_BINARY_DIR}/_deps/mpv_dev-src")
  
  # Download if archive doesn't exist
  if(NOT EXISTS "${MPV_ARM64_ARCHIVE}")
    message(STATUS "Downloading ARM64 MPV from ${MPV_ARM64_URL}")
    file(DOWNLOAD "${MPV_ARM64_URL}" "${MPV_ARM64_ARCHIVE}" SHOW_PROGRESS STATUS download_status)
    list(GET download_status 0 status_code)
    if(NOT status_code EQUAL 0)
      message(FATAL_ERROR "Failed to download MPV ARM64: ${download_status}")
    endif()
  endif()
  
  # Extract if not already extracted
  if(NOT EXISTS "${MPV_ARM64_EXTRACT_DIR}/mpv/include/mpv/client.h")
    message(STATUS "Extracting ARM64 MPV using 7-Zip")
    file(MAKE_DIRECTORY "${MPV_ARM64_EXTRACT_DIR}")
    # Convert to native path and build the -o argument (7z requires -oPath with no space)
    file(TO_NATIVE_PATH "${MPV_ARM64_EXTRACT_DIR}" MPV_NATIVE_EXTRACT_DIR)
    execute_process(
      COMMAND "C:/Program Files/7-Zip/7z.exe" x "${MPV_ARM64_ARCHIVE}" "-o${MPV_NATIVE_EXTRACT_DIR}" -y
      RESULT_VARIABLE extract_result
      OUTPUT_QUIET
    )
    if(NOT extract_result EQUAL 0)
      message(FATAL_ERROR "Failed to extract MPV ARM64 archive with 7-Zip (exit code: ${extract_result})")
    endif()
  endif()
  
  set(MPV_INCLUDE_DIR "${MPV_ARM64_EXTRACT_DIR}/mpv/include")
  set(MPV_LIB_DIR "${MPV_ARM64_EXTRACT_DIR}/mpv/lib")
  set(MPV_DLL_DIR "${MPV_ARM64_EXTRACT_DIR}/mpv/bin")
else()
  message(STATUS "Using x64 MPV build")
  FetchContent_Declare(
    mpv_dev
    URL https://github.com/shinchiro/mpv-winbuild-cmake/releases/download/20260120/mpv-dev-x86_64-v3-20260120-git-b7e8fe9.7z
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  )
  FetchContent_MakeAvailable(mpv_dev)
  set(MPV_INCLUDE_DIR "${mpv_dev_SOURCE_DIR}/include")
  set(MPV_LIB_DIR "${mpv_dev_SOURCE_DIR}")
  set(MPV_DLL_DIR "${mpv_dev_SOURCE_DIR}")
endif()

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "plezy")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
if(EXISTS "${NATIVE_ASSETS_DIR}")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
     DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
     COMPONENT Runtime)
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

# Install mpv DLL
install(FILES "${MPV_DLL_DIR}/libmpv-2.dll"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)
