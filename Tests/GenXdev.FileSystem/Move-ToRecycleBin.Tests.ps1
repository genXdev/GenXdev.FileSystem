
###############################################################################
Describe 'Move-ToRecycleBin' {

    ###############################################################################
    BeforeAll {
        $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Push-Location $Script:testRoot
        $Script:testFile = Join-Path $Script:testRoot 'recycle-test.txt'
        Set-Content -Path $Script:testFile -Value "test content"
    }

    AfterAll {
        $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        Remove-AllItems $Script:testRoot -DeleteFolder

        Pop-Location
    }

    It 'Moves file to recycle bin' {

        Move-ToRecycleBin -Path $Script:testFile | Should -BeTrue
    }
}

