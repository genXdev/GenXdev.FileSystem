################################################################################

################################################################################

Describe "GenXdev.FileSystem\Expand-Path unit tests" {

    BeforeAll {

        # define test paths
        $Script:testPath = Join-Path $PSScriptRoot "TestData"
        $Script:testFile = Join-Path $Script:testPath "test.txt"
    }

    It "expands relative path to absolute path" {
        # arrange
        $relativePath = ".\test.txt"
        Push-Location $Script:testPath

        # act
        $result = Expand-Path $relativePath

        # assert
        $result | Should -Be "$((Get-Location).Path)\test.txt"

        # cleanup
        Pop-Location
    }

    It "handles UNC paths" {
        # arrange
        $uncPath = "\\server\share\file.txt"

        # act
        $result = Expand-Path $uncPath

        # assert
        $result | Should -Be $uncPath
    }

    It "preserves UNC paths exactly as provided" {
        # arrange
        $uncPath = "\\server\share\file.txt"

        # act
        $result = Expand-Path $uncPath

        # assert
        $result | Should -Be $uncPath
    }

    It "preserves UNC paths with trailing slashes" {
        # arrange
        $uncPath = "\\webserver\sites\powershell.genxdev.net\"

        # act
        $result = Expand-Path $uncPath

        # assert
        $result | Should -Be "\\webserver\sites\powershell.genxdev.net"
        $result | Should -Not -Be "e:\webserver\sites\powershell.genxdev.net"
        $result | Should -Match "^\\\\[^\\]+"
    }

    It "expands user home directory" {
        # arrange
        $homePath = "~/test.txt"

        # act
        $result = Expand-Path $homePath

        # assert
        $result | Should -Be (Join-Path $HOME "test.txt")
    }
}

################################################################################
