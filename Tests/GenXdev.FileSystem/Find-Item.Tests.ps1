###############################################################################
Describe "Find-Item" {
    BeforeAll {
        $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Push-Location $Script:testRoot
    }

    AfterAll {
        $Script:testRoot = Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory

        # cleanup test folder
        Remove-AllItems $Script:testRoot -DeleteFolder

        Pop-Location
    }
    BeforeEach {
        # setup test folder structure
        $testDir = [IO.Path]::GetDirectoryName((Expand-Path (Join-Path $Script:testRoot "find-item-test\*") -CreateDirectory))
        Push-Location $testDir
        New-Item -ItemType Directory -Path "dir1", "dir2/subdir" -Force
        "test1" | Out-File "dir1/file1.txt"
        "test2" | Out-File "dir2/file2.txt"
        "test3" | Out-File "dir2/subdir/file3.txt"
    }

    AfterEach {
        Pop-Location
        Remove-Item -Path (Join-Path $Script:testRoot "find-item-test") -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Finds files by extension" {
        $files = Find-Item -SearchMask "./*.txt" -PassThru
        $files.Count | Should -Be 3
        $files.Name | Should -Contain "file1.txt"
    }

    It "Finds files by content pattern" {
        $files = Find-Item -Pattern "test2" -PassThru
        $files.Count | Should -Be 1
        $files[0].Name | Should -Be "file2.txt"
    }

    It "Finds only directories" {
        $dirs = Find-Item -Directory -PassThru
        $dirs.Count | Should -Be 3
        $dirs.Name | Should -Contain "dir1"
        $dirs.Name | Should -Contain "dir2"
        $dirs.Name | Should -Contain "subdir"
    }
}

###############################################################################
Describe 'Find-Item' {
    BeforeAll {
        $testDir = Join-Path $Script:testRoot 'find-item-tests'
        New-Item -Path $testDir -ItemType Directory
        Set-Content -Path "$testDir\test1.txt" -Value "test content"
        Set-Content -Path "$testDir\test2.txt" -Value "different content"
        New-Item -Path "$testDir\subdir" -ItemType Directory
        Set-Content -Path "$testDir\subdir\test3.txt" -Value "test content"
    }

    It 'Finds files by name pattern' {
        $found = Find-Item -SearchMask "$testDir\*.txt" -PassThru
        $found.Count | Should -Be 3
    }

    It 'Finds files by content pattern' {
        $found = Find-Item -SearchMask "$testDir\*.txt" -Pattern "test content" -PassThru
        $found.Count | Should -Be 2
    }

    It 'Finds only directories when specified' {
        $found = Find-Item -SearchMask "$testDir\" -Directory -PassThru
        $found.Count | Should -Be 1
        $found | Should -Match 'subdir'
    }
}

