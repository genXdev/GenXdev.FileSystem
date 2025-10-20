// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Processing.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.302.2025
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



using Microsoft.PowerShell.Commands;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace GenXdev.FileSystem
{
    public partial class FindItem : PSGenXdevCmdlet
    {
        /// <summary>
        /// Processes search tasks until completion.
        /// </summary>
        protected void ProcessSearchTasks()
        {

            // add initial worker tasks if needed to start processing
            AddWorkerTasksIfNeeded(cts.Token);

            /*
             * main loop to consume outputs while workers are active or queues
             * have items.
             * this ensures all results are processed before completion.
             */

            // continue loop until cancellation or all workers done and output
            // queue empty
            while (!cts.Token.IsCancellationRequested && (
                   !AllWorkersCompleted() || !OutputQueue.IsEmpty ||
                   !DirQueue.IsEmpty || !VerboseQueue.IsEmpty ||
                   !FileContentMatchQueue.IsEmpty))
            {

                // yield cpu time to other threads

                // short sleep to avoid high cpu usage in tight loop
                Thread.Sleep(25);

                // process all queues to handle outputs and messages
                EmptyQueues();

                if (!cts.Token.IsCancellationRequested)
                {
                    // restart paused workers
                    AddWorkerTasksIfNeeded(cts.Token);
                }
            }

            EmptyQueues();
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
        ///
        /// The search logic handles:
        /// - Complex path patterns with wildcards
        /// - UNC and local paths differently
        /// - Directory-only or file-only searches
        /// - Pattern-based recursion
        /// </remarks>
        /// <param name="token">Cancellation token to support stopping the search
        /// operation</param>

        protected void DirectoryProcessor(CancellationToken token)
        {

            /*
             * process each directory from the queue until cancellation is requested
             * or queue is empty.
             * this loop enables parallel processing of multiple directories.
             */

            // loop while not canceled and dequeue succeeds
            // (FileContentMatchQueue.Count <= baseMemoryPerWorker / 256) &&
            while (!token.IsCancellationRequested)
            {
                lock (WorkersLock)
                {
                    // dynamic throttling: check at end of iteration if we should exit
                    var currentDirectoryProcessors = Interlocked.Read(ref directoryProcessors);
                    var maxDirectoryProcessors = maxDirectoryWorkersInParallel();
                    if (currentDirectoryProcessors > maxDirectoryProcessors)
                    {
                        if (UseVerboseOutput)
                        {
                            VerboseQueue.Enqueue($"Directory processor exiting: {currentDirectoryProcessors} > {maxDirectoryProcessors}");
                        }
                        break;
                    }
                    else
                    {
                        if (currentDirectoryProcessors < maxDirectoryProcessors)
                        {
                            AddWorkerTasksIfNeeded(token);
                        }
                    }
                }
                lock (UpwardsDirQueue)
                {
                    try
                    {
                        // if no more directories to process, but upwards dirs exist and
                        // no files found yet, start processing upwards dirs
                        if (DirQueue.Count == 0 && UpwardsDirQueue.Count > 0 && Interlocked.Read(ref filesFound) == 0)
                        {
                            // get the upwards dir with the lowest depth value
                            var firstKey = (from q in UpwardsDirQueue.Keys
                                            orderby UpwardsDirQueue[q]
                                            select q).FirstOrDefault();

                            // build path by prepending ..\ for each depth level
                            var value = UpwardsDirQueue[firstKey] + 1;
                            var path = CurrentDirectory;

                            // we don't want to find the current directory
                            if (value == 1) VisitedNodes.TryAdd(CurrentDirectory, true);

                            // create the necessary upwards directory traversals
                            for (int i = 0; i < value; i++)
                            {
                                path += "\\..";
                            }

                            // get rid of excess ..\ if already at root
                            path = System.IO.Path.GetFullPath(path);

                            // enqueue search
                            InitializeSearchDirectory(path + "\\" + firstKey, false);

                            // remove from upwards queue if max depth reached or at root
                            if (value == MaxSearchUpDepth || path.Length == 3)
                            {
                                if (UseVerboseOutput)
                                {
                                    VerboseQueue.Enqueue("Adding last upwards search directory for '" + firstKey + "' -> " + path);
                                }

                                UpwardsDirQueue.TryRemove(firstKey, out int _);
                            }
                            else
                            {
                                if (UseVerboseOutput)
                                {
                                    VerboseQueue.Enqueue("Adding upwards (" + value + "/" + MaxSearchUpDepth + ") search directory for '" + firstKey + "' -> " + path);
                                }

                                UpwardsDirQueue[firstKey] = value;
                            }
                        }
                    }
                    catch (Exception e)
                    {
                        // log unexpected error if verbose, providing full details for
                        // debugging unexpected issues
                        if (UseVerboseOutput)
                        {
                            // enqueue verbose message with path, message, and stack
                            VerboseQueue.Enqueue((
                                "Unexpected error in directory processor " +
                                ": \r\n" + e.Message +
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
                    }
                }

                if (DirQueue.TryDequeue(out string name))
                {
                    try
                    {
                        // log processing directory if verbose mode enabled, providing
                        // details on current path for user to track search progress
                        if (UseVerboseOutput)
                        {
                            // enqueue verbose message with path details
                            VerboseQueue.Enqueue((
                                "Processing directory: " + name
                            ));
                        }

                        // try processing the directory
                        try
                        {

                            // declare workload variables
                            string remainingNameInput, remainingNameToRepeatWhenFound,
                                currentLocation, currentFileName,
                                uncMachineNameToEnumerate;

                            // more workload variables
                            bool isUncPath, hasLongPathPrefix, recurseSubDirectories,
                                noMoreCustomWildcards, shouldEnumerateFiles,
                                shouldEnumerateDirectories;

                            // depth variables
                            int currentRecursionDepth, currentRecursionLimit;

                            // get parameters for current workload
                            GetCurrentWorkloadParameters(

                                name,

                                out currentRecursionDepth,
                                out currentRecursionLimit,
                                out recurseSubDirectories,
                                out shouldEnumerateFiles,
                                out shouldEnumerateDirectories,
                                out isUncPath,
                                out noMoreCustomWildcards,
                                out hasLongPathPrefix,
                                out remainingNameInput,
                                out remainingNameToRepeatWhenFound,
                                out currentLocation,
                                out currentFileName,
                                out uncMachineNameToEnumerate
                            );

                            // check if this location + name has already been visited
                            if (LocationAreadyVisited(currentLocation,
                                currentFileName, token))
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
                                EnumerateDirectoryFiles(

                                    currentLocation,
                                    currentFileName,
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
                                    currentFileName,
                                    remainingNameInput,
                                    remainingNameToRepeatWhenFound,
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
                                    name + ": " + e.Message
                                ));
                            }
                        }
                        catch (IOException e)
                        {

                            // log io error if verbose, informing user of file system
                            // issues encountered
                            if (UseVerboseOutput)
                            {

                                // enqueue verbose message with path and error
                                VerboseQueue.Enqueue((
                                    "I/O error for path " + name +
                                    ": " + e.Message
                                ));
                            }
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
                                    name + ": \r\n" + e.Message +
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
                        }
                    }
                    finally
                    {
                        // increment count of unqueued directories
                        Interlocked.Increment(ref dirsCompleted);
                    }
                }
                else break;
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
        /// <param name="RemainingNamePart">Outputs the remaining search
        /// mask.</param>
        /// <param name="RemainingNameToRepeatWhenFound">Outputs the repeat
        /// mask when found.</param>
        /// <param name="CurrentLocation">Outputs the current location.</param>
        /// <param name="CurrentFileName">Outputs the current file search
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
            out string RemainingNamePart,
            out string remainingNameToRepeatWhenFound,
            out string CurrentLocation,
            out string CurrentFileName,
            out string UncMachineNameToEnumerate
        )
        {

            // split the input into location and remaining namePart for
            // processing

            // handle long path prefixes and tilde expansion
            EnsureFullProvidedLocationAndNamePart(

                ref ProvidedLocation,

                out HasLongPathPrefix,
                out IsUncPath,
                out UncMachineNameToEnumerate
            );

            // separate the fixed path prefix from the wildcard-containing parts

            // advance to the next search location based on wildcards in the path

            // this sets up the current location and file namePart for
            // enumeration
            AdvanceNamePartToNextSearchLocation(
                ProvidedLocation,

                IsUncPath,
                out RecurseSubDirectories,
                out NoMoreCustomWildcards,
                out RemainingNamePart,
                out remainingNameToRepeatWhenFound,
                out CurrentLocation,
                out CurrentFileName
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
                (RemainingNamePart.IndexOf("\\") < 0) && (
                    FilesAndDirectories.ToBool() ||
                    !Directory.ToBool()
                );

            // set if should enumerate directories
            ShouldEnumerateDirectories = CurrentFileName.IndexOf(':') < 0 && (
                enumUncShares || RecurseSubDirectories || Directory.ToBool() ||
                FilesAndDirectories.ToBool()
            );

            // get full path for current location
            CurrentLocation = Path.GetFullPath(CurrentLocation);

            // adjust repeat mask if ends with *
            if (RemainingNamePart.EndsWith('*') &&
                !remainingNameToRepeatWhenFound.EndsWith("*"))
            {

                // append *
                remainingNameToRepeatWhenFound += "*";
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
                    "RemainingNamePart: '" + RemainingNamePart + "'\r\n" +
                    "remainingNameToRepeatWhenFound: '" +
                    remainingNameToRepeatWhenFound + "'\r\n" +
                    "CurrentLocation: '" + CurrentLocation + "'\r\n" +
                    "CurrentFileName: '" + CurrentFileName + "'\r\n" +
                    "CurrentRecursionDepth: '" + CurrentRecursionDepth + "'\r\n" +
                    "CurrentRecursionLimit: '" + CurrentRecursionLimit + "'\t\n" +
                    "ShouldEnumerateFiles : '" + ShouldEnumerateFiles + "'\r\n" +
                    "ShouldEnumerateDirectories: '" +
                    ShouldEnumerateDirectories + "'\r\n---\r\n"
                ));
            }
        }

        /// <summary>
        /// Empties all queues and handles output.
        /// </summary>
        private void EmptyQueues()
        {
            // process verbose queue for messages

            bool hadOutput = false;

            // dequeue and write verbose messages
            while (VerboseQueue.TryDequeue(out string msg))
            {
                hadOutput = true;

                WriteVerbose(msg);
            }

            // dequeue and write output
            while (OutputQueue.TryDequeue(out object result))
            {
                hadOutput = true;

                WriteObject(result);
            }

            AddWorkerTasksIfNeeded(cts.Token);

            // check all progress items in queue
            UpdateProgressStatus(true);
        }

        /// <summary>
        /// Ensures full provided location and name, handling prefixes and
        /// expansions.
        /// </summary>
        /// <param name="ProvidedLocation">The provided location, passed by
        /// reference.</param>
        /// <param name="HasLongPathPrefix">Outputs if has long path
        /// prefix.</param>
        /// <param name="IsUncPath">Outputs if it's a UNC path.</param>
        /// <param name="UncMachineNameToEnumerate">Outputs the UNC machine name
        /// to enumerate.</param>
        protected void EnsureFullProvidedLocationAndNamePart(

            ref string ProvidedLocation,

            out bool HasLongPathPrefix,
            out bool IsUncPath,
            out string UncMachineNameToEnumerate
        )
        {

            // normalize separators
            // Normalize separators to backslashes for consistency
            ProvidedLocation = ProvidedLocation.Replace("/", "\\");

            // normalize path
            // Normalize the path part for processing
            // var normPath = NormalizePathForNonFileSystemUse(ProvidedLocation);

            // adjust trailing recurse
            // Adjust for trailing recursive patterns
            if (RecurseEndPatternWithSlashAtStartMatcher.IsMatch(ProvidedLocation))
            {
                ProvidedLocation += "\\";
            }

            // Remove leading .\ for clean path
            if (ProvidedLocation.StartsWith(".\\"))
            {
                ProvidedLocation = ProvidedLocation.Substring(2);
            }

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

            // detect type and needs
            bool endsWithSeperator = ProvidedLocation.EndsWith("\\");
            bool isRooted = Path.IsPathRooted(ProvidedLocation);
            bool isRelative = !isRooted && !IsUncPath;
            bool needsCurrentDir = !IsUncPath && isRooted && (ProvidedLocation.Length < 3 || ProvidedLocation[2] != '\\');

            // handle relative
            if (isRelative)
            {

                // combine with current
                // Combine with current directory for relative paths
                ProvidedLocation = Path.Combine(CurrentDirectory, ProvidedLocation);
            }
            else if (needsCurrentDir)
            {

                // get drive current path
                // Get current path for the drive
                var currentPath = InvokeScript<string>($@"(Microsoft.PowerShell.Management\Get-Location -PSDrive {ProvidedLocation.Substring(0, 1)}).Path");

                // combine
                ProvidedLocation = Path.Combine(currentPath, ProvidedLocation.Substring(2));
            }

            // add separator if needed
            if (endsWithSeperator && !ProvidedLocation.EndsWith("\\"))
            {
                ProvidedLocation += "\\";
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
                    ProvidedLocation = @"\\" + Environment.MachineName + @"\>";
                }
                else
                {

                    // find first slash
                    int firstSlash = ProvidedLocation.IndexOf('\\', 2);

                    // append \ if no slash
                    if (firstSlash < 0)
                    {

                        // add trailing
                        ProvidedLocation += @"\>";
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
        /// <param name="RemainingNamePart">Remaining namePart by
        /// ref.</param>
        /// <param name="CurrentFileName">Current filename by
        /// ref.</param>
        /// <returns>Whether it was a recurse pattern.</returns>
        bool DetermineAndStripRecursePattern(

            ref string RemainingNamePart,
            ref string CurrentFileName
        )
        {
            // check if recurse pattern
            bool result = RecursePatternMatcher.IsMatch(CurrentFileName);

            // init recurse flag
            bool isRecursePattern = result;

            // loop while recurse
            while (isRecursePattern)
            {

                // find first slash
                int firstSlash = RemainingNamePart.IndexOf('\\');

                // handle if slash and mask not empty
                if (!string.IsNullOrEmpty(CurrentFileName) &&
                    firstSlash >= 0)
                {

                    // set current mask
                    CurrentFileName = RemainingNamePart.Substring(0,
                        firstSlash);

                    // update remaining
                    RemainingNamePart = RemainingNamePart.Substring(
                        firstSlash + 1
                    );
                }
                else
                {

                    // set current to remaining
                    CurrentFileName = RemainingNamePart;

                    // clear remaining
                    RemainingNamePart = string.Empty;
                }

                // check again
                isRecursePattern = RecursePatternMatcher.IsMatch(
                    CurrentFileName
                );
            }

            // return result
            return result;
        }

        /// <summary>
        /// Advances namePart to next search location.
        /// </summary>
        /// <param name="ProvidedLocation">Provided location.</param>
        /// <param name="IsUncPath">If UNC path.</param>
        /// <param name="RecurseSubDirectories">Outputs recurse
        /// subdirectories.</param>
        /// <param name="NoMoreCustomWildcards">Outputs no more custom
        /// wildcards.</param>
        /// <param name="RemainingNamePart">Outputs remaining search
        /// mask.</param>
        /// <param name="RemainingNameToRepeatWhenFound">Outputs repeat mask
        /// when found.</param>
        /// <param name="CurrentLocation">Outputs current location.</param>
        /// <param name="CurrentFileName">Outputs current file search
        /// mask.</param>
        protected void AdvanceNamePartToNextSearchLocation(

            string ProvidedLocation,
            bool IsUncPath,

            out bool RecurseSubDirectories,
            out bool NoMoreCustomWildcards,

            out string RemainingNamePart,
            out string RemainingNameToRepeatWhenFound,
            out string CurrentLocation,
            out string CurrentFileName
        )
        {
            // determine remaining mask
            DetermineRemainingNamePart(
                ProvidedLocation,
                IsUncPath,

                out RemainingNamePart,
                out CurrentLocation
            );

            // determine current mask
            DetermineCurrentNamePart(

                ref RemainingNamePart,
                out RemainingNameToRepeatWhenFound,

                out RecurseSubDirectories,
                out NoMoreCustomWildcards,
                out CurrentFileName
            );
        }

        /// <summary>
        /// Determines remaining namePart.
        /// </summary>
        /// <param name="ProvidedLocation">Provided location.</param>
        /// <param name="IsUncPath">If UNC path.</param>
        /// <param name="RemainingNamePart">Outputs remaining search
        /// mask.</param>
        /// <param name="CurrentLocation">Outputs current location.</param>
        protected void DetermineRemainingNamePart(

           string ProvidedLocation,
           bool IsUncPath,

           out string RemainingNamePart,
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
            RemainingNamePart = string.Empty;

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
            RemainingNamePart = string.Join('\\',
                remainingDeterminedParts.Skip(iSkipped).ToList<string>()
            );
        }

        /// <summary>
        /// Determines current namePart.
        /// </summary>
        /// <param name="RemainingNamePart">Remaining namePart by
        /// ref.</param>
        /// <param name="RemainingNameToRepeatWhenFound">Outputs repeat mask
        /// when found.</param>
        /// <param name="RecurseSubDirectories">Outputs recurse
        /// subdirectories.</param>
        /// <param name="NoMoreCustomWildcards">Outputs no more custom
        /// wildcards.</param>
        /// <param name="CurrentFileName">Outputs current file search
        /// mask.</param>
        protected void DetermineCurrentNamePart(

            ref string RemainingNamePart,
            out string RemainingNameToRepeatWhenFound,

            out bool RecurseSubDirectories,
            out bool NoMoreCustomWildcards,
            out string CurrentFileName)
        {
            // init recurse pattern flag
            bool wasRecursePattern = false;

            // set no more wildcards
            NoMoreCustomWildcards = true;
            bool moreCustomWildcards = false;

            // default current mask
            CurrentFileName = "*";

            // set recurse based on switch
            RecurseSubDirectories = !(NoRecurse.ToBool());

            // set repeat to remaining
            RemainingNameToRepeatWhenFound = RemainingNamePart;

            // extract the pattern for the current directory level

            // find first slash
            int firstSlash = RemainingNamePart.IndexOf('\\');

            // handle if slash found
            if (firstSlash >= 0)
            {
                // set current mask
                CurrentFileName = RemainingNamePart.Substring(0,
                    firstSlash);

                // update remaining
                RemainingNamePart = RemainingNamePart.Substring(
                    firstSlash + 1
                );

                // strip recurse
                wasRecursePattern = DetermineAndStripRecursePattern(

                    ref RemainingNamePart,
                    ref CurrentFileName
                );

                // find next slash
                firstSlash = RemainingNamePart.IndexOf('\\');

                // set repeat
                RemainingNameToRepeatWhenFound = RemainingNamePart;

                // check no more wildcards
                NoMoreCustomWildcards = RemainingNamePart == string.Empty ||
                    RemainingNamePart == "*";

                // more wildcards flag
                moreCustomWildcards = !NoMoreCustomWildcards;

                // update recurse
                RecurseSubDirectories |= wasRecursePattern | moreCustomWildcards;

                // build repeated
                var repeatedMask = string.IsNullOrEmpty(RemainingNamePart) ?
                            CurrentFileName :
                            (CurrentFileName + "\\" + RemainingNamePart);

                // handle recurse pattern
                if (wasRecursePattern)
                {

                    // prepend **
                    RemainingNamePart = "**\\" + repeatedMask;
                }
                else
                {
                    // set if recurse
                    if (RecurseSubDirectories)
                    {

                        // set to repeated
                        RemainingNamePart = repeatedMask;
                    }
                }

                // found slash
                return;
            }

            // done?
            if (string.IsNullOrEmpty(RemainingNamePart))
            {
                return;
            }

            // check recurse
            wasRecursePattern = RecursePatternMatcher.IsMatch(
                RemainingNamePart
            );

            // update recurse
            RecurseSubDirectories |= wasRecursePattern;

            // check no more
            NoMoreCustomWildcards = RemainingNamePart == string.Empty ||
                RemainingNamePart == "*";
            moreCustomWildcards = !NoMoreCustomWildcards;

            // set current
            CurrentFileName = RemainingNamePart;

            // set remaining based on recurse
            RemainingNamePart = wasRecursePattern ? "**" :
                CurrentFileName;

            // set repeat
            RemainingNameToRepeatWhenFound = CurrentFileName;
        }

        /// <summary>
        /// Checks if currentlocation + name already visited.
        /// </summary>
        /// <param name="CurrentLocation">Current location.</param>
        /// <param name="CurrentFileName">Current filename.</param>
        /// <param name="token">Cancellation token.</param>
        /// <returns>If already visited.</returns>
        private bool LocationAreadyVisited(
            string CurrentLocation,
            string CurrentFileName,
            CancellationToken token)
        {

            // try add to visited
            if (!VisitedNodes.TryAdd(Path.Combine(CurrentLocation,
                CurrentFileName), true))
            {
                // log skip if verbose
                if (UseVerboseOutput)
                {

                    // enqueue skip
                    VerboseQueue.Enqueue((
                        "Skipping already processed path: " + CurrentLocation +
                        " with pattern " + CurrentFileName
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

        /// <summary>
        /// Enumerates directory files.
        /// </summary>
        /// <param name="StartLocation">Start location.</param>
        /// <param name="CurrentFileName">Current filename.</param>
        /// <param name="HasLongPathPrefix">Has long path prefix.</param>
        /// <param name="NoMoreCustomWildcards">No more custom wildcards.</param>
        /// <param name="IsUncPath">Is UNC path.</param>
        /// <param name="token">Cancellation token.</param>
        protected void EnumerateDirectoryFiles(

            string StartLocation,
            string CurrentFileName,
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
                    MatchCasing = CaseNameMatching,

                    // set buffer
                    BufferSize = 163840,

                    // set skip attributes
                    AttributesToSkip = AttributesToSkip
                };

            // skip reparse if not follow
            if (!FollowSymlinkAndJunctions.ToBool())
            {

                // set skip
                options.AttributesToSkip = FileAttributes.ReparsePoint;
            }

            // find stream index
            int idp = CurrentFileName.IndexOf(':');

            // set has stream
            bool hasStreamPattern = idp >= 0;

            // init stream name
            string streamName = null;

            // handle stream pattern
            if (hasStreamPattern)
            {

                // get stream name
                streamName = CurrentFileName.Substring(idp + 1);

                // default *
                if (streamName == string.Empty) streamName = "*";

                // update mask
                CurrentFileName = CurrentFileName.Substring(0, idp);
            }

            // create matcher
            var patternMatcher = new WildcardPattern(
                EscapeBracketsInPattern(CurrentFileName),
                CurrentWildCardOptions);

            // enumerate files in top directory only

            // loop files
            foreach (var filePath in System.IO.Directory.EnumerateFiles(
                (
                IsUncPath ?
                    ("\\\\?\\UNC" + StartLocation.Substring(1)) :
                    ("\\\\?\\" + StartLocation)
                ),
                CurrentFileName,
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
                            CurrentFileName
                        ));
                    }

                    // skip
                    continue;
                }

                haveExclusion = ShouldFileBeExcluded(fileInfo);

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
                    if (matchingFileContent)
                    {

                        // check if content search should be performed based on
                        // switches and extension

                        // if include or not skip ext
                        if (IncludeNonTextFileMatching ||
                            !ExtensionsToSkip.Contains(
                                Path.GetExtension(normalizedFilePath)
                            ))
                        {
                            FileContentMatchQueue.Enqueue(fileInfo);
                            Interlocked.Increment(ref matchesQueued);
                            AddWorkerTasksIfNeeded(token);
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
                        AddToOutputQueue(new FileInfo(normalizedFilePath));
                    }
                }

                // process alternate data streams if the switch is set

                // if include or only ads
                if (IncludeAlternateFileStreams.ToBool() || onlyAds)
                {

                    // get streams
                    GetFileAlternateFileStreams(normalizedFilePath,
                        cts!.Token, streamName);
                }
            }
        }

        private bool ShouldFileBeExcluded(FileInfo fileInfo)
        {
            bool haveExclusion = false;

            // check size constraints
            if ((MaxFileSize > 0 && fileInfo.Length > MaxFileSize) ||
                (MinFileSize > 0 && fileInfo.Length < MinFileSize))
            {

                // log skip size if verbose
                if (UseVerboseOutput)
                {
                    // enqueue skip size
                    VerboseQueue.Enqueue((
                        "Skipping file " + fileInfo.FullName +
                        " due to size constraints. Size: " +
                        fileInfo.Length + " bytes"
                    ));
                }

                // skip
                haveExclusion = true;
            }

            // check mod dates
            if (!haveExclusion && (ModifiedAfter.HasValue &&
                fileInfo.LastWriteTimeUtc < ModifiedAfter.Value) ||
                (ModifiedBefore.HasValue &&
                fileInfo.LastWriteTimeUtc > ModifiedBefore.Value))
            {

                // log skip date if verbose
                if (UseVerboseOutput)
                {

                    // enqueue skip date
                    VerboseQueue.Enqueue((
                        "Skipping file " + fileInfo.FullName +
                        " due to modification date constraints. " +
                        "LastWriteTimeUtc: " + fileInfo.LastWriteTimeUtc
                    ));
                }

                // skip
                haveExclusion = true;
            }

            // check exclude patterns
            if (!haveExclusion)
                foreach (var pattern in FileExcludePatterns)
                {

                    // if match
                    if (pattern.IsMatch(WildcardPattern.Escape(fileInfo.FullName)))
                    {

                        // set exclusion
                        haveExclusion = true;

                        // log exclude if verbose
                        if (UseVerboseOutput)
                        {

                            // enqueue exclude
                            VerboseQueue.Enqueue((
                                "Excluding file " + fileInfo.FullName +
                                " due to pattern " + pattern
                            ));
                        }

                        // break
                        break;
                    }
                }

            // check file categories
            if (!haveExclusion && Category != null && Category.Length > 0)
            {
                haveExclusion = true;
                var extension = Path.GetExtension(fileInfo.FullName);

                foreach (var pattern in Category)
                {
                    if (FileGroups.Groups.TryGetValue(pattern, out var group))
                    {
                        if (group.Contains(extension))
                        {

                            if (UseVerboseOutput)
                            {
                                // enqueue exclude
                                VerboseQueue.Enqueue((
                                    "Including file " + fileInfo.FullName +
                                    " for being member of: " + pattern
                                ));

                            }

                            haveExclusion = false;
                            break;
                        }
                    }
                }
            }

            return haveExclusion;
        }

        /// <summary>
        /// Gets file alternate data streams.
        /// </summary>
        /// <param name="FilePath">File path.</param>
        /// <param name="token">Cancellation token.</param>
        /// <param name="StreamName">Stream name optional.</param>
        protected void GetFileAlternateFileStreams(string FilePath,
            CancellationToken token, string StreamName = null)
        {

            // create pattern if name
            WildcardPattern wildcardPattern = string.IsNullOrEmpty(StreamName) ?
                null :
              new WildcardPattern(
                  EscapeBracketsInPattern(StreamName),
                  CurrentWildCardOptions
            );

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
                                    ':');

                                // find data index
                                int dataIdx = streamName.IndexOf(
                                    ":$DATA", StringComparison.OrdinalIgnoreCase
                                );

                                // substring if found
                                if (dataIdx > 0)
                                    streamName = streamName.Substring(0, dataIdx);

                                // skip if no match
                                if (wildcardPattern != null &&
                                    !wildcardPattern.IsMatch(WildcardPattern.Escape(streamName)))
                                {
                                    continue;
                                }

                                // if not empty
                                if (!string.IsNullOrEmpty(streamName))
                                {

                                    // build ads path
                                    var adsPath = $"{FilePath}:{streamName}";

                                    // if have pattern and search ads
                                    if (matchingFileContent && SearchADSContent.ToBool())
                                    {

                                        // perform content search in ads if enabled

                                        // if include or not skip
                                        if (IncludeNonTextFileMatching ||
                                            !ExtensionsToSkip.Contains(
                                                Path.GetExtension(streamName)
                                            ))
                                        {
                                            FileContentMatchQueue.Enqueue(new FileInfo(adsPath));
                                            Interlocked.Increment(ref matchesQueued);
                                            AddWorkerTasksIfNeeded(token);
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
                                    AddToOutputQueue(new FileInfo(adsPath));
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
            }

            // check cancel
            token.ThrowIfCancellationRequested();
        }

        /// <summary>
        /// Processes file content for pattern matching.
        /// </summary>
        /// <param name="fileInfo">File path to process.</param>
        /// <param name="token">Cancellation token.</param>
        protected async Task FileContentProcessor(
            FileInfo fileInfo,
            CancellationToken token)
        {

            // early exit if cancellation requested
            if (token.IsCancellationRequested) return;

            bool found = false;
            MatchContentProcessor selectString = null;

            try
            {
                // update counter
                Interlocked.Increment(ref fileMatchesActive);
                Interlocked.Increment(ref fileMatchesStarted);

                if (!MatchContentProcessors.TryDequeue(out selectString))
                {
                    selectString = new MatchContentProcessor(
                            (int)baseMemoryPerWorker,
                            Content,
                            SimpleMatch.ToBool(),
                            AllMatches.ToBool(),
                            NotMatch.ToBool(),
                            CaseSensitive.ToBool(),
                            Encoding,
                            List.ToBool(),
                            Context,
                            Culture,
                            Quiet.ToBool(),
                            NoEmphasis.ToBool(),
                            token
                        );
                }

                await foreach (MatchInfo result in selectString.SearchAsync(fileInfo))
                {
                    found = true;

                    if (!Quiet.ToBool())
                    {
                        AddToOutputQueue(result);
                    }
                    else
                    {
                        break;
                    }
                }
            }
            catch (Exception e)
            {
                // log failure if verbose
                VerboseQueue.Enqueue((
                    "Failed to read file: " + fileInfo + "\r\n Error: " + e.Message + "\r\n" + e.TargetSite + "\r\n" + e.StackTrace + "\r\nSource:" + e.Source)
                );

                return;
            }
            finally
            {
                // update counter
                Interlocked.Decrement(ref fileMatchesActive);
                Interlocked.Increment(ref fileMatchesCompleted);

                if (selectString != null)
                {
                    MatchContentProcessors.Enqueue(selectString);
                }
            }

            if (!found || (NoLinks.ToBool() && !Quiet.ToBool())) return;

            // log match if verbose
            if (UseVerboseOutput)
            {
                // enqueue output
                VerboseQueue.Enqueue((
                    "Outputting file with pattern match: " + fileInfo
                ));
            }

            // enqueue output
            AddToOutputQueue(fileInfo);
        }

        /// <summary>
        /// Enumerates subdirectories matching patterns.
        /// </summary>
        /// <param name="CurrentLocation">Location.</param>
        /// <param name="CurrentFileName">File mask.</param>
        /// <param name="RemainingNamePart">Remaining mask.</param>
        /// <param name="RemainingNameToRepeatWhenFound">Repeat mask.</param>
        /// <param name="uncMachineNameToEnumerate">UNC machine.</param>
        /// <param name="RecurseSubDirectories">Recurse.</param>
        /// <param name="NoMoreCustomWildcards">No wild.</param>
        /// <param name="HasLongPathPrefix">Long prefix.</param>
        /// <param name="IsUncPath">UNC.</param>
        /// <param name="token">Token.</param>
        void EnumerateSubDirectories(
        string CurrentLocation,
        string CurrentFileName,
        string RemainingNamePart,
        string RemainingNameToRepeatWhenFound,
        string uncMachineNameToEnumerate,
        bool RecurseSubDirectories,
        bool NoMoreCustomWildcards,
        bool HasLongPathPrefix,
        bool IsUncPath,
        CancellationToken token
        )
        {
            // adjust wildcards flag based on mask
            NoMoreCustomWildcards &= CurrentFileName == "*";

            // init found flag for subdirs
            var found = false;

            // create wildcard pattern matcher
            var patternMatcher = new WildcardPattern(
                EscapeBracketsInPattern(CurrentFileName),
                CurrentWildCardOptions);

            // set remaining full mask
            var remainingFull = RemainingNamePart;

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
                RemainingNamePart);

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
            var patternMatcherFull = new WildcardPattern(
                EscapeBracketsInPattern(fullPattern),
                CurrentWildCardOptions);

            // create matcher for recursive full
            var patternMatcherFullRecurse = new WildcardPattern(
                EscapeBracketsInPattern(fullPatternRecurse),
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
                var uncShareMatcher = new WildcardPattern(
                    EscapeBracketsInPattern(shareName),
                    CurrentWildCardOptions);

                // list disk shares on unc machine
                var shares = ListDiskSharesUNC(uncMachineNameToEnumerate);

                // get remaining parts after skipping unc prefix
                var partsLeft = string.Join('\\', Path.Combine(CurrentLocation,
                    RemainingNamePart).Split('\\').Skip<string>(4).ToArray());

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
                    AddWorkerTasksIfNeeded(token);
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
                        MatchCasing = CaseNameMatching
                    };

                // skip reparse points if not following symlinks
                if (!FollowSymlinkAndJunctions.ToBool())
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
                            RemainingNameToRepeatWhenFound :
                            RemainingNamePart);

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

                        DirQueue.Enqueue(Path.Combine(normalizedSubDir, remaining));

                        Interlocked.Increment(ref dirsQueued);

                        AddWorkerTasksIfNeeded(token);
                    }
                    else
                    {
                        // log queueing subdir if verbose, showing remaining parts
                        if (UseVerboseOutput)
                        {

                            // enqueue queueing message
                            VerboseQueue.Enqueue((
                                "Skipping subdirectory for processing: " +
                                normalizedSubDir + " with remaining parts: " +
                                RemainingNamePart
                            ));
                        }
                    }

                    // check full pattern match
                    bool isMatch1 = patternMatcherFull.IsMatch(normalizedSubDir);

                    // check recursive full match
                    bool isMatch2 = patternMatcherFullRecurse.IsMatch(
                        normalizedSubDir);

                    // combine match results
                    isMatch = isMatch1 || isMatch2;

                    // output if searching directories or both
                    if ((Directory.ToBool() || FilesAndDirectories.ToBool()) &&
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
                        AddToOutputQueue(new DirectoryInfo(normalizedSubDir));
                    }
                }
            }

            // log no subdirs found if verbose and none found
            if (!found && UseVerboseOutput)
            {

                // enqueue no found message, helping user see empty results
                VerboseQueue.Enqueue((
                    "No subdirectories found in: " + CurrentLocation +
                    " matching pattern: " + CurrentFileName
                ));
            }
        }
    }
}