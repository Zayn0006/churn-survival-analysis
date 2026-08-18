@echo off
chcp 65001 >nul
title Jupyter - churn-survival-analysis
cd /d "%~dp0"
echo Starting Jupyter...
echo Browser will NOT open automatically. Copy the URL below into your browser.
echo.
.venv\Scripts\jupyter.exe notebook --no-browser --port=8888 --ServerApp.root_dir="%~dp0."
pause
