##############################################################################
# Part of PowerShell module : GenXdev.Helpers
# Cmdlet filename           : Confirm-InstallationConsent.ps1
# Author                    : René Vaessen / GenXdev (with AI assistance)
# Version                   : 1.0.0
################################################################################
# MIT License
#
# Copyright 2021-2025 GenXdev
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################
<#
.SYNOPSIS
Confirms user consent for installing third-party software, using preferences for persistent choices.

.DESCRIPTION
This function acts as a custom ShouldProcess mechanism specifically for software installations.
It checks a user preference (via Get-GenXdevPreference) to determine if automatic installation
is allowed for the specified application. If no preference is set, it prompts the user with
a clear explanation of what will be installed, the source, potential risks, and options to
allow or deny the installation (with options for one-time or persistent choices).

This ensures explicit user consent before proceeding with any installation, helping to
mitigate potential legal risks by requiring affirmative action from the user. The prompt
clearly states that the module author (GenXdev) is not responsible for third-party software,
and that the user is consenting to the installation at their own risk.

Preferences are stored using Set-GenXdevPreference, allowing users to set "always allow"
or "always deny" for specific applications, making it convenient while remaining legally sound.

If consent is denied (or preference is set to deny), the function returns $false and does not
proceed with installation. If allowed, it returns $true.

.PARAMETER ApplicationName
The name of the application or software being installed (e.g., "Docker Desktop", "Sysinternals Suite").
This is used to create a unique preference key like "AllowInstall_DockerDesktop".

.PARAMETER Source
The source of the installation (e.g., "Winget", "PowerShell Gallery", "apt-get in WSL", "dotnet CLI").
This is included in the explanation prompt for transparency.

.PARAMETER Description
Optional detailed description of what the software does and why it's being installed.
If not provided, a generic message is used.

.PARAMETER Publisher
Optional publisher or vendor of the software (e.g., "Microsoft", "Docker Inc.").
Included in the prompt for clarity.

.PARAMETER ForcePrompt
Forces a prompt even if a preference is already set (useful for re-confirmation).

.EXAMPLE
if (Confirm-InstallationConsent -ApplicationName "Docker Desktop" -Source "Winget") {
    # Proceed with installation
    Microsoft.WinGet.Client\Install-WinGetPackage -Id "Docker.DockerDesktop"
}

This checks consent before installing Docker Desktop via Winget.

.EXAMPLE
Confirm-InstallationConsent -ApplicationName "Pester" -Source "PowerShell Gallery" -Publisher "Pester Team" -Description "Required for unit testing in PowerShell modules."

Prompts with detailed information before installing the Pester module.

