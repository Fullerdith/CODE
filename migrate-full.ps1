# ============================================
# Phase 1: Copy all remaining AppData to F:
# ============================================
$ErrorActionPreference = "Continue"
$TargetRoot = "F:\APPDATA"
$SourceRoot = "C:\Users\lenovo\AppData"

# All remaining large folders (everything except already-junctioned)
$Folders = @(
    # LocalLow
    "LocalLow\NVIDIA",
    "LocalLow\JutsuGames",
    "LocalLow\Baidu",
    "LocalLow\PeroPeroGames",
    "LocalLow\Mediatonic",
    # Local
    "Local\Programs",
    "Local\perfectworldarena-updater",
    # Roaming
    "Roaming\QQEX",
    "Roaming\JetBrains",
    "Roaming\BCUT",
    "Roaming\od"
)

# Also move .vscode from user root
$ExtraFolders = @(
    ".vscode"
)
$ExtraSource = "C:\Users\lenovo"
$ExtraTarget = "F:\APPDATA"

Write-Host "========================================"
Write-Host " Phase 1: Copy ALL data to F:"
Write-Host "========================================"

# Create target root
if (!(Test-Path $TargetRoot)) {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
}

# Copy AppData folders
$FailedFolders = @()
foreach ($Folder in $Folders) {
    $src = Join-Path $SourceRoot $Folder
    $dst = Join-Path $TargetRoot $Folder

    if (!(Test-Path $src)) {
        Write-Host "SKIP $Folder - not found"
        continue
    }

    # Get size
    try {
        $size = [math]::Round((Get-ChildItem $src -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    } catch { $size = 0 }

    # Create parent
    $dstParent = Split-Path $dst -Parent
    if (!(Test-Path $dstParent)) {
        New-Item -ItemType Directory -Path $dstParent -Force | Out-Null
    }

    Write-Host "[$Folder] $size MB - copying..."
    $rc = robocopy $src $dst /E /COPYALL /R:0 /W:0 /NP /NFL /NDL
    # rc < 8 means success (some skipped locked files are OK)
    if ($rc -ge 8) {
        Write-Host "  WARNING: robocopy rc=$rc - will retry on boot"
        $FailedFolders += $Folder
    } else {
        Write-Host "  Copied (rc=$rc)"

        # Try to migrate NOW (rename + junction)
        $backup = "$src.old"
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }

        try {
            Rename-Item $src $backup -ErrorAction Stop
            cmd /c "mklink /J `"$src`" `"$dst`""
            if (Test-Path $src) {
                Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  [OK] Migrated now!"
            } else {
                Rename-Item $backup (Split-Path $src -Leaf)
                Write-Host "  FAILED: junction - will retry on boot"
                $FailedFolders += $Folder
            }
        } catch {
            Write-Host "  FAILED: locked - will retry on boot"
            $FailedFolders += $Folder
        }
    }
}

# Copy extra folders (like .vscode)
foreach ($Folder in $ExtraFolders) {
    $src = Join-Path $ExtraSource $Folder
    $dst = Join-Path $ExtraTarget $Folder

    if (!(Test-Path $src)) {
        Write-Host "SKIP $Folder - not found"
        continue
    }

    try {
        $size = [math]::Round((Get-ChildItem $src -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    } catch { $size = 0 }

    $dstParent = Split-Path $dst -Parent
    if (!(Test-Path $dstParent)) {
        New-Item -ItemType Directory -Path $dstParent -Force | Out-Null
    }

    Write-Host "[$Folder] $size MB - copying..."
    $rc = robocopy $src $dst /E /COPYALL /R:0 /W:0 /NP /NFL /NDL
    if ($rc -ge 8) {
        $FailedFolders += $Folder
    } else {
        $backup = "$src.old"
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }
        try {
            Rename-Item $src $backup -ErrorAction Stop
            cmd /c "mklink /J `"$src`" `"$dst`""
            if (Test-Path $src) {
                Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  [OK] Migrated now!"
            } else {
                Rename-Item $backup (Split-Path $src -Leaf)
                $FailedFolders += $Folder
            }
        } catch {
            $FailedFolders += $Folder
        }
    }
}

# ============================================
# Phase 2: Create boot-time script for failures
# ============================================
Write-Host ""
Write-Host "========================================"
Write-Host " Phase 2: Boot-time migration setup"
Write-Host "========================================"

if ($FailedFolders.Count -eq 0) {
    Write-Host "All folders migrated! No boot script needed."
} else {
    Write-Host "Failed folders (will migrate on boot):"
    foreach ($f in $FailedFolders) { Write-Host "  - $f" }

    # Convert folder list to PowerShell array syntax
    $folderList = ($FailedFolders | ForEach-Object { "'$_'" }) -join ",`n    "

    $bootScript = @"
# ============================================
# Boot-time AppData Migration Finisher
# Runs at system startup, before user login
# ============================================
`$ErrorActionPreference = "Continue"
`$TargetRoot = "F:\APPDATA"
`$AppSource = "C:\Users\lenovo\AppData"
`$UserSource = "C:\Users\lenovo"

# Wait for F: drive to be available
`$waited = 0
while (!(Test-Path "F:\") -and `$waited -lt 60) {
    Start-Sleep 1
    `$waited++
}

if (!(Test-Path "F:\")) {
    Write-Output "ERROR: F: drive not available after 60s"
    exit 1
}

Write-Output "Boot-time migration starting..."
Write-Output "Target: `$TargetRoot"

`$appFolders = @(
    $folderList
)

`$extraMappings = @{
}

foreach (`$folder in `$appFolders) {
    `$src = Join-Path `$AppSource `$folder
    `$dst = Join-Path `$TargetRoot `$folder
    `$backup = "`$src.old"

    Write-Output "Processing: `$folder"

    # If junction already exists, skip
    `$item = Get-Item `$src -ErrorAction SilentlyContinue
    if (`$item -and `$item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Output "  Already a junction, skipping"
        continue
    }

    # If .old backup exists from previous attempt, remove it first
    if (Test-Path `$backup) {
        Write-Output "  Removing old backup..."
        Remove-Item `$backup -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Rename original
    if (Test-Path `$src) {
        try {
            Rename-Item `$src `$backup -ErrorAction Stop
            Write-Output "  Renamed to .old"
        } catch {
            Write-Output "  FAILED rename: `$_"
            continue
        }
    } else {
        Write-Output "  Source not found (may already be migrated)"
    }

    # Create junction
    if (Test-Path `$dst) {
        cmd /c "mklink /J `"`$src`" `"`$dst`""
        if (Test-Path `$src) {
            Write-Output "  Junction created"

            # Remove backup
            if (Test-Path `$backup) {
                Remove-Item `$backup -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "  Old data removed"
            }
            Write-Output "  [OK] `$folder migrated"
        } else {
            Write-Output "  FAILED: Junction not created, restoring..."
            if (Test-Path `$backup) {
                Rename-Item `$backup (Split-Path `$src -Leaf)
            }
        }
    } else {
        Write-Output "  Target not found at `$dst, skipping"
    }
}

Write-Output "Boot-time migration complete!"
"@

    # Save boot script
    $bootScriptPath = "F:\APPDATA\boot-finish.ps1"
    $bootScript | Out-File -FilePath $bootScriptPath -Encoding UTF8 -Force
    Write-Host "Boot script saved to $bootScriptPath"

    # Create scheduled task to run at startup
    $taskName = "AppDataMigrationFinisher"
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$bootScriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DeleteExpiredTaskAfter 00:00:10

    # Remove existing task if any
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Host "Scheduled task '$taskName' created - will run at next boot"
}

Write-Host ""
Write-Host "Done! Review summary above."
