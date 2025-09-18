// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Utilities.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.276.2025
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



using StreamRegex.Extensions.Core;
using StreamRegex.Extensions.RegexExtensions;
using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Data.Common;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Windows.ApplicationModel.Calls;

public partial class FindItem : PSCmdlet
{

    /// <summary>
    /// Normalizes paths by removing long path prefixes for non-filesystem use.
    /// </summary>
    /// <param name="path">The path to normalize.</param>
    /// <returns>The normalized path.</returns>
    protected string NormalizePathForNonFileSystemUse(string path)
    {
        // force paths internally to have backslashes
        path = path.Replace("/", "\\");

        // path references user home directory?
        if (path == "~" || path.StartsWith("~\\"))
        {
            string home = this.SessionState.Path.GetResolvedPSPathFromPSPath("~")[0].Path;
            path = path == "~" ? home : Path.Combine(home, path.Substring(2));
        }

        // check for unc long path prefix
        if (path.StartsWith(@"\\?\UNC\", StringComparison.InvariantCultureIgnoreCase))
        {

            // remove prefix and adjust
            string result = @"\\" + path.Substring(8);

            return result;
        }

        // check for local long path prefix
        if (path.StartsWith(@"\\?\"))
        {

            // remove prefix
            string result = path.Substring(4);

            return result;
        }

        // check for alternate unc prefix
        if (path.StartsWith(@"\??\UNC\", StringComparison.InvariantCultureIgnoreCase))
        {

            // remove prefix and adjust
            string result = @"\\" + path.Substring(8);

            return result;
        }

        // check for alternate local prefix
        if (path.StartsWith(@"\??\"))
        {

            // remove prefix
            string result = path.Substring(4);

            return result;
        }

        // return unchanged if no prefix
        return path;
    }

    /// <summary>
    /// Gets the number of physical cores for default parallelism
    /// </summary>
    /// <returns>The count of physical cores.</returns>
    public int GetCoreCount()
    {

        // initialize core count
        int totalPhysicalCores = 0;

        // query wmi for processors
        using (var searcher = new ManagementObjectSearcher("SELECT NumberOfCores FROM Win32_Processor"))
        {

            // sum cores from each processor
            foreach (var item in searcher.Get())
            {
                totalPhysicalCores += Convert.ToInt32(item["NumberOfCores"]);
            }
        }

        // return total cores
        return totalPhysicalCores;
    }

    /// <summary>
    /// Gets available RAM in bytes for resource calculations
    /// </summary>
    /// <returns>Available bytes of RAM.</returns>
    protected long GetFreeRamInBytes()
    {

        // use performance counter for memory
        using (var counter = new PerformanceCounter("Memory", "Available Bytes"))
        {

            // get current value
            long result = (long)counter.NextValue();

            return result;
        }
    }

    /// <summary>
    /// Lists disk shares on a machine using UNC paths.
    /// </summary>
    /// <param name="machineName">The machine to query.</param>
    /// <returns>Array of share names.</returns>
    public static string[] ListDiskSharesUNC(string machineName)
    {

        // attempt to query shares
        try
        {

            // create wmi query for shares
            var query = new ObjectQuery("SELECT * FROM Win32_Share");

            // set scope to machine
            var scope = new ManagementScope($@"\\{machineName}\root\cimv2");

            // connect to scope
            scope.Connect();

            // execute query
            var searcher = new ManagementObjectSearcher(scope, query);

            // get results
            var shares = searcher.Get();

            // prepare list for unc paths
            var uncPaths = new List<string>();

            // process each share
            foreach (ManagementObject share in shares)
            {
                // get type value
                uint typeValue = Convert.ToUInt32(share["Type"]);

                // get share name
                string name = share["Name"]?.ToString() ?? "";

                // check if disk share
                bool isDisk = (typeValue & 0xFFFF) == 0;

                // add if disk and named
                if (isDisk && !string.IsNullOrEmpty(name))
                {
                    uncPaths.Add(name);
                }
            }

            // return as array
            return uncPaths.ToArray<string>();
        }
        catch
        {

            // silent error handling
            // Console.WriteLine($"Error: {ex.Message}"); // Uncomment for
            // debugging
        }

        // return empty on failure
        return new string[0];
    }

    /// <summary>
    /// Adds a path to the search queue and updates counters.
    /// </summary>
    /// <param name="path">The path to enqueue.</param>
    protected void AddToSearchQueue(string path)
    {
        if (UseVerboseOutput) { VerboseQueue.Enqueue($"AddToSearchQueue: '{path}'"); }

        // add to directory queue
        DirQueue.Enqueue(path);

        // increment queued count
        Interlocked.Increment(ref dirsQueued);

        // wait..
        if (!isStarted) return;

        // add workers if needed
        AddWorkerTasksIfNeeded(cts.Token);
    }

    /// <summary>
    /// Gets drives to search based on parameters.
    /// </summary>
    /// <returns>Enumerable of drives.</returns>
    protected IEnumerable<string> GetRootsToSearch()
    {
        // handle all drives switch
        if (this.AllDrives.IsPresent)
        {
            var combinedDrives = DriveInfo.GetDrives()
                 .Where(q => q.IsReady && (IncludeOpticalDiskDrives || q.DriveType != DriveType.CDRom) && q.DriveType != DriveType.Unknown)
                 .Select(q => char.ToUpperInvariant(q.Name[0]))
                 .Union(SearchDrives
                     .Where(q => !string.IsNullOrWhiteSpace(q))
                     .Select(q => char.ToUpperInvariant(q[0]))
                     .Union(DriveLetter
                         .Where(c => !char.IsWhiteSpace(c))
                         .Select(c => char.ToUpperInvariant(c))
                     )
                  );

            foreach (var drive in combinedDrives)
            {
                yield return (drive + ":\\");
            }
        }
        else
        {
            var drives = SearchDrives
                     .Where(q => !string.IsNullOrWhiteSpace(q))
                     .Select(q => char.ToUpperInvariant(q[0]))
                     .Union(DriveLetter
                         .Where(c => !char.IsWhiteSpace(c))
                         .Select(c => char.ToUpperInvariant(c))
                      );

            foreach (var drive in drives)
            {
                yield return (drive + ":\\");
            }
        }
    }

    /// <summary>
    /// Adds worker tasks if below parallelism limit.
    /// </summary>
    protected void AddWorkerTasksIfNeeded(CancellationToken ctx)
    {
        if (ctx.IsCancellationRequested) return;

        // get count of active matches
        long fileMatchesCount = Interlocked.Read(ref this.fileMatchesActive);

        // get count of directories left
        long dirsLeft = Interlocked.Read(ref dirsQueued);

        // get count of files found
        long fileOutputCount = Interlocked.Read(ref filesFound);

        // lock for worker management
        lock (WorkersLock)
        {
            // remove completed workers
            Workers.RemoveAll(w => w.IsCompleted);

            // count active workers
            var currentNrOfDirectoryProcessors = Interlocked.Read(ref this.directoryProcessors);

            // calculate needed matching workers
            var requestedDirectoryProcessors = Math.Min(
                MaxDegreeOfParallelism,
                DirQueue.Count
            );

            // determine missing workers
            long missingDirectoryProcessors = Math.Min(

                requestedDirectoryProcessors - currentNrOfDirectoryProcessors,
                (FileContentMatchQueue.Count <= PatternMatcherOptions.BufferSize / 125) ?
                    Int32.MaxValue :
                    0
            );

            // add missing workers
            // List to hold worker tasks
            while (missingDirectoryProcessors-- > 0)
            {

                // Start worker tasks for parallel directory processing
                AddWorkerTask(Workers, false, ctx);
            }

            // count active workers
            var currentNrOfMatchingProcessors = Interlocked.Read(ref this.matchProcessors);

            // calculate needed matching workers
            var requestedMatchingProcessors = Math.Min(MaxDegreeOfParallelism, FileContentMatchQueue.Count);

            // determine missing workers
            var missingMatchingProcessors = requestedMatchingProcessors - currentNrOfMatchingProcessors;

            // add missing workers
            // List to hold worker tasks
            while (missingMatchingProcessors-- > 0)
            {

                // Start worker tasks for parallel directory processing
                AddWorkerTask(Workers, true, ctx);
            }
        }
    }

    /// <summary>
    /// Adds a single worker task to the list.
    /// </summary>
    /// <param name="workers">The list of workers.</param>
    protected void AddWorkerTask(List<Task> workers, bool contentMatcher, CancellationToken ctx)
    {
        if (UseVerboseOutput) {

            string str = contentMatcher ? "content matcher" : "directory processor";

            VerboseQueue.Enqueue($"Start new {str} worker");
        }

        // need to add a content matcher task?
        if (contentMatcher)
        {
            // update counters
            Interlocked.Increment(ref matchProcessors);

            // add worker
            workers.Add(Task.Run(async () =>
            {
                try
                {
                    string filePath;

                    while (FileContentMatchQueue.TryDequeue(out filePath) && !ctx.IsCancellationRequested)
                    {
                        // try processing
                        try
                        {
                            await FileContentProcessor(filePath, ctx);
                        }
                        catch (Exception ex)
                        {
                            // log failure if verbose
                            if (UseVerboseOutput)
                            {
                                VerboseQueue.Enqueue($"Worker task failed: {ex.Message}");
                            }
                        }
                        finally
                        {
                            if (UseVerboseOutput)
                            {

                                string str = contentMatcher ? "Content matcher" : "Directory processor";

                                VerboseQueue.Enqueue($"{str} worker stopped");
                            }

                            AddWorkerTasksIfNeeded(ctx);
                        }
                    }
                }
                finally
                {
                    Interlocked.Decrement(ref matchProcessors);
                    AddWorkerTasksIfNeeded(ctx);
                }
            }, ctx));

            return;
        }


        Interlocked.Increment(ref directoryProcessors);

        // add new task
        workers.Add(Task.Run(() =>
        {

            // try processing
            try
            {

                // run directory processor
                DirectoryProcessor(cts!.Token);
            }
            catch (Exception ex)
            {

                // log failure if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Worker task failed: {ex.Message}");
                }
            }
            finally
            {
                if (UseVerboseOutput)
                {

                    string str = contentMatcher ? "Content matcher" : "Directory processor";

                    VerboseQueue.Enqueue($"{str} worker stopped");
                }

                Interlocked.Decrement(ref directoryProcessors);
            }
        }));
    }

    /// <summary>
    /// Checks if all workers are completed.
    /// </summary>
    /// <returns>True if all completed.</returns>
    protected bool AllWorkersCompleted()
    {

        // lock for check
        lock (WorkersLock)
        {

            // check for any incomplete
            bool result = !(Workers.Any(w => !w.IsCompleted));

            return result;
        }
    }

    /// <summary>
    /// Executes a PowerShell script and returns the result of type T, handling
    /// any errors that occur.
    /// </summary>
    /// <param name="script">The script to execute.</param>
    /// <returns>The result as type T.</returns>
    protected T InvokeScript<T>(string script)
    {

        // invoke and collect results
        // Invoke the script and collect results
        Collection<PSObject> results = InvokeCommand.InvokeScript(script);

        // check if results match T
        // Return the result if it matches type T
        if (results is T)
        {
            return (T)(object)results;
        }

        // check first result base
        if (results.Count > 0 && results[0].BaseObject is T)
        {
            return (T)results[0].BaseObject;
        }

        // return default on failure
        return default(T);
    }

    // Local method to calculate current depth for recursion limit check
    /// <summary>
    /// Calculates current recursion depth and limit.
    /// </summary>
    /// <param name="CurrentLocation">The current path.</param>
    /// <param name="IsUncPath">If UNC path.</param>
    /// <param name="CurrentRecursionDepth">Output depth.</param>
    /// <param name="CurrentRecursionLimit">Output limit.</param>
    void GetCurrentDepthParameters(string CurrentLocation, bool IsUncPath, out int CurrentRecursionDepth, out int CurrentRecursionLimit)
    {

        // get relative path
        // Compute relative path to determine depth from base
        var relativePath = Path.GetRelativePath(RelativeBasePath, CurrentLocation);

        // adjust leading dot separator
        if (relativePath.StartsWith("." + Path.DirectorySeparatorChar) ||
            relativePath.StartsWith("." + Path.AltDirectorySeparatorChar))
        {
            relativePath = relativePath.Substring(2);
        }
        else if (relativePath.StartsWith(".." + Path.DirectorySeparatorChar) ||
                 relativePath.StartsWith(".." + Path.AltDirectorySeparatorChar))
        {
            relativePath = relativePath.Substring(3);
        }

        // count directory levels
        // Count directory levels in the relative path
        CurrentRecursionDepth = relativePath.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar).Length;

        // set offset based on path type
        // Adjust limit based on path type (UNC or local)
        var offset = IsUncPath ? 4 : 2; // Account for \\server\share\ or C:\

        // compute limit
        CurrentRecursionLimit = MaxRecursionDepth <= 0 ? 0 : Path.IsPathRooted(relativePath) ? (MaxRecursionDepth + offset) : MaxRecursionDepth;
    }

    /// <summary>
    ///     Formats 64-bits integers to string with a semi fixed width
    /// </summary>
    /// <param name="nr">Number to format</param>
    /// <param name="padLeft">When set, will pad spaces to the left side</param>
    /// <returns></returns>
    private string formatStat(long nr, bool padLeft)
    {
        var s = nr.ToString();

        // snap to sizes of 4
        int steps = 3;
        int length = s.Length + (steps - (s.Length % steps));

        return padLeft ?
            (s.PadLeft(length)) :
            (s.PadRight(length));
    }

    /// <summary>
    /// Handles progress queue dequeuing.
    /// </summary>
    /// <param name="all">If to process all.</param>
    private void UpdateProgressStatus(bool force = false)
    {

        // get and convert last timestamp
        var now = DateTime.UtcNow;
        long lastProgress = Interlocked.Read(ref this.lastProgress);
        var time = DateTime.FromBinary(lastProgress);

        // too soon/frequent?
        if (!force && now - time < TimeSpan.FromMilliseconds(250)) return;

        // set current timestamp as the new checkpoint
        lastProgress = now.ToBinary();
        Interlocked.Exchange(ref lastProgress, lastProgress);

        // get output kind
        bool outputtingFiles = FilesAndDirectories.IsPresent || !Directory.IsPresent;

        // get processing actions
        bool matchingContent = outputtingFiles && (Content != ".*" && !string.IsNullOrWhiteSpace(Content));

        // determine if including files based on switches and pattern
        bool andFiles = outputtingFiles && matchingContent;

        // get counters
        long fileMatchesCount = Interlocked.Read(ref this.fileMatchesActive);
        long dirsDone = Interlocked.Read(ref dirsCompleted);
        long dirsLeft = Interlocked.Read(ref dirsQueued);
        long fileMatchesLeft = Interlocked.Read(ref matchesQueued);
        long fileOutputCount = Interlocked.Read(ref filesFound);

        long directoryProcessorsCount = Interlocked.Read(ref directoryProcessors);
        long matchProcessorsCount = Interlocked.Read(ref matchProcessors);
        long fileMatchesStartedCount = Interlocked.Read(ref fileMatchesStarted);
        long fileMatchesCompletedCount = Interlocked.Read(ref fileMatchesCompleted);
        long queuedMatchesCount = FileContentMatchQueue.Count;

        // calculate percent complete
        double ratio = (dirsDone + fileMatchesCompletedCount) / Math.Max(1d, (dirsLeft + fileMatchesLeft));

        // calculate completion percentage for progress
        int progressPercent = (int)Math.Round(

            Math.Min(100,
                Math.Max(0,
                    ratio
                ) * 100d
            ), 0
        );

        // create progress record
        var record = new ProgressRecord(0, "Find-Item", (
            "Scanning directories" + (andFiles ?
            " and found file contents" : "")
        ))
        {

            // set percent complete
            PercentComplete = progressPercent,

            // set status description with counts
            StatusDescription = (
                "Directories: " + formatStat(dirsDone, true) + "/" + formatStat(DirQueue.Count, false) +
                " [" + formatStat(directoryProcessorsCount, false) + "] | Found: " + formatStat(fileOutputCount, false) +
                (matchingContent ? " | Matched: " + formatStat(fileMatchesStartedCount, true) + "/" + formatStat(queuedMatchesCount, false) + " [" + formatStat(matchProcessors, false) + "]" :
                string.Empty)
            ),

            // set current operation message
            CurrentOperation = (
                outputtingFiles && matchingContent ? (
                    dirsLeft - dirsDone == 0 ?
                    "Searching for more files and matching file content" :
                    dirsLeft == 0 ?
                    "Searching for files to match" :
                    "Matching file contents"
                )
                : (
                    outputtingFiles ? (
                        filesFound == 0 ?
                            "Searching for files" :
                            "Searching for more files"
                    ) :
                    "Searching for matching directories"
                )
            )
        };

        // write the progress record
        WriteProgress(record);
    }
}