.NOTES
- Preference keys are formatted as "AllowInstall_<ApplicationName>" (spaces removed for simplicity).
- Preferences are stored in JSON format at: $Env:LOCALAPPDATA\GenXdev.PowerShell\SoftwareConsent.json
- If denied, no installation occurs, and the function returns $false.
- For legal soundness: The prompt explicitly requires user consent, disclaims liability, and explains risks (e.g., third-party software may have its own terms, potential security implications).
- Integrate this into your Ensure* functions by replacing automatic installations with a check like: if (-not (Confirm-InstallationConsent ...)) { throw "Installation consent denied." }
- For non-Winget installs (e.g., apt-get in EnsureYtdlp, dotnet in EnsureNuGetAssembly), still use this function for consistency.
- This function does not perform the installation itself—it's purely for consent checking.
#>
function Confirm-InstallationConsent {

    [CmdletBinding()]
    [OutputType([System.Boolean])]

    param(
        [Parameter(Mandatory = $true, Position = 0,
            HelpMessage = "The name of the application or software being installed.")]
        [ValidateNotNullOrEmpty()]
        [string] $ApplicationName,

        [Parameter(Mandatory = $true, Position = 1,
            HelpMessage = "The source of the installation (e.g., Winget, PowerShell Gallery).")]
        [ValidateNotNullOrEmpty()]
        [string] $Source,

        [Parameter(Mandatory = $false,
            HelpMessage = "Optional description of the software and its purpose.")]
        [string] $Description = "This software is required for certain features in the GenXdev modules.",

        [Parameter(Mandatory = $false,
            HelpMessage = "Optional publisher or vendor of the software.")]
        [string] $Publisher = "Third-party vendor",

        [Parameter(Mandatory = $false,
            HelpMessage = "Force a prompt even if preference is set.")]
        [switch] $ForcePrompt
    )

    begin {
        # Normalize ApplicationName for preference key (remove spaces, make it safe)
        $safeAppName = $ApplicationName -replace '\s+', ''
        $preferenceKey = "AllowInstall_$safeAppName"

        # Setup JSON file path for storing consent preferences
        $consentDir = Microsoft.PowerShell.Management\Join-Path $Env:LOCALAPPDATA "GenXdev.PowerShell"
        $consentFile = Microsoft.PowerShell.Management\Join-Path $consentDir "SoftwareConsent.json"

        Microsoft.PowerShell.Utility\Write-Verbose "Checking consent for installing '$ApplicationName' from '$Source'."
    }

    process {
        # Check existing preference from JSON file
        $existingPref = $null
        try {
            if (Microsoft.PowerShell.Management\Test-Path $consentFile) {
                $consentData = Microsoft.PowerShell.Management\Get-Content $consentFile -Raw | Microsoft.PowerShell.Utility\ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($consentData -and $consentData.PSObject.Properties.Name -contains $preferenceKey) {
                    $existingPref = $consentData.$preferenceKey
                }
            }
        } catch {
            Microsoft.PowerShell.Utility\Write-Verbose "Could not read consent file: $_"
        }

        if ($existingPref -and -not $ForcePrompt) {
            if ($existingPref -eq 'true') {
                Microsoft.PowerShell.Utility\Write-Verbose "Existing preference allows installation of '$ApplicationName'."
                return $true
            } elseif ($existingPref -eq 'false') {
                Microsoft.PowerShell.Utility\Write-Warning "Installation of '$ApplicationName' denied by user preference."
                return $false
            }
        }

        # If no preference or ForcePrompt, explain and prompt
        $promptMessage = @"
`n### Installation Consent Required for '$ApplicationName' ###

This PowerShell module (GenXdev) needs to install third-party software: '$ApplicationName'.
- Publisher: $Publisher
- Source: $Source
- Purpose: $Description

Important Legal and Safety Notes:
- This software is provided by a third party ($Publisher), not by GenXdev or its author (René Vaessen).
- By consenting, you agree to download and install this software at your own risk.
- GenXdev makes no warranties about the software's safety, functionality, or compliance with laws.
- Third-party software may have its own license terms, privacy policies, and potential risks (e.g., security vulnerabilities, data collection).
- You are responsible for reviewing the software's terms and ensuring it meets your needs and legal requirements.
- No liability: The author of GenXdev (René Vaessen) assumes no responsibility for any issues arising from this installation.

Do you consent to install '$ApplicationName'?
- [Y] Yes (this time only)
- [A] Always allow (set persistent preference)
- [N] No (this time only)
- [D] Always deny (set persistent preference)
- [?] Help (more info)

Your choice:
"@

        # Display the prompt
        Microsoft.PowerShell.Utility\Write-Host $promptMessage -ForegroundColor Yellow

        # Get user input
        $choice = Microsoft.PowerShell.Utility\Read-Host
        $choice = $choice.ToUpper()

        switch ($choice) {
            'Y' {
                Microsoft.PowerShell.Utility\Write-Verbose "User consented for this installation only."
                return $true
            }
            'A' {
                try {
                    # Ensure directory exists
                    if (-not (Microsoft.PowerShell.Management\Test-Path $consentDir)) {
                        Microsoft.PowerShell.Management\New-Item -Path $consentDir -ItemType Directory -Force | Microsoft.PowerShell.Core\Out-Null
                    }

                    # Load existing data or create new
                    $consentData = @{}
                    if (Microsoft.PowerShell.Management\Test-Path $consentFile) {
                        $consentData = Microsoft.PowerShell.Management\Get-Content $consentFile -Raw | Microsoft.PowerShell.Utility\ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
                        if (-not $consentData) { $consentData = @{} }
                    }

                    # Update and save
                    $consentData[$preferenceKey] = 'true'
                    $consentData | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 10 | Microsoft.PowerShell.Management\Set-Content $consentFile -Encoding UTF8
                    Microsoft.PowerShell.Utility\Write-Verbose "User set persistent allowance for '$ApplicationName'."
                } catch {
                    Microsoft.PowerShell.Utility\Write-Warning "Could not save consent preference: $_"
                }
                return $true
            }
            'N' {
                Microsoft.PowerShell.Utility\Write-Warning "User denied installation for this time."
                return $false
            }
            'D' {
                try {
                    # Ensure directory exists
                    if (-not (Microsoft.PowerShell.Management\Test-Path $consentDir)) {
                        Microsoft.PowerShell.Management\New-Item -Path $consentDir -ItemType Directory -Force | Microsoft.PowerShell.Core\Out-Null
                    }

                    # Load existing data or create new
                    $consentData = @{}
                    if (Microsoft.PowerShell.Management\Test-Path $consentFile) {
                        $consentData = Microsoft.PowerShell.Management\Get-Content $consentFile -Raw | Microsoft.PowerShell.Utility\ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
                        if (-not $consentData) { $consentData = @{} }
                    }

                    # Update and save
                    $consentData[$preferenceKey] = 'false'
                    $consentData | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 10 | Microsoft.PowerShell.Management\Set-Content $consentFile -Encoding UTF8
                    Microsoft.PowerShell.Utility\Write-Warning "User set persistent denial for '$ApplicationName'."
                } catch {
                    Microsoft.PowerShell.Utility\Write-Warning "Could not save consent preference: $_"
                }
                return $false
            }
            '?' {
                Microsoft.PowerShell.Utility\Write-Host @"
Additional Help:
- Choosing 'Always' options saves your preference to: $consentFile
- You can manually edit the JSON file or delete it to reset all preferences.
- This prompt ensures your explicit consent to avoid any automatic installations.
- The preference key for this application is: $preferenceKey
"@ -ForegroundColor Cyan

                # Re-prompt after help
                return GenXdev.FileSystem\Confirm-InstallationConsent @PSBoundParameters
            }
            default {
                Microsoft.PowerShell.Utility\Write-Warning "Invalid choice. Treating as denial."
                return $false
            }
        }
    }
}
