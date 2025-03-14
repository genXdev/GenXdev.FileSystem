###############################################################################
Describe "Find-Item 1" {
    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-Item.ps1"

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
        $testDir = Join-Path $testRoot 'find-item-tests'
        New-Item -Path $testDir -ItemType Directory
        Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Set-Content -Path "$testDir\test2.txt" -Value "different content"
        New-Item -Path "$testDir\subdir" -ItemType Directory
        Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"
    }

    AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        Remove-AllItems $testRoot -DeleteFolder
    }

    BeforeEach {

        Set-Location (GenXdev.FileSystem\Expand-Path "$testDir\" -CreateDirectory)
    }

    AfterEach {

        Remove-AllItems $testDir
    }

    It "Finds files by extension" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Set-Location $testDir
        New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Out-File "dir1/file1.txt"
        "test2" | Out-File "dir2/file2.txt"
        "test3" | Out-File "dir2/subdir/file3.txt"

        $files = Find-Item -SearchMask "./*.txt" -PassThru
        $files.Count | Should -Be 3
        $files.Name | Should -Contain "file1.txt"
    }

    It "Finds files by content pattern" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Set-Location $testDir
        New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Out-File "dir1/file1.txt"
        "test2" | Out-File "dir2/file2.txt"
        "test3" | Out-File "dir2/subdir/file3.txt"

        $files = Find-Item -Pattern "test2" -PassThru
        $files.Count | Should -Be 1
        $files[0].Name | Should -Be "file2.txt"
    }

    It "Finds only directories" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Set-Location $testDir
        New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Out-File "dir1/file1.txt"
        "test2" | Out-File "dir2/file2.txt"
        "test3" | Out-File "dir2/subdir/file3.txt"
        $dirs = Find-Item -Directory -PassThru
        $dirs.Count | Should -Be 3
        $dirs.Name | Should -Contain "dir1"
        $dirs.Name | Should -Contain "dir2"
        $dirs.Name | Should -Contain "subdir"
    }

    It 'Handles wildcards correctly' {

        $results = Find-Item "$PSScriptRoot\..\..\..\..\..\mod*es\genX*" -dir -NoRecurse -PassThru | ForEach-Object FullName

        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.AI")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Console")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Data")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.FileSystem")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Helpers")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Local")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.PackageManagement")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Queries")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Webbrowser")
        $results | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Windows")

        $results.Length | Should -Be 12
    }

    It 'Finds files by name pattern' {

        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Set-Location $testDir
        New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Out-File "dir1/file1.txt"
        "test2" | Out-File "dir2/file2.txt"
        "test3" | Out-File "dir2/subdir/file3.txt"

        $found = @(Find-Item -SearchMask "$testDir\*.txt" -PassThru)
        $found.Count | Should -Be 3
    }

    It 'Finds files by content pattern' {
        Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Set-Content -Path "$testDir\test2.txt" -Value "different content"
        New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(Find-Item -SearchMask "$testDir\*.txt" -Pattern "test content" -PassThru)
        $found.Count | Should -Be 2
    }

    It 'Finds only directories when specified' {

        Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Set-Content -Path "$testDir\test2.txt" -Value "different content"
        New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(Find-Item -SearchMask "$testDir" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found.Count | Should -Be 1
        $found | Should -Contain $testDir
    }

    It 'With backslash at the end, finds only undelaying directories, not itself' {

        Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Set-Content -Path "$testDir\test2.txt" -Value "different content"
        New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(Find-Item -SearchMask "$testDir\" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found.Count | Should -Be 1
        $found | Should -Not -Contain $testDir
        $found | Should -Contain "$testDir\subdir"
    }

    It "Should work with pattern `$testDir\subdir*\a*\boom\correctly -Directory" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(Find-Item -SearchMask "$testDir\subdir*\a*\boom\" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Should -Not -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Should -Not -Contain "$testDir\subdir\aap\test\vuur5\"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Should -Be 4
    }

    It "Should work with pattern `"`$testDir\**\boom\`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(Find-Item -SearchMask "$testDir\**\boom\" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Should -Not -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Should -Not -Contain "$testDir\subdir\aap\test\vuur5\"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Should -Be 4
    }

    It "Should work with pattern: `"`$testDir\**\boom`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(Find-Item -SearchMask "$testDir\**\boom" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found | Should -Contain "$testDir\subdir2\aap\boom"
        $found | Should -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Should -Contain "$testDir\subdir\arend\boom"
        $found | Should -Contain "$testDir\subdir\aap\boom"
        $found | Should -Contain "$testDir\other\something\here\and\there\aap\boom"
        $found.Count | Should -Be 5
    }

    It "Should work with pattern: `"`$testRoot\**\aap\boom`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(Find-Item -SearchMask "$testRoot\**\aap\boom" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found | Should -Contain "$testDir\subdir2\aap\boom"
        $found | Should -Contain "$testDir\subdir\aap\boom"
        $found | Should -Contain "$testDir\other\something\here\and\there\aap\boom"
        $found.Count | Should -Be 3
    }

    It "Should work with pattern: `"`$testRoot\**\aap\boom\`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        "testA123" > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        "testA567" > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        "testB890" > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(Find-Item -SearchMask "$testRoot\**\aap\boom\" -Directory -PassThru | Select-Object -ExpandProperty FullName)
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Should -Be 3
    }

    It "Should work with pattern: `"`$testRoot\**\aap\boom\`" -PassThru" {
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        "testA123" > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        "testA567" > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        "testB890" > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(Find-Item -SearchMask "$testRoot\**\aap\boom\" -PassThru | Select-Object -ExpandProperty FullName)

        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found.Count | Should -Be 3
    }

    It "Should work with pattern: `"`$testRoot\**\aap\boom\fi*A*.txt`"  -PassThru" {
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        "testA123" > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        "testA567" > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        "testB890" > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(Find-Item -SearchMask "$testRoot\**\aap\boom\fi*A*.txt" -PassThru | Select-Object -ExpandProperty FullName)

        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        $found | Should -Contain "$testDir\subdir\aap\boom\vuur6\fileA567.txt"

        $found.Count | Should -Be 2
    }

    It "Should work with pattern: `"`$testRoot\**\aap\boom\fi*B*.txt`" -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        "testA123" > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        "testA567" > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        "testB890" > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(Find-Item -SearchMask "$testRoot\**\aap\boom\fi*B*.txt" -PassThru | Select-Object -ExpandProperty FullName)

        $found | Should -Contain "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found.Count | Should -Be 1
    }

    It 'Should match the pattern' {

        $found = @(Find-Item -SearchMask "$PSScriptRoot\..\..\..\..\..\..\**\Genx*stem\*.*.*\Functions\GenXdev.FileSystem\*.ps1" -PassThru | Select-Object -ExpandProperty FullName)

        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\AssurePester.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Expand-Path.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-Item.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Invoke-Fasti.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-AllItems.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-OnReboot.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Rename-InProject.ps1")
        $found | Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Start-RoboCopy.ps1")

        $found.Count | Should -Be 12
    }
}