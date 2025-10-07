// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Initialization.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.292.2025
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
using static System.Net.Mime.MediaTypeNames;

namespace GenXdev.FileSystem
{

    /// <summary>
    /// Handles initialization for the FindItem cmdlet.
    /// </summary>
    public partial class FindItem : PSCmdlet
    {
        /// <summary>
        /// set up parallelism based on user input or defaults
        /// </summary>
        private void InitializeParallelismConfiguration()
        {
            // determine actions
            matchingFileContent = Content != null && Content.Length > 0 && (
                (Content.Any(c => c != ".*" && !SimpleMatch.IsPresent) ||
                (Content.Any(c => c != "*" && SimpleMatch.IsPresent))));

            // how many files at once? what user wants, or default to core count
            baseTargetWorkerCount =
                MaxDegreeOfParallelism <= 0 ?
                GetCoreCount() :
                Math.Max(1, MaxDegreeOfParallelism / 2);

            int baseFullLength = Math.Max(2, baseMemoryPerWorker / 125);
            int baseEmptyLength = Math.Max(1, baseMemoryPerWorker / 500);

            // Add intermediate thresholds to prevent oscillation
            int baseHighLength = Math.Max(1, (baseFullLength + baseEmptyLength) / 2);  // ~75% threshold
            int baseLowLength = Math.Max(1, baseEmptyLength + (baseHighLength - baseEmptyLength) / 3);  // ~40% threshold

            bool wasFull = false;
            bool wasHigh = false;
            bool first = true;
            long lastStateChange = 0;

            buffersFull = () =>
            {
                // Cache queue counts to avoid multiple expensive .Count calls
                int fileMatchCount = FileContentMatchQueue.Count;
                int verboseCount = VerboseQueue.Count;
                int dirCount = DirQueue.Count;
                int outputCount = OutputQueue.Count;

                // Find the maximum queue size for state determination
                int maxQueueSize = Math.Max(Math.Max(fileMatchCount, verboseCount),
                                          Math.Max(dirCount, outputCount));

                // Rate limiting: prevent state changes more than once per 100ms
                long now = DateTime.UtcNow.Ticks;
                bool canChangeState = (now - lastStateChange) > TimeSpan.TicksPerMillisecond * 100;

                // Multi-level state machine to prevent oscillation
                if (first)
                {
                    // Initial state determination
                    wasFull = maxQueueSize >= baseFullLength;
                    wasHigh = maxQueueSize >= baseHighLength;
                    first = false;
                    lastStateChange = now;
                    return wasFull;
                }

                // State transition logic with hysteresis
                if (!wasFull && !wasHigh)
                {
                    // Currently in LOW state
                    if (maxQueueSize >= baseHighLength && canChangeState)
                    {
                        wasHigh = true;
                        lastStateChange = now;
                    }
                    else if (maxQueueSize >= baseFullLength && canChangeState)
                    {
                        wasFull = true;
                        wasHigh = true;
                        lastStateChange = now;
                    }
                }
                else if (wasHigh && !wasFull)
                {
                    // Currently in MEDIUM state
                    if (maxQueueSize >= baseFullLength && canChangeState)
                    {
                        wasFull = true;
                        lastStateChange = now;
                    }
                    else if (maxQueueSize <= baseLowLength && canChangeState)
                    {
                        wasHigh = false;
                        lastStateChange = now;
                    }
                }
                else if (wasFull)
                {
                    // Currently in FULL state
                    if (maxQueueSize <= baseEmptyLength && canChangeState)
                    {
                        wasFull = false;
                        wasHigh = false;
                        lastStateChange = now;
                    }
                    else if (maxQueueSize <= baseHighLength && canChangeState)
                    {
                        wasFull = false;
                        lastStateChange = now;
                    }
                }

                return wasFull;
            };

            // stop finding files when the queues get too full
            maxDirectoryWorkersInParallel = () =>
            {
                // we are thinking about the memory being used
                // for storing paths to process
                // On first call (before initial workers start), skip buffer check
                // After that, check all queues including verbose to prevent overflow
                if (!initialWorkerStarted)
                {
                    return Math.Min(
                        DirQueue.Count,
                        Math.Max(
                            baseTargetWorkerCount,
                            (int)Interlocked.Read(ref recommendedDirectoryWorkers)
                        )
                    );
                }

                // After initial worker started, check buffers before allowing more
                return buffersFull() ? 0 :
                    Math.Min(
                        DirQueue.Count,
                        Math.Max(
                            baseTargetWorkerCount,
                            (int)Interlocked.Read(ref recommendedDirectoryWorkers)
                        )
                    );
            };


            // dynamicly scale according to how full buffers are getting
            maxMatchWorkersInParallel = () =>
            {
                int recMatchWorkers = (int)Interlocked.Read(ref recommendedMatchWorkers);
                return Math.Min(
                    Math.Min(
                            // idealy as much as possible
                            FileContentMatchQueue.Count,
                            // if user wants one we take one
                            MaxDegreeOfParallelism == 1 ? 1 : int.MaxValue
                    ),
                    Math.Max(
                        Math.Min(
                            // idealy as much as possible
                            FileContentMatchQueue.Count,
                            // limit to twice the target worker count (or throughput recommendation)
                            Math.Max(baseTargetWorkerCount * 2, recMatchWorkers)
                            // and share it with directory workers
                            // so when they get throttled, we can use more for matching
                            ) - maxDirectoryWorkersInParallel(),
                        Math.Min(
                            // idealy as much as possible
                            FileContentMatchQueue.Count,
                            // limit to twice the target worker count (or throughput recommendation)
                            Math.Max(baseTargetWorkerCount, recMatchWorkers)
                        )
                    )
                );
            };

            // we will only temporarily change the thread pool size
            ThreadPool.GetMaxThreads(out this.oldMaxWorkerThread, out this.oldMaxCompletionPorts);

            int workerThreads = Math.Max(1, Math.Max(this.oldMaxWorkerThread, maxDirectoryWorkersInParallel() * 2));
            int completionPortThreads = Math.Max(1, Math.Max(this.oldMaxCompletionPorts, maxMatchWorkersInParallel()));

            // increase thread pool size if needed
            ThreadPool.SetMaxThreads(

                // worker threads
                // used for Directory processors and Match processors
                workerThreads,

                // used after async IO operations
                completionPortThreads
             );

            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Max worker threads set to {workerThreads}, completion port threads set to {completionPortThreads}");
                VerboseQueue.Enqueue($"Base target worker count: {baseTargetWorkerCount}");
                VerboseQueue.Enqueue($"Using content matching: {matchingFileContent}");
                if (matchingFileContent)
                {
                    VerboseQueue.Enqueue($"Max match workers in parallel: {maxMatchWorkersInParallel()}");
                }
                VerboseQueue.Enqueue($"Max directory workers in parallel: {maxDirectoryWorkersInParallel()}");
                VerboseQueue.Enqueue($"Throughput-based adaptive scaling enabled with 1000ms measurement intervals");
            }

