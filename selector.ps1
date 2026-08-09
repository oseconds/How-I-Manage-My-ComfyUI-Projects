$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================

$WorkflowDir = "C:\**\ComfyUI_windows_portable\ComfyUI\user\default\workflows"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = Join-Path $ProjectDir "workflows"

# ============================================================
# Check directories
# ============================================================

if (-not (Test-Path -LiteralPath $WorkflowDir)) {
    Write-Host ""
    Write-Host "[ERROR] ComfyUI workflow directory not found:" -ForegroundColor Red
    Write-Host $WorkflowDir
    exit 1
}

if (-not (Test-Path -LiteralPath $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

# ============================================================
# Get workflows - latest first
# ============================================================

$Files = @(
    Get-ChildItem -LiteralPath $WorkflowDir -Filter "*.json" -File |
    Sort-Object LastWriteTime -Descending
)

if ($Files.Count -eq 0) {
    Clear-Host
    Write-Host "========================================"
    Write-Host "      ComfyUI Workflow Import"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "No workflow files found."
    Write-Host ""
    exit 0
}

# ============================================================
# Keyboard selector
# ============================================================

$Index = 0
$Selected = $null
$Cancelled = $false

[Console]::CursorVisible = $false

try {

    :SelectorLoop while ($true) {

        Clear-Host

        Write-Host "========================================"
        Write-Host "      ComfyUI Workflow Import"
        Write-Host "========================================"
        Write-Host ""

        Write-Host "Source:"
        Write-Host $WorkflowDir
        Write-Host ""

        Write-Host "Target:"
        Write-Host $TargetDir
        Write-Host ""

        Write-Host "----------------------------------------"
        Write-Host ""

        for ($i = 0; $i -lt $Files.Count; $i++) {

            $File = $Files[$i]
            $Date = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm")

            if ($i -eq $Index) {
                Write-Host ("^> " + $File.Name + "    " + $Date)
            }
            else {
                Write-Host ("  " + $File.Name + "    " + $Date)
            }
        }

        Write-Host ""
        Write-Host "----------------------------------------"
        Write-Host ""
        Write-Host "???? Move"
        Write-Host "Enter  Select"
        Write-Host "Esc    Cancel"

        $Key = [Console]::ReadKey($true)

        if ($Key.Key -eq [ConsoleKey]::UpArrow) {
            $Index--
            if ($Index -lt 0) {
                $Index = $Files.Count - 1
            }
        }
        elseif ($Key.Key -eq [ConsoleKey]::DownArrow) {
            $Index++
            if ($Index -ge $Files.Count) {
                $Index = 0
            }
        }
        elseif ($Key.Key -eq [ConsoleKey]::Enter) {
            $Selected = $Files[$Index]
            break SelectorLoop
        }
        elseif ($Key.Key -eq [ConsoleKey]::Escape) {
            $Cancelled = $true
            break SelectorLoop
        }
    }

}
finally {
    [Console]::CursorVisible = $true
}

# ============================================================
# Cancel
# ============================================================

if ($Cancelled -or $null -eq $Selected) {
    Write-Host ""
    Write-Host "Cancelled."
    exit 0
}

# ============================================================
# Destination
# ============================================================

$Destination = Join-Path $TargetDir $Selected.Name

# ============================================================
# Existing file check
# ============================================================

if (Test-Path -LiteralPath $Destination) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "File already exists:"
    Write-Host $Selected.Name
    Write-Host "========================================"
    Write-Host ""
    Write-Host "[Y] Overwrite"
    Write-Host "[N] Cancel"
    Write-Host ""

    while ($true) {
        $Key = [Console]::ReadKey($true)

        if ($Key.Key -eq [ConsoleKey]::Y) {
            break
        }

        if ($Key.Key -eq [ConsoleKey]::N -or $Key.Key -eq [ConsoleKey]::Escape) {
            Write-Host ""
            Write-Host "Cancelled."
            exit 0
        }
    }
}

# ============================================================
# Copy
# ============================================================

Copy-Item -LiteralPath $Selected.FullName -Destination $Destination -Force

Write-Host ""
Write-Host "========================================"
Write-Host "Workflow imported successfully."
Write-Host "========================================"
Write-Host ""
Write-Host $Selected.Name
Write-Host ""
Write-Host "Saved to:"
Write-Host $TargetDir

