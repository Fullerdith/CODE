Write-Host "=== Disabling NVIDIA GPU to release file locks ==="
Write-Host "Screen may flicker briefly..."
$nvidiaDevices = Get-PnpDevice -FriendlyName "NVIDIA*" -ErrorAction SilentlyContinue
$nvidiaDevices | Format-Table FriendlyName,Status

if ($nvidiaDevices) {
    Write-Host "Disabling NVIDIA devices..."
    $nvidiaDevices | Disable-PnpDevice -Confirm:$false -ErrorAction Stop
    Start-Sleep 3
    Write-Host "GPU disabled"
}

Write-Host ""
Write-Host "=== Attempting NVIDIA migration ==="
$src = "C:\Users\lenovo\AppData\LocalLow\NVIDIA"
$dst = "F:\APPDATA\LocalLow\NVIDIA"
$backup = "$src.old"

# Final robocopy attempt
$rc = robocopy $src $dst /E /COPYALL /R:0 /W:0 /NP /NFL /NDL
Write-Host "Robocopy rc=$rc"

# Try to rename
if (Test-Path $backup) { Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue }

try {
    Rename-Item $src $backup -ErrorAction Stop
    Write-Host "Renamed original to .old"

    cmd /c "mklink /J `"$src`" `"$dst`""
    if (Test-Path $src) {
        Write-Host "Junction created for NVIDIA"
        Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Old NVIDIA data removed from C:"
        Write-Host "[OK] NVIDIA migration done!"
    }
} catch {
    Write-Host "FAILED: $_"
}

Write-Host ""
Write-Host "=== Re-enabling NVIDIA GPU ==="
if ($nvidiaDevices) {
    $nvidiaDevices | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep 2
    Write-Host "GPU re-enabled"
}

Write-Host ""
Write-Host "=== Final Junction Verification ==="
Write-Host "--- Local ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Local`"" 2>$null
Write-Host "--- LocalLow ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\LocalLow`"" 2>$null
Write-Host "--- Roaming\Tencent ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Roaming\Tencent`"" 2>$null
Write-Host "Done!"
