// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Utilities.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.288.2025
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



using Microsoft.PowerShell.Commands;
using System;
using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Management;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;

namespace GenXdev.FileSystem
{
    public partial class FindItem : PSCmdlet
    {

        /// <summary>
        /// Measures throughput every 1000ms and adjusts recommended worker counts based on processing rates.
        /// Thread-safe implementation using locks and atomic operations.
        /// </summary>
        private void MeasureThroughputAndAdjustWorkers()
        {
            // Early exit if not enough time has passed (thread-safe read)
            long now = DateTime.UtcNow.Ticks;
            long lastMeasurement = Interlocked.Read(ref lastThroughputMeasurement);
            long timeSinceLastMeasurement = now - lastMeasurement;

            // Only measure every 1000ms (10,000,000 ticks = 1 second)
            if (timeSinceLastMeasurement < TimeSpan.TicksPerSecond)
                return;

            // Use lock to ensure only one thread performs measurement at a time
            lock (throughputLock)
            {
                // Double-check pattern: verify time hasn't been updated by another thread
                long currentLastMeasurement = Interlocked.Read(ref lastThroughputMeasurement);
                if (now - currentLastMeasurement < TimeSpan.TicksPerSecond)
                    return;

                // Get current counters atomically
                long currentDirsCompleted = Interlocked.Read(ref dirsCompleted);
                long currentMatchesCompleted = Interlocked.Read(ref fileMatchesCompleted);
                long currentOutputs = Interlocked.Read(ref filesFound);

                // Calculate deltas since last measurement
                long dirsDelta = currentDirsCompleted - lastDirsCompleted;
                long matchesDelta = currentMatchesCompleted - lastMatchesCompleted;
                long outputDelta = currentOutputs - lastOutputCount;

                // Calculate time elapsed in seconds
                double secondsElapsed = timeSinceLastMeasurement / (double)TimeSpan.TicksPerSecond;

                // Calculate throughput rates (items per second * 100 for precision)
                long newDirThroughputx100 = (long)((dirsDelta / secondsElapsed) * 100.0);
                long newMatchThroughputx100 = (long)((matchesDelta / secondsElapsed) * 100.0);
                long newOutputThroughputx100 = (long)((outputDelta / secondsElapsed) * 100.0);

                // Update throughput values atomically
                Interlocked.Exchange(ref currentDirThroughputx100, newDirThroughputx100);
                Interlocked.Exchange(ref currentMatchThroughputx100, newMatchThroughputx100);
                Interlocked.Exchange(ref currentOutputThroughputx100, newOutputThroughputx100);

                // Adaptive scaling algorithm (inside lock for consistency)
                CalculateRecommendedWorkerCounts(dirsDelta, matchesDelta, secondsElapsed);

                // Update measurement baseline atomically
                Interlocked.Exchange(ref lastThroughputMeasurement, now);
                Interlocked.Exchange(ref lastDirsCompleted, currentDirsCompleted);
                Interlocked.Exchange(ref lastMatchesCompleted, currentMatchesCompleted);
                Interlocked.Exchange(ref lastOutputCount, currentOutputs);

                if (UseVerboseOutput)
                {
                    double dirThroughput = newDirThroughputx100 / 100.0;
                    double matchThroughput = newMatchThroughputx100 / 100.0;
                    double outputThroughput = newOutputThroughputx100 / 100.0;
                    long recDirWorkers = Interlocked.Read(ref recommendedDirectoryWorkers);
                    long recMatchWorkers = Interlocked.Read(ref recommendedMatchWorkers);

                    VerboseQueue.Enqueue($"Throughput: Dir={dirThroughput:F1}/s, Match={matchThroughput:F1}/s, Output={outputThroughput:F1}/s");
                    VerboseQueue.Enqueue($"Recommended workers: Dir={recDirWorkers}, Match={recMatchWorkers}");
                }
            }
        }

        /// <summary>
        /// Calculates recommended worker counts based on throughput analysis.
        /// Must be called within throughputLock for thread safety.
        /// </summary>
        private void CalculateRecommendedWorkerCounts(long dirsDelta, long matchesDelta, double secondsElapsed)
        {
            // Get current queue sizes and worker counts atomically
            int dirQueueSize = DirQueue.Count;
            int matchQueueSize = FileContentMatchQueue.Count;
            long currentDirWorkers = Interlocked.Read(ref directoryProcessors);
            long currentMatchWorkers = Interlocked.Read(ref matchProcessors);

            // Calculate throughput from parameters (avoid reading non-atomic fields)
            double currentDirThroughput = dirsDelta / secondsElapsed;
            double currentMatchThroughput = matchesDelta / secondsElapsed;

            // Calculate directory worker recommendations
            long newRecommendedDirWorkers;
            if (currentDirThroughput > 0 && dirQueueSize > 0)
            {
                // Estimate time to clear queue at current rate
                double timeToClearDirs = dirQueueSize / currentDirThroughput;

                // If it would take > 10 seconds, increase workers
                // If it would take < 2 seconds, decrease workers
                if (timeToClearDirs > 10.0 && currentDirWorkers < baseTargetWorkerCount * 2)
                {
                    newRecommendedDirWorkers = Math.Min(
                        baseTargetWorkerCount * 2,
                        currentDirWorkers + Math.Max(1, (long)(timeToClearDirs / 10.0))
                    );
                }
                else if (timeToClearDirs < 2.0 && currentDirWorkers > 1)
                {
                    newRecommendedDirWorkers = Math.Max(1, currentDirWorkers - 1);
                }
                else
                {
                    newRecommendedDirWorkers = Math.Max(baseTargetWorkerCount, currentDirWorkers);
                }
            }
            else
            {
                // No throughput data, use baseline
                newRecommendedDirWorkers = baseTargetWorkerCount;
            }

            // Calculate match worker recommendations
            long newRecommendedMatchWorkers;
            if (currentMatchThroughput > 0 && matchQueueSize > 0)
            {
                // Estimate time to clear queue at current rate
                double timeToClearMatches = matchQueueSize / currentMatchThroughput;

                // If it would take > 10 seconds, increase workers
                // If it would take < 2 seconds, decrease workers
                if (timeToClearMatches > 10.0 && currentMatchWorkers < baseTargetWorkerCount * 3)
                {
                    newRecommendedMatchWorkers = Math.Min(
                        baseTargetWorkerCount * 3,
                        currentMatchWorkers + Math.Max(1, (long)(timeToClearMatches / 10.0))
                    );
                }
                else if (timeToClearMatches < 2.0 && currentMatchWorkers > 1)
                {
                    newRecommendedMatchWorkers = Math.Max(1, currentMatchWorkers - 1);
                }
                else
                {
                    newRecommendedMatchWorkers = Math.Max(baseTargetWorkerCount, currentMatchWorkers);
                }
            }
            else
            {
                // No throughput data, use baseline
                newRecommendedMatchWorkers = baseTargetWorkerCount;
            }

            // Apply output pressure feedback
            // If output rate is very low compared to processing, something is bottlenecked
            double outputThroughput = Interlocked.Read(ref filesFound) / secondsElapsed;
            if (outputThroughput > 0 && currentDirThroughput > 0)
            {
                double outputRatio = outputThroughput / Math.Max(currentDirThroughput, currentMatchThroughput);

                // If output ratio is very low, reduce workers to prevent queue buildup
                if (outputRatio < 0.1)
                {
                    newRecommendedDirWorkers = Math.Max(1, newRecommendedDirWorkers / 2);
                    newRecommendedMatchWorkers = Math.Max(1, newRecommendedMatchWorkers / 2);
                }
            }

            // Update recommendations atomically
            Interlocked.Exchange(ref recommendedDirectoryWorkers, newRecommendedDirWorkers);
            Interlocked.Exchange(ref recommendedMatchWorkers, newRecommendedMatchWorkers);
        }

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
            // initialize core count accumulator
            int totalPhysicalCores = 0;

            // query WMI for accurate physical core counts per processor
            using (var searcher = new ManagementObjectSearcher("SELECT NumberOfCores FROM Win32_Processor"))
            {
                // iterate through each processor and sum physical cores
                // handles multi-socket systems correctly
                foreach (var item in searcher.Get())
                {
                    totalPhysicalCores += Convert.ToInt32(item["NumberOfCores"]);
                }
            }

            // return total physical cores across all processors
            return totalPhysicalCores;
        }

