<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : ReadJsonWithRetry.ps1
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
Reads JSON file with retry logic and automatic lock cleanup.

.DESCRIPTION
Attempts to read a JSON file with retry logic to handle concurrent access.
Implements automatic cleanup of stale lock files. Returns empty hashtable if
file doesn't exist.

.PARAMETER FilePath
The path to the JSON file to read.

.PARAMETER AsHashtable
Return the parsed JSON as a hashtable instead of PSCustomObject. Defaults to true.

.PARAMETER MaxRetries
Maximum number of retry attempts. Defaults to 10.

.PARAMETER RetryDelayMs
Delay in milliseconds between retries. Defaults to 200.
#>
function ReadJsonWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 10,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelayMs = 200,

        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable
    )

    # return empty hashtable if file doesn't exist
    if (-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $FilePath)) {
        if ($AsHashtable) {
            return @{}
        }
        else {
            return
        }
    }

    # construct lock file path
    $lockFile = "${FilePath}.lock"

    # attempt to read with retries
    for ($attempt = 0; $attempt -lt $MaxRetries; $attempt++) {
        try {
            # clean up stale lock files older than 30 seconds
            if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $lockFile) {
                $lockInfo = [System.IO.FileInfo]::new($lockFile)
                $ageSeconds = ([DateTime]::Now - $lockInfo.LastWriteTime).TotalSeconds

                if ($ageSeconds -gt 30) {
                    Microsoft.PowerShell.Utility\Write-Verbose `
                        "Removing stale lock file: $lockFile (age: ${ageSeconds}s)"
                    Microsoft.PowerShell.Management\Remove-Item `
                        -LiteralPath $lockFile `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }

            # read and parse json file
            $content = Microsoft.PowerShell.Management\Get-Content `
                -LiteralPath $FilePath `
                -Raw `
                -ErrorAction Stop

            if ([string]::IsNullOrWhiteSpace($content)) {
                if ($AsHashtable) {
                    return @{}
                }
                else {
                    return
                }
            }

            if ($AsHashtable) {
                $data = $content | Microsoft.PowerShell.Utility\ConvertFrom-Json `
                    -AsHashtable `
                    -ErrorAction Stop
            }
            else {
                $data = $content | Microsoft.PowerShell.Utility\ConvertFrom-Json `
                    -ErrorAction Stop
            }

            return $data
        }
        catch {
            # log retry attempt
            Microsoft.PowerShell.Utility\Write-Verbose `
                "Read attempt $($attempt + 1) failed: $($_.Exception.Message)"

            # wait before retry unless this is the last attempt
            if ($attempt -lt ($MaxRetries - 1)) {
                Microsoft.PowerShell.Utility\Start-Sleep `
                    -Milliseconds $RetryDelayMs
            }
            else {
                # final attempt failed, throw error
                throw "Failed to read JSON file after ${MaxRetries} attempts: $_"
            }
        }
    }
}