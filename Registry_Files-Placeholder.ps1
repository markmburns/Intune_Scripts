<#

.DESCRIPTION
    
    Sets registry keys.
    Can be delivered via Intune as a powershell script for one-time deployment, or wrapped in an intunewin and treated as an app
    Dropping down files will need to be packaged as an app
    App detection rule can be single reg key, or use the detection script provided
    Requires admin
 
 
.NOTES  
    Mark.Burns@dell.com 
 
  
#>
 
BEGIN {}
 
PROCESS {
    try {
         #Files
         Copy-Item "$($PSScriptRoot)\Dell-Logo-2016.jpg" -Destination "$($env:windir)\Dell-Logo-2016.jpg" -Force
         Copy-Item "$($PSScriptRoot)\Placeholder Files" -Destination "$($env:HOMEDRIVE)\Dell\Placeholder Files\" -Recurse -Force

         #Registry
         New-Item -Path "HKLM:\SOFTWARE\DELL\Registry_Files-Placeholder" -Force
         New-ItemProperty -Path "HKLM:\SOFTWARE\DELL\Registry_Files-Placeholder" -Name "Placeholder" -PropertyType String -Value "123456" -Force
 
    } catch {
        $ErrorMessage = "Error: " + $_.Exception.Message
 
    }
        
}
 
END {}