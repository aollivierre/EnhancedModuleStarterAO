function Invoke-CommandInPS5 {
    <#
    .SYNOPSIS
    Executes a command in PowerShell 5 and returns the result.

    .DESCRIPTION
    The Invoke-CommandInPS5 function takes a command string, switches to PowerShell 5, and executes the command. It captures the exit code and logs the process. This function can be used for any command that needs to be run inside PowerShell 5.

    .PARAMETER Command
    The command string to be executed in PowerShell 5.

    .EXAMPLE
    Invoke-CommandInPS5 -Command "Upload-Win32App -Prg $Prg -Prg_Path $Prg_Path -Prg_img $Prg_img"
    Executes the Upload-Win32App command inside PowerShell 5.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the command to be executed in PowerShell 5.")]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )

    Begin {
        Write-EnhancedLog -Message "Starting Invoke-CommandInPS5 function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Path to PowerShell 5
        $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Validate if PowerShell 5 exists
        if (-not (Test-Path $ps5Path)) {
            throw "PowerShell 5 executable not found: $ps5Path"
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Preparing to run command in PowerShell 5: $Command" -Level "INFO"

            # Splatting for Start-Process
            $startProcessParams = @{
                FilePath        = $ps5Path
                ArgumentList    = "-Command", $Command
                Wait            = $true
                NoNewWindow     = $true
                PassThru        = $true
            }

            Write-EnhancedLog -Message "Executing command in PowerShell 5" -Level "INFO"
            $process = Start-Process @startProcessParams

            if ($process.ExitCode -eq 0) {
                Write-EnhancedLog -Message "Command executed successfully in PS5" -Level "INFO"
            } else {
                Write-EnhancedLog -Message "Error occurred during command execution. Exit Code: $($process.ExitCode)" -Level "ERROR"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error executing command: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Invoke-CommandInPS5 function" -Level "Notice"
        }
    }

    End {
        Write-EnhancedLog -Message "Command execution in PowerShell 5 completed" -Level "INFO"
    }
}
