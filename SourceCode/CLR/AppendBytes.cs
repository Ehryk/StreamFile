using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void AppendBytes(SqlString path, SqlBinary binary)
    {
        using (FileStream fs = File.Open(path.Value, FileMode.Append))
        {
            fs.Write(binary.Value, 0, binary.Length);
        }
    }
}
