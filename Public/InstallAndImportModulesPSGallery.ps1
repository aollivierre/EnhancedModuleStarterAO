# Helper function to check for duplicates and add module to summary
function Add-ModuleToSummary {
    param (
        [string]$moduleName,
        [Version]$moduleVersion,
        [string]$modulePath,
        [ref]$moduleList,
        [ref]$moduleCount  # Reference to the module count variable
    )

    # Check for duplicates (module name, version, and path)
    $exists = $moduleList.Value | Where-Object {
        $_.Name -eq $moduleName -and 
        $_.Version -eq $moduleVersion -and 
        $_.Path -eq $modulePath
    }

    # Add the module to the list only if it doesn't already exist
    if (-not $exists) {
        $moduleDetails = [PSCustomObject]@{
            Name    = $moduleName
            Version = $moduleVersion
            Path    = $modulePath
        }
        $moduleList.Value.Add($moduleDetails)
        $moduleCount.Value++  # Increment the count only when a new module is added
    }
}



function InstallAndImportModulesPSGallery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePsd1Path
    )

    begin {
        Write-EnhancedLog -Message "Starting InstallAndImportModulesPSGallery function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize counters and lists for summary
        $moduleSuccessCount = 0
        $moduleFailCount = 0
        $successModules = [System.Collections.Generic.List[PSCustomObject]]::new()
        $failedModules = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Validate PSD1 file path
        if (-not (Test-Path -Path $modulePsd1Path)) {
            Write-EnhancedLog -Message "modules.psd1 file not found at path: $modulePsd1Path" -Level "ERROR"
            throw "modules.psd1 file not found."
        }

        Write-EnhancedLog -Message "Found modules.psd1 file at path: $modulePsd1Path" -Level "INFO"
    }

    process {
        try {
            # Read and import PSD1 data
            $moduleData = Import-PowerShellDataFile -Path $modulePsd1Path
            $requiredModules = $moduleData.RequiredModules
            $importedModules = $moduleData.ImportedModules
            $myModules = $moduleData.MyModules
    
            # Install and Import Modules
            if ($requiredModules) {
                Write-EnhancedLog -Message "Installing required modules: $($requiredModules -join ', ')" -Level "INFO"
                foreach ($moduleName in $requiredModules) {
                    try {
                        Update-ModuleIfOldOrMissing -ModuleName $moduleName
                        $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion $moduleInfo.Version -modulePath $moduleInfo.ModuleBase -moduleList ([ref]$successModules) -moduleCount ([ref]$moduleSuccessCount)
                        Write-EnhancedLog -Message "Successfully installed/updated module: $moduleName" -Level "INFO"
                    }
                    catch {
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion "N/A" -modulePath "N/A" -moduleList ([ref]$failedModules) -moduleCount ([ref]$moduleFailCount)
                        Write-EnhancedLog -Message "Failed to install/update module: $moduleName. Error: $_" -Level "ERROR"
                    }
                }
            }
    
            if ($importedModules) {
                Write-EnhancedLog -Message "Importing modules: $($importedModules -join ', ')" -Level "INFO"
                foreach ($moduleName in $importedModules) {
                    try {
                        Import-Module -Name $moduleName -Force
                        $moduleInfo = Get-Module -Name $moduleName | Select-Object -First 1
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion $moduleInfo.Version -modulePath $moduleInfo.ModuleBase -moduleList ([ref]$successModules) -moduleCount ([ref]$moduleSuccessCount)
                        Write-EnhancedLog -Message "Successfully imported module: $moduleName" -Level "INFO"
                    }
                    catch {
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion "N/A" -modulePath "N/A" -moduleList ([ref]$failedModules) -moduleCount ([ref]$moduleFailCount)
                        Write-EnhancedLog -Message "Failed to import module: $moduleName. Error: $_" -Level "ERROR"
                    }
                }
            }
    
            if ($myModules) {
                Write-EnhancedLog -Message "Importing custom modules: $($myModules -join ', ')" -Level "INFO"
                foreach ($moduleName in $myModules) {
                    try {
                        Import-Module -Name $moduleName -Force
                        $moduleInfo = Get-Module -Name $moduleName | Select-Object -First 1
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion $moduleInfo.Version -modulePath $moduleInfo.ModuleBase -moduleList ([ref]$successModules) -moduleCount ([ref]$moduleSuccessCount)
                        Write-EnhancedLog -Message "Successfully imported custom module: $moduleName" -Level "INFO"
                    }
                    catch {
                        Add-ModuleToSummary -moduleName $moduleName -moduleVersion "N/A" -modulePath "N/A" -moduleList ([ref]$failedModules) -moduleCount ([ref]$moduleFailCount)
                        Write-EnhancedLog -Message "Failed to import custom module: $moduleName. Error: $_" -Level "ERROR"
                    }
                }
            }
    
            Write-EnhancedLog -Message "Modules installation and import process completed." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error processing modules.psd1: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        # Output summary report
        Write-EnhancedLog -Message "InstallAndImportModulesPSGallery function execution completed." -Level "INFO"

        Write-Host "---------- Summary Report ----------" -ForegroundColor Cyan
        Write-Host "Total Modules Processed: $($moduleSuccessCount + $moduleFailCount)" -ForegroundColor Cyan
        Write-Host "Modules Successfully Processed: $moduleSuccessCount" -ForegroundColor Green
        Write-Host "Modules Failed: $moduleFailCount" -ForegroundColor Red

        if ($successModules.Count -gt 0) {
            Write-Host "Successful Modules:" -ForegroundColor Green
            $successModules | Format-Table -Property Name, Version, Path -AutoSize | Out-String | Write-Host
        }

        if ($failedModules.Count -gt 0) {
            Write-Host "Failed Modules:" -ForegroundColor Red
            $failedModules | Format-Table -Property Name, Version, Path -AutoSize | Out-String | Write-Host
        }

        Write-Host "-----------------------------------" -ForegroundColor Cyan
    }
}