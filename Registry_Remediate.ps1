#Remediation template for remediating a key
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$Name = "UseWUServer"
$Type = "DWORD"
$Value = 0

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value