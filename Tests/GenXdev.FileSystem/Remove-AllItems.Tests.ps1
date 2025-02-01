
###############################################################################
BeforeAll {
    $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
Push-Location $testRoot
}

AfterAll {
    $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    if (Test-Path $testRoot) {
        Remove-AllItems $testRoot -DeleteFolder
    }
}

###############################################################################
Describe "Remove-AllItems" {

    BeforeEach {
        # setup test folder structure
        $testPath = "$testRoot\delete_test"
        New-Item -ItemType Directory -Path $testPath -Force
        New-Item -ItemType Directory -Path "$testPath\subdir" -Force
        "test1" | Out-File "$testPath\file1.txt"
        "test2" | Out-File "$testPath\subdir\file2.txt"
    }

    It "Removes all files and subdirectories" {
        Remove-AllItems -Path $testPath
        $remaining = Get-ChildItem $testPath -Recurse
        $remaining.Count | Should -Be 0
    }

    It "Removes root folder when specified" {
        Remove-AllItems -Path $testPath -DeleteFolder
        Test-Path $testPath | Should -Be $false
    }

    It "Shows what-if output without deleting" {
        Remove-AllItems -Path $testPath -WhatIf
        Test-Path $testPath | Should -Be $true
        $items = Get-ChildItem $testPath -Recurse
        $items.Count | Should -BeGreaterThan 0
    }
}

