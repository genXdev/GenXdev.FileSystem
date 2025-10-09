<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-FoundLocation.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.300.2025
################################################################################
Copyright (c)  René Vaessen / GenXdev

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
################################################################################>
################################################################################
<#
.SYNOPSIS
Finds the first matching file or folder and sets the location to it.

.DESCRIPTION
This cmdlet will help you change directories quickly by using search phrases
that will find the first matching folder or file (optional) and changes
directory to it. Supports advanced filtering by content, file attributes,
size, modification dates, and many other criteria.

.PARAMETER Name
File name or pattern to search for. Supports wildcards.

.PARAMETER InputObject
File name or pattern to search for from pipeline input.

.PARAMETER Content
Regular expression pattern to search within file contents.

.PARAMETER Category
Only output files belonging to selected categories (Pictures, Videos, Music,
Documents, etc.).

.PARAMETER MaxDegreeOfParallelism
Maximum degree of parallelism for directory tasks.

.PARAMETER TimeoutSeconds
Optional cancellation timeout in seconds.

.PARAMETER AllDrives
Search across all available drives.

.PARAMETER File
Search for filenames only and change to folder of first found file.

.PARAMETER DirectoriesAndFiles
Include filename matching and change to folder of first found file.

.PARAMETER IncludeAlternateFileStreams
Include alternate data streams in search results.

.PARAMETER NoRecurse
Do not recurse into subdirectories.

.PARAMETER FollowSymlinkAndJunctions
Follow symlinks and junctions during directory traversal.

.PARAMETER IncludeOpticalDiskDrives
Include optical disk drives.

.PARAMETER SearchDrives
Optional: search specific drives.

.PARAMETER DriveLetter
Optional: search specific drives by letter.

.PARAMETER Root
Optional: search specific base folders combined with provided Names.

.PARAMETER IncludeNonTextFileMatching
Include non-text files (binaries, images, etc.) when searching file contents.

.PARAMETER CaseNameMatching
Gets or sets the case-sensitivity for files and directories.

.PARAMETER SearchADSContent
When set, performs content search within alternate data streams (ADS).

.PARAMETER MaxRecursionDepth
Maximum recursion depth for directory traversal. 0 means unlimited.

.PARAMETER MaxFileSize
Maximum file size in bytes to include in results. 0 means unlimited.

.PARAMETER MinFileSize
Minimum file size in bytes to include in results. 0 means no minimum.

.PARAMETER ModifiedAfter
Only include files modified after this date/time (UTC).

.PARAMETER ModifiedBefore
Only include files modified before this date/time (UTC).

.PARAMETER AttributesToSkip
File attributes to skip (e.g., System, Hidden or None).

.PARAMETER Exclude
Exclude files or directories matching these wildcard patterns.

.PARAMETER CaseSensitive
Indicates that the cmdlet matches are case-sensitive.

.PARAMETER Culture
Specifies a culture name to match the specified pattern.

.PARAMETER Encoding
Specifies the type of encoding for the target file.

.PARAMETER NotMatch
The NotMatch parameter finds text that doesn't match the specified pattern.

.PARAMETER SimpleMatch
Indicates that the cmdlet uses a simple match rather than a regular expression.

.PARAMETER Push
Use Push-Location instead of Set-Location and push the location onto the location stack.

.PARAMETER ExactMatch
When set, only exact name matches are considered.

.EXAMPLE
Set-FoundLocation *.Console

Changes to the first directory matching the pattern '*.Console'.

.EXAMPLE
lcd *.Console

Changes to the first directory matching the pattern '*.Console' using the alias.

.EXAMPLE
Set-FoundLocation -Name "*.ps1" -Content "function"

Changes to the directory containing the first PowerShell file that contains
the word 'function'.

.EXAMPLE
Set-FoundLocation *test* -File

Changes to the directory containing the first file with 'test' in its name.

.EXAMPLE
Set-FoundLocation * '1\.\d+\.2025'

