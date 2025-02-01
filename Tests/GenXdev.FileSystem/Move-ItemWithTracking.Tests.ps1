
###############################################################################
BeforeAll {
    $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
Push-Location $testRoot
}

AfterAll {
    $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
        Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Describe 'Move-ItemWithTracking' {
    BeforeAll {
        $sourceFile = Join-Path $testRoot 'track-source.txt'
        $destFile = Join-Path $testRoot 'track-dest.txt'
        Set-Content -Path $sourceFile -Value "test content"
    }

    It 'Moves file with link tracking' {
        Mock Add-Type {
            return @{
                MoveFileEx = { return $true }
            }
        }

        Move-ItemWithTracking -Path $sourceFile -Destination $destFile | Should -BeTrue
        Test-Path -Path $sourceFile | Should -BeFalse
        Test-Path -Path $destFile | Should -BeTrue
    }
}

