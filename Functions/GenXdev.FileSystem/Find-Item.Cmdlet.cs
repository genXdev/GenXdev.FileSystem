// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Cmdlet.cs
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

/// <summary>
/// <para type="synopsis">
/// Fast multi-threaded file and directory search with optional textcontent pattern matching
/// capabilities.
/// </para>
/// <para type="description">
/// SearchMask format capabilities:
/// 1. Basic Pattern Support:
///    - Wildcards: * and ? for pattern matching
///    - Directory Navigation: \ and / for path separators
///    - \**\ pattern for recursive directory matching
/// 2. Path Type Support:
///    - File names without paths: e.g., *.txt
///    - Relative paths: .\subfolder\*.log
///    - Absolute paths: C:\Windows\*.exe
///    - UNC paths: \\server\share\*.doc
///    - Rooted paths with drive letters
///    - Base directory patterns: [Directory]*.cs
/// 3. Pattern Examples:
///    - Simple wildcard: *.txt - All txt files in current directory
///    - Specific extension: .\*.js - JavaScript files in current directory
///    - Complex pattern: test*.log - Log files starting with "test"
///    - Recursive: **\*.txt - All txt files recursively in any subdirectory
///    - Deep path: dir1\*\item_??\john*\subdir\*\final\*.dat - Dat files in
///      directories
///      including and below any matching '\subdir\' directories
///    - Multiple wildcards: *test*\*.xml - XML files in folders containing
///      "test"
/// 4. Special Features:
///    - Alternate Data Streams: file.txt:stream
///    - Multi-drive search with -AllDrives
///    - -Directory switch to only match directories
///    - -NoRecurse to prevent recursive searching
///    - -Pattern parameter for content searching
///    - Case-insensitive matching
/// 5. Search Behavior:
///    - When using -AllDrives, only the filename part is matched
///    - Handles special characters in filenames
///    - Supports long paths (>260 chars)
///    - Follows NTFS junctions and symlinks
///    - Respects access permissions
/// </para>
/// <para type="description">
/// A powerful search utility that combines file/directory pattern matching with
/// content filtering. Defaults to fast recursive searches, supports multi-drive
/// operations, and flexible output formats.
/// Can search by name patterns and content patterns
/// simultaneously.
/// Supports ntfs alternate-data-streams, unc share matching, and long filenames
/// </para>
///
/// <para type="description">
/// PARAMETERS
/// </para>
///
/// <para type="description">
/// -SearchMask &lt;String[]&gt;<br/>
/// File name or pattern to search for. Supports wildcards (*, ?). Default is
/// '*'.<br/>
/// - <b>Aliases</b>: like, l, Path, Name, file, Query, FullName<br/>
/// - <b>Position</b>: 0<br/>
/// - <b>Examples</b>:<br/>
///   - Simple wildcard: <c>*.txt</c> - All txt files in the current
///     directory<br/>
///   - Specific extension: <c>.\*.js</c> - JavaScript files in the current
///     directory<br/>
///   - Complex pattern: <c>test*.log</c> - Log files starting with "test"<br/>
///   - Recursive: <c>**\*.txt</c> - All txt files recursively in any
///     subdirectory<br/>
///   - Deep path: <c>dir1\*\item_??\john*\subdir\*\final\*.dat</c> - Dat files
///     in directories including and below any matching '\subdir\'
///     directories<br/>
///   - Multiple wildcards: <c>*test*\*.xml</c> - XML files in folders
///     containing "test"<br/>
/// - <b>Features</b>:<br/>
///   - Wildcards: <c>*</c> and <c>?</c> for pattern matching<br/>
///   - Directory Navigation: <c>\</c> and <c>/</c> for path separators<br/>
///   - Recursive pattern: <c>\**\</c> for recursive directory matching<br/>
///   - Supports file names without paths, relative paths, absolute paths, UNC
///     paths, rooted paths with drive letters, and base directory patterns<br/>
///   - Alternate Data Streams: <c>file.txt:stream</c>
/// </para>
///
/// <para type="description">
/// -Input &lt;String&gt;<br/>
/// File name or pattern to search for from pipeline input. Default is '*'.<br/>
/// - <b>Aliases</b>: like, l, Path, Name, file, Query, FullName<br/>
/// - <b>Accepts pipeline input</b>: Yes
/// </para>
///
/// <para type="description">
/// -Pattern &lt;String&gt;<br/>
/// Regular expression pattern to search within file contents.<br/>
/// - <b>Aliases</b>: mc, matchcontent<br/>
/// - <b>Position</b>: 1<br/>
/// - <b>Default</b>: ".*"
/// </para>
///
/// <para type="description">
/// -RelativeBasePath &lt;String&gt;<br/>
/// Base path for resolving relative paths in output.<br/>
/// - <b>Aliases</b>: base<br/>
/// - <b>Position</b>: 2<br/>
/// - <b>Default</b>: ".\\"
/// </para>
///
/// <para type="description">
/// -MaxDegreeOfParallelism &lt;Int32&gt;<br/>
/// Maximum degree of parallelism for directory tasks.<br/>
/// - <b>Default</b>: 8
/// </para>
///
/// <para type="description">
/// -TimeoutSeconds &lt;Int32&gt;<br/>
/// Optional cancellation timeout in seconds.
/// </para>
///
/// <para type="description">
/// -AllDrives &lt;SwitchParameter&gt;<br/>
/// Search across all available drives.
/// </para>
///
/// <para type="description">
/// -Directory &lt;SwitchParameter&gt;<br/>
/// Search for directories only.<br/>
/// - <b>Aliases</b>: dir
/// </para>
///
/// <para type="description">
/// -FilesAndDirectories &lt;SwitchParameter&gt;<br/>
/// Include both files and directories.<br/>
/// - <b>Aliases</b>: both
/// </para>
///
/// <para type="description">
/// -PassThru &lt;SwitchParameter&gt;<br/>
/// Output matched items as objects.<br/>
/// - <b>Aliases</b>: pt
/// </para>
///
/// <para type="description">
/// -IncludeAlternateFileStreams &lt;SwitchParameter&gt;<br/>
/// Include alternate data streams in search results.<br/>
/// - <b>Aliases</b>: ads
/// </para>
///
/// <para type="description">
/// -NoLinks &lt;SwitchParameter&gt;<br/>
///Forces unattended mode and will not generate links
/// - <b>Aliases</b>: nl
/// </para>

