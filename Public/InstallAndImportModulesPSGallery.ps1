function Invoke-ParallelExecution {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Modules,
        [string]$PwshPath
    )
    
    Write-EnhancedLog -Message "Running in parallel execution mode" -Level "INFO"
    $processList = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()

    foreach ($moduleName in $Modules) {
        $splatProcessParams = @{
            FilePath     = $PwshPath
            ArgumentList = @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command", "& { Update-ModuleIfOldOrMissing -ModuleName '$moduleName' }"
            )
            NoNewWindow  = $true
            PassThru     = $true
        }

        # Start the process for parallel execution
        $process = Start-Process @splatProcessParams
        $processList.Add($process)
    }

    # Wait for all processes to complete
    foreach ($process in $processList) {
        $process.WaitForExit()
    }

    Write-EnhancedLog "All module update processes have completed (parallel execution)." -Level "NOTICE"

    # After parallel execution, validate module installation
    $successModules = [System.Collections.Generic.List[PSCustomObject]]::new()
    $failedModules = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($moduleName in $Modules) {
        $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        if ($moduleInfo) {
            $moduleDetails = [PSCustomObject]@{
                Name    = $moduleName
                Version = $moduleInfo.Version
                Path    = $moduleInfo.ModuleBase
            }
            $successModules.Add($moduleDetails)
            Write-EnhancedLog -Message "Successfully installed/updated module: $moduleName" -Level "INFO"
        }
        else {
            $moduleDetails = [PSCustomObject]@{
                Name    = $moduleName
                Version = "N/A"
                Path    = "N/A"
            }
            $failedModules.Add($moduleDetails)
            Write-EnhancedLog -Message "Failed to install/update module: $moduleName" -Level "ERROR"
        }
    }

    return @{
        SuccessModules = $successModules
        FailedModules  = $failedModules
    }
}

function Invoke-SeriesExecution {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Modules
    )

    Write-EnhancedLog -Message "Running in series execution mode" -Level "INFO"

    foreach ($moduleName in $Modules) {
        try {
            Update-ModuleIfOldOrMissing -ModuleName $moduleName
            Write-EnhancedLog -Message "Successfully installed/updated module: $moduleName" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to install/update module: $moduleName. Error: $_" -Level "ERROR"
        }
    }

    Write-EnhancedLog "All module update processes have completed (series execution)." -Level "NOTICE"
}

function Display-SummaryReport {
    param (
        [Parameter(Mandatory = $true)]
        [int]$ModuleSuccessCount,
        [int]$ModuleFailCount,
        [System.Collections.Generic.List[PSCustomObject]]$SuccessModules,
        [System.Collections.Generic.List[PSCustomObject]]$FailedModules
    )

    Write-Host "---------- Summary Report ----------" -ForegroundColor Cyan
    Write-Host "Total Modules Processed: $($ModuleSuccessCount + $ModuleFailCount)" -ForegroundColor Cyan
    Write-Host "Modules Successfully Processed: $ModuleSuccessCount" -ForegroundColor Green
    Write-Host "Modules Failed: $ModuleFailCount" -ForegroundColor Red

    if ($SuccessModules.Count -gt 0) {
        Write-Host "Successful Modules:" -ForegroundColor Green
        $SuccessModules | Format-Table -Property Name, Version, Path -AutoSize | Out-String | Write-Host
    }

    if ($FailedModules.Count -gt 0) {
        Write-Host "Failed Modules:" -ForegroundColor Red
        $FailedModules | Format-Table -Property Name, Version, Path -AutoSize | Out-String | Write-Host
    }

    Write-Host "-----------------------------------" -ForegroundColor Cyan
}

function InstallAndImportModulesPSGallery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePsd1Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("series", "parallel")]
        [string]$ExecutionMode
    )

    begin {
        Write-EnhancedLog -Message "Starting InstallAndImportModulesPSGallery function in $ExecutionMode mode" -Level "INFO"
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

            # Determine the PowerShell path
            $PwshPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

            # Execute in parallel or series mode
            $executionResult = $null
            if ($ExecutionMode -eq "parallel" -and -not (Is-ServerCore)) {
                $executionResult = Invoke-ParallelExecution -Modules $requiredModules -PwshPath $PwshPath
            }
            else {
                Invoke-SeriesExecution -Modules $requiredModules
            }

            if ($executionResult) {
                $successModules.AddRange($executionResult.SuccessModules)
                $failedModules.AddRange($executionResult.FailedModules)
                $moduleSuccessCount += $executionResult.SuccessModules.Count
                $moduleFailCount += $executionResult.FailedModules.Count
            }

            # Import additional modules from PSD1
            if ($importedModules) {
                Write-EnhancedLog -Message "Importing modules: $($importedModules -join ', ')" -Level "INFO"
                foreach ($moduleName in $importedModules) {
                    try {
                        Import-Module -Name $moduleName -Force
                        $moduleInfo = Get-Module -Name $moduleName | Select-Object -First 1
                        $moduleDetails = [PSCustomObject]@{
                            Name    = $moduleName
                            Version = $moduleInfo.Version
                            Path    = $moduleInfo.ModuleBase
                        }
                        $successModules.Add($moduleDetails)
                        Write-EnhancedLog -Message "Successfully imported module: $moduleName" -Level "INFO"
                        $moduleSuccessCount++
                    }
                    catch {
                        $moduleDetails = [PSCustomObject]@{
                            Name    = $moduleName
                            Version = "N/A"
                            Path    = "N/A"
                        }
                        $failedModules.Add($moduleDetails)
                        Write-EnhancedLog -Message "Failed to import module: $moduleName. Error: $_" -Level "ERROR"
                        $moduleFailCount++
                    }
                }
            }

            # Import custom modules
            if ($myModules) {
                Write-EnhancedLog -Message "Importing custom modules: $($myModules -join ', ')" -Level "INFO"
                foreach ($moduleName in $myModules) {
                    try {
                        Import-Module -Name $moduleName -Force
                        $moduleInfo = Get-Module -Name $moduleName | Select-Object -First 1
                        $moduleDetails = [PSCustomObject]@{
                            Name    = $moduleName
                            Version = $moduleInfo.Version
                            Path    = $moduleInfo.ModuleBase
                        }
                        $successModules.Add($moduleDetails)
                        Write-EnhancedLog -Message "Successfully imported custom module: $moduleName" -Level "INFO"
                        $moduleSuccessCount++
                    }
                    catch {
                        $moduleDetails = [PSCustomObject]@{
                            Name    = $moduleName
                            Version = "N/A"
                            Path    = "N/A"
                        }
                        $failedModules.Add($moduleDetails)
                        Write-EnhancedLog -Message "Failed to import custom module: $moduleName. Error: $_" -Level "ERROR"
                        $moduleFailCount++
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
        $summaryParams = @{
            ModuleSuccessCount = $moduleSuccessCount
            ModuleFailCount    = $moduleFailCount
            SuccessModules     = $successModules
            FailedModules      = $failedModules
        }
        
        Display-SummaryReport @summaryParams
        
    }
}