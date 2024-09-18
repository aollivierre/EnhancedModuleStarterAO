
function Initialize-Environment {
    param (
        [string]$Mode, # Accepts either 'dev' or 'prod'
        [string]$ExecutionMode, # Accepts either 'parallel' or 'series'
        # [string]$WindowsModulePath, # Path to the Windows module
        [string]$ModulesBasePath, # Custom modules base path,
        [PSCustomObject[]]$scriptDetails,

        [Parameter(Mandatory = $false)]
        [string]$ScriptDirectory,

        [Parameter(Mandatory = $false, HelpMessage = "Skip installation of enhanced modules.")]
        [bool]$SkipEnhancedModules = $false
    )
 
    if ($Mode -eq "dev") {
        
        $gitInstalled = Ensure-GitIsInstalled
        if ($gitInstalled) {
            Write-EnhancedLog -Message "Git installation check completed successfully." -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "Failed to install Git." -Level "ERROR"
        }

        if (-not $SkipGitRepos) {
            Manage-GitRepositories -ModulesBasePath 'C:\Code\modulesv2'
            Write-EnhancedLog -Message "Git repose checked successfully." -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "Skipping Git Repos" -Level "INFO"
        }
       
        # Call Setup-GlobalPaths with custom paths
        Setup-GlobalPaths -ModulesBasePath $ModulesBasePath
        # Check if the directory exists and contains any files (not just the directory existence)
        if (-Not (Test-Path "$global:modulesBasePath\*.*")) {
            Write-EnhancedLog -Message "Modules not found or directory is empty at $global:modulesBasePath. Initiating download..." -Level "INFO"
            # Download-Modules -scriptDetails $scriptDetails

            if (-not $SkipEnhancedModules) {
                # Download-Modules -scriptDetails $scriptDetails

                # Example usage: Call the main function with the script details
                Invoke-CloneEnhancedRepos -scriptDetails $scriptDetails -ScriptDirectory $ScriptDirectory

                Write-EnhancedLog -Message "Modules downloaded successfully." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Skipping module download as per the provided parameter." -Level "INFO"
            }

            # Re-check after download attempt
            if (-Not (Test-Path "$global:modulesBasePath\*.*")) {
                throw "Download failed or the modules were not placed in the expected directory."
            }
        }
        else {
            Write-EnhancedLog -Message "Source Modules already exist at $global:modulesBasePath" -Level "INFO"
        }

        Write-EnhancedLog -Message "Starting to call Import-LatestModulesLocalRepository..."
        Import-ModulesFromLocalRepository -ModulesFolderPath $global:modulesBasePath
    }
    elseif ($Mode -eq "prod") {
        # Log the start of the process
        Write-EnhancedLog -Message "Production mode selected. Importing modules..." -Level "INFO"

        Reset-ModulePaths
        # Ensure NuGet provider is installed
        Ensure-NuGetProvider

        # Define the PSD1 file URLs and local paths
        $psd1Url = "https://raw.githubusercontent.com/aollivierre/module-starter/main/Enhanced-modules.psd1"
        $localPsd1Path = "$env:TEMP\enhanced-modules.psd1"

        # Download the PSD1 file
        Download-Psd1File -url $psd1Url -destinationPath $localPsd1Path

        # Install and import modules based on the PSD1 file
        InstallAndImportModulesPSGallery -modulePsd1Path $localPsd1Path -ExecutionMode $ExecutionMode

        # Handle third-party PS Gallery modules
        if ($SkipPSGalleryModules) {
            Write-EnhancedLog -Message "Skipping third-party PS Gallery Modules" -Level "INFO"
        }
        else {
            Write-EnhancedLog -Message "Starting PS Gallery Module installation" -Level "INFO"

            # Reset the module paths in PS5
            Reset-ModulePaths

            # Ensure NuGet provider is installed
            Ensure-NuGetProvider

            # Download and process the third-party modules PSD1 file
            $psd1Url = "https://raw.githubusercontent.com/aollivierre/module-starter/main/modules.psd1"
            $localPsd1Path = "$env:TEMP\modules.psd1"
    
            Download-Psd1File -url $psd1Url -destinationPath $localPsd1Path
            InstallAndImportModulesPSGallery -modulePsd1Path $localPsd1Path -ExecutionMode $ExecutionMode
        }
    }
}