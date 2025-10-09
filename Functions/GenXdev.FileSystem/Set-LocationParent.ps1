<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-LocationParent.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.300.2025
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