# 校园网自动登录脚本 (Dr.COM)
# 开机自动运行，检测断网后自动重连

$configPath = Join-Path $PSScriptRoot "config.json"

if (-not (Test-Path $configPath)) {
    Write-Host "[错误] 找不到配置文件 config.json" -ForegroundColor Red
    Write-Host "请先编辑 config.json 填入你的账号密码" -ForegroundColor Yellow
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$Username    = $config.username
$Password    = $config.password
$Carrier     = $config.carrier
$RetrySec    = $config.retryInterval

$LOGIN_URL  = "http://10.2.255.26/eportal/InterFace.do?method=login"
$TEST_URL   = "http://www.baidu.com"

$CARRIERS = @{ "1" = ""; "2" = "@dx"; "3" = "@lt"; "4" = "@mobile" }
$suffix = $CARRIERS[$Carrier]
if (-not $suffix) { $suffix = "" }
$fullUser = $Username + $suffix

Write-Host "[校园网自动登录] 用户: $fullUser" -ForegroundColor Cyan

function Test-Network {
    try {
        $req = [System.Net.WebRequest]::Create($TEST_URL)
        $req.Timeout = 5000
        $res = $req.GetResponse()
        $status = [int]$res.StatusCode
        $res.Close()
        return ($status -eq 200)
    } catch { return $false }
}

function Send-Login {
    $body = "DDDDD=$fullUser&upass=$Password&R1=0&R2=&R3=0&R6=0&para=00&0MKKey=123456"
    try {
        $web = New-Object System.Net.WebClient
        $resp = $web.UploadString($LOGIN_URL, "POST", $body)
        if ($resp -match "Dr.COMWebLoginID_3") { return $true }
        elseif ($resp -match "Dr.COMWebLoginID_2") { return $false }
        else { return $true }  # 可能已登录
    } catch { return $false }
}

# 主循环
$attempts = 0
while ($attempts -lt 10) {
    $attempts++
    $time = Get-Date -Format "HH:mm:ss"

    if (Test-Network) {
        Write-Host "[$time] 网络已连通 ✓" -ForegroundColor Green; exit 0
    }

    Write-Host "[$time] 未联网，正在登录..." -NoNewline
    if (Send-Login) {
        Write-Host " 成功 ✓" -ForegroundColor Green
        Start-Sleep 2
        if (Test-Network) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 网络已连通 ✓" -ForegroundColor Green; exit 0 }
    } else {
        Write-Host " 失败(请检查账号密码)" -ForegroundColor Red
    }

    Write-Host "[$time] ${RetrySec}秒后重试($attempts/10)"
    Start-Sleep $RetrySec
}

Write-Host "[失败] 重试次数耗尽，请检查网络或配置" -ForegroundColor Red
exit 1
