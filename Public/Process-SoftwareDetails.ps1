
function Process-SoftwareDetails {
    param (
        [PSCustomObject]$detail,
        [string]$powerShellPath,
        [ref]$installationResults,
        [ref]$processList
    )

    $url = $detail.Url
    $softwareName = $detail.SoftwareName
    $minVersion = $detail.MinVersion
    $registryPath = $detail.RegistryPath

    # Validate the existing installation
    Write-EnhancedLog "Validating existing installation of $softwareName..."
    $installationCheck = if ($registryPath) {
        Validate-SoftwareInstallation -SoftwareName $softwareName -MinVersion $minVersion -MaxRetries 3 -DelayBetweenRetries 5 -RegistryPath $registryPath
    }
    else {
        Validate-SoftwareInstallation -SoftwareName $softwareName -MinVersion $minVersion -MaxRetries 3 -DelayBetweenRetries 5
    }

    if ($installationCheck.IsInstalled) {
        Write-EnhancedLog "$softwareName version $($installationCheck.Version) is already installed. Skipping installation." -Level "INFO"
        $installationResults.Value.Add([pscustomobject]@{ SoftwareName = $softwareName; Status = "Already Installed"; VersionFound = $installationCheck.Version })
    }
    else {
        if (Test-Url -url $url) {
            Log-Step
            Write-EnhancedLog "Running script from URL: $url" -Level "INFO"
            $process = Start-Process -FilePath $powerShellPath -ArgumentList @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "Invoke-Expression (Invoke-RestMethod -Uri '$url')") -Verb RunAs -PassThru
            $processList.Value.Add($process)

            $installationResults.Value.Add([pscustomobject]@{ SoftwareName = $softwareName; Status = "Installed"; VersionFound = "N/A" })
        }
        else {
            Write-EnhancedLog "URL $url is not accessible" -Level "ERROR"
            $installationResults.Value.Add([pscustomobject]@{ SoftwareName = $softwareName; Status = "Failed - URL Not Accessible"; VersionFound = "N/A" })
        }
    }
}