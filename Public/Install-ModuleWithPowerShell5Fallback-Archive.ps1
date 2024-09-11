# function Install-ModuleWithPowerShell5Fallback {
#     param (
#         [string]$ModuleName
#     )

#     # Log the start of the module installation process
#     Write-Enhancedlog "Starting the module installation process for: $ModuleName" -Level "NOTICE"

    
#     Reset-ModulePaths

#     CheckAndElevate -ElevateIfNotAdmin $true

#     $DBG

#     # Check if the current PowerShell version is not 5
#     if ($PSVersionTable.PSVersion.Major -ne 5) {
#         Write-Enhancedlog "Current PowerShell version is $($PSVersionTable.PSVersion). PowerShell 5 is required." -Level "WARNING"
#         # Invoke-InPowerShell5

#         $params = @{
#             ModuleName = "$Modulename"
#         }
#         Install-ModuleInPS5 @params
#     }

#     # If already in PowerShell 5, install the module
#     Write-Enhancedlog "Current PowerShell version is 5. Proceeding with module installation." -Level "INFO"
#     Write-Enhancedlog "Installing module: $ModuleName in PowerShell 5" -Level "NOTICE"

#     try {
#         Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers -Confirm:$false
#         Write-Enhancedlog "Module $ModuleName installed successfully in PowerShell 5." -Level "INFO"
#     }
#     catch {
#         Write-Enhancedlog "Failed to install module $ModuleName. Error: $_" -Level "ERROR"
#     }
# }
