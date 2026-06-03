# 自动推送 — 轻量，只在调用时运行
Set-Location f:\Stuff
git add -A
$changes = git status --porcelain
if ($changes) {
    $files = (git diff --cached --name-only | Measure-Object -Line).Lines
    git commit -m "chore: auto-sync $files files"
    git push origin main
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Pushed $files files"
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No changes"
}
