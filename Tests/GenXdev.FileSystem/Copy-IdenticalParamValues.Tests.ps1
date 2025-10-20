Pester\Describe 'Copy-IdenticalParamValues unit tests' {

    Pester\BeforeAll {

        function Script:testParams {
            [CmdletBinding()]
            param
            (
                [string[]] $Path = 'c:\otherfile.txt',
                [string[]] $ExcludePath,
                [string[]] $TagFilter,
                [string[]] $ExcludeTagFilter,
                [string[]] $FullNameFilter,
                [switch] $CI,
                [Parameter(Mandatory = $false)]
                [string] $CodeCoverageOutputFileFormat
            )

            $params = GenXdev.FileSystem\Copy-IdenticalParamValues `
                -BoundParameters $PSBoundParameters `
                -FunctionName "Pester\Invoke-Pester" `
                -DefaultValues (Microsoft.PowerShell.Utility\Get-Variable -Scope Local -ErrorAction SilentlyContinue);

            return $params
        }
    }

    Pester\It 'returns the correct parameter values 1' {

        $Path = 'c:\example.txt'
        $ExcludePath = 'c:\exclude.txt'
        $TagFilter = 'Tag1', 'Tag2'
        $ExcludeTagFilter = 'Tag3'
        $FullNameFilter = 'example*'
        $CI = $true
        $CodeCoverageOutputFileFormat = 'Detailed'

        [System.Collections.Hashtable] $expected = @{
            Path             = [string[]] @($Path)
            ExcludePath      = [string[]] @($ExcludePath)
            TagFilter        = [string[]] @($TagFilter)
            ExcludeTagFilter = [string[]] @($ExcludeTagFilter)
            FullNameFilter   = [string[]] @($FullNameFilter)
            CI               = !!$CI
            CodeCoverageOutputFileFormat           = $CodeCoverageOutputFileFormat
        }

        [System.Collections.Hashtable] $result = testParams @expected

        $sorted1 = $expected.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3
        $sorted2 = $result.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3

        $sorted1 | Pester\Should -Be $sorted2
    }

    Pester\It 'returns the correct parameter values 2' {

        $ExcludePath = 'c:\exclude.txt'
        $TagFilter = 'Tag1', 'Tag2'
        $ExcludeTagFilter = 'Tag3'
        $FullNameFilter = 'example*'
        $CI = $true
        $CodeCoverageOutputFileFormat = 'Detailed'

        [System.Collections.Hashtable] $expected = @{
            ExcludePath      = [string[]] @($ExcludePath)
            TagFilter        = [string[]] @($TagFilter)
            ExcludeTagFilter = [string[]] @($ExcludeTagFilter)
            FullNameFilter   = [string[]] @($FullNameFilter)
            CI               = !!$CI
            CodeCoverageOutputFileFormat           = $CodeCoverageOutputFileFormat
        }

        [System.Collections.Hashtable] $result = testParams @expected

        $expected["Path"] = [string[]] @('c:\otherfile.txt')

        $sorted1 = $expected.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3
        $sorted2 = $result.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3

        $sorted1 | Pester\Should -Be $sorted2
    }

    Pester\It 'returns the correct parameter values 3' {

        $ExcludePath = 'c:\exclude.txt'
        $TagFilter = 'Tag1', 'Tag2'
        $ExcludeTagFilter = 'Tag3'
        $FullNameFilter = 'example*'
        $CI = $true
        $CodeCoverageOutputFileFormat = 'Detailed'

        [System.Collections.Hashtable] $expected = @{
            ExcludePath      = [string[]] @($ExcludePath)
            TagFilter        = [string[]] @($TagFilter)
            ExcludeTagFilter = [string[]] @($ExcludeTagFilter)
            FullNameFilter   = [string[]] @($FullNameFilter)
            CI               = !!$CI
            CodeCoverageOutputFileFormat           = $CodeCoverageOutputFileFormat
        }

        [System.Collections.Hashtable] $result = testParams @expected -Path 'c:\secondotherfile.txt'

        $expected["Path"] = [string[]] @('c:\secondotherfile.txt')

        $sorted1 = $expected.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3
        $sorted2 = $result.GetEnumerator() | Microsoft.PowerShell.Utility\Sort-Object Name | Microsoft.PowerShell.Utility\Select-Object Name, Value | Microsoft.PowerShell.Utility\ConvertTo-Json -Depth 3

        $sorted1 | Pester\Should -Be $sorted2
    }

    Pester\It 'returns the correct parameter values 4' {

        $ExcludePath = 'c:\exclude.txt'
        $TagFilter = 'Tag1', 'Tag2'
        $ExcludeTagFilter = 'Tag3'
        $FullNameFilter = 'example*'
        $CI = $true

         [System.Collections.Hashtable] $expected = @{
            ExcludePath      = [string[]] @($ExcludePath)
            TagFilter        = [string[]] @($TagFilter)
            ExcludeTagFilter = [string[]] @($ExcludeTagFilter)
            FullNameFilter   = [string[]] @($FullNameFilter)
            CI               = !!$CI
        }

        [System.Collections.Hashtable] $result = testParams @expected

        $result.ContainsKey("CodeCoverageOutputFileFormat") | Pester\Should -Be $False
    }
}
