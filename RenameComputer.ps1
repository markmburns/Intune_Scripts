
<#PSScriptInfo

.VERSION 1.2

.GUID 3b42d8c8-cda5-4411-a623-90d812a8e29e

.AUTHOR Michael Niehaus
.Additions: mark_burns@dell.com

.COMPANYNAME Microsoft

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Version 1.0: Initial version.
Version 1.1: Added suffix loop
Version 1.2: long servicetag for VM testing

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Rename the computer 

#> 

Param()


# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy bypass -File "$PSCommandPath"
        Exit $lastexitcode
    }
}

# Create a tag file just so Intune knows this was installed
if (-not (Test-Path "$($env:ProgramData)\Microsoft\RenameComputer"))
{
    Mkdir "$($env:ProgramData)\Microsoft\RenameComputer"
}
Set-Content -Path "$($env:ProgramData)\Microsoft\RenameComputer\RenameComputer.ps1.tag" -Value "Installed"

# Initialization
$dest = "$($env:ProgramData)\Microsoft\RenameComputer"
if (-not (Test-Path $dest))
{
    mkdir $dest
}
Start-Transcript "$dest\RenameComputer.log" -Append

# Make sure we are already domain-joined
$goodToGo = $true
$details = Get-ComputerInfo
if (-not $details.CsPartOfDomain)
{
    Write-Host "Not part of a domain."
    $goodToGo = $false
}

# Make sure we have connectivity
$dcInfo = [ADSI]"LDAP://RootDSE"
if ($dcInfo.dnsHostName -eq $null)
{
    Write-Host "No connectivity to the domain."
    $goodToGo = $false
}

if ($goodToGo)
{
    # Get the new computer name
    #$newName = Invoke-RestMethod -Method GET -Uri "https://generatename.azurewebsites.net/api/HttpTrigger1?prefix=AD-"
    $model = Get-WmiObject Win32_ComputerSystem | Select -Expand Model | Out-String # Get Model name of Machine
    $model2 = Get-WmiObject Win32_ComputerSystemProduct | Select -Expand Version | Out-String # Get Model name of Machine for Lenovos
    $servicetag = Get-WmiObject Win32_ComputerSystemProduct | Select -Expand IdentifyingNumber | Out-String # Get Service Tag or Serial
    $servicetag = $servicetag -replace '\s',''
    if($servicetag.length -gt 10){
        $servicetag = $servicetag.substring(0,10)
    }

    #$num = Get-Random -Minimum 1 -Maximum 999 #Get a random integer to set as the temporary name for the VM
    ###### NAMING SCHEME AS OF 04/02/2019 ######
    # [SYSTEM_TYPE]-[SERVICE_TAG] - Example: W-AB12CD
    ###### SYSTEM TYPE EXAMPLES ######
    # W - Workstation
    # L - Laptop
    # S - Surface
    # V - Virtual 
    # Z - Unknown 

    If($model -like '*optiplex*')
    {    
        $newName = "W-$servicetag"

    }
    If($model -like '*precision*')
    {    
        $newName = "W-$servicetag"

    }
    elseIf($model -like '*latitude*')
    {
       $newName = "L-$servicetag"
    }
    elseIf($model2 -like '*thinkpad*')
    {
       $newName = "L-$servicetag"
    }
    elseIf($model2 -like '*V130*')
    {
       $newName = "L-$servicetag"
    }
    elseIf($model -like '*surface*')
    {
       $newName = "S-$servicetag"
    }
    elseIf($model -like '*vmware*')
    {
       $newName = "V-$servicetag"
    }
    else
    {
       $newName = "Z-$servicetag"
    }
    #Check for existing name
    $newName = $newName.Trim()
    $adsiResult = ([ADSISearcher]"Name=$newName").FindAll()
    If($adsiResult -ne $null){
        Write-Host "newname exists:"$adsiResult.path
        $suffix = 2
        Do{
            $newerName = "$newName-$suffix"
            $suffix++
            Remove-Variable -Name "adsiResult"
            Write-Host "Checking LDAP for "$newerName
            $adsiResult = ([ADSISearcher]"Name=$newerName").FindAll()
            if($adsiResult -ne $null){
                Write-Host "Found "$adsiResult.path
            }else{
                Write-Host "Cound not find $newerName"
                $end = 1
            }
        }Until($end)
        Write-Host "Setting new name to "$newerName
        $newName = $newerName
    }else{
        Write-Host "Newname $newName does not already exist"
    }


    # Set the computer name
    Write-Host "Renaming computer to $($newName)"
    $passThru = Rename-Computer -NewName $newName -PassThru
    Write-Host "Result: "$passThru

    # Remove the scheduled task
    Disable-ScheduledTask -TaskName "RenameComputer" -ErrorAction Ignore
    Unregister-ScheduledTask -TaskName "RenameComputer" -Confirm:$false -ErrorAction Ignore
    Write-Host "Scheduled task unregistered."

    # Make sure we reboot if still in ESP/OOBE by reporting a 1641 return code (hard reboot)
    if ($details.CsUserName -match "defaultUser")
    {
        Write-Host "Exiting during ESP/OOBE with return code 1641"
        Stop-Transcript
        Exit 1641
    }
    else {
        Write-Host "Initiating a restart in 10 minutes"
        & shutdown.exe /g /t 600 /f /c "Computer will restart after 10 minutes to complete name change. Save your work."
        Stop-Transcript
        Exit 0
    }
}
else
{
    # Check to see if already scheduled
    $existingTask = Get-ScheduledTask -TaskName "RenameComputer" -ErrorAction SilentlyContinue
    if ($existingTask -ne $null)
    {
        Write-Host "Scheduled task already exists."
        Stop-Transcript
        Exit 0
    }

    # Copy myself to a safe place if not already there
    if (-not (Test-Path "$dest\RenameComputer.ps1"))
    {
        Copy-Item $PSCommandPath "$dest\RenameComputer.PS1"
    }

    # Create the scheduled task action
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -ExecutionPolicy bypass -WindowStyle Hidden -File $dest\RenameComputer.ps1"

    # Create the scheduled task trigger
    $timespan = New-Timespan -minutes 5
    $triggers = @()
    $triggers += New-ScheduledTaskTrigger -Daily -At 9am
    $triggers += New-ScheduledTaskTrigger -AtLogOn -RandomDelay $timespan
    $triggers += New-ScheduledTaskTrigger -AtStartup -RandomDelay $timespan
    
    # Register the scheduled task
    Register-ScheduledTask -User SYSTEM -Action $action -Trigger $triggers -TaskName "RenameComputer" -Description "RenameComputer" -Force
    Write-Host "Scheduled task created."
}

Stop-Transcript
