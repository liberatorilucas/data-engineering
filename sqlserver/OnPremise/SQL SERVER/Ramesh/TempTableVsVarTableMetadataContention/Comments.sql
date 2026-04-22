
--Table Variable Vs Temp Table - Tempdb Metadata Contention
--Related article / hands-on video: http://www.sqlvideo.com/AllVideos/Tempdb-Metadata-Contention---Table-Variable-Vs-Temporary-Table

/*********************************************************************************************************
To practice, if you have a “(local)” instance (default instance of SQL Server installed on your local 
computer), you don’t need to change the connection string. If you have a non “(local)” instance 
(named instance and / or SQL Server installed on a remote computer), then you need to change the connection
string. For additional information open online example “SQLTest_OnlineExamplesSetup” and refer to menu 
Settings -> Comments for details in that example.

To practice, you can use Microsoft SQL Server Developer Edition, now it is free, for download details 
refer to this blog: https://blogs.technet.microsoft.com/dataplatforminsider/2016/03/31/microsoft-sql-server-developer-edition-is-now-free
**********************************************************************************************************/

/*********************************************************************************************************
When SQLTest online example needs to create or alter databases that includes file location, it uses 
keywords as place holder for file location. To practice these examples you need to create a file 
“FindAndReplace.txt” in “..\Documents\SQLTest” directory with the following content. 

Replace the drive letter and directory location specific to your computer (also make sure these directory 
exists or create them, there needs to be some free space for database file creation).

DatabaseDataFileLocation1=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA
DatabaseDataFileLocation2=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA
DatabaseDataFileLocation3=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA
DatabaseDataFileLocation4=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA

DatabaseLogFileLocation=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA

TempdbDataFileLocation=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA
TempdbLogFileLocation=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA
*********************************************************************************************************/

-- Check how many files tempdb have.
use master
    SELECT  *
    FROM    sys.master_files 
    WHERE   database_id = db_id('tempdb')
GO

--Trace flag
--T1118

-- Check if you have a TraceFlag enable.
dbcc tracestatus()
go

-- Check what is running from SQLTest.
USE MASTER
    SELECT r.session_id, r.status, r.command, r.wait_type, r.wait_time, r.wait_resource
    FROM   sys.dm_exec_requests r
    JOIN   sys.dm_exec_sessions s 
    ON     (r.session_id = s.session_id)
    WHERE  program_name LIKE 'SQLTest%'
GO

-- sys.dm_os_buffer_descriptors
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-buffer-descriptors-transact-sql?view=sql-server-ver15
-- Returns information about all the data pages that are currently in the SQL Server buffer pool

USE tempdb
SELECT object_name, index_name, database_id, file_id, page_id
FROM   sys.dm_os_buffer_descriptors bd
JOIN    (   SELECT o.name as object_name
                 , i.name as index_name
                 , au.allocation_unit_id
			FROM sys.allocation_units au
			JOIN sys.partitions p 
            ON  (au.container_id = p.hobt_id)
			JOIN sys.indexes i
            ON  (p.object_id = i.object_id 
            AND  p.index_id  = i.index_id)
			JOIN sys.objects o 
            ON  (p.object_id = o.object_id)
			WHERE au.type in (1, 3)
		    
            UNION
		
            SELECT  o.name as object_name, i.name as index_name, au.allocation_unit_id
			FROM    sys.allocation_units au
			JOIN    sys.partitions p 
            ON      (au.container_id = p.hobt_id)
			JOIN    sys.indexes i 
            ON      (p.object_id = i.object_id 
            AND      p.index_id = i.index_id )
			JOIN    sys.objects o 
            ON      (p.object_id = o.object_id)
			WHERE   au.type IN (2)
	    ) AS objects 
ON (bd.allocation_unit_id = objects.allocation_unit_id)
WHERE 
      bd.database_id = db_id() 
AND   bd.file_id     = 1 
AND   bd.page_id     = 116
GO

-- Add .mdf file
use master
alter database tempdb 
    modify file (   name      = 'tempdev'
                  , filename  = 'TempdbDataFileLocation\tempdb.mdf'
                  , size      = 1536MB )
go

use master
alter database tempdb 
    modify file (   name     = 'templog'
                  , filename = 'TempdbLogFileLocation\templog.ldf'
                  , size     = 512MB )
go

