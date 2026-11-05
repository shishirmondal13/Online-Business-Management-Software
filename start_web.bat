@echo off
title Smart Buy Online Web Server
echo ========================================================
echo   Starting Smart Buy Online Web App (Local Server)
echo   URL: http://localhost:8080
echo ========================================================
cd /d "%~dp0build\web"
start http://localhost:8080
python -m http.server 8080
pause

