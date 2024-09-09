function Get-PowerShellPath {
    <#
    .SYNOPSIS
        Retrieves the path to the installed PowerShell executable, defaulting to PowerShell 5.

    .DESCRIPTION
        This function checks for the existence of PowerShell 5 and PowerShell 7 on the system.
        By default, it returns the path to PowerShell 5 unless the -UsePS7 switch is provided.
        If the specified version is not found, an error is thrown.

    .PARAMETER UsePS7
        Optional switch to prioritize PowerShell 7 over PowerShell 5.

    .EXAMPLE
        $pwshPath = Get-PowerShellPath
        Write-Host "PowerShell found at: $pwshPath"

    .EXAMPLE
        $pwshPath = Get-PowerShellPath -UsePS7
        Write-Host "PowerShell found at: $pwshPath"

    .NOTES
        Author: Abdullah Ollivierre
        Date: 2024-08-15
    #>

    [CmdletBinding()]
    param (
        [switch]$UsePS7
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-PowerShellPath function" -Level "NOTICE"
    }

    Process {
        $pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
        $pwsh5Path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

        if ($UsePS7) {
            if (Test-Path $pwsh7Path) {
                Write-EnhancedLog -Message "PowerShell 7 found at $pwsh7Path" -Level "INFO"
                return $pwsh7Path
            } elseif (Test-Path $pwsh5Path) {
                Write-EnhancedLog -Message "PowerShell 7 not found, falling back to PowerShell 5 at $pwsh5Path" -Level "WARNING"
                return $pwsh5Path
            }
        } else {
            if (Test-Path $pwsh5Path) {
                Write-EnhancedLog -Message "PowerShell 5 found at $pwsh5Path" -Level "INFO"
                return $pwsh5Path
            } elseif (Test-Path $pwsh7Path) {
                Write-EnhancedLog -Message "PowerShell 5 not found, falling back to PowerShell 7 at $pwsh7Path" -Level "WARNING"
                return $pwsh7Path
            }
        }

        $errorMessage = "Neither PowerShell 7 nor PowerShell 5 was found on this system."
        Write-EnhancedLog -Message $errorMessage -Level "ERROR"
        throw $errorMessage
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-PowerShellPath function" -Level "NOTICE"
    }
}



# # Get the path to the installed PowerShell executable
# try {
#     $pwshPath = Get-PowerShellPath
#     Write-Host "PowerShell executable found at: $pwshPath"
    
#     # Example: Start a new PowerShell session using the found path
#     Start-Process -FilePath $pwshPath -ArgumentList "-NoProfile", "-Command", "Get-Process" -NoNewWindow -Wait
# }
# catch {
#     Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
# }