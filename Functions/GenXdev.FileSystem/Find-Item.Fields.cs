// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Fields.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.284.2025
// ################################################################################
// MIT License
//
// Copyright 2021-2025 GenXdev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ################################################################################



using System.Collections.Concurrent;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;

namespace GenXdev.FileSystem
{

    public partial class FindItem : PSCmdlet
    {

        // current wildcard options for matching
        protected WildcardOptions CurrentWildCardOptions;

        // patterns to exclude files
        protected WildcardPattern[] FileExcludePatterns;

        // patterns to exclude directories
        protected WildcardPattern[] DirectoryExcludePatterns;

        // Tracks visited paths to prevent duplicate processing and avoid infinite
        // loops during traversal
        protected ConcurrentDictionary<string, bool> VisitedNodes;

        // Stores the current working directory for resolving relative paths
        protected string CurrentDirectory = "";

        // Indicates if the cmdlet is running in unattended mode, which affects how
        // output is formatted
        protected bool UnattendedMode = false;

        // Regex to detect recursive search patterns like **
        protected Regex RecursePatternMatcher = new Regex("^\\*\\*\\**$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        // Regex to detect recursive patterns ending with a slash
        protected Regex RecursePatternWithSlashAtEndMatcher = new Regex("^\\*\\*\\**\\\\$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        // Regex to detect recursive patterns starting with **
        protected Regex RecurseStartPatternWithSlashMatcher = new Regex("^\\*\\*\\**\\\\", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        // Regex to detect recursive patterns ending with **
        protected Regex RecurseEndPatternWithSlashAtStartMatcher = new Regex("\\\\\\*\\*\\**$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        // Set of file extensions to skip during content search to avoid processing
        // non-text files
        protected static HashSet<string> ExtensionsToSkip = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
        // Image formats (expanded with more common and specialized types)
        ".gif", ".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp",
        ".ico", ".heic", ".heif",
        ".cr2", ".dng", ".raw", ".3dv", ".amf", ".ai", ".cgm", ".cdr", ".cmx",
        ".dp", ".drawio", ".dxf", ".e2d",
        ".eps", ".fs", ".gbr", ".odg", ".movie.byu", ".3dmlw", ".stl", ".wrl",
        ".x3d", ".sxd", ".tgax", ".v2d",
        ".vdoc", ".vsd", ".vsdx", ".vnd", ".wmf", ".emf", ".art", ".xar",
        ".psd", ".dib", ".jpe", ".jif",
        ".jfi", ".pct", ".pic", ".pnm", ".pbm", ".pgm", ".ppm", ".ras", ".sr",
        ".rgb", ".xbm", ".xpm", ".xwd",

        // Audio formats
        ".mp3", ".wav", ".ogg", ".flac", ".aac", ".wma", ".m4a", ".8svx",
        ".16svx", ".aiff", ".aif", ".aifc",
        ".au", ".bwf", ".cdda", ".dsf", ".dff", ".cwav", ".qau", ".qau0",
        ".iff", ".m3u", ".mid", ".mpa",
        ".ra", ".mka", ".weba", ".opus", ".amr", ".ac3", ".dts", ".gsm",
        ".alac",

        // Video formats
        ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".mpeg", ".mpg",
        ".webm", ".3gp", ".3g2", ".aaf",
        ".at3", ".asf", ".avchd", ".bik", ".braw", ".cam", ".collab",
        ".dvr-ms", ".gmv", ".m4v",
        ".mxf", ".noa", ".nsv", ".ogg", ".qmg", ".rm", ".rmvb", ".svi",
        ".smk", ".swf", ".thp", ".torrent",
        ".wmv", ".wtv", ".yuv", ".h264", ".vob", ".m2v", ".mpe", ".ogv",
        ".mts", ".m2ts", ".divx",

        // Compressed/Archive formats
        ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".ace", ".alz",
        ".arc", ".arj", ".cab", ".cpt",
        ".egg", ".egt", ".ecab", ".ezip", ".ess", ".flipchart", ".fun",
        ".g3fc", ".jar", ".lawrence", ".lbr",
        ".lzh", ".lz", ".lzo", ".lzma", ".lzx", ".mbw", ".mcaddon", ".oar",
        ".pak", ".par", ".par2", ".paf",
        ".pea", ".pyk", ".rax", ".sitx", ".wax", ".z", ".zoo", ".adf",
        ".adz", ".b5t", ".b6t", ".bwt", ".cdi",
        ".cue", ".cif", ".c2d", ".daa", ".d64", ".dmg", ".dms", ".dsk",
        ".esd", ".ffppkg", ".gho", ".ghs",
        ".img", ".iso", ".mds", ".mdx", ".nrg", ".sdi", ".swm", ".tib",
        ".wim", ".deb", ".pkg", ".rpm",
        ".tar.gz", ".z", ".hqx", ".lza", ".sit",

        // Executable and binary formats
        ".exe", ".dll", ".bin", ".msi", ".apk", ".app", ".8bf", ".a",
        ".a.out", ".bac", ".bpl", ".bundle",
        ".class", ".coff", ".com", ".dcu", ".dol", ".ear", ".elf", ".ipa",
        ".jeff", ".ko", ".lib", ".list",
        ".mach-o", ".nlm", ".o", ".obj", ".rll", ".s1es", ".so", ".vap",
        ".war", ".xap", ".xbe", ".xcoff",
        ".xex", ".xpi", ".ocx", ".tlb", ".vbx", ".gadget", ".wsf", ".drv",
        ".sys", ".cpl", ".cur", ".icns",

        // Font formats
        ".ttf", ".otf", ".woff", ".woff2", ".fnt", ".fon",

        // Database and data storage formats
        ".db", ".sqlite", ".mdb", ".accdb", ".4db", ".4dc", ".4dd", ".4dindy",
        ".4dindx", ".4dr", ".4dz",
        ".accde", ".adt", ".apr", ".box", ".chml", ".daf", ".dbf", ".dta",
        ".egt", ".ess", ".eap",
        ".fdb", ".fp", ".fp3", ".fp5", ".fp7", ".frm", ".gdb", ".gtable",
        ".kexi", ".kexic", ".kexis",
        ".ldb", ".lirs", ".mda", ".adp", ".mde", ".mdf", ".myd", ".myi",
        ".ncf", ".nsf", ".ntf", ".nv2",
        ".odb", ".ora", ".pcontact", ".pdb", ".pdi", ".pdx", ".prc", ".rec",
        ".rel", ".rin", ".sdb", ".sdf",
        ".udl", ".wadata", ".waindx", ".wamodel", ".wajournal", ".wdb",
        ".wmdb", ".avro", ".parquet", ".orc",

        // 3D and CAD formats
        ".obj", ".stl", ".3ds", ".dwg", ".dxf", ".3dxml", ".3mf", ".acp",
        ".aec", ".aedt", ".ar", ".asc",
        ".asm", ".brep", ".c3d", ".c3p", ".ccc", ".ccm", ".ccs", ".cad",
        ".catdrawing", ".catpart",
        ".catproduct", ".catprocess", ".cgr", ".dae", ".fbx", ".glb", ".gltf",
        ".iges", ".igs", ".jt",
        ".ply", ".prt", ".sldprt", ".step", ".stp",

        // Other binary or proprietary formats (e.g., from games, multimedia,
        // etc.)
        ".swf", ".midi", ".accde", ".toast", ".vcd", ".3g2", ".h264", ".rm",
        ".vob", ".bz", ".gz", ".midi",
        ".mp3", ".mp4", ".mpeg", ".ogg", ".rar", ".tar", ".tif", ".tiff",
        ".ttf", ".vsd", ".wav", ".webm",
        ".weba", ".woff", ".7z", ".bsp", ".map", ".mdl", ".md2", ".md3",
        ".md5", ".pk3", ".pk4", ".uasset",
        ".uax", ".umap", ".uxx", ".bdl", ".brres", ".bfres", ".dff",
        ".jmesh", ".bmsh", ".ost", ".ccp4",
        ".hitran", ".root", ".csdm", ".csdf", ".csdfe", ".eafx", ".scptd",
        ".xaml", ".omf", ".gxk", ".ssh",
        ".bdl4", ".gmf", ".fes"
    };

        /*
         * Queues for implementing producer-consumer pattern to enable parallel
         * directory processing
         * and coordinated output handling.
         */
        protected readonly ConcurrentQueue<string> DirQueue = new();
        protected readonly ConcurrentQueue<object> OutputQueue = new();
        protected readonly ConcurrentQueue<string> VerboseQueue = new();
        protected readonly ConcurrentQueue<FileInfo> FileContentMatchQueue = new();
        private readonly ConcurrentQueue<MatchContentProcessor> MatchContentProcessors = new();

        protected readonly List<Task> Workers = new List<Task>();
        protected readonly object WorkersLock = new object();
        protected readonly StringBuilder statusBuilder = new StringBuilder(256);


        // Cancellation source to handle timeouts and user interruptions gracefully
        protected CancellationTokenSource cts;

        // only show progress after at least 2 seconds of search activity
        protected long lastProgress = DateTime.UtcNow.AddSeconds(2).ToBinary();

        // Counters for tracking progress: number of files found and directories
        // queued
        protected long directoryProcessors;
        protected long matchProcessors;
        protected long filesFound;
        protected long fileMatchesActive;
        protected long fileMatchesStarted;
        protected long fileMatchesCompleted;
        protected long dirsQueued;
        protected long matchesQueued;
        protected long dirsCompleted;

        // Throughput measurement fields for adaptive scaling (thread-safe)
        protected long lastThroughputMeasurement = DateTime.UtcNow.Ticks;
        protected long lastDirsCompleted = 0;
        protected long lastMatchesCompleted = 0;
        protected long lastOutputCount = 0;
        protected long currentDirThroughputx100 = 0;    // directories/second * 100 (for precision)
        protected long currentMatchThroughputx100 = 0;  // matches/second * 100 (for precision)
        protected long currentOutputThroughputx100 = 0; // outputs/second * 100 (for precision)
        protected long recommendedDirectoryWorkers = 0;
        protected long recommendedMatchWorkers = 0;
        protected readonly object throughputLock = new object(); // Lock for measurement updates

        // Store original thread pool settings to restore after cmdlet execution
        protected int oldMaxWorkerThread;
        protected int oldMaxCompletionPorts;

        // constraints for workers
        protected int baseMemoryPerWorker;
        protected int baseTargetWorkerCount;
        protected Func<bool> buffersFull;
        protected Func<int> maxDirectoryWorkersInParallel;
        protected Func<int> maxMatchWorkersInParallel;

        protected int oldMaxWorkerThreads;
        protected bool isStarted;
        protected bool matchingFileContent;

        /// <summary>
        /// Flag for enabling verbose output based on user preferences
        /// </summary>
        protected bool UseVerboseOutput;

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        protected static extern IntPtr FindFirstStreamW(string lpFileName, uint dwStreamInfoLevel, ref WIN32_FIND_STREAM_DATA lpFindStreamData, uint dwFlags);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        protected static extern bool FindNextStreamW(IntPtr hFindStream, ref WIN32_FIND_STREAM_DATA lpFindStreamData);

        [DllImport("kernel32.dll", SetLastError = true)]
        protected static extern bool FindClose(IntPtr hFindFile);

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        protected struct WIN32_FIND_STREAM_DATA
        {

            public long StreamSize;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 296)]
            public string StreamName;
        }
    }
}
