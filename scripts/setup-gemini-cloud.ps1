# ==================================================================
# Setup Google Gemini Free-Tier Cloud for Playerbot Chatter
# ==================================================================

param(
    [string]$ApiKey,
    [string]$Model = "gemini-2.5-flash",
    [switch]$SwitchToOllama
)

$ErrorActionPreference = "Stop"

$ConfPathWSL = "/home/chris/azerothcore-wotlk/env/dist/etc/modules/mod_llm_chatter.conf"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   AzerothCore LLM Chatter - Cloud Provider Switcher" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

if ($SwitchToOllama) {
    Write-Host "Switching chatter provider back to local Ollama (hermes3:8b)..." -ForegroundColor Yellow
    wsl -d Ubuntu python3 -c @"
conf_file = '$ConfPathWSL'
with open(conf_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.strip().startswith('LLMChatter.Provider'):
        new_lines.append('LLMChatter.Provider = ollama\n')
    elif line.strip().startswith('LLMChatter.Model ='):
        new_lines.append('LLMChatter.Model = hermes3:8b\n')
    else:
        new_lines.append(line)

with open(conf_file, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
"@
    Write-Host "Restarting ac-llm-chatter-bridge container..." -ForegroundColor Cyan
    docker restart ac-llm-chatter-bridge | Out-Null
    Start-Sleep -Seconds 3
    Write-Host "Switched to local Ollama. Healthcheck:" -ForegroundColor Green
    docker logs --tail 20 ac-llm-chatter-bridge
    exit 0
}

if (-not $ApiKey) {
    Write-Host "To use Google Gemini Free Tier for Playerbot chatter:" -ForegroundColor Yellow
    Write-Host " 1. Sign in to your secondary Google account at: https://aistudio.google.com/app/apikey" -ForegroundColor White
    Write-Host " 2. Click 'Create API key' and copy the generated key (starts with 'AIza...')." -ForegroundColor White
    Write-Host ""
    $ApiKey = Read-Host "Enter your Google Gemini API Key"
}

if (-not $ApiKey -or $ApiKey.Trim() -eq "") {
    Write-Host "Error: No API key provided. Operation cancelled." -ForegroundColor Red
    exit 1
}

$ApiKey = $ApiKey.Trim()

Write-Host "`nConfiguring Google Gemini ($Model) in mod_llm_chatter.conf..." -ForegroundColor Cyan

# Update mod_llm_chatter.conf safely inside WSL
wsl -d Ubuntu python3 -c @"
conf_file = '$ConfPathWSL'
with open(conf_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('LLMChatter.Provider'):
        new_lines.append('LLMChatter.Provider = google\n')
    elif stripped.startswith('LLMChatter.Model ='):
        new_lines.append('LLMChatter.Model = $Model\n')
    elif stripped.startswith('LLMChatter.Google.ApiKey'):
        new_lines.append('LLMChatter.Google.ApiKey = $ApiKey\n')
    elif stripped.startswith('LLMChatter.Google.ThinkingBudget'):
        new_lines.append('LLMChatter.Google.ThinkingBudget = 0\n')
    elif stripped.startswith('LLMChatter.Google.ReasoningEffort'):
        new_lines.append('LLMChatter.Google.ReasoningEffort = minimal\n')
    else:
        new_lines.append(line)

with open(conf_file, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
"@

Write-Host "Configuration saved. Restarting ac-llm-chatter-bridge..." -ForegroundColor Cyan
docker restart ac-llm-chatter-bridge | Out-Null

Write-Host "Waiting for chatter bridge healthcheck..." -ForegroundColor Gray
Start-Sleep -Seconds 4

Write-Host "`nBridge Live Status:" -ForegroundColor Green
docker logs --tail 25 ac-llm-chatter-bridge

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   Google Gemini Integration Ready!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " * Provider:  Google Gemini Cloud ($Model)" -ForegroundColor White
Write-Host " * API Key:   Stored in WSL config (/config/mod_llm_chatter.conf)" -ForegroundColor Gray
Write-Host " * Fallback:  Run .\scripts\setup-gemini-cloud.ps1 -SwitchToOllama to revert anytime." -ForegroundColor Yellow
