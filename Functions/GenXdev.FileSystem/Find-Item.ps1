################################################################################
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

.PARAMETER NoRecurse
Prevents recursive searching into subdirectories.

.EXAMPLE
# Find all files with that have the word "translation" in their content
Find-Item -Pattern "translation"

# or in short
l -mc translation

.EXAMPLE
# Find any javascript file that tests a version string in it's code
Find-Item -SearchMask *.js -Pattern "Version == `"\d\d?\.\d\d?\.\d\d?`""
# or in short
l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""

.EXAMPLE

# Find any node_modules\react-dom folder on all drives
Find-Item -SearchMask "node_modules\react-dom" -Pattern "Version == `"\d\d?\.\d\d?\.\d\d?`""

# or in short
l *.js "Version == `"\d\d?\.\d\d?\.\d\d?`""

.EXAMPLE
# Find all directories in the current directory and its subdirectories
Find-Item -Directory

# or in short
l -dir

.EXAMPLE
# Find all files with the .log extension in all drives
Find-Item -SearchMask "*.log" -AllDrives

# or in short
l *.log -all

.EXAMPLE
# Find all files with the .config extension and search for the pattern "connectionString" within the files
Find-Item -SearchMask "*.config" -Pattern "connectionString"

# or in short
l *.config connectionString

.EXAMPLE
# Find all files with the .xml extension and pass the objects through the pipeline
Find-Item -SearchMask "*.xml" -PassThru

# or in short
l *.xml -PassThru
#>
function Find-Item {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("l")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidTrailingWhitespace", "")]
    param(
        ########################################################################
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "File name or pattern to search for. Default is '*'"
        )]
        [Alias("like", "l", "Path", "Name", "file", "Query", "FullName")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]] $SearchMask = "*",
        ########################################################################
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = 'WithPattern',
            HelpMessage = "Regular expression pattern to search within content"
        )]
        [Alias("mc", "matchcontent")]
        [ValidateNotNull()]
        [SupportsWildcards()]
        [string] $Pattern = ".*",
        ########################################################################
        [Parameter(
            Position = 2,
            Mandatory = $false,
            HelpMessage = "Base path for resolving relative paths in output"
        )]
        [Alias("base")]
        [ValidateNotNullOrEmpty()]
        [string] $RelativeBasePath = ".\",
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Search across all available drives"
        )]
        [Alias("all")]
        [switch] $AllDrives,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = "Search for directories only"
        )]
        [Alias("dir")]
        [switch] $Directory,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = "Include both files and directories"
        )]
        [Alias("both")]
        [switch] $FilesAndDirectories,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Output matched items as objects"
        )]
        [switch] $PassThru,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Do not recurse into subdirectories"
        )]
        [switch] $NoRecurse
        ########################################################################
    )

    process {

        Microsoft.PowerShell.Utility\Write-Verbose ("Starting search with patterns: " +
            ($SearchMask -join ", "))

        # parallel search across all filesystem drives
        ($AllDrives ? (
            Microsoft.PowerShell.Management\Get-PSDrive -ErrorAction SilentlyContinue |
            Microsoft.PowerShell.Core\Where-Object {
                    ($PSItem.Provider -Like "*FileSystem") -and ($PSItem.Name.Length -eq 1)
            }) : $null) |
        Microsoft.PowerShell.Core\ForEach-Object -ThrottleLimit 8 -Parallel {

            # helper function to search file contents using regex
            function Search-FileContent {
                param (
                    [string] $filePath,
                    [string] $using:Pattern
                )

                return (Microsoft.PowerShell.Utility\Select-String -Path $filePath -Pattern $using:Pattern)
            }

            # helper function to recursively search directories
            function Search-DirectoryContent {
                param (
                    [string] $searchPhrase
                )

                # handle empty search phrase by defaulting to current directory
                if ([string]::IsNullOrWhiteSpace($searchPhrase)) {
                    $searchPhrase = ".\*"
                }

                # clean up and normalize the search path
                $searchPhrase = $searchPhrase.Trim()

                # ensure proper path termination for directories
                $endedWithPathSeparator = $searchPhrase.EndsWith(
                    [System.IO.Path]::DirectorySeparatorChar)
                if ($endedWithPathSeparator) {
                    $searchPhrase += "*"
                }

                # convert to absolute path
                $searchPhrase = GenXdev.FileSystem\Expand-Path $searchPhrase
                $remainingPath = $searchPhrase

                # initialize stack for directory traversal
                [System.Collections.Generic.Stack[System.Collections.Hashtable]] `
                    $directories = @()

                # find the next separator
                $index = $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)
                $indexOriginal = $index
                $indexWildcard = $remainingPath.IndexOf("*")
                $indexQuestionMark = $remainingPath.IndexOf("?")
                if ($indexQuestionMark -ge 0 -and ($indexWildcard -lt 0 -or $indexQuestionMark -lt $indexWildcard)) {

                    $indexWildcard = $indexQuestionMark
                }
                $last = $index -eq -1

                # be more effecient by skipping directories that don't require a match
                # have no wildcard or a wildcard in the path that comes after next directory separator?
                if ((-not $last) -and (($indexWildCard -lt 0) -or ($indexWildcard -gt $index))) {

                    # determine start position for searching wildcard preceeding directory separator character
                    $index = $indexWildcard -lt 0 ? $index : $indexWildcard

                    # determine if there is a wildcard after the wildcard character
                    $index2 = $indexWildcard -lt 0 ? -1 : $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar, $indexWildcard)

                    # if wildcard was found, search for the preceeding directory separator character
                    if ($indexWildCard -ge 0) {

                        while ($index -ge 1 -and ($remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                            $index--
                        }
                    }

                    # wildcard was found and did not have a preceeding directory separator character?
                    if ($index2 -lt 0) {

                        # set last flag to true, for later processing
                        $last = $true

                        # if wildcard was present, make sure to adjust the position so we don't include
                        # the directory where the wildcard was found in our next directory scan
                        if ($indexWildcard -ge 0) {

                            # we move the cursor to one character before directory separator..
                            $index--;
                        }
                        else {

                            # if no wildcard was found, we move the cursor to the last directory separator..
                            $index = $remainingPath.LastIndexOf([System.IO.Path]::DirectorySeparatorChar) - 1;
                        }

                        # ..so we can now exlude the directory holding the wildcard from our next directory scan
                        while ($index -ge 1 -and ($remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                            $index--
                        }
                    }
                }

                # prepare the invocation arguments for the first directory scan
                $invocationArgs = @{

                    Path        = "$($currentPath)*"
                    Force       = $true
                    ErrorAction = "SilentlyContinue"
                }

                # have no wildcard or a wildcard in the path that comes after next directory separator?
                if (($index -ge 0) -and (($indexWildcard -lt 0) -or ($indexWildcard -gt $index))) {

                    # wildcard was found and did not have a preceeding directory separator character?
                    if ($last) {

                        # find the last directory separator character
                        $i = $remainingPath.LastIndexOf([System.IO.Path]::DirectorySeparatorChar)

                        # set the appropiate path to search
                        $invocationArgs.Path = "$($currentPath)$($remainingPath.Substring(0, $i))\*"
                    }
                    else {

                        # set the appropiate path to search
                        $invocationArgs.Path = "$($currentPath)$($remainingPath.Substring(0, $indexWildcard))*"
                    }
                }

                # push the first directory scan
                $null = $directories.Push(
                    @{
                        currentPath   = $remainingPath.Substring(0, $index + 1)
                        remainingPath = $remainingPath.Substring($index + 1)
                        currentDepth  = 0
                    }
                )

                # process directories
                [hashtable]$folder = $null
                while ($directories.TryPop([ref]$folder)) {

                    # find the next directory separator in the remaining path
                    $index = $folder.remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)

                    # save the original index for later use
                    $indexOriginal = $index

                    # find the first wildcard in the remaining path
                    $indexWildcard = $folder.remainingPath.IndexOf("*")
                    $indexQuestionMark = $folder.remainingPath.IndexOf("?")
                    if ($indexQuestionMark -ge 0 -and ($indexWildcard -lt 0 -or $indexQuestionMark -lt $indexWildcard)) {

                        $indexWildcard = $indexQuestionMark
                    }
                    # determine if this is the last directory in the path
                    $last = $index -eq -1

                    # be more effecient by skipping directories that don't require a match
                    # have no wildcard or a wildcard in the path that comes after next directory separator?
                    if ((-not $last) -and (($indexWildCard -lt 0) -or ($indexWildcard -gt $index))) {

                        # determine start position for searching wildcard preceeding directory separator character
                        $index = $indexWildcard -lt 0 ? $index - 1 : $indexWildcard

                        # determine if there is a wildcard after the wildcard character
                        $index2 = $indexWildcard -lt 0 ? -1 : $folder.remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar, $indexWildcard);

                        # if wildcard was found, search for the preceeding directory separator character
                        if ($indexWildCard -ge 0) {

                            while ($index -ge 1 -and ($folder.remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                                $index--
                            }
                        }

                        # wildcard was found and did not have a preceeding directory separator character?
                        if ($index2 -lt 0) {

                            # set last flag to true, for later processing
                            $last = $true

                            # if wildcard was present, make sure to adjust the position so we don't include
                            # the directory where the wildcard was found in our next directory scan
                            if ($indexWildcard -ge 0) {

                                # we move the cursor to one character before directory separator..
                                $index--;
                            }
                            else {

                                # if no wildcard was found, we move the cursor to the last directory separator..
                                $index = $remainingPath.LastIndexOf([System.IO.Path]::DirectorySeparatorChar) - 1;
                            }

                            # ..so we can now exlude the directory holding the wildcard from our next directory scan
                            while ($index -ge 1 -and ($folder.remainingPath[$index] -ne [System.IO.Path]::DirectorySeparatorChar)) {

                                $index--
                            }
                        }
                    }

                    # prepare the invocation arguments for the next directory scan
                    $invocationArgs = @{

                        Path        = "$($folder.currentPath)*"
                        Force       = $true
                        ErrorAction = "SilentlyContinue"
                    }

                    # have no wildcard or a wildcard in the path that comes after next directory separator?
                    if (($index -ge 0) -and (($indexWildcard -lt 0) -or ($indexWildcard -gt $index))) {

                        # wildcard was found and did not have a preceeding directory separator character?
                        if ($last) {

                            # find the last directory separator character
                            $i = $folder.remainingPath.LastIndexOf([System.IO.Path]::DirectorySeparatorChar)

                            # set the appropiate path to search
                            $invocationArgs.Path = "$($folder.currentPath)$($folder.remainingPath.Substring(0, $i))\*"

                            # set the name to match for the next directory scan
                            $nameToMatch = $folder.remainingPath.Substring($i + 1)
                        }
                        else {

                            # set the appropiate path to search
                            $invocationArgs.Path = "$($folder.currentPath)$($folder.remainingPath.Substring(0, $indexWildcard))*"

                            # set the name to match for the next directory scan
                            $nameToMatch = $folder.remainingPath
                        }
                    }
                    else {

                        # are we following a /**/ pattern but haven't found the first matching directory yet?
                        if ($folder.forwardSearch) {

                            # set the name to match for the next directory scan
                            $nameToMatch = $folder.nameToMatch

                            # force the last flag to true, so we can keep following /**/ pattern without
                            # losing the informatino what directory to match next
                            $last = $folder.remainingPath.Substring(3).IndexOf(
                                [System.IO.Path]::DirectorySeparatorChar) -lt 0;
                        }
                        else {

                            # set the name to match for the next directory scan
                            $nameToMatch = $folder.remainingPath
                        }
                    }

                    # if we are not at the last directory in the path
                    if (-not $last) {

                        # and we are not following a /**/ pattern
                        if (-not $folder.forwardSearch) {

                            # then set the next directory to match to be the next directory in the path
                            $nameToMatch = $folder.remainingPath.Substring(0, $indexOriginal)
                        }

                        # only find directories, since there are more directories to match
                        $invocationArgs.Directory = $true

                        # invoke the next directory scan
                        Microsoft.PowerShell.Management\Get-ChildItem @invocationArgs | Microsoft.PowerShell.Core\ForEach-Object {

                            # are we following a /**/ pattern?

                            if ($folder.forwardSearch) {

                                # is this the next directory to match
                                if ($_.Name -like $nameToMatch) {

                                    $remainingPath = $folder.remainingPath.Substring(3);
                                    $i = $remainingPath.IndexOf([System.IO.Path]::DirectorySeparatorChar)
                                    if ($i -ge 0) {

                                        $remainingPath = $remainingPath.Substring($i + 1)
                                    }

                                    # schedule directory scan that stop the following of the /**/ pattern
                                    # and will continue the normal directory matching pattern again
                                    # where remainingPath will get shorter again
                                    $null = $directories.Push(
                                        @{
                                            remainingPath = $remainingPath
                                            currentPath   = "$($folder.currentPath)$($_.Name)\"
                                            currentDepth  = $folder.currentDepth + 1
                                        }
                                    )

                                    Microsoft.PowerShell.Utility\Write-Verbose "Ending /**/ search for $nameToMatch in $($directories.Peek().currentPath)"
                                }
                                else {
                                    # schedule directory scan that will keep following the /**/ pattern
                                    # where remainingPath will remain the same until we find the next directory to match
                                    $null = $directories.Push(
                                        @{
                                            forwardSearch = $true
                                            remainingPath = $folder.remainingPath
                                            currentPath   = "$($folder.currentPath)$($_.Name)\"
                                            currentDepth  = $folder.currentDepth + 1
                                            nameToMatch   = $folder.remainingPath.Substring(3).Split([System.IO.Path]::DirectorySeparatorChar)[0]
                                        }
                                    )

                                    Microsoft.PowerShell.Utility\Write-Verbose "Continuing following /**/ search for $($directories.Peek().$nameToMatch) in $($directories.Peek().currentPath)"
                                }
                            }

                            # not following a /**/ pattern, so we are looking for the next directory to match
                            # but first we check if we are entering a /**/ pattern
                            elseif ($nameToMatch -eq "**") {

                                # schedule directory scan that will start following the /**/ pattern
                                # we do this for every other directory we no found during this scan
                                $null = $directories.Push(
                                    @{
                                        forwardSearch = $true
                                        remainingPath = $folder.remainingPath
                                        currentPath   = "$($folder.currentPath)$($_.Name)\"
                                        currentDepth  = $folder.currentDepth + 1
                                        nameToMatch   = $folder.remainingPath.Substring(3).Split([System.IO.Path]::DirectorySeparatorChar)[0]
                                    }
                                )

                                Microsoft.PowerShell.Utility\Write-Verbose "Starting /**/ search for $($directories.Peek().$nameToMatch) in $($directories.Peek().currentPath)"
                            }

                            # we are not starting or following a /**/ pattern,
                            # so we only schedule directories that match the name to match
                            elseif ($_.Name -like $nameToMatch) {

                                $null = $directories.Push(
                                    @{
                                        remainingPath = $folder.remainingPath.Substring($index + 1)
                                        currentPath   = "$($folder.currentPath)$($_.Name)\"
                                        currentDepth  = $folder.currentDepth + 1
                                    }
                                )
                                Microsoft.PowerShell.Utility\Write-Verbose "Matched next directory for $($nameToMatch) in $($directories.Peek().currentPath)"
                            }
                        }
                        continue;
                    }

                    # we now at the last directory of the SearchPhrase supplied
                    # invoke the directory scan
                    # we scan for files and directories, since this is the last directory to match
                    Microsoft.PowerShell.Management\Get-ChildItem @invocationArgs | Microsoft.PowerShell.Core\ForEach-Object {

                        # determine if the found item is a directory
                        $isDirectory = $_ -is [System.IO.DirectoryInfo]

                        # if we find directories after the last directory of the SearchPhrase supplied
                        # we only want to scan them too if the user has specified to do so
                        # by default we recurse directories
                        if ($isDirectory -and (-not $using:NoRecurse)) {

                            # schedule directory scan for this additionaly found directory
                            $null = $directories.Push(
                                @{
                                    remainingPath = ($Last) ? "$nameToMatch" : "*"
                                    currentPath   = "$($_.FullName)\"
                                    currentDepth  = $folder.currentDepth + 1
                                }
                            )
                            Microsoft.PowerShell.Utility\Write-Verbose "Recursing after last matched directory in $($directories.Peek().currentPath)"
                        }

                        # if the item does not match the name pattern supplied
                        # we skip it and continue with the next item
                        if (-not ($_.Name -like $nameToMatch)) {

                            return
                        }

                        # determine if the item being a directory or file
                        # matches the type of item the user wants to search for
                        $typeOk = ($isDirectory -and ($using:Directory -or $using:FilesAndDirectories)) -or
                                  ((-not $using:Directory) -and (-not $isDirectory))

                        if ($typeOk) {

                            # if this is a file and a regular expression pattern was supplied
                            # we search the file content for the pattern to see if the user
                            # wants to include this file in the search results
                            if ($isDirectory -or [string]::IsNullOrWhiteSpace($using:Pattern) -or ($using:Pattern -eq ".*") -or (

                                    # match the file content with the regular expression pattern
                                    Search-FileContent -FilePath ($_.FullName) -Pattern $using:Pattern
                                )) {
                                Microsoft.PowerShell.Utility\Write-Verbose "Found $($_.FullName)"

                                # output FileInfo/DirectoryInfo objects if -PassThru is specified
                                if ($using:PassThru) {

                                    Microsoft.PowerShell.Utility\Write-Output $_
                                    return;
                                }

                                # or output the relative path of the found item
                                Microsoft.PowerShell.Management\Resolve-Path -Path $_ -Relative -RelativeBasePath:$using:RelativeBasePath
                            }
                        }
                    }
                }
            }

            foreach ($currentSearchPhrase in $using:SearchMask) {

                Microsoft.PowerShell.Utility\Write-Verbose "Processing search pattern: $currentSearchPhrase"

                if ($null -eq $PSItem) {

                    Search-DirectoryContent -SearchPhrase $currentSearchPhrase
                }
                else {
                    $expandedPath = GenXdev.FileSystem\Expand-Path $currentSearchPhrase `
                        -ForceDrive $PSItem.Name

                    Search-DirectoryContent -SearchPhrase $expandedPath
                }
            }
        }
    }

    end {
    }
}
################################################################################