using CommandLine;
using CommandLine.Text;

namespace StreamFile
{
    public class Options
    {
        [ValueOption(0)]
        [Option('i', "input", DefaultValue = null, Required = false, HelpText = "Input")]
        public string Input { get; set; }

        [ValueOption(1)]
        [Option('b', "buffer", DefaultValue = "4096", HelpText = "Buffer Size")]
        public int Buffer { get; set; }

        [ValueOption(2)]
        [Option('e', "encoding", DefaultValue = "Default", HelpText = "Encoding")]
        public string Encoding { get; set; }

        [Option('h', "help", DefaultValue = false, HelpText = "Show Help and Usage")]
        public bool Help { get; set; }
        [Option('v', "verbose", DefaultValue = false, HelpText = "Additional output")]
        public bool Verbose { get; set; }
        [Option("version", DefaultValue = false, HelpText = "Print Version and Exit")]
        public bool Version { get; set; }
        [Option('f', "filename", DefaultValue = false, HelpText = "Specify the target filename")]
        public bool Filename { get; set; }
        [Option('t', "text", DefaultValue = false, HelpText = "Pass the file as text")]
        public bool TextMode { get; set; }
        [Option('s', "save", DefaultValue = false, HelpText = "Save the file in one operation rather than streaming")]
        public bool SaveMode { get; set; }
        [Option('n', "nonewline", DefaultValue = false, HelpText = "Do not append last new line to output")]
        public bool NoNewLine { get; set; }
        [Option('c', "color", DefaultValue = false, HelpText = "Disable colored output")]
        public bool NoColor { get; set; }

        //[HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this, (current) => { });
            //return HelpText.AutoBuild(this,
            //  (HelpText current) => HelpText.DefaultParsingErrorsHandler(this, current));
        }

        public static Options Default
        {
            get
            {
                Options defaults = new Options();
                Parser.Default.ParseArguments(new string[] { }, defaults);
                return defaults;
            }
        }
    }
}
