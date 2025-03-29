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
| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | aliases&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description |
| --- | --- | --- |
| [_AssureTypes](#_AssureTypes) |  |  |
| [AssurePester](#AssurePester) |  | Ensures Pester testing framework is available for use. |
| [Expand-Path](#Expand-Path) | ep | Expands any given file reference to a full pathname. |
| [Find-DuplicateFiles](#Find-DuplicateFiles) | fdf | Find duplicate files across multiple directories based on configurable criteria. |
| [Find-Item](#Find-Item) | l | Performs advanced file and directory searches with content filtering capabilities. |
| [Invoke-Fasti](#Invoke-Fasti) | fasti | Extracts archive files in the current directory and deletes the originals. |
| [Move-ItemWithTracking](#Move-ItemWithTracking) |  | Moves files and directories while preserving filesystem links and references. |
| [Move-ToRecycleBin](#Move-ToRecycleBin) | recycle | Moves files and directories to the Windows Recycle Bin safely. |
| [Remove-AllItems](#Remove-AllItems) | sdel | Recursively removes all content from a directory with advanced error handling. |
| [Remove-ItemWithFallback](#Remove-ItemWithFallback) | rmf | Removes files or directories with multiple fallback mechanisms for reliable deletion. |
| [Remove-OnReboot](#Remove-OnReboot) |  | Marks files or directories for deletion during the next system boot. |
| [Rename-InProject](#Rename-InProject) | rip | Performs case-sensitive text replacement throughout a project directory. |
| [Start-RoboCopy](#Start-RoboCopy) | xc, rc | Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility. |

<br/><hr/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.FileSystem<hr/>