        /// <summary>
        /// Gets available RAM in bytes for resource calculations
        /// </summary>
        /// <returns>Available bytes of RAM.</returns>
        protected long GetFreeRamInBytes()
        {
            // use PerformanceCounter for real-time memory availability
            // provides more accurate current values than static WMI queries
            using (var counter = new PerformanceCounter("Memory", "Available Bytes"))
            {
                // get current available memory snapshot
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
            // attempt to query remote machine shares via WMI
            try
            {
                // create WMI query for all shares on the target machine
                var query = new ObjectQuery("SELECT * FROM Win32_Share");

                // establish WMI connection to remote machine
                var scope = new ManagementScope($@"\\{machineName}\root\cimv2");

                // connect to the remote WMI namespace
                scope.Connect();

                // execute the share enumeration query
                var searcher = new ManagementObjectSearcher(scope, query);

                // retrieve all shares from the query results
                var shares = searcher.Get();

                // prepare collection for disk share names only
                var uncPaths = new List<string>();

                // iterate through each share to filter disk shares
                foreach (ManagementObject share in shares)
                {
                    // extract share type value (bitmask indicating share type)
                    uint typeValue = Convert.ToUInt32(share["Type"]);

                    // extract share name, handling null cases
                    string name = share["Name"]?.ToString() ?? "";

                    // check if this is a disk share (type 0 = disk, higher bits indicate special shares)
                    // Win32_Share.Type: 0 = Disk, 1 = Print Queue, 2 = Device, 3 = IPC, 2147483648 = Disk Admin, etc.
                    bool isDisk = (typeValue & 0xFFFF) == 0;

                    // add to results if it's a disk share with a valid name
                    if (isDisk && !string.IsNullOrEmpty(name))
                    {
                        uncPaths.Add(name);
                    }
                }

                // return the filtered disk share names as array
                return uncPaths.ToArray<string>();
            }
            catch
            {
                // silently handle connection/permission failures
                // network issues or access denied return empty results
            }

            // return empty array on any failure
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
            // handle -AllDrives parameter which searches all available drives
            if (this.AllDrives.IsPresent)
            {
                // combine all drive sources: system drives, explicit search drives, and drive letters
                // deduplicate and normalize to uppercase drive letters
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

                // convert drive letters to full root paths (C:\, D:\, etc.)
                foreach (var drive in combinedDrives)
                {
                    yield return (drive + ":\\");
                }
            }
            else
            {
                // when not using -AllDrives, only search explicitly specified drives
                var drives = SearchDrives
                         .Where(q => !string.IsNullOrWhiteSpace(q))
                         .Select(q => char.ToUpperInvariant(q[0]))
                         .Union(DriveLetter
                             .Where(c => !char.IsWhiteSpace(c))
                             .Select(c => char.ToUpperInvariant(c))
                          );

                // convert to full root paths
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
            // exit if operation is being cancelled
            if (ctx.IsCancellationRequested) return;

            // increase thread pool size if needed
            ThreadPool.SetMaxThreads(

                // worker threads
                // used for Directory processors and Match processors
                Math.Max(this.oldMaxWorkerThread, maxDirectoryWorkersInParallel() * 2),

                // used after async IO operations
                Math.Max(this.oldMaxCompletionPorts, maxMatchWorkersInParallel())
             );

            // get current active file matching operations
            long fileMatchesCount = Interlocked.Read(ref this.fileMatchesActive);

            // get remaining directories to process
            long dirsLeft = Interlocked.Read(ref dirsQueued);

            // get total files found so far
            long fileOutputCount = Interlocked.Read(ref filesFound);

            // enter critical section for worker management
            lock (WorkersLock)
            {
                // clean up completed worker tasks from the list
                Workers.RemoveAll(w => w.IsCompleted);

                // get current directory processor count
                var currentNrOfDirectoryProcessors = Interlocked.Read(ref this.directoryProcessors);

                // calculate maximum directory processors needed based on queue size and parallelism limit
                var missingDirectoryProcessors = maxDirectoryWorkersInParallel() - currentNrOfDirectoryProcessors;

                // create the calculated number of directory processor workers
                while (missingDirectoryProcessors-- > 0)
                {
                    // start new directory processing worker task
                    AddWorkerTask(Workers, false, ctx);
                }

                // get current content matching processor count
                var currentNrOfMatchingProcessors = Interlocked.Read(ref this.matchProcessors);

                // determine missing content matching workers
                var missingMatchingProcessors = maxMatchWorkersInParallel() - currentNrOfMatchingProcessors;

                // create the calculated number of content matching workers
                while (missingMatchingProcessors-- > 0)
                {
                    // start new content matching worker task
                    AddWorkerTask(Workers, true, ctx);
                }
            }
        }

        /// <summary>
        /// Adds a single worker task to the list.
        /// </summary>
        protected void AddWorkerTask(List<Task> workers, bool contentMatcher, CancellationToken ctx)
        {
            // log worker creation if verbose output enabled
            if (UseVerboseOutput)
            {
                // determine worker type for logging
                string str = contentMatcher ? "content matcher" : "directory processor";

                VerboseQueue.Enqueue($"Start new {str} worker");
            }

            // branch based on worker type needed - content matchers vs directory processors
            if (contentMatcher)
            {
                // increment content matcher counter atomically
                Interlocked.Increment(ref matchProcessors);

                // create async content matching worker task
                workers.Add(Task.Run(async () =>
                {
                    try
                    {
                        // main content matching loop
                        FileInfo fileInfo;
                        var maxMatchersFunc = maxMatchWorkersInParallel; // cache delegate reference

                        // process files from content matching queue until cancelled
                        while (FileContentMatchQueue.TryDequeue(out fileInfo) && !ctx.IsCancellationRequested)
                        {
                            try
                            {
                                // perform content matching on the dequeued file
                                await FileContentProcessor(fileInfo, ctx);
                            }
                            catch (Exception ex)
                            {
                                // log individual file processing failures
                                if (UseVerboseOutput)
                                {
                                    VerboseQueue.Enqueue($"Worker task failed: {ex.Message}");
                                }
                            }

                            // dynamic throttling: check at end of iteration if we should exit
                            var currentMatchers = Interlocked.Read(ref matchProcessors);
                            var maxMatchers = maxMatchersFunc();
                            if (currentMatchers > maxMatchers)
                            {
                                // if (UseVerboseOutput)
                                // {
                                //     VerboseQueue.Enqueue($"Content matcher exiting: {currentMatchers} > {maxMatchers}");
                                // }
                                // ensure other workers can be spawned when needed
                                AddWorkerTasksIfNeeded(ctx);
                                break;
                            }
                        }
                    }
                    finally
                    {
                        // decrement counter when worker exits
                        Interlocked.Decrement(ref matchProcessors);
                        // final check for needed workers
                        AddWorkerTasksIfNeeded(ctx);

                    }
                }, ctx));

                return;
            }

            // create directory processing worker (non-async)
            Interlocked.Increment(ref directoryProcessors);

            // add directory processor task
            workers.Add(Task.Run(() =>
            {
                try
                {
                    // run the main directory processing loop
                    DirectoryProcessor(cts!.Token);
                }
                catch (Exception ex)
                {
                    // log directory processing failures
                    if (UseVerboseOutput)
                    {
                        VerboseQueue.Enqueue($"Worker task failed: {ex.Message}");
                    }
                }
                finally
                {
                    // log worker completion
                    if (UseVerboseOutput)
                    {
                        // determine worker type for completion logging
                        string str = contentMatcher ? "Content matcher" : "Directory processor";

                        VerboseQueue.Enqueue($"{str} worker stopped");
                    }

                    // decrement active directory processor count
                    Interlocked.Decrement(ref directoryProcessors);
                }
            }, ctx));
        }

        /// <summary>
        /// Checks if all workers are completed.
        /// </summary>
        /// <returns>True if all completed.</returns>
        protected bool AllWorkersCompleted()
        {
            // use lock to ensure thread-safe access to workers list
            // prevents race conditions when checking completion status
            lock (WorkersLock)
            {
                // check if any worker tasks are still running
                // returns true only if NO workers are incomplete
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
            // execute the PowerShell script and collect all output objects
            Collection<PSObject> results = InvokeCommand.InvokeScript(script);

            // check if the entire results collection is of type T
            // handles cases where script returns a single collection
            if (results is T)
            {
                return (T)(object)results;
            }

            // check if first result's base object is of type T
            // handles cases where script returns wrapped PSObjects
            if (results.Count > 0 && results[0].BaseObject is T)
            {
                return (T)results[0].BaseObject;
            }

            // return default value if no matching type found
            return default(T);
        }

        /// <summary>
        /// Calculates current recursion depth and limit for directory traversal.
        /// Handles both UNC paths (\\server\share) and local paths (C:\) with appropriate offsets.
        /// </summary>
        /// <param name="CurrentLocation">The current path being processed</param>
        /// <param name="IsUncPath">True if the path is a UNC path (\\server\share format)</param>
        /// <param name="CurrentRecursionDepth">Output parameter: current depth from base path</param>
        /// <param name="CurrentRecursionLimit">Output parameter: maximum allowed depth with path-specific offsets</param>
        void GetCurrentDepthParameters(string CurrentLocation, bool IsUncPath, out int CurrentRecursionDepth, out int CurrentRecursionLimit)
        {
            // calculate relative path from the base search directory
            // this gives us the path components below our starting point
            var relativePath = Path.GetRelativePath(RelativeBasePath, CurrentLocation);

            // normalize relative path by removing leading separators
            // handles cases where path starts with .\ or .\
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

            // count directory levels by splitting on path separators
            // this gives us the recursion depth from our base path
            CurrentRecursionDepth = relativePath.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar).Length;

            // calculate recursion limit with path-type specific offsets
            // UNC paths need extra levels for \\server\share\, local paths need 2 for C:\
            var offset = IsUncPath ? 4 : 2; // Account for \\server\share\ or C:\

            // apply recursion limit, or disable if MaxRecursionDepth is 0
            CurrentRecursionLimit = MaxRecursionDepth <= 0 ? 0 : Path.IsPathRooted(relativePath) ? (MaxRecursionDepth + offset) : MaxRecursionDepth;
        }

        /// <summary>
        /// Formats 64-bit integers to string with a semi fixed width.
        /// Pads the string to multiples of 4 characters for consistent alignment.
        /// </summary>
        /// <param name="nr">Number to format</param>
        /// <param name="padLeft">When set, will pad spaces to the left side</param>
        /// <returns>Formatted string with consistent width</returns>
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
        /// Updates the PowerShell progress display with current search statistics.
        /// Throttles updates to avoid UI flooding and shows directory/file counts.
        /// </summary>
        /// <param name="force">If true, forces an immediate update regardless of throttling</param>
        private void UpdateProgressStatus(bool force = false)
        {
            // get current timestamp and convert from stored binary format
            var now = DateTime.UtcNow;
            long lastProgress = Interlocked.Read(ref this.lastProgress);
            var time = DateTime.FromBinary(lastProgress);

            // throttle progress updates to avoid flooding the UI
            // only update if forced or at least 250ms have passed
            if (!force && now - time < TimeSpan.FromMilliseconds(250)) return;

            // update the timestamp checkpoint for next throttling check
            lastProgress = now.ToBinary();
            Interlocked.Exchange(ref lastProgress, lastProgress);

            // determine output mode based on parameters
            bool outputtingFiles = FilesAndDirectories.IsPresent || !Directory.IsPresent;

            // check if we're doing content matching (Select-String like behavior)
            bool matchingContent = outputtingFiles && matchingFileContent;

            // determine if we're including files in the search scope
            bool andFiles = outputtingFiles && matchingContent;

            // gather all the counter values atomically to ensure consistent progress calculation
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

            // calculate overall completion ratio
            // combines directory processing and content matching progress
            double ratio = (dirsDone + fileMatchesCompletedCount) / Math.Max(1d, (dirsLeft + fileMatchesLeft));

            // convert to percentage with bounds checking
            int progressPercent = (int)Math.Round(

                Math.Min(100,
                    Math.Max(0,
                        ratio
                    ) * 100d
                ), 0
            );


            // build detailed status string showing directory and file counts
            // Replace multiple string concatenations in UpdateProgressStatus
            statusBuilder.Clear();
            statusBuilder.Append("Folders: ")
            .Append(formatStat(dirsDone, true))
            .Append("/")
            .Append(formatStat(DirQueue.Count, false))
            .Append(" [")
            .Append(formatStat(directoryProcessorsCount, false))
            .Append("] | Found: ")
            .Append(formatStat(fileOutputCount, false));

            if (matchingContent)
            {
                statusBuilder.Append(" | Matched: ")
                    .Append(formatStat(fileMatchesStartedCount, true))
                    .Append('/')
                    .Append(formatStat(queuedMatchesCount, false))
                    .Append(" [")
                    .Append(formatStat(matchProcessors, false))
                    .Append(']');
            }

            // create progress record with dynamic status information
            var record = new ProgressRecord(0, "Find-Item", (
                "Scanning directories" + (andFiles ?
                " and found file contents" : "")
            ))
            {
                // set completion percentage
                PercentComplete = progressPercent,
                StatusDescription = statusBuilder.ToString(),

                // set current operation description based on search state
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

            // send the progress record to PowerShell host
            WriteProgress(record);
        }

        /// <summary>
        /// Adds a file or directory item to the output queue with appropriate formatting.
        /// Handles both PassThru mode and formatted output with relative paths and hyperlinks.
        /// </summary>
        /// <param name="item">The FileInfo or DirectoryInfo object to add to output</param>
        private void AddToOutputQueue(object item)
        {
            // safely handle output item processing with error recovery
            try
            {
                // determine item type for appropriate handling
                bool isFile = item is FileInfo;
                bool isDirectory = item is DirectoryInfo;

                // increment counters for found items
                if (isFile || isDirectory)
                {
                    // atomically increment total files found counter
                    Interlocked.Increment(ref filesFound);
                }

                bool outputtingMatches = matchingFileContent && !Quiet.IsPresent;
                bool userIsWatching = !UnattendedMode;
                bool notDisabledByUser = !PassThru.IsPresent;
                bool outputRelative = (isFile || isDirectory) && notDisabledByUser;

                // handle non-PassThru mode (formatted output)
                if (outputRelative)
                {
                    // extract full path from file or directory object
                    string fullName = (item is FileInfo fi ? fi.FullName :
                        ((DirectoryInfo)item).FullName);

                    // calculate relative path from search base for cleaner display
                    var relativePath = Path.GetRelativePath(RelativeBasePath, fullName);

                    // ensure relative path appears relative by prefixing with .\
                    if (!Path.IsPathRooted(relativePath))
                    {
                        // prepend .\ to make it explicitly relative
                        relativePath = ".\\" + relativePath;
                    }

                    // branch based on terminal capability
                    if (UnattendedMode)
                    {
                        // simple text output for non-interactive environments
                        OutputQueue.Enqueue(relativePath);
                    }
                    else
                    {
                        // create clickable hyperlink for interactive terminals using ANSI escape sequences
                        // convert backslashes to forward slashes for URL compatibility
                        var name = fullName.Replace("\\", "/");

                        // format as ANSI hyperlink escape sequence
                        // \u001b]8;; creates hyperlink, file:// URI, \u001b]8;; closes it
                        OutputQueue.Enqueue($"\u001b]8;;file://{name}\u001b\\{relativePath}\u001b]8;;\u001b\\");
                    }

                    return;
                }

                // default handling for other object types
                OutputQueue.Enqueue(item);
            }
            catch (Exception ex)
            {
                // log failures in verbose mode only
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Failed to enqueue output item: {ex.Message}");
                }
            }
        }

        public static string EscapeBracketsInPattern(string Pattern)
        {
            // Escape unescaped brackets in the pattern for regex safety
            // This prevents regex syntax errors from unbalanced brackets
            // Only escape brackets that are not already escaped with a backslash
            if (string.IsNullOrEmpty(Pattern)) return Pattern;
            // Use a StringBuilder for efficient string manipulation
            var sb = new System.Text.StringBuilder();
            bool isEscaped = false;
            foreach (char c in Pattern)
            {
                if (c == '`' && !isEscaped)
                {
                    // Next character is escaped
                    isEscaped = true;
                    sb.Append(c);
                }
                else if ((c != '`' || !isEscaped) && (c == '[' || c == ']') && !isEscaped)
                {
                    // Escape unescaped brackets
                    sb.Append('`');
                }

                sb.Append(c);
                isEscaped = false; // Reset escape flag
            }

            return sb.ToString();
        }
    }

    /// <summary>
    /// Processes file content for pattern matching using both regex and simple string matching.
    /// Supports context lines, encoding detection, and memory-efficient streaming file processing.
    /// Uses buffer pooling and unsafe operations for high-performance text processing.
    /// </summary>
    internal class MatchContentProcessor
    {
        /// <summary>
        /// Determines whether to find all matches on each line or stop at the first match.
        /// When true, all occurrences of the pattern within a line are captured.
        /// </summary>
        private readonly bool allMatches;

        /// <summary>
        /// Controls case sensitivity for pattern matching operations.
        /// When true, pattern matching distinguishes between uppercase and lowercase characters.
        /// </summary>
        private readonly bool caseSensitive;

        /// <summary>
        /// Array specifying the number of context lines to include before and after matches.
        /// Index 0 contains pre-context count, index 1 contains post-context count.
        /// </summary>
        private readonly int[] context;

        /// <summary>
        /// Maximum number of bytes to process per file to prevent excessive memory usage.
        /// Used to calculate buffer sizes and limit file processing scope.
        /// </summary>
        private readonly int memoryBase;

        /// <summary>
        /// Cancellation token for cooperative cancellation of long-running operations.
        /// Allows graceful termination of file processing when requested.
        /// </summary>
        private readonly CancellationToken token = CancellationToken.None;

        /// <summary>
        /// Array of string patterns to search for in file content.
        /// Can contain either literal strings or regular expression patterns depending on simpleMatch setting.
        /// </summary>
        private readonly string[] pattern;

        /// <summary>
        /// Number of lines to include after each match for context display.
        /// Calculated from the context array during initialization.
        /// </summary>
        private int postContext;

        /// <summary>
        /// Number of lines to include before each match for context display.
        /// Calculated from the context array during initialization.
        /// </summary>
        private int preContext;

        /// <summary>
        /// When true, only returns the first match found in each file without detailed match information.
        /// Optimizes performance when only file names with matches are needed.
        /// </summary>
        private readonly bool list;

        /// <summary>
        /// Inverts the matching logic when true, showing lines that do NOT match the pattern.
        /// Similar to the -v option in grep for negative matching.
        /// </summary>
        private readonly bool notMatch;

        /// <summary>
        /// Disables tracking to disable highlighting when formatting MatchInfo objects
        /// in the terminal.
        /// </summary>
        private readonly bool noEmphasis;

        /// <summary>
        /// Indicates that the cmdlet returns a simple response instead of
        /// a MatchInfo object. The returned value is $true if the pattern
        /// is found or $null if the pattern is not found.
        private readonly bool quiet;

        /// <summary>
        /// When true, uses simple string matching instead of regular expression matching.
        /// Provides better performance for literal string searches.
        /// </summary>
        private readonly bool simpleMatch;

        /// <summary>
        /// Text encoding used for reading and decoding file content.
        /// Determines how byte sequences are converted to character data.
        /// </summary>
        private readonly System.Text.Encoding textEncoding;

        /// <summary>
        /// String representation of the encoding name for internal reference.
        /// Used during encoding conversion and error reporting.
        /// </summary>
        private readonly string Encoding;

        /// <summary>
        /// Array of pre-compiled regular expression objects for pattern matching.
        /// Only populated when simpleMatch is false to enable regex-based searching.
        /// </summary>
        private readonly Regex[] regexPattern;

        /// <summary>
        /// Culture name for culture-specific string comparisons.
        /// When null or empty, uses current culture for comparisons.
        /// </summary>
        private readonly string cultureName;

        /// <summary>
        /// Pre-computed culture-aware string comparison function for performance.
        /// Avoids repeated culture lookups during pattern matching.
        /// </summary>
        private readonly Func<string, string, bool> stringContainsFunc;

        /// <summary>
        /// Pre-computed culture-aware IndexOf function for match position finding.
        /// Optimizes position computation by avoiding repeated culture setup.
        /// </summary>
        private readonly Func<string, string, int, int> indexOfFunc;
        /// <summary>
        /// Reusable byte buffer pool for file reading operations to reduce memory allocations.
        /// Buffers are shared across all MatchContentProcessor instances for efficiency.
        /// </summary>
        protected static ConcurrentQueue<byte[]> reusableByteBuffers = new();

        /// <summary>
        /// Reusable character buffer pool for text decoding operations.
        /// Maintains buffers of standard size for character conversion from bytes.
        /// </summary>
        protected static ConcurrentQueue<char[]> reusableCharBuffers = new();

        /// <summary>
        /// Reusable long character buffer pool for line processing operations.
        /// Used for storing complete lines during text processing with overlap handling.
        /// </summary>
        protected static ConcurrentQueue<char[]> reusableLongCharBuffers = new();

        /// <summary>
        /// Reusable integer list pool for storing match positions and lengths.
        /// Reduces allocations during pattern matching operations.
        /// </summary>
        protected static ConcurrentQueue<List<int>> reusableIntLists = new();

        /// <summary> Reusable list for matchinfo results</summary>
        protected static ConcurrentQueue<List<MatchInfo>> reusableMatchResults = new();

        /// <summary>
        /// Initializes a new content processor for file content matching.
        /// Supports both regex and simple string matching with context lines.
        /// </summary>
        /// <param name="pattern">Patterns to match against file content.</param>
        /// <param name="simpleMatch">If true, use simple string matching instead of regex.</param>
        /// <param name="allMatches">If true, find all matches in each line.</param>
        /// <param name="notMatch">If true, invert match logic (show non-matching lines).</param>
        /// <param name="caseSensitive">If true, matching is case sensitive.</param>
        /// <param name="encoding">Text encoding for file reading.</param>
        /// <param name="list">If true, only show filenames with matches.</param>
        /// <param name="context">Context lines before and after matches.</param>
        /// <param name="culture">Culture name for culture-specific comparisons.</param>
        /// <param name="quiet">If true, only return basic match information for performance.</param>
        /// <param name="token">Cancellation token for cooperative cancellation.</param>
        public MatchContentProcessor(
            int maxBytes,
            string[] pattern,
            bool simpleMatch = false,
            bool allMatches = false,
            bool notMatch = false,
            bool caseSensitive = false,
            string encoding = null,
            bool list = false,
            int[] context = null,
            string culture = null,
            bool quiet = false,
            bool noEmphasis = false,
            CancellationToken token = default
            )
        {
            // store pattern array for matching operations
            this.token = token;
            this.memoryBase = maxBytes;
            this.pattern = pattern ?? throw new ArgumentNullException(nameof(pattern));
            this.simpleMatch = simpleMatch;
            this.allMatches = allMatches;
            this.notMatch = notMatch;
            this.caseSensitive = caseSensitive;
            this.list = list;
            this.noEmphasis = noEmphasis || notMatch;
            this.context = context ?? new int[] { 0, 0 };
            this.cultureName = culture;
            this.quiet = quiet;

            // pre-compute culture-aware comparison functions for performance
            if (!string.IsNullOrEmpty(culture))
            {
                // use specified culture for all comparisons
                var cultureInfo = CultureInfo.GetCultureInfo(culture);
                var compareOptions = caseSensitive ? CompareOptions.None : CompareOptions.IgnoreCase;

                this.stringContainsFunc = (subject, pattern) =>
                    cultureInfo.CompareInfo.IndexOf(subject, pattern, compareOptions) >= 0;

                this.indexOfFunc = (subject, pattern, startIndex) =>
                    cultureInfo.CompareInfo.IndexOf(subject, pattern, startIndex, compareOptions);
            }
            else
            {
                // use current culture for all comparisons
                var comparison = caseSensitive
                    ? StringComparison.CurrentCulture
                    : StringComparison.CurrentCultureIgnoreCase;

                this.stringContainsFunc = (subject, pattern) =>
                    subject.IndexOf(pattern, comparison) >= 0;

                this.indexOfFunc = (subject, pattern, startIndex) =>
                    subject.IndexOf(pattern, startIndex, comparison);
            }

            // calculate context line counts from array parameter
            if (this.context != null && this.context.Length > 0)
            {
                this.preContext = Math.Max(0, this.context[0]);
                this.postContext = this.context.Length > 1 ? Math.Max(0, this.context[1]) : this.preContext;
            }
            else
            {
                this.preContext = 0;
                this.postContext = 0;
            }

            // determine text encoding for file reading - default to UTF8 if not specified
            if (string.IsNullOrWhiteSpace(this.Encoding))
            {
                // default to UTF8 for broad compatibility
                this.textEncoding = new UTF8Encoding();
            }
            else
            {
                // convert encoding name to Encoding object
                this.textEncoding = EncodingConversion.Convert(null, this.Encoding);
            }

            // set case sensitivity option
            RegexOptions options =
                (this.caseSensitive ?
                RegexOptions.None :
                RegexOptions.IgnoreCase) | RegexOptions.Compiled;

            this.regexPattern = new Regex[this.pattern.Length];
            for (int i = 0; i < this.pattern.Length; i++)
            {
                try
                {
                    // compile each pattern with error handling
                    this.regexPattern[i] = new Regex(this.simpleMatch ? Regex.Escape(this.pattern[i]) : this.pattern[i], options);
                }
                catch (Exception exception)
                {
                    // provide clear error message for invalid regex
                    throw new ArgumentException(string.Format("Invalid regular expression: {0}, Message: {1}", this.pattern[i], exception.Message), exception);
                }
            }
        }

        /// <summary>
        /// Searches file content asynchronously and yields match results.
        /// Handles both list mode (first match only) and full matching modes.
        /// </summary>
        /// <param name="file">The file to search.</param>
        /// <returns>Async enumerable of match results.</returns>
        public async IAsyncEnumerable<MatchInfo> SearchAsync(FileInfo file)
        {
            // handle list mode - only return first match per file
            if (list)
            {
                var firstMatch = default(MatchInfo);
                // iterate through matches but only keep the first one
                await foreach (var match in SearchInternalAsync(file))
                {
                    if (firstMatch == null)
                    {
                        firstMatch = match;
                    }
                }
                // yield only the first match if found
                if (firstMatch != null)
                {
                    yield return firstMatch;
                }
                yield break;
            }

            // full matching mode - return all matches
            await foreach (var match in SearchInternalAsync(file))
            {
                yield return match;
            }
        }

        /// <summary>
        /// Internal search implementation that processes file line by line.
        /// Uses context tracking to collect pre/post context lines around matches.
        /// </summary>
        /// <param name="file">The file to search.</param>
        /// <param name="options">Search configuration options.</param>
        /// <returns>Async enumerable of match results with context.</returns>
        private async IAsyncEnumerable<MatchInfo> SearchInternalAsync(FileInfo file)
        {
            // initialize context tracker for pre/post context line collection
            bool useTracking = !noEmphasis && !quiet;
            ContextTracker contextTracker = useTracking ? new ContextTracker(preContext, postContext) : null;
            ulong lineNumber = 0;

            // open file with specified encoding for reading
            await using var stream = file.OpenRead();

            // acquire or create buffers from pools for efficient memory usage
            byte[] byteBuffer;
            if (!reusableByteBuffers.TryDequeue(out byteBuffer) || byteBuffer.Length != 1024 * 64) byteBuffer = new byte[1024 * 64];
            char[] charBuffer;
            int maxCharCount = textEncoding.GetMaxCharCount(byteBuffer.Length);
            if (!reusableCharBuffers.TryDequeue(out charBuffer) || charBuffer.Length != maxCharCount) charBuffer = new char[maxCharCount];

            // calculate optimized buffer sizes based on memory limits and encoding requirements
            maxCharCount = Math.Min(
                1024 * 128,
                textEncoding.GetMaxCharCount(memoryBase)
            );
            char[] head;
            if (!reusableCharBuffers.TryDequeue(out head) || head.Length != maxCharCount) head = new char[maxCharCount];
            char[] line;
            if (!reusableLongCharBuffers.TryDequeue(out line) || line.Length != maxCharCount * 2) line = new char[maxCharCount * 2];
            List<MatchInfo> matchResults = null;
            if (!reusableMatchResults.TryDequeue(out matchResults)) matchResults = new List<MatchInfo>();
            try
            {
                int headStartIndex = 0;
                int headEndIndex = 0;
                int lineEndIndex = 0;

                Encoding encoding = textEncoding;
                Decoder decoder = encoding.GetDecoder();

                // read file line by line until end of file
                while (stream.CanRead || headEndIndex > 0 || lineEndIndex > 0)
                {
                    (headStartIndex, headEndIndex, lineEndIndex) = await ReadFilteredLineAsync(
                        stream,
                        byteBuffer,
                        charBuffer,
                        head,
                        line,
                        headStartIndex,
                        headEndIndex,
                        headEndIndex,
                        encoding,
                        decoder
                    );

                    if (lineEndIndex == 0)
                    {
                        break;
                    }

                    lineNumber++;

                    ReadOnlySpan<char> lineSpan = line.AsSpan(0, lineEndIndex);

                    // check if current line matches the search pattern
                    if (doMatch(lineSpan, matchResults))
                    {
                        if (quiet)
                        {
                            yield return null;
                            yield break;
                        }

                        foreach (var matchResult in matchResults)
                        {
                            // populate match result with file and line information
                            matchResult.LineNumber = lineNumber;
                            matchResult.Path = file.FullName;

                            // track this match for context collection
                            if (useTracking)
                            {
                                contextTracker.TrackMatch(matchResult);
                            }
                            else
                            {
                                yield return matchResult;
                            }
                        }
                    }
                    else
                    {
                        if (useTracking) contextTracker.TrackLine(new string(lineSpan));
                    }

                    if (useTracking)
                    {
                        // yield any completed match results with full context
                        foreach (var match in contextTracker.EmitQueue)
                        {
                            yield return match;
                        }

                        contextTracker.EmitQueue.Clear();
                    }
                }

                // handle end-of-file to emit any pending matches
                if (useTracking)
                {
                    contextTracker.TrackEOF();
                    foreach (var match in contextTracker.EmitQueue)
                    {
                        yield return match;
                    }

                    if (useTracking) contextTracker.EmitQueue.Clear();
                }
            }
            finally
            {
                // recycle buffers for future use
                byteBuffer.AsSpan().Clear();
                charBuffer.AsSpan().Clear();
                line.AsSpan().Clear();
                head.AsSpan().Clear();
                matchResults.Clear();

                reusableByteBuffers.Enqueue(byteBuffer);
                reusableCharBuffers.Enqueue(charBuffer);
                reusableCharBuffers.Enqueue(head);
                reusableLongCharBuffers.Enqueue(line);
                reusableMatchResults.Enqueue(matchResults);
            }
        }

        /// <summary>
        /// Asynchronously reads and filters a single line from a file stream.
        /// Handles character encoding, line ending detection, and buffer management.
        /// </summary>
        /// <param name="Stream">The file stream to read from</param>
        /// <param name="ByteBuffer">Buffer for raw bytes from stream</param>
        /// <param name="CharBuffer">Buffer for decoded characters</param>
        /// <param name="Head">Buffer for line overlap between reads</param>
        /// <param name="Line">Buffer for the output line</param>
        /// <param name="headStartIndex">Start index in head buffer</param>
        /// <param name="headEndIndex">End index in head buffer</param>
        /// <param name="lineEndIndex">Current end index in line buffer</param>
        /// <param name="Encoding">Text encoding for character conversion</param>
        /// <param name="Decoder">Character decoder instance</param>
        /// <returns>Tuple with updated buffer indices</returns>
        private async Task<(int headStartIndex, int headEndIndex, int lineEndIndex)> ReadFilteredLineAsync(
            FileStream Stream,
            byte[] ByteBuffer,
            char[] CharBuffer,
            char[] Head,
            char[] Line,
            int headStartIndex,
            int headEndIndex,
            int lineEndIndex,
            Encoding Encoding,
            Decoder Decoder
            )
        {
            // clear output line
            lineEndIndex = 0;

            // Process head first, if present
            while (headEndIndex - headStartIndex > 0)
            {
                var span = Head.AsSpan(headStartIndex, headEndIndex - headStartIndex);

                // process next line
                int trimIndex;
                (trimIndex, lineEndIndex) = ProcessSpan(Line, lineEndIndex, span);
                bool emptyLineFound = trimIndex < 0;
                bool hitMax = trimIndex == span.Length;

                if (emptyLineFound)
                {
                    // remove processed part from head
                    headStartIndex -= trimIndex;

                    // go find more
                    continue;
                }

                // no line endings found?
                if (hitMax)
                {
                    break;
                }
                else
                {
                    headStartIndex += trimIndex;

                    return (headStartIndex, headEndIndex, lineEndIndex);
                }
            }

            // head is empty, start reading from stream
            headStartIndex = 0;
            headEndIndex = 0;

            int charFactor = Encoding.GetMaxCharCount(memoryBase) / memoryBase;

            while (Stream.CanRead && (lineEndIndex < memoryBase))
            {
                // determine how many bytes to read, leaving space for potential char expansion
                int bytesToRead = Math.Min(ByteBuffer.Length, (Line.Length - lineEndIndex) * charFactor);

                bytesToRead = Math.Min(ByteBuffer.Length, Math.Max(1, bytesToRead - (bytesToRead % charFactor)));

                if (bytesToRead == 0) { break; }

                // read bytes from stream
                int bytesRead = await Stream.ReadAsync(
                    ByteBuffer,
                    0,
                    bytesToRead,
                    token
                ).ConfigureAwait(false);

                // end of stream?
                if (bytesRead == 0)
                {
                    // process any remaining head
                    if (headStartIndex < headEndIndex)
                    {
                        // append remaining head
                        var headSpan = Head.AsSpan(headStartIndex, headEndIndex - headStartIndex);
                        lineEndIndex = CopySpanToCharBuffer(Line, lineEndIndex, headSpan);

                        // clear head
                        headStartIndex = 0;
                        headEndIndex = 0;
                    }

                    // stop everything and return the results
                    return (headStartIndex, headEndIndex, lineEndIndex);
                }

                // decode bytes to chars
                int charsDecoded = Decoder.GetChars(ByteBuffer, 0, bytesRead, CharBuffer, 0, true);

                if (charsDecoded == 0)
                {
                    // go find more
                    continue;
                }

                // get span reference
                Span<char> span = CharBuffer.AsSpan(0, charsDecoded);
                ReplaceControlCharsWithSpaces(span);

                // process next line
                int trimIndex;
                (trimIndex, lineEndIndex) = ProcessSpan(Line, lineEndIndex, span);
                bool hitMax = trimIndex == span.Length;
                bool emptyLineFound = trimIndex < 0;

                // care for regex overlap
                if (hitMax)
                {
                    // take 10% overlap
                    int startPosition = (int)Math.Floor(lineEndIndex * 0.6);

                    // copy to head
                    headStartIndex = 0;
                    headEndIndex = CopySpanToCharBuffer(Head, 0, Line.AsSpan(startPosition, lineEndIndex - startPosition));
                }
                else
                {
                    // remove processed part from span
                    // get rest of char buffer
                    span = span.Slice(trimIndex);

                    // add to head
                    headStartIndex = 0;
                    headEndIndex = CopySpanToCharBuffer(Head, 0, span);
                }

                if (emptyLineFound)
                {
                    // go find more
                    continue;
                }

                // return the line
                break;
            }

            return (headStartIndex, headEndIndex, lineEndIndex);
        }

        /// <summary>
        /// Processes a span of characters, extracting a trimmed line and handling line endings.
        /// Uses unsafe pointer operations for performance when parsing character data.
        /// </summary>
        /// <param name="Line">Character array to store the processed line</param>
        /// <param name="lineEndIndex">Current end position in the Line array</param>
        /// <param name="span">The span of characters to process for line extraction</param>
        /// <returns>Tuple with final trim index and updated line end index</returns>
        private unsafe static (int finalTrimIndex, int endIndex) ProcessSpan(
            char[] Line,
            int lineEndIndex,
            ReadOnlySpan<char> span
         )
        {
            int finalTrimIndex = span.Length;

            // find first linefeeding char
            int spanLineEndIdx = IndexOfLineEnding(span);
            bool hitMax = spanLineEndIdx < 0;

            // found a line ending?
            if (spanLineEndIdx >= 0)
            {
                finalTrimIndex = spanLineEndIdx;

                // slice span to line ending
                span = span.Slice(0, spanLineEndIdx);
            }

            // trim start
            int trimIndex = FindIndexOfFirstNonSpaceChar(span);
            if (trimIndex < 0)
            {
                // nothing but spaces?
                return (-finalTrimIndex, lineEndIndex);
            }

            if (trimIndex > 0)
            {
                span = span.Slice(trimIndex);
            }

            // trim end
            int lastNonSpaceIdx = FindLastIndexOfNonSpaceChar(span);
            if (lastNonSpaceIdx != span.Length)
            {
                span = span.Slice(0, lastNonSpaceIdx + 1);
            }

            // nothing but spaces?
            if (span.Length == 0)
            {
                // go find more
                return (-finalTrimIndex, lineEndIndex);
            }

            // output
            lineEndIndex = CopySpanToCharBuffer(Line, lineEndIndex, span);

            return (finalTrimIndex, lineEndIndex);
        }

        /// <summary>
        /// Copies characters from a ReadOnlySpan to a character buffer using unsafe pointers for performance.
        /// Updates the buffer end index to reflect the new position after copying.
        /// </summary>
        /// <param name="charBuffer">The destination character buffer</param>
        /// <param name="bufferEndIndex">Current end position in the buffer</param>
        /// <param name="span">Source span to copy characters from</param>
        /// <returns>Updated buffer end index after copying</returns>
        private static unsafe int CopySpanToCharBuffer(char[] charBuffer, int bufferEndIndex, ReadOnlySpan<char> span)
        {
            // use unsafe pointers for maximum copy performance
            fixed (char* pointerSpan = span)
            fixed (char* charBufferPointer = charBuffer)
            {
                char* pSpan = pointerSpan;
                char* pCharBuffer = charBufferPointer + bufferEndIndex;
                char* pCharBufferEnd = pCharBuffer + span.Length;

                // update buffer index before copying
                bufferEndIndex += span.Length;

                // perform high-speed character-by-character copy
                while (pCharBuffer < pCharBufferEnd)
                {
                    *pCharBuffer++ = *pSpan++;
                }
            }

            // return updated buffer position
            return bufferEndIndex;
        }

        /// <summary>
        /// In-place replaces specified invisible Unicode characters and select ASCII controls (ESC and BEL) with spaces.
        /// Handles bidirectional controls, zero-width spaces, and other invisible formatting characters.
        /// </summary>
        /// <param name="buffer">The character span to process in-place</param>
        public static unsafe void ReplaceControlCharsWithSpaces(Span<char> buffer)
        {
            // use unsafe pointers for maximum performance during character replacement
            fixed (char* ptr = buffer)
            {
                char* p = ptr;
                char* end = p + buffer.Length;

                // scan through entire buffer character by character
                while (p < end)
                {
                    // Check for ESC (27) and BEL (7), plus the invisible Unicodes
                    if (*p == 7 || *p == 0x001b || (*p >= 128 && (
                        // Bidirectional controls (all >128)
                        *p == 0x200E || *p == 0x200F || *p == 0x202A || *p == 0x202B || *p == 0x202C ||
                        *p == 0x202D || *p == 0x202E || *p == 0x2066 || *p == 0x2067 || *p == 0x2068 ||
                        *p == 0x2069 ||
                        // Zero-width and invisible spaces
                        *p == 0x200B || *p == 0x200C || *p == 0x200D || *p == 0x2060 || *p == 0xFEFF ||
                        *p == 0x00AD || *p == 0x034F || *p == 0x2061 || *p == 0x2062 || *p == 0x2063 ||
                        *p == 0x2064 ||
                        // Other invisible fillers and separators
                        *p == 0x115F || *p == 0x1160 || *p == 0x3164 || *p == 0xFFA0 || *p == 0x180E ||
                        *p == 0x202F || *p == 0x205F ||
                        // Ranges
                        (*p >= 0x2000 && *p <= 0x200A) ||
                        (*p >= 0x206A && *p <= 0x206F) ||
                        (*p >= 0xFE00 && *p <= 0xFE0F))))
                    {
                        // replace problematic characters with space
                        *p = ' ';
                    }

                    p++;
                }
            }
        }

        /// <summary>
        /// Finds the index of the first line ending (\r or \n) in the span using unsafe pointers.
        /// Handles consecutive line ending characters and returns position after all line endings.
        /// </summary>
        /// <param name="span">The character span to search</param>
        /// <returns>Index after line ending sequence, or -1 if no line ending found</returns>
        private static unsafe int IndexOfLineEnding(ReadOnlySpan<char> span)
        {
            int result = -1;

            // use unsafe pointers for high-performance line ending detection
            fixed (char* ptr = span)
            {
                char* p = ptr;
                char* end = p + span.Length;

                // skip any leading line endings at the start
                while (p < end && (*p == '\r' || *p == '\n'))
                {
                    result++;
                    p++;
                }

                // scan for the first line ending in the content
                while (p < end)
                {
                    if (*p == '\r' || *p == '\n')
                    {
                        // consume all consecutive line ending characters
                        while (p < end && (*p == '\r' || *p == '\n'))
                        {
                            result++;
                            p++;
                        }

                        // return position after all line endings
                        return (int)(p - ptr);
                    }
                    p++;
                }
            }

            // no line ending found in content
            return result;
        }

        /// <summary>
        /// Finds the index of the first non-whitespace character using unsafe pointer operations.
        /// Considers space, carriage return, and line feed as whitespace characters.
        /// </summary>
        /// <param name="span">The character span to search</param>
        /// <param name="startIndex">Starting index for the search</param>
        /// <returns>Index of first non-whitespace character, or -1 if none found</returns>
        private static unsafe int FindIndexOfFirstNonSpaceChar(ReadOnlySpan<char> span, int startIndex = 0)
        {
            // use unsafe pointers for maximum performance in character scanning
            fixed (char* ptr = span)
            {
                char* p = ptr + startIndex;
                char* end = p + span.Length;

                // scan forward until non-whitespace character found
                while (p < end)
                {
                    // check for space, carriage return, and line feed
                    if (*p != ' ' && *p != '\r' && *p != '\n')
                        return (int)(p - ptr);
                    p++;
                }
            }
            return -1;
        }

        /// <summary>
        /// Finds the index of the last non-whitespace character using unsafe pointer operations.
        /// Searches backwards from the end of the span for efficient trimming.
        /// </summary>
        /// <param name="span">The character span to search</param>
        /// <returns>Index of last non-whitespace character, or -1 if none found</returns>
        private static unsafe int FindLastIndexOfNonSpaceChar(ReadOnlySpan<char> span)
        {
            // use unsafe pointers for optimal backward scanning performance
            fixed (char* pointerSpan = span)
            {
                char* pSpan = pointerSpan + span.Length;
                char* pEnd = pointerSpan;

                // scan backwards from end until non-whitespace character found
                while (--pSpan >= pEnd)
                {
                    // check for space, carriage return, and line feed
                    if (*pSpan != ' ' && *pSpan != '\r' && *pSpan != '\n')
                        return (int)(pSpan - pointerSpan);
                }
            }
            return -1;
        }

        /// <summary>
        /// Performs pattern matching against a line of text using either regex or simple string matching.
        /// Automatically selects optimized implementation based on Quiet mode setting.
        /// </summary>
        /// <param name="operandSpan">The line of text to match against as a character span</param>
        /// <param name="matchResult">Output parameter containing detailed match information (null in Quiet mode)</param>
        /// <returns>True if the line matches the pattern (considering notMatch inversion)</returns>
        private bool doMatch(
                ReadOnlySpan<char> operandSpan,
                List<MatchInfo> matchResult
            )
        {
            // use optimized Quiet mode implementation when detailed output isn't needed
            if (quiet)
            {
                matchResult.Clear();
                return doMatchQuiet(operandSpan);
            }

            // use full output implementation for detailed match information
            return doMatchWithOutput(operandSpan, matchResult);
        }

        /// <summary>
        /// Optimized pattern matching for Quiet mode - returns simple boolean without detailed match information.
        /// Prioritizes performance by avoiding unnecessary match position calculations and object allocations.
        /// </summary>
        /// <param name="operandSpan">The line of text to match against as a character span</param>
        /// <returns>True if the line matches the pattern (considering notMatch inversion)</returns>
        private bool doMatchQuiet(ReadOnlySpan<char> operandSpan)
        {
            // convert span to string only once for efficiency
            string subject = operandSpan.ToString();

            // iterate through all regex patterns until one matches
            foreach (var regExPattern in this.regexPattern)
            {
                // find all matches in the line when requested
                if (regExPattern.IsMatch(subject))
                {
                    return true ^ notMatch;
                }
            }

            return false;
        }

        /// <summary>
        /// Optimized pattern matching for non-Quiet mode with full match information output.
        /// Generates complete MatchInfo objects with positions, context, and detailed match data.
        /// </summary>
        /// <param name="operandSpan">The line of text to match against as a character span</param>
        /// <param name="matchResult">Output parameter containing detailed match information including positions</param>
        /// <returns>True if the line matches the pattern (considering notMatch inversion)</returns>
        private bool doMatchWithOutput(
                ReadOnlySpan<char> operandSpan,
                List<MatchInfo> matchResult
            )
        {
            bool success = false;
            matchResult.Clear();

            // convert span to string only once for efficiency
            string subject = operandSpan.ToString();

            // iterate through all regex patterns until one matches
            foreach (var regExPattern in this.regexPattern)
            {
                Match[] found = Array.Empty<Match>();

                if (allMatches && !notMatch)
                {
                    // find all matches in the line when requested
                    var coll = regExPattern.Matches(subject);
                    if (coll.Count > 0)
                    {
                        found = new Match[coll.Count];
                        coll.CopyTo(found, 0);
                        success = true;

                        if (!this.notMatch)
                        {
                            var idxs = (found != null) ? found.Select(m => m.Index).ToArray() : Array.Empty<int>();
                            var lens = (found != null) ? found.Select(m => m.Length).ToArray() : Array.Empty<int>();
                            matchResult.Add(setMatchResultProperties((idxs.Length > 0) ? new MatchInfo(idxs, lens) : new MatchInfo(), subject, regExPattern.ToString(), found));
                        }

                        break;
                    }
                }
                else
                {
                    // find only the first match in the line
                    var m = regExPattern.Match(subject);
                    if (m.Success)
                    {
                        found = new[] { m };
                        success = true;
                        if (!this.notMatch)
                        {
                            var idxs = (found != null) ? found.Select(m => m.Index).ToArray() : Array.Empty<int>();
                            var lens = (found != null) ? found.Select(m => m.Length).ToArray() : Array.Empty<int>();
                            matchResult.Add(
                                setMatchResultProperties(
                                    !noEmphasis && idxs.Length > 0 ?
                                    new MatchInfo(idxs, lens) :
                                    new MatchInfo(),
                                    subject,
                                    regExPattern.ToString(),
                                    found
                                )
                            );
                        }

                        break;
                    }
                    else
                    {
                        if (this.notMatch)
                        {
                            success = true;

                            // add the whole line as matchResult
                            matchResult.Add(
                                setMatchResultProperties(
                                    new MatchInfo(
                                        new int[1] { 0 },
                                        new int[1] { 0 }
                                    ), subject,
                                    regExPattern.ToString(),
                                    new Match[0]
                                )
                            );
                        }
                    }
                }

                // stop on first successful pattern
                if (success)
                {
                    break;
                }
            }

            // for notMatch, success flag is already correctly set by individual line matching
            // do not invert the overall success - it represents whether we found lines that should be yielded
            return success;
        }

        /// <summary>
        /// Populates the specified MatchInfo instance with result properties based on the provided subject and pattern.
        /// </summary>
        /// <remarks>If context lines are requested, the method attaches a MatchInfoContext object to the
        /// Context property of the MatchInfo. The IgnoreCase property is set based on the case sensitivity
        /// configuration.</remarks>
        /// <param name="matchInfo">The MatchInfo object to populate with match result properties. Must not be null.</param>
        /// <param name="subject">The input string that was searched for matches. This value is assigned to the Line property of the
        /// MatchInfo.</param>
        /// <param name="pattern">The pattern used for matching. This value is assigned to the Pattern property of the MatchInfo.</param>
        /// <returns>The same MatchInfo instance with its properties updated to reflect the match result and context.</returns>
        private MatchInfo setMatchResultProperties(MatchInfo matchInfo, string subject, string pattern, Match[] found)
        {
            // populate common MatchInfo properties
            matchInfo.IgnoreCase = !this.caseSensitive;
            matchInfo.Line = subject;
            if (!noEmphasis) matchInfo.Pattern = pattern;

            // attach context object if context lines are requested
            if (!noEmphasis && (this.preContext > 0) || (this.postContext > 0))
            {
                matchInfo.Context = (MatchInfoContext)Activator.CreateInstance(typeof(MatchInfoContext), true);
            }
            if (!noEmphasis) matchInfo.Matches = (found != null) ? found : Array.Empty<Match>();
            return matchInfo;
        }

        /// <summary>
        /// Tracks and manages lines of text that appear before and after matches to provide contextual output, similar
        /// to Select-String context features.
        /// </summary>
        /// <remarks>ContextTracker collects a configurable number of lines preceding and following each
        /// match, enabling consumers to display search results with surrounding context. It maintains a circular buffer
        /// for pre-context lines and a list for post-context lines, and provides a queue of completed matches with
        /// their associated context. This class is intended for internal use and is not thread-safe.</remarks>
        internal class ContextTracker : IContextTracker
        {
            /// <summary>
            /// Circular buffer that maintains the most recent non-matching lines for pre-context.
            /// Automatically overwrites oldest lines when capacity is exceeded.
            /// </summary>
            private CircularBuffer<string> collectedPreContext;

            /// <summary>
            /// List of lines collected after a match for post-context display.
            /// Cleared and rebuilt for each new match.
            /// </summary>
            private List<string> collectedPostContext;

            /// <summary>
            /// Queue of match results that are ready to be emitted with complete context.
            /// Populated by UpdateQueue when matches have collected sufficient context.
            /// </summary>
            private List<MatchInfo> emitQueue;

            /// <summary>
            /// The current match being processed while collecting post-context lines.
            /// Set when a match is found and cleared when the match is emitted.
            /// </summary>
            private MatchInfo matchInfo;

            /// <summary>
            /// Number of lines to collect before each match for context display.
            /// Determines the size of the pre-context circular buffer.
            /// </summary>
            private int preContext;

            /// <summary>
            /// Number of lines to collect after each match for context display.
            /// Controls when matches are emitted from the post-context collection state.
            /// </summary>
            private int postContext;

            /// <summary>
            /// Current state of the context collection state machine.
            /// Determines how non-matching lines are processed (ignored, pre-context, or post-context).
            /// </summary>
            private ContextState contextState;

            /// <summary>
            /// Tracks context lines around matches for Select-String style output.
            /// Maintains circular buffer for pre-context and list for post-context.
            /// </summary>
            /// <param name="preContext">Number of lines to show before each match.</param>
            /// <param name="postContext">Number of lines to show after each match.</param>
            public ContextTracker(int preContext, int postContext)
            {
                this.preContext = preContext;
                this.postContext = postContext;
                // circular buffer automatically handles overflow for pre-context
                this.collectedPreContext = new CircularBuffer<string>(preContext);
                this.collectedPostContext = new List<string>(postContext);
                this.emitQueue = new List<MatchInfo>();
                this.Reset();
            }

            /// <summary>
            /// Resets tracker state between matches.
            /// </summary>
            private void Reset()
            {
                // determine initial state based on pre-context requirements
                this.contextState = (this.preContext > 0) ? ContextState.CollectPre : ContextState.InitialState;
                this.collectedPreContext.Clear();
                this.collectedPostContext.Clear();
                this.matchInfo = null;
            }

            /// <summary>
            /// Signals end of file - emit any pending matches.
            /// </summary>
            public void TrackEOF()
            {
                // if we were collecting post-context, emit the match now
                if (this.contextState == ContextState.CollectPost)
                {
                    this.UpdateQueue();
                }
            }

            /// <summary>
            /// Processes a non-matching line for potential context inclusion.
            /// </summary>
            /// <param name="line">The line content.</param>
            public void TrackLine(string line)
            {
                switch (this.contextState)
                {
                    case ContextState.InitialState:
                        // no active match, nothing to do
                        break;

                    case ContextState.CollectPre:
                        // add to pre-context buffer (circular, so old lines drop out)
                        this.collectedPreContext.Add(line);
                        return;

                    case ContextState.CollectPost:
                        // add to post-context list
                        this.collectedPostContext.Add(line);
                        // check if we've collected enough post-context lines
                        if (this.collectedPostContext.Count >= this.postContext)
                        {
                            this.UpdateQueue();
                        }
                        break;

                    default:
                        return;
                }
            }

            /// <summary>
            /// Processes a matching line and transitions to post-context collection.
            /// </summary>
            /// <param name="match">The match information.</param>
            public void TrackMatch(MatchInfo match)
            {
                // if we were already collecting post-context, emit previous match first
                if (this.contextState == ContextState.CollectPost)
                {
                    this.UpdateQueue();
                }
                // store the new match
                this.matchInfo = match;

                // transition to post-context collection if needed
                if (this.postContext > 0)
                {
                    this.contextState = ContextState.CollectPost;
                }
                else
                {
                    // no post-context needed, emit immediately
                    this.UpdateQueue();
                }
            }

            /// <summary>
            /// Moves completed match with full context to emit queue.
            /// </summary>
            private void UpdateQueue()
            {
                if (this.matchInfo != null)
                {
                    // add match to emit queue
                    this.emitQueue.Add(this.matchInfo);

                    // attach collected context if match supports it
                    if (this.matchInfo.Context != null)
                    {
                        this.matchInfo.Context.DisplayPreContext = this.collectedPreContext.ToArray();
                        this.matchInfo.Context.DisplayPostContext = this.collectedPostContext.ToArray();
                    }
                    // reset for next match
                    this.Reset();
                }
            }

            /// <summary>
            /// Queue of completed matches ready for emission.
            /// </summary>
            public IList<MatchInfo> EmitQueue
            {
                get
                {
                    return this.emitQueue;
                }
            }

            /// <summary>
            /// State machine for context collection phases.
            /// </summary>
            private enum ContextState
            {
                InitialState,   // no active match
                CollectPre,     // collecting pre-context lines
                CollectPost     // collecting post-context lines
            }
        }

        /// <summary>
        /// Interface for tracking context lines around pattern matches in file content.
        /// Provides methods for collecting pre and post-context lines and managing match emission.
        /// </summary>
        internal interface IContextTracker
        {
            /// <summary>
            /// Signals that end of file has been reached and any pending matches should be emitted.
            /// </summary>
            void TrackEOF();

            /// <summary>
            /// Tracks a non-matching line for potential inclusion as context around matches.
            /// </summary>
            /// <param name="line">The line content to potentially include as context</param>
            void TrackLine(string line);

            /// <summary>
            /// Tracks a matching line and begins collecting post-context if needed.
            /// </summary>
            /// <param name="match">The match information including line content and position data</param>
            void TrackMatch(MatchInfo match);

            /// <summary>
            /// Gets the queue of completed matches ready for emission with full context attached.
            /// </summary>
            IList<MatchInfo> EmitQueue { get; }
        }

        /// <summary>
        /// Provides encoding name to Encoding object conversion for file operations.
        /// Supports common encoding names used in PowerShell and .NET.
        /// </summary>
        internal static class EncodingConversion
        {
            // encoding name constants for case-insensitive comparison
            internal const string Ascii = "ascii";
            internal const string Ansi = "ansi";
            internal const string BigEndianUnicode = "bigendianunicode";
            internal const string BigEndianUtf32 = "bigendianutf32";
            internal const string Default = "default";
            internal const string OEM = "oem";
            internal const string String = "string";
            internal const string Unicode = "unicode";
            internal const string Unknown = "unknown";
            internal const string Utf32 = "utf32";
            internal const string Utf7 = "utf7";
            internal const string Utf8 = "utf8";
            internal const string Utf8BOM = "utf8bom";
            internal const string Utf8NoBOM = "utf8nobom";

            /// <summary>
            /// Converts an encoding name string to the corresponding Encoding object.
            /// Supports PowerShell standard encodings, .NET encoding names, and numeric codepages.
            /// </summary>
            /// <param name="cmdlet">Cmdlet for error reporting (currently unused).</param>
            /// <param name="encoding">The encoding name to convert.</param>
            /// <returns>The corresponding Encoding object, defaults to UTF8NoBOM.</returns>
            internal static Encoding Convert(Cmdlet cmdlet, string encoding)
            {
                // handle null or empty encoding name
                if ((encoding == null) || (encoding.Length == 0))
                {
                    return new UTF8Encoding(false); // UTF8NoBOM
                }

                // handle special "unknown" encoding
                if (string.Equals(encoding, "unknown", StringComparison.OrdinalIgnoreCase))
                {
                    return new UTF8Encoding(false); // UTF8NoBOM
                }

                // handle "string" encoding (PowerShell convention)
                if (string.Equals(encoding, "string", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.Unicode;
                }

                // handle Unicode encodings
                if (string.Equals(encoding, "unicode", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.Unicode;
                }
                if (string.Equals(encoding, "bigendianunicode", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.BigEndianUnicode;
                }

                // handle ASCII encoding
                if (string.Equals(encoding, "ascii", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.ASCII;
                }

                // handle ANSI encoding (PowerShell 7.4+)
                if (string.Equals(encoding, "ansi", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.GetEncoding(0); // Current culture's ANSI codepage
                }

                // handle UTF encodings
                if (string.Equals(encoding, "utf8", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.UTF8;
                }
                if (string.Equals(encoding, "utf8bom", StringComparison.OrdinalIgnoreCase))
                {
                    return new UTF8Encoding(true); // UTF8 with BOM
                }
                if (string.Equals(encoding, "utf8nobom", StringComparison.OrdinalIgnoreCase))
                {
                    return new UTF8Encoding(false); // UTF8 without BOM
                }
                if (string.Equals(encoding, "utf7", StringComparison.OrdinalIgnoreCase))
                {
#pragma warning disable SYSLIB0001 // Type or member is obsolete
                    return System.Text.Encoding.UTF7;
#pragma warning restore SYSLIB0001 // Type or member is obsolete
                }
                if (string.Equals(encoding, "utf32", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.UTF32;
                }
                if (string.Equals(encoding, "bigendianutf32", StringComparison.OrdinalIgnoreCase))
                {
                    return new UTF32Encoding(true, true); // Big-endian UTF32 with BOM
                }

                // handle system default encoding
                if (string.Equals(encoding, "default", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.Default;
                }

                // handle OEM codepage (console encoding)
                if (string.Equals(encoding, "oem", StringComparison.OrdinalIgnoreCase))
                {
                    return System.Text.Encoding.GetEncoding((int)NativeMethods.GetOEMCP());
                }

                // Try to parse as numeric codepage
                if (int.TryParse(encoding, out int codepage))
                {
                    try
                    {
                        return System.Text.Encoding.GetEncoding(codepage);
                    }
                    catch (ArgumentException)
                    {
                        // Invalid codepage, fall through to name-based lookup
                    }
                }

                // Try to get encoding by name (handles all .NET encoding names)
                try
                {
                    return System.Text.Encoding.GetEncoding(encoding);
                }
                catch (ArgumentException)
                {
                    // Encoding name not found, use default
                }

                // default fallback to UTF8NoBOM for unrecognized encodings
                return new UTF8Encoding(false);
            }

            /// <summary>
            /// P/Invoke declarations for Windows API functions.
            /// </summary>
            private static class NativeMethods
            {
                /// <summary>
                /// Gets the OEM codepage identifier for the system.
                /// </summary>
                /// <returns>The OEM codepage identifier.</returns>
                [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
                internal static extern int GetOEMCP();
            }
        }

        /// <summary>
        /// Fixed-size circular buffer implementation for efficient storage of recent items.
        /// Automatically overwrites oldest items when capacity is exceeded.
        /// Used for storing pre-context lines in content matching.
        /// </summary>
        /// <typeparam name="T">The type of items stored in the buffer.</typeparam>
        internal class CircularBuffer<T> : IList<T>
        {
            private T[] _buffer;
            private int _head;
            private int _count;

            /// <summary>
            /// Initializes a new circular buffer with the specified capacity.
            /// </summary>
            /// <param name="capacity">The maximum number of items the buffer can hold.</param>
            public CircularBuffer(int capacity)
            {
                _buffer = new T[capacity];
            }

            /// <summary>
            /// Gets the number of items currently in the buffer.
            /// </summary>
            public int Count => _count;

            /// <summary>
            /// Gets a value indicating whether the buffer is read-only (always false).
            /// </summary>
            public bool IsReadOnly => false;

            /// <summary>
            /// Gets or sets the item at the specified index.
            /// Index 0 is the oldest item, higher indices are more recent.
            /// </summary>
            /// <param name="index">The zero-based index of the item.</param>
            /// <returns>The item at the specified index.</returns>
            public T this[int index] { get => _buffer[(_head + index) % _buffer.Length]; set => _buffer[(_head + index) % _buffer.Length] = value; }

            /// <summary>
            /// Not implemented - circular buffers don't support index-based search.
            /// </summary>
            public int IndexOf(T item) => throw new NotImplementedException();

            /// <summary>
            /// Not implemented - circular buffers don't support insertion at arbitrary positions.
            /// </summary>
            public void Insert(int index, T item) => throw new NotImplementedException();

            /// <summary>
            /// Not implemented - circular buffers don't support removal at arbitrary positions.
            /// </summary>
            public void RemoveAt(int index) => throw new NotImplementedException();

            /// <summary>
            /// Adds an item to the buffer. If the buffer is full, the oldest item is overwritten.
            /// </summary>
            /// <param name="item">The item to add.</param>
            public void Add(T item)
            {
                // handle buffer capacity - either add new item or overwrite oldest
                if (_count < _buffer.Length)
                {
                    _buffer[_head] = item;
                    _head = (_head + 1) % _buffer.Length;
                    _count++;
                }
                else
                {
                    // buffer is full, overwrite oldest item (circular behavior)
                    _buffer[_head] = item;
                    _head = (_head + 1) % _buffer.Length;
                    // count stays the same (buffer remains full)
                }
            }

            /// <summary>
            /// Clears all items from the buffer.
            /// </summary>
            public void Clear()
            {
                _head = 0;
                _count = 0;
            }

            /// <summary>
            /// Not implemented - circular buffers don't support containment checks.
            /// </summary>
            public bool Contains(T item) => throw new NotImplementedException();

            /// <summary>
            /// Copies the elements of the circular buffer to an array, starting at the specified array index.
            /// </summary>
            /// <param name="array">The one-dimensional array that is the destination of the elements copied from the circular buffer.</param>
            /// <param name="arrayIndex">The zero-based index in array at which copying begins.</param>
            public void CopyTo(T[] array, int arrayIndex)
            {
                if (array == null) throw new ArgumentNullException(nameof(array));
                if (arrayIndex < 0) throw new ArgumentOutOfRangeException(nameof(arrayIndex));
                if (array.Length - arrayIndex < _count) throw new ArgumentException("Destination array is not large enough");

                for (int i = 0; i < _count; i++)
                {
                    array[arrayIndex + i] = this[i];
                }
            }

            /// <summary>
            /// Not implemented - circular buffers don't support removal of specific items.
            /// </summary>
            public bool Remove(T item) => throw new NotImplementedException();

            /// <summary>
            /// Returns an enumerator that iterates through the buffer from oldest to newest.
            /// </summary>
            /// <returns>An enumerator for the buffer.</returns>
            public IEnumerator<T> GetEnumerator()
            {
                // iterate from oldest (head - count) to newest (head - 1), wrapping around
                for (int i = 0; i < _count; i++)
                {
                    yield return this[i];
                }
            }

            /// <summary>
            /// Returns a non-generic enumerator for the buffer.
            /// </summary>
            /// <returns>A non-generic enumerator.</returns>
            System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
        }

        /// <summary>
        /// Provides string formatting and manipulation utilities.
        /// Includes culture-aware formatting and buffer width calculations.
        /// </summary>
        internal static class StringUtil
        {
            /// <summary>
            /// Formats a string using the current thread's culture.
            /// </summary>
            /// <param name="formatSpec">The format string.</param>
            /// <param name="o">The objects to format.</param>
            /// <returns>The formatted string.</returns>
            internal static string Format(string formatSpec, params object[] o)
            {
                return string.Format(Thread.CurrentThread.CurrentCulture, formatSpec, o);
            }

            /// <summary>
            /// Formats a string with one parameter using the current thread's culture.
            /// </summary>
            /// <param name="formatSpec">The format string.</param>
            /// <param name="o">The object to format.</param>
            /// <returns>The formatted string.</returns>
            internal static string Format(string formatSpec, object o)
            {
                return string.Format(Thread.CurrentThread.CurrentCulture, formatSpec, new object[] { o });
            }

            /// <summary>
            /// Formats a string with two parameters using the current thread's culture.
            /// </summary>
            /// <param name="formatSpec">The format string.</param>
            /// <param name="o1">The first object to format.</param>
            /// <param name="o2">The second object to format.</param>
            /// <returns>The formatted string.</returns>
            internal static string Format(string formatSpec, object o1, object o2)
            {
                return string.Format(Thread.CurrentThread.CurrentCulture, formatSpec, new object[] { o1, o2 });
            }

            /// <summary>
            /// Truncates a string to fit within a specified buffer cell width.
            /// Accounts for wide characters and terminal display width.
            /// </summary>
            /// <param name="rawUI">The PowerShell host raw UI interface.</param>
            /// <param name="toTruncate">The string to truncate.</param>
            /// <param name="maxWidthInBufferCells">The maximum width in buffer cells.</param>
            /// <returns>The truncated string that fits within the specified width.</returns>
            internal static string TruncateToBufferCellWidth(PSHostRawUserInterface rawUI, string toTruncate, int maxWidthInBufferCells)
            {
                // start with the full string length, but don't exceed the string length
                int length = Math.Min(toTruncate.Length, maxWidthInBufferCells);

                // iteratively reduce length until the string fits in the buffer width
                while (true)
                {
                    string source = toTruncate.Substring(0, length);
                    // check if this substring fits within the buffer cell width
                    if (rawUI.LengthInBufferCells(source) <= maxWidthInBufferCells)
                    {
                        return source;
                    }
                    length--; // reduce length and try again
                }
            }
        }
    }
}