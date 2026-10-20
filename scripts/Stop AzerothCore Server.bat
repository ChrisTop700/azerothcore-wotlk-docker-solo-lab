@echo off
title AzerothCore WotLK - Stop All Services
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\chris\Documents\antigravity\azerothcore-wotlk-docker-solo-lab\scripts\stop-server.ps1"
echo.
echo Press any key to close this window...
pause >nul
