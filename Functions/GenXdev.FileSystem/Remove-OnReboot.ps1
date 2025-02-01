################################################################################

<#
.SYNOPSIS
Marks a file for deletion on next system boot using Windows API.

.DESCRIPTION
Items are renamed to a temporary filename first to handle
locked files. All moves are tracked to maintain file system links.

.PARAMETER Path
The path(s) to the files or directories to mark for deletion.

.PARAMETER MarkInPlace
Marks the file for deletion even if renaming it fails.

.EXAMPLE
Remove-OnReboot -Path "C:\temp\locked-file.txt"

.EXAMPLE
"file1.txt","file2.txt" | Remove-OnReboot
#>
function Remove-OnReboot {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        ###############################################################################
        [Parameter(Mandatory = $false, HelpMessage = "Marks the file for deletion even if renaming it fails")]
        [switch]$MarkInPlace
        ###############################################################################
    )

    begin {
        # Registry key for pending file operations
        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
        $regName = "PendingFileRenameOperations"

        # Get existing pending renames or create new array
        try {
            $pendingRenames = @(Get-ItemProperty -Path $regKey -Name $regName -ErrorAction SilentlyContinue).$regName
        }
        catch {
            $pendingRenames = @()
        }

        if ($null -eq $pendingRenames) {
            $pendingRenames = @()
        }
    }

    process {
        try {
            foreach ($item in $Path) {
                $fullPath = Expand-Path $item

                if (Test-Path -LiteralPath $fullPath) {
                    if ($PSCmdlet.ShouldProcess($fullPath, "Mark for deletion on reboot")) {
                        try {
                            # Try direct deletion first
                            Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop
                            Write-Verbose "Successfully deleted: $fullPath"
                            continue
                        }
                        catch {
                            Write-Verbose "Direct deletion failed for $fullPath, attempting rename and mark for deletion..."

                            try {
                                # Get directory and generate new hidden name
                                $newName = "." + [System.Guid]::NewGuid().ToString()
                                $newPath = [System.IO.Path]::Combine($dir, $newName)

                                # Rename the file and set attributes
                                Rename-Item -Path $fullPath -NewName $newName -Force -ErrorAction Stop
                                $file = Get-Item -LiteralPath $newPath -Force
                                $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System

                                Write-Verbose "Renamed to hidden system file: $newPath"

                                # Format paths with \??\ prefix for registry
                                $sourcePath = "\??\" + $newPath
                                $pendingRenames += $sourcePath
                                $pendingRenames += ""

                                Write-Verbose "Marked for deletion on reboot: $newPath"
                            }
                            catch {
                                if ($MarkInPlace) {
                                    Write-Verbose "Renaming failed, marking in place for deletion on reboot: $fullPath"
                                    $sourcePath = "\??\" + $fullPath
                                    $pendingRenames += $sourcePath
                                    $pendingRenames += ""
                                } else {
                                    Write-Error "Failed to rename $($fullPath): $_"
                                    continue
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Warning "Path not found: $fullPath"
                }
            }

            if ($pendingRenames.Count -gt 0) {
                # Save as REG_MULTI_SZ
                Set-ItemProperty -Path $regKey -Name $regName -Value $pendingRenames -Type MultiString
                return $true
            }
        }
        catch {
            Write-Error "Failed to set pending file operations: $_"
            return $false
        }
        
        return $true
    }
}
