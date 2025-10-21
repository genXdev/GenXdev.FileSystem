<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Find-DuplicateFiles.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.304.2025
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
###############################################################################

# don't remove this line [dontrefactor]

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

.PARAMETER Recurse
Recurse into subdirectories.

.EXAMPLE
Find-DuplicateFiles -Paths "C:\Pictures","D:\Backup\Pictures"

.EXAMPLE
"C:\Pictures","D:\Backup\Pictures" | fdf -DontCompareSize
#>
function Find-DuplicateFiles {

    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [Alias('fdf')]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = 'One or more directory paths to search for duplicates'
        )]
        [string[]] $Paths,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'One or more directory paths to search for duplicates'
        )]
        [Alias("FullName", "Filename", "Path")]
        [string] $Input,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Skip file size comparison when grouping duplicates'
        )]
        [switch] $DontCompareSize,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Skip last modified date comparison when grouping duplicates'
        )]
        [switch] $DontCompareModifiedDate,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Recurse into subdirectories'
        )]
        [switch] $Recurse
        ###############################################################################
    )

    begin {
        [System.Collections.Generic.List[IO.FileInfo]] $allFiles = @();

        # internal helper function to generate unique comparison key for each file
        function Get-FileKey([System.IO.FileInfo]$file) {
            $key = $file.Name
            if (-not $DontCompareSize) {
                $key += ";$($file.Length)"
            }
            if (-not $DontCompareModifiedDate) {
                # Truncate to second precision to avoid millisecond differences
                $key += ";$($file.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
            }
            return $key
        }

        # initialize high-performance collection for gathering files
        $allFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

        @($Paths) |
            Microsoft.PowerShell.Core\Where-Object { $_ -is [string] -and -not [string]::IsNullOrEmpty($_) } |
            Microsoft.PowerShell.Core\ForEach-Object { ([IO.Directory]::Exists($_) ? "$($_.TrimEnd("/\".ToCharArray()))\" : $_) } |
            GenXdev.FileSystem\Find-Item -PassThru -NoRecurse:($Recurse -ne $true) |
            Microsoft.PowerShell.Core\ForEach-Object -ErrorAction SilentlyContinue {

                    $null = $allFiles.Add($_)
            }
    }

    process {

        @($Input) |
            Microsoft.PowerShell.Core\Where-Object { $_ -is [string] -and -not [string]::IsNullOrEmpty($_) } |
            Microsoft.PowerShell.Core\ForEach-Object { ([IO.Directory]::Exists($_) ? "$($_.TrimEnd("/\".ToCharArray()))\" : $_) } |
            GenXdev.FileSystem\Find-Item -PassThru -NoRecurse:($Recurse -ne $true) |
            Microsoft.PowerShell.Core\ForEach-Object -ErrorAction SilentlyContinue {

                $null = $allFiles.Add($_)
            }
    }

    end {

        # group files by composite key and return only groups with duplicates
         $allFiles | Microsoft.PowerShell.Utility\Sort-Object -Unique -Property FullName |
            Microsoft.PowerShell.Utility\Group-Object -Property { Get-FileKey $_ } |
            Microsoft.PowerShell.Core\Where-Object { $_.Count -gt 1 } |
            Microsoft.PowerShell.Core\ForEach-Object {
                # create result object for each duplicate group
                [PSCustomObject]@{
                    FileName = $_.Group[0].Name
                    Files    = $_.Group
                }
            } | Microsoft.PowerShell.Utility\Write-Output
    }
}