# ==================================================================
# Manage Playerbot Personalities (JSON & World Populator)
# ==================================================================

param(
    [switch]$List,
    [switch]$Apply,
    [switch]$PopulateWorld,
    [int]$Count = 100,
    [switch]$Overwrite,
    [string]$ConfigPath = "config\bot_personalities.json"
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
elseif ($PopulateWorld) {
    $params = @("--populate-world", $Count)
    if ($Overwrite) { $params += "--overwrite" }
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
    Write-Host "      Applies curated personalities from config\bot_personalities.json to the database."
    Write-Host ""
    Write-Host "  .\scripts\manage-bot-personalities.ps1 -PopulateWorld [-Count 150] [-Overwrite]"
    Write-Host "      Populates the entire server population with diverse, authentic gamer archetypes."
    Write-Host "==================================================================" -ForegroundColor Cyan
}
