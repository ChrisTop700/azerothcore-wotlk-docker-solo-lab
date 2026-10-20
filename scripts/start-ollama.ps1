# Start Ollama with external binding for Docker containers
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
Write-Host "Ollama started and listening on 0.0.0.0:11434 (accessible from Docker and host)."
