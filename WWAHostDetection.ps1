<# 
    WWAHostDetection.ps1
    mark.burns@dell.com

    Custom requirement rule for Win32 applications
    Use for apps incompatible with Autopilot ESP, such as those requiring user interaction or reconfiguring network
    Add as additional script requirement with string output equals WWAHost is not running
    Applications will be marked not-applicable until next boot, and will not break ESP

#>
$ESPProcesses = Get-Process -Name 'wwahost' -ErrorAction 'SilentlyContinue'
if ($ESPProcesses.Count -eq 0) {
    Write-Host 'WWAHost is not running'
}
