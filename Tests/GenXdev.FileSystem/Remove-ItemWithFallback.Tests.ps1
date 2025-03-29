###############################################################################
Pester\Describe 'Remove-ItemWithFallback' {

    Pester\BeforeAll {
        ###############################################################################
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1"

        # run analyzer with explicit settings
        $analyzerResults = GenXdev.Coding\Invoke-GenXdevScriptAnalyzer `
            -Path $scriptPath

        [string] $message = ""
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

    Pester\BeforeAll {
        Microsoft.PowerShell.Management\Set-Location "$($testRoot)"
        $testFile = GenXdev.FileSystem\Expand-Path "$($testRoot)\fallback-test.txt" -CreateFile
        Microsoft.PowerShell.Management\Set-Content -Path $testFile -Value "test content"
        $lockedFile = [IO.File]::OpenWrite($testFile)
    }

    Pester\AfterAll {
        if ($lockedFile) {
            $lockedFile.Close()
        }

        if ([IO.Path]::Exists($testFile)) {
            Microsoft.PowerShell.Management\Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    Pester\It 'Removes file using direct deletion' {
        # Should fail since file is locked
        { GenXdev.FileSystem\Remove-ItemWithFallback -Path $testFile -ErrorAction Stop } |
            Pester\Should -Throw -Because "the file is locked and cannot be deleted"

        # File should still exist after failed deletion
        Microsoft.PowerShell.Management\Test-Path $testFile | Pester\Should -BeTrue
    }

    # Pester\It 'Returns false when deletion fails without ErrorAction Stop' {
    #     # Should return false without throwing when ErrorAction is not Stop
    #     $result = GenXdev.FileSystem\Remove-ItemWithFallback -Path $testFile -ErrorAction SilentlyContinue
    #     $result | Pester\Should -BeFalse -Because "immediate deletion fails and CountRebootDeletionAsSuccess is false by default"
    #     Microsoft.PowerShell.Management\Test-Path $testFile | Pester\Should -BeTrue
    # }

    # Pester\It 'Returns true when deletion fails but CountRebootDeletionAsSuccess is true' {
    #     # Should return true when CountRebootDeletionAsSuccess is specified
    #     $result = GenXdev.FileSystem\Remove-ItemWithFallback -Path $testFile -ErrorAction SilentlyContinue -CountRebootDeletionAsSuccess
    #     $result | Pester\Should -BeTrue -Because "file is marked for deletion on reboot and CountRebootDeletionAsSuccess is true"
    #     Microsoft.PowerShell.Management\Test-Path $testFile | Pester\Should -BeTrue
    # }
}