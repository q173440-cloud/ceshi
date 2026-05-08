@echo off
title 校园网自动登录

set USER=17344086087
set PASS=888888
set SUFFIX=@dx
set "LOGIN_URL=http://10.2.255.26:801/eportal/?c=ACSetting&a=Login"
set TEST_URL=http://www.baidu.com

echo ========================================
echo       校园网自动登录脚本
echo ========================================
echo.
echo [*] 账号：%USER%%SUFFIX%
echo [*] 正在连接认证服务器...
echo.

curl -s -o nul -w "%%{http_code}" "%LOGIN_URL%" --data "DDDDD=%USER%%SUFFIX%&upass=%PASS%" > _login_tmp.txt
findstr "200" _login_tmp.txt > nul
del _login_tmp.txt

if %errorlevel% equ 0 (
    echo [OK] 登录请求已发送
) else (
    echo [!] 登录请求发送失败
)

timeout /t 1 /nobreak > nul

echo [*] 正在验证网络连通性...
echo.

curl -s -o nul -w "%%{http_code}" --connect-timeout 5 "%TEST_URL%" > _check_tmp.txt
findstr "200" _check_tmp.txt > nul
del _check_tmp.txt

if %errorlevel% equ 0 (
    echo ========================================
    echo       网络连接成功！
    echo ========================================
    echo.
    echo 账号：%USER%%SUFFIX%
    echo.
) else (
    echo [!] 网络验证失败
    echo [!] 可能的原因：
    echo     1. 账号或密码错误
    echo     2. 未连接到校园网
    echo     3. 运营商选择错误
    echo.
)

echo 按任意键退出...
pause > nul
