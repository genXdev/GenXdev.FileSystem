<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Confirm-InstallationConsent.ps1
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
<#
.SYNOPSIS
Confirms user consent for installing third-party software, using
preferences for persistent choices.

.DESCRIPTION
This function acts as a custom ShouldProcess mechanism specifically for
software installations. It checks a user preference to determine if
automatic installation is allowed for the specified application. If no
preference is set, it prompts the user with a clear explanation of what
will be installed, the source, potential risks, and options to allow or
deny the installation (with options for one-time or persistent choices).

This ensures explicit user consent before proceeding with any installation,
helping to mitigate potential legal risks by requiring affirmative action
from the user. The prompt clearly states that the module author (GenXdev)
is not responsible for third-party software, and that the user is
consenting to the installation at their own risk.

Preferences are stored in a JSON file, allowing users to set "always
allow" for specific applications or enable global consent for all GenXdev
third-party installations, making it convenient while remaining legally
sound.

If consent is denied (or preference is set to deny), the function returns $false and does not
proceed with installation. If allowed, it returns $true.

.PARAMETER ApplicationName
The name of the application or software being installed (e.g., "Docker
Desktop", "Sysinternals Suite"). This is used to create a unique
preference key like "AllowInstall_DockerDesktop".

.PARAMETER Source
The source of the installation (e.g., "Winget", "PowerShell Gallery",
"apt-get in WSL", "dotnet CLI"). This is included in the explanation
prompt for transparency.

.PARAMETER Description
Optional detailed description of what the software does and why it's
being installed. If not provided, a generic message is used.

.PARAMETER Publisher
Optional publisher or vendor of the software (e.g., "Microsoft", "Docker
Inc."). Included in the prompt for clarity.

.PARAMETER ForceConsent
Forces a prompt even if a preference is already set (useful for
re-confirmation).

.EXAMPLE
if (Confirm-InstallationConsent -ApplicationName "Docker Desktop" `
        -Source "Winget") {
    # Proceed with installation
    Microsoft.WinGet.Client\Install-WinGetPackage `
        -Id "Docker.DockerDesktop"
}

This checks consent before installing Docker Desktop via Winget.

.EXAMPLE
Confirm-InstallationConsent -ApplicationName "Pester" `
    -Source "PowerShell Gallery" -Publisher "Pester Team" `
    -Description "Required for unit testing in PowerShell modules."

Prompts with detailed information before installing the Pester module.

.NOTES
- Preference keys are formatted as "AllowInstall_<ApplicationName>" (spaces
  removed for simplicity).
- Global consent key is "AllowInstall_GenXdevGlobal" which applies to all
  third-party installations.
- Preferences are stored in JSON format at:
  $Env:LOCALAPPDATA\GenXdev.PowerShell\SoftwareConsent.json
- If denied, no installation occurs, and the function returns $false.
- For legal soundness: The prompt explicitly requires user consent,
  disclaims liability, and explains risks (e.g., third-party software may
  have its own terms, potential security implications).
- Integrate this into your Ensure* functions by replacing automatic
  installations with a check like: if (-not (Confirm-InstallationConsent
  ...)) { throw "Installation consent denied." }
- For non-Winget installs (e.g., apt-get in EnsureYtdlp, dotnet in
  EnsureNuGetAssembly), still use this function for consistency.
- This function does not perform the installation itself—it's purely for
  consent checking.
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
        [ValidateNotNullOrEmpty()]
        [string] $Description = "This software is required for certain features in the GenXdev modules.",

        ###############################################################################
        [Parameter(Mandatory = $false,
            HelpMessage = "Optional publisher or vendor of the software.")]
        [ValidateNotNullOrEmpty()]
        [string] $Publisher = "Third-party vendor",

        ###############################################################################
        [Parameter(Mandatory = $false,
            HelpMessage = "Force a prompt even if preference is set.")]
        [switch] $ForceConsent,

        ###############################################################################
        [Parameter(Mandatory = $false,
            HelpMessage = "Automatically consent to third-party software installation and set persistent flag.")]
        [switch] $ConsentToThirdPartySoftwareInstallation
    )

    begin {
        # Normalize ApplicationName for preference key (remove spaces, make it safe)
        $safeAppName = $ApplicationName -replace '\s+', ''
        $preferenceKey = "AllowInstall_${safeAppName}"

        # Setup JSON file path for storing consent preferences
        $consentDir = Microsoft.PowerShell.Management\Join-Path $Env:LOCALAPPDATA "GenXdev.PowerShell"
        $consentFile = Microsoft.PowerShell.Management\Join-Path $consentDir "SoftwareConsent.json"

        Microsoft.PowerShell.Utility\Write-Verbose "Checking consent for installing '${ApplicationName}' from '${Source}'."

        # Helper function to read consent data
        function GetConsentData {
            try {
                if (Microsoft.PowerShell.Management\Test-Path $consentFile) {
                    $data = Microsoft.PowerShell.Management\Get-Content $consentFile -Raw -ErrorAction Stop |
                        Microsoft.PowerShell.Utility\ConvertFrom-Json -AsHashtable -ErrorAction Stop
                    if ($data) { return $data }
                }
            } catch {
                Microsoft.PowerShell.Utility\Write-Verbose "Could not read consent file: ${_}"
            }
            return @{}
        }

        # Helper function to save consent data
        function SaveConsentData {
            param([hashtable]$Data, [string]$Key, [string]$Value)
            try {
                if (-not (Microsoft.PowerShell.Management\Test-Path $consentDir)) {
                    Microsoft.PowerShell.Management\New-Item -Path $consentDir -ItemType Directory -Force |
                        Microsoft.PowerShell.Core\Out-Null
                }
                $Data[$Key] = $Value
                $Data | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 10 |
                    Microsoft.PowerShell.Management\Set-Content $consentFile -Encoding UTF8 -ErrorAction Stop
                return $true
            } catch {
                Microsoft.PowerShell.Utility\Write-Warning "Could not save consent preference: ${_}"
                return $false
            }
        }
    }

    process {
        # Check for global GenXdev consent first
        $globalConsentKey = "AllowInstall_GenXdevGlobal"
        $consentData = GetConsentData

        if ($consentData[$globalConsentKey] -eq 'true' -and -not $ForceConsent) {
            Microsoft.PowerShell.Utility\Write-Verbose "Global GenXdev consent allows installation of '${ApplicationName}'."
            return $true
        }

        # Check existing preference from JSON file
        $existingPref = $consentData[$preferenceKey]

        if ($existingPref -and -not $ForceConsent) {
            if ($existingPref -eq 'true') {
                Microsoft.PowerShell.Utility\Write-Verbose "Existing preference allows installation of '${ApplicationName}'."
                return $true
            } elseif ($existingPref -eq 'false') {
                Microsoft.PowerShell.Utility\Write-Warning "Installation of '${ApplicationName}' denied by user preference."
                return $false
            }
        }

        # Handle automatic consent parameter
        if ($ConsentToThirdPartySoftwareInstallation) {
            if (SaveConsentData -Data $consentData -Key $preferenceKey -Value 'true') {
                Microsoft.PowerShell.Utility\Write-Verbose "Automatic consent granted and persistent allowance set for '${ApplicationName}'."
            }
            return $true
        }

        # If no preference or ForceConsent, explain and prompt

        # Display colorized header
        Microsoft.PowerShell.Utility\Write-Host "`n" -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "### " -ForegroundColor Cyan -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "Installation Consent Required" -ForegroundColor Cyan -NoNewline
        Microsoft.PowerShell.Utility\Write-Host " ###`n" -ForegroundColor Cyan

        # Display software details with colors
        Microsoft.PowerShell.Utility\Write-Host "This PowerShell module (GenXdev) needs to install third-party software:" -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "  Software: " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "${ApplicationName}" -ForegroundColor Green
        Microsoft.PowerShell.Utility\Write-Host "  Publisher: " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "${Publisher}" -ForegroundColor Green
        Microsoft.PowerShell.Utility\Write-Host "  Source: " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "${Source}" -ForegroundColor Green
        Microsoft.PowerShell.Utility\Write-Host "  Purpose: " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "${Description}" -ForegroundColor Cyan

        # Display legal notes with warning colors
        Microsoft.PowerShell.Utility\Write-Host "`nImportant Legal and Safety Notes:" -ForegroundColor Yellow
        Microsoft.PowerShell.Utility\Write-Host "• This software is provided by a third party (" -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "${Publisher}" -ForegroundColor Yellow -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "), not by GenXdev or its author." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "• By consenting, you agree to download and install this software " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "at your own risk" -ForegroundColor Yellow -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "• GenXdev makes " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "no warranties" -ForegroundColor Yellow -NoNewline
        Microsoft.PowerShell.Utility\Write-Host " about the software's safety, functionality, or compliance." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "• Third-party software may have its own license terms, privacy policies, and potential risks." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "• You are responsible for reviewing the software's terms and ensuring compliance." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host "• " -ForegroundColor White -NoNewline
        Microsoft.PowerShell.Utility\Write-Host "No liability:" -ForegroundColor Yellow -NoNewline
        Microsoft.PowerShell.Utility\Write-Host " The author of GenXdev assumes no responsibility for any issues." -ForegroundColor White
        Microsoft.PowerShell.Utility\Write-Host ""

        # Use $Host.UI.PromptForChoice for professional prompt
        $title = "Installation Consent for '${ApplicationName}'"
        $message = "Do you consent to install this third-party software?"

        $choices = @(
            Microsoft.PowerShell.Utility\New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Yes (this time only)"
            Microsoft.PowerShell.Utility\New-Object System.Management.Automation.Host.ChoiceDescription "&Always", "Always allow (set persistent preference)"
            Microsoft.PowerShell.Utility\New-Object System.Management.Automation.Host.ChoiceDescription "&Global", "Always consent with GenXdev (allow all GenXdev third-party installations)"
            Microsoft.PowerShell.Utility\New-Object System.Management.Automation.Host.ChoiceDescription "&No", "No (this time only)"
            Microsoft.PowerShell.Utility\New-Object System.Management.Automation.Host.ChoiceDescription "&Help", "Show additional help information"
        )

        $defaultChoice = 3  # Default to "No"
        $choice = $Host.UI.PromptForChoice($title, $message, $choices, $defaultChoice)

        switch ($choice) {
            0 {  # Yes
                Microsoft.PowerShell.Utility\Write-Verbose "User consented for this installation only."
                return $true
            }
            1 {  # Always
                if (SaveConsentData -Data $consentData -Key $preferenceKey -Value 'true') {
                    Microsoft.PowerShell.Utility\Write-Host "Persistent allowance set for '${ApplicationName}'." -ForegroundColor Green
                    Microsoft.PowerShell.Utility\Write-Verbose "User set persistent allowance for '${ApplicationName}'."
                }
                return $true
            }
            2 {  # Global
                if (SaveConsentData -Data $consentData -Key $globalConsentKey -Value 'true') {
                    Microsoft.PowerShell.Utility\Write-Host "Global GenXdev consent enabled for all third-party software installations." -ForegroundColor Green
                    Microsoft.PowerShell.Utility\Write-Verbose "User enabled global GenXdev consent for all third-party installations."
                }
                return $true
            }
            3 {  # No
                Microsoft.PowerShell.Utility\Write-Host "Installation denied for this time." -ForegroundColor Yellow
                return $false
            }
            4 {  # Help
                Microsoft.PowerShell.Utility\Write-Host "`nAdditional Help:" -ForegroundColor Cyan
                Microsoft.PowerShell.Utility\Write-Host "• Choosing 'Always' options saves your preference to: " -ForegroundColor White -NoNewline
                Microsoft.PowerShell.Utility\Write-Host "${consentFile}" -ForegroundColor Green
                Microsoft.PowerShell.Utility\Write-Host "• 'Global' option enables automatic consent for ALL GenXdev third-party installations." -ForegroundColor White
                Microsoft.PowerShell.Utility\Write-Host "• You can manually edit the JSON file or delete it to reset all preferences." -ForegroundColor White
                Microsoft.PowerShell.Utility\Write-Host "• This prompt ensures your explicit consent to avoid any automatic installations." -ForegroundColor White
                Microsoft.PowerShell.Utility\Write-Host "• The preference key for this application is: " -ForegroundColor White -NoNewline
                Microsoft.PowerShell.Utility\Write-Host "${preferenceKey}" -ForegroundColor Green
                Microsoft.PowerShell.Utility\Write-Host "• The global preference key is: " -ForegroundColor White -NoNewline
                Microsoft.PowerShell.Utility\Write-Host "${globalConsentKey}" -ForegroundColor Green
                Microsoft.PowerShell.Utility\Write-Host ""

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