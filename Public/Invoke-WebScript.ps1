
function Invoke-WebScript {
    param (
        [string]$url
    )

    $powerShellPath = Get-PowerShellPath -ForcePowerShell5

    Write-EnhancedModuleStarterLog -Message "Validating URL: $url" -Level "INFO"

    if (Test-Url -url $url) {
        Write-EnhancedModuleStarterLog -Message "Running script from URL: $url" -Level "INFO"

        $startProcessParams = @{
            FilePath     = $powerShellPath
            ArgumentList = @(
                "-NoExit",
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command", "Invoke-Expression (Invoke-RestMethod -Uri '$url')"
            )
            Verb         = "RunAs"
            PassThru     = $true
        }
        
        $process = Start-Process @startProcessParams
        
        return $process
    }
    else {
        Write-EnhancedModuleStarterLog -Message "URL $url is not accessible" -Level "ERROR"
        return $null
    }
}