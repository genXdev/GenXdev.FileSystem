// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : PSGenXdevCmdlet.FindItem.cs
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



using System.Collections;
using System.Collections.Concurrent;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;

public abstract partial class PSGenXdevCmdlet : PSCmdlet
{
    /// <summary>
    /// Fast multi-threaded file and directory search with optional text content pattern matching
    /// </summary>
    protected object[] FindItem(
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool directory = false,
        bool filesAndDirectories = false,
        bool passThru = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        bool noLinks = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool allMatches = false,
        bool caseSensitive = false,
        int[] context = null,
        string culture = null,
        string encoding = null,
        bool list = false,
        bool noEmphasis = false,
        bool notMatch = false,
        bool quiet = false,
        bool raw = false,
        bool simpleMatch = false)
    {
        var scriptBuilder = new System.Text.StringBuilder();
        scriptBuilder.Append("param(");

        // Define all parameters
        var paramNames = new[] {
            "Name", "Input", "Content", "RelativeBasePath", "Category", "MaxDegreeOfParallelism", "TimeoutSeconds",
            "AllDrives", "Directory", "FilesAndDirectories", "PassThru", "IncludeAlternateFileStreams", "NoRecurse",
            "FollowSymlinkAndJunctions", "IncludeOpticalDiskDrives", "SearchDrives", "DriveLetter", "Root",
            "IncludeNonTextFileMatching", "NoLinks", "CaseNameMatching", "SearchADSContent", "MaxRecursionDepth",
            "MaxSearchUpDepth", "MaxFileSize", "MinFileSize", "ModifiedAfter", "ModifiedBefore", "AttributesToSkip",
            "Exclude", "AllMatches", "CaseSensitive", "Context", "Culture", "Encoding", "List", "NoEmphasis",
            "NotMatch", "Quiet", "Raw", "SimpleMatch"
        };

        scriptBuilder.Append(string.Join(", ", paramNames.Select(p => "$" + p)));
        scriptBuilder.Append(") GenXdev.FileSystem\\Find-Item");

        // Add parameters conditionally
        if (name != null && name.Length > 0)
        {
            scriptBuilder.Append(" -Name $Name");
        }

        if (input != null)
        {
            scriptBuilder.Append(" -Input $Input");
        }

        if (content != null && content.Length > 0)
        {
            scriptBuilder.Append(" -Content $Content");
        }

        if (!string.IsNullOrEmpty(relativeBasePath))
        {
            scriptBuilder.Append(" -RelativeBasePath $RelativeBasePath");
        }

        if (category != null && category.Length > 0)
        {
            scriptBuilder.Append(" -Category $Category");
        }

        if (maxDegreeOfParallelism != 0)
        {
            scriptBuilder.Append(" -MaxDegreeOfParallelism $MaxDegreeOfParallelism");
        }

        if (timeoutSeconds.HasValue)
        {
            scriptBuilder.Append(" -TimeoutSeconds $TimeoutSeconds");
        }

        if (allDrives)
        {
            scriptBuilder.Append(" -AllDrives");
        }

        if (directory)
        {
            scriptBuilder.Append(" -Directory");
        }

        if (filesAndDirectories)
        {
            scriptBuilder.Append(" -FilesAndDirectories");
        }

        if (passThru)
        {
            scriptBuilder.Append(" -PassThru");
        }

        if (includeAlternateFileStreams)
        {
            scriptBuilder.Append(" -IncludeAlternateFileStreams");
        }

        if (noRecurse)
        {
            scriptBuilder.Append(" -NoRecurse");
        }

        if (followSymlinkAndJunctions)
        {
            scriptBuilder.Append(" -FollowSymlinkAndJunctions");
        }

        if (includeOpticalDiskDrives)
        {
            scriptBuilder.Append(" -IncludeOpticalDiskDrives");
        }

        if (searchDrives != null && searchDrives.Length > 0)
        {
            scriptBuilder.Append(" -SearchDrives $SearchDrives");
        }

        if (driveLetter != null && driveLetter.Length > 0)
        {
            scriptBuilder.Append(" -DriveLetter $DriveLetter");
        }

        if (root != null && root.Length > 0)
        {
            scriptBuilder.Append(" -Root $Root");
        }

        if (includeNonTextFileMatching)
        {
            scriptBuilder.Append(" -IncludeNonTextFileMatching");
        }

        if (noLinks)
        {
            scriptBuilder.Append(" -NoLinks");
        }

        if (caseNameMatching != System.IO.MatchCasing.PlatformDefault)
        {
            scriptBuilder.Append(" -CaseNameMatching $CaseNameMatching");
        }

        if (searchADSContent)
        {
            scriptBuilder.Append(" -SearchADSContent");
        }

        if (maxRecursionDepth != 0)
        {
            scriptBuilder.Append(" -MaxRecursionDepth $MaxRecursionDepth");
        }

        if (maxSearchUpDepth != 0)
        {
            scriptBuilder.Append(" -MaxSearchUpDepth $MaxSearchUpDepth");
        }

        if (maxFileSize != 0)
        {
            scriptBuilder.Append(" -MaxFileSize $MaxFileSize");
        }

        if (minFileSize != 0)
        {
            scriptBuilder.Append(" -MinFileSize $MinFileSize");
        }

        if (modifiedAfter.HasValue)
        {
            scriptBuilder.Append(" -ModifiedAfter $ModifiedAfter");
        }

        if (modifiedBefore.HasValue)
        {
            scriptBuilder.Append(" -ModifiedBefore $ModifiedBefore");
        }

        if (attributesToSkip != System.IO.FileAttributes.System)
        {
            scriptBuilder.Append(" -AttributesToSkip $AttributesToSkip");
        }

        if (exclude != null)
        {
            scriptBuilder.Append(" -Exclude $Exclude");
        }

        if (allMatches)
        {
            scriptBuilder.Append(" -AllMatches");
        }

        if (caseSensitive)
        {
            scriptBuilder.Append(" -CaseSensitive");
        }

        if (context != null && context.Length > 0)
        {
            scriptBuilder.Append(" -Context $Context");
        }

        if (!string.IsNullOrEmpty(culture))
        {
            scriptBuilder.Append(" -Culture $Culture");
        }

        if (!string.IsNullOrEmpty(encoding))
        {
            scriptBuilder.Append(" -Encoding $Encoding");
        }

        if (list)
        {
            scriptBuilder.Append(" -List");
        }

        if (noEmphasis)
        {
            scriptBuilder.Append(" -NoEmphasis");
        }

        if (notMatch)
        {
            scriptBuilder.Append(" -NotMatch");
        }

        if (quiet)
        {
            scriptBuilder.Append(" -Quiet");
        }

        if (raw)
        {
            scriptBuilder.Append(" -Raw");
        }

        if (simpleMatch)
        {
            scriptBuilder.Append(" -SimpleMatch");
        }

        var findItemScript = ScriptBlock.Create(scriptBuilder.ToString());

        var result = findItemScript.Invoke(
            name,
            input,
            content,
            relativeBasePath,
            category,
            maxDegreeOfParallelism,
            timeoutSeconds,
            allDrives,
            directory,
            filesAndDirectories,
            passThru,
            includeAlternateFileStreams,
            noRecurse,
            followSymlinkAndJunctions,
            includeOpticalDiskDrives,
            searchDrives,
            driveLetter,
            root,
            includeNonTextFileMatching,
            noLinks,
            caseNameMatching,
            searchADSContent,
            maxRecursionDepth,
            maxSearchUpDepth,
            maxFileSize,
            minFileSize,
            modifiedAfter,
            modifiedBefore,
            attributesToSkip,
            exclude,
            allMatches,
            caseSensitive,
            context,
            culture,
            encoding,
            list,
            noEmphasis,
            notMatch,
            quiet,
            raw,
            simpleMatch
        );

        // Convert PSObjects to their base objects
        var results = new object[result.Count];
        for (int i = 0; i < result.Count; i++)
        {
            if (result[i]?.BaseObject != null)
            {
                results[i] = result[i].BaseObject;
            }
            else
            {
                results[i] = result[i];
            }
        }

        return results;
    }
    /// <summary>
    /// Callback wrapper that allows PowerShell to call back into .NET for each result
    /// </summary>
    private class FindItemCallbackWrapper
    {
        private readonly Func<object, bool> _callback;
        public FindItemCallbackWrapper(Func<object, bool> callback) => _callback = callback;

