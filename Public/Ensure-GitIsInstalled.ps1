function Ensure-GitIsInstalled {
    <#
    .SYNOPSIS
    Ensures that Git is installed and meets the minimum version requirement.

    .DESCRIPTION
    The Ensure-GitIsInstalled function checks if Git is installed on the system and meets the specified minimum version requirement. If Git is not installed or does not meet the requirement, it attempts to install Git from the web. The function logs all steps and handles errors appropriately.

    .PARAMETER MinVersion
    The minimum version of Git required.

    .PARAMETER RegistryPath
    The registry path to check for Git installation.

    .PARAMETER ExePath
    The full path to the Git executable.

    .EXAMPLE
    $params = @{
        MinVersion    = [version]"2.46.0"
        RegistryPath  = "HKLM:\SOFTWARE\GitForWindows"
        ExePath       = "C:\Program Files\Git\bin\git.exe"
    }
    Ensure-GitIsInstalled @params
    Ensures that Git is installed and meets the minimum version requirement.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Provide the minimum required version of Git.")]
        [ValidateNotNullOrEmpty()]
        [version]$MinVersion,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the registry path to check for Git installation.")]
        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the full path to the Git executable.")]
        [ValidateNotNullOrEmpty()]
        [string]$ExePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Ensure-GitIsInstalled function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Parameters for validating the installation
        $validateSoftwareParams = @{
            SoftwareName        = "Git"
            # MinVersion          = $MinVersion
            # RegistryPath        = $RegistryPath
            # ExePath             = $ExePath
            MinVersion          = [version]"2.46.0"
            RegistryPath        = "HKLM:\SOFTWARE\GitForWindows"
            ExePath             = "C:\Program Files\Git\bin\git.exe"
            LatestVersion       = $null  # Optional, can be provided if needed
            MaxRetries          = 3      # Default value
            DelayBetweenRetries = 5      # Default value in seconds
        }
    }

    Process {
        try {
            # Validate if Git is installed and meets the version requirement
            Write-EnhancedLog -Message "Checking if Git is installed and meets the minimum version requirement." -Level "INFO"
            $validationResult = Validate-SoftwareInstallation @validateSoftwareParams

            if ($validationResult.IsInstalled) {
                Write-EnhancedLog -Message "Git version $($validationResult.InstalledVersion) is installed and meets the minimum version requirement." -Level "INFO"
                return $true
            }
            else {
                Write-EnhancedLog -Message "Git is not installed or does not meet the minimum version requirement. Installing Git..." -Level "WARNING"
                $installSuccess = Install-GitFromWeb
                return $installSuccess
            }
        }
        catch {
            Write-EnhancedLog -Message "Error ensuring Git installation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        Finally {
            Write-EnhancedLog -Message "Exiting Ensure-GitIsInstalled function" -Level "Notice"
        }
    }

    End {
        # No additional actions needed in the End block for this function.
    }
}

# Example usage
# $params = @{
#     MinVersion    = [version]"2.46.0"
#     RegistryPath  = "HKLM:\SOFTWARE\GitForWindows"
#     ExePath       = "C:\Program Files\Git\bin\git.exe"
# }
# Ensure-GitIsInstalled @params
