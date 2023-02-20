# Dell 2022
$date = Get-Date -Format yyyyMMddhhmmss
$file = "$($env:temp)\gpos_$date.csv"
Add-Content $file "Name,LinksPath,WMI Filter,CreatedTime,ModifiedTime,CompVerDir,CompVerSys,UserVerDir,UserVerSys,CompEnabled,UserEnabled,SecurityFilter,GPO Enabled,Enforced"
$GPOList = (Get-Gpo -All).DisplayName
$colGPOLinks = @()
$LinksPaths = @()
foreach ($GPOItem in $GPOList){

    $LinksPaths = "" 
    $LinksPath = ""

    [xml]$gpocontent =  Get-GPOReport $GPOItem -ReportType xml

    $LinksPaths = $gpocontent.GPO.LinksTo #| %{$_.SOMPath}
    
    $Wmi = Get-GPO $GPOItem | Select-Object WmiFilter

    $CreatedTime = $gpocontent.GPO.CreatedTime
    $ModifiedTime = $gpocontent.GPO.ModifiedTime
    $CompVerDir = $gpocontent.GPO.Computer.VersionDirectory
    $CompVerSys = $gpocontent.GPO.Computer.VersionSysvol
    $CompEnabled = $gpocontent.GPO.Computer.Enabled
    $UserVerDir = $gpocontent.GPO.User.VersionDirectory
    $UserVerSys = $gpocontent.GPO.User.VersionSysvol
    $UserEnabled = $gpocontent.GPO.User.Enabled
    $SecurityFilter = ((Get-GPPermissions -Name $GPOItem -All | ?{$_.Permission -eq "GpoApply"}).Trustee | ?{$_.SidType -ne "Unknown"}).name -Join ','
   if($LinksPaths -ne $null){
        foreach ($LinksPath in $LinksPaths){
            Add-Content $file "$GPOItem,$($LinksPath.SOMPath),$(($wmi.WmiFilter).Name),$CreatedTime,$ModifiedTime,$CompVerDir,$CompVerSys,$UserVerDir,$UserVerSys,$CompEnabled,$UserEnabled,""$($SecurityFilter)"",$($LinksPath.Enabled),$($LinksPath.NoOverride)"
        }
    
    }
    else{
            Add-Content $file "$GPOItem,$($LinksPath.SOMPath),$(($wmi.WmiFilter).Name),$CreatedTime,$ModifiedTime,$CompVerDir,$CompVerSys,$UserVerDir,$UserVerSys,$CompEnabled,$UserEnabled,""$($SecurityFilter)"",$($LinksPath.Enabled),$($LinksPath.NoOverride)"
    } 
} 
