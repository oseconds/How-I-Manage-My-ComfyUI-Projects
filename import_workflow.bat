@echo off
setlocal

title ComfyUI Workflow Importer

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"         -NoProfile         -ExecutionPolicy Bypass         -File "%~dp0selector.ps1"

pause