Changes to the directory containing the first file which content  matches the pattern '1.\d+\.2025'.
#>
function Set-FoundLocation {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('lcd')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseDeclaredVarsMoreThanAssignments', '')]

    param(
        ########################################################################
        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = "File name or pattern to search for."
        )]
        [Alias("like", "Path", "LiteralPath", "Query", "SearchMask", "Include")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $providedBoundParameters)

            $CurrentLocation = (Microsoft.PowerShell.Management\Get-Location).Path;

            function completeFoundName($foundName, $truncate) {

                $result = $foundName;

                # calculate relative path from search base for cleaner display
                $result = [IO.Path]::GetRelativePath($CurrentLocation, $foundName);

                # ensure relative path appears relative by prefixing with .\
                if (-not [IO.Path]::IsPathRooted($result))
                {
                    # prepend .\ to make it explicitly relative
                    $result = ".\" + $result;
                }

                $result = "'$($result.Replace("'", "''"))'"

                if ($truncate) {

                    if ($result.Length -ge [Console]::BufferWidth-1) {

                        $max = [Math]::Max([Console]::BufferWidth -3, 20);

                        # use /../ in the center
                        $firstPart = [Math]::Floor(($max - 4) / 2);
                        $lastPart = $max - 4 - $firstPart;
                        $result = $result.Substring(0, $firstPart) + '/.../' +
                            $result.Substring($result.Length - $lastPart, $lastPart);
                    }
                }

                $result;
            }

            try {
                # Derive search params from function defaults or bound params (e.g., respect -Root if provided)
                $findParams = GenXdev.FileSystem\Copy-IdenticalParamValues `
                    -FunctionName 'GenXdev.FileSystem\Find-Item' `
                    -BoundParameters $providedBoundParameters;

                $findParams.PassThru = $true
                $findParams.Quiet = $true
                $findParams.ProgressAction = 'SilentlyContinue'
                $findParams.Verbose = $False
                $findParams.WarningAction = 'SilentlyContinue'
                $findParams.ErrorAction = 'SilentlyContinue'
                $findParams.InformationAction = 'SilentlyContinue'
                $findParams.NoLinks = $true
                $findParams.MaxSearchUpDepth = 100
                $findParams.TimeoutSeconds = 5;
                $wtc = $wordToComplete.Trim("'`"".ToCharArray());
                $findParams.Name = $ExactMatch -or $wordToComplete.Contains("*") -or $wordToComplete.Contains("?") ?
                    $wtc : "*$($wtc)*";

                # configure search type based on user preferences
                if ($providedBoundParameters['DirectoriesAndFiles'] -eq $true) {

                    $findParams.FilesAndDirectories = $true
                }

                $NoContentSearch = (-not $Content) -or ($Content.Length -eq 1 -and $Content[0] -eq ".*");

                # search directories by default unless explicitly searching for files
                if ((-not $providedBoundParameters['File']) -and $NoContentSearch) {

                    $findParams.Directory = $true
                }

                # Find matching directories based on the current input
                $matchingDirs = GenXdev.FileSystem\Find-Item @findParams |
                    Microsoft.PowerShell.Core\Where-Object {

                        (($PSItem -is [System.IO.DirectoryInfo]) -and ($PSItem.FullName -ne $CurrentLocation)) -or
                        (($PSItem -is [System.IO.FileInfo]) -and ($PSItem.DirectoryName -ne $CurrentLocation))

                    } |
                    Microsoft.PowerShell.Utility\Select-Object -First 25 | Microsoft.PowerShell.Utility\Sort-Object -Unique -Property FullName

                foreach ($dir in $matchingDirs) {

                    # determine target directory based on result type
                    if ($dir -is [System.IO.DirectoryInfo]) {

                        $completionText = (completeFoundName $dir.FullName)
                        $listText = (completeFoundName $dir.FullName $true)
                        $toolTip = "(Last modified: $($dir.LastWriteTimeUtc))"
                        [System.Management.Automation.CompletionResult]::new($completionText, $listText, 'ParameterValue', $toolTip)
                    }
                    elseif ($dir -is [System.IO.FileInfo]) {

                        $completionText = (completeFoundName $dir.DirectoryName)
                        $listText = (completeFoundName $dir.DirectoryName $true)
                        $toolTip = "(Last modified: $($dir.LastWriteTimeUtc))"
                        [System.Management.Automation.CompletionResult]::new($completionText, $listText, 'ParameterValue', $toolTip)
                    }
                }
            } catch {
                # suppress any errors during tab completion
                Microsoft.PowerShell.Utility\Write-Warning ($_.Exception.Message)
            }
        })]
        [string] $Name,
        ########################################################################
        [Parameter(
            ParameterSetName = 'InputObject',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = (
                "File name or pattern to search for from pipeline input. " +
                "Default is '*'")
        )]
        [Alias('FullName')]
        [SupportsWildcards()]
        [object] $InputObject,
        ########################################################################
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "Regular expression pattern to search within file contents")
        )]
        [Alias("mc", "matchcontent", "regex", "Pattern")]
        [ValidateNotNull()]
        [SupportsWildcards()]
        [string[]] $Content = @(".*"),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Only output files belonging to selected categories")
        )]
        [Alias("filetype")]
        [ValidateSet(
            "Pictures",
            "Videos",
            "Music",
            "Documents",
            "Spreadsheets",
            "Presentations",
            "Archives",
            "Installers",
            "Executables",
            "Databases",
            "DesignFiles",
            "Ebooks",
            "Subtitles",
            "Fonts",
            "EmailFiles",
            "3DModels",
            "GameAssets",
            "MedicalFiles",
            "FinancialFiles",
            "LegalFiles",
            "SourceCode",
            "Scripts",
            "MarkupAndData",
            "Configuration",
            "Logs",
            "TextFiles",
            "WebFiles",
            "MusicLyricsAndChords",
            "CreativeWriting",
            "Recipes",
            "ResearchFiles"
        )]
        [string[]] $Category,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Maximum degree of parallelism for directory tasks")
        )]
        [Alias("threads")]
        [int] $MaxDegreeOfParallelism = 0,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optional: cancellation timeout in seconds"
        )]
        [Alias("maxseconds")]
        [int] $TimeoutSeconds,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Search across all available drives"
        )]
        [switch] $AllDrives,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Search for filenames only and change to folder of first " +
                "found file")
        )]
        [Alias("filename")]
        [switch] $File,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Include filename matching and change to folder of first " +
                "found file")
        )]
        [Alias("both", "FilesAndDirectories")]
        [switch] $DirectoriesAndFiles,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Include alternate data streams in search results")
        )]
        [Alias("ads")]
        [switch] $IncludeAlternateFileStreams,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Do not recurse into subdirectories"
        )]
        [Alias("nr")]
        [switch] $NoRecurse,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Follow symlinks and junctions during directory traversal")
        )]
        [Alias("symlinks", "sl")]
        [switch] $FollowSymlinkAndJunctions,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Include optical disk drives"
        )]
        [switch] $IncludeOpticalDiskDrives,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optional: search specific drives"
        )]
        [Alias("drives")]
        [string[]] $SearchDrives = @(),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optional: search specific drives"
        )]
        [char[]] $DriveLetter = @(),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Optional: search specific base folders combined with " +
                "provided Names")
        )]
        [string[]] $Root = @(),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Include non-text files (binaries, images, etc.) when " +
                "searching file contents")
        )]
        [Alias("binary")]
        [switch] $IncludeNonTextFileMatching,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Gets or sets the case-sensitivity for files and directories")
        )]
        [Alias("casing", "CaseSearchMaskMatching")]
        [System.IO.MatchCasing] $CaseNameMatching = (
            [System.IO.MatchCasing]::PlatformDefault),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "When set, performs content search within alternate data " +
                "streams (ADS). When not set, outputs ADS file info without " +
                "searching their content.")
        )]
        [Alias("sads")]
        [switch] $SearchADSContent,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Maximum recursion depth for directory traversal. 0 means " +
                "unlimited.")
        )]
        [Alias("md", "depth", "maxdepth")]
        [int] $MaxRecursionDepth = 0,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Maximum file size in bytes to include in results. 0 means " +
                "unlimited.")
        )]
        [Alias("maxlength", "maxsize")]
        [long] $MaxFileSize = 0,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Minimum file size in bytes to include in results. 0 means " +
                "no minimum.")
        )]
        [Alias("minsize", "minlength")]
        [long] $MinFileSize = 0,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Only include files modified after this date/time (UTC).")
        )]
        [Alias("ma", "after")]
        [DateTime] $ModifiedAfter,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Only include files modified before this date/time (UTC).")
        )]
        [Alias("before", "mb")]
        [DateTime] $ModifiedBefore,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "File attributes to skip (e.g., System, Hidden or None).")
        )]
        [Alias("skipattr")]
        [System.IO.FileAttributes] $AttributesToSkip = (
            [System.IO.FileAttributes]::System),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Exclude files or directories matching these wildcard " +
                "patterns (e.g., *.tmp, *\\bin\\*).")
        )]
        [Alias("skiplike")]
        [string[]] $Exclude = @("*\\.git\\*"),
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "Indicates that the cmdlet matches are case-sensitive. By " +
                "default, matches aren't case-sensitive.")
        )]
        [switch] $CaseSensitive,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "Specifies a culture name to match the specified pattern. The " +
                "Culture parameter must be used with the SimpleMatch parameter. " +
                "The default behavior uses the culture of the current PowerShell " +
                "runspace (session).")
        )]
        [string] $Culture,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "Specifies the type of encoding for the target file. The " +
                "default value is utf8NoBOM.")
        )]
        [ValidateSet("ASCII", "ANSI", "BigEndianUnicode", "BigEndianUTF32",
            "OEM", "Unicode", "UTF7", "UTF8", "UTF8BOM", "UTF8NoBOM",
            "UTF32", "Default")]
        [string] $Encoding = "UTF8NoBOM",
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "The NotMatch parameter finds text that doesn't match the " +
                "specified pattern.")
        )]
        [switch] $NotMatch,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "WithPattern",
            HelpMessage = (
                "Indicates that the cmdlet uses a simple match rather than a " +
                "regular expression match. In a simple match, Select-String " +
                "searches the input for the text in the Pattern parameter. It " +
                "doesn't interpret the value of the Pattern parameter as a " +
                "regular expression statement.")
        )]
        [switch] $SimpleMatch,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "Use Push-Location instead of Set-Location and push the location " +
                "onto the location stack")
        )]
        [switch] $Push,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = (
                "When set, only exact name matches are considered. By default, " +
                "wildcard matching is used unless the Name contains wildcard " +
                "characters.")
        )]
        [switch] $ExactMatch
    )

    begin {

        # handle default value for Name parameter since mandatory parameters cannot have defaults
        if ([string]::IsNullOrEmpty($Name)) {

            $Name = '*'
        }

        $CurrentLocation = (Microsoft.PowerShell.Management\Get-Location).Path;
        $callerSessionState = $PSCmdlet.SessionState

        # initialize collections for processing input files and results
        $inputFiles = [System.Collections.Generic.List[object]]::new()

        $allFiles = (
            [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new())

        # copy parameters from current function to find-item function parameters
        # this maintains consistency in parameter handling across functions
        $invocationParams = GenXdev.FileSystem\Copy-IdenticalParamValues `
            -FunctionName 'GenXdev.FileSystem\Find-Item' `
            -BoundParameters $PSBoundParameters `
            -DefaultValues (
                Microsoft.PowerShell.Utility\Get-Variable `
                    -Scope Local `
                    -ErrorAction SilentlyContinue)

        # ensure we get file objects back instead of just paths for processing
        $invocationParams.PassThru = $true
        $invocationParams.NoLinks = $true
        $invocationParams.Quiet = $true

        if (-not [string]::IsNullOrWhiteSpace($Name)) {

            $invocationParams.Name = (
                    ($ExactMatch -or $Name.Contains("*") -or $Name.Contains("?")) ? $Name : "*$($Name)*"
            )
        }

        # configure search type based on user preferences
        if ($DirectoriesAndFiles) {

            $invocationParams.FilesAndDirectories = $true
        }

        $NoContentSearch = (-not $Content) -or ($Content.Length -eq 1 -and $Content[0] -eq ".*");

        # search directories by default unless explicitly searching for files
        if ((-not $File) -and $NoContentSearch) {

            $invocationParams.Directory = $true
        }

        # log the search parameters for troubleshooting purposes
        Microsoft.PowerShell.Utility\Write-Verbose (
            "Searching for files with parameters: " +
            ($invocationParams.Keys -join ', '))
    }

    process {

        # log current parameter set name for debugging pipeline behavior
        Microsoft.PowerShell.Utility\Write-Verbose (
            "process: Detected paramset : $($PSCmdlet.ParameterSetName)")

        # skip processing if no input received from pipeline
        if ($null -eq $Input) {

            return
        }

        ########################################################################
        # recursive function to process various input object types
        function processObject($inputObj) {

            # log the type of object being processed for troubleshooting
            Microsoft.PowerShell.Utility\Write-Verbose (
                "Processing input object of type: " +
                $inputObj.GetType().FullName)

            # directly add fileinfo objects to the final collection
            if ($inputObj -is [System.IO.FileInfo]) {

                Microsoft.PowerShell.Utility\Write-Verbose (
                    "Adding FileInfo to allFiles: $($inputObj.FullName)")

                $null = $allFiles.Add($inputObj)

                return
            }

            # add strings and directory objects to search collection
            if ($inputObj -is [string] -or
                $inputObj -is [System.IO.DirectoryInfo]) {

                Microsoft.PowerShell.Utility\Write-Verbose (
                    "Adding String or DirectoryInfo to inputFiles: $inputObj")

                $null = $inputFiles.Add($inputObj)

                return
            }

            # recursively process enumerable collections
            if ($inputObj -is [System.Collections.IEnumerable]) {

                Microsoft.PowerShell.Utility\Write-Verbose (
                    "Processing IEnumerable, iterating through items...")

                foreach ($item in $inputObj) {

                    processObject($item)
                }

                return
            }

            # handle any other object types by forcing array conversion
            @($inputObj) |
                Microsoft.PowerShell.Core\ForEach-Object {

                    # avoid infinite recursion for the same object
                    if ($_ -ne $inputObj) {

                        processObject($_)
                    }
                }
        }
        ########################################################################

        # process the pipeline input through our recursive handler
        processObject($Input)
    }

    end {

        try {

            $unboundScriptBlock = $null

            if ($Push) {
                $unboundScriptBlock = {
                    param($Path)
                    Microsoft.PowerShell.Management\Push-Location -LiteralPath $Path
                }.Ast.GetScriptBlock()
            } else {
                $unboundScriptBlock = {
                    param($Path)
                    Microsoft.PowerShell.Management\Set-Location -LiteralPath $Path
                }.Ast.GetScriptBlock()
            }

            # provided a name?
            if (-not [string]::IsNullOrWhiteSpace($Name)) {

                # get full path
                $path = GenXdev.FileSystem\Expand-Path $Name

                # if path exists, change to its directory
                if ([IO.File]::Exists($path)) {

                    $Path = [IO.Path]::GetDirectoryName($path)
                }

                # is an existing directory?
                if ([IO.Directory]::Exists($path)) {

                    if ($PSCmdlet.ShouldProcess($path, "Set location")) {

                        Microsoft.PowerShell.Utility\Write-Verbose (
                            "Changing location to directory: " +
                            $path)

                        # Invoke in caller's session state to update global stack/history
                        $ExecutionContext.SessionState.InvokeCommand.InvokeScript(
                            $callerSessionState,
                            $unboundScriptBlock,
                            @($path)
                        )
                    }

                    return
                }
            }

            # create detailed verbose output for search operation debugging
            $verboseMessage = (
                "** Performing search for provided names.`r`n" +
                ($invocationParams |
                    Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3))

            Microsoft.PowerShell.Utility\Write-Verbose $verboseMessage

            # find all matching files and sort them alphabetically by full path
            $found = $false
            while ($true) {
                $InputFiles |
                    GenXdev.FileSystem\Find-Item @invocationParams | Microsoft.PowerShell.Core\Where-Object {

                        (($PSItem -is [System.IO.DirectoryInfo]) -and ($PSItem.FullName -ne $CurrentLocation)) -or
                        (($PSItem -is [System.IO.FileInfo]) -and ($PSItem.DirectoryName -ne $CurrentLocation))

                    } |
                    Microsoft.PowerShell.Utility\Select-Object -First 1 |
                    Microsoft.PowerShell.Core\ForEach-Object {

                        # determine target directory based on result type
                        if ($PSItem -is [System.IO.DirectoryInfo]) {

                            if ($PSCmdlet.ShouldProcess($PSItem.FullName, "Set location")) {

                                $found = $true
                                Microsoft.PowerShell.Utility\Write-Verbose (
                                    "Changing location to directory: " +
                                    $PSItem.FullName)

                                # Invoke in caller's session state to update global stack/history
                                $ExecutionContext.SessionState.InvokeCommand.InvokeScript(
                                    $callerSessionState,
                                    $unboundScriptBlock,
                                    @($PSItem.FullName)
                                )
                            }
                            else {

                                $found = $true
                            }
                        }
                        elseif ($PSItem -is [System.IO.FileInfo]) {

                            if ($PSCmdlet.ShouldProcess($PSItem.DirectoryName, "Set location")) {

                                $found = $true
                                Microsoft.PowerShell.Utility\Write-Verbose (
                                    "Changing location to file's directory: " +
                                    $PSItem.DirectoryName)

                                # Invoke in caller's session state to update global stack/history
                                $ExecutionContext.SessionState.InvokeCommand.InvokeScript(
                                    $callerSessionState,
                                    $unboundScriptBlock,
                                    @($PSItem.DirectoryName)
                                )

                                Microsoft.PowerShell.Utility\Write-Output $PSItem
                            }
                            else {

                                $found = $true
                            }
                        }
                    }

                if ($found -or ($invocationParams.MaxSearchUpDepth)) {

                    break;
                }
                else {

                    $invocationParams.MaxSearchUpDepth = 100;
                    $invocationParams.TimeoutSeconds = 6;
                    continue;
                }
            }
        }
        catch {

            # log any errors encountered during the search process
            Microsoft.PowerShell.Utility\Write-Error (
                "Error during file search: $($_.Exception.Message)`r`n" +
                ($_.Exception.StackTrace))
        }
        finally {

            if (-not $found) {

                Microsoft.PowerShell.Utility\Write-Information (
                    "No matching files or directories found for the provided input."
                )
            }
        }
    }
}
################################################################################