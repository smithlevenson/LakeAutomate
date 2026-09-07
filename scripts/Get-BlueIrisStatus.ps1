param(
    [string]$BaseUrl = $(if ($env:LAKE_BI_URL) { $env:LAKE_BI_URL } else { "http://10.2.0.100:81" }),
    [string]$User = $(if ($env:LAKE_BI_USER) { $env:LAKE_BI_USER } else { "LevWebUser" }),
    [string]$Password = $env:LAKE_BI_PASSWORD,
    [switch]$Raw
)

$ErrorActionPreference = "Stop"

function Get-PlainTextPassword {
    param([string]$ProvidedPassword)

    if ($ProvidedPassword) {
        return $ProvidedPassword
    }

    $secure = Read-Host "Blue Iris password for $User" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Invoke-BlueIrisJson {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Body
    )

    Invoke-RestMethod `
        -Uri "$BaseUrl/json" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Compress)
}

function Get-Md5Hex {
    param([Parameter(Mandatory = $true)][string]$Text)

    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
        $hash = $md5.ComputeHash($bytes)
        return -join ($hash | ForEach-Object { $_.ToString("x2") })
    }
    finally {
        $md5.Dispose()
    }
}

function Convert-ToNumber {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $match = [regex]::Match([string]$Value, '-?\d+(?:\.\d+)?')
    if (-not $match.Success) {
        return $null
    }

    return [double]::Parse(
        $match.Value,
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

function Parse-ClipsSummary {
    param([string]$Clips)

    $result = [ordered]@{
        clip_count       = $null
        storage_used_gb  = $null
        storage_limit_gb = $null
        disk_free_gb     = $null
    }

    if (-not $Clips) {
        return $result
    }

    $m = [regex]::Match(
        $Clips,
        'Clips:\s*(\d+)\s+items,\s*([0-9.]+)\/([0-9.]+)GB;\s*C:\s*\+([0-9.]+)GB',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if ($m.Success) {
        $result.clip_count = [int]$m.Groups[1].Value
        $result.storage_used_gb = [double]::Parse($m.Groups[2].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        $result.storage_limit_gb = [double]::Parse($m.Groups[3].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        $result.disk_free_gb = [double]::Parse($m.Groups[4].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return $result
}

$plainPassword = Get-PlainTextPassword -ProvidedPassword $Password

try {
    # Request a fresh challenge and consume it immediately. Blue Iris sessions can expire quickly.
    $challenge = Invoke-BlueIrisJson -Body @{ cmd = "login" }

    if (-not $challenge.session) {
        throw "Blue Iris did not return a login session challenge."
    }

    $session = [string]$challenge.session
    $responseHash = Get-Md5Hex -Text "$User`:$session`:$plainPassword"

    $login = Invoke-BlueIrisJson -Body @{
        cmd      = "login"
        session  = $session
        response = $responseHash
    }

    if ($login.result -ne "success") {
        $reason = if ($login.data.reason) { $login.data.reason } else { "unknown reason" }
        throw "Blue Iris login failed: $reason"
    }

    $status = Invoke-BlueIrisJson -Body @{
        cmd     = "status"
        session = $session
    }

    if ($status.result -ne "success") {
        $reason = if ($status.data.reason) { $status.data.reason } else { "unknown reason" }
        throw "Blue Iris status request failed: $reason"
    }

    if ($Raw) {
        $status.data | ConvertTo-Json -Depth 8
        exit 0
    }

    $d = $status.data
    $clips = Parse-ClipsSummary -Clips ([string]$d.clips)

    $normalized = [ordered]@{
        healthy            = ($d.warnings -eq 0)
        cpu_percent        = Convert-ToNumber $d.cpu
        gpu_percent        = Convert-ToNumber $d.gpu
        blueiris_ram_mb    = Convert-ToNumber $d.mem
        system_ram_percent = Convert-ToNumber $d.memload
        system_ram_total   = [string]$d.memphys
        uptime             = [string]$d.uptime
        connections        = [int]$d.cxns
        warnings           = [int]$d.warnings
        alerts             = [int]$d.alerts
        profile            = [int]$d.profile
        schedule           = [string]$d.schedule
        clip_count         = $clips.clip_count
        storage_used_gb    = $clips.storage_used_gb
        storage_limit_gb   = $clips.storage_limit_gb
        disk_free_gb       = $clips.disk_free_gb
        raw_clips_summary  = [string]$d.clips
        sampled_at         = (Get-Date).ToString("o")
        source             = "blueiris-json"
    }

    $normalized | ConvertTo-Json -Depth 5
}
finally {
    $plainPassword = $null
}
