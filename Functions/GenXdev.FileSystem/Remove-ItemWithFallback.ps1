################################################################################
<#
.SYNOPSIS
Helper function to remove an item with provider-aware fallback handling.

.DESCRIPTION
Attempts to remove an item using multiple fallback methods:
1. Direct .NET IO methods
2. PowerShell Remove-Item cmdlet
3. Mark for deletion on next reboot if other methods fail

.PARAMETER Path
The path to the item to remove. Supports both files and directories.

.EXAMPLE
Remove-ItemWithFallback -Path "C:\temp\myfile.txt"

.EXAMPLE
rif "C:\temp\myfile.txt"
#>
function Remove-ItemWithFallback {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias("rif")]

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
        [string]$Path
        ########################################################################
    )

    begin {

        # expand path to full file system path
        $Path = Expand-Path $Path
    }

    process {
        try {
            # verify item exists and get provider info for proper handling
            $item = Get-Item -LiteralPath $Path -ErrorAction Stop

            # handle filesystem items using direct IO methods
            if ($item.PSProvider.Name -eq 'FileSystem') {

                if ($PSCmdlet.ShouldProcess($Path, "Remove item")) {

                    # remove files using System.IO
                    if ([System.IO.File]::Exists($Path)) {
                        [System.IO.File]::Delete($Path)
                        Write-Verbose "Successfully removed file: $Path"
                        return $true
                    }

                    # remove directories using System.IO
                    if ([System.IO.Directory]::Exists($Path)) {
                        [System.IO.Directory]::Delete($Path, $true)
                        Write-Verbose "Successfully removed directory: $Path"
                        return $true
                    }
                }
            }
            else {
                # fallback to provider-specific removal for non-filesystem items
                if ($PSCmdlet.ShouldProcess($Path, "Remove via provider")) {
                    Remove-Item -LiteralPath $Path -Force
                    Write-Verbose "Successfully removed item via provider: $Path"
                    return $true
                }
            }
        }
        catch {
            Write-Verbose "Direct deletion failed, attempting boot-time removal..."

            # only attempt boot-time deletion for filesystem items
            if ((Get-Item -LiteralPath $Path).PSProvider.Name -eq 'FileSystem') {

                # mark item for deletion on next system reboot
                if (Remove-OnReboot -Path $Path) {
                    Write-Verbose "Successfully marked for deletion on reboot: $Path"
                    return $true
                }
            }

            Write-Warning "All deletion methods failed for: $Path"
            Write-Error $_.Exception.Message
            return $false
        }
    }

    end {
    }
}
################################################################################
