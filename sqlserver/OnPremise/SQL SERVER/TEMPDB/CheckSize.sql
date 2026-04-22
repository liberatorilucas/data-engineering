
USE TEMPDB
GO

--SELECT
--    FILE_ID
--    , type_desc
--    , Name
--    , physical_name
--    , size
--    , state_desc
--FROM tempdb.sys.database_files

--First part of the script
SELECT instance_name AS 'Database',
[Data File(s) Size (KB)]/1024 AS [Data file (MB)],
[Log File(s) Size (KB)]/1024 AS [Log file (MB)],
[Log File(s) Used Size (KB)]/1024 AS [Log file space used (MB)]
FROM (
        SELECT * 
        FROM   SYS.DM_OS_PERFORMANCE_COUNTERS
        WHERE  counter_name IN ( 'Data File(s) Size (KB)',
                                    'Log File(s) Size (KB)',
                                    'Log File(s) Used Size (KB)' )
        AND     instance_name = 'tempdb') AS A
            
        PIVOT
 
        (
            MAX(cntr_value) FOR counter_name IN ( [Data File(s) Size (KB)],
                                                  [LOG File(s) Size (KB)],
                                                  [Log File(s) Used Size (KB)])
        ) AS B
GO

-- Second part of the script
SELECT 
      create_date AS [Creation date]  
    , recovery_model_desc [Recovery model]
FROM sys.databases 
WHERE name = 'tempdb'
GO

-- Tamaño total
SELECT 
    SUM(size) / 128 AS [Total database size (MB)]
FROM tempdb.SYS.DATABASE_FILES


-- Utilice la siguiente consulta para poder obtener información sobre el uso del espacio por parte de objetos específicos tempdb:
SELECT 
  (
    SUM(unallocated_extent_page_count)/128) AS [Free space (MB)],
    SUM(internal_object_reserved_page_count)*8 AS [Internal objects (KB)],
    SUM(user_object_reserved_page_count)*8 AS [User objects (KB)],
    SUM(version_store_reserved_page_count)*8 AS [Version store (KB)]
FROM sys.dm_db_file_space_usage
   --database_id '2' represents tempdb
WHERE database_id = 2
