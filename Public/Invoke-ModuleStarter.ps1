function Invoke-ModuleStarter {
    param (
        [string]$Mode = "dev",
        [bool]$SkipPSGalleryModules = $false,
        [bool]$SkipCheckandElevate = $false,
        [bool]$SkipPowerShell7Install = $false,
        [bool]$SkipEnhancedModules = $false,
        [bool]$SkipGitRepos = $false
    )

    # Log the parameters
    Write-Host "The Module Starter script is running in mode: $Mode"
    Write-Host "The Module Starter SkipPSGalleryModules is set to: $SkipPSGalleryModules"
    Write-Host "The Module Starter SkipCheckandElevate is set to: $SkipCheckandElevate"
    Write-Host "The Module Starter SkipPowerShell7Install is set to: $SkipPowerShell7Install"
    Write-Host "The Module Starter SkipEnhancedModules is set to: $SkipEnhancedModules"
    Write-Host "The Module Starter SkipGitRepos is set to: $SkipGitRepos"

    # Report the current PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Host "Current PowerShell Version: $psVersion" -ForegroundColor Green
    Write-Host "Full PowerShell Version Details:"
    $PSVersionTable | Format-Table -AutoSize

    # $processList = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
    # $ScriptPath = $MyInvocation.MyCommand.Definition
    # $global:currentStep = 0

    # Install PSFramework module if not installed
    if (-not $SkipPSGalleryModules) {
        Write-Host "Installing PSFramework module..." -ForegroundColor Cyan
        Install-Module -Name PSFramework -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck -Verbose
    }

    # Define script details for initialization
    $initializeParams = @{
        Mode              = $Mode
        WindowsModulePath = "EnhancedBoilerPlateAO\EnhancedBoilerPlateAO.psm1"
        ModulesBasePath   = "C:\code\modulesv2"
        scriptDetails     = @(
            @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-Git.ps1"; SoftwareName = "Git"; MinVersion = [version]"2.41.0.0" },
            @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-GitHubCLI.ps1"; SoftwareName = "GitHub CLI"; MinVersion = [version]"2.54.0" }
        )
    }

    # Check and elevate permissions if required
    if (-not $SkipCheckandElevate) {
        Write-EnhancedModuleStarterLog -Message "Checking and elevating permissions if necessary." -Level "INFO"
        CheckAndElevate -ElevateIfNotAdmin $true
    }
    else {
        Write-EnhancedModuleStarterLog -Message "Skipping CheckAndElevate due to SkipCheckandElevate parameter." -Level "INFO"
    }

    # Initialize environment based on the mode and other parameters
    Write-Host "Initializing environment..." -ForegroundColor Cyan
    Initialize-Environment @initializeParams

    # Setup logging
    Write-EnhancedModuleStarterLog -Message "Script Started in $Mode mode" -Level "INFO"
}