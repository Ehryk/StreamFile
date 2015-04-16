using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void CreateFile(SqlString path)
    {
        using (File.Create(path.Value)) { }
    }
}