        /// <summary>
        /// Called by PowerShell for each result - returns false to stop processing
        /// </summary>
        public bool ProcessItem(object item)
        {
            // Convert PSObject to base object if needed
            object processedItem = (item as PSObject)?.BaseObject ?? item;
            return _callback(processedItem);
        }
    }

    /// <summary>
    /// Fast multi-threaded file and directory search with streaming callback processing
    /// Processes results one by one without caching them all in memory
    /// </summary>
    protected void FindItem(
        Func<object, bool> callback,
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool directory = false,
        bool filesAndDirectories = false,
        bool passThru = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        bool noLinks = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool allMatches = false,
        bool caseSensitive = false,
        int[] context = null,
        string culture = null,
        string encoding = null,
        bool list = false,
        bool noEmphasis = false,
        bool notMatch = false,
        bool quiet = false,
        bool raw = false,
        bool simpleMatch = false)
    {
        // Create wrapper that holds the callback
        var callbackWrapper = new FindItemCallbackWrapper(callback);

        // Build parameter list for PowerShell script
        var scriptBuilder = new System.Text.StringBuilder();
        scriptBuilder.Append("param($CallbackWrapper, ");

        var paramNames = new[] {
        "Name", "Input", "Content", "RelativeBasePath", "Category", "MaxDegreeOfParallelism", "TimeoutSeconds",
        "AllDrives", "Directory", "FilesAndDirectories", "PassThru", "IncludeAlternateFileStreams", "NoRecurse",
        "FollowSymlinkAndJunctions", "IncludeOpticalDiskDrives", "SearchDrives", "DriveLetter", "Root",
        "IncludeNonTextFileMatching", "NoLinks", "CaseNameMatching", "SearchADSContent", "MaxRecursionDepth",
        "MaxSearchUpDepth", "MaxFileSize", "MinFileSize", "ModifiedAfter", "ModifiedBefore", "AttributesToSkip",
        "Exclude", "AllMatches", "CaseSensitive", "Context", "Culture", "Encoding", "List", "NoEmphasis",
        "NotMatch", "Quiet", "Raw", "SimpleMatch"
    };

        scriptBuilder.Append(string.Join(", ", paramNames.Select(p => "$" + p)));
        scriptBuilder.Append(") ");

        // Build the Find-Item command with all parameters
        scriptBuilder.Append("GenXdev.FileSystem\\Find-Item");

        // Add parameters conditionally (same logic as before)
        if (name != null && name.Length > 0) scriptBuilder.Append(" -Name $Name");
        if (input != null) scriptBuilder.Append(" -Input $Input");
        if (content != null && content.Length > 0) scriptBuilder.Append(" -Content $Content");
        if (!string.IsNullOrEmpty(relativeBasePath)) scriptBuilder.Append(" -RelativeBasePath $RelativeBasePath");
        if (category != null && category.Length > 0) scriptBuilder.Append(" -Category $Category");
        if (maxDegreeOfParallelism != 0) scriptBuilder.Append(" -MaxDegreeOfParallelism $MaxDegreeOfParallelism");
        if (timeoutSeconds.HasValue) scriptBuilder.Append(" -TimeoutSeconds $TimeoutSeconds");
        if (allDrives) scriptBuilder.Append(" -AllDrives");
        if (directory) scriptBuilder.Append(" -Directory");
        if (filesAndDirectories) scriptBuilder.Append(" -FilesAndDirectories");
        if (passThru) scriptBuilder.Append(" -PassThru");
        if (includeAlternateFileStreams) scriptBuilder.Append(" -IncludeAlternateFileStreams");
        if (noRecurse) scriptBuilder.Append(" -NoRecurse");
        if (followSymlinkAndJunctions) scriptBuilder.Append(" -FollowSymlinkAndJunctions");
        if (includeOpticalDiskDrives) scriptBuilder.Append(" -IncludeOpticalDiskDrives");
        if (searchDrives != null && searchDrives.Length > 0) scriptBuilder.Append(" -SearchDrives $SearchDrives");
        if (driveLetter != null && driveLetter.Length > 0) scriptBuilder.Append(" -DriveLetter $DriveLetter");
        if (root != null && root.Length > 0) scriptBuilder.Append(" -Root $Root");
        if (includeNonTextFileMatching) scriptBuilder.Append(" -IncludeNonTextFileMatching");
        if (noLinks) scriptBuilder.Append(" -NoLinks");
        if (caseNameMatching != System.IO.MatchCasing.PlatformDefault) scriptBuilder.Append(" -CaseNameMatching $CaseNameMatching");
        if (searchADSContent) scriptBuilder.Append(" -SearchADSContent");
        if (maxRecursionDepth != 0) scriptBuilder.Append(" -MaxRecursionDepth $MaxRecursionDepth");
        if (maxSearchUpDepth != 0) scriptBuilder.Append(" -MaxSearchUpDepth $MaxSearchUpDepth");
        if (maxFileSize != 0) scriptBuilder.Append(" -MaxFileSize $MaxFileSize");
        if (minFileSize != 0) scriptBuilder.Append(" -MinFileSize $MinFileSize");
        if (modifiedAfter.HasValue) scriptBuilder.Append(" -ModifiedAfter $ModifiedAfter");
        if (modifiedBefore.HasValue) scriptBuilder.Append(" -ModifiedBefore $ModifiedBefore");
        if (attributesToSkip != System.IO.FileAttributes.System) scriptBuilder.Append(" -AttributesToSkip $AttributesToSkip");
        if (exclude != null) scriptBuilder.Append(" -Exclude $Exclude");
        if (allMatches) scriptBuilder.Append(" -AllMatches");
        if (caseSensitive) scriptBuilder.Append(" -CaseSensitive");
        if (context != null && context.Length > 0) scriptBuilder.Append(" -Context $Context");
        if (!string.IsNullOrEmpty(culture)) scriptBuilder.Append(" -Culture $Culture");
        if (!string.IsNullOrEmpty(encoding)) scriptBuilder.Append(" -Encoding $Encoding");
        if (list) scriptBuilder.Append(" -List");
        if (noEmphasis) scriptBuilder.Append(" -NoEmphasis");
        if (notMatch) scriptBuilder.Append(" -NotMatch");
        if (quiet) scriptBuilder.Append(" -Quiet");
        if (raw) scriptBuilder.Append(" -Raw");
        if (simpleMatch) scriptBuilder.Append(" -SimpleMatch");

        // Pipe through ForEach-Object to process each result individually
        scriptBuilder.Append(" | ForEach-Object { ");
        scriptBuilder.Append("    $continue = $CallbackWrapper.ProcessItem($_); ");
        scriptBuilder.Append("    if (-not $continue) { break } ");
        scriptBuilder.Append("}");

        var findItemScript = ScriptBlock.Create(scriptBuilder.ToString());

        // Invoke with callback wrapper as first parameter
        findItemScript.Invoke(
            callbackWrapper,
            name, input, content, relativeBasePath, category, maxDegreeOfParallelism, timeoutSeconds,
            allDrives, directory, filesAndDirectories, passThru, includeAlternateFileStreams, noRecurse,
            followSymlinkAndJunctions, includeOpticalDiskDrives, searchDrives, driveLetter, root,
            includeNonTextFileMatching, noLinks, caseNameMatching, searchADSContent, maxRecursionDepth,
            maxSearchUpDepth, maxFileSize, minFileSize, modifiedAfter, modifiedBefore, attributesToSkip,
            exclude, allMatches, caseSensitive, context, culture, encoding, list, noEmphasis, notMatch,
            quiet, raw, simpleMatch
        );
    }

