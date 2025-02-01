###############################################################################
$Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

AfterAll {
    $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Describe 'Remove-ItemWithFallback' {
    BeforeAll {
        Push-Location $Script:testRoot
        $Script:testFile = Expand-Path "$Script:testRoot\fallback-test.txt" -CreateFile
        Set-Content -Path $Script:testFile -Value "test content"
        $Script:lockedFile = [IO.File]::OpenWrite($Script:testFile)
    }

    AfterAll {
        if ($Script:lockedFile) {
            $Script:lockedFile.Close()
        }
        Pop-Location

        if ([IO.Path]::Exists($Script:testFile)) {
            Remove-Item $Script:testFile -Force
        }
    }

    It 'Removes file using direct deletion' {
        # Should fail since file is locked
        { Remove-ItemWithFallback -Path $Script:testFile -ErrorAction Stop } | Should -Throw
        Test-Path $Script:testFile | Should -BeTrue
    }
}

