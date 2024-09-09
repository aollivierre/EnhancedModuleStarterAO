function Validate-InstallationResults {
    param (
        [ref]$processList,
        [ref]$installationResults,
        [PSCustomObject[]]$scriptDetails
    )

    # Wait for all processes to complete
    foreach ($process in $processList.Value) {
        $process.WaitForExit()
    }

    # Post-installation validation
    foreach ($result in $installationResults.Value) {
        if ($result.Status -eq "Installed") {
            if ($result.SoftwareName -in @("RDP", "Windows Terminal")) {
                Write-Log "Skipping post-installation validation for $($result.SoftwareName)." -Level "INFO"
                $result.Status = "Successfully Installed"
                continue
            }

            Write-Log "Validating installation of $($result.SoftwareName)..."
            $validationResult = Validate-SoftwareInstallation -SoftwareName $result.SoftwareName -MinVersion ($scriptDetails | Where-Object { $_.SoftwareName -eq $result.SoftwareName }).MinVersion

            if ($validationResult.IsInstalled) {
                Write-Log "Validation successful: $($result.SoftwareName) version $($validationResult.Version) is installed." -Level "INFO"
                $result.VersionFound = $validationResult.Version
                $result.Status = "Successfully Installed"
            }
            else {
                Write-Log "Validation failed: $($result.SoftwareName) was not found on the system." -Level "ERROR"
                $result.Status = "Failed - Not Found After Installation"
            }
        }
    }
}
