if (-not $IsWindows) {
    throw "This module only supports Windows 10+ x64 with PowerShell 7.5+ x64"
}

$osVersion = [System.Environment]::OSVersion.Version
$major = $osVersion.Major
$build = $osVersion.Build

if ($major -ne 10) {
    throw "This module only supports Windows 10+ x64 with PowerShell 7.5+ x64"
}


. "$PSScriptRoot\Functions\GenXdev.FileSystem\EnsurePester.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Expand-Path.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Find-Item.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Invoke-Fasti.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Remove-AllItems.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Remove-OnReboot.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Rename-InProject.ps1"
. "$PSScriptRoot\Functions\GenXdev.FileSystem\Start-RoboCopy.ps1"
