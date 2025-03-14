###############################################################################
BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
}

AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    Remove-AllItems $Script:testRoot -DeleteFolder
}

###############################################################################
Describe "Rename-InProject" {
    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Rename-InProject.ps1"

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
        Push-Location $Script:testRoot
    }

    AfterAll {
        Pop-Location
        Remove-AllItems $Script:testRoot -DeleteFolder
    }

    BeforeEach {
        # Setup test directory structure
        $Script:testDir = Join-Path $Script:testRoot "rename-test"
        New-Item -Path $Script:testDir -ItemType Directory -Force

        # Create test files with content using Unix-style line endings
        $Script:files = @{
            "oldfile.txt"       = "This is oldtext in a file"
            "subdir/nested.txt" = "More oldtext content"
            "OldName/test.txt"  = "oldtext in subdirectory"
        }

        foreach ($file in $Script:files.Keys) {
            $path = Join-Path $Script:testDir $file
            New-Item -Path (Split-Path $path) -ItemType Directory -Force
            # Use Set-Content with -NoNewline to avoid adding line endings
            Set-Content -Path $path -Value $Script:files[$file] -NoNewline
        }

        Push-Location $Script:testDir
    }

    AfterEach {
        Pop-Location
        Remove-Item -Path (Join-Path $Script:testRoot "rename-test") -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Replaces text content in files" {
        Rename-InProject -Source .\ -FindText "oldtext" -ReplacementText "newtext"

        # Trim any line endings when comparing content
        $content = (Get-Content "oldfile.txt" -Raw).TrimEnd()
        $content | Should -Be "This is newtext in a file"

        $nestedContent = (Get-Content "subdir/nested.txt" -Raw).TrimEnd()
        $nestedContent | Should -Be "More newtext content"
    }

    It "Renames files containing search text" {
        Rename-InProject -Source .\ -FindText "old" -ReplacementText "new"

        Test-Path "newfile.txt" | Should -BeTrue
        Test-Path "oldfile.txt" | Should -BeFalse
    }

    It "Renames directories containing search text" {
        Rename-InProject -Source . -FindText "OldName" -ReplacementText "NewName"

        Test-Path "NewName" | Should -BeTrue
        Test-Path "OldName" | Should -BeFalse
        Test-Path "NewName/test.txt" | Should -BeTrue
    }

    It "Performs no changes in WhatIf mode" {
        Rename-InProject -Source . -FindText "oldtext" -ReplacementText "newtext" -WhatIf

        $content = (Get-Content "oldfile.txt" -Raw).TrimEnd()
        $content | Should -Be "This is oldtext in a file"
        Test-Path "oldfile.txt" | Should -BeTrue
    }

    It "Skips binary files" {
        # Create a fake binary file
        $binPath = "test.exe"
        [byte[]]$bytes = 1..10
        [System.IO.File]::WriteAllBytes((Join-Path $Script:testDir $binPath), $bytes)

        Rename-InProject -Source . -FindText "old" -ReplacementText "new"

        # Binary file Should remain unchanged
        Test-Path $binPath | Should -BeTrue
        $newBytes = [System.IO.File]::ReadAllBytes((Join-Path $Script:testDir $binPath))
        $newBytes | Should -Be $bytes
    }
}