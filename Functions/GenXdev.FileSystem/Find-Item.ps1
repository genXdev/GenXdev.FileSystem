###############################################################################
<#
.SYNOPSIS
Performs advanced file and directory searches with content filtering capabilities.

.DESCRIPTION
A powerful search utility that combines file/directory pattern matching with
content filtering. Supports recursive searches, multi-drive operations, and
flexible output formats. Can search by name patterns and content patterns
simultaneously.

.PARAMETER SearchMask
File or directory pattern to match against. Supports wildcards (*,?).
Default is "*" to match everything.

.PARAMETER Pattern
Regular expression to search within file contents. Only applies to files.
Default is ".*" to match any content.

.PARAMETER RelativeBasePath
Base directory for generating relative paths in output.
Only used when -PassThru is not specified.

.PARAMETER AllDrives
When specified, searches across all available filesystem drives.

.PARAMETER Directory
Limits search to directories only, ignoring files.

.PARAMETER FilesAndDirectories
Includes both files and directories in search results.

.PARAMETER PassThru
Returns FileInfo/DirectoryInfo objects instead of paths.

.PARAMETER IncludeAlternateFileStreams
Include alternate data streams in search results.

.PARAMETER NoRecurse
Prevents recursive searching into subdirectories.

.EXAMPLE
Find all files with that have the word "translation" in their content
Find-Item -Pattern "translation"

or in short
l -mc translation

.EXAMPLE
Find any javascript file that tests a version string in it's code
Find-Item -SearchMask *.js -Pattern "Version == `"\d\d?\.\d\d?\.\d\d?`""

or in short
l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""

.EXAMPLE
Find any node_modules\react-dom folder on all drives
Find-Item -SearchMask "node_modules\react-dom" -Pattern "Version == `"\d\d?\.\d\d?\.\d\d?`""

or in short
l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""

.EXAMPLE
Find all directories in the current directory and its subdirectories
Find-Item -Directory

or in short
l -dir

.EXAMPLE
Find all files with the .log extension in all drives
Find-Item -SearchMask "*.log" -AllDrives

or in short
l *.log -all

.EXAMPLE
Find all files with the .config extension and search for the pattern "connectionString" within the files
Find-Item -SearchMask "*.config" -Pattern "connectionString"

or in short
l *.config connectionString

.EXAMPLE
Find all files with the .xml extension and pass the objects through the pipeline
Find-Item -SearchMask "*.xml" -PassThru

or in short
l *.xml -PassThru

.EXAMPLE
Find all files and also include alternate data streams
Find-Item -IncludeAlternateFileStreams

or in short
l -ads

.EXAMPLE
Find only the alternate data streams (not the base files) for all .jpg files
Find-Item -SearchMask "*.jpg:"

This syntax automatically enables -IncludeAlternateFileStreams

.EXAMPLE
Find jpg files that have a stream named "Zone.Identifier"
Find-Item -SearchMask "*.jpg:Zone.Identifier"

No need to specify -IncludeAlternateFileStreams, it's automatically enabled

.EXAMPLE
Find all alternate filestreams in the current directory and beyond
containing "secret" text in their content
Find-Item -SearchMask "*:*" -Pattern "secret"

This will find all alternate streams in any file that contain the word "secret"

.EXAMPLE
Find files with Zone.Identifier streams and return them as objects
Find-Item "*:Zone*" -PassThru

