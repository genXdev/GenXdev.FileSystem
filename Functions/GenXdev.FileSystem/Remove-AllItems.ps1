################################################################################
<#
.SYNOPSIS
Removes all files and folders in the specified directory.

.DESCRIPTION
Removes all files and folders in the specified directory.

.PARAMETER Path
The path of the directory to clear.

.PARAMETER DeleteFolder
Also delete the root folder supplied with the Path parameter.

.PARAMETER WhatIf
Displays a message that describes the effect of the command, instead of executing
the command.

.EXAMPLE
Remove-AllItems -Path ".\vms"
#>
function Remove-AllItems {

    [CmdletBinding(SupportsShouldProcess)]
    [Alias("sdel")]

    param(
        ###############################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "The directory path to clear"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Also delete the root folder supplied with the Path parameter"
        )]
        [switch] $DeleteFolder
        ###############################################################################
    )

    begin {

        # store original preference values for later restoration
        $originalVerbosePreference = $VerbosePreference
        $originalWhatIfPreference = $WhatIfPreference

        try {
            # normalize and expand the provided path
            $Path = Expand-Path $Path
            Write-Verbose "Normalized path: $Path"

            # enable verbose output when in whatif mode
            if ($WhatIfPreference -or $WhatIf) {
                $VerbosePreference = "Continue"
            }
        }
        catch {
            # restore preferences and rethrow the error

            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    process {
        try {
            # verify the directory exists before proceeding
            if (![System.IO.Directory]::Exists($Path)) {
                Write-Verbose "Directory does not exist: $Path"
                return
            }

            Write-Verbose "Processing directory: $Path"

            # get and remove all files in reverse order for safe deletion
            [System.IO.Directory]::GetFiles($Path, "*.*", `
                    [System.IO.SearchOption]::AllDirectories) |
            Sort-Object -Descending |
            ForEach-Object {
                $filePath = $_
                if ($PSCmdlet.ShouldProcess($filePath, "Remove file")) {
                    $null = Remove-ItemWithFallback -Path $filePath
                }
            }

            # get and remove all subdirectories in reverse order
            [System.IO.Directory]::GetDirectories($Path, "*", `
                    [System.IO.SearchOption]::AllDirectories) |
            Sort-Object -Descending |
            ForEach-Object {
                $dirPath = $_
                if ($PSCmdlet.ShouldProcess($dirPath, "Remove directory")) {
                    try {
                        [System.IO.Directory]::Delete($dirPath, $true)
                        Write-Verbose "Removed directory: $dirPath"
                    }
                    catch {
                        Write-Warning "Failed to delete directory: $dirPath"
                    }
                }
            }

            # delete root folder if requested
            if ($DeleteFolder) {
                if ($PSCmdlet.ShouldProcess($Path, "Remove root directory")) {
                    try {
                        [System.IO.Directory]::Delete($Path, $true)
                        Write-Verbose "Removed root directory: $Path"
                    }
                    catch {

                        $null = Remove-ItemWithFallback -Path $Path
                    }
                }
            }
        }
        catch {
            # restore preferences if process block fails

            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    end {
        # restore original preference values

        $WhatIfPreference = $originalWhatIfPreference
    }
}
################################################################################
