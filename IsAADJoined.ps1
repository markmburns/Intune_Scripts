#IsAADJoined
$dsregcmdstatus = dsregcmd /status
If($dsregcmdstatus -like "*AzureAdJoined : YES*"){
    $result = $true
}Else{
    $result = $false
}
$result