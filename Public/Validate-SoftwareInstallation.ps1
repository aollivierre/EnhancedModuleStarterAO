function Validate-SoftwareInstallation {
    <#
    .SYNOPSIS
    Validates the installation of a specified software by checking registry or file-based versions.

    .DESCRIPTION
    The function checks if the specified software is installed, either through registry validation or file-based validation, and ensures that the installed version meets a specified minimum version. Supports retries in case of transient issues.

    .PARAMETER SoftwareName
    The name of the software to validate.

    .PARAMETER MinVersion
    The minimum version of the software required for validation.

    .PARAMETER RegistryPath
    The specific registry path to validate the software installation.

    .PARAMETER ExePath
    The path to the executable file of the software for file-based validation.

    .PARAMETER MaxRetries
    The maximum number of retry attempts for validation.

    .PARAMETER DelayBetweenRetries
    The delay in seconds between retry attempts.

    .EXAMPLE
    $params = @{
        SoftwareName        = 'MySoftware'
        MinVersion          = '1.0.0.0'
        RegistryPath        = 'HKLM:\SOFTWARE\MySoftware'
        ExePath             = 'C:\Program Files\MySoftware\mysoftware.exe'
        MaxRetries          = 3
        DelayBetweenRetries = 5
    }
    Validate-SoftwareInstallation @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the software name.")]
        [ValidateNotNullOrEmpty()]
        [string]$SoftwareName,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the minimum software version required.")]
        [ValidateNotNullOrEmpty()]
        [version]$MinVersion = [version]"0.0.0.0",

        [Parameter(Mandatory = $false, HelpMessage = "Specify a registry path for validation.")]
        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath = "",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the path to the software executable for validation.")]
        [ValidateNotNullOrEmpty()]
        [string]$ExePath = "",

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retries for validation.")]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds between retries.")]
        [ValidateRange(1, 60)]
        [int]$DelayBetweenRetries = 5
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-SoftwareInstallation function for $SoftwareName" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        $retryCount = 0
        $validationSucceeded = $false
        $foundVersion = $null

        while ($retryCount -lt $MaxRetries -and -not $validationSucceeded) {
            # Registry-based validation
            if ($RegistryPath -or $SoftwareName) {
                Write-EnhancedLog -Message "Starting registry-based validation for $SoftwareName." -Level "INFO"

                $registryPaths = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
                )

                if ($RegistryPath) {
                    Write-EnhancedLog -Message "Checking specific registry path: $RegistryPath." -Level "INFO"
                    if (Test-Path $RegistryPath) {
                        $app = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue
                        if ($app -and $app.DisplayName -like "*$SoftwareName*") {
                            $installedVersion = Sanitize-VersionString -versionString $app.DisplayVersion
                            $foundVersion = $installedVersion
                            if ($installedVersion -ge $MinVersion) {
                                Write-EnhancedLog -Message "Registry validation succeeded: $SoftwareName version $installedVersion found." -Level "INFO"
                                return @{
                                    IsInstalled = $true
                                    Version     = $installedVersion
                                    ProductCode = $app.PSChildName
                                }
                            }
                        }
                    }
                } else {
                    Write-EnhancedLog -Message "Checking common uninstall registry paths for $SoftwareName." -Level "INFO"
                    foreach ($path in $registryPaths) {
                        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                        foreach ($item in $items) {
                            $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
                            if ($app.DisplayName -like "*$SoftwareName*") {
                                $installedVersion = Sanitize-VersionString -versionString $app.DisplayVersion
                                $foundVersion = $installedVersion
                                if ($installedVersion -ge $MinVersion) {
                                    Write-EnhancedLog -Message "Registry validation succeeded: $SoftwareName version $installedVersion found." -Level "INFO"
                                    return @{
                                        IsInstalled = $true
                                        Version     = $installedVersion
                                        ProductCode = $app.PSChildName
                                    }
                                }
                            }
                        }
                    }
                }
            }

            # File-based validation
            if ($ExePath) {
                Write-EnhancedLog -Message "Starting file-based validation for $SoftwareName at $ExePath." -Level "INFO"
                if (Test-Path $ExePath) {
                    $appVersionString = (Get-ItemProperty -Path $ExePath).VersionInfo.ProductVersion.Split(" ")[0]
                    $appVersion = Sanitize-VersionString -versionString $appVersionString
                    $foundVersion = $appVersion

                    if ($appVersion -ge $MinVersion) {
                        Write-EnhancedLog -Message "File-based validation succeeded: $SoftwareName version $appVersion found." -Level "INFO"
                        return @{
                            IsInstalled = $true
                            Version     = $appVersion
                            Path        = $ExePath
                        }
                    } else {
                        Write-EnhancedLog -Message "File-based validation failed: $SoftwareName version $appVersion does not meet the minimum requirement ($MinVersion)." -Level "ERROR"
                    }
                } else {
                    Write-EnhancedLog -Message "File-based validation failed: $SoftwareName executable not found at $ExePath." -Level "ERROR"
                }
            }

            # Retry logic
            if ($foundVersion) {
                Write-EnhancedLog -Message "$SoftwareName version $foundVersion was found, but does not meet the minimum version requirement ($MinVersion)." -Level "ERROR"
            } else {
                Write-EnhancedLog -Message "Validation attempt $retryCount failed: $SoftwareName not found or does not meet the version requirement. Retrying in $DelayBetweenRetries seconds..." -Level "WARNING"
            }

            $retryCount++
            Start-Sleep -Seconds $DelayBetweenRetries
        }

        Write-EnhancedLog -Message "Validation failed after $MaxRetries retries: $SoftwareName not found or version did not meet the minimum requirement." -Level "ERROR"
        return @{ IsInstalled = $false; Version = $foundVersion }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-SoftwareInstallation function for $SoftwareName." -Level "NOTICE"
    }
}