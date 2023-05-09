#DCU Settings by registry
#mark_burns@dell.com

#Determine install path
$dcupath = (Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Update%'").InstallLocation
$dcuclipath = "$($path)dcu-cli.exe"
If(!(Test-Path $dcuclipath)){
    write-host "Could not find $($dcuclipath)"
    Exit 1
}else{
    Write-Host "Found $($dcuclipath)"
}
#Apply registry settings
WriteReg "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings\General" "MaxRetryAttempts" "DWORD" "3"
WriteReg "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings\Schedule" "ScheduleMode" "STRING" "Auto"
WriteReg "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings\UpdateFilter\UpdateType" "IsApplicationSelected" "DWORD" "0"
WriteReg "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings\UpdateFilter\UpdateType" "IsUtilitySelected" "DWORD" "0"
Remove-ItemProperty -path "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\Preferences\Settings\Schedule" -Name "AutomationMode" -Force

#Tag
WriteReg "HKLM:SOFTWARE\Dell\UpdateService\Clients\CommandUpdate\" "DCUSettings-Registry" "STRING" "1.0"


Function WriteReg ($key, $name, $type, $value){
    If(!(test-path $key)){
        New-Item -path $key -Force | Out-Null
    }
    Try{
        New-ItemProperty -path $key -name $name -propertytype $type -value $value -force -ErrorAction Continue | Out-Null
        Write-Host "Succeeded: $($key) $($name) $($value)"
    }catch{
        Write-host "Failed: $($key) $($name) $($value)"
    }
}