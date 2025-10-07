<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Start-RoboCopy.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.292.2025
################################################################################
MIT License

Copyright 2021-2025 GenXdev

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
################################################################################>
########################################################################
<#
.SYNOPSIS
Provides a PowerShell wrapper for Microsoft's Robust Copy (RoboCopy) utility.

.DESCRIPTION
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

.PARAMETER Source
The source directory, file path, or directory with search mask to copy from.

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
        ########################################################################Mirror a directory with security settings
Start-RoboCopy -Source "C:\Projects" -DestinationDirectory "D:\Backup" `
    -Mirror -IncludeSecurity

.EXAMPLE
        ########################################################################Monitor and sync changes every 10 minutes
Start-RoboCopy -Source "C:\Documents" -DestinationDirectory "\\server\share" `
    -MonitorMode -MonitorModeThresholdMinutes 10

.LINK
https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy

.LINK
https://en.wikipedia.org/wiki/Robocopy

#>
function Start-RoboCopy {
    [CmdLetBinding(
        DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [Alias('xc', 'rc')]
    Param
    (
        ########################################################################

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline = $false,
            HelpMessage = 'The directory, filepath, or directory+searchmask'
        )]
        [string]$Source,
        ########################################################################

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $false,
            HelpMessage = "The destination directory to place the copied files and directories into.
            If this directory does not exist yet, all missing directories will be created.
            Default value = `".\`""
        )]
        [string]$DestinationDirectory = ".$([System.IO.Path]::DirectorySeparatorChar)",
        ########################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 2,
            HelpMessage = "Optional searchmask for selecting the files that need to be copied.
            Default value = '*'"
        )]
        [SupportsWildcards()]
        [string[]] $Files = @(),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source'
        )]
        [switch] $Mirror,
        ########################################################################

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will move instead of copy all files from source to destination'
        )]
        [switch] $Move,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will also copy ownership, security descriptors and auditing information of files and directories'
        )]
        [switch] $IncludeSecurity,
        ########################################################################
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Copies only files from source and skips sub-directories (no recurse)'
        )]
        [switch] $SkipDirectories,
        ########################################################################
        [Parameter(
            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Does not copy directories if they would be empty'
        )]
        [switch] $SkipEmptyDirectories,
        ########################################################################
        [Parameter(
            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Create directory tree only'
        )]
        [switch] $CopyOnlyDirectoryTreeStructure,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Create directory tree and zero-length files only'
        )]
        [switch] $CopyOnlyDirectoryTreeStructureAndEmptyFiles,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy symbolic links, junctions or the content they point to"
        )]
        [switch] $SkipAllSymbolicLinks,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy file symbolic links but do follow directory junctions"
        )]
        [switch] $SkipSymbolicFileLinks,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Instead of copying the content where symbolic links point to, copy the links themselves'
        )]
        [switch] $CopySymbolicLinksAsLinks,
        ########################################################################
        [Parameter(

            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't copy directory junctions (symbolic link for a folder) or the content they point to"
        )]
        [switch] $SkipJunctions,
        ########################################################################
        [Parameter(

            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Instead of copying the content where junctions point to, copy the junctions themselves'
        )]
        [switch] $CopyJunctionsAsJunctons,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will copy all files even if they are older then the ones in the destination'
        )]
        [switch] $Force,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Copies only files that have the archive attribute set'
        )]
        [switch] $SkipFilesWithoutArchiveAttribute,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'In addition of copying only files that have the archive attribute set, will then reset this attribute on the source'
        )]
        [switch] $ResetArchiveAttributeAfterSelection,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Exclude any files that matches any of these names/paths/wildcards'
        )]
        [SupportsWildcards()]
        [string[]] $FileExcludeFilter = @(),
        ########################################################################
        [Parameter(
            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Exclude any directories that matches any of these names/paths/wildcards'
        )]
        [SupportsWildcards()]
        [string[]] $DirectoryExcludeFilter = @(),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Copy only files that have all these attributes set [RASHCNETO]'
        )]
        [string] $AttributeIncludeFilter,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Exclude files that have any of these attributes set [RASHCNETO]'
        )]
        [string] $AttributeExcludeFilter,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will set the given attributes to copied files [RASHCNETO]'
        )]
        [string] $SetAttributesAfterCopy,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will remove the given attributes from copied files [RASHCNETO]'
        )]
        [string] $RemoveAttributesAfterCopy,
        ########################################################################
        [ValidateRange(1, 1000000)]
        [Parameter(
            ParameterSetName = 'SkipDirectories',
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Only copy the top n levels of the source directory tree'
        )]
        [int] $MaxSubDirTreeLevelDepth = -1,
        ########################################################################
        [ValidateRange(0, 9999999999999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that are not at least n bytes in size'
        )]
        [int] $MinFileSize = -1,
        ########################################################################
        [ValidateRange(0, 9999999999999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that are larger then n bytes'
        )]
        [int] $MaxFileSize = -1,
        ########################################################################
        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that are not at least: n days old OR created before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)'
        )]
        [int] $MinFileAge = -1,
        ########################################################################
        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)'
        )]
        [int] $MaxFileAge = -1,
        ########################################################################
        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)'
        )]
        [int] $MinLastAccessAge = -1,
        ########################################################################
        [ValidateRange(0, 99999999)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)'
        )]
        [int] $MaxLastAccessAge = -1,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will shortly pause and retry when I/O errors occur during copying'
        )]
        [switch] $RecoveryMode,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes'
        )]
        [switch] $MonitorMode,
        ########################################################################
        [ValidateRange(1, 144000)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Run again in n minutes Time, if changed'
        )]
        [int] $MonitorModeThresholdMinutes = -1,
        ########################################################################
        [ValidateRange(1, 1000000000)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Run again when more then n changes seen'
        )]
        [int] $MonitorModeThresholdNrOfChanges = -1,
        ########################################################################
        [ValidateRange(0, 2359)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Run hours - times when new copies may be started, start-time, range 0000:2359'
        )]
        [int] $MonitorModeRunHoursFrom = -1,
        ########################################################################
        [ValidateRange(0, 2359)]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Run hours - times when new copies may be started, end-time, range 0000:2359'
        )]
        [int] $MonitorModeRunHoursUntil = -1,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'If specified, logging will also be done to specified file'
        )]
        [string] $LogFilePath,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Don't append to the specified logfile, but overwrite instead"
        )]
        [switch] $LogfileOverwrite,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Include all scanned directory names in output'
        )]
        [switch] $LogDirectoryNames,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Include all scanned file names in output, even skipped onces'
        )]
        [switch] $LogAllFileNames,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Output status as UNICODE'
        )]
        [switch] $Unicode,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Enables optimization for copying large files'
        )]
        [switch] $LargeFiles,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'Optimize performance by doing multithreaded copying'
        )]
        [switch] $MultiThreaded,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = 'If applicable use compression when copying files between servers to safe bandwidth and time'
        )]
        [switch] $CompressibleContent,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromRemainingArguments,
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
        [string] $Override
        ########################################################################
    )

    Begin {
        # initialize robocopy path and validate system requirements
        Microsoft.PowerShell.Utility\Write-Verbose "Initializing RoboCopy with source '$Source' and destination '$DestinationDirectory'"

        ########################################################################

        # initialize settings
        $RobocopyPath = "$env:SystemRoot\system32\robocopy.exe";

        # normalize to current directory
        $Source = GenXdev.FileSystem\Expand-Path $Source
        $DestinationDirectory = GenXdev.FileSystem\Expand-Path $DestinationDirectory

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
                    if (!$SourceSearchMask.Contains('*') -and !$SourceSearchMask.Contains('?')) {

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

            $Files = @('*');
        }

        # destination directory does not exist yet?
        if ([IO.Directory]::Exists($DestinationDirectory) -eq $false) {

            # create it
            [IO.Directory]::CreateDirectory($DestinationDirectory) | Microsoft.PowerShell.Core\Out-Null
        }

        ########################################################################

        function _CurrentUserHasElevatedRights() {

            $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $p = Microsoft.PowerShell.Utility\New-Object System.Security.Principal.WindowsPrincipal($id)

            if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or
                $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::BackupOperator)) {

                return $true;
            }

            return $false;
        }

        function ConstructFileFilterSet([string[]] $FileFilterSet, [string] $CommandName) {

            $result = '';

            $FileFilterSet | Microsoft.PowerShell.Core\ForEach-Object {

                $result = "$result '$PSItem'".Trim()
            }

            return $result;
        }

        function SanitizeAttributeSet([string] $AttributeSet, [string] $CommandName) {

            $AttributeSetNew = '';
            $AttributeSet.Replace('[', '').Replace(']', '').ToUpperInvariant().ToCharArray() | Microsoft.PowerShell.Core\ForEach-Object {

                if (('RASHCNETO'.IndexOf($PSItem) -ge 0) -and ($AttributeSetNew.IndexOf($PSItem) -lt 0)) {

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
            $switchesDictionary = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.Dictionary[String, String]';

            if ([String]::IsNullOrWhiteSpace($Switches)) {

                return $switchesDictionary
            }

            $switchesCleaned = " $Switches ";

            # remove spaces
            while ($switchesCleaned.IndexOf('  /') -ge 0) {

                $switchesCleaned = $switchesCleaned.Replace('  /', ' /');
            }
            while ($switchesCleaned.IndexOf('  -/') -ge 0) {

                $switchesCleaned = $switchesCleaned.Replace('  -/', ' -/');
            }

            # split up
            $allSwitches = $switchesCleaned.Replace(' -/', ' /-').Split([string[]]@(' /'), [System.StringSplitOptions]::RemoveEmptyEntries);

            # enumerate switches
            $allSwitches | Microsoft.PowerShell.Core\ForEach-Object -ErrorAction SilentlyContinue {

                # add to Dictionary
                $switchesDictionary["$($PSItem.Trim().Split(' ')[0].Split(':' )[0].Trim().ToUpperInvariant())"] = $PSItem.Trim()
            }

            return $switchesDictionary;
        }

        function overrideAndCleanSwitches([string] $Switches) {

            $autoGeneratedSwitches = (getSwitchesDictionary $Switches)
            $overridenSwitches = (getSwitchesDictionary $Override)
            $newSwitches = '';

            $autoGeneratedSwitches.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object -ErrorAction SilentlyContinue {

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

            $overridenSwitches.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object -ErrorAction SilentlyContinue {

                # not already processed above?
                if (!$PSItem.Key.StartsWith('-') -and !$autoGeneratedSwitches.ContainsKey("$($PSItem.Key)")) {

                    # add it
                    $newSwitches += " /$($PSItem.Value)"
                }
            }

            return $newSwitches.Trim();
        }

        ########################################################################

        # /B            █  copy files in Backup mode.
        # /ZB           █  use restartable mode; if access denied use Backup mode.
        if (_CurrentUserHasElevatedRights) {

            $ParamMode = '/B'
        }
        else {
            $ParamMode = ''
        }

        # /MOV			█  MOVE files AND dirs (delete from source after copying).
        $ParamMOV = '';

        # /MIR			█ MIRror a directory tree (equivalent to /E plus /PURGE).
        $ParamMIR = '';

        # /SECFIX		█ FIX file SECurity on all files, even skipped files.
        $ParamSECFIX = '';

        # /E			█  copy subdirectories, including Empty ones.
        # /S			█ copy Subdirectories, but not empty ones.
        $ParamDirs = '/E'

        # /COPY			█ what to COPY for files (default is /COPY:DAT).
        $ParamCOPY = '/COPY:DAT'

        # /XO			█ eXclude Older files.
        $ParamXO = '/XO';

        # /IM			█  Include Modified files (differing change times).
        $ParamIM = '/IM';

        # /IT			█ Include Tweaked files.
        $ParamIT = '/IT';

        # /IS			█ Include Same files.
        $ParamIS = '';

        # /EFSRAW		█  copy all encrypted files in EFS RAW mode.
        $ParamEFSRAW = '';

        # /NOOFFLOAD	█ 	copy files without using the Windows Copy Offload mechanism.
        $ParamNOOFFLOAD = '';

        # /R			█ number of Retries on failed copies: default 1 million.
        $ParamR = '/R:0';

        # /W			█ Wait time between retries: default is 30 seconds.
        $ParamW = '/W:0';

        # /J			█ copy using unbuffered I/O (recommended for large files).
        $paramJ = '';

        # /MT           █ Do multi-threaded copies with n threads (default 8).
        $paramMT = '';

        # /NDL			█ No Directory List - don't log directory names.
        $ParamNDL = '/NDL';

        # /X			█ report all eXtra files, not just those selected.
        $ParamX = '';

        # /V			█  produce Verbose output, showing skipped files.
        $ParamV = '';

        # /CREATE		█  CREATE directory tree and zero-length files only.
        $ParamCREATE = '';

        # /XJ			█ eXclude symbolic links (for both files and directories) and Junction points.
        $ParamXJ = '';

        # /XJD			█ eXclude symbolic links for Directories and Junction points.
        $ParamXJD = '';

        # /XJF			█  eXclude symbolic links for Files.
        $ParamXJF = '';

        # /SJ			█ copy Junctions as junctions instead of as the junction targets.
        $ParamSJ = '';

        # /SL			█ copy Symbolic Links as links instead of as the link targets.
        $ParamSL = '';

        # /A			█  copy only files with the Archive attribute set.
        # /M			█ copy only files with the Archive attribute and reset it.
        $ParamArchive = '';

        # /XF
        $ParamXF = '' # █ eXclude Files matching given names/paths/wildcards.

        # /XD
        $ParamXD = '' # █ eXclude Directories matching given names/paths/wildcards.

        # /IA			█ Include only files with any of the given Attributes set.
        $ParamIA = '';

        # /XA			█  eXclude files with any of the given Attributes set.
        $ParamXA = '';

        # /A+			█  add the given Attributes to copied files
        $ParamAttrSet = '';

        # /A-			█ remove the given Attributes from copied files.
        $ParamAttrRemove = '';

        # /LEV			█ only copy the top n LEVels of the source directory tree.
        $ParamLEV = '';

        # /MIN			█  MINimum file size - exclude files smaller than n bytes.
        $ParamMIN = '';

        # /MAX			█  MAXimum file size - exclude files bigger than n bytes.
        $ParamMAX = '';

        # /MINAGE 	    █ MINimum file AGE - exclude files newer than n days/date.
        $ParamMINAGE = '';

        # /MAXAGE		█ MAXimum file AGE - exclude files older than n days/date.
        $ParamMaxAGE = '';

        # /LOG			█ output status to LOG file (overwrite existing log).
        # /LOG+         █ output status to LOG file (append to existing log).
        $ParamLOG = '';

        # /TEE          █ output to console window, as well as the log file.
        $ParamTee = '';

        # /UNICODE		█  output status as UNICODE.
        $ParamUnicode = '';

        # /RH			█  Run Hours - times when new copies may be started.
        $ParamRH = '';

        # /MON			█ MONitor source; run again when more than n changes seen.
        # /MOT          █ MOnitor source; run again in m minutes Time, if changed.
        $ParamMON = '';

        # /MAXLAD		█  MAXimum Last Access Date - exclude files unused since n.
        $ParamMAXLAD = '';

        # /MINLAD		█  MINimum Last Access Date - exclude files used since n.
        $ParamMINLAD = '';

        # /COMPRESS		█  Request network compression during file transfer, if applicable.
        $ParamCOMPRESS = '';

        ########################################################################

        # -Mirror ➜ Synchronizes the content of specified directories, will also delete any files and directories in the destination that do not exist in the source
        if ($Mirror -eq $true) {

            $ParamMIR = '/MIR' #                          █ MIRror a directory tree (equivalent to /E plus /PURGE).
        }

        # -Move ➜ Will move instead of copy all files from source to destination
        if ($Move -eq $true) {

            $ParamMOV = '/MOV' #                          █ MOVE files AND dirs (delete from source after copying).
        }

        # -IncludeSecurity ➜ Will also copy ownership, security descriptors and auditing information of files and directories
        if ($IncludeSecurity -eq $true) {

            $ParamSECFIX = '/SECFIX' #                    █ FIX file SECurity on all files, even skipped files.
            $ParamCOPY = "$($ParamCOPY)SOU" #             █ what to COPY for files (default is /COPY:DAT).
            $ParamEFSRAW = '/EFSRAW' #                    █ copy all encrypted files in EFS RAW mode.
        }

        # -SkipDirectories ➜ Copies only files from source and skips sub-directories (no recurse)
        if ($SkipDirectories -eq $true) {

            $ParamDirs = '' #                             █ copy subdirectories, including Empty ones.
        }
        else {

            # -SkipEmptyDirectories ➜ Does not copy directories if they would be empty
            if ($SkipEmptyDirectories -eq $true) {

                $ParamDirs = '/S' #                       █ copy Subdirectories, but not empty ones.
            }
        }

        # -CopyOnlyDirectoryTreeStructure ➜ Create directory tree only
        if ($CopyOnlyDirectoryTreeStructure -eq $true) {

            $ParamCREATE = '/CREATE'; #                   █ CREATE directory tree and zero-length files only.
            $Files = @('DontCopy4nyF1lés') #              █ File(s) to copy  (names/wildcards: default is "*.*")
        }
        else {
            # -CopyOnlyDirectoryTreeStructureAndEmptyFiles ➜ Create directory tree and zero-length files only
            if ($CopyOnlyDirectoryTreeStructureAndEmptyFiles -eq $true) {

                $ParamCREATE = '/CREATE'; #               █ CREATE directory tree and zero-length files only.
            }
        }

        # -SkipAllSymbolicLinks ➜ Don't copy symbolic links, junctions or the content they point to
        if ($SkipAllSymbolicLinks -eq $true) {

            $ParamXJ = '/XJ'; #                           █ eXclude symbolic links (for both files and directories) and Junction points.
        }
        else {

            # -SkipSymbolicFileLinks ➜ Don't copy file symbolic links but do follow directory junctions
            if ($SkipSymbolicFileLinks -eq $true) {

                $ParamXJF = '/XJF'; #                     █ eXclude symbolic links for Files.
            }
            else {

                # -CopySymbolicLinksAsLinks ➜ Instead of copying the content where symbolic links point to, copy the links themselves
                if ($CopySymbolicLinksAsLinks -eq $true) {

                    $ParamSL = '/SL'; #                   █ copy Symbolic Links as links instead of as the link targets.
                }
            }

            # -SkipJunctions ➜ Don't copy directory junctions (symbolic link for a folder) or the content they point to
            if ($SkipJunctions -eq $true) {

                $ParamXJD = '/XJD'; #                     █ eXclude symbolic links for Directories and Junction points.
            }
            else {

                # -CopyJunctionsAsJunctons ➜ Instead of copying the content where junctions point to, copy the junctions themselves
                if ($CopyJunctionsAsJunctons -eq $true) {

                    $ParamSJ = '/SJ'; #                   █ copy Junctions as junctions instead of as the junction targets.
                }
            }
        }

        ########################################################################

        # -Force ➜ Will copy all files even if they are older then the ones in the destination
        if ($Force -eq $true) {

            $ParamXO = '' #                               █ eXclude Older files.
            $ParamIT = '/IT' #                            █ Include Tweaked files.
            $ParamIS = '/IS' #                            █ Include Same files.
        }

        ########################################################################

        # -SkipFilesWithoutArchiveAttribute ➜ Copies only files that have the archive attribute set
        if ($SkipFilesWithoutArchiveAttribute -eq $true) {

            $ParamArchive = '/A' #                        █ copy only files with the Archive attribute set.
        }

        # -ResetArchiveAttributeAfterSelection ➜ In addition of copying only files that have the archive attribute set, will then reset this attribute on the source
        if ($ResetArchiveAttributeAfterSelection -eq $true) {

            $ParamArchive = '/M' #                        █ copy only files with the Archive attribute and reset it
        }

        ########################################################################

        # -FileExcludeFilter ➜ Exclude any files that matches any of these names/paths/wildcards
        if ($FileExcludeFilter.Length -gt 0) {

            $Filter = "$((ConstructFileFilterSet $FileExcludeFilter 'FileExcludeFilter'))";
            $ParamXF = "/XF $Filter" #                    █ eXclude Files matching given names/paths/wildcards.
        }

        # -DirectoryExcludeFilter ➜ Exclude any directories that matches any of these names/paths/wildcards
        if ($DirectoryExcludeFilter.Length -gt 0) {

            $Filter = "$((ConstructFileFilterSet $DirectoryExcludeFilter 'DirectoryExcludeFilter'))";
            $ParamXD = "/XD $Filter" #                    █ eXclude Directories matching given names/paths/wildcards.
        }

        # -AttributeIncludeFilter ➜ Copy only files that have all these attributes set [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($AttributeIncludeFilter) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $AttributeIncludeFilter 'AttributeIncludeFilter'))";
            $ParamIA = "/IA:$Filter" #                    █ Include only files with any of the given Attributes set.
        }

        # -AttributeExcludeFilter ➜ Exclude files that have any of these attributes set [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($AttributeExcludeFilter) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $AttributeExcludeFilter 'AttributeExcludeFilter'))";
            $ParamXA = "/XA:$Filter" #                    █ eXclude files with any of the given Attributes set.
        }

        # -SetAttributesAfterCopy ➜ Will set the given attributes to copied files [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($SetAttributesAfterCopy) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $SetAttributesAfterCopy 'SetAttributesAfterCopy'))";
            $ParamAttrSet = "/A+:$Filter" #               █ add the given Attributes to copied files
        }

        # -RemoveAttributesAfterCopy ➜ Will remove the given attributes from copied files [RASHCNETO]
        if ([string]::IsNullOrWhiteSpace($RemoveAttributesAfterCopy) -eq $false) {

            $Filter = "$((SanitizeAttributeSet $RemoveAttributesAfterCopy 'RemoveAttributesAfterCopy'))";
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

            CheckAgeInteger $MinFileAge 'MinFileAge'

            $ParamMINAGE = "/MINAGE:$MinFileAge" #        █ MINimum file AGE - exclude files newer than n days/date.
        }

        # -MaxFileAge ➜ Skip files that are older then: n days OR created after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MaxFileAge -ge 0) {

            CheckAgeInteger $MaxFileAge 'MaxFileAge'

            $ParamMaxAGE = "/MAXAGE:$MaxFileAge" #        █ MAXimum file AGE - exclude files older than n days/date.
        }

        # -MinLastAccessAge ➜ Skip files that are accessed within the last: n days OR before n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MinLastAccessAge -ge 0) {

            CheckAgeInteger $MinLastAccessAge 'MinLastAccessAge'

            $ParamMINLAD = "/MINLAD:$MinLastAccessAge" #  █ MINimum Last Access Date - exclude files used since n.
        }

        # -MaxLastAccessAge ➜ Skip files that have not been accessed in: n days OR after n date (if n < 1900 then n = n days, else n = YYYYMMDD date)
        if ($MaxLastAccessAge -ge 0) {

            CheckAgeInteger $MaxLastAccessAge 'MaxLastAccessAge'

            $ParamMAXLAD = "/MAXLAD:$MaxLastAccessAge" #  █ MAXimum Last Access Date - exclude files unused since n.
        }

        ########################################################################

        # -RecoveryMode ➜ Will shortly pause and retry when I/O errors occur during copying
        if ($RecoveryMode -eq $true) {

            $ParamNOOFFLOAD = '/NOOFFLOAD' #              █ copy files without using the Windows Copy Offload mechanism.
            $ParamR = '/R:25' #                           █ number of Retries on failed copies: default 1 million.
            $ParamW = '/W:1' #                            █ Wait time between retries: default is 30 seconds.
        }

        ########################################################################

        # -MonitorMode ➜ Will stay active after copying, and copy additional changes after a a default threshold of 10 minutes
        if ($MonitorMode -eq $true) {

            $ParamMON = '/MOT:10' #                       █ MOnitor source; run again in m minutes Time, if changed.
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

                $MonitorModeRunHoursFromStr = "$MonitorModeRunHoursFrom".PadLeft('0', 4);
                [int] $FromMinute = $MonitorModeRunHoursFromStr.Substring(2, 2);
                if ($FromMinute -lt 59) {

                    throw "Could not parse '-MonitorModeRunHoursFrom $MonitorModeRunHoursFromStr' parameter, range 0000:2359"
                }
            }
            else {
                $MonitorModeRunHoursFromStr = '0000';
            }

            # -MonitorModeRunHoursUntil ➜ Run hours - times when new copies may be started, end-time, range 0000:2359
            if ($MonitorModeRunHoursUntil -ge 0) {

                $MonitorModeRunHoursUntilStr = "$MonitorModeRunHoursUntil".PadLeft('0', 4);
                [int] $UntilMinute = $MonitorModeRunHoursUntilStr.Substring(2, 2);

                if ($UntilMinute -lt 59) {

                    throw "Could not parse '-MonitorModeRunHoursUntil $MonitorModeRunHoursUntilStr' parameter, range 0000:2359"
                }
            }
            else {
                $MonitorModeRunHoursUntilStr = '2359'
            }

            $RHArgs = "$MonitorModeRunHoursFromStr-$MonitorModeRunHoursUntilStr"
            $ParamRH = "/RH:$RHArgs" #                    █ Run Hours - times when new copies may be started.
        }

        ########################################################################

        # -Unicode -> Output status as UNICODE
        if ($Unicode -eq $true) {

            $ParamUnicode = '/UNICODE' #                  █ output status as UNICODE.
        }

        # -LogFilePath ➜ If specified, logging will also be done to specified file
        if ([string]::IsNullOrWhiteSpace($LogFilePath) -eq $false) {

            $LogArgs = "'$((GenXdev.FileSystem\Expand-Path $LogFilePath $true).ToString().Replace("'", "''"))'"
            $LogPrefix = '';
            $ParamTee = '/TEE' #                          █ output to console window, as well as the log file

            # -Unicode -> Output status as UNICODE
            if ($Unicode -eq $true) { $LogPrefix = 'UNI'; }

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

            $ParamNDL = '' #                              █ No Directory List - don't log directory names.
        }

        # -LogAllFileNames ➜ Include all scanned file names in output, even skipped onces
        if ($LogAllFileNames -eq $true) {

            $ParamX = '/X' #                              █ report all eXtra files, not just those selected.
            $ParamV = '/V' #                              █ produce Verbose output, showing skipped files.
        }

        # -LargeFiles ➜ Enables optimization for copying large files
        if ($LargeFiles -eq $true) {

            $ParamMode = '/ZB' #                          █ use restartable mode; if access denied use Backup mode.
            $paramJ = '/J' #                              █ copy using unbuffered I/O (recommended for large files).
        }

        # -LargeFiles ➜ Optimize performance by doing multithreaded copying
        if ($MultiThreaded -eq $true) {

            $paramMT = '/MT:16' #                         █ Do multi-threaded copies with n threads (default 8).
        }

        # -CompressibleContent ➜ If applicable use compression when copying files between servers to safe bandwidth and time
        if ($CompressibleContent -eq $true) {

            $ParamCOMPRESS = '/COMPRESS' #                █ Request network compression during file transfer, if applicable.
        }

        ########################################################################

        $switches = "$ParamDirs /TS /FP $ParamMode /DCOPY:DAT /NP $ParamMT $ParamMOV $ParamMIR $ParamSECFIX $ParamCOPY $ParamXO $ParamIM $ParamIT $ParamIS $ParamEFSRAW $ParamNOOFFLOAD $ParamR $ParamW $paramJ $ParamNDL $ParamX $ParamV $ParamCREATE $ParamXJ $ParamXJD $ParamXJF $ParamSJ $ParamSL $ParamArchive $ParamIA $ParamXA $ParamAttrSet $ParamAttrRemove $ParamLEV $ParamMIN $ParamMAX $ParamMINAGE $ParamMaxAGE $ParamLOG $ParamTee $ParamUnicode $ParamRH $ParamMON $ParamMON $ParamMAXLAD $ParamMINLAD $ParamCOMPRESS $ParamXF $ParamXD".Replace('  ', ' ').Trim();
        $switchesCleaned = overrideAndCleanSwitches($switches)
        $FilesArgs = ConstructFileFilterSet $Files 'FileMask'
        $cmdLine = "& '$($RobocopyPath.Replace("'", "''"))' '$($Source.Replace("'", "''"))' '$($DestinationDirectory.Replace("'", "''"))' $FilesArgs $switchesCleaned"
    }

    process {

    }

    end {
        # construct and execute robocopy command
        Microsoft.PowerShell.Utility\Write-Verbose 'Constructing RoboCopy command with selected parameters'

        # collect param help information
        $paramList = @{};
            (& $RobocopyPath -?) | Microsoft.PowerShell.Core\ForEach-Object {
            if ($PSItem.Contains(' :: ')) {
                $s = $PSItem.Split([string[]]@(' :: '), [StringSplitOptions]::RemoveEmptyEntries);
                $paramList."$($s[0].ToLowerInvariant().split(':')[0].Split('[')[0].Trim().split(' ')[0])" = $s[1];
            }
        };

        $first = $true;
        $paramsExplained = @(

            " $switchesCleaned ".Split([string[]]@(' /'), [System.StringSplitOptions]::RemoveEmptyEntries) |
                Microsoft.PowerShell.Core\ForEach-Object {

                    $description = $paramList."/$($PSItem.ToLowerInvariant().split(':')[0].Split('[')[0].Trim().split(' ')[0])"
                    $Space = '                         '; if ($first) { $Space = ''; $first = $false; }
                    "$Space/$($PSItem.ToUpperInvariant().split(':')[0].Split('[')[0].Trim().split(' ')[0].PadRight(15)) --> $description`r`n"
                }
        );
        # create a descriptive operation message based on selected mode
        $operation = if ($Mirror) {
            'Mirror'
        }
        elseif ($Move) {
            'Move'
        }
        else {
            'Copy'
        }

        $target = "$operation from '$Source' to '$DestinationDirectory'"
        $message = "

            RoboCopy would be executed as:
                $($cmdLine.Replace(' /L ', ' '))

            Source      : $Source
            Files       : $Files
            Destination : $DestinationDirectory

            Mirror      : $($Mirror -eq $true)
            Move        : $($Move -eq $true)

            Switches    : $paramsExplained
        "

        if (-not ($PSCmdlet.ShouldProcess($target, $message))) {

            return;
        }

        # execute robocopy with constructed parameters
        Microsoft.PowerShell.Utility\Write-Verbose "Executing RoboCopy command: $cmdLine"

        Microsoft.PowerShell.Utility\Invoke-Expression $cmdLine
    }
}