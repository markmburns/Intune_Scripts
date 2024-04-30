<# Detect AppxProvisionedPackages for Removal

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

$exit = 0
$exitstring = "Detection Results"
ForEach ($app In $apps){
    If (get-appxprovisionedpackage -online | where displayname -eq $app){
        Write-Output "$($app) Installed"
        $exitstring = $exitstring + "`n$($app) Installed"
        $exit = 1
    } else{
        Write-Output "$($app) Not installed"
        $exitstring = $exitstring + "`n$($app) Not installed"
    }
}
$exitstring = $exitstring + "`nExiting with code $($exit)"
Write-Output $exitstring
Exit $exit
