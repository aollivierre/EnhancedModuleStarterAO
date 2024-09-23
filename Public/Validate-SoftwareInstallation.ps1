#v6 Refactored
function Compare-SoftwareVersion {
    param (
        [Parameter(Mandatory = $true)]
        [version]$InstalledVersion,

        [Parameter(Mandatory = $false)]
        [version]$MinVersion = [version]"0.0.0.0",

        [Parameter(Mandatory = $false)]
        [version]$LatestVersion
    )

    $meetsMinRequirement = $InstalledVersion -ge $MinVersion
    
    if ($LatestVersion) {
        $isUpToDate = $InstalledVersion -ge $LatestVersion
    } else {
        $isUpToDate = $meetsMinRequirement
    }

    return [PSCustomObject]@{
        MeetsMinRequirement = $meetsMinRequirement
        IsUpToDate          = $isUpToDate
        Timestamp           = (Get-Date).ToString("o")
    }
}

function Test-SoftwareInstallation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,

        [Parameter(Mandatory = $false)]
        [string]$RegistryPath = "",

        [Parameter(Mandatory = $false)]
        [string]$ExePath = ""
    )

    $uniqueId = [Guid]::NewGuid().ToString()
    $envVarName = "SoftwareInstallationStatus_$uniqueId"

    # Initialize the result object with all expected properties
    $result = [PSCustomObject]@{
        IsInstalled         = $false
        Version             = $null
        InstallationPath    = $null
        Status              = "Not Found"
        Message             = "Software $SoftwareName not found."
        ErrorMessage        = $null
        ExitCode            = 1
        Timestamp           = (Get-Date).ToString("o")  # ISO 8601 format
        AttemptCount        = 1
        ValidationSource    = "None"
        MeetsMinRequirement = $false  # Add these properties here
        IsUpToDate          = $false  # Add these properties here
    }

    if ($RegistryPath) {
        Write-EnhancedLog -Message "Checking specific registry path: $RegistryPath." -Level "INFO"
        if (Test-Path $RegistryPath) {
            $app = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue
            if ($app -and $app.DisplayName -like "*$SoftwareName*") {
                $installedVersion = Sanitize-VersionString -versionString $app.DisplayVersion
                $result.IsInstalled = $true
                $result.Version = $installedVersion

                # Check if InstallLocation exists and is populated, otherwise fallback to ExePath
                if ($app.PSObject.Properties['InstallLocation'] -and $app.InstallLocation) {
                    $result.InstallationPath = $app.InstallLocation
                } elseif ($ExePath -and (Test-Path $ExePath)) {  # Corrected line
                    Write-EnhancedLog -Message "InstallLocation is not found or empty, using ExePath: $ExePath." -Level "WARNING"
                    $result.InstallationPath = $ExePath
                } else {
                    Write-EnhancedLog -Message "Both InstallLocation and ExePath are not valid for $SoftwareName." -Level "ERROR"
                    $result.ErrorMessage = "Cannot determine installation path."
                    $result.Status = "Failed"
                    $result.Message = "Installation path could not be determined."
                    $result.ExitCode = 2
                }

                $result.Status = "Success"
                $result.Message = "$SoftwareName is installed. Version: $installedVersion"
                $result.ExitCode = 0  # Indicating success
                $result.ValidationSource = "CustomRegistryPath"

                $jsonResult = $result | ConvertTo-Json -Compress
                [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
                
                return $result
            } else {
                $result.ErrorMessage = "Software $SoftwareName not found in the custom registry path."
                $result.Status = "Not Found"
                $result.Message = "Software $SoftwareName not found in the custom registry path."
                $result.ExitCode = 1
            }
        } else {
            Write-EnhancedLog -Message "Custom registry path $RegistryPath does not exist." -Level "ERROR"
            $result.ErrorMessage = "Registry path $RegistryPath does not exist."
            $result.Status = "Failed"
            $result.Message = "Registry path $RegistryPath does not exist."
            $result.ExitCode = 2  # Indicating failure due to missing path
        }

        $jsonResult = $result | ConvertTo-Json -Compress
        [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
        
        return $result
    }

    # If no custom registry path is provided, fall back to default registry locations
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($path in $registryPaths) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
            if ($app.DisplayName -like "*$SoftwareName*") {
                $installedVersion = Sanitize-VersionString -versionString $app.DisplayVersion
                $result.IsInstalled = $true
                $result.Version = $installedVersion

                # Check if InstallLocation exists and is populated, otherwise fallback to ExePath
                if ($app.PSObject.Properties['InstallLocation'] -and $app.InstallLocation) {
                    $result.InstallationPath = $app.InstallLocation
                } elseif ($ExePath -and (Test-Path $ExePath)) {  # Corrected line
                    Write-EnhancedLog -Message "InstallLocation is not found or empty, using ExePath: $ExePath." -Level "WARNING"
                    $result.InstallationPath = $ExePath
                } else {
                    Write-EnhancedLog -Message "Both InstallLocation and ExePath are not valid for $SoftwareName." -Level "ERROR"
                    $result.ErrorMessage = "Cannot determine installation path."
                    $result.Status = "Failed"
                    $result.Message = "Installation path could not be determined."
                    $result.ExitCode = 2
                }

                $result.Status = "Success"
                $result.Message = "$SoftwareName is installed. Version: $installedVersion"
                $result.ExitCode = 0  # Indicating success
                $result.ValidationSource = "Registry"

                $jsonResult = $result | ConvertTo-Json -Compress
                [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
                
                return $result
            }
        }
    }

    # If no software was found in any registry path
    $jsonResult = $result | ConvertTo-Json -Compress
    [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
    
    return $result
}

function Validate-SoftwareInstallation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,

        [Parameter(Mandatory = $false)]
        [version]$MinVersion = [version]"0.0.0.0",

        [Parameter(Mandatory = $false)]
        [version]$LatestVersion,

        [Parameter(Mandatory = $false)]
        [string]$RegistryPath = "",

        [Parameter(Mandatory = $false)]
        [string]$ExePath = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$DelayBetweenRetries = 5
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-SoftwareInstallation function for $SoftwareName" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        $retryCount = 0
        $isInstalled = $false
        $installedVersion = $null

        $uniqueId = [Guid]::NewGuid().ToString()
        $envVarName = "SoftwareInstallationStatus_$uniqueId"

        $result = [PSCustomObject]@{
            IsInstalled         = $false
            MeetsMinRequirement = $false
            IsUpToDate          = $false
            Version             = $null
            ErrorMessage        = $null
            Status              = "Not Found"
            Message             = "Software $SoftwareName not found."
            ExitCode            = 1
            Timestamp           = (Get-Date).ToString("o")
            AttemptCount        = 0
            ValidationSource    = "None"
        }

        while ($retryCount -lt $MaxRetries -and -not $isInstalled) {
            $retryCount++
            $result.AttemptCount = $retryCount
            $result = Test-SoftwareInstallation -SoftwareName $SoftwareName -RegistryPath $RegistryPath -ExePath $ExePath

            if ($result.IsInstalled) {
                Write-EnhancedLog -Message "$SoftwareName is installed. Detected version: $($result.Version)." -Level "INFO"
                break
            } else {
                Write-EnhancedLog -Message "Validation attempt $retryCount failed: $SoftwareName not found. Retrying in $DelayBetweenRetries seconds..." -Level "WARNING"
                Start-Sleep -Seconds $DelayBetweenRetries
            }
        }

        if (-not $result.IsInstalled) {
            Write-EnhancedLog -Message "$SoftwareName is not installed after $MaxRetries retries." -Level "ERROR"
            $result.ErrorMessage = "$SoftwareName is not installed."
            $result.Status = "Failed"
            $result.Message = "$SoftwareName is not installed after $MaxRetries retries."
            $result.ExitCode = 1

            $jsonResult = $result | ConvertTo-Json -Compress
            [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
            
            return $result
        }

        $versionComparison = Compare-SoftwareVersion -InstalledVersion $result.Version -MinVersion $MinVersion -LatestVersion $LatestVersion

        $result.MeetsMinRequirement = $versionComparison.MeetsMinRequirement
        $result.IsUpToDate = $versionComparison.IsUpToDate
        $result.ExitCode = if ($versionComparison.MeetsMinRequirement -and $versionComparison.IsUpToDate) { 0 } elseif (-not $versionComparison.MeetsMinRequirement) { 3 } else { 4 }

        $jsonResult = $result | ConvertTo-Json -Compress
        [System.Environment]::SetEnvironmentVariable($envVarName, $jsonResult, "Process")
        
        return $result
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-SoftwareInstallation function for $SoftwareName." -Level "NOTICE"
        exit $result.ExitCode
    }
}