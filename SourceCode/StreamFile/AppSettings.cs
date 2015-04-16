using System.Configuration;

namespace StreamFile
{
    public static class AppSettings
    {
        #region Private Properties (loaded from App.config)

        private static readonly string leaveConsoleOpen = ConfigurationManager.AppSettings["LeaveConsoleOpen"];
        private static readonly string defaultBufferSize = ConfigurationManager.AppSettings["DefaultBufferSize"];

        private static readonly string sp_StreamFile_Start = ConfigurationManager.AppSettings["SP_StreamFile_Start"];
        private static readonly string sp_StreamFile_AddText = ConfigurationManager.AppSettings["SP_StreamFile_AddText"];
        private static readonly string sp_StreamFile_AddBytes = ConfigurationManager.AppSettings["SP_StreamFile_AddBytes"];
        private static readonly string sp_StreamFile_End = ConfigurationManager.AppSettings["SP_StreamFile_End"];
        private static readonly string sp_StreamFile_Cleanup = ConfigurationManager.AppSettings["SP_StreamFile_Cleanup"];

        private static readonly string sp_SaveFile_Text = ConfigurationManager.AppSettings["SP_SaveFileText"];
        private static readonly string sp_SaveFile_Bytes = ConfigurationManager.AppSettings["SP_SaveFileBytes"];

        #endregion

        #region Public Accessors (with defaults)

        public static bool LeaveConsoleOpen { get { return leaveConsoleOpen.ToNullableBoolean() ?? false; } }
        public static int DefaultBufferSize { get { return defaultBufferSize.ToInt(4096); } }

        public static string SP_StreamFile_Start { get { return sp_StreamFile_Start ?? "StreamFile_Start"; } }
        public static string SP_StreamFile_AddText { get { return sp_StreamFile_AddText ?? "StreamFile_AddText"; } }
        public static string SP_StreamFile_AddBytes { get { return sp_StreamFile_AddBytes ?? "StreamFile_AddBytes"; } }
        public static string SP_StreamFile_End { get { return sp_StreamFile_End ?? "StreamFile_End"; } }
        public static string SP_StreamFile_Cleanup { get { return sp_StreamFile_Cleanup ?? "StreamFile_Cleanup"; } }

        public static string SP_SaveFile_Text { get { return sp_SaveFile_Text ?? "SaveFile_Text"; } }
        public static string SP_SaveFile_Bytes { get { return sp_SaveFile_Bytes ?? "SaveFile_Bytes"; } }

        #endregion
    }
}
