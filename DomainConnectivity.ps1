# Make sure we are already domain-joined
$goodToGo = $true
$details = Get-ComputerInfo
if (-not $details.CsPartOfDomain)
{
   # Write-Host "Not part of a domain."
    $goodToGo = $false
}

# Make sure we have connectivity
$dcInfo = [ADSI]"LDAP://RootDSE"
if ($dcInfo.dnsHostName -eq $null)
{
  #  Write-Host "No connectivity to the domain."
    $goodToGo = $false
}

if ($goodToGo)
{
    Write-Host "Domain Connectivity"
}