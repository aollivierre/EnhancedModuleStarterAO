function Invoke-InPowerShell5 {
    <#
    .SYNOPSIS
    Relaunches the script in PowerShell 5 (x64) if the current session is not already running in PowerShell 5.

    .PARAMETER ScriptPath
    The full path to the script that needs to be executed in PowerShell 5 (x64).

    .DESCRIPTION
    This function checks if the current PowerShell session is running in PowerShell 5. If not, it relaunches the specified script in PowerShell 5 (x64) with elevated privileges.

    .EXAMPLE
    Invoke-InPowerShell5 -ScriptPath "C:\Scripts\MyScript.ps1"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Provide the full path to the script to be run in PowerShell 5.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    Begin {
        # Log parameters
        Write-EnhancedLog -Message "Starting Invoke-InPowerShell5 function." -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Log the start of the process
        Write-EnhancedLog -Message "Checking PowerShell version." -Level "INFO"
    }

    Process {
        try {
            # Check if we're not in PowerShell 5
            if ($PSVersionTable.PSVersion.Major -ne 5) {
                Write-EnhancedLog -Message "Relaunching script in PowerShell 5 (x64)..." -Level "WARNING"

                # Get the path to PowerShell 5 (x64)
                $ps5x64Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

                # Define arguments for the Start-Process command
                $arguments = @(
                    "-NoExit"
                    "-NoProfile"
                    "-ExecutionPolicy", "Bypass"
                    "-File", "`"$PSCommandPath`""
                    # "-File", "`"$ScriptPath`""
                )

                # Launch in PowerShell 5 (x64) with elevated privileges
                $startProcessParams64 = @{
                    FilePath     = $ps5x64Path
                    ArgumentList = $arguments
                    # ArgumentList = @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
                    Verb         = "RunAs"
                    PassThru     = $true
                }

                Write-EnhancedLog -Message "Starting PowerShell 5 (x64) to perform the update..." -Level "NOTICE"
                $process64 = Start-Process @startProcessParams64
                $process64.WaitForExit()

                
                write-host 'hello from PS5'

                Write-EnhancedLog -Message "PowerShell 5 (x64) process completed." -Level "NOTICE"
                # Exit
            }
            else {
                Write-EnhancedLog -Message "Already running in PowerShell 5. No need to relaunch." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error occurred while relaunching script in PowerShell 5: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Invoke-InPowerShell5 function." -Level "Notice"
    }
}

# Example usage
# Invoke-InPowerShell5 -ScriptPath "C:\Scripts\MyScript.ps1"
# Invoke-InPowerShell5 -ScriptPath $PSScriptRoot
# Invoke-InPowerShell5