/// <para type="description">
/// -NoRecurse &lt;SwitchParameter&gt;<br/>
/// Do not recurse into subdirectories.
/// </para>
///
/// <para type="description">
/// -SearchDrives &lt;String[]&gt;<br/>
/// Optional: search specific drives.
/// </para>
///
/// <para type="description">
/// -CaseSensitivePattern &lt;SwitchParameter&gt;<br/>
/// Makes pattern matching case-sensitive. By default, pattern matching
/// is case-insensitive.
/// </para>
///
/// <para type="description">
/// -SearchADSContent &lt;SwitchParameter&gt;<br/>
/// When set, performs content search within alternate data streams (ADS). When
/// not set, outputs ADS file info without searching their content.
/// </para>
/// <para type="description">
/// -MaxRecursionDepth &lt;Int32&gt;<br/>
/// Maximum recursion depth for directory traversal. 0 means unlimited.
/// </para>
///
/// <para type="description">
/// -MaxFileSize &lt;Int64&gt;<br/>
/// Maximum file size in bytes to include in results. 0 means unlimited.
/// </para>
///
/// <para type="description">
/// -MinFileSize &lt;Int64&gt;<br/>
/// Minimum file size in bytes to include in results. 0 means no minimum.
/// </para>
///
/// <para type="description">
/// -ModifiedAfter &lt;DateTime?&gt;<br/>
/// Only include files modified after this date/time (UTC).
/// </para>
///
/// <para type="description">
/// -ModifiedBefore &lt;DateTime?&gt;<br/>
/// Only include files modified before this date/time (UTC).
/// </para>
///
/// <para type="description">
/// -AttributesToSkip &lt;FileAttributes&gt;<br/>
/// File attributes to skip (e.g., System, Hidden or None).
/// </para>
///
/// <para type="description">
/// -Exclude &lt;String[]&gt;<br/>
/// Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\bin\*).
/// </para>
/// <para type="description">
/// -IncludeOpticalDiskDrives &lt;SwitchParameter&gt;<br/>
/// Include optical disk drives
/// </para>
/// <para type="description">
/// -IncludeNonTextFileMatching &lt;SwitchParameter&gt;<br/>
/// Include non-text files (binaries, images, etc.) when searching file
/// contents.
/// </para>
///
/// <example>
/// <para>Find files containing a specific word</para>
/// <para>Search for all files in the current directory and subdirectories that contain the word "translation".</para>
/// <code>
/// Find-Item -Pattern "translation"
///
/// # Short form:
/// l -mc translation
/// </code>
/// </example>
///
/// <example>
/// <para>Find JavaScript files with a version string</para>
/// <para>Search for JavaScript files containing a version string in the format "Version == `x.y.z`".</para>
/// <code>
/// Find-Item "*.js" "Version == `"\d\d?\.\d\d?\.\d\d?`""
///
/// # Short form:
/// l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""
/// </code>
/// </example>
///
/// <example>
/// <para>List all directories</para>
/// <para>Find all directories in the current directory and its subdirectories.</para>
/// <code>
/// Find-Item -Directory
///
/// # Short form:
/// l -dir
/// </code>
/// </example>
///
/// <example>
/// <para>Find XML files and pass objects</para>
/// <para>Search for all .xml files and pass the results as objects through the pipeline.</para>
/// <code>
/// Find-Item ".\*.xml" -PassThru | % FullName
///
/// # Short form:
/// l *.xml -pt | % FullName
/// </code>
/// </example>
///
/// <example>
/// <para>Include alternate data streams</para>
/// <para>Search for all files and include their alternate data streams in the results.</para>
/// <code>
/// Find-Item -IncludeAlternateFileStreams
///
/// # Short form:
/// l -ads
/// </code>
/// </example>
///
/// <example>
/// <para>Search across all drives</para>
/// <para>Search for all PDF files across all available drives.</para>
/// <code>
/// Find-Item "*.pdf" -AllDrives
///
/// # Short form:
/// l *.pdf -alldrives
/// </code>
/// </example>
///
/// <example>
/// <para>Custom timeout and parallelism</para>
/// <para>Search for log files with a 5-minute timeout and limited parallelism.</para>
/// <code>
/// Find-Item "*.log" -TimeoutSeconds 300 -MaxDegreeOfParallelism 4
///
/// # Short form:
/// l *.log -maxseconds 300 -threads 4
/// </code>
/// </example>
///
/// <example>
/// <para>Pipeline input</para>
/// <para>Pass file paths from Get-ChildItem to search for files containing "error".</para>
/// <code>
/// Get-ChildItem -Path "C:\Logs" | Find-Item -Pattern "error"
///
/// # Short form:
/// ls C:\Logs | l -matchcontent "error"
/// </code>
/// </example>
///
/// <example>
/// <para>Limit recursion depth</para>
/// <para>Search for text files but limit recursion to 2 directory levels.</para>
/// <code>
/// Find-Item "*.txt" -MaxRecursionDepth 2
///
/// # Short form:
/// l *.txt -maxdepth 2
/// </code>
/// </example>
///
/// <example>
/// <para>Filter by file size</para>
/// <para>Find files larger than 1MB but smaller than 10MB.</para>
/// <code>
/// Find-Item -MinFileSize 1048576 -MaxFileSize 10485760
///
/// # Short form:
/// l -minsize 1048576 -maxsize 10485760
/// </code>
/// </example>
///
/// <example>
/// <para>Filter by modification date</para>
/// <para>Find files modified after January 1, 2025.</para>
/// <code>
/// Find-Item -ModifiedAfter "2025-01-01"
///
/// # Short form:
/// l -after "2025-01-01"
/// </code>
/// </example>
///
/// <example>
/// <para>Exclude specific patterns</para>
/// <para>Search for all files but exclude temporary files and bin directories.</para>
/// <code>
/// Find-Item -Exclude "*.tmp","*\bin\*"
///
/// # Short form:
/// l -skiplike "*.tmp","*\bin\*"
/// </code>
/// </example>
///
/// <example>
/// <para>Search specific drives</para>
/// <para>Search for .docx files on C: and D: drives only.</para>
/// <code>
/// Find-Item "*.docx" -SearchDrives "C:\","D:\"
///
/// # Short form:
/// l *.docx -drives C:\, D:\
/// </code>
/// </example>
///
/// <example>
/// <para>Case-sensitive content search</para>
/// <para>Search for files containing "Error" (case-sensitive) in their content.</para>
/// <code>
/// Find-Item -Pattern "Error" -CaseSensitivePattern
///
/// # Short form:
/// l -matchcontent "Error" -patternmatchcase
/// </code>
/// </example>
///
/// <example>
/// <para>Search alternate data stream content</para>
/// <para>Search for files with alternate data streams containing "secret".</para>
/// <code>
/// Find-Item -IncludeAlternateFileStreams -SearchADSContent -Pattern "secret"
///
/// # Short form:
/// </code>
/// </example>
///
/// <para type="link" uri="https://github.com/genXdev/GenXdev.FileSystem">
/// Online documentation: https://github.com/genXdev/GenXdev.FileSystem
/// </para>


