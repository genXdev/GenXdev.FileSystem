<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : EnsurePester.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.302.2025
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
Ensures Pester testing framework is available for use.

.DESCRIPTION
This function verifies if the Pester module is installed in the current
PowerShell environment. If not found, it automatically installs it from the
PowerShell Gallery and imports it into the current session. This ensures that
Pester testing capabilities are available when needed.

.EXAMPLE
EnsurePester
This ensures Pester is installed and ready for use
#>
function EnsurePester {

    [CmdletBinding()]
    param()

    begin {

        # inform user that we're checking pester installation
        Microsoft.PowerShell.Utility\Write-Verbose 'Checking for Pester module installation...'
    }


    process {

        # attempt silent import of pester to check if it's available
        Microsoft.PowerShell.Core\Import-Module -Name Pester -ErrorAction SilentlyContinue

        $found = (Microsoft.PowerShell.Core\Get-Module -Name Pester -ErrorAction SilentlyContinue);

        # verify if pester module is now loaded in the current session
        if ((-not $found) -or ($found.Version -lt '5.7.0')) {

            # notify about installation attempt through verbose and regular output
            Microsoft.PowerShell.Utility\Write-Verbose 'Pester module not found, attempting installation...'
            Microsoft.PowerShell.Utility\Write-Host 'Pester not found. Installing Pester...'

            try {
                # install pester module from the powershell gallery
                $null = PowerShellGet\Install-Module -Name Pester `
                    -Force `
                    -SkipPublisherCheck

                # load the newly installed pester module
                $null = Microsoft.PowerShell.Core\Import-Module -Name Pester -Force

                # confirm successful installation
                Microsoft.PowerShell.Utility\Write-Host 'Pester installed successfully.'
                Microsoft.PowerShell.Utility\Write-Verbose 'Pester module installation and import completed.'
            }
            catch {
                # report any installation failures
                Microsoft.PowerShell.Utility\Write-Error "Failed to install Pester. Error: $PSItem"
                Microsoft.PowerShell.Utility\Write-Verbose 'Pester installation failed with error.'
            }
        }
        else {
            # inform that pester is already available
            Microsoft.PowerShell.Utility\Write-Verbose 'Pester module already installed and imported.'
        }
    }

    end {
    }
}