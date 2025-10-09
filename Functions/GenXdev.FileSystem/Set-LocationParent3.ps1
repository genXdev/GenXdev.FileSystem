<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Set-LocationParent3.ps1
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