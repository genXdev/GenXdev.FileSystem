// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Cmdlet.cs
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



using System.Management.Automation;

namespace GenXdev.FileSystem
{

    /// <summary>
    /// <para type="synopsis">
    /// Fast multi-threaded file and directory search with optional textcontent pattern matching
    /// capabilities.
    /// </para>
    ///
    /// <para type="description">
    /// PARAMETERS
    /// </para>
    ///
    /// <para type="description">
    /// -Name &lt;String[]&gt;<br/>
    /// File name or pattern to search for. Default is '*'.<br/>
    /// - <b>Aliases</b>: like, l, Path, LiteralPath, Query, SearchMask, Include<br/>
    /// - <b>Position</b>: 0<br/>
    /// - <b>Default</b>: "*"<br/>
    /// - <b>Features</b>:<br/>
    ///   - Supports wildcards: <c>*</c> and <c>?</c> for pattern matching<br/>
    ///   - Directory Navigation: <c>\</c> and <c>/</c> for path separators<br/>
    ///   - Recursive pattern: <c>\**\</c> for recursive directory matching<br/>
    ///   - Supports file names without paths, relative paths, absolute paths, UNC paths, rooted paths with drive letters, and base directory patterns<br/>
    ///   - Alternate Data Streams: <c>file.txt:stream</c><br/>
    /// - <b>Examples</b>:<br/>
    ///   - Simple wildcard: <c>*.txt</c> - All txt files in the current directory<br/>
    ///   - Specific extension: <c>.\*.js</c> - JavaScript files in the current directory<br/>
    ///   - Complex pattern: <c>test*.log</c> - Log files starting with "test"<br/>
    ///   - Recursive: <c>**\*.txt</c> - All txt files recursively in any subdirectory<br/>
    /// </para>
    ///
    /// <para type="description">
    /// -Input &lt;String&gt;<br/>
    /// File name or pattern to search for from pipeline input. Default is '*'<br/>
    /// - <b>Aliases</b>: FullName<br/>
    /// - <b>Default</b>: "*"<br/>
    /// </para>

    /// <para type="description">
    /// -Content &lt;String[]&gt;<br/>
    /// Regular expression pattern to search within file contents<br/>
    /// - <b>Aliases</b>: mc, matchcontent, regex, Pattern<br/>
    /// - <b>Position</b>: 1<br/>
    /// - <b>Default</b>: ".*"<br/>
    /// </para>

    /// <para type="description">
    /// -RelativeBasePath &lt;String&gt;<br/>
    /// Base path for resolving relative paths in output<br/>
    /// - <b>Aliases</b>: base<br/>
    /// - <b>Position</b>: 2<br/>
    /// - <b>Default</b>: ".\\"<br/>
    /// </para>

    /// <para type="description">
    /// -Category &lt;String[]&gt;<br/>
    /// Only output files belonging to selected categories<br/>
    /// - <b>Aliases</b>: filetype<br/>
    /// </para>

    /// <para type="description">
    /// -MaxDegreeOfParallelism &lt;Int32&gt;<br/>
    /// Maximum degree of parallelism for directory tasks<br/>
    /// - <b>Aliases</b>: threads<br/>
    /// - <b>Default</b>: 0<br/>
    /// </para>

    /// <para type="description">
    /// -TimeoutSeconds &lt;Int32?&gt;<br/>
    /// Optional: cancellation timeout in seconds<br/>
    /// - <b>Aliases</b>: maxseconds<br/>
    /// </para>

    /// <para type="description">
    /// -AllDrives &lt;SwitchParameter&gt;<br/>
    /// Search across all available drives<br/>
    /// </para>

    /// <para type="description">
    /// -Directory &lt;SwitchParameter&gt;<br/>
    /// Search for directories only<br/>
    /// - <b>Aliases</b>: dir<br/>
    /// </para>

    /// <para type="description">
    /// -FilesAndDirectories &lt;SwitchParameter&gt;<br/>
    /// Include both files and directories<br/>
    /// - <b>Aliases</b>: both<br/>
    /// </para>

