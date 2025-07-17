###############################################################################
Pester\BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
}

Pester\AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Pester\Describe 'Find-DuplicateFiles' {

    Pester\It 'Should pass PSScriptAnalyzer rules' {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1"

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

    Pester\BeforeAll {
        # Setup test folders with duplicate files
        $path1 = Microsoft.PowerShell.Management\Join-Path $testRoot 'dup_test1'
        $path2 = Microsoft.PowerShell.Management\Join-Path $testRoot 'dup_test2'
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path $path1, $path2 -Force | Microsoft.PowerShell.Core\Out-Null

        # Create identical files with identical content
        'test content' | Microsoft.PowerShell.Management\Set-Content -Path "$path1\file1.txt" -Encoding UTF8
        'test content' | Microsoft.PowerShell.Management\Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Microsoft.PowerShell.Utility\Get-Date
        Microsoft.PowerShell.Management\Set-ItemProperty -Path "$path1\file1.txt" -Name LastWriteTime -Value $date
        Microsoft.PowerShell.Management\Set-ItemProperty -Path "$path2\file1.txt" -Name LastWriteTime -Value $date

        $unique1 = Microsoft.PowerShell.Management\Join-Path $testRoot 'unique1'
        $unique2 = Microsoft.PowerShell.Management\Join-Path $testRoot 'unique2'

        # Create unique files
        'unique1' | Microsoft.PowerShell.Management\Set-Content -Path $unique1 -Encoding UTF8
        'unique2' | Microsoft.PowerShell.Management\Set-Content -Path $unique2 -Encoding UTF8

    }

    Pester\AfterAll {
        Microsoft.PowerShell.Management\Remove-Item -Path (Microsoft.PowerShell.Management\Join-Path $testRoot 'dup_test*') -Recurse -Force -ErrorAction SilentlyContinue
    }

    Pester\It 'Ignores size comparison when specified' {

        'different content' | Microsoft.PowerShell.Management\Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Microsoft.PowerShell.Utility\Get-Date
        Microsoft.PowerShell.Management\Set-ItemProperty -Path "$path1\file1.txt" -Name LastWriteTime -Value $date
        Microsoft.PowerShell.Management\Set-ItemProperty -Path "$path2\file1.txt" -Name LastWriteTime -Value $date

        $dups = GenXdev.FileSystem\Find-DuplicateFiles -Paths $path1, $path2 -DontCompareSize
        $dups.Count | Pester\Should -Be 1
        $dups[0].Files.Count | Pester\Should -Be 2
    }

    Pester\It "Doesn't ignore last modified date comparison when specified" {

        'different content' | Microsoft.PowerShell.Management\Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        $dups = GenXdev.FileSystem\Find-DuplicateFiles -Paths $path1, $path2 -DontCompareSize
        $dups.Count | Pester\Should -Be 0
    }

    Pester\It 'Finds no duplicates when files are unique' {

        Microsoft.PowerShell.Management\Remove-Item "$path2\file1.txt"
        $dups = GenXdev.FileSystem\Find-DuplicateFiles -Paths $path1, $path2
        $dups | Pester\Should -BeNullOrEmpty
    }
}