    /// <summary>
    /// Fast multi-threaded file and directory search with streaming callback processing
    /// Processes results one by one without caching them all in memory
    /// </summary>
    protected void FindItem(
        Func<FileInfo, bool> callback,
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool caseSensitive = false,
        string culture = null,
        string encoding = null,
        bool notMatch = false,
        bool simpleMatch = false)
    {
        Func<object, bool> cb = (obj) =>
        {
            if (obj is FileInfo matchInfo)
            {
                return callback(matchInfo);
            }
            return true; // Continue processing if cast fails
        };

        this.FindItem(
            cb,
            name,
            input,
            content,
            relativeBasePath,
            category,
            maxDegreeOfParallelism,
            timeoutSeconds,
            allDrives,
            false,
            false,
            true,
            includeAlternateFileStreams,
            noRecurse,
            followSymlinkAndJunctions,
            includeOpticalDiskDrives,
            searchDrives,
            driveLetter,
            root,
            includeNonTextFileMatching,
            true,
            caseNameMatching,
            searchADSContent,
            maxRecursionDepth,
            maxSearchUpDepth,
            maxFileSize,
            minFileSize,
            modifiedAfter,
            modifiedBefore,
            attributesToSkip,
            exclude,
            false,
            caseSensitive,
            null,
            culture,
            encoding,
            false,
            false,
            notMatch,
            true,
            false,
            simpleMatch
        );
    }


