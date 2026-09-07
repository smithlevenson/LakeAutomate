# Run from an elevated PowerShell session.
$ErrorActionPreference = "Stop"

$TaskName = "LakeAutomate API"
$StartScript = "C:\Projects\LakeAutomate\scripts\Start-LakeAutomate.ps1"

if (-not (Test-Path $StartScript)) {
    throw "Startup script not found: $StartScript"
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$StartScript`""

$trigger = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -User "SYSTEM" `
    -RunLevel Highest `
    -Force | Out-Null

Get-ScheduledTask $TaskName |
    Select-Object TaskName, State
