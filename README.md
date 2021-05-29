<hr/>

![](https://pc7x.net/Powershell.jpg)

<hr/>

# NAME

    GenXdev.FileSystem

# TYPE
    PowerShell Module

# INSTALLATION
````Powershell

    # construct file path to modules directory
    $CurrentUserModulesPath = "$([IO.Path]::GetDirectoryName($Profile))\Modules"

    # create it, if necessary
    if (![IO.Directory]::Exists($CurrentUserModulesPath)) { [IO.Directory]::CreateDirectory($CurrentUserModulesPath)};

    # change current directory to modules directory
    Set-Location $CurrentUserModulesPath;

    # clone the repo
    git clone https://github.com/renevaessen/GenXdev.FileSystem.git GenXdev.FileSystem

    # soon this becomes the default, according to Microsoft
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    # until it becomes a NuGet package, this should do it
    Import-Module ".\GenXdev.FileSystem\GenXdev.FileSystem.psm1" -Force

    # show manual pages for the new CmdLets
    Get-Module "GenXdev.*" | % ExportedCommands | % Values | Where-Object -Property CommandType -NotLike "Alias" | % Name | % {

        man $PSItem
    }

````

<br/><hr/><hr/><hr/><hr/><br/>

## NAME
    Start-RoboCopy

## SYNOPSIS
    Wrapper for Microsoft's Robust Copy Utility
    Copies file data from one location to another.

## SYNTAX
````Powershell
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
    [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-LargeFiles] [-MultiThreaded]
    [-CompressibleContent] [-WhatIf] [<CommonParameters>]

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
    [-LogfileOverwrite] [-LogDirectoryNames] [-LogAllFileNames] [-LargeFiles] [-MultiThreaded]
    [-CompressibleContent] [-WhatIf] [<CommonParameters>]
````

## DESCRIPTION
    Wrapper for Microsoft's Robust Copy Utility
    Copies file data from one location to another.

    Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command
    for Microsoft Windows.
    Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first
    released as part of the
    Windows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and
    Windows Server 2008.

## Key features

    * Folder synchronization
    * Support for extra long pathnames > 256 characters
    * Uses restartable* and shadow-copy backup-modes as default
    * Support for copying and fixing security settings
    * Advanced file attribute features
    * Advanced symbolic link and junction support
    * Monitor mode (restart copying after change threshold)
    * Optimization features for LargeFiles, multithreaded copying and network compression
    * Recovery mode (copy from failing disks)

## RELATED LINKS
[Microsoft](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy)
[Wikipedia](https://en.wikipedia.org/wiki/Robocopy)

## REMARKS
````Powershell
To see the examples, type: "Get-Help Start-RoboCopy -Examples"
For more information, type: "Get-Help Start-RoboCopy -Detailed"
For technical information, type: "Get-Help Start-RoboCopy -Full"
For online help, type: "Get-Help Start-RoboCopy -Online"
````

<br/><hr/><hr/><hr/><hr/><br/>

## NAME
    Rename-InProject

## SYNOPSIS
    Performs a case sensitive text replacement throughout a project


## SYNTAX
````Powershell
Rename-InProject [[-Source] <String>] [-FindText] <String> [-ReplacementText] <String>
    [-WhatIf] [<CommonParameters>]
````

## DESCRIPTION
    Performs a rename action throughout a project folder. It will skip .git and .svn folders,
    images, archives and other common known binaries.
    But will rename within other files, like sourcecode, json, html, etc, AND folders and
    filenames!
    Always perform a -WhatIf operation first, to validate the actions it will take.


## PARAMETERS
````Powershell

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

Rename-InProject -Source .\src\*.js -FindText "tsconfig.json" -ReplacementText "typescript.configuration.json"

Rename-InProject .\src\ "MyCustomClass"  "MyNewRenamedClass" -WhatIf
````

## REMARKS
````Typescript
To see the examples, type: "Get-Help Rename-InProject -Examples"
For more information, type: "Get-Help Rename-InProject -Detailed"
For technical information, type: "Get-Help Rename-InProject -Full"
````

<br/><hr/><hr/><hr/><hr/><br/>

## NAME
    Find-Item

## SYNOPSIS
    Finds files by seachmask


## SYNTAX
````Powershell
Find-Item [-SearchMask] <String> [-File] [-Directory] [<CommonParameters>]
````

## DESCRIPTION
    Finds files by searchmask on every disk available in the current session

## PARAMETERS
````Powershell
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
````

## REMARKS
````Powershell
To see the examples, type: "Get-Help Find-Item -Examples"
For more information, type: "Get-Help Find-Item -Detailed"
For technical information, type: "Get-Help Find-Item -Full"
````

<br/><hr/><hr/><hr/><hr/><br/>

## NAME
    ExpandPath

## SYNOPSIS
    Expands any given file reference to a full pathname

## SYNTAX
````Powershell
ExpandPath [[-FilePath] <String>] [[-CreateDirectory] <Boolean>] [<CommonParameters>]
````

## DESCRIPTION
    Expands any given file reference to a full pathname, with respect to the users current
    directory


## PARAMETERS
````Powershell
-FilePath <String>
    Path to expand

-CreateDirectory <Boolean>
    Will create directory if it does not exist

<CommonParameters>
    This cmdlet supports the common parameters: Verbose, Debug,
    ErrorAction, ErrorVariable, WarningAction, WarningVariable,
    OutBuffer, PipelineVariable, and OutVariable. For more information, see
    about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

-------------------------- EXAMPLE 1 --------------------------

GetFullPath .\

$DestinationPath = (GetFullPath .\build -CreateDirectory)
````

## REMARKS
````Powershell
To see the examples, type: "Get-Help ExpandPath -Examples"
For more information, type: "Get-Help ExpandPath -Detailed"
For technical information, type: "Get-Help ExpandPath -Full"
````
<br/><hr/><hr/><hr/><hr/><br/>
