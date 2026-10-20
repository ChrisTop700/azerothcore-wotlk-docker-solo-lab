# ==================================================================
# Setup Google Gemini Free-Tier Cloud for Playerbot Chatter
# Supports Multi-Account Key Pool & Separate-Quota Model Cascades
# ==================================================================

param(
    [string]$ApiKey,
    [string]$SecondaryApiKey,
    [string]$Model = "gemini-2.5-flash",
    [string]$FallbackModels = "gemini-2.0-flash-lite,gemini-1.5-flash",
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
    Write-Host "Google Gemini Free-Tier Configuration:" -ForegroundColor Yellow
    Write-Host " * Quotas are per-model and per-account (15 RPM / 1,500 RPD each)." -ForegroundColor Gray
    Write-Host " * Using secondary Google accounts ensures your main work quota is 100% untouched." -ForegroundColor Gray
    Write-Host ""
    $ApiKey = Read-Host "Enter Primary Gemini API Key (Account 1)"
}

if (-not $ApiKey -or $ApiKey.Trim() -eq "") {
    Write-Host "Error: Primary API key is required. Operation cancelled." -ForegroundColor Red
    exit 1
}

$ApiKey = $ApiKey.Trim()

if (-not $SecondaryApiKey) {
    $secInput = Read-Host "Enter Secondary Gemini API Key (Account 2) [Optional, press Enter to skip]"
    if ($secInput -and $secInput.Trim() -ne "") {
        $SecondaryApiKey = $secInput.Trim()
    }
}

$combinedKeys = $ApiKey
if ($SecondaryApiKey -and $SecondaryApiKey.Trim() -ne "") {
    $combinedKeys = "$ApiKey,$($SecondaryApiKey.Trim())"
}

Write-Host "`nConfiguring Google Gemini Cloud Pool..." -ForegroundColor Cyan
Write-Host " * Primary Model:    $Model" -ForegroundColor White
Write-Host " * Fallback Models:  $FallbackModels" -ForegroundColor White
Write-Host " * Account Keys:     $(if ($SecondaryApiKey) { '2 Accounts configured (automatic failover)' } else { '1 Account configured' })" -ForegroundColor White

# Update mod_llm_chatter.conf safely inside WSL
wsl -d Ubuntu python3 -c @"
conf_file = '$ConfPathWSL'
with open(conf_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
has_fallback_models = False

for line in lines:
    stripped = line.strip()
    if stripped.startswith('LLMChatter.Provider'):
        new_lines.append('LLMChatter.Provider = google\n')
    elif stripped.startswith('LLMChatter.Model ='):
        new_lines.append('LLMChatter.Model = $Model\n')
    elif stripped.startswith('LLMChatter.Google.ApiKey'):
        new_lines.append('LLMChatter.Google.ApiKey = $combinedKeys\n')
    elif stripped.startswith('LLMChatter.Google.ThinkingBudget'):
        new_lines.append('LLMChatter.Google.ThinkingBudget = 0\n')
    elif stripped.startswith('LLMChatter.Google.ReasoningEffort'):
        new_lines.append('LLMChatter.Google.ReasoningEffort = minimal\n')
    elif stripped.startswith('LLMChatter.Google.FallbackModels'):
        new_lines.append('LLMChatter.Google.FallbackModels = $FallbackModels\n')
        has_fallback_models = True
    else:
        new_lines.append(line)

if not has_fallback_models:
    new_lines.append('LLMChatter.Google.FallbackModels = $FallbackModels\n')

with open(conf_file, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
"@

Write-Host "`nRestarting ac-llm-chatter-bridge..." -ForegroundColor Cyan
docker restart ac-llm-chatter-bridge | Out-Null

Write-Host "Waiting for chatter bridge healthcheck..." -ForegroundColor Gray
Start-Sleep -Seconds 4

Write-Host "`nBridge Live Status:" -ForegroundColor Green
docker logs --tail 25 ac-llm-chatter-bridge

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   Multi-Account Gemini Integration Ready!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " * Key Failover:    Account 1 -> Account 2 (automatic)" -ForegroundColor White
Write-Host " * Model Cascade:   $Model -> $FallbackModels (separate quota pools)" -ForegroundColor White
Write-Host " * Ultimate Backup: Local Ollama (hermes3:8b on RTX 4080)" -ForegroundColor White
