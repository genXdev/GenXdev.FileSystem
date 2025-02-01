################################################################################
<#
.SYNOPSIS
Moves a file or directory while maintaining file system links and references.

.DESCRIPTION
Moves files and directories using the Windows MoveFileEx API with link tracking
enabled. This preserves file system references, symbolic links, and helps tools
like Git track renamed files.

.PARAMETER Path
The source path of the file or directory to move.

.PARAMETER Destination
The destination path where the item should be moved to.

.PARAMETER Force
If specified, will overwrite an existing destination file.

.EXAMPLE
Move-ItemWithTracking -Path ".\oldname.txt" -Destination ".\newname.txt"

.EXAMPLE
Move-ItemWithTracking -Path ".\olddir" -Destination ".\newdir" -Force
#>
function Move-ItemWithTracking {

    [CmdletBinding(SupportsShouldProcess)]
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

        # define the win32 api signature for moving files with link tracking
        $signature = @"
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool MoveFileEx(
    string lpExistingFileName,
    string lpNewFileName,
    int dwFlags);
"@

        try {
            # load the win32 api function into memory
            $win32 = Add-Type -MemberDefinition $signature `
                -Name "MoveFileExUtils" `
                -Namespace Win32 `
                -PassThru
        }
        catch {
            Write-Error "Failed to load Win32 API: $_"
            return $false
        }

        # set flags for maintaining links and handling overwrites
        $moveFileWriteThrough = 0x8
        $moveFileReplaceExisting = 0x1

        $flags = $moveFileWriteThrough
        if ($Force) {
            $flags = $flags -bor $moveFileReplaceExisting
        }
    }

    process {
        try {
            # expand paths to full filesystem paths
            $fullSourcePath = Expand-Path $Path
            $fullDestPath = Expand-Path $Destination

            # verify source path exists
            if (Test-Path -LiteralPath $fullSourcePath) {

                # confirm action if -whatif specified
                if ($PSCmdlet.ShouldProcess($fullSourcePath,
                    "Move to $fullDestPath")) {

                    Write-Verbose "Moving $fullSourcePath to $fullDestPath"

                    # attempt the move operation
                    $result = $win32::MoveFileEx($fullSourcePath,
                        $fullDestPath, $flags)

                    if (-not $result) {
                        # get detailed error on failure
                        $errorCode = [System.Runtime.InteropServices.Marshal]:: `
                            GetLastWin32Error()
                        throw "Move failed from '$fullSourcePath' to " + `
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
