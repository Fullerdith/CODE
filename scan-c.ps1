Write-Host "=== C盘总容量 ==="
Get-PSDrive C | Select-Object Used, Free | Format-Table -AutoSize

Write-Host "`n=== 用户目录 Top10 ==="
Get-ChildItem "C:\Users\lenovo" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $dir = $_
    $size = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    [PSCustomObject]@{Name=$dir.Name; SizeMB=[math]::Round($size,1)}
} | Sort-Object SizeMB -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "`n=== AppData 子目录 ==="
Get-ChildItem "C:\Users\lenovo\AppData" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $parent = $_
    Write-Host "--- $($parent.Name) ---"
    Get-ChildItem $parent.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        [PSCustomObject]@{Folder=$_.Name; SizeMB=[math]::Round($size,1)}
    } | Sort-Object SizeMB -Descending | Select-Object -First 5 | Format-Table -AutoSize
}

Write-Host "`n=== C盘根目录 Top15 ==="
Get-ChildItem "C:\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $dir = $_
    $size = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    [PSCustomObject]@{Name=$dir.Name; SizeMB=[math]::Round($size,1)}
} | Sort-Object SizeMB -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "`n=== Temp 目录 ==="
$tempSize = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Temp: $([math]::Round($tempSize,1)) MB"

Write-Host "`n=== 微信/QQ 目录 ==="
$wechat = "C:\Users\lenovo\Documents\WeChat Files"
$qq = "C:\Users\lenovo\Documents\Tencent Files"
if (Test-Path $wechat) {
    $wcSize = (Get-ChildItem $wechat -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "WeChat Files: $([math]::Round($wcSize,1)) MB"
} else { Write-Host "WeChat Files: 不存在" }
if (Test-Path $qq) {
    $qqSize = (Get-ChildItem $qq -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "Tencent Files (QQ): $([math]::Round($qqSize,1)) MB"
} else { Write-Host "Tencent Files: 不存在" }

Write-Host "`n完成!"
