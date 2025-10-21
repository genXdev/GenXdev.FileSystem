<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : ResolveInputObjectFileNames.ps1
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
<#
.SYNOPSIS
Expands input objects into file and directory names, supporting various
filters and output options.

.DESCRIPTION
This function processes input objects (files, directories, or collections)
and expands them into file and directory names. It supports filtering,
pattern matching, and can output results as objects. The function is
designed to work with pipeline input and provides options for recursion,
alternate data streams, and more.

.PARAMETER Input
Input object containing file names or directories. Accepts pipeline input.

.PARAMETER File
Return only files in the output.

.PARAMETER Pattern
Regular expression pattern to search within content.

.PARAMETER RelativeBasePath
Base path for resolving relative paths in output.

.PARAMETER AllDrives
Search across all available drives.

.PARAMETER Directory
Search for directories only.

.PARAMETER FilesAndDirectories
Include both files and directories in the output.

.PARAMETER PassThru
Output matched items as objects.

.PARAMETER IncludeAlternateFileStreams
Include alternate data streams in search results.

.PARAMETER NoRecurse
Do not recurse into subdirectories.

.EXAMPLE
ResolveInputObjectFileNames -Input "C:\Temp" -File

#>
###############################################################################
function ResolveInputObjectFileNames  {


    [CmdletBinding(DefaultParameterSetName = 'Default')]


    param(

        ###########################################################################
        [parameter(
            Position = 0,
            Mandatory = $false,
            HelpMessage = 'Input object containing file names or directories',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
    [Alias('Path', 'FilePath', 'Input')]
    [Object]$InputObject,

        ###########################################################################
        [parameter(
            Mandatory = $false,
            HelpMessage = 'Return only files'
        )]
        [switch]$File,

        ###########################################################################
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = 'WithPattern',
            HelpMessage = 'Regular expression pattern to search within content'
        )]
        [Alias('mc', 'matchcontent')]
        [ValidateNotNull()]
        [SupportsWildcards()]
        [string] $Pattern,

        ###########################################################################
        [Parameter(
            Position = 2,
            Mandatory = $false,
            HelpMessage = 'Base path for resolving relative paths in output'
        )]
        [Alias('base')]
        [ValidateNotNullOrEmpty()]
        [string] $RelativeBasePath,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Search across all available drives'
        )]

        [switch] $AllDrives,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = 'Search for directories only'
        )]
        [Alias('dir')]
        [switch] $Directory,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'DirectoriesOnly',
            HelpMessage = 'Include both files and directories'
        )]
        [Alias('both')]
        [switch] $FilesAndDirectories,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Output matched items as objects'
        )]
        [Alias('pt')]
        [switch]$PassThru,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Include alternate data streams in search results'
        )]
        [Alias('ads')]
        [switch] $IncludeAlternateFileStreams,

        ###########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Do not recurse into subdirectories'
        )]
        [switch] $NoRecurse
        ###########################################################################
    )

    begin {

    }

    process {

        # return if input is null
        if ($null -eq $InputObject) {
            return;
        }

        # handle input as FileInfo object
    if ($InputObject -is [System.IO.FileInfo]) {

            # copy parameters for Find-Item call
            $findParams = GenXdev.FileSystem\Copy-IdenticalParamValues `
                -BoundParameters $PSBoundParameters `
                -FunctionName 'GenXdev.FileSystem\Find-Item' `
                -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue)

            # find the item using Find-Item
            $item = GenXdev.FileSystem\Find-Item -SearchMask ("$($InputObject.FullName)") `
                @findParams -NoRecurse -File |
                Microsoft.PowerShell.Utility\Select-Object -First 1

            # output item if found, otherwise verbose skip
            if ($item) {
                Microsoft.PowerShell.Utility\Write-Verbose (
                    "Item $($InputObject.FullName) included"
                )
                Microsoft.PowerShell.Utility\Write-Output $item
            }
            else {
                Microsoft.PowerShell.Utility\Write-Verbose (
                    "Item $($InputObject.FullName) skipped due to filters"
                )
            }

            return;
        }

        # handle input as DirectoryInfo object
    if ($InputObject -is [System.IO.DirectoryInfo]) {

            # if filter is present, process each filter value
            if ($Filter) {
                # if multiple filters, use Find-Item for each
                if ($Filter.Count -gt 1) {
                    foreach ($f in $Filter) {
                        # copy parameters for Find-Item call
                        $params = GenXdev.FileSystem\Copy-IdenticalParamValues `
                            -BoundParameters $PSBoundParameters `
                            -FunctionName 'GenXdev.FileSystem\Find-Item' `
                            -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue)

                        # enumerate items for each filter
                        GenXdev.FileSystem\Find-Item -SearchMask ("$($InputObject.FullName)\$f") `
                            @params |
                            Microsoft.PowerShell.Core\ForEach-Object {

                                # copy parameters for recursive expansion
                                $expandParams = GenXdev.FileSystem\Copy-IdenticalParamValues `
                                    -BoundParameters $PSBoundParameters `
                                    -FunctionName 'GenXdev.FileSystem\ResolveInputObjectFileNames' `
                                    -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue);

                                $expandParams.InputObject = "$($InputObject.FullName)\$_"
                                GenXdev.FileSystem\ResolveInputObjectFileNames @expandParams |
                                    Microsoft.PowerShell.Core\ForEach-Object {
                                        Microsoft.PowerShell.Utility\Write-Output $_
                                    }
                            }
                    }
                    return;
                }
            }

            # copy parameters for Find-Item call
            $params = GenXdev.FileSystem\Copy-IdenticalParamValues `
                    -BoundParameters $PSBoundParameters `
                    -FunctionName 'GenXdev.FileSystem\Find-Item' `
                    -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue)

            # enumerate items found by Find-Item
            GenXdev.FileSystem\Find-Item -SearchMask "$($InputObject.FullName)\*" -NoRecurse @params |
                Microsoft.PowerShell.Core\ForEach-Object {

                    # skip directories if -File is specified
                    if (($_ -is [System.IO.DirectoryInfo]) -and ($File)) { return }
                    # skip string paths that are directories if -File is specified
                    if (($_ -is [string]) -and [System.IO.Directory]::Exists((GenXdev.FileSystem\Expand-Path $_)) -and ($File)) { return }

                    Microsoft.PowerShell.Utility\Write-Output $_
                }

            return;
        }

        # handle input as enumerable collection
    if (($InputObject -isnot [string]) -and ($InputObject -is [System.Collections.IEnumerable])) {

            # expand each item in the collection
            $InputObject | Microsoft.PowerShell.Core\ForEach-Object {

                $a = $_
                # Handle objects with Key/Value properties (e.g., DictionaryEntry, hashtable, PSCustomObject)
                if ($a -is [System.Collections.DictionaryEntry]) {
                    $a = $a.Value
                } elseif ($a -is [hashtable]) {
                    $a = $a.Values
                } elseif ($a.PSObject.Properties.Match('Key').Count -gt 0 -and $a.PSObject.Properties.Match('Value').Count -gt 0) {
                    $a = $a.Value
                }
                $a | Microsoft.PowerShell.Core\ForEach-Object {

                    $expandParams = GenXdev.FileSystem\Copy-IdenticalParamValues `
                        -BoundParameters $PSBoundParameters `
                        -FunctionName 'GenXdev.FileSystem\ResolveInputObjectFileNames' `
                        -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue);

                    @(GenXdev.FileSystem\ResolveInputObjectFileNames @expandParams -InputObject $PSItem) |
                        Microsoft.PowerShell.Core\ForEach-Object {
                            Microsoft.PowerShell.Utility\Write-Output $_
                        }
                }
            }
            return;
        }

        # return if input is not a string or is empty/whitespace
        if ((-not ($InputObject -is [string])) -or [string]::IsNullOrWhiteSpace($InputObject)) {
            return;
        }

        # copy parameters for Find-Item call
        $params = GenXdev.FileSystem\Copy-IdenticalParamValues `
                -BoundParameters $PSBoundParameters `
                -FunctionName 'GenXdev.FileSystem\Find-Item' `
                -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue)

        # enumerate items found by Find-Item
        GenXdev.FileSystem\Find-Item -SearchMask $InputObject @params |
            Microsoft.PowerShell.Core\ForEach-Object {

                # skip directories if -File is specified
                if (($_ -is [System.IO.DirectoryInfo]) -and ($File)) { return }
                # skip string paths that are directories if -File is specified
                if (($_ -is [string]) -and [System.IO.Directory]::Exists((GenXdev.FileSystem\Expand-Path $_)) -and ($File)) { return }

                Microsoft.PowerShell.Utility\Write-Output $_
            }
    }

    end {

    }
}

###############################################################################