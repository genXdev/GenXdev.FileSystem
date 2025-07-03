###############################################################################
<#
.SYNOPSIS
Removes files or directories with multiple fallback mechanisms for reliable deletion.

.DESCRIPTION
This function provides a robust way to delete files and directories by attempting
multiple deletion methods in sequence:
1. Direct deletion via System.IO methods for best performance
2. PowerShell provider-aware Remove-Item cmdlet as fallback
3. Mark for deletion on next system reboot if other methods fail
This ensures maximum reliability when removing items across different providers.

.PARAMETER Path
The file or directory path to remove. Can be a filesystem path or provider path.
Accepts pipeline input and wildcards. Must be a valid, non-empty path.

.PARAMETER CountRebootDeletionAsSuccess
If specified, the function returns $true when a file is successfully marked for deletion on reboot.
By default ($false), the function returns $false in this scenario.

.EXAMPLE
Remove-ItemWithFallback -Path "C:\temp\myfile.txt"
Attempts to remove the file using all available methods.

.EXAMPLE
"C:\temp\mydir" | rif
Uses the alias 'rif' to remove a directory through the pipeline.
        ###############################################################################>
function Remove-ItemWithFallback {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    [Alias("rmf")]

    param(
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "The path to the item to remove"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$Path,
        ########################################################################
        [Parameter(
            Mandatory = $false
        )]
        [switch]$CountRebootDeletionAsSuccess = $false
        ########################################################################
    )

    begin {

        # convert relative or provider paths to full filesystem paths
        $Path = GenXdev.FileSystem\Expand-Path $Path
    }

    process {
        try {
            # verify item exists and get its provider information
            $item = Microsoft.PowerShell.Management\Get-Item -LiteralPath $Path `
                -ErrorAction Stop

            # handle filesystem items with direct IO methods for best performance
            if ($item.PSProvider.Name -eq 'FileSystem') {

                if ($PSCmdlet.ShouldProcess($Path, "Remove item")) {

                    # try fastest method first - direct file deletion
                    if ([System.IO.File]::Exists($Path)) {
                        try {
                            [System.IO.File]::Delete($Path)
                            Microsoft.PowerShell.Utility\Write-Verbose "Successfully removed file using IO: $Path"
                            return $true
                        }
                        catch {
                            # If ErrorAction Stop was specified, immediately rethrow
                            if (($PSBoundParameters.ContainsKey('ErrorAction') -and $PSBoundParameters['ErrorAction'] -eq 'Stop') -or
                                $ErrorActionPreference -eq 'Stop') {
                                throw
                            }
                            # Otherwise, fall through to next deletion method
                            Microsoft.PowerShell.Utility\Write-Verbose "Direct file deletion failed: $_"
                            # Don't rethrow here - let the code flow to the next deletion method
                        }
                    }

                    # handle directory deletion with recursive option
                    if ([System.IO.Directory]::Exists($Path)) {
                        try {
                            [System.IO.Directory]::Delete($Path, $true)
                            Microsoft.PowerShell.Utility\Write-Verbose "Successfully removed directory using IO: $Path"
                            return $true
                        }
                        catch {
                            # If ErrorAction Stop was specified, immediately rethrow
                            if (($PSBoundParameters.ContainsKey('ErrorAction') -and $PSBoundParameters['ErrorAction'] -eq 'Stop') -or
                                $ErrorActionPreference -eq 'Stop') {
                                throw
                            }
                            # Otherwise, fall through to next deletion method
                            Microsoft.PowerShell.Utility\Write-Verbose "Direct directory deletion failed: $_"
                            # Don't rethrow here - let the code flow to the next deletion method
                        }
                    }
                }
            }
            else {
                # non-filesystem items need provider-specific handling
                if ($PSCmdlet.ShouldProcess($Path, "Remove via provider")) {
                    Microsoft.PowerShell.Management\Remove-Item -LiteralPath $Path `
                        -Force
                    Microsoft.PowerShell.Utility\Write-Verbose "Removed item via provider: $Path"
                    return $true
                }
            }
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Verbose "Standard deletion failed, attempting boot-time removal..."

            # Check if ErrorAction Stop was specified via parameter or preference variable
            if (($PSBoundParameters.ContainsKey('ErrorAction') -and $PSBoundParameters['ErrorAction'] -eq 'Stop') -or
                $ErrorActionPreference -eq 'Stop') {
                # Rethrow the original exception immediately without trying fallback methods
                throw
            }

            # Only try boot-time deletion for filesystem items and verify path exists first
            if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue) {
                $providerInfo = (Microsoft.PowerShell.Management\Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue).PSProvider

                if ($null -ne $providerInfo -and $providerInfo.Name -eq 'FileSystem') {
                    # last resort - mark for deletion on next boot
                    if (GenXdev.FileSystem\Remove-OnReboot -Path $Path) {
                        Microsoft.PowerShell.Utility\Write-Verbose "Marked for deletion on next reboot: $Path"
                        return [bool]$CountRebootDeletionAsSuccess
                    }
                }
            }

            Microsoft.PowerShell.Utility\Write-Warning "All deletion methods failed for: $Path"
            Microsoft.PowerShell.Utility\Write-Error $_.Exception.Message
            return $false
        }
    }

    end {
    }
}
        ###############################################################################