Pester\Describe 'Find-DuplicateFiles' {

    Pester\BeforeAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\$([DateTime]::UtcNow.Ticks)\" -CreateDirectory
        GenXdev.FileSystem\Remove-AllItems $testRoot

        # Setup test folders with duplicate files
        $path1 = Microsoft.PowerShell.Management\Join-Path $testRoot 'dup_test1'
        $path2 = Microsoft.PowerShell.Management\Join-Path $testRoot 'dup_test2'
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path $path1, $path2 -Force | Microsoft.PowerShell.Core\Out-Null

        # Create identical files with identical content
        'test content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath "$path1\file1.txt" -Encoding UTF8
        'test content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Microsoft.PowerShell.Utility\Get-Date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path1\file1.txt" -Name LastWriteTime -Value $date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path2\file1.txt" -Name LastWriteTime -Value $date

        $unique1 = Microsoft.PowerShell.Management\Join-Path $testRoot 'unique1'
        $unique2 = Microsoft.PowerShell.Management\Join-Path $testRoot 'unique2'

        # Create unique files
        'unique1' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $unique1 -Encoding UTF8
        'unique2' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $unique2 -Encoding UTF8
    }

    Pester\AfterAll {

        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\It 'Ignores size comparison when specified' {

        'different content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Microsoft.PowerShell.Utility\Get-Date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path1\file1.txt" -Name LastWriteTime -Value $date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path2\file1.txt" -Name LastWriteTime -Value $date

        $dups = @(GenXdev.FileSystem\Find-DuplicateFiles -Paths $path1, $path2 -DontCompareSize)
        $dups.Count | Pester\Should -Be 1
        $dups[0].Files.Count | Pester\Should -Be 2
    }

    Pester\It 'Finds no duplicates when files are unique' {

        # Give them the same last modified dates
        $date = Microsoft.PowerShell.Utility\Get-Date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path1\file1.txt" -Name LastWriteTime -Value $date
        Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath "$path2\file1.txt" -Name LastWriteTime -Value $date

        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "$path2\file1.txt"  -Confirm:$False
        $dups = @(GenXdev.FileSystem\Find-DuplicateFiles -Paths $path1, $path2)
        $dups | Pester\Should -BeNullOrEmpty
    }
}