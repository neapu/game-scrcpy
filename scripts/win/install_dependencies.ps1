$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$subDir = "$scriptDir\sub"

Write-Host "Starting dependencies installation..." -ForegroundColor Cyan

# List of build scripts to run
$buildScripts = @(
    "build_ffmpeg.ps1",
    "build_sdl3.ps1"
)

foreach ($script in $buildScripts) {
    $scriptPath = "$subDir\$script"
    
    if (Test-Path $scriptPath) {
        Write-Host "`nRunning $script..." -ForegroundColor Cyan
        & $scriptPath
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: $script failed with exit code $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "Warning: Script $script not found at $scriptPath" -ForegroundColor Yellow
    }
}

Write-Host "`nAll dependencies installed successfully!" -ForegroundColor Green
