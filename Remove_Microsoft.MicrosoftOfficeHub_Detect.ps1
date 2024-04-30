<# Detect AppxProvisionedPackage Removal

#>
$app = "Microsoft.MicrosoftOfficeHub"
If (get-appxprovisionedpackage -online | where displayname -eq $app){
    Write-Output "Installed"
    Exit 1
} else{
    Write-Output "Not installed"
    Exit 0
}