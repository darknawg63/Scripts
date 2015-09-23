<#
 Check-BackupSQL.ps1
 ----------------

 AUTHOR: Jerry Webster
 VERSION: 1.3
 DATE: 17-09-2015
-----------------
 
** getBackupStatus()


 Usage:
 -------------------------------------------------------------------------------

 Queries the "Application" eventlog and gets the most recent status of the SQL backup task.
 The output is then formatted for use by Nagios and sent via NSClient

 Parameters:
 -------------------------------------------------------------------------------
 
 -conditions: Filter used for targeting specific log events.

 -------------------------------------------------------------------------------
#>

$age = $null
$dayOfWeek = (Get-Date).DayOfWeek.value__
$logName = "Application"
$sDay = 86400
$targetsIn = 6
$targetsOut = 0
$timeStamp = $null

# Set the columns that we wish to query.
$selection = @{"field" = "Id";"state" = 18264};

# Number of seconds since epoch
function dateToSec($date) {
    $day = $date.DayOfYear -as [int]
    $hour = $date.Hour     -as [int]
    $minute = $date.Minute -as [int]
    $second = $date.Second -as [int]

    return ($day * 24 * 60 * 60) + ($hour * 60 * 60) + ($minute * 60) + $second
}

function getBackupStatus ($conditions) {

    Set-Variable -Name returnValue -Value $null -Scope 0
   
    $field = $conditions.field
    $state = $conditions.state

    try {

        $dateObject = Get-WinEvent -Logname $logName -ErrorAction Stop |`
        Where-Object {$_.$field -eq $state} | Select-Object -First $targetsIn |`
        Select -ExpandProperty TimeCreated

        foreach ($timeCreated in $dateObject) {
            # The difference in seconds between the current time and time of last record
            $age = (dateToSec(Get-Date)) - (dateToSec($timeCreated))

            if($targetsOut -eq 0) {
                $timeStamp = $timeCreated
            }
            # Padding...
            if($age -le ($sDay * 3)) {
                $targetsOut++
            } else {

                break
            }
        }

        switch ($age) {

            # Latest job < 2 days old, any day, all targets
            {$age -lt ($sDay * 2) -and $targetsIn -eq $targetsOut} {
                Write-Host "Dumped $targetsOut of $targetsIn targets:" $timeStamp -NoNewline
                $returnValue = 0
                break
            } 
            # Latest job <= 3 days old, Sunday, Monday, all targets
            {$age -le ($sDay * 3) -and $dayOfWeek -eq 0 -or $dayOfWeek -eq 1 -and $targetsIn -eq $targetsOut} {
                Write-Host "Dumped $targetsOut of $targetsIn targets:" $timeStamp -NoNewline
                $returnValue = 0
                break
            }
            # Latest job < 2 days old, any day, some targets
            {$age -lt ($sDay * 2) -and $targetsIn -ne $targetsOut} {
                Write-Host "Dumped $targetsOut of $targetsIn targets: Last seen on" $timeStamp -NoNewline
                $returnValue = 2
                break
            } 
            # Latest job >= 2 days old
            {$age -ge ($sDay * 2)} {
                Write-Host "Dumped $targetsOut of $targetsIn targets: Last seen on" $timeStamp -NoNewline
                $returnValue = 2 
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

getBackupStatus -conditions:$selection