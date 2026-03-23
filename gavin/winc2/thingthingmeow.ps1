#Requires -Module ActiveDirectory
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates 10 Domain Admin accounts in Active Directory.
.DESCRIPTION
    Creates specified admin accounts, adds them to Domain Admins group,
    and logs all actions. Requires the ActiveDirectory module and
    Domain Admin privileges to run.
#>

# ── Configuration ──────────────────────────────────────────────────────────────

$LogFile   = "C:\Logs\DA_Creation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$OUPath    = "OU=Admin Accounts,DC=yourdomain,DC=com"   # <-- update this
$Domain    = (Get-ADDomain).DNSRoot

# Define the 10 accounts (customise as needed)
$AdminAccounts = @(
    @{ SamAccountName = "da_admin01"; GivenName = "Admin"; Surname = "01"; Description = "Domain Admin 01" },
    @{ SamAccountName = "da_admin02"; GivenName = "Admin"; Surname = "02"; Description = "Domain Admin 02" },
    @{ SamAccountName = "da_admin03"; GivenName = "Admin"; Surname = "03"; Description = "Domain Admin 03" },
    @{ SamAccountName = "da_admin04"; GivenName = "Admin"; Surname = "04"; Description = "Domain Admin 04" },
    @{ SamAccountName = "da_admin05"; GivenName = "Admin"; Surname = "05"; Description = "Domain Admin 05" },
    @{ SamAccountName = "da_admin06"; GivenName = "Admin"; Surname = "06"; Description = "Domain Admin 06" },
    @{ SamAccountName = "da_admin07"; GivenName = "Admin"; Surname = "07"; Description = "Domain Admin 07" },
    @{ SamAccountName = "da_admin08"; GivenName = "Admin"; Surname = "08"; Description = "Domain Admin 08" },
    @{ SamAccountName = "da_admin09"; GivenName = "Admin"; Surname = "09"; Description = "Domain Admin 09" },
    @{ SamAccountName = "da_admin10"; GivenName = "Admin"; Surname = "10"; Description = "Domain Admin 10" }
)

# ── Helpers ────────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $Entry -ForegroundColor $(if ($Level -eq "ERROR") {"Red"} elseif ($Level -eq "WARN") {"Yellow"} else {"Cyan"})
    Add-Content -Path $LogFile -Value $Entry
}

function New-SecureRandomPassword {
    # Generates a 24-char password meeting complexity requirements
    $Chars   = 'abcdefghijkmnopqrstuvwxyz'
    $Upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $Digits  = '23456789'
    $Special = '!@#$%^&*()-_=+'
    $All     = $Chars + $Upper + $Digits + $Special

    $Password  = ($Upper   | Get-Random -Count 2) -join ''
    $Password += ($Digits  | Get-Random -Count 2) -join ''
    $Password += ($Special | Get-Random -Count 2) -join ''
    $Password += (-join ((1..18) | ForEach-Object { $All[(Get-Random -Maximum $All.Length)] }))

    # Shuffle
    return -join ($Password.ToCharArray() | Get-Random -Count $Password.Length)
}

# ── Pre-flight checks ──────────────────────────────────────────────────────────

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
Write-Log "Script started by: $($env:USERDOMAIN)\$($env:USERNAME)"
Write-Log "Target domain   : $Domain"
Write-Log "Target OU       : $OUPath"

# Verify OU exists
try {
    Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop | Out-Null
    Write-Log "OU verified OK."
} catch {
    Write-Log "OU '$OUPath' not found. Please update the OUPath variable." "ERROR"
    exit 1
}

$DomainAdminsGroup = "Domain Admins"
$Results           = [System.Collections.Generic.List[PSCustomObject]]::new()

# ── Main loop ──────────────────────────────────────────────────────────────────

foreach ($Account in $AdminAccounts) {
    $Sam = $Account.SamAccountName
    $UPN = "$Sam@$Domain"

    Write-Log "Processing: $Sam"

    # Skip if already exists
    if (Get-ADUser -Filter { SamAccountName -eq $Sam } -ErrorAction SilentlyContinue) {
        Write-Log "  SKIPPED — account '$Sam' already exists." "WARN"
        $Results.Add([PSCustomObject]@{ Account = $Sam; Status = "Skipped (exists)"; Password = "N/A" })
        continue
    }

    try {
        $PlainPassword  = New-SecureRandomPassword
        $SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force

        # Create the user
        $NewUserParams = @{
            SamAccountName        = $Sam
            UserPrincipalName     = $UPN
            GivenName             = $Account.GivenName
            Surname               = $Account.Surname
            DisplayName           = "$($Account.GivenName) $($Account.Surname)"
            Description           = $Account.Description
            AccountPassword       = $SecurePassword
            Path                  = $OUPath
            Enabled               = $true
            PasswordNeverExpires  = $false
            ChangePasswordAtLogon = $true   # Force reset on first login
        }

        New-ADUser @NewUserParams
        Write-Log "  Created user: $Sam"

        # Add to Domain Admins
        Add-ADGroupMember -Identity $DomainAdminsGroup -Members $Sam
        Write-Log "  Added '$Sam' to '$DomainAdminsGroup'"

        $Results.Add([PSCustomObject]@{
            Account  = $Sam
            Status   = "Created & added to Domain Admins"
            Password = $PlainPassword   # store securely — see note below
        })

    } catch {
        Write-Log "  FAILED for '$Sam': $_" "ERROR"
        $Results.Add([PSCustomObject]@{ Account = $Sam; Status = "FAILED: $_"; Password = "N/A" })
    }
}

# ── Summary ────────────────────────────────────────────────────────────────────

Write-Log "─── Summary ───────────────────────────────────────────"
$Results | ForEach-Object { Write-Log "  $($_.Account) → $($_.Status)" }
Write-Log "Script completed."

# Export results (passwords in plaintext here — pipe to a vault in production!)
$CsvPath = "C:\Logs\DA_Accounts_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$Results | Export-Csv -Path $CsvPath -NoTypeInformation
Write-Host "`nResults exported to: $CsvPath" -ForegroundColor Green
Write-Host "Log file         at: $LogFile"   -ForegroundColor Green
