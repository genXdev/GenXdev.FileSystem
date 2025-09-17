<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.FileSystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.FileSystem?style=flat-square)](./LICENSE)

## MIT License

````text
MIT License

Copyright (c) 2025 GenXdev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
````

### FEATURES

    * ✅ Simple but agile utility for renaming text throughout a project directory,
          including file- and directory- names: Rename-InProject -> rip

    * ✅ Pretty good wrapper for robocopy, Microsoft's robuust file copy utility: Start-RoboCopy -> rc, xc
        * ✅ Folder synchronization
        * ✅ Support for extra long pathnames > 256 characters
        * ✅ Restartable mode backups
        * ✅ Support for copying and fixing security settings
        * ✅ Advanced file attribute features
        * ✅ Advanced symbolic link and junction support
        * ✅ Monitor mode (restart copying after change threshold)
        * ✅ Optimization features for LargeFiles, multithreaded copying and network compression
        * ✅ Recovery mode (copy from failing disks)

    * ✅ Find files with Find-Item -> l
        * ✅ Fast multi-threaded search: utilizes parallel and asynchronous IO processing with configurable maximum degree of parallelism (default based on CPU cores) for efficient file and directory scanning.
        * ✅ Advanced Pattern Matching: Supports wildcards (*, ?), recursive patterns like **, and complex path structures for precise file and directory queries.
        * ✅ Content Searching: Matches regular expression patterns within file contents using the -Pattern parameter, with options for case sensitivity.
        * ✅ Path Type Flexibility: Handles relative, absolute, UNC, rooted paths, and NTFS alternate data streams (ADS) with optional content search in streams.
        * ✅ Multi-Drive Support: Searches across all drives with -AllDrives or specific drives via -SearchDrives, including optical disks if specified.
        * ✅ Directory and File Filtering: Options to search directories only (-Directory), both files and directories (-FilesAndDirectories), or files with content matching.
        * ✅ Exclusion and Limits: Exclude patterns with -Exclude, set max recursion depth (-MaxRecursionDepth), file size limits (-MaxFileSize, -MinFileSize), and modified date filters (-ModifiedAfter, -ModifiedBefore).
        * ✅ Output Customization: Supports PassThru for FileInfo/DirectoryInfo objects, relative paths, hyperlinks in attended mode, or plain paths in unattended mode (use -NoLinks in case of mishaps to enforce unattended mode).
        * ✅ Performance Optimizations: Skips non-text files by default for content search (override with -IncludeNonTextFileMatching), handles long paths (>260 chars), and follows symlinks/junctions.
        * ✅ Safety Features: Timeout support (-TimeoutSeconds), ignores inaccessible items, skips system attributes by default, and prevents infinite loops with visited node tracking.

    * ✅ Delete complete directory contents with Remove-AllItems -> sdel
        * ✅ Optionally delete the root folder as well

    * ✅ Move files and directories with Move-ItemWithTracking

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
| [EnsurePester](#ensurepester) | &nbsp; | Ensures Pester testing framework is available for use. |
| [Expand-Path](#expand-path) | ep | Expands any given file reference to a full pathname. |
| [Find-DuplicateFiles](#find-duplicatefiles) | fdf | Find duplicate files across multiple directories based on configurable criteria. |
| [Find-Item](#find-item) | l | Fast multi-threaded file and directory search with optional textcontent pattern matching |
| [Invoke-Fasti](#invoke-fasti) | fasti | Extracts archive files in the current directory to their own folders and deletes the afterwards. |
| [Move-ItemWithTracking](#move-itemwithtracking) | &nbsp; | Moves files and directories while preserving filesystem links and references. |
| [Move-ToRecycleBin](#move-torecyclebin) | recycle | Moves files and directories to the Windows Recycle Bin safely. |
| [Remove-AllItems](#remove-allitems) | sdel | Recursively removes all content from a directory with advanced error handling. |
| [Remove-ItemWithFallback](#remove-itemwithfallback) | rmf | Removes files or directories with multiple fallback mechanisms for reliable deletion. |
| [Remove-OnReboot](#remove-onreboot) | &nbsp; | Marks files or directories for deletion during the next system boot. |
| [Rename-InProject](#rename-inproject) | rip | Performs text replacement throughout a project directory. |
| [ResolveInputObjectFileNames](#resolveinputobjectfilenames) | &nbsp; | &nbsp; |
| [Start-RoboCopy](#start-robocopy) | rc, xc | Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility. |
| [WriteFileOutput](#writefileoutput) | &nbsp; | &nbsp; |

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
Find-Item [[-SearchMask] <string[]>] [[-RelativeBasePath] <string>] [-Input <string>] [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives] [-SearchDrives <string[]>] [-IncludeNonTextFileMatching] [-NoLinks] [-CaseSensitivePattern] [-CaseSearchMaskMatching {PlatformDefault | CaseSensitive | CaseInsensitive}] [-SearchADSContent] [-MaxRecursionDepth <int>] [-MaxFileSize <long>] [-MinFileSize <long>] [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>] [-AttributesToSkip {None | ReadOnly | Hidden | System | Directory | Archive | Device | Normal | Temporary | SparseFile | ReparsePoint | Compressed | Offline | NotContentIndexed | Encrypted | IntegrityStream | NoScrubData}] [-Exclude <string[]>] [<CommonParameters>]  
   Find-Item [[-SearchMask] <string[]>] [[-Pattern] <string>] [[-RelativeBasePath] <string>] [-Input <string>] [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives] [-SearchDrives <string[]>] [-IncludeNonTextFileMatching] [-NoLinks] [-CaseSensitivePattern] [-CaseSearchMaskMatching {PlatformDefault | CaseSensitive | CaseInsensitive}] [-SearchADSContent] [-MaxRecursionDepth <int>] [-MaxFileSize <long>] [-MinFileSize <long>] [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>] [-AttributesToSkip {None | ReadOnly | Hidden | System | Directory | Archive | Device | Normal | Temporary | SparseFile | ReparsePoint | Compressed | Offline | NotContentIndexed | Encrypted | IntegrityStream | NoScrubData}] [-Exclude <string[]>] [<CommonParameters>]  
   Find-Item [[-SearchMask] <string[]>] [[-RelativeBasePath] <string>] [-Input <string>] [-MaxDegreeOfParallelism <int>] [-TimeoutSeconds <int>] [-AllDrives] [-Directory] [-FilesAndDirectories] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [-FollowSymlinkAndJunctions] [-IncludeOpticalDiskDrives] [-SearchDrives <string[]>] [-IncludeNonTextFileMatching] [-NoLinks] [-CaseSensitivePattern] [-CaseSearchMaskMatching {PlatformDefault | CaseSensitive | CaseInsensitive}] [-SearchADSContent] [-MaxRecursionDepth <int>] [-MaxFileSize <long>] [-MinFileSize <long>] [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>] [-AttributesToSkip {None | ReadOnly | Hidden | System | Directory | Archive | Device | Normal | Temporary | SparseFile | ReparsePoint | Compressed | Offline | NotContentIndexed | Encrypted | IntegrityStream | NoScrubData}] [-Exclude <string[]>] [<CommonParameters>] 
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
    -CaseSearchMaskMatching <MatchCasing>  
        Gets or sets the case-sensitivity for files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      casing  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -CaseSensitivePattern  
        Makes pattern matching case-sensitive. By default, pattern matching is case-insensitive.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      patternmatchcase, csp  
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
        Parameter set name           DirectoriesOnly  
        Aliases                      both  
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
    -Input <string>  
        File name or pattern to search for. Default is '*'  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
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
    -NoLinks  
        Forces unattended mode and will not generate links  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      nl  
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
        Aliases                      mc, matchcontent, regex  
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
    -SearchMask <string[]>  
        File name or pattern to search for. Default is '*'  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      like, l, Path, Query  
        Dynamic?                     false  
        Accept wildcard characters?  true  
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
Expand-Path [-FilePath] <string> [-CreateDirectory] [-CreateFile] [-DeleteExistingFile] [-ForceDrive <char>] [-FileMustExist] [-DirectoryMustExist] [<CommonParameters>] 
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
Find-DuplicateFiles [-Paths] <string[]> [[-DontCompareSize]] [[-DontCompareModifiedDate]] [<CommonParameters>] 
```` 

### PARAMETERS 
    -DontCompareModifiedDate  
        Skip last modified date comparison when grouping duplicates  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -DontCompareSize  
        Skip file size comparison when grouping duplicates  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
    -Paths <string[]>  
        One or more directory paths to search for duplicates  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
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
Invoke-Fasti [[-Password] <string>] [-ExtractOutputToo] [<CommonParameters>] 
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
Move-ItemWithTracking [-Path] <string> [-Destination] <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
Move-ToRecycleBin [-Path] <string[]> [-WhatIf] [-Confirm] [<CommonParameters>] 
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
 

##	Remove-AllItems 
```PowerShell 

   Remove-AllItems                      --> sdel  
```` 

### SYNTAX 
```PowerShell 
Remove-AllItems [-Path] <string> [[-DeleteFolder]] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
Remove-ItemWithFallback [-Path] <string> [-CountRebootDeletionAsSuccess] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
Remove-OnReboot [-Path] <String[]> [-MarkInPlace] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
Rename-InProject [[-Source] <string>] [-FindText] <string> [-ReplacementText] <string> [-CaseInsensitive] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
 

##	Start-RoboCopy 
```PowerShell 

   Start-RoboCopy                       --> rc, xc  
```` 

### SYNTAX 
```PowerShell 
Start-RoboCopy [-Source] <string> [[-DestinationDirectory] <string>] [[-Files] <string[]>] [[-Override] <string>] [-Mirror] [-Move] [-IncludeSecurity] [-SkipDirectories] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-Force] [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <string[]>] [-AttributeIncludeFilter <string>] [-AttributeExcludeFilter <string>] [-SetAttributesAfterCopy <string>] [-RemoveAttributesAfterCopy <string>] [-MinFileSize <int>] [-MaxFileSize <int>] [-MinFileAge <int>] [-MaxFileAge <int>] [-MinLastAccessAge <int>] [-MaxLastAccessAge <int>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <int>] [-MonitorModeThresholdNrOfChanges <int>] [-MonitorModeRunHoursFrom <int>] [-MonitorModeRunHoursUntil <int>] [-LogFilePath <string>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles] [-MultiThreaded] [-CompressibleContent] [-WhatIf] [-Confirm] [<CommonParameters>]  
   Start-RoboCopy [-Source] <string> [[-DestinationDirectory] <string>] [[-Files] <string[]>] [[-Override] <string>] [-Mirror] [-Move] [-IncludeSecurity] [-SkipEmptyDirectories] [-CopyOnlyDirectoryTreeStructure] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-SkipJunctions] [-CopyJunctionsAsJunctons] [-Force] [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <string[]>] [-DirectoryExcludeFilter <string[]>] [-AttributeIncludeFilter <string>] [-AttributeExcludeFilter <string>] [-SetAttributesAfterCopy <string>] [-RemoveAttributesAfterCopy <string>] [-MaxSubDirTreeLevelDepth <int>] [-MinFileSize <int>] [-MaxFileSize <int>] [-MinFileAge <int>] [-MaxFileAge <int>] [-MinLastAccessAge <int>] [-MaxLastAccessAge <int>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <int>] [-MonitorModeThresholdNrOfChanges <int>] [-MonitorModeRunHoursFrom <int>] [-MonitorModeRunHoursUntil <int>] [-LogFilePath <string>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles] [-MultiThreaded] [-CompressibleContent] [-WhatIf] [-Confirm] [<CommonParameters>] 
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
