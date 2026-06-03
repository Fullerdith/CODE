$files = @('C:\hiberfil.sys', 'C:\pagefile.sys', 'C:\swapfile.sys')
foreach ($f in $files) {
    if (Test-Path $f) {
        $size = [math]::Round((Get-Item $f).Length / 1GB, 2)
        Write-Host "$f : $size GB"
    } else { Write-Host "$f : NOT FOUND" }
}

Write-Host ""
Write-Host "=== WeChat Files ==="
$w = "C:\Users\lenovo\Documents\WeChat Files"
if (Test-Path $w) {
    $ws = [math]::Round((Get-ChildItem $w -Recurse -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    Write-Host "Size: $ws GB"
    Get-ChildItem $w -Directory | ForEach-Object { Write-Host "  - $($_.Name)" }
} else { Write-Host "Not found" }

Write-Host ""
Write-Host "=== Tencent Documents ==="
$t = "C:\Users\lenovo\Documents\Tencent Files"
if (Test-Path $t) {
    $ts = [math]::Round((Get-ChildItem $t -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    Write-Host "Tencent Files: $ts GB"
} else { Write-Host "Not found" }

Write-Host ""
Write-Host "=== Roaming Tencent Top5 ==="
Get-ChildItem "C:\Users\lenovo\AppData\Roaming\Tencent" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = [math]::Round((Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "$($_.Name) : $size MB"
}
