function Import-ModulesFromLocalRepository {
    <#
    .SYNOPSIS
    Imports all modules found in the specified Modules directory.

    .DESCRIPTION
    This function scans the Modules directory for module folders and attempts to import the module. If a module
    file is not found or if importing fails, appropriate error messages are logged.

    .PARAMETER ModulesFolderPath
    The path to the folder containing the modules.

    .PARAMETER ScriptPath
    The path to the script directory containing the exclusion file.

    .EXAMPLE
    Import-ModulesFromLocalRepository -ModulesFolderPath "C:\code\Modules" -ScriptPath "C:\scripts"
    This example imports all modules found in the specified Modules directory.
    #>

    [CmdletBinding()]
    param (
        [string]$ModulesFolderPath
        # [string]$ScriptPath
    )

    Begin {
        # Get the path to the Modules directory
        $moduleDirectories = Get-ChildItem -Path $ModulesFolderPath -Directory

        Write-Host "Module directories found: $($moduleDirectories.Count)" -ForegroundColor ([ConsoleColor]::Cyan)

        # Read the modules exclusion list from the JSON file
        # $exclusionFilePath = Join-Path -Path $ScriptPath -ChildPath "modulesexclusion.json"
    #     if (Test-Path -Path $exclusionFilePath) {
    #         $excludedModules = Get-Content -Path $exclusionFilePath | ConvertFrom-Json
    #         Write-Host "Excluded modules: $excludedModules" -ForegroundColor ([ConsoleColor]::Cyan)
    #     } else {
    #         $excludedModules = @()
    #         Write-Host "No exclusion file found. Proceeding with all modules." -ForegroundColor ([ConsoleColor]::Yellow)
    #     }
    }

    Process {
        foreach ($moduleDir in $moduleDirectories) {
            # Skip the module if it is in the exclusion list
            if ($excludedModules -contains $moduleDir.Name) {
                Write-Host "Skipping excluded module: $($moduleDir.Name)" -ForegroundColor ([ConsoleColor]::Yellow)
                continue
            }

            # Construct the path to the module file
            $modulePath = Join-Path -Path $moduleDir.FullName -ChildPath "$($moduleDir.Name).psm1"

            # Check if the module file exists
            if (Test-Path -Path $modulePath) {
                # Import the module with retry logic
                try {
                    Import-ModuleWithRetry -ModulePath $modulePath
                    Write-Host "Successfully imported module: $($moduleDir.Name)" -ForegroundColor ([ConsoleColor]::Green)
                }
                catch {
                    Write-Host "Failed to import module: $($moduleDir.Name). Error: $_" -ForegroundColor ([ConsoleColor]::Red)
                }
            }
            else {
                Write-Host "Module file not found: $modulePath" -ForegroundColor ([ConsoleColor]::Red)
            }
        }
    }

    End {
        Write-Host "Module import process completed." -ForegroundColor ([ConsoleColor]::Cyan)
    }
}
