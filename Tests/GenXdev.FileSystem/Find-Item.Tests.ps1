Pester\Describe 'Find-Item 1' {

    Pester\BeforeAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        $testDir = Microsoft.PowerShell.Management\Join-Path $testRoot 'find-item-tests'
        Microsoft.PowerShell.Management\New-Item -Path $testDir -ItemType Directory
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder
    }

    Pester\BeforeEach {

        Microsoft.PowerShell.Management\Set-Location -LiteralPath (GenXdev.FileSystem\Expand-Path "$testDir\" -CreateDirectory) -ErrorAction SilentlyContinue
    }

    Pester\AfterEach {

        GenXdev.FileSystem\Remove-AllItems $testDir
    }

    Pester\It 'Should work with wildcard in the holding directory' {

        $pattern = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\Genx*\1*\functions\genxdev.*\*.ps1"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $pattern)

        if ($found.Count -eq 0) {
            Microsoft.PowerShell.Utility\Write-Warning 'Find-Item still not working, see issue'
        }
        else {
            Microsoft.PowerShell.Utility\Write-Host 'Find-Item is FIXED!!' -ForegroundColor Cyan
        }

        # $found.Count | Pester\Should -GT 0
    }

    Pester\It 'Finds files by extension' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $files = GenXdev.FileSystem\Find-Item -SearchMask './*.txt' -PassThru
        $files.Count | Pester\Should -Be 3
        $files.Name | Pester\Should -Contain 'file1.txt'
    }

    Pester\It 'Finds files by content pattern' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $files = GenXdev.FileSystem\Find-Item -Pattern 'test2' -PassThru
        $files.Count | Pester\Should -Be 1
        $files[0].Name | Pester\Should -Be 'file2.txt'
    }

    Pester\It 'Finds only directories' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'
        $dirs = GenXdev.FileSystem\Find-Item -Directory -PassThru
        $dirs.Count | Pester\Should -Be 3
        $dirs.Name | Pester\Should -Contain 'dir1'
        $dirs.Name | Pester\Should -Contain 'dir2'
        $dirs.Name | Pester\Should -Contain 'subdir'
    }

    Pester\It 'Handles wildcards correctly' {

        $results = GenXdev.FileSystem\Find-Item "$PSScriptRoot\..\..\..\..\..\mod*es\genX*" -dir -NoRecurse -PassThru | Microsoft.PowerShell.Core\ForEach-Object FullName

        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.AI")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Console")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Data")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.FileSystem")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Helpers")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Queries")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Webbrowser")
        $results | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\..\Modules\GenXdev.Windows")
    }

    Pester\It 'Finds files by name pattern' {

        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\find-item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*.txt" -PassThru)
        $found.Count | Pester\Should -Be 3
    }

    Pester\It 'Finds files by content pattern' {
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*.txt" -Pattern 'test content' -PassThru)
        $found.Count | Pester\Should -Be 2
    }

    Pester\It 'Finds only directories when specified' {

        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found.Count | Pester\Should -Be 1
        $found | Pester\Should -Contain $testDir
    }

    Pester\It 'With backslash at the end, finds only undelaying directories, not itself' {

        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

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

        'testA123' > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        'testA567' > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        'testB890' > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

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

        'testA123' > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        'testA567' > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        'testB890' > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

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

        'testA123' > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        'testA567' > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        'testB890' > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

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

        'testA123' > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        'testA567' > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        'testB890' > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\fi*B*.txt" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found.Count | Pester\Should -Be 1
    }

    Pester\It 'Should match the pattern' {

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$PSScriptRoot\..\..\..\..\..\**\Genx*stem\1.250.2025\Functions\GenXdev.FileSystem\*.ps1" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\EnsurePester.ps1")
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

        # if this is failing right here, you added files to GenXdev.FileSystem, update the number accordingly
        $found.Count | Pester\Should -Be 14
    }

    Pester\It 'Should find files with certain symbols in the filename' {

        $path = "$testDir\this is a [test] file.txt"
        $null = GenXdev.FileSystem\Expand-Path $path -CreateDirectory -CreateFile
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain $path
        $found.Count | Pester\Should -Be 1
    }

    Pester\It 'Should only show ADS when IncludeAlternateFileStreams is specified' {
        # Create a file with an alternate data stream
        $testFile = "$testDir\test-ads.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile
        'Stream content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'test-stream'

        # Without the -IncludeAlternateFileStreams switch, only the base file should be returned
        $found1 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile)
        $found1.Count | Pester\Should -Be 1
        $found1[0] | Pester\Should -Be (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)

        # With the -IncludeAlternateFileStreams switch, both the base file and the stream should be returned
        $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -IncludeAlternateFileStreams)
        $found2.Count | Pester\Should -Be 2
        $found2[0] | Pester\Should -Be (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)
        $found2[1] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test-stream"
    }

    Pester\It 'Should find specific named streams when using streammask' {
        # Create a file with multiple alternate data streams
        $testFile = "$testDir\stream-test.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile
        'Stream1 content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'stream1'
        'Stream2 content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'stream2'
        'Zone content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'Zone.Identifier'

        # Test explicit stream search (no file, only matching stream)
        $found1 = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:stream1")
        $found1.Count | Pester\Should -Be 1
        $found1[0] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream1"

        # Test wildcard stream search
        $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:stream*")
        $found2.Count | Pester\Should -Be 2
        $found2 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream1"
        $found2 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream2"

        # Test colon at end means all streams (implicit wildcard)
        $found4 = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:")
        $found4.Count | Pester\Should -Be 4
        $found4 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative))::`$DATA"
        $found4 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream1"
        $found4 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream2"
        $found4 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):Zone.Identifier"
    }

    Pester\It 'Should filter streams with pattern matching' {
        # Create a file with multiple alternate data streams with different content
        $testFile = "$testDir\pattern-stream.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile
        'Content with password123' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'secret'
        'Content with no match' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'normal'

        # Test pattern matching within streams
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:*" -Pattern 'password\d+')
        $found.Count | Pester\Should -Be 1
        $found[0] | Pester\Should -Be '.\pattern-stream.txt:secret'

        # Verify no match returns empty
        $noMatch = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:*" -Pattern 'nonexistent')
        $noMatch.Count | Pester\Should -Be 0
    }

    Pester\It 'Should handle wildcards in file and stream patterns' {
        # Create multiple files with streams
        $testFile1 = "$testDir\wildcard1.dat"
        $testFile2 = "$testDir\wildcard2.dat"

        'File1 content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile1
        'File2 content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile2

        'Stream data 1' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile1 -Stream 'data'
        'Stream meta 1' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile1 -Stream 'meta'
        'Stream data 2' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile2 -Stream 'data'

        # Test wildcard file with specific stream
        $found1 = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\wildcard*.dat:data")
        $found1.Count | Pester\Should -Be 2
        $found1 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile1 -Relative)):data"
        $found1 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath  $testFile2 -Relative)):data"

        # Test wildcard file with wildcard stream
        $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\wildcard1*:m*")
        $found2.Count | Pester\Should -Be 1
        $found2[0] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile1 -Relative)):meta"
    }

    Pester\It 'Should correctly handle -ads flag vs explicit stream masks' {
        # Create a file with streams
        $testFile = "$testDir\ads-vs-mask.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File -FilePath $testFile
        'Stream content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'test1'
        'Another stream' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'test2'

        # Test: with -ads flag and no streammask, return file and all streams
        $found1 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -IncludeAlternateFileStreams)
        $found1.Count | Pester\Should -Be 3
        $found1 | Pester\Should -Contain (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)
        $found1 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test1"
        $found1 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test2"

        # Test: with streammask, only return matching streams (no file)
        $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:test*")
        $found2.Count | Pester\Should -Be 2
        $found2 | Pester\Should -Not -Contain (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)
        $found2 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test1"
        $found2 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test2"
    }

    Pester\It 'Should work with wildcard file paths and combined with stream masks' {
        # Create multiple files in subdirectories with streams
        $subDir = "$testDir\adstest"
        Microsoft.PowerShell.Management\New-Item -Path $subDir -ItemType Directory -Force | Microsoft.PowerShell.Core\Out-Null

        $file1 = "$subDir\file1.jpg"
        $file2 = "$subDir\file2.jpg"

        'File1' | Microsoft.PowerShell.Utility\Out-File -FilePath $file1
        'File2' | Microsoft.PowerShell.Utility\Out-File -FilePath $file2

        'Description 1' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $file1 -Stream 'description.json'
        'Description 2' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $file2 -Stream 'description.json'
        'Zone data' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $file1 -Stream 'Zone.Identifier'

        # Test: Find all description.json streams in all jpg files
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$subDir\*.jpg:description.json")
        $found.Count | Pester\Should -Be 2
        $found | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $file1 -Relative)):description.json"
        $found | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $file2 -Relative)):description.json"

        # Test: Combination of file wildcards, stream wildcards and content pattern
        'Metadata with secret key' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $file1 -Stream 'metadata'
        'Regular metadata' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $file2 -Stream 'metadata'

        $foundWithPattern = @(GenXdev.FileSystem\Find-Item -SearchMask "$subDir\*.jpg:metadata" -Pattern 'secret')
        $foundWithPattern.Count | Pester\Should -Be 1
        $foundWithPattern[0] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $file1 -Relative)):metadata"
    }
}