#mark.burns@dell.com
#Backs up all GPOs in a domain, ready for Group Policy Analytics Import
#Variables
$GPOBackups = "C:\GPOBackups"


# Import the Group Policy module
Import-Module GroupPolicy

# Get all Group Policy objects from the domain
$gpos = Get-GPO -All

# Loop through each GPO and back it up
foreach ($gpo in $gpos) {
 # Set the path to where the GPO backup will be saved
 $backupPath = "$($GPOBackups)\$($gpo.DisplayName)"
 #Write-Host $backupPath
  
 #Create the backup path if required
 If(-not (Test-Path $backupPath)){
  mkdir $backupPath
 }
 # Export the GPO to the backup path
  Backup-GPO -Guid $gpo.Id -Path $backupPath 
 }

#Search for all gpreport.xml files
$gpReports = Get-ChildItem -Path $GPOBackups -Filter gpreport.xml -recurse
foreach ($gpReport in $gpReports) {
 # File rename
 $gpoArray = $gpReport.FullName.Split("\")
 Write-Host $gpoArray[2]
 $fileName = $gpoArray[2]
 #Copy to central location
 Copy-Item -path $gpReport.FullName -Destination "$GPOBackups\$($fileName).xml"
 }
 