    /// <para type="description">
    /// -PassThru &lt;SwitchParameter&gt;<br/>
    /// Output matched items as objects<br/>
    /// - <b>Aliases</b>: pt<br/>
    /// </para>

    /// <para type="description">
    /// -IncludeAlternateFileStreams &lt;SwitchParameter&gt;<br/>
    /// Include alternate data streams in search results<br/>
    /// - <b>Aliases</b>: ads<br/>
    /// </para>

    /// <para type="description">
    /// -NoRecurse &lt;SwitchParameter&gt;<br/>
    /// Do not recurse into subdirectories<br/>
    /// - <b>Aliases</b>: nr<br/>
    /// </para>

    /// <para type="description">
    /// -FollowSymlinkAndJunctions &lt;SwitchParameter&gt;<br/>
    /// Follow symlinks and junctions during directory traversal<br/>
    /// - <b>Aliases</b>: symlinks, sl<br/>
    /// </para>

    /// <para type="description">
    /// -IncludeOpticalDiskDrives &lt;SwitchParameter&gt;<br/>
    /// Include optical disk drives<br/>
    /// </para>

    /// <para type="description">
    /// -SearchDrives &lt;String[]&gt;<br/>
    /// Optional: search specific drives<br/>
    /// - <b>Aliases</b>: drives<br/>
    /// - <b>Default</b>: Empty array<br/>
    /// </para>

    /// <para type="description">
    /// -DriveLetter &lt;Char[]&gt;<br/>
    /// Optional: search specific drives<br/>
    /// - <b>Default</b>: Empty array<br/>
    /// </para>

    /// <para type="description">
    /// -Root &lt;String[]&gt;<br/>
    /// Optional: search specific base folders combined with provided Names<br/>
    /// - <b>Default</b>: Empty array<br/>
    /// </para>

    /// <para type="description">
    /// -IncludeNonTextFileMatching &lt;SwitchParameter&gt;<br/>
    /// Include non-text files (binaries, images, etc.) when searching file contents<br/>
    /// - <b>Aliases</b>: binary<br/>
    /// </para>

    /// <para type="description">
    /// -NoLinks &lt;SwitchParameter&gt;<br/>
    /// Forces unattended mode and will not generate links<br/>
    /// - <b>Aliases</b>: nl<br/>
    /// </para>

    /// <para type="description">
    /// -CaseNameMatching &lt;MatchCasing&gt;<br/>
    /// Gets or sets the case-sensitivity for files and directories<br/>
    /// - <b>Aliases</b>: casing, CaseSearchMaskMatching<br/>
    /// - <b>Default</b>: PlatformDefault<br/>
    /// </para>

    /// <para type="description">
    /// -SearchADSContent &lt;SwitchParameter&gt;<br/>
    /// When set, performs content search within alternate data streams (ADS). When not set, outputs ADS file info without searching their content.<br/>
    /// - <b>Aliases</b>: sads<br/>
    /// </para>

    /// <para type="description">
    /// -MaxRecursionDepth &lt;Int32&gt;<br/>
    /// Maximum recursion depth for directory traversal. 0 means unlimited.<br/>
    /// - <b>Aliases</b>: md, depth, maxdepth<br/>
    /// - <b>Default</b>: 0<br/>
    /// </para>

    /// <para type="description">
    /// -MaxFileSize &lt;Int64&gt;<br/>
    /// Maximum file size in bytes to include in results. 0 means unlimited.<br/>
    /// - <b>Aliases</b>: maxlength, maxsize<br/>
    /// - <b>Default</b>: 0<br/>
    /// </para>

    /// <para type="description">
    /// -MinFileSize &lt;Int64&gt;<br/>
    /// Minimum file size in bytes to include in results. 0 means no minimum.<br/>
    /// - <b>Aliases</b>: minsize, minlength<br/>
    /// - <b>Default</b>: 0<br/>
    /// </para>

    /// <para type="description">
    /// -ModifiedAfter &lt;DateTime?&gt;<br/>
    /// Only include files modified after this date/time (UTC).<br/>
    /// - <b>Aliases</b>: ma, after<br/>
    /// </para>

