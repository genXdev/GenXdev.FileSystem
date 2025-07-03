###############################################################################
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
        ###############################################################################>
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
        [switch] $DeleteExistingFile,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will force the use of a specific drive"
        )]
        [char] $ForceDrive = '*',
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will throw if file does not exist"
        )]
        [switch] $FileMustExist,
        ########################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Will throw if directory does not exist"
        )]
        [switch] $DirectoryMustExist
        ########################################################################
    )

    begin {

        # normalize path separators and remove double separators
        [string] $normalizedPath = $FilePath.Trim().Replace("\", [IO.Path]::DirectorySeparatorChar).
        Replace("/", [IO.Path]::DirectorySeparatorChar);

        if ($normalizedPath.StartsWith([IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar)) {

            $normalizedPath = [IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar +
            $normalizedPath.Substring(2).Replace(
                [IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::DirectorySeparatorChar
            )

            if (($ForceDrive -ne '*') -and
                ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".IndexOf(($ForceDrive -as [string]).ToUpperInvariant()) -ge 0)) {

                $i = $normalizedPath.IndexOf([IO.Path]::DirectorySeparatorChar, 2);
                $normalizedPath = $ForceDrive + ":" + (

                    $i -lt 0 ? ([IO.Path]::DirectorySeparatorChar) : $normalizedPath.Substring($i)
                )
            }
        }
        else {

            $normalizedPath = $normalizedPath.Replace(
                [IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::DirectorySeparatorChar
            )
        }

        # check if path ends with a directory separator
        $hasTrailingSeparator = $normalizedPath.EndsWith(
            [System.IO.Path]::DirectorySeparatorChar) -or
        $normalizedPath.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)
    }


process {

        # expand home directory if path starts with ~
        if ($normalizedPath.StartsWith("~")) {

            if (($ForceDrive -ne '*') -and
                ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".IndexOf(($ForceDrive -as [string]).ToUpperInvariant()) -ge 0)) {

                $i = $normalizedPath.IndexOf([IO.Path]::DirectorySeparatorChar, 1);
                $normalizedPath = $ForceDrive + ":" + (

                    $i -lt 0 ? [IO.Path]::DirectorySeparatorChar + "**" + [IO.Path]::DirectorySeparatorChar : ("\**" + $normalizedPath.Substring($i))
                )
            }
            else {

                $normalizedPath = Microsoft.PowerShell.Management\Join-Path (Microsoft.PowerShell.Management\Convert-Path ~) `
                    $normalizedPath.Substring(1)
            }
        }

        if ((($normalizedPath.Length -gt 1) -and
                ($normalizedPath.Substring(1, 1) -eq ":"))) {

            if (($ForceDrive -ne '*') -and
                ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".IndexOf(($ForceDrive -as [string]).ToUpperInvariant()) -ge 0)) {
                $i = $normalizedPath.IndexOf([IO.Path]::DirectorySeparatorChar);
                $normalizedPath = $ForceDrive + ":" + [IO.Path]::DirectorySeparatorChar + (($i -eq -1 -and $normalizedPath.Length -gt 2) -or $i -eq 2 ? "**" + [IO.Path]::DirectorySeparatorChar : "") + $normalizedPath.Substring(2)
            }
            else {

                if (($normalizedPath.Length -lt 3) -or ($normalizedPath.Substring(2, 1) -ne [System.IO.Path]::DirectorySeparatorChar)) {

                    Microsoft.PowerShell.Management\Push-Location $normalizedPath.Substring(0, 2)
                    try {
                        $normalizedPath = "$(Microsoft.PowerShell.Management\Get-Location)$([IO.Path]::DirectorySeparatorChar)$($normalizedPath.Substring(2))"
                        $normalizedPath = [System.IO.Path]::GetFullPath($normalizedPath)
                    }
                    finally {
                        Microsoft.PowerShell.Management\Pop-Location
                    }
                }
            }
        }

        # handle absolute paths (drive letter or UNC)
        if ($normalizedPath.StartsWith([IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar)) {

            try {
                $normalizedPath = [System.IO.Path]::GetFullPath($normalizedPath)
            }
            catch {
                Microsoft.PowerShell.Utility\Write-Verbose "Failed to normalize path, keeping original"
            }
        }
        else {

            if (($ForceDrive -ne '*') -and
                ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".IndexOf(($ForceDrive -as [string]).ToUpperInvariant()) -ge 0)) {

                if ($normalizedPath.Length -lt 2 -or $normalizedPath.Substring(1, 1) -ne ":") {

                    $newPath = $ForceDrive + ":" + [IO.Path]::DirectorySeparatorChar;

                    while ($normalizedPath.StartsWith(".")) {

                        $i = $normalizedPath.IndexOf([IO.Path]::DirectorySeparatorChar);
                        if ($i -lt 0) {

                            $normalizedPath = ""
                        }
                        else {

                            $normalizedPath = $normalizedPath.Substring($i + 1)
                        }
                    }

                    if ($normalizedPath.StartsWith([IO.Path]::DirectorySeparatorChar)) {

                        $newPath += $normalizedPath
                    }
                    else {

                        $newPath += "**" + [IO.Path]::DirectorySeparatorChar + $normalizedPath
                    }

                    $normalizedPath = $newPath
                }
            }

            # handle relative paths
            try {
                $normalizedPath = [System.IO.Path]::GetFullPath(
                    [System.IO.Path]::Combine($pwd, $normalizedPath))
            }
            catch {
                $normalizedPath = Microsoft.PowerShell.Management\Convert-Path $normalizedPath
            }
        }

        # handle directory/file creation if requested
        if ($DirectoryMustExist -or $FileMustExist) {

            # get directory path accounting for trailing separator
            $directoryPath = if ($hasTrailingSeparator) {
                [IO.Path]::TrimEndingDirectorySeparator($normalizedPath)
            }
            else {
                [IO.Path]::TrimEndingDirectorySeparator(
                    [System.IO.Path]::GetDirectoryName($normalizedPath))
            }

            # create directory if it doesn't exist
            if ($DirectoryMustExist -and (-not [IO.Directory]::Exists($directoryPath))) {

                throw "Directory does not exist: $directoryPath"
            }

            if ($FileMustExist -and (-not [IO.File]::Exists($normalizedPath))) {

                throw "File does not exist: $normalizedPath"
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
                Microsoft.PowerShell.Utility\Write-Verbose "Created directory: $directoryPath"
            }
        }

        # delete existing file if requested
        if ($DeleteExistingFile -and [IO.File]::Exists($normalizedPath)) {

            # verify path doesn't point to existing directory
            if ([IO.Directory]::Exists($normalizedPath)) {
                throw "Cannot create file: Path refers to an existing directory"
            }

            if (-not (GenXdev.FileSystem\Remove-ItemWithFallback -Path $normalizedPath)) {

                throw "Failed to delete existing file: $normalizedPath"
            }

            Microsoft.PowerShell.Utility\Write-Verbose "Deleted existing file: $normalizedPath"
        }


        # clean up trailing separators except for root paths
        while ([IO.Path]::EndsInDirectorySeparator($normalizedPath) -and
            $normalizedPath.Length -gt 4) {
            $normalizedPath = [IO.Path]::TrimEndingDirectorySeparator($normalizedPath)
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
                Microsoft.PowerShell.Utility\Write-Verbose "Created empty file: $normalizedPath"
            }
        }

        return $normalizedPath
    }

    end {
    }
}
        ###############################################################################