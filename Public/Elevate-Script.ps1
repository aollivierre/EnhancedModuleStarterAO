function Elevate-Script {
    if (-not (Test-Admin)) {
        Write-EnhancedLog "Restarting script with elevated permissions..."
        $startProcessParams = @{
            FilePath     = "powershell.exe"
            ArgumentList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath)
            Verb         = "RunAs"
        }
        Start-Process @startProcessParams
        exit
    }
}