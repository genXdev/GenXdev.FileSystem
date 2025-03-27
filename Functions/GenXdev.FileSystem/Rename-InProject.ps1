################################################################################
<#
.SYNOPSIS
Performs case-sensitive text replacement throughout a project directory.

.DESCRIPTION
Recursively searches through files and directories in a project to perform text
replacements. Handles both file/directory names and file contents. Skips common
binary files and repository folders (.git, .svn) to avoid corruption. Uses UTF-8
encoding without BOM for file operations.

.PARAMETER Source
The directory, filepath, or directory+searchmask to process. Defaults to current
directory if not specified.

.PARAMETER FindText
The case-sensitive text pattern to search for in filenames and content.

.PARAMETER ReplacementText
The text to replace all instances of FindText with.

.PARAMETER WhatIf
Shows what changes would occur without actually making them.

.EXAMPLE
Rename-InProject -Source .\src\*.js -FindText "oldName" `
    -ReplacementText "newName"

.EXAMPLE
rip . "MyClass" "MyNewClass" -WhatIf
#>
function Rename-InProject {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias("rip")]
    param(
        ########################################################################
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $false,
            HelpMessage = "The directory, filepath, or directory+searchmask"
        )]
        [Alias("src", "s")]
        [PSDefaultValue(Value = ".\")]
        [string] $Source,
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $false,
            HelpMessage = "The text to find (case sensitive)"
        )]
        [Alias("find", "what", "from")]
        [ValidateNotNullOrEmpty()]
        [string] $FindText,
        ########################################################################
        [Parameter(
            Mandatory = $true,
            Position = 2,
            ValueFromPipeline = $false,
            HelpMessage = "The text to replace matches with"
        )]
        [Alias("into", "txt", "to")]
        [ValidateNotNull()]
        [string] $ReplacementText
        ########################################################################
    )

    begin {

        try {
            # normalize path and extract search pattern if specified
            $sourcePath = GenXdev.FileSystem\Expand-Path $Source
            $searchPattern = "*"

            # split source into path and pattern if not a directory
            if (![System.IO.Directory]::Exists($sourcePath)) {

                $searchPattern = [System.IO.Path]::GetFileName($sourcePath)
                $sourcePath = [System.IO.Path]::GetDirectoryName($sourcePath)

                if (![System.IO.Directory]::Exists($sourcePath)) {
                    throw "Source directory not found: $sourcePath"
                }
            }

            Microsoft.PowerShell.Utility\Write-Verbose "Processing source path: $sourcePath"
            Microsoft.PowerShell.Utility\Write-Verbose "Using search pattern: $searchPattern"

            # extensions to skip to avoid corrupting binary files
            $skipExtensions = @(
                ".jpg", ".jpeg", ".gif", ".bmp", ".png", ".tiff",
                ".exe", ".dll", ".pdb", ".so",
                ".wav", ".mp3", ".avi", ".mkv", ".wmv",
                ".tar", ".7z", ".zip", ".rar", ".apk", ".ipa",
                ".cer", ".crt", ".pkf", ".db", ".bin"
            )
        }
        catch {
            throw
        }
    }


process {

        try {
            # recursive function to get all project files excluding repos
            function Get-ProjectFiles {

                [CmdletBinding()]
                [OutputType([System.Collections.Generic.List[string]])]
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
                    "PSUseSingularNouns",
                    "Get-ProjectFiles"
                )]
                param(
                    [string] $Dir,
                    [string] $Mask
                )

                $result = [System.Collections.Generic.List[string]]::new()

                # skip version control directories
                if ([IO.Path]::GetFileName($Dir) -in @(".svn", ".git")) {
                    return $result
                }

                # collect matching files in current directory
                [IO.Directory]::GetFiles($Dir, $Mask) | Microsoft.PowerShell.Core\ForEach-Object {
                    $null = $result.Add($_)
                }

                # recursively process subdirectories
                [IO.Directory]::GetDirectories($Dir, "*") | Microsoft.PowerShell.Core\ForEach-Object {
                    if ([IO.Path]::GetFileName($_) -notin @(".svn", ".git")) {
                        $null = Get-ProjectFiles $_ $Mask | Microsoft.PowerShell.Core\ForEach-Object {
                            $null = $result.Add($_)
                        }
                    }
                }

                return $result
            }

            # process files in reverse order to handle renames safely
            Get-ProjectFiles -dir $sourcePath -mask $searchPattern |
            Microsoft.PowerShell.Utility\Sort-Object -Descending |
            Microsoft.PowerShell.Core\ForEach-Object {

                $filePath = $_
                $extension = [IO.Path]::GetExtension($filePath).ToLower()

                # only process text files
                if ($extension -notin $skipExtensions) {

                    try {
                        Microsoft.PowerShell.Utility\Write-Verbose "Processing file: $filePath"

                        # replace text in file contents
                        $content = [IO.File]::ReadAllText($filePath,
                            [Text.Encoding]::UTF8)
                        $newContent = $content.Replace($FindText, $ReplacementText)

                        if ($content -ne $newContent) {
                            if ($PSCmdlet.ShouldProcess($filePath,
                                    "Replace content")) {

                                $utf8 = [Text.UTF8Encoding]::new($false)
                                [IO.File]::WriteAllText($filePath, $newContent,
                                    $utf8)

                                Microsoft.PowerShell.Utility\Write-Verbose "Updated content in: $filePath"
                            }
                        }
                    }
                    catch {
                        Microsoft.PowerShell.Utility\Write-Warning "Failed to update content in: $filePath`n$_"
                    }

                    # handle filename changes
                    $oldName = [IO.Path]::GetFileName($filePath)
                    $newName = $oldName.Replace($FindText, $ReplacementText)

                    if ($oldName -ne $newName) {
                        $newPath = [IO.Path]::Combine(
                            [IO.Path]::GetDirectoryName($filePath),
                            $newName)

                        if ($PSCmdlet.ShouldProcess($filePath, "Rename file")) {
                            try {

                                if ("$filePath".ToLowerInvariant() -eq "$newPath".ToLowerInvariant()) {

                                    $newPath = "$newPath.$([DateTime]::Now.Ticks).tmp"
                                    $null = GenXdev.FileSystem\Move-ItemWithTracking -Path $filePath `
                                        -Destination "$newPath.tmp12389"
                                    Microsoft.PowerShell.Utility\Write-Verbose "Renamed file: $filePath -> $newPath"
                                    $filePath = $newPath
                                }

                                $null = GenXdev.FileSystem\Move-ItemWithTracking -Path $filePath `
                                    -Destination $newPath
                                Microsoft.PowerShell.Utility\Write-Verbose "Renamed file: $filePath -> $newPath"
                            }
                            catch {
                                Microsoft.PowerShell.Utility\Write-Warning "Failed to rename file: $filePath`n$_"
                            }
                        }
                    }
                }
            }

            # process directories in reverse order
            Microsoft.PowerShell.Management\Get-ChildItem -Path $sourcePath -Directory -Recurse |
            Microsoft.PowerShell.Utility\Sort-Object -Descending |
            Microsoft.PowerShell.Core\Where-Object {
                $_.FullName -notlike "*\.git\*" -and
                $_.FullName -notlike "*\.svn\*"
            } |
            Microsoft.PowerShell.Core\ForEach-Object {

                $dir = $_
                $oldName = $dir.Name
                $newName = $oldName.Replace($FindText, $ReplacementText)

                if ($oldName -ne $newName) {
                    $newPath = GenXdev.FileSystem\Expand-Path (
                        [IO.Path]::Combine($dir.Parent.FullName, $newName))

                    if ($PSCmdlet.ShouldProcess($dir.FullName,
                            "Rename directory")) {

                        if ([IO.Directory]::Exists($newPath)) {
                            # merge directories if target exists
                            GenXdev.FileSystem\Start-RoboCopy -Source $dir.FullName `
                                -DestinationDirectory $newPath -Move
                            $null = GenXdev.FileSystem\Remove-AllItems ($dir.FullName) -DeleteFolder
                            Microsoft.PowerShell.Utility\Write-Verbose "Merged directory: $($dir.FullName) -> $newPath"
                        }
                        else {
                            try {
                                $null = GenXdev.FileSystem\Move-ItemWithTracking -Path $dir.FullName `
                                    -Destination $newPath
                                Microsoft.PowerShell.Utility\Write-Verbose "Renamed directory: $($dir.FullName) -> $newPath"
                            }
                            catch {
                                Microsoft.PowerShell.Utility\Write-Warning "Failed to rename directory: $($dir.FullName)`n$_"
                            }
                        }
                    }
                }
            }
        }
        catch {
            throw
        }
    }

    end {
    }
}
################################################################################