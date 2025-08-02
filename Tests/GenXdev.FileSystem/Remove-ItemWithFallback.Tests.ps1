###############################################################################
Pester\Describe 'Remove-ItemWithFallback' {

    Pester\BeforeAll {
        ###############################################################################
        # Create test directory in TEMP path
        $script:testRoot = GenXdev.FileSystem\Expand-Path "${env:TEMP}\GenXdev.FileSystem.Tests\" -CreateDirectory

        # Explicitly set working location to avoid C:\ access issues
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $script:testRoot

        # Create test files in the test directory
        $script:testFile = GenXdev.FileSystem\Expand-Path "${script:testRoot}\fallback-test.txt" -CreateFile
        Microsoft.PowerShell.Management\Set-Content -LiteralPath $script:testFile -Value 'test content'

        try {
            $script:lockedFile = [IO.File]::OpenWrite($script:testFile)
        }
        catch {
            Microsoft.PowerShell.Utility\Write-Warning "Failed to lock test file: $_"
        }
    }

    Pester\AfterAll {
        # Ensure file is unlocked and cleaned up
        if ($null -ne $script:lockedFile) {
            try {
                $script:lockedFile.Close()
                $script:lockedFile.Dispose()
                $script:lockedFile = $null
            }
            catch {
                Microsoft.PowerShell.Utility\Write-Warning "Failed to close file handle: $_"
            }
        }

        if ($script:testFile -and (Microsoft.PowerShell.Management\Test-Path -LiteralPath $script:testFile -ErrorAction SilentlyContinue)) {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $script:testFile -Force -ErrorAction SilentlyContinue
        }

        # Ensure we have a valid test directory
        if (![string]::IsNullOrEmpty($script:testRoot) -and (Microsoft.PowerShell.Management\Test-Path -LiteralPath $script:testRoot)) {
            # cleanup test folder, but make sure we're not accidentally deleting C:\
            if ($script:testRoot -like "${env:TEMP}*") {
                GenXdev.FileSystem\Remove-AllItems $script:testRoot -DeleteFolder -ErrorAction SilentlyContinue
            }
        }
    }

    Pester\It 'Should pass PSScriptAnalyzer rules' {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1"

        # run analyzer with explicit settings
        $analyzerResults = GenXdev.Coding\Invoke-GenXdevScriptAnalyzer `
            -Path $scriptPath

        [string] $message = ''
        $analyzerResults | Microsoft.PowerShell.Core\ForEach-Object {
            $message = $message + @"
--------------------------------------------------
Rule: $($_.RuleName)`
Description: $($_.Description)
Message: $($_.Message)
`r`n
"@
        }

        $analyzerResults.Count | Pester\Should -Be 0 -Because @"
The following PSScriptAnalyzer rules are being violated:
$message
"@;
    }

    Pester\It 'Removes file using direct deletion' {
        # Should fail since file is locked
        { GenXdev.FileSystem\Remove-ItemWithFallback -Path $script:testFile -ErrorAction Stop } |
            Pester\Should -Throw -Because 'the file is locked and cannot be deleted'

        # File should still exist after failed deletion
        Microsoft.PowerShell.Management\Test-Path -LiteralPath $script:testFile | Pester\Should -BeTrue
    }

    # Pester\It 'Returns false when deletion fails without ErrorAction Stop' {
    #     # Should return false without throwing when ErrorAction is not Stop
    #     $result = GenXdev.FileSystem\Remove-ItemWithFallback -Path $testFile -ErrorAction SilentlyContinue
    #     $result | Pester\Should -BeFalse -Because "immediate deletion fails and CountRebootDeletionAsSuccess is false by default"
    #     Microsoft.PowerShell.Management\Test-Path -LiteralPath $testFile | Pester\Should -BeTrue
    # }

    # Pester\It 'Returns true when deletion fails but CountRebootDeletionAsSuccess is true' {
    #     # Should return true when CountRebootDeletionAsSuccess is specified
    #     $result = GenXdev.FileSystem\Remove-ItemWithFallback -Path $testFile -ErrorAction SilentlyContinue -CountRebootDeletionAsSuccess
    #     $result | Pester\Should -BeTrue -Because "file is marked for deletion on reboot and CountRebootDeletionAsSuccess is true"
    #     Microsoft.PowerShell.Management\Test-Path -LiteralPath $testFile | Pester\Should -BeTrue
    # }
}