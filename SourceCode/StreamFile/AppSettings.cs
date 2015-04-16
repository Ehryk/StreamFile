using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace StreamFile
{
    public static class AppSettings
    {
        #region Private Properties (loaded from App.config)

        private static string leaveConsoleOpen = ConfigurationManager.AppSettings["LeaveConsoleOpen"];
        private static string defaultBufferSize = ConfigurationManager.AppSettings["DefaultBufferSize"];

        private static string sp_StreamFile_Start = ConfigurationManager.AppSettings["SP_StreamFile_Start"];
        private static string sp_StreamFile_AddText = ConfigurationManager.AppSettings["SP_StreamFile_AddText"];
        private static string sp_StreamFile_AddBytes = ConfigurationManager.AppSettings["SP_StreamFile_AddBytes"];
        private static string sp_StreamFile_End = ConfigurationManager.AppSettings["SP_StreamFile_End"];
        private static string sp_StreamFile_Cleanup = ConfigurationManager.AppSettings["SP_StreamFile_Cleanup"];

        private static string sp_SaveFileText = ConfigurationManager.AppSettings["SP_SaveFileText"];
        private static string sp_SaveFileBytes = ConfigurationManager.AppSettings["SP_SaveFileBytes"];

        #endregion

        #region Public Accessors

        public static bool LeaveConsoleOpen { get { return leaveConsoleOpen.ToNullableBoolean() ?? false; } }
        public static int DefaultBufferSize { get { return defaultBufferSize.ToInt(4096); } }

        public static string SP_StreamFile_Start { get { return sp_StreamFile_Start ?? "StreamFile_Start"; } }
        public static string SP_StreamFile_AddText { get { return sp_StreamFile_AddText ?? "StreamFile_AddText"; } }
        public static string SP_StreamFile_AddBytes { get { return sp_StreamFile_AddBytes ?? "StreamFile_AddBytes"; } }
        public static string SP_StreamFile_End { get { return sp_StreamFile_End ?? "StreamFile_End"; } }
        public static string SP_StreamFile_Cleanup { get { return sp_StreamFile_Cleanup ?? "StreamFile_Cleanup"; } }

        public static string SP_SaveFileText { get { return sp_SaveFileText ?? "SaveFileText"; } }
        public static string SP_SaveFileBytes { get { return sp_SaveFileBytes ?? "SaveFileBytes"; } }

        #endregion
    }
}
