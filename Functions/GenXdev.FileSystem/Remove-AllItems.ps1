<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Remove-AllItems.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.298.2025
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
###############################################################################
<#
.SYNOPSIS
Recursively removes all content from a directory with advanced error handling.

.DESCRIPTION
Safely removes all files and subdirectories within a specified directory using
a reverse-order deletion strategy to handle deep paths. Includes WhatIf support,
verbose logging, and fallback deletion methods for locked files.

.PARAMETER Path
The directory path to clear. Can be relative or absolute path. Will be normalized
and expanded before processing.

.PARAMETER DeleteFolder
When specified, also removes the root directory specified by Path after clearing
its contents.

.PARAMETER WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.

.EXAMPLE
Remove-AllItems -Path "C:\Temp\BuildOutput" -DeleteFolder -Verbose

.EXAMPLE
sdel ".\temp" -DeleteFolder
#>
function Remove-AllItems {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('sdel')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The directory path to clear'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string] $Path,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = 'Also delete the root folder supplied with the Path parameter'
        )]
        [switch] $DeleteFolder
        ###############################################################################
    )

    begin {

        # preserve original preference settings for restoration in end block
        $originalVerbosePreference = $VerbosePreference
        $originalWhatIfPreference = $WhatIfPreference

        try {
            # convert relative or shorthand paths to full filesystem paths
            $Path = GenXdev.FileSystem\Expand-Path $Path
            Microsoft.PowerShell.Utility\Write-Verbose "Normalized path: $Path"

            # ensure verbose output is enabled during WhatIf operations
            if ($WhatIfPreference -or $WhatIf) {
                $VerbosePreference = 'Continue'
            }
        }
        catch {
            # restore original whatif setting before propagating error
            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }


    process {
        try {
            # skip processing if target directory doesn't exist
            if (![System.IO.Directory]::Exists($Path)) {
                Microsoft.PowerShell.Utility\Write-Verbose "Directory does not exist: $Path"
                return
            }

            Microsoft.PowerShell.Utility\Write-Verbose "Processing directory: $Path"

            # delete files first, in reverse order to handle nested paths
            [System.IO.Directory]::GetFiles($Path, '*.*', `
                    [System.IO.SearchOption]::AllDirectories) |
                Microsoft.PowerShell.Utility\Sort-Object -Descending |
                Microsoft.PowerShell.Core\ForEach-Object {
                    $filePath = $_
                    if ($PSCmdlet.ShouldProcess($filePath, 'Remove file')) {
                        $null = GenXdev.FileSystem\Remove-ItemWithFallback -Path $filePath
                    }
                }

            # delete directories after files, also in reverse order
            [System.IO.Directory]::GetDirectories($Path, '*', `
                    [System.IO.SearchOption]::AllDirectories) |
                Microsoft.PowerShell.Utility\Sort-Object -Descending |
                Microsoft.PowerShell.Core\ForEach-Object {
                    $dirPath = $_
                    if ($PSCmdlet.ShouldProcess($dirPath, 'Remove directory')) {
                        try {
                            [System.IO.Directory]::Delete($dirPath, $true)
                            Microsoft.PowerShell.Utility\Write-Verbose "Removed directory: $dirPath"
                        }
                        catch {
                            # Microsoft.PowerShell.Utility\Write-Warning "Failed to delete directory: $dirPath"
                        }
                    }
                }

            # optionally remove the root directory itself
            if ($DeleteFolder) {
                if ($PSCmdlet.ShouldProcess($Path, 'Remove root directory')) {
                    try {
                        [System.IO.Directory]::Delete($Path, $true)
                        Microsoft.PowerShell.Utility\Write-Verbose "Removed root directory: $Path"
                    }
                    catch {
                        try {
                            $null = GenXdev.FileSystem\Remove-ItemWithFallback -Path $Path
                        }
                        catch {}
                    }
                }
            }
        }
        catch {
            # restore original whatif setting before propagating error
            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    end {
        # restore original preference settings
        $WhatIfPreference = $originalWhatIfPreference
    }
}