function Get-GitPath {
    <#
    .SYNOPSIS
    Discovers the path to the Git executable on the system.

    .DESCRIPTION
    This function attempts to find the Git executable by checking common installation directories and the system's PATH environment variable.

    .EXAMPLE
    $gitPath = Get-GitPath
    if ($gitPath) {
        Write-Host "Git found at: $gitPath"
    } else {
        Write-Host "Git not found."
    }
    #>

    [CmdletBinding()]
    param ()

    try {
        # Common Git installation paths
        $commonPaths = @(
            "C:\Program Files\Git\bin\git.exe",
            "C:\Program Files (x86)\Git\bin\git.exe"
        )

        # Check the common paths
        foreach ($path in $commonPaths) {
            if (Test-Path -Path $path) {
                Write-EnhancedLog -Message "Git found at: $path" -Level "INFO"
                return $path
            }
        }

        # If not found, check if Git is in the system PATH
        $gitPathInEnv = (Get-Command git -ErrorAction SilentlyContinue).Source
        if ($gitPathInEnv) {
            Write-EnhancedLog -Message "Git found in system PATH: $gitPathInEnv" -Level "INFO"
            return $gitPathInEnv
        }

        # If Git is still not found, return $null
        Write-EnhancedLog -Message "Git executable not found." -Level "ERROR"
        return $null
    }
    catch {
        Write-EnhancedLog -Message "Error occurred while trying to find Git path: $_" -Level "ERROR"
        return $null
    }
}