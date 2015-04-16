using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void SaveFileText (SqlString path, SqlString text)
    {
        using (StreamWriter sw = File.CreateText(path.Value))
        {
            sw.Write(text.Value);
        }
    }
}
