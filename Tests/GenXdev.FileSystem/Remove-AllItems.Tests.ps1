###############################################################################
BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
    Push-Location $testRoot
}

AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    if (Test-Path $testRoot) {
        $null = Remove-AllItems $testRoot -DeleteFolder
    }
}

###############################################################################
Describe "Remove-AllItems" {

    It "should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-AllItems.ps1"

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

    BeforeEach {
        # setup test folder structure
        $testPath = "$testRoot\delete_test"
        New-Item -ItemType Directory -Path $testPath -Force
        New-Item -ItemType Directory -Path "$testPath\subdir" -Force
        "test1" | Out-File "$testPath\file1.txt"
        "test2" | Out-File "$testPath\subdir\file2.txt"
    }

    It "Removes all files and subdirectories" {
        $null = Remove-AllItems -Path $testPath
        $remaining = Get-ChildItem $testPath -Recurse
        $remaining.Count | Should -Be 0
    }

    It "Removes root folder when specified" {
        $null = Remove-AllItems -Path $testPath -DeleteFolder
        Test-Path $testPath | Should -Be $false
    }

    It "Shows what-if output without deleting" {
        $null = Remove-AllItems -Path $testPath -WhatIf
        Test-Path $testPath | Should -Be $true
        $items = Get-ChildItem $testPath -Recurse
        $items.Count | Should -BeGreaterThan 0
    }
}

