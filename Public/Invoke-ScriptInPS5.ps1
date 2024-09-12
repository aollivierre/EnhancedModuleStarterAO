function Invoke-ScriptInPS5 {
    <#
    .SYNOPSIS
    Executes a script in PowerShell 5 and returns the result.

    .DESCRIPTION
    The Invoke-ScriptInPS5 function takes a script path, switches to PowerShell 5, and executes the script. It captures the exit code and logs the process. This function can be used for any script that needs to be run inside PowerShell 5.

    .PARAMETER ScriptPath
    The full path to the script to be executed in PowerShell 5.

    .PARAMETER ScriptArgs
    The arguments to pass to the script, if any.

    .EXAMPLE
    Invoke-ScriptInPS5 -ScriptPath "C:\Scripts\MyScript.ps1"
    Executes MyScript.ps1 inside PowerShell 5.

    .EXAMPLE
    Invoke-ScriptInPS5 -ScriptPath "C:\Scripts\MyScript.ps1" -ScriptArgs "-Param1 Value1"
    Executes MyScript.ps1 with specified parameters inside PowerShell 5.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the path to the script to be executed in PowerShell 5.")]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, HelpMessage = "Provide arguments for the script being executed.")]
        [string]$ScriptArgs
    )

    Begin {
        Write-EnhancedLog -Message "Starting Invoke-ScriptInPS5 function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters


        Reset-ModulePaths

        # Path to PowerShell 5
        $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Validate if PowerShell 5 exists
        if (-not (Test-Path $ps5Path)) {
            throw "PowerShell 5 executable not found: $ps5Path"
        }

        # Validate if the script exists
        if (-not (Test-Path $ScriptPath)) {
            throw "Script file not found: $ScriptPath"
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Preparing to run script in PowerShell 5: $ScriptPath with arguments: $ScriptArgs" -Level "INFO"

            # Build the argument list for Start-Process
            $ps5Command = "& '$ScriptPath' $ScriptArgs"
            $startProcessParams = @{
                FilePath        = $ps5Path
                ArgumentList    = "-Command", $ps5Command
                Wait            = $true
                NoNewWindow     = $true
                PassThru        = $true
            }

            Write-EnhancedLog -Message "Executing script in PowerShell 5" -Level "INFO"
            $process = Start-Process @startProcessParams

            if ($process.ExitCode -eq 0) {
                Write-EnhancedLog -Message "Script executed successfully in PS5" -Level "INFO"
            } else {
                Write-EnhancedLog -Message "Error occurred during script execution. Exit Code: $($process.ExitCode)" -Level "ERROR"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error executing script: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Invoke-ScriptInPS5 function" -Level "Notice"
        }
    }

    End {
        Write-EnhancedLog -Message "Script execution in PowerShell 5 completed" -Level "INFO"
    }
}
