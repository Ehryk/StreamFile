using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void RenameFile(SqlString source, SqlString destination)
    {
        File.Move(source.Value, destination.Value);
    }
}
