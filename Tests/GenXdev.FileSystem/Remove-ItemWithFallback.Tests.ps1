###############################################################################
$Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    Remove-AllItems $testRoot -DeleteFolder
}

###############################################################################
Describe 'Remove-ItemWithFallback' {

    It "should pass PSScriptAnalyzer rules" {
        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1"

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
        Set-Location $Script:testRoot
        $Script:testFile = GenXdev.FileSystem\Expand-Path "$Script:testRoot\fallback-test.txt" -CreateFile
        Set-Content -Path $Script:testFile -Value "test content"
        $Script:lockedFile = [IO.File]::OpenWrite($Script:testFile)
    }

    AfterAll {
        if ($Script:lockedFile) {
            $Script:lockedFile.Close()
        }

        if ([IO.Path]::Exists($Script:testFile)) {
            Remove-Item $Script:testFile -Force
        }
    }

    It 'Removes file using direct deletion' {
        # Should fail since file is locked
        { Remove-ItemWithFallback -Path $Script:testFile -ErrorAction Stop } | Should -Throw
        Test-Path $Script:testFile | Should -BeTrue
    }
}

