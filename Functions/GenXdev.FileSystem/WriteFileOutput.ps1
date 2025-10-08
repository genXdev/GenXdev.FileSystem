<##############################################################################
Part of PowerShell module : GenXdev.FileSystem
Original cmdlet filename  : WriteFileOutput.ps1
Original author           : René Vaessen / GenXdev
Version                   : 1.298.2025
################################################################################
MIT License

Copyright 2021-2025 GenXdev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
################################################################################>
################################################################################
<#
.SYNOPSIS
Outputs file information with hyperlinked display names for enhanced user
experience.

.DESCRIPTION
This function processes file input objects and outputs them in a user-friendly
format with hyperlinked file names when displayed in the console. It handles
different input types including strings, FileInfo objects, and other object
types. The function automatically detects if output is being redirected or
captured in a pipeline and adjusts its behavior accordingly.

.PARAMETER CallerInvocation
The invocation information from the calling function, used to detect pipeline
context and output redirection status.

.PARAMETER Input
The input object to process, which can be a file path string, FileInfo object,
or any other object type that should be passed through.

.PARAMETER RelativeBasePath
Optional base path for generating relative file paths in the output display.

.PARAMETER FullPaths
When specified, forces the output to use full absolute paths instead of
relative paths for file display.

.PARAMETER Prefix
An optional string prefix to prepend to the output display for additional
context.

.EXAMPLE
WriteFileOutput -CallerInvocation $MyInvocation -Input "C:\temp\file.txt"

.EXAMPLE
Get-ChildItem | WriteFileOutput -CallerInvocation $MyInvocation -Input $_
#>
function WriteFileOutput {

    param(
        ###################################################################
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = ("The invocation information from the calling " +
                          "function")
        )]
        [object] $CallerInvocation,
        ###################################################################
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            HelpMessage = ("The input object to process, which can be a " +
                          "file path or object")
        )]
        [object] $Input,
        ###################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = ("An optional string prefix to prepend to the " +
                          "output display for additional context")
        )]
        [string] $Prefix,
        ###################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = ("Base path for generating relative file paths " +
                          "in output")
        )]
        [string] $RelativeBasePath,
        ###################################################################
        [Parameter(
            Mandatory = $false,
            HelpMessage = ("Forces output to use full absolute paths " +
                          "instead of relative paths")
        )]
        [switch] $FullPaths
        ###################################################################
    )

    begin {

        # determine if pipeline output is captured or redirected to detect
        # the appropriate output behavior
        $unattendedMode = GenXdev.Helpers\Test-UnattendedMode -CallersInvocation $CallerInvocation

        # output verbose information about redirection detection
        Microsoft.PowerShell.Utility\Write-Verbose (
            "UnattendedMode: ${unattendedMode}"
        )
    }

    process {
        try {

            # return early if input is null to avoid processing empty values
            if ($null -eq $Input) {
                return
            }

            # helper function to output with optional prefix
            function OutputWithPrefix($content) {
                if ($Prefix) {
                    Microsoft.PowerShell.Utility\Write-Output ("${Prefix}${content}")
                } else {
                    Microsoft.PowerShell.Utility\Write-Output $content
                }
            }

            # helper function to create hyperlinked output for console display
            function OutputHyperlink($displayText, $targetPath) {
                $PSStyle.FormatHyperlink($displayText, $targetPath) | Microsoft.PowerShell.Core\Out-Host
            }

            # helper function to get FileInfo object, reusing existing if available
            function GetFileInfo($path, $inputObject) {
                if ($inputObject -is [System.IO.FileInfo]) {
                    return $inputObject
                }
                return Microsoft.PowerShell.Management\Get-Item -LiteralPath $path
            }

            # initialize filepath variable with the input object
            $filePath = $Input

            # convert string input to expanded file path using filesystem module
            if ($Input -is [string]) {
                $filePath = GenXdev.FileSystem\Expand-Path $Input
            }
            # extract full name from fileinfo objects for consistent processing
            elseif ($Input -is [System.IO.FileInfo]) {
                $filePath = $Input.FullName
            }
            # pass through non-file objects unchanged to the pipeline
            else {
                OutputWithPrefix $Input
                return
            }

            # verify that the file path exists as a file before processing
            if (-not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $filePath -PathType Leaf)) {
                # output the filepath directly if it doesn't exist as a file
                OutputWithPrefix $filePath
                return
            }

            # get FileInfo object once for reuse
            $fileInfo = GetFileInfo $filePath $Input

            # handle full paths mode
            if ($FullPaths) {
                Microsoft.PowerShell.Utility\Write-Output $fileInfo
                return
            }

            # calculate relative path
            $relativePath = if (-not [string]::IsNullOrWhiteSpace($RelativeBasePath)) {
                # convert to relative path if a base path is provided
                GenXdev.FileSystem\Find-Item $filePath -NoRecurse -RelativeBasePath $RelativeBasePath
            } else {
                GenXdev.FileSystem\Find-Item $filePath -NoRecurse
            }

            # prepare display text with optional prefix
            $displayText = if ($Prefix) { "${Prefix}${relativePath}" } else { $relativePath }

            # handle output redirection
            if ($unattendedMode) {
                OutputHyperlink $displayText $fileInfo.FullName
            } else {
                # output fileinfo object to pipeline for programmatic use
                Microsoft.PowerShell.Utility\Write-Output $fileInfo
                # create hyperlinked output for console display
                OutputHyperlink $displayText $fileInfo.FullName
            }
        }
        catch {
            # output any errors that occur during file processing
            Microsoft.PowerShell.Utility\Write-Error $_
        }
    }

    end {
    }
}
################################################################################