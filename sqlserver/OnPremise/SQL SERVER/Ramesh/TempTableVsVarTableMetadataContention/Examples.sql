
USE TEMPDB
CREATE TABLE #t1(c1 int, c2 int)
INSERT INTO #t1 VALUES(1, 1), (2, 1), (3, 1)
go


USE tempdb
if exists (select * from sys.objects where name = 'test1')
	drop proc test1
go
CREATE PROC test1 as
begin
	SELECT 'test1: ' + cast(count(*) as nvarchar(1)) from #t1
end
GO

USE TEMPDB
	EXEC test1
go




USE tempdb
if exists (select * from sys.objects where name = 'test2')
	drop proc test2
go
CREATE PROC test2 as
begin
	create table #t1(c1 int, c2 int)
	insert into #t1 values(1,1), (2,1), (3,1), (4,1), (5,1), (6,1), (7,1)
	exec test1
end
GO

USE TEMPDB
	EXEC test2
go
