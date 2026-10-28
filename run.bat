@echo off
chcp 65001 >nul
title NovaForge AI Game Engine Launcher (Godot 4.6 + Jolt + Colibri Local AI)
cd /d "%~dp0"

echo ============================================================================
echo   NovaForge AI Game Engine — Launcher (Windows x64)
echo   Godot 4.6 UI + Hybrid Blueprint/C++ + Colibri Multi-Brain Local AI
echo ============================================================================
echo.
echo   [1] Open Godot 4 Editor with NovaForge Modules (Auto-installs Godot 4.6 if missing)
echo   [2] Play 3D Sandbox Game Directly (WASD + Mouse Combo + [E] Interact)
echo   [3] Run Live Browser Studio Server (http://127.0.0.1:8080)
echo.
set /p MODE="Select mode [1/2/3] (Default=1): "

if "%MODE%"=="2" (
    python launcher\novaforge_launcher.py --play
) else if "%MODE%"=="3" (
    start "" http://127.0.0.1:8080
    python launcher\novaforge_launcher.py --studio --host 127.0.0.1 --port 8080
) else (
    python launcher\novaforge_launcher.py --editor
)
pause
