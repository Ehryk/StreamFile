using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace StreamFile
{
    public class StreamFile
    {
        public int StreamFileID { get; set; }

        public int ObjectToken { get; set; }
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

        public StreamFile(int token, int streamID = -1)
        {
            StreamFileID = streamID;
            ObjectToken = token;
        }
    }
}