    /// <summary>
    /// Fast multi-threaded file and directory search with streaming callback processing
    /// Processes results one by one without caching them all in memory
    /// </summary>
    protected void FindItem(
        Func<DirectoryInfo, bool> callback,
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool caseSensitive = false,
        string culture = null,
        string encoding = null,
        bool notMatch = false,
        bool simpleMatch = false)
    {
        Func<object, bool> cb = (obj) =>
        {
            if (obj is DirectoryInfo dirInfo)
            {
                return callback(dirInfo);
            }
            return true; // Continue processing if cast fails
        };

        this.FindItem(
            cb,
            name,
            input,
            content,
            relativeBasePath,
            category,
            maxDegreeOfParallelism,
            timeoutSeconds,
            allDrives,
            true,
            false,
            true,
            includeAlternateFileStreams,
            noRecurse,
            followSymlinkAndJunctions,
            includeOpticalDiskDrives,
            searchDrives,
            driveLetter,
            root,
            includeNonTextFileMatching,
            true,
            caseNameMatching,
            searchADSContent,
            maxRecursionDepth,
            maxSearchUpDepth,
            maxFileSize,
            minFileSize,
            modifiedAfter,
            modifiedBefore,
            attributesToSkip,
            exclude,
            false,
            caseSensitive,
            null,
            culture,
            encoding,
            false,
            false,
            notMatch,
            true,
            false,
            simpleMatch
        );
    }


