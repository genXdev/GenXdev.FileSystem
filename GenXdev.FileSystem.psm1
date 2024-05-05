###############################################################################

<#
Copyright 2021 GenXdev - genXdev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#>
###############################################################################

<#
.SYNOPSIS
 Finds files by searchmask

.DESCRIPTION
Finds files by searchmask on every disk available in the current session

.PARAMETER SearchMask
Partial or full filename to look for

.PARAMETER File
Only find files

.PARAMETER Directory
Only find directories

.EXAMPLE
Find-Item settings.json -File

Find-Item node_modules -Directory
#>
function Find-Item {

    [Alias("fi")]

    param (
        [parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = "Search phrase to look for",
            ValueFromPipeline = $false
        )]
        [string] $SearchMask,

        [Parameter(
            HelpMessage = "Files only",
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch] $File,

        [Parameter(
            HelpMessage = "Directory only",
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch] $Directory
    )

    Get-PSDrive -ErrorAction SilentlyContinue | ForEach-Object -ThrottleLimit 8 -Parallel {

        try {
            if ($_.Provider.Name -eq "FileSystem") {

                Get-ChildItem -Path "$($_.Root)*$SearchMask*" -File:$File -Directory:$Directory -ErrorAction SilentlyContinue

                Get-ChildItem -Path "$($_.Root)" -Directory -ErrorAction SilentlyContinue  |
                ForEach-Object -ThrottleLimit 16 -Parallel {

                    try {

                        Get-ChildItem -Path "$($_.FullName)\*$SearchMask*" -File:$File -Directory:$Directory -Recurse -ErrorAction SilentlyContinue

                    }
                    catch {

                    }

                }
            }
        }
        catch {

        }
    }
}

###############################################################################

<#
.SYNOPSIS
Expands any given file reference to a full pathname

.DESCRIPTION
Expands any given file reference to a full pathname, with respect to the users current directory

.PARAMETER FilePath
Path to expand

.PARAMETER CreateDirectory
Will create directory if it does not exist

.EXAMPLE
GetFullPath .\

#>
function Expand-Path {

    [CmdletBinding()]
    [Alias("ep")]

    param(
        [parameter(Mandatory, Position = 0)]
        [string] $FilePath,

        [parameter(Mandatory = $false, Position = 1)]
        [switch] $CreateDirectory
    )

    # root folder included?
    if ((($FilePath.Length -gt 1) -and ($FilePath.Substring(1, 1) -eq ":")) -or $FilePath.StartsWith("\\")) {

        try {

            # just normalize
            $FilePath = [System.IO.Path]::GetFullPath($FilePath);
        }
        catch {

            # keep original
        }
    }
    else {

        try {
            # combine with users current directory
            $FilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($pwd, $FilePath));
        }
        catch {

            # allow powershell to try to convert it
            $FilePath = Convert-Path $FilePath;
        }
    }

    # create directory?
    if ($CreateDirectory -eq $true) {

        # get directory name
        $directory = [System.IO.Path]::GetDirectoryName($FilePath);

        # does not exist?
        if (![IO.Directory]::Exists($directory)) {

            # create it
            New-Item -ItemType Directory -Path $directory -Force
        }
    }

    # remove trailing path delimiter
    while ($FilePath.EndsWith("\") -and $FilePath.Length -gt 4) {

        $FilePath = $FilePath.SubString(0, $FilePath.Length - 1)
    }

    return $FilePath;
}

###############################################################################

<#
.SYNOPSIS
Wrapper for Microsoft's Robust Copy Utility
Copies file data from one location to another.

.DESCRIPTION
Wrapper for Microsoft's Robust Copy Utility
Copies file data from one location to another.

Robocopy, for "Robust File Copy", is a command-line directory and/or file replication command for Microsoft Windows.
Robocopy functionally replaces Xcopy, with more options. Created by Kevin Allen and first released as part of the
Windows NT 4.0 Resource Kit, it has been a standard feature of Windows since Windows Vista and Windows Server 2008.

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

.PARAMETER Source
The directory, filepath, or directory+searchmask

.PARAMETER DestinationDirectory
The destination directory to place the copied files and directories into.
If this directory does not exist yet, all missing directories will be created.
Default value = `.\`

.PARAMETER FileMask
Optional searchmask for selecting the files that need to be copied.

.PARAMETER Mirror
Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source

.PARAMETER Move
Will move instead of copy all files from source to destination

.PARAMETER IncludeSecurity
Will also copy ownership, security descriptors and auditing information of files and directories

.PARAMETER SkipDirectories
Copies only files from source and skips sub-directories (no recurse)

.PARAMETER SkipEmptyDirectories
Does not copy directories if they would be empty

.PARAMETER CopyOnlyDirectoryTreeStructure
Create directory tree only

.PARAMETER CopyOnlyDirectoryTreeStructureAndEmptyFiles
Create directory tree and zero-length files only

.PARAMETER SkipAllSymbolicLinks
Don't copy symbolic links, junctions or the content they point to

.PARAMETER CopySymbolicLinksAsLinks
Instead of copying the content where symbolic links point to, copy the links themselves

.PARAMETER SkipJunctions
Don't copy directory junctions (symbolic link for a folder) or the content they point to

.PARAMETER SkipSymbolicFileLinks
Don't copy file symbolic links but do follow directory junctions

.PARAMETER CopyJunctionsAsJunctons
Instead of copying the content where junctions point to, copy the junctions themselves

.PARAMETER Force
Will copy all files even if they are older then the ones in the destination

.PARAMETER SkipFilesWithoutArchiveAttribute
Copies only files that have the archive attribute set

.PARAMETER ResetArchiveAttributeAfterSelection
In addition of copying only files that have the archive attribute set, will then reset this attribute on the source

.PARAMETER FileExcludeFilter
Exclude any files that matches any of these names/paths/wildcards

.PARAMETER DirectoryExcludeFilter
Exclude any directories that matches any of these names/paths/wildcards

.PARAMETER AttributeIncludeFilter
Copy only files that have all these attributes set [RASHCNETO]

.PARAMETER AttributeExcludeFilter
Exclude files that have any of these attributes set [RASHCNETO]

.PARAMETER SetAttributesAfterCopy
Will set the given attributes to copied files [RASHCNETO]

.PARAMETER RemoveAttributesAfterCopy
Will remove the given attributes from copied files [RASHCNETO]

.PARAMETER MaxSubDirTreeLevelDepth
Only copy the top n levels of the source directory tree

.PARAMETER MinFileSize
Skip files that are not at least n bytes in size

.PARAMETER MaxFileSize
Skip files that are larger then n bytes

.PARAMETER MinFileAge
Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)

.PARAMETER MaxFileAge
Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)

.PARAMETER MinLastAccessAge
Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)

.PARAMETER MaxLastAccessAge
Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)

.PARAMETER RecoveryMode
Will shortly pause and retry when I/O errors occur during copying

.PARAMETER MonitorMode
Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes

.PARAMETER MonitorModeThresholdMinutes
Run again in n minutes Time, if changed

.PARAMETER MonitorModeThresholdNrOfChanges
Run again when more then n changes seen

.PARAMETER MonitorModeRunHoursFrom
Run hours - times when new copies may be started, start-time, range 0000:2359

.PARAMETER MonitorModeRunHoursUntil
Run hours - times when new copies may be started, end-time, range 0000:2359

.PARAMETER LogFilePath
If specified, logging will also be done to specified file

.PARAMETER LogfileOverwrite
Don't append to the specified logfile, but overwrite instead

.PARAMETER LogDirectoryNames
Include all scanned directory names in output

.PARAMETER LogAllFileNames
Include all scanned file names in output, even skipped onces

.PARAMETER Unicode
Output status as UNICODE

.PARAMETER LargeFiles
Enables optimization for copying large files

.PARAMETER Multithreaded
Optimize performance by doing multithreaded copying

.PARAMETER CompressibleContent
If applicable use compression when copying files between servers to safe bandwidth and time

.PARAMETER Override
Overrides, Removes, or Adds any specified robocopy parameter.

Usage:

Add or replace parameter:

    -Override /SwitchWithValue:'SomeValue'

    -Override /Switch

Remove parameter:

    -Override -/Switch

Multiple overrides:

    -Override "/ReplaceThisSwitchWithValue:'SomeValue' -/RemoveThisSwitch /AddThisSwitch"

.PARAMETER WhatIf
Displays a message that describes the effect of the command, instead of executing the command.

.EXAMPLE
Start-RoboCopy c:\videos e:\backups\videos

Start-RoboCopy c:\users\user\onedrive\photos\screenshots e:\backups\screenshots -Move

Start-RoboCopy c:\users\user\onedrive e:\backups\onedrive -Mirror

.LINK
https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy

.LINK
https://en.wikipedia.org/wiki/Robocopy

#>
function Start-RoboCopy {
    [CmdLetBinding(
        DefaultParameterSetName = "Default",
        ConfirmImpact = "Medium"
    )]
    [Alias("xc", "rc")]
    Param
    (
        ###############################################################################

        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $false,
            HelpMessage = "The directory, filepath, or directory+searchmask"
        )]
        [string]$Source,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $false,
            HelpMessage = "The destination directory to place the copied files and directories into.
            If this directory does not exist yet, all missing directories will be created.
            Default value = `".\`""
        )]
        [string]$DestinationDirectory = ".\",
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 2,
            HelpMessage = "Optional searchmask for selecting the files that need to be copied.
            Default value = '*'"
        )] [string[]] $Files = @(),
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source"
        )]
        [switch] $Mirror,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will move instead of copy all files from source to destination"
        )]
        [switch] $Move,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will also copy ownership, security descriptors and auditing information of files and directories"
        )]
        [switch] $IncludeSecurity,
        ###############################################################################

        ###############################################################################
        [Parameter(
            ParameterSetName = "Default",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Copies only files from source and skips sub-directories (no recurse)"
        )]
        [switch] $SkipDirectories,
        ###############################################################################

        [Parameter(
            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Does not copy directories if they would be empty"
        )]
        [switch] $SkipEmptyDirectories,
        ###############################################################################

        [Parameter(
            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Create directory tree only"
        )]
        [switch] $CopyOnlyDirectoryTreeStructure,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Create directory tree and zero-length files only"
        )]
        [switch] $CopyOnlyDirectoryTreeStructureAndEmptyFiles,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy symbolic links, junctions or the content they point to"
        )]
        [switch] $SkipAllSymbolicLinks,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy file symbolic links but do follow directory junctions"
        )]
        [switch] $SkipSymbolicFileLinks,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Instead of copying the content where symbolic links point to, copy the links themselves"
        )]
        [switch] $CopySymbolicLinksAsLinks,
        ###############################################################################

        [Parameter(

            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy directory junctions (symbolic link for a folder) or the content they point to"
        )]
        [switch] $SkipJunctions,
        ###############################################################################

        [Parameter(

            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Instead of copying the content where junctions point to, copy the junctions themselves"
        )]
        [switch] $CopyJunctionsAsJunctons,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will copy all files even if they are older then the ones in the destination"
        )]
        [switch] $Force,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Copies only files that have the archive attribute set"
        )]
        [switch] $SkipFilesWithoutArchiveAttribute,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "In addition of copying only files that have the archive attribute set, will then reset this attribute on the source"
        )]
        [switch] $ResetArchiveAttributeAfterSelection,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Exclude any files that matches any of these names/paths/wildcards"
        )]
        [string[]] $FileExcludeFilter = @(),
        ###############################################################################

        [Parameter(
            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Exclude any directories that matches any of these names/paths/wildcards"
        )]
        [string[]] $DirectoryExcludeFilter = @(),
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Copy only files that have all these attributes set [RASHCNETO]"
        )]
        [string] $AttributeIncludeFilter,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Exclude files that have any of these attributes set [RASHCNETO]"
        )]
        [string] $AttributeExcludeFilter,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will set the given attributes to copied files [RASHCNETO]"
        )]
        [string] $SetAttributesAfterCopy,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will remove the given attributes from copied files [RASHCNETO]"
        )]
        [string] $RemoveAttributesAfterCopy,
        ###############################################################################

        ###############################################################################
        [ValidateRange(1, 1000000)]
        [Parameter(
            ParameterSetName = "SkipDirectories",
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Only copy the top n levels of the source directory tree"
        )]
        [int] $MaxSubDirTreeLevelDepth = -1,
        ###############################################################################

        [ValidateRange(0, 9999999999999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that are not at least n bytes in size"
        )]
        [int] $MinFileSize = -1,
        ###############################################################################

        [ValidateRange(0, 9999999999999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that are larger then n bytes"
        )]
        [int] $MaxFileSize = -1,
        ###############################################################################

        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)"
        )]
        [int] $MinFileAge = -1,
        ###############################################################################

        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)"
        )]
        [int] $MaxFileAge = -1,
        ###############################################################################

        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)"
        )]
        [int] $MinLastAccessAge = -1,
        ###############################################################################

        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)"
        )]
        [int] $MaxLastAccessAge = -1,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will shortly pause and retry when I/O errors occur during copying"
        )]
        [switch] $RecoveryMode,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes"
        )]
        [switch] $MonitorMode,
        ###############################################################################

        [ValidateRange(1, 144000)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Run again in n minutes Time, if changed"
        )]
        [int] $MonitorModeThresholdMinutes = -1,
        ###############################################################################

        [ValidateRange(1, 1000000000)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Run again when more then n changes seen"
        )]
        [int] $MonitorModeThresholdNrOfChanges = -1,
        ###############################################################################

        [ValidateRange(0, 2359)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Run hours - times when new copies may be started, start-time, range 0000:2359"
        )]
        [int] $MonitorModeRunHoursFrom = -1,
        ###############################################################################

        [ValidateRange(0, 2359)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Run hours - times when new copies may be started, end-time, range 0000:2359"
        )]
        [int] $MonitorModeRunHoursUntil = -1,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "If specified, logging will also be done to specified file"
        )]
        [string] $LogFilePath,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't append to the specified logfile, but overwrite instead"
        )]
        [switch] $LogfileOverwrite,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Include all scanned directory names in output"
        )]
        [switch] $LogDirectoryNames,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Include all scanned file names in output, even skipped onces"
        )]
        [switch] $LogAllFileNames,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Output status as UNICODE"
        )]
        [switch] $Unicode,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Enables optimization for copying large files"
        )]
        [switch] $LargeFiles,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Optimize performance by doing multithreaded copying"
        )]
        [switch] $MultiThreaded,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "If applicable use compression when copying files between servers to safe bandwidth and time"
        )]
        [switch] $CompressibleContent,
        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromRemainingArguments = $true,
            Position = 3,
            HelpMessage = "Overrides, Removes, or Adds any specified robocopy parameter.

