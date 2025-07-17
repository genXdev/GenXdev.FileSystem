###############################################################################
Pester\BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
    Microsoft.PowerShell.Management\Push-Location $testRoot
}

Pester\AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    if (Microsoft.PowerShell.Management\Test-Path $testRoot) {
        $null = GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }
}

###############################################################################
Pester\Describe 'Remove-AllItems' {

    Pester\It 'Should pass PSScriptAnalyzer rules' {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-AllItems.ps1"

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
        $remaining = Microsoft.PowerShell.Management\Get-ChildItem $testPath -Recurse
        $remaining.Count | Pester\Should -Be 0
    }

    Pester\It 'Removes root folder when specified' {
        $null = GenXdev.FileSystem\Remove-AllItems -Path $testPath -DeleteFolder
        Microsoft.PowerShell.Management\Test-Path $testPath | Pester\Should -Be $false
    }

    Pester\It 'Shows what-if output without deleting' {
        $null = GenXdev.FileSystem\Remove-AllItems -Path $testPath -WhatIf
        Microsoft.PowerShell.Management\Test-Path $testPath | Pester\Should -Be $true
        $items = Microsoft.PowerShell.Management\Get-ChildItem $testPath -Recurse
        $items.Count | Pester\Should -BeGreaterThan 0
    }
}