# ==================================================================
# Manage Playerbot Personalities (JSON & Database Sync)
# ==================================================================

param(
    [switch]$List,
    [switch]$Apply,
    [string]$ConfigPath = "config\bot_personalities.json",
    [string]$Name,
    [string]$Tone,
    [string]$Backstory,
    [string]$Role
)

$PSScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $PSScriptDir
$PythonScript = Join-Path $PSScriptDir "manage_bot_personalities.py"

if ($List) {
    python $PythonScript --list
}
elseif ($Apply) {
    $fullConfig = Join-Path $RepoRoot $ConfigPath
    python $PythonScript --apply $fullConfig
}
elseif ($Name) {
    $params = @("--set", "--name", $Name)
    if ($Tone) { $params += @("--tone", $Tone) }
    if ($Backstory) { $params += @("--backstory", $Backstory) }
    if ($Role) { $params += @("--role", $Role) }
    python $PythonScript @params
}
else {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "   AzerothCore Bot Personality Manager" -ForegroundColor White
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\manage-bot-personalities.ps1 -List"
    Write-Host "      Lists all configured bot backstories and tones in the database."
    Write-Host ""
    Write-Host "  .\scripts\manage-bot-personalities.ps1 -Apply"
    Write-Host "      Applies all personalities from config\bot_personalities.json to the database."
    Write-Host ""
    Write-Host "  .\scripts\manage-bot-personalities.ps1 -Name Pier -Tone 'sarcastic speedrunner' -Backstory 'Needs gold for epic mount.'"
    Write-Host "      Quickly updates a single bot directly."
    Write-Host "==================================================================" -ForegroundColor Cyan
}
