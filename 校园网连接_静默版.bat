@echo off
REM 校园网静默自动登录脚本（适合放在开机启动项）

set USER=17344086087
set PASS=888888
set SUFFIX=@dx
set "LOGIN_URL=http://10.2.255.26:801/eportal/?c=ACSetting&a=Login"

curl -s -o nul "http://www.baidu.com" --connect-timeout 3
if %errorlevel% equ 0 (
    exit /b
)

curl -s -o nul "%LOGIN_URL%" --data "DDDDD=%USER%%SUFFIX%&upass=%PASS%"
if %errorlevel% equ 0 (
    echo [%date% %time%] 登录成功 >> "%USERPROFILE%\campus_login.log"
)