Usage:

Add or replace parameter:

    -Override /SwitchWithValue:'SomeValue'

    -Override /Switch

Remove parameter:

    -Override -/Switch

Multiple overrides:

    -Override `"/ReplaceThisSwitchWithValue:'SomeValue' -/RemoveThisSwitch /AddThisSwitch`"
"
        )]
        [string] $Override,
        ###############################################################################

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Displays a message that describes the effect of the command, instead of executing the command."
        )]
        [switch] $WhatIf
    )

    Begin {

        ###############################################################################

        # initialize settings
        $RobocopyPath = "$env:SystemRoot\system32\robocopy.exe";

        # normalize to current directory
        $Source = Expand-Path $Source
        $DestinationDirectory = Expand-Path $DestinationDirectory

        # source is not an existing directory?
        if ([IO.Directory]::Exists($Source) -eq $false) {

            # split directory and filename
            $SourceSearchMask = [IO.Path]::GetFileName($Source);
            $SourceDirOnly = [IO.Path]::GetDirectoryName($Source);

            # does parent directory exist?
            if ([IO.Directory]::Exists($SourceDirOnly)) {

                # ..but the supplied source parameter is not an existing file?
                if ([IO.File]::Exists($Source) -eq $false) {

                    # ..and the supplied filename is not searchMask?
                    if (!$SourceSearchMask.Contains("*") -and !$SourceSearchMask.Contains("?")) {

                        throw "Could not find source: $Source"
                    }
                }

                $Mirror = $false;
            }

            # reconfigure
            $Source = $SourceDirOnly;
            if ($Files -notcontains $SourceSearchMask) {

                $Files = $Files + @($SourceSearchMask);
            }
        }

        # default value
        if ($Files.Length -eq 0) {

            $Files = @("*");
        }

        # destination directory does not exist yet?
        if ([IO.Directory]::Exists($DestinationDirectory) -eq $false) {

            # create it
            [IO.Directory]::CreateDirectory($DestinationDirectory) | Out-Null
        }

        # Turn on verbose
        $VerbosePreference = "Continue"

        ###############################################################################

        function CurrentUserHasElivatedRights() {

            $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $p = New-Object System.Security.Principal.WindowsPrincipal($id)

            if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or
                $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::BackupOperator)) {

                return $true;
            }

            return $false;
        }

        function ConstructFileFilterSet([string[]] $FileFilterSet, [string] $CommandName) {

            $result = "";

            $FileFilterSet | ForEach-Object {

                $result = "$result '$PSItem'".Trim()
            }

            return $result;
        }

        function SanitizeAttributeSet([string] $AttributeSet, [string] $CommandName) {

            $AttributeSetNew = "";
            $AttributeSet.Replace("[", "").Replace("]", "").ToUpperInvariant().ToCharArray() | ForEach-Object {

                if (("RASHCNETO".IndexOf($PSItem) -ge 0) -and ($AttributeSetNew.IndexOf($PSItem) -lt 0)) {

                    $AttributeSetNew = "$AttributeSet$PSItem";
                }
                else {

                    throw "Could not parse parameter -$CommandName $AttributeSet - '$PSItem' is not valid
    possible attributes to combine: [RASHCNETO]

    R - Read only
    A - Archive
    S - System
    H - Hidden
    C - Compressed
    N - Not content indexed
    E - Encrypted
    T - Temporary
    O - Offline
"
                }
            }

            return $AttributeSetNew
        }

        function CheckAgeInteger([int] $AgeValue, [string] $CommandName) {

            if ($AgeValue -ge 1900) {

                [DateTime] $date;
                if ([DateTime]::TryParse("$MaxFileAge", [ref] $date) -eq $false) {

                    throw "Could not parse parameter '-$CommandName $AgeValue as a valid date (if n < 1900 then n = n days, else n = YYYYMMDD date)"
                }
            }
        }

        function getSwitchesDictionary([string] $Switches) {

            # initialize
            $switchesDictionary = New-Object "System.Collections.Generic.Dictionary[String, String]";

            if ([String]::IsNullOrWhiteSpace($Switches)) {

                return $switchesDictionary
            }

            $switchesCleaned = " $Switches ";

            # remove spaces
            while ($switchesCleaned.IndexOf("  /") -ge 0) {

                $switchesCleaned = $switchesCleaned.Replace("  /", " /");
            }
            while ($switchesCleaned.IndexOf("  -/") -ge 0) {

                $switchesCleaned = $switchesCleaned.Replace("  -/", " -/");
            }

            # split up
            $allSwitches = $switchesCleaned.Replace(" -/", " /-").Split([string[]]@(" /"), [System.StringSplitOptions]::RemoveEmptyEntries);

            # enumerate switches
            $allSwitches | ForEach-Object -ErrorAction SilentlyContinue {

                # add to Dictionary
                $switchesDictionary["$($PSItem.Trim().Split(" ")[0].Split(":" )[0].Trim().ToUpperInvariant())"] = $PSItem.Trim()
            }

            return $switchesDictionary;
        }

        function overrideAndCleanSwitches([string] $Switches) {

            $autoGeneratedSwitches = (getSwitchesDictionary $Switches)
            $overridenSwitches = (getSwitchesDictionary $Override)
            $newSwitches = "";

            $autoGeneratedSwitches.GetEnumerator() | ForEach-Object -ErrorAction SilentlyContinue {

                # should NOT remove it?
                if (!$overridenSwitches.ContainsKey("-$($PSItem.Key)")) {

                    # should replace it?
                    if ($overridenSwitches.ContainsKey($PSItem.Key)) {

                        $newSwitches += " /$($overridenSwitches[$PSItem.Key])"
                    }
                    else {

                        # keep the autogenerated switch
                        $newSwitches += " /$($PSItem.Value)"
                    }
                }
            }

            $overridenSwitches.GetEnumerator() | ForEach-Object -ErrorAction SilentlyContinue {

                # not already processed above?
                if (!$PSItem.Key.StartsWith("-") -and !$autoGeneratedSwitches.ContainsKey("$($PSItem.Key)")) {

                    # add it
                    $newSwitches += " /$($PSItem.Value)"
                }
            }

            return $newSwitches.Trim();
        }

        ###############################################################################

        # /B            █  copy files in Backup mode.
        # /ZB           █  use restartable mode; if access denied use Backup mode.
        if (CurrentUserHasElivatedRights) {

            $ParamMode = "/B"
        }
        else {
            $ParamMode = ""
        }

        # /MOV			█  MOVE files AND dirs (delete from source after copying).
        $ParamMOV = "";

        # /MIR			█ MIRror a directory tree (equivalent to /E plus /PURGE).
        $ParamMIR = "";

        # /SECFIX		█ FIX file SECurity on all files, even skipped files.
        $ParamSECFIX = "";

        # /E			█  copy subdirectories, including Empty ones.
        # /S			█ copy Subdirectories, but not empty ones.
        $ParamDirs = "/E"

        # /COPY			█ what to COPY for files (default is /COPY:DAT).
        $ParamCOPY = "/COPY:DAT"

        # /XO			█ eXclude Older files.
        $ParamXO = "/XO";

        # /IM			█  Include Modified files (differing change times).
        $ParamIM = "/IM";

        # /IT			█ Include Tweaked files.
        $ParamIT = "/IT";

        # /IS			█ Include Same files.
        $ParamIS = "";

        # /EFSRAW		█  copy all encrypted files in EFS RAW mode.
        $ParamEFSRAW = "";

        # /NOOFFLOAD	█ 	copy files without using the Windows Copy Offload mechanism.
        $ParamNOOFFLOAD = "";

        # /R			█ number of Retries on failed copies: default 1 million.
        $ParamR = "/R:0";

        # /W			█ Wait time between retries: default is 30 seconds.
        $ParamW = "/W:0";

        # /J			█ copy using unbuffered I/O (recommended for large files).
        $paramJ = "";

        # /MT           █ Do multi-threaded copies with n threads (default 8).
        $paramMT = "";

        # /NDL			█ No Directory List - don't log directory names.
        $ParamNDL = "/NDL";

        # /X			█ report all eXtra files, not just those selected.
        $ParamX = "";

        # /V			█  produce Verbose output, showing skipped files.
        $ParamV = "";

        # /CREATE		█  CREATE directory tree and zero-length files only.
        $ParamCREATE = "";

        # /XJ			█ eXclude symbolic links (for both files and directories) and Junction points.
        $ParamXJ = "";

        # /XJD			█ eXclude symbolic links for Directories and Junction points.
        $ParamXJD = "";

        # /XJF			█  eXclude symbolic links for Files.
        $ParamXJF = "";

        # /SJ			█ copy Junctions as junctions instead of as the junction targets.
        $ParamSJ = "";

        # /SL			█ copy Symbolic Links as links instead of as the link targets.
        $ParamSL = "";

        # /A			█  copy only files with the Archive attribute set.
        # /M			█ copy only files with the Archive attribute and reset it.
        $ParamArchive = "";

        # /XF
        $ParamXF = "" # █ eXclude Files matching given names/paths/wildcards.

        # /XD
        $ParamXD = "" # █ eXclude Directories matching given names/paths/wildcards.

        # /IA			█ Include only files with any of the given Attributes set.
        $ParamIA = "";

        # /XA			█  eXclude files with any of the given Attributes set.
        $ParamXA = "";

        # /A+			█  add the given Attributes to copied files
        $ParamAttrSet = "";

        # /A-			█ remove the given Attributes from copied files.
        $ParamAttrRemove = "";

        # /LEV			█ only copy the top n LEVels of the source directory tree.
        $ParamLEV = "";

        # /MIN			█  MINimum file size - exclude files smaller than n bytes.
        $ParamMIN = "";

        # /MAX			█  MAXimum file size - exclude files bigger than n bytes.
        $ParamMAX = "";

        # /MINAGE 	    █ MINimum file AGE - exclude files newer than n days/date.
        $ParamMINAGE = "";

        # /MAXAGE		█ MAXimum file AGE - exclude files older than n days/date.
        $ParamMaxAGE = "";

        # /LOG			█ output status to LOG file (overwrite existing log).
        # /LOG+         █ output status to LOG file (append to existing log).
        $ParamLOG = "";

        # /TEE          █ output to console window, as well as the log file.
        $ParamTee = "";

        # /UNICODE		█  output status as UNICODE.
        $ParamUnicode = "";

        # /RH			█  Run Hours - times when new copies may be started.
        $ParamRH = "";

        # /MON			█ MONitor source; run again when more than n changes seen.
        # /MOT          █ MOnitor source; run again in m minutes Time, if changed.
        $ParamMON = "";

        # /MAXLAD		█  MAXimum Last Access Date - exclude files unused since n.
        $ParamMAXLAD = "";

        # /MINLAD		█  MINimum Last Access Date - exclude files used since n.
        $ParamMINLAD = "";

        # /COMPRESS		█  Request network compression during file transfer, if applicable.
        $ParamCOMPRESS = "";

        ###############################################################################

        # -Mirror ➜ Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source
        if ($Mirror -eq $true) {

            $ParamMIR = "/MIR" #                          █ MIRror a directory tree (equivalent to /E plus /PURGE).
        }

        # -Move ➜ Will move instead of copy all files from source to destination
        if ($Move -eq $true) {

            $ParamMOV = "/MOV" #                          █ MOVE files AND dirs (delete from source after copying).
        }

        # -IncludeSecurity ➜ Will also copy ownership, security descriptors and auditing information of files and directories
        if ($IncludeSecurity -eq $true) {

            $ParamSECFIX = "/SECFIX" #                    █ FIX file SECurity on all files, even skipped files.
            $ParamCOPY = "$($ParamCOPY)SOU" #             █ what to COPY for files (default is /COPY:DAT).
            $ParamEFSRAW = "/EFSRAW" #                    █ copy all encrypted files in EFS RAW mode.
        }

        # -SkipDirectories ➜ Copies only files from source and skips sub-directories (no recurse)
        if ($SkipDirectories -eq $true) {

            $ParamDirs = "" #                             █ copy subdirectories, including Empty ones.
        }
        else {

            # -SkipEmptyDirectories ➜ Does not copy directories if they would be empty
            if ($SkipEmptyDirectories -eq $true) {

                $ParamDirs = "/S" #                       █ copy Subdirectories, but not empty ones.
            }
        }

        # -CopyOnlyDirectoryTreeStructure ➜ Create directory tree only
        if ($CopyOnlyDirectoryTreeStructure -eq $true) {

            $ParamCREATE = "/CREATE"; #                   █ CREATE directory tree and zero-length files only.
            $Files = @("DontCopy4nyF1lés") #              █ File(s) to copy  (names/wildcards: default is "*.*")
        }
        else {
            # -CopyOnlyDirectoryTreeStructureAndEmptyFiles ➜ Create directory tree and zero-length files only
            if ($CopyOnlyDirectoryTreeStructureAndEmptyFiles -eq $true) {

                $ParamCREATE = "/CREATE"; #               █ CREATE directory tree and zero-length files only.
            }
        }

        # -SkipAllSymbolicLinks ➜ Don't copy symbolic links, junctions or the content they point to
        if ($SkipAllSymbolicLinks -eq $true) {

            $ParamXJ = "/XJ"; #                           █ eXclude symbolic links (for both files and directories) and Junction points.
        }
        else {

            # -SkipSymbolicFileLinks ➜ Don't copy file symbolic links but do follow directory junctions
            if ($SkipSymbolicFileLinks -eq $true) {

                $ParamXJF = "/XJF"; #                     █ eXclude symbolic links for Files.
            }
            else {

                # -CopySymbolicLinksAsLinks ➜ Instead of copying the content where symbolic links point to, copy the links themselves
                if ($CopySymbolicLinksAsLinks -eq $true) {

                    $ParamSL = "/SL"; #                   █ copy Symbolic Links as links instead of as the link targets.
                }
            }

            # -SkipJunctions ➜ Don't copy directory junctions (symbolic link for a folder) or the content they point to
            if ($SkipJunctions -eq $true) {

                $ParamXJD = "/XJD"; #                     █ eXclude symbolic links for Directories and Junction points.
            }
            else {

                # -CopyJunctionsAsJunctons ➜ Instead of copying the content where junctions point to, copy the junctions themselves
                if ($CopyJunctionsAsJunctons -eq $true) {

                    $ParamSJ = "/SJ"; #                   █ copy Junctions as junctions instead of as the junction targets.
                }
            }
        }

        ###############################################################################

        # -Force ➜ Will copy all files even if they are older then the ones in the destination
        if ($Force -eq $true) {

            $ParamXO = "" #                               █ eXclude Older files.
            $ParamIT = "/IT" #                            █ Include Tweaked files.
            $ParamIS = "/IS" #                            █ Include Same files.
        }

        ###############################################################################

        # -SkipFilesWithoutArchiveAttribute ➜ Copies only files that have the archive attribute set
        if ($SkipFilesWithoutArchiveAttribute -eq $true) {

            $ParamArchive = "/A" #                        █ copy only files with the Archive attribute set.
        }

        # -ResetArchiveAttributeAfterSelection ➜ In addition of copying only files that have the archive attribute set, will then reset this attribute on the source
        if ($ResetArchiveAttributeAfterSelection -eq $true) {

            $ParamArchive = "/M" #                        █ copy only files with the Archive attribute and reset it
        }

        ###############################################################################

        # -FileExcludeFilter ➜ Exclude any files that matches any of these names/paths/wildcards
        if ($FileExcludeFilter.Length -gt 0) {

            $Filter = "$((ConstructFileFilterSet $FileExcludeFilter "FileExcludeFilter"))";
            $ParamXF = "/XF $Filter" #                    █ eXclude Files matching given names/paths/wildcards.
        }

        # -DirectoryExcludeFilter ➜ Exclude any directories that matches any of these names/paths/wildcards
        if ($DirectoryExcludeFilter.Length -gt 0) {

            $Filter = "$((ConstructFileFilterSet $DirectoryExcludeFilter "DirectoryExcludeFilter"))";
            $ParamXD = "/XD $Filter" #                    █ eXclude Directories matching given names/paths/wildcards.
        }

        # -AttributeIncludeFilter ➜ Copy only files that have all these attributes set [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($AttributeIncludeFilter) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $AttributeIncludeFilter "AttributeIncludeFilter"))";
            $ParamIA = "/IA:$Filter" #                    █ Include only files with any of the given Attributes set.
        }

        # -AttributeExcludeFilter ➜ Exclude files that have any of these attributes set [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($AttributeExcludeFilter) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $AttributeExcludeFilter "AttributeExcludeFilter"))";
            $ParamXA = "/XA:$Filter" #                    █ eXclude files with any of the given Attributes set.
        }

        # -SetAttributesAfterCopy ➜ Will set the given attributes to copied files [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($SetAttributesAfterCopy) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $SetAttributesAfterCopy "SetAttributesAfterCopy"))";
            $ParamAttrSet = "/A+:$Filter" #               █ add the given Attributes to copied files
        }

        # -RemoveAttributesAfterCopy ➜ Will remove the given attributes from copied files [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($RemoveAttributesAfterCopy) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $RemoveAttributesAfterCopy "RemoveAttributesAfterCopy"))";
            $ParamAttrRemove = "/A+:$Filter" #            █ remove the given Attributes from copied files.
        }

        # -MaxSubDirTreeLevelDepth ➜ Only copy the top n levels of the source directory tree
        if ($MaxSubDirTreeLevelDepth -ge 0) {

            $ParamLEV = "/LEV:$MaxSubDirTreeLevelDepth" # █ only copy the top n LEVels of the source directory tree.
        }

        # -MinFileSize ➜ Skip files that are not at least n bytes in size
        if ($MinFileSize -ge 0) {

            $ParamMIN = "/MIN:$MinFileSize" #             █ MINimum file size - exclude files smaller than n bytes.
        }

        # -MaxFileSize ➜ Skip files that are larger then n bytes
        if ($MaxFileSize -ge 0) {

            $ParamMAX = "/MAX:$MinFileSize" #             █ MAXimum file size - exclude files bigger than n bytes.
        }

        # -MinFileAge ➜ Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MinFileAge -ge 0) {

            CheckAgeInteger $MinFileAge "MinFileAge"

            $ParamMINAGE = "/MINAGE:$MinFileAge" #        █ MINimum file AGE - exclude files newer than n days/date.
        }

        # -MaxFileAge ➜ Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MaxFileAge -ge 0) {

            CheckAgeInteger $MaxFileAge "MaxFileAge"

            $ParamMaxAGE = "/MAXAGE:$MaxFileAge" #        █ MAXimum file AGE - exclude files older than n days/date.
        }

        # -MinLastAccessAge ➜ Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MinLastAccessAge -ge 0) {

            CheckAgeInteger $MinLastAccessAge "MinLastAccessAge"

            $ParamMINLAD = "/MINLAD:$MinLastAccessAge" #  █ MINimum Last Access Date - exclude files used since n.
        }

        # -MaxLastAccessAge ➜ Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MaxLastAccessAge -ge 0) {

            CheckAgeInteger $MaxLastAccessAge "MaxLastAccessAge"

            $ParamMAXLAD = "/MAXLAD:$MaxLastAccessAge" #  █ MAXimum Last Access Date - exclude files unused since n.
        }

        ###############################################################################

        # -RecoveryMode ➜ Will shortly pause and retry when I/O errors occur during copying
        if ($RecoveryMode -eq $true) {

            $ParamNOOFFLOAD = "/NOOFFLOAD" #              █ copy files without using the Windows Copy Offload mechanism.
            $ParamR = "/R:25" #                           █ number of Retries on failed copies: default 1 million.
            $ParamW = "/W:1" #                            █ Wait time between retries: default is 30 seconds.
        }

        ###############################################################################

        # -MonitorMode ➜ Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes
        if ($MonitorMode -eq $true) {

            $ParamMON = "/MOT:10" #                       █ MOnitor source; run again in m minutes Time, if changed.
        }

        # -MonitorModeThresholdMinutes ➜ Run again in n minutes Time, if changed
        if ($MonitorModeThresholdMinutes -ge 0) {

            $MotArgs = $MonitorModeThresholdMinutes;
            $ParamMON = "/MOT:$MotArgs" #                 █ MOnitor source; run again in m minutes Time, if changed.
        }

        # -MonitorModeThresholdNrOfChanges ➜ Run again when more then n changes seen
        if ($MonitorModeThresholdNrOfChanges -ge 0) {

            $MonArgs = $MonitorModeThresholdNrOfChanges
            $ParamMON = "/MON:$MonArgs" #                 █ MONitor source; run again when more than n changes seen.
        }

        if (($MonitorModeRunHoursFrom -ge 0) -or ($MonitorModeRunHoursUntil -ge 0)) {

            # -MonitorModeRunHoursFrom ➜ Run hours - times when new copies may be started, start-time, range 0000:2359
            if ($MonitorModeRunHoursFrom -ge 0) {

                $MonitorModeRunHoursFromStr = "$MonitorModeRunHoursFrom".PadLeft("0", 4);
                [int] $FromMinute = $MonitorModeRunHoursFromStr.Substring(2, 2);
                if ($FromMinute -lt 59) {

                    throw "Could not parse '-MonitorModeRunHoursFrom $MonitorModeRunHoursFromStr' parameter, range 0000:2359"
                }
            }
            else {
                $MonitorModeRunHoursFromStr = "0000";
            }

            # -MonitorModeRunHoursUntil ➜ Run hours - times when new copies may be started, end-time, range 0000:2359
            if ($MonitorModeRunHoursUntil -ge 0) {

                $MonitorModeRunHoursUntilStr = "$MonitorModeRunHoursUntil".PadLeft("0", 4);
                [int] $UntilMinute = $MonitorModeRunHoursUntilStr.Substring(2, 2);

                if ($UntilMinute -lt 59) {

                    throw "Could not parse '-MonitorModeRunHoursUntil $MonitorModeRunHoursUntilStr' parameter, range 0000:2359"
                }
            }
            else {
                $MonitorModeRunHoursUntilStr = "2359"
            }

            $RHArgs = "$MonitorModeRunHoursFromStr-$MonitorModeRunHoursUntilStr"
            $ParamRH = "/RH:$RHArgs" #                    █ Run Hours - times when new copies may be started.
        }

        ###############################################################################

        # -Unicode -> Output status as UNICODE
        if ($Unicode -eq $true) {

            $ParamUnicode = "/UNICODE" #                  █ output status as UNICODE.
        }

        # -LogFilePath ➜ If specified, logging will also be done to specified file
        if ([string]::IsNullOrWhiteSpace($LogFilePath) -eq $false) {

            $LogArgs = "'$((Expand-Path $LogFilePath $true).ToString().Replace("'", "''"))'"
            $LogPrefix = "";
            $ParamTee = "/TEE" #                          █ output to console window, as well as the log file

            # -Unicode -> Output status as UNICODE
            if ($Unicode -eq $true) { $LogPrefix = "UNI"; }

            # -LogfileOverwrite ➜ Don't append to the specified logfile, but overwrite instead
            if ($LogfileOverwrite -eq $true) {

                $ParamLOG = "/$($LogPrefix)LOG:$LogArgs" #█ output status to LOG file (overwrite existing log).
            }
            else {

                $ParamLOG = "/$($LogPrefix)LOG+:$LogArgs"#█ output status to LOG file (append to existing log).
            }
        }

        # -LogDirectoryNames ➜ Include all scanned directory names in output
        if ($LogDirectoryNames -eq $true) {

            $ParamNDL = "" #                              █ No Directory List - don't log directory names.
        }

        # -LogAllFileNames ➜ Include all scanned file names in output, even skipped onces
        if ($LogAllFileNames -eq $true) {

            $ParamX = "/X" #                              █ report all eXtra files, not just those selected.
            $ParamV = "/V" #                              █ produce Verbose output, showing skipped files.
        }

        # -LargeFiles ➜ Enables optimization for copying large files
        if ($LargeFiles -eq $true) {

            $ParamMode = "/ZB" #                          █ use restartable mode; if access denied use Backup mode.
            $paramJ = "/J" #                              █ copy using unbuffered I/O (recommended for large files).
        }

        # -LargeFiles ➜ Optimize performance by doing multithreaded copying
        if ($MultiThreaded -eq $true) {

            $paramMT = "/MT:16" #                         █ Do multi-threaded copies with n threads (default 8).
        }

        # -CompressibleContent ➜ If applicable use compression when copying files between servers to safe bandwidth and time
        if ($CompressibleContent -eq $true) {

            $ParamCOMPRESS = "/COMPRESS" #                █ Request network compression during file transfer, if applicable.
        }

        ###############################################################################

        $switches = "$ParamDirs /TS /FP $ParamMode /DCOPY:DAT /NP $ParamMT $ParamMOV $ParamMIR $ParamSECFIX $ParamCOPY $ParamXO $ParamIM $ParamIT $ParamIS $ParamEFSRAW $ParamNOOFFLOAD $ParamR $ParamW $paramJ $ParamNDL $ParamX $ParamV $ParamCREATE $ParamXJ $ParamXJD $ParamXJF $ParamSJ $ParamSL $ParamArchive $ParamIA $ParamXA $ParamAttrSet $ParamAttrRemove $ParamLEV $ParamMIN $ParamMAX $ParamMINAGE $ParamMaxAGE $ParamLOG $ParamTee $ParamUnicode $ParamRH $ParamMON $ParamMON $ParamMAXLAD $ParamMINLAD $ParamCOMPRESS $ParamXF $ParamXD".Replace("  ", " ").Trim();
        $switchesCleaned = overrideAndCleanSwitches($switches)
        $FilesArgs = ConstructFileFilterSet $Files "FileMask"
        $cmdLine = "& '$($RobocopyPath.Replace("'", "''"))' '$($Source.Replace("'", "''"))' '$($DestinationDirectory.Replace("'", "''"))' $FilesArgs $switchesCleaned"
    }
    Process {

        # WHAT IF?
        if ($WhatIf -or $WhatIfPreference) {

            # collect param help information
            $paramList = @{};
            (& $RobocopyPath -?) | ForEach-Object {
                if ($PSItem.Contains(" :: ")) {
                    $s = $PSItem.Split([string[]]@(" :: "), [StringSplitOptions]::RemoveEmptyEntries);
                    $paramList."$($s[0].ToLowerInvariant().split(":")[0].Split("[")[0].Trim().split(" ")[0])" = $s[1];
                }
            };

            $first = $true;
            $paramsExplained = @(

                " $switchesCleaned ".Split([string[]]@(" /"), [System.StringSplitOptions]::RemoveEmptyEntries) |
                ForEach-Object {

                    $description = $paramList."/$($PSItem.ToLowerInvariant().split(":")[0].Split("[")[0].Trim().split(" ")[0])"
                    $Space = "                         "; if ($first) { $Space = ""; $first = $false; }
                    "$Space/$($PSItem.ToUpperInvariant().split(":")[0].Split("[")[0].Trim().split(" ")[0].PadRight(15)) --> $description`r`n"
                }
            );

            Write-Host "

            RoboCopy would be executed as:
                $($cmdLine.Replace(" /L ", " "))

            Source      : $Source
            Files       : $Files
            Destination : $DestinationDirectory

            Mirror      : $($Mirror -eq $true)
            Move        : $($Move -eq $true)

            Switches    : $paramsExplained

"
            return;
        }

        Invoke-Expression $cmdLine
    }
    End {

    }
}

###############################################################################

<#
.SYNOPSIS
Performs a case sensitive text replacement throughout a project

.DESCRIPTION
Performs a rename action throughout a project folder. It will skip .git and .svn folders, images, archives and other common known binaries.
But will rename within other files, like sourcecode, json, html, etc, AND folders and filenames!
Always perform a -WhatIf operation first, to validate the actions it will take.

.PARAMETER Source
The directory, filepath, or directory+searchmask

.PARAMETER FindText
The case sensitive phrase to search for, when making replacements

.PARAMETER ReplacementText
The text that will replace the found occurance

.PARAMETER WhatIf
Displays a message that describes the effect of the command, instead of executing the command.

.EXAMPLE
Rename-InProject -Source .\src\*.js -FindText "tsconfig.json" - ReplacementText "typescript.configuration.json"

Rename-InProject .\src\ "MyCustomClass"  "MyNewRenamedClass" -WhatIf

.NOTES
Be carefull, use -WhatIf
#>
function Rename-InProject {

    [Alias("rip")]

    Param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 0,
            HelpMessage = "Path of folder that gets cloned")]
        [Alias("src", "s")]
        [PSDefaultValue(Value = ".\\")]
        [string] $Source,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1,
            HelpMessage = "string to match (case sensitive)")]
        [Alias("find", "what", "from")]
        [string] $FindText,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 2,
            HelpMessage = "The replacement text")]
        [Alias("into", "txt", "to")]
        [string] $ReplacementText,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Only show what actions would be taken")]
        [Switch] $WhatIf
    )

    Begin {

        # normalize to current directory
        $Source = Expand-Path $Source
        $Files = "*"

        # source is not an existing directory?
        if ([IO.Directory]::Exists($Source) -eq $false) {

            # split directory and filename
            $SourceSearchMask = [IO.Path]::GetFileName($Source);
            $SourceDirOnly = [IO.Path]::GetDirectoryName($Source);

            # does parent directory exist?
            if ([IO.Directory]::Exists($SourceDirOnly)) {

                # ..but the supplied source parameter is not an existing file?
                if ([IO.File]::Exists($Source) -eq $false) {

                    # ..and the supplied filename is not searchMask?
                    if ($Files -notcontains "*" -and $Files -notcontains "?") {

                        throw "Could not find source: $Source"
                    }
                }
            }

            # reconfigure
            $Source = $SourceDirOnly;
            $Files = $SourceSearchMask;
        }

        # not actually making any changes?
        if ($WhatIfPreference -or $WhatIf) {

            # Turn on verbose
            $VerbosePreference = "Continue"
        }
    }

    Process {

        if ([String]::IsNullOrWhiteSpace($Source)) {

            $Source = ".\";
        }

        if ([String]::IsNullOrWhiteSpace($findText)) {

            return;
        }

        # gets all files by directory and searchmask recursively, but skips repositories
        function GetAllFilesFromAllDirectories([string] $parentDirectory, [string] $searchMask) {

            # create new list
            [System.Collections.Generic.List[string]] $result = New-Object "System.Collections.Generic.List[string]"

            # is a repository?
            if ([System.IO.Path]::GetFileName($parentDirectory) -eq ".svn" -or [System.IO.Path]::GetFileName($parentDirectory) -eq ".git") {

                # skip
                return $result.ToArray();
            }

            # add all files by searchmask
            foreach ($file in [IO.Directory]::GetFiles($parentDirectory, $searchMask)) {

                $result.Add($file);
            }

            # enumerate all sub-directories
            foreach ($directory in [IO.Directory]::GetDirectories($parentDirectory, "*", [System.IO.SearchOption]::AllDirectories)) {

                # no match?
                if ([System.IO.Path]::GetFileName($directory) -notlike $searchMask) {

                    # skip it
                    continue;
                }

                # is a repository?
                if ([System.IO.Path]::GetFileName($directory) -eq ".svn" -or [System.IO.Path]::GetFileName($directory) -eq ".git") {

                    # skip it
                    continue;
                }

                # add all files by searchmask
                foreach ($file in [IO.Directory]::GetFiles($directory, $searchMask)) {

                    $result.Add($file);
                }
            }

            return $result.ToArray();
        }

        # gets all sub-directory by searchmask recursively, but skips repositories
        function GetAllDirectories([string] $parentDirectory, [string] $searchMask) {

            # create new list
            [System.Collections.Generic.List[string]] $result = New-Object "System.Collections.Generic.List[string]"

            # is a repository?
            if ([System.IO.Path]::GetFileName($parentDirectory) -eq ".svn" -or [System.IO.Path]::GetFileName($parentDirectory) -eq ".git") {

                # skip
                return $result.ToArray();
            }

            # enumerate all sub-directories
            foreach ($directory in [IO.Directory]::GetDirectories($parentDirectory, "*", [System.IO.SearchOption]::AllDirectories)) {

                # no match?
                if ([System.IO.Path]::GetFileName($directory) -notlike $searchMask) {

                    # skip it
                    continue;
                }

                # is a repository?
                if ([System.IO.Path]::GetFileName($directory) -eq ".svn" -or [System.IO.Path]::GetFileName($directory) -eq ".git") {

                    # skip it
                    continue;
                }

                # add this directory
                $result.Add($directory);
            }

            return $result.ToArray();
        }

        function SearchInFiles() {

            GetAllFilesFromAllDirectories $Source $Files |
            Sort-Object -Descending |
            ForEach-Object -ErrorAction SilentlyContinue {

                # reference next file
                $fn = $PSItem

                # convert to lowercase
                $fnl = $fn.ToLower();

                # determine if it is candidate for content replacement/renaming
                $ok = !$fnl.EndsWith(".jpg") -and !$fnl.EndsWith(".jpeg") -and !$fnl.EndsWith(".gif") -and !$fnl.EndsWith(".bmp") -and !$fnl.EndsWith(".exe") -and !$fnl.EndsWith(".dll") -and !$fnl.EndsWith(".cer") -and !$fnl.EndsWith(".crt") -and !$fnl.EndsWith(".pkf") -and !$fnl.EndsWith(".pdb") -and !$fnl.EndsWith(".so") -and !$fnl.EndsWith(".png") -and !$fnl.EndsWith(".tiff") -and !$fnl.EndsWith(".wav") -and !$fnl.EndsWith(".mp3") -and !$fnl.EndsWith(".avi") -and !$fnl.EndsWith(".mkv") -and !$fnl.EndsWith(".wmv") -and !$fnl.EndsWith(".dll") -and !$fnl.EndsWith(".exe") -and !$fnl.EndsWith(".pdb") -and !$fnl.EndsWith(".tar") -and !$fnl.EndsWith(".7z") -and !$fnl.EndsWith(".png") -and !$fnl.EndsWith(".db") -and !$fnl.EndsWith(".zip") -and !$fnl.EndsWith(".7z") -and !$fnl.EndsWith(".rar") -and !$fnl.EndsWith(".apk") -and !$fnl.EndsWith(".ipa");

                # all good? if not, you should have used -WhatIf ;)
                if ($ok) {

                    # read content as text
                    $oldtxt = [IO.File]::ReadAllText($fn, [System.Text.Encoding]::UTF8);

                    # make replacements
                    $newtxt = $oldtxt.Replace($findText, $replacementText);

                    # has it changed?
                    if (!$oldtxt.Equals($newtxt)) {

                        # not actually making any changes?
                        if ($WhatIfPreference -or $WhatIf) {

                            # output the action we would have performed
                            Write-Verbose "What-If: Would replace in file: '$($fn.Substring($Source.Length+1))'"
                        }
                        else {

                            # store changed content to disk
                            $utf8 = New-Object "System.Text.UTF8Encoding" @($false)
                            [IO.File]::WriteAllText($fn, $newtxt, $utf8);

                            # output the action we have performed
                            Write-Verbose "Replaced in file: '$($fn.Substring($Source.Length+1))'"
                        }
                    }
                }

                # get the name of this file
                $fnOld = [System.IO.Path]::GetFileName($fn);

                # perform renaming inside of this filename
                $fnNew = $fnOld.Replace($findText, $replacementText);

                # has it changed?
                if (!$fnNew.Equals($fnOld)) {

                    # construct new full path
                    $newPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($fn), $fnNew);

                    # not actually making any changes?
                    if ($WhatIfPreference -or $WhatIf) {

                        # output the action we would have performed
                        Write-Verbose "What-If: Would rename file: '$($fn.Substring($Source.Length+1))' --> '$($newPath.Substring($Source.Length+1))'"
                    }
                    else {

                        # rename this file
                        [IO.File]::Move($fn, $newPath);

                        # output the action we have performed
                        Write-Verbose "Renamed file: '$($fn.Substring($Source.Length+1))' --> '$($newPath.Substring($Source.Length+1))'"
                    }
                }
            }
        }

        function RenameDirectories() {

            GetAllDirectories $Source "*" |
            Sort-Object -Descending |
            ForEach-Object -ErrorAction SilentlyContinue {

                # reference next directory
                $fn = $PSItem

                # not current directory?
                if (!$fn -ne ".") {

                    # get the name of this directory
                    $fnOld = [System.IO.Path]::GetFileName($fn);

                    # perform renaming inside of this directoryname
                    $fnNew = $fnOld.Replace($findText, $replacementText);

                    # has the directoryname changed?
                    if (!$fnNew.Equals($fnOld)) {

                        # contruct new full path
                        $pathNew = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($fn), $fnNew));

                        # not actually making any changes?
                        if ($WhatIfPreference -or $WhatIf) {

                            $additional = "";

                            # is there a file, with the exact same name, as this renamed directory?
                            if ([IO.File]::Exists($pathNew)) {

                                $additional = " First deleting file '$fnNew' and then"
                            }

                            # has only the capitalization changed?
                            if ([IO.Directory]::Exists($pathNew) -and $fnOld.ToLower().Equals($fnNew.ToLower())) {

                                Write-Verbose "What-If:$additional Fixing capitalization in directoryname: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"
                                return;
                            }

                            # does another directory already exist with the same name?
                            if ([IO.Directory]::Exists($pathNew)) {

                                Write-Verbose "What-If:$additional Merging files due to directory rename: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"

                                # move all files into existing directory
                                Start-RoboCopy -Source $fn -DestinationDirectory $pathNew -Move -WhatIf

                                return;
                            }

                            # just rename directory
                            Write-Verbose "What-If:$additional Renaming directoryname: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"
                            return;
                        }

                        $additional = "";

                        # is there a file, with the exact same name, as this renamed directory?
                        if ([IO.File]::Exists($pathNew)) {

                            # delete it
                            Remove-Item $pathNew -Force
                            $additional = " Deleted file '$fnNew' and then"
                        }

                        # has only the capitalization changed?
                        if ([IO.Directory]::Exists($pathNew) -and $fnOld.ToLower().Equals($fnNew.ToLower())) {

                            # construct new temporary directoryname
                            $tmpPath = $pathNew + "_" + [DateTime]::UtcNow.Ticks.ToString();

                            # rename back and forth
                            [IO.Directory]::Move($fn, $tmpPath);
                            [IO.Directory]::Move($tmpPath, $pathNew);

                            Write-Verbose "$additional Fixed capitalization in directoryname: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"
                            return;
                        }

                        # does another directory already exist with the same name?
                        if ([IO.Directory]::Exists($pathNew)) {

                            # move all files into existing directory
                            Start-RoboCopy -Source $fn -DestinationDirectory $pathNew -Move

                            # now remove old directory
                            Remove-Item $fn -Force

                            Write-Verbose "$additional Merged files due to directory rename: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"
                            return;
                        }

                        # just rename directory
                        [IO.Directory]::Move($fn, $pathNew);
                        Write-Verbose "$additional Renamed directoryname: '$($fn.Substring($Source.Length+1))' --> '$fnNew'"
                    }
                }
            }
        }

        SearchInFiles

        RenameDirectories
    }

    End {

    }
}

