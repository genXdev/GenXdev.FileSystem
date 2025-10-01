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
