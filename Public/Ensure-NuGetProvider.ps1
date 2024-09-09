function Ensure-NuGetProvider {
    # Ensure NuGet provider and PowerShellGet module are installed if running in PowerShell 5
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -Confirm:$false
            Install-Module -Name PowerShellGet -Force -AllowClobber
            Write-EnhancedModuleStarterLog "NuGet provider installed successfully." -Level "INFO"
        }
        else {
            Write-EnhancedModuleStarterLog "NuGet provider is already installed." -Level "INFO"
        }
    }
    else {
        Write-EnhancedModuleStarterLog "This script is running in PowerShell version $($PSVersionTable.PSVersion) which is not version 5. No action is taken for NuGet" -Level "INFO"
    }
}
