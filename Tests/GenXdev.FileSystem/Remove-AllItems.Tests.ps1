Pester\Describe 'Remove-AllItems' {

    Pester\BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $testRoot
    }

    Pester\AfterAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $testRoot) {
            $null = GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
        }
    }

    Pester\BeforeEach {
        # setup test folder structure
        $testPath = "$testRoot\delete_test"
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path $testPath -Force
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "$testPath\subdir" -Force
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testPath\file1.txt"
        'test2' | Microsoft.PowerShell.Utility\Out-File "$testPath\subdir\file2.txt"
    }

    Pester\It 'Removes all files and subdirectories' {
        $null = GenXdev.FileSystem\Remove-AllItems -Path $testPath
        $remaining = Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $testPath -Recurse
        $remaining.Count | Pester\Should -Be 0
    }

    Pester\It 'Removes root folder when specified' {
        $null = GenXdev.FileSystem\Remove-AllItems -Path $testPath -DeleteFolder
        Microsoft.PowerShell.Management\Test-Path -LiteralPath $testPath | Pester\Should -Be $false
    }

    Pester\It 'Shows what-if output without deleting' {
        $null = GenXdev.FileSystem\Remove-AllItems -Path $testPath -WhatIf
        Microsoft.PowerShell.Management\Test-Path -LiteralPath $testPath | Pester\Should -Be $true
        $items = Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $testPath -Recurse
        $items.Count | Pester\Should -BeGreaterThan 0
    }
}