# Save current location
$originalLocation = Get-Location

# Configuration
$ffmpegDownloadUrl = "https://github.com/GyanD/codexffmpeg/releases/download/7.1.1/ffmpeg-7.1.1-full_build-shared.zip"

# Check requirements
$requiredTools = @{
    "7z" = "https://www.7-zip.org/download.html"
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
$downloadPath = "$tempDir\ffmpeg-7.1.1-full_build-shared.zip"
$extractDir = "$tempDir\ffmpeg_extracted"
$installDir = "$rootDir\core\third_party\ffmpeg"

# Check if FFmpeg is already installed
if (Test-Path "$installDir\bin\avcodec-*.dll") {
    Write-Host "FFmpeg is already installed in $installDir. Skipping installation." -ForegroundColor Green
    exit 0
}

# Ensure temp directory exists
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Download FFmpeg
if (-not (Test-Path $downloadPath)) {
    Write-Host "Downloading FFmpeg from $ffmpegDownloadUrl ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $ffmpegDownloadUrl -OutFile $downloadPath
}

# Extract FFmpeg
if (-not (Test-Path $extractDir)) {
    Write-Host "Extracting FFmpeg..." -ForegroundColor Cyan
    $7zPath = (Get-Command "7z" -ErrorAction SilentlyContinue).Source
    if (-not $7zPath) {
        # Try common paths
        $commonPaths = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        )
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $7zPath = $path
                break
            }
        }
    }
    
    if (-not $7zPath) {
        Write-Host "Error: 7z not found. Please install 7-Zip." -ForegroundColor Red
        exit 1
    }

    & "$7zPath" x "$downloadPath" "-o$extractDir" -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Extraction failed." -ForegroundColor Red
        exit 1
    }
}

# Install (Copy) files
Write-Host "Installing FFmpeg to $installDir ..." -ForegroundColor Cyan

# Ensure install directory exists and is clean
if (Test-Path $installDir) {
    Remove-Item -Path $installDir -Recurse -Force
}
New-Item -ItemType Directory -Path $installDir | Out-Null
New-Item -ItemType Directory -Path "$installDir\bin" | Out-Null
New-Item -ItemType Directory -Path "$installDir\include" | Out-Null
New-Item -ItemType Directory -Path "$installDir\lib" | Out-Null

# Find the inner directory (e.g. ffmpeg-7.1-full_build-shared)
$innerDir = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
if (-not $innerDir) {
    Write-Host "Error: Could not find extracted directory." -ForegroundColor Red
    exit 1
}

# Copy files
Copy-Item -Path "$($innerDir.FullName)\bin\*" -Destination "$installDir\bin" -Recurse
Copy-Item -Path "$($innerDir.FullName)\include\*" -Destination "$installDir\include" -Recurse
Copy-Item -Path "$($innerDir.FullName)\lib\*" -Destination "$installDir\lib" -Recurse

# Cleanup temp files
Write-Host "Cleaning up temp files..." -ForegroundColor Cyan
Set-Location $originalLocation
if (Test-Path $downloadPath) {
    Remove-Item -Path $downloadPath -Force
}
if (Test-Path $extractDir) {
    Remove-Item -Path $extractDir -Recurse -Force
}

Write-Host "FFmpeg installation completed successfully." -ForegroundColor Green
