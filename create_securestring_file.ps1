 ########################################################################
## This script ask for a password and store it secured within a file
##
## Run the create_securestring_file.ps1 script before to create a file
## within a secured password
## 
## Author: Pablo García Arévalo
########################################################################

$cDOTname = Read-Host "What is the cluster's name?"
$password = Read-Host 'What is your password?' -AsSecureString

$filePath = ".\$cDOTname.txt"
$password | convertfrom-securestring | out-file $filePath
