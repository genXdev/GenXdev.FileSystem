<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.FileSystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.FileSystem?style=flat-square)](./LICENSE)

## APACHE 2.0 License

````text
Copyright (c) 2025 René Vaessen / GenXdev

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

````

### FEATURES

    * Simple but agile utility for renaming text throughout a project directory,
          including file- and directory- names: Rename-InProject -> rip

    * Pretty good wrapper for robocopy, Microsoft's robuust file copy utility: Start-RoboCopy -> rc, xc
        * Folder synchronization
        * Support for extra long pathnames > 256 characters
        * Restartable mode backups
        * Support for copying and fixing security settings
        * Advanced file attribute features
        * Advanced symbolic link and junction support
        * Monitor mode (restart copying after change threshold)
        * Optimization features for LargeFiles, multithreaded copying and
             network compression
        * Recovery mode (copy from failing disks)

    * Find files with Find-Item -> l
        * Fast multi-threaded search: utilizes parallel and asynchronous
              IO processing with configurable maximum degree of parallelism
              (default based on CPU cores) for efficient file and directory scanning.
        * Advanced Pattern Matching: Supports wildcards (*, ?), recursive patterns
              like **, and complex path structures for precise file and directory queries.
              **/filename will only recurse until filename is matched. multiple of these
              patterns are allowed, as long as the are preceeded with a filename or
              directoryname to match.
              This pattern parser has the power of Resolve-Path but has recursion
              features, and does only support * and ? as wildcards,
              preventing bugs with paths with [ ] brackets in them, eliminating
              the need for -LiteralPath parameter, while maintaining integrity
              for paths sections without wildcards, unlike a wildcard match on the
              whole full path.
        * Enhanced Content Searching: Comprehensive Select-String integration
              with regular expression patterns within file contents using the
              -Content parameter.
            * Large File Optimization: Handles extremely large files with smart
                  overlapping buffers and minimal heap allocation
            * Multiple Match Options: Find all matches per line (-AllMatches) or
                  just the first match per file (-List)
            * Case Sensitivity Control: Case-sensitive matching (-CaseSensitive)
                  with culture-specific options (-Culture)
            * Context Capture: Show lines before and after matches (-Context) for
                  better understanding
            * Inverse Matching: Find files that don't contain the pattern (-NotMatch)
            * Output Formats: Raw string output (-Raw), quiet boolean response (-Quiet),
                  or full MatchInfo objects
            * Pattern Types: Regular expressions (default) or simple literal string
                  matching (-SimpleMatch)
            * Encoding Support: Specify file encoding (-Encoding) for accurate text
                  processing
        * Path Type Flexibility: Handles relative, absolute, UNC, rooted paths, and
              NTFS alternate data streams (ADS) with optional content search in streams.
        * Multi-Drive Support: Searches across all drives with -AllDrives or specific
              drives via -SearchDrives, including optical disks if specified.
        * Directory and File Filtering: Options to search directories only (-Directory),
              both files and directories (-FilesAndDirectories), or files with content matching.
        * Exclusion and Limits: Exclude patterns with -Exclude, set max recursion depth
              -MaxRecursionDepth), file size limits (-MaxFileSize, -MinFileSize), and modified
              date filters (-ModifiedAfter, -ModifiedBefore).
        * Output Customization: Supports PassThru for FileInfo/DirectoryInfo objects,
              relative paths, hyperlinks in attended mode, or plain paths in unattended mode
              (use -NoLinks in case of mishaps to enforce unattended mode).
        * Performance Optimizations: Skips non-text files by default for content search
              (override with -IncludeNonTextFileMatching), handles long paths (>260 chars),
              and follows symlinks/junctions.
        * Safety Features: Timeout support (-TimeoutSeconds), ignores inaccessible items,
              skips system attributes by default, and prevents infinite loops with visited node tracking.

    * Easily change directories with Set-FoundLocation -> lcd
        * Find directories by name/wildcard
        * Supports most of Find-Items parameters, like searching in file contents to match
              the directory to change location too
        * Has autocompletion, just type the first letters and press Tab or CTRL-SPACE

    * Delete complete directory contents with Remove-AllItems -> sdel
        * Optionally delete the root folder as well

    * Move files and directories with Move-ItemWithTracking

### SYNTAX

```PowerShell
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>]
    [-Mirror] [-Move]
    [-IncludeSecurity] [-SkipDirectories]
    [-CopyOnlyDirectoryTreeStructureAndEmptyFiles]
    [-FileExcludeFilter <String[]>]
    [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks]
    [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection]
    [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter <String>]
    [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>]
    [-MinFileSize <Int32>] [-MaxFileSize <Int32>]
    [-MinFileAge <Int32>] [-MaxFileAge <Int32>]
    [-MinLastAccessAge <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode]
    [-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>]
    [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath <String>]
    [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles]
    [-MultiThreaded] [-CompressibleContent] [[-Override] <String>]
    [-Force]
    [-WhatIf] [<CommonParameters>]
```
```PowerShell
Rename-InProject [[-Source] <String>]
                 [-FindText] <String>
                 [-ReplacementText] <String>
                 [-WhatIf] [<CommonParameters>]
```

