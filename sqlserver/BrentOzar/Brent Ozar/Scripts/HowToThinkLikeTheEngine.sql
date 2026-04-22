
SET STATISTICS IO ON;

-- Query 1
SELECT ID 
FROM dbo.Users;

-- Query 2
-- Porque esta query lee mas paginas? Creo que es el por el paralelismo
SELECT ID 
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01';


-- Query 3
-- Buscar un poco mas de info de MemoryGrant
SELECT ID 
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;

-- Query 4
SELECT *
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;

-- Query 5
/*
CREATE NONCLUSTERED INDEX [IX_LastAccessDate]
ON [dbo].[Users] ([LastAccessDate])
GO
*/

SELECT Id
FROM dbo.Users WITH (INDEX = 1)
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;

SELECT Id
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;

-- Query 6
-- Why an Index Seex read all rows in the table?
SELECT Id
FROM dbo.Users
WHERE LastAccessDate > '1800/07/01'
ORDER BY LastAccessDate;

-- Because SQL doesn't know if '1800/07/01' is all the records.

-- SEEK means: I am going to jump to a row and start reading. Pero no sabe donde va parar de leer
-- SCAN means: I am going to start at either end of the object (might be either the start or the end)
--			   and start reading.
