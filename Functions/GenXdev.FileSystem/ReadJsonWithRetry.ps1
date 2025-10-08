<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : ReadJsonWithRetry.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.298.2025
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
Reads JSON file with retry logic and automatic lock cleanup.

.DESCRIPTION
Attempts to read a JSON file with retry logic to handle concurrent access.
Implements automatic cleanup of stale lock files. Returns empty hashtable if
file doesn't exist.

.PARAMETER FilePath
The path to the JSON file to read.

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
        [int]$RetryDelayMs = 200
    )

    # return empty hashtable if file doesn't exist
    if (-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $FilePath)) {
        return @{}
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
                return @{}
            }

            $data = $content | Microsoft.PowerShell.Utility\ConvertFrom-Json `
                -AsHashtable `
                -ErrorAction Stop

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
