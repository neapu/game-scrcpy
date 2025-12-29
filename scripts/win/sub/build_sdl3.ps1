# Save current location
$originalLocation = Get-Location

# Configuration
if ($env:SDL_GIT_REPO) {
    $sdlRepoUrl = $env:SDL_GIT_REPO
} else {
    $sdlRepoUrl = "https://github.com/libsdl-org/SDL.git"
}
$sdlVersion = "release-3.2.28"

# Check requirements
$requiredTools = @{
    "git" = "https://git-scm.com/downloads"
    "cmake" = "https://cmake.org/download/"
}

foreach ($tool in $requiredTools.Keys) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "Error: '$tool' is required but not found." -ForegroundColor Red
        Write-Host "Please install it from: $($requiredTools[$tool])"
        exit 1
    }
}

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path "$scriptDir\..\..\..").Path
$tempDir = "$rootDir\temp"
$sdlSourceDir = "$tempDir\sdl3"
$buildDir = "$sdlSourceDir\build"
$installDir = "$rootDir\core\third_party\sdl3"

# Check if SDL3 is already installed
if (Test-Path "$installDir\lib\SDL3-static.lib") {
    Write-Host "SDL3 is already installed in $installDir. Skipping build." -ForegroundColor Green
    exit 0
}

# Ensure temp directory exists
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Clone SDL3 if not exists
if (-not (Test-Path $sdlSourceDir)) {
    Write-Host "Cloning SDL3 from $sdlRepoUrl ..." -ForegroundColor Cyan
    git clone $sdlRepoUrl $sdlSourceDir
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# Checkout version
Set-Location $sdlSourceDir
Write-Host "Checking out version $sdlVersion..." -ForegroundColor Cyan
git checkout $sdlVersion
if ($LASTEXITCODE -ne 0) { exit 1 }

# Create build directory
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Configure CMake
Set-Location $buildDir
Write-Host "Configuring SDL3 with CMake..." -ForegroundColor Cyan
# Using Visual Studio generator to avoid setting up MSVC environment manually
$cmakeArgs = @(
    "-G", "Visual Studio 18 2026",
    "-A", "x64",
    "-DCMAKE_INSTALL_PREFIX=$installDir",
    "-DSDL_STATIC=ON",
    "-DSDL_SHARED=OFF",
    "-DSDL_TEST_LIBRARY=OFF",
    "-DSDL_DISABLE_INSTALL_DOCS=ON"
)

cmake .. @cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed." -ForegroundColor Red
    exit 1
}

# Build and Install
Write-Host "Building and Installing SDL3..." -ForegroundColor Cyan
cmake --build . --config Release --target install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build/Install failed." -ForegroundColor Red
    exit 1
}

# Change directory out of build dir so we can delete it
Set-Location $originalLocation

# Cleanup temp files
Write-Host "Cleaning up temp files..." -ForegroundColor Cyan
if (Test-Path $sdlSourceDir) {
    Remove-Item -Path $sdlSourceDir -Recurse -Force
}

Write-Host "SDL3 build completed successfully." -ForegroundColor Green
