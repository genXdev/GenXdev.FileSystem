// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Processing.cs
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



using Newtonsoft.Json.Linq;
using StreamRegex.Extensions.Core;
using StreamRegex.Extensions.RegexExtensions;
using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Data.Common;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Reflection.Metadata.Ecma335;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using Windows.ApplicationModel.Calls;

public partial class FindItem : PSCmdlet
{

    /// <summary>
    /// Processes search tasks until completion.
    /// </summary>
    protected void ProcessSearchTasks()
    {

        // add initial worker tasks if needed to start processing
        AddWorkerTasksIfNeeded();

        /*
         * main loop to consume outputs while workers are active or queues
         * have items.
         * this ensures all results are processed before completion.
         */

        // continue loop until cancellation or all workers done and output
        // queue empty
        while (!cts.Token.IsCancellationRequested &&
               (!AllWorkersCompleted()) || !OutputQueue.IsEmpty)
        {

            // yield cpu time to other threads

            // short sleep to avoid high cpu usage in tight loop
            Thread.Sleep(0);

            // process all queues to handle outputs and messages
            EmptyQueues();
        }
    }

    /// <summary>
    /// Empties all queues and handles output.
    /// </summary>
    private void EmptyQueues()
    {

        // process verbose queue for messages

        // dequeue and write verbose messages
        while (VerboseQueue.TryDequeue(out string? msg))
        {

            // check progress queue for updates
            checkProgoressQueue();

            // write the dequeued message as verbose output
            WriteVerbose(msg);
        }

        // process output queue for results

        // process output items such as files or directories
        while (OutputQueue.TryDequeue(out object? result))
        {

            // try handling the output item
            try
            {

                // increment the count of found files or directories
                Interlocked.Increment(ref filesFound);

                // handle passthru switch if present
                if (PassThru.IsPresent)
                {

                    // write the result object directly
                    WriteObject(result);
                }
                else if (UnattendedMode)
                {

                    // get full name of the file or directory
                    string FullName = (result is FileInfo fi ? fi.FullName :
                        ((DirectoryInfo)result).FullName);

                    // get relative path based on base path
                    var relativePath = Path.GetRelativePath(RelativeBasePath,
                        FullName);

                    // adjust relative path if not rooted by adding current
                    // directory prefix
                    if (!Path.IsPathRooted(relativePath))
                    {

                        // prepend .\ to make it relative
                        relativePath = ".\\" + relativePath;
                    }

                    // output the relative path
                    WriteObject(relativePath);
                }
                else
                {

                    // get full name normalized for non-filesystem use
                    string fullNameFull = result is FileInfo fi ? fi.FullName :
                        ((DirectoryInfo)result).FullName;

                    // normalize the full name path
                    string fullName = NormalizePathForNonFileSystemUse(
                        fullNameFull);

                    // get relative path from base
                    var relativePath = Path.GetRelativePath(RelativeBasePath,
                        fullName);

                    // adjust if not rooted
                    if (!Path.IsPathRooted(relativePath))
                    {

                        // prepend .\ for relative indication
                        relativePath = ".\\" + relativePath;
                    }

                    // prepare name for hyperlink by replacing backslashes
                    // with forward slashes
                    var name = fullName.Replace("\\", "/");

                    // format hyperlink using ansi escape sequences for
                    // terminal link
                    var formattedLink = (
                        "\u001b]8;;file://" + name + "\u001b\\" +
                        relativePath + "\u001b]8;;\u001b\\"
                    );

                    // output the formatted link
                    WriteObject(formattedLink);
                }
            }
            catch (Exception ex)
            {

                // write error record for the exception
                WriteError(new ErrorRecord(ex, "QueManager",
                    ErrorCategory.WriteError, result));
            }

            // check progress queue after handling output
            checkProgoressQueue();
        }

        // check all progress items in queue
        checkProgoressQueue(true);
    }

