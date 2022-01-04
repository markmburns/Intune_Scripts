<#

.DESCRIPTION
    
    TEMPLATE
    Sets registry keys.
    Can be delivered via Intune as a powershell script for one-time deployment, or wrapped in an intunewin and treated as an app
    Dropping down files will need to be packaged as an app
    App detection rule can be single reg key, or use the detection script provided
    Requires admin
 
    TCS AllowedBuses
    AllowedBuses key to enabled BitLocker
 
.NOTES  
    Mark.Burns@dell.com 
 
  
#>
 
BEGIN {}
 
PROCESS {
    try {
         #Files
         # Copy-Item "$($PSScriptRoot)\Dell-Logo-2016.jpg" -Destination "$($env:windir)\Dell-Logo-2016.jpg" -Force
         # Copy-Item "$($PSScriptRoot)\Placeholder Files" -Destination "$($env:HOMEDRIVE)\Dell\Placeholder Files\" -Recurse -Force

         #Registry
         # New-Item -Path "HKLM:\SOFTWARE\DELL\Registry_Files-Placeholder" -Force
         New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses" -Name "Intel(R) LPC Controller (Q570) - 4384" -PropertyType String -Value "PCI\\VEN_8086&DEV_4384" -Force
 
    } catch {
        $ErrorMessage = "Error: " + $_.Exception.Message
 
    }
        
}
 
END {}