    /// <para type="description">
    /// -ModifiedBefore &lt;DateTime?&gt;<br/>
    /// Only include files modified before this date/time (UTC).<br/>
    /// - <b>Aliases</b>: before, mb<br/>
    /// </para>

    /// <para type="description">
    /// -AttributesToSkip &lt;FileAttributes&gt;<br/>
    /// File attributes to skip (e.g., System, Hidden or None).<br/>
    /// - <b>Aliases</b>: skipattr<br/>
    /// - <b>Default</b>: System<br/>
    /// </para>

    /// <para type="description">
    /// -Exclude &lt;String[]&gt;<br/>
    /// Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\bin\*).<br/>
    /// - <b>Aliases</b>: skiplike<br/>
    /// - <b>Default</b>: "*\\.git\\*"<br/>
    /// </para>

    /// <para type="description">
    /// -AllMatches &lt;SwitchParameter&gt;<br/>
    /// Indicates that the cmdlet searches for more than one match in each line of text. Without this parameter, Select-String finds only the first match in each line of text.<br/>
    /// </para>

    /// <para type="description">
    /// -CaseSensitive &lt;SwitchParameter&gt;<br/>
    /// Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.<br/>
    /// </para>

    /// <para type="description">
    /// -Context &lt;Int32[]&gt;<br/>
    /// Captures the specified number of lines before and after the line that matches the pattern.<br/>
    /// - <b>Default</b>: null<br/>
    /// </para>

    /// <para type="description">
    /// -Culture &lt;String&gt;<br/>
    /// Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).<br/>
    /// </para>

    /// <para type="description">
    /// -Encoding &lt;String&gt;<br/>
    /// Specifies the type of encoding for the target file. The default value is utf8NoBOM.<br/>
    /// - <b>Default</b>: "UTF8NoBOM"<br/>
    /// </para>

    /// <para type="description">
    /// -List &lt;SwitchParameter&gt;<br/>
    /// Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.<br/>
    /// </para>

    /// <para type="description">
    /// -NoEmphasis &lt;SwitchParameter&gt;<br/>
    /// Disables highlighting of matching strings in output. By default, matching patterns are highlighted using negative colors based on your PowerShell theme.<br/>
    /// - <b>Features</b>:<br/>
    ///   - Disables highlighting of pattern matches<br/>
    ///   - Uses negative colors based on PowerShell background and text colors<br/>
    ///   - Example: Black background with white text becomes white background with black text<br/>
    /// </para>

    /// <para type="description">
    /// -NotMatch &lt;SwitchParameter&gt;<br/>
    /// The NotMatch parameter finds text that doesn't match the specified pattern.<br/>
    /// </para>

    /// <para type="description">
    /// -Quiet &lt;SwitchParameter&gt;<br/>
    /// Indicates that the cmdlet returns a simple response instead of a MatchInfo object. The returned value is $true if the pattern is found or $null if the pattern is not found.<br/>
    /// - <b>Aliases</b>: NoMatchOutput<br/>
    /// </para>

    /// <para type="description">
    /// -Raw &lt;SwitchParameter&gt;<br/>
    /// Causes the cmdlet to output only the matching strings, rather than MatchInfo objects. This is the results in behavior that's the most similar to the Unix grep or Windows findstr.exe commands.<br/>
    /// </para>

    /// <para type="description">
    /// -SimpleMatch &lt;SwitchParameter&gt;<br/>
    /// Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.<br/>
    /// </para>

