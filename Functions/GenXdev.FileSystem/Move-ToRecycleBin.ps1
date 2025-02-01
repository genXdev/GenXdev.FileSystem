################################################################################
<#
.SYNOPSIS
Moves a file to the recycle bin using the Windows Shell API.

.DESCRIPTION
Safely moves a file or directory to the recycle bin, even if it's currently in
use. Uses the Shell.Application COM object to perform the operation.

.PARAMETER Path
The path to the file or directory to move to the recycle bin.

.EXAMPLE
Move-ToRecycleBin -Path "C:\temp\myfile.txt"

.EXAMPLE
# Move multiple files
"file1.txt","file2.txt" | Move-ToRecycleBin
#>
function Move-ToRecycleBin {

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    [Alias("recycle")]
    param(
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Specify the path(s) to move to the recycle bin"
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path
        ########################################################################
    )

    begin {

        # initialize success tracking
        $success = $true

        # create shell automation object for recycle bin operations
        $shellObj = $null
        try {
            $shellObj = New-Object -ComObject Shell.Application
            Write-Verbose "Successfully created Shell.Application COM object"
        }
        catch {
            Write-Error "Failed to create Shell.Application COM object: $_"
            return $false
        }
    }

    process {

        foreach ($itemPath in $Path) {

            # convert to full filesystem path
            $fullPath = Expand-Path $itemPath
            Write-Verbose "Processing path: $fullPath"

            try {
                # verify path exists
                if ([System.IO.File]::Exists($fullPath) -or `
                    [System.IO.Directory]::Exists($fullPath)) {

                    # confirm operation with user
                    if ($PSCmdlet.ShouldProcess($fullPath, "Move to Recycle Bin")) {

                        # split path for shell operation
                        $dirName = [System.IO.Path]::GetDirectoryName($fullPath)
                        $fileName = [System.IO.Path]::GetFileName($fullPath)

                        # get shell namespace for operation
                        $folderObj = $shellObj.Namespace($dirName)
                        $fileObj = $folderObj.ParseName($fileName)

                        # move to recycle bin
                        $fileObj.InvokeVerb("delete")
                        Write-Verbose "Successfully recycled: $fullPath"
                    }
                }
                else {
                    Write-Warning "Path not found: $fullPath"
                    $success = $false
                }
            }
            catch {
                Write-Error "Failed to recycle $fullPath : $_"
                $success = $false
            }
        }
    }

    end {

        # cleanup com object
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shellObj) | `
                Out-Null
            Write-Verbose "Successfully released COM object"
        }
        catch {
            Write-Warning "Failed to release COM object: $_"
        }

        return $success
    }
}
################################################################################
