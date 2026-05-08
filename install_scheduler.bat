@echo off
chcp 65001 >nul
title 校园网自动登录 - 安装程序

echo ========================================
echo   校园网自动登录 - 开机自启安装
echo ========================================
echo.

REM 检查配置文件
if not exist "%~dp0config.json" (
    echo [错误] 找不到 config.json
    echo 请先编辑 config.json 填入你的学号和密码
    pause
    exit /b 1
)

REM 检查脚本
if not exist "%~dp0auto_login.ps1" (
    echo [错误] 找不到 auto_login.ps1
    pause
    exit /b 1
)

echo [1/3] 请先编辑 config.json 填入你的校园网账号和密码
echo       按任意键继续...
pause >nul

echo [2/3] 注册开机自启任务...
schtasks /create /tn "CampusAutoLogin" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%~dp0auto_login.ps1\"" /sc onstart /delay 0000:30 /rl highest /f

if %errorlevel% neq 0 (
    echo [错误] 任务创建失败，请以管理员身份运行
    pause
    exit /b 1
)

echo [3/3] 测试运行...
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0auto_login.ps1"

echo.
echo ========================================
echo   安装完成！
echo.
echo   - 每次开机 30 秒后自动运行
echo   - 配置文件: config.json
echo   - 手动测试: 双击 auto_login.ps1
echo   - 卸载命令: schtasks /delete /tn CampusAutoLogin /f
echo ========================================
pause
