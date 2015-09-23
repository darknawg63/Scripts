<#
 Check-Backup.ps1
 ----------------

 AUTHOR: Jerry Webster
 VERSION: 2.2
 DATE: 09-09-2015
-----------------
 
** getBackupStatus()


 Usage:
 -------------------------------------------------------------------------------

 In conjunction with NSClient++ queries the "Microsoft-Windows-Backup"
 eventlog and gets the most recent status of the backup task. The output is then 
 formatted for use in Nagios.

 Parameters:
 -------------------------------------------------------------------------------

 -excludeStart: Beginning of time period that we do not wish to run checks.
 
 -excludeEnd: End of the time period that we do not wish to run checks.
 
 -conditions: Filter used for targeting specific log events.

 -------------------------------------------------------------------------------
#>

# Select the columns that we wish to query.
$selection = @{"field"="Id";"state"=4};

function dateString ([String]$dateString) {
    $dateMask = "%d-%M-yyyy HH:mm:ss"
    return [DateTime]::ParseExact("$dateString", $dateMask, $null)
}

function getBackupStatus ($conditions) {

    Set-Variable -Name returnValue -Value $null -Scope 0
   
    $field = $conditions.field
    $state = $conditions.state

    try {
        if ($messageObject = Get-WinEvent -Logname Microsoft-Windows-Backup -ErrorAction Stop |`
            Where-Object {$_.$field -eq $state} | Select-Object -First 1 |`
            Format-Table -AutoSize -Wrap -Property Message, TimeCreated -HideTableHeaders) { 
                
            # We'd like to show the message string, not the object.
            $messageOutput = Format-List -InputObject $messageObject | Out-String

            $dateObject = Get-WinEvent -Logname Microsoft-Windows-Backup -ErrorAction Stop |`
            Where-Object {$_.$field -eq $state} | Select-Object -First 1 |`
            Format-Table -AutoSize -Wrap -Property TimeCreated -HideTableHeaders;

            $dateString = Format-List -InputObject $dateObject | Out-String
            $timeCreated = dateString -dateString $dateString.Replace("`r`n",'')
            $dateDiff = ((Get-Date).DayOfYear - $timeCreated.DayOfYear)

            switch ($dateDiff) {
        
                # Last job less than three days old..
                {$dateDiff -lt 3} {
                    Write-Host $messageOutput.Replace("`r`n",'')
                    $returnValue = 0 
                }
                # Last job is three days old, starting on Monday
                {$dateDiff -lt 4 -and $dateDiff -gt 2 -and (Get-Date).DayOfWeek.value__ -eq 1} {
                    Write-Host $messageOutput.Replace("`r`n",'')
                    $returnValue = 0
                }
                # Last job is three days old, on any day except Monday
                {$dateDiff -lt 4 -and $dateDiff -gt 2 -and (Get-Date).DayOfWeek.value__ -ne 1} {
                    Write-Host $messageOutput.Replace("`r`n",'')
                    $returnValue = 1 
                }
                # Last job is at least four days old
                {$dateDiff -ge 4} {
                    Write-Host $messageOutput.Replace("`r`n",'')
                    $returnValue = 2
                }
            }
        }
    }

    catch {
        Write-Host $_.Exception.Message
        $returnValue = 3
    }

    finally {
        exit $returnValue
    }
}

getBackupStatus -conditions:$selection;

