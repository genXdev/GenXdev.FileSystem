###############################################################################
Pester\Describe 'Move-ToRecycleBin' {

    Pester\It "Should pass PSScriptAnalyzer rules" {

# get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1"

# run analyzer with explicit settings
        $analyzerResults = GenXdev.Coding\Invoke-GenXdevScriptAnalyzer `
            -Path $scriptPath

        [string] $message = ""
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

    ###############################################################################
    Pester\BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $Script:testRoot
        $Script:testFile = Microsoft.PowerShell.Management\Join-Path $Script:testRoot 'recycle-test.txt'
        Microsoft.PowerShell.Management\Set-Content -Path $Script:testFile -Value "test content"
    }

    Pester\AfterAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

# cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $Script:testRoot -DeleteFolder
    }

    Pester\It 'Moves file to recycle bin' {

        GenXdev.FileSystem\Move-ToRecycleBin -Path $Script:testFile | Pester\Should -BeTrue
    }
}