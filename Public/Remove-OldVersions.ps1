function Remove-OldVersions {
    <#
    .SYNOPSIS
    Removes older versions of a specified PowerShell module.

    .DESCRIPTION
    The Remove-OldVersions function removes all but the latest version of the specified PowerShell module. It ensures that only the most recent version is retained.

    .PARAMETER ModuleName
    The name of the module for which older versions will be removed.

    .EXAMPLE
    Remove-OldVersions -ModuleName "Pester"
    Removes all but the latest version of the Pester module.

    .NOTES
    This function requires administrative access to manage modules and assumes that the CheckAndElevate function is defined elsewhere in the script.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    begin {
        Write-EnhancedLog -Message "Starting Remove-OldVersions function for module: $ModuleName" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        # Get all versions except the latest one
        $allVersions = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version
        $latestVersion = $allVersions | Select-Object -Last 1
        $olderVersions = $allVersions | Where-Object { $_.Version -ne $latestVersion.Version }

        foreach ($version in $olderVersions) {
            try {
                Write-EnhancedLog -Message "Removing older version $($version.Version) of $ModuleName..." -Level "INFO"
                $modulePath = $version.ModuleBase

                Write-EnhancedLog -Message "Starting takeown and icacls for $modulePath" -Level "INFO"
                Write-EnhancedLog -Message "Checking and elevating to admin if needed" -Level "INFO"
                CheckAndElevate -ElevateIfNotAdmin $true
                & takeown.exe /F $modulePath /A /R
                & icacls.exe $modulePath /reset
                & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
                Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

                Write-EnhancedLog -Message "Removed $($version.Version) successfully." -Level "INFO"
            } catch {
                Write-EnhancedLog -Message "Failed to remove version $($version.Version) of $ModuleName at $modulePath. Error: $_" -Level "ERROR"
                Handle-Error -ErrorRecord $_
            }
        }
    }

    end {
        Write-EnhancedLog -Message "Remove-OldVersions function execution completed for module: $ModuleName" -Level "INFO"
    }
}