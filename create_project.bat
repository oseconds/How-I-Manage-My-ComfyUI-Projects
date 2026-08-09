@echo off
setlocal EnableExtensions
title ComfyUI Project Creator

REM ============================================================
REM Configuration
REM ============================================================

set "COMFY=C:\**\ComfyUI_windows_portable"
set "GITATTRIBUTES_CONFIG=%~dp0gitattributes.conf"

echo.
echo ========================================
echo       ComfyUI Project Creator
echo ========================================
echo.

set /p "PROJECT_NAME=Project name: "

if "%PROJECT_NAME%"=="" (
    echo.
    echo [ERROR] Project name cannot be empty.
    pause
    exit /b 1
)

set "PROJECT_ROOT=%~dp0%PROJECT_NAME%"

REM ============================================================
REM Check existing project
REM ============================================================

if exist "%PROJECT_ROOT%" (
    echo.
    echo [ERROR] Project already exists:
    echo %PROJECT_ROOT%
    echo.
    echo Nothing was changed.
    pause
    exit /b 1
)

REM ============================================================
REM Create project directories
REM ============================================================

echo.
echo Creating project...

mkdir "%PROJECT_ROOT%"
mkdir "%PROJECT_ROOT%\workflows"
mkdir "%PROJECT_ROOT%\prompts"
mkdir "%PROJECT_ROOT%\input"
mkdir "%PROJECT_ROOT%\output"
mkdir "%PROJECT_ROOT%\docs"

REM ============================================================
REM Git ignore
REM ============================================================

