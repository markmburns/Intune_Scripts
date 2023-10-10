#Get the computer model (typically a vendor-specific range name)
$ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model).Model

#Get the PC system type (typically a desktop or laptop)
$SystemType = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object PCSystemType).PCSystemType

#Get the serial number and store the last 7 characters of it
$SerialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object SerialNumber).SerialNumber
$SerLast7 = $SerialNumber.SubString($SerialNumber.Length-7)

#Get the MAC address of the enabled NIC and store the last 6 characters of it
$MacAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IpEnabled='True'" | Select-Object MacAddress).MacAddress
$MacEscaped = $MacAddress.Replace(":", "")
$MacLast6 = $MacEscaped.SubString($MacEscaped.Length-6,6)

# Get the SMS task sequence object
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Set the computer name and AD OU location for desktop devices
if (($ComputerModel -match "Precision") -OR ($ComputerModel -match "Optiplex") -OR ($ComputerManufacturer -match "Lenovo" -And $SystemType -match "1"))
{
    $OSDComputerName = "PCD-" + $SerLast7
    $TSEnv.Value("OSDComputerName") = "$OSDComputerName"
    $OSDDomainOUName = "LDAP://OU=Desktops,OU=Workstations,OU=iResourcesLTW,DC=INT,DC=DIR,DC=WILLIS,DC=COM"
    $TSEnv.Value("OSDDomainOUName") = "$OSDDomainOUName"
}

# Set the computer name and AD OU location for mobile devices
if (($ComputerModel -like "*Latitude*") -OR ($ComputerManufacturer -match "Lenovo" -And $SystemType -match "2") -OR ($ComputerModel -match "Surface"))
{
    $OSDComputerName = "PCM-" + $SerLast7
    $TSEnv.Value("OSDComputerName") = "$OSDComputerName"
    $OSDDomainOUName = "LDAP://OU=Laptops,OU=Workstations,OU=iResourcesLTW,DC=INT,DC=DIR,DC=WILLIS,DC=COM"
    $TSEnv.Value("OSDDomainOUName") = "$OSDDomainOUName"
}

# Set the computer name and AD OU location for virtual devices
if (($ComputerModel -like "*Virtual*") -OR ($ComputerModel -match "VMware7,1")) {
    $OSDComputerName = "PCV-" + $MacLast6
    $TSEnv.Value("OSDComputerName") = "$OSDComputerName"
    $OSDDomainOUName = "LDAP://OU=Virtual Machines,OU=Workstations,OU=iResourcesLTW,DC=INT,DC=DIR,DC=WILLIS,DC=COM"
    $TSEnv.Value("OSDDomainOUName") = "$OSDDomainOUName"
}

# Define the device-specific BIOS password based on a SHA512 hash of the device name
$SaltedComputerName = "jfdireo" + $OSDComputerName.ToUpper() + "fhcer7ui88923"
$Hasher = [System.Security.Cryptography.HashAlgorithm]::Create("SHA512")
$HashBytes = $Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($SaltedComputerName))
$HashBytes12 = $HashBytes[0], $HashBytes[1], $HashBytes[2], $HashBytes[3], $HashBytes[4], $HashBytes[5], $HashBytes[6], $HashBytes[7], $HashBytes[8], $HashBytes[9], $HashBytes[10], $HashBytes[11]
$Password = ""
foreach($i in $HashBytes12) { $Password += [convert]::ToChar(97+ ($i % 26)) }
$Password = $Password.Substring(0,4) + "-" + $Password.Substring(4,4) + "-" + $Password.Substring(8,4)

# Set the BIOS password
Start-Process "cctk.exe" -ArgumentList "--setuppwd=$Password"