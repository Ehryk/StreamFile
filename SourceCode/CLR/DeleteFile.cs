using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void DeleteFile(SqlString path)
    {
        File.Delete(path.Value);
    }
}
