
USE MASTER
GO

/*
Example execution
	sp_BlitzFirst
		@ExpertMode = 1

Aditional Parameters
	@OutputTableNameFileStats – contents of sys.dm_io_virtual_file_stats
	@OutputTableNamePerfmonStats – contents of sys.dm_os_performance_counters
	@OutputTableNameWaitStats – contents of sys.dm_os_wait_stats, with common harmless waits filtered out  
*/

/*
How to execute on a Job
*/
EXEC dbo.sp_BlitzFirst	
	@OutputDatabaseName = 'DBA'
 ,	@OutputSchemaName = 'dbo'
 ,  @OutputTableName = 'BlitzFirst'
 ,  @OutputTableNameFileStats = 'BlitzFirst_FileStats'
 ,  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats'
 ,  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats'
 ,  @OutputTableNameBlitzCache = 'BlitzCache'
 ,  @OutputTableNameBlitzWho = 'BlitzWho'
--  @OutputType = 'none'

/*
How to Read the result
	To query the past data, use the delta views that sp_BlitzFirst automatically creates for you. 
	Whatever your table name inputs were, just add _Deltas to the end of them, and you’ll get 
	data with differences from each pass.
*/


/*
Extra
	EXEC sp_BlitzFirst 
	   @AsOf			   = '2024-01-01 13:00'
	 , @OutputDatabaseName = 'DBA'
	 , @OutputSchemaName   = 'dbo'
	 , @OutputTableName    = 'BlitzFirstResults
*/