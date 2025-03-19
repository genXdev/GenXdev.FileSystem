###############################################################################
$Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

Pester\AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Pester\Describe 'Remove-ItemWithFallback' {

    Pester\It "Should pass PSScriptAnalyzer rules" {
        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1"

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
        Microsoft.PowerShell.Management\Set-Location $Script:testRoot
        $Script:testFile = GenXdev.FileSystem\Expand-Path "$Script:testRoot\fallback-test.txt" -CreateFile
        Microsoft.PowerShell.Management\Set-Content -Path $Script:testFile -Value "test content"
        $Script:lockedFile = [IO.File]::OpenWrite($Script:testFile)
    }

    Pester\AfterAll {
        if ($Script:lockedFile) {
            $Script:lockedFile.Close()
        }

        if ([IO.Path]::Exists($Script:testFile)) {
            Microsoft.PowerShell.Management\Remove-Item $Script:testFile -Force
        }
    }

    Pester\It 'Removes file using direct deletion' {
        # Should fail since file is locked
        { GenXdev.FileSystem\Remove-ItemWithFallback -Path $Script:testFile -ErrorAction Stop } | Pester\Should -Throw
        Microsoft.PowerShell.Management\Test-Path $Script:testFile | Pester\Should -BeTrue
    }
}