@echo off
setlocal

title ComfyUI - How I Manage My ComfyUI Projects

REM External ComfyUI Portable runtime
set "COMFY=C:\**\ComfyUI_windows_portable"
set "PROJECT=%~dp0"

echo ========================================
echo  ComfyUI Project: How I Manage My ComfyUI Projects
echo ========================================
echo.
echo Project: %PROJECT%
echo Input:   %PROJECT%input
echo Output:  %PROJECT%output
echo.

"%COMFY%\python_embeded\python.exe" -s "%COMFY%\ComfyUI\main.py"         --windows-standalone-build         --input-directory "%PROJECT%input"         --output-directory "%PROJECT%output"

pause
