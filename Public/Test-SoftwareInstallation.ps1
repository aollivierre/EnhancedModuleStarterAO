function Get-SoftwareFromRegistry {
    param (
        [string]$SoftwareName,
        [string[]]$RegistryPaths
    )

    foreach ($path in $RegistryPaths) {
        Write-EnhancedLog -Message "Checking registry path: $path" -Level "INFO"

        if (Test-Path $path) {
            try {
                $subkeys = Get-ChildItem -Path $path -ErrorAction Stop
                foreach ($subkey in $subkeys) {
                    $app = Get-ItemProperty -Path $subkey.PSPath -ErrorAction Stop
                    if ($app.DisplayName -like "*$SoftwareName*") {
                        Write-EnhancedLog -Message "Found $SoftwareName at $path with version $($app.DisplayVersion)." -Level "INFO"

                        return [PSCustomObject]@{
                            IsInstalled = $true
                            Version     = $app.DisplayVersion
                        }
                    }
                }
            }
            catch {
                Write-EnhancedLog -Message "Failed to retrieve properties from registry path: $path. Error: $_" -Level "CRITICAL"
            }
        }
        else {
            Write-EnhancedLog -Message "Registry path $path does not exist." -Level "WARNING"
        }
    }

    return $null
}

function Get-SoftwareFromExe {
    param (
        [string]$ExePath,
        [string]$SoftwareName
    )

    if (Test-Path $ExePath) {
        $fileVersion = (Get-Item -Path $ExePath).VersionInfo.FileVersion
        Write-EnhancedLog -Message "Found $SoftwareName executable at $ExePath with version $fileVersion." -Level "INFO"

        return [PSCustomObject]@{
            IsInstalled = $true
            Version     = $fileVersion
        }
    }
    else {
        Write-EnhancedLog -Message "Executable path $ExePath does not exist." -Level "WARNING"
        return $null
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

    Begin {
        Write-EnhancedLog -Message "Starting Test-SoftwareInstallation function for $SoftwareName" -Level "NOTICE"

        $defaultRegistryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        if ($RegistryPath) {
            $defaultRegistryPaths += $RegistryPath
        }
    }

    Process {
        # Check registry paths first
        $registryResult = Get-SoftwareFromRegistry -SoftwareName $SoftwareName -RegistryPaths $defaultRegistryPaths

        if ($registryResult) {
            return $registryResult  # Immediately return the result from the registry check
        }

        # Check EXE path if not found in registry
        if ($ExePath) {
            $exeResult = Get-SoftwareFromExe -ExePath $ExePath -SoftwareName $SoftwareName

            if ($exeResult) {
                return $exeResult  # Immediately return the result from the executable check
            }
        }

        # If neither registry nor EXE path validation succeeded, return a result indicating not installed
        return [PSCustomObject]@{
            IsInstalled = $false
            Version     = $null
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Test-SoftwareInstallation function for $SoftwareName." -Level "NOTICE"
    }
}

