# ==================================================================
# AzerothCore WotLK (3.3.5a) Solo Lab - Server Shutdown & Cleanup
# ==================================================================

$ErrorActionPreference = "Continue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   AzerothCore Solo Lab - Shutting Down All Services" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Stop all Docker containers (Core Game Server + Web Portal + Armory)
Write-Host "[1/2] Stopping all AzerothCore & Web containers (Game + Web + Armory + DB)..." -ForegroundColor Cyan
try {
    wsl -d Ubuntu bash -c "cd ~/azerothcore-wotlk && docker compose --profile web stop"
} catch {
    Write-Warning "WSL docker compose stop command returned an issue: $_"
}

# Safety net: ensure any lingering ac-* containers are cleanly stopped
try {
    $lingering = docker ps -q --filter "name=ac-"
    if ($lingering) {
        Write-Host "      Stopping lingering containers: $lingering..." -ForegroundColor Yellow
        docker stop $lingering | Out-Null
    }
} catch {}

Write-Host "      All AzerothCore game and web containers stopped." -ForegroundColor Green

# 2. Unload Ollama models and stop background process to release GPU VRAM
Write-Host "[2/2] Unloading Ollama AI models & releasing GPU memory..." -ForegroundColor Cyan

$stopOllamaScript = Join-Path $PSScriptRoot "stop-ollama.ps1"
if (Test-Path $stopOllamaScript) {
    & $stopOllamaScript
} else {
    try {
        $modelsOutput = ollama ps 2>$null
        if ($modelsOutput) {
            $loadedModels = $modelsOutput | Select-Object -Skip 1 | ForEach-Object {
                $parts = $_ -split '\s+'
                if ($parts.Count -gt 0) { $parts[0] }
            } | Where-Object { $_ -and $_ -ne "NAME" }

            foreach ($model in $loadedModels) {
                Write-Host "      Stopping model: $model..." -ForegroundColor Yellow
                ollama stop $model
            }
        }
    } catch {}

    Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
    Write-Host "      Ollama unloaded and stopped." -ForegroundColor Green
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   Shutdown Complete - All Services Stopped & GPU VRAM Released" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "`n"
