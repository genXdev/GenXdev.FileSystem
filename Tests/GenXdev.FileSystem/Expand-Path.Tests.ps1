###############################################################################

Pester\Describe 'Expand-Path unit tests' {

    Pester\It 'Should pass PSScriptAnalyzer rules' {

        # get the script path for analysis
        $scriptPath = GenXdev.FileSystem\Expand-Path "$PSScriptRoot\..\..\Functions\GenXdev.FileSystem\Expand-Path.ps1"

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

        # define test paths
        $Script:testPath = [IO.Path]::GetFullPath("$($Env:TEMP)")
        $Script:testFile = Microsoft.PowerShell.Management\Join-Path $Script:testPath 'test.txt'
    }

    Pester\It 'expands relative path to absolute path' {
        # arrange
        $relativePath = '.\test.txt'
        Microsoft.PowerShell.Management\Push-Location $Script:testPath

        # act
        $result = GenXdev.FileSystem\Expand-Path $relativePath

        # assert
        $result | Pester\Should -Be "$((Microsoft.PowerShell.Management\Get-Location).Path)\test.txt"

        # cleanup
        Microsoft.PowerShell.Management\Pop-Location
    }

    Pester\It 'handles UNC paths' {
        # arrange
        $uncPath = '\\server\share\file.txt'

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Pester\Should -Be $uncPath
    }

    Pester\It 'preserves UNC paths exactly as provided' {
        # arrange
        $uncPath = '\\server\share\file.txt'

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Pester\Should -Be $uncPath
    }

    Pester\It 'preserves UNC paths with trailing slashes' {
        # arrange
        $uncPath = '\\webserver\sites\powershell.genxdev.net\'

        # act
        $result = GenXdev.FileSystem\Expand-Path $uncPath

        # assert
        $result | Pester\Should -Be '\\webserver\sites\powershell.genxdev.net'
        $result | Pester\Should -Not -Be 'e:\webserver\sites\powershell.genxdev.net'
        $result | Pester\Should -Match '^\\\\[^\\]+'
    }

    Pester\It 'expands user home directory' {
        # arrange
        $homePath = '~/test.txt'

        # act
        $result = GenXdev.FileSystem\Expand-Path $homePath

        # assert
        $result | Pester\Should -Be (Microsoft.PowerShell.Management\Join-Path $HOME 'test.txt')
    }

    Pester\It 'tests -ForceDrive parameter' {

        $result = GenXdev.FileSystem\Expand-Path 'b:\movies\classics\*.mp4' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\**\movies\classics\*.mp4'

        $result = GenXdev.FileSystem\Expand-Path '\movies\classics\*.mp4' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\movies\classics\*.mp4'

        $result = GenXdev.FileSystem\Expand-Path '\\media\data\users\*' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\**\data\users\*'

        $result = GenXdev.FileSystem\Expand-Path 'B:' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\'

        $result = GenXdev.FileSystem\Expand-Path 'B:*.txt' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\**\*.txt'

        $result = GenXdev.FileSystem\Expand-Path '\folder1\*.ps1' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\folder1\*.ps1'

        $result = GenXdev.FileSystem\Expand-Path '.\folder1\*.ps1' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\**\folder1\*.ps1'

        $result = GenXdev.FileSystem\Expand-Path 'folder1\*.ps1' -ForceDrive Z
        $result | Pester\Should -Be 'Z:\**\folder1\*.ps1'

        Microsoft.PowerShell.Management\Pop-Location
    }
}

###############################################################################