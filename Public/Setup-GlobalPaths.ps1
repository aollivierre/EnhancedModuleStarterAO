
function Setup-GlobalPaths {
    param (
        [string]$ModulesBasePath       # Path to the modules directory
    )

    # Set the modules base path and create if it doesn't exist
    if (-Not (Test-Path $ModulesBasePath)) {
        Write-EnhancedModuleStarterLog "ModulesBasePath '$ModulesBasePath' does not exist. Creating directory..." -Level "INFO"
        New-Item -Path $ModulesBasePath -ItemType Directory -Force
    }
    $global:modulesBasePath = $ModulesBasePath

    # Log the paths for verification
    Write-EnhancedModuleStarterLog "Modules Base Path: $global:modulesBasePath" -Level "INFO"
}