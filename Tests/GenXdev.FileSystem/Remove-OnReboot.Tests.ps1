###############################################################################
Describe 'Remove-OnReboot' {
    ###############################################################################
    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-OnReboot.ps1"

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
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Set-Location $testRoot
        $testFile = Join-Path $testRoot 'reboot-delete.txt'
        Set-Content -Path $testFile -Value "test content"
    }

    AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Remove-AllItems $testRoot -DeleteFolder
    }

    It 'Marks file for deletion on reboot' {
        Remove-OnReboot -Path $testFile | Should -BeTrue
    }
}