Returns System.IO.FileInfo.AlternateDataStream objects with full FileInfo compatibility
#>
function Find-Item {

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [Alias('l')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidTrailingWhitespace', '')]
    param(
        ########################################################################
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "File name or pattern to search for. Default is '*'"
        )]
        [Alias('like', 'l', 'Path', 'Name', 'file', 'Query', 'FullName')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]] $SearchMask = '*',
        ########################################################################
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = 'WithPattern',
            HelpMessage = 'Regular expression pattern to search within content'
        )]
        [Alias('mc', 'matchcontent')]
        [ValidateNotNull()]
        [SupportsWildcards()]
        [string] $Pattern = '.*',
        ########################################################################
        [Parameter(
            Position = 2,
            Mandatory = $false,
            HelpMessage = 'Base path for resolving relative paths in output'
        )]
        [Alias('base')]
        [ValidateNotNullOrEmpty()]
        [string] $RelativeBasePath = '.\',
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Search across all available drives'
        )]

        [switch] $AllDrives,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = 'Search for directories only'
        )]
        [Alias('dir')]
        [switch] $Directory,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = 'Include both files and directories'
        )]
        [Alias('both')]
        [switch] $FilesAndDirectories,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Output matched items as objects'
        )]
        [Alias('pt')]
        [switch]$PassThru,

        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Include alternate data streams in search results'
        )]
        [Alias('ads')]
        [switch] $IncludeAlternateFileStreams,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Do not recurse into subdirectories'
        )]
        [switch] $NoRecurse
        ########################################################################
    )

    begin {
        # log function entry with parameters for debugging
        Microsoft.PowerShell.Utility\Write-Information 'BEGIN Find-Item: Initializing with parameters:'
        Microsoft.PowerShell.Utility\Write-Information "  SearchMask: $($SearchMask -join ', ')"
        Microsoft.PowerShell.Utility\Write-Information "  Pattern: $Pattern"
        Microsoft.PowerShell.Utility\Write-Information "  RelativeBasePath: $RelativeBasePath"
        Microsoft.PowerShell.Utility\Write-Information "  AllDrives: $AllDrives"
        Microsoft.PowerShell.Utility\Write-Information "  Directory: $Directory"
        Microsoft.PowerShell.Utility\Write-Information "  FilesAndDirectories: $FilesAndDirectories"
        Microsoft.PowerShell.Utility\Write-Information "  PassThru: $PassThru"
        Microsoft.PowerShell.Utility\Write-Information "  IncludeAlternateFileStreams: $IncludeAlternateFileStreams"
        Microsoft.PowerShell.Utility\Write-Information "  NoRecurse: $NoRecurse"

        # Track whether we have an implicit ADS request for specific masks
        $processedSearchMasks = @()
        $streamPatterns = @{}
        $searchMasksWithAds = @()

        # Process SearchMask for alternate data stream patterns
        foreach ($mask in $SearchMask) {
            # Skip empty masks
            if ([string]::IsNullOrWhiteSpace($mask)) {
                continue
            }

            # Expand the mask to a full path to handle drive specifications correctly
            try {
                $expandedMask = GenXdev.FileSystem\Expand-Path $mask -ErrorAction SilentlyContinue
            }
            catch {
                # If expansion fails, just use the original mask
                $expandedMask = $mask
                Microsoft.PowerShell.Utility\Write-Information "Failed to expand path '$mask': $($_.Exception.Message)"
            }

            Microsoft.PowerShell.Utility\Write-Information "Expanded mask '$mask' to '$expandedMask'"

            # Count the number of colons in the path
            $colonCount = ($expandedMask -split ':').Length - 1
            Microsoft.PowerShell.Utility\Write-Information "Found $colonCount colons in expanded mask"

            # If we have more than 1 colon (one for drive spec, others for stream)
            if ($colonCount -gt 1) {
                $lastColonIndex = $expandedMask.LastIndexOf(':' )

                # Extract the file pattern (everything before the last colon)
                $filePattern = $expandedMask.Substring(0, $lastColonIndex)

                # Extract the stream pattern (everything after the last colon)
                $streamPattern = $expandedMask.Substring($lastColonIndex + 1)

                # If stream pattern is empty, use wildcard to match all streams
                if ([string]::IsNullOrWhiteSpace($streamPattern)) {
                    $streamPattern = '*'
                }

                Microsoft.PowerShell.Utility\Write-Information "Found ADS pattern in SearchMask. File pattern: $filePattern, Stream pattern: $streamPattern"

                # Store the stream pattern for the expanded file path only
                $streamPatterns[$filePattern] = $streamPattern

                # Add only the file pattern to the processed masks and mark it as needing ADS
                $processedSearchMasks += $filePattern
                $searchMasksWithAds += $filePattern

                Microsoft.PowerShell.Utility\Write-Information "Added file pattern to SearchMasksWithAds: $filePattern"
            }
            else {
                # No ADS pattern, add the mask as is
                $processedSearchMasks += $mask

                # If IncludeAlternateFileStreams switch is provided, also add this mask to SearchMasksWithAds
                if ($IncludeAlternateFileStreams) {
                    $searchMasksWithAds += $mask
                    Microsoft.PowerShell.Utility\Write-Information "Added mask to SearchMasksWithAds due to IncludeAlternateFileStreams: $mask"
                }
            }
        }

        # Replace the original SearchMask with the processed one
        $SearchMask = $processedSearchMasks

        # No need to store in script: variables when using $using: in parallel

        Microsoft.PowerShell.Utility\Write-Information "Modified SearchMask: $($SearchMask -join ', ')"
        Microsoft.PowerShell.Utility\Write-Information "SearchMasksWithAds: $($searchMasksWithAds -join ', ')"
        Microsoft.PowerShell.Utility\Write-Information "Stream patterns: $(($streamPatterns | Microsoft.PowerShell.Utility\Out-String))"

        # user-friendly verbose message about what the function will do
        Microsoft.PowerShell.Utility\Write-Verbose "Starting search for $($SearchMask -join ', ')$(if(![string]::IsNullOrWhiteSpace($Pattern) -and $Pattern -ne '.*'){" containing text matching pattern: '$Pattern'"})"
    }

    process {
        # log process block entry for debugging
        Microsoft.PowerShell.Utility\Write-Information 'PROCESS Find-Item: Starting search processing'

        # log high-level search information for users
        Microsoft.PowerShell.Utility\Write-Verbose "Searching for $(if($Directory){'directories'}elseif($FilesAndDirectories){'files and directories'}else{'files'}) matching $($SearchMask -join ', ')"

        # if searching across drives, inform the user
        if ($AllDrives) {
            Microsoft.PowerShell.Utility\Write-Verbose 'Searching across all available drives - this may take some time'
            Microsoft.PowerShell.Utility\Write-Information 'Searching across all available drives'
        }

        # parallel search across all filesystem drives if AllDrives switch is provided
        ($AllDrives ? ( & {
                # get all filesystem drives with single-letter names
                Microsoft.PowerShell.Utility\Write-Information 'Getting available filesystem drives'
                $drives = Microsoft.PowerShell.Management\Get-PSDrive -ErrorAction SilentlyContinue |
                    Microsoft.PowerShell.Core\Where-Object {
                    ($PSItem.Provider -Like '*FileSystem') -and ($PSItem.Name.Length -eq 1)
                    }
                    Microsoft.PowerShell.Utility\Write-Verbose "Found drives: $($drives.Name -join ', ')"
                    Microsoft.PowerShell.Utility\Write-Information "Found drives: $($drives.Name -join ', ')"
                    $drives
                }
            ) : $null) |
                Microsoft.PowerShell.Core\ForEach-Object -ThrottleLimit 8 -Parallel {
                    # Access parent scope variables with $using:
                    $streamPatterns = $using:streamPatterns
                    $searchMasksWithAds = $using:searchMasksWithAds
                    $includeAlternateFileStreams = $using:IncludeAlternateFileStreams

                    Microsoft.PowerShell.Utility\Write-Information "Stream patterns in parallel block: $(($streamPatterns | Microsoft.PowerShell.Utility\Out-String))"

                    # helper function to search file contents using regex, including alternate data streams
                    function Search-FileContent {
                        param (
                            [string] $filePath,
                            [string] $pattern,
                            [string] $streamName = $null
                        )

                        Microsoft.PowerShell.Utility\Write-Information "Searching file content: $filePath$(if($streamName){":$streamName"}) for pattern: '$pattern'"

                        # Debug information to help identify issues
                        Microsoft.PowerShell.Utility\Write-Information "Pattern type: $($pattern.GetType().FullName), Length: $($pattern.Length)"

                        try {
                            # If a stream name is provided, search in that specific stream content
                            if ($streamName) {
                                # Get the stream content as a string
                                [string] $content = Microsoft.PowerShell.Management\Get-Content -LiteralPath $filePath -Stream $streamName -Raw -ErrorAction Stop

                                if ($content) {
                                    # Now apply the regex to the actual content
                                    [bool] $matchResult = $content -match $pattern
                                    Microsoft.PowerShell.Utility\Write-Information "Stream content match result: $matchResult (explicit regex)"
                                    return $matchResult
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Information 'Stream content is empty'
                                    return $false
                                }
                            }
                            # For regular files, use the same regex matching approach for consistency
                            else {
                                # Read the file content directly to use the same matching logic for both
                                [string] $fileContent = Microsoft.PowerShell.Management\Get-Content -LiteralPath $filePath -Raw -ErrorAction Stop
                                if ($fileContent) {
                                    [bool] $matchResult = $fileContent -match $pattern
                                    Microsoft.PowerShell.Utility\Write-Information "File content match result: $matchResult (explicit regex)"
                                    return $matchResult
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Information 'File is empty'
                                    return $false
                                }
                            }
                        }
                        catch {
                            Microsoft.PowerShell.Utility\Write-Information "Error searching content: $($_.Exception.Message)"
                            return $false
                        }
                    }

                    # helper function to recursively search directories
                    function Search-DirectoryContent {
                        param (
                            [string] $searchPhrase,
                            [bool] $includeAds = $false,
                            [bool] $hasStreamPattern,
                            [string] $expandedSearchMask = $null,
                            [hashtable] $streamPatterns,
                            [bool] $passThru,
                            [string] $relativeBasePath,
                            [string] $pattern,
                            [bool] $directory,
                            [bool] $filesAndDirectories,
                            [bool] $noRecurse
                        )

                        Microsoft.PowerShell.Utility\Write-Information "Search-DirectoryContent: Starting with phrase: $searchPhrase, includeAds: $includeAds, mask: $expandedSearchMask"

                        # handle empty search phrase by defaulting to current directory
                        if ([string]::IsNullOrWhiteSpace($searchPhrase)) {
                            $searchPhrase = '.\*'
                            Microsoft.PowerShell.Utility\Write-Information "Search phrase was empty, defaulting to: $searchPhrase"
                        }

                        # clean up and normalize the search path
                        $searchPhrase = $searchPhrase.Trim()
                        Microsoft.PowerShell.Utility\Write-Information "Normalized search phrase: $searchPhrase"

                        # ensure proper path termination for directories
                        $endedWithPathSeparator = $searchPhrase.EndsWith(
                            [System.IO.Path]::DirectorySeparatorChar)

                        if ($endedWithPathSeparator) {
                            $searchPhrase += '*'
                            Microsoft.PowerShell.Utility\Write-Information "Path ended with separator, appended wildcard: $searchPhrase"
                        }

                        # convert to absolute path
                        Microsoft.PowerShell.Utility\Write-Information "Converting to absolute path: $searchPhrase"
                        $searchPhrase = GenXdev.FileSystem\Expand-Path $searchPhrase
                        Microsoft.PowerShell.Utility\Write-Information "Absolute path: $searchPhrase"
                        $remainingPath = $searchPhrase

                        # initialize stack for directory traversal
                        Microsoft.PowerShell.Utility\Write-Information 'Initializing directory traversal stack'
                        [System.Collections.Generic.Stack[System.Collections.Hashtable]] `
                            $directories = @()

                        # find the next path separator character
                        $index = $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)
                        Microsoft.PowerShell.Utility\Write-Information "First path separator index: $index"
                        $indexOriginal = $index

                        # find the first wildcard character (* or ?)
                        $indexWildcard = $remainingPath.IndexOf('*')
                        $indexQuestionMark = $remainingPath.IndexOf('?')
                        Microsoft.PowerShell.Utility\Write-Information "First wildcard positions - * at: $indexWildcard, ? at: $indexQuestionMark"

                        # if question mark comes before asterisk, use that as the wildcard position
                        if ($indexQuestionMark -ge 0 -and
                    ($indexWildcard -lt 0 -or $indexQuestionMark -lt $indexWildcard)) {
                            $indexWildcard = $indexQuestionMark
                            Microsoft.PowerShell.Utility\Write-Information "Using ? as first wildcard at position: $indexWildcard"
                        }

                        # determine if we're at the last path component
                        $last = $index -eq -1
                        Microsoft.PowerShell.Utility\Write-Information "Is last path component: $last"

                        # be more efficient by skipping directories that don't require a match
                        # have no wildcard or a wildcard in the path that comes after next directory separator?
                        if ((-not $last) -and (($indexWildCard -lt 0) -or ($indexWildcard -gt $index))) {
                            Microsoft.PowerShell.Utility\Write-Information 'Optimizing directory traversal path'

                            # determine start position for searching wildcard preceding directory separator
                            $index = $indexWildcard -lt 0 ? $index : $indexWildcard
                            Microsoft.PowerShell.Utility\Write-Information "Adjusted index: $index"

                            # determine if there is a wildcard after the wildcard character
                            $index2 = $indexWildcard -lt 0 ? -1 :
                            $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar, $indexWildcard)
                            Microsoft.PowerShell.Utility\Write-Information "Wildcard delimiter index: $index2"

                            # if wildcard was found, search for the preceding directory separator character
                            if ($indexWildCard -ge 0) {
                                Microsoft.PowerShell.Utility\Write-Information 'Finding directory separator before wildcard'
                                while ($index -ge 1 -and
                               ($remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {
                                    $index--
                                }
                                Microsoft.PowerShell.Utility\Write-Information "Found at index: $index"
                            }

                            # wildcard was found and did not have a preceding directory separator character?
                            if ($index2 -lt 0) {
                                # set last flag to true, for later processing
                                $last = $true
                                Microsoft.PowerShell.Utility\Write-Information 'Setting last flag to true as wildcard has no following separator'

                                # if wildcard was present, adjust position to exclude directory with wildcard
                                if ($indexWildcard -ge 0) {
                                    # move cursor to one character before directory separator
                                    $index--;
                                    Microsoft.PowerShell.Utility\Write-Information "Adjusted index position: $index"
                                }
                                else {
                                    # if no wildcard was found, move cursor to the last directory separator
                                    $index = $remainingPath.LastIndexOf(
                                        [System.IO.Path]::DirectorySeparatorChar) - 1;
                                    Microsoft.PowerShell.Utility\Write-Information "No wildcard found, moved to last separator: $index"
                                }

                                # exclude the directory holding the wildcard from our next directory scan
                                Microsoft.PowerShell.Utility\Write-Information 'Excluding directory with wildcard from scan'
                                while ($index -ge 1 -and
                               ($remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {
                                    $index--
                                }
                                Microsoft.PowerShell.Utility\Write-Information "Final index position: $index"
                            }
                        }

                        # prepare the search path for the first directory scan
                        $searchPath = "$($currentPath)*"
                        Microsoft.PowerShell.Utility\Write-Information "Initial search path: $searchPath"

                        # have no wildcard or a wildcard in the path that comes after next directory separator?
                        if (($index -ge 0) -and
                    (($indexWildcard -lt 0) -or ($indexWildcard -gt $index))) {
                            Microsoft.PowerShell.Utility\Write-Information 'Adjusting search path based on wildcard position'

                            # wildcard was found and did not have a preceding directory separator character?
                            if ($last) {
                                # find the last directory separator character
                                $i = $remainingPath.LastIndexOf([System.IO.Path]::DirectorySeparatorChar)
                                Microsoft.PowerShell.Utility\Write-Information "Last directory separator at: $i"

                                # set the appropriate path to search
                                $searchPath = "$($currentPath)$($remainingPath.Substring(0, $i))\*"
                                Microsoft.PowerShell.Utility\Write-Information "Updated search path: $searchPath"
                            }
                            else {
                                # set the appropriate path to search
                                $searchPath = "$($currentPath)$($remainingPath.Substring(0, $indexWildcard))*"
                                Microsoft.PowerShell.Utility\Write-Information "Updated search path with wildcard: $searchPath"
                            }
                        }

                        # push the first directory scan onto the stack
                        Microsoft.PowerShell.Utility\Write-Information 'Pushing first directory scan to stack'
                        $null = $directories.Push(
                            @{
                                currentPath   = $remainingPath.Substring(0, $index + 1)
                                remainingPath = $remainingPath.Substring($index + 1)
                                currentDepth  = 0
                            }
                        )
                        Microsoft.PowerShell.Utility\Write-Information "Stack entry - currentPath: $($directories.Peek().currentPath), remainingPath: $($directories.Peek().remainingPath)"

                        # process directories using a stack for efficient traversal
                        [hashtable]$folder = $null
                        Microsoft.PowerShell.Utility\Write-Information 'Starting directory stack processing loop'
                        $stackProcessCount = 0
                        $totalDirsProcessed = 0
                        $totalFilesChecked = 0
                        $totalMatches = 0

                        while ($directories.TryPop([ref]$folder)) {
                            $stackProcessCount++
                            $totalDirsProcessed++

                            # every 10 directories, update the verbose message for users
                            if ($totalDirsProcessed % 10 -eq 0) {
                                Microsoft.PowerShell.Utility\Write-Verbose "Searched $totalDirsProcessed directories, found $totalMatches matches so far..."
                            }

                            Microsoft.PowerShell.Utility\Write-Information "Processing stack item #$stackProcessCount - currentPath: $($folder.currentPath), remainingPath: $($folder.remainingPath), depth: $($folder.currentDepth)"

                            # find the next directory separator in the remaining path
                            $index = $folder.remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)
                            Microsoft.PowerShell.Utility\Write-Information "Next directory separator in remaining path: $index"

                            # save the original index for later use
                            $indexOriginal = $index

                            # find the first wildcard in the remaining path
                            $indexWildcard = $folder.remainingPath.IndexOf('*')
                            $indexQuestionMark = $folder.remainingPath.IndexOf('?')
                            Microsoft.PowerShell.Utility\Write-Information "Wildcards in remaining path - * at: $indexWildcard, ? at: $indexQuestionMark"

                            # if question mark comes before asterisk, use that as the wildcard position
                            if ($indexQuestionMark -ge 0 -and
                        ($indexWildcard -lt 0 -or $indexQuestionMark -lt $indexWildcard)) {
                                $indexWildcard = $indexQuestionMark
                                Microsoft.PowerShell.Utility\Write-Information "Using ? as wildcard position: $indexWildcard"
                            }

                            # determine if this is the last directory in the path
                            $last = $index -eq -1
                            Microsoft.PowerShell.Utility\Write-Information "Is last directory component: $last"

                            # be more efficient by skipping directories that don't require a match
                            # have no wildcard or a wildcard in the path that comes after next directory separator?
                            if ((-not $last) -and
                        (($indexWildCard -lt 0) -or ($indexWildcard -gt $index))) {
                                Microsoft.PowerShell.Utility\Write-Information 'Optimizing intermediate directory traversal'

                                # determine start position for searching wildcard preceding directory separator
                                $index = $indexWildcard -lt 0 ? $index - 1 : $indexWildcard
                                Microsoft.PowerShell.Utility\Write-Information "Adjusted intermediate index: $index"

                                # determine if there is a wildcard after the wildcard character
                                $index2 = $indexWildcard -lt 0 ? -1 :
                                $folder.remainingPath.IndexOf(
                                    [System.IO.Path]::DirectorySeparatorChar, $indexWildcard);
                                Microsoft.PowerShell.Utility\Write-Information "Intermediate wildcard delimiter index: $index2"

                                # if wildcard was found, search for the preceding directory separator character
                                if ($indexWildCard -ge 0) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Finding directory separator before intermediate wildcard'
                                    while ($index -ge 1 -and
                                  ($folder.remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                                        $index--
                                    }
                                    Microsoft.PowerShell.Utility\Write-Information "Found at intermediate index: $index"
                                }

                                # wildcard was found and did not have a preceding directory separator character?
                                if ($index2 -lt 0) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Intermediate wildcard has no following separator'
                                    # set last flag to true, for later processing
                                    $last = $true

                                    # if wildcard was present, adjust position to exclude directory with wildcard
                                    if ($indexWildcard -ge 0) {
                                        # move cursor to one character before directory separator
                                        $index--;
                                        Microsoft.PowerShell.Utility\Write-Information "Adjusted intermediate index position: $index"
                                    }
                                    else {
                                        # if no wildcard was found, move cursor to the last directory separator
                                        $index = $remainingPath.LastIndexOf(
                                            [System.IO.Path]::DirectorySeparatorChar) - 1;
                                        Microsoft.PowerShell.Utility\Write-Information "No intermediate wildcard found, moved to last separator: $index"
                                    }

                                    # exclude directory holding the wildcard from our next directory scan
                                    Microsoft.PowerShell.Utility\Write-Information 'Excluding intermediate directory with wildcard from scan'
                                    while ($index -ge 1 -and
                                  ($folder.remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                                        $index--
                                    }
                                    Microsoft.PowerShell.Utility\Write-Information "Final intermediate index position: $index"
                                }
                            }

                            # prepare the search path for the next directory scan
                            $searchPath = "$($folder.currentPath)*"
                            Microsoft.PowerShell.Utility\Write-Information "Next search path: $searchPath"

                            # have no wildcard or a wildcard in the path that comes after next directory separator?
                            if (($index -ge 0) -and
                        (($indexWildcard -lt 0) -or ($indexWildcard -gt $index))) {
                                Microsoft.PowerShell.Utility\Write-Information 'Adjusting next search path based on wildcard position'

                                # wildcard was found and did not have a preceding directory separator character?
                                if ($last) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Last directory with wildcard handling'
                                    # find the last directory separator character
                                    $i = $folder.remainingPath.LastIndexOf(
                                        [System.IO.Path]::DirectorySeparatorChar)
                                    Microsoft.PowerShell.Utility\Write-Information "Last directory separator at: $i"

                                    # set the appropriate path to search
                                    $searchPath = "$($folder.currentPath)$($folder.remainingPath.Substring(0, $i))\*"
                                    Microsoft.PowerShell.Utility\Write-Information "Updated final search path: $searchPath"

                                    # set the name to match for the next directory scan
                                    $nameToMatch = $folder.remainingPath.Substring($i + 1)
                                    Microsoft.PowerShell.Utility\Write-Information "Name pattern to match: $nameToMatch"
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Information 'Intermediate directory with wildcard handling'
                                    # set the appropriate path to search
                                    $searchPath = "$($folder.currentPath)$($folder.remainingPath.Substring(0, $indexWildcard))*"
                                    Microsoft.PowerShell.Utility\Write-Information "Updated intermediate search path: $searchPath"

                                    # set the name to match for the next directory scan
                                    $nameToMatch = $folder.remainingPath
                                    Microsoft.PowerShell.Utility\Write-Information "Intermediate name pattern to match: $nameToMatch"
                                }
                            }
                            else {
                                # are we following a /**/ pattern but haven't found the first matching directory yet?
                                if ($folder.forwardSearch) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Following /**/ recursive pattern search'
                                    # set the name to match for the next directory scan
                                    $nameToMatch = $folder.nameToMatch
                                    Microsoft.PowerShell.Utility\Write-Information "Recursive pattern name to match: $nameToMatch"

                                    # force the last flag to true to keep following /**/ pattern without
                                    # losing information about directory to match next
                                    $last = $folder.remainingPath.Substring(3).IndexOf(
                                        [System.IO.Path]::DirectorySeparatorChar) -lt 0;
                                    Microsoft.PowerShell.Utility\Write-Information "Updated last flag for recursive pattern: $last"
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Information 'Standard pattern matching'
                                    # set the name to match for the next directory scan
                                    $nameToMatch = $folder.remainingPath
                                    Microsoft.PowerShell.Utility\Write-Information "Standard name pattern to match: $nameToMatch"

                                    # log that we've reached the end of the path pattern
                                    Microsoft.PowerShell.Utility\Write-Information (
                                        'No more directories to match in ' +
                                        "$($folder.currentPath) - setting last flag to true")
                                }
                            }

                            # if we are not at the last directory in the path
                            if (-not $last) {
                                Microsoft.PowerShell.Utility\Write-Information 'Not at last directory, processing intermediate directories'

                                # and we are not following a /**/ pattern
                                if (-not $folder.forwardSearch) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Not in /**/ pattern search mode'
                                    # set next directory to match to be the next directory in the path
                                    $nameToMatch = $folder.remainingPath.Substring(0, $indexOriginal)
                                    Microsoft.PowerShell.Utility\Write-Information "Directory name to match: $nameToMatch"
                                }

                                # get only directories since there are more directories to match
                                $directorySearchOption = [System.IO.SearchOption]::TopDirectoryOnly
                                Microsoft.PowerShell.Utility\Write-Information "Getting directories from: $searchPath"

                                try {
                                    # use System.IO.Directory to get directories instead of Get-ChildItem
                                    $searchDir = [System.IO.Path]::GetDirectoryName($searchPath)
                                    $searchPattern = [System.IO.Path]::GetFileName($searchPath)
                                    Microsoft.PowerShell.Utility\Write-Information "Search directory: $searchDir, pattern: $searchPattern"

                                    $directories_to_process = [System.IO.Directory]::GetDirectories(
                                        $searchDir, $searchPattern, $directorySearchOption)
                                    Microsoft.PowerShell.Utility\Write-Information "Found $(if($directories_to_process){$directories_to_process.Count}else{0}) directories to process"

                                    foreach ($dirPath in $directories_to_process) {
                                        # create DirectoryInfo object to match PowerShell behavior
                                        $dirInfo = Microsoft.PowerShell.Utility\New-Object System.IO.DirectoryInfo($dirPath)
                                        Microsoft.PowerShell.Utility\Write-Information "Processing directory: $($dirInfo.FullName)"

                                        # are we following a /**/ pattern?
                                        if ($folder.forwardSearch) {
                                            Microsoft.PowerShell.Utility\Write-Information "In /**/ search mode, checking if directory matches pattern: $($folder.nameToMatch)"

                                            # is this the next directory to match
                                            if ($dirInfo.Name -like $nameToMatch) {
                                                Microsoft.PowerShell.Utility\Write-Information "Found matching directory for /**/ pattern: $($dirInfo.Name)"

                                                $remainingPath = $folder.remainingPath.Substring(3);
                                                $i = $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)
                                                if ($i -ge 0) {
                                                    $remainingPath = $remainingPath.Substring($i + 1)
                                                }
                                                Microsoft.PowerShell.Utility\Write-Information "Remaining path after match: $remainingPath"

                                                # schedule directory scan that stops following the /**/ pattern
                                                $null = $directories.Push(
                                                    @{
                                                        remainingPath = $remainingPath
                                                        currentPath   = "$($folder.currentPath)$($dirInfo.Name)\"
                                                        currentDepth  = $folder.currentDepth + 1
                                                    }
                                                )

                                                Microsoft.PowerShell.Utility\Write-Information (
                                                    "Ending /**/ search for $nameToMatch in " +
                                                    "$($directories.Peek().currentPath)")
                                            }
                                            else {
                                                Microsoft.PowerShell.Utility\Write-Information "Directory doesn't match /**/ pattern, continuing search"
                                                # schedule directory scan that will continue following /**/ pattern
                                                $null = $directories.Push(
                                                    @{
                                                        forwardSearch = $true
                                                        remainingPath = $folder.remainingPath
                                                        currentPath   = "$($folder.currentPath)$($dirInfo.Name)\"
                                                        currentDepth  = $folder.currentDepth + 1
                                                        nameToMatch   = $folder.remainingPath.Substring(3).Split(
                                                            [System.IO.Path]::DirectorySeparatorChar)[0]
                                                    }
                                                )

                                                Microsoft.PowerShell.Utility\Write-Information (
                                                    'Continuing following /**/ search for ' +
                                                    "$($directories.Peek().$nameToMatch) in " +
                                                    "$($directories.Peek().currentPath)")
                                            }
                                        }
                                        # check if we are entering a /**/ pattern
                                        elseif ($nameToMatch -eq '**') {
                                            Microsoft.PowerShell.Utility\Write-Information 'Entering /**/ recursive search pattern'

                                            # schedule directory scan that will start following the /**/ pattern
                                            $null = $directories.Push(
                                                @{
                                                    forwardSearch = $true
                                                    remainingPath = $folder.remainingPath
                                                    currentPath   = "$($folder.currentPath)$($dirInfo.Name)\"
                                                    currentDepth  = $folder.currentDepth + 1
                                                    nameToMatch   = $folder.remainingPath.Substring(3).Split(
                                                        [System.IO.Path]::DirectorySeparatorChar)[0]
                                                }
                                            )

                                            Microsoft.PowerShell.Utility\Write-Information (
                                                'Starting /**/ search for ' +
                                                "$($directories.Peek().$nameToMatch) in " +
                                                "$($directories.Peek().currentPath)")
                                        }
                                        # only schedule directories that match the name to match
                                        elseif ($dirInfo.Name -like $nameToMatch) {
                                            Microsoft.PowerShell.Utility\Write-Information "Directory name '$($dirInfo.Name)' matches pattern '$nameToMatch'"

                                            # push directory onto stack for processing
                                            $null = $directories.Push(
                                                @{
                                                    remainingPath = $folder.remainingPath.Substring($index + 1)
                                                    currentPath   = "$($folder.currentPath)$($dirInfo.Name)\"
                                                    currentDepth  = $folder.currentDepth + 1
                                                }
                                            )

                                            Microsoft.PowerShell.Utility\Write-Information (
                                                "Matched next directory for $nameToMatch in " +
                                                "$($directories.Peek().currentPath)")
                                        }
                                        else {
                                            Microsoft.PowerShell.Utility\Write-Information "Directory name '$($dirInfo.Name)' does not match pattern '$nameToMatch'"
                                        }
                                    }
                                }
                                catch {
                                    # log any errors accessing directories
                                    Microsoft.PowerShell.Utility\Write-Information (
                                        "Error accessing directory: $([System.IO.Path]::GetDirectoryName($searchPath)) - $($_.Exception.Message)")
                                }

                                # skip to next directory in the stack
                                Microsoft.PowerShell.Utility\Write-Information 'Continuing to next directory in stack'
                                continue;
                            }

                            # we are at the last directory of the SearchPhrase supplied
                            Microsoft.PowerShell.Utility\Write-Information 'Reached last directory component, performing final matching'

                            # get both files and directories for final matching
                            try {
                                $searchOption = [System.IO.SearchOption]::TopDirectoryOnly
                                $searchDir = [System.IO.Path]::GetDirectoryName($searchPath)
                                $searchPattern = [System.IO.Path]::GetFileName($searchPath)
                                Microsoft.PowerShell.Utility\Write-Information "Final search in directory: $searchDir with pattern: $searchPattern"
                                Microsoft.PowerShell.Utility\Write-Verbose "Searching in directory: $searchDir"

                                # get directories if requested
                                Microsoft.PowerShell.Utility\Write-Information "Directory search enabled: $($directory -or $filesAndDirectories -or (-not $directory))"
                                $directories_found = @()
                                if ($directory -or $filesAndDirectories -or (-not $directory)) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Searching for directories matching pattern'
                                    $directories_found = [System.IO.Directory]::GetDirectories(
                                        $searchDir, $searchPattern, $searchOption)
                                    Microsoft.PowerShell.Utility\Write-Information "Found $(if($directories_found){$directories_found.Count}else{0}) matching directories"
                                }

                                # get files if not directories only
                                $files_found = @()
                                if (-not $directory) {
                                    Microsoft.PowerShell.Utility\Write-Information 'Searching for files matching pattern'
                                    $files_found = [System.IO.Directory]::GetFiles(
                                        $searchDir, $searchPattern, $searchOption)
                                    $totalFilesChecked += $files_found.Count
                                    Microsoft.PowerShell.Utility\Write-Information "Found $(if($files_found){$files_found.Count}else{0}) matching files"
                                }

                                # combine results
                                $all_items = $directories_found + $files_found
                                Microsoft.PowerShell.Utility\Write-Information "Total items found in this directory: $(if($all_items){$all_items.Count}else{0})"

                                foreach ($itemPath in $all_items) {
                                    # create appropriate info object based on item type
                                    $isDirectory = [System.IO.Directory]::Exists($itemPath)
                                    $itemInfo = $isDirectory ?
                                (Microsoft.PowerShell.Utility\New-Object System.IO.DirectoryInfo($itemPath)) :
                                (Microsoft.PowerShell.Utility\New-Object System.IO.FileInfo($itemPath))
                                    Microsoft.PowerShell.Utility\Write-Information "Processing $(if($isDirectory){'directory'}else{'file'}): $($itemInfo.FullName)"

                                    # if we find directories, recurse if not disabled
                                    if ($isDirectory -and (-not $noRecurse)) {
                                        Microsoft.PowerShell.Utility\Write-Information "Will recurse into directory: $($itemInfo.FullName)"

                                        # schedule directory scan for this additionally found directory
                                        $null = $directories.Push(
                                            @{
                                                remainingPath = ($Last) ? "$nameToMatch" : '*'
                                                currentPath   = "$($itemInfo.FullName)\"
                                                currentDepth  = $folder.currentDepth + 1
                                            }
                                        )

                                        Microsoft.PowerShell.Utility\Write-Information (
                                            'Recursing after last matched directory in ' +
                                            "$($directories.Peek().currentPath)")
                                    }

                                    # if item doesn't match name pattern, skip it
                                    if (-not ($itemInfo.Name -like $nameToMatch)) {
                                        Microsoft.PowerShell.Utility\Write-Information "Skipping item: '$($itemInfo.FullName)' - doesn't match name pattern: '$nameToMatch'"
                                        continue
                                    }

                                    Microsoft.PowerShell.Utility\Write-Information "Item name '$($itemInfo.Name)' matches pattern '$nameToMatch'"

                                    # check if item type matches what user wants
                                    $typeOk = ($isDirectory -and ($directory -or $filesAndDirectories)) -or
                                      ((-not $directory) -and (-not $isDirectory))

                                    if (-not $typeOk) {
                                        Microsoft.PowerShell.Utility\Write-Information "Skipping item: item type doesn't match requested type"
                                        continue
                                    }

                                    Microsoft.PowerShell.Utility\Write-Information 'Item type matches filter criteria'

                                    $hasStreamPattern = $null -ne $streamPatterns[$expandedSearchMask]

                                    # if this is a file, check content pattern if specified
                                    $contentMatch = $isDirectory -or ($hasStreamPattern) -or
                                    [string]::IsNullOrWhiteSpace($pattern) -or
                                ($pattern -eq '.*')

                                    if (-not $contentMatch) {

                                        Microsoft.PowerShell.Utility\Write-Information "Checking file content against pattern: $pattern"
                                        # Fix: Use the actual boolean result instead of checking if non-null
                                        $contentMatch = Search-FileContent -FilePath ($itemInfo.FullName) -Pattern $pattern
                                        Microsoft.PowerShell.Utility\Write-Information "Content match result: $contentMatch"
                                    }

                                    if ($contentMatch) {
                                        $totalMatches++
                                        Microsoft.PowerShell.Utility\Write-Information "Found matching item: $($itemInfo.FullName)"
                                        Microsoft.PowerShell.Utility\Write-Verbose "Found match: $($itemInfo.FullName)"

                                        # Determine if we should output the base file - simplified check
                                        # Only check if the expanded path has a stream pattern

                                        $shouldOutputFile = -not $hasStreamPattern

                                        if ($shouldOutputFile) {

                                            # output FileInfo/DirectoryInfo objects if -PassThru is specified
                                            if ($passThru) {
                                                Microsoft.PowerShell.Utility\Write-Information 'Returning object directly (PassThru mode)'
                                                Microsoft.PowerShell.Utility\Write-Output $itemInfo
                                            }
                                            else {
                                                # output relative path of the found item
                                                Microsoft.PowerShell.Utility\Write-Information "Resolving relative path with base: $relativeBasePath"
                                                $rp = Microsoft.PowerShell.Management\Resolve-Path -LiteralPath:($itemInfo.FullName) -Relative -RelativeBasePath:$relativeBasePath
                                                Microsoft.PowerShell.Utility\Write-Verbose "Microsoft.PowerShell.Management\Resolve-Path -LiteralPath '$($itemInfo.FullName)'  -Relative -RelativeBasePath:'$relativeBasePath'"

                                                Microsoft.PowerShell.Utility\Write-Information "Relative path: $rp"
                                                Microsoft.PowerShell.Utility\Write-Output $rp
                                            }
                                        }
                                        else {
                                            Microsoft.PowerShell.Utility\Write-Information 'Skipping base file because a stream pattern was specified for this search mask'
                                        }
                                    }
                                    else {
                                        Microsoft.PowerShell.Utility\Write-Information "Item content doesn't match pattern, skipping"
                                    }

                                    # If IncludeAlternateFileStreams is specified and this is a file
                                    if ((-not $isDirectory) -and $includeAds) {

                                        Microsoft.PowerShell.Utility\Write-Information "Getting alternate data streams for file: $($itemInfo.FullName)"
                                        try {
                                            # Get all streams for this file
                                            $streams = Microsoft.PowerShell.Management\Get-Item -LiteralPath $itemInfo.FullName -Stream * -ErrorAction SilentlyContinue |
                                                Microsoft.PowerShell.Core\Where-Object { ($_.Stream -ne ':$DATA') -or $hasStreamPattern }  # Skip the default stream

                                                Microsoft.PowerShell.Utility\Write-Information "Found $(if($streams){$streams.Count}else{0}) alternate data streams"

                                                # Check if we have specific stream patterns to match against
                                                $streamPatternsForFile = $streamPatterns."$expandedSearchMask"
                                                if ([string]::IsNullOrWhiteSpace($streamPatternsForFile)) {

                                                    $streamPatternsForFile = '*'
                                                }

                                                foreach ($stream in $streams) {

                                                    Microsoft.PowerShell.Utility\Write-Information "Processing stream: $($stream.Stream) of size: $($stream.Length)"

                                                    # If we have specific stream patterns, check if this stream matches
                                                    $streamNameMatch = $true

                                                    if ($streamPatternsForFile) {
                                                        $streamNameMatch = $stream.Stream -like $streamPatternsForFile
                                                        Microsoft.PowerShell.Utility\Write-Information "Checking stream name '$($stream.Stream)' against pattern '$streamPatternsForFile': $streamNameMatch"
                                                    }

                                                    # Skip this stream if it doesn't match the stream pattern
                                                    if (-not $streamNameMatch) {
                                                        Microsoft.PowerShell.Utility\Write-Information "Stream name doesn't match pattern, skipping"
                                                        continue
                                                    }

                                                    # Check if Pattern parameter is specified and not the default value
                                                    $streamContentMatch = [string]::IsNullOrWhiteSpace($pattern) -or ($pattern -eq '.*')

                                                    if (-not $streamContentMatch) {
                                                        # Search for pattern in stream content
                                                        Microsoft.PowerShell.Utility\Write-Information "Checking stream content against pattern: $pattern"
                                                        # Fix: Use the actual boolean result instead of checking if non-null
                                                        $streamContentMatch = Search-FileContent -FilePath $itemInfo.FullName -Pattern $pattern -StreamName $stream.Stream
                                                        Microsoft.PowerShell.Utility\Write-Information "Stream content match result: $streamContentMatch"
                                                    }

                                                    # Only process streams that match the pattern (if specified)
                                                    if ($streamContentMatch) {
                                                        if ($passThru) {
                                                            # Create a PSCustomObject clone of the FileInfo with stream info
                                                            # This maintains compatibility with FileInfo while including stream information
                                                            $properties = @{}

                                                            # Copy all properties from the original FileInfo object
                                                            foreach ($property in $itemInfo.PSObject.Properties) {
                                                                if ($property.Name -eq 'FullName') {
                                                                    $properties['FullName'] = "$($itemInfo.FullName):$($stream.Stream)"
                                                                }
                                                                elseif ($property.Name -eq 'Name') {
                                                                    $properties['Name'] = "$($itemInfo.Name):$($stream.Stream)"
                                                                }
                                                                else {
                                                                    $properties[$property.Name] = $property.Value
                                                                }
                                                            }

                                                            # Add additional stream properties
                                                            $properties['Stream'] = $stream.Stream
                                                            $properties['StreamLength'] = $stream.Length

                                                            # Create the custom object with the properties
                                                            $streamObj = [PSCustomObject]$properties

                                                            # Add a type name to help with type conversion
                                                            $streamObj.PSObject.TypeNames.Insert(0, 'System.IO.FileInfo.AlternateDataStream')
                                                            $streamObj.PSObject.TypeNames.Insert(1, 'System.IO.FileInfo')

                                                            Microsoft.PowerShell.Utility\Write-Output $streamObj
                                                        }
                                                        else {
                                                            # For path output format the path with stream
                                                            $rp = Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $itemInfo.FullName `
                                                                -Relative -RelativeBasePath:$relativeBasePath
                                                            Microsoft.PowerShell.Utility\Write-Output "$rp`:$($stream.Stream)"
                                                        }
                                                    }
                                                    else {
                                                        Microsoft.PowerShell.Utility\Write-Information "Stream content doesn't match pattern, skipping"
                                                    }
                                                }
                                            }
                                            catch {
                                                Microsoft.PowerShell.Utility\Write-Information "Error accessing alternate data streams: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                }
                                catch {
                                    # log any errors processing directories
                                    Microsoft.PowerShell.Utility\Write-Information (
                                        "Error processing directory: $searchDir - $($_.Exception.Message)")
                                    Microsoft.PowerShell.Utility\Write-Verbose "Error accessing $searchDir - $($_.Exception.Message)"
                                }
                            }

                            Microsoft.PowerShell.Utility\Write-Information "Directory stack processing complete - processed $stackProcessCount items"
                            Microsoft.PowerShell.Utility\Write-Verbose "Search complete: Examined $totalDirsProcessed directories and $totalFilesChecked files, found $totalMatches matches"
                        }

                        # process each search mask provided
                        foreach ($currentSearchPhrase in $using:SearchMask) {

                            Microsoft.PowerShell.Utility\Write-Information "Processing search pattern: $currentSearchPhrase"
                            Microsoft.PowerShell.Utility\Write-Verbose "Processing search pattern: $currentSearchPhrase"

                            $expandedSearchMask = GenXdev.FileSystem\Expand-Path $currentSearchPhrase

                            # Check if this specific search mask should include alternate data streams
                            # Simplified to only check the expanded search mask
                            $hasStreamPattern = $null -ne $streamPatterns[$expandedSearchMask]
                            $includeAds = $includeAlternateFileStreams -or $hasStreamPattern

                            if ($includeAds) {
                                Microsoft.PowerShell.Utility\Write-Information "This search mask should include ADS: $currentSearchPhrase"
                            }

                            # if not a multi-drive search or currently processing root context
                            if ($null -eq $PSItem) {

                                Microsoft.PowerShell.Utility\Write-Information 'Searching in current context (not drive-specific)'
                                Search-DirectoryContent -SearchPhrase $currentSearchPhrase `
                                    -IncludeAds $includeAds `
                                    -HasStreamPattern $hasStreamPattern `
                                    -ExpandedSearchMask $expandedSearchMask `
                                    -StreamPatterns $streamPatterns `
                                    -PassThru $using:PassThru `
                                    -RelativeBasePath $using:RelativeBasePath `
                                    -Pattern $using:Pattern `
                                    -Directory $using:Directory `
                                    -FilesAndDirectories $using:FilesAndDirectories `
                                    -NoRecurse $using:NoRecurse
                            }
                            else {
                                $expandedSearchMask = GenXdev.FileSystem\Expand-Path $currentSearchPhrase `
                                    -ForceDrive $PSItem.Name
                                # force the search to start from the specific drive
                                Microsoft.PowerShell.Utility\Write-Information "Searching on drive $($PSItem.Name)"
                                Microsoft.PowerShell.Utility\Write-Verbose "Searching on drive $($PSItem.Name)"
                                Microsoft.PowerShell.Utility\Write-Information "Expanded path for drive $($PSItem.Name): $expandedSearchMask"

                                Search-DirectoryContent -SearchPhrase $expandedSearchMask `
                                    -IncludeAds $includeAds `
                                    -HasStreamPattern $hasStreamPattern `
                                    -ExpandedSearchMask $expandedSearchMask `
                                    -StreamPatterns $streamPatterns `
                                    -PassThru $using:PassThru `
                                    -RelativeBasePath $using:RelativeBasePath `
                                    -Pattern $using:Pattern `
                                    -Directory $using:Directory `
                                    -FilesAndDirectories $using:FilesAndDirectories `
                                    -NoRecurse $using:NoRecurse
                            }
                        }
                    }

        Microsoft.PowerShell.Utility\Write-Information 'PROCESS Find-Item: Search processing completed'
        Microsoft.PowerShell.Utility\Write-Verbose 'Search completed'
    }

    end {
        Microsoft.PowerShell.Utility\Write-Information 'END Find-Item: Function execution completed'
    }
}