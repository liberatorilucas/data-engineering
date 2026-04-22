# Brent Ozar Course Notes
<style>
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }
</style>

```sql
```  

* Initial Training Page
  
  https://training.brentozar.com/courses/

---

# 1. Mastering Parameter Sniffing

* Index
  - [Reducing the Stench of Sniffing Problems](#Reducing-the-Stench-of-Sniffing-Problems)  
    - [With Index Tuning](#With-Index-Tuning)
    - [RECAP](#RECAP)
    - [With Query Tuning](#With-Query-Tuning)
    - [With Recompile Hints](#With-Recompile-Hints)
    - [Lab 1](#LAB-1)
---

# With Index Tuning
By far, the single biggest causes of parameter sniffing is when SQL Server has to:

  - Choose between an index seek + key lookup versus a table scan, or
  - Choose between two different indexes on the same table, or
  - Choose which table to process first in a join

Let’s see which ones we can reduce with index expansion and tuning.

```sql
/**********************************************************************************************
Mastering Parameter Sniffing
1.1 How Index Tuning Reduces the Stench
**********************************************************************************************/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

/* Set the stage with the right server options & database config. We'll be 
doing this repeatedly for a few modules, and this script should be idempotent. */
USE StackOverflow;
GO
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'Location')
	CREATE INDEX Location ON dbo.Users(Location);
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'_dta_index_Posts_5_85575343__K8')
	EXEC sp_rename @objname = N'dbo.Posts._dta_index_Posts_5_85575343__K8', @newname = N'CreationDate', @objtype = N'INDEX';
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'IX_OwnerUserId')
	EXEC sp_rename @objname = N'dbo.Posts.IX_OwnerUserId', @newname = N'OwnerUserId', @objtype = N'INDEX';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'CreationDate')
	CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'OwnerUserId')
	CREATE INDEX OwnerUserId ON dbo.Posts(OwnerUserId);
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
```

```sql
/* We'll start with a fairly simple proc: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
SELECT TOP 200 
    p.Score
  , p.Title
  , p.Body
  , p.Id
  , p.CreationDate
  , u.DisplayName
  FROM dbo.Posts p
  JOIN dbo.Users u 
  ON   p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.Score DESC;
END
GO

/* And remember that we have this index: */
CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
```

```sql
/* If I pass in a very selective date range, I get an index seek + key lookups: */
EXEC usp_TopScoringPostsByDate @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE;
```

![alt text](Image\EP_1.png)

```sql
/* A less selective range gets a table scan, and it's rightfully slow: */
EXEC usp_TopScoringPostsByDate @StartDate = '2017-01-01', @EndDate = '2017-12-31' WITH RECOMPILE;

/* The question is: how can we strech this SP?

We can fix this by reducing the number of key lookups we do.

We can't cover the entire query: they're asking for the Body of the post. That's big. But remember from 
Fundamentals of Index Tuning: an ORDER BY with a TOP is basically a WHERE clause.

Armed with that, how could we reduce our key lookups? */

CREATE INDEX CreationDate_Score ON dbo.Posts(CreationDate, Score);
GO

/* But now think about the Posts component of the query: */
SELECT TOP 200 CreationDate, Score
FROM   dbo.Posts
WHERE  CreationDate BETWEEN '2017-12-01' AND '2017-12-31'
ORDER BY Score DESC;
GO
```

- The index is sorted by both CreationDate AND Score.
  So what will our query plan look like?

  Poll "The query plan will:"
    1. "Have an index seek and a TOP"
    2. "Have an index seek, then a sort by CreationDate, then a TOP"
    3. "Have an index scan"
    4. "Have a table scan"

  Response
    OPTION 2. After create the index I executed the query. The engine use the new Index. Execute an Index Seek + Order By

    ![alt text](Image\EX_2.png)

```sql
/* Now what happens with the queries and the new index?

If I pass in a very selective date range, I get an index seek + key lookups: */
EXEC usp_TopScoringPostsByDate @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE;
```

- The Engines use the new index.

  ![alt text](Image\EP_3.png)


```sql
/* A less selective range gets a table scan, and it's rightfully slow: */
EXEC usp_TopScoringPostsByDate @StartDate = '2017-01-01', @EndDate = '2017-12-31' WITH RECOMPILE;
```

- The Engines doesn't use the new index.

  ![alt text](Image\EP_4.png)


```sql
/* Index visualization query: */
SELECT CreationDate, Score
FROM   dbo.Posts
WHERE  CreationDate BETWEEN '2017-12-01' AND '2017-12-31'
ORDER BY CreationDate, Score;


/* So basically, EITHER of these indexes would have the same plan here: */
CREATE INDEX CreationDate_Score ON dbo.Posts(CreationDate, Score);
GO
CREATE INDEX CreationDate_Inc ON dbo.Posts(CreationDate) INCLUDE (Score);
GO

/* Don't get too hung up on chasing "perfect." = Perfect, is the enemy of good.

Armed with either of these indexes, how does our plan look now: 

If I pass in a very selective date range, I get an index seek + key lookups: */
EXEC usp_TopScoringPostsByDate @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE;
```

- A GOOD PLAN, As usual we get Index Seek + Kee Lookups
 
```sql
/* Now try the less selective range: bad plan as usual */
EXEC usp_TopScoringPostsByDate @StartDate = '2017-01-01', @EndDate = '2017-12-31' WITH RECOMPILE;
GO
```

- A BAD PLAN, As usual we get Index Seek + Kee Lookups

```sql
/* What if we put the tiny data plan in memory first? */
sp_recompile 'usp_TopScoringPostsByDate';
GO

EXEC usp_TopScoringPostsByDate @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';

/* Then run the big one? */
EXEC usp_TopScoringPostsByDate @StartDate = '2017-01-01', @EndDate = '2017-12-31';
GO
```

- Now on the second query the engine use the new index but we are still executing a Sort.

  ![alt text](Image\EP_5.png)


- The problem is the location of the sort.
  SQL Server usually puts the index seek + key lookup right next to each other, and then sorts the data AFTER it finds the rows.

  What if we:
  1. Used the index to find the rows we want
  2. Sort them
  3. Did the 200 key lookups later?

  To do that, we'll need to coach SQL Server. Here's one way:

  - using CTE
    ```sql
    CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate_CTE @StartDate DATETIME, @EndDate DATETIME AS
    BEGIN

      -- Here we only put the columns that we have on the index
      WITH RowsIWant AS 
      (
        SELECT TOP 200 
          p.Score, 
          p.CreationDate, 
          p.Id
        FROM dbo.Posts p
        WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
        ORDER BY p.Score DESC
      )

      SELECT TOP 200 
        pKeyLookup.Score, 
        pKeyLookup.Title, 
        pKeyLookup.Body, 
        pKeyLookup.Id, 
        pKeyLookup.CreationDate, 
        u.DisplayName
      FROM RowsIWant r
      JOIN dbo.Posts pKeyLookup 
      ON   r.Id = pKeyLookup.Id
      JOIN dbo.Users u 
      ON   pKeyLookup.OwnerUserId = u.Id
      ORDER BY r.Score DESC;
    END
    GO

    sp_recompile 'usp_TopScoringPostsByDate_CTE';
    GO

    EXEC usp_TopScoringPostsByDate_CTE @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';
    ```

    - So now the execution plan changed. The engine execute the Index Seek, then Sort and the the Key Lookups for only 200 records.

      ![alt text](Image\EP_6.png)

    ```sql
    /* Then run the big one? */
    EXEC usp_TopScoringPostsByDate_CTE @StartDate = '2017-01-01', @EndDate = '2017-12-31';
    GO
    ```

    - So now the query finished. execute the same query plan fir both queries "small" and "big"

      ![alt text](Image\EP_7.png)

  - Using TEMPTABLE
    It's kinda like an index hint, but without naming the index.

    ```sql
    CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate_TempTables @StartDate DATETIME, @EndDate DATETIME AS
    BEGIN
      CREATE TABLE #RowsIWant (Id INT);

      INSERT INTO #RowsIWant (Id)
        SELECT TOP 200 p.Id
        FROM dbo.Posts p
        WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
        ORDER BY p.Score DESC;

      SELECT TOP 200 
        pKeyLookup.Score, 
        pKeyLookup.Title, 
        pKeyLookup.Body, 
        pKeyLookup.Id, 
        pKeyLookup.CreationDate, 
        u.DisplayName
      FROM #RowsIWant r
      JOIN dbo.Posts pKeyLookup 
      ON   r.Id = pKeyLookup.Id
      JOIN dbo.Users u 
      ON   pKeyLookup.OwnerUserId = u.Id
      ORDER BY pKeyLookup.Score DESC;
    END
    GO
    ```

    ```sql
    sp_recompile 'usp_TopScoringPostsByDate_TempTables';
    GO
    
    EXEC usp_TopScoringPostsByDate_TempTables @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';
    ```

    - So now, the engine create the temp table and do the sort. Then execute the Keylookups

      ![alt text](Image\EP_8.png)


    ```sql
    /* Then run the big one */
    EXEC usp_TopScoringPostsByDate_TempTables @StartDate = '2017-01-01', @EndDate = '2017-12-31';
    GO
    ```

    - So now, the engine execute the same Plan.

      ![alt text](Image\EP_9.png)


    ```sql
    /* You can still have outliers though: */
    EXEC usp_TopScoringPostsByDate @StartDate = '1970-01-01', @EndDate = '2039-12-31';

    /* If you needed to make THAT fast, then you really need two different plans. More on that later. */
    ```

- Notes
  - Fixing parameter sniffing with indexes is all about giving SQL Server a narrower copy of the data to reduce the blast radius.
  Sometimes we have to encourage SQL Server to use the index by breaking the work up into different phases.

  WE STILL HAVE PARAMETER SNIFFING. These plans can have different:
  * Parallelism
  * Memory grants

  But they will at least look CLOSER than they looked before, and it may not matter AS MUCH which one goes in first.

  If your biggest challenge in a parameter sniffing problem is deciding between an index seek vs key lookup, your goal is to reduce
  the number of key lookups that SQL Server is forced to do. Give it enough in the index to let it do the filtering necessary.

  The index helps you find the rows you want.

  Once you've found the rows you want, 100-10,000 key lookups isn't a big deal at all (and the numbers may go even higher on bigger 
  databases.) Although if someone says they want more than 10,000 rows on a single report, I'm like look, buddy, it's time to do table scans.


- That was a relatively simple filtering problem on one table. But what if the choice is between TWO indexes?

  ```sql
  CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore @StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
  BEGIN
    SELECT TOP 200 
      p.Score, 
      p.Title, 
      p.Body, 
      p.Id, 
      p.CreationDate, 
      u.DisplayName
    FROM dbo.Posts p
    JOIN dbo.Users u 
    ON   p.OwnerUserId = u.Id
    WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND   p.Score >= @MinimumScore
    ORDER BY p.Score DESC;
  END
  GO


  /* If we call it for a narrow date range, we can do our filtering on the index: 
  
  @MinimumScore = 1 Is NOT selective, almost all the users has MinimumScore = 1 */
  EXEC usp_TopScoringPostsByDateAndScore @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01', @MinimumScore = 1 WITH RECOMPILE;
  GO
  ```

  - Here the engine use the CreationDate_Score index to run the Index Seek + Key Lookups

    ![alt text](Image\EP_10.png)


  ```sql
  /* But if we call it for a wide date range, and a narrow score filter: 
  @MinimumScore = 10000 Is selective, almost nobody has MinimumScore = 10000 */
  EXEC usp_TopScoringPostsByDateAndScore  @StartDate = '2016-01-01', @EndDate = '2016-12-31', @MinimumScore = 10000 WITH RECOMPILE;
  GO
  ```
  
  - Here the execution plan is different

  ![alt text](Image\EP_11.png)

  ```sql
  /* Now, an index on Score would be way more effective - because there just aren't a lot of rows that match that narrow predicate.
  If we had an index on Score, CreationDate: */
  CREATE INDEX Score_CreationDate ON dbo.Posts(Score, CreationDate);
  GO

  /* Then SQL Server will pick it when the score is very selective: */
  EXEC usp_TopScoringPostsByDateAndScore @StartDate = '2016-01-01', @EndDate = '2016-12-31', @MinimumScore = 10000 WITH RECOMPILE;
  GO
  ```

  - Here the engine use the new index Score_CreationDate

    ![alt text](Image\12.png)

  ```sql 
  /* But not when the date is very selective, and the score isn't: */
  EXEC usp_TopScoringPostsByDateAndScore @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01', @MinimumScore = 1 WITH RECOMPILE;
  GO
  ```

  - Here the engine use the old index CreationDate_Score

    ![alt text](Image\13.png)


  - Here we have a NEW problem.
  Our problem is NOT choosing between an index seek + key lookup vs a table scan.
  Our problem is choosing between TWO DIFFERENT INDEXES on the same table.

  Index tuning doesn't help here. Query tuning could help

- Now let's take it up a notch and filter on two tables at once:

  ```sql
  CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
  BEGIN
    /* Find the most recent posts from an area */
    SELECT TOP 200 
      u.DisplayName, 
      p.Title, 
      p.Id, 
      p.CreationDate
    FROM dbo.Posts p
    JOIN dbo.Users u 
    ON   p.OwnerUserId = u.Id
    WHERE u.Location     LIKE @Location
    AND   p.CreationDate BETWEEN @StartDate AND @EndDate
    ORDER BY p.CreationDate DESC;
  END
  GO
  ```

  - That's actually really similar to the above proc - but now, SQL Server's biggest challenge is determining WHICH TABLE 
  to process first, and THEN which index to use on that table.

  When the User.Location is very selective, it makes sense to find the users in that location first, then look up their posts.

  When the Post.CreationDate range is very selective, it makes sense to find the posts in that date range first, then look up 
  the users to see if they match.

  If BOTH are very selective, it doesn't really matter which plan we pick.

  If NEITHER is very selective, we'll probably end up with table scans.

  Index tuning alone isn't going to be enough here: when SQL Server has to choose which table to process first, indexing each 
  table isn't going to be enough.


# RECAP

What to take away from this demo:

* <r>If the biggest problem you're trying to solve is the choice between an index seek + key lookup versus a table scan,<r>
  your goal is to find the parts of the filtering & sorting that require key lookups, and see if you can move those to the index instead.

* <r>Even the index alone may not cut it: if we can't fully cover the query, we may need to break the query into phases so that we can do a 
  sort before we do a key lookup.</r>

* If the biggest problem is choosing between <r>two indexes on the same table,</r> index tuning can help, but it's probably not going to be 
  the only solution by itself. We're probably also going to have to introduce branching logic or a recompile hint to let ourselves get 
  different query plans for different sets of parameters.

* If the biggest problem you're trying to solve is <r>which table to process first</r> because different parameters should focus on 
  different tables, indexes alone won't be enough.


# With Query Tuning
In our last module, we hit a wall when we tried to use index tuning to solve a problem where SQL Server had to choose between two different indexes for the same table. Sometimes a date range was more selective, and sometimes a score was more selective.

When you’re facing the problem of which index to process first, try both (or all) of the options and see if there’s one that has the least amount of terribleness.
No, you shouldn’t hint the index by name – instead, just give SQL Server optimization hints that suggest which columns will be more selective, and that way, as index
names change, you’ll still get a working plan. (This beats index hints and plan guides because those will fail as index names change.)

```sql
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

USE StackOverflow;
GO
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId,Score_CreationDate';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'Location')
	CREATE INDEX Location ON dbo.Users(Location);
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'_dta_index_Posts_5_85575343__K8')
	EXEC sp_rename @objname = N'dbo.Posts._dta_index_Posts_5_85575343__K8', @newname = N'CreationDate', @objtype = N'INDEX';
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'IX_OwnerUserId')
	EXEC sp_rename @objname = N'dbo.Posts.IX_OwnerUserId', @newname = N'OwnerUserId', @objtype = N'INDEX';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'CreationDate')
	CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'OwnerUserId')
	CREATE INDEX OwnerUserId ON dbo.Posts(OwnerUserId);
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'Score_CreationDate')
	CREATE INDEX Score_CreationDate ON dbo.Posts(Score, CreationDate);
GO

ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
```

- In the index-tuning module, we hit a wall when we tried to use index tuning alone to solve a tough choice between two indexes, on this proc:
```sql
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore @StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
  SELECT TOP 200 
    p.Score, 
    p.Title,
    p.Body, 
    p.Id, 
    p.CreationDate, 
    u.DisplayName
  FROM dbo.Posts p
  JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  AND   p.Score >= @MinimumScore
  ORDER BY p.Score DESC;
END
GO
```

- There is no one good plan for this.

- If you call it for a SELECTIVE date range and a NON-SELECTIVE score, you need to use the index on CreationDate first:

```sql
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate    = '2009-01-01 10:00', 
	@EndDate      = '2009-01-01 10:01',
	@MinimumScore = 1 
	WITH RECOMPILE;
GO
```

- If you call it for a NON-SELECTIVE date range and a SELECTIVE score, you need to use the index on Score first:

```sql
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate    = '2017-01-01', 
	@EndDate      = '2017-12-31',
	@MinimumScore = 10000 
	WITH RECOMPILE;
GO
```

- If the CreationDate index goes into cache first, and then we call the other, the results are terrible:
- 
```sql
sp_recompile 'usp_TopScoringPostsByDateAndScore';
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate    = '2009-01-01 10:00', 
	@EndDate      = '2009-01-01 10:01',
	@MinimumScore = 1;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2017-01-01', 
	@EndDate		  = '2017-12-31',
	@MinimumScore	= 10000;
GO
```

- If the Score index goes in memory first:

```sql
sp_recompile 'usp_TopScoringPostsByDateAndScore';
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2017-01-01', 
	@EndDate		  = '2017-12-31',
	@MinimumScore	= 10000;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2009-01-01 10:00', 
	@EndDate		  = '2009-01-01 10:01',
	@MinimumScore	= 1;
GO
```

- Wait Wait Wait .... - that's...that's actually not bad! We might be able to live with that plan being used for everything.  Let's try the absolute worst case for it: a score filter that matches ALL posts, and a CreationDate that only matches just one single post:

```sql
SELECT TOP 1 CreationDate FROM dbo.Posts;
GO
-- 2008-07-31 21:42:52.667
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2008-07-31 21:42:52.667', 
	@EndDate		= '2008-07-31 21:42:52.667',
	@MinimumScore	= -100;
GO
```

- In this case:
  - We read ALL of the posts (40 millons records) - that's a lot of logical reads
  - But SQL Server can read data quickly, even with just one core
  - There's no over-allocation of CPU here
  - There's no over-allocation of memory here
  - There aren't a bunch of key lookups

- This might be the least-bad query! If we want to stick with this, we could use an index hint on the SP by name:

```sql
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore @StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
  SELECT TOP 200 
    p.Score, 
    p.Title, 
    p.Body, 
    p.Id, 
    p.CreationDate, 
    u.DisplayName
  FROM dbo.Posts p WITH (INDEX = Score_CreationDate)
  JOIN dbo.Users u 
  ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  AND   p.Score >= @MinimumScore
  ORDER BY p.Score DESC;
END
GO
```

- Try our absolute worst case scenario first, which SHOULD build a query plan that wants the index by CreationDate first:

```sql
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2008-07-31 21:42:52.667', 
	@EndDate		= '2008-07-31 21:42:52.667',
	@MinimumScore	= -100;
GO
```

- Things to note in the actual plan:
	* We get a seek on the Score_CreationDate index
	* Even though Score -100 isn't selective
	* Because SQL Server used the index hint

But if something happens with that index, like if someone renames it:

```sql
EXEC sp_rename 
	@objname = N'dbo.Posts.Score_CreationDate', 
	@newname = N'IX_Score_CreationDate', 
	@objtype = N'INDEX';
GO
```

- So yeah, not a big fan of index hints.
Hint the PARAMETERS instead, and then let SQL Server pick the appropriate index at runtime. Plus, the parameter hints let SQL Server optimize for different parallelism, memory grants, data changes over time, etc:

```sql
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore @StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
  SELECT TOP 200 
    p.Score, 
    p.Title, 
    p.Body, 
    p.Id, 
    p.CreationDate, 
    u.DisplayName
  FROM dbo.Posts p
  JOIN dbo.Users u 
  ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC
  OPTION (OPTIMIZE FOR (@MinimumScore = 100000));
END
GO
```

- Is hinting for score alone enough?

```sql
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2009-01-01 10:00', 
	@EndDate		= '2009-01-01 10:01',
	@MinimumScore	= 1;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2017-01-01', 
	@EndDate		= '2017-12-31',
	@MinimumScore	= 10000;
GO
/* And our worst case: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate		= '2008-07-31 21:42:52.667', 
	@EndDate		= '2008-07-31 21:42:52.667',
	@MinimumScore	= -100;
GO
```

- We can also hint both score and dates:

```sql
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p												/* INDEX HINT IS GONE */
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC
  OPTION (OPTIMIZE FOR (@MinimumScore = 100000, 
  @StartDate = '2008-07-31 21:42:52.667', 
  @EndDate = '2008-07-31 21:42:52.667'));
END
GO
```

```sql
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore @StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
  DECLARE @StringToExecute NVARCHAR(4000);
  SET @StringToExecute = N'
    SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
      FROM dbo.Posts p
      INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
      WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
      AND p.Score >= @MinimumScore
      ORDER BY p.Score DESC ';

/* If they're asking for >60 days, it's big data, so get a fresh plan for it: */
IF DATEDIFF(DD, @StartDate, @EndDate) > 60
	SET @StringToExecute = @StringToExecute + N' OPTION (RECOMPILE) ';

EXEC sp_executesql @StringToExecute, 
	N'@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT',
	@StartDate, @EndDate, @MinimumScore;
END
GO
```

- There are a huge number of hints available, and they keep growing with each new version:
  https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver15

  I don't use these often, but when I do, these are the ones I like:

  - OPTIMIZE FOR specific variables:
	Lets me pick which plan I want to aim for. Works well if the majority of my queries have a similar pattern, like a narrow or wide date range.

	- OPTIMIZE FOR UNKNOWN:
	I don't actually like this much because you're optimizing for the "average" value, and that value can change a lot over time. However, if your query would
	perform well if the "average" value worked well, and if you specifically want to exclude an outlier plan (like Jon Skeet running first), then this works.
	If you find yourself using this a lot, try the database-level setting for disabling parameter sniffing instead (which can also be set differently for AG
	secondaries, which have reporting-style big-data queries.)

	- MAX_GRANT_PERCENT:
	If SQL Server believes a huge amount of memory is necessary for a query, but I know that the predicate is just nonsargable, OR if I know the speed of this
	query just doesn't matter (and I'm okay if it spills to disk), then this lets me limit the grant.

	- MAXDOP:
	You can actually pass in a HIGHER number here than the server's MAXDOP. Useful if you need to run batch reports against something like a Dynamics database
	that would otherwise get MAXDOP 1. When I do this, I tend to hint MAXDOP 8. I don't usually want to take over *all* of the cores on a server. To be clear
	though, this does NOT encourage a parallel plan.

	- OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	This one encourages a parallel plan.

	- Cardinality estimation hotfixes:
	There are hints you can use to ask for a newer or legacy CE, depending on whether your database defaults to the old or new one.

	- QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_n:
	This is Microsoft's attempt to let ISVs ask for a specific CE, and thereby maintain support on newer versions of SQL Server. If they have a query that
	only performs well on the older (or a specific) compat level, they can ask for it at the query level here. I've never met an ISV that had enough time to hint
	all of their queries like this. Your mileage may vary.

	- QUERYTRACEON:
	If you need a specific trace flag, you can do it with this syntax:
	OPTION (QUERYTRACEON 4199, QUERYTRACEON 4137)

	List of supported trace flags:
	https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql
		
    * 4199: query optimizer behavior changes
    * 9398: disables Adaptive Joins
    * 9481: old CE (pre-2014) regardless of compat level
    * 11064: memory balancing for columnstore inserts

	List of all trace flags, including unsupported:
	https://github.com/ktaranov/sqlserver-kit/blob/master/SQL%20Server%20Trace%20Flag.md

    * 8671: spend more time compiling plans, ignore "good enough plan found"
    * 2453: table variables can trigger recompile when rows are inserted

I've seriously never done this in production, but I know a lot of folks that I respect who have, so I'm leaving this here.

RECOMPILE:
But I'll dedicate a whole module to that.

# With Recompile Hints

So far, we’ve added indexes, broken up queries into sections to encourage SQL Server to use those indexes, and even added query-level hints, all in an effort to get one execution plan that works well enough for most scenarios.

But what if you can’t?

Recompile hints are so compelling because they get a brand new customized execution plan for every set of incoming parameters. Option recompile is almost like a cheat code, and I love cheat codes! Let’s talk about when they’re safe to use, when they’ll get you busted, and how to use Erik Darling’s sp_HumanEvents to find out how bad of a problem they are for you already.


  ********************************************************************************
  SI LA QUERY CORRE A CADA MINUTO O MENOS NO USAR OPTION()

  SI LA QUERY CORRE con menos frecuencia 
    REPORTES QUE CORREN CADA MES O 3 O 6 MESES TIENEN QUE USAR OPTION(RECOMPILE)

  escuchar este video de nuevo en el minuto 13:30 .. no termino de entender.
  ********************************************************************************

```sql
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* Set the stage with the right server options & database config. We'll be 
doing this repeatedly for a few modules, and this script should be idempotent. */
USE StackOverflow;
GO
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'Location')
	CREATE INDEX Location ON dbo.Users(Location);
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'_dta_index_Posts_5_85575343__K8')
	EXEC sp_rename @objname = N'dbo.Posts._dta_index_Posts_5_85575343__K8', @newname = N'CreationDate', @objtype = N'INDEX';
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'IX_OwnerUserId')
	EXEC sp_rename @objname = N'dbo.Posts.IX_OwnerUserId', @newname = N'OwnerUserId', @objtype = N'INDEX';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'CreationDate')
	CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'OwnerUserId')
	CREATE INDEX OwnerUserId ON dbo.Posts(OwnerUserId);
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
DBCC FREEPROCCACHE;
GO
```

- We've been hitting a wall when we have a really big choice to make: which table should we process first?

```sql
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
  SELECT TOP 200 
    u.DisplayName, 
    p.Title, 
    p.Id, 
    p.CreationDate
  FROM dbo.Posts p
  JOIN dbo.Users u 
  ON   p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
  AND   p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC;
END
GO
```

- If we run them all with recompile hints, they all add up to < 10 seconds:

```sql
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Outlier data, small dates */
GO
```

- Their actual plans are all over the place! 

- If we truly want every one of them to get their own plan, we can just redefine the stored procedure with a recompile hint built right in:

```sql
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
  SELECT TOP 200 
    u.DisplayName, 
    p.Title, 
    p.Id, 
    p.CreationDate
  FROM dbo.Posts p
  JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC
  OPTION (RECOMPILE) /* THIS IS NEW */;
END
GO
```

- We don't have to ask for a recompile - it's even easier & faster!

```sql
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO
```

- There are 3 drawbacks:

  1. The plans may still not actually be good: if SQL Server has estimation problems, it may still pick bad indexes, grants, orders, etc. That's a separate problem - that's just plain old query tuning. We cover that in Mastering Query Tuning.

  2. The statement-level metrics disappear from cache: note the number of executions for the proc and for the statement:
  sp_BlitzCache;

  3. Each time the query is compiled, there's a CPU hit. This isn't bad in a small stored proc like ours, but it can be a big deal as:
  	* You build the hint into more queries
  	* You build the hint into LARGER queries (that take more CPU time to compile)

- You can see the overhead in each actual plan by looking at its compilation CPU and compilation time metrics, but ain't nobody got time for that.

  Let's see the overhead with sp_HumanEvents: https://www.erikdarlingdata.com/sp_humanevents/

  ```sql
  /* Start this in another window: */
  EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 30;
  GO
  ```
  
  - Then run our workload again:
 
  ```sql
  EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
  EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
  EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
  
  EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
  EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
  EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
  
  EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
  EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
  EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
  
  EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
  EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
  EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
  GO
  ```

  - The compilation overhead on a simple query like that is not bad. However, add more of these:
    * Statements
    * Joins
    * Partitions
    * Plan choices
  
  And compilation time gets worse. To illustrate it, I am going to partition the Users table by CreationDate:

  ```sql
  /* Create a numbers table with 1M rows: */
  DROP TABLE IF EXISTS dbo.Numbers;
  GO
  
  CREATE TABLE Numbers (Number int not null PRIMARY KEY CLUSTERED);
  ;WITH
    Pass0 as (select 1 as C union all select 1), --2 rows
    Pass1 as (select 1 as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select 1 as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select 1 as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select 1 as C from Pass3 as A, Pass3 as B),--65536 rows
    Pass5 as (select 1 as C from Pass4 as A, Pass4 as B),--Bigint
    Tally as (select row_number() over(order by C) as Number from Pass5)
  INSERT dbo.Numbers
          (Number)
      SELECT Number
          FROM Tally
          WHERE Number <= 1000000;
  GO
  ```

  - Create date partition function by day since Stack Overflow's origin, modified from Microsoft Books Online:
  https://docs.microsoft.com/en-us/sql/t-sql/statements/create-partition-function-transact-sql?view=sql-server-ver15#BKMK_examples

  ```sql
  DROP PARTITION SCHEME [DatePartitionScheme];
  DROP PARTITION FUNCTION [DatePartitionFunction];
  
  DECLARE @DatePartitionFunction nvarchar(max) = 
    N'CREATE PARTITION FUNCTION DatePartitionFunction (datetime) 
    AS RANGE RIGHT FOR VALUES (';  
  DECLARE @i datetime = '2008-06-01';
  WHILE @i <= GETDATE()
  BEGIN  
  SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(20)) + '''' + N', ';  
  SET @i = DATEADD(DAY, 1, @i);  
  END  
  SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(20))+ '''' + N');';  
  EXEC sp_executesql @DatePartitionFunction;  
  GO
  
  /* Create matching partition scheme, but put everything in Primary: */
  CREATE PARTITION SCHEME DatePartitionScheme  
  AS PARTITION DatePartitionFunction  
  ALL TO ( [PRIMARY] ); 
  GO

  DROP TABLE IF EXISTS dbo.Users_partitioned;
  GO
  CREATE TABLE [dbo].[Users_partitioned](
    [Id] [int] NOT NULL,
    [AboutMe] [nvarchar](max) NULL,
    [Age] [int] NULL,
    [CreationDate] [datetime] NOT NULL,
    [DisplayName] [nvarchar](40) NOT NULL,
    [DownVotes] [int] NOT NULL,
    [EmailHash] [nvarchar](40) NULL,
    [LastAccessDate] [datetime] NOT NULL,
    [Location] [nvarchar](100) NULL,
    [Reputation] [int] NOT NULL,
    [UpVotes] [int] NOT NULL,
    [Views] [int] NOT NULL,
    [WebsiteUrl] [nvarchar](200) NULL,
    [AccountId] [int] NULL
  ) ON [PRIMARY];
  GO

  CREATE CLUSTERED INDEX CreationDate_Id ON dbo.Users_partitioned (Id) ON DatePartitionScheme(CreationDate);
  GO

  INSERT INTO dbo.Users_partitioned (Id, AboutMe, Age, CreationDate, DisplayName, DownVotes, EmailHash,
    LastAccessDate, Location, Reputation, UpVotes, Views, WebsiteUrl, AccountId)
  SELECT Id, AboutMe, Age, CreationDate, DisplayName, DownVotes, EmailHash,
    LastAccessDate, Location, Reputation, UpVotes, Views, WebsiteUrl, AccountId
  FROM dbo.Users;
  GO
  
  CREATE INDEX Location_Aligned    ON dbo.Users_partitioned(Location);
  CREATE INDEX Location_NotAligned ON dbo.Users(Location) ON [PRIMARY];
  GO

  /* Change the SP */
  CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation_Partitioned @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
  BEGIN
  /* Find the most recent posts from an area */
    SELECT TOP 200 
      u.DisplayName, 
      p.Title, 
      p.Id, 
      p.CreationDate
    FROM dbo.Posts p
    JOIN dbo.Users_partitioned u 
    ON   p.OwnerUserId = u.Id
    WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
    ORDER BY p.CreationDate DESC
    OPTION (RECOMPILE);
  END
  GO

  /* Start this in another window: */
  EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 30;
  GO

  /* Then run our workload again: */
  EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
  
  EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
  
  EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
  
  EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
  EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
  GO
  ```


- Last note: if you're gonna do recompilations in the real world, never put the hint on the outside of the stored procedure like this:

```sql
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME 
  /* This is bad */
  WITH RECOMPILE AS
BEGIN
  /* Find the most recent posts from an area */
  SELECT TOP 200 
      u.DisplayName, 
      p.Title, 
      p.Id, 
      p.CreationDate
  FROM dbo.Posts p
  JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
  AND   p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC;
END
GO    

/* Put them on the inside like this: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC
  OPTION (RECOMPILE); /* This is less bad */
END
GO
```

- Because you'll get some (but not all) monitoring in the plan cache:

```sql
DBCC FREEPROCCACHE;
GO

/* Then run our workload again: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO

sp_BlitzCache;
```

## RECAP
What to take away from this demo:
  
  * If you truly need different plans for every parameter set, statement-level recompile hints are the way to go.

  * I just only use these when the query runs less than a few times per minute, or else the overhead of this (plus the rest of the queries where I end up REQUIRING recompile hints) can add up to a big deal.

  * The easy way to see if it's a big deal on your server already: sp_HumanEvents by Erik Darling.
  https://www.erikdarlingdata.com/sp_humanevents/

# LAB 1

- Setting up for the lab
  1. Restart your SQL Server service (clears all stats)
  2. Restore your StackOverflow database (Agent job)
  3. Copy & run the setup script for Lab 1
  4. (No SQLQueryStress for this lab)

- Task #1: fix these 2 parameters
  EXEC usp_MostRecentCommentsForMe @UserId = 26837, @MinimumCommenterReputation = 0, @MinimumCommentScore = 0
  EXEC usp_MostRecentCommentsForMe @UserId = 22656, @MinimumCommenterReputation = 10000, @MinimumCommentScore = 50

  Get them both to run in <5 seconds no matter which one is called first.

- Task #2: find more outlier params
  Find at least 3 other sets of parameters that might cause a problem for your newly tuned stored proc.
  * Outlier users
  * Outlier minimum reputations
  * Outlier minimum comment scores

- Task #3, optional: fix those too
  Can you tune it so everyone performs in <5 seconds?
  What changes might you consider making? (This one’s really hard.)

- Gotchas
  * Recompile hints are off-limits
  * You’re not allowed to drop indexes: assume all indexes are being used by other queries

