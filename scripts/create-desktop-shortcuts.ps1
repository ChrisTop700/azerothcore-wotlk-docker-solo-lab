# Create desktop shortcuts with custom Warcraft-themed icons
$desktop = [Environment]::GetFolderPath('Desktop')
$wsh = New-Object -ComObject WScript.Shell
$repo = 'C:\Users\chris\Documents\antigravity\azerothcore-wotlk-docker-solo-lab'

$shortcuts = @(
    @{
        Name = 'Start AzerothCore Server.lnk'
        Target = Join-Path $repo 'scripts\Start AzerothCore Server.bat'
        Icon = Join-Path $repo 'icons\server_start.ico'
        Desc = 'Start AzerothCore WotLK Server Stack & Ollama'
    },
    @{
        Name = 'Start Web & Armory Portal.lnk'
        Target = Join-Path $repo 'scripts\Start Web & Armory Portal.bat'
        Icon = Join-Path $repo 'icons\web_armory.ico'
        Desc = 'Start BlizzCMS Web Portal (:8080) and AzerothCore Armory (:48733)'
    },
    @{
        Name = 'Stop AzerothCore Server.lnk'
        Target = Join-Path $repo 'scripts\Stop AzerothCore Server.bat'
        Icon = Join-Path $repo 'icons\server_stop.ico'
        Desc = 'Shut down AzerothCore Server, Web/Armory, and unload Ollama'
    }
)

foreach ($sc in $shortcuts) {
    $lnkPath = Join-Path $desktop $sc.Name
    $lnk = $wsh.CreateShortcut($lnkPath)
    $lnk.TargetPath = $sc.Target
    $lnk.WorkingDirectory = $repo
    $lnk.IconLocation = "$($sc.Icon),0"
    $lnk.Description = $sc.Desc
    $lnk.Save()
    Write-Host "Created shortcut: $lnkPath (Icon: $($sc.Icon))" -ForegroundColor Green
}

# Remove the raw batch files from the Desktop so only the styled shortcuts appear
$rawBats = @(
    'Start AzerothCore Server.bat',
    'Start Web & Armory Portal.bat',
    'Stop AzerothCore Server.bat'
)

foreach ($bat in $rawBats) {
    $batPath = Join-Path $desktop $bat
    if (Test-Path $batPath) {
        Remove-Item $batPath -Force
        Write-Host "Replaced raw $bat with styled desktop shortcut." -ForegroundColor Cyan
    }
}
