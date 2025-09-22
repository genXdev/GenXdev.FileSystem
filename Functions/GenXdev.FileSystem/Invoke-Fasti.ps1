<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : Invoke-Fasti.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.280.2025
################################################################################
MIT License

Copyright 2021-2025 GenXdev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
################################################################################>
###############################################################################
<#
.SYNOPSIS
Extracts archive files in the current directory to their own folders and deletes 
them afterwards.

.DESCRIPTION
Automatically extracts common archive formats (zip, 7z, tar, etc.) found in the
current directory into individual folders named after each archive. After
successful extraction, the original archive files are deleted. Requires 7-Zip
to be installed on the system.

.EXAMPLE
PS C:\Downloads> Invoke-Fasti

.EXAMPLE
PS C:\Downloads> fasti

.NOTES
Supported formats: 7z, zip, rar, tar, iso and many others.
Requires 7-Zip installation (will attempt auto-install via winget if missing).
#>
function Invoke-Fasti {

    [CmdletBinding()]
    [Alias("fasti")]
    param(
        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Enter the password for the encrypted archive(s)"
        )]
        [string] $Password,

        ###############################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Recursively extract archives found within extracted folders"
        )]
        [switch] $ExtractOutputToo
    )

    begin {

        # list of supported archive extensions
        $extensions = @("*.7z", "*.7z.001", "*.xz", "*.bzip2", "*.gzip", "*.tar", "*.zip", "*.zip.001",
            "*.wim", "*.ar", "*.arj", "*.cab", "*.chm", "*.cpio", "*.cramfs",
            "*.dmg", "*.ext", "*.fat", "*.gpt", "*.hfs", "*.ihex", "*.iso",
            "*.lzh", "*.lzma", "*.mbr", "*.msi", "*.nsis", "*.ntfs", "*.qcow2",
            "*.rar", "*.rpm", "*.squashfs", "*.udf", "*.uefi", "*.vdi", "*.vhd",
            "*.vmdk", "*.wim", "*.xar", "*.z")
    }


    process {

        # process each archive file found in current directory
        Microsoft.PowerShell.Management\Get-ChildItem -Path $extensions -File -ErrorAction SilentlyContinue |
            Microsoft.PowerShell.Core\ForEach-Object {

                Microsoft.PowerShell.Utility\Write-Verbose "Processing archive: $($PSItem.Name)"

                # initialize 7zip executable path
                $sevenZip = "7z"

                # get archive details
                $zipFile = $PSItem.fullname
                $name = [system.IO.Path]::GetFileNameWithoutExtension($zipFile)
                $path = [System.IO.Path]::GetDirectoryName($zipFile)
                $extractPath = [system.Io.Path]::Combine($path, $name)

                # create extraction directory if it doesn"t exist
                if ([System.IO.Directory]::exists($extractPath) -eq $false) {

                    Microsoft.PowerShell.Utility\Write-Verbose "Creating directory: $extractPath"
                    [System.IO.Directory]::CreateDirectory($extractPath)
                }

                # verify 7zip installation or attempt to install it
                if ((Microsoft.PowerShell.Core\Get-Command $sevenZip -ErrorAction SilentlyContinue).Length -eq 0) {

                    $sevenZip = "${env:ProgramFiles}\7-Zip\7z.exe"

                    if (![IO.File]::Exists($sevenZip)) {

                        if ((Microsoft.PowerShell.Core\Get-Command winget -ErrorAction SilentlyContinue).Length -eq 0) {

                            throw "You need to install 7zip or winget first"
                        }

                        Microsoft.PowerShell.Utility\Write-Verbose "Installing 7-Zip via winget..."
                        winget install 7zip

                        if (![IO.File]::Exists($sevenZip)) {

                            throw "You need to install 7-zip"
                        }
                    }
                }

                # extract archive contents
                Microsoft.PowerShell.Utility\Write-Verbose "Extracting to: $extractPath"
                $pwparam = if ($Password) { "-p$Password" } else { "" }
                if ([string]::IsNullOrWhiteSpace($Password)) {

                    & $sevenZip x -y "-o$extractPath" $zipFile
                }
                else {

                    & $sevenZip x -y $pwparam "-o$extractPath" $zipFile
                }

                # delete original archive if extraction succeeded
                if ($?) {

                    try {
                        Microsoft.PowerShell.Utility\Write-Verbose "Removing original archive: $zipFile"
                        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "$zipFile" -Force -ErrorAction silentlycontinue
                    }
                    catch {
                        Microsoft.PowerShell.Utility\Write-Verbose "Failed to remove original archive"
                    }

                    # if ExtractOutputToo is enabled, recursively extract archives in the output folder
                    if ($ExtractOutputToo) {
                        Microsoft.PowerShell.Utility\Write-Verbose "Checking for nested archives in: $extractPath"

                        do {
                            # find all archives recursively in the extraction path
                            $nestedArchives = Microsoft.PowerShell.Management\Get-ChildItem -Recurse -File "${extractPath}\*" -ErrorAction SilentlyContinue |
                                Microsoft.PowerShell.Core\Where-Object {
                                    $extensions -contains "*$($_.Extension)"
                                }

                            if ($nestedArchives.Count -eq 0) {
                                Microsoft.PowerShell.Utility\Write-Verbose "No more nested archives found"
                                break
                            }

                            Microsoft.PowerShell.Utility\Write-Verbose "Found $($nestedArchives.Count) nested archive(s)"

                            $nestedDirectories = $nestedArchives | Microsoft.PowerShell.Core\ForEach-Object {
                                [System.IO.Path]::GetDirectoryName($_.FullName)
                            } | Microsoft.PowerShell.Utility\Select-Object -Unique

                            $errorOccured = $false

                            # process each nested archive in its own directory
                            foreach ($nestedDirectory in $nestedDirectories) {

                                Microsoft.PowerShell.Utility\Write-Verbose "Processing nested archive in: $nestedDirectory"

                                try {
                                    Microsoft.PowerShell.Management\Push-Location -LiteralPath $nestedDirectory
                                    if ($Password) {
                                        GenXdev.FileSystem\Invoke-Fasti -Password $Password -ExtractOutputToo
                                    } else {
                                        GenXdev.FileSystem\Invoke-Fasti -ExtractOutputToo
                                    }
                                }
                                catch {
                                    $errorOccured = $true
                                    Microsoft.PowerShell.Utility\Write-Verbose "Error occurred while processing nested archive in: $nestedDirectory"
                                }
                                finally {
                                    Microsoft.PowerShell.Management\Pop-Location
                                }
                            }
                        } while (-not $errorOccured)
                    }
                }
            }
    }

    end {
    }
}