###############################################################################
BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
}

AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Describe "Find-DuplicateFiles" {

    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1"

        # run analyzer with explicit settings
        $analyzerResults = GenXdev.Coding\Invoke-GenXdevScriptAnalyzer `
            -Path $scriptPath

        [string] $message = ""
        $analyzerResults | ForEach-Object {

            $message = $message + @"
--------------------------------------------------
Rule: $($_.RuleName)`
Description: $($_.Description)
Message: $($_.Message)
`r`n
"@
        }

        $analyzerResults.Count | Should -Be 0 -Because @"
The following PSScriptAnalyzer rules are being violated:
$message
"@;
    }

    BeforeAll {
        # Setup test folders with duplicate files
        $path1 = Join-Path $testRoot "dup_test1"
        $path2 = Join-Path $testRoot "dup_test2"
        New-Item -ItemType Directory -Path $path1, $path2 -Force | Out-Null

        # Create identical files with identical content
        "test content" | Set-Content -Path "$path1\file1.txt" -Encoding UTF8
        "test content" | Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Get-Date
        Set-ItemProperty -Path "$path1\file1.txt" -Name LastWriteTime -Value $date
        Set-ItemProperty -Path "$path2\file1.txt" -Name LastWriteTime -Value $date

        $unique1 = Join-Path $testRoot "unique1"
        $unique2 = Join-Path $testRoot "unique2"

        # Create unique files
        "unique1" | Set-Content -Path $unique1 -Encoding UTF8
        "unique2" | Set-Content -Path $unique2 -Encoding UTF8

    }

    AfterAll {
        Remove-Item -Path (Join-Path $testRoot "dup_test*") -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Ignores size comparison when specified" {

        "different content" | Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        # Give them the same last modified dates
        $date = Get-Date
        Set-ItemProperty -Path "$path1\file1.txt" -Name LastWriteTime -Value $date
        Set-ItemProperty -Path "$path2\file1.txt" -Name LastWriteTime -Value $date

        $dups = Find-DuplicateFiles -Paths $path1, $path2 -DontCompareSize
        $dups.Count | Should -Be 1
        $dups[0].Files.Count | Should -Be 2
    }

    It "Doesn't ignore last modified date comparison when specified" {

        "different content" | Set-Content -Path "$path2\file1.txt" -Encoding UTF8

        $dups = Find-DuplicateFiles -Paths $path1, $path2 -DontCompareSize
        $dups.Count | Should -Be 0
    }

    It "Finds no duplicates when files are unique" {

        Remove-Item "$path2\file1.txt"
        $dups = Find-DuplicateFiles -Paths $path1, $path2
        $dups | Should -BeNullOrEmpty
    }
}