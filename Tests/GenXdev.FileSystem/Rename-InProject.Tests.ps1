###############################################################################
Pester\BeforeAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
}

Pester\AfterAll {
    $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

    # cleanup test folder
    GenXdev.FileSystem\Remove-AllItems $Script:testRoot -DeleteFolder
}

###############################################################################
Pester\Describe 'Rename-InProject' {
    Pester\It 'Should pass PSScriptAnalyzer rules' {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Rename-InProject.ps1"

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

    Pester\BeforeAll {
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $Script:testRoot
    }

    Pester\AfterAll {
        Microsoft.PowerShell.Management\Pop-Location
        GenXdev.FileSystem\Remove-AllItems $Script:testRoot -DeleteFolder
    }

    Pester\BeforeEach {
        # Setup test directory structure
        $Script:testDir = Microsoft.PowerShell.Management\Join-Path $Script:testRoot 'rename-test'
        Microsoft.PowerShell.Management\New-Item -Path $Script:testDir -ItemType Directory -Force

        # Create test files with content using Unix-style line endings
        $Script:files = @{
            'oldfile.txt'       = 'This is oldtext in a file'
            'subdir/nested.txt' = 'More oldtext content'
            'OldName/test.txt'  = 'oldtext in subdirectory'
        }

        foreach ($file in $Script:files.Keys) {
            $path = Microsoft.PowerShell.Management\Join-Path $Script:testDir $file
            Microsoft.PowerShell.Management\New-Item -Path (Microsoft.PowerShell.Management\Split-Path $path) -ItemType Directory -Force
            # Use Set-Content with -NoNewline to avoid adding line endings
            Microsoft.PowerShell.Management\Set-Content -LiteralPath $path -Value $Script:files[$file] -NoNewline
        }

        Microsoft.PowerShell.Management\Push-Location -LiteralPath $Script:testDir
    }

    Pester\AfterEach {
        Microsoft.PowerShell.Management\Pop-Location
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath (Microsoft.PowerShell.Management\Join-Path $Script:testRoot 'rename-test') -Recurse -Force -ErrorAction SilentlyContinue
    }

    Pester\It 'Replaces text content in files' {
        GenXdev.FileSystem\Rename-InProject -Source .\ -FindText 'oldtext' -ReplacementText 'newtext'

        # Trim any line endings when comparing content
        $content = (Microsoft.PowerShell.Management\Get-Content -LiteralPath 'oldfile.txt' -Raw).TrimEnd()
        $content | Pester\Should -Be 'This is newtext in a file'

        $nestedContent = (Microsoft.PowerShell.Management\Get-Content -LiteralPath 'subdir/nested.txt' -Raw).TrimEnd()
        $nestedContent | Pester\Should -Be 'More newtext content'
    }

    Pester\It 'Renames files containing search text' {
        GenXdev.FileSystem\Rename-InProject -Source .\ -FindText 'old' -ReplacementText 'new'

        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'newfile.txt' | Pester\Should -BeTrue
        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'oldfile.txt' | Pester\Should -BeFalse
    }

    Pester\It 'Renames directories containing search text' {
        GenXdev.FileSystem\Rename-InProject -Source . -FindText 'OldName' -ReplacementText 'NewName'

        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'NewName' | Pester\Should -BeTrue
        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'OldName' | Pester\Should -BeFalse
        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'NewName/test.txt' | Pester\Should -BeTrue
    }

    Pester\It 'Performs no changes in WhatIf mode' {
        GenXdev.FileSystem\Rename-InProject -Source . -FindText 'oldtext' -ReplacementText 'newtext' -WhatIf

        $content = (Microsoft.PowerShell.Management\Get-Content -LiteralPath 'oldfile.txt' -Raw).TrimEnd()
        $content | Pester\Should -Be 'This is oldtext in a file'
        Microsoft.PowerShell.Management\Test-Path -LiteralPath 'oldfile.txt' | Pester\Should -BeTrue
    }

    Pester\It 'Skips binary files' {
        # Create a fake binary file
        $binPath = 'test.exe'
        [byte[]]$bytes = 1..10
        [System.IO.File]::WriteAllBytes((Microsoft.PowerShell.Management\Join-Path $Script:testDir $binPath), $bytes)

        GenXdev.FileSystem\Rename-InProject -Source . -FindText 'old' -ReplacementText 'new'

        # Binary file Should remain unchanged
        Microsoft.PowerShell.Management\Test-Path -LiteralPath $binPath | Pester\Should -BeTrue
        $newBytes = [System.IO.File]::ReadAllBytes((Microsoft.PowerShell.Management\Join-Path $Script:testDir $binPath))
        $newBytes | Pester\Should -Be $bytes
    }
}