            // Initialize throughput-based recommendations with baseline values (thread-safe)
            Interlocked.Exchange(ref recommendedDirectoryWorkers, baseTargetWorkerCount);
            Interlocked.Exchange(ref recommendedMatchWorkers, baseTargetWorkerCount);
            Interlocked.Exchange(ref lastThroughputMeasurement, DateTime.UtcNow.Ticks);
        }

        /// <summary>
        ///  initialize provided names for searching
        /// </summary>
        private void InitializeProvidedNames()
        {
            // process each unique search mask provided
            if (Name != null && Name.Length > 0)
            {
                // loop through each mask
                foreach (var name in Name)
                {
                    foreach (var namePart in name.Split(";"))
                    {

                        // check if mask already processed to avoid duplicates
                        if (VisitedNodes.TryAdd("start;" + namePart, true))
                        {

                            // log processing of mask if verbose enabled
                            if (UseVerboseOutput)
                            {
                                VerboseQueue.Enqueue($"Processing name: {namePart}");
                            }

                            // prepare search starting point
                            InitializeSearchDirectory(namePart);
                        }
                        else if (UseVerboseOutput)
                        {

                            // log skipping duplicate mask
                            WriteWarning($"Skipping duplicate name: {namePart}");
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Sets up cancellation token with optional timeout.
        /// </summary>
        protected void InitializeCancellationToken()
        {

            // create token source
            // Set up cancellation with optional timeout
            cts = new CancellationTokenSource();

            // apply timeout if specified and greater than 0
            if (TimeoutSeconds.HasValue && TimeoutSeconds.Value > 0)
            {
                cts.CancelAfter(TimeSpan.FromSeconds(TimeoutSeconds.Value));

                // log timeout if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Search timeout set to {TimeoutSeconds.Value} seconds");
                }
            }
            else if (UseVerboseOutput && TimeoutSeconds.HasValue)
            {
                VerboseQueue.Enqueue($"Search timeout set to 0 seconds (no timeout)");
            }
        }

        /// <summary>
        /// Configures buffering for pattern matching.
        /// </summary>
        protected void InitializeBufferingConfiguration()
        {

            // calculate max file size from ram
            // Calculate max file size based on available RAM to prevent memory
            // issues
            baseMemoryPerWorker = Math.Max(
                // minimal 2MB
                1024 * 1024 * 2,
                Math.Min(
                    // max 10 mb
                    1024 * 1024 * 50,

                        (int)Math.Round(

                            // shoot for approximately max 5% of free ram available
                            // for this user invoced PowerShell search
                            (
                                GetFreeRamInBytes() * 0.05d

                             ) / Math.Max(1, Convert.ToDouble(baseTargetWorkerCount)),
                            0
                        )
                )
            );

            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Base memory per worker set to {baseMemoryPerWorker / (1024 * 1024)} MB");
            }
        }

        /// <summary>
        /// Resolves the relative base directory.
        /// </summary>
        protected void InitializeRelativeBaseDir()
        {

            // declare base dir
            string baseDir;

            // check if base path provided
            if (!string.IsNullOrEmpty(RelativeBasePath))
            {

                // use full path if rooted
                if (Path.IsPathRooted(RelativeBasePath))
                {
                    baseDir = Path.GetFullPath(RelativeBasePath);
                }
                else
                {

                    // combine with current if relative
                    baseDir = Path.GetFullPath(Path.Combine(CurrentDirectory, RelativeBasePath));
                }
            }
            else
            {

                // default to current
                baseDir = Path.GetFullPath(CurrentDirectory);
            }

            // set relative base
            RelativeBasePath = baseDir;

            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Using relative base directory: {RelativeBasePath}");
            }
        }

        /// <summary>
        /// Sets the current directory safely.
        /// </summary>
        protected void InitializeCurrentDirectory()
        {
            // get powershell location
            // Get current PowerShell location for base directory
            var psLocation = InvokeScript<string>("(Get-Location).Path");

            // declare safe dir
            string safeDir = null;

            // declare validity
            bool isValid = false;

            // try to validate
            try
            {

                if (psLocation.StartsWith("Microsoft.PowerShell.Core\\FileSystem::\\\\"))
                {
                    // For UNC paths, use the path as-is since Path.GetFullPath can modify UNC paths
                    psLocation = psLocation.Substring("Microsoft.PowerShell.Core\\FileSystem::".Length);
                }

                // get full path
                // Validate and get full path
                safeDir = Path.GetFullPath(psLocation);

                // check existence
                isValid = System.IO.Directory.Exists(safeDir);
            }
            catch
            {

                // log invalid if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Invalid current directory path: {psLocation}");
                }

                // set invalid
                isValid = false;
            }

            // use if valid
            if (isValid)
            {
                CurrentDirectory = safeDir;

                // log if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Using current directory: {CurrentDirectory}");
                }
            }
            else
            {

                // default to profile
                // Default to user profile if current directory invalid
                CurrentDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

                // log default if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Defaulted to user profile directory: {CurrentDirectory}");
                }
            }
        }

        /// <summary>
        /// Sets up exclude patterns for wildcards.
        /// </summary>
        protected void InitializeExcludePatterns()
        {

            // set options based on casing
            this.CurrentWildCardOptions = CaseNameMatching == MatchCasing.PlatformDefault ? (
                         // windows or linux based?
                         Environment.OSVersion.Platform == PlatformID.Win32NT ?
                         WildcardOptions.IgnoreCase |
                         WildcardOptions.CultureInvariant : WildcardOptions.CultureInvariant
                    ) : CaseNameMatching == MatchCasing.CaseInsensitive ? (
                       WildcardOptions.IgnoreCase |
                       WildcardOptions.CultureInvariant
                    ) : WildcardOptions.CultureInvariant;

            // create file exclude patterns
            FileExcludePatterns = Exclude.Select(
                p => WildcardPattern.Get(p, CurrentWildCardOptions)
            ).ToArray();

            // create dir exclude patterns
            DirectoryExcludePatterns = Exclude.Select(
                p => WildcardPattern.Get(p.EndsWith("\\") ? p.TrimEnd('\\') : p, CurrentWildCardOptions)
            ).ToArray();

            // default git exclusion if none
            if (DirectoryExcludePatterns.Length == 0)
            {
                DirectoryExcludePatterns = new WildcardPattern[1] { new WildcardPattern(EscapeBracketsInPattern("*\\.git"), CurrentWildCardOptions) };
            }

            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Using {FileExcludePatterns.Length} file exclude patterns and {DirectoryExcludePatterns.Length} directory exclude patterns.");
                foreach (var pattern in Exclude)
                {
                    VerboseQueue.Enqueue($" Exclude pattern: '{pattern}'");
                }

                if (DirectoryExcludePatterns.Length == 1 && Exclude.Length == 0)
                {
                    VerboseQueue.Enqueue($" Defaulted to exclude pattern: '*.git'");
                }

                if (matchingFileContent && !IncludeNonTextFileMatching.IsPresent)
                {
                    VerboseQueue.Enqueue($"Skipping non text file content based ono file-extensions, use -IncludeNonTextFileMatching to disable");
                }
            }
        }

        /// <summary>
        /// Initializes wildcard matcher and deduplicates excludes.
        /// </summary>
        protected void InitializeWildcardMatcher()
        {

            // deduplicate excludes if present
            if (Exclude != null && Exclude.Length > 0)
            {
                Exclude = Exclude.Distinct().ToArray();
            }
            else
            {

                // set empty if none
                Exclude = Array.Empty<string>();
            }
        }

        /// <summary>
        /// Sets up visited nodes dictionary with appropriate comparer.
        /// </summary>
        protected void InitializeVisitedNodes()
        {

            // create dictionary with casing comparer
            VisitedNodes = new ConcurrentDictionary<string, bool>(
                comparer: (
                       this.CaseNameMatching == MatchCasing.PlatformDefault ?
                       (
                            // windows or linux based?
                            Environment.OSVersion.Platform == PlatformID.Win32NT ?
                            StringComparer.OrdinalIgnoreCase :
                            StringComparer.Ordinal
                       ) : (

                            this.CaseNameMatching == MatchCasing.CaseInsensitive ?
                                StringComparer.OrdinalIgnoreCase :
                                StringComparer.Ordinal
                       )
                    )
            );
        }

        /// <summary>
        /// Initializes verbose output setting
        /// </summary>
        protected void InitializeVerboseOutput()
        {

            // attempt to set verbose
            try
            {

                // check verbose switch
                // Check for -Verbose switch
                bool verboseSwitch = MyInvocation.BoundParameters.ContainsKey("Verbose");

                // check preference if no switch
                // Fall back to VerbosePreference if no switch
                if (!verboseSwitch)
                {

                    // get preference value
                    var verbosePref = InvokeScript<string>("Write-Output ($VerbosePreference)");

                    // evaluate preference
                    verboseSwitch = !string.IsNullOrEmpty(verbosePref) &&
                                   !verbosePref.Equals("SilentlyContinue", StringComparison.OrdinalIgnoreCase);
                }

                // set flag
                UseVerboseOutput = verboseSwitch;
            }
            catch
            {

                // default to false on error
                UseVerboseOutput = false;
            }
        }

        /// <summary>
        /// Prepares search directory from mask.
        /// </summary>
        /// <param name="name">The search mask.</param>
        protected void InitializeSearchDirectory(string name)
        {
            // normalize separators
            // Normalize separators to backslashes for consistency
            name = name.Replace("/", "\\");

            if (name.EndsWith("\\"))
            {
                name += "*";
            }

            // normalize path
            // Normalize the path part for processing
            var normPath = NormalizePathForNonFileSystemUse(name);

            // handle direct current root references
            if (name.StartsWith("\\") && !name.StartsWith("\\\\"))
            {
                name = CurrentDirectory.Substring(0, 2) + name;
            }

            // adjust trailing recurse
            // Adjust for trailing recursive patterns
            if (RecurseEndPatternWithSlashAtStartMatcher.IsMatch(normPath))
            {
                normPath += "\\";
            }

            // determine path types
            // Determine path type for correct handling
            bool isRooted = Path.IsPathRooted(normPath);
            bool isUncPath = normPath.StartsWith(@"\\");

            bool isRelative = !isRooted && !isUncPath && !normPath.StartsWith("~");

            // add it
            if (UseVerboseOutput) { VerboseQueue.Enqueue($"Adding name: '{name}'"); }
            AddToSearchQueue(name);

            // add more roots?
            if (isRelative && Root != null && Root.Length > 0)
            {
                foreach (string path in Root)
                {
                    if (UseVerboseOutput) { VerboseQueue.Enqueue($"Adding for path '{path}' with name: '{name}'"); }
                    AddToSearchQueue(Path.Combine(path, name));
                }
            }

            // Process search for each specified drive
            foreach (var root in GetRootsToSearch())
            {
                if (UseVerboseOutput) { VerboseQueue.Enqueue($"Adding for root '{root}' with name: '{name}'"); }
                AddToSearchQueue(Path.Combine(root, name));
            }
        }
    }
}