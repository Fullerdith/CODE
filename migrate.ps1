# ============================================
# AppData Migration Script
# Moves safe cache folders from C to F:\APPDATA
# Uses Junction (symlink) so programs still work
# ============================================

$ErrorActionPreference = "Stop"
$TargetRoot = "F:\APPDATA"
$SourceRoot = "C:\Users\lenovo\AppData"

# Define folders to migrate (source relative path)
$Folders = @(
    "LocalLow\NVIDIA",
    "Local\JetBrains",
    "Local\Steam",
    "Local\Microsoft\Edge",
    "Roaming\Tencent\WeChat",
    "Roaming\Tencent\QQ",
    "Roaming\Tencent\QQMusic",
    "Roaming\Tencent\QQLive",
    "Roaming\Tencent\QQLiveAppStore"
)

$TotalMB = 0
$Success = @()
$Failed = @()

Write-Host "========================================"
Write-Host " AppData -> F:\APPDATA Migration"
Write-Host "========================================"
Write-Host ""

# Create target root
if (!(Test-Path $TargetRoot)) {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
    Write-Host "[OK] Created $TargetRoot"
}

foreach ($Folder in $Folders) {
    Write-Host ""
    Write-Host "--- [$Folder] ---"

    $SourcePath = Join-Path $SourceRoot $Folder
    $TargetPath = Join-Path $TargetRoot $Folder

    # Check source exists
    if (!(Test-Path $SourcePath)) {
        Write-Host "  SKIP: Source not found"
        continue
    }

    # Get source size
    try {
        $size = [math]::Round((Get-ChildItem $SourcePath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
        Write-Host "  Size: $size MB"
    } catch {
        Write-Host "  Size: unknown (will copy anyway)"
    }

    # Create target parent directory
    $TargetParent = Split-Path $TargetPath -Parent
    if (!(Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }

    # Step 1: Copy data to F drive
    Write-Host "  [1/4] Copying to F:..."
    $robocopyArgs = @(
        $SourcePath,
        $TargetPath,
        "/E",        # all subdirs including empty
        "/COPYALL",  # keep all attributes
        "/R:3",      # retry 3 times
        "/W:3",      # wait 3 sec between retries
        "/NP",       # no progress percentage
        "/NFL",      # no file list
        "/NDL"       # no dir list
    )
    $rc = robocopy @robocopyArgs
    # robocopy exit codes: 0=no change, 1=files copied, 2=extra files, 3=2+3, 4-7=mismatch
    if ($rc -ge 8) {
        Write-Host "  FAILED: robocopy exit code $rc"
        $Failed += $Folder
        continue
    }
    Write-Host "  [OK] Copy done (rc=$rc)"

    # Step 2: Rename original to .old
    Write-Host "  [2/4] Renaming original..."
    $BackupPath = "$SourcePath.old"
    if (Test-Path $BackupPath) {
        Remove-Item $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Rename-Item $SourcePath $BackupPath
    Write-Host "  [OK] Renamed to .old"

    # Step 3: Create junction
    Write-Host "  [3/4] Creating junction..."
    $null = cmd /c "mklink /J `"$SourcePath`" `"$TargetPath`""
    if (Test-Path $SourcePath) {
        Write-Host "  [OK] Junction created"
    } else {
        Write-Host "  FAILED: Junction creation failed, restoring..."
        Rename-Item $BackupPath (Split-Path $SourcePath -Leaf)
        $Failed += $Folder
        continue
    }

    # Step 4: Remove .old backup
    Write-Host "  [4/4] Removing .old backup..."
    Remove-Item $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Old data removed from C:"

    $Success += $Folder
}

Write-Host ""
Write-Host "========================================"
Write-Host " SUMMARY"
Write-Host "========================================"
Write-Host "Success: $($Success.Count) folders"
foreach ($s in $Success) {
    Write-Host "  [OK] $s"
}
if ($Failed.Count -gt 0) {
    Write-Host "Failed: $($Failed.Count) folders"
    foreach ($f in $Failed) {
        Write-Host "  [!!] $f"
    }
}
Write-Host ""
Write-Host "Done!"