    /// <summary>
    /// Fast multi-threaded file and directory search with streaming callback processing
    /// Processes results one by one without caching them all in memory
    /// </summary>
    protected void FindItem(
        Func<string, bool> callback,
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool directory = false,
        bool filesAndDirectories = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool allMatches = false,
        bool caseSensitive = false,
        string culture = null,
        string encoding = null,
        bool notMatch = false,
        bool quiet = true,
        bool simpleMatch = false)
    {
        Func<object, bool> cb = (obj) =>
        {
            if (obj is string stringPath)
            {
                return callback((string)obj);
            }

            return true; // Continue processing if cast fails
        };

        this.FindItem(
            cb,
            name,
            input,
            content,
            relativeBasePath,
            category,
            maxDegreeOfParallelism,
            timeoutSeconds,
            allDrives,
            directory,
            filesAndDirectories,
            false,
            includeAlternateFileStreams,
            noRecurse,
            followSymlinkAndJunctions,
            includeOpticalDiskDrives,
            searchDrives,
            driveLetter,
            root,
            includeNonTextFileMatching,
            true,
            caseNameMatching,
            searchADSContent,
            maxRecursionDepth,
            maxSearchUpDepth,
            maxFileSize,
            minFileSize,
            modifiedAfter,
            modifiedBefore,
            attributesToSkip,
            exclude,
            allMatches,
            caseSensitive,
            null,
            culture,
            encoding,
            false,
            false,
            notMatch,
            quiet,
            !quiet,
            simpleMatch
        );
    }

    /// <summary>
    /// Fast multi-threaded file and directory search with streaming callback processing
    /// Processes results one by one without caching them all in memory
    /// </summary>
    protected void FindItem(
        Func<FileSystemInfo, bool> callback,
        string[] name = null,
        object input = null,
        string[] content = null,
        string relativeBasePath = null,
        string[] category = null,
        int maxDegreeOfParallelism = 0,
        int? timeoutSeconds = null,
        bool allDrives = false,
        bool directory = false,
        bool filesAndDirectories = false,
        bool includeAlternateFileStreams = false,
        bool noRecurse = false,
        bool followSymlinkAndJunctions = false,
        bool includeOpticalDiskDrives = false,
        string[] searchDrives = null,
        char[] driveLetter = null,
        string[] root = null,
        bool includeNonTextFileMatching = false,
        System.IO.MatchCasing caseNameMatching = System.IO.MatchCasing.PlatformDefault,
        bool searchADSContent = false,
        int maxRecursionDepth = 0,
        int maxSearchUpDepth = 0,
        long maxFileSize = 0,
        long minFileSize = 0,
        DateTime? modifiedAfter = null,
        DateTime? modifiedBefore = null,
        System.IO.FileAttributes attributesToSkip = System.IO.FileAttributes.System,
        string[] exclude = null,
        bool caseSensitive = false,
        string culture = null,
        string encoding = null,
        bool notMatch = false,
        bool simpleMatch = false)
    {
        Func<object, bool> cb = (obj) =>
        {
            if (obj is FileSystemInfo)
            {
                return callback((FileSystemInfo)obj);
            }

            return true; // Continue processing if cast fails
        };

        this.FindItem(
            cb,
            name,
            input,
            content,
            relativeBasePath,
            category,
            maxDegreeOfParallelism,
            timeoutSeconds,
            allDrives,
            directory,
            filesAndDirectories,
            true,
            includeAlternateFileStreams,
            noRecurse,
            followSymlinkAndJunctions,
            includeOpticalDiskDrives,
            searchDrives,
            driveLetter,
            root,
            includeNonTextFileMatching,
            true,
            caseNameMatching,
            searchADSContent,
            maxRecursionDepth,
            maxSearchUpDepth,
            maxFileSize,
            minFileSize,
            modifiedAfter,
            modifiedBefore,
            attributesToSkip,
            exclude,
            false,
            caseSensitive,
            null,
            culture,
            encoding,
            false,
            false,
            notMatch,
            false,
            true,
            simpleMatch
        );
    }
}