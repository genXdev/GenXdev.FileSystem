## Features

## Ideas

## Issues

## Todoos

<hr/>

<img src="powershell.jpg" alt="drawing" width="50%"/>

<hr/>

### NAME
    GenXdev.FileSystem
### SYNOPSIS
    A Windows PowerShell module for basic and advanced file management tasks
[![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.Filesystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![License](https://img.shields.io/github/license/renevaessen/GenXdev.Filesystem?style=flat-square)](./LICENSE)


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
Install-Module "GenXdev.FileSystem" -Force
Import-Module "GenXdev.FileSystem"
````
### UPDATE
````PowerShell
Update-Module
````
<br/><hr/><hr/><hr/><hr/><br/>
# Cmdlets
### NAME
    Start-RoboCopy

### SYNOPSIS
    Wrapper for Microsoft`s Robust Copy Utility
    Copies file data from one location to another.


### SYNTAX
````PowerShell
    Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>]
    [-Mirror] [-Move] [-IncludeSecurity] [-SkipDirectories]
    [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks]
    [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-Force]
    [-SkipFilesWithoutArchiveAttribute] [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter
    <String[]>] [-AttributeIncludeFilter <String>] [-AttributeExcludeFilter <String>]
    [-SetAttributesAfterCopy <String>] [-RemoveAttributesAfterCopy <String>] [-MinFileSize
    <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge
    <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode]
    [-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>]
    [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath <String>]
    [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles]
    [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [<CommonParameters>]

    Start-RoboCopy [-Source] <String> [[-DestinationDirectory] <String>] [[-Files] <String[]>]
    [-Mirror] [-Move] [-IncludeSecurity] [-SkipEmptyDirectories] [-CopyOnlyDirectoryTreeStructure]
    [-CopyOnlyDirectoryTreeStructureAndEmptyFiles] [-SkipAllSymbolicLinks]
    [-SkipSymbolicFileLinks] [-CopySymbolicLinksAsLinks] [-SkipJunctions]
    [-CopyJunctionsAsJunctons] [-Force] [-SkipFilesWithoutArchiveAttribute]
    [-ResetArchiveAttributeAfterSelection] [-FileExcludeFilter <String[]>]
    [-DirectoryExcludeFilter <String[]>] [-AttributeIncludeFilter <String>]
    [-AttributeExcludeFilter <String>] [-SetAttributesAfterCopy <String>]
    [-RemoveAttributesAfterCopy <String>] [-MaxSubDirTreeLevelDepth <Int32>] [-MinFileSize
    <Int32>] [-MaxFileSize <Int32>] [-MinFileAge <Int32>] [-MaxFileAge <Int32>] [-MinLastAccessAge
    <Int32>] [-MaxLastAccessAge <Int32>] [-RecoveryMode] [-MonitorMode]
    [-MonitorModeThresholdMinutes <Int32>] [-MonitorModeThresholdNrOfChanges <Int32>]
    [-MonitorModeRunHoursFrom <Int32>] [-MonitorModeRunHoursUntil <Int32>] [-LogFilePath <String>]
    [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-Unicode] [-LargeFiles]
    [-MultiThreaded] [-CompressibleContent] [[-Override] <String>] [-WhatIf] [<CommonParameters>]
````


### DESCRIPTION
    Wrapper for Microsoft`s Robust Copy Utility
    Copies file data from one location to another.

    Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command
    for Microsoft Windows.
    Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first
    released as part of the
    Windows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and
    Windows Server 2008.

### FEATURES

* ✅ Folder synchronization
* ✅ Support for extra long pathnames > 256 characters
* ✅ Restartable mode backups
* ✅ Support for copying and fixing security settings
* ✅ Advanced file attribute features
* ✅ Advanced symbolic link and junction support
* ✅ Monitor mode (restart copying after change threshold)
* ✅ Optimization features for LargeFiles, multithreaded copying and network compression
* ✅ Recovery mode (copy from failing disks)


### PARAMETERS
````
    -Source <String>
        The directory, filepath, or directory+searchmask

    -DestinationDirectory <String>
        The destination directory to place the copied files and directories into.
        If this directory does not exist yet, all missing directories will be created.
        Default value = `.\`

    -Files <String[]>

    -Mirror [<SwitchParameter>]
        Synchronizes the content of specified directories, will also delete any files and
        directories in the destination that do not exist in the source

    -Move [<SwitchParameter>]
        Will move instead of copy all files from source to destination

    -IncludeSecurity [<SwitchParameter>]
        Will also copy ownership, security descriptors and auditing information of files and
        directories

    -SkipDirectories [<SwitchParameter>]
        Copies only files from source and skips sub-directories (no recurse)

    -SkipEmptyDirectories [<SwitchParameter>]
        Does not copy directories if they would be empty

    -CopyOnlyDirectoryTreeStructure [<SwitchParameter>]
        Create directory tree only

    -CopyOnlyDirectoryTreeStructureAndEmptyFiles [<SwitchParameter>]
        Create directory tree and zero-length files only

    -SkipAllSymbolicLinks [<SwitchParameter>]
        Do NOT copy symbolic links, junctions or the content they point to

    -SkipSymbolicFileLinks [<SwitchParameter>]
        Do NOT copy file symbolic links but do follow directory junctions

    -CopySymbolicLinksAsLinks [<SwitchParameter>]
        Instead of copying the content where symbolic links point to, copy the links themselves

    -SkipJunctions [<SwitchParameter>]
        Do NOT copy directory junctions (symbolic link for a folder) or the content they point to

    -CopyJunctionsAsJunctons [<SwitchParameter>]
        Instead of copying the content where junctions point to, copy the junctions themselves

    -Force [<SwitchParameter>]
        Will copy all files even if they are older then the ones in the destination

    -SkipFilesWithoutArchiveAttribute [<SwitchParameter>]
        Copies only files that have the archive attribute set

    -ResetArchiveAttributeAfterSelection [<SwitchParameter>]
        In addition of copying only files that have the archive attribute set, will then reset
        this attribute on the source

    -FileExcludeFilter <String[]>
        Exclude any files that matches any of these names/paths/wildcards

    -DirectoryExcludeFilter <String[]>
        Exclude any directories that matches any of these names/paths/wildcards

    -AttributeIncludeFilter <String>
        Copy only files that have all these attributes set [RASHCNETO]

    -AttributeExcludeFilter <String>
        Exclude files that have any of these attributes set [RASHCNETO]

    -SetAttributesAfterCopy <String>
        Will set the given attributes to copied files [RASHCNETO]

    -RemoveAttributesAfterCopy <String>
        Will remove the given attributes from copied files [RASHCNETO]

    -MaxSubDirTreeLevelDepth <Int32>
        Only copy the top n levels of the source directory tree

    -MinFileSize <Int32>
        Skip files that are not at least n bytes in size

    -MaxFileSize <Int32>
        Skip files that are larger then n bytes

    -MinFileAge <Int32>
        Skip files that are not at least: n days old OR created before n date (if n < 1900 then n
        = n days, else n = YYYYMMDD date)

    -MaxFileAge <Int32>
        Skip files that are older then: n days OR created after n date (if n < 1900 then n = n
        days, else n = YYYYMMDD date)

    -MinLastAccessAge <Int32>
        Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n
        = n days, else n = YYYYMMDD date)

    -MaxLastAccessAge <Int32>
        Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n
        days, else n = YYYYMMDD date)

    -RecoveryMode [<SwitchParameter>]
        Will shortly pause and retry when I/O errors occur during copying

    -MonitorMode [<SwitchParameter>]
        Will stay active after copying, and copy additional changes after a a default threshold of
        10 minutes

    -MonitorModeThresholdMinutes <Int32>
        Run again in n minutes Time, if changed

    -MonitorModeThresholdNrOfChanges <Int32>
        Run again when more then n changes seen

    -MonitorModeRunHoursFrom <Int32>
        Run hours - times when new copies may be started, start-time, range 0000:2359

    -MonitorModeRunHoursUntil <Int32>
        Run hours - times when new copies may be started, end-time, range 0000:2359

    -LogFilePath <String>
        If specified, logging will also be done to specified file

    -LogfileOverwrite [<SwitchParameter>]
        Do NOT append to the specified logfile, but overwrite instead

    -LogDirectoryNames [<SwitchParameter>]
        Include all scanned directory names in output

    -LogAllFileNames [<SwitchParameter>]
        Include all scanned file names in output, even skipped onces

    -Unicode [<SwitchParameter>]
        Output status as UNICODE

    -LargeFiles [<SwitchParameter>]
        Enables optimization for copying large files

    -MultiThreaded [<SwitchParameter>]
        Optimize performance by doing multithreaded copying

    -CompressibleContent [<SwitchParameter>]
        If applicable use compression when copying files between servers to safe bandwidth and time

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

    -WhatIf [<SwitchParameter>]
        Displays a message that describes the effect of the command, instead of executing the
        command.

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    Start-RoboCopy c:\videos e:\backups\videos

    Start-RoboCopy c:\users\user\onedrive\photos\screenshots e:\backups\screenshots -Move

    Start-RoboCopy c:\users\user\onedrive e:\backups\onedrive -Mirror
````

### REMARKS
````PowerShell
    To see the examples, type: "Get-Help Start-RoboCopy -Examples"
    For more information, type: "Get-Help Start-RoboCopy -Detailed"
    For technical information, type: "Get-Help Start-RoboCopy -Full"
    For online help, type: "Get-Help Start-RoboCopy -Online"
````

### NAME
    Rename-InProject

### SYNOPSIS
    Performs a case sensitive text replacement throughout a project

### SYNTAX
````PowerShell
    Rename-InProject [[-Source] <String>] [-FindText] <String> [-ReplacementText] <String>
    [-WhatIf] [<CommonParameters>]
````

### DESCRIPTION
    Performs a rename action throughout a project folder. It will skip .git and .svn folders,
    images, archives and other common known binaries.
    But will rename within other files, like sourcecode, json, html, etc, AND folders and
    filenames!
    Always perform a -WhatIf operation first, to validate the actions it will take.


### PARAMETERS
````
    -Source <String>
        The directory, filepath, or directory+searchmask

    -FindText <String>
        The case sensitive phrase to search for, when making replacements

    -ReplacementText <String>
        The text that will replace the found occurance

    -WhatIf [<SwitchParameter>]
        Displays a message that describes the effect of the command, instead of executing the
        command.

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    Rename-InProject -Source .\src\*.js -FindText "tsconfig.json" - ReplacementText
    "typescript.configuration.json"

    Rename-InProject .\src\ "MyCustomClass"  "MyNewRenamedClass" -WhatIf
````
### REMARKS
````PowerShell
    To see the examples, type: "Get-Help Rename-InProject -Examples"
    For more information, type: "Get-Help Rename-InProject -Detailed"
    For technical information, type: "Get-Help Rename-InProject -Full"
````
<br/><hr/><hr/><hr/><hr/><br/>

### NAME
    Find-Item

### SYNOPSIS
    Finds files by searchmask


### SYNTAX
````PowerShell
    Find-Item [-SearchMask] <String> [-File] [-Directory] [<CommonParameters>]
````

### DESCRIPTION
    Finds files by searchmask on every disk available in the current session

### PARAMETERS
````
    -SearchMask <String>
        Partial or full filename to look for

    -File [<SwitchParameter>]
        Only find files

    -Directory [<SwitchParameter>]
        Only find directories

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    Find-Item settings.json -File

    Find-Item node_modules -Directory

### REMARKS
    To see the examples, type: "Get-Help Find-Item -Examples"
    For more information, type: "Get-Help Find-Item -Detailed"
    For technical information, type: "Get-Help Find-Item -Full"
````
<br/><hr/><hr/><hr/><hr/><br/>

### NAME
    Expand-Path

### SYNOPSIS
    Expands any given file reference to a full pathname


### SYNTAX
````PowerShell
    Expand-Path [[-FilePath] <String>] [[-CreateDirectory] <Boolean>] [<CommonParameters>]
````

### DESCRIPTION
    Expands any given file reference to a full pathname, with respect to the users current
    directory

### PARAMETERS
````
    -FilePath <String>
        Path to expand

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CreateDirectory <Boolean>
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
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

````
### OUTPUTS
````PowerShell
    -------------------------- EXAMPLE 1 --------------------------

    Expand-Path .\
````
