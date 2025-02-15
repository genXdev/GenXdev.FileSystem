################################################################################
<#
.SYNOPSIS
Searches for files or directories with optional content filtering.

.DESCRIPTION
Performs recursive file and directory searches with support for:
- File/directory name patterns
- Content matching using regular expressions
- Searching across all drives
- Directory-only searches
- Object pipeline output

.PARAMETER SearchMask
The file/directory name pattern to search for. Supports wildcards.
Defaults to "*" if not specified.

.PARAMETER Pattern
Regular expression to match against file contents.
Only applies when searching files, not directories.

.PARAMETER AllDrives
Search across all available drives instead of just the current path.

.PARAMETER Directory
Search for directories only, ignoring files.

.PARAMETER PassThru
Output matched items as objects instead of formatted strings.

.EXAMPLE
# Search for all .txt files in current directory and subdirectories
Find-Item -SearchMask "*.txt"

.EXAMPLE
# Find all files with that have the word "translation" in their name
Find-Item -SearchMask "*translation*"

# or in short
l *translation*

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

.NOTES
Assuming c:\temp exists;

'Find-Item c:\temp\'
    would search the whole content of directory 'temp' for any file or directory with the name 'temp'

'Find-Item c:\temp'
    would search the whole C drive for any file or directory with the name 'temp'

'Find-Item temp -AllDrives'
    would search the all drives for any file or directory with the name 'temp'
so would:
    'Find-Item c:\temp -AllDrives'
