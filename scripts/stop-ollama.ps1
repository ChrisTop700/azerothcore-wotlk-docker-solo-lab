# Unload all active models and stop Ollama process to release GPU VRAM
Write-Host "Unloading Ollama models from memory..." -ForegroundColor Cyan
try {
    $modelsOutput = ollama ps 2>$null
    if ($modelsOutput) {
        $loadedModels = $modelsOutput | Select-Object -Skip 1 | ForEach-Object {
            $parts = $_ -split '\s+'
            if ($parts.Count -gt 0) { $parts[0] }
        } | Where-Object { $_ -and $_ -ne "NAME" }

        foreach ($model in $loadedModels) {
            Write-Host "Stopping and unloading model: $model..." -ForegroundColor Yellow
            ollama stop $model
        }
    }
} catch {
    Write-Warning "Could not query or stop models via ollama CLI: $_"
}

Write-Host "Stopping Ollama background processes..." -ForegroundColor Cyan
Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "Ollama completely unloaded and GPU memory released." -ForegroundColor Green
