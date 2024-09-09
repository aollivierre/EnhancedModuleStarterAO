function Ensure-GitIsInstalled {
    param (
        [version]$MinVersion = [version]"2.46.0",
        [string]$RegistryPath = "HKLM:\SOFTWARE\GitForWindows",
        [string]$ExePath = "C:\Program Files\Git\bin\git.exe"
    )

    Write-EnhancedLog -Message "Checking if Git is installed and meets the minimum version requirement." -Level "INFO"

    # Use the Validate-SoftwareInstallation function to check if Git is installed and meets the version requirement
    $validationResult = Validate-SoftwareInstallation -SoftwareName "Git" -MinVersion $MinVersion -RegistryPath $RegistryPath -ExePath $ExePath

    if ($validationResult.IsInstalled) {
        Write-EnhancedLog -Message "Git version $($validationResult.Version) is installed and meets the minimum version requirement." -Level "INFO"
        return $true
    }
    else {
        Write-EnhancedLog -Message "Git is not installed or does not meet the minimum version requirement. Installing Git..." -Level "WARNING"
        $installSuccess = Install-GitFromWeb
        return $installSuccess
    }
}