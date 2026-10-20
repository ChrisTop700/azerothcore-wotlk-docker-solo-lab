# ==================================================================
# AzerothCore WotLK (3.3.5a) Solo Lab - Game Server Startup
# ==================================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   AzerothCore WotLK (3.3.5a) Solo Lab - Server Startup" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Ensure Docker Desktop is running
$dockerRunning = $false
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    Write-Host "[1/3] Docker Desktop is not running. Starting Docker Desktop..." -ForegroundColor Yellow
    $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Start-Process $dockerPath
        Write-Host "      Waiting for Docker daemon to initialize..." -ForegroundColor Gray
        $timeout = 60
        $timer = 0
        while (-not $dockerRunning -and $timer -lt $timeout) {
            Start-Sleep -Seconds 3
            $timer += 3
            try {
                $null = docker info 2>&1
                if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
            } catch {}
        }
        if (-not $dockerRunning) {
            Write-Host "Error: Docker Desktop failed to start within $timeout seconds. Please launch it manually." -ForegroundColor Red
            exit 1
        }
        Write-Host "      Docker daemon is ready." -ForegroundColor Green
    } else {
        Write-Host "Error: Docker Desktop executable not found at $dockerPath. Please start Docker manually." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[1/3] Docker Desktop is running." -ForegroundColor Green
}

# 2. Ensure Ollama is started with 0.0.0.0 binding for Docker bridge
Write-Host "[2/3] Checking Ollama AI status..." -ForegroundColor Cyan
$ollamaResponding = $false
try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:11434/" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response -match "Ollama is running") { $ollamaResponding = $true }
} catch {}

if (-not $ollamaResponding) {
    Write-Host "      Launching Ollama with external binding (0.0.0.0:11434)..." -ForegroundColor Yellow
    $startOllamaScript = Join-Path $PSScriptRoot "start-ollama.ps1"
    if (Test-Path $startOllamaScript) {
        & $startOllamaScript
    } else {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
        $psi.Arguments = "serve"
        $psi.EnvironmentVariables["OLLAMA_HOST"] = "0.0.0.0:11434"
        $psi.EnvironmentVariables["OLLAMA_ORIGINS"] = "*"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.UseShellExecute = $false
        Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
    Start-Sleep -Seconds 2
    Write-Host "      Ollama is ready for playerbot chatter." -ForegroundColor Green
} else {
    Write-Host "      Ollama is already running and listening." -ForegroundColor Green
}

# 3. Start Core AzerothCore Game Containers via WSL
Write-Host "[3/3] Starting AzerothCore core services (Auth, World, Database, LLM Bridge)..." -ForegroundColor Cyan
wsl -d Ubuntu bash -c "cd ~/azerothcore-wotlk && docker compose up -d"

Write-Host "`nContainer Status:" -ForegroundColor Green
docker ps --filter "name=ac-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   AzerothCore Server is Online!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " * Realmlist:           127.0.0.1" -ForegroundColor Yellow
Write-Host " * Auth Port:           3724" -ForegroundColor Gray
Write-Host " * World Port:          8085" -ForegroundColor Gray
Write-Host " * SOAP Port:           7878" -ForegroundColor Gray
Write-Host " * Ollama LLM Bridge:   Active (0.0.0.0:11434)" -ForegroundColor Gray
Write-Host "`n To attach to GM Worldserver Console:" -ForegroundColor White
Write-Host "   docker attach ac-worldserver" -ForegroundColor Yellow
Write-Host "   (Safely detach anytime: Press Ctrl+P then Ctrl+Q)`n" -ForegroundColor DarkGray