    /// <example>
    /// <para>Find files containing a specific word</para>
    /// <para>Search for all files in the current directory and subdirectories that contain the word "translation".</para>
    /// <code>
    /// Find-Item -Content "translation"
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
    /// Get-ChildItem -Path "C:\Logs" | Find-Item -Content "error"
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
    /// Find-Item -Exclude "*.tmp", "*\bin\*"
    ///
    /// # Short form:
    /// l -skiplike "*.tmp", "*\bin\*"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Search specific drives</para>
    /// <para>Search for .docx files on C: and D: drives only.</para>
    /// <code>
    /// Find-Item "*.docx" -SearchDrives "C:\", "D:\"
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
    /// Find-Item -Content "Error" -CaseSensitive
    ///
    /// # Short form:
    /// l -mc "Error" -CaseSensitive
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Search alternate data stream content</para>
    /// <para>Search for files with alternate data streams containing "secret".</para>
    /// <code>
    /// Find-Item -IncludeAlternateFileStreams -SearchADSContent -Content "secret"
    ///
    /// # Short form:
    /// l -ads -sads -mc "secret"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Find all matches per line</para>
    /// <para>Search for all occurrences of "function" in each line, not just the first match.</para>
    /// <code>
    /// Find-Item "*.ps1" -Content "function" -AllMatches
    ///
    /// # Short form:
    /// l *.ps1 -mc "function" -AllMatches
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Show context around matches</para>
    /// <para>Display 2 lines before and 3 lines after each match for better understanding.</para>
    /// <code>
    /// Find-Item "*.log" -Content "error" -Context 2,3
    ///
    /// # Short form:
    /// l *.log -mc "error" -Context 2,3
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Get only matching strings</para>
    /// <para>Return just the matching text strings instead of full match objects.</para>
    /// <code>
    /// Find-Item "*.txt" -Content "TODO:.*" -Raw
    ///
    /// # Short form:
    /// l *.txt -mc "TODO:.*" -Raw
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Simple boolean check</para>
    /// <para>Return true/false instead of match details to check if pattern exists.</para>
    /// <code>
    /// Find-Item "*.config" -Content "database" -Quiet
    ///
    /// # Short form:
    /// l *.config -mc "database" -Quiet
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Find first match only per file</para>
    /// <para>Stop at the first match in each file for efficient file listing.</para>
    /// <code>
    /// Find-Item "*.cs" -Content "class.*Controller" -List
    ///
    /// # Short form:
    /// l *.cs -mc "class.*Controller" -List
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Literal string matching</para>
    /// <para>Search for exact text without regex interpretation using SimpleMatch.</para>
    /// <code>
    /// Find-Item "*.txt" -Content "$variable[0]" -SimpleMatch
    ///
    /// # Short form:
    /// l *.txt -mc "$variable[0]" -SimpleMatch
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Find files NOT containing pattern</para>
    /// <para>Use NotMatch to find files that don't contain the specified pattern.</para>
    /// <code>
    /// Find-Item "*.js" -Content "console\.log" -NotMatch
    ///
    /// # Short form:
    /// l *.js -mc "console\.log" -NotMatch
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Specify file encoding</para>
    /// <para>Search files with specific encoding for accurate text processing.</para>
    /// <code>
    /// Find-Item "*.txt" -Content "café" -Encoding UTF8
    ///
    /// # Short form:
    /// l *.txt -mc "café" -Encoding UTF8
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Cultural text comparison</para>
    /// <para>Use culture-specific matching with SimpleMatch for international text.</para>
    /// <code>
    /// Find-Item "*.txt" -Content "Müller" -SimpleMatch -Culture "de-DE"
    ///
    /// # Short form:
    /// l *.txt -mc "Müller" -SimpleMatch -Culture "de-DE"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Complex content search with file filters</para>
    /// <para>Combine file size, date, and content filters for precise searches.</para>
    /// <code>
    /// Find-Item "*.log" -Content "exception" -MinFileSize 1024 -ModifiedAfter "2025-01-01" -MaxRecursionDepth 3
    ///
    /// # Short form:
    /// l *.log -mc "exception" -minsize 1024 -after "2025-01-01" -maxdepth 3
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
        [Alias("like", "l", "Path", "LiteralPath", "Query", "SearchMask", "Include")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        public string[] Name { get; set; }

        /// <summary>
        /// <para type="description">File name or pattern to search for from pipeline input. Default is '*'</para>
        /// </summary>
        [Parameter(Mandatory = false, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = "File name or pattern to search for. Default is '*'")]
        [Alias("FullName")]
        [SupportsWildcards()]
        public string Input { get; set; }

        /// <summary>
        /// <para type="description">Regular expression pattern to search within file contents</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Regular expression pattern to search within content")]
        [Alias("mc", "matchcontent", "regex", "Pattern")]
        [ValidateNotNull()]
        [SupportsWildcards()]
        public string[] Content { get; set; } = new string[1] { ".*" };

        /// <summary>
        /// <para type="description">Base path for resolving relative paths in output</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = false, HelpMessage = "Base path for resolving relative paths in output")]
        [Alias("base")]
        [ValidateNotNullOrEmpty()]
        public string RelativeBasePath { get; set; } = ".\\";

        /// <summary>
        /// <para type="description">Only output files belonging to selected categories</para>
        /// </summary>
        [Parameter(Mandatory = false)]
        [Alias("filetype")]
        [ValidateSet(
            "Pictures",
            "Videos",
            "Music",
            "Documents",
            "Spreadsheets",
            "Presentations",
            "Archives",
            "Installers",
            "Executables",
            "Databases",
            "DesignFiles",
            "Ebooks",
            "Subtitles",
            "Fonts",
            "EmailFiles",
            "3DModels",
            "GameAssets",
            "MedicalFiles",
            "FinancialFiles",
            "LegalFiles",
            "SourceCode",
            "Scripts",
            "MarkupAndData",
            "Configuration",
            "Logs",
            "TextFiles",
            "WebFiles",
            "MusicLyricsAndChords",
            "CreativeWriting",
            "Recipes",
            "ResearchFiles"
        )]
        public string[] Category { get; set; }

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
        [Parameter(Mandatory = false, HelpMessage = "Search for directories only")]
        [Alias("dir")]
        public SwitchParameter Directory { get; set; }

        /// <summary>
        /// <para type="description">Include both files and directories</para>
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Include both files and directories")]
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
        /// <para type="description">Optional: search specific drives</para>
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Optional: search specific drives")]
        public char[] DriveLetter { get; set; } = Array.Empty<char>();

        /// <summary>
        /// <para type="description">Optional: search specific base folders combined with provided Names</para>
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Optional: search specific directories")]
        public string[] Root { get; set; } = Array.Empty<string>();

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
        [Alias("nl", "ForceUnattenedMode")]
        public SwitchParameter NoLinks { get; set; }

        /// <summary>Gets or sets the case-sensitivity for files and directories.
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Gets or sets the case-sensitivity for files and directories")]
        [Alias("casing", "CaseSearchMaskMatching ")]
        public System.IO.MatchCasing CaseNameMatching { get; set; } = System.IO.MatchCasing.PlatformDefault;

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
        public string[] Exclude { get; set; } = new string[1] { "*\\.git\\*" };

        /// <summary>
        /// <para type="description">Indicates that the cmdlet searches for more than one match in each line of text. Without this parameter, Select-String finds only the first match in each line of text.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Indicates that the cmdlet searches for more than one match in each line of text. Without this parameter, Select-String finds only the first match in each line of text.")]
        public SwitchParameter AllMatches { get; set; }

        /// <summary>
        /// <para type="description">Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.")]
        public SwitchParameter CaseSensitive { get; set; }

        /// <summary>
        /// <para type="description">Captures the specified number of lines before and after the line that matches the pattern.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Captures the specified number of lines before and after the line that matches the pattern.")]
        public int[] Context { get; set; } = null;

        /// <summary>
        /// <para type="description">Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).")]
        public string Culture { get; set; }

        /// <summary>
        /// <para type="description">Specifies the type of encoding for the target file. The default value is utf8NoBOM.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Specifies the type of encoding for the target file. Supports Select-String compatible values and extended .NET encodings.")]
        [ValidateSet("ASCII", "ANSI", "BigEndianUnicode", "BigEndianUTF32", "OEM", "Unicode", "UTF7", "UTF8", "UTF8BOM", "UTF8NoBOM", "UTF32", "Default")]
        public string Encoding { get; set; } = "UTF8NoBOM";

        /// <summary>
        /// <para type="description">Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.")]
        public SwitchParameter List { get; set; }

        /// <summary>
        /// <para type="description">
        /// By default, Select-String highlights the string that matches the pattern you
        /// searched for with the Pattern parameter. The NoEmphasis parameter disables
        /// the highlighting. The emphasis uses negative colors based on your PowerShell
        /// background and text colors. For example, if your PowerShell colors are a
        /// black background with white text, the emphasis is a white background with
        /// black text.
        /// </para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Disables highlighting of matching strings in output.")]
        public SwitchParameter NoEmphasis { get; set; }

        /// <summary>
        /// <para type="description">The NotMatch parameter finds text that doesn't match the specified pattern.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "The NotMatch parameter finds text that doesn't match the specified pattern.")]
        public SwitchParameter NotMatch { get; set; }

        /// <summary>
        /// <para type="description">Indicates that the cmdlet returns a simple response instead of a MatchInfo object. The returned value is $true if the pattern is found or $null if the pattern is not found.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Indicates that the cmdlet returns a simple response instead of a MatchInfo object. The returned value is $true if the pattern is found or $null if the pattern is not found.")]
        [Alias("NoMatchOutput")]
        public SwitchParameter Quiet { get; set; }

        /// <summary>
        /// <para type="description">Causes the cmdlet to output only the matching strings, rather than MatchInfo objects. This is the results in behavior that's the most similar to the Unix grep or Windows findstr.exe commands.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Causes the cmdlet to output only the matching strings, rather than MatchInfo objects. This is the results in behavior that's the most similar to the Unix grep or Windows findstr.exe commands.")]
        public SwitchParameter Raw { get; set; }

        /// <summary>
        /// <para type="description">Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.</para>
        /// </summary>
        [Parameter(Mandatory = false, ParameterSetName = "WithPattern", HelpMessage = "Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.")]
        public SwitchParameter SimpleMatch { get; set; }

        // Cmdlet lifecycle methods
        protected override void BeginProcessing()
        {
            // set up verbose logging based on user preference
            InitializeVerboseOutput();

            // configure buffering for large file processing
            InitializeBufferingConfiguration();

            // set up parallelism based on user input or defaults
            InitializeParallelismConfiguration();

            // detect if running in unattended mode for output formatting
            UnattendedMode = NoLinks.IsPresent || UnattendedModeHelper.IsUnattendedMode(MyInvocation);

            // prepare dictionary to track visited nodes for loop prevention
            InitializeVisitedNodes();

            // prepare wildcard matching for exclusions
            InitializeWildcardMatcher();

            // set up exclusion patterns for files and directories
            InitializeExcludePatterns();

            // determine current working directory for relative paths
            InitializeCurrentDirectory();

            // resolve base path for relative output
            InitializeRelativeBaseDir();

            // set up cancellation with optional timeout
            InitializeCancellationToken();

            // initialize provided names for searching
            InitializeProvidedNames();
        }

        protected override void ProcessRecord()
        {
            if (string.IsNullOrEmpty(Input)) return;

            // add to visited if new and initialize search
            if (VisitedNodes.TryAdd("start;" + Input, true))
            {
                InitializeSearchDirectory(Input);
            }
            else if (UseVerboseOutput)
            {

                // log skipping duplicate mask
                WriteWarning($"Skipping duplicate name: {Input}");
            }
        }

        protected override void EndProcessing()
        {
            // check for no params
            if (DirQueue.Count == 0)
            {
                if (UseVerboseOutput)
                {

                    // log skipping duplicate mask
                    VerboseQueue.Enqueue($"No input, adding current directory to the queue: {CurrentDirectory}\\");
                }

                InitializeSearchDirectory(CurrentDirectory + "\\");
            }

            // allow new workers to be created
            isStarted = true;

            // run the search tasks
            ProcessSearchTasks();

            // clear all queues
            EmptyQueues();
            MatchContentProcessor p; while (MatchContentProcessors.TryDequeue(out p)) ;
            GC.Collect();

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

            // restore configuration
            ThreadPool.SetMaxThreads(this.oldMaxWorkerThread, this.oldMaxCompletionPorts);

            // clean up cancellation source
            cts?.Dispose();
        }

        protected override void StopProcessing()
        {

            // trigger cancellation
            cts?.Cancel();
        }
    }
}