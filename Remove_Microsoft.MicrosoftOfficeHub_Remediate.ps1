<# Remediate AppxProvisionedPackage Removal

#>
$app = "Microsoft.MicrosoftOfficeHub"
Get-AppxProvisionedPackage -online | where displayname -eq $app | Remove-AppxProvisionedPackage -Online
Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers