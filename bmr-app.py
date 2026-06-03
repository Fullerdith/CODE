"""
BMR Calculator - Desktop App
依赖: pip install pywebview pyinstaller
打包: pyinstaller --onefile --windowed --add-data "bmr-calculator.html;." bmr-app.py
"""
import os
import sys
import webview

# HTML 文件路径（支持 PyInstaller 打包后路径）
if getattr(sys, 'frozen', False):
    base = sys._MEIPASS
else:
    base = os.path.dirname(os.path.abspath(__file__))

html_path = os.path.join(base, 'bmr-calculator.html')

with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()

webview.create_window(
    '基础代谢计算器 BMR Calculator',
    html=html,
    width=480,
    height=720,
    resizable=True,
    text_select=True,
)
webview.start()
