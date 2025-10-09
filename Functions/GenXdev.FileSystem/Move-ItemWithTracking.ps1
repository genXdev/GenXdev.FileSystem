<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Move-ItemWithTracking.ps1
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
################################################################################
<#
.SYNOPSIS
Moves files and directories while preserving filesystem links and references.

.DESCRIPTION
Uses the Windows MoveFileEx API to move files and directories with link tracking
enabled. This ensures that filesystem references, symbolic links, and hardlinks
are maintained. If the source path is under Git control, it attempts to use `git mv`
to track the rename in Git. Falls back to MoveFileEx if Git is not available or
the git mv operation fails. The function is particularly useful for tools like Git
that need to track file renames.

.OUTPUTS
System.Boolean
Returns $true if the move operation succeeds, $false otherwise.

.PARAMETER Path
The source path of the file or directory to move. Accepts pipeline input and
aliases to FullName for compatibility with Get-ChildItem output.

.PARAMETER Destination
The target path where the file or directory should be moved to. Must be a valid
filesystem path.

.PARAMETER Force
If specified, allows overwriting an existing file or directory at the
destination path.

.EXAMPLE
Move-ItemWithTracking -Path "C:\temp\oldfile.txt" -Destination "D:\newfile.txt"
Moves a file while preserving any existing filesystem links or Git tracking

.EXAMPLE
"C:\temp\olddir" | Move-ItemWithTracking -Destination "D:\newdir" -Force
Moves a directory, overwriting destination if it exists, with Git tracking if applicable
#>
function Move-ItemWithTracking {

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    param(
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Source path of file/directory to move'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string]$Path,
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Destination path to move to'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        ########################################################################
        [Parameter(
            HelpMessage = 'Overwrite destination if it exists'
        )]
        [switch]$Force
        ########################################################################
    )

    begin {

        # define the native windows api function signature for moving files
        $signature = @'
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool MoveFileEx(
    string lpExistingFileName,
    string lpNewFileName,
    int dwFlags);
'@

        try {
            # load the native windows api function into the current session
            $win32 = Microsoft.PowerShell.Utility\Add-Type -MemberDefinition $signature `
                -Name 'MoveFileExUtils' `
                -Namespace Win32 `
                -PassThru
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Error "Failed to load Win32 API: $_"
            return $false
        }

        # configure move operation flags for link tracking and overwrite handling
        $moveFileWriteThrough = 0x8  # ensures the move completes before returning
        $moveFileReplaceExisting = 0x1  # allows overwriting existing files

        # combine flags based on whether Force parameter was specified
        $flags = $moveFileWriteThrough
        if ($Force) {
            $flags = $flags -bor $moveFileReplaceExisting
        }
    }

    process {
        try {
            # convert relative paths to absolute filesystem paths
            $fullSourcePath = GenXdev.FileSystem\Expand-Path $Path
            $fullDestPath = GenXdev.FileSystem\Expand-Path $Destination

            # verify the source path exists before attempting move
            if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $fullSourcePath -ErrorAction SilentlyContinue) {

                # check if user wants to proceed with the operation
                if ($PSCmdlet.ShouldProcess($fullSourcePath, "Move to $fullDestPath")) {

                    # Check if git is available
                    $gitAvailable = $null -ne (Microsoft.PowerShell.Core\Get-Command git.exe -ErrorAction SilentlyContinue)

                    if ($gitAvailable) {
                        # Check if the source path is under Git control
                        $sourceDir = [System.IO.Path]::GetDirectoryName($fullSourcePath)
                        Microsoft.PowerShell.Management\Push-Location -Path $sourceDir
                        try {
                            $gitStatus = & git rev-parse --is-inside-work-tree 2>$null
                            $isGitRepo = $gitStatus -eq 'true'
                        }
                        finally {
                            Microsoft.PowerShell.Management\Pop-Location
                        }

                        if ($isGitRepo) {
                            Microsoft.PowerShell.Utility\Write-Verbose "Source path is under Git control, attempting git mv"
                            # Attempt git mv
                            try {
                                $gitMvArgs = $Force ? "-f" : ""
                                & git mv $gitMvArgs $fullSourcePath $fullDestPath 2>$null
                                if ($LASTEXITCODE -eq 0) {
                                    Microsoft.PowerShell.Utility\Write-Verbose "Git mv completed successfully"
                                    # Verify the move occurred
                                    if (-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $fullSourcePath) -and
                                        (Microsoft.PowerShell.Management\Test-Path -LiteralPath $fullDestPath)) {
                                        return $true
                                    }
                                    else {
                                        Microsoft.PowerShell.Utility\Write-Verbose "Git mv reported success but move not confirmed, falling back to MoveFileEx"
                                    }
                                }
                                else {
                                    Microsoft.PowerShell.Utility\Write-Verbose "Git mv failed, falling back to MoveFileEx"
                                }
                            }
                            catch {
                                Microsoft.PowerShell.Utility\Write-Verbose "Error during git mv: $_, falling back to MoveFileEx"
                            }
                        }
                    }

                    # Fallback to original MoveFileEx logic if not in Git or git mv failed
                    Microsoft.PowerShell.Utility\Write-Verbose "Moving $fullSourcePath to $fullDestPath using MoveFileEx"
                    $result = $win32::MoveFileEx($fullSourcePath, $fullDestPath, $flags)

                    if (-not $result) {
                        # get detailed error information on failure
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        throw ("Move failed from '$fullSourcePath' to '$fullDestPath'. Error: $errorCode")
                    }

                    Microsoft.PowerShell.Utility\Write-Verbose 'Move completed successfully with link tracking'
                    return $true
                }
            }
            else {
                Microsoft.PowerShell.Utility\Write-Warning "Source path not found: $fullSourcePath"
                return $false
            }
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Error $_
            return $false
        }
    }

    end {
    }
}