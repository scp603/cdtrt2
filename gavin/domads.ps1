# ============================================================
#  Add-DomainAdmins.ps1
#  Creates 200 Domain Admin accounts in Active Directory.
#  5 usernames will be "cyberrange"-adjacent.
#  Passwords are random but human-readable (word+digits+symbol).
#  Prints a full credential table at the end.
# ============================================================

#Requires -Module ActiveDirectory

# ── Configuration ────────────────────────────────────────────
$OU            = "OU=Users,DC=yourdomain,DC=local"   # <-- Change to your target OU
$DomainAdmins  = "Domain Admins"
$TotalUsers    = 200
$CyberCount    = 5   # how many "cyberrange-like" names to include

# ── Readable password word lists ─────────────────────────────
$Adjectives = @(
    "Amber","Breezy","Clever","Daring","Eager","Fierce","Golden","Happy",
    "Icy","Jolly","Keen","Lively","Mighty","Noble","Orange","Peppy",
    "Quick","Rapid","Sunny","Tidy","Ultra","Vivid","Witty","Xenial",
    "Young","Zesty","Brave","Calm","Dark","Epic","Fancy","Giant",
    "Heavy","Iron","Jazzy","Kinky","Lunar","Mystic","Neon","Onyx",
    "Prime","Quiet","Royal","Sharp","Turbo","Ultra","Velvet","Warm"
)

$Nouns = @(
    "Falcon","Tiger","Storm","Raven","Cobra","Phoenix","Dragon","Shadow",
    "Blaze","Frost","Eagle","Viper","Lynx","Panda","Wolf","Hawk",
    "Bear","Shark","Moose","Bison","Crane","Finch","Gecko","Hyena",
    "Ibis","Jackal","Koala","Lemur","Mamba","Newt","Otter","Puffin",
    "Quail","Robin","Skunk","Tapir","Urchin","Vole","Wasp","Xerus",
    "Yak","Zebra","Ant","Bat","Crab","Deer","Elk","Fox"
)

$Symbols = @("!","@","#","$","%","^","&","*")

# ── Username pools ────────────────────────────────────────────

# 5 cyberrange-adjacent names (cannot be exactly "cyberrange")
$CyberNames = @(
    "cyberRange01",
    "cyber_range",
    "cyberranger",
    "thecyberrange",
    "cyberrangeOps"
)

# Generic first/last name pools for the remaining 195 users
$FirstNames = @(
    "James","Mary","John","Patricia","Robert","Jennifer","Michael","Linda",
    "William","Barbara","David","Elizabeth","Richard","Susan","Joseph","Jessica",
    "Thomas","Sarah","Charles","Karen","Christopher","Lisa","Daniel","Nancy",
    "Matthew","Betty","Anthony","Margaret","Mark","Sandra","Donald","Ashley",
    "Steven","Dorothy","Paul","Kimberly","Andrew","Emily","Kenneth","Donna",
    "George","Michelle","Joshua","Carol","Kevin","Amanda","Brian","Melissa",
    "Edward","Deborah","Ronald","Stephanie","Timothy","Rebecca","Jason","Sharon",
    "Jeffrey","Laura","Ryan","Cynthia","Jacob","Kathleen","Gary","Amy",
    "Nicholas","Angela","Eric","Shirley","Jonathan","Anna","Stephen","Brenda",
    "Larry","Pamela","Justin","Emma","Scott","Nicole","Brandon","Helen",
    "Benjamin","Samantha","Samuel","Katherine","Raymond","Christine","Gregory","Debra",
    "Frank","Rachel","Alexander","Carolyn","Patrick","Janet","Jack","Catherine"
)

$LastNames = @(
    "Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis",
    "Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas",
    "Taylor","Moore","Jackson","Martin","Lee","Perez","Thompson","White",
    "Harris","Sanchez","Clark","Ramirez","Lewis","Robinson","Walker","Young",
    "Allen","King","Wright","Scott","Torres","Nguyen","Hill","Flores",
    "Green","Adams","Nelson","Baker","Hall","Rivera","Campbell","Mitchell",
    "Carter","Roberts","Phillips","Evans","Turner","Torres","Parker","Collins",
    "Edwards","Stewart","Flores","Morris","Nguyen","Murphy","Rivera","Cook",
    "Rogers","Morgan","Peterson","Cooper","Reed","Bailey","Bell","Gomez",
    "Kelly","Howard","Ward","Cox","Diaz","Richardson","Wood","Watson",
    "Brooks","Bennett","Gray","James","Reyes","Cruz","Hughes","Price",
    "Myers","Long","Foster","Sanders","Ross","Morales","Powell","Sullivan"
)

# ── Helper functions ──────────────────────────────────────────

