# 自动推送 — 轻量，只在调用时运行
Set-Location f:\Stuff
git add -A
$changes = git status --porcelain
if ($changes) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "auto: $time"
    git push origin main
    Write-Host "[$time] Pushed to GitHub"
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No changes"
}
