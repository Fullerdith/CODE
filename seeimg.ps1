# 保存剪贴板截图 + 调视觉识别
# 用法: 截图(Win+Shift+S) → 双击此脚本
Add-Type -AssemblyName System.Windows.Forms
$img = [Windows.Forms.Clipboard]::GetImage()
if ($img) {
    $path = "F:/Screenshots/clipboard.png"
    $img.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "已保存: $path"
    python f:/Stuff/vision.py $path
} else {
    Write-Host "剪贴板无图片，请先截图"
}
