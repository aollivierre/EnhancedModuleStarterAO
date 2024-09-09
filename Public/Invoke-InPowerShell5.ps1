function Invoke-InPowerShell5 {
    param (
        [string]$ScriptPath
    )

    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-EnhancedLog -Message "Relaunching script in PowerShell 5 (x64)..." -Level "WARNING"

        # Get the path to PowerShell 5 (x64)
        $ps5x64Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Launch in PowerShell 5 (x64)
        $startProcessParams64 = @{
            FilePath     = $ps5x64Path
            ArgumentList = @(
                "-NoExit",
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", "`"$ScriptPath`""
            )
            Verb         = "RunAs"
            PassThru     = $true
        }

        Write-EnhancedLog -Message "Starting PowerShell 5 (x64) to perform the update..." -Level "NOTICE"
        $process64 = Start-Process @startProcessParams64
        $process64.WaitForExit()

        Write-EnhancedLog -Message "PowerShell 5 (x64) process completed." -Level "NOTICE"
        Exit
    }
}
