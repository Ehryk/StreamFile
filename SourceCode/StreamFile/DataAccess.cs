using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
                if (connection != null && connection.State == System.Data.ConnectionState.Open)
                    return connection;
                else if (connection != null)
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

        public static StreamFile Open()
        {
            var cmd = new SqlCommand("StreamFile_Open", Connection);
            cmd.CommandType = CommandType.StoredProcedure;

            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new StreamFile(reader.GetInt32(0), reader.GetInt32(1));
            }

            return null;
        }

        public static bool AddChunk(int token, byte[] chunk, int? streamID = null)
        {
            var cmd = new SqlCommand("StreamFile_AddChunk", Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@token", token);
            cmd.Parameters.AddWithValue("@chunk", chunk);
            if (streamID != null)
                cmd.Parameters.AddWithValue("@streamID", streamID);

            int rows = cmd.ExecuteNonQuery();
            return rows == 1;
        }

        public static bool AddChunk(int token, string chunk, int? streamID = null)
        {
            var cmd = new SqlCommand("StreamFile_AddChunkText", Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@token", token);
            cmd.Parameters.AddWithValue("@chunk", chunk);
            if (streamID != null)
                cmd.Parameters.AddWithValue("@streamID", streamID);

            int rows = cmd.ExecuteNonQuery();
            return rows == 1;
        }

        public static bool Close(int token, string filename = null, int? streamID = null, string destination = null)
        {
            var cmd = new SqlCommand("StreamFile_Close", Connection);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@token", token);
            cmd.Parameters.AddWithValue("@filename", filename);
            if (streamID != null)
                cmd.Parameters.AddWithValue("@streamID", streamID);
            if (destination != null)
                cmd.Parameters.AddWithValue("@destination", destination);

            int rows = cmd.ExecuteNonQuery();
            return rows == 1;
        }

        #endregion

        #region Non-Streaming Methods

        public static bool Send(string contents, string filename = null, string destination = null)
        {
            var cmd = new SqlCommand("SendFileText", Connection);
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
            var cmd = new SqlCommand("SendFile", Connection);
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
