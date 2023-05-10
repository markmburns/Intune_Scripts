#Some PowerShell snippets for automating Group Tags
Install-Module -name WindowsAutopilotIntune
Connect-MSGraph

get-autopilotdevice | where groupTag -EQ "" | Format-Table
Get-AutopilotDevice | where {(($_.model -eq "Latitude 5421") -or ($_.model -eq "Latitude 5420")) -and ($_.groupTag -eq "")} | Format-Table
Get-AutopilotDevice | where {(($_.model -eq "Latitude 5421") -or ($_.model -eq "Latitude 5420")) -and ($_.groupTag -eq "")} | Set-AutopilotDevice -groupTag "AAD"