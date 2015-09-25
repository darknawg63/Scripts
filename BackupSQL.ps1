<#
 BackupSQL.ps1
 ----------------

 AUTHOR: Jerry Webster
 VERSION: 1.1
 DATE: 17-09-2015
-----------------
 

 Usage:
 -------------------------------------------------------------------------------

Calls Dump.sql and passes in the storage location in VAR = destination. 

* You must first set the system wide environment variable %STORAGE%.
* The variable $storage may need to be adjusted to the particular setup.

 -------------------------------------------------------------------------------

  Includes:
 -------------------------------------------------------------------------------
 
 -Include\Dunp.sql

 -------------------------------------------------------------------------------
#>

$hostName = get-content env:computername
$dayOfWeek = get-date -format dddd
$instances = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
$storage = get-content env:storage
$destination = $storage + $dayOfWeek + "\" + $hostName + "\"
$logFile = "C:\Beheer\Logs\Backupsql.log"

function dump($instance) {

    if(Test-Path $logFile) {
        Remove-Item $logFile
    }

    sqlcmd -E -S $hostname\$instance -v destination = "'$destination$instance\'" -i Include\Dump.sql -o $logFile
}

function backup($instances) {

    try {

        foreach($instance in $instances) { 

            if( Test-Path -PathType CONTAINER $destination$instance ) {
                dump -instance $instance
            } else {
                New-Item -ItemType Directory -Force -Path $destination$instance
                dump -instance $instance
            }  
        }
    }
    
    catch {
        Write-Host $_.Exception.Message
    }
    
    finally {
      exit
    }
}
backup -instances:$instances



