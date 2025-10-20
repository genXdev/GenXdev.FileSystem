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
| [Copy-IdenticalParamValues](#copy-identicalparamvalues) | &nbsp; | &nbsp; |
| [EnsurePester](#ensurepester) | &nbsp; | &nbsp; |
| [Expand-Path](#expand-path) | ep | Expands any given file reference to a full pathname. |
| [Find-DuplicateFiles](#find-duplicatefiles) | fdf | Find duplicate files across multiple directories based on configurable criteria. |
| [Find-Item](#find-item) | l | Fast multi-threaded file and directory search with optional textcontent pattern matching capabilities. |
| [Invoke-Fasti](#invoke-fasti) | fasti | &nbsp; |
| [Move-ItemWithTracking](#move-itemwithtracking) | &nbsp; | Moves files and directories while preserving filesystem links and references. |
| [Move-ToRecycleBin](#move-torecyclebin) | &nbsp; | Moves files and directories to the Windows Recycle Bin safely. |
| [ReadJsonWithRetry](#readjsonwithretry) | &nbsp; | Reads JSON file with retry logic and automatic lock cleanup. |
| [Remove-AllItems](#remove-allitems) | sdel | &nbsp; |
| [Remove-ItemWithFallback](#remove-itemwithfallback) | rmf | &nbsp; |
| [Remove-OnReboot](#remove-onreboot) | &nbsp; | Marks files or directories for deletion during the next system boot. |
| [Rename-InProject](#rename-inproject) | rip | &nbsp; |
| [ResolveInputObjectFileNames](#resolveinputobjectfilenames) | &nbsp; | &nbsp; |
| [Set-FoundLocation](#set-foundlocation) | lcd | Finds the first matching file or folder and sets the location to it. |
| [Set-LocationParent](#set-locationparent) | .. | Changes the current location to the parent directory and lists its contents. |
| [Set-LocationParent2](#set-locationparent2) | ... | Navigates up two directory levels in the file system hierarchy. |
| [Set-LocationParent3](#set-locationparent3) | .... | Navigates up three directory levels in the file system hierarchy. |
| [Set-LocationParent4](#set-locationparent4) | ..... | Navigates up four directory levels in the filesystem hierarchy. |
| [Set-LocationParent5](#set-locationparent5) | ...... | Navigates up five directory levels in the file system hierarchy. |
| [Start-RoboCopy](#start-robocopy) | rc, xc | &nbsp; |
| [WriteFileOutput](#writefileoutput) | &nbsp; | &nbsp; |
| [WriteJsonAtomic](#writejsonatomic) | &nbsp; | &nbsp; |

<br/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/> 

##	Confirm-InstallationConsent 
```PowerShell 

   Confirm-InstallationConsent  
``` 

### SYNTAX 
```PowerShell 
Confirm-InstallationConsent [-ApplicationName] <string>
    [-Source] <string> [-Description <string>] [-Publisher
    <string>] [-ForceConsent]
    [-ConsentToThirdPartySoftwareInstallation]
    [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -ApplicationName <string>  
        The name of the application or software being installed.  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ConsentToThirdPartySoftwareInstallation  
        Automatically consent to third-party software installation and set persistent flag.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Description <string>  
        Optional description of the software and its purpose.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ForceConsent  
        Force a prompt even if preference is set.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Publisher <string>  
        Optional publisher or vendor of the software.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Source <string>  
        The source of the installation (e.g., Winget, PowerShell Gallery).  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	EnsurePester 
```PowerShell 

   EnsurePester  
``` 

### SYNTAX 
```PowerShell 
EnsurePester [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Expand-Path 
```PowerShell 

   Expand-Path                          --> ep  
``` 

### SYNTAX 
```PowerShell 
Expand-Path [-FilePath] <string> [-CreateDirectory]
    [-CreateFile] [-DeleteExistingFile] [-ForceDrive <char>]
    [-FileMustExist] [-DirectoryMustExist]
    [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -CreateDirectory  
        Will create directory if it does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CreateFile  
        Will create an empty file if it does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -DeleteExistingFile  
        Will delete the file if it already exists  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -DirectoryMustExist  
        Will throw if directory does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FileMustExist  
        Will throw if file does not exist  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FilePath <string>  
        Path to expand  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ForceDrive <char>  
        Will force the use of a specific drive  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Find-DuplicateFiles 
```PowerShell 

   Find-DuplicateFiles                  --> fdf  
``` 

### SYNOPSIS 
    Find duplicate files across multiple directories based on configurable criteria.  

### SYNTAX 
```PowerShell 
Find-DuplicateFiles [[-Paths] <String[]>] [-Input <String>]
    [-DontCompareSize] [-DontCompareModifiedDate] [-Recurse]
    [<CommonParameters>] 
``` 

### DESCRIPTION 
    Recursively searches specified directories for duplicate files. Files are  
    considered duplicates if they share the same name and optionally match on size  
    and modification date. Returns groups of duplicate files for further processing.  

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -Paths <String[]>  
        Array of directory paths to recursively search for duplicate files. Accepts  
        pipeline input and wildcard paths.  
        Required?                    false  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -Input <String>  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -DontCompareSize [<SwitchParameter>]  
        When specified, file size is not used as a comparison criterion, only names  
        are matched.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -DontCompareModifiedDate [<SwitchParameter>]  
        When specified, file modification dates are not used as a comparison criterion.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -Recurse [<SwitchParameter>]  
        Recurse into subdirectories.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Invoke-Fasti 
```PowerShell 

   Invoke-Fasti                         --> fasti  
``` 

### SYNOPSIS 
    Extracts archive files in the current directory to their own folders and deletes  
    them afterwards.  

### SYNTAX 
```PowerShell 
Invoke-Fasti [[-Password] <String>] [-ExtractOutputToo]
    [<CommonParameters>] 
``` 

### DESCRIPTION 
    Automatically extracts common archive formats (zip, 7z, tar, etc.) found in the  
    current directory into individual folders named after each archive. After  
    successful extraction, the original archive files are deleted. Requires 7-Zip  
    to be installed on the system.  

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -Password <String>  
        Required?                    false  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -ExtractOutputToo [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

### NOTES 
```PowerShell 

       Supported formats: 7z, zip, rar, tar, iso and many others.  
       Requires 7-Zip installation (will attempt auto-install via winget if missing).  
   -------------------------- EXAMPLE 1 --------------------------  
   PS C:\Downloads>Invoke-Fasti  
   -------------------------- EXAMPLE 2 --------------------------  
   PS C:\Downloads>fasti  
``` 

<br/><hr/><br/>
 

##	ReadJsonWithRetry 
```PowerShell 

   ReadJsonWithRetry  
``` 

### SYNOPSIS 
    Reads JSON file with retry logic and automatic lock cleanup.  

### SYNTAX 
```PowerShell 
ReadJsonWithRetry [-FilePath] <String> [[-MaxRetries] <Int32>] [[-RetryDelayMs] <Int32>] [-AsHashtable] [<CommonParameters>] 
``` 

### DESCRIPTION 
    Attempts to read a JSON file with retry logic to handle concurrent access.  
    Implements automatic cleanup of stale lock files. Returns empty hashtable if  
    file doesn't exist.  

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -FilePath <String>  
        The path to the JSON file to read.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxRetries <Int32>  
        Maximum number of retry attempts. Defaults to 10.  
        Required?                    false  
        Position?                    2  
        Default value                10  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -RetryDelayMs <Int32>  
        Delay in milliseconds between retries. Defaults to 200.  
        Required?                    false  
        Position?                    3  
        Default value                200  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -AsHashtable [<SwitchParameter>]  
        Return the parsed JSON as a hashtable instead of PSCustomObject. Defaults to true.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Remove-AllItems 
```PowerShell 

   Remove-AllItems                      --> sdel  
``` 

### SYNOPSIS 
    Recursively removes all content from a directory with advanced error handling.  

### SYNTAX 
```PowerShell 
Remove-AllItems [-Path] <String> [[-DeleteFolder]] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
``` 

### DESCRIPTION 
    Safely removes all files and subdirectories within a specified directory using  
    a reverse-order deletion strategy to handle deep paths. Includes WhatIf support,  
    verbose logging, and fallback deletion methods for locked files.  

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -Path <String>  
        The directory path to clear. Can be relative or absolute path. Will be normalized  
        and expanded before processing.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -DeleteFolder [<SwitchParameter>]  
        When specified, also removes the root directory specified by Path after clearing  
        its contents.  
        Required?                    false  
        Position?                    2  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -WhatIf [<SwitchParameter>]  
        Shows what would happen if the cmdlet runs. The cmdlet is not run.  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -Confirm [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Remove-ItemWithFallback 
```PowerShell 

   Remove-ItemWithFallback              --> rmf  
``` 

### SYNOPSIS 
    Removes files or directories with multiple fallback mechanisms for reliable deletion.  

### SYNTAX 
```PowerShell 
Remove-ItemWithFallback [-Path] <String>
    [-CountRebootDeletionAsSuccess] [-WhatIf] [-Confirm]
    [<CommonParameters>] 
``` 

### DESCRIPTION 
    This function provides a robust way to delete files and directories by attempting  
    multiple deletion methods in sequence:  
    1. Direct deletion via System.IO methods for best performance  
    2. PowerShell provider-aware Remove-Item cmdlet as fallback  
    3. Mark for deletion on next system reboot if other methods fail  
    This ensures maximum reliability when removing items across different providers.  

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -Path <String>  
        The file or directory path to remove. Can be a filesystem path or provider path.  
        Accepts pipeline input and wildcards. Must be a valid, non-empty path.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -CountRebootDeletionAsSuccess [<SwitchParameter>]  
        If specified, the function returns $true when a file is successfully marked for deletion on reboot.  
        By default ($false), the function returns $false in this scenario.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -WhatIf [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    -Confirm [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Rename-InProject 
```PowerShell 

   Rename-InProject                     --> rip  
``` 

### SYNTAX 
```PowerShell 
Rename-InProject [[-Source] <string>] [-FindText] <string>
    [-ReplacementText] <string> [-CaseInsensitive] [-WhatIf]
    [-Confirm] [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -CaseInsensitive  
        Perform case-insensitive text replacement  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FindText <string>  
        The text to find (case sensitivity controlled by CaseInsensitive parameter)  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      find, what, from  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ReplacementText <string>  
        The text to replace matches with  
        Required?                    true  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      into, txt, to  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Source <string>  
        The directory, filepath, or directory+searchmask  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      src, s  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	ResolveInputObjectFileNames 
```PowerShell 

   ResolveInputObjectFileNames  
``` 

### SYNTAX 
```PowerShell 
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-Pattern] <string>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]
ResolveInputObjectFileNames [[-InputObject] <Object>] [[-RelativeBasePath] <string>] [-File] [-AllDrives] [-Directory] [-FilesAndDirectories] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -AllDrives  
        Search across all available drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Directory  
        Search for directories only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           DirectoriesOnly  
        Aliases                      dir  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -File  
        Return only files  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FilesAndDirectories  
        Include both files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           DirectoriesOnly  
        Aliases                      both  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -IncludeAlternateFileStreams  
        Include alternate data streams in search results  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -InputObject <Object>  
        Input object containing file names or directories  
        Required?                    false  
        Position?                    0  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           (All)  
        Aliases                      Path, FilePath, Input  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -NoRecurse  
        Do not recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -PassThru  
        Output matched items as objects  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      pt  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Pattern <string>  
        Regular expression pattern to search within content  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      mc, matchcontent  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
    -RelativeBasePath <string>  
        Base path for resolving relative paths in output  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      base  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Set-FoundLocation 
```PowerShell 

   Set-FoundLocation                    --> lcd  
``` 

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
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -AllDrives  
        Search across all available drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -AttributesToSkip <FileAttributes>  
        File attributes to skip (e.g., System, Hidden or None).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skipattr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CaseNameMatching <MatchCasing>  
        Gets or sets the case-sensitivity for files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      casing, CaseSearchMaskMatching  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CaseSensitive  
        Indicates that the cmdlet matches are case-sensitive. By default, matches aren't case-sensitive.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Category <string[]>  
        Only output files belonging to selected categories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      filetype  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Content <string[]>  
        Regular expression pattern to search within file contents  
        Required?                    false  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      mc, matchcontent, regex, Pattern  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
    -Culture <string>  
        Specifies a culture name to match the specified pattern. The Culture parameter must be used with the SimpleMatch parameter. The default behavior uses the culture of the current PowerShell runspace (session).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -DirectoriesAndFiles  
        Include filename matching and change to folder of first found file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      both, FilesAndDirectories  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -DriveLetter <char[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Encoding <string>  
        Specifies the type of encoding for the target file. The default value is utf8NoBOM.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ExactMatch  
        When set, only exact name matches are considered. By default, wildcard matching is used unless the Name contains wildcard characters.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Exclude <string[]>  
        Exclude files or directories matching these wildcard patterns (e.g., *.tmp, *\\bin\\*).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      skiplike  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -File  
        Search for filenames only and change to folder of first found file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      filename  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FollowSymlinkAndJunctions  
        Follow symlinks and junctions during directory traversal  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      symlinks, sl  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -IncludeAlternateFileStreams  
        Include alternate data streams in search results  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -IncludeNonTextFileMatching  
        Include non-text files (binaries, images, etc.) when searching file contents  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      binary  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -IncludeOpticalDiskDrives  
        Include optical disk drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -InputObject <Object>  
        File name or pattern to search for from pipeline input. Default is '*'  
        Required?                    true  
        Position?                    Named  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Parameter set name           InputObject  
        Aliases                      FullName  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
    -MaxDegreeOfParallelism <int>  
        Maximum degree of parallelism for directory tasks  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      threads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxFileSize <long>  
        Maximum file size in bytes to include in results. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxlength, maxsize  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxRecursionDepth <int>  
        Maximum recursion depth for directory traversal. 0 means unlimited.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      md, depth, maxdepth  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MinFileSize <long>  
        Minimum file size in bytes to include in results. 0 means no minimum.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      minsize, minlength  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ModifiedAfter <datetime>  
        Only include files modified after this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      ma, after  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ModifiedBefore <datetime>  
        Only include files modified before this date/time (UTC).  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      before, mb  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Name <string>  
        File name or pattern to search for.  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      like, Path, LiteralPath, Query, SearchMask, Include  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
    -NoRecurse  
        Do not recurse into subdirectories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      nr  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -NotMatch  
        The NotMatch parameter finds text that doesn't match the specified pattern.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Push  
        Use Push-Location instead of Set-Location and push the location onto the location stack  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Root <string[]>  
        Optional: search specific base folders combined with provided Names  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SearchADSContent  
        When set, performs content search within alternate data streams (ADS). When not set, outputs ADS file info without searching their content.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      sads  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SearchDrives <string[]>  
        Optional: search specific drives  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      drives  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SimpleMatch  
        Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, Select-String searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           WithPattern  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -TimeoutSeconds <int>  
        Optional: cancellation timeout in seconds  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      maxseconds  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Start-RoboCopy 
```PowerShell 

   Start-RoboCopy                       --> rc, xc  
``` 

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
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -AttributeExcludeFilter <string>  
        Exclude files that have any of these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -AttributeIncludeFilter <string>  
        Copy only files that have all these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CompressibleContent  
        If applicable use compression when copying files between servers to safe bandwidth and time  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Confirm  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      cf  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CopyJunctionsAsJunctons  
        Instead of copying the content where junctions point to, copy the junctions themselves  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CopyOnlyDirectoryTreeStructure  
        Create directory tree only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CopyOnlyDirectoryTreeStructureAndEmptyFiles  
        Create directory tree and zero-length files only  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -CopySymbolicLinksAsLinks  
        Instead of copying the content where symbolic links point to, copy the links themselves  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
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
``` 
```yaml 
    -DirectoryExcludeFilter <string[]>  
        Exclude any directories that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
    -FileExcludeFilter <string[]>  
        Exclude any files that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  true  
``` 
```yaml 
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
``` 
```yaml 
    -Force  
        Will copy all files even if they are older then the ones in the destination  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -IncludeSecurity  
        Will also copy ownership, security descriptors and auditing information of files and directories  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -LargeFiles  
        Enables optimization for copying large files  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -LogAllFileNames  
        Include all scanned file names in output, even skipped onces  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -LogDirectoryNames  
        Include all scanned directory names in output  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -LogFilePath <string>  
        If specified, logging will also be done to specified file  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -LogfileOverwrite  
        Do not append to the specified logfile, but overwrite instead  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxFileAge <int>  
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxFileSize <int>  
        Skip files that are larger then n bytes  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxLastAccessAge <int>  
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxSubDirTreeLevelDepth <int>  
        Only copy the top n levels of the source directory tree  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MinFileAge <int>  
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MinFileSize <int>  
        Skip files that are not at least n bytes in size  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MinLastAccessAge <int>  
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Mirror  
        Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MonitorMode  
        Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MonitorModeRunHoursFrom <int>  
        Run hours - times when new copies may be started, start-time, range 0000:2359  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MonitorModeRunHoursUntil <int>  
        Run hours - times when new copies may be started, end-time, range 0000:2359  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MonitorModeThresholdMinutes <int>  
        Run again in n minutes Time, if changed  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MonitorModeThresholdNrOfChanges <int>  
        Run again when more then n changes seen  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Move  
        Will move instead of copy all files from source to destination  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MultiThreaded  
        Optimize performance by doing multithreaded copying  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Override <string>  
        Overrides, Removes, or Adds any specified robocopy parameter.  
        Usage:  
        Add or replace parameter:  
``` 
```yaml 
            -Override /SwitchWithValue:'SomeValue'  
``` 
```yaml 
            -Override /Switch  
        Remove parameter:  
``` 
```yaml 
            -Override -/Switch  
        Multiple overrides:  
``` 
```yaml 
            -Override "/ReplaceThisSwitchWithValue:'SomeValue' -/RemoveThisSwitch /AddThisSwitch"  
        Required?                    false  
        Position?                    3  
        Accept pipeline input?       true (FromRemainingArguments)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -RecoveryMode  
        Will shortly pause and retry when I/O errors occur during copying  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -RemoveAttributesAfterCopy <string>  
        Will remove the given attributes from copied files [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -ResetArchiveAttributeAfterSelection  
        In addition of copying only files that have the archive attribute set, will then reset this attribute on the source  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SetAttributesAfterCopy <string>  
        Will set the given attributes to copied files [RASHCNETO]  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipAllSymbolicLinks  
        Do not copy symbolic links, junctions or the content they point to  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipDirectories  
        Copies only files from source and skips sub-directories (no recurse)  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           Default  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipEmptyDirectories  
        Does not copy directories if they would be empty  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipFilesWithoutArchiveAttribute  
        Copies only files that have the archive attribute set  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipJunctions  
        Do not copy directory junctions (symbolic link for a folder) or the content they point to  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           SkipDirectories  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -SkipSymbolicFileLinks  
        Do not copy file symbolic links but do follow directory junctions  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Source <string>  
        The directory, filepath, or directory+searchmask  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Unicode  
        Output status as UNICODE  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -WhatIf  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      wi  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	WriteFileOutput 
```PowerShell 

   WriteFileOutput  
``` 

### SYNTAX 
```PowerShell 
WriteFileOutput [-CallerInvocation] <Object> [-Input] <Object> [-Prefix <string>] [-RelativeBasePath <string>] [-FullPaths] [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -CallerInvocation <Object>  
        The invocation information from the calling function  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       true (ByValue)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FullPaths  
        Forces output to use full absolute paths instead of relative paths  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Input <Object>  
        The input object to process, which can be a file path or object  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       true (ByValue)  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -Prefix <string>  
        An optional string prefix to prepend to the output display for additional context  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -RelativeBasePath <string>  
        Base path for generating relative file paths in output  
        Required?                    false  
        Position?                    Named  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	WriteJsonAtomic 
```PowerShell 

   WriteJsonAtomic  
``` 

### SYNTAX 
```PowerShell 
WriteJsonAtomic [-FilePath] <string> [-Data] <hashtable> [[-MaxRetries] <int>] [[-RetryDelayMs] <int>] [<CommonParameters>] 
``` 

### PARAMETERS 
```yaml 
 
``` 
```yaml 
    -Data <hashtable>  
        Required?                    true  
        Position?                    1  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -FilePath <string>  
        Required?                    true  
        Position?                    0  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -MaxRetries <int>  
        Required?                    false  
        Position?                    2  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    -RetryDelayMs <int>  
        Required?                    false  
        Position?                    3  
        Accept pipeline input?       false  
        Parameter set name           (All)  
        Aliases                      None  
        Dynamic?                     false  
        Accept wildcard characters?  false  
``` 
```yaml 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   
``` 

<br/><hr/><br/>
 

##	Copy-IdenticalParamValues 
```PowerShell 

   Copy-IdenticalParamValues  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Find-Item 
```PowerShell 

   Find-Item                            --> l  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Move-ItemWithTracking 
```PowerShell 

   Move-ItemWithTracking  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Move-ToRecycleBin 
```PowerShell 

   Move-ToRecycleBin  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Remove-OnReboot 
```PowerShell 

   Remove-OnReboot  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Set-LocationParent 
```PowerShell 

   Set-LocationParent                   --> ..  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Set-LocationParent2 
```PowerShell 

   Set-LocationParent2                  --> ...  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Set-LocationParent3 
```PowerShell 

   Set-LocationParent3                  --> ....  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Set-LocationParent4 
```PowerShell 

   Set-LocationParent4                  --> .....  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
 

##	Set-LocationParent5 
```PowerShell 

   Set-LocationParent5                  --> ......  
``` 

### SYNOPSIS 

### SYNTAX 
```PowerShell 
 
``` 

### DESCRIPTION 

### PARAMETERS 
```yaml 
 
``` 

<br/><hr/><br/>
