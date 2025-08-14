<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.FileSystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.FileSystem?style=flat-square)](./LICENSE)

## MIT License

```text
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
        *
    * ✅ Find files with Find-Item -> l
        * ✅ Returns relative paths by default
        * ✅ Or passes Get-ChildItem objects to the pipeline
        * ✅ Search all drives with -AllDrives
        * ✅ Accepts wildcards
        * ✅ Match files with regex patterns for searching within file content with -Pattern

    * ✅ Delete complete directory contents with Remove-AllItems -> sdel
        * ✅ Optionally delete the root folder as well

    * ✅ Move files and directories with Move-ItemWithTracking
        * ✅ Preserves file system links and references for tools like Git

### SYNTAX

````PowerShell
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
````
````PowerShell
Rename-InProject [[-Source] <String>]
                 [-FindText] <String>
                 [-ReplacementText] <String>
                 [-WhatIf] [<CommonParameters>]
````

### INSTALLATION
````PowerShell
Install-Module "GenXdev.FileSystem"
Import-Module "GenXdev.FileSystem"
````
### UPDATE
````PowerShell
Update-Module
````
<br/><hr/><hr/><br/>

# Cmdlet Index
### GenXdev.FileSystem<hr/>
### GenXdev.FileSystem
| Command | Aliases | Description |
| --- | --- | --- |
| [EnsurePester](#ensurepester) | &nbsp; | Ensures Pester testing framework is available for use. |
| [Expand-Path](#expand-path) | ep | Expands any given file reference to a full pathname. |
| [Find-DuplicateFiles](#find-duplicatefiles) | fdf | Find duplicate files across multiple directories based on configurable criteria. |
| [Find-Item](#find-item) | l | Performs advanced file and directory searches with content filtering capabilities. |
| [Invoke-Fasti](#invoke-fasti) | fasti | Extracts archive files in the current directory and deletes the originals. |
| [Move-ItemWithTracking](#move-itemwithtracking) | &nbsp; | Moves files and directories while preserving filesystem links and references. |
| [Move-ToRecycleBin](#move-torecyclebin) | recycle | Moves files and directories to the Windows Recycle Bin safely. |
| [Remove-AllItems](#remove-allitems) | sdel | Recursively removes all content from a directory with advanced error handling. |
| [Remove-ItemWithFallback](#remove-itemwithfallback) | rmf | Removes files or directories with multiple fallback mechanisms for reliable deletion. |
| [Remove-OnReboot](#remove-onreboot) | &nbsp; | Marks files or directories for deletion during the next system boot. |
| [Rename-InProject](#rename-inproject) | rip | Performs text replacement throughout a project directory. |
| [ResolveInputObjectFileNames](#resolveinputobjectfilenames) | &nbsp; |  |
| [Start-RoboCopy](#start-robocopy) | rc, xc | Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility. |

<br/><hr/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/> 

##	EnsurePester 
````PowerShell 

   EnsurePester  
```` 

### SYNOPSIS 
    Ensures Pester testing framework is available for use.  

### SYNTAX 
````PowerShell 
EnsurePester [<CommonParameters>] 
```` 

### DESCRIPTION 
    This function verifies if the Pester module is installed in the current  
    PowerShell environment. If not found, it automatically installs it from the  
    PowerShell Gallery and imports it into the current session. This ensures that  
    Pester testing capabilities are available when needed.  

### PARAMETERS 
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><hr/><br/>
 

##	Expand-Path 
````PowerShell 

   Expand-Path                          --> ep  
```` 

### SYNOPSIS 
    Expands any given file reference to a full pathname.  

### SYNTAX 
````PowerShell 
Expand-Path [-FilePath] <String> [-CreateDirectory] [-CreateFile] [-DeleteExistingFile] [-ForceDrive <Char>] [-FileMustExist] [-DirectoryMustExist] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Expands any given file reference to a full pathname, with respect to the user's  
    current directory. Can optionally assure that directories or files exist.  

### PARAMETERS 
    -FilePath <String>  
        The file path to expand to a full path.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -CreateDirectory [<SwitchParameter>]  
        Will create directory if it does not exist.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CreateFile [<SwitchParameter>]  
        Will create an empty file if it does not exist.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -DeleteExistingFile [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -ForceDrive <Char>  
        Required?                    false  
        Position?                    named  
        Default value                *  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -FileMustExist [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -DirectoryMustExist [<SwitchParameter>]  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><hr/><br/>
 

##	Find-DuplicateFiles 
````PowerShell 

   Find-DuplicateFiles                  --> fdf  
```` 

### SYNOPSIS 
    Find duplicate files across multiple directories based on configurable criteria.  

### SYNTAX 
````PowerShell 
Find-DuplicateFiles [-Paths] <String[]> [[-DontCompareSize]] [[-DontCompareModifiedDate]] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Recursively searches specified directories for duplicate files. Files are  
    considered duplicates if they share the same name and optionally match on size  
    and modification date. Returns groups of duplicate files for further processing.  

### PARAMETERS 
    -Paths <String[]>  
        Array of directory paths to recursively search for duplicate files. Accepts  
        pipeline input and wildcard paths.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -DontCompareSize [<SwitchParameter>]  
        When specified, file size is not used as a comparison criterion, only names  
        are matched.  
        Required?                    false  
        Position?                    2  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -DontCompareModifiedDate [<SwitchParameter>]  
        When specified, file modification dates are not used as a comparison criterion.  
        Required?                    false  
        Position?                    3  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><hr/><br/>
 

##	Find-Item 
````PowerShell 

   Find-Item                            --> l  
```` 

### SYNOPSIS 
    Performs advanced file and directory searches with content filtering capabilities.  

### SYNTAX 
````PowerShell 
Find-Item [[-SearchMask] <String[]>] [[-RelativeBasePath] <String>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]  
   Find-Item [[-SearchMask] <String[]>] [[-Pattern] <String>] [[-RelativeBasePath] <String>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]  
   Find-Item [[-SearchMask] <String[]>] [[-RelativeBasePath] <String>] [-AllDrives] [-Directory] [-FilesAndDirectories] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>] 
```` 

### DESCRIPTION 
    A powerful search utility that combines file/directory pattern matching with  
    content filtering. Supports recursive searches, multi-drive operations, and  
    flexible output formats. Can search by name patterns and content patterns  
    simultaneously.  

### PARAMETERS 
    -SearchMask <String[]>  
        File or directory pattern to match against. Supports wildcards (*,?).  
        Default is "*" to match everything.  
        Required?                    false  
        Position?                    1  
        Default value                *  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  true  
    -Pattern <String>  
        Regular expression to search within file contents. Only applies to files.  
        Default is ".*" to match any content.  
        Required?                    false  
        Position?                    2  
        Default value                .*  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  true  
    -RelativeBasePath <String>  
        Base directory for generating relative paths in output.  
        Only used when -PassThru is not specified.  
        Required?                    false  
        Position?                    3  
        Default value                .\  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -AllDrives [<SwitchParameter>]  
        When specified, searches across all available filesystem drives.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Directory [<SwitchParameter>]  
        Limits search to directories only, ignoring files.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -FilesAndDirectories [<SwitchParameter>]  
        Includes both files and directories in search results.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -PassThru [<SwitchParameter>]  
        Returns FileInfo/DirectoryInfo objects instead of paths.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -IncludeAlternateFileStreams [<SwitchParameter>]  
        Include alternate data streams in search results.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -NoRecurse [<SwitchParameter>]  
        Prevents recursive searching into subdirectories.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><hr/><br/>
 

##	Invoke-Fasti 
````PowerShell 

   Invoke-Fasti                         --> fasti  
```` 

### SYNOPSIS 
    Extracts archive files in the current directory and deletes the originals.  

### SYNTAX 
````PowerShell 
Invoke-Fasti [[-Password] <String>] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Automatically extracts common archive formats (zip, 7z, tar, etc.) found in the  
    current directory into individual folders named after each archive. After  
    successful extraction, the original archive files are deleted. Requires 7-Zip  
    to be installed on the system.  

### PARAMETERS 
    -Password <String>  
        Required?                    false  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

### NOTES 
````PowerShell 

       Supported formats: 7z, zip, rar, tar, iso and many others.  
       Requires 7-Zip installation (will attempt auto-install via winget if missing).  
   -------------------------- EXAMPLE 1 --------------------------  
   PS C:\Downloads>Invoke-Fasti  
   -------------------------- EXAMPLE 2 --------------------------  
   PS C:\Downloads>fasti  
```` 

<br/><hr/><hr/><br/>
 

##	Move-ItemWithTracking 
````PowerShell 

   Move-ItemWithTracking  
```` 

### SYNOPSIS 
    Moves files and directories while preserving filesystem links and references.  

### SYNTAX 
````PowerShell 
Move-ItemWithTracking [-Path] <String> [-Destination] <String> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Uses the Windows MoveFileEx API to move files and directories with link tracking  
    enabled. This ensures that filesystem references, symbolic links, and hardlinks  
    are maintained. The function is particularly useful for tools like Git that need  
    to track file renames.  

### PARAMETERS 
    -Path <String>  
        The source path of the file or directory to move. Accepts pipeline input and  
        aliases to FullName for compatibility with Get-ChildItem output.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -Destination <String>  
        The target path where the file or directory should be moved to. Must be a valid  
        filesystem path.  
        Required?                    true  
        Position?                    2  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Force [<SwitchParameter>]  
        If specified, allows overwriting an existing file or directory at the  
        destination path.  
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

<br/><hr/><hr/><br/>
 

##	Move-ToRecycleBin 
````PowerShell 

   Move-ToRecycleBin                    --> recycle  
```` 

### SYNOPSIS 
    Moves files and directories to the Windows Recycle Bin safely.  

### SYNTAX 
````PowerShell 
Move-ToRecycleBin [-Path] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Safely moves files or directories to the recycle bin using the Windows Shell API,  
    even if they are currently in use. The function uses the Shell.Application COM  
    object to perform the operation, ensuring proper recycling behavior and undo  
    capability.  

### PARAMETERS 
    -Path <String[]>  
        One or more paths to files or directories that should be moved to the recycle  
        bin. Accepts pipeline input and wildcards. The paths must exist and be  
        accessible.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
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

<br/><hr/><hr/><br/>
 

##	Remove-AllItems 
````PowerShell 

   Remove-AllItems                      --> sdel  
```` 

### SYNOPSIS 
    Recursively removes all content from a directory with advanced error handling.  

### SYNTAX 
````PowerShell 
Remove-AllItems [-Path] <String> [[-DeleteFolder]] [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Safely removes all files and subdirectories within a specified directory using  
    a reverse-order deletion strategy to handle deep paths. Includes WhatIf support,  
    verbose logging, and fallback deletion methods for locked files.  

### PARAMETERS 
    -Path <String>  
        The directory path to clear. Can be relative or absolute path. Will be normalized  
        and expanded before processing.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -DeleteFolder [<SwitchParameter>]  
        When specified, also removes the root directory specified by Path after clearing  
        its contents.  
        Required?                    false  
        Position?                    2  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -WhatIf [<SwitchParameter>]  
        Shows what would happen if the cmdlet runs. The cmdlet is not run.  
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

<br/><hr/><hr/><br/>
 

##	Remove-ItemWithFallback 
````PowerShell 

   Remove-ItemWithFallback              --> rmf  
```` 

### SYNOPSIS 
    Removes files or directories with multiple fallback mechanisms for reliable deletion.  

### SYNTAX 
````PowerShell 
Remove-ItemWithFallback [-Path] <String> [-CountRebootDeletionAsSuccess] [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    This function provides a robust way to delete files and directories by attempting  
    multiple deletion methods in sequence:  
    1. Direct deletion via System.IO methods for best performance  
    2. PowerShell provider-aware Remove-Item cmdlet as fallback  
    3. Mark for deletion on next system reboot if other methods fail  
    This ensures maximum reliability when removing items across different providers.  

### PARAMETERS 
    -Path <String>  
        The file or directory path to remove. Can be a filesystem path or provider path.  
        Accepts pipeline input and wildcards. Must be a valid, non-empty path.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -CountRebootDeletionAsSuccess [<SwitchParameter>]  
        If specified, the function returns $true when a file is successfully marked for deletion on reboot.  
        By default ($false), the function returns $false in this scenario.  
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

<br/><hr/><hr/><br/>
 

##	Remove-OnReboot 
````PowerShell 

   Remove-OnReboot  
```` 

### SYNOPSIS 
    Marks files or directories for deletion during the next system boot.  

### SYNTAX 
````PowerShell 
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

<br/><hr/><hr/><br/>
 

##	Rename-InProject 
````PowerShell 

   Rename-InProject                     --> rip  
```` 

### SYNOPSIS 
    Performs text replacement throughout a project directory.  

### SYNTAX 
````PowerShell 
Rename-InProject [[-Source] <String>] [-FindText] <String> [-ReplacementText] <String> [-CaseInsensitive] [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    Recursively searches through files and directories in a project to perform text  
    replacements. Handles both file/directory names and file contents. Skips common  
    binary files and repository folders (.git, .svn) to avoid corruption. Uses UTF-8  
    encoding without BOM for file operations. Supports both case-sensitive and  
    case-insensitive replacement modes.  

### PARAMETERS 
    -Source <String>  
        The directory, filepath, or directory+searchmask to process. Defaults to current  
        directory if not specified.  
        Required?                    false  
        Position?                    1  
        Default value                .\  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -FindText <String>  
        The text pattern to search for in filenames and content. Case sensitivity is  
        controlled by the CaseInsensitive parameter.  
        Required?                    true  
        Position?                    2  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -ReplacementText <String>  
        The text to replace all instances of FindText with.  
        Required?                    true  
        Position?                    3  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CaseInsensitive [<SwitchParameter>]  
        Perform case-insensitive text replacement. When specified, matching is done  
        without regard to case.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -WhatIf [<SwitchParameter>]  
        Shows what changes would occur without actually making them.  
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

<br/><hr/><hr/><br/>
 

##	ResolveInputObjectFileNames 
````PowerShell 

   ResolveInputObjectFileNames  
```` 

### SYNOPSIS 
    Expands input objects into file and directory names, supporting various  
    filters and output options.  

### SYNTAX 
````PowerShell 
ResolveInputObjectFileNames [[-InputObject] <Object>] [-File] [[-RelativeBasePath] <String>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]  
   ResolveInputObjectFileNames [[-InputObject] <Object>] [-File] [[-Pattern] <String>] [[-RelativeBasePath] <String>] [-AllDrives] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>]  
   ResolveInputObjectFileNames [[-InputObject] <Object>] [-File] [[-RelativeBasePath] <String>] [-AllDrives] [-Directory] [-FilesAndDirectories] [-PassThru] [-IncludeAlternateFileStreams] [-NoRecurse] [<CommonParameters>] 
```` 

### DESCRIPTION 
    This function processes input objects (files, directories, or collections)  
    and expands them into file and directory names. It supports filtering,  
    pattern matching, and can output results as objects. The function is  
    designed to work with pipeline input and provides options for recursion,  
    alternate data streams, and more.  

### PARAMETERS 
    -InputObject <Object>  
        Required?                    false  
        Position?                    1  
        Default value                  
        Accept pipeline input?       true (ByValue, ByPropertyName)  
        Aliases                        
        Accept wildcard characters?  false  
    -File [<SwitchParameter>]  
        Return only files in the output.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Pattern <String>  
        Regular expression pattern to search within content.  
        Required?                    false  
        Position?                    2  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  true  
    -RelativeBasePath <String>  
        Base path for resolving relative paths in output.  
        Required?                    false  
        Position?                    3  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -AllDrives [<SwitchParameter>]  
        Search across all available drives.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Directory [<SwitchParameter>]  
        Search for directories only.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -FilesAndDirectories [<SwitchParameter>]  
        Include both files and directories in the output.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -PassThru [<SwitchParameter>]  
        Output matched items as objects.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -IncludeAlternateFileStreams [<SwitchParameter>]  
        Include alternate data streams in search results.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -NoRecurse [<SwitchParameter>]  
        Do not recurse into subdirectories.  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    <CommonParameters>  
        This cmdlet supports the common parameters: Verbose, Debug,  
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,  
        OutBuffer, PipelineVariable, and OutVariable. For more information, see  
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).   

<br/><hr/><hr/><br/>
 

##	Start-RoboCopy 
````PowerShell 

   Start-RoboCopy                       --> rc, xc  
```` 

### SYNOPSIS 
    Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility.  

### SYNTAX 
````PowerShell 
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>] [-Mirror] [-Move] [-IncludeSecurity] [-SkipDirectories] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-Force] [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>] [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter <String>] [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>] [-MinFileSize <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>] [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath <String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]  
   Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>] [-Mirror] [-Move] [-IncludeSecurity] [-SkipEmptyDirectories] [-CopyOnlyDirectoryTreeStructure] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-SkipJunctions] [-CopyJunctionsAsJunctons] [-Force] [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>] [-DirectoryExcludeFilter <String[]>] [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter <String>] [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>] [-MaxSubDirTreeLevelDepth <Int32>] [-MinFileSize <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>] [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath <String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [-Confirm] [<CommonParameters>] 
```` 

### DESCRIPTION 
    A comprehensive wrapper for the RoboCopy command-line utility that provides  
    robust file and directory copying capabilities. This function exposes RoboCopy's  
    extensive feature set through PowerShell-friendly parameters while maintaining  
    most of its powerful functionality.  
    Key Features:  
    - Directory synchronization with mirror options  
    - Support for extra long pathnames (>256 characters)  
    - Restartable mode for resilient copying  
    - Security settings preservation  
    - Advanced file attribute handling  
    - Symbolic link and junction point management  
    - Monitor mode for continuous synchronization  
    - Performance optimization for large files  
    - Network compression support  
    - Recovery mode for failing devices  

### PARAMETERS 
    -Source <String>  
        The source directory, file path, or directory with search mask to copy from.  
        Required?                    true  
        Position?                    1  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -DestinationDirectory <String>  
        The destination directory to place the copied files and directories into.  
        If this directory does not exist yet, all missing directories will be created.  
        Default value = `.\`  
        Required?                    false  
        Position?                    2  
        Default value                ".$([System.IO.Path]::DirectorySeparatorChar)"  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Files <String[]>  
        Required?                    false  
        Position?                    3  
        Default value                @()  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  true  
    -Mirror [<SwitchParameter>]  
        Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Move [<SwitchParameter>]  
        Will move instead of copy all files from source to destination  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -IncludeSecurity [<SwitchParameter>]  
        Will also copy ownership, security descriptors and auditing information of files and directories  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipDirectories [<SwitchParameter>]  
        Copies only files from source and skips sub-directories (no recurse)  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipEmptyDirectories [<SwitchParameter>]  
        Does not copy directories if they would be empty  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CopyOnlyDirectoryTreeStructure [<SwitchParameter>]  
        Create directory tree only  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CopyOnlyDirectoryTreeStructureAndEmptyFiles [<SwitchParameter>]  
        Create directory tree and zero-length files only  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipAllSymbolicLinks [<SwitchParameter>]  
        Do not copy symbolic links, junctions or the content they point to  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipSymbolicFileLinks [<SwitchParameter>]  
        Do not copy file symbolic links but do follow directory junctions  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CopySymbolicLinksAsLinks [<SwitchParameter>]  
        Instead of copying the content where symbolic links point to, copy the links themselves  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipJunctions [<SwitchParameter>]  
        Do not copy directory junctions (symbolic link for a folder) or the content they point to  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CopyJunctionsAsJunctons [<SwitchParameter>]  
        Instead of copying the content where junctions point to, copy the junctions themselves  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Force [<SwitchParameter>]  
        Will copy all files even if they are older then the ones in the destination  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SkipFilesWithoutArchiveAttribute [<SwitchParameter>]  
        Copies only files that have the archive attribute set  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -ResetArchiveAttributeAfterSelection [<SwitchParameter>]  
        In addition of copying only files that have the archive attribute set, will then reset this attribute on the source  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -FileExcludeFilter <String[]>  
        Exclude any files that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    named  
        Default value                @()  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  true  
    -DirectoryExcludeFilter <String[]>  
        Exclude any directories that matches any of these names/paths/wildcards  
        Required?                    false  
        Position?                    named  
        Default value                @()  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  true  
    -AttributeIncludeFilter <String>  
        Copy only files that have all these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -AttributeExcludeFilter <String>  
        Exclude files that have any of these attributes set [RASHCNETO]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -SetAttributesAfterCopy <String>  
        Will set the given attributes to copied files [RASHCNETO]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -RemoveAttributesAfterCopy <String>  
        Will remove the given attributes from copied files [RASHCNETO]  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MaxSubDirTreeLevelDepth <Int32>  
        Only copy the top n levels of the source directory tree  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MinFileSize <Int32>  
        Skip files that are not at least n bytes in size  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MaxFileSize <Int32>  
        Skip files that are larger then n bytes  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MinFileAge <Int32>  
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MaxFileAge <Int32>  
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MinLastAccessAge <Int32>  
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MaxLastAccessAge <Int32>  
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -RecoveryMode [<SwitchParameter>]  
        Will shortly pause and retry when I/O errors occur during copying  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MonitorMode [<SwitchParameter>]  
        Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MonitorModeThresholdMinutes <Int32>  
        Run again in n minutes Time, if changed  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MonitorModeThresholdNrOfChanges <Int32>  
        Run again when more then n changes seen  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MonitorModeRunHoursFrom <Int32>  
        Run hours - times when new copies may be started, start-time, range 0000:2359  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MonitorModeRunHoursUntil <Int32>  
        Run hours - times when new copies may be started, end-time, range 0000:2359  
        Required?                    false  
        Position?                    named  
        Default value                -1  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -LogFilePath <String>  
        If specified, logging will also be done to specified file  
        Required?                    false  
        Position?                    named  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -LogfileOverwrite [<SwitchParameter>]  
        Do not append to the specified logfile, but overwrite instead  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -LogDirectoryNames [<SwitchParameter>]  
        Include all scanned directory names in output  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -LogAllFileNames [<SwitchParameter>]  
        Include all scanned file names in output, even skipped onces  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Unicode [<SwitchParameter>]  
        Output status as UNICODE  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -LargeFiles [<SwitchParameter>]  
        Enables optimization for copying large files  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -MultiThreaded [<SwitchParameter>]  
        Optimize performance by doing multithreaded copying  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -CompressibleContent [<SwitchParameter>]  
        If applicable use compression when copying files between servers to safe bandwidth and time  
        Required?                    false  
        Position?                    named  
        Default value                False  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -Override <String>  
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
        Position?                    4  
        Default value                  
        Accept pipeline input?       false  
        Aliases                        
        Accept wildcard characters?  false  
    -WhatIf [<SwitchParameter>]  
        Displays a message that describes the effect of the command, instead of executing the command.  
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

<br/><hr/><hr/><br/>
