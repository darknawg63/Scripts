/*
Dump.sql

AUTHOR: Jerry Webster
VERSION: 1.1
DATE: 17-09-2015

Usage:
--------------------------------------------------------------------------------

This script is called by BackupSQL.ps1 and is used for dumping each database out
to a storage location

 Parameters:
-------------------------------------------------------------------------------
 
$(destination): Script variable passed from within BackupSQL.ps1 containing the 
storage destination.
*/

DECLARE @name VARCHAR(100)  
DECLARE @fileName VARCHAR(250) 

DECLARE db_cursor CURSOR FOR  
SELECT name 
    FROM master.dbo.sysdatabases 
        WHERE name NOT IN ('tempdb')  

OPEN db_cursor   
FETCH NEXT 
    FROM db_cursor INTO @name   

    WHILE @@FETCH_STATUS = 0   
        BEGIN   
            SET @fileName = $(destination) + @name + '.bkp'  
            BACKUP DATABASE @name TO DISK = @fileName WITH NOFORMAT, INIT,  NAME = @name, SKIP, NOREWIND, NOUNLOAD,  STATS = 10 
            FETCH NEXT FROM db_cursor INTO @name   
        END   

CLOSE db_cursor   
DEALLOCATE db_cursor