    /// <summary>
    /// Handles progress queue dequeuing.
    /// </summary>
    /// <param name="all">If to process all.</param>
    private void checkProgoressQueue(bool all = false)
    {

        // force processing of all items
        all = true;

        // determine if including files based on switches and pattern
        bool andFiles = (!Directory.IsPresent || FilesAndDirectories.IsPresent)
            && Pattern != ".*";

        // process progress updates

        // dequeue and write progress updates
        while (ProgressQueue.TryDequeue(out string? msg) && all)
        {

            // get count of directories done
            long dirsDone = Interlocked.Read(ref dirsUnQueued);

            // get count of directories left
            long dirsLeft = Interlocked.Read(ref dirsQueued);

            // calculate percent complete

            // calculate completion percentage for progress
            int progressPercent = (int)Math.Round(

                Math.Min(100,
                    Math.Max(0,
                        dirsDone /
                        Math.Max(1d, dirsLeft)
                    )) * 100d, 0
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
                    "Directories: " + dirsDone + "/" + dirsLeft +
                    " | Found: " + Interlocked.Read(ref filesFound)
                ),

                // set current operation message
                CurrentOperation = msg
            };

            // write the progress record
            WriteProgress(record);
        }
    }

    /// <summary>
    /// Worker task that processes directories from the work queue, performing
    /// file and directory
    /// enumeration according to search criteria.
    /// </summary>
    /// <remarks>
    /// The method implements a producer/consumer pattern where:
    /// - It consumes directories from the DirQueue
    /// - It produces both files (OutputQueue) and subdirectories (back to
    ///   DirQueue)
    /// - It updates progress via ProgressQueue
    ///
    /// The search logic handles:
    /// - Complex path patterns with wildcards
    /// - UNC and local paths differently
    /// - Directory-only or file-only searches
    /// - Pattern-based recursion
    /// </remarks>
    /// <param name="token">Cancellation token to support stopping the search
    /// operation</param>
    protected async Task DirectoryProcessor(CancellationToken token)
    {

        /*
         * process each directory from the queue until cancellation is requested
         * or queue is empty.
         * this loop enables parallel processing of multiple directories.
         */

        // loop while not canceled and dequeue succeeds
        while (!token.IsCancellationRequested && DirQueue.TryDequeue(
            out string? fullSearchMaskPositionedPath))
        {

            // increment count of unqueued directories
            Interlocked.Increment(ref dirsUnQueued);

            // check for cancellation request
            token.ThrowIfCancellationRequested();

            // log processing directory if verbose mode enabled, providing
            // details on current path for user to track search progress
            if (UseVerboseOutput)
            {

                // enqueue verbose message with path details
                VerboseQueue.Enqueue((
                    "Processing directory: " + fullSearchMaskPositionedPath
                ));
            }

            // try processing the directory
            try
            {

                // declare workload variables
                string remainingSearchMask, remainingSearchMaskToRepeatWhenFound,
                    currentLocation, currentFileSearchMask,
                    uncMachineNameToEnumerate;

                // more workload variables
                bool isUncPath, hasLongPathPrefix, recurseSubDirectories,
                    noMoreCustomWildcards, shouldEnumerateFiles,
                    shouldEnumerateDirectories;

                // depth variables
                int currentRecursionDepth, currentRecursionLimit;

                // get parameters for current workload
                GetCurrentWorkloadParameters(

                    fullSearchMaskPositionedPath,

                    out currentRecursionDepth,
                    out currentRecursionLimit,
                    out recurseSubDirectories,
                    out shouldEnumerateFiles,
                    out shouldEnumerateDirectories,
                    out isUncPath,
                    out noMoreCustomWildcards,
                    out hasLongPathPrefix,
                    out remainingSearchMask,
                    out remainingSearchMaskToRepeatWhenFound,
                    out currentLocation,
                    out currentFileSearchMask,
                    out uncMachineNameToEnumerate
                );

                // check if this search mask position has already been visited
                if (SearchMaskPositionAlreadyVisited(currentLocation,
                    currentFileSearchMask, token))
                {

                    // skip to next if already visited
                    continue;
                }

                // check recursion depth limit

                // enforce maximum recursion depth if specified to prevent stack
                // overflows in deep directories
                if (currentRecursionLimit > 0 && currentRecursionDepth >
                    currentRecursionLimit)
                {

                    // log skip due to depth if verbose, informing user why
                    // certain deep paths are not searched
                    if (UseVerboseOutput)
                    {

                        // enqueue verbose message with depth and path
                        VerboseQueue.Enqueue((
                            "Skipping path due to max recursion depth (" +
                            MaxRecursionDepth + "): " + currentLocation
                        ));
                    }

                    // skip this path
                    continue;
                }

                // enumerate files if needed
                if (shouldEnumerateFiles)
                {

                    // call file enumeration asynchronously
                    await EnumerateDirectoryFiles(

                        currentLocation,
                        currentFileSearchMask,
                        hasLongPathPrefix,
                        noMoreCustomWildcards,
                        isUncPath,
                        token
                    );
                }

                // enumerate directories if needed
                if (shouldEnumerateDirectories)
                {

                    // log enumerating subdirectories if verbose, showing user
                    // where subfolder scanning occurs
                    if (UseVerboseOutput)
                    {

                        // enqueue verbose message with location
                        VerboseQueue.Enqueue((
                            "Enumerating subdirectories in: " + currentLocation
                        ));
                    }

                    // call subdirectory enumeration
                    EnumerateSubDirectories(

                        currentLocation,
                        currentFileSearchMask,
                        remainingSearchMask,
                        remainingSearchMaskToRepeatWhenFound,
                        uncMachineNameToEnumerate,
                        recurseSubDirectories,
                        noMoreCustomWildcards,
                        hasLongPathPrefix,
                        isUncPath,
                        token
                    );
                }
            }
            catch (UnauthorizedAccessException e)
            {

                // log access denied if verbose, helping user identify
                // permission issues in paths
                if (UseVerboseOutput)
                {

                    // enqueue verbose message with path and error
                    VerboseQueue.Enqueue((
                        "Access denied for path " +
                        fullSearchMaskPositionedPath + ": " + e.Message
                    ));
                }

                // queue progress message with error for access denied
                ProgressQueue.Enqueue((
                    "Access denied: " + fullSearchMaskPositionedPath + " - " +
                    e.Message
                ));
            }
            catch (IOException e)
            {

                // log io error if verbose, informing user of file system
                // issues encountered
                if (UseVerboseOutput)
                {

                    // enqueue verbose message with path and error
                    VerboseQueue.Enqueue((
                        "I/O error for path " + fullSearchMaskPositionedPath +
                        ": " + e.Message
                    ));
                }

                // queue progress message with io error
                ProgressQueue.Enqueue((
                    "I/O error: " + fullSearchMaskPositionedPath + " - " +
                    e.Message
                ));
            }
            catch (Exception e)
            {

                // log unexpected error if verbose, providing full details for
                // debugging unexpected issues
                if (UseVerboseOutput)
                {

                    // enqueue verbose message with path, message, and stack
                    VerboseQueue.Enqueue((
                        "Unexpected error processing " +
                        fullSearchMaskPositionedPath + ": \r\n" + e.Message +
                        "\r\n" + e.StackTrace.ToString()
                    ));

                    // log inner exception if present
                    if (e.InnerException != null)
                    {

                        // enqueue inner exception message
                        VerboseQueue.Enqueue((
                            "Inner exception: " + e.InnerException.Message
                        ));
                    }
                }

                // queue progress message with general error
                ProgressQueue.Enqueue((
                    "Error processing " + fullSearchMaskPositionedPath +
                    " - " + e.Message
                ));
            }

            // check for cancellation after processing
            token.ThrowIfCancellationRequested();
        }
    }
    /// <summary>
    /// Gets parameters for current workload.
    /// </summary>
    /// <param name="ProvidedLocation">The provided location string.</param>
    /// <param name="CurrentRecursionDepth">Outputs the current recursion
    /// depth.</param>
    /// <param name="CurrentRecursionLimit">Outputs the current recursion
    /// limit.</param>
    /// <param name="RecurseSubDirectories">Outputs whether to recurse
    /// subdirectories.</param>
    /// <param name="ShouldEnumerateFiles">Outputs whether to enumerate
    /// files.</param>
    /// <param name="ShouldEnumerateDirectories">Outputs whether to enumerate
    /// directories.</param>
    /// <param name="IsUncPath">Outputs if it's a UNC path.</param>
    /// <param name="NoMoreCustomWildcards">Outputs if no more custom
    /// wildcards.</param>
    /// <param name="HasLongPathPrefix">Outputs if has long path
    /// prefix.</param>
    /// <param name="RemainingSearchMask">Outputs the remaining search
    /// mask.</param>
    /// <param name="RemainingSearchMaskToRepeatWhenFound">Outputs the repeat
    /// mask when found.</param>
    /// <param name="CurrentLocation">Outputs the current location.</param>
    /// <param name="CurrentFileSearchMask">Outputs the current file search
    /// mask.</param>
    /// <param name="UncMachineNameToEnumerate">Outputs the UNC machine name
    /// to enumerate.</param>
    void GetCurrentWorkloadParameters(
        string ProvidedLocation,

        out int CurrentRecursionDepth,
        out int CurrentRecursionLimit,
        out bool RecurseSubDirectories,
        out bool ShouldEnumerateFiles,
        out bool ShouldEnumerateDirectories,
        out bool IsUncPath,
        out bool NoMoreCustomWildcards,
        out bool HasLongPathPrefix,
        out string RemainingSearchMask,
        out string RemainingSearchMaskToRepeatWhenFound,
        out string CurrentLocation,
        out string CurrentFileSearchMask,
        out string UncMachineNameToEnumerate
    )
    {

        // split the input into location and remaining search mask for
        // processing

        // handle long path prefixes and tilde expansion
        EnsureFullProvidedLocationAndSearchMask(

            ref ProvidedLocation,

            out HasLongPathPrefix,
            out IsUncPath,
            out UncMachineNameToEnumerate

        );

        // separate the fixed path prefix from the wildcard-containing parts

        // advance to the next search location based on wildcards in the path

        // this sets up the current location and file search mask for
        // enumeration
        AdvanceSearchMaskToNextSearchLocation(
            ProvidedLocation,

            IsUncPath,
            out RecurseSubDirectories,
            out NoMoreCustomWildcards,
            out RemainingSearchMask,
            out RemainingSearchMaskToRepeatWhenFound,
            out CurrentLocation,
            out CurrentFileSearchMask

        );

        // get depth parameters
        GetCurrentDepthParameters(
            CurrentLocation,
            IsUncPath,
            out CurrentRecursionDepth,
            out CurrentRecursionLimit
        );

        // determine if enumerating unc shares
        bool enumUncShares = !string.IsNullOrEmpty(UncMachineNameToEnumerate);

        // set if should enumerate files
        ShouldEnumerateFiles = !enumUncShares &&
            (RemainingSearchMask.IndexOf("\\") < 0) && (
                FilesAndDirectories.IsPresent ||
                !Directory.IsPresent
            );

        // set if should enumerate directories
        ShouldEnumerateDirectories = CurrentFileSearchMask.IndexOf(':') < 0 && (
            enumUncShares || RecurseSubDirectories || Directory.IsPresent ||
            FilesAndDirectories.IsPresent
        );

        // get full path for current location
        CurrentLocation = Path.GetFullPath(CurrentLocation);

        // adjust repeat mask if ends with *
        if (RemainingSearchMask.EndsWith('*') &&
            !RemainingSearchMaskToRepeatWhenFound.EndsWith("*"))
        {

            // append *
            RemainingSearchMaskToRepeatWhenFound += "*";
        }

        // log exit parameters if verbose, summarizing all outputs for
        // complete overview
        if (UseVerboseOutput)
        {

            // enqueue verbose out message with all params
            VerboseQueue.Enqueue((
                "GetCurrentWorkloadParameters\r\n" +
                "RecurseSubDirectories: '" + RecurseSubDirectories + "'\r\n" +
                "IsUncPath: '" + IsUncPath + "'\r\n" +
                "NoMoreCustomWildcards: '" + NoMoreCustomWildcards + "'\r\n" +
                "HasLongPathPrefix: '" + HasLongPathPrefix + "'\r\n" +
                "RemainingSearchMask: '" + RemainingSearchMask + "'\r\n" +
                "RemainingSearchMaskToRepeatWhenFound: '" +
                RemainingSearchMaskToRepeatWhenFound + "'\r\n" +
                "CurrentLocation: '" + CurrentLocation + "'\r\n" +
                "CurrentFileSearchMask: '" + CurrentFileSearchMask + "'\r\n" +
                "CurrentRecursionDepth: '" + CurrentRecursionDepth + "'\r\n" +
                "CurrentRecursionLimit: '" + CurrentRecursionLimit + "'\t\n" +
                "ShouldEnumerateFiles : '" + ShouldEnumerateFiles + "'\r\n" +
                "ShouldEnumerateDirectories: '" +
                ShouldEnumerateDirectories + "'\r\n---\r\n"
            ));
        }
    }

    /// <summary>
    /// Ensures full provided location and search mask, handling prefixes and
    /// expansions.
    /// </summary>
    /// <param name="ProvidedLocation">The provided location, passed by
    /// reference.</param>
    /// <param name="HasLongPathPrefix">Outputs if has long path
    /// prefix.</param>
    /// <param name="IsUncPath">Outputs if it's a UNC path.</param>
    /// <param name="UncMachineNameToEnumerate">Outputs the UNC machine name
    /// to enumerate.</param>
    protected void EnsureFullProvidedLocationAndSearchMask(

        ref string ProvidedLocation,
        out bool HasLongPathPrefix,

        out bool IsUncPath,
        out string UncMachineNameToEnumerate
    )
    {

        // split the input string to separate location and search pattern for
        // independent processing

        // append * if ends with \
        if (ProvidedLocation.EndsWith("\\"))
        {

            // add wildcard
            ProvidedLocation += "*";
        }

        // check for long path prefix
        HasLongPathPrefix = ProvidedLocation.StartsWith(@"\\?\");

        // strip prefix if present
        if (HasLongPathPrefix)
        {

            // remove \\?\
            ProvidedLocation = ProvidedLocation.Substring(4);
        }

        // expand ~ to user home directory if requested
        if (ProvidedLocation.StartsWith("~"))
        {
            // get home path
            var homePath = Environment.GetFolderPath(
                Environment.SpecialFolder.UserProfile
            );

            // combine with rest
            ProvidedLocation = Path.Combine(homePath,
                ProvidedLocation.Substring(1).TrimStart('\\', '/')
            );
        }

        // init unc path flag
        IsUncPath = false;

        // handle long prefix for unc
        if (HasLongPathPrefix)
        {

            // check unc start
            if (ProvidedLocation.StartsWith(
                @"UNC\", StringComparison.InvariantCultureIgnoreCase
            ))
            {

                // adjust for unc
                ProvidedLocation = @"\" + ProvidedLocation.Substring(3);

                // set unc flag
                IsUncPath = true;
            }
        }
        else
        {

            // check unc start
            IsUncPath = ProvidedLocation.StartsWith(@"\\");
        }

        // init unc machine
        UncMachineNameToEnumerate = string.Empty;

        // handle unc paths
        if (IsUncPath)
        {

            // handle short unc
            if (ProvidedLocation.Length == 2)
            {

                // use local machine
                ProvidedLocation = @"\\" + Environment.MachineName + @"\";
            }
            else
            {

                // find first slash
                int firstSlash = ProvidedLocation.IndexOf('\\', 2);

                // append \ if no slash
                if (firstSlash < 0)
                {

                    // add trailing
                    ProvidedLocation += @"\";
                }
            }

            // find second slash
            int secondSlash = ProvidedLocation.IndexOf('\\', 2);

            // extract machine name
            UncMachineNameToEnumerate = ProvidedLocation.Substring(2,
                secondSlash - 2).Trim();

            // handle local names
            if (UncMachineNameToEnumerate.Equals(".") ||
                UncMachineNameToEnumerate.Equals(
                    "localhost", StringComparison.OrdinalIgnoreCase
                ))
            {

                // set to machine name
                UncMachineNameToEnumerate = Environment.MachineName;
            }

            // rebuild provided location
            ProvidedLocation = @"\\" + UncMachineNameToEnumerate +
                ProvidedLocation.Substring(secondSlash);

            // find second slash again
            secondSlash = ProvidedLocation.IndexOf('\\', 2);

            // init share name
            string uncShareName = string.Empty;

            // find third slash
            int thirdSlash = ProvidedLocation.IndexOf('\\', secondSlash + 1);

            // handle third slash
            if (thirdSlash >= 0)
            {

                // extract share name
                uncShareName = ProvidedLocation.Substring(secondSlash + 1,
                    thirdSlash - secondSlash - 1).Trim();

                // rebuild if share not empty
                if (!string.IsNullOrEmpty(uncShareName))
                {

                    // combine parts
                    ProvidedLocation = ProvidedLocation.Substring(0,
                        secondSlash + 1) +
                        uncShareName + ProvidedLocation.Substring(thirdSlash);
                }
                else
                {

                    // throw if double slashes
                    throw new InvalidOperationException((
                        "double slashes should have been removed"
                    ));
                }
            }

            // clear machine if share no wildcards
            if (ProvidedLocation.Length > secondSlash + 1 &&
                !uncShareName.Contains("*") && !uncShareName.Contains("?"))
            {

                // clear
                UncMachineNameToEnumerate = string.Empty;
            }
            else
            {

                // append share
                UncMachineNameToEnumerate += ";" +
                    (string.IsNullOrEmpty(uncShareName) ? "*" : uncShareName);
            }
        }
    }

    /// <summary>
    /// Determines and strips recurse pattern.
    /// </summary>
    /// <param name="RemainingSearchMask">Remaining search mask by
    /// ref.</param>
    /// <param name="CurrentFileSearchMask">Current file search mask by
    /// ref.</param>
    /// <returns>Whether it was a recurse pattern.</returns>
    bool DetermineAndStripRecursePattern(

        ref string RemainingSearchMask,
        ref string CurrentFileSearchMask
    )
    {

        // check if recurse pattern
        bool result = RecursePatternMatcher.IsMatch(CurrentFileSearchMask);

        // init recurse flag
        bool isRecursePattern = result;

        // loop while recurse
        while (isRecursePattern)
        {

            // find first slash
            int firstSlash = RemainingSearchMask.IndexOf('\\');

            // handle if slash and mask not empty
            if (!string.IsNullOrEmpty(CurrentFileSearchMask) &&
                firstSlash >= 0)
            {

                // set current mask
                CurrentFileSearchMask = RemainingSearchMask.Substring(0,
                    firstSlash);

                // update remaining
                RemainingSearchMask = RemainingSearchMask.Substring(
                    firstSlash + 1
                );
            }
            else
            {

                // set current to remaining
                CurrentFileSearchMask = RemainingSearchMask;

                // clear remaining
                RemainingSearchMask = string.Empty;
            }

            // check again
            isRecursePattern = RecursePatternMatcher.IsMatch(
                CurrentFileSearchMask
            );
        }

        // return result
        return result;
    }

    /// <summary>
    /// Advances search mask to next search location.
    /// </summary>
    /// <param name="ProvidedLocation">Provided location.</param>
    /// <param name="IsUncPath">If UNC path.</param>
    /// <param name="RecurseSubDirectories">Outputs recurse
    /// subdirectories.</param>
    /// <param name="NoMoreCustomWildcards">Outputs no more custom
    /// wildcards.</param>
    /// <param name="RemainingSearchMask">Outputs remaining search
    /// mask.</param>
    /// <param name="RemainingSearchMaskToRepeatWhenFound">Outputs repeat mask
    /// when found.</param>
    /// <param name="CurrentLocation">Outputs current location.</param>
    /// <param name="CurrentFileSearchMask">Outputs current file search
    /// mask.</param>
    protected void AdvanceSearchMaskToNextSearchLocation(

        string ProvidedLocation,

        bool IsUncPath,

        out bool RecurseSubDirectories,
        out bool NoMoreCustomWildcards,

        out string RemainingSearchMask,
        out string RemainingSearchMaskToRepeatWhenFound,
        out string CurrentLocation,
        out string CurrentFileSearchMask
    )
    {
        // determine remaining mask
        DetermineRemainingSearchMask(
            ProvidedLocation,
            IsUncPath,

            out RemainingSearchMask,
            out CurrentLocation
        );

        // determine current mask
        DetermineCurrentSearchMask(

            ref RemainingSearchMask,
            out RemainingSearchMaskToRepeatWhenFound,

            out RecurseSubDirectories,
            out NoMoreCustomWildcards,
            out CurrentFileSearchMask
        );
    }

    /// <summary>
    /// Determines remaining search mask.
    /// </summary>
    /// <param name="ProvidedLocation">Provided location.</param>
    /// <param name="IsUncPath">If UNC path.</param>
    /// <param name="RemainingSearchMask">Outputs remaining search
    /// mask.</param>
    /// <param name="CurrentLocation">Outputs current location.</param>
    protected void DetermineRemainingSearchMask(

       string ProvidedLocation,
       bool IsUncPath,

       out string RemainingSearchMask,
       out string CurrentLocation
    )
    {

        // calculate starting index for path based on whether it's unc or local
        // to handle root correctly

        // init index
        int idxS;

        // handle unc
        if (IsUncPath)
        {

            // unc path handling - skip server and share name

            // find first
            int first = ProvidedLocation.IndexOf('\\', 0);

            // find second
            int second = ProvidedLocation.IndexOf('\\', first + 2);

            // find third
            int third = ProvidedLocation.IndexOf('\\', second + 2);

            // set index
            idxS = third >= 0 ? third + 1 : ProvidedLocation.Length;
        }
        else
        {

            // local path handling - skip drive letter

            // find first
            int first = ProvidedLocation.IndexOf('\\');

            // set index
            idxS = first >= 0 ? first + 1 : ProvidedLocation.Length;
        }

        // init remaining
        RemainingSearchMask = string.Empty;

        // separate the fixed path prefix from the wildcard-containing parts

        // set current location
        CurrentLocation = ProvidedLocation.Substring(0, idxS);

        // get remaining
        var remainingDetermined = ProvidedLocation.Substring(idxS);

        // split parts
        var remainingDeterminedParts = remainingDetermined.Split(
                '\\',
                StringSplitOptions.RemoveEmptyEntries
            ).ToArray<string>();

        // skip non-wildcard parts to optimize the starting point for search

        // init skipped
        var iSkipped = 0;

        // get length
        var l = remainingDeterminedParts.Length;

        // loop parts
        foreach (var part in remainingDeterminedParts)
        {

            // break if wildcard
            if (part.Contains('*') || part.Contains('?'))
                break;

            // break if last and no wildcard
            if (iSkipped == l - 1 && !(part.Contains('*') ||
                part.Contains('?')))
                break;

            // increment skipped
            iSkipped++;

            // combine to current
            CurrentLocation = System.IO.Path.Combine(CurrentLocation, part);
        }

        // join remaining parts that may contain wildcards
        RemainingSearchMask = string.Join('\\',
            remainingDeterminedParts.Skip(iSkipped).ToList<string>()
        );
    }

    /// <summary>
    /// Determines current search mask.
    /// </summary>
    /// <param name="RemainingSearchMask">Remaining search mask by
    /// ref.</param>
    /// <param name="RemainingSearchMaskToRepeatWhenFound">Outputs repeat mask
    /// when found.</param>
    /// <param name="RecurseSubDirectories">Outputs recurse
    /// subdirectories.</param>
    /// <param name="NoMoreCustomWildcards">Outputs no more custom
    /// wildcards.</param>
    /// <param name="CurrentFileSearchMask">Outputs current file search
    /// mask.</param>
    protected void DetermineCurrentSearchMask(

        ref string RemainingSearchMask,
        out string RemainingSearchMaskToRepeatWhenFound,

        out bool RecurseSubDirectories,
        out bool NoMoreCustomWildcards,
        out string CurrentFileSearchMask)
    {

        // init recurse pattern flag
        bool wasRecursePattern = false;

        // set no more wildcards
        NoMoreCustomWildcards = true;

        // default current mask
        CurrentFileSearchMask = "*";

        // set recurse based on switch
        RecurseSubDirectories = !(NoRecurse.IsPresent);

        // set repeat to remaining
        RemainingSearchMaskToRepeatWhenFound = RemainingSearchMask;

        // extract the pattern for the current directory level

        // find first slash
        int firstSlash = RemainingSearchMask.IndexOf('\\');

        // handle if slash found
        if (firstSlash >= 0)
        {

            // set current mask
            CurrentFileSearchMask = RemainingSearchMask.Substring(0,
                firstSlash);

            // update remaining
            RemainingSearchMask = RemainingSearchMask.Substring(
                firstSlash + 1
            );

            // strip recurse
            wasRecursePattern = DetermineAndStripRecursePattern(

                ref RemainingSearchMask,
                ref CurrentFileSearchMask
            );

            // find next slash
            firstSlash = RemainingSearchMask.IndexOf('\\');

            // set repeat
            RemainingSearchMaskToRepeatWhenFound = RemainingSearchMask;

            // check no more wildcards
            NoMoreCustomWildcards = RemainingSearchMask == string.Empty ||
                RemainingSearchMask == "*";

            // more wildcards flag
            bool MoreCustomWildcards = !NoMoreCustomWildcards;

            // update recurse
            RecurseSubDirectories |= wasRecursePattern | MoreCustomWildcards;

            // build repeated
            var repeatedMask = string.IsNullOrEmpty(RemainingSearchMask) ?
                        CurrentFileSearchMask :
                        (CurrentFileSearchMask + "\\" + RemainingSearchMask);

            // handle recurse pattern
            if (wasRecursePattern)
            {

                // prepend **
                RemainingSearchMask = "**\\" + repeatedMask;
            }
            else
            {

                // set if recurse
                if (RecurseSubDirectories)
                {

                    // set to repeated
                    RemainingSearchMask = repeatedMask;
                }
            }
        }
        else if (!string.IsNullOrEmpty(RemainingSearchMask))
        {

            // check recurse
            wasRecursePattern = RecursePatternMatcher.IsMatch(
                RemainingSearchMask
            );

            // update recurse
            RecurseSubDirectories |= wasRecursePattern;

            // check no more
            NoMoreCustomWildcards = RemainingSearchMask == string.Empty ||
                RemainingSearchMask == "*";

            // more flag
            bool MoreCustomWildcards = !NoMoreCustomWildcards;

            // set current
            CurrentFileSearchMask = RemainingSearchMask;

            // set remaining based on recurse
            RemainingSearchMask = wasRecursePattern ? "**" :
                CurrentFileSearchMask;

            // set repeat
            RemainingSearchMaskToRepeatWhenFound = CurrentFileSearchMask;
        }
    }

    /// <summary>
    /// Checks if search mask position already visited.
    /// </summary>
    /// <param name="CurrentLocation">Current location.</param>
    /// <param name="CurrentFileSearchMask">Current file search mask.</param>
    /// <param name="token">Cancellation token.</param>
    /// <returns>If already visited.</returns>
    private bool SearchMaskPositionAlreadyVisited(
        string CurrentLocation,
        string CurrentFileSearchMask,
        CancellationToken token)
    {

        // try add to visited
        if (!VisitedNodes.TryAdd(Path.Combine(CurrentLocation,
            CurrentFileSearchMask), true))
        {

            // log skip if verbose
            if (UseVerboseOutput)
            {

                // enqueue skip
                VerboseQueue.Enqueue((
                    "Skipping already processed path: " + CurrentLocation +
                    " with pattern " + CurrentFileSearchMask
                ));
            }

            // check cancel
            token.ThrowIfCancellationRequested();

            // return visited
            return true;
        }

        // not visited
        return false;
    }

    // verbosequeue

    /// <summary>
    /// Enumerates directory files.
    /// </summary>
    /// <param name="StartLocation">Start location.</param>
    /// <param name="CurrentFileSearchMask">Current file search mask.</param>
    /// <param name="HasLongPathPrefix">Has long path prefix.</param>
    /// <param name="NoMoreCustomWildcards">No more custom wildcards.</param>
    /// <param name="IsUncPath">Is UNC path.</param>
    /// <param name="token">Cancellation token.</param>
    protected async Task EnumerateDirectoryFiles(

        string StartLocation,
        string CurrentFileSearchMask,
        bool HasLongPathPrefix,
        bool NoMoreCustomWildcards,
        bool IsUncPath,
        CancellationToken token
    )
    {

        // options for enumeration to ignore inaccessible items and reparse
        // points

        // create options
        System.IO.EnumerationOptions options =
            new System.IO.EnumerationOptions
            {

                // no recurse
                RecurseSubdirectories = false, // Handle recursion manually

                // ignore access
                IgnoreInaccessible = true,

                // set casing
                MatchCasing = CaseSearchMaskMatching,

                // set buffer
                BufferSize = 163840,

                // set skip attributes
                AttributesToSkip = AttributesToSkip
            };

        // skip reparse if not follow
        if (!FollowSymlinkAndJunctions.IsPresent)
        {

            // set skip
            options.AttributesToSkip = FileAttributes.ReparsePoint;
        }

        // find stream index
        int idp = CurrentFileSearchMask.IndexOf(':');

        // set has stream
        bool hasStreamPattern = idp >= 0;

        // init stream name
        string streamName = null;

        // handle stream pattern
        if (hasStreamPattern)
        {

            // get stream name
            streamName = CurrentFileSearchMask.Substring(idp + 1);

            // default *
            if (streamName == string.Empty) streamName = "*";

            // update mask
            CurrentFileSearchMask = CurrentFileSearchMask.Substring(0, idp);
        }

        // create matcher
        var patternMatcher = new WildcardPattern(CurrentFileSearchMask,
            CurrentWildCardOptions);

        // enumerate files in top directory only

        // loop files
        foreach (var filePath in System.IO.Directory.EnumerateFiles(
            (
            IsUncPath ?
                ("\\\\?\\UNC" + StartLocation.Substring(1)) :
                ("\\\\?\\" + StartLocation)
            ),
            CurrentFileSearchMask,
            SearchOption.TopDirectoryOnly
        ))
        {

            // check cancel
            token.ThrowIfCancellationRequested();

            // normalize path
            var normalizedFilePath = HasLongPathPrefix ? filePath :
                NormalizePathForNonFileSystemUse(filePath);

            // create file info
            var fileInfo = new FileInfo(normalizedFilePath);

            // check size constraints
            if ((MaxFileSize > 0 && fileInfo.Length > MaxFileSize) ||
                (MinFileSize > 0 && fileInfo.Length < MinFileSize))
            {

                // log skip size if verbose
                if (UseVerboseOutput)
                {
                    // enqueue skip size
                    VerboseQueue.Enqueue((
                        "Skipping file " + normalizedFilePath +
                        " due to size constraints. Size: " +
                        fileInfo.Length + " bytes"
                    ));
                }

                // skip
                continue;
            }

            // check mod dates
            if ((ModifiedAfter.HasValue &&
                fileInfo.LastWriteTimeUtc < ModifiedAfter.Value) ||
                (ModifiedBefore.HasValue &&
                fileInfo.LastWriteTimeUtc > ModifiedBefore.Value))
            {

                // log skip date if verbose
                if (UseVerboseOutput)
                {

                    // enqueue skip date
                    VerboseQueue.Enqueue((
                        "Skipping file " + normalizedFilePath +
                        " due to modification date constraints. " +
                        "LastWriteTimeUtc: " + fileInfo.LastWriteTimeUtc
                    ));
                }

                // skip
                continue;
            }

            // check exclusion
            bool noExclusion = NoMoreCustomWildcards ||
                patternMatcher.IsMatch(fileInfo.Name);

            // set have exclusion
            bool haveExclusion = !noExclusion;

            // skip if exclusion
            if (haveExclusion)
            {

                // log mismatch if verbose
                if (UseVerboseOutput)
                {

                    // enqueue mismatch
                    VerboseQueue.Enqueue((
                        "Skipping file " + normalizedFilePath +
                        " due to pattern mismatch with " +
                        CurrentFileSearchMask
                    ));
                }

                // skip
                continue;
            }

            // check exclude patterns
            foreach (var pattern in FileExcludePatterns)
            {

                // if match
                if (pattern.IsMatch(normalizedFilePath))
                {

                    // set exclusion
                    haveExclusion = true;

                    // log exclude if verbose
                    if (UseVerboseOutput)
                    {

                        // enqueue exclude
                        VerboseQueue.Enqueue((
                            "Excluding file " + normalizedFilePath +
                            " due to pattern " + pattern
                        ));
                    }

                    // break
                    break;
                }
            }

            // skip if exclusion
            if (haveExclusion)
            {

                // skip
                continue;
            }

            // set only ads
            bool onlyAds = !string.IsNullOrEmpty(streamName);

            // handle not only ads
            if (!onlyAds)
            {

                // skip excluded patterns

                // if have pattern
                if (HavePattern)
                {

                    // check if content search should be performed based on
                    // switches and extension

                    // if include or not skip ext
                    if (IncludeNonTextFileMatching ||
                        !ExtensionsToSkip.Contains(
                            Path.GetExtension(normalizedFilePath)
                        ))
                    {

                        // process content
                        await FileContentProcessor(normalizedFilePath,
                            cts!.Token);
                    }
                }
                else
                {

                    // log output if verbose
                    if (UseVerboseOutput)
                    {

                        // enqueue output
                        VerboseQueue.Enqueue((
                            "Outputting file: " + normalizedFilePath
                        ));
                    }

                    // output file info if no content pattern
                    OutputQueue.Enqueue(new FileInfo(normalizedFilePath));

                    // progress
                    ProgressQueue.Enqueue((
                        "Found file: " + normalizedFilePath
                    ));
                }
            }

            // process alternate data streams if the switch is set

            // if include or only ads
            if (IncludeAlternateFileStreams.IsPresent || onlyAds)
            {

                // get streams
                await GetFileAlternateFileStreams(normalizedFilePath,
                    cts!.Token, streamName);
            }
        }
    }

    /// <summary>
    /// Gets file alternate data streams.
    /// </summary>
    /// <param name="FilePath">File path.</param>
    /// <param name="token">Cancellation token.</param>
    /// <param name="StreamName">Stream name optional.</param>
    protected async Task GetFileAlternateFileStreams(string FilePath,
        CancellationToken token, string StreamName = null)
    {

        // create pattern if name
        WildcardPattern wildcardPattern = string.IsNullOrEmpty(StreamName) ?
            null :
          new WildcardPattern(StreamName, CurrentWildCardOptions);

        // try process
        try
        {

            // init stream data
            var streamData = new WIN32_FIND_STREAM_DATA();

            // init handle
            IntPtr handle = IntPtr.Zero;

            // try finally
            try
            {

                // start enumerating streams using win32 api
                handle = FindFirstStreamW(FilePath, 0, ref streamData, 0);

                // handle invalid
                if (handle == IntPtr.Zero || handle == new IntPtr(-1))
                {

                    // get error
                    int error = Marshal.GetLastWin32Error();

                    // if error
                    if (error != 0)
                    {

                        // log error if verbose
                        if (UseVerboseOutput)
                        {

                            // enqueue error
                            VerboseQueue.Enqueue((
                                "Error accessing ADS for " + FilePath +
                                ": Win32 error " + error
                            ));
                        }

                        // progress error
                        ProgressQueue.Enqueue((
                            "Error retrieving ADS for " + FilePath +
                            ": Win32 error " + error
                        ));
                    }
                }
                else
                {

                    // loop through all streams
                    do
                    {

                        // filter non-standard streams

                        // if name and not data
                        if (!string.IsNullOrEmpty(streamData.StreamName) &&
                            streamData.StreamName != ":$DATA" &&
                            streamData.StreamName != "::$DATA")
                        {

                            // clean stream name

                            // trim :
                            var streamName = streamData.StreamName.TrimStart(
                                ':'
                            );

                            // find data index
                            int dataIdx = streamName.IndexOf(
                                ":$DATA", StringComparison.OrdinalIgnoreCase
                            );

                            // substring if found
                            if (dataIdx > 0)
                                streamName = streamName.Substring(0, dataIdx);

                            // skip if no match
                            if (wildcardPattern != null &&
                                !wildcardPattern.IsMatch(streamName))
                            {
                                // continue
                                continue;
                            }

                            // if not empty
                            if (!string.IsNullOrEmpty(streamName))
                            {

                                // build ads path
                                var adsPath = $"{FilePath}:{streamName}";

                                // if have pattern and search ads
                                if (HavePattern && SearchADSContent.IsPresent)
                                {

                                    // perform content search in ads if enabled

                                    // if include or not skip
                                    if (IncludeNonTextFileMatching ||
                                        !ExtensionsToSkip.Contains(
                                            Path.GetExtension(streamName)
                                        ))
                                    {

                                        // process content
                                        await FileContentProcessor(adsPath,
                                            cts!.Token);
                                    }
                                    else if (UseVerboseOutput)
                                    {

                                        // enqueue skip ext
                                        VerboseQueue.Enqueue((
                                            "Skipping content search in ADS " +
                                            "due to extension filter: " +
                                            adsPath
                                        ));
                                    }

                                    // continue
                                    continue;
                                }

                                // log found if verbose
                                if (UseVerboseOutput)
                                {

                                    // enqueue found
                                    VerboseQueue.Enqueue((
                                        "Found alternate data streams for: " + adsPath
                                    ));
                                }

                                // output ads info
                                OutputQueue.Enqueue(new FileInfo(adsPath));

                                // progress
                                ProgressQueue.Enqueue((
                                    "Found ADS: " + adsPath
                                ));
                            }
                        }
                    }
                    while (FindNextStreamW(handle, ref streamData));
                }
            }
            finally
            {

                // close the find handle

                // if valid handle
                if (handle != IntPtr.Zero && handle != new IntPtr(-1))
                    FindClose(handle);
            }
        }
        catch (Exception ex)
        {

            // log error if verbose
            if (UseVerboseOutput)
            {

                // enqueue error
                VerboseQueue.Enqueue((
                    "Error processing ADS for " + FilePath + ": " +
                    ex.Message
                ));

                // log inner if present
                if (ex.InnerException != null)
                {

                    // enqueue inner
                    VerboseQueue.Enqueue((
                        "Inner exception: " + ex.InnerException.Message
                    ));
                }
            }

            // progress error
            ProgressQueue.Enqueue((
                "Error retrieving ADS for " + FilePath + ": " + ex.Message
            ));
        }

        // check cancel
        token.ThrowIfCancellationRequested();
    }

    /// <summary>
    /// Processes file content for pattern matching.
    /// </summary>
    /// <param name="filePath">File path to process.</param>
    /// <param name="token">Cancellation token.</param>
    protected async Task FileContentProcessor(string filePath,
        CancellationToken token)
    {

        // early exit if cancellation requested
        if (token.IsCancellationRequested) return;

        // create file info
        var fileInfo = new FileInfo(filePath);

        // init found
        var found = false;

        // try reading
        try
        {

            // open file stream for reading content
            using (var stream = new FileStream(filePath, FileMode.Open,
                FileAccess.Read, FileShare.Read, 4096, true))
            {

                // get matches using stream regex for large files
                var matchCollection = await PatternMatcher.GetMatchCollectionAsync(
                    stream,
                    PatternMatcherOptions
                );

                // check if any matches found
                found = matchCollection.Any();
            }

            // skip if no match
            if (!found)
            {

                // log no match if verbose, informing user why file is skipped
                if (UseVerboseOutput)
                {

                    // enqueue no match
                    VerboseQueue.Enqueue((
                        "No pattern match found in file: " + filePath
                    ));
                }

                // return
                return;
            }
        }
        catch
        {

            // log failure if verbose
            VerboseQueue.Enqueue((
                "Failed to read file: " + filePath
            ));

            // return
            return;
        }

        // log match if verbose
        if (UseVerboseOutput)
        {

            // enqueue match
            VerboseQueue.Enqueue((
                "Pattern match found in file: " + filePath
            ));

            // enqueue output
            VerboseQueue.Enqueue((
                "Outputting file with pattern match: " + filePath
            ));
        }

        // enqueue output
        OutputQueue.Enqueue(fileInfo);

        // queue progress
        ProgressQueue.Enqueue((
            "Found file: " + filePath
        ));

        // check cancel
        token.ThrowIfCancellationRequested();
    }

    /// <summary>
    /// Enumerates subdirectories matching patterns.
    /// </summary>
    /// <param name="CurrentLocation">Location.</param>
    /// <param name="CurrentFileSearchMask">File mask.</param>
    /// <param name="RemainingSearchMask">Remaining mask.</param>
    /// <param name="RemainingSearchMaskToRepeatWhenFound">Repeat mask.</param>
    /// <param name="uncMachineNameToEnumerate">UNC machine.</param>
    /// <param name="RecurseSubDirectories">Recurse.</param>
    /// <param name="NoMoreCustomWildcards">No wild.</param>
    /// <param name="HasLongPathPrefix">Long prefix.</param>
    /// <param name="IsUncPath">UNC.</param>
    /// <param name="token">Token.</param>
    void EnumerateSubDirectories(
    string CurrentLocation,
    string CurrentFileSearchMask,
    string RemainingSearchMask,
    string RemainingSearchMaskToRepeatWhenFound,
    string uncMachineNameToEnumerate,
    bool RecurseSubDirectories,
    bool NoMoreCustomWildcards,
    bool HasLongPathPrefix,
    bool IsUncPath,
    CancellationToken token
)
    {

        // adjust wildcards flag based on mask
        NoMoreCustomWildcards &= CurrentFileSearchMask == "*";

        // init found flag for subdirs
        var found = false;

        // create wildcard pattern matcher
        var patternMatcher = new WildcardPattern(CurrentFileSearchMask,
            CurrentWildCardOptions);

        // set remaining full mask
        var remainingFull = RemainingSearchMask;

        // handle leading recursive wildcard
        if (remainingFull.StartsWith("**\\"))
        {

            // trim recursive prefix
            remainingFull = remainingFull.Substring(3);

            // clear if no more wildcards or default
            if (NoMoreCustomWildcards || remainingFull == "*")
            {

                // set to empty
                remainingFull = "";
            }
        }

        // combine full pattern path
        var fullPattern = Path.Combine(CurrentLocation, remainingFull);

        // combine recursive pattern path
        var fullPatternRecurse = Path.Combine(CurrentLocation,
            RemainingSearchMask);

        // add long path prefix if needed
        if (HasLongPathPrefix)
        {

            // handle unc paths
            if (IsUncPath)
            {

                // escape and add unc prefix
                fullPattern = WildcardPattern.Escape("\\\\?\\UNC") +
                    fullPattern.Substring(1);

                // same for recurse
                fullPatternRecurse = WildcardPattern.Escape("\\\\?\\UNC") +
                    fullPatternRecurse.Substring(1);
            }
            else
            {

                // add local long prefix
                fullPattern = WildcardPattern.Escape("\\\\?\\") + fullPattern;

                // same for recurse
                fullPatternRecurse = WildcardPattern.Escape("\\\\?\\") +
                    fullPatternRecurse;
            }
        }

        // create matcher for full pattern
        var patternMatcherFull = new WildcardPattern(fullPattern,
            CurrentWildCardOptions);

        // create matcher for recursive full
        var patternMatcherFullRecurse = new WildcardPattern(fullPatternRecurse,
            CurrentWildCardOptions);

        // handle unc share enumeration if machine specified
        if (!string.IsNullOrEmpty(uncMachineNameToEnumerate))
        {

            // split unc parts by semicolon
            var uncParts = uncMachineNameToEnumerate.Split(';');

            // set machine name
            uncMachineNameToEnumerate = uncParts[0];

            // set share name
            var shareName = uncParts[1];

            // log enumerating unc if verbose, showing network scan details
            if (UseVerboseOutput)
            {

                // enqueue unc enumeration message
                VerboseQueue.Enqueue((
                    "Enumerating unc networkshares for " +
                    uncMachineNameToEnumerate
                ));
            }

            // create matcher for unc shares
            var uncShareMatcher = new WildcardPattern(shareName,
                CurrentWildCardOptions);

            // list disk shares on unc machine
            var shares = ListDiskSharesUNC(uncMachineNameToEnumerate);

            // get remaining parts after skipping unc prefix
            var partsLeft = string.Join('\\', Path.Combine(CurrentLocation,
                RemainingSearchMask).Split('\\').Skip<string>(4).ToArray());

            // add backslash if parts left
            partsLeft = string.IsNullOrEmpty(partsLeft) ? string.Empty :
                ('\\' + partsLeft);

            // process each share
            foreach (var share in shares)
            {

                // skip if share does not match
                if (!uncShareMatcher.IsMatch(share)) continue;

                // build full name with prefix
                string name = (HasLongPathPrefix ? (
                    "\\\\?\\UNC\\" + uncMachineNameToEnumerate + "\\" + share +
                    partsLeft
                ) : (
                    "\\\\" + uncMachineNameToEnumerate + "\\" + share +
                    partsLeft
                ));

                // log queueing share if verbose
                if (UseVerboseOutput)
                {

                    // enqueue queueing message
                    VerboseQueue.Enqueue((
                        "Queueing networkshares: " + name
                    ));
                }

                // set found flag
                found = true;

                // enqueue the name to dir queue
                DirQueue.Enqueue(name);

                // increment queued count
                Interlocked.Increment(ref dirsQueued);

                // add worker tasks if needed
                AddWorkerTasksIfNeeded();
            }
        }
        // enumerate directories matching the pattern
        else
        {

            // set enumeration options
            System.IO.EnumerationOptions options =
                new System.IO.EnumerationOptions
                {

                    // no automatic recursion
                    RecurseSubdirectories = false, // Handle recursion manually

                    // ignore inaccessible items
                    IgnoreInaccessible = true,

                    // set match casing
                    MatchCasing = CaseSearchMaskMatching
                };

            // skip reparse points if not following symlinks
            if (!FollowSymlinkAndJunctions.IsPresent)
            {

                // set attributes to skip
                options.AttributesToSkip = FileAttributes.ReparsePoint;
            }

            // enumerate directories with options
            foreach (var subDir in System.IO.Directory.EnumerateDirectories(
                (IsUncPath ?
                    ("\\\\?\\UNC" + CurrentLocation.Substring(1)) :
                    ("\\\\?\\" + CurrentLocation)
                ),
                "*",
                options
            )
         )
            {

                // check for cancellation
                token.ThrowIfCancellationRequested();

                // set found flag
                found = true;

                // normalize subdirectory path
                var normalizedSubDir = HasLongPathPrefix ? subDir :
                    NormalizePathForNonFileSystemUse(subDir);

                // check if filename matches pattern
                bool isMatch = patternMatcher.IsMatch(Path.GetFileName(
                    normalizedSubDir));

                // handle recursion if recurse and match or wildcards remain
                if (RecurseSubDirectories && (isMatch ||
                    !NoMoreCustomWildcards))
                {

                    // select remaining mask based on match
                    var remaining = (isMatch ?
                        RemainingSearchMaskToRepeatWhenFound :
                        RemainingSearchMask);

                    // default to * if empty
                    if (string.IsNullOrEmpty(remaining))
                    {

                        // set default
                        remaining = "*";
                    }

                    // log queueing subdir if verbose, showing remaining parts
                    if (UseVerboseOutput)
                    {

                        // enqueue queueing message
                        VerboseQueue.Enqueue((
                            "Queuing subdirectory for processing: " +
                            normalizedSubDir + " with remaining parts: " +
                            remaining
                        ));
                    }

                    // enqueue combined path
                    DirQueue.Enqueue(Path.Combine(normalizedSubDir, remaining));

                    // increment queued
                    Interlocked.Increment(ref dirsQueued);

                    // add workers if needed
                    AddWorkerTasksIfNeeded();
                }

                // check full pattern match
                bool isMatch1 = patternMatcherFull.IsMatch(normalizedSubDir);

                // check recursive full match
                bool isMatch2 = patternMatcherFullRecurse.IsMatch(
                    normalizedSubDir);

                // combine match results
                isMatch = isMatch1 || isMatch2;

                // output if searching directories or both
                if ((Directory.IsPresent || FilesAndDirectories.IsPresent) &&
                    isMatch)
                {

                    // init exclusion flag
                    bool haveExclusion = false;

                    // check each exclude pattern
                    foreach (var pattern in DirectoryExcludePatterns)
                    {

                        // set exclusion if matches
                        if (pattern.IsMatch(normalizedSubDir))
                        {

                            // set flag
                            haveExclusion = true;

                            // log exclusion if verbose
                            if (UseVerboseOutput)
                            {

                                // enqueue exclusion message
                                VerboseQueue.Enqueue((
                                    "Excluding file " + normalizedSubDir +
                                    " due to pattern " + pattern
                                ));
                            }

                            // break loop
                            break;
                        }
                    }

                    // skip if excluded
                    if (haveExclusion)
                    {

                        // log skip if verbose, explaining exclusion
                        if (UseVerboseOutput)
                        {

                            // enqueue skip message
                            VerboseQueue.Enqueue((
                                "Skipping directory " + normalizedSubDir +
                                " due to exclusion patterns"
                            ));
                        }

                        // continue to next
                        continue;
                    }

                    // log outputting if verbose
                    if (UseVerboseOutput)
                    {

                        // enqueue output message
                        VerboseQueue.Enqueue((
                            "Outputting directory: " + normalizedSubDir
                        ));
                    }

                    // enqueue directory info
                    OutputQueue.Enqueue(new DirectoryInfo(normalizedSubDir));

                    // queue progress found directory
                    ProgressQueue.Enqueue((
                        "Found directory: " + normalizedSubDir
                    ));
                }
            }
        }

        // log no subdirs found if verbose and none found
        if (!found && UseVerboseOutput)
        {

            // enqueue no found message, helping user see empty results
            VerboseQueue.Enqueue((
                "No subdirectories found in: " + CurrentLocation +
                " matching pattern: " + CurrentFileSearchMask
            ));
        }
    }
}