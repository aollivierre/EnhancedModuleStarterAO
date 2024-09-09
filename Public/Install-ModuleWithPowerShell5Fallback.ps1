function Install-ModuleWithPowerShell5Fallback {
    param (
        [string]$ModuleName
    )

    # Log the start of the module installation process
    Write-Enhancedlog "Starting the module installation process for: $ModuleName" -Level "NOTICE"


    $DBG

    # Check if the current PowerShell version is not 5
    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-Enhancedlog "Current PowerShell version is $($PSVersionTable.PSVersion). PowerShell 5 is required." -Level "WARNING"

        # # Get the path to PowerShell 5
        # $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        # Write-Enhancedlog "PowerShell 5 path: $ps5Path" -Level "INFO"

        # # Construct the parameters for Start-Process
        # $startProcessParams = @{
        #     FilePath     = $ps5Path
        #     ArgumentList = @(
        #         "-NoExit",
        #         "-NoProfile",
        #         "-ExecutionPolicy", "Bypass",
        #         "-Command", "Install-Module -Name '$ModuleName' -Force -SkipPublisherCheck -Scope AllUsers"
        #     )
        #     Verb         = "RunAs"
        #     PassThru     = $true
        # }
        
        # Write-Enhancedlog "Constructed Start-Process parameters for PowerShell 5: $($startProcessParams | Out-String)" -Level "DEBUG"

        # # Launch PowerShell 5 to run the module installation
        # Write-Enhancedlog "Launching PowerShell 5 to install the module: $ModuleName" -Level "INFO"

        # $DBG
        # $process = Start-Process @startProcessParams

        # Write-Enhancedlog "Module installation command executed in PowerShell 5. Exiting current session." -Level "NOTICE"
        # return
    }

    # If already in PowerShell 5, install the module
    Write-Enhancedlog "Current PowerShell version is 5. Proceeding with module installation." -Level "INFO"
    Write-Enhancedlog "Installing module: $ModuleName in PowerShell 5" -Level "NOTICE"

    try {
        Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers
        Write-Enhancedlog "Module $ModuleName installed successfully in PowerShell 5." -Level "INFO"
    }
    catch {
        Write-Enhancedlog "Failed to install module $ModuleName. Error: $_" -Level "ERROR"
    }
}
