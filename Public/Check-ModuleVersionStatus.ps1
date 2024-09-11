function Check-ModuleVersionStatus {
    <#
    .SYNOPSIS
    Checks the installed and latest versions of PowerShell modules.

    .DESCRIPTION
    The Check-ModuleVersionStatus function checks if the specified PowerShell modules are installed and compares their versions with the latest available version in the PowerShell Gallery. It logs the checking process and handles errors gracefully.

    .PARAMETER ModuleNames
    The names of the PowerShell modules to check for version status.

    .EXAMPLE
    $params = @{
        ModuleNames = @('Pester', 'AzureRM', 'PowerShellGet')
    }
    Check-ModuleVersionStatus @params
    Checks the version status of the specified modules.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the names of the modules to check.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$ModuleNames
    )

    Begin {
        Write-EnhancedLog -Message "Starting Check-ModuleVersionStatus function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Import PowerShellGet if it's not already loaded
        Write-EnhancedLog -Message "Importing necessary modules (PowerShellGet)." -Level "INFO"
        try {
            Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue
        } catch {
            Write-EnhancedLog -Message "Failed to import PowerShellGet: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }

        # Initialize a list to hold the results
        $results = [System.Collections.Generic.List[PSObject]]::new()
    }

    Process {
        foreach ($ModuleName in $ModuleNames) {
            try {
                Write-EnhancedLog -Message "Checking module: $ModuleName" -Level "INFO"
                
                # Get installed module details
                $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
                
                # Get latest module version from the PowerShell Gallery
                $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

                if ($installedModule -and $latestModule) {
                    if ($installedModule.Version -lt $latestModule.Version) {
                        $results.Add([PSCustomObject]@{
                            ModuleName       = $ModuleName
                            Status           = "Outdated"
                            InstalledVersion = $installedModule.Version
                            LatestVersion    = $latestModule.Version
                        })
                        Write-EnhancedLog -Message "Module $ModuleName is outdated. Installed: $($installedModule.Version), Latest: $($latestModule.Version)" -Level "INFO"
                    } else {
                        $results.Add([PSCustomObject]@{
                            ModuleName       = $ModuleName
                            Status           = "Up-to-date"
                            InstalledVersion = $installedModule.Version
                            LatestVersion    = $installedModule.Version
                        })
                        Write-EnhancedLog -Message "Module $ModuleName is up-to-date. Version: $($installedModule.Version)" -Level "INFO"
                    }
                } elseif (-not $installedModule) {
                    $results.Add([PSCustomObject]@{
                        ModuleName       = $ModuleName
                        Status           = "Not Installed"
                        InstalledVersion = $null
                        LatestVersion    = $null
                    })
                    Write-EnhancedLog -Message "Module $ModuleName is not installed." -Level "INFO"
                } else {
                    $results.Add([PSCustomObject]@{
                        ModuleName       = $ModuleName
                        Status           = "Not Found in Gallery"
                        InstalledVersion = $installedModule.Version
                        LatestVersion    = $null
                    })
                    Write-EnhancedLog -Message "Module $ModuleName is installed but not found in the PowerShell Gallery." -Level "WARNING"
                }
            } catch {
                Write-EnhancedLog -Message "Error occurred while checking module '$ModuleName': $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
                throw
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Check-ModuleVersionStatus function" -Level "Notice"
        # Return the results
        return $results
    }
}

# Example usage:
# $params = @{
#     ModuleNames = @('Pester', 'AzureRM', 'PowerShellGet')
# }
# $versionStatuses = Check-ModuleVersionStatus @params
# $versionStatuses | Format-Table -AutoSize
