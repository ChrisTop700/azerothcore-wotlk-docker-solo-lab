# ==================================================================
# AzerothCore WotLK (3.3.5a) Solo Lab - Web Portal & Armory Startup
# ==================================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   AzerothCore Solo Lab - Web Portal & Armory Startup" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Ensure Docker is running
$dockerRunning = $false
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    Write-Host "Docker Desktop is not running. Please start the main server first or launch Docker Desktop." -ForegroundColor Red
    exit 1
}

# 2. Launch Web & Armory Containers via WSL
Write-Host "Starting Web Portal (BlizzCMS) and Armory containers..." -ForegroundColor Cyan
wsl -d Ubuntu bash -c "cd ~/azerothcore-wotlk && docker compose --profile web up -d ac-web-portal ac-armory"

Write-Host "`nWeb Containers Status:" -ForegroundColor Green
docker ps --filter "name=ac-web" --filter "name=ac-armory" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   Web Services are Online!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " * BlizzCMS Registration Portal:  http://localhost:8080" -ForegroundColor Yellow
Write-Host " * AzerothCore 3D Armory:         http://localhost:48733" -ForegroundColor Yellow
Write-Host "`n"
