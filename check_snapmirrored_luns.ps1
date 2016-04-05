####################################################################################
## This script works for two SnapMirrored clustered Data ONTAP storage systems. 
## It's been deployed just for the below scenario:
## - There is one source SVM with the source LUNs
## - There is one destionation SVM with the destination LUNs (without production volumes)
## - The destionation SVM has only destionation volumes from one source SVM
## - Each LUN is stored in one volume
##
## First of all run once the create_securestring_file.ps1 script for each cDOT.
## 
## Author: Pablo Garcia Arevalo
####################################################################################

# Runtime variables
$username = "admin"
$sourceClusterName = "MySourceCDOT"
$sourceClusterIP = "192.168.0.5"
$sourceSVM = "mySourceSVM"
$destinationClusterName = "myDestinationCDOT"
$destinationClusterIP = "192.168.0.6"
$destinationSVM = "myDestinationSVM"

# Setting the default path files based on the cluster's name
$sourcePathFile = ".\$sourceClusterName.txt"
$destinationPathFile = ".\$destinationClusterName.txt"

# Get the secured password from the source cluster
$sourceSecstr = cat $sourcePathFile | convertto-securestring
$sourceCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $sourceSecstr

# Get the secured password from the destination cluster
$destinationSecstr = cat $destinationPathFile | convertto-securestring
$destinationCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $destinationSecstr

Write-Host

# Connect to destination cluster
Write-Host "Connecting to cluster $destinationClusterName ... " -NoNewLine
$conn = Connect-NcController -Name $destinationClusterIP -HTTPS -Credential $destinationCred
if ($conn -eq $null)
    {
    Write-Host "Connection to host $destinationClusterName failed!" -foregroundcolor "red"
    break
    }
else {
    Write-Host "Done." -foregroundcolor "green"
}

# Get the snapmirror relationship for the destination SVM
$snapmirrorList = Get-NcSnapmirror -DestinationVserver $destinationSVM

# Initiatlize the destination LUN serials table
$lun_serial_destination = @{"" = ""}

#Loop through the destination volumes to get the lun path and serial numbers
foreach ($snapmirror in $snapmirrorList) { 
    $destinationPath = $snapmirror | select DestinationVolume | ft -hide | out-string
    $destinationPath = $destinationPath.Trim()
    $destinationVolumePath = "/vol/"+$destinationPath+"*"
    $destinationLunSerial = Get-NcLun $destinationVolumePath | Get-NcLunSerialNumber | select SerialNumber | ft -hide | Out-String
    $destinationLunSerial = $destinationLunSerial.Trim()
    $destinationLunPath = Get-NcLun $destinationVolumePath | select Path | ft -hide | Out-String
    $destinationLunPath = $destinationLunPath.Trim()
    
    $lun_serial_destination.Add($destinationLunPath, $destinationLunSerial)
}

# Write-host "El de la primera LUN" $lun_serial_destination.Get_Item("/vol/vol1/lun1")
#$lun_serial_destination

# Connect to source cluster
Write-Host "Connecting to cluster $sourceClusterName ... " -NoNewLine
$conn = Connect-NcController -Name $sourceClusterIP -HTTPS -Credential $sourceCred
if ($conn -eq $null)
    {
    Write-Host "Connection to host $destinationClusterName failed!" -foregroundcolor "red"
    break
    }
else {
    Write-Host "Done." -foregroundcolor "green"
}

Write-Host
$matched = "true"

foreach ($h in $lun_serial_destination.GetEnumerator()) {
    # Write-Host "$($h.Name): $($h.Value)"
    if ([string]::IsNullOrEmpty($($h.Name))) {}
    else {
        Write-Host "Checking the serial number for the LUN "$($h.Name) "... " -NoNewLine
        $sourceLunSerial = Get-NcLunSerialNumber -path $($h.Name) -VserverContext $sourceSVM | select SerialNumber | ft -hide | Out-String
        $sourceLunSerial = $sourceLunSerial.Trim()
        if ($sourceLunSerial -eq $lun_serial_destination.Get_Item($($h.Name))) {
            Write-Host " OK" -foregroundcolor "green"
        }
        else {
            $matched = "false"
            $volume = $($h.Name).Split("/")[2]
            Write-Host " Error, the serial numbers don't match" -foregroundcolor "red"
            Write-Host "snapmirror break -destination-path $destinationSVM" -NoNewLine -foregroundcolor "DarkGray"
            Write-Host ":"  -NoNewLine -foregroundcolor "DarkGray"
            Write-Host $volume -foregroundcolor "DarkGray"
            Write-Host "lun offline -vserver $destinationSVM -path $($h.Name)" -foregroundcolor "DarkGray"
            Write-Host "lun modify -vserver $destinationSVM -path $($h.Name) -serial $sourceLunSerial" -foregroundcolor "DarkGray"
            Write-Host "lun online -vserver $destinationSVM -path $($h.Name)" -foregroundcolor "DarkGray"
            Write-Host "snapmirror resync -destination-path $destinationSVM" -NoNewLine -foregroundcolor "DarkGray"
            Write-Host ":"  -NoNewLine -foregroundcolor "DarkGray"
            Write-Host $volume "-force true" -foregroundcolor "DarkGray"            
        }
    }
}

Write-Host
if ($matched -eq "true") {
    Write-Host "Every destination LUNs match the serial number with their source LUNs." -foregroundcolor "green"
    }
else {
    Write-Host "Execute the above commands in the cluster $destinationClusterName and run again this script."  -foregroundcolor "red"
    }