-- ShrinkFile tempdb
use tempdb
    dbcc shrinkfile ('tempdev2' , emptyfile)
    dbcc shrinkfile ('tempdev3' , emptyfile)
    dbcc shrinkfile ('tempdev4' , emptyfile)
    dbcc shrinkfile ('tempdev5' , emptyfile)
    dbcc shrinkfile ('tempdev6' , emptyfile)
    dbcc shrinkfile ('tempdev7' , emptyfile)
    dbcc shrinkfile ('tempdev8' , emptyfile)
    dbcc shrinkfile ('tempdev9' , emptyfile)
    dbcc shrinkfile ('tempdev10' , emptyfile)
    dbcc shrinkfile ('tempdev11' , emptyfile)
    dbcc shrinkfile ('tempdev12' , emptyfile)
    dbcc shrinkfile ('tempdev13' , emptyfile)
    dbcc shrinkfile ('tempdev14' , emptyfile)
    dbcc shrinkfile ('tempdev15' , emptyfile)
    dbcc shrinkfile ('tempdev16' , emptyfile)
    dbcc shrinkfile ('tempdev17' , emptyfile)
    dbcc shrinkfile ('tempdev18' , emptyfile)
    dbcc shrinkfile ('tempdev19' , emptyfile)
    dbcc shrinkfile ('tempdev20' , emptyfile)
    dbcc shrinkfile ('tempdev21' , emptyfile)
    dbcc shrinkfile ('tempdev22' , emptyfile)
    dbcc shrinkfile ('tempdev23' , emptyfile)
    dbcc shrinkfile ('tempdev24' , emptyfile)
go

-- Remove File tempdb
use master
    alter database tempdb remove file tempdev2
    alter database tempdb remove file tempdev3
    alter database tempdb remove file tempdev4
    alter database tempdb remove file tempdev5
    alter database tempdb remove file tempdev6
    alter database tempdb remove file tempdev7
    alter database tempdb remove file tempdev8
    alter database tempdb remove file tempdev9
    alter database tempdb remove file tempdev10
    alter database tempdb remove file tempdev11
    alter database tempdb remove file tempdev12
    alter database tempdb remove file tempdev13
    alter database tempdb remove file tempdev14
    alter database tempdb remove file tempdev15
    alter database tempdb remove file tempdev16
    alter database tempdb remove file tempdev17
    alter database tempdb remove file tempdev18
    alter database tempdb remove file tempdev19
    alter database tempdb remove file tempdev20
    alter database tempdb remove file tempdev21
    alter database tempdb remove file tempdev22
    alter database tempdb remove file tempdev23
    alter database tempdb remove file tempdev24
go

