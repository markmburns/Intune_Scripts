#Remediation to delete unwanted machine certs
#Only looking at certs from a specific template
#mark_burns@dell.com
$intendedTemplate = "PKCS"
$unwantedPrefix = "MMBB"
$intendedSubject = "CN=$($env:COMPUTERNAME)"
$output = ""

function Get-CertificateTemplateName($certificate)
{
    # The template name is stored in the Extension data. 
    # If available, the best is the extension named "Certificate Template Name", since it contains the exact name.
    $templateExt = $certificate.Extensions | Where-Object{ ( $_.Oid.FriendlyName -eq 'Certificate Template Name') } | Select-Object -First 1   
    if($templateExt) {
        return $templateExt.Format(1)
    }
    else {
        # Our fallback option is the "Certificate Template Information" extension, it contains the name as part of a string like:
        # "Template=Web Server v2(1.3.6.1.4.1.311.21.8.2499889.12054413.13650051.8431889.13164297.111.14326010.6783216)"
        $templateExt = $certificate.Extensions | Where-Object{ ( $_.Oid.FriendlyName -eq 'Certificate Template Information') } | Select-Object -First 1   
        if($templateExt) {
            $information = $templateExt.Format(1)

            # Extract just the template name in $Matches[1]
            if($information -match "^Template=(.+)\([0-9\.]+\)") {
                return $Matches[1]
            } else {
                # No regex match, just return the complete information then
                return $information
            }
        } else {
            # No template name found
            return $null
        }
    }
}

$myMachineCerts = Get-ChildItem -Path Cert:\LocalMachine\My
foreach($cert IN $myMachineCerts){
    $templateName =  Get-CertificateTemplateName $cert
    If($templateName -match $intendedTemplate){
        If($cert.Subject -match $intendedSubject){
            #Write-Output "Valid certificate found: $($cert.Subject), $($templateName)"
        }
        If($cert.Subject -notmatch $intendedSubject){
            $output = "$($output) | Extraneous: $($cert.Subject), $($templateName)"
            $cert | Remove-Item
        }
    }
}
Write-Output $output
Exit 0