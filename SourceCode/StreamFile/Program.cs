using System;
using System.IO;
using System.Diagnostics;

namespace StreamFile
{
    public class Program
    {
        static void Main(string[] args)
        {
            var timer = new Stopwatch();
            try
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine(" === {0} v{1}.{2} === ", ApplicationInfo.Title, ApplicationInfo.Version.Major, ApplicationInfo.Version.Minor);
                Console.WriteLine();
                Console.ResetColor();

                if (args.Length >= 1)
                {
                    timer.Start();

                    string path = args[0];
                    if (!File.Exists(path))
                        throw new FileNotFoundException(String.Format("File not found: {0}", path));
                    string fileName = Path.GetFileName(path);
                    int buffer = AppSettings.DefaultBufferSize;
                    if (args.Length > 2)
                        buffer = int.Parse(args[1]);

                    Console.Write("Streaming {0} in chunks of {1} bytes... ", fileName, buffer);

                    long length;
                    using (FileStream fs = File.OpenRead(path))
                    {
                        int read = 1;
                        int chunks = 0;
                        length = fs.Length;
                        long remaining = length;
                        byte[] chunk = new byte[buffer];

                        StreamFile sf = DataAccess.Start(fileName);

                        while (remaining > 0 && read > 0)
                        {
                            read = fs.Read(chunk, 0, (int)Math.Min(length, buffer));
                            DataAccess.AddBytes(sf.StreamFileID, chunk);
                            remaining -= read;
                            chunks++;
                        }

                        DataAccess.End(sf.StreamFileID);
                        Console.WriteLine("Done ({0} chunks).", chunks);
                    }

                    timer.Stop();
                    Console.ForegroundColor = ConsoleColor.White;
                    Console.WriteLine("Transferred {0} ({1:N3} MB) in {2}m {3}.{4}s", fileName, length/1024.0/1024.0, Math.Floor(timer.Elapsed.TotalMinutes), timer.Elapsed.Seconds, timer.Elapsed.Milliseconds);
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

            if (AppSettings.LeaveConsoleOpen)
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
