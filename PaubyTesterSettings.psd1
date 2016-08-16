# Settings file for PSPaubyTesting module

@{
    RulesUrl = @( 'https://raw.githubusercontent.com/PowerShell/PSScriptAnalyzer/development/Tests/Engine/CommunityAnalyzerRules/CommunityAnalyzerRules.psd1',
                'https://raw.githubusercontent.com/PowerShell/PSScriptAnalyzer/development/Tests/Engine/CommunityAnalyzerRules/CommunityAnalyzerRules.psm1'
            )
    RulesBaseDirectory = "Rules"
    TestsBaseDirectory = "Tests"
    TestsName = "*.Tests.ps1"
}