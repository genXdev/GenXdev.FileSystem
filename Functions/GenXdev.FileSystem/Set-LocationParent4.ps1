<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-LocationParent4.ps1
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
Navigates up four directory levels in the filesystem hierarchy.

.DESCRIPTION
Provides a convenient way to move up four directory levels from the current
location in the filesystem. After navigation, displays the contents of the
resulting directory.

.EXAMPLE
Set-LocationParent4

.EXAMPLE
.....

.NOTES
The alias '.....'' represents moving up four parent directories, where each dot
represents one level up.
#>
function Set-LocationParent4 {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('.....')]
    param()

    begin {

        Microsoft.PowerShell.Utility\Write-Verbose "Starting navigation up four directory levels from $(Microsoft.PowerShell.Management\Get-Location)"
    }


    process {

        # navigate up four levels
        for ($i = 1; $i -le 4; $i++) {

            # check if we can move up before attempting
            $parent = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Get-Location) -Parent
            if ($null -eq $parent) {
                Microsoft.PowerShell.Utility\Write-Verbose 'Cannot go up further - at root level'
                break
            }

            # prepare target description for ShouldProcess
            $target = "from '$(Microsoft.PowerShell.Management\Get-Location)' to '$parent' (level $i of 4)"

            # only navigate if ShouldProcess returns true
            if ($PSCmdlet.ShouldProcess($target, 'Change location')) {
                Microsoft.PowerShell.Management\Set-Location -LiteralPath $parent
            }
            else {
                # exit the loop if user declined
                break
            }
        }

        # show contents of the new current directory if not in WhatIf mode
        if (-not $WhatIfPreference -and (Microsoft.PowerShell.Management\Get-Location).Provider.Name -eq 'FileSystem') {
            Microsoft.PowerShell.Management\Get-ChildItem
        }
    }

    end {

        Microsoft.PowerShell.Utility\Write-Verbose "Completed navigation. New location: $PWD"
    }
}