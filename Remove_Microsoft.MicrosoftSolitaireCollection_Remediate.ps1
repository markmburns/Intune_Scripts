<# Remediate AppxProvisionedPackage Removal

#>
$app = "Microsoft.MicrosoftSolitaireCollection"
Get-AppxProvisionedPackage -online | where displayname -eq $app | Remove-AppxProvisionedPackage -Online
Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers