<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-LocationParent.ps1
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
Changes the current location to the parent directory and lists its contents.

.DESCRIPTION
This function navigates up one directory level in the file system hierarchy and
displays the contents of the new current directory. It provides a convenient '..'
alias for quick directory navigation.

.EXAMPLE
Set-LocationParent

.EXAMPLE
..
#>
function Set-LocationParent {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('..')]
    param()

    begin {

        Microsoft.PowerShell.Utility\Write-Verbose 'Changing location to parent directory'
    }


    process {

        # check if we can move up before attempting
        $parent = Microsoft.PowerShell.Management\Split-Path(Microsoft.PowerShell.Management\Get-Location) -Parent
        if ($null -ne $parent) {

            # prepare target description for ShouldProcess
            $target = "from '$(Microsoft.PowerShell.Management\Get-Location)' to '$parent'"

            # only navigate if ShouldProcess returns true
            if ($PSCmdlet.ShouldProcess($target, 'Change location')) {
                # navigate up one directory level
                Microsoft.PowerShell.Management\Set-Location ..
            }
        }
        else {
            Microsoft.PowerShell.Utility\Write-Verbose 'Cannot go up further - at root level'
        }

        # show contents of the new current directory
        Microsoft.PowerShell.Management\Get-ChildItem
    }

    end {
    }
}