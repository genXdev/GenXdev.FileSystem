<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Remove-OnReboot.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.268.2025
################################################################################
MIT License

Copyright 2021-2025 GenXdev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
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