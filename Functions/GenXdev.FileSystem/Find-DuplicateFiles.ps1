################################################################################
<#
.SYNOPSIS
Find duplicate files by name and properties across specified directories.

.DESCRIPTION
Takes an array of directory paths, searches each path recursively for files,
then groups files by name and optionally by size and modified date. Returns
groups containing two or more duplicate files.

.PARAMETER Paths
One or more directory paths to search for duplicate files.

.PARAMETER DontCompareSize
Skip file size comparison when determining duplicates.

.PARAMETER DontCompareModifiedDate
Skip last modified date comparison when determining duplicates.

.EXAMPLE
Find-DuplicateFiles -Paths "C:\Folder1","D:\Folder2" -DontCompareSize

.EXAMPLE
Get-Item "C:\Folder1","D:\Folder2" | Find-DuplicateFiles
#>
function Find-DuplicateFiles {

    [CmdletBinding()]
    [Alias("fdf")]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "One or more directory paths to search for duplicates"
        )]
        [ValidateNotNullOrEmpty()]
        [string[]] $Paths,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Skip file size comparison when grouping duplicates"
        )]
        [switch] $DontCompareSize,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "Skip last modified date comparison when grouping duplicates"
        )]
        [switch] $DontCompareModifiedDate
        ###############################################################################
    )

    begin {

        # normalize all input paths to full paths
        $normalizedPaths = @()
        $Paths | ForEach-Object {
            $normalizedPaths += (Expand-Path $_)
        }

        # helper function to generate unique key for file comparison
        function Get-FileKey([System.IO.FileInfo]$file) {

            # start with filename as base key
            $key = $file.Name

            # add size to key if size comparison is enabled
            if (-not $DontCompareSize) {
                $key += "|$($file.Length)"
            }

            # add modified date to key if date comparison is enabled
            if (-not $DontCompareModifiedDate) {
                $key += "|$($file.LastWriteTimeUtc.ToString('o'))"
            }

            return $key
        }

        # initialize generic list for better performance with large collections
        $allFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    }

    process {

        # process each normalized path
        foreach ($path in $normalizedPaths) {

            # verify directory exists before processing
            if ([System.IO.Directory]::Exists($path)) {

                Write-Verbose "Scanning directory: $path"

                # get all files using direct .NET IO methods for performance
                [System.IO.Directory]::GetFiles($path, "*.*",
                    [System.IO.SearchOption]::AllDirectories) |
                ForEach-Object {
                    $null = $allFiles.Add([System.IO.FileInfo]::new($_))
                }
            }
            else {
                Write-Warning "Directory not found: $path"
            }
        }
    }

    end {

        # group files by composite key and return groups with duplicates
        $allFiles |
        Group-Object -Property { Get-FileKey $_ } |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            # create custom object for each group of duplicates
            [PSCustomObject]@{
                FileName = $_.Group[0].Name
                Files = $_.Group
            }
        }
    }
}
################################################################################
