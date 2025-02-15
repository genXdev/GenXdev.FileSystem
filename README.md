<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.FileSystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.FileSystem?style=flat-square)](./LICENSE)

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
| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | aliases&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [AssurePester](#AssurePester)                                                                                 |                                                               | This function checks if Pester module is installed. If not found, it attempts toinstall it from the PowerShell Gallery and imports it into the current session.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| [Expand-Path](#Expand-Path)                                                                                   | ep                                                            | Expands any given file reference to a full pathname, with respect to the user'scurrent directory. Can optionally assure that directories or files exist.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [Find-DuplicateFiles](#Find-DuplicateFiles)                                                                   | fdf                                                           | Takes an array of directory paths, searches each path recursively for files,then groups files by name and optionally by size and modified date. Returnsgroups containing two or more duplicate files.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| [Find-Item](#Find-Item)                                                                                       | l                                                             | Searches for file- or directory- names, optionally performs a regular expressionmatch within the content of each matched file.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [Move-ItemWithTracking](#Move-ItemWithTracking)                                                               |                                                               | Moves files and directories using the Windows MoveFileEx API with link trackingenabled. This preserves file system references, symbolic links, and helps toolslike Git track renamed files.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| [Move-ToRecycleBin](#Move-ToRecycleBin)                                                                       | recycle                                                       | Safely moves a file or directory to the recycle bin, even if it's currently inuse. Uses the Shell.Application COM object to perform the operation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| [Remove-AllItems](#Remove-AllItems)                                                                           | sdel                                                          | Removes all files and folders in the specified directory.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| [Remove-ItemWithFallback](#Remove-ItemWithFallback)                                                           | rif                                                           | Attempts to remove an item using multiple fallback methods:1. Direct .NET IO methods2. PowerShell Remove-Item cmdlet3. Mark for deletion on next reboot if other methods fail                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| [Remove-OnReboot](#Remove-OnReboot)                                                                           |                                                               | Items are renamed to a temporary filename first to handlelocked files. All moves are tracked to maintain file system links.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| [Rename-InProject](#Rename-InProject)                                                                         | rip                                                           | Performs find and replace operations across files and folders in a project.Skips common binary files and repository folders (.git, .svn).Always use -WhatIf first to validate planned changes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [Start-RoboCopy](#Start-RoboCopy)                                                                             | rc, xc                                                        | Wrapper for Microsoft's Robust Copy UtilityCopies file data from one location to another.Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command for Microsoft Windows.Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first released as part of theWindows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and Windows Server 2008.Key features- Folder synchronization- Support for extra long pathnames > 256 characters- Restartable mode backups- Support for copying and fixing security settings- Advanced file attribute features- Advanced symbolic link and junction support- Monitor mode (restart copying after change threshold)- Optimization features for LargeFiles, multithreaded copying and network compression- Recovery mode (copy from failing disks) |

<br/><hr/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/>

##	AssurePester
````PowerShell
AssurePester
````

### SYNOPSIS
    Ensures that Pester testing framework is installed and available.

### SYNTAX
````PowerShell
AssurePester [<CommonParameters>]
````

### DESCRIPTION
    This function checks if Pester module is installed. If not found, it attempts to
    install it from the PowerShell Gallery and imports it into the current session.

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
Expand-Path [-FilePath] <String> [-CreateDirectory] [-CreateFile] [-DeleteExistingFile]
[<CommonParameters>]
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
    Find duplicate files by name and properties across specified directories.

### SYNTAX
````PowerShell
Find-DuplicateFiles [-Paths] <String[]> [[-DontCompareSize]] [[-DontCompareModifiedDate]]
[<CommonParameters>]
````

### DESCRIPTION
    Takes an array of directory paths, searches each path recursively for files,
    then groups files by name and optionally by size and modified date. Returns
    groups containing two or more duplicate files.

### PARAMETERS
    -Paths <String[]>
        One or more directory paths to search for duplicate files.
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Aliases
        Accept wildcard characters?  false
    -DontCompareSize [<SwitchParameter>]
        Skip file size comparison when determining duplicates.
        Required?                    false
        Position?                    2
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -DontCompareModifiedDate [<SwitchParameter>]
        Skip last modified date comparison when determining duplicates.
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
    Searches for file- or directory- names with optionally filtering regex content matching

### SYNTAX
````PowerShell
Find-Item [[-SearchMask] <String>] [-AllDrives] [-PassThru] [<CommonParameters>]
Find-Item [[-SearchMask] <String>] [[-Pattern] <String>] [-AllDrives] [-PassThru]
[<CommonParameters>]
Find-Item [[-SearchMask] <String>] [-AllDrives] [-Directory] [-PassThru]
[<CommonParameters>]
````

### DESCRIPTION
    Searches for file- or directory- names, optionally performs a regular expression
    match within the content of each matched file.

### PARAMETERS
    -SearchMask <String>
        Specify the file name or pattern to search for. Default is "*".
        Required?                    false
        Position?                    1
        Default value                *
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -Pattern <String>
        Regular expression pattern to search within the content of files to match against.
        Default is ".*".
        Required?                    false
        Position?                    2
        Default value                .*
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -AllDrives [<SwitchParameter>]
        Search all drives.
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
    -PassThru [<SwitchParameter>]
        Pass through the objects to the pipeline.
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

### NOTES
````PowerShell
    Assuming c:\temp exists;
    'Find-Item c:\temp\'
        would search the whole content of directory 'temp' for any file or directory with
    the name 'temp'
    'Find-Item c:\temp'
        would search the whole C drive for any file or directory with the name 'temp'
    'Find-Item temp -AllDrives'
        would search the all drives for any file or directory with the name 'temp'
    so would:
        'Find-Item c:\temp -AllDrives'
-------------------------- EXAMPLE 1 --------------------------
PS C:\> # Find all files with the .txt extension in the current directory and its
subdirectories
Find-Item -SearchMask "*.txt"
# or in short
l *.txt
-------------------------- EXAMPLE 2 --------------------------
PS C:\> # Find all files with that have the word "translation" in their name
Find-Item -SearchMask "*translation*"
# or in short
l *translation*
-------------------------- EXAMPLE 3 --------------------------
PS C:\> # Find all files with that have the word "translation" in their content
Find-Item -Pattern "translation"
# or in short
l -mc translation
-------------------------- EXAMPLE 4 --------------------------
PS C:\> # Find any javascript file that tests a version string in it's code
Find-Item -SearchMask *.js -Pattern "Version == `"\d\d?\.\d\d?\.\d\d?`""
# or in short
l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""
-------------------------- EXAMPLE 5 --------------------------
PS C:\> # Find all directories in the current directory and its subdirectories
Find-Item -Directory
# or in short
l -dir
-------------------------- EXAMPLE 6 --------------------------
PS C:\> # Find all files with the .log extension in all drives
Find-Item -SearchMask "*.log" -AllDrives
# or in short
l *.log -all
-------------------------- EXAMPLE 7 --------------------------
PS C:\> # Find all files with the .config extension and search for the pattern
"connectionString" within the files
Find-Item -SearchMask "*.config" -Pattern "connectionString"
# or in short
l *.config connectionString
-------------------------- EXAMPLE 8 --------------------------
PS C:\> # Find all files with the .xml extension and pass the objects through the pipeline
Find-Item -SearchMask "*.xml" -PassThru
# or in short
l *.xml -PassThru
````

<br/><hr/><hr/><br/>

##	Move-ItemWithTracking
````PowerShell
Move-ItemWithTracking
````

### SYNOPSIS
    Moves a file or directory while maintaining file system links and references.

### SYNTAX
````PowerShell
Move-ItemWithTracking [-Path] <String> [-Destination] <String> [-Force] [-WhatIf]
[-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Moves files and directories using the Windows MoveFileEx API with link tracking
    enabled. This preserves file system references, symbolic links, and helps tools
    like Git track renamed files.

### PARAMETERS
    -Path <String>
        The source path of the file or directory to move.
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Aliases
        Accept wildcard characters?  false
    -Destination <String>
        The destination path where the item should be moved to.
        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -Force [<SwitchParameter>]
        If specified, will overwrite an existing destination file.
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
    Moves a file to the recycle bin using the Windows Shell API.

### SYNTAX
````PowerShell
Move-ToRecycleBin [-Path] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Safely moves a file or directory to the recycle bin, even if it's currently in
    use. Uses the Shell.Application COM object to perform the operation.

### PARAMETERS
    -Path <String[]>
        The path to the file or directory to move to the recycle bin.
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
    Removes all files and folders in the specified directory.

### SYNTAX
````PowerShell
Remove-AllItems [-Path] <String> [[-DeleteFolder]] [-WhatIf] [-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Removes all files and folders in the specified directory.

### PARAMETERS
    -Path <String>
        The path of the directory to clear.
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Aliases
        Accept wildcard characters?  false
    -DeleteFolder [<SwitchParameter>]
        Also delete the root folder supplied with the Path parameter.
        Required?                    false
        Position?                    2
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -WhatIf [<SwitchParameter>]
        Displays a message that describes the effect of the command, instead of executing
        the command.
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
Remove-ItemWithFallback              --> rif
````

### SYNOPSIS
    Helper function to remove an item with provider-aware fallback handling.

### SYNTAX
````PowerShell
Remove-ItemWithFallback [-Path] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Attempts to remove an item using multiple fallback methods:
    1. Direct .NET IO methods
    2. PowerShell Remove-Item cmdlet
    3. Mark for deletion on next reboot if other methods fail

### PARAMETERS
    -Path <String>
        The path to the item to remove. Supports both files and directories.
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

##	Remove-OnReboot
````PowerShell
Remove-OnReboot
````

### SYNOPSIS
    Marks a file for deletion on next system boot using Windows API.

### SYNTAX
````PowerShell
Remove-OnReboot [-Path] <String[]> [-MarkInPlace] [-WhatIf] [-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Items are renamed to a temporary filename first to handle
    locked files. All moves are tracked to maintain file system links.

### PARAMETERS
    -Path <String[]>
        The path(s) to the files or directories to mark for deletion.
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue)
        Aliases
        Accept wildcard characters?  false
    -MarkInPlace [<SwitchParameter>]
        Marks the file for deletion even if renaming it fails.
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
    Performs case-sensitive text replacement throughout a project directory.

### SYNTAX
````PowerShell
Rename-InProject [[-Source] <String>] [-FindText] <String> [-ReplacementText] <String>
[-WhatIf] [-Confirm] [<CommonParameters>]
````

### DESCRIPTION
    Performs find and replace operations across files and folders in a project.
    Skips common binary files and repository folders (.git, .svn).
    Always use -WhatIf first to validate planned changes.

### PARAMETERS
    -Source <String>
        The directory, filepath, or directory+searchmask to process.
        Required?                    false
        Position?                    1
        Default value                .\
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -FindText <String>
        The case-sensitive text to find and replace.
        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -ReplacementText <String>
        The text to replace FindText with.
        Required?                    true
        Position?                    3
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -WhatIf [<SwitchParameter>]
        Shows what would happen if the cmdlet runs.
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

##	Start-RoboCopy
````PowerShell
Start-RoboCopy                       --> rc, xc
````

### SYNOPSIS
    Wrapper for Microsoft's Robust Copy Utility
    Copies file data from one location to another.

### SYNTAX
````PowerShell
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>]
[-Mirror] [-Move] [-IncludeSecurity] [-SkipDirectories]
[-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks]
[-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-Force]
[-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection]
[-FileExcludeFilter <String[]>] [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter
<String>] [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>]
[-MinFileSize <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>]
[-MinLastAccessAge <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode]
[-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>]
[-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath
<String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode]
[-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf]
[<CommonParameters>]
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>]
[-Mirror] [-Move] [-IncludeSecurity] [-SkipEmptyDirectories]
[-CopyOnlyDirectoryTreeStructure] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles]
[-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks]
[-SkipJunctions] [-CopyJunctionsAsJunctons] [-Force] [-SkipFilesWithoutArchiveAttribute]
[-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>]
[-DirectoryExcludeFilter <String[]>] [-AttributeIncludeFilter <String>]
[-AttributeExcludeFilter <String>] [-SetAttributesAfterCopy <String>]
[-RemoveAttributesAfterCopy <String>] [-MaxSubDirTreeLevelDepth <Int32>] [-MinFileSize
<Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>]
[-MinLastAccessAge <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode]
[-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>]
[-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath
<String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode]
[-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf]
[<CommonParameters>]
````

### DESCRIPTION
    Wrapper for Microsoft's Robust Copy Utility
    Copies file data from one location to another.
    Robocopy, for "Robust File Copy", is a command-line directory and/or file replication
    command for Microsoft Windows.
    Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first
    released as part of the
    Windows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista
    and Windows Server 2008.
    Key features
    - Folder synchronization
    - Support for extra long pathnames > 256 characters
    - Restartable mode backups
    - Support for copying and fixing security settings
    - Advanced file attribute features
    - Advanced symbolic link and junction support
    - Monitor mode (restart copying after change threshold)
    - Optimization features for LargeFiles, multithreaded copying and network compression
    - Recovery mode (copy from failing disks)

### PARAMETERS
    -Source <String>
        The directory, filepath, or directory+searchmask
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
        Accept wildcard characters?  false
    -Mirror [<SwitchParameter>]
        Synchronizes the content of specified directories, will also delete any files and
        directories in the destination that do not exist in the source
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
        Will also copy ownership, security descriptors and auditing information of files and
        directories
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
        In addition of copying only files that have the archive attribute set, will then reset
        this attribute on the source
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
        Accept wildcard characters?  false
    -DirectoryExcludeFilter <String[]>
        Exclude any directories that matches any of these names/paths/wildcards
        Required?                    false
        Position?                    named
        Default value                @()
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
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
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then
        n = n days, else n = YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -MaxFileAge <Int32>
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n
        days, else n = YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -MinLastAccessAge <Int32>
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then
        n = n days, else n = YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -MaxLastAccessAge <Int32>
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n =
        n days, else n = YYYYMMDD date)
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
        Will stay active after copying, and copy additional changes after a a default threshold
        of 10 minutes
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
        If applicable use compression when copying files between servers to safe bandwidth and
        time
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
            -Override "/ReplaceThisSwitchWithValue:'SomeValue' -/RemoveThisSwitch
        /AddThisSwitch"
        Required?                    false
        Position?                    4
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -WhatIf [<SwitchParameter>]
        Displays a message that describes the effect of the command, instead of executing the
        command.
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