```PowerShell
Find-Item [[-Name] <string[]>] [[-RelativeBasePath]
    <string>] [-Input <string>] [-Category {Pictures |
    Videos | Music | Documents | Spreadsheets |
    Presentations | Archives | Installers | Executables |
    Databases | DesignFiles | Ebooks | Subtitles | Fonts |
    EmailFiles | 3DModels | GameAssets | MedicalFiles |
    FinancialFiles | LegalFiles | SourceCode | Scripts |
    MarkupAndData | Configuration | Logs | TextFiles |
    WebFiles | MusicLyricsAndChords | CreativeWriting |
    Recipes | ResearchFiles}] [-MaxDegreeOfParallelism
    <int>] [-TimeoutSeconds <int>] [-AllDrives] [-Directory]
    [-FilesAndDirectories] [-PassThru]
    [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-NoLinks] [-CaseNameMatching {PlatformDefault |
    CaseSensitive | CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxFileSize <long>]
    [-MinFileSize <long>] [-ModifiedAfter <datetime>]
    [-ModifiedBefore <datetime>] [-AttributesToSkip {None |
    ReadOnly | Hidden | System | Directory | Archive |
    Device | Normal | Temporary | SparseFile | ReparsePoint
    | Compressed | Offline | NotContentIndexed | Encrypted |
    IntegrityStream | NoScrubData}] [-Exclude <string[]>]
    [<CommonParameters>]

Find-Item [[-Name] <string[]>] [[-Content] <string[]>]
    [[-RelativeBasePath] <string>] [-Input <string>]
    [-Category {Pictures | Videos | Music | Documents |
    Spreadsheets | Presentations | Archives | Installers |
    Executables | Databases | DesignFiles | Ebooks |
    Subtitles | Fonts | EmailFiles | 3DModels | GameAssets |
    MedicalFiles | FinancialFiles | LegalFiles | SourceCode
    | Scripts | MarkupAndData | Configuration | Logs |
    TextFiles | WebFiles | MusicLyricsAndChords |
    CreativeWriting | Recipes | ResearchFiles}]
    [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>]
    [-AllDrives] [-Directory] [-FilesAndDirectories]
    [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-NoLinks] [-CaseNameMatching {PlatformDefault |
    CaseSensitive | CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxFileSize <long>]
    [-MinFileSize <long>] [-ModifiedAfter <datetime>]
    [-ModifiedBefore <datetime>] [-AttributesToSkip {None |
    ReadOnly | Hidden | System | Directory | Archive |
    Device | Normal | Temporary | SparseFile | ReparsePoint
    | Compressed | Offline | NotContentIndexed | Encrypted |
    IntegrityStream | NoScrubData}] [-Exclude <string[]>]
    [-AllMatches] [-CaseSensitive] [-Context <int[]>]
    [-Culture <string>] [-Encoding {ASCII | ANSI |
    BigEndianUnicode | BigEndianUTF32 | OEM | Unicode | UTF7
    | UTF8 | UTF8BOM | UTF8NoBOM | UTF32 | Default}] [-List]
    [-NoEmphasis] [-NotMatch] [-Quiet] [-Raw] [-SimpleMatch]
    [<CommonParameters>]
```

### INSTALLATION
```PowerShell
Install-Module "GenXdev.FileSystem"
Import-Module "GenXdev.FileSystem"
```
### UPDATE
```PowerShell
Update-Module
```

<br/><hr/><br/>

