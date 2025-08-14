Pester\Describe 'Remove-OnReboot' {

    Pester\BeforeAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testRoot
        $testFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'reboot-delete.txt'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Value 'test content'
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\It 'Marks file for deletion on reboot' {
        GenXdev.FileSystem\Remove-OnReboot -Path $testFile | Pester\Should -BeTrue
    }
}