function New-ReadablePassword {
    $adj    = $Adjectives | Get-Random
    $noun   = $Nouns      | Get-Random
    $digits = "{0:D2}" -f (Get-Random -Minimum 10 -Maximum 99)
    $sym    = $Symbols    | Get-Random
    return "$adj$noun$digits$sym"
}

function New-UniqueUsername {
    param(
        [string]$First,
        [string]$Last,
        [System.Collections.Generic.HashSet[string]]$Taken
    )
    # Strategies: flast, f.last, firstl, first.last, flastNN
    $base1 = ($First[0] + $Last).ToLower() -replace '\s',''
    $base2 = ($First[0] + "." + $Last).ToLower() -replace '\s',''
    $base3 = ($First + $Last[0]).ToLower() -replace '\s',''
    $base4 = ($First + "." + $Last).ToLower() -replace '\s',''

    foreach ($candidate in @($base1,$base2,$base3,$base4)) {
        if (-not $Taken.Contains($candidate)) { return $candidate }
    }
    # fallback: append random number
    do {
        $candidate = $base1 + (Get-Random -Minimum 2 -Maximum 999)
    } while ($Taken.Contains($candidate))
    return $candidate
}

# ── Build the full user list ──────────────────────────────────
$UsersToCreate = [System.Collections.Generic.List[PSCustomObject]]::new()
$TakenUsernames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# Add the 5 cyberrange-like accounts
foreach ($cn in $CyberNames) {
    $password = New-ReadablePassword
    $UsersToCreate.Add([PSCustomObject]@{
        Username    = $cn
        Password    = $password
        DisplayName = $cn
        GivenName   = "Cyber"
        Surname     = "Range"
    })
    [void]$TakenUsernames.Add($cn)
}

# Add remaining 195 generic accounts
$remaining = $TotalUsers - $CyberCount
for ($i = 0; $i -lt $remaining; $i++) {
    $first    = $FirstNames | Get-Random
    $last     = $LastNames  | Get-Random
    $username = New-UniqueUsername -First $first -Last $last -Taken $TakenUsernames
    [void]$TakenUsernames.Add($username)

    $UsersToCreate.Add([PSCustomObject]@{
        Username    = $username
        Password    = (New-ReadablePassword)
        DisplayName = "$first $last"
        GivenName   = $first
        Surname     = $last
    })
}

# ── Create users in AD ────────────────────────────────────────
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

Write-Host "`n[*] Creating $TotalUsers Domain Admin accounts...`n" -ForegroundColor Cyan

foreach ($u in $UsersToCreate) {
    $securePass = ConvertTo-SecureString $u.Password -AsPlainText -Force

    try {
        New-ADUser `
            -SamAccountName   $u.Username `
            -UserPrincipalName "$($u.Username)@yourdomain.local" `
            -Name              $u.DisplayName `
            -GivenName         $u.GivenName `
            -Surname           $u.Surname `
            -DisplayName       $u.DisplayName `
            -AccountPassword   $securePass `
            -PasswordNeverExpires $true `
            -Enabled           $true `
            -Path              $OU `
            -ErrorAction Stop

        Add-ADGroupMember -Identity $DomainAdmins -Members $u.Username -ErrorAction Stop

        $status = "OK"
        Write-Host "  [+] $($u.Username)" -ForegroundColor Green
    }
    catch {
        $status = "FAILED: $_"
        Write-Host "  [-] $($u.Username) — $status" -ForegroundColor Red
    }

    $Results.Add([PSCustomObject]@{
        Username = $u.Username
        Password = $u.Password
        Status   = $status
    })
}

# ── Print full credential table ───────────────────────────────
Write-Host "`n`n============================================================" -ForegroundColor Yellow
Write-Host "  CREDENTIAL DUMP — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

$colW = 30
Write-Host ("{0,-$colW} {1,-35} {2}" -f "USERNAME","PASSWORD","STATUS") -ForegroundColor Cyan
Write-Host ("{0,-$colW} {1,-35} {2}" -f "--------","--------","------") -ForegroundColor Cyan

foreach ($r in $Results) {
    $color = if ($r.Status -eq "OK") { "White" } else { "Red" }
    Write-Host ("{0,-$colW} {1,-35} {2}" -f $r.Username, $r.Password, $r.Status) -ForegroundColor $color
}

Write-Host "`n[*] Done. $($Results.Where({$_.Status -eq 'OK'}).Count)/$TotalUsers accounts created successfully." -ForegroundColor Cyan

# ── Optional: export to CSV ───────────────────────────────────
# $Results | Export-Csv -Path ".\domain_admins_creds.csv" -NoTypeInformation
# Write-Host "[*] Credentials saved to domain_admins_creds.csv" -ForegroundColor Cyan
