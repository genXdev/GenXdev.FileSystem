<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.Filesystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.Filesystem?style=flat-square)](./LICENSE)

### FEATURES

    * ✅ Simple but agile utility for renaming text throughout a project directory,
          including file- and directory- names

    * ✅ Pretty good wrapper for robocopy, Microsoft's robuust file copy utility
        * ✅ Folder synchronization
        * ✅ Support for extra long pathnames > 256 characters
        * ✅ Restartable mode backups
        * ✅ Support for copying and fixing security settings
        * ✅ Advanced file attribute features
        * ✅ Advanced symbolic link and junction support
        * ✅ Monitor mode (restart copying after change threshold)
        * ✅ Optimization features for LargeFiles, multithreaded copying and network compression
        * ✅ Recovery mode (copy from failing disks)

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
| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | aliases&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description |
| --- | --- | --- |
| [Find-Item](#Find-Item) | fi | Finds files by searchmask on every disk available in the current session |
| [Expand-Path](#Expand-Path) | ep | Expands any given file reference to a full pathname, with respect to the users current directory |
| [Start-RoboCopy](#Start-RoboCopy) | rc, xc | Wrapper for Microsoft's Robust Copy UtilityCopies file data from one location to another.Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command for Microsoft Windows.Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first released as part of theWindows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and Windows Server 2008.Key features- Folder synchronization- Support for extra long pathnames > 256 characters- Restartable mode backups- Support for copying and fixing security settings- Advanced file attribute features- Advanced symbolic link and junction support- Monitor mode (restart copying after change threshold)- Optimization features for LargeFiles, multithreaded copying and network compression- Recovery mode (copy from failing disks) |
| [Rename-InProject](#Rename-InProject) | rip | Performs a rename action throughout a project folder. It will skip .git and .svn folders, images, archives and other common known binaries.But will rename within other files, like sourcecode, json, html, etc, AND folders and filenames!Always perform a -WhatIf operation first, to validate the actions it will take. |

<br/><hr/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/>

##	Find-Item
````PowerShell
Find-Item                            --> fi
````

### SYNOPSIS
    Finds files by searchmask

### SYNTAX
````PowerShell
Find-Item [-SearchMask] <String> [-File] [-Directory] [<CommonParameters>]
````

### DESCRIPTION
    Finds files by searchmask on every disk available in the current session

### PARAMETERS
    -SearchMask <String>
        Partial or full filename to look for
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -File [<SwitchParameter>]
        Only find files
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Directory [<SwitchParameter>]
        Only find directories
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
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
    Expands any given file reference to a full pathname

### SYNTAX
````PowerShell
Expand-Path [-FilePath] <String> [[-CreateDirectory]] [<CommonParameters>]
````

### DESCRIPTION
    Expands any given file reference to a full pathname, with respect to the users current directory

### PARAMETERS
    -FilePath <String>
        Path to expand
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CreateDirectory [<SwitchParameter>]
        Will create directory if it does not exist
        Required?                    false
        Position?                    2
        Default value                False
        Accept pipeline input?       false
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
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>] [-Mirror] [-Move]
[-IncludeSecurity] [-SkipDirectories] [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks]
[-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-Force] [-SkipFilesWithoutArchiveAttribute]
[-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>] [-AttributeIncludeFilter <String>]
[-AttributeExcludeFilter <String>] [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>]
[-MinFileSize <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge
<Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <Int32>]
[-MonitorModeThresholdNrOfChanges <Int32>] [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil
<Int32>] [-LogFilePath <String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode]
[-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [<CommonParameters>]
Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>] [-Mirror] [-Move]
[-IncludeSecurity] [-SkipEmptyDirectories] [-CopyOnlyDirectoryTreeStructure]
[-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks] [-SkipSymbolicFileLinks]
[-CopySymbolicLinksAsLinks] [-SkipJunctions] [-CopyJunctionsAsJunctons] [-Force]
[-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>]
[-DirectoryExcludeFilter <String[]>] [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter <String>]
[-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>] [-MaxSubDirTreeLevelDepth <Int32>]
[-MinFileSize <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge
<Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode] [-MonitorModeThresholdMinutes <Int32>]
[-MonitorModeThresholdNrOfChanges <Int32>] [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil
<Int32>] [-LogFilePath <String>] [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode]
[-LargeFiles] [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [<CommonParameters>]
````

### DESCRIPTION
    Wrapper for Microsoft's Robust Copy Utility
    Copies file data from one location to another.
    Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command for Microsoft
    Windows.
    Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first released as part
    of the
    Windows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and Windows
    Server 2008.
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
        Accept wildcard characters?  false
    -DestinationDirectory <String>
        The destination directory to place the copied files and directories into.
        If this directory does not exist yet, all missing directories will be created.
        Default value = `.\`
        Required?                    false
        Position?                    2
        Default value                .\
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Files <String[]>
        Required?                    false
        Position?                    3
        Default value                @()
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Mirror [<SwitchParameter>]
        Synchronizes the content of specified directories, will also delete any files and directories in the
        destination that do not exist in the source
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Move [<SwitchParameter>]
        Will move instead of copy all files from source to destination
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -IncludeSecurity [<SwitchParameter>]
        Will also copy ownership, security descriptors and auditing information of files and directories
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipDirectories [<SwitchParameter>]
        Copies only files from source and skips sub-directories (no recurse)
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipEmptyDirectories [<SwitchParameter>]
        Does not copy directories if they would be empty
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CopyOnlyDirectoryTreeStructure [<SwitchParameter>]
        Create directory tree only
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CopyOnlyDirectoryTreeStructureAndEmptyFiles [<SwitchParameter>]
        Create directory tree and zero-length files only
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipAllSymbolicLinks [<SwitchParameter>]
        Do not copy symbolic links, junctions or the content they point to
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipSymbolicFileLinks [<SwitchParameter>]
        Do not copy file symbolic links but do follow directory junctions
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CopySymbolicLinksAsLinks [<SwitchParameter>]
        Instead of copying the content where symbolic links point to, copy the links themselves
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipJunctions [<SwitchParameter>]
        Do not copy directory junctions (symbolic link for a folder) or the content they point to
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CopyJunctionsAsJunctons [<SwitchParameter>]
        Instead of copying the content where junctions point to, copy the junctions themselves
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Force [<SwitchParameter>]
        Will copy all files even if they are older then the ones in the destination
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SkipFilesWithoutArchiveAttribute [<SwitchParameter>]
        Copies only files that have the archive attribute set
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -ResetArchiveAttributeAfterSelection [<SwitchParameter>]
        In addition of copying only files that have the archive attribute set, will then reset this attribute on
        the source
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -FileExcludeFilter <String[]>
        Exclude any files that matches any of these names/paths/wildcards
        Required?                    false
        Position?                    named
        Default value                @()
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -DirectoryExcludeFilter <String[]>
        Exclude any directories that matches any of these names/paths/wildcards
        Required?                    false
        Position?                    named
        Default value                @()
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -AttributeIncludeFilter <String>
        Copy only files that have all these attributes set [RASHCNETO]
        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -AttributeExcludeFilter <String>
        Exclude files that have any of these attributes set [RASHCNETO]
        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -SetAttributesAfterCopy <String>
        Will set the given attributes to copied files [RASHCNETO]
        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -RemoveAttributesAfterCopy <String>
        Will remove the given attributes from copied files [RASHCNETO]
        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MaxSubDirTreeLevelDepth <Int32>
        Only copy the top n levels of the source directory tree
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MinFileSize <Int32>
        Skip files that are not at least n bytes in size
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MaxFileSize <Int32>
        Skip files that are larger then n bytes
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MinFileAge <Int32>
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else
        n = YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MaxFileAge <Int32>
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n =
        YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MinLastAccessAge <Int32>
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else
        n = YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MaxLastAccessAge <Int32>
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n =
        YYYYMMDD date)
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -RecoveryMode [<SwitchParameter>]
        Will shortly pause and retry when I/O errors occur during copying
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MonitorMode [<SwitchParameter>]
        Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MonitorModeThresholdMinutes <Int32>
        Run again in n minutes Time, if changed
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MonitorModeThresholdNrOfChanges <Int32>
        Run again when more then n changes seen
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MonitorModeRunHoursFrom <Int32>
        Run hours - times when new copies may be started, start-time, range 0000:2359
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MonitorModeRunHoursUntil <Int32>
        Run hours - times when new copies may be started, end-time, range 0000:2359
        Required?                    false
        Position?                    named
        Default value                -1
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -LogFilePath <String>
        If specified, logging will also be done to specified file
        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -LogfileOverwrite [<SwitchParameter>]
        Do not append to the specified logfile, but overwrite instead
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -LogDirectoryNames [<SwitchParameter>]
        Include all scanned directory names in output
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -LogAllFileNames [<SwitchParameter>]
        Include all scanned file names in output, even skipped onces
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -Unicode [<SwitchParameter>]
        Output status as UNICODE
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -LargeFiles [<SwitchParameter>]
        Enables optimization for copying large files
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -MultiThreaded [<SwitchParameter>]
        Optimize performance by doing multithreaded copying
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    -CompressibleContent [<SwitchParameter>]
        If applicable use compression when copying files between servers to safe bandwidth and time
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
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
        Accept wildcard characters?  false
    -WhatIf [<SwitchParameter>]
        Displays a message that describes the effect of the command, instead of executing the command.
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

<br/><hr/><hr/><br/>
