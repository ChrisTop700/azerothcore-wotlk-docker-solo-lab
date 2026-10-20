# Start Ollama with external binding for Docker containers
Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_ORIGINS = "*"

Start-Process "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
    $res = Invoke-RestMethod "http://127.0.0.1:11434/" -TimeoutSec 5
    if ($res -match "Ollama is running") {
        Write-Host "Ollama started and listening on 0.0.0.0:11434 (accessible from Docker and host)." -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Ollama launched, but endpoint test timed out." -ForegroundColor Yellow
}
