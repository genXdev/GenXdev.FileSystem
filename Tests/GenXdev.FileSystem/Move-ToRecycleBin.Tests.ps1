###############################################################################
Describe 'Move-ToRecycleBin' {

    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1"

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

    ###############################################################################
    BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Set-Location $Script:testRoot
        $Script:testFile = Join-Path $Script:testRoot 'recycle-test.txt'
        Set-Content -Path $Script:testFile -Value "test content"
    }

    AfterAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        Remove-AllItems $Script:testRoot -DeleteFolder
    }

    It 'Moves file to recycle bin' {

        Move-ToRecycleBin -Path $Script:testFile | Should -BeTrue
    }
}