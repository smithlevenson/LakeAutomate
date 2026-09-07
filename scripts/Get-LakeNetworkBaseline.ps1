$ErrorActionPreference = "Continue"

$RepoRoot = "C:\Projects\LakeAutomate"
$OutputDir = Join-Path $RepoRoot "docs\network"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$OutputFile = Join-Path $OutputDir "baseline-$Timestamp.txt"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Write-Section {
    param([string]$Title)

    Add-Content $OutputFile ""
    Add-Content $OutputFile ("=" * 80)
    Add-Content $OutputFile $Title
    Add-Content $OutputFile ("=" * 80)
}

"LevLake Network Baseline" | Set-Content $OutputFile
"Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $OutputFile
"Computer: $env:COMPUTERNAME" | Add-Content $OutputFile
"User: $env:USERNAME" | Add-Content $OutputFile

Write-Section "SYSTEM"
Get-ComputerInfo |
    Select-Object WindowsProductName,
                  WindowsVersion,
                  OsBuildNumber,
                  CsManufacturer,
                  CsModel |
    Format-List |
    Out-String |
    Add-Content $OutputFile

Write-Section "NETWORK ADAPTERS"
Get-NetAdapter |
    Sort-Object InterfaceIndex |
    Select-Object Name,
                  InterfaceDescription,
                  Status,
                  MacAddress,
                  LinkSpeed,
                  InterfaceIndex |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "IP CONFIGURATION"
Get-NetIPConfiguration -Detailed |
    Format-List |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "IP ADDRESSES"
Get-NetIPAddress |
    Sort-Object InterfaceIndex, AddressFamily |
    Select-Object InterfaceAlias,
                  InterfaceIndex,
                  AddressFamily,
                  IPAddress,
                  PrefixLength,
                  PrefixOrigin,
                  AddressState |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "DEFAULT ROUTES"
Get-NetRoute |
    Where-Object {
        $_.DestinationPrefix -in @("0.0.0.0/0", "::/0")
    } |
    Sort-Object RouteMetric |
    Select-Object InterfaceAlias,
                  DestinationPrefix,
                  NextHop,
                  RouteMetric,
                  InterfaceMetric |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "DNS CONFIGURATION"
Get-DnsClientServerAddress |
    Where-Object { $_.ServerAddresses.Count -gt 0 } |
    Select-Object InterfaceAlias,
                  AddressFamily,
                  ServerAddresses |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "DNS SUFFIX / CLIENT SETTINGS"
Get-DnsClient |
    Select-Object InterfaceAlias,
                  ConnectionSpecificSuffix,
                  RegisterThisConnectionsAddress,
                  UseSuffixWhenRegistering |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "DHCP STATUS"
Get-NetIPInterface |
    Select-Object InterfaceAlias,
                  AddressFamily,
                  Dhcp,
                  ConnectionState,
                  InterfaceMetric |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "ARP / NEIGHBOR TABLE"
Get-NetNeighbor |
    Where-Object {
        $_.AddressFamily -eq "IPv4" -and
        $_.State -ne "Unreachable"
    } |
    Sort-Object IPAddress |
    Select-Object InterfaceAlias,
                  IPAddress,
                  LinkLayerAddress,
                  State |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "ROUTE TABLE"
route print |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "IPCONFIG /ALL"
ipconfig /all |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "WIFI"
try {
    netsh wlan show interfaces |
        Out-String -Width 220 |
        Add-Content $OutputFile

    netsh wlan show drivers |
        Out-String -Width 220 |
        Add-Content $OutputFile
}
catch {
    "Wi-Fi information unavailable." | Add-Content $OutputFile
}

Write-Section "TAILSCALE"
if (Get-Command tailscale -ErrorAction SilentlyContinue) {
    tailscale status |
        Out-String -Width 220 |
        Add-Content $OutputFile

    ""
    "TAILSCALE IP:"
    tailscale ip |
        Out-String -Width 220 |
        Add-Content $OutputFile

    ""
    "TAILSCALE NETCHECK:"
    tailscale netcheck |
        Out-String -Width 220 |
        Add-Content $OutputFile
}
else {
    "Tailscale command not found." | Add-Content $OutputFile
}

Write-Section "LISTENING TCP PORTS"
Get-NetTCPConnection -State Listen |
    Sort-Object LocalPort |
    Select-Object LocalAddress,
                  LocalPort,
                  OwningProcess |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "RUNNING NETWORK-RELATED SERVICES"
Get-Service |
    Where-Object {
        $_.Status -eq "Running" -and
        $_.Name -match "tailscale|dns|dhcp|ssh|mqtt|mosquitto"
    } |
    Select-Object Status,
                  Name,
                  DisplayName |
    Format-Table -AutoSize |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "NETWORK PROFILE"
Get-NetConnectionProfile |
    Format-List |
    Out-String -Width 220 |
    Add-Content $OutputFile

Write-Section "PUBLIC INTERNET TEST"
try {
    Test-NetConnection 1.1.1.1 -Port 443 |
        Format-List |
        Out-String -Width 220 |
        Add-Content $OutputFile
}
catch {
    "Internet connectivity test failed." | Add-Content $OutputFile
}

Write-Section "LOCAL GATEWAY TEST"

$Gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
    Sort-Object RouteMetric |
    Select-Object -First 1 -ExpandProperty NextHop

"Detected gateway: $Gateway" | Add-Content $OutputFile

if ($Gateway) {
    Test-Connection $Gateway -Count 4 |
        Format-Table -AutoSize |
        Out-String -Width 220 |
        Add-Content $OutputFile
}

Write-Host ""
Write-Host "Baseline complete:"
Write-Host $OutputFile