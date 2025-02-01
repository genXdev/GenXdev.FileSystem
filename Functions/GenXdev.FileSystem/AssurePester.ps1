################################################################################

function AssurePester {

    Import-Module -Name Pester -ErrorAction SilentlyContinue

    # Check if Pester is installed
    if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {

        Write-Host "Pester not found. Installing Pester..."

        # Install Pester from the PowerShell Gallery
        try {
            Install-Module -Name Pester -Force -SkipPublisherCheck | Out-Null
            Import-Module -Name Pester -Force | Out-Null
            Write-Host "Pester installed successfully."
        }
        catch {

            Write-Error "Failed to install Pester. Error: $PSItem"
        }
    }
}
