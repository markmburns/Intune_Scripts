<#
Detect whether Files/Registry items all exist
 
#>

 function Test-RegistryValue {

param (

 [parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Path,

[parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Value
)

try {

Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
 return $true
 }

catch {

return $false

}

}



$a = Test-Path "$($env:windir)\Dell-Logo-2016.jpg"
$b = Test-Path "$($env:HOMEDRIVE)\Dell\Placeholder Files\"
$c = Test-RegistryValue -Path "HKLM:\SOFTWARE\DELL\Registry_Files-Placeholder" -Value "Placeholder"
If ($a -and $b -and $c){Write-Output "All prerequisites exist"}


