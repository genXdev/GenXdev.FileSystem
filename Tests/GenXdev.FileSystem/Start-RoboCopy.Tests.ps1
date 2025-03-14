Describe "Start-RoboCopy" {
    BeforeAll {
        $Script:testRoot = GenXdev.FileSystem\Expand-Path "$env:TEMP\GenXdev.FileSystem.Tests\" -CreateDirectory
        Push-Location ($Script:testRoot)
    }

    AfterAll {
        Pop-Location
        Remove-AllItems $Script:testRoot -DeleteFolder
    }

    BeforeEach {
        $Script:source = "$Script:testRoot\source"
        $Script:dest = "$Script:testRoot\dest"
        New-Item -ItemType Directory -Path $Script:source, $Script:dest -Force

        1..3 | ForEach-Object {
            "test$_" | Out-File "$Script:source\file$_.txt"
        }
    }

    AfterEach {
        Remove-Item -Path $Script:source, $Script:dest -Recurse -Force
    }

    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Start-RoboCopy.ps1"

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
            $analyzerResults.Count | Should -Be 0 -Because @"
The following PSScriptAnalyzer rules are being violated:
$message
"@;
        }
    }

    It "Copies files between folders" {
        Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest
        $destFiles = Get-ChildItem $Script:dest -File
        $destFiles.Count | Should -Be 3
    }

    It "Moves files when specified" {
        Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest -Move
        $sourceFiles = Get-ChildItem $Script:source -File
        $sourceFiles.Count | Should -Be 0
        $destFiles = Get-ChildItem $Script:dest -File
        $destFiles.Count | Should -Be 3
    }

    It "Mirrors directory structure" {
        New-Item -ItemType Directory -Path "$Script:source\subfolder" -Force
        "subtest" | Out-File "$Script:source\subfolder\subfile.txt"

        Start-RoboCopy -Source $Script:source -DestinationDirectory $Script:dest -Mirror
        Test-Path "$Script:dest\subfolder\subfile.txt" | Should -Be $true
    }
}