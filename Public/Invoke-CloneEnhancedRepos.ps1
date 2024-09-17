function Invoke-CloneEnhancedRepos {
    param (
        [PSCustomObject[]]$scriptDetails,
        [Parameter(Mandatory = $false)]
        [string]$ScriptDirectory
    )

    try {
        # Elevate script if needed
        Elevate-Script

        # Initialize necessary variables
        $powerShellPath = Get-PowerShellPath
        $processList = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
        $installationResults = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Process each software detail
        foreach ($detail in $scriptDetails) {
            Process-SoftwareDetails -detail $detail -powerShellPath $powerShellPath -installationResults ([ref]$installationResults) -processList ([ref]$processList)
        }

        # Validate installation results after processes finish
        Validate-InstallationResults -processList ([ref]$processList) -installationResults ([ref]$installationResults) -scriptDetails $scriptDetails

        # Generate the final summary report
        Generate-SoftwareInstallSummaryReport -installationResults $installationResults

        # Example invocation to clone repositories:
        Clone-EnhancedRepos -githubUsername "aollivierre" -targetDirectory "C:\Code\modulesv2" -ScriptDirectory $ScriptDirectory
    }
    catch {
        # Capture the error details
        $errorDetails = $_ | Out-String
        Write-EnhancedLog "An error occurred: $errorDetails" -Level "ERROR"
        throw
    }
}