(
    echo # ComfyUI generated files
    echo.
    echo prompts/*
    echo !prompts/.gitkeep
    echo.
    echo input/*
    echo !input/.gitkeep
    echo.
    echo output/*
    echo !output/.gitkeep
    echo.
    echo # Temporary files
    echo *.tmp
    echo *.temp
    echo.
    echo # Local helper scripts
    echo import_workflow.bat
    echo selector.ps1
) > "%PROJECT_ROOT%\.gitignore"

REM ============================================================
REM Generate .gitattributes
REM ============================================================

(
    echo # Auto detect text files and perform LF normalization
    echo.
    echo * text=auto

    if exist "%GITATTRIBUTES_CONFIG%" (
        type "%GITATTRIBUTES_CONFIG%"
    )
) > "%PROJECT_ROOT%\.gitattributes"

REM ============================================================
REM Keep empty directories in Git
REM ============================================================

type nul > "%PROJECT_ROOT%\workflows\.gitkeep"
type nul > "%PROJECT_ROOT%\prompts\.gitkeep"
type nul > "%PROJECT_ROOT%\input\.gitkeep"
type nul > "%PROJECT_ROOT%\output\.gitkeep"
type nul > "%PROJECT_ROOT%\docs\.gitkeep"

REM ============================================================
REM README
REM ============================================================

(
    echo # %PROJECT_NAME%
    echo.
    echo ComfyUI project.
    echo.
    echo ## Structure
    echo.
    echo - `workflows/` - ComfyUI workflows
    echo - `input/` - Input media
    echo - `output/` - Generated media
    echo - `prompts/` - Prompts
    echo - `docs/` - Project notes and documentation
    echo.
    echo ## Runtime
    echo.
    echo This project uses the external ComfyUI Portable runtime.
) > "%PROJECT_ROOT%\README.md"

REM ============================================================
REM Project launcher
REM ============================================================

(
    echo @echo off
    echo setlocal
    echo.
    echo title ComfyUI - %PROJECT_NAME%
    echo.
    echo REM External ComfyUI Portable runtime
    echo set "COMFY=%COMFY%"
    echo set "PROJECT=%%~dp0"
    echo.
    echo echo ========================================
    echo echo  ComfyUI Project: %PROJECT_NAME%
    echo echo ========================================
    echo echo.
    echo echo Project: %%PROJECT%%
    echo echo Input:   %%PROJECT%%input
    echo echo Output:  %%PROJECT%%output
    echo echo.
    echo.
    echo "%%COMFY%%\python_embeded\python.exe" -s "%%COMFY%%\ComfyUI\main.py" ^
        --windows-standalone-build ^
        --input-directory "%%PROJECT%%input" ^
        --output-directory "%%PROJECT%%output"
    echo.
    echo pause
) > "%PROJECT_ROOT%\run.bat"

REM ============================================================
REM Workflow importer
REM ============================================================

(
    echo @echo off
    echo setlocal
    echo.
    echo title ComfyUI Workflow Importer
    echo.
    echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" ^
        -NoProfile ^
        -ExecutionPolicy Bypass ^
        -File "%%~dp0selector.ps1"
    echo.
    echo pause
) > "%PROJECT_ROOT%\import_workflow.bat"

REM ============================================================
REM Workflow selector PowerShell
REM ============================================================

(
    echo $ErrorActionPreference = "Stop"
    echo.
    echo # ============================================================
    echo # Configuration
    echo # ============================================================
    echo.
    echo $WorkflowDir = "C:\**\ComfyUI_windows_portable\ComfyUI\user\default\workflows"
    echo $ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    echo $TargetDir = Join-Path $ProjectDir "workflows"
    echo.
    echo # ============================================================
    echo # Check directories
    echo # ============================================================
    echo.
    echo if ^(-not ^(Test-Path -LiteralPath $WorkflowDir^)^) {
    echo     Write-Host ""
    echo     Write-Host "[ERROR] ComfyUI workflow directory not found:" -ForegroundColor Red
    echo     Write-Host $WorkflowDir
    echo     exit 1
    echo }
    echo.
    echo if ^(-not ^(Test-Path -LiteralPath $TargetDir^)^) {
    echo     New-Item -ItemType Directory -Path $TargetDir ^| Out-Null
    echo }
    echo.
    echo # ============================================================
    echo # Get workflows - latest first
    echo # ============================================================
    echo.
    echo $Files = @^(
    echo     Get-ChildItem -LiteralPath $WorkflowDir -Filter "*.json" -File ^|
    echo     Sort-Object LastWriteTime -Descending
    echo ^)
    echo.
    echo if ^($Files.Count -eq 0^) {
    echo     Clear-Host
    echo     Write-Host "========================================"
    echo     Write-Host "      ComfyUI Workflow Import"
    echo     Write-Host "========================================"
    echo     Write-Host ""
    echo     Write-Host "No workflow files found."
    echo     Write-Host ""
    echo     exit 0
    echo }
    echo.
    echo # ============================================================
    echo # Keyboard selector
    echo # ============================================================
    echo.
    echo $Index = 0
    echo $Selected = $null
    echo $Cancelled = $false
    echo.
    echo [Console]::CursorVisible = $false
    echo.
    echo try {
    echo.
    echo     :SelectorLoop while ^($true^) {
    echo.
    echo         Clear-Host
    echo.
    echo         Write-Host "========================================"
    echo         Write-Host "      ComfyUI Workflow Import"
    echo         Write-Host "========================================"
    echo         Write-Host ""
    echo.
    echo         Write-Host "Source:"
    echo         Write-Host $WorkflowDir
    echo         Write-Host ""
    echo.
    echo         Write-Host "Target:"
    echo         Write-Host $TargetDir
    echo         Write-Host ""
    echo.
    echo         Write-Host "----------------------------------------"
    echo         Write-Host ""
    echo.
    echo         for ^($i = 0; $i -lt $Files.Count; $i++^) {
    echo.
    echo             $File = $Files[$i]
    echo             $Date = $File.LastWriteTime.ToString^("yyyy-MM-dd HH:mm"^)
    echo.
    echo             if ^($i -eq $Index^) {
    echo                 Write-Host ^("^> " + $File.Name + "    " + $Date^)
    echo             }
    echo             else {
    echo                 Write-Host ^("  " + $File.Name + "    " + $Date^)
    echo             }
    echo         }
    echo.
    echo         Write-Host ""
    echo         Write-Host "----------------------------------------"
    echo         Write-Host ""
    echo         Write-Host "↑ ↓  Move"
    echo         Write-Host "Enter  Select"
    echo         Write-Host "Esc    Cancel"
    echo.
    echo         $Key = [Console]::ReadKey^($true^)
    echo.
    echo         if ^($Key.Key -eq [ConsoleKey]::UpArrow^) {
    echo             $Index--
    echo             if ^($Index -lt 0^) {
    echo                 $Index = $Files.Count - 1
    echo             }
    echo         }
    echo         elseif ^($Key.Key -eq [ConsoleKey]::DownArrow^) {
    echo             $Index++
    echo             if ^($Index -ge $Files.Count^) {
    echo                 $Index = 0
    echo             }
    echo         }
    echo         elseif ^($Key.Key -eq [ConsoleKey]::Enter^) {
    echo             $Selected = $Files[$Index]
    echo             break SelectorLoop
    echo         }
    echo         elseif ^($Key.Key -eq [ConsoleKey]::Escape^) {
    echo             $Cancelled = $true
    echo             break SelectorLoop
    echo         }
    echo     }
    echo.
    echo }
    echo finally {
    echo     [Console]::CursorVisible = $true
    echo }
    echo.
    echo # ============================================================
    echo # Cancel
    echo # ============================================================
    echo.
    echo if ^($Cancelled -or $null -eq $Selected^) {
    echo     Write-Host ""
    echo     Write-Host "Cancelled."
    echo     exit 0
    echo }
    echo.
    echo # ============================================================
    echo # Destination
    echo # ============================================================
    echo.
    echo $Destination = Join-Path $TargetDir $Selected.Name
    echo.
    echo # ============================================================
    echo # Existing file check
    echo # ============================================================
    echo.
    echo if ^(Test-Path -LiteralPath $Destination^) {
    echo.
    echo     Write-Host ""
    echo     Write-Host "========================================"
    echo     Write-Host "File already exists:"
    echo     Write-Host $Selected.Name
    echo     Write-Host "========================================"
    echo     Write-Host ""
    echo     Write-Host "[Y] Overwrite"
    echo     Write-Host "[N] Cancel"
    echo     Write-Host ""
    echo.
    echo     while ^($true^) {
    echo         $Key = [Console]::ReadKey^($true^)
    echo.
    echo         if ^($Key.Key -eq [ConsoleKey]::Y^) {
    echo             break
    echo         }
    echo.
    echo         if ^($Key.Key -eq [ConsoleKey]::N -or $Key.Key -eq [ConsoleKey]::Escape^) {
    echo             Write-Host ""
    echo             Write-Host "Cancelled."
    echo             exit 0
    echo         }
    echo     }
    echo }
    echo.
    echo # ============================================================
    echo # Copy
    echo # ============================================================
    echo.
    echo Copy-Item -LiteralPath $Selected.FullName -Destination $Destination -Force
    echo.
    echo Write-Host ""
    echo Write-Host "========================================"
    echo Write-Host "Workflow imported successfully."
    echo Write-Host "========================================"
    echo Write-Host ""
    echo Write-Host $Selected.Name
    echo Write-Host ""
    echo Write-Host "Saved to:"
    echo Write-Host $TargetDir
    echo.
) > "%PROJECT_ROOT%\selector.ps1"

REM ============================================================
REM Initialize Git
REM ============================================================

cd /d "%PROJECT_ROOT%"

git init

if errorlevel 1 (
    echo.
    echo [WARNING] Git initialization failed.
    echo Make sure Git is installed and available in PATH.
) else (
    echo.
    echo Git repository initialized.
)

REM ============================================================
REM Done
REM ============================================================

echo.
echo ========================================
echo       Project Created Successfully
echo ========================================
echo.
echo Project:
echo %PROJECT_ROOT%
echo.
echo Structure:
echo   workflows
echo   input
echo   output
echo   prompts
echo   docs
echo   README.md
echo   .gitignore
echo   .gitattributes
echo   run.bat
echo   import_workflow.bat
echo   selector.ps1
echo.
echo Git repository initialized.
echo.
echo Run ComfyUI:
echo   %PROJECT_ROOT%\run.bat
echo.
echo Import workflow:
echo   %PROJECT_ROOT%\import_workflow.bat
echo.
pause