<#
.SYNOPSIS
This function removes all files and folders in the specified directory.

.DESCRIPTION
This function removes all files and folders in the specified directory. The directory path is first expanded using the Expand-Path function.

.PARAMETER Path
The path of the directory to clear.

.PARAMETER DeleteFolder
Also delete the root folder supplied with the Path parameter.

.PARAMETER WhatIf
Displays a message that describes the effect of the command, instead of executing the command.

.EXAMPLE
Remove-AllItems -Path ".\vms"
#>
function Remove-AllItems {

    [Alias("sdel")]
    [CmdletBinding()]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $true,
            HelpMessage = "The path of the directory to clear.")
        ]
        [string] $Path,

        ###############################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Also delete the root folder supplied with the Path parameter"
        )]
        [switch] $DeleteFolder,

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Displays a message that describes the effect of the command, instead of executing the command."
        )]
        [switch] $WhatIf
    )

    function subRoutine([string] $Path, [bool] $deleteFolder, [bool] $WhatIf, [bool] $Verbose, [bool] $suppressFilesWhatIf) {

        # initialize
        [bool] $suppressFilesWhatIf = $suppressFilesWhatIf -eq $true;
        [bool] $WhatIfValue = $WhatIf -or $WhatIfPreference;
        [bool] $VerboseValue = $Verbose -or $VerbosePreference -or $WhatIfValue;

        # Expand the path
        $Path = Expand-Path -FilePath $Path

        # Check if the directory exists
        if (Test-Path $Path) {

            # If were not actually deleting we need this workarround to prevent double files being displayed
            if (!$WhatIfValue -or ($suppressFilesWhatIf -eq $false)) {

                # Get all the files and directories in the target directory
                $items = Get-ChildItem -Path $Path -Recurse -File -Force

                # Loop through each item and delete it
                foreach ($item in $items) {

                    if ($WhatIfValue) {

                        Write-Verbose "What if: Performing the operation `"Remove File`" on target `"$($item.FullName)`"." -Verbose
                    }
                    else {

                        # Remove the file
                        if ($VerboseValue) {

                            Remove-Item -Path $item.FullName -Force -Verbose
                        }
                        else {

                            Remove-Item -Path $item.FullName -Force
                        }
                    }
                }
            }

            # Get all the files and directories in the target directory
            $items = Get-ChildItem -Path $Path -Directory -Recurse -Force

            # Loop through each item and delete it
            foreach ($item in $items) {

                # recurse
                subRoutine $item.FullName $DeleteFolder $WhatIfValue $VerboseValue $WhatIfValue
            }

            if ($DeleteFolder -eq $true) {

                if ($WhatIfValue) {

                    # write whatif action to host
                    Write-Verbose "WhatIf: Deleting folder $Path" -Verbose
                }
                else {

                    # delete folder
                    [System.IO.Directory]::Delete($Path, $true);

                    if ($VerboseValue) {

                        # write whatif action to host
                        Write-Verbose "Deleting folder $Path" -Verbose
                    }
                }
            }
        }
        else {

            if ($VerboseValue) {

                Write-Verbose "The directory $Path does not exist."
            }
        }
    }

    subRoutine $Path $DeleteFolder ($WhatIf -or $WhatIfPreference) ($Verbose -or $VerbosePreference) $false
}

