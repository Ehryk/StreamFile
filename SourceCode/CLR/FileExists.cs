using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static int FileExists(SqlString path)
    {
        return File.Exists(path.Value) ? 1 : 0;
    }
}
