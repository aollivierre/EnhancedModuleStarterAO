function Ensure-NuGetProvider {
    <#
    .SYNOPSIS
    Ensures that the NuGet provider and PowerShellGet module are installed when running in PowerShell 5.

    .DESCRIPTION
    This function checks if the NuGet provider is installed when running in PowerShell 5. If not, it installs the NuGet provider and ensures that the PowerShellGet module is installed as well.

    .EXAMPLE
    Ensure-NuGetProvider
    Ensures the NuGet provider is installed on a PowerShell 5 system.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Ensure-NuGetProvider function" -Level "Notice"

        Reset-ModulePaths
        
        # Log the current PowerShell version
        Write-EnhancedLog -Message "Running PowerShell version: $($PSVersionTable.PSVersion)" -Level "INFO"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Process {
        try {
            # Check if running in PowerShell 5
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                Write-EnhancedLog -Message "Running in PowerShell version 5, checking NuGet provider..." -Level "INFO"

                # Use -ListAvailable to only check installed providers without triggering installation
                if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                    Write-EnhancedLog -Message "NuGet provider not found. Installing NuGet provider..." -Level "INFO"

                    # Install the NuGet provider with ForceBootstrap to bypass the prompt
                    Install-PackageProvider -Name NuGet -ForceBootstrap -Force -Confirm:$false
                    Write-EnhancedLog -Message "NuGet provider installed successfully." -Level "INFO"
                    
                    # Install the PowerShellGet module
                    $params = @{
                        ModuleName = "PowerShellGet"
                    }
                    Install-ModuleInPS5 @params

                } else {
                    Write-EnhancedLog -Message "NuGet provider is already installed." -Level "INFO"
                }
            }
            else {
                Write-EnhancedLog -Message "This script is running in PowerShell version $($PSVersionTable.PSVersion), which is not version 5. No action is taken for NuGet." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error encountered during NuGet provider installation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Ensure-NuGetProvider function" -Level "Notice"
    }
}
