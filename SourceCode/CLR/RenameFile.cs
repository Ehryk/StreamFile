using System;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void RenameFile(SqlString source, SqlString destination)
    {
        File.Move(source.Value, destination.Value);
    }
}
