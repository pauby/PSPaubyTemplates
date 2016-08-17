$script:SettingsFilename = "PaubyTesterSettings.psd1"

function Get-PaubyTestingSettings
{
    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [string]
        $Settings = $script:SettingsFilename
    )

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
    return (Import-LocalizedData -BaseDirectory (Split-Path -Path (Get-Item $settingsPath).Fullname -Parent) -FileName (Split-Path $settingsPath -Leaf))
}

function Get-PaubyTestingRules {
    [CmdletBinding()]
    Param (
        [switch]$Force,

        [ValidateNotNullOrEmpty()]
        [string]
        $Settings = $script:SettingsFilename
    )

    $config = Get-PaubyTestingSettings -Settings $Settings
    $rulesAbsoluteDirectory = (Join-Path -Path (Get-Location) -ChildPath $config.RulesBaseDirectory)

    # check we directory structure setup
    Write-Verbose "Checking folder structure."
    Write-Verbose "Checking $rulesAbsoluteDirectory exists." 
    if (-not (Test-Path $rulesAbsoluteDirectory)) {
        Write-Verbose "Creating folder $rulesAbsoluteDirectory"
        New-Item -Path $rulesAbsoluteDirectory -ItemType Directory | Out-Null
    }

    # the force parameter requires us to download the files anyway so no need to check this next bit
    if (-not $Force) {
        Write-Verbose "Checking we have the rules already downloaded."
        $forceDownload = $false
        foreach ($rule in $config.RulesUrl) {
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
        foreach ($rule in $config.RulesUrl) {
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
}