################################################################################
<#
.SYNOPSIS
Ensures Pester testing framework is available for use.

.DESCRIPTION
This function verifies if the Pester module is installed in the current
PowerShell environment. If not found, it automatically installs it from the
PowerShell Gallery and imports it into the current session. This ensures that
Pester testing capabilities are available when needed.

.EXAMPLE
AssurePester
# This ensures Pester is installed and ready for use
#>
function AssurePester {

    [CmdletBinding()]
    param()

    begin {

        # inform user that we're checking pester installation
        Write-Verbose "Checking for Pester module installation..."
    }

    process {

        # attempt silent import of pester to check if it's available
        Import-Module -Name Pester -ErrorAction SilentlyContinue

        # verify if pester module is now loaded in the current session
        if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {

            # notify about installation attempt through verbose and regular output
            Write-Verbose "Pester module not found, attempting installation..."
            Write-Host "Pester not found. Installing Pester..."

            try {
                # install pester module from the powershell gallery
                $null = Install-Module -Name Pester `
                    -Force `
                    -SkipPublisherCheck

                # load the newly installed pester module
                $null = Import-Module -Name Pester -Force

                # confirm successful installation
                Write-Host "Pester installed successfully."
                Write-Verbose "Pester module installation and import completed."
            }
            catch {
                # report any installation failures
                Write-Error "Failed to install Pester. Error: $PSItem"
                Write-Verbose "Pester installation failed with error."
            }
        }
        else {
            # inform that pester is already available
            Write-Verbose "Pester module already installed and imported."
        }
    }

    end {
    }
}
################################################################################
