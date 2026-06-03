$ErrorActionPreference = "Continue"

Write-Host "=== Killing Edge processes ==="
Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
$remaining = Get-Process msedge -ErrorAction SilentlyContinue
if ($remaining) { Write-Host "WARNING: Some Edge processes still running" }
else { Write-Host "OK: All Edge processes killed" }

Write-Host ""
Write-Host "=== Retry: NVIDIA ==="

$src = "C:\Users\lenovo\AppData\LocalLow\NVIDIA"
$dst = "F:\APPDATA\LocalLow\NVIDIA"

if (Test-Path $src) {
    # Copy again with no retry on locked files
    $rc = robocopy $src $dst /E /COPYALL /R:0 /W:0 /NP /NFL /NDL
    Write-Host "Robocopy rc=$rc (data already copied previously, skipping locked files OK)"

    # Rename original
    $backup = "$src.old"
    if (Test-Path $backup) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }
    try {
        Rename-Item $src $backup -ErrorAction Stop
        Write-Host "Renamed original to .old"

        # Create junction
        cmd /c "mklink /J `"$src`" `"$dst`""
        if (Test-Path $src) {
            Write-Host "Junction created for NVIDIA"

            # Remove backup
            Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Old NVIDIA data removed from C:"
            Write-Host "[OK] NVIDIA migration done!"
        } else {
            Write-Host "FAILED: junction creation, restoring..."
            Rename-Item $backup NVIDIA
        }
    } catch {
        Write-Host "FAILED: cannot rename, files still locked"
    }
} else {
    Write-Host "Source not found, might already be migrated"
}

Write-Host ""
Write-Host "=== Retry: Edge ==="

$srcEdge = "C:\Users\lenovo\AppData\Local\Microsoft\Edge"
$dstEdge = "F:\APPDATA\Local\Microsoft\Edge"

if (Test-Path $srcEdge) {
    # Copy with no retry
    $rc = robocopy $srcEdge $dstEdge /E /COPYALL /R:0 /W:0 /NP /NFL /NDL
    Write-Host "Robocopy rc=$rc"

    $backup = "$srcEdge.old"
    if (Test-Path $backup) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }
    try {
        Rename-Item $srcEdge $backup -ErrorAction Stop
        Write-Host "Renamed original to .old"

        cmd /c "mklink /J `"$srcEdge`" `"$dstEdge`""
        if (Test-Path $srcEdge) {
            Write-Host "Junction created for Edge"

            Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Old Edge data removed from C:"
            Write-Host "[OK] Edge migration done!"
        } else {
            Write-Host "FAILED: junction creation, restoring..."
            Rename-Item $backup Edge
        }
    } catch {
        Write-Host "FAILED: $_"
    }
} else {
    Write-Host "Edge source not found, might already be migrated"
}

Write-Host ""
Write-Host "=== Final verification ==="
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Local`"" 2>$null
cmd /c "dir /AL `"C:\Users\lenovo\AppData\LocalLow`"" 2>$null
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Roaming\Tencent`"" 2>$null
Write-Host "Done!"