#>
function Find-Item {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("l")]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "File name or pattern to search for. Default is '*'"
        )]
        [Alias("like", "l")]
        [PSDefaultValue(Value = "*")]
        [string] $SearchMask = "*",
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = 'WithPattern',
            HelpMessage = "Regular expression pattern to search within file contents"
        )]
        [Alias("mc", "matchcontent")]
        [PSDefaultValue(Value = ".*")]
        [string] $Pattern = ".*",
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Search across all available drives"
        )]
        [Alias("all")]
        [switch] $AllDrives,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = "Search for directories only"
        )]
        [Alias("dir")]
        [switch] $Directory,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Output matched items as objects rather than strings"
        )]
        [switch] $PassThru
        ###############################################################################
    )

    begin {

        Write-Verbose "Starting Find-Item with SearchMask: $SearchMask"

        # normalize and validate the search mask
        $SearchMask = $SearchMask.Trim()
        if ($SearchMask -eq [string]::Empty) {
            $SearchMask = ".\*"
        }

        # normalize path separators
        $SearchMask = $SearchMask.Trim().Replace("\", [IO.Path]::DirectorySeparatorChar).`
            Replace("/", [IO.Path]::DirectorySeparatorChar).`
            Replace([IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::DirectorySeparatorChar)

        # ensure directory paths end with wildcard
        if ($SearchMask.EndsWith([IO.Path]::DirectorySeparatorChar)) {
            $SearchMask += "*"
        }

        Write-Verbose "Normalized SearchMask: $SearchMask"

        # convert to full path
        $SearchMask = Expand-Path $SearchMask
        Write-Verbose "Expanded SearchMask: $SearchMask"

        # store current location for relative path handling
        $location = Get-Location | ForEach-Object Path
    }

    process {

        # helper function to search file content
        function Search-FileContent {
            param (
                [string] $FilePath,
                [string] $Pattern
            )

            return Select-String -Path $FilePath -Pattern $Pattern
        }

        # output blank line unless passing through objects
        if (-not $PassThru) {
            "" | Out-Host
        }

        # searching with content pattern
        if ((-not $Directory) -and ($Pattern -ne ".*") -and
            (-not [string]::IsNullOrWhiteSpace($Pattern))) {

            Write-Verbose "Searching files with content pattern: $Pattern"

            # search all drives
            if ($AllDrives) {
                Write-Verbose "Searching across all drives"

                # process drives in parallel
                Get-PSDrive -ErrorAction SilentlyContinue |
                ForEach-Object -ThrottleLimit 8 -Parallel {

                    # extract filename part
                    $file = [IO.Path]::GetFileName($SearchMask)
                    $filter = [string]::IsNullOrEmpty($file) ? "*" : $file

                    try {
                        # skip non-filesystem providers
                        if ($PSItem.Provider.Name -ne "FileSystem") { return }

                        # search files matching name filter
                        Get-ChildItem "$($PSItem.Root)" -File:($Directory -eq $false) `
                            -ErrorAction SilentlyContinue `
                            -Directory:($Directory -eq $true) -Recurse |
                        Where-Object -Property Name -Like $filter |
                        ForEach-Object {

                            # check file content
                            if (Search-FileContent -FilePath $PSItem.FullName `
                                    -Pattern $Pattern) {

                                if ($PassThru) {
                                    $PSItem
                                }
                                else {
                                    # return relative or full path
                                    if ($PSItem.FullName.StartsWith($location +
                                            [IO.Path]::DirectorySeparatorChar)) {
                                        ".$($PSItem.FullName.Substring($location.Length))"
                                    }
                                    else {
                                        $PSItem.FullName
                                    }
                                }
                            }
                        }
                    }
                    catch {}
                }
                return
            }

            # regular content search
            Get-ChildItem $SearchMask -File -Recurse |
            ForEach-Object {
                if (($Pattern -eq ".*") -or
                    (Search-FileContent -FilePath $PSItem.FullName -Pattern $Pattern)) {

                    if ($PassThru) {
                        $PSItem
                        return
                    }

                    if ($PSItem.FullName.StartsWith($location +
                            [IO.Path]::DirectorySeparatorChar)) {
                        ".$($PSItem.FullName.Substring($location.Length))"
                    }
                    else {
                        $PSItem.FullName
                    }
                }
            }
            return
        }

        # search all drives without content
        if ($AllDrives) {
            Write-Verbose "Searching all drives for matching items"

            Get-PSDrive -ErrorAction SilentlyContinue |
            ForEach-Object -ThrottleLimit 8 -Parallel {
                try {
                    if ($PSItem.Provider.Name -ne "FileSystem") { return }

                    $file = [IO.Path]::GetFileName($SearchMask)
                    $filter = [string]::IsNullOrEmpty($file) ? "*" : $file

                    Get-ChildItem "$($PSItem.Root)" -File:($Directory -eq $false) `
                        -ErrorAction SilentlyContinue `
                        -Directory:($Directory -eq $true) -Recurse |
                    Where-Object -Property Name -Like $filter |
                    ForEach-Object {
                        if ($PassThru) {
                            $PSItem
                            return
                        }
                        $PSItem.FullName
                    }
                }
                catch {}
            }
            return
        }

        # regular file/directory search
        Write-Verbose "Performing regular file/directory search"

        $dir = [IO.Path]::GetDirectoryName($SearchMask)
        if ([string]::IsNullOrEmpty($dir)) {
            $dir = ".$([IO.Path]::DirectorySeparatorChar)"
        }

        $file = [IO.Path]::GetFileName($SearchMask)
        $search = [string]::IsNullOrEmpty($dir) ?
            ([string]::IsNullOrEmpty($file) ? "*" : $file) : $dir
        $filter = [string]::IsNullOrEmpty($file) ? "*" : $file

        Get-ChildItem $search -File:($Directory -eq $false) `
            -ErrorAction SilentlyContinue `
            -Directory:($Directory -eq $true) -Recurse |
        Where-Object -Property Name -Like $filter |
        ForEach-Object {
            if ($PassThru) {
                $PSItem
                return
            }

            if ($PSItem.FullName.StartsWith($location +
                    [IO.Path]::DirectorySeparatorChar)) {
                ".$($PSItem.FullName.Substring($location.Length))"
            }
            else {
                $PSItem.FullName
            }
        }

        # output blank line unless passing through objects
        if (-not $PassThru) {
            "" | Out-Host
        }
    }

    end {
    }
}
################################################################################
