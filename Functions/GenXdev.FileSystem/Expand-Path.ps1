################################################################################
<#
.SYNOPSIS
Expands any given file reference to a full pathname.

.DESCRIPTION
Expands any given file reference to a full pathname, with respect to the user's
current directory. Can optionally assure that directories or files exist.

.PARAMETER FilePath
The file path to expand to a full path.

.PARAMETER CreateDirectory
Will create directory if it does not exist.

.PARAMETER CreateFile
Will create an empty file if it does not exist.

.EXAMPLE
Expand-Path -FilePath ".\myfile.txt" -CreateFile

.EXAMPLE
ep ~\documents\test.txt -CreateFile
#>
function Expand-Path {

    [CmdletBinding()]
    [Alias("ep")]

    param(
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to expand"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will create directory if it does not exist"
        )]
        [switch] $CreateDirectory,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will create an empty file if it does not exist"
        )]
        [switch] $CreateFile,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will delete the file if it already exists"
        )]
        [switch] $DeleteExistingFile
        ########################################################################
    )

    begin {

        # normalize path separators and remove double separators
        $normalizedPath = $FilePath.Trim().Replace("\", [IO.Path]::DirectorySeparatorChar).
        Replace("/", [IO.Path]::DirectorySeparatorChar)

        # check if path ends with a directory separator
        $hasTrailingSeparator = $normalizedPath.EndsWith(
            [System.IO.Path]::DirectorySeparatorChar) -or
        $normalizedPath.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)
    }

    process {

        # expand home directory if path starts with ~
        if ($normalizedPath.StartsWith("~")) {
            $normalizedPath = Join-Path (Resolve-Path ~).Path `
                $normalizedPath.Substring(1)
        }

        # handle absolute paths (drive letter or UNC)
        if ((($normalizedPath.Length -gt 1) -and
                ($normalizedPath.Substring(1, 1) -eq ":")) -or
            $normalizedPath.StartsWith("\\")) {

            try {
                $normalizedPath = [System.IO.Path]::GetFullPath($normalizedPath)
            }
            catch {
                Write-Verbose "Failed to normalize path, keeping original"
            }
        }
        else {
            # handle relative paths
            try {
                $normalizedPath = [System.IO.Path]::GetFullPath(
                    [System.IO.Path]::Combine($pwd, $normalizedPath))
            }
            catch {
                $normalizedPath = Convert-Path $normalizedPath
            }
        }

        # handle directory/file creation if requested
        if ($CreateDirectory -or $CreateFile) {

            # get directory path accounting for trailing separator
            $directoryPath = if ($hasTrailingSeparator) {
                [IO.Path]::TrimEndingDirectorySeparator($normalizedPath)
            }
            else {
                [IO.Path]::TrimEndingDirectorySeparator(
                    [System.IO.Path]::GetDirectoryName($normalizedPath))
            }

            # create directory if it doesn't exist
            if (-not [IO.Directory]::Exists($directoryPath)) {
                $null = [IO.Directory]::CreateDirectory($directoryPath)
                Write-Verbose "Created directory: $directoryPath"
            }
        }

        # delete existing file if requested
        if ($DeleteExistingFile -and [IO.File]::Exists($normalizedPath)) {

            # verify path doesn't point to existing directory
            if ([IO.Directory]::Exists($normalizedPath)) {
                throw "Cannot create file: Path refers to an existing directory"
            }

            if (-not (Remove-ItemWithFallback -Path $normalizedPath)) {

                throw "Failed to delete existing file: $normalizedPath"
            }

            Write-Verbose "Deleted existing file: $normalizedPath"
        }

        # handle file creation if requested
        if ($CreateFile) {

            # verify path doesn't point to existing directory
            if ([IO.Directory]::Exists($normalizedPath)) {
                throw "Cannot create file: Path refers to an existing directory"
            }


            # create empty file if it doesn't exist
            if (-not [IO.File]::Exists($normalizedPath)) {
                $null = [IO.File]::WriteAllText($normalizedPath, "")
                Write-Verbose "Created empty file: $normalizedPath"
            }
        }

        # clean up trailing separators except for root paths
        while ([IO.Path]::EndsInDirectorySeparator($normalizedPath) -and
            $normalizedPath.Length -gt 4) {
            $normalizedPath = [IO.Path]::TrimEndingDirectorySeparator($normalizedPath)
        }

        return $normalizedPath
    }

    end {
    }
}
################################################################################
