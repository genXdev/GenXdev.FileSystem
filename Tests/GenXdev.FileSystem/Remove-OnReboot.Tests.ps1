
###############################################################################
Describe 'Remove-OnReboot' {
    ###############################################################################
    BeforeAll {
        $testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Set-Location $testRoot
        $testFile = Join-Path $testRoot 'reboot-delete.txt'
        Set-Content -Path $testFile -Value "test content"
    }

    AfterAll {
        $testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Remove-AllItems $testRoot -DeleteFolder
    }

    It 'Marks file for deletion on reboot' {
        Remove-OnReboot -Path $testFile | Should -BeTrue
    }
}

