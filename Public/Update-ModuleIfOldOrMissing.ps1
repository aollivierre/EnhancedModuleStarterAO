function Update-ModuleIfOldOrMissing {
    <#
    .SYNOPSIS
    Updates or installs a specified PowerShell module if it is outdated or missing.

    .DESCRIPTION
    The Update-ModuleIfOldOrMissing function checks the status of a specified PowerShell module and updates it if it is outdated. If the module is not installed, it installs the latest version. It also removes older versions after the update.

    .PARAMETER ModuleName
    The name of the module to be checked and updated or installed.

    .EXAMPLE
    Update-ModuleIfOldOrMissing -ModuleName "Pester"
    Checks and updates the Pester module if it is outdated or installs it if not present.

    .NOTES
    This function requires administrative access to manage modules and assumes that the CheckAndElevate, Check-ModuleVersionStatus, and Remove-OldVersions functions are defined elsewhere in the script.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    begin {
        Write-EnhancedLog -Message "Starting Update-ModuleIfOldOrMissing function for module: $ModuleName" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Ensure-NuGetProvider

    }

    process {
        $moduleStatus = Check-ModuleVersionStatus -ModuleNames @($ModuleName)
        foreach ($status in $moduleStatus) {
            switch ($status.Status) {
                "Outdated" {
                    Write-EnhancedLog -Message "Updating $ModuleName from version $($status.InstalledVersion) to $($status.LatestVersion)." -Level "WARNING"

                    # Remove older versions
                    Remove-OldVersions -ModuleName $ModuleName


                    $params = @{
                        ModuleName = "$Modulename"
                    }
                    Install-ModuleInPS5 @params

                    # Install the latest version of the module
                    # Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers
                    # Install-ModuleWithPowerShell5Fallback -ModuleName $ModuleName

                    Write-EnhancedLog -Message "$ModuleName has been updated to the latest version." -Level "INFO"
                }
                "Up-to-date" {
                    Write-EnhancedLog -Message "$ModuleName version $($status.InstalledVersion) is up-to-date. No update necessary." -Level "INFO"
                    Remove-OldVersions -ModuleName $ModuleName
                }
                "Not Installed" {
                    Write-EnhancedLog -Message "$ModuleName is not installed. Installing the latest version..." -Level "WARNING"
                    # Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers


                    $params = @{
                        ModuleName = "$Modulename"
                    }
                    Install-ModuleInPS5 @params

                    # $DBG
                    # Install-ModuleWithPowerShell5Fallback -ModuleName $ModuleName
                    Write-EnhancedLog -Message "$ModuleName has been installed." -Level "INFO"
                }
                "Not Found in Gallery" {
                    Write-EnhancedLog -Message "Unable to find '$ModuleName' in the PowerShell Gallery." -Level "ERROR"
                }
            }
        }
    }

    end {
        Write-EnhancedLog -Message "Update-ModuleIfOldOrMissing function execution completed for module: $ModuleName" -Level "Notice"
    }
}