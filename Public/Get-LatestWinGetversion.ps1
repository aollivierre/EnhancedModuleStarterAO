function Add-WinGetPathToEnvironment {
    <#
    .SYNOPSIS
    Adds a specified path to the environment PATH variable.

    .DESCRIPTION
    The Add-EnvPath function adds a specified path to the environment PATH variable. The path can be added to the session, user, or machine scope.

    .PARAMETER Path
    The path to be added to the environment PATH variable.

    .PARAMETER Container
    Specifies the scope of the environment variable. Valid values are 'Machine', 'User', or 'Session'.

    .EXAMPLE
    Add-EnvPath -Path 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Imaging and Configuration Designer\x86' -Container 'Machine'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [ValidateSet('Machine', 'User', 'Session')]
        [string] $Container = 'Session'
    )

    begin {
        Write-EnhancedLog -Message "Starting Add-EnvPath function" -Level "INFO"
        Log-Params -Params @{"Path" = $Path; "Container" = $Container}

        $envPathHashtable = [ordered]@{}
        $containerMapping = @{
            Machine = [System.EnvironmentVariableTarget]::Machine
            User    = [System.EnvironmentVariableTarget]::User
        }
    }

    process {
        try {
            # Add to Machine or User PATH
            if ($Container -ne 'Session') {
                $containerType = $containerMapping[$Container]
                $existingPaths = [System.Environment]::GetEnvironmentVariable('Path', $containerType) -split ';'

                if (-not $existingPaths -contains $Path) {
                    $updatedPaths = "$($existingPaths -join ';');$Path"
                    [System.Environment]::SetEnvironmentVariable('Path', $updatedPaths, $containerType)
                    Write-EnhancedLog -Message "Added $Path to $Container PATH." -Level "INFO"
                }
            }

            # Add to Session PATH
            $existingSessionPaths = $env:Path -split ';'
            if (-not $existingSessionPaths -contains $Path) {
                $env:Path += ";$Path"
                Write-EnhancedLog -Message "Added $Path to Session PATH." -Level "INFO"
            }

            # Validate PATH update
            $wingetCmd = Get-Command "winget.exe" -ErrorAction SilentlyContinue
            if (-not $wingetCmd) {
                throw "WinGet executable not found after adding to PATH."
            }
        } catch {
            Write-EnhancedLog -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    end {
        Write-EnhancedLog -Message "Exiting Add-EnvPath function" -Level "INFO"
    }
}
function Find-WinGetPath {
    <#
    .SYNOPSIS
    Finds the path to winget.exe based on the context (Machine or User) and checks for Windows Server.

    .DESCRIPTION
    This function finds the location of winget.exe depending on whether it's running in a machine or user context, and adjusts the environment path if running on Windows Server.

    .EXAMPLE
    $wingetPath = Find-WinGetPath
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Find-WinGetPath function" -Level "Notice"
    }

    Process {
        try {
            # Check if running as SYSTEM
            $isSystem = Test-RunningAsSystem
            Write-EnhancedLog -Message "Running as SYSTEM: $isSystem" -Level "INFO"

            # Check if running on Windows Server
            $isWindowsServer = (Get-WmiObject Win32_OperatingSystem).ProductType -eq 3
            Write-EnhancedLog -Message "Running on Windows Server: $isWindowsServer" -Level "INFO"

            if ($isWindowsServer) {
                # On Windows Server, use the UniGet path
                Write-EnhancedLog -Message "Windows Server detected, using UniGet path for winget..." -Level "INFO"
                $wingetPath = "C:\Program Files\UniGetUI\winget-cli_x64\winget.exe"
                Add-WinGetPathToEnvironment -Path "C:\Program Files\UniGetUI\winget-cli_x64" -Container 'Machine'
            }
            else {
                # On non-server systems running as SYSTEM, resolve the regular winget path
                if ($isSystem) {
                    Write-EnhancedLog -Message "Non-Windows Server system detected and running as SYSTEM, resolving WinGet path..." -Level "INFO"
                    $resolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
                    if ($resolveWingetPath) {
                        $wingetPath = $resolveWingetPath[-1].Path + "\winget.exe"
                    }
                    else {
                        Write-EnhancedLog -Message "Failed to resolve WinGet path." -Level "ERROR"
                        throw "Failed to resolve WinGet path."
                    }
                }
                else {
                    Write-EnhancedLog -Message "Non-Windows Server and not running as SYSTEM, assuming WinGet is available in PATH." -Level "INFO"
                    $wingetPath = "winget.exe"
                }
            }

            # Validate WinGet path
            $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
            if (-not $wingetCommand) {
                Write-EnhancedLog -Message "WinGet executable not found in the specified path: $wingetPath" -Level "ERROR"
                throw "WinGet executable not found."
            }

            Write-EnhancedLog -Message "WinGet path found and validated: $($wingetCommand.Path)" -Level "INFO"
            return $wingetCommand.Path
        }
        catch {
            Write-EnhancedLog -Message "Failed to find WinGet path: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Find-WinGetPath function" -Level "Notice"
    }
}
#Using Winget.exe
function Get-LatestVersionFromWinGet {
    <#
    .SYNOPSIS
    Retrieves the latest version of an application from WinGet.

    .DESCRIPTION
    This function queries WinGet to retrieve the latest version of a specified application.

    .PARAMETER id
    The exact WinGet package ID of the application.

    .EXAMPLE
    $latestVersion = Get-LatestVersionFromWinGet -id "VideoLAN.VLC"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$id
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-LatestVersionFromWinGet function for package ID: $id" -Level "Notice"
    }

    Process {
        try {
            $wingetPath = Find-WinGetPath
            $params = @{
                FilePath               = $wingetPath
                ArgumentList           = "show --id $id --exact --accept-source-agreements"
                WindowStyle            = "Hidden"
                Wait                   = $true
                RedirectStandardOutput = "$env:TEMP\wingetOutput.txt"
            }

            Write-EnhancedLog -Message "Querying WinGet for the latest version of package ID: $id" -Level "INFO"
            Start-Process @params
            $winGetOutput = Get-Content -Path "$env:TEMP\wingetOutput.txt"
            Remove-Item -Path "$env:TEMP\wingetOutput.txt" -Force

            $latestVersion = $winGetOutput | Select-String -Pattern "version:" | ForEach-Object { $_.Line -replace '.*version:\s*(.*)', '$1' }
            Write-EnhancedLog -Message "WinGet latest version: $latestVersion" -Level "INFO"
            return $latestVersion
        }
        catch {
            Write-EnhancedLog -Message "Failed to get latest version from WinGet: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LatestVersionFromWinGet function" -Level "Notice"
    }
}
function Get-LatestWinGetVersion {
    <#
    .SYNOPSIS
    Compares the latest version from WinGet with an optional target version.

    .DESCRIPTION
    This function retrieves the latest available version of an application from WinGet and compares it with an optional target version.

    .PARAMETER id
    The exact WinGet package ID of the application.

    .PARAMETER TargetVersion
    A specific version to target for comparison (optional).

    .PARAMETER AcceptNewerVersion
    Indicates whether a locally installed version that is newer than the target or WinGet version is acceptable.

    .EXAMPLE
    $params = @{
        id                = "VideoLAN.VLC"
        TargetVersion     = ""
        AcceptNewerVersion = $true
    }
    $result = Get-LatestWinGetVersion @params
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$id,

        [Parameter(Mandatory = $false)]
        [string]$TargetVersion = "",

        [Parameter(Mandatory = $false)]
        [bool]$AcceptNewerVersion = $true
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-LatestWinGetVersion function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Get the latest version from WinGet
            $latestVersion = if ($TargetVersion) { [version]$TargetVersion } else { [version](Get-LatestVersionFromWinGet -id $id) }

            $result = [PSCustomObject]@{
                LatestVersion       = $latestVersion
                Status              = "Latest Version Retrieved"
                Message             = "The latest version of $id is $latestVersion."
            }

            Write-EnhancedLog -Message $result.Message -Level "INFO"
            return $result
        }
        catch {
            Write-EnhancedLog -Message "Error in Get-LatestWinGetVersion function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LatestWinGetVersion function" -Level "Notice"
    }
}