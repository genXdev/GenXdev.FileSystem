################################################################################
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

.EXAMPLE
Remove-ItemWithFallback -Path "C:\temp\myfile.txt"
Attempts to remove the file using all available methods.

.EXAMPLE
"C:\temp\mydir" | rif
Uses the alias 'rif' to remove a directory through the pipeline.
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
        [Alias("FullName")]
        [string]$Path
        ########################################################################
    )

    begin {

        # convert relative or provider paths to full filesystem paths
        $Path = Expand-Path $Path
    }

    process {
        try {
            # verify item exists and get its provider information
            $item = Get-Item -LiteralPath $Path `
                -ErrorAction Stop

            # handle filesystem items with direct IO methods for best performance
            if ($item.PSProvider.Name -eq 'FileSystem') {

                if ($PSCmdlet.ShouldProcess($Path, "Remove item")) {

                    # try fastest method first - direct file deletion
                    if ([System.IO.File]::Exists($Path)) {
                        [System.IO.File]::Delete($Path)
                        Write-Verbose "Successfully removed file using IO: $Path"
                        return $true
                    }

                    # handle directory deletion with recursive option
                    if ([System.IO.Directory]::Exists($Path)) {
                        [System.IO.Directory]::Delete($Path, $true)
                        Write-Verbose "Successfully removed directory using IO: $Path"
                        return $true
                    }
                }
            }
            else {
                # non-filesystem items need provider-specific handling
                if ($PSCmdlet.ShouldProcess($Path, "Remove via provider")) {
                    Remove-Item -LiteralPath $Path `
                        -Force
                    Write-Verbose "Removed item via provider: $Path"
                    return $true
                }
            }
        }
        catch {
            Write-Verbose "Standard deletion failed, attempting boot-time removal..."

            # only try boot-time deletion for filesystem items
            if ((Get-Item -LiteralPath $Path).PSProvider.Name -eq 'FileSystem') {

                # last resort - mark for deletion on next boot
                if (Remove-OnReboot -Path $Path) {
                    Write-Verbose "Marked for deletion on next reboot: $Path"
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
