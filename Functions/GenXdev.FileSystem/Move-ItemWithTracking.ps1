################################################################################
<#
.SYNOPSIS
Moves files and directories while preserving filesystem links and references.

.DESCRIPTION
Uses the Windows MoveFileEx API to move files and directories with link tracking
enabled. This ensures that filesystem references, symbolic links, and hardlinks
are maintained. The function is particularly useful for tools like Git that need
to track file renames.

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
# Moves a file while preserving any existing filesystem links

.EXAMPLE
"C:\temp\olddir" | Move-ItemWithTracking -Destination "D:\newdir" -Force
# Moves a directory, overwriting destination if it exists
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
            HelpMessage = "Source path of file/directory to move"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$Path,
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Destination path to move to"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        ########################################################################
        [Parameter(
            HelpMessage = "Overwrite destination if it exists"
        )]
        [switch]$Force
        ########################################################################
    )

    begin {

        # define the native windows api function signature for moving files
        $signature = @"
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool MoveFileEx(
    string lpExistingFileName,
    string lpNewFileName,
    int dwFlags);
"@

        try {
            # load the native windows api function into the current session
            $win32 = Add-Type -MemberDefinition $signature `
                -Name "MoveFileExUtils" `
                -Namespace Win32 `
                -PassThru
        }
        catch {
            Write-Error "Failed to load Win32 API: $_"
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
            if (Test-Path -LiteralPath $fullSourcePath) {

                # check if user wants to proceed with the operation
                if ($PSCmdlet.ShouldProcess($fullSourcePath,
                        "Move to $fullDestPath")) {

                    Write-Verbose "Moving $fullSourcePath to $fullDestPath"

                    # perform the move operation with link tracking
                    $result = $win32::MoveFileEx($fullSourcePath,
                        $fullDestPath, $flags)

                    if (-not $result) {
                        # get detailed error information on failure
                        $errorCode = [System.Runtime.InteropServices.Marshal]:: `
                            GetLastWin32Error()
                        throw "Move failed from '$fullSourcePath' to " +
                        "'$fullDestPath'. Error: $errorCode"
                    }

                    Write-Verbose "Move completed successfully with link tracking"
                    return $true
                }
            }
            else {
                Write-Warning "Source path not found: $fullSourcePath"
                return $false
            }
        }
        catch {
            Write-Error $_
            return $false
        }
    }

    end {
    }
}
################################################################################