# SIG # Begin signature block
# MIIbzgYJKoZIhvcNAQcCoIIbvzCCG7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCKSzNAFeuX561t
# mFQ26QZpnrpquPK9RDE/jO2XXiEDbqCCFhswggMOMIIB9qADAgECAhBwxOfTiuon
# hU3SZf3YwpWAMA0GCSqGSIb3DQEBCwUAMB8xHTAbBgNVBAMMFEdlblhkZXYgQXV0
# aGVudGljb2RlMB4XDTI0MDUwNTIwMzEzOFoXDTM0MDUwNTE4NDEzOFowHzEdMBsG
# A1UEAwwUR2VuWGRldiBBdXRoZW50aWNvZGUwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQDAD4JXwna5uBAYw54JXXscQPSos9pMeeyV99hvQPs6IcQ/wIXs
# zQ0xdkMGlzo1Nvldyqwa6+OXMyHsZM2D6QA1WjRoTzjT432hlGJT3VrP3R9cvOfg
# sAnVLpZy+4uty2fh5o8NEk4tmULOXDPZBT6NOoRjRCyt+KwCL8yioCFWa/7pqpG0
# niyJka8rhOVQLg8sZ+n5DrSihs1o3PyN28mZLendSbL9Y06cbqadL0J6sn31sw6e
# tpLOToIj1DXQbID0ejeafONHYJ3cKBrQ0TG7aoK8dte4X+iQQuDgA/l7ATxCjC7V
# 18vKRQXzSjvBQvNuWSw6DX2b7sc7dzC9v2T1AgMBAAGjRjBEMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUf8ZHrsKtJB9RD6z2
# x2Txu7wQ1/4wDQYJKoZIhvcNAQELBQADggEBAK/GgNjLVhQkhbFMrJUt3nFfYa2a
# iP/+U2vapwtqeyNBreMiTYwtqkULEPotRlRCMZ+k8kwRhv1bsR82MXK1H74DKcTM
# 0gu62RxOMXz8ij0BjXW9axEWqYGAbbP0EoNyoBzqiLYqXkwCXqIFsywuDZO4QY3D
# 1c+NEKVnPnhf/gufOUrlugklExh9i4QagCSlUObYAa9yBhcoxOHzN0v6mN+I7EjM
# sVsydPsk3NshubldpNSavFUcF477l21eM5F1bFXGTJGgGq9k1/drpILe5e4oLy9w
# sxmdnqpyvbwtPe2+LZx0XSlR5vCfYFih6eV8fNcgvMmAKAcuIuKxKwJkAscwggWN
# MIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBD
# QTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZI
# hvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK
# 2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/G
# nhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJ
# IB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4M
# K7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN
# 2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I
# 11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KIS
# G2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9
# HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4
# pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpy
# FiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS31
# 2amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs
# 1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd
# 823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQw
# RQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZI
# hvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4
# hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3
# rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs
# 9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K
# 2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0n
# ftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3
# JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBa
# Fw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2Vy
# dCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNI
# QTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVC
# X6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf
# 69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvb
# REGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5
# EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbw
# sDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb
# 7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqW
# c0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxm
# SVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+
# s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11G
# deJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCC
# AVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxq
# II+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/
# BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tgh
# QuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qE
# ICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqr
# hc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8o
# VInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SN
# oOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1Os
# Ox0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS
# 1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr
# 2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1V
# wDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL5
# 0CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK
# 5xMOHds3OBqhK/bt1nz8MIIGwjCCBKqgAwIBAgIQBUSv85SdCDmmv9s/X+VhFjAN
# BgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEy
# NTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAwMDAwMFoXDTM0MTAxMzIzNTk1
# OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMSAwHgYD
# VQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCCAiIwDQYJKoZIhvcNAQEBBQAD
# ggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X5dLnXaEOCdwvSKOXejsqnGfc
# YhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86l+uUUI8cIOrHmjsvlmbjaedp/lvD
# 1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa2mq62DvKXd4ZGIX7ReoNYWyd
# /nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgtXkV1lnX+3RChG4PBuOZSlbVH
# 13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60pCFkcOvV5aDaY7Mu6QXuqvYk
# 9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17cz4y7lI0+9S769SgLDSb495u
# ZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BYQfvYsSzhUa+0rRUGFOpiCBPT
# aR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9c33u3Qr/eTQQfqZcClhMAD6F
# aXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw9/sqhux7UjipmAmhcbJsca8+
# uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2ckpMEtGlwJw1Pt7U20clfCKRw
# o+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhRB8qUt+JQofM604qDy0B7AgMB
# AAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1s
# BwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFKW2
# 7xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1l
# U3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZU
# aW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAIEa1t6gqbWYF7xw
# jU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF7SaCinEvGN1Ott5s1+FgnCvt
# 7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrCQDifXcigLiV4JZ0qBXqEKZi2
# V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFcjGnRuSvExnvPnPp44pMadqJp
# ddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8wWkZus8W8oM3NG6wQSbd3lqX
# TzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbFKNOt50MAcN7MmJ4ZiQPq1JE3
# 701S88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP4xeR0arAVeOGv6wnLEHQmjNK
# qDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VPNTwAvb6cKmx5AdzaROY63jg7
# B145WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvrmoI1VygWy2nyMpqy0tg6uLFG
# hmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2obhDLN9OTH0eaHDAdwrUAuBc
# YLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJuEbTbDJ8WC9nR2XlG3O2mflr
# LAZG70Ee8PBf4NvZrZCARK+AEEGKMYIFCTCCBQUCAQEwMzAfMR0wGwYDVQQDDBRH
# ZW5YZGV2IEF1dGhlbnRpY29kZQIQcMTn04rqJ4VN0mX92MKVgDANBglghkgBZQME
# AgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCBeQyiBf8ZaaPtqfYiLjjqOdlIIF1PJHQ9lnkG3s5BXHzANBgkq
# hkiG9w0BAQEFAASCAQC8O1nZceqFK4WoKFFBL7B+r+NKf9/DwagRejXDNMKHjoTx
# ayy70P2NdfFyUF/3mLCaamy35G6/+1JioWr34d/WHvmwdElX5eHe1dWyezLSLN8A
# GYLDDAjwTVF72s3STmYi8iDe9/vNZLNASaADIb3XrvkDnwYVC7RREDI5Mr/m7MBa
# ued3IH8U9KXVbHyaX4Dj0gSgItXUp7p0lORvjgfO7AoaSyc+z4wcim4Nh62j51Sk
# G1ZYsGlRA1ChHfsx33+L5eyWnvwaeew15IHbWJ57u7dUsXeJFrcuO9MEnuJchGu4
# knekF8rGhjpnvMihvETeN9n4HzhjOjVT3LTFNKYSoYIDIDCCAxwGCSqGSIb3DQEJ
# BjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hB
# MjU2IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQME
# AgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTI0MDUwNTIxMjEyOFowLwYJKoZIhvcNAQkEMSIEIIniL5TvOS2nbx2fHHN6VeHg
# ilTtELS+lDnBUMWYx4MiMA0GCSqGSIb3DQEBAQUABIICAF1K8fB835noXP4dpDWd
# BP2oya8aKrEOeTZT1LNkLEXHutrgALyDtsG9IJiytbun5VkrpiPOwZUqAtg441oo
# 9iww2Z3quN+3UoLCf2vvRz+hB4zdrMqWxMgMiGJNr137LNuTwJcoYtyF1rD2Ap0T
# JL429cayhKEmq+XUEOSuskIGKGw+3QfTMsmfkwDMXCce0mbqoajC5AuvjT061Vkp
# ep7d71cNDmRi/B41wzNUl+QklkR0SbNqXezGoKb/XHwU27UNEnwabZgYcETZSzmu
# aECbokRtLkbYD37eblQsUR41BkmfkzGkCDSuMkqqd9fpdHF0MgNxk6QbcOJpr4ZZ
# 1Axr27tOD5KhtyXXLKO+K+rUXta1P4pW5t1gV03AcNodIMFa2Yey4rmKRqW641nh
# t1S1KPgFpEDdLYXA9fKBF0BWPw4u26CeILApmkGuiYRWMSE0axZgw8KI56oZ8q3b
# 0P7HhH5CXhpMH/6TCc9GQeffo+3PYEmnZkkOOXnTogdo2t1HNNmTUmd78T6pP4WJ
# RAVjBcWeaoVoG83nW/oCOtqPIyMOQX6yE8UsHdzwCWfl2l2+oeof5yANak2h08jZ
# glnInMSgWXEmxvqcubyeBudhwiF8JrMKc30PkmhGQNYsrgnmHaAFwy3JbcrM1kPd
# zS+/bbaODOTrK8yHLyOAr5oD
# SIG # End signature block
