################################################################################

Describe "Expand-Path unit tests" {

    It "Should pass PSScriptAnalyzer rules" {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Expand-Path.ps1"

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

        # define test paths
        $Script:testPath = [IO.Path]::GetFullPath("$($Env:TEMP)")
        $Script:testFile = Join-Path $Script:testPath "test.txt"
    }

    It "expands relative path to absolute path" {
        # arrange
        $relativePath = ".\test.txt"
        Push-Location $Script:testPath

        # act
        $result = GenXdev.FileSystem\Expand-Path $relativePath

        # assert
        $result | Should -Be "$((Get-Location).Path)\test.txt"

        # cleanup
        Pop-Location
    }

    It "handles UNC paths" {
        # arrange
        $uncPath = "\\server\share\file.txt"

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Should -Be $uncPath
    }

    It "preserves UNC paths exactly as provided" {
        # arrange
        $uncPath = "\\server\share\file.txt"

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Should -Be $uncPath
    }

    It "preserves UNC paths with trailing slashes" {
        # arrange
        $uncPath = "\\webserver\sites\powershell.genxdev.net\"

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Should -Be "\\webserver\sites\powershell.genxdev.net"
        $result | Should -Not -Be "e:\webserver\sites\powershell.genxdev.net"
        $result | Should -Match "^\\\\[^\\]+"
    }

    It "expands user home directory" {
        # arrange
        $homePath = "~/test.txt"

        # act
        $result = GenXdev.FileSystem\Expand-Path $homePath

        # assert
        $result | Should -Be (Join-Path $HOME "test.txt")
    }

    It "takes into account current locations on other drives" {

        Push-Location

        Set-Location b:\movies\
        Set-Location c:\

        $result = GenXdev.FileSystem\Expand-Path "b:"
        $result | Should -Be "B:\Movies"

        $result = GenXdev.FileSystem\Expand-Path "b:movie.mp4"
        $result | Should -Be "B:\Movies\movie.mp4"

        Pop-Location
    }

    It "tests -ForceDrive parameter" {

        $result = GenXdev.FileSystem\Expand-Path "b:\movies\classics\*.mp4" -ForceDrive Z
        $result | Should -Be "Z:\**\movies\classics\*.mp4"

        $result = GenXdev.FileSystem\Expand-Path "\movies\classics\*.mp4" -ForceDrive Z
        $result | Should -Be "Z:\movies\classics\*.mp4"

        $result = GenXdev.FileSystem\Expand-Path "\\media\data\users\*" -ForceDrive Z
        $result | Should -Be "Z:\**\data\users\*"

        $result = GenXdev.FileSystem\Expand-Path "B:" -ForceDrive Z
        $result | Should -Be "Z:\"

        $result = GenXdev.FileSystem\Expand-Path "B:*.txt" -ForceDrive Z
        $result | Should -Be "Z:\**\*.txt"

        $result = GenXdev.FileSystem\Expand-Path "\folder1\*.ps1" -ForceDrive Z
        $result | Should -Be "Z:\folder1\*.ps1"

        $result = GenXdev.FileSystem\Expand-Path ".\folder1\*.ps1" -ForceDrive Z
        $result | Should -Be "Z:\**\folder1\*.ps1"

        $result = GenXdev.FileSystem\Expand-Path "folder1\*.ps1" -ForceDrive Z
        $result | Should -Be "Z:\**\folder1\*.ps1"

        Pop-Location
    }
}

################################################################################