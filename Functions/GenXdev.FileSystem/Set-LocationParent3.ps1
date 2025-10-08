<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-LocationParent3.ps1
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
Navigates up three directory levels in the file system hierarchy.

.DESCRIPTION
Changes the current working directory by moving up three parent directories in
the filesystem hierarchy and displays the contents of the resulting directory.

.EXAMPLE
Set-LocationParent3

.EXAMPLE
....
#>
function Set-LocationParent3 {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('....')]

    param (
        ########################################################################
    )

    begin {

        # output verbose information about starting directory movement
        Microsoft.PowerShell.Utility\Write-Verbose "Moving up three directory levels from: $($PWD.Path)"
    }


    process {

        # navigate up three levels
        for ($i = 1; $i -le 3; $i++) {

            # check if we can move up before attempting
            $parent = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Get-Location) -Parent
            if ($null -eq $parent) {
                Microsoft.PowerShell.Utility\Write-Verbose 'Cannot go up further - at root level'
                break
            }

            # prepare target description for ShouldProcess
            $target = "from '$(Microsoft.PowerShell.Management\Get-Location)' to '$parent' (level $i of 3)"

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

        # output verbose information about final directory location
        Microsoft.PowerShell.Utility\Write-Verbose "Arrived at new location: $($PWD.Path)"
    }
}