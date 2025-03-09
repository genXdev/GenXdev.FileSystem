###############################################################################
BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
    Push-Location $testRoot
}

AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Describe 'Move-ItemWithTracking' {
    It "should pass PSScriptAnalyzer rules" {
        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1"

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
        $sourceFile = Join-Path $testRoot 'track-source.txt'
        $destFile = Join-Path $testRoot 'track-dest.txt'
        Set-Content -Path $sourceFile -Value "test content"
    }

    It 'Moves file with link tracking' {
        Mock Add-Type {
            return @{
                MoveFileEx = { return $true }
            }
        }

        Move-ItemWithTracking -Path $sourceFile -Destination $destFile | Should -BeTrue
        Test-Path -Path $sourceFile | Should -BeFalse
        Test-Path -Path $destFile | Should -BeTrue
    }
}

