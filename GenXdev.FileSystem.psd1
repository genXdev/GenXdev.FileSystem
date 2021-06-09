#
# Module manifest for module 'GenXdev.FileSystem'


@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'GenXdev.FileSystem.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '2f62080f-0483-4421-8497-b3d433b65171'

    # Author of this module
    Author            = 'René Vaessen'

    # Company or vendor of this module
    CompanyName       = 'GenXdev'

    # Copyright statement for this module
    Copyright         = 'Copyright (c) 2021 René Vaessen'

    # Description of the functionality provided by this module
    Description       = 'Provides a collection of filesystem helper functions, like Start-RoboCopy'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1.19041.906'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

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
    FunctionsToExport = @("Start-RoboCopy", "Rename-InProject", "Expand-Path")

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @("Start-RoboCopy", "Rename-InProject", "Expand-Path")

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList        = @("GenXdev.FileSystem")

    # List of all files packaged with this module
    FileList          = @("GenXdev.FileSystem.psd1", "GenXdev.FileSystem.psm1", "LICENSE", "license.txt", "README.md")

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags                     = 'Markdown', 'Tools', 'RoboCopy'

            # A URL to the license for this module.
            LicenseUri               = 'https://raw.githubusercontent.com/renevaessen/GenXdev.FileSystem/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri               = 'https://github.com/renevaessen/GenXdev.FileSystem'

            # A URL to an icon representing this module.
            IconUri                  = 'https://genxdev.net/favicon.ico'

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $true

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI       = 'https://github.com/renevaessen/GenXdev.FileSystem'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}

