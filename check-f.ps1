Write-Host "=== F:\APPDATA contents ==="
Get-ChildItem "F:\APPDATA" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $total = 0
    Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $total += $_.Length }
    $mb = [math]::Round($total / 1MB, 1)
    Write-Host "$($_.Name) : $mb MB"
}

Write-Host ""
$totalAll = 0
Get-ChildItem "F:\APPDATA" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $totalAll += $_.Length }
$gb = [math]::Round($totalAll / 1GB, 2)
Write-Host "Total on F: $gb GB"

Write-Host ""
Write-Host "=== .vscode check ==="
if (Test-Path "F:\APPDATA\.vscode") {
    $vs = 0
    Get-ChildItem "F:\APPDATA\.vscode" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $vs += $_.Length }
    Write-Host "F:\APPDATA\.vscode : $([math]::Round($vs/1MB,1)) MB"
} else {
    Write-Host ".vscode NOT on F: - need to copy"
}

Write-Host ""
Write-Host "=== C:\Users\lenovo\.vscode check ==="
if (Test-Path "C:\Users\lenovo\.vscode") {
    $attr = (Get-Item "C:\Users\lenovo\.vscode").Attributes
    Write-Host "Attributes: $attr"
    if ($attr -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "Already a junction!"
    } else {
        Write-Host "Still a real folder"
    }
} else {
    Write-Host "Not found on C:"
}
