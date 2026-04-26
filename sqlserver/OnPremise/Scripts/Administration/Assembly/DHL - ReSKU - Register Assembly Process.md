
```sql
/****************************************************************************************************************************** 
 To work this option should be ON
******************************************************************************************************************************/

	/* TRUSTWORTHY */
	SELECT name, is_trustworthy_on FROM SYS.DATABASES

	ALTER DATABASE ExpressLaneExtracts SET TRUSTWORTHY ON

	/* clr enabled and clr strict security */
	USE master
	GO

	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;

	EXEC sp_configure 'clr enabled'
	EXEC sp_configure 'clr strict security'

	EXEC sp_configure 'clr enabled', 1;
	RECONFIGURE;
	EXEC sp_configure 'clr strict security', 1;
	RECONFIGURE;

	EXEC sp_configure 'clr enabled'
	EXEC sp_configure 'clr strict security'
	
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;

/****************************************************************************************************************************** 
  Option I - Add the Assembly creating the hash from the binary (You should request the binary to Jesse, etc)
******************************************************************************************************************************/
USE master;
GO

	/* Step I - Check if the assembly is on trusted */
	SELECT * FROM sys.assemblies
	SELECT * FROM sys.trusted_assemblies;

	/* Step II - If you need to do all from scratch use this query to remove the old trusted entry. If it's neccessary */
    -- << paste the entire hex blob here >>
	EXEC sp_drop_trusted_assembly @hash = 0x<oldhash>;

	/* Step III - Add the  */
    -- << paste the entire hex blob here >>
	DECLARE @assembly VARBINARY(MAX) = 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C0103000E4CF6680000000000000000E00022200B013000001400000006000000000000F6320000002000000040000000000010002000000002000004000000000000000600000000000000008000000002000000000000030060850000100000100000000010000010000000000000100000000000000000000000A43200004F00000000400000D002000000000000000000000000000000000000006000000C0000006C3100001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E74657874000000FC120000002000000014000000020000000000000000000000000000200000602E72737263000000D0020000004000000004000000160000000000000000000000000000400000402E72656C6F6300000C0000000060000000020000001A0000000000000000000;
 
	DECLARE @hash VARBINARY(64);
	SELECT  @hash = HASHBYTES('SHA2_512', @assembly);
 
	SELECT @hash AS AssemblyHash;
 
	EXEC sp_add_trusted_assembly 
		@hash = @hash, 
		@description = N'ExpressLaneExtracts Assembly - trusted deployment';
	GO
 
	/* Step IV - Check if it was added */
	SELECT * FROM sys.assemblies
	SELECT * FROM sys.trusted_assemblies;

	/* Step V - General Permissions */
	USE ExpressLaneExtracts 
	GO

	ALTER ASSEMBLY ExpressLaneExtracts WITH PERMISSION_SET = EXTERNAL_ACCESS;
 
	/* Step VI - Give general permissions to the corresponding accounts - Change depend on the project */
	USE MASTER;
	GO

	GRANT UNSAFE ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
	GRANT EXTERNAL access ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
 
	USE [ExpressLaneExtracts];
	GO

	GRANT CREATE ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
	GRANT ALTER ANY ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];


/****************************************************************************************************************************** 
  Option II - Add the Assembly creating the hash from the SQL Server (You should have deployed it already)
******************************************************************************************************************************/
USE master;
GO

	/* Step I - Check it the assembly */
	SELECT * FROM sys.assemblies
	SELECT * FROM sys.trusted_assemblies;

	/* Step II - If you need to do all from scratch use this query to remove the old trusted entry. If it's neccessary */
    -- << paste the entire hex blob here >>
	EXEC sp_drop_trusted_assembly @hash = 0x<oldhash>;

	/* Step III - The binary of your assembly is stored in sys.assembly_files as a varbinary(max). You can extract it and 
	compute the hash like this: */
	USE [ExpressLaneExtracts];
	GO

	DECLARE @assembly_hash VARBINARY(64);
	
	-- Compute SHA2_512 hash directly from stored assembly binary 
	SELECT @assembly_hash = HASHBYTES('SHA2_512', af.content)
	FROM sys.assembly_files AS af
	JOIN sys.assemblies AS a
      ON af.assembly_id = a.assembly_id
	WHERE a.name = N'ExpressLaneExtracts';

	SELECT @assembly_hash AS AssemblyHash;

	/* Step VI - Add it as a trusted assembly (run once per SQL instance) */
	USE master;
	GO

	EXEC sp_add_trusted_assembly 
		@hash = 0xE94F5A9C824CA26FC8E54FB770A5EBE68EC37DA8C74A7F9F07E37CCD0AAAF9E618F3B87E4531753CB365FFFEF668E19700C3662AF161831318A8AD72BF6CD91D, 
		@description = N'ExpressLaneExtracts Assembly trusted';
	GO

 	/* Step V - Check if it was added */
	SELECT * FROM sys.assemblies
	SELECT * FROM sys.trusted_assemblies;

	/* Step VI - General Permissions */
	USE ExpressLaneExtracts 
	GO

	ALTER ASSEMBLY ExpressLaneExtracts WITH PERMISSION_SET = EXTERNAL_ACCESS;
 
	 /* Step VII - Give general permissions*/
	USE MASTER;
	GO

	GRANT UNSAFE ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
	GRANT EXTERNAL access ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
 
	USE [ExpressLaneExtracts];
	GO

	GRANT CREATE ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];
	GRANT ALTER ANY ASSEMBLY TO [PHX-DC\gs_phxrtrnsado$];

/****************************************************************************************************************************** 
  Option III - Add the Assembly creating the hash from the Path (If you have the Path)
******************************************************************************************************************************/


/****************************************************************************************************************************** 
 The next error could be:

	The database owner SID recorded in the master database differs from the database owner SID recorded in database 
	'ExpressLaneExtracts'. You should correct this situation by resetting the owner of database 'ExpressLaneExtracts' 
	using the ALTER AUTHORIZATION statement.
******************************************************************************************************************************/

	/* STEP I - Check database user owner */
	SELECT name, suser_sname(owner_sid) FROM master.sys.databases where name = 'ExpressLaneExtracts'

	/* STEP II: Configure the login you want to use as the new DB owner */
	DECLARE @NewOwner SYSNAME = N'PHX-DC\lulibera';  -- 👈 Change this to your sysadmin or service account
 
	/* STEP III: Detect mismatched databases and fix them */
	DECLARE @DBName SYSNAME, @SQL NVARCHAR(MAX);
 
	-- Table variable to capture mismatches for review
	DECLARE @Mismatches TABLE (
		DatabaseName SYSNAME,
		MasterOwner SYSNAME,
		DatabaseOwner SYSNAME,
		FixSQL NVARCHAR(MAX)
	);
 
	-- Cursor through all databases except system ones
	DECLARE db_cursor CURSOR FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE 
		--database_id > 4  -- skip system DBs
		name = 'ExpressLaneExtracts'
	AND state_desc = 'ONLINE';
 

	OPEN db_cursor;
	FETCH NEXT FROM db_cursor INTO @DBName;
 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @OwnerInMaster SYSNAME;
		DECLARE @OwnerInDB SYSNAME;
 
		-- Get owner from master
		SELECT @OwnerInMaster = SUSER_SNAME(owner_sid)
		FROM sys.databases
		WHERE name = @DBName;
 
		-- Get owner inside the database
		DECLARE @SQLGetOwner NVARCHAR(MAX) = N'
			SELECT @OwnerInDB_OUT = name
			FROM sys.database_principals
			WHERE principal_id = 1;
		';
 
		EXEC sp_executesql @SQLGetOwner, 
			N'@OwnerInDB_OUT SYSNAME OUTPUT',
			@OwnerInDB_OUT = @OwnerInDB OUTPUT;
 
		-- Compare SIDs and fix if mismatch
		IF @OwnerInMaster IS NULL OR @OwnerInDB IS NULL OR @OwnerInMaster <> @OwnerInDB
		BEGIN
			SET @SQL = N'ALTER AUTHORIZATION ON DATABASE::' + QUOTENAME(@DBName) + N' TO ' + QUOTENAME(@NewOwner) + N';';
			BEGIN TRY
				EXEC(@SQL);
				-- SELECT @SQL;
				INSERT INTO @Mismatches VALUES (@DBName, @OwnerInMaster, @OwnerInDB, @SQL);
			END TRY
			BEGIN CATCH
				PRINT '⚠️ Failed to change owner for ' + @DBName + ': ' + ERROR_MESSAGE();
			END CATCH
		END
 
		FETCH NEXT FROM db_cursor INTO @DBName;
	END
 
	CLOSE db_cursor;
	DEALLOCATE db_cursor;
 
	/* STEP IV: Review what was fixed */
	SELECT 
		DatabaseName,
		MasterOwner AS OldOwnerInMaster,
		DatabaseOwner AS OldOwnerInDB,
		FixSQL AS ExecutedStatement
	FROM @Mismatches;
 
	/* STEP V: Verify final ownership */
	SELECT 
		name AS DatabaseName,
		suser_sname(owner_sid) AS CurrentOwner
	FROM sys.databases
	WHERE database_id > 4
	ORDER BY name;
```
