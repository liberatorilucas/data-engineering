
# <h1 align="center" id="heading">**REGEXP_INSTR - CHARINDEX - PATINDEX**</h1>

<style>
[Heading](#heading)
.large-text {
  font-size: 2em;
}
.small-text {
  font-size: 0.9em;
}
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }

<p class="large-text">This text will be large.</p>
<p class="small-text">This text will be small.</p>
</style>


* CHARINDEX 
    This function searches for one character expression inside a second character expression, returning the starting position of the first expression if found.
	https://learn.microsoft.com/en-us/sql/t-sql/functions/charindex-transact-sql?view=sql-server-ver17

    ```sql
    /* EXAMPLE */
    DECLARE @document AS VARCHAR (64);
    SELECT  @document = 'Reflectors are vital safety' + ' components of your bicycle.';

    SELECT  
        CHARINDEX('bicycle', @document)  AS 'String I'
    , CHARINDEX('vital', @document, 5) AS 'String II'
    , CHARINDEX('bike', @document)     AS 'String II';
    GO
    ```

* PATINDEX
	Returns the starting position of the first occurrence of a pattern in a specified expression, or zero if the pattern isn't found, on all valid text and character data types.
	https://learn.microsoft.com/en-us/sql/t-sql/functions/patindex-transact-sql?view=sql-server-ver17
    
    ```sql
    /* EXAMPLE */
    DECLARE @document AS VARCHAR (64);
    SELECT  @document = 'Reflectors are vital safety' + ' components of your bicycle.';

    SELECT
        PATINDEX('%are%', @document) AS 'String I'
    ,  PATINDEX('%v%', @document) AS 'String II'
    ,  PATINDEX('%sat%', @document) AS 'String III'
    ```

* Comparison Summary

|Feature                    | CHARINDEX                           | PATINDEX                                |
|---------------------------| ----------------------------------- | ------------                            |
|Pattern type			    | Literal string					  | Wildcard pattern (LIKE syntax)          |
|Wildcards supported?		| ❌ No							    |	✅ Yes                                |  
|Start position argument?	| ✅ Yes							    |	❌ No                                 |  
|Performance				| Slightly faster	(simple match)	  |	Slightly slower (pattern match)         |
|Use case					| When searching for exact substrings |	When searching using patterns or wildcards |


* 