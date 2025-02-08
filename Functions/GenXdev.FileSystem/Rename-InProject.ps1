################################################################################
<#
.SYNOPSIS
Performs case-sensitive text replacement throughout a project directory.

.DESCRIPTION
Performs find and replace operations across files and folders in a project.
Skips common binary files and repository folders (.git, .svn).
Always use -WhatIf first to validate planned changes.

.PARAMETER Source
The directory, filepath, or directory+searchmask to process.

.PARAMETER FindText
The case-sensitive text to find and replace.

.PARAMETER ReplacementText
The text to replace FindText with.

.PARAMETER WhatIf
Shows what would happen if the cmdlet runs.

.EXAMPLE
Rename-InProject -Source .\src\*.js -FindText "tsconfig.json" `
    -ReplacementText "typescript.configuration.json"

.EXAMPLE
rip .\src\ "MyClass" "MyNewClass" -WhatIf
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
            # normalize and validate source path
            $sourcePath = Expand-Path $Source
            $searchPattern = "*"

            # split path if not a directory
            if (![System.IO.Directory]::Exists($sourcePath)) {
                $searchPattern = [System.IO.Path]::GetFileName($sourcePath)
                $sourcePath = [System.IO.Path]::GetDirectoryName($sourcePath)

                if (![System.IO.Directory]::Exists($sourcePath)) {
                    throw "Source directory not found: $sourcePath"
                }
            }

            Write-Verbose "Source path: $sourcePath"
            Write-Verbose "Search pattern: $searchPattern"

            # list of extensions to skip
            $skipExtensions = @(
                ".jpg", ".jpeg", ".gif", ".bmp", ".png", ".tiff",
                ".exe", ".dll", ".pdb", ".so",
                ".wav", ".mp3", ".avi", ".mkv", ".wmv",
                ".tar", ".7z", ".zip", ".rar", ".apk", ".ipa",
                ".cer", ".crt", ".pkf", ".db"
            )
        }
        catch {

            throw
        }
    }

    process {
        try {

            # get all files recursively excluding repos
            function Get-ProjectFiles([string] $dir, [string] $mask) {

                $result = [System.Collections.Generic.List[string]]::new()

                # skip repo directories
                if ([IO.Path]::GetFileName($dir) -in @(".svn", ".git")) {
                    return $result
                }

                # add matching files
                [IO.Directory]::GetFiles($dir, $mask) | ForEach-Object {
                    $null = $result.Add($_)
                }

                # process subdirectories
                [IO.Directory]::GetDirectories($dir, "*") | ForEach-Object {

                    if ([IO.Path]::GetFileName($_) -notin @(".svn", ".git")) {
                        Get-ProjectFiles $_ $mask | ForEach-Object {
                            $result.Add($_)
                        } | Out-Null
                    }
                }

                return $result
            }

            # process files
            Get-ProjectFiles -dir $sourcePath -mask $searchPattern |
            Sort-Object -Descending |
            ForEach-Object {
                $filePath = $_
                $extension = [IO.Path]::GetExtension($filePath).ToLower()

                # skip binary files
                if ($extension -notin $skipExtensions) {

                    try {

                        Write-Verbose "Processing file: $filePath"

                        # read and replace content
                        $content = [IO.File]::ReadAllText($filePath, [Text.Encoding]::UTF8)
                        $newContent = $content.Replace($FindText, $ReplacementText)

                        if ($content -ne $newContent) {
                            if ($PSCmdlet.ShouldProcess($filePath, "Replace content")) {
                                $utf8 = [Text.UTF8Encoding]::new($false)
                                [IO.File]::WriteAllText($filePath, $newContent, $utf8)
                                Write-Verbose "Updated content in: $filePath"
                            }
                        }
                    }
                    catch {
                        Write-Warning "Failed to update content in: $filePath`n$_"
                    }

                    # process filename
                    $oldName = [IO.Path]::GetFileName($filePath)
                    $newName = $oldName.Replace($FindText, $ReplacementText)

                    if ($oldName -ne $newName) {
                        $newPath = [IO.Path]::Combine([IO.Path]::GetDirectoryName($filePath),
                            $newName)

                        if ($PSCmdlet.ShouldProcess($filePath, "Rename file")) {
                            try {
                                Move-ItemWithTracking -Path $filePath -Destination $newPath
                                Write-Verbose "Renamed file: $filePath -> $newPath"
                            }
                            catch {
                                Write-Warning "Failed to rename file: $filePath`n$_"
                            }
                        }
                    }
                }
            }

            # process directories
            Get-ChildItem -Path $sourcePath -Directory -Recurse |
            Sort-Object -Descending |
            Where-Object {
                $_.FullName -notlike "*\.git\*" -and
                $_.FullName -notlike "*\.svn\*"
            } |
            ForEach-Object {
                $dir = $_
                $oldName = $dir.Name
                $newName = $oldName.Replace($FindText, $ReplacementText)

                if ($oldName -ne $newName) {

                    $newPath = Expand-Path ([IO.Path]::Combine($dir.Parent.FullName, $newName))

                    if ($PSCmdlet.ShouldProcess($dir.FullName, "Rename directory")) {

                        if ([IO.Directory]::Exists($newPath)) {
                            # merge directories if target exists
                            Start-RoboCopy -Source $dir.FullName `
                                -DestinationDirectory $newPath -Move
                            Remove-AllItems ($dir.FullName) -DeleteFolder
                            Write-Verbose "Merged directory: $($dir.FullName) -> $newPath"
                        }
                        else {
                            try {
                                Move-ItemWithTracking -Path $dir.FullName -Destination $newPath
                                Write-Verbose "Renamed directory: $($dir.FullName) -> $newPath"
                            }
                            catch {
                                Write-Warning "Failed to rename directory: $($dir.FullName)`n$_"
                            }
                        }
                    }
                }
            }
        }
        catch {

            $WhatIfPreference = $originalWhatIfPreference
            throw
        }
    }

    end {
        # restore preferences

        $WhatIfPreference = $originalWhatIfPreference
    }
}
################################################################################