/*
use master
alter database tempdb add file (name = 'tempdev25', filename = 'TempdbDataFileLocation\tempdb25.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev26', filename = 'TempdbDataFileLocation\tempdb26.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev27', filename = 'TempdbDataFileLocation\tempdb27.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev28', filename = 'TempdbDataFileLocation\tempdb28.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev29', filename = 'TempdbDataFileLocation\tempdb29.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev30', filename = 'TempdbDataFileLocation\tempdb30.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev31', filename = 'TempdbDataFileLocation\tempdb31.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev32', filename = 'TempdbDataFileLocation\tempdb32.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev33', filename = 'TempdbDataFileLocation\tempdb33.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev34', filename = 'TempdbDataFileLocation\tempdb34.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev35', filename = 'TempdbDataFileLocation\tempdb35.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev36', filename = 'TempdbDataFileLocation\tempdb36.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev37', filename = 'TempdbDataFileLocation\tempdb37.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev38', filename = 'TempdbDataFileLocation\tempdb38.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev39', filename = 'TempdbDataFileLocation\tempdb39.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev40', filename = 'TempdbDataFileLocation\tempdb40.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev41', filename = 'TempdbDataFileLocation\tempdb41.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev42', filename = 'TempdbDataFileLocation\tempdb42.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev43', filename = 'TempdbDataFileLocation\tempdb43.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev44', filename = 'TempdbDataFileLocation\tempdb44.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev45', filename = 'TempdbDataFileLocation\tempdb45.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev46', filename = 'TempdbDataFileLocation\tempdb46.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev47', filename = 'TempdbDataFileLocation\tempdb47.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev48', filename = 'TempdbDataFileLocation\tempdb48.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev49', filename = 'TempdbDataFileLocation\tempdb49.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev50', filename = 'TempdbDataFileLocation\tempdb50.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev51', filename = 'TempdbDataFileLocation\tempdb51.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev52', filename = 'TempdbDataFileLocation\tempdb52.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev53', filename = 'TempdbDataFileLocation\tempdb53.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev54', filename = 'TempdbDataFileLocation\tempdb54.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev55', filename = 'TempdbDataFileLocation\tempdb55.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev56', filename = 'TempdbDataFileLocation\tempdb56.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev57', filename = 'TempdbDataFileLocation\tempdb57.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev58', filename = 'TempdbDataFileLocation\tempdb58.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev59', filename = 'TempdbDataFileLocation\tempdb59.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev60', filename = 'TempdbDataFileLocation\tempdb60.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev61', filename = 'TempdbDataFileLocation\tempdb61.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev62', filename = 'TempdbDataFileLocation\tempdb62.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev63', filename = 'TempdbDataFileLocation\tempdb63.ndf', size = 64MB)
alter database tempdb add file (name = 'tempdev64', filename = 'TempdbDataFileLocation\tempdb64.ndf', size = 64MB)
go

use tempdb
dbcc shrinkfile ('tempdev25' , emptyfile)
dbcc shrinkfile ('tempdev26' , emptyfile)
dbcc shrinkfile ('tempdev27' , emptyfile)
dbcc shrinkfile ('tempdev28' , emptyfile)
dbcc shrinkfile ('tempdev29' , emptyfile)
dbcc shrinkfile ('tempdev30' , emptyfile)
dbcc shrinkfile ('tempdev31' , emptyfile)
dbcc shrinkfile ('tempdev32' , emptyfile)
dbcc shrinkfile ('tempdev33' , emptyfile)
dbcc shrinkfile ('tempdev34' , emptyfile)
dbcc shrinkfile ('tempdev35' , emptyfile)
dbcc shrinkfile ('tempdev36' , emptyfile)
dbcc shrinkfile ('tempdev37' , emptyfile)
dbcc shrinkfile ('tempdev38' , emptyfile)
dbcc shrinkfile ('tempdev39' , emptyfile)
dbcc shrinkfile ('tempdev40' , emptyfile)
dbcc shrinkfile ('tempdev41' , emptyfile)
dbcc shrinkfile ('tempdev42' , emptyfile)
dbcc shrinkfile ('tempdev43' , emptyfile)
dbcc shrinkfile ('tempdev44' , emptyfile)
dbcc shrinkfile ('tempdev45' , emptyfile)
dbcc shrinkfile ('tempdev46' , emptyfile)
dbcc shrinkfile ('tempdev47' , emptyfile)
dbcc shrinkfile ('tempdev48' , emptyfile)
dbcc shrinkfile ('tempdev49' , emptyfile)
dbcc shrinkfile ('tempdev50' , emptyfile)
dbcc shrinkfile ('tempdev51' , emptyfile)
dbcc shrinkfile ('tempdev52' , emptyfile)
dbcc shrinkfile ('tempdev53' , emptyfile)
dbcc shrinkfile ('tempdev54' , emptyfile)
dbcc shrinkfile ('tempdev55' , emptyfile)
dbcc shrinkfile ('tempdev56' , emptyfile)
dbcc shrinkfile ('tempdev57' , emptyfile)
dbcc shrinkfile ('tempdev58' , emptyfile)
dbcc shrinkfile ('tempdev59' , emptyfile)
dbcc shrinkfile ('tempdev60' , emptyfile)
dbcc shrinkfile ('tempdev61' , emptyfile)
dbcc shrinkfile ('tempdev62' , emptyfile)
dbcc shrinkfile ('tempdev63' , emptyfile)
dbcc shrinkfile ('tempdev64' , emptyfile)
go
use master
alter database tempdb remove file tempdev25
alter database tempdb remove file tempdev26
alter database tempdb remove file tempdev27
alter database tempdb remove file tempdev28
alter database tempdb remove file tempdev29
alter database tempdb remove file tempdev30
alter database tempdb remove file tempdev31
alter database tempdb remove file tempdev32
alter database tempdb remove file tempdev33
alter database tempdb remove file tempdev34
alter database tempdb remove file tempdev35
alter database tempdb remove file tempdev36
alter database tempdb remove file tempdev37
alter database tempdb remove file tempdev38
alter database tempdb remove file tempdev39
alter database tempdb remove file tempdev40
alter database tempdb remove file tempdev41
alter database tempdb remove file tempdev42
alter database tempdb remove file tempdev43
alter database tempdb remove file tempdev44
alter database tempdb remove file tempdev45
alter database tempdb remove file tempdev46
alter database tempdb remove file tempdev47
alter database tempdb remove file tempdev48
alter database tempdb remove file tempdev49
alter database tempdb remove file tempdev50
alter database tempdb remove file tempdev51
alter database tempdb remove file tempdev52
alter database tempdb remove file tempdev53
alter database tempdb remove file tempdev54
alter database tempdb remove file tempdev55
alter database tempdb remove file tempdev56
alter database tempdb remove file tempdev57
alter database tempdb remove file tempdev58
alter database tempdb remove file tempdev59
alter database tempdb remove file tempdev60
alter database tempdb remove file tempdev61
alter database tempdb remove file tempdev62
alter database tempdb remove file tempdev63
alter database tempdb remove file tempdev64
go
*/
