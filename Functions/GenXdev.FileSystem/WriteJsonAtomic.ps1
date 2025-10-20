<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : WriteJsonAtomic.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.302.2025
################################################################################
Copyright (c)  René Vaessen / GenXdev

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
################################################################################>
###############################################################################
<#
.SYNOPSIS
    Writes data to a JSON file atomically to prevent corruption.

.DESCRIPTION
    This function writes a hashtable to a JSON file using atomic operations
    to ensure data integrity even if the process is interrupted. It uses
    temporary files and locking to prevent corruption.

.PARAMETER FilePath
    The path to the JSON file to write.

.PARAMETER Data
    The hashtable data to serialize to JSON.

.PARAMETER MaxRetries
    The maximum number of retry attempts for the atomic write operation.

.PARAMETER RetryDelayMs
    The delay in milliseconds between retry attempts.

.EXAMPLE
    WriteJsonAtomic -FilePath "config.json" -Data @{setting="value"}
#>
function WriteJsonAtomic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Data,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 10,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelayMs = 200
    )

    # ensure directory exists
    $directory = [System.IO.Path]::GetDirectoryName($FilePath)
    if (-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $directory)) {
        $null = GenXdev.FileSystem\Expand-Path $directory -CreateDirectory
    }

    # construct file paths for atomic operation
    $lockFile = "${FilePath}.lock"
    $tmpFile = "${FilePath}.tmp"
    $tmp2File = "${FilePath}.tmp2"

    # attempt atomic write with retries
    for ($attempt = 0; $attempt -lt $MaxRetries; $attempt++) {
        try {
            # clean up stale lock files older than 30 seconds
            if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $lockFile) {
                $lockInfo = [System.IO.FileInfo]::new($lockFile)
                $ageMilliSeconds = ([DateTime]::Now - $lockInfo.LastWriteTime).TotalMilliseconds

                if ($ageMilliSeconds -gt ($MaxRetries * 10)) {
                    Microsoft.PowerShell.Utility\Write-Verbose `
                        "Removing stale lock file: $lockFile (age: ${ageMilliSeconds}ms)"
                    Microsoft.PowerShell.Management\Remove-Item `
                        -LiteralPath $lockFile `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
                else {
                    # lock is recent, wait and retry
                    throw "File is locked by another process"
                }
            }

            # create lock file
            $null = Microsoft.PowerShell.Management\New-Item `
                -Path $lockFile `
                -ItemType File `
                -Force `
                -ErrorAction Stop

            try {
                # write json content to temporary file
                $jsonContent = $Data | Microsoft.PowerShell.Utility\ConvertTo-Json `
                    -Depth 10 `
                    -Compress:$false

                [System.IO.File]::WriteAllText($tmpFile, $jsonContent, `
                        [System.Text.Encoding]::UTF8)

                # perform atomic rename operation
                if (Microsoft.PowerShell.Management\Test-Path `
                        -LiteralPath $FilePath) {
                    # rename existing file to .tmp2
                    Microsoft.PowerShell.Management\Move-Item `
                        -LiteralPath $FilePath `
                        -Destination $tmp2File `
                        -Force `
                        -ErrorAction Stop
                }

                # rename .tmp to actual filename
                Microsoft.PowerShell.Management\Move-Item `
                    -LiteralPath $tmpFile `
                    -Destination $FilePath `
                    -Force `
                    -ErrorAction Stop

                # delete backup file if it exists
                if (Microsoft.PowerShell.Management\Test-Path `
                        -LiteralPath $tmp2File) {
                    Microsoft.PowerShell.Management\Remove-Item `
                        -LiteralPath $tmp2File `
                        -Force `
                        -ErrorAction SilentlyContinue
                }

                # operation successful, break retry loop
                break
            }
            finally {
                # always remove lock file
                if (Microsoft.PowerShell.Management\Test-Path `
                        -LiteralPath $lockFile) {
                    Microsoft.PowerShell.Management\Remove-Item `
                        -LiteralPath $lockFile `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            # log retry attempt
            Microsoft.PowerShell.Utility\Write-Verbose `
                "Write attempt $($attempt + 1) failed: $($_.Exception.Message)"

            # clean up temporary files on error
            foreach ($tempFile in @($tmpFile, $tmp2File, $lockFile)) {
                if (Microsoft.PowerShell.Management\Test-Path `
                        -LiteralPath $tempFile) {
                    Microsoft.PowerShell.Management\Remove-Item `
                        -LiteralPath $tempFile `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }

            # wait before retry unless this is the last attempt
            if ($attempt -lt ($MaxRetries - 1)) {
                Microsoft.PowerShell.Utility\Start-Sleep `
                    -Milliseconds $RetryDelayMs
            }
            else {
                # final attempt failed, throw error
                throw "Failed to write JSON file after ${MaxRetries} attempts: $_"
            }
        }
    }
}