<#PSScriptInfo

.NAME RenameComputer.ps1

.VERSION 1.4

.AUTHOR Michael Niehaus
.ADDITIONS mark_burns@dell.com

.RELEASENOTES
Version 1.0: Initial version.
Version 1.1: Added suffix loop to deal with existing computer objects
Version 1.2: long servicetag for VM testing
Version 1.3: Renamed tag for use as standalone PowerShell
Version 1.4: AssetTag & SerialNumber logic

.DESCRIPTION 
Rename the computer, using AssetTag or SerialNumber logic
Pre-reqs: https://oofhours.com/2020/05/19/renaming-autopilot-deployed-hybrid-azure-ad-join-devices/
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
# For use as Win32 but you can also run as PowerShell
if (-not (Test-Path "$($env:ProgramData)\RenameComputer"))
{
    Mkdir "$($env:ProgramData)\RenameComputer"
}
Set-Content -Path "$($env:ProgramData)\RenameComputer\RenameComputer.ps1.tag" -Value "Installed"

# Initialization
$dest = "$($env:ProgramData)\RenameComputer"
if (-not (Test-Path $dest))
{
    mkdir $dest
}
Start-Transcript "$dest\RenameComputer.log" -Append

#Have we already run successfully?
If (Test-Path "$($env:ProgramData)\RenameComputer\Renamed.tag"){
    Write-Host "Script previously completed, exiting"
    Exit 0
}

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

#Check for ESP WWAHostDetection
$ESPProcesses = Get-Process -Name 'wwahost' -ErrorAction 'SilentlyContinue'
if ($ESPProcesses.Count -eq 0) {
    Write-Host 'WWAHost is not running'
}else{
    Write-Host "WWAHost is running"
    $goodToGo = $false
}

#Check for Hybrid Join
$CheckAzureADState = [string](dsregcmd.exe /status)
if($CheckAzureADState -notlike '*AzureAdJoined : YES*'){
    Write-Host "Azure AD not yet joined"
    $goodToGo = $false
}else{
    Write-Host "Azure AD Joined"
}

# Get the new computer name
$newName = ""

#Asset Tag
$at = Get-CIMInstance win32_systemenclosure | select-object SMBIOSAssetTag
Write-Host "Looking up Asset tag: $($at.SMBIOSAssetTag)"
if($at.SMBIOSAssetTag -eq "" -or $at.SMBIOSAssetTag -eq "No Asset Information"-or $at.SMBIOSAssetTag -eq "No Asset Tag"){
    #Service Tag
    Write-Host "Valid asset tag not found, resorting to service tag"
    $servicetag = Get-WmiObject Win32_ComputerSystemProduct | Select -Expand IdentifyingNumber | Out-String # Get Service Tag or Serial number
    if($servicetag -ne ""){
        Write-Host "Service tag found: $($servicetag)"
        $newName = $servicetag
    }else{
        Write-Host "Service tag not found"
    }
  }else{
    Write-Host "Valid asset tag found: $($at.SMBIOSAssetTag)"
    $newName = $at.SMBIOSAssetTag
}

if($newName -ne ""){
    $newName = $newName -replace '\s',''
    if($newName.length -gt 12){
        $newName = $newName.substring(0,12)
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
        Write-Host "Could not find $newName via LDAP"
    }
}else{
    Write-Host "Could not determine new name"
    $goodToGo = $false
}

if ($goodToGo)
{
    # Set the computer name
    Write-Host "Renaming computer to $($newName)"
    $passThru = Rename-Computer -NewName $newName -PassThru
    Write-Host "Result: "$passThru

    # Remove the scheduled task
    Disable-ScheduledTask -TaskName "RenameComputer" -ErrorAction Ignore
    Unregister-ScheduledTask -TaskName "RenameComputer" -Confirm:$false -ErrorAction Ignore
    Write-Host "Scheduled task unregistered."
    Set-Content -Path "$($env:ProgramData)\RenameComputer\Renamed.tag" -Value "Installed"

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
