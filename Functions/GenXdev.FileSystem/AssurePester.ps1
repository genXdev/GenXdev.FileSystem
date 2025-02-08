################################################################################
<#
.SYNOPSIS
Ensures that Pester testing framework is installed and available.

.DESCRIPTION
This function checks if Pester module is installed. If not found, it attempts to
install it from the PowerShell Gallery and imports it into the current session.

.EXAMPLE
AssurePester
#>
function AssurePester {

    [CmdletBinding()]
    param()

    begin {

        Write-Verbose "Checking for Pester module installation..."
    }

    process {

        # attempt to import pester module without showing errors
        Import-Module -Name Pester -ErrorAction SilentlyContinue

        # check if pester module is available
        if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {

            Write-Verbose "Pester module not found, attempting installation..."
            Write-Host "Pester not found. Installing Pester..."

            try {
                # install pester from powershell gallery
                $null = Install-Module -Name Pester -Force -SkipPublisherCheck

                # import the newly installed module
                $null = Import-Module -Name Pester -Force

                Write-Host "Pester installed successfully."
                Write-Verbose "Pester module installation and import completed."
            }
            catch {
                Write-Error "Failed to install Pester. Error: $PSItem"
                Write-Verbose "Pester installation failed with error."
            }
        }
        else {
            Write-Verbose "Pester module already installed and imported."
        }
    }

    end {
    }
}
################################################################################
