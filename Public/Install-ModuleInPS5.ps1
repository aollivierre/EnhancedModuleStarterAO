function Install-ModuleInPS5 {
    <#
    .SYNOPSIS
    Installs a PowerShell module in PowerShell 5 and validates the installation.

    .DESCRIPTION
    The Install-ModuleInPS5 function installs a specified PowerShell module using PowerShell 5. It ensures that the module is installed in the correct environment and logs the entire process. It handles errors gracefully and validates the installation after completion.

    .PARAMETER ModuleName
    The name of the PowerShell module to install in PowerShell 5.

    .EXAMPLE
    $params = @{
        ModuleName = "Az"
    }
    Install-ModuleInPS5 @params
    Installs the specified PowerShell module using PowerShell 5 and logs the process.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the name of the module to install.")]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-ModuleInPS5 function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        Reset-ModulePaths

        CheckAndElevate -ElevateIfNotAdmin $true

        # Path to PowerShell 5
        $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Validate if PowerShell 5 exists
        if (-not (Test-Path $ps5Path)) {
            throw "PowerShell 5 executable not found: $ps5Path"
        }
    }

    Process {
        try {
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                # If already in PowerShell 5, install the module directly
                Write-EnhancedLog -Message "Already running in PowerShell 5, installing module directly." -Level "INFO"
                Install-Module -Name $ModuleName -Scope AllUsers -SkipPublisherCheck -AllowClobber -Force -Confirm:$false
            }
            else {
                # If not in PowerShell 5, use Start-Process to switch to PowerShell 5
                Write-EnhancedLog -Message "Preparing to install module: $ModuleName in PowerShell 5" -Level "INFO"

                $ps5Command = "Install-Module -Name $ModuleName -Scope AllUsers -SkipPublisherCheck -AllowClobber -Force -Confirm:`$false"

                # Splatting for Start-Process
                $startProcessParams = @{
                    FilePath     = $ps5Path
                    ArgumentList = "-NoProfile", "-Command", $ps5Command
                    Wait         = $true
                    NoNewWindow  = $true
                    PassThru     = $true
                }

                Write-EnhancedLog -Message "Starting installation of module $ModuleName in PowerShell 5" -Level "INFO"
                $process = Start-Process @startProcessParams

                if ($process.ExitCode -eq 0) {
                    Write-EnhancedLog -Message "Module '$ModuleName' installed successfully in PS5" -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Error occurred during module installation. Exit Code: $($process.ExitCode)" -Level "ERROR"
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "Error installing module: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Install-ModuleInPS5 function" -Level "Notice"
        }
    }

    End {
        Write-EnhancedLog -Message "Validating module installation in PS5" -Level "INFO"

        if ($PSVersionTable.PSVersion.Major -eq 5) {
            # Validate directly in PowerShell 5
            $module = Get-Module -ListAvailable -Name $ModuleName
        }
        else {
            # Use Start-Process to validate in PowerShell 5
            $ps5ValidateCommand = "Get-Module -ListAvailable -Name $ModuleName"

            $validateProcessParams = @{
                FilePath     = $ps5Path
                ArgumentList = "-NoProfile", "-Command", $ps5ValidateCommand
                NoNewWindow  = $true
                PassThru     = $true
                Wait         = $true
            }

            $moduleInstalled = Start-Process @validateProcessParams
            if ($moduleInstalled.ExitCode -ne 0) {
                Write-EnhancedLog -Message "Module $ModuleName validation failed in PS5" -Level "ERROR"
                throw "Module $ModuleName installation could not be validated in PS5"
            }
        }

        Write-EnhancedLog -Message "Module $ModuleName validated successfully in PS5" -Level "INFO"
    }
}

# Example usage
# $params = @{
#     ModuleName = "Az"
# }
# Install-ModuleInPS5 @params
