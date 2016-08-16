# download latest

function Invoke-PaubyTests 
{
    [CmdletBinding()]
    Param (
        [switch]$Force,

        [ValidateScript( { Test-Path $_ } )]
        [string[]]
        $TestName
    )

    $SettingsFilename = "PaubyTesterSettings.psd1"
 
    # Look for the settings file in the current directory and if doesn't exist look for the default in teh module directory
    $settingsPath = $SettingsFilename
    Write-Verbose "Looking for settings file at $settingsPath (current directory)."
    if (-not (Test-Path $settingsPath)) {
        Write-Verbose "Settings file not found in the current directory." 
        $settingsPath = (Join-Path -Path $PSScriptRoot -ChildPath $SettingsFilename)
        Write-Verbose "Looking for settings file at $settingsPath"  
        if (-not (Test-Path $settingsPath)) {
            throw "Cannot continue. Settings file $SettingsFilename not found at current directory or module directory $PSScriptRoot"
            Exit
        }
    }
    Write-Verbose "Settings file found at $settingsPath"
    Write-Verbose "Importing the settings from $settingsPath"
    $settings = Import-LocalizedData -BaseDirectory (Split-Path -Path (Get-Item $settingsPath).Fullname -Parent) -FileName (Split-Path $settingsPath -Leaf)

    # setup a few variable we will use throughout
    $rulesAbsoluteDirectory = Join-Path -Path $PSScriptRoot -ChildPath $settings.RulesBaseDirectory 
    $testsAbsoluteDirectory = Join-Path -Path (Get-Location) -ChildPath $settings.TestsBaseDirectory

    # check we directory structure setup
    Write-Verbose "Checking folder structure."
    Write-Verbose "Checking $rulesAbsoluteDirectory exists." 
    if (-not (Test-Path $rulesAbsoluteDirectory)) {
        Write-Verbose "Creating folder $rulesAbsoluteDirectory"
        New-Item -Path $rulesAbsoluteDirectory -ItemType Directory
    }

    # the force parameter requires us to download the files anyway so no need to check this next bit
    if (-not $Force) {
        Write-Verbose "Checking we have the rules already downloaded."
        $forceDownload = $false
        foreach ($rule in $settings.RulesUrl) {
            $rulePath = Join-Path -Path $rulesAbsoluteDirectory -ChildPath (Split-Path -Path $rule -Leaf)
            Write-Verbose "Checking for $rulePath"
            if (-not (Test-Path $rulePath)) {
                Write-Verbose "One or more rules are missing so downloading."
                $forceDownload = $true
                break
            }
        }
    }

    if ($Force -or $forceDownload) {
        Write-Verbose "Downloading rules."
        foreach ($rule in $settings.RulesURL) {
            $filename = Split-Path -Path $rule -Leaf
            Write-Verbose "Downloading $rule"
            try {
                Invoke-WebRequest -Uri $rule -Out (Join-Path -Path $rulesAbsoluteDirectory -ChildPath $filename)
            }
            catch [System.Exception] {
                Write-Error "Cannot download $rule"
                break
            }
        }
    }

    # Before we import any modules we must import PSScriptAnalyzer
    try {
        Write-Verbose "Importing PSScriptAnalyzer"
        Import-Module PSScriptAnalyzer
    }
    catch
    {
        Write-Host "The PSScriptAnalyzer module must be available to import."
    }

    # Import any modules
    # we find the modules by checking the extension of the url's we download - modules are classified as having the extension psd1
    $rulesModules = $rulesUrl | where { [io.path]::GetExtension($_) -match ".psd1" } | Split-Path -Leaf
    foreach ($module in $rulesModules) {
        Write-Verbose "Importing Script Analyzer Rules module $module"
        Import-Module (Join-Path -Path $rulesPath -ChildPath $module)
    }

    if ($TestName) {
        $testScripts = (Get-Item -Path $TestName)
    }
    else {
        $testScripts = (Get-ChildItem -Path (Join-Path -Path $testsAbsoluteDirectory -ChildPath $settings.TestsName))
    }
    Write-Verbose "$($testScripts.count) tests found."

    foreach ($test in $testScripts) {
        Invoke-Pester $test.fullname
    }
}