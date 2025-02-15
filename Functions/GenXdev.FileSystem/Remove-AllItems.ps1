################################################################################
<#
.SYNOPSIS
Recursively removes all content from a directory with advanced error handling.

.DESCRIPTION
Safely removes all files and subdirectories within a specified directory using
a reverse-order deletion strategy to handle deep paths. Includes WhatIf support,
verbose logging, and fallback deletion methods for locked files.

.PARAMETER Path
The directory path to clear. Can be relative or absolute path. Will be normalized
and expanded before processing.

.PARAMETER DeleteFolder
When specified, also removes the root directory specified by Path after clearing
its contents.

.PARAMETER WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.

.EXAMPLE
Remove-AllItems -Path "C:\Temp\BuildOutput" -DeleteFolder -Verbose

.EXAMPLE
sdel ".\temp" -DeleteFolder
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

        # preserve original preference settings for restoration in end block
        $originalVerbosePreference = $VerbosePreference
        $originalWhatIfPreference = $WhatIfPreference

        try {
            # convert relative or shorthand paths to full filesystem paths
            $Path = Expand-Path $Path
            Write-Verbose "Normalized path: $Path"

            # ensure verbose output is enabled during WhatIf operations
            if ($WhatIfPreference -or $WhatIf) {
                $VerbosePreference = "Continue"
            }
        }
        catch {
            # restore original whatif setting before propagating error
            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    process {
        try {
            # skip processing if target directory doesn't exist
            if (![System.IO.Directory]::Exists($Path)) {
                Write-Verbose "Directory does not exist: $Path"
                return
            }

            Write-Verbose "Processing directory: $Path"

            # delete files first, in reverse order to handle nested paths
            [System.IO.Directory]::GetFiles($Path, "*.*", `
                    [System.IO.SearchOption]::AllDirectories) |
            Sort-Object -Descending |
            ForEach-Object {
                $filePath = $_
                if ($PSCmdlet.ShouldProcess($filePath, "Remove file")) {
                    $null = Remove-ItemWithFallback -Path $filePath
                }
            }

            # delete directories after files, also in reverse order
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

            # optionally remove the root directory itself
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
            # restore original whatif setting before propagating error
            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    end {
        # restore original preference settings
        $WhatIfPreference = $originalWhatIfPreference
    }
}
################################################################################
