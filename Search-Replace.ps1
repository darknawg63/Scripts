$machines = @("as02","sbs01","ts01")

Foreach($machine in $machines) {
    (Get-Content "\\$machine\c$\Program Files\NSClient++\scripts\Check-Backup.ps1") |
    Foreach-Object { $_.replace('{$_.Id -eq 4}', '{$_.$field -eq $state}')} |
    Set-Content "\\$machine\c$\Program Files\NSClient++\scripts\Check-Backup.ps1"
}