###############################################################################
Pester\Describe "Find-Item 1" {
    Pester\It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-Item.ps1"

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
        $testDir = Microsoft.PowerShell.Management\Join-Path $testRoot 'find-item-tests'
        Microsoft.PowerShell.Management\New-Item -Path $testDir -ItemType Directory
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test2.txt" -Value "different content"
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\BeforeEach {

        Microsoft.PowerShell.Management\Set-Location (GenXdev.FileSystem\Expand-Path "$testDir\" -CreateDirectory)
    }

    Pester\AfterEach {

        GenXdev.FileSystem\Remove-AllItems $testDir
    }

    Pester\It "Finds files by extension" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Microsoft.PowerShell.Utility\Out-File "dir1/file1.txt"
        "test2" | Microsoft.PowerShell.Utility\Out-File "dir2/file2.txt"
        "test3" | Microsoft.PowerShell.Utility\Out-File "dir2/subdir/file3.txt"

        $files = GenXdev.FileSystem\Find-Item -SearchMask "./*.txt" -PassThru
        $files.Count | Pester\Should -Be 3
        $files.Name | Pester\Should -Contain "file1.txt"
    }

    Pester\It "Finds files by content pattern" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Microsoft.PowerShell.Utility\Out-File "dir1/file1.txt"
        "test2" | Microsoft.PowerShell.Utility\Out-File "dir2/file2.txt"
        "test3" | Microsoft.PowerShell.Utility\Out-File "dir2/subdir/file3.txt"

        $files = GenXdev.FileSystem\Find-Item -Pattern "test2" -PassThru
        $files.Count | Pester\Should -Be 1
        $files[0].Name | Pester\Should -Be "file2.txt"
    }

    Pester\It "Finds only directories" {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Microsoft.PowerShell.Utility\Out-File "dir1/file1.txt"
        "test2" | Microsoft.PowerShell.Utility\Out-File "dir2/file2.txt"
        "test3" | Microsoft.PowerShell.Utility\Out-File "dir2/subdir/file3.txt"
        $dirs = GenXdev.FileSystem\Find-Item -Directory -PassThru
        $dirs.Count | Pester\Should -Be 3
        $dirs.Name | Pester\Should -Contain "dir1"
        $dirs.Name | Pester\Should -Contain "dir2"
        $dirs.Name | Pester\Should -Contain "subdir"
    }

    Pester\It 'Handles wildcards correctly' {

        $results = GenXdev.FileSystem\Find-Item "$PSScriptRoot\..\..\..\..\..\mod*es\genX*" -dir -NoRecurse -PassThru | Microsoft.PowerShell.Core\ForEach-Object FullName

        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.AI")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Console")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Data")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.FileSystem")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Helpers")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Local")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.PackageManagement")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Queries")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Webbrowser")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Windows")

        $results.Length | Pester\Should -Be 12
    }

    Pester\It 'Finds files by name pattern' {

        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Microsoft.PowerShell.Utility\Out-File "dir1/file1.txt"
        "test2" | Microsoft.PowerShell.Utility\Out-File "dir2/file2.txt"
        "test3" | Microsoft.PowerShell.Utility\Out-File "dir2/subdir/file3.txt"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*.txt" -PassThru)
        $found.Count | Pester\Should -Be 3
    }

    Pester\It 'Finds files by content pattern' {
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test2.txt" -Value "different content"
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*.txt" -Pattern "test content" -PassThru)
        $found.Count | Pester\Should -Be 2
    }

    Pester\It 'Finds only directories when specified' {

        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test2.txt" -Value "different content"
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found.Count | Pester\Should -Be 1
        $found | Pester\Should -Contain $testDir
    }

    Pester\It 'With backslash at the end, finds only undelaying directories, not itself' {

        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\test2.txt" -Value "different content"
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found.Count | Pester\Should -Be 1
        $found | Pester\Should -Not -Contain $testDir
        $found | Pester\Should -Contain "$testDir\subdir"
    }

    Pester\It "Should work with pattern `$testDir\subdir*\a*\boom\correctly -Directory" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\subdir*\a*\boom\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Not -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Pester\Should -Not -Contain "$testDir\subdir\aap\test\vuur5\"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Pester\Should -Be 4
    }

    Pester\It "Should work with pattern `"`$testDir\**\boom\`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\**\boom\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Not -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Pester\Should -Not -Contain "$testDir\subdir\aap\test\vuur5\"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Pester\Should -Be 4
    }

    Pester\It "Should work with pattern: `"`$testDir\**\boom`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\**\boom" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Contain "$testDir\other\something\here\and\there\aap\boom"
        $found.Count | Pester\Should -Be 5
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Contain "$testDir\other\something\here\and\there\aap\boom"
        $found.Count | Pester\Should -Be 3
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom\`" -Directory -PassThru" {

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

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found.Count | Pester\Should -Be 3
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom\`" -PassThru" {
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

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found.Count | Pester\Should -Be 3
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom\fi*A*.txt`"  -PassThru" {
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

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\fi*A*.txt" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6\fileA567.txt"

        $found.Count | Pester\Should -Be 2
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom\fi*B*.txt`" -PassThru" {

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

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\fi*B*.txt" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found.Count | Pester\Should -Be 1
    }

    Pester\It 'Should match the pattern' {

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$PSScriptRoot\..\..\..\..\..\**\Genx*stem\1.158.2025\Functions\GenXdev.FileSystem\*.ps1" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\_AssureTypes.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\AssurePester.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Expand-Path.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Find-Item.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Invoke-Fasti.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-AllItems.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Remove-OnReboot.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Rename-InProject.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Start-RoboCopy.ps1")

        $found.Count | Pester\Should -Be 13
    }
}