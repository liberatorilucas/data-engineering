using System;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;

namespace SqlClrDemo
{
public class ClrFunctions
{
// A simple deterministic scalar CLR function that returns the input uppercased.
// Attributes: deterministic/precise help SQL Server with optimization and plan caching.
[SqlFunction(IsDeterministic = true, IsPrecise = true)]
public static SqlString EchoToUpper(SqlString input)
{
if (input.IsNull)
return SqlString.Null;

        return new SqlString(input.Value.ToUpperInvariant());
    }
}


}