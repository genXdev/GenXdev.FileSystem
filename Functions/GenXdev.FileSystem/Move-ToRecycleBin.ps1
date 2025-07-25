﻿###############################################################################
<#
.SYNOPSIS
Moves files and directories to the Windows Recycle Bin safely.

.DESCRIPTION
Safely moves files or directories to the recycle bin using the Windows Shell API,
even if they are currently in use. The function uses the Shell.Application COM
object to perform the operation, ensuring proper recycling behavior and undo
capability.

.PARAMETER Path
One or more paths to files or directories that should be moved to the recycle
bin. Accepts pipeline input and wildcards. The paths must exist and be
accessible.

.EXAMPLE
Move-ToRecycleBin -Path "C:\temp\old-report.txt"
Moves a single file to the recycle bin

.EXAMPLE
"file1.txt","file2.txt" | recycle
Moves multiple files using pipeline and alias
#>
function Move-ToRecycleBin {

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    [Alias('recycle')]
    param(
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Specify the path(s) to move to the recycle bin'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string[]]$Path
        ########################################################################
    )

    begin {
        # track overall success of operations
        $success = $true

        # initialize shell automation object for recycle bin operations
        $shellObj = $null
        try {
            $shellObj = Microsoft.PowerShell.Utility\New-Object -ComObject Shell.Application
            Microsoft.PowerShell.Utility\Write-Verbose 'Created Shell.Application COM object for recycle operations'
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Error "Failed to create Shell.Application COM object: $_"
            return $false
        }
    }


    process {

        foreach ($itemPath in $Path) {

            # convert relative or shorthand paths to full filesystem paths
            $fullPath = GenXdev.FileSystem\Expand-Path $itemPath
            Microsoft.PowerShell.Utility\Write-Verbose "Processing path: $fullPath"

            try {
                # check if the target path actually exists before attempting to recycle
                if ([System.IO.File]::Exists($fullPath) -or `
                        [System.IO.Directory]::Exists($fullPath)) {

                    # confirm the recycle operation with the user
                    if ($PSCmdlet.ShouldProcess($fullPath, 'Move to Recycle Bin')) {

                        # split the path into directory and filename for shell operation
                        $dirName = [System.IO.Path]::GetDirectoryName($fullPath)
                        $fileName = [System.IO.Path]::GetFileName($fullPath)

                        # get shell folder object for the directory containing the item
                        $folderObj = $shellObj.Namespace($dirName)
                        $fileObj = $folderObj.ParseName($fileName)

                        # perform the recycle operation using shell verbs
                        $fileObj.InvokeVerb('delete')
                        Microsoft.PowerShell.Utility\Write-Verbose "Successfully moved to recycle bin: $fullPath"
                    }
                }
                else {
                    Microsoft.PowerShell.Utility\Write-Warning "Path not found: $fullPath"
                    $success = $false
                }
            }
            catch {
                Microsoft.PowerShell.Utility\Write-Error "Failed to recycle $fullPath : $_"
                $success = $false
            }
        }
    }

    end {

        # cleanup the COM object to prevent resource leaks
        try {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shellObj) | `
                    Microsoft.PowerShell.Core\Out-Null
            Microsoft.PowerShell.Utility\Write-Verbose 'Released Shell.Application COM object'
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Warning "Failed to release COM object: $_"
        }

        return $success
    }
}