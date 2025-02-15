################################################################################
<#
.SYNOPSIS
Find duplicate files across multiple directories based on configurable criteria.

.DESCRIPTION
Recursively searches specified directories for duplicate files. Files are
considered duplicates if they share the same name and optionally match on size
and modification date. Returns groups of duplicate files for further processing.

.PARAMETER Paths
Array of directory paths to recursively search for duplicate files. Accepts
pipeline input and wildcard paths.

.PARAMETER DontCompareSize
When specified, file size is not used as a comparison criterion, only names
are matched.

.PARAMETER DontCompareModifiedDate
When specified, file modification dates are not used as a comparison criterion.

.EXAMPLE
Find-DuplicateFiles -Paths "C:\Photos","D:\Backup\Photos"

.EXAMPLE
"C:\Photos","D:\Backup\Photos" | fdf -DontCompareSize
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

        # convert all input paths to full filesystem paths
        $normalizedPaths = @()
        $Paths | ForEach-Object {
            $normalizedPaths += (Expand-Path $_)
        }

        # internal helper function to generate unique comparison key for each file
        function Get-FileKey([System.IO.FileInfo]$file) {

            # start with filename as the base identifier
            $key = $file.Name

            # include file size in comparison key if enabled
            if (-not $DontCompareSize) {
                $key += "|$($file.Length)"
            }

            # include modification date in comparison key if enabled
            if (-not $DontCompareModifiedDate) {
                $key += "|$($file.LastWriteTimeUtc.ToString('o'))"
            }

            return $key
        }

        # initialize high-performance collection for gathering files
        $allFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    }

    process {

        foreach ($path in $normalizedPaths) {

            # verify directory exists before attempting to process
            if ([System.IO.Directory]::Exists($path)) {

                Write-Verbose "Scanning directory for duplicates: $path"

                # use direct .NET IO for faster recursive file enumeration
                [System.IO.Directory]::GetFiles($path, "*.*",
                    [System.IO.SearchOption]::AllDirectories) |
                ForEach-Object {
                    $null = $allFiles.Add([System.IO.FileInfo]::new($_))
                }
            }
            else {
                Write-Warning "Skipping non-existent directory: $path"
            }
        }
    }

    end {

        # group files by composite key and return only groups with duplicates
        $allFiles |
        Group-Object -Property { Get-FileKey $_ } |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            # create result object for each duplicate group
            [PSCustomObject]@{
                FileName = $_.Group[0].Name
                Files    = $_.Group
            }
        }
    }
}
################################################################################
