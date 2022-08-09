#Mitigate dependency not immediately existing
#{4812D39E-A2E8-46B8-B09A-CFC7B8FCA172}
#powershell.exe -executionpolicy bypass -file "install-ccmsetup.ps1"
#mark_burns@dell.com for Primark
.\ccmsetup.exe /mp:CWACMSITE1 SMSSITECODE=PSL /FSP:CWASCCMDEPLOY1 
$retry = 0
while($retry -lt 14){
    $service= get-service -name CcmExec
    if($service){
        exit 0
    }
    else{
        start-sleep -s 30
        $retry ++
        write-output "Retrying $retry"
        }
}
exit 1