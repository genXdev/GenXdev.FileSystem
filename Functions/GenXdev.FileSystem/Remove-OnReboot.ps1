<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Remove-OnReboot.ps1
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
###############################################################################

<#
.SYNOPSIS
Marks files or directories for deletion during the next system boot.

.DESCRIPTION
This function uses the Windows API to mark files for deletion on next boot.
It handles locked files by first attempting to rename them to temporary names
and tracks all moves to maintain file system integrity. If renaming fails,
the -MarkInPlace parameter can be used to mark files in their original location.

.PARAMETER Path
One or more file or directory paths to mark for deletion. Accepts pipeline input.

.PARAMETER MarkInPlace
If specified, marks files for deletion in their original location when renaming
fails. This is useful for locked files that cannot be renamed.

.EXAMPLE
Remove-OnReboot -Path "C:\temp\locked-file.txt"

.EXAMPLE
"file1.txt","file2.txt" | Remove-OnReboot -MarkInPlace
#>
function Remove-OnReboot {

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        ###############################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'Path(s) to files/directories to mark for deletion'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string[]]$Path,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Marks files for deletion without renaming'
        )]
        [switch]$MarkInPlace
        ###############################################################################
    )

    begin {
        # registry location storing pending file operations
        $regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        $regName = 'PendingFileRenameOperations'

        # get existing pending renames or initialize empty array
        try {
            $pendingRenames = @(Microsoft.PowerShell.Management\Get-ItemProperty `
                    -Path $regKey `
                    -Name $regName -ErrorAction SilentlyContinue).$regName
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
                $fullPath = GenXdev.FileSystem\Expand-Path $item

                if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $fullPath) {
                    if ($PSCmdlet.ShouldProcess($fullPath, 'Mark for deletion on reboot')) {

                        try {
                            # attempt immediate deletion first
                            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop
                            Microsoft.PowerShell.Utility\Write-Verbose "Successfully deleted: $fullPath"
                            continue
                        }
                        catch {
                            Microsoft.PowerShell.Utility\Write-Verbose 'Direct deletion failed, attempting rename...'

                            try {
                                # create hidden temporary file name
                                $newName = '.' + [System.Guid]::NewGuid().ToString()
                                $newPath = [System.IO.Path]::Combine($dir, $newName)

                                # rename and hide the file
                                Microsoft.PowerShell.Management\Rename-Item -LiteralPath $fullPath -NewName $newName -Force `
                                    -ErrorAction Stop
                                $file = Microsoft.PowerShell.Management\Get-Item -LiteralPath $newPath -Force
                                $file.Attributes = $file.Attributes -bor `
                                    [System.IO.FileAttributes]::Hidden -bor `
                                    [System.IO.FileAttributes]::System

                                Microsoft.PowerShell.Utility\Write-Verbose "Renamed to hidden system file: $newPath"

                                # add to pending renames with windows api path format
                                $sourcePath = '\??\' + $newPath
                                $pendingRenames += $sourcePath
                                $pendingRenames += ''

                                Microsoft.PowerShell.Utility\Write-Verbose "Marked for deletion on reboot: $newPath"
                            }
                            catch {
                                if ($MarkInPlace) {
                                    Microsoft.PowerShell.Utility\Write-Verbose 'Marking original file for deletion'
                                    $sourcePath = '\??\' + $fullPath
                                    $pendingRenames += $sourcePath
                                    $pendingRenames += ''
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Error "Failed to rename $($fullPath): $_"
                                    continue
                                }
                            }
                        }
                    }
                }
                else {
                    Microsoft.PowerShell.Utility\Write-Warning "Path not found: $fullPath"
                }
            }

            if ($pendingRenames.Count -gt 0) {
                # save pending operations to registry
                Microsoft.PowerShell.Management\Set-ItemProperty -Path $regKey -Name $regName `
                    -Value $pendingRenames -Type MultiString
                return $true
            }
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Error "Failed to set pending file operations: $_"
            return $false
        }

        return $true
    }

    end {
    }
}