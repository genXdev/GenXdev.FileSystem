###############################################################################
Pester\BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
    Microsoft.PowerShell.Management\Push-Location $testRoot
}

Pester\AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Pester\Describe 'Move-ItemWithTracking' {
    Pester\It "Should pass PSScriptAnalyzer rules" {
        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1"

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
        $sourceFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'track-source.txt'
        $destFile = Microsoft.PowerShell.Management\Join-Path $testRoot 'track-dest.txt'
        Microsoft.PowerShell.Management\Set-Content -Path $sourceFile -Value "test content"
    }

    Pester\It 'Moves file with link tracking' {
        Pester\Mock Add-Type {
            return @{
                MoveFileEx = { return $true }
            }
        }

        GenXdev.FileSystem\Move-ItemWithTracking -Path $sourceFile -Destination $destFile | Pester\Should -BeTrue
        Microsoft.PowerShell.Management\Test-Path -Path $sourceFile | Pester\Should -BeFalse
        Microsoft.PowerShell.Management\Test-Path -Path $destFile | Pester\Should -BeTrue
    }
}