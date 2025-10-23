// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Fields.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 2.1.2025
// ################################################################################
// Copyright (c)  René Vaessen / GenXdev
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ################################################################################



using System.Collections.Concurrent;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;

namespace GenXdev.FileSystem
{

    public partial class FindItem : PSGenXdevCmdlet
    {

        /// <summary>
        /// Current wildcard options for matching file and directory names.
        /// </summary>
        protected WildcardOptions CurrentWildCardOptions;

        /// <summary>
        /// Patterns to exclude files from the search results.
        /// </summary>
        protected WildcardPattern[] FileExcludePatterns;

        /// <summary>
        /// Patterns to exclude directories from the search traversal.
        /// </summary>
        protected WildcardPattern[] DirectoryExcludePatterns;

        /// <summary>
        /// Tracks visited paths to prevent duplicate processing and avoid infinite
        /// loops during traversal.
        /// </summary>
        protected ConcurrentDictionary<string, bool> VisitedNodes;

        /// <summary>
        /// Stores the current working directory for resolving relative paths.
        /// </summary>
        protected string CurrentDirectory = "";

        /// <summary>
        /// Indicates if the cmdlet is running in unattended mode, which affects how
        /// output is formatted.
        /// </summary>
        protected bool UnattendedMode = false;

        /// <summary>
        /// Regex to detect recursive search patterns like **.
        /// </summary>
        protected Regex RecursePatternMatcher = new Regex("^\\*\\*\\**$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        /// <summary>
        /// Regex to detect recursive patterns ending with a slash.
        /// </summary>
        protected Regex RecursePatternWithSlashAtEndMatcher = new Regex("^\\*\\*\\**\\\\$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        /// <summary>
        /// Regex to detect recursive patterns starting with **.
        /// </summary>
        protected Regex RecurseStartPatternWithSlashMatcher = new Regex("^\\*\\*\\**\\\\", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        /// <summary>
        /// Regex to detect recursive patterns ending with **.
        /// </summary>
        protected Regex RecurseEndPatternWithSlashAtStartMatcher = new Regex("\\\\\\*\\*\\**$", RegexOptions.Compiled | RegexOptions.CultureInvariant);

        /// <summary>
        /// Set of file extensions to skip during content search to avoid processing
        /// non-text files.
        /// </summary>
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
        /// <summary>
        /// Queue for directories to be processed in parallel.
        /// </summary>
        protected readonly ConcurrentQueue<string> DirQueue = new();

        /// <summary>
        /// Dictionary for tracking upward directory traversal.
        /// </summary>
        protected readonly ConcurrentDictionary<string, int> UpwardsDirQueue = new();

        /// <summary>
        /// Queue for output objects to be written to the pipeline.
        /// </summary>
        protected readonly ConcurrentQueue<object> OutputQueue = new();

        /// <summary>
        /// Queue for verbose messages to be displayed.
        /// </summary>
        protected readonly ConcurrentQueue<string> VerboseQueue = new();

        /// <summary>
        /// Queue for files that match content search criteria.
        /// </summary>
        protected readonly ConcurrentQueue<FileInfo> FileContentMatchQueue = new();

        /// <summary>
        /// Queue for content match processors.
        /// </summary>
        private readonly ConcurrentQueue<MatchContentProcessor> MatchContentProcessors = new();

        /// <summary>
        /// List of worker tasks for parallel processing.
        /// </summary>
        protected readonly List<Task> Workers = new List<Task>();

        /// <summary>
        /// Lock object for synchronizing access to the workers list.
        /// </summary>
        protected readonly object WorkersLock = new object();

        /// <summary>
        /// String builder for constructing status messages.
        /// </summary>
        protected readonly StringBuilder statusBuilder = new StringBuilder(256);

        /// <summary>
        /// Cancellation source to handle timeouts and user interruptions gracefully.
        /// </summary>
        protected CancellationTokenSource cts;

        /// <summary>
        /// Timestamp for last progress display, delayed by 2 seconds from start.
        /// </summary>
        protected long lastProgress = DateTime.UtcNow.AddSeconds(2).ToBinary();

        /// <summary>
        /// Counters for tracking progress: number of files found and directories queued.
        /// </summary>
        protected long directoryProcessors;

        /// <summary>
        /// Counter for match processors.
        /// </summary>
        protected long matchProcessors;

        /// <summary>
        /// Counter for total files found.
        /// </summary>
        protected long filesFound;

        /// <summary>
        /// Counter for active file content matches.
        /// </summary>
        protected long fileMatchesActive;

        /// <summary>
        /// Counter for started file content matches.
        /// </summary>
        protected long fileMatchesStarted;

        /// <summary>
        /// Counter for completed file content matches.
        /// </summary>
        protected long fileMatchesCompleted;

        /// <summary>
        /// Counter for directories queued for processing.
        /// </summary>
        protected long dirsQueued;

        /// <summary>
        /// Counter for matches queued.
        /// </summary>
        protected long matchesQueued;

        /// <summary>
        /// Counter for directories completed.
        /// </summary>
        protected long dirsCompleted;

        /// <summary>
        /// Throughput measurement fields for adaptive scaling (thread-safe).
        /// </summary>
        protected long lastThroughputMeasurement = DateTime.UtcNow.Ticks;

        /// <summary>
        /// Last count of directories completed for throughput calculation.
        /// </summary>
        protected long lastDirsCompleted = 0;

        /// <summary>
        /// Last count of matches completed for throughput calculation.
        /// </summary>
        protected long lastMatchesCompleted = 0;

        /// <summary>
        /// Last count of output items for throughput calculation.
        /// </summary>
        protected long lastOutputCount = 0;

        /// <summary>
        /// Current directory processing throughput (directories/second * 100 for precision).
        /// </summary>
        protected long currentDirThroughputx100 = 0;

        /// <summary>
        /// Current match processing throughput (matches/second * 100 for precision).
        /// </summary>
        protected long currentMatchThroughputx100 = 0;

        /// <summary>
        /// Current output throughput (outputs/second * 100 for precision).
        /// </summary>
        protected long currentOutputThroughputx100 = 0;

        /// <summary>
        /// Recommended number of directory workers based on throughput.
        /// </summary>
        protected long recommendedDirectoryWorkers = 0;

        /// <summary>
        /// Recommended number of match workers based on throughput.
        /// </summary>
        protected long recommendedMatchWorkers = 0;

        /// <summary>
        /// Lock for measurement updates to ensure thread safety.
        /// </summary>
        protected readonly object throughputLock = new object();

        /// <summary>
        /// Store original thread pool settings to restore after cmdlet execution.
        /// </summary>
        protected int oldMaxWorkerThread;

        /// <summary>
        /// Original completion ports setting.
        /// </summary>
        protected int oldMaxCompletionPorts;

        /// <summary>
        /// Base memory allocation per worker thread.
        /// </summary>
        protected int baseMemoryPerWorker;

        /// <summary>
        /// Base target number of worker threads.
        /// </summary>
        protected int baseTargetWorkerCount;

        /// <summary>
        /// Function to check if processing buffers are full.
        /// </summary>
        protected Func<bool> buffersFull;

        /// <summary>
        /// Function to get maximum directory workers in parallel.
        /// </summary>
        protected Func<int> maxDirectoryWorkersInParallel;

        /// <summary>
        /// Function to get maximum match workers in parallel.
        /// </summary>
        protected Func<int> maxMatchWorkersInParallel;

        /// <summary>
        /// Original maximum worker threads setting.
        /// </summary>
        protected int oldMaxWorkerThreads;

        /// <summary>
        /// Flag indicating if the cmdlet has started processing.
        /// </summary>
        protected bool isStarted;

        /// <summary>
        /// Start time of the cmdlet execution.
        /// </summary>
        protected DateTime startTime = DateTime.UtcNow;

        /// <summary>
        /// Flag indicating if the cmdlet has received input.
        /// </summary>
        protected bool hadInput;

        /// <summary>
        /// Flag indicating if content matching is enabled.
        /// </summary>
        protected bool matchingFileContent;

        /// <summary>
        /// Flag indicating if the initial worker has been started.
        /// </summary>
        protected bool initialWorkerStarted;

        /// <summary>
        /// Flag for enabling verbose output based on user preferences.
        /// </summary>
        protected bool UseVerboseOutput;

        /// <summary>
        /// Windows API function to find the first stream in a file.
        /// </summary>
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        protected static extern IntPtr FindFirstStreamW(string lpFileName, uint dwStreamInfoLevel, ref WIN32_FIND_STREAM_DATA lpFindStreamData, uint dwFlags);

        /// <summary>
        /// Windows API function to find the next stream in a file.
        /// </summary>
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        protected static extern bool FindNextStreamW(IntPtr hFindStream, ref WIN32_FIND_STREAM_DATA lpFindStreamData);

        /// <summary>
        /// Windows API function to close a find stream handle.
        /// </summary>
        [DllImport("kernel32.dll", SetLastError = true)]
        protected static extern bool FindClose(IntPtr hFindFile);

        /// <summary>
        /// Structure for Windows find stream data.
        /// </summary>
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        protected struct WIN32_FIND_STREAM_DATA
        {

            /// <summary>
            /// Size of the stream in bytes.
            /// </summary>
            public long StreamSize;

            /// <summary>
            /// Name of the stream.
            /// </summary>
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 296)]
            public string StreamName;
        }
    }
}
