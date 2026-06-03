Write-Host "=== Running Processes ==="
$procs = @("WeChat", "QQ", "Steam", "QQMusic", "QQLive", "NVIDIA Share", "jetbrains")
foreach ($p in $procs) {
    $running = Get-Process -Name $p -ErrorAction SilentlyContinue
    if ($running) { Write-Host "WARNING: $p is running - MUST close before migration!" }
    else { Write-Host "OK: $p not running" }
}

Write-Host ""
Write-Host "=== Local Microsoft subdirs ==="
Get-ChildItem "C:\Users\lenovo\AppData\Local\Microsoft" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = [math]::Round((Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "$($_.Name) : $size MB"
}

Write-Host ""
Write-Host "=== F Drive ==="
if (Test-Path "F:\") {
    $fFree = [math]::Round((Get-PSDrive F).Free / 1GB, 1)
    Write-Host "F drive free: $fFree GB"
} else {
    Write-Host "F drive NOT FOUND!"
}