# SIG # Begin signature block
# MIIR5wYJKoZIhvcNAQcCoIIR2DCCEdQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUumNBK3Nz1d0DUyEUIc9hUo7t
# wI+ggg1JMIIDDjCCAfagAwIBAgIQZXHXlWP9LahGpAR03yV8GTANBgkqhkiG9w0B
# AQsFADAfMR0wGwYDVQQDDBRHZW5YZGV2IEF1dGhlbnRpY29kZTAeFw0yMTA2MDkx
# ODAxNTRaFw0zMTA2MDkxNjExNTRaMB8xHTAbBgNVBAMMFEdlblhkZXYgQXV0aGVu
# dGljb2RlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoqprttBWSVMu
# 3dGODwVxMbbxvJ1dfBDu3iL2WS7qgrkQ6f4XoXHlnYg6MenKfxpUPDcwAcwWkJTd
# iJqPazPLSv3G8TvXVoZQFJ6XxdwkXxZvazlXQ9LezQEeAOoFzm7VqLOcrxWD82+z
# xk/1QPmKoysvw+Yjxju1tezGF/cTRVuCrGuLhw51GkuxYPMNxFH+orXmkhzxz62Q
# i/K0O7cx3dkC3soVNG6bgENrMrI/JcegoPS6H+LnLAI5W5sS47YYO4fToIOj4xYX
# V4VISl53WljME9hDKuRjlIB7Zoa/0yZkipMc7k5ai+iCLSc9lbbXvXN1z2YVK9dD
# vYs4IhNr7QIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFO6ZL9q1eRyDuzSdbt/8CUGmTbxEMA0GCSqGSIb3DQEB
# CwUAA4IBAQBubf5PEhhsys5K7OwYQG4txefS7nefQjk1Jsxk6uc8P0N4xGddOVrs
# bmZ34wTsA9MeDgT/OD14STsDG1oL0uQJAX2+ghXyE0GICDNyRNVm6dCcKWm0L98h
# vP8xo55AQrnERovLZcczCjyhQiBnZ0ToUjmmxfymaJ3Gfs2SKfXV+jxBqvQ0su7d
# MYg/vGHo6uN8xYjyEQDAKGud9uhg9XWQlm46ke9UyP1Vno9jlN0z4TF7ewAGDQ/A
# cvcBOSI0mbSf71y0A+qsxHCQ62PQNZlBgmw4Dpj7La/D/YtjZhdA4JgsWEtTRE5M
# 0McWb2bqzkP99Bx7J2q5w3kaWAbfxPofMIIE/jCCA+agAwIBAgIQDUJK4L46iP9g
# QCHOFADw3TANBgkqhkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQD
# EyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIx
# MDEwMTAwMDAwMFoXDTMxMDEwNjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAg
# MjAyMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQik
# Rcpja1HXOhFCvQp1dU2UtAxQtSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cL
# nGP9NmqB+in43Stwhd4CGPN4bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHT
# WjaPxqPhLxs6t2HWc+xObTOKfF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WH
# IOsOjizVI9r0TXhG4wODMSlKXAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6Bqr
# W7EdMMKbaYK02/xWVLwfoYervnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+
# DUmEvQECAwEAAaOCAbgwggG0MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAA
# MBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcB
# MCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNV
# HSMEGDAWgBT0tuEgHf4prtLkYaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+
# vCgtHUQ23eNqerwwcQYDVR0fBGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL3NoYTItYXNzdXJlZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRp
# Z2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcw
# AoZDaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3Vy
# ZWRJRFRpbWVzdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctema
# I7znGucgDo5nRv1CclF0CiNHo6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+
# RAJmTe1ppA/2uHDPYuj1UUp4eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+
# t2R3Y18jUmmDgvoaU+2QzI2hF3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8
# gQ74wOFcz8QRcucbZEnYIpp1FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1Ha
# vWPWH1ub9y4bTxMd90oNcX6Xt/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2
# mOHLKNpbh6aKLzCCBTEwggQZoAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJKoZI
# hvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNz
# dXJlZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAwMFow
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2ziOSX
# v2MhkJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsnfsCi
# 9aDg3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAPdc9x
# ck4Krd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJhFHm
# gudGUP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC/aJT
# Kk+FHcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0tuEg
# Hf4prtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHow
# eDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG/WwA
# AgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyqY3qz
# eM8GN0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFaKrcFNB1qrpn4J6JmvwmqYN92
# pDqTD/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9IEBhf
# iThhTWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVrlsD0
# WGkNfMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0rbaLE
# frvEJStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWmjlIx
# ggQIMIIEBAIBATAzMB8xHTAbBgNVBAMMFEdlblhkZXYgQXV0aGVudGljb2RlAhBl
# cdeVY/0tqEakBHTfJXwZMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQ15MuC2eXTSJnX0zulKXxq
# +Q2EXDANBgkqhkiG9w0BAQEFAASCAQCiOVs69qAVh+dBaPzVGeZ+viUN8RAEpYe6
# qCo30ska187QkZ9NLW8pUVwSxelfVC1jt8xLr1Sj09iqAkL86kicg1Ba6cOlnssO
# rlbOJOmb6rqSXPhff4m/66ekUP0brSGXESVgDsShC/FCkIs/3WuCmc4Xp6brw3tk
# 3yetqFifG59QPMpqg6oO4GyVxf5iW+ZfbvdtvmQQiVXoqNEgCLeWltXq71eYr0hU
# sVzNVefKfLyezV1VhhVMqJZTDwrfMN3S4p9akd7cdveESqaXIgOVjVXOa/aJb2Xo
# ZsetMNoKuhZpVgfbSyJimT689edwXPrlMdsdUQEBl5FyLEQFdmU7oYICMDCCAiwG
# CSqGSIb3DQEJBjGCAh0wggIZAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0ECEA1C
# SuC+Ooj/YEAhzhQA8N0wDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMTA2MDkxOTIyNTJaMC8GCSqGSIb3
# DQEJBDEiBCAU9a7xx6rsIYRYxvpw/HCmcHpghdtr81Ahht9xJGLyBTANBgkqhkiG
# 9w0BAQEFAASCAQAyN1fa6sOc9iwjq5iqPA8RQev9RM7TnOkea2QJebMc/qLmr0v1
# IHjpB+1i/KPZKqiMy8D9Bf+d82qM9ect9Z8aKmKp5VyCqJIfwSrFVziv6sXNh9mC
# jI4CPMHNT/vJgQ9DCcy0Dn6KQ/RLi6k85fwVPuCbmH8mjvY1F4G1zxqP+tT7zKdC
# jqpn6sHrg5o2r3ERJI8o3DVWSWoYcj33MJ5dCJCT0O9PhLhrXyBoT99lRZ1OqRrz
# 4KWS4dWyxNd9n0tNxvw1NCsaEhrDU3Gq37uySQefzwr5SPQj4PeLVjyeZa4tPgsw
# UnKMCgjTwYAcsVHblxRKnqyuNx8zOgNz/J+y
# SIG # End signature block
