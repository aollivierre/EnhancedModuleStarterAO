function Install-EnhancedModule {
    param (
        [string]$ModuleName
    )

    # Log the start of the module installation process
    Write-EnhancedLog "Starting the module installation process for: $ModuleName" -Level "NOTICE"

    # Check if the current PowerShell version is not 5
    # if ($PSVersionTable.PSVersion.Major -ne 5) {
    # Write-EnhancedLog "Current PowerShell version is $($PSVersionTable.PSVersion). PowerShell 5 is required." -Level "WARNING"

    # # Get the path to PowerShell 5
    # $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    # Write-EnhancedLog "PowerShell 5 path: $ps5Path" -Level "INFO"

    # # Construct the command to install the module in PowerShell 5
    # $command = "& '$ps5Path' -ExecutionPolicy Bypass -Command `"Install-Module -Name '$ModuleName' -Force -SkipPublisherCheck -Scope AllUsers`""
    # Write-EnhancedLog "Constructed command for PowerShell 5: $command" -Level "DEBUG"

    # # Launch PowerShell 5 to run the module installation
    # Write-EnhancedLog "Launching PowerShell 5 to install the module: $ModuleName" -Level "INFO"
    # Invoke-Expression $command

    # Write-EnhancedLog "Module installation command executed in PowerShell 5. Exiting current session." -Level "NOTICE"
    # return

    # Path to the current script
    # $ScriptPath = $MyInvocation.MyCommand.Definition

    # # Check if we need to re-launch in PowerShell 5
    # Invoke-InPowerShell5 -ScriptPath $ScriptPath

    # # If running in PowerShell 5, reset the module paths and proceed with the rest of the script
    # Reset-ModulePaths

    # }

    # If already in PowerShell 5, install the module
    Write-EnhancedLog "Current PowerShell version is 5. Proceeding with module installation." -Level "INFO"
    Write-EnhancedLog "Installing module: $ModuleName in PowerShell 5" -Level "NOTICE"

    try {
        Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers
        Write-EnhancedLog "Module $ModuleName installed successfully in PowerShell 5." -Level "INFO"
    }
    catch {
        Write-EnhancedLog "Failed to install module $ModuleName. Error: $_" -Level "ERROR"
    }
}