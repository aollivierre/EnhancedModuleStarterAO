function Ensure-ModuleIsLatest {
    param (
        [string]$ModuleName
    )

    Write-EnhancedModuleStarterLog -Message "Checking if the latest version of $ModuleName is installed..." -Level "INFO"

    try {

        if ($SkipCheckandElevate) {
            Write-EnhancedModuleStarterLog -Message "Skipping CheckAndElevate due to SkipCheckandElevate parameter." -Level "INFO"
        }
        else {
            CheckAndElevate -ElevateIfNotAdmin $true
        }
        
        Invoke-InPowerShell5

        Reset-ModulePaths

        # Get the installed version of the module, if any
        $installedModule = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

        # Get the latest available version of the module from PSGallery
        $latestModule = Find-Module -Name $ModuleName

        if ($installedModule) {
            if ($installedModule.Version -lt $latestModule.Version) {
                Write-EnhancedModuleStarterLog -Message "$ModuleName version $($installedModule.Version) is installed, but version $($latestModule.Version) is available. Updating module..." -Level "WARNING"
                Install-Module -Name $ModuleName -Scope AllUsers -Force -SkipPublisherCheck -Verbose
            }
            else {
                Write-EnhancedModuleStarterLog -Message "The latest version of $ModuleName is already installed. Version: $($installedModule.Version)" -Level "INFO"
            }
        }
        else {
            Write-EnhancedModuleStarterLog -Message "$ModuleName is not installed. Installing the latest version $($latestModule.Version)..." -Level "WARNING"
            Install-Module -Name $ModuleName -Scope AllUsers -Force -SkipPublisherCheck -Verbose -AllowClobber
        }
    }
    catch {
        Write-EnhancedModuleStarterLog -Message "Error occurred while checking or installing $ModuleName $_" -Level "ERROR"
        throw
    }
}
