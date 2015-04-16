using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace StreamFile
{
    public class Program
    {
        public static bool LeaveOpen = true;

        static void Main(string[] args)
        {
            try
            {
                if (args.Length >= 1)
                {
                    string path = args[0];
                    int buffer = 1024;
                    if (args.Length > 2)
                        buffer = int.Parse(args[1]);

                    using (FileStream fs = File.OpenRead(path))
                    {
                        int read = 1;
                        long length = fs.Length;
                        byte[] chunk = new byte[buffer];
                        
                        StreamFile sf = DataAccess.Open();
                        sf.FileName = Path.GetFileName(path);

                        while (length > 0 && read > 0)
                        {
                            read = fs.Read(chunk, 0, (int)Math.Min(length, buffer));
                            DataAccess.AddChunk(sf.ObjectToken, chunk, sf.StreamFileID);
                            length -= read;
                        }

                        DataAccess.Close(sf.ObjectToken, sf.FileName, sf.StreamFileID);
                    }
                }
                else
                {
                    Console.WriteLine("No input provided.");
                    Console.WriteLine("Usage: StreamFile.exe [File] (buffer_size)");
                }
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Error: {0}", ex.Message);
            }

            if (LeaveOpen)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine();
                Console.WriteLine("Press any key to continue... ");
                Console.ReadKey();
            }

            Console.ResetColor();
        }
    }
}
