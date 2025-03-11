#
# Module manifest for module 'GenXdev.FileSystem'
#
# Generated by: genXdev
#
# Generated on: 11/03/2025
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'GenXdev.FileSystem.psm1'

# Version number of this module.
ModuleVersion = '1.126.2025'

# Supported PSEditions
CompatiblePSEditions = 'Core'

# ID used to uniquely identify this module
GUID = '2f62080f-0483-4421-8497-b3d433b65171'

# Author of this module
Author = 'genXdev'

# Company or vendor of this module
CompanyName = 'GenXdev'

# Copyright statement for this module
Copyright = 'Copyright 2021-2025 GenXdev'

# Description of the functionality provided by this module
Description = 'A Windows PowerShell module for basic and advanced file management tasks'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.5.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
ClrVersion = '9.0.1'

# Processor architecture (None, X86, Amd64) required by this module
ProcessorArchitecture = 'Amd64'

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'AssurePester', 'Expand-Path', 'Find-DuplicateFiles', 'Find-Item',
               'Invoke-Fasti', 'Move-ItemWithTracking', 'Move-ToRecycleBin',
               'Remove-AllItems', 'Remove-ItemWithFallback', 'Remove-OnReboot',
               'Rename-InProject', 'Start-RoboCopy'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'ep', 'fasti', 'fdf', 'l', 'rc', 'recycle', 'rip', 'rmf', 'sdel', 'xc'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
ModuleList = @('GenXdev.FileSystem')

# List of all files packaged with this module
FileList = 'GenXdev.FileSystem.psd1', 'GenXdev.FileSystem.psm1', 'LICENSE',
               'license.txt', 'powershell.jpg', 'README.md',
               'Tests\GenXdev.FileSystem\AssurePester.Tests.ps1',
               'Tests\GenXdev.FileSystem\Expand-Path.Tests.ps1',
               'Tests\GenXdev.FileSystem\Find-DuplicateFiles.Tests.ps1',
               'Tests\GenXdev.FileSystem\Find-Item.Tests.ps1',
               'Tests\GenXdev.FileSystem\Invoke-Fasti.Tests.ps1',
               'Tests\GenXdev.FileSystem\Move-ItemWithTracking.Tests.ps1',
               'Tests\GenXdev.FileSystem\Move-ToRecycleBin.Tests.ps1',
               'Tests\GenXdev.FileSystem\Remove-AllItems.Tests.ps1',
               'Tests\GenXdev.FileSystem\Remove-ItemWithFallback.Tests.ps1',
               'Tests\GenXdev.FileSystem\Remove-OnReboot.Tests.ps1',
               'Tests\GenXdev.FileSystem\Rename-InProject.Tests.ps1',
               'Tests\GenXdev.FileSystem\Start-RoboCopy.Tests.ps1',
               'Functions\GenXdev.FileSystem\AssurePester.ps1',
               'Functions\GenXdev.FileSystem\Expand-Path.ps1',
               'Functions\GenXdev.FileSystem\Find-DuplicateFiles.ps1',
               'Functions\GenXdev.FileSystem\Find-Item.ps1',
               'Functions\GenXdev.FileSystem\Invoke-Fasti.ps1',
               'Functions\GenXdev.FileSystem\Move-ItemWithTracking.ps1',
               'Functions\GenXdev.FileSystem\Move-ToRecycleBin.ps1',
               'Functions\GenXdev.FileSystem\Remove-AllItems.ps1',
               'Functions\GenXdev.FileSystem\Remove-ItemWithFallback.ps1',
               'Functions\GenXdev.FileSystem\Remove-OnReboot.ps1',
               'Functions\GenXdev.FileSystem\Rename-InProject.ps1',
               'Functions\GenXdev.FileSystem\Start-RoboCopy.ps1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Markdown','Tools','RoboCopy','GenXdev'

        # A URL to the license for this module.
        # LicenseUri = 'https://raw.githubusercontent.com/genXdev/GenXdev.FileSystem/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://powershell.genxdev.net/#GenXdev.FileSystem'

        # A URL to an icon representing this module.
        IconUri = 'https://genxdev.net/favicon.ico'

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $true

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

