$ESPProcesses = Get-Process -Name 'wwahost' -ErrorAction 'SilentlyContinue'
if ($ESPProcesses.Count -eq 0) {
    Write-Host 'WWAHost is not running'
}