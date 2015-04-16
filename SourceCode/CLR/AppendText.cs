using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void AppendText(SqlString path, SqlString text)
    {
        using (StreamWriter sw = File.AppendText(path.Value))
        {
            sw.Write(text);
        }
    }
}
