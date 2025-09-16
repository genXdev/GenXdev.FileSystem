// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Utilities.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.270.2025
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
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
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
        path = path.Replace("/", "\\");

        if (path == "~" || path.StartsWith("~\\") || path.StartsWith("~/"))
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
        catch (Exception ex)
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

        // add to directory queue
        DirQueue.Enqueue(path);

        // increment queued count
        Interlocked.Increment(ref dirsQueued);

        // add workers if needed
        AddWorkerTasksIfNeeded();
    }

    /// <summary>
    /// Gets drives to search based on parameters.
    /// </summary>
    /// <returns>Enumerable of drives.</returns>
    protected IEnumerable<DriveInfo> GetDrivesToSearch()
    {

        // get all drives
        var allDrives = DriveInfo.GetDrives();

        // declare result
        IEnumerable<DriveInfo> result;

        // handle all drives switch
        if (this.AllDrives.IsPresent)
        {

            // filter ready non-unknown drives
            result = allDrives.Where(d => d.IsReady &&
                                        (IncludeOpticalDiskDrives || d.DriveType != DriveType.CDRom) &&
                                        d.DriveType != DriveType.Unknown);
        }
        else if (SearchDrives.Length > 0)
        {

            // filter specified drives
            result = allDrives.Where(d => SearchDrives.Contains(d.Name, StringComparer.OrdinalIgnoreCase) &&
                                        d.IsReady &&
                                        (IncludeOpticalDiskDrives || d.DriveType != DriveType.CDRom) &&
                                        d.DriveType != DriveType.Unknown);
        }
        else
        {

            // no multi-drive, empty
            result = Enumerable.Empty<DriveInfo>();
        }

        return result;
    }

    /// <summary>
    /// Adds worker tasks if below parallelism limit.
    /// </summary>
    protected void AddWorkerTasksIfNeeded()
    {

        // lock for worker management
        lock (WorkersLock)
        {

            // remove completed workers
            Workers.RemoveAll(w => w.IsCompleted);

            // count active workers
            var current = Workers.Where(w => !w.IsCompleted).Count();

            // calculate needed workers
            var requested = Math.Min(MaxDegreeOfParallelism, Interlocked.Read(ref dirsQueued));

            // determine missing workers
            var missing = requested - current;

            // add missing workers
            // List to hold worker tasks
            while (missing-- > 0)
            {

                // Start worker tasks for parallel directory processing
                AddWorkerTask(Workers);
            }
        }
    }

    /// <summary>
    /// Adds a single worker task to the list.
    /// </summary>
    /// <param name="workers">The list of workers.</param>
    protected void AddWorkerTask(List<Task> workers)
    {

        // add new task
        workers.Add(Task.Run(async () =>
        {

            // try processing
            try
            {

                // run directory processor
                await DirectoryProcessor(cts!.Token);
            }
            catch (Exception ex)
            {

                // log failure if verbose
                if (UseVerboseOutput)
                {
                    VerboseQueue.Enqueue($"Worker task failed: {ex.Message}");
                }
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
}