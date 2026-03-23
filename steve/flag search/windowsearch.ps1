# flag_finder.ps1
# search local readable files on Windows for common flag formats

param(
    [string]$SearchRoot = "", # optional root directory
    [string]$FlagRegex = 'FLAGS\{[^}]+\}|FLAG\{[^}]+\}|flag\{[^}]+\}|HTB\{[^}]+\}|THM\{[^}]+\}|picoCTF\{[^}]+\}|CTF\{[^}]+\}', # flag regex
    [int]$MaxDepth = 5, # recursion depth
    [int]$MaxFileSizeMB = 2 # max file size to scan
)

$ErrorActionPreference = "SilentlyContinue" # suppress non-fatal errors

# get primary IPv4
function Get-PrimaryIPv4 {
    try {
        $ip = Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.IPAddress -ne '127.0.0.1' -and
                $_.InterfaceAlias -notmatch 'Loopback|Virtual|VMware|vEthernet|Hyper-V'
            } |
            Select-Object -ExpandProperty IPAddress -First 1

        if ($ip) {
            return $ip
        } else {
            return "unknownip"
        }
    }
    catch {
        return "unknownip"
    }
}

# decide if file is likely text
function Test-LikelyTextFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $textExt = @(
        ".txt", ".log", ".conf", ".config", ".ini", ".xml", ".json", ".yaml", ".yml",
        ".csv", ".md", ".ps1", ".bat", ".env", ".py", ".php", ".aspx", ".js", ".sql"
    )

    $binExt = @(
        ".exe", ".dll", ".msi", ".zip", ".7z", ".jpg", ".png", ".pdf", ".mp4", ".iso", ".dat"
    )

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    if ($textExt -contains $ext) { return $true }
    if ($binExt -contains $ext)  { return $false }

    # fallback: look for null bytes
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $buffer = New-Object byte[] 512
            $read = $stream.Read($buffer, 0, 512)

            for ($i = 0; $i -lt $read; $i++) {
                if ($buffer[$i] -eq 0) {
                    return $false
                }
            }

            return $true
        }
        finally {
            $stream.Close()
        }
    }
    catch {
        return $false
    }
}

# write to screen and file
function Write-Log {
    param([string]$Message)
    Write-Host $Message
    Add-Content -Path $script:OutFile -Value $Message
}

# setup output
$hostIP = Get-PrimaryIPv4
$safeIP = $hostIP -replace '\.', '_'
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = Join-Path (Get-Location) "flag_results"

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$script:OutFile = Join-Path $outDir "flags_${safeIP}_${timestamp}.txt"

# resolve target dirs
$targetDirs = New-Object System.Collections.Generic.List[string]

if ($SearchRoot -and (Test-Path -LiteralPath $SearchRoot -PathType Container)) {
    $targetDirs.Add((Resolve-Path -LiteralPath $SearchRoot).Path)
}
else {
    $defaults = @(
        $env:USERPROFILE,
        "$env:USERPROFILE\Documents",
        "$env:TEMP",
        "C:\Users\Public",
        "C:\inetpub\wwwroot",
        "C:\Windows\Temp"
    )

    foreach ($p in $defaults) {
        if ($p -and (Test-Path -LiteralPath $p -PathType Container)) {
            $targetDirs.Add((Resolve-Path -LiteralPath $p).Path)
        }
    }
}

Write-Host "[*] Target IP: $hostIP"
Write-Host "[*] Targets: $($targetDirs -join ', ')"
Write-Host "[*] Regex: $FlagRegex"
Write-Host "[*] Output: $script:OutFile"
Write-Host ""

$filesScanned = 0
$matchCount = 0

Write-Log "[*] Starting content search..."

foreach ($dir in ($targetDirs | Select-Object -Unique)) {
    Write-Log "[*] Searching: $dir"

    Get-ChildItem -LiteralPath $dir -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_.FullName
        $filesScanned++

        # skip empty or oversized files
        if ($_.Length -le 0) { return }
        if ($_.Length -gt ($MaxFileSizeMB * 1MB)) { return }

        # only scan likely text files
        if (Test-LikelyTextFile -Path $file) {
            Select-String -LiteralPath $file -Pattern $FlagRegex -AllMatches -ErrorAction SilentlyContinue | ForEach-Object {
                foreach ($hit in $_.Matches) {
                    Write-Log "[FOUND] $file :: $($hit.Value)"
                    $matchCount++
                }
            }
        }
    }

    Write-Log ""
}

Write-Log "[*] Done. Scanned $filesScanned files. Found $matchCount flags."