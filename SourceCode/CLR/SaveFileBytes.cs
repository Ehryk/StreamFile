using System;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void SaveFileBytes (SqlString path, SqlBinary binary)
    {
        using (FileStream fs = File.Open(path.Value, FileMode.Create))
        {
            fs.Write(binary.Value, 0, binary.Length);
        }
    }
}
