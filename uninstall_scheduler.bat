@echo off
chcp 65001 >nul
title 校园网自动登录 - 卸载程序

echo ========================================
echo   校园网自动登录 - 卸载
echo ========================================
echo.

schtasks /delete /tn "CampusAutoLogin" /f

if %errorlevel% equ 0 (
    echo [成功] 开机自启任务已删除
) else (
    echo [提示] 任务不存在或已删除
)

echo.
echo 文件未删除，如需完全移除请手动删除：
echo   %~dp0auto_login.ps1
echo   %~dp0config.json
echo   %~dp0install_scheduler.bat
echo.
pause
