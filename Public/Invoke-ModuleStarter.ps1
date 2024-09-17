function Invoke-ModuleStarter {
    <#
    .SYNOPSIS
    Initializes the environment for module development or deployment.

    .DESCRIPTION
    The Invoke-ModuleStarter function sets up the environment for module development or deployment by managing the installation of necessary modules, elevating privileges, and initializing other script details.

    .PARAMETER Mode
    Specifies the mode to run the script in (e.g., dev, prod). Default is 'dev'.

    .PARAMETER SkipPSGalleryModules
    Skips the installation of modules from the PowerShell Gallery if set to $true.

    .PARAMETER SkipCheckandElevate
    Skips the privilege elevation check if set to $true.

    .PARAMETER SkipPowerShell7Install
    Skips the installation of PowerShell 7 if set to $true.

    .PARAMETER SkipEnhancedModules
    Skips the installation of enhanced modules if set to $true.

    .PARAMETER SkipGitRepos
    Skips the cloning of Git repositories if set to $true.

    .EXAMPLE
    $params = @{
        Mode                 = "prod"
        SkipPSGalleryModules = $true
        SkipCheckandElevate  = $false
        SkipPowerShell7Install = $false
        SkipEnhancedModules  = $true
        SkipGitRepos         = $false
    }
    Invoke-ModuleStarter @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the script mode (dev, prod, etc.).")]
        [string]$Mode = "dev",

        [Parameter(Mandatory = $false, HelpMessage = "Skip installation of modules from PowerShell Gallery.")]
        [bool]$SkipPSGalleryModules = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Skip the check and elevation to admin privileges.")]
        [bool]$SkipCheckandElevate = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Skip installation of PowerShell 7.")]
        [bool]$SkipPowerShell7Install = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Skip installation of enhanced modules.")]
        [bool]$SkipEnhancedModules = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Skip cloning of Git repositories.")]
        [bool]$SkipGitRepos = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the path for the Script Directory to pass files like secrets.psd1")]
        [string]$ScriptDirectory
    )

    Begin {
        Write-EnhancedLog -Message "Starting Invoke-ModuleStarter function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Log the parameters
        Write-EnhancedLog -Message "The Module Starter script is running in mode: $Mode" -Level "INFO"
        Write-EnhancedLog -Message "SkipPSGalleryModules is set to: $SkipPSGalleryModules" -Level "INFO"
        Write-EnhancedLog -Message "SkipCheckandElevate is set to: $SkipCheckandElevate" -Level "INFO"
        Write-EnhancedLog -Message "SkipPowerShell7Install is set to: $SkipPowerShell7Install" -Level "INFO"
        Write-EnhancedLog -Message "SkipEnhancedModules is set to: $SkipEnhancedModules" -Level "INFO"
        Write-EnhancedLog -Message "SkipGitRepos is set to: $SkipGitRepos" -Level "INFO"

        # Report the current PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        Write-EnhancedLog -Message "Current PowerShell Version: $psVersion" -Level 'INFO'
        Write-EnhancedLog -Message "Full PowerShell Version Details:"
        $PSVersionTable | Format-Table -AutoSize
    }

    Process {
        try {
            # Install PSFramework module if not installed
            # if (-not $SkipPSGalleryModules) {
            #     Write-EnhancedLog -Message "Installing PSFramework module..." -Level 'INFO'
            #     # Install-Module -Name PSFramework -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck -Verbose

            #     $params = @{
            #         ModuleName = "PSFramework"
            #     }
            #     Install-ModuleInPS5 @params

            # }

            # Define script details for initialization
            # $initializeParams = @{
            #     Mode            = $Mode
            #     ModulesBasePath = "C:\code\modulesv2"
            #     scriptDetails   = @(
            #         @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-Git.ps1"; SoftwareName = "Git"; MinVersion = [version]"2.41.0.0" },
            #         @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-GitHubCLI.ps1"; SoftwareName = "GitHub CLI"; MinVersion = [version]"2.54.0" }
            #     )
            #     ScriptDirectory = $ScriptDirectory
            # }


            # Initialize the base hashtable without ScriptDirectory
            $initializeParams = @{
                Mode            = $Mode
                ModulesBasePath = "C:\code\modulesv2"
                scriptDetails   = @(
                    @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-Git.ps1"; SoftwareName = "Git"; MinVersion = [version]"2.41.0.0" },
                    @{ Url = "https://raw.githubusercontent.com/aollivierre/setuplab/main/Install-GitHubCLI.ps1"; SoftwareName = "GitHub CLI"; MinVersion = [version]"2.54.0" }
                )
                SkipEnhancedModules = $SkipEnhancedModules
            }

            # Conditionally add ScriptDirectory to the hashtable if it is not null or empty
            if ($PSBoundParameters.ContainsKey('ScriptDirectory') -and $ScriptDirectory) {
                $initializeParams.ScriptDirectory = $ScriptDirectory
            }


            # Check and elevate permissions if required
            if (-not $SkipCheckandElevate) {
                Write-EnhancedLog -Message "Checking and elevating permissions if necessary." -Level "INFO"
                CheckAndElevate -ElevateIfNotAdmin $true
            }
            else {
                Write-EnhancedLog -Message "Skipping CheckAndElevate due to SkipCheckandElevate parameter." -Level "INFO"
            }

            # Initialize environment based on the mode and other parameters
            Write-EnhancedLog -Message "Initializing environment..." -Level 'INFO'
            Initialize-Environment @initializeParams
        }
        catch {
            Write-EnhancedLog -Message "Error during Module Starter execution: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        # Setup logging
        Write-EnhancedLog -Message "Exiting Invoke-ModuleStarter function" -Level "Notice"
        Write-EnhancedLog -Message "Script Started in $Mode mode" -Level "INFO"
    }
}

# Example usage
# $params = @{
#     Mode                 = "prod"
#     SkipPSGalleryModules = $true
#     SkipCheckandElevate  = $false
#     SkipPowerShell7Install = $false
#     SkipEnhancedModules  = $true
#     SkipGitRepos         = $false
# }
# Invoke-ModuleStarter @params
