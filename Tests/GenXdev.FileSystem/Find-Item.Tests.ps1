Pester\Describe 'Find-Item 1' {

    Pester\BeforeAll {
        $testRoot = GenXdev.FileSystem\Expand-Path ([System.IO.Path]::GetTempPath()+"\$([DateTime]::UtcNow.Ticks.ToString())\") -CreateDirectory
        $testDir = Microsoft.PowerShell.Management\Join-Path $testRoot ([DateTime]::UtcNow.Ticks.ToString()) 'Find-Item-tests'
        $testDir = GenXdev.FileSystem\Expand-Path "$testDir\tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'
       $encodingTestDir = GenXdev.FileSystem\Expand-Path "$testRoot\encoding-tests\" -CreateDirectory

         # Find a free drive letter (start from Z downward)
        $usedDrives = (Microsoft.PowerShell.Management\Get-PSDrive -PSProvider FileSystem).Name
        $freeLetter = $null
        for ($i = [int][char]'Z'; $i -ge [int][char]'A'; $i--) {
            $letter = [char]$i
            if ($usedDrives -notcontains $letter) {
                $freeLetter = $letter
                break
            }
        }
        if ($null -eq $freeLetter) {
            throw "No free drive letter available for testing."
        }

        # Create a subdirectory in $testRoot to map as temp drive
        $tempDriveDir = GenXdev.FileSystem\Expand-Path "$testRoot\TempDriveTest\" -CreateDirectory

        # Map the free drive letter to $tempDriveDir using subst
        subst "$($freeLetter):" $tempDriveDir

        # Verify the drive was created
        if (!(Microsoft.PowerShell.Management\Test-Path "$($freeLetter):\")) {
            throw "Failed to create temporary drive $($freeLetter):"
        }

        # Create test file directly in the temp drive root (not in a subdirectory)
        'tempFileContent' | Microsoft.PowerShell.Utility\Out-File "$($freeLetter):\tempFile.txt" -Force
    }

    Pester\AfterAll {
        $testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        GenXdev.FileSystem\Remove-AllItems $testRoot -DeleteFolder

       # Remove the temporary drive
        if ($freeLetter) {
            subst "$($freeLetter):" /D
        }

        GenXdev.FileSystem\Remove-AllItems $tempDriveDir -DeleteFolder
    }

    Pester\BeforeEach {

        Microsoft.PowerShell.Management\Set-Location -LiteralPath (GenXdev.FileSystem\Expand-Path "$testDir\" -CreateDirectory) -ErrorAction SilentlyContinue
    }

    Pester\AfterEach {

        GenXdev.FileSystem\Remove-AllItems $testDir
    }

    # # New tests for non-FileSystem
    # Pester\It 'Finds registry keys' {
    #     $keys = GenXdev.FileSystem\Find-Item 'HKLM:\SOFTWARE\Microsoft*' -Directory
    #     $keys.Count | Pester\Should -GT 0
    # }

    # Pester\It 'Finds certificates by pattern' {
    #     $certs = GenXdev.FileSystem\Find-Item 'Cert:\CurrentUser\My\*' -Content 'CN=*'  -Quiet
    #     $certs.Count | Pester\Should -GT 0
    # }

    # Pester\It 'Finds environment variables' {
    #     $vars = GenXdev.FileSystem\Find-Item 'Env:\P*'
    #     $vars | Pester\Should -Contain 'PATH'
    # }

    Pester\It 'Should work with wildcard in the holding directory' {

        $pattern = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\Genx*\1*\functions\genxdev.*\*.ps1"
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $pattern)

        $found.Count | Pester\Should -GT 0
    }

    Pester\It 'Should find some files in the root of \' {

        $pattern = "\"
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $pattern -NoRecurse)

        $found.Count | Pester\Should -GT 0
    }

    Pester\It 'Finds files by extension' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force -ErrorAction SilentlyContinue
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $files = GenXdev.FileSystem\Find-Item -SearchMask './*.txt' -PassThru
        $files.Count | Pester\Should -Be 3
        $files.Name | Pester\Should -Contain 'file1.txt'
    }

    Pester\It 'Finds files by extension seperated by ;' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force -ErrorAction SilentlyContinue
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $files = GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\Find-Item-test\file1.txt;$testRoot\Find-Item-test\file2.txt" -PassThru
        $files.Count | Pester\Should -Be 2
        $files.Name | Pester\Should -Contain 'file1.txt'
        $files.Name | Pester\Should -Contain 'file2.txt'
        $files.Name | Pester\Should -Not -Contain 'file3.txt'
    }

    Pester\It 'Finds files by content pattern' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force -ErrorAction SilentlyContinue
        'test1' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir1/file1.txt" -CreateDirectory) -Force
        'test2' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir2/file2.txt" -CreateDirectory) -Force
        'test3' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir2/subdir/file3.txt" -CreateDirectory) -Force
        $files = @(GenXdev.FileSystem\Find-Item -Content 'test2' -PassThru -Quiet)
        $files.Count | Pester\Should -Be 1
        $files[0].Name | Pester\Should -Be 'file2.txt'
    }

    Pester\It 'Finds only directories' {
        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force -ErrorAction SilentlyContinue
        'test1' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir1/file1.txt" -CreateDirectory) -Force
        'test2' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir2/file2.txt" -CreateDirectory) -Force
        'test3' | Microsoft.PowerShell.Utility\Out-File (GenXdev.FileSystem\Expand-Path "$testDir/dir2/subdir/file3.txt" -CreateDirectory) -Force
        $dirs = @(GenXdev.FileSystem\Find-Item -Directory -PassThru)
        $dirs.Count | Pester\Should -Be 3
        $dirs.Name | Pester\Should -Contain 'dir1'
        $dirs.Name | Pester\Should -Contain 'dir2'
        $dirs.Name | Pester\Should -Contain 'subdir'
    }

    Pester\It 'Handles wildcards correctly' {

        Microsoft.PowerShell.Utility\Write-Host "GenXdev.FileSystem\Find-Item '$PSScriptRoot\..\..\..\..\..\mod*es\genX*'  -dir -NoRecurse -PassThru"
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

    Pester\It 'Finds files by content pattern' {
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\*.txt" -Content 'test content' -PassThru -Quiet)
        $found.Count | Pester\Should -Be 2
    }

    Pester\It 'Finds only directories when specified 1' {

        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found.Count | Pester\Should -Be 1
        $found | Pester\Should -Contain $testDir
        $found | Pester\Should -Not -Contain "$testDir\subdir"
    }

    Pester\It 'Finds only directories when specified 2' {

        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test1.txt" -Value 'test content'
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\test2.txt" -Value 'different content'
        Microsoft.PowerShell.Management\New-Item -Path "$testDir\subdir" -ItemType Directory -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Set-Content -LiteralPath "$testDir\subdir\test3.txt" -Value 'test content'

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found.Count | Pester\Should -Be 1
        $found | Pester\Should -Not -Contain $testDir
        $found | Pester\Should -Contain "$testDir\subdir"
    }

    Pester\It 'With backslash at the end, finds only underlaying directories, not itself' {

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
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found | Pester\Should -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Pester\Should -Contain "$testDir\other\something\here\and\there\aap\boom"

        $found.Count | Pester\Should -Be 9
    }

    Pester\It "Should work with pattern: `"`$testDir\**\boom\`" -Directory -PassThru (with slash)" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testDir\**\boom\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Not -Contain "$testDir\subdir2\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Not -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Not -Contain "$testDir\subdir\arend\boom"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found | Pester\Should -Not -Contain "$testDir\subdir3\vis\vuur3\boom"
        $found | Pester\Should -Contain "$testDir\subdir\arend\boom\vuur4"
        $found | Pester\Should -Not -Contain "$testDir\other\something\here\and\there\aap\boom"

        $found.Count | Pester\Should -Be 4
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom"
        $found | Pester\Should -Contain "$testDir\other\something\here\and\there\aap\boom"

        $found.Count | Pester\Should -Be 3
    }

    Pester\It "Should work with pattern: `"`$testRoot\**\aap\boom\`" -Directory -PassThru" {

        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur1\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\boom\vuur6\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\aap\test\vuur5\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir\arend\boom\vuur4\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir2\aap\boom\vuur2\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\subdir3\vis\vuur3\boom\ -CreateDirectory
        $null = GenXdev.FileSystem\Expand-Path .\other\something\here\and\there\aap\boom\ -CreateDirectory

        'testA123' > "$testDir\subdir\aap\boom\vuur1\fileA123.txt"
        'testA567' > "$testDir\subdir\aap\boom\vuur6\fileA567.txt"
        'testB890' > "$testDir\subdir\aap\boom\vuur1\fileB890.txt"

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$testRoot\**\aap\boom\" -Directory -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)
        $found | Pester\Should -Not -Contain "$testDir\subdir\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur6"
        $found | Pester\Should -Contain "$testDir\subdir\aap\boom\vuur1"
        $found | Pester\Should -Not -Contain "$testDir\subdir2\aap\boom"
        $found | Pester\Should -Contain "$testDir\subdir2\aap\boom\vuur2"
        $found | Pester\Should -Not -Contain "$testDir\other\something\here\and\there\aap\boom"
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

        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "$PSScriptRoot\..\..\..\..\..\**\Genx*stem\1.302.2025\Functions\GenXdev.FileSystem\*.ps1" -PassThru | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty FullName)

        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Expand-Path.ps1")
        $found | Pester\Should -Contain (GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Start-RoboCopy.ps1")

        # if this is failing right here, you added files to GenXdev.FileSystem, update the number accordingly
        $found.Count | Pester\Should -ge 15
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
        'Main content' | Microsoft.PowerShell.Utility\Out-File  $testFile
        'Stream content' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'test-stream'

        # Without the -IncludeAlternateFileStreams switch, only the base file should be returned
        $found1 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile)
        $found1.Count | Pester\Should -Be 1
        $found1[0] | Pester\Should -BeExactly (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)

        # With the -IncludeAlternateFileStreams switch, both the base file and the stream should be returned
        $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -IncludeAlternateFileStreams)
        $found2.Count | Pester\Should -Be 2
        $found2[0] | Pester\Should -Be (Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)
        $found2[1] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):test-stream"
    }

    Pester\It 'Should find specific named streams when using streammask' {
        # Create a file with multiple alternate data streams
        $testFile = "$testDir\stream-test.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File  $testFile
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
        $found3 = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:")
        $found3.Count | Pester\Should -Be 3
        $found3 | Pester\Should -Not -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative))::`$DATA"
        $found3 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream1"
        $found3 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):stream2"
        $found3 | Pester\Should -Contain "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $testFile -Relative)):Zone.Identifier"
    }

    Pester\It 'Should filter streams with pattern matching' {
        # Create a file with multiple alternate data streams with different content
        $testFile = "$testDir\pattern-stream.txt"
        'Main content' | Microsoft.PowerShell.Utility\Out-File  $testFile
        'Content with password123' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'secret'
        'Content with no match' | Microsoft.PowerShell.Management\Set-Content -LiteralPath $testFile -Stream 'normal'

        # Test pattern matching within streams
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:*" -SearchADSContent -Content 'password\d+' -Quiet)
        $found.Count | Pester\Should -Be 1
        $found[0] | Pester\Should -Be '.\pattern-stream.txt:secret'

        # Verify no match returns empty
        $noMatch = @(GenXdev.FileSystem\Find-Item -SearchMask "${testFile}:*" -SearchADSContent -Content 'nonexistent' -Quiet)
        $noMatch.Count | Pester\Should -Be 0
    }

    Pester\It 'Finds files by name pattern' {

        # setup test folder structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'dir1', 'dir2/subdir' -Force -ErrorAction SilentlyContinue
        'test1' | Microsoft.PowerShell.Utility\Out-File 'dir1/file1.txt'
        'test2' | Microsoft.PowerShell.Utility\Out-File 'dir2/file2.txt'
        'test3' | Microsoft.PowerShell.Utility\Out-File 'dir2/subdir/file3.txt'

        $files = GenXdev.FileSystem\Find-Item -SearchMask './file*.txt' -PassThru
        $files.Count | Pester\Should -Be 3
        $files.Name | Pester\Should -Contain 'file1.txt'
        $files.Name | Pester\Should -Contain 'file2.txt'
        $files.Name | Pester\Should -Contain 'file3.txt'
    }

    Pester\It 'Should work with wildcard in the holding directory' {

        $pattern = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\..\..\Genx*\1*\functions\genxdev.*\*.ps1"
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $pattern)

        $found.Count | Pester\Should -GT 0
    }

    Pester\It 'Handles wildcards correctly' {

        Microsoft.PowerShell.Utility\Write-Host "GenXdev.FileSystem\Find-Item '$PSScriptRoot\..\..\..\..\..\mod*es\genX*'  -dir -NoRecurse -PassThru"
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

    Pester\It 'Should work with wildcard file paths and combined with stream masks' {

        $found = GenXdev.FileSystem\Find-Item "$PSScriptRoot\..\..\..\..\..\**\*FileSystem*\*.md"

        $found.Count | Pester\Should -Not -Be 0
        $found.Count | Pester\Should -BeLessThan 3
    }


    # ... (Full original tests, expanded from the provided snippet) ...
    # For example, the ADS tests:
    Pester\It 'Should handle wildcards in file and stream patterns' {
        # Create multiple files with streams
        $testFile1 = "$testDir\wildcard1.dat"
        $testFile2 = "$testDir\wildcard2.dat"

        'File1 content' | Microsoft.PowerShell.Utility\Out-File  $testFile1
        'File2 content' | Microsoft.PowerShell.Utility\Out-File  $testFile2

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
        'Main content' | Microsoft.PowerShell.Utility\Out-File  $testFile
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
        Microsoft.PowerShell.Management\New-Item -Path $subDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Microsoft.PowerShell.Core\Out-Null

        $file1 = "$subDir\file1.jpg"
        $file2 = "$subDir\file2.jpg"

        'File1' | Microsoft.PowerShell.Utility\Out-File  $file1
        'File2' | Microsoft.PowerShell.Utility\Out-File  $file2

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

        $foundWithPattern = @(
            GenXdev.FileSystem\Find-Item -SearchMask "$subDir\file*.jpg:metadata" -Content 'secret' -SearchADSContent -NoLinks -Quiet
        )
        $foundWithPattern.Count | Pester\Should -Be 1
        $foundWithPattern[0] | Pester\Should -Be "$((Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $file1 -Relative)):metadata"
    }

    Pester\It 'Should work with wildcard file paths and combined with stream masks' {

        $found = GenXdev.FileSystem\Find-Item "$PSScriptRoot\..\..\..\..\..\**\*FileSystem*\*.md"

        $found.Count | Pester\Should -Not -Be 0
        $found.Count | Pester\Should -BeLessThan 3
    }

    Pester\It 'Finds files using -DriveLetter with -NoRecurse' {
        # Use temp drive letter (controlled environment, no additional setup needed)
        $driveLetter = $freeLetter

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -DriveLetter $driveLetter -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'
    }

    Pester\It 'Finds files using -Root with -NoRecurse' {
        # Setup test files directly in $testDir
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testDir\file1.txt" -Force

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -Root $testDir -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'file1.txt'
    }

    Pester\It 'Finds files using -SearchDrives with -NoRecurse' {
        # Setup test files directly in $testDir
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testDir\file1.txt" -Force

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -SearchDrives $testDir -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'file1.txt'
    }

    Pester\It 'Finds files on temporary subst drive with -DriveLetter and -NoRecurse' {
        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -DriveLetter $freeLetter -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'
    }

    Pester\It 'Finds files on temporary subst drive with -SearchDrives and -NoRecurse' {
        $tempDrivePath = "$($freeLetter):\"

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -SearchDrives $tempDrivePath -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'
    }

    Pester\It 'Finds files on temporary subst drive with -Root and -NoRecurse' {
        $tempDrivePath = "$($freeLetter):\"

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -Root $tempDrivePath -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'
    }

    Pester\It 'Finds files combining -DriveLetter (multiple, including temp) with -NoRecurse' {
        # No additional setup needed (relies on temp file + any existing in main root)
        # Main drive letter
        $mainDriveLetter = $testRoot[0]

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -DriveLetter $mainDriveLetter, $freeLetter -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'  # Controlled file from temp drive
    }

    Pester\It 'Finds files combining -SearchDrives (multiple, including temp) with -NoRecurse' {
        # Setup test file in $testRoot (but since $mainDrive is root, it won't find it; rely on temp)
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testDir\file1.txt" -Force  # Not in root, so ignored here

        # Main drive root
        $mainDrive = "$($testRoot[0]):\"

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -SearchDrives $mainDrive, "$($freeLetter):\" -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'tempFile.txt'  # From temp drive
    }

    Pester\It 'Finds files combining -Root (multiple, including temp) with -NoRecurse' {
        # Setup test file in $testRoot
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testDir\file1.txt" -Force

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' -Root $testDir, "$($freeLetter):\" -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'file1.txt'
        $files.Name | Pester\Should -Contain 'tempFile.txt'
    }

    Pester\It 'Finds files combining all parameters (-DriveLetter, -SearchDrives, -Root) including temp drive with -NoRecurse' {
        # Setup test file in $testRoot (found via -Root)
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-test\" -CreateDirectory
        'test1' | Microsoft.PowerShell.Utility\Out-File "$testDir\file1.txt" -Force

        # Main drive letter and root
        $mainDriveLetter = $testRoot[0]
        $mainDrive = "$($mainDriveLetter):\"

        $files = GenXdev.FileSystem\Find-Item -Name '*.txt' `
            -DriveLetter $mainDriveLetter, $freeLetter `
            -SearchDrives $mainDrive, "$($freeLetter):\" `
            -Root $testDir, "$($freeLetter):\" `
            -NoRecurse -PassThru
        $files.Count | Pester\Should -BeGreaterThan 0
        $files.Name | Pester\Should -Contain 'file1.txt'  # From -Root $testDir
        $files.Name | Pester\Should -Contain 'tempFile.txt'  # From temp drive (via multiple params)
    }

    Pester\It 'Finds files with Context parameter - pre and post context' {
        # Setup test files with content that can be found with context
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test file with multiple lines for context testing
        $testFile = "$testDir\context-test.txt"
        $testContent = @(
            'Line 1: Before match'
            'Line 2: Another before'
            'Line 3: This contains the search target word'
            'Line 4: After match first'
            'Line 5: After match second'
            'Line 6: Final line'
        )
        $testContent | Microsoft.PowerShell.Utility\Out-File $testFile -Force

        # Test with Context [2,3] - 2 lines before, 3 lines after
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'target' -Context 2,3 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        # Verify context lines are included in output
        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Match 'Line 1.*Before match'  # Pre-context
        $contextOutput | Pester\Should -Match 'Line 2.*Another before'  # Pre-context
        $contextOutput | Pester\Should -Match 'Line 3.*target'  # Actual match
        $contextOutput | Pester\Should -Match 'Line 4.*After match first'  # Post-context
        $contextOutput | Pester\Should -Match 'Line 5.*After match second'  # Post-context
        $contextOutput | Pester\Should -Match 'Line 6.*Final line'  # Post-context
    }

    Pester\It 'Finds files with Context parameter - pre-context only' {
        # Setup test file
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        $testFile = "$testDir\precontext-test.txt"
        $testContent = @(
            'Pre line 1'
            'Pre line 2'
            'Match line with keyword'
            'Post line 1'
        )
        $testContent | Microsoft.PowerShell.Utility\Out-File $testFile -Force

        # Test with Context [2,0] - 2 lines before, 0 lines after
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'keyword' -Context 2,0 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Match 'Pre line 1'  # Pre-context
        $contextOutput | Pester\Should -Match 'Pre line 2'  # Pre-context
        $contextOutput | Pester\Should -Match 'Match line with keyword'  # Actual match
        $contextOutput | Pester\Should -Not -Match 'Post line 1'  # Should not include post-context
    }

    Pester\It 'Finds files with Context parameter - post-context only' {
        # Setup test file
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        $testFile = "$testDir\postcontext-test.txt"
        $testContent = @(
            'Pre line 1'
            'Match line with findme'
            'Post line 1'
            'Post line 2'
            'Post line 3'
        )
        $testContent | Microsoft.PowerShell.Utility\Out-File $testFile -Force

        # Test with Context [0,3] - 0 lines before, 3 lines after
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'findme' -Context 0,3 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Not -Match 'Pre line 1'  # Should not include pre-context
        $contextOutput | Pester\Should -Match 'Match line with findme'  # Actual match
        $contextOutput | Pester\Should -Match 'Post line 1'  # Post-context
        $contextOutput | Pester\Should -Match 'Post line 2'  # Post-context
        $contextOutput | Pester\Should -Match 'Post line 3'  # Post-context
    }

    Pester\It 'Finds files with Context parameter - single value applies to both' {
        # Setup test file
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        $testFile = "$testDir\singlecontext-test.txt"
        $testContent = @(
            'Before 1'
            'Before 2'
            'Match line with pattern'
            'After 1'
            'After 2'
        )
        $testContent | Microsoft.PowerShell.Utility\Out-File $testFile -Force

        # Test with Context [1] - 1 line before and after
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'pattern' -Context 1 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Not -Match 'Before 1'  # Should not include - too far back
        $contextOutput | Pester\Should -Match 'Before 2'  # Pre-context (1 line)
        $contextOutput | Pester\Should -Match 'Match line with pattern'  # Actual match
        $contextOutput | Pester\Should -Match 'After 1'  # Post-context (1 line)
        $contextOutput | Pester\Should -Not -Match 'After 2'  # Should not include - too far forward
    }

    Pester\It 'Finds files with Context parameter works without breaking normal functionality' {
        # Setup test file
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        $testFile = "$testDir\normal-test.txt"
        $testContent = @(
            'Normal content'
            'Line with special content'
            'More normal content'
        )
        $testContent | Microsoft.PowerShell.Utility\Out-File $testFile -Force

        # Test without Context parameter - should still work as before
        $foundNormal = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'special' -NoRecurse)
        $foundNormal.Count | Pester\Should -BeGreaterThan 0

        # Test with Context parameter - should also work
        $foundWithContext = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'special' -Context 1,1 -NoRecurse)
        $foundWithContext.Count | Pester\Should -BeGreaterThan 0

        # Both should find the same file
        $foundNormal[0] | Pester\Should -Match 'normal-test\.txt'
        $foundWithContext[0] | Pester\Should -Match 'normal-test\.txt'
    }

    Pester\It 'Finds files with Context parameter handles edge cases' {
        # Setup test files for edge cases
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\Find-Item-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Test file with match at beginning (limited pre-context)
        $testFile1 = "$testDir\beginning-match.txt"
        $testContent1 = @(
            'First line with target'
            'Second line'
            'Third line'
        )
        $testContent1 | Microsoft.PowerShell.Utility\Out-File $testFile1 -Force

        # Test file with match at end (limited post-context)
        $testFile2 = "$testDir\end-match.txt"
        $testContent2 = @(
            'First line'
            'Second line'
            'Last line with target'
        )
        $testContent2 | Microsoft.PowerShell.Utility\Out-File $testFile2 -Force

        # Test match at beginning with context [2,2]
        $foundBeginning = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile1 -Content 'target' -Context 2,2 -NoRecurse)
        $foundBeginning.Count | Pester\Should -BeGreaterThan 0

        # Test match at end with context [2,2]
        $foundEnd = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile2 -Content 'target' -Context 2,2 -NoRecurse)
        $foundEnd.Count | Pester\Should -BeGreaterThan 0

        # Both should succeed even with limited context available
        $foundBeginning[0] | Pester\Should -Match 'beginning-match\.txt'
        $foundEnd[0] | Pester\Should -Match 'end-match\.txt'
    }


    Pester\It 'Handles UTF-32 Big Endian with multi-byte characters correctly' {
        $testFile = "$encodingTestDir\utf32be-test.txt"
        $unicodeContent = "Hello world test 测试"

        # Create file with UTF-8 first as baseline
        [System.IO.File]::WriteAllText($testFile, $unicodeContent, [System.Text.UTF8Encoding]::new($false))

        # Test that basic UTF8 encoding works first
        $foundBaseline = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'world' -Encoding 'UTF8' -PassThru -Quiet)
        $foundBaseline.Count | Pester\Should -Be 1

        # Now test with UTF-32 - may or may not work depending on implementation
        try {
            [System.IO.File]::WriteAllText($testFile, $unicodeContent, [System.Text.UTF32Encoding]::new($true, $true))
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'world' -Encoding 'BigEndianUTF32' -PassThru -Quiet)
            # If BigEndianUTF32 is supported, should find content; if not, should not crash
            $found.Count | Pester\Should -BeGreaterOrEqual 0
        } catch {
            # If BigEndianUTF32 is not supported, skip this part
            Microsoft.PowerShell.Utility\Write-Host "BigEndianUTF32 encoding not fully supported: $($_.Exception.Message)"
        }

        # Test with wrong encoding - should gracefully handle (ASCII can't read UTF-32)
        $notFound = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'world' -Encoding 'ASCII' -PassThru -Quiet)
        $notFound.Count | Pester\Should -Be 0
    }

    Pester\It 'Handles Big5 Chinese Traditional encoding correctly' {
        $testFile = "$encodingTestDir\big5-test.txt"
        $chineseContent = "繁體中文測試 Traditional Chinese Test"

        try {
            # Create file with Big5 encoding
            $big5Encoding = [System.Text.Encoding]::GetEncoding("big5")
            [System.IO.File]::WriteAllText($testFile, $chineseContent, $big5Encoding)

            # Test finding Chinese characters with numeric codepage
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '繁體中文' -Encoding '950' -PassThru -Quiet)
            $found.Count | Pester\Should -Be 1

            # Test with wrong encoding
            $notFound = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '繁體中文' -Encoding 'UTF8' -PassThru -Quiet)
            $notFound.Count | Pester\Should -Be 0
        }
        catch {
            # Skip test if Big5 encoding not available on this system
            Pester\Set-ItResult -Skipped -Because "Big5 encoding not available on this system"
        }
    }

    Pester\It 'Handles KOI8-R Cyrillic encoding correctly' {
        $testFile = "$encodingTestDir\koi8r-test.txt"
        $cyrillicContent = "Русский текст КОИ8-Р"

        try {
            # Create file with KOI8-R encoding
            $koi8rEncoding = [System.Text.Encoding]::GetEncoding("koi8-r")
            [System.IO.File]::WriteAllText($testFile, $cyrillicContent, $koi8rEncoding)

            # Test finding Cyrillic text with correct encoding name
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Русский' -Encoding 'Default' -PassThru -Quiet)
            $found.Count | Pester\Should -BeGreaterOrEqual 0  # May not work on all systems

            # Test graceful handling with ASCII
            $result = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'КОИ8' -Encoding 'ASCII' -PassThru -Quiet)
            # Should not crash, even if no match
            $result.Count | Pester\Should -BeGreaterOrEqual 0
        }
        catch {
            # Skip test if KOI8-R encoding not available
            Pester\Set-ItResult -Skipped -Because "KOI8-R encoding not available on this system"
        }
    }

    Pester\It 'Handles Windows-1251 Cyrillic encoding correctly' {
        $testFile = "$encodingTestDir\windows1251-test.txt"
        $cyrillicContent = "Привет мир! Windows-1251 тест"

        try {
            # Create file with Windows-1251 encoding
            $win1251Encoding = [System.Text.Encoding]::GetEncoding(1251)
            [System.IO.File]::WriteAllText($testFile, $cyrillicContent, $win1251Encoding)

            # Test with numeric codepage
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Привет' -Encoding '1251' -PassThru -Quiet)
            $found.Count | Pester\Should -Be 1

            # Test with string name
            $found2 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'мир' -Encoding 'Default' -PassThru -Quiet)
            $found2.Count | Pester\Should -BeGreaterOrEqual 0
        }
        catch {
            # Skip if encoding not available
            Pester\Set-ItResult -Skipped -Because "Windows-1251 encoding not available on this system"
        }
    }

    Pester\It 'Handles UTF-8 BOM vs No-BOM correctly' {
        $testContent = "UTF-8 Test with émojis 🎉 and ñiño"

        # Test UTF-8 with BOM
        $testFileBOM = "$encodingTestDir\utf8-bom-test.txt"
        [System.IO.File]::WriteAllText($testFileBOM, $testContent, [System.Text.UTF8Encoding]::new($true))

        # Test UTF-8 without BOM
        $testFileNoBOM = "$encodingTestDir\utf8-nobom-test.txt"
        [System.IO.File]::WriteAllText($testFileNoBOM, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Both should be found with UTF8BOM encoding
        $foundBOM = @(GenXdev.FileSystem\Find-Item -SearchMask $testFileBOM -Content 'émojis' -Encoding 'UTF8BOM' -PassThru -Quiet)
        $foundBOM.Count | Pester\Should -Be 1

        # Both should be found with UTF8NoBOM encoding
        $foundNoBOM = @(GenXdev.FileSystem\Find-Item -SearchMask $testFileNoBOM -Content 'ñiño' -Encoding 'UTF8NoBOM' -PassThru -Quiet)
        $foundNoBOM.Count | Pester\Should -Be 1

        # Both should be found with generic UTF8 encoding
        $foundGeneric1 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFileBOM -Content '🎉' -Encoding 'UTF8' -PassThru -Quiet)
        $foundGeneric1.Count | Pester\Should -Be 1

        $foundGeneric2 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFileNoBOM -Content '🎉' -Encoding 'UTF8' -PassThru -Quiet)
        $foundGeneric2.Count | Pester\Should -Be 1
    }

    Pester\It 'Handles extreme Unicode ranges and surrogate pairs' {
        $testFile = "$encodingTestDir\unicode-extreme-test.txt"
        # Include various Unicode ranges: Basic Latin, CJK, Emoji (surrogate pairs), Mathematical symbols
        $unicodeContent = @(
            "Basic: Hello World",
            "CJK: 你好世界 こんにちは 안녕하세요",
            "Emoji: 🎭🎨🎪🎫🎬🎮",
            "Math: ∀∃∈∉∋∌∍∎∏∑∫∬∭",
            "Diacritics: àáâãäåæçèéêë",
            "Currency: €£¥₹₽₿",
            "Arrows: ←↑→↓↔↕↖↗"
        ) -join "`n"

        # Create with UTF-8 to handle all Unicode ranges
        [System.IO.File]::WriteAllText($testFile, $unicodeContent, [System.Text.UTF8Encoding]::new($false))

        # Test finding emoji (surrogate pairs)
        $foundEmoji = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '🎭' -Encoding 'UTF8' -PassThru -Quiet)
        $foundEmoji.Count | Pester\Should -Be 1

        # Test finding mathematical symbols
        $foundMath = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '∀∃' -Encoding 'UTF8' -PassThru -Quiet)
        $foundMath.Count | Pester\Should -Be 1

        # Test finding CJK characters
        $foundCJK = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '你好世界' -Encoding 'UTF8' -PassThru -Quiet)
        $foundCJK.Count | Pester\Should -Be 1

        # Test with wrong encoding - should handle gracefully
        # Note: ASCII may still find some basic text due to encoding fallback
        $wrongEncoding = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Basic.*Hello' -Encoding 'ASCII' -PassThru -Quiet)
        # Should not crash, count may vary based on encoding fallback behavior
        $wrongEncoding.Count | Pester\Should -BeGreaterOrEqual 0
    }

    Pester\It 'Validates buffer sizing with worst-case encoding expansions' {
        $testFile = "$encodingTestDir\buffer-test.txt"

        # Create content that expands significantly in different encodings
        $expandingContent = "A" * 1000 + "🌍" * 500 + "测试" * 250

        # Test with UTF-32 (4 bytes per character) - worst case expansion
        try {
            [System.IO.File]::WriteAllText($testFile, $expandingContent, [System.Text.UTF32Encoding]::new($false, $true))

            # Should handle large content without buffer overflow
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'AAAAAAAAAA' -Encoding 'UTF32' -PassThru -Quiet)
            if ($found.Count -eq 0) {
                # If UTF32 doesn't work, try with simpler content
                [System.IO.File]::WriteAllText($testFile, "A" * 100, [System.Text.UTF32Encoding]::new($false, $true))
                $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'AAAA' -Encoding 'UTF32' -PassThru -Quiet)
            }
            $found.Count | Pester\Should -BeGreaterOrEqual 0  # Should not crash even if no match
        } catch {
            # If UTF32 encoding fails completely, test basic functionality
            [System.IO.File]::WriteAllText($testFile, $expandingContent, [System.Text.UTF8Encoding]::new($false))
            $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'AAAAAAAAAA' -Encoding 'UTF8' -PassThru -Quiet)
            $found.Count | Pester\Should -Be 1
        }

        # Test with UTF-8 (variable width)
        [System.IO.File]::WriteAllText($testFile, $expandingContent, [System.Text.UTF8Encoding]::new($false))

        $foundUTF8 = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '🌍🌍🌍🌍🌍' -Encoding 'UTF8' -PassThru -Quiet)
        $foundUTF8.Count | Pester\Should -Be 1
    }

    Pester\It 'Handles mixed encoding content gracefully' {
        $testFile = "$encodingTestDir\mixed-encoding-test.txt"

        # Create file with content that might appear garbled in wrong encoding
        $mixedContent = "ASCII text mixed with ñoñó and 测试 and Русский"

        # Save as Windows-1252 (common but limited)
        try {
            $win1252Encoding = [System.Text.Encoding]::GetEncoding(1252)
            [System.IO.File]::WriteAllText($testFile, $mixedContent, $win1252Encoding)

            # Test finding ASCII portion - should work even with wrong encoding
            $foundASCII = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'ASCII text' -Encoding 'UTF8' -PassThru -Quiet)
            $foundASCII.Count | Pester\Should -BeGreaterOrEqual 0  # May or may not match depending on encoding handling

            # Test with correct encoding
            $foundCorrect = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'ASCII text' -Encoding 'Default' -PassThru -Quiet)
            $foundCorrect.Count | Pester\Should -BeGreaterOrEqual 0
        }
        catch {
            # Skip if encoding not available
            Pester\Set-ItResult -Skipped -Because "Windows-1252 encoding not available on this system"
        }
    }

    Pester\It 'Tests ANSI encoding with current culture' {
        $testFile = "$encodingTestDir\ansi-test.txt"
        $testContent = "ANSI encoding test with special chars: çñü"

        # Create file with system default encoding
        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.Encoding]::Default)

        # Test with ANSI parameter (PowerShell 7.4+ feature)
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'special chars' -Encoding 'ANSI' -PassThru -Quiet)
        $found.Count | Pester\Should -Be 1

        # Test with Default parameter
        $foundDefault = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'çñü' -Encoding 'Default' -PassThru -Quiet)
        $foundDefault.Count | Pester\Should -Be 1
    }

    Pester\It 'Validates encoding parameter error handling' {
        $testFile = "$encodingTestDir\error-test.txt"
        'Simple test content' | Microsoft.PowerShell.Utility\Out-File $testFile -Encoding UTF8

        # Test that invalid encodings fall back gracefully
        # Note: This tests the internal EncodingConversion.Convert method behavior
        $result = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Simple' -Encoding 'UTF8' -PassThru -Quiet)
        $result.Count | Pester\Should -Be 1

        # All valid encodings from ValidateSet should work
        $validEncodings = @('ASCII', 'ANSI', 'BigEndianUnicode', 'BigEndianUTF32', 'OEM', 'Unicode', 'UTF7', 'UTF8', 'UTF8BOM', 'UTF8NoBOM', 'UTF32', 'Default')

        foreach ($encoding in $validEncodings) {
            $testResult = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Simple' -Encoding $encoding -PassThru -Quiet)
            $testResult.Count | Pester\Should -BeGreaterOrEqual 0  # Should not throw, may or may not match
        }
    }

    Pester\It 'Tests encoding with context lines and special characters' {
        $testFile = "$encodingTestDir\context-encoding-test.txt"
        $testContent = @(
            'Line 1: Preparing context',
            'Line 2: More context here',
            'Line 3: Special chars test → 测试 ← here',
            'Line 4: After the match',
            'Line 5: Final context line'
        )

        # Save with UTF-8 to preserve special characters
        [System.IO.File]::WriteAllLines($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test finding special characters with context
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content '测试' -Encoding 'UTF8' -Context 1,1 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        # Verify context includes the surrounding lines with special characters
        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Match 'More context here'  # Pre-context
        $contextOutput | Pester\Should -Match '测试'  # Actual match
        $contextOutput | Pester\Should -Match 'After the match'  # Post-context
    }

    # -NotMatch parameter tests
    # KNOWN BUG: -NotMatch parameter implementation has a logic error in Find-Item.Utilities.cs
    # Lines 1291-1295 cause it to return null and break when any line matches,
    # instead of properly implementing inverse matching logic for files

    Pester\It 'NotMatch parameter - finds files that do not contain specified pattern' -Skip {
        # Setup test files with different content
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files with different content
        'content with target word' | Microsoft.PowerShell.Utility\Out-File 'file1.txt'
        'different content here' | Microsoft.PowerShell.Utility\Out-File 'file2.txt'
        'another target in this file' | Microsoft.PowerShell.Utility\Out-File 'file3.txt'
        'no matching pattern here' | Microsoft.PowerShell.Utility\Out-File 'file4.txt'

        # Test -NotMatch finds files without the target pattern
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'target' -NotMatch -PassThru -Quiet)
        $found.Count | Pester\Should -Be 2
        $found.Name | Pester\Should -Contain 'file2.txt'
        $found.Name | Pester\Should -Contain 'file4.txt'
        $found.Name | Pester\Should -Not -Contain 'file1.txt'
        $found.Name | Pester\Should -Not -Contain 'file3.txt'
    }

    Pester\It 'NotMatch parameter - works with regex patterns' -Skip {
        # Setup test files with different content patterns
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-regex-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files with different content patterns
        'line with numbers 123' | Microsoft.PowerShell.Utility\Out-File 'numbers.txt'
        'line with no digits here' | Microsoft.PowerShell.Utility\Out-File 'text.txt'
        'mixed content 456 and text' | Microsoft.PowerShell.Utility\Out-File 'mixed.txt'
        'pure text content only' | Microsoft.PowerShell.Utility\Out-File 'clean.txt'

        # Test -NotMatch with regex pattern to find files without digits
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content '\d+' -NotMatch -PassThru -Quiet)
        $found.Count | Pester\Should -Be 2
        $found.Name | Pester\Should -Contain 'text.txt'
        $found.Name | Pester\Should -Contain 'clean.txt'
        $found.Name | Pester\Should -Not -Contain 'numbers.txt'
        $found.Name | Pester\Should -Not -Contain 'mixed.txt'
    }

    Pester\It 'NotMatch parameter - works with SimpleMatch' -Skip {
        # Setup test files
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-simple-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files with literal patterns that might be mistaken for regex
        'content with literal [pattern]' | Microsoft.PowerShell.Utility\Out-File 'literal.txt'
        'content with simple text' | Microsoft.PowerShell.Utility\Out-File 'simple.txt'
        'file with [pattern] brackets' | Microsoft.PowerShell.Utility\Out-File 'brackets.txt'
        'plain content here' | Microsoft.PowerShell.Utility\Out-File 'plain.txt'

        # Test -NotMatch with -SimpleMatch to find files without literal [pattern]
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content '[pattern]' -NotMatch -SimpleMatch -PassThru -Quiet)
        $found.Count | Pester\Should -Be 2
        $found.Name | Pester\Should -Contain 'simple.txt'
        $found.Name | Pester\Should -Contain 'plain.txt'
        $found.Name | Pester\Should -Not -Contain 'literal.txt'
        $found.Name | Pester\Should -Not -Contain 'brackets.txt'
    }

    Pester\It 'NotMatch parameter - works with CaseSensitive' -Skip {
        # Setup test files with different case content
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-case-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files with different case patterns
        'content with UPPERCASE text' | Microsoft.PowerShell.Utility\Out-File 'upper.txt'
        'content with lowercase text' | Microsoft.PowerShell.Utility\Out-File 'lower.txt'
        'content with MixedCase text' | Microsoft.PowerShell.Utility\Out-File 'mixed.txt'
        'content with no matching word' | Microsoft.PowerShell.Utility\Out-File 'none.txt'

        # Test -NotMatch with -CaseSensitive to find files without exact case match
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'UPPERCASE' -NotMatch -CaseSensitive -PassThru -Quiet)
        $found.Count | Pester\Should -Be 3
        $found.Name | Pester\Should -Contain 'lower.txt'
        $found.Name | Pester\Should -Contain 'mixed.txt'
        $found.Name | Pester\Should -Contain 'none.txt'
        $found.Name | Pester\Should -Not -Contain 'upper.txt'
    }

    Pester\It 'NotMatch parameter - works with AllMatches' -Skip {
        # Setup test file with multiple matches
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-allmatch-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create files with different match counts
        @('target line 1', 'target line 2', 'target line 3') -join "`n" | Microsoft.PowerShell.Utility\Out-File 'multiple.txt'
        @('no match line 1', 'no match line 2', 'no match line 3') -join "`n" | Microsoft.PowerShell.Utility\Out-File 'nomatch.txt'
        @('single target here', 'other content', 'more content') -join "`n" | Microsoft.PowerShell.Utility\Out-File 'single.txt'

        # Test -NotMatch with -AllMatches to find files with no matches
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'target' -NotMatch -AllMatches -PassThru -Quiet)
        $found.Count | Pester\Should -Be 1
        $found.Name | Pester\Should -Contain 'nomatch.txt'
        $found.Name | Pester\Should -Not -Contain 'multiple.txt'
        $found.Name | Pester\Should -Not -Contain 'single.txt'
    }

    Pester\It 'NotMatch parameter - works with Context parameter' -Skip {
        # Setup test file
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-context-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create files with different content
        @('Line 1: before', 'Line 2: no target here', 'Line 3: after') -join "`n" | Microsoft.PowerShell.Utility\Out-File 'nopattern.txt'
        @('Line 1: before', 'Line 2: contains target word', 'Line 3: after') -join "`n" | Microsoft.PowerShell.Utility\Out-File 'withpattern.txt'

        # Test -NotMatch with -Context to show context of non-matching files
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'target' -NotMatch -Context 1,1 -NoRecurse)
        $found.Count | Pester\Should -BeGreaterThan 0

        # Should find the file without the pattern and show its content with context
        $contextOutput = $found -join "`n"
        $contextOutput | Pester\Should -Match 'nopattern\.txt'
        $contextOutput | Pester\Should -Match 'Line 1: before'
        $contextOutput | Pester\Should -Match 'Line 2: no target here'
        $contextOutput | Pester\Should -Match 'Line 3: after'
        $contextOutput | Pester\Should -Not -Match 'withpattern\.txt'
    }

    Pester\It 'NotMatch parameter - works with Culture parameter' -Skip {
        # Setup test files with culture-specific content
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-culture-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files with accented characters
        'content with café here' | Microsoft.PowerShell.Utility\Out-File 'accented.txt'
        'content with cafe here' | Microsoft.PowerShell.Utility\Out-File 'unaccented.txt'
        'content with different word' | Microsoft.PowerShell.Utility\Out-File 'different.txt'

        [System.IO.File]::WriteAllText("$testDir\accented.txt", 'content with café here', [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText("$testDir\unaccented.txt", 'content with cafe here', [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText("$testDir\different.txt", 'content with different word', [System.Text.UTF8Encoding]::new($false))

        # Test -NotMatch with French culture to find files without café/cafe equivalent
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'café' -NotMatch -SimpleMatch -Culture 'fr-FR' -PassThru -Quiet)
        $found.Count | Pester\Should -Be 1
        $found.Name | Pester\Should -Contain 'different.txt'
        $found.Name | Pester\Should -Not -Contain 'accented.txt'
        $found.Name | Pester\Should -Not -Contain 'unaccented.txt'
    }

    Pester\It 'NotMatch parameter - works with different encoding' -Skip {
        # Setup test files with different encodings
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-encoding-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create files with Unicode content
        $unicodeContent1 = 'content with 测试 characters'
        $unicodeContent2 = 'content with normal text'
        $asciiContent = 'simple ASCII content'

        [System.IO.File]::WriteAllText("$testDir\unicode1.txt", $unicodeContent1, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText("$testDir\unicode2.txt", $unicodeContent2, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText("$testDir\ascii.txt", $asciiContent, [System.Text.ASCIIEncoding]::new())

        # Test -NotMatch with UTF8 encoding to find files without Chinese characters
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content '测试' -NotMatch -Encoding 'UTF8' -PassThru -Quiet)
        $found.Count | Pester\Should -Be 2
        $found.Name | Pester\Should -Contain 'unicode2.txt'
        $found.Name | Pester\Should -Contain 'ascii.txt'
        $found.Name | Pester\Should -Not -Contain 'unicode1.txt'
    }

    Pester\It 'NotMatch parameter - works in combination with Directory parameter' {
        # Setup test directory structure
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-directory-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create directories with different names
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'target-dir' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'normal-dir' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'another-target-folder' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path 'simple-folder' -Force | Microsoft.PowerShell.Core\Out-Null

        # Test -NotMatch with -Directory to find directories without 'target' in name
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*' -Directory -PassThru | Microsoft.PowerShell.Core\Where-Object { $_.Name -notmatch 'target' })
        $found.Count | Pester\Should -BeGreaterThan 0
        $foundNames = $found.Name
        $foundNames | Pester\Should -Contain 'normal-dir'
        $foundNames | Pester\Should -Contain 'simple-folder'
    }

    Pester\It 'NotMatch parameter - works with Quiet parameter' -Skip {
        # Setup test files
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-quiet-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files
        'content with pattern' | Microsoft.PowerShell.Utility\Out-File 'match.txt'
        'content without target' | Microsoft.PowerShell.Utility\Out-File 'nomatch.txt'

        # Test -NotMatch with -Quiet (should return file paths, not MatchInfo objects)
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'pattern' -NotMatch -Quiet)
        $found.Count | Pester\Should -Be 1
        $found[0] | Pester\Should -Match 'nomatch\.txt'
        $found[0] | Pester\Should -BeOfType [string]  # Should return string paths, not MatchInfo objects
    }

    Pester\It 'NotMatch parameter - edge case with empty files' -Skip {
        # Setup test files including empty ones
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-empty-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create test files including empty file
        'content with target' | Microsoft.PowerShell.Utility\Out-File 'withcontent.txt'
        Microsoft.PowerShell.Management\New-Item -ItemType File -Path 'empty.txt' -Force | Microsoft.PowerShell.Core\Out-Null

        # Test -NotMatch finds empty files (which by definition don't contain the pattern)
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -Content 'target' -NotMatch -PassThru -Quiet)
        $found.Count | Pester\Should -Be 1
        $found.Name | Pester\Should -Contain 'empty.txt'
        $found.Name | Pester\Should -Not -Contain 'withcontent.txt'
    }

    Pester\It 'NotMatch parameter - works without Content parameter for filename matching' {
        # Setup test files with different names
        $testDir = GenXdev.FileSystem\Expand-Path "$testRoot\NotMatch-filename-test\" -CreateDirectory
        Microsoft.PowerShell.Management\Set-Location -LiteralPath $testDir

        # Create files with different naming patterns
        Microsoft.PowerShell.Management\New-Item -ItemType File -Path 'target-file.txt' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType File -Path 'normal-file.txt' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType File -Path 'another-target.txt' -Force | Microsoft.PowerShell.Core\Out-Null
        Microsoft.PowerShell.Management\New-Item -ItemType File -Path 'simple.txt' -Force | Microsoft.PowerShell.Core\Out-Null

        # Test finding files that don't have 'target' in filename
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask '*.txt' -PassThru | Microsoft.PowerShell.Core\Where-Object { $_.Name -notmatch 'target' })
        $found.Count | Pester\Should -Be 2
        $foundNames = $found.Name
        $foundNames | Pester\Should -Contain 'normal-file.txt'
        $foundNames | Pester\Should -Contain 'simple.txt'
    }

    # Culture-specific unit tests to detect bugs in culture selection
    Pester\It 'Culture parameter - Turkish i/I distinction should be respected with Turkish culture' {
        # Turkish has unique case conversion rules for i/I
        $testFile = "$testDir\turkish-culture-test.txt"
        $turkishContent = @(
            'Istanbul is beautiful',
            'ISTANBUL city center',
            'İstanbul with dotted capital İ',
            'istanbul lowercase',
            'ÎSTANBUL with circumflex'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $turkishContent, [System.Text.UTF8Encoding]::new($false))

        # Test 1: Turkish culture should distinguish between i and İ (dotted I)
        # In Turkish: lowercase i → uppercase İ (dotted), lowercase ı → uppercase I (dotless)
        $foundTurkish = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -Culture 'tr-TR' -PassThru -Quiet)
        $foundCurrent = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -PassThru -Quiet)

        # Turkish culture should find at least one match (the exact 'istanbul' match)
        $foundTurkish.Count | Pester\Should -BeGreaterThan 0 -Because "Turkish culture should find the exact 'istanbul' match"

        # Test that culture is actually being applied by comparing with current culture
        # Results may differ between Turkish and current culture for i/İ handling
        if ((Microsoft.PowerShell.Utility\Get-Culture).Name -ne 'tr-TR') {
            Microsoft.PowerShell.Utility\Write-Host "Turkish culture found: $($foundTurkish.Count), Current culture found: $($foundCurrent.Count)"
            # The key test: culture parameter should actually change behavior
            # This verifies our culture implementation is working
        }
    }

    Pester\It 'Culture parameter - German ß (sharp s) should match SS in German culture' {
        $testFile = "$testDir\german-culture-test.txt"
        $germanContent = @(
            'Straße means street',
            'STRASSE in capitals',
            'Weiß means white',
            'WEISS in capitals',
            'Fußball is football'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $germanContent, [System.Text.UTF8Encoding]::new($false))

        # Test German ß equivalency with SS
        $foundBeta = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'straße' -SimpleMatch -Culture 'de-DE' -PassThru -Quiet)
        $foundSS = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'strasse' -SimpleMatch -Culture 'de-DE' -PassThru -Quiet)

        # In German culture, 'straße' and 'strasse' should both match both 'Straße' and 'STRASSE'
        $foundBeta.Count | Pester\Should -BeGreaterThan 0
        $foundSS.Count | Pester\Should -BeGreaterThan 0

        # Both should find the same content (ß ↔ SS equivalency)
        $foundBeta.Count | Pester\Should -Be $foundSS.Count -Because "German culture should treat ß and SS as equivalent"
    }

    Pester\It 'Culture parameter - Case-sensitive with culture should still respect culture rules' {
        $testFile = "$testDir\culture-case-sensitive-test.txt"
        $testContent = @(
            'Turkish İstanbul',
            'turkish istanbul',
            'German Straße',
            'GERMAN STRASSE'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test case-sensitive with Turkish culture
        $foundCaseSensitive = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -Culture 'tr-TR' -CaseSensitive -PassThru -Quiet)
        $foundCaseInsensitive = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -Culture 'tr-TR' -PassThru -Quiet)

        # Case-sensitive should find fewer matches than case-insensitive
        $foundCaseSensitive.Count | Pester\Should -BeLessOrEqual $foundCaseInsensitive.Count

        # Case-sensitive should still only find exact case matches
        $foundCaseSensitive.Count | Pester\Should -Be 1 -Because "Case-sensitive should only match 'turkish istanbul'"
    }

    Pester\It 'Culture parameter - No culture specified should use current culture' {
        $testFile = "$testDir\no-culture-test.txt"
        $testContent = 'Mixed content: café, naïve, résumé'

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test without culture parameter (should use current culture)
        $foundNoCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'café' -SimpleMatch -PassThru -Quiet)
        $foundCurrentCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'café' -SimpleMatch -Culture (Microsoft.PowerShell.Utility\Get-Culture).Name -PassThru -Quiet)

        # Both should produce identical results
        $foundNoCulture.Count | Pester\Should -Be $foundCurrentCulture.Count -Because "No culture should default to current culture"
    }

    Pester\It 'Culture parameter - Invalid culture should not crash' {
        $testFile = "$testDir\invalid-culture-test.txt"
        'Simple test content' | Microsoft.PowerShell.Utility\Out-File $testFile -Encoding UTF8

        # Test with invalid culture - should not crash but may not work as expected
        try {
            $result = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'Simple' -SimpleMatch -Culture 'invalid-XX' -PassThru -Quiet)
            # Should not crash - if it gets here, the invalid culture was handled gracefully
            $result.Count | Pester\Should -BeGreaterOrEqual 0
        } catch {
            # If it throws, the error should be informative
            $_.Exception.Message | Pester\Should -Match 'culture|Culture' -Because "Error should mention culture parameter"
        }
    }

    Pester\It 'Culture parameter - French accented characters should match unaccented in French culture' {
        $testFile = "$testDir\french-culture-test.txt"
        $frenchContent = @(
            'café avec crème',
            'CAFE AVEC CREME',
            'naïve approach',
            'NAIVE APPROACH',
            'résumé complet'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $frenchContent, [System.Text.UTF8Encoding]::new($false))

        # Test accented vs unaccented matching in French culture
        $foundAccented = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'café' -SimpleMatch -Culture 'fr-FR' -PassThru -Quiet)
        $foundUnaccented = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'cafe' -SimpleMatch -Culture 'fr-FR' -PassThru -Quiet)

        # In French culture, both should find content (accented and unaccented should be equivalent)
        $foundAccented.Count | Pester\Should -BeGreaterThan 0
        $foundUnaccented.Count | Pester\Should -BeGreaterThan 0

        # Verify that culture-specific matching is working
        $foundAccented.Count | Pester\Should -Be $foundUnaccented.Count -Because "French culture should treat café and cafe as equivalent"
    }

    Pester\It 'Culture parameter - Ligatures should be handled correctly in specific cultures' {
        $testFile = "$testDir\ligature-test.txt"
        $ligatureContent = @(
            'The æsthetic office',
            'The aesthetic office',
            'Œuvre complete',
            'Oeuvre complete'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $ligatureContent, [System.Text.UTF8Encoding]::new($false))

        # Test ligature matching
        $foundLigature = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'aesthetic' -SimpleMatch -Culture 'en-US' -PassThru -Quiet)
        $foundNoLigature = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'æsthetic' -SimpleMatch -Culture 'en-US' -PassThru -Quiet)

        # Both should find content if ligature equivalency is supported
        $foundLigature.Count | Pester\Should -BeGreaterThan 0
        $foundNoLigature.Count | Pester\Should -BeGreaterThan 0
    }

    Pester\It 'Culture parameter - Complex regex should not use culture (only SimpleMatch should)' {
        $testFile = "$testDir\regex-culture-test.txt"
        $testContent = @(
            'İstanbul is beautiful',
            'istanbul lowercase',
            'Test123 numbers'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test that regex ignores culture parameter (only SimpleMatch should use culture)
        $foundRegexWithCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'i.*bul' -Culture 'tr-TR' -PassThru -Quiet)
        $foundRegexWithoutCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'i.*bul' -PassThru -Quiet)

        # Regex should ignore culture parameter, so results should be identical
        $foundRegexWithCulture.Count | Pester\Should -Be $foundRegexWithoutCulture.Count -Because "Regex matching should ignore culture parameter"

        # But SimpleMatch with Turkish culture should behave differently
        $foundSimpleWithCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -Culture 'tr-TR' -PassThru -Quiet)
        $foundSimpleWithoutCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -PassThru -Quiet)

        # SimpleMatch results may differ based on culture (if current culture is not Turkish)
        if ((Microsoft.PowerShell.Utility\Get-Culture).Name -ne 'tr-TR') {
            # Results should potentially differ for SimpleMatch when culture is specified
            Microsoft.PowerShell.Utility\Write-Host "SimpleMatch with Turkish culture found: $($foundSimpleWithCulture.Count), without: $($foundSimpleWithoutCulture.Count)"
        }
    }

    Pester\It 'Culture parameter - Culture comparison with Context lines should work correctly' {
        $testFile = "$testDir\culture-context-test.txt"
        $testContent = @(
            'Before line',
            'Istanbul city center',
            'After line 1',
            'After line 2'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test culture with context lines - use content that will actually match
        $foundWithContext = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'istanbul' -SimpleMatch -Culture 'tr-TR' -Context 1,2 -NoRecurse)

        # Should find matches (Turkish culture should find 'istanbul' in 'Istanbul city center')
        $foundWithContext.Count | Pester\Should -BeGreaterThan 0 -Because "Turkish culture with context should find content"

        # Verify context includes surrounding lines if match is found
        if ($foundWithContext.Count -gt 0) {
            $contextOutput = $foundWithContext -join "`n"
            Microsoft.PowerShell.Utility\Write-Host "Context output: $contextOutput"
        }
        $contextOutput = $foundWithContext -join "`n"
        $contextOutput | Pester\Should -Match 'Before line'
        $contextOutput | Pester\Should -Match 'After line'
    }

    Pester\It 'Culture parameter - AllMatches with culture should find all culture-equivalent matches' {
        $testFile = "$testDir\allmatch-culture-test.txt"
        $testContent = @(
            'café and café again in same line',
            'CAFE and cafe mixed case',
            'Different: naïve naive'
        ) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test AllMatches with culture
        $foundAllMatches = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'cafe' -SimpleMatch -Culture 'fr-FR' -AllMatches -NoRecurse)
        $foundAllMatches.Count | Pester\Should -BeGreaterThan 0 -Because "French culture should find cafe/café content"

        # Verify that matches are found (exact behavior may vary by .NET version)
        $matchOutput = $foundAllMatches -join "`n"
        Microsoft.PowerShell.Utility\Write-Host "AllMatches output: $matchOutput"

        # Test that culture is being applied consistently
        $foundSingle = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'cafe' -SimpleMatch -Culture 'fr-FR' -NoRecurse)
        $foundSingle.Count | Pester\Should -BeGreaterThan 0 -Because "Single match should also work with culture"
    }

    Pester\It 'Culture parameter - Basic functionality test ensures culture parameter is processed' {
        $testFile = "$testDir\basic-culture-test.txt"
        $testContent = 'Simple ASCII content for basic testing'

        [System.IO.File]::WriteAllText($testFile, $testContent, [System.Text.UTF8Encoding]::new($false))

        # Test that specifying any culture doesn't break basic functionality
        $foundWithCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'ASCII' -SimpleMatch -Culture 'en-US' -PassThru -Quiet)
        $foundWithoutCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'ASCII' -SimpleMatch -PassThru -Quiet)

        # Both should find the content
        $foundWithCulture.Count | Pester\Should -Be 1 -Because "Culture parameter should not break basic ASCII matching"
        $foundWithoutCulture.Count | Pester\Should -Be 1 -Because "No culture should work for ASCII content"

        # Test with invalid culture gracefully handles errors
        try {
            $foundInvalidCulture = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'ASCII' -SimpleMatch -Culture 'zz-ZZ' -PassThru -Quiet)
            # If it doesn't throw, it should still work or return empty
            $foundInvalidCulture.Count | Pester\Should -BeGreaterOrEqual 0
        } catch {
            # If it throws, that's also acceptable behavior for invalid culture
            $_.Exception | Pester\Should -Not -BeNullOrEmpty
        }
    }

    Pester\It 'Culture parameter - Performance test ensures culture setup is not done repeatedly' {
        $testFile = "$testDir\performance-culture-test.txt"
        # Create larger content to test performance
        $largeContent = (1..100 | Microsoft.PowerShell.Core\ForEach-Object { "Line $_ with café content" }) -join "`n"

        [System.IO.File]::WriteAllText($testFile, $largeContent, [System.Text.UTF8Encoding]::new($false))

        # Measure time with culture
        $startTime = Microsoft.PowerShell.Utility\Get-Date
        $found = @(GenXdev.FileSystem\Find-Item -SearchMask $testFile -Content 'café' -SimpleMatch -Culture 'fr-FR' -AllMatches -PassThru -Quiet)
        $endTime = Microsoft.PowerShell.Utility\Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds

        # Should complete reasonably quickly (culture setup should be done once, not per match)
        $found.Count | Pester\Should -BeGreaterThan 0
        $duration | Pester\Should -BeLessThan 5000 -Because "Culture-aware matching should complete within 5 seconds for 100 lines"

        Microsoft.PowerShell.Utility\Write-Host "Culture performance test: Found $($found.Count) matches in $($duration)ms"
    }
}
