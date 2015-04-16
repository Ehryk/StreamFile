using System;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void AppendText(SqlString path, SqlString text)
    {
        using (StreamWriter sw = File.AppendText(path.Value))
        {
            sw.Write(text);
        }
    }
}
