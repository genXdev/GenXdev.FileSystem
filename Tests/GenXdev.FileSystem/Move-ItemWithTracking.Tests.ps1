Pester\Describe 'Move-ItemWithTracking' {

    Pester\BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Push-Location $testRoot

        $sourceFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'track-source.txt'
        $destFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'track-dest.txt'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath $sourceFile -Value 'test content'
    }

    Pester\AfterAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\It 'Moves file with link tracking' {
        Pester\Mock Add-Type {
            return @{
                MoveFileEx = { return $true }
            }
        }

        GenXdev.FileSystem\Move-ItemWithTracking -Path $sourceFile -Destination $destFile | Pester\Should -BeTrue
        Microsoft.PowerShell.Management\Test-Path -LiteralPath  $sourceFile | Pester\Should -BeFalse
        Microsoft.PowerShell.Management\Test-Path -LiteralPath  $destFile | Pester\Should -BeTrue
    }
}