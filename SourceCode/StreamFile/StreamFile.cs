using System;
using System.Data.SqlClient;

namespace StreamFile
{
    public class StreamFile
    {
        public int StreamFileID { get; set; }

        public DateTime? OpenDate { get; set; }
        public int Chunks { get; set; }
        public long FileSize { get; set; }
        public string FileName { get; set; }
        public string FilePath { get; set; }
        public DateTime? CloseDate { get; set; }
        public bool Complete { get; set; }

        public string InsertUser { get; set; }
        public DateTime? InsertDate { get; set; }
        public string UpdateUser { get; set; }
        public DateTime? UpdateDate { get; set; }

        public StreamFile(int fileID = -1)
        {
            StreamFileID = fileID;
        }

        public StreamFile(SqlDataReader reader)
        {
            StreamFileID = reader[0].ToInt();
            OpenDate = reader[1].ToNullableDateTime();
            Chunks = reader[2].ToInt();
            FileSize = reader[3].ToLong();
            FileName = reader[4].ToString();
            FilePath = reader[5].ToString();
            CloseDate = reader[6].ToNullableDateTime();
            Complete = reader[7].ToBoolean();
        }
    }
}
