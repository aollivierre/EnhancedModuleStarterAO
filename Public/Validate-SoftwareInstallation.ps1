function Validate-SoftwareInstallation {
    <#
    .SYNOPSIS
    Validates whether a software is installed and checks its version against specified requirements.

    .DESCRIPTION
    This function checks if a software is installed by searching specific registry paths or an executable path, and compares the installed version against the minimum and latest versions.

    .PARAMETER SoftwareName
    The name of the software to validate.

    .PARAMETER MinVersion
    The minimum version of the software required. Default is "0.0.0.0".

    .PARAMETER LatestVersion
    The latest version of the software available.

    .PARAMETER RegistryPath
    A specific registry path to check for the software installation.

    .PARAMETER ExePath
    The path to the software's executable file.

    .EXAMPLE
    $params = @{
        SoftwareName  = "7-Zip"
        MinVersion    = [version]"19.00"
        LatestVersion = [version]"24.08.00.0"
        RegistryPath  = "HKLM:\SOFTWARE\7-Zip"
        ExePath       = "C:\Program Files\7-Zip\7z.exe"
    }
    Validate-SoftwareInstallation @params
    #>

    [CmdletBinding()]
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
        Write-EnhancedLog -Message "Starting validation for $SoftwareName" -Level "NOTICE"

        $retryCount = 0
        $isInstalled = $false
        $installedVersion = $null

        $result = [PSCustomObject]@{
            IsInstalled         = $false
            Version             = $null
            MeetsMinRequirement = $false
            IsUpToDate          = $false
        }
    }

    Process {
        while ($retryCount -lt $MaxRetries -and -not $isInstalled) {
            $retryCount++
            Write-EnhancedLog -Message "Attempt $retryCount of $MaxRetries to validate $SoftwareName installation." -Level "INFO"

            $installResult = Test-SoftwareInstallation -SoftwareName $SoftwareName -RegistryPath $RegistryPath -ExePath $ExePath

            if ($installResult.IsInstalled) {
                $isInstalled = $true
                $installedVersion = [version]$installResult.Version
                $result.IsInstalled = $true
                $result.Version = $installedVersion
                Write-EnhancedLog -Message "$SoftwareName is installed. Detected version: $installedVersion" -Level "INFO"
                break
            } else {
                Write-EnhancedLog -Message "Validation attempt $retryCount failed: $SoftwareName not found. Retrying in $DelayBetweenRetries seconds..." -Level "WARNING"
                Start-Sleep -Seconds $DelayBetweenRetries
            }
        }

        if (-not $isInstalled) {
            Write-EnhancedLog -Message "$SoftwareName is not installed after $MaxRetries retries." -Level "ERROR"
            return $result
        }

        # Use the Compare-SoftwareVersion function to compare versions
        Write-EnhancedLog -Message "Comparing installed version of $SoftwareName with minimum and latest versions." -Level "INFO"
        $versionComparison = Compare-SoftwareVersion -InstalledVersion $installedVersion -MinVersion $MinVersion -LatestVersion $LatestVersion

        $result.MeetsMinRequirement = $versionComparison.MeetsMinRequirement
        $result.IsUpToDate = $versionComparison.IsUpToDate

        Write-EnhancedLog -Message "Validation complete for $SoftwareName. Meets minimum requirements: $($result.MeetsMinRequirement). Is up-to-date: $($result.IsUpToDate)." -Level "INFO"

        return $result
    }
}
