<# Remediate AppxProvisionedPackages Removal

#>
$apps = @(
    "Microsoft.GamingApp"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
)
ForEach ($app In $apps){
    Get-AppxProvisionedPackage -online | where displayname -eq $app | Remove-AppxProvisionedPackage -Online
    Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers   
}
