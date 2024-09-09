function Import-EnhancedModules {
    param (
        [string]$modulePsd1Path, # Path to the PSD1 file containing the list of modules to install and import
        [string]$ScriptPath  # Path to the PSD1 file containing the list of modules to install and import
    )

    # Validate PSD1 file path
    if (-not (Test-Path -Path $modulePsd1Path)) {
        Write-EnhancedModuleStarterLog "modules.psd1 file not found at path: $modulePsd1Path" -Level "ERROR"
        throw "modules.psd1 file not found."
    }


    # Check if we need to re-launch in PowerShell 5
    Invoke-InPowerShell5 -ScriptPath $ScriptPath

    # If running in PowerShell 5, reset the module paths and proceed with the rest of the script
    Reset-ModulePaths

    # Import the PSD1 data
    $moduleData = Import-PowerShellDataFile -Path $modulePsd1Path
    $modulesToImport = $moduleData.requiredModules

    foreach ($moduleName in $modulesToImport) {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-EnhancedModuleStarterLog "Module $moduleName is not installed. Attempting to install..." -Level "INFO"
            Install-EnhancedModule -ModuleName $moduleName -ScriptPath $ScriptPath
        }

        Write-EnhancedModuleStarterLog "Importing module: $moduleName" -Level "INFO"
        try {
            Import-Module -Name $moduleName -Verbose:$true -Force:$true -Global:$true
        }
        catch {
            Write-EnhancedModuleStarterLog "Failed to import module $moduleName. Error: $_" -Level "ERROR"
        }
    }
}