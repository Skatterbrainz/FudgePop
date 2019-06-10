# Module manifest for module 'FudgePop'
# Generated by: David Stein
# Generated on: 12/27/2017

@{
    RootModule            = '.\FudgePop.psm1'
    ModuleVersion         = '1.0.17'
    GUID                  = '9d9f57f3-3188-42bb-9680-43024a7e7c04'
    Author                = 'David Stein'
    CompanyName           = 'skatterbrainz artificial research laboratory'
    Copyright             = '(c) 2017-2019 David Stein'
    Description           = 'Windows computer configuration management using Chocolatey and PowerShell and other stuff. Configure and manage registry settings, files, folders, services, applications, and more.'
    PowerShellVersion     = '3.0'
    PowerShellHostVersion = '3.0'
    FunctionsToExport     = @(
        'Get-FudgePopInventory',
        'Install-FudgePop',
        'Start-FudgePop',
        'New-FudgePopTemplate',
        'Remove-FudgePop',
        'Show-FudgePop'
    )
    CmdletsToExport       = '*'
    VariablesToExport     = '*'
    AliasesToExport       = '*'
    FileList              = @(
        '.\Public\RunFudgePop.bat',
        '.\READme.md',
        '.\docs\about_FudgePop.md',
        '.\docs\ControlFileSyntax.md',
        '.\docs\Get-FudgePopInventory.md',
        '.\docs\Install-FudgePop.md',
        '.\docs\Start-FudgePop.md',
        '.\docs\Remove-FudgePop.md',
        '.\docs\Show-FudgePop.md',
        '.\assets\control1.xml'
    )

    PrivateData           = @{
        PSData = @{
            Tags         = @('fudgepop', 'fudge')
            LicenseUri   = 'https://github.com/Skatterbrainz/FudgePop/blob/master/LICENSE'
            ProjectUri   = 'https://github.com/Skatterbrainz/FudgePop/'
            IconUri      = 'https://user-images.githubusercontent.com/11505001/32978413-d6e41f9c-cc0f-11e7-907e-589f78009bb8.png'
            ReleaseNotes = @'
        - Bug fixes
        - Renamed Invoke-FudgePop to Start-FudgePop
        - Icon added
'@
        }
    }
    HelpInfoURI           = 'https://github.com/Skatterbrainz/FudgePop/'
}