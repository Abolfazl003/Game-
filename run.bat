@echo off
chcp 65001 >nul
title NovaForge AI Game Engine — Official Godot 4.7.2 Launcher
cd /d "%~dp0"

echo ============================================================================
echo   NovaForge AI Game Engine — Launcher (Windows x64)
echo   Official Godot 4.7.2 Editor + Jolt + Hybrid Blueprint/C++ + Colibri AI
echo ============================================================================
echo.
echo   [1] Open Real Godot 4.7.2 Editor with NovaForge Modules (Auto-downloads Godot 4.7.2 if missing)
echo   [2] Play 3D Samurai Sandbox Game Directly (WASD + Mouse Combo + [E] Interact)
echo.
set /p MODE="Select mode [1/2] (Default=1): "

if "%MODE%"=="2" (
    python launcher\novaforge_launcher.py --play
) else (
    python launcher\novaforge_launcher.py --editor
)
pause
