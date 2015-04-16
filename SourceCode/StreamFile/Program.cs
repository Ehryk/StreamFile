using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Diagnostics;
using System.Text;

namespace StreamFile
{
    public class Program
    {
        public static bool LeaveOpen = true;

        static void Main(string[] args)
        {
            var timer = new Stopwatch();
            try
            {
                if (args.Length >= 1)
                {
                    timer.Start();

                    string path = args[0];
                    if (!File.Exists(path))
                        throw new FileNotFoundException(String.Format("File not found: {0}", path));
                    string fileName = Path.GetFileName(path);
                    int buffer = 1024;
                    if (args.Length > 2)
                        buffer = int.Parse(args[1]);

                    long length = 0;
                    using (FileStream fs = File.OpenRead(path))
                    {
                        int read = 1;
                        length = fs.Length;
                        long remaining = length;
                        byte[] chunk = new byte[buffer];
                        
                        StreamFile sf = DataAccess.Create(fileName);

                        while (length > 0 && read > 0)
                        {
                            read = fs.Read(chunk, 0, (int)Math.Min(length, buffer));
                            DataAccess.AddChunk(sf.StreamFileID, Encoding.Unicode.GetString(chunk));
                            remaining -= read;
                        }

                        DataAccess.Close(sf.StreamFileID);
                    }

                    timer.Stop();
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("Transferred {0} ({1:N3} MB) in {2}m{3}.{4:N1}s", fileName, length, timer.Elapsed.TotalMinutes, timer.Elapsed.Seconds, timer.Elapsed.Milliseconds);
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
            finally
            {
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
