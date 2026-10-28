@echo off
cd /d "%~dp0"
if exist "%~dp0NovaForge_Studio.exe" (
    start "" "%~dp0NovaForge_Studio.exe"
    exit /b 0
)
python launcher\gui_hub.py
