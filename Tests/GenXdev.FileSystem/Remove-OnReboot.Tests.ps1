###############################################################################
Pester\Describe 'Remove-OnReboot' {
    ###############################################################################
    Pester\It "Should pass PSScriptAnalyzer rules" {

# get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-OnReboot.ps1"

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

    Pester\BeforeAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $testRoot
        $testFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'reboot-delete.txt'
        Microsoft.PowerShell.Management\Set-Content -Path $testFile -Value "test content"
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\It 'Marks file for deletion on reboot' {
        GenXdev.FileSystem\Remove-OnReboot -Path $testFile | Pester\Should -BeTrue
    }
}