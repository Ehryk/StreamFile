using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace StreamFile
{
    public static class DataAccess
    {
        #region Properties

        private static SqlConnection connection;

        public static string ConnectionString { get; private set; }
        private static SqlConnection Connection
        {
            get
            {
                if (connection != null && connection.State == ConnectionState.Open)
                    return connection;
                
                if (connection != null)
                    connection.Dispose();

                connection = new SqlConnection(ConnectionString);
                connection.Open();
                return connection;
            }
        }

        #endregion

        #region Constructors

        static DataAccess()
        {
            ConnectionString = ConfigurationManager.ConnectionStrings["Main"].ConnectionString;
        }

        #endregion

        #region Streaming Methods

        public static StreamFile Start(string filename = null, bool? overwrite = true, string destination = null)
        {
            var cmd = new SqlCommand(AppSettings.SP_StreamFile_Start, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            if (filename != null)
                cmd.Parameters.AddWithValue("@filename", filename);
            if (overwrite != null)
                cmd.Parameters.AddWithValue("@overwrite", overwrite);
            if (destination != null)
                cmd.Parameters.AddWithValue("@destination", destination);

            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new StreamFile(reader);
            }

            return null;
        }

        public static StreamFile AddBytes(int fileID, byte[] chunk)
        {
            var cmd = new SqlCommand(AppSettings.SP_StreamFile_AddBytes, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@fileID", fileID);
            cmd.Parameters.AddWithValue("@chunk", chunk);

            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new StreamFile(reader);
            }

            return null;
        }

        public static StreamFile AddText(int fileID, string chunk)
        {
            var cmd = new SqlCommand(AppSettings.SP_StreamFile_AddText, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@fileID", fileID);
            cmd.Parameters.AddWithValue("@chunk", chunk);

            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new StreamFile(reader);
            }

            return null;
        }

        public static StreamFile End(int fileID)
        {
            var cmd = new SqlCommand(AppSettings.SP_StreamFile_End, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@fileID", fileID);

            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new StreamFile(reader);
            }

            return null;
        }

        #endregion

        #region Non-Streaming Methods

        public static bool Send(string contents, string filename = null, string destination = null)
        {
            var cmd = new SqlCommand(AppSettings.SP_SaveFile_Text, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@contents", contents);
            if (filename != null)
                cmd.Parameters.AddWithValue("@filename", filename);
            if (destination != null)
                cmd.Parameters.AddWithValue("@destination", destination);

            return (bool)cmd.ExecuteScalar();
        }

        public static bool Send(byte[] contents, string filename = null, string destination = null)
        {
            var cmd = new SqlCommand(AppSettings.SP_SaveFile_Bytes, Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@contents", contents);
            if (filename != null)
                cmd.Parameters.AddWithValue("@filename", filename);
            if (destination != null)
                cmd.Parameters.AddWithValue("@destination", destination);

            return (bool)cmd.ExecuteScalar();
        }

        #endregion
    }
}
