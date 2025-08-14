Pester\Describe 'Start-RoboCopy' {
    Pester\BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Microsoft.PowerShell.Management\Push-Location -LiteralPath ($Script:testRoot)
    }

    Pester\AfterAll {
        Microsoft.PowerShell.Management\Pop-Location
        GenXdev.FileSystem\Remove-AllItems $Script:testRoot -DeleteFolder
    }

    Pester\BeforeEach {
        $Script:source = "$Script:testRoot\source"
        $Script:dest = "$Script:testRoot\dest"
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path $Script:source, $Script:dest -Force

        1..3 | Microsoft.PowerShell.Core\ForEach-Object {
            "test$_" | Microsoft.PowerShell.Utility\Out-File "$Script:source\file$_.txt"
        }
    }

    Pester\AfterEach {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath $Script:source, $Script:dest -Recurse -Force
    }

    Pester\It 'Copies files between folders' {
        GenXdev.FileSystem\Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest
        $destFiles = Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $Script:dest -File
        $destFiles.Count | Pester\Should -Be 3
    }

    Pester\It 'Moves files when specified' {
        GenXdev.FileSystem\Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest -Move
        $sourceFiles = Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $Script:source -File
        $sourceFiles.Count | Pester\Should -Be 0
        $destFiles = Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $Script:dest -File
        $destFiles.Count | Pester\Should -Be 3
    }

    Pester\It 'Mirrors directory structure' {
        Microsoft.PowerShell.Management\New-Item -ItemType Directory -Path "$Script:source\subfolder" -Force
        'subtest' | Microsoft.PowerShell.Utility\Out-File "$Script:source\subfolder\subfile.txt"

        GenXdev.FileSystem\Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest -Mirror
        Microsoft.PowerShell.Management\Test-Path -LiteralPath "$Script:dest\subfolder\subfile.txt" | Pester\Should -Be $true
    }
}