# Cmdlet Index
### GenXdev.FileSystem
| Command | Aliases | Description |
| :--- | :--- | :--- |
| [Confirm-InstallationConsent](#confirm-installationconsent) | &nbsp; | &nbsp; |
| [EnsurePester](#ensurepester) | &nbsp; | Ensures Pester testing framework is available for use. |
| [Expand-Path](#expand-path) | ep | Expands any given file reference to a full pathname. |
| [Find-DuplicateFiles](#find-duplicatefiles) | fdf | Find duplicate files across multiple directories based on configurable criteria. |
| [Find-Item](#find-item) | l | Fast multi-threaded file and directory search with optional textcontent pattern matching |
| [Invoke-Fasti](#invoke-fasti) | fasti | &nbsp; |
| [Move-ItemWithTracking](#move-itemwithtracking) | &nbsp; | Moves files and directories while preserving filesystem links and references. |
| [Move-ToRecycleBin](#move-torecyclebin) | recycle | Moves files and directories to the Windows Recycle Bin safely. |
| [ReadJsonWithRetry](#readjsonwithretry) | &nbsp; | Reads JSON file with retry logic and automatic lock cleanup. |
| [Remove-AllItems](#remove-allitems) | sdel | Recursively removes all content from a directory with advanced error handling. |
| [Remove-ItemWithFallback](#remove-itemwithfallback) | rmf | Removes files or directories with multiple fallback mechanisms for reliable deletion. |
| [Remove-OnReboot](#remove-onreboot) | &nbsp; | Marks files or directories for deletion during the next system boot. |
| [Rename-InProject](#rename-inproject) | rip | Performs text replacement throughout a project directory. |
| [ResolveInputObjectFileNames](#resolveinputobjectfilenames) | &nbsp; | &nbsp; |
| [Set-FoundLocation](#set-foundlocation) | lcd | Finds the first matching file or folder and sets the location to it. |
| [Set-LocationParent](#set-locationparent) | .. | Changes the current location to the parent directory and lists its contents. |
| [Set-LocationParent2](#set-locationparent2) | ... | Navigates up two directory levels in the file system hierarchy. |
| [Set-LocationParent3](#set-locationparent3) | .... | Navigates up three directory levels in the file system hierarchy. |
| [Set-LocationParent4](#set-locationparent4) | ..... | Navigates up four directory levels in the filesystem hierarchy. |
| [Set-LocationParent5](#set-locationparent5) | ...... | Navigates up five directory levels in the file system hierarchy. |
| [Start-RoboCopy](#start-robocopy) | rc, xc | Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility. |
| [WriteFileOutput](#writefileoutput) | &nbsp; | &nbsp; |
| [WriteJsonAtomic](#writejsonatomic) | &nbsp; | &nbsp; |

<br/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/> 

##	Find-Item 
```PowerShell 

   Find-Item                            --> l  
```` 

### SYNTAX 
```PowerShell 
Find-Item [[-Name] <string[]>] [[-RelativeBasePath]
    <string>] [-Input <Object>] [-Category {Pictures |
    Videos | Music | Documents | Spreadsheets |
    Presentations | Archives | Installers | Executables |
    Databases | DesignFiles | Ebooks | Subtitles | Fonts |
    EmailFiles | 3DModels | GameAssets | MedicalFiles |
    FinancialFiles | LegalFiles | SourceCode | Scripts |
    MarkupAndData | Configuration | Logs | TextFiles |
    WebFiles | MusicLyricsAndChords | CreativeWriting |
    Recipes | ResearchFiles}] [-MaxDegreeOfParallelism
    <int>] [-TimeoutSeconds <int>] [-AllDrives] [-Directory]
    [-FilesAndDirectories] [-PassThru]
    [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-NoLinks] [-CaseNameMatching {PlatformDefault |
    CaseSensitive | CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxSearchUpDepth <int>]
    [-MaxFileSize <long>] [-MinFileSize <long>]
    [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>]
    [-AttributesToSkip {None | ReadOnly | Hidden | System |
    Directory | Archive | Device | Normal | Temporary |
    SparseFile | ReparsePoint | Compressed | Offline |
    NotContentIndexed | Encrypted | IntegrityStream |
    NoScrubData}] [-Exclude <string[]>] [<CommonParameters>]
Find-Item [[-Name] <string[]>] [[-Content] <string[]>]
    [[-RelativeBasePath] <string>] [-Input <Object>]
    [-Category {Pictures | Videos | Music | Documents |
    Spreadsheets | Presentations | Archives | Installers |
    Executables | Databases | DesignFiles | Ebooks |
    Subtitles | Fonts | EmailFiles | 3DModels | GameAssets |
    MedicalFiles | FinancialFiles | LegalFiles | SourceCode
    | Scripts | MarkupAndData | Configuration | Logs |
    TextFiles | WebFiles | MusicLyricsAndChords |
    CreativeWriting | Recipes | ResearchFiles}]
    [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>]
    [-AllDrives] [-Directory] [-FilesAndDirectories]
    [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-NoLinks] [-CaseNameMatching {PlatformDefault |
    CaseSensitive | CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxSearchUpDepth <int>]
    [-MaxFileSize <long>] [-MinFileSize <long>]
    [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>]
    [-AttributesToSkip {None | ReadOnly | Hidden | System |
    Directory | Archive | Device | Normal | Temporary |
    SparseFile | ReparsePoint | Compressed | Offline |
    NotContentIndexed | Encrypted | IntegrityStream |
    NoScrubData}] [-Exclude <string[]>] [-AllMatches]
    [-CaseSensitive] [-Context <int[]>] [-Culture <string>]
    [-Encoding {ASCII | ANSI | BigEndianUnicode |
    BigEndianUTF32 | OEM | Unicode | UTF7 | UTF8 | UTF8BOM |
    UTF8NoBOM | UTF32 | Default}] [-List] [-NoEmphasis]
    [-NotMatch] [-Quiet] [-Raw] [-SimpleMatch]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -AllDrives  
        Search across all available drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -AllMatches  
        Indicates that the cmdlet searches for more than one match in each line of text. Without this parameter, Select-String finds only the first match in each line of text.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -AttributesToSkip <FileAttributes>  
        File attributes to skip (e.g., System, Hidden or None).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skipattr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CaseNameMatching <MatchCasing>  
        Gets or sets the case-sensitivity for files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      casing, CaseSearchMaskMatching   
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CaseSensitive  
        Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Category <string[]>  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      filetype  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Content <string[]>  
        Regular expression pattern to search within content  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      mc, matchcontent, regex, Pattern  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -Context <int[]>  
        Captures the specified number of lines before and after the line that matches the pattern.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Culture <string>  
        Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Directory  
        Search for directories only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      dir  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DriveLetter <char[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Encoding <string>  
        Specifies the type of encoding for the target file. Supports Select-String compatible values and extended .NET encodings.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Exclude <string[]>  
        Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\bin\*).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skiplike  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FilesAndDirectories  
        Include both files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      both, DirectoriesAndFiles  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FollowSymlinkAndJunctions  
        Follow symlinks and junctions during directory traversal  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      symlinks, sl  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeAlternateFileStreams  
        Include alternate data streams in search results  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeNonTextFileMatching  
        Include non-text files when searching file contents  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      binary  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeOpticalDiskDrives  
        Include optical disk drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Input <Object>  
        File name or pattern to search for. Default is '*'  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -List  
        Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxDegreeOfParallelism <int>  
        Maximum degree of parallelism for directory tasks  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      threads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxFileSize <long>  
        Maximum file size in bytes to include in results. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxlength, maxsize  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxRecursionDepth <int>  
        Maximum recursion depth for directory traversal. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      md, depth, maxdepth  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxSearchUpDepth <int>  
        Maximum recursion depth for continuing searching upwards the tree for relative searches, while no items are found. 0 means disabled.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxupward  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MinFileSize <long>  
        Minimum file size in bytes to include in results. 0 means no minimum.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      minsize, minlength  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ModifiedAfter <datetime>  
        Only include files modified after this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ma, after  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ModifiedBefore <datetime>  
        Only include files modified before this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      before, mb  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Name <string[]>  
        File name or pattern to search for. Default is '*'  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      like, Path, LiteralPath, Query, SearchMask, Include  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -NoEmphasis  
        Disables highlighting of matching strings in output.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -NoLinks  
        Forces unattended mode and will not generate links  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      nl, ForceUnattenedMode  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -NoRecurse  
        Do not recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      nr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -NotMatch  
        The NotMatch parameter finds text that doesn't match the specified pattern.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -PassThru  
        Output matched items as objects  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      pt  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Quiet  
        Indicates that the cmdlet returns a simple response instead of a MatchInfo object. The returned value is $true if the pattern is found or $null if the pattern is not found.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      NoMatchOutput  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Raw  
        Causes the cmdlet to output only the matching strings, rather than MatchInfo objects. This is the results in behavior that's the most similar to the Unix grep or Windows findstr.exe commands.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -RelativeBasePath <string>  
        Base path for resolving relative paths in output  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      base  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Root <string[]>  
        Optional: search specific directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SearchADSContent  
        When set, performs content search within alternate data streams (ADS). When not set, outputs ADS file info without searching their content.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      sads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SearchDrives <string[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      drives  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SimpleMatch  
        Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -TimeoutSeconds <int>  
        Optional: cancellation timeout in seconds  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxseconds  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Confirm-InstallationConsent 
```PowerShell 

   Confirm-InstallationConsent  
```` 

### SYNTAX 
```PowerShell 
Confirm-InstallationConsent [-ApplicationName] <string>
    [-Source] <string> [-Description <string>] [-Publisher
    <string>] [-ForceConsent]
    [-ConsentToThirdPartySoftwareInstallation]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -ApplicationName <string>  
        The name of the application or software being installed.  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ConsentToThirdPartySoftwareInstallation  
        Automatically consent to third-party software installation and set persistent flag.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Description <string>  
        Optional description of the software and its purpose.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ForceConsent  
        Force a prompt even if preference is set.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Publisher <string>  
        Optional publisher or vendor of the software.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Source <string>  
        The source of the installation (e.g., Winget, PowerShell Gallery).  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	EnsurePester 
```PowerShell 

   EnsurePester  
```` 

### SYNTAX 
```PowerShell 
EnsurePester [<CommonParameters>] 
```` 

### PARAMETERS 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Expand-Path 
```PowerShell 

   Expand-Path                          --> ep  
```` 

### SYNTAX 
```PowerShell 
Expand-Path [-FilePath] <string> [-CreateDirectory]
    [-CreateFile] [-DeleteExistingFile] [-ForceDrive <char>]
    [-FileMustExist] [-DirectoryMustExist]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -CreateDirectory  
        Will create directory if it does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CreateFile  
        Will create an empty file if it does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DeleteExistingFile  
        Will delete the file if it already exists  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DirectoryMustExist  
        Will throw if directory does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FileMustExist  
        Will throw if file does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FilePath <string>  
        Path to expand  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ForceDrive <char>  
        Will force the use of a specific drive  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Find-DuplicateFiles 
```PowerShell 

   Find-DuplicateFiles                  --> fdf  
```` 

### SYNTAX 
```PowerShell 
Find-DuplicateFiles [[-Paths] <string[]>] [-Input <string>]
    [-DontCompareSize] [-DontCompareModifiedDate] [-Recurse]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -DontCompareModifiedDate  
        Skip last modified date comparison when grouping duplicates  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DontCompareSize  
        Skip file size comparison when grouping duplicates  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Input <string>  
        One or more directory paths to search for duplicates  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName, Filename, Path  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Paths <string[]>  
        One or more directory paths to search for duplicates  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Recurse  
        Recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Invoke-Fasti 
```PowerShell 

   Invoke-Fasti                         --> fasti  
```` 

### SYNTAX 
```PowerShell 
Invoke-Fasti [[-Password] <string>] [-ExtractOutputToo]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -ExtractOutputToo  
        Recursively extract archives found within extracted folders  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Password <string>  
        Enter the password for the encrypted archive(s)  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Move-ItemWithTracking 
```PowerShell 

   Move-ItemWithTracking  
```` 

### SYNTAX 
```PowerShell 
Move-ItemWithTracking [-Path] <string> [-Destination]
    <string> [-Force] [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Destination <string>  
        Destination path to move to  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Force  
        Overwrite destination if it exists  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Path <string>  
        Source path of file/directory to move  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Move-ToRecycleBin 
```PowerShell 

   Move-ToRecycleBin                    --> recycle  
```` 

### SYNTAX 
```PowerShell 
Move-ToRecycleBin [-Path] <string[]> [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Path <string[]>  
        Specify the path(s) to move to the recycle bin  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	ReadJsonWithRetry 
```PowerShell 

   ReadJsonWithRetry  
```` 

### SYNOPSIS 
    Reads JSON file with retry logic and automatic lock cleanup.  

### SYNTAX 
```PowerShell 
ReadJsonWithRetry [-FilePath] <String> [[-MaxRetries] <Int32>] [[-RetryDelayMs] <Int32>] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Attempts to read a JSON file with retry logic to handle concurrent access.  
    Implements automatic cleanup of stale lock files. Returns empty hashtable if  
    file doesn't exist.  

### PARAMETERS 
    -FilePath <String>  
        The path to the JSON file to read.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MaxRetries <Int32>  
        Maximum number of retry attempts. Defaults to 10.  
        Required?                    false  
        Position?                    2  
        Default value                10  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -RetryDelayMs <Int32>  
        Delay in milliseconds between retries. Defaults to 200.  
        Required?                    false  
        Position?                    3  
        Default value                200  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Remove-AllItems 
```PowerShell 

   Remove-AllItems                      --> sdel  
```` 

### SYNTAX 
```PowerShell 
Remove-AllItems [-Path] <string> [[-DeleteFolder]] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DeleteFolder  
        Also delete the root folder supplied with the Path parameter  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Path <string>  
        The directory path to clear  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Remove-ItemWithFallback 
```PowerShell 

   Remove-ItemWithFallback              --> rmf  
```` 

### SYNTAX 
```PowerShell 
Remove-ItemWithFallback [-Path] <string>
    [-CountRebootDeletionAsSuccess] [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CountRebootDeletionAsSuccess  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Path <string>  
        The path to the item to remove  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Remove-OnReboot 
```PowerShell 

   Remove-OnReboot  
```` 

### SYNOPSIS 
    Marks files or directories for deletion during the next system boot.  

### SYNTAX 
```PowerShell 
Remove-OnReboot [-Path] <String[]> [-MarkInPlace] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    This function uses the Windows API to mark files for deletion on next boot.  
    It handles locked files by first attempting to rename them to temporary names  
    and tracks all moves to maintain file system integrity. If renaming fails,  
    the -MarkInPlace parameter can be used to mark files in their original location.  

### PARAMETERS 
    -Path <String[]>  
        One or more file or directory paths to mark for deletion. Accepts pipeline input.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue)  
        Aliases                        
        Accept wildcard characters?  false  
    -MarkInPlace [<SwitchParameter>]  
        If specified, marks files for deletion in their original location when renaming  
        fails. This is useful for locked files that cannot be renamed.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -WhatIf [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Confirm [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Rename-InProject 
```PowerShell 

   Rename-InProject                     --> rip  
```` 

### SYNTAX 
```PowerShell 
Rename-InProject [[-Source] <string>] [-FindText] <string>
    [-ReplacementText] <string> [-CaseInsensitive] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
```` 

### PARAMETERS 
    -CaseInsensitive  
        Perform case-insensitive text replacement  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FindText <string>  
        The text to find (case sensitivity controlled by CaseInsensitive parameter)  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      find, what, from  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ReplacementText <string>  
        The text to replace matches with  
        Required?                    true  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      into, txt, to  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Source <string>  
        The directory, filepath, or directory+searchmask  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      src, s  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	ResolveInputObjectFileNames 
```PowerShell 

   ResolveInputObjectFileNames  
```` 

### SYNTAX 
```PowerShell 
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-Pattern] <string>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-Directory] [-FilesAndDirectories] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>] 
```` 

### PARAMETERS 
    -AllDrives  
        Search across all available drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Directory  
        Search for directories only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           DirectoriesOnly  
        Aliases                      dir  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -File  
        Return only files  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FilesAndDirectories  
        Include both files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           DirectoriesOnly  
        Aliases                      both  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeAlternateFileStreams  
        Include alternate data streams in search results  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -InputObject <Object>  
        Input object containing file names or directories  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      Path, FilePath, Input  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -NoRecurse  
        Do not recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -PassThru  
        Output matched items as objects  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      pt  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Pattern <string>  
        Regular expression pattern to search within content  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      mc, matchcontent  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -RelativeBasePath <string>  
        Base path for resolving relative paths in output  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      base  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-FoundLocation 
```PowerShell 

   Set-FoundLocation                    --> lcd  
```` 

### SYNTAX 
```PowerShell 
Set-FoundLocation [-Name] <string> -InputObject <Object>
    [-Category {Pictures | Videos | Music | Documents |
    Spreadsheets | Presentations | Archives | Installers |
    Executables | Databases | DesignFiles | Ebooks |
    Subtitles | Fonts | EmailFiles | 3DModels | GameAssets |
    MedicalFiles | FinancialFiles | LegalFiles | SourceCode
    | Scripts | MarkupAndData | Configuration | Logs |
    TextFiles | WebFiles | MusicLyricsAndChords |
    CreativeWriting | Recipes | ResearchFiles}]
    [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>]
    [-AllDrives] [-File] [-DirectoriesAndFiles]
    [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-CaseNameMatching {PlatformDefault | CaseSensitive |
    CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxFileSize <long>]
    [-MinFileSize <long>] [-ModifiedAfter <datetime>]
    [-ModifiedBefore <datetime>] [-AttributesToSkip {None |
    ReadOnly | Hidden | System | Directory | Archive |
    Device | Normal | Temporary | SparseFile | ReparsePoint
    | Compressed | Offline | NotContentIndexed | Encrypted |
    IntegrityStream | NoScrubData}] [-Exclude <string[]>]
    [-Push] [-ExactMatch] [-WhatIf] [-Confirm]
    [<CommonParameters>]
Set-FoundLocation [-Name] <string> [[-Content] <string[]>]
    [-Category {Pictures | Videos | Music | Documents |
    Spreadsheets | Presentations | Archives | Installers |
    Executables | Databases | DesignFiles | Ebooks |
    Subtitles | Fonts | EmailFiles | 3DModels | GameAssets |
    MedicalFiles | FinancialFiles | LegalFiles | SourceCode
    | Scripts | MarkupAndData | Configuration | Logs |
    TextFiles | WebFiles | MusicLyricsAndChords |
    CreativeWriting | Recipes | ResearchFiles}]
    [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>]
    [-AllDrives] [-File] [-DirectoriesAndFiles]
    [-IncludeAlternateFileStreams] [-NoRecurse]
    [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives]
    [-SearchDrives <string[]>] [-DriveLetter <char[]>]
    [-Root <string[]>] [-IncludeNonTextFileMatching]
    [-CaseNameMatching {PlatformDefault | CaseSensitive |
    CaseInsensitive}] [-SearchADSContent]
    [-MaxRecursionDepth <int>] [-MaxFileSize <long>]
    [-MinFileSize <long>] [-ModifiedAfter <datetime>]
    [-ModifiedBefore <datetime>] [-AttributesToSkip {None |
    ReadOnly | Hidden | System | Directory | Archive |
    Device | Normal | Temporary | SparseFile | ReparsePoint
    | Compressed | Offline | NotContentIndexed | Encrypted |
    IntegrityStream | NoScrubData}] [-Exclude <string[]>]
    [-CaseSensitive] [-Culture <string>] [-Encoding {ASCII |
    ANSI | BigEndianUnicode | BigEndianUTF32 | OEM | Unicode
    | UTF7 | UTF8 | UTF8BOM | UTF8NoBOM | UTF32 | Default}]
    [-NotMatch] [-SimpleMatch] [-Push] [-ExactMatch]
    [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### PARAMETERS 
    -AllDrives  
        Search across all available drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -AttributesToSkip <FileAttributes>  
        File attributes to skip (e.g., System, Hidden or None).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skipattr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CaseNameMatching <MatchCasing>  
        Gets or sets the case-sensitivity for files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      casing, CaseSearchMaskMatching  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CaseSensitive  
        Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Category <string[]>  
        Only output files belonging to selected categories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      filetype  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Content <string[]>  
        Regular expression pattern to search within file contents  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      mc, matchcontent, regex, Pattern  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -Culture <string>  
        Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DirectoriesAndFiles  
        Include filename matching and change to folder of first found file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      both, FilesAndDirectories  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DriveLetter <char[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Encoding <string>  
        Specifies the type of encoding for the target file. The default value is utf8NoBOM.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ExactMatch  
        When set, only exact name matches are considered. By default, wildcard matching is used unless the Name contains wildcard characters.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Exclude <string[]>  
        Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\\bin\\*).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skiplike  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -File  
        Search for filenames only and change to folder of first found file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      filename  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FollowSymlinkAndJunctions  
        Follow symlinks and junctions during directory traversal  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      symlinks, sl  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeAlternateFileStreams  
        Include alternate data streams in search results  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeNonTextFileMatching  
        Include non-text files (binaries, images, etc.) when searching file contents  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      binary  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeOpticalDiskDrives  
        Include optical disk drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -InputObject <Object>  
        File name or pattern to search for from pipeline input. Default is '*'  
        Required?                    true  
        Position?                    Named  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           InputObject  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -MaxDegreeOfParallelism <int>  
        Maximum degree of parallelism for directory tasks  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      threads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxFileSize <long>  
        Maximum file size in bytes to include in results. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxlength, maxsize  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxRecursionDepth <int>  
        Maximum recursion depth for directory traversal. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      md, depth, maxdepth  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MinFileSize <long>  
        Minimum file size in bytes to include in results. 0 means no minimum.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      minsize, minlength  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ModifiedAfter <datetime>  
        Only include files modified after this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ma, after  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ModifiedBefore <datetime>  
        Only include files modified before this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      before, mb  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Name <string>  
        File name or pattern to search for.  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      like, Path, LiteralPath, Query, SearchMask, Include  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -NoRecurse  
        Do not recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      nr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -NotMatch  
        The NotMatch parameter finds text that doesn't match the specified pattern.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Push  
        Use Push-Location instead of Set-Location and push the location onto the location stack  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Root <string[]>  
        Optional: search specific base folders combined with provided Names  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SearchADSContent  
        When set, performs content search within alternate data streams (ADS). When not set, outputs ADS file info without searching their content.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      sads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SearchDrives <string[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      drives  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SimpleMatch  
        Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -TimeoutSeconds <int>  
        Optional: cancellation timeout in seconds  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxseconds  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-LocationParent 
```PowerShell 

   Set-LocationParent                   --> ..  
```` 

### SYNTAX 
```PowerShell 
Set-LocationParent [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-LocationParent2 
```PowerShell 

   Set-LocationParent2                  --> ...  
```` 

### SYNTAX 
```PowerShell 
Set-LocationParent2 [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-LocationParent3 
```PowerShell 

   Set-LocationParent3                  --> ....  
```` 

### SYNTAX 
```PowerShell 
Set-LocationParent3 [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-LocationParent4 
```PowerShell 

   Set-LocationParent4                  --> .....  
```` 

### SYNTAX 
```PowerShell 
Set-LocationParent4 [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Set-LocationParent5 
```PowerShell 

   Set-LocationParent5                  --> ......  
```` 

### SYNTAX 
```PowerShell 
Set-LocationParent5 [-WhatIf] [-Confirm]
    [<CommonParameters>] 
```` 

### PARAMETERS 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	Start-RoboCopy 
```PowerShell 

   Start-RoboCopy                       --> rc, xc  
```` 

### SYNTAX 
```PowerShell 
Start-RoboCopy [-Source] <string> [[-DestinationDirectory]
    <string>] [[-Files] <string[]>] [[-Override] <string>]
    [-Mirror] [-Move] [-IncludeSecurity] [-SkipDirectories]
    [-CopyOnlyDirectoryTreeStructureAndEmptyFiles]
    [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks]
    [-CopySymbolicLinksAsLinks] [-Force]
    [-SkipFilesWithoutArchiveAttribute]
    [-ResetArchiveAttributeAfterSelection]
    [-FileExcludeFilter <string[]>] [-AttributeIncludeFilter
    <string>] [-AttributeExcludeFilter <string>]
    [-SetAttributesAfterCopy <string>]
    [-RemoveAttributesAfterCopy <string>] [-MinFileSize
    <int>] [-MaxFileSize <int>] [-MinFileAge <int>]
    [-MaxFileAge <int>] [-MinLastAccessAge <int>]
    [-MaxLastAccessAge <int>] [-RecoveryMode] [-MonitorMode]
    [-MonitorModeThresholdMinutes <int>]
    [-MonitorModeThresholdNrOfChanges <int>]
    [-MonitorModeRunHoursFrom <int>]
    [-MonitorModeRunHoursUntil <int>] [-LogFilePath
    <string>] [-LogfileOverwrite] [-LogDirectoryNames]
    [-LogAllFileNames] [-Unicode] [-LargeFiles]
    [-MultiThreaded] [-CompressibleContent] [-WhatIf]
    [-Confirm] [<CommonParameters>]
Start-RoboCopy [-Source] <string> [[-DestinationDirectory]
    <string>] [[-Files] <string[]>] [[-Override] <string>]
    [-Mirror] [-Move] [-IncludeSecurity]
    [-SkipEmptyDirectories]
    [-CopyOnlyDirectoryTreeStructure]
    [-CopyOnlyDirectoryTreeStructureAndEmptyFiles]
    [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks]
    [-CopySymbolicLinksAsLinks] [-SkipJunctions]
    [-CopyJunctionsAsJunctons] [-Force]
    [-SkipFilesWithoutArchiveAttribute]
    [-ResetArchiveAttributeAfterSelection]
    [-FileExcludeFilter <string[]>] [-DirectoryExcludeFilter
    <string[]>] [-AttributeIncludeFilter <string>]
    [-AttributeExcludeFilter <string>]
    [-SetAttributesAfterCopy <string>]
    [-RemoveAttributesAfterCopy <string>]
    [-MaxSubDirTreeLevelDepth <int>] [-MinFileSize <int>]
    [-MaxFileSize <int>] [-MinFileAge <int>] [-MaxFileAge
    <int>] [-MinLastAccessAge <int>] [-MaxLastAccessAge
    <int>] [-RecoveryMode] [-MonitorMode]
    [-MonitorModeThresholdMinutes <int>]
    [-MonitorModeThresholdNrOfChanges <int>]
    [-MonitorModeRunHoursFrom <int>]
    [-MonitorModeRunHoursUntil <int>] [-LogFilePath
    <string>] [-LogfileOverwrite] [-LogDirectoryNames]
    [-LogAllFileNames] [-Unicode] [-LargeFiles]
    [-MultiThreaded] [-CompressibleContent] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
```` 

### PARAMETERS 
    -AttributeExcludeFilter <string>  
        Exclude files that have any of these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -AttributeIncludeFilter <string>  
        Copy only files that have all these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CompressibleContent  
        If applicable use compression when copying files between servers to safe bandwidth and time  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CopyJunctionsAsJunctons  
        Instead of copying the content where junctions point to, copy the junctions themselves  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CopyOnlyDirectoryTreeStructure  
        Create directory tree only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CopyOnlyDirectoryTreeStructureAndEmptyFiles  
        Create directory tree and zero-length files only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CopySymbolicLinksAsLinks  
        Instead of copying the content where symbolic links point to, copy the links themselves  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DestinationDirectory <string>  
        The destination directory to place the copied files and directories into.  
                    If this directory does not exist yet, all missing directories will be created.  
                    Default value = ".\"  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DirectoryExcludeFilter <string[]>  
        Exclude any directories that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -FileExcludeFilter <string[]>  
        Exclude any files that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -Files <string[]>  
        Optional searchmask for selecting the files that need to be copied.  
                    Default value = '*'  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  true  
    -Force  
        Will copy all files even if they are older then the ones in the destination  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -IncludeSecurity  
        Will also copy ownership, security descriptors and auditing information of files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -LargeFiles  
        Enables optimization for copying large files  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -LogAllFileNames  
        Include all scanned file names in output, even skipped onces  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -LogDirectoryNames  
        Include all scanned directory names in output  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -LogFilePath <string>  
        If specified, logging will also be done to specified file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -LogfileOverwrite  
        Do not append to the specified logfile, but overwrite instead  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxFileAge <int>  
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxFileSize <int>  
        Skip files that are larger then n bytes  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxLastAccessAge <int>  
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxSubDirTreeLevelDepth <int>  
        Only copy the top n levels of the source directory tree  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MinFileAge <int>  
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MinFileSize <int>  
        Skip files that are not at least n bytes in size  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MinLastAccessAge <int>  
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Mirror  
        Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MonitorMode  
        Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MonitorModeRunHoursFrom <int>  
        Run hours - times when new copies may be started, start-time, range 0000:2359  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MonitorModeRunHoursUntil <int>  
        Run hours - times when new copies may be started, end-time, range 0000:2359  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MonitorModeThresholdMinutes <int>  
        Run again in n minutes Time, if changed  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MonitorModeThresholdNrOfChanges <int>  
        Run again when more then n changes seen  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Move  
        Will move instead of copy all files from source to destination  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MultiThreaded  
        Optimize performance by doing multithreaded copying  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Override <string>  
        Overrides, Removes, or Adds any specified robocopy parameter.  
        Usage:  
        Add or replace parameter:  
            -Override /SwitchWithValue:'SomeValue'  
            -Override /Switch  
        Remove parameter:  
            -Override -/Switch  
        Multiple overrides:  
            -Override "/ReplaceThisSwitchWithValue:'SomeValue' -/RemoveThisSwitch /AddThisSwitch"  
        Required?                    false  
        Position?                    3  
        Accept pipeline input?       true (FromRemainingArguments)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -RecoveryMode  
        Will shortly pause and retry when I/O errors occur during copying  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -RemoveAttributesAfterCopy <string>  
        Will remove the given attributes from copied files [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -ResetArchiveAttributeAfterSelection  
        In addition of copying only files that have the archive attribute set, will then reset this attribute on the source  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SetAttributesAfterCopy <string>  
        Will set the given attributes to copied files [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipAllSymbolicLinks  
        Do not copy symbolic links, junctions or the content they point to  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipDirectories  
        Copies only files from source and skips sub-directories (no recurse)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           Default  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipEmptyDirectories  
        Does not copy directories if they would be empty  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipFilesWithoutArchiveAttribute  
        Copies only files that have the archive attribute set  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipJunctions  
        Do not copy directory junctions (symbolic link for a folder) or the content they point to  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -SkipSymbolicFileLinks  
        Do not copy file symbolic links but do follow directory junctions  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Source <string>  
        The directory, filepath, or directory+searchmask  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Unicode  
        Output status as UNICODE  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	WriteFileOutput 
```PowerShell 

   WriteFileOutput  
```` 

### SYNTAX 
```PowerShell 
WriteFileOutput [-CallerInvocation] <Object> [-Input] <Object> [-Prefix <string>] [-RelativeBasePath <string>] [-FullPaths] [<CommonParameters>] 
```` 

### PARAMETERS 
    -CallerInvocation <Object>  
        The invocation information from the calling function  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FullPaths  
        Forces output to use full absolute paths instead of relative paths  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Input <Object>  
        The input object to process, which can be a file path or object  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       true (ByValue)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Prefix <string>  
        An optional string prefix to prepend to the output display for additional context  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -RelativeBasePath <string>  
        Base path for generating relative file paths in output  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
 

##	WriteJsonAtomic 
```PowerShell 

   WriteJsonAtomic  
```` 

### SYNTAX 
```PowerShell 
WriteJsonAtomic [-FilePath] <string> [-Data] <hashtable> [[-MaxRetries] <int>] [[-RetryDelayMs] <int>] [<CommonParameters>] 
```` 

### PARAMETERS 
    -Data <hashtable>  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -FilePath <string>  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -MaxRetries <int>  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -RetryDelayMs <int>  
        Required?                    false  
        Position?                    3  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><br/>