[Cmdlet(VerbsCommon.Find, "Item", DefaultParameterSetName = "Default")]
[Alias("l")]
public partial class FindItem : PSCmdlet
{
    /// <summary>
    /// <para type="description">File name or pattern to search for. Supports wildcards (*,?). Default is '*'</para>
    /// </summary>
    [Parameter(Position = 0, Mandatory = false, HelpMessage = "File name or pattern to search for. Default is '*'")]
    [Alias("like", "l", "Path", "Query")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    public string[] SearchMask { get; set; } = new string[] { "*" };

    /// <summary>
    /// <para type="description">File name or pattern to search for from pipeline input. Default is '*'</para>
    /// </summary>
    [Parameter(Mandatory = false, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = "File name or pattern to search for. Default is '*'")]
    [Alias("FullName")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    public string Input { get; set; }

    /// <summary>
    /// <para type="description">Regular expression pattern to search within file contents</para>
    /// </summary>
    [Parameter(Position = 1, Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Regular expression pattern to search within content")]
    [Alias("mc", "matchcontent", "regex")]
    [ValidateNotNull()]
    [SupportsWildcards()]
    public string Pattern { get; set; } = ".*";

    /// <summary>
    /// <para type="description">Base path for resolving relative paths in output</para>
    /// </summary>
    [Parameter(Position = 2, Mandatory = false, HelpMessage = "Base path for resolving relative paths in output")]
    [Alias("base")]
    [ValidateNotNullOrEmpty()]
    public string RelativeBasePath { get; set; } = ".\\";

    /// <summary>
    /// <para type="description">Maximum degree of parallelism for directory tasks</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Maximum degree of parallelism for directory tasks")]
    [Alias("threads")]
    public int MaxDegreeOfParallelism { get; set; } = 0;

    /// <summary>
    /// <para type="description">Optional: cancellation timeout in seconds</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Optional: cancellation timeout in seconds")]
    [Alias("maxseconds")]
    public int? TimeoutSeconds { get; set; }

    /// <summary>
    /// <para type="description">Search across all available drives</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Search across all available drives")]
    public SwitchParameter AllDrives { get; set; }

    /// <summary>
    /// <para type="description">Search for directories only</para>
    /// </summary>
    [Parameter(Mandatory = false, ParameterSetName = "DirectoriesOnly", HelpMessage = "Search for directories only")]
    [Alias("dir")]
    public SwitchParameter Directory { get; set; }

    /// <summary>
    /// <para type="description">Include both files and directories</para>
    /// </summary>
    [Parameter(Mandatory = false, ParameterSetName = "DirectoriesOnly", HelpMessage = "Include both files and directories")]
    [Alias("both")]
    public SwitchParameter FilesAndDirectories { get; set; }

    /// <summary>
    /// <para type="description">Output matched items as objects</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Output matched items as objects")]
    [Alias("pt")]
    public SwitchParameter PassThru { get; set; }

    /// <summary>
    /// <para type="description">Include alternate data streams in search results
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Include alternate data streams in search results")]
    [Alias("ads")]
    public SwitchParameter IncludeAlternateFileStreams { get; set; }

    /// <summary>
    /// <para type="description">Do not recurse into subdirectories</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Do not recurse into subdirectories")]
    [Alias("nr")]
    public SwitchParameter NoRecurse { get; set; }

    /// <summary>
    /// <para type="description">Follow symlinks and junctions during directory
    /// traversal</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Follow symlinks and junctions during directory traversal")]
    [Alias("symlinks", "sl")]
    public SwitchParameter FollowSymlinkAndJunctions { get; set; }

    /// <summary>
    /// <para type="description">Include optical disk drives</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Include optical disk drives")]
    public SwitchParameter IncludeOpticalDiskDrives { get; set; }

    /// <summary>
    /// <para type="description">Optional: search specific drives</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Optional: search specific drives")]
    [Alias("drives")]
    public string[] SearchDrives { get; set; } = Array.Empty<string>();

    /// <summary>
    /// <para type="description">Include non-text files (binaries, images, etc.)
    /// when searching file contents</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Include non-text files when searching file contents")]
    [Alias("binary")]
    public SwitchParameter IncludeNonTextFileMatching { get; set; }
    /// <summary>
    /// <para type="description">Forces unattended mode and will not generate
    /// links</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Forces unattended mode and will not generate links")]
    [Alias("nl")]
    public SwitchParameter NoLinks { get; set; }

    /// <summary>
    /// <para type="description">Makes pattern matching case-sensitive. By default,
    /// pattern matching is case-insensitive.</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Makes pattern matching case-sensitive. By default, pattern matching is case-insensitive.")]
    [Alias("patternmatchcase", "csp")]
    public SwitchParameter CaseSensitivePattern { get; set; }

    /// <summary>Gets or sets the case-sensitivity for files and directories.
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Gets or sets the case-sensitivity for files and directories")]
    [Alias("casing")]
    public System.IO.MatchCasing CaseSearchMaskMatching { get; set; } = System.IO.MatchCasing.PlatformDefault;

    /// <summary>
    /// <para type="description">
    /// When set, performs content search within alternate data streams (ADS). When
    /// not set,
    /// outputs ADS file info without searching their content.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "When set, performs content search within alternate data streams (ADS). When not set, outputs ADS file info without searching their content.")]
    [Alias("sads")]
    public SwitchParameter SearchADSContent { get; set; }

    /// <summary>
    /// <para type="description">Maximum recursion depth for directory traversal. 0
    /// means unlimited.</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Maximum recursion depth for directory traversal. 0 means unlimited.")]
    [Alias("md", "depth", "maxdepth")]
    public int MaxRecursionDepth { get; set; } = 0;

    /// <summary>
    /// <para type="description">Maximum file size in bytes to include in results. 0
    /// means unlimited.</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Maximum file size in bytes to include in results. 0 means unlimited.")]
    [Alias("maxlength", "maxsize")]
    public long MaxFileSize { get; set; } = 0;

    /// <summary>
    /// <para type="description">Minimum file size in bytes to include in results. 0
    /// means no minimum.</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Minimum file size in bytes to include in results. 0 means no minimum.")]
    [Alias("minsize", "minlength")]
    public long MinFileSize { get; set; } = 0;

    /// <summary>
    /// <para type="description">Only include files modified after this date/time
    /// (UTC).</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Only include files modified after this date/time (UTC).")]
    [Alias("ma", "after")]
    public DateTime? ModifiedAfter { get; set; }

    /// <summary>
    /// <para type="description">Only include files modified before this date/time
    /// (UTC).</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Only include files modified before this date/time (UTC).")]
    [Alias("before", "mb")]
    public DateTime? ModifiedBefore { get; set; }

    /// <summary>Gets or sets the attributes to skip. The default is
    /// <c>FileAttributes.System</c>.</summary>
    [Parameter(Mandatory = false, HelpMessage = "File attributes to skip (e.g., System, Hidden or None).")]
    [Alias("skipattr")]
    public FileAttributes AttributesToSkip { get; set; } = FileAttributes.System;

    /// <summary>
    /// <para type="description">Exclude files or directories matching these
    /// wildcard patterns (e.g., *.tmp, *\bin\*).</para>
    /// </summary>
    [Parameter(Mandatory = false, HelpMessage = "Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\\bin\\*).")]
    [Alias("skiplike")]
    public string[] Exclude { get; set; } = new string[1] { "\\.git\\*" };

    // Cmdlet lifecycle methods
    protected override void BeginProcessing()
    {

        // set default parallelism if not provided by user
        MaxDegreeOfParallelism = MaxDegreeOfParallelism <= 0 ? GetCoreCount() * 2 : MaxDegreeOfParallelism;

        // detect if running in unattended mode for output formatting
        UnattendedMode = NoLinks.IsPresent || UnattendedModeHelper.IsUnattendedMode(MyInvocation);

        // prepare dictionary to track visited nodes for loop prevention
        InitializeVisitedNodes();

        // set up verbose logging based on user preference
        InitializeVerboseOutput();

        // prepare wildcard matching for exclusions
        InitializeWildcardMatcher();

        // set up exclusion patterns for files and directories
        InitializeExcludePatterns();

        // determine current working directory for relative paths
        InitializeCurrentDirectory();

        // resolve base path for relative output
        InitializeRelativeBaseDir();

        // compile regex for content searching
        InitializePatternMatcher();

        // configure buffering for large file processing
        InitializeBufferingConfiguration();

        // set up cancellation with optional timeout
        InitializeCancellationToken();

        // process each unique search mask provided
        if (SearchMask != null && SearchMask.Length > 0)
        {

            // loop through each mask
            foreach (var mask in SearchMask)
            {

                // check if mask already processed to avoid duplicates
                if (VisitedNodes.TryAdd("start;" + mask, true))
                {

                    // log processing of mask if verbose enabled
                    if (UseVerboseOutput)
                    {
                        VerboseQueue.Enqueue($"Processing search mask: {mask}");
                    }

                    // prepare search starting point
                    InitializeSearchDirectory(mask);
                }
                else if (UseVerboseOutput)
                {

                    // log skipping duplicate mask
                    VerboseQueue.Enqueue($"Skipping duplicate search mask: {mask}");
                }
            }
        }
    }

    protected override void ProcessRecord()
    {

        // handle pipeline input if provided
        if (!string.IsNullOrEmpty(Input))
        {

            // add to visited if new and initialize search
            if (VisitedNodes.TryAdd("start;" + Input, true))
            {
                InitializeSearchDirectory(Input);
            }
        }
    }

    protected override void EndProcessing()
    {

        // run the search tasks
        ProcessSearchTasks();

        // clear all queues
        EmptyQueues();

        // create completion progress record
        var completeRecord = new ProgressRecord(0, "FastFileSearch", "Completed")
        {
            // set completion percentage
            PercentComplete = 100,

            // mark as completed
            RecordType = ProgressRecordType.Completed
        };

        // output completion progress
        WriteProgress(completeRecord);

        // clean up cancellation source
        cts?.Dispose();
    }

    protected override void StopProcessing()
    {

        // trigger cancellation
        cts?.Cancel();
    }
}