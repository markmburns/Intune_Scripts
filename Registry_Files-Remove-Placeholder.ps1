<#

.DESCRIPTION
    Uninstall
   
 
 
.NOTES  
    Mark.Burns@dell.com 
 
  
#>
 BEGIN {}
 
PROCESS {
    try {

         #Files
         Remove-Item "$($env:windir)\Dell-Logo-2016.jpg" -Force
         Remove-Item "$($env:HOMEDRIVE)\Dell\Placeholder Files\" -Recurse -Force

         #Registry
         Remove-ItemProperty -Path "HKLM:\SOFTWARE\DELL\Registry_Files-Placeholder" -Name "Placeholder" -Force

    } catch {
        $ErrorMessage = "Error: " + $_.Exception.Message
 
    }
        
}
 
END {}