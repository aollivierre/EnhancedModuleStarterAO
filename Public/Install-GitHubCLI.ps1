function Get-LatestGitHubCLIInstallerUrl {
    <#
    .SYNOPSIS
    Gets the latest GitHub CLI Windows amd64 installer URL.

    .DESCRIPTION
    This function retrieves the URL for the latest GitHub CLI Windows amd64 installer from the GitHub releases page.

    .PARAMETER releasesUrl
    The URL for the GitHub CLI releases page.

    .EXAMPLE
    Get-LatestGitHubCLIInstallerUrl -releasesUrl "https://api.github.com/repos/cli/cli/releases/latest"
    Retrieves the latest GitHub CLI Windows amd64 installer URL.

    .NOTES
    This function requires an internet connection to access the GitHub API.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$releasesUrl
    )

    begin {
        Write-EnhancedLog -Message "Starting Get-LatestGitHubCLIInstallerUrl function" -Level "Notice"
        # Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            $headers = @{
                "User-Agent" = "Mozilla/5.0"
            }

            $response = Invoke-RestMethod -Uri $releasesUrl -Headers $headers

            foreach ($asset in $response.assets) {
                if ($asset.name -match "windows_amd64.msi") {
                    return $asset.browser_download_url
                }
            }

            throw "Windows amd64 installer not found."
        } catch {
            Write-EnhancedLog -Message "Error retrieving installer URL: $_" -Level "ERROR"
            # Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Get-LatestGitHubCLIInstallerUrl function execution completed." -Level "Notice"
    }
}

# Function to get PowerShell path
function Get-PowerShellPath {
    if (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") {
        return "C:\Program Files\PowerShell\7\pwsh.exe"
    }
    elseif (Test-Path "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe") {
        return "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    else {
        throw "Neither PowerShell 7 nor PowerShell 5 was found on this system."
    }
}


function Validate-GitHubCLIInstallation {
    param (
        [version]$MinVersion = [version]"2.54.0",
        [int]$MaxRetries = 3,
        [int]$DelayBetweenRetries = 5  # Delay in seconds
    )

    $retryCount = 0
    $validationSucceeded = $false

    while ($retryCount -lt $MaxRetries -and -not $validationSucceeded) {
        try {
            $registryPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"  # Include HKCU for user-installed apps
            )

            foreach ($path in $registryPaths) {
                $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
                    if ($app.DisplayName -like "*GitHub CLI*") {
                        $installedVersion = [version]$app.DisplayVersion
                        if ($installedVersion -ge $MinVersion) {
                            $validationSucceeded = $true
                            return @{
                                IsInstalled = $true
                                Version     = $installedVersion
                                ProductCode = $app.PSChildName
                            }
                        }
                    }
                }
            }
        } catch {
            Write-EnhancedLog "Error validating GitHub CLI installation: $_" -Level "ERROR"
        }

        $retryCount++
        if (-not $validationSucceeded) {
            Write-EnhancedLog "Validation attempt $retryCount failed: GitHub CLI not found or version does not meet minimum requirements. Retrying in $DelayBetweenRetries seconds..." -Level "WARNING"
            Start-Sleep -Seconds $DelayBetweenRetries
        }
    }

    return @{IsInstalled = $false }
}




function Download-File {
    <#
    .SYNOPSIS
    Downloads a file from a given URL using WebClient.

    .DESCRIPTION
    This function downloads a file from the specified URL and saves it to the given path using the WebClient class for faster downloads.

    .PARAMETER Url
    The URL of the file to download.

    .PARAMETER OutputPath
    The local path where the file should be saved.

    .EXAMPLE
    Download-File -Url "https://example.com/file.msi" -OutputPath "$env:TEMP\file.msi"
    Downloads the file and saves it to the specified path.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    begin {
        Write-EnhancedLog -Message "Starting Download-File function" -Level "Notice"
    }

    process {
        try {
            Write-EnhancedLog -Message "Downloading file from $Url to $OutputPath..." -Level "INFO"
            $webClient = [System.Net.WebClient]::new()
            $webClient.DownloadFile($Url, $OutputPath)
            Write-EnhancedLog -Message "Download completed successfully." -Level "INFO"
        } catch {
            Write-EnhancedLog -Message "Error during file download: $_" -Level "ERROR"
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Download-File function execution completed." -Level "Notice"
    }
}



function Install-GitHubCLI {
    <#
    .SYNOPSIS
    Installs the GitHub CLI on Windows.

    .DESCRIPTION
    This function installs the latest GitHub CLI Windows amd64 installer. It also verifies the installation in the same PowerShell session.

    .PARAMETER releasesUrl
    The URL for the GitHub CLI releases page.

    .PARAMETER installerPath
    The local path to save the installer.

    .EXAMPLE
    Install-GitHubCLI -releasesUrl "https://api.github.com/repos/cli/cli/releases/latest" -installerPath "$env:TEMP\gh_cli_installer.msi"
    Installs the latest GitHub CLI.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$releasesUrl,
        [Parameter(Mandatory = $true)]
        [string]$installerPath
    )

    begin {
        Write-EnhancedLog -Message "Starting Install-GitHubCLI function" -Level "Notice"
    }

    process {
        try {
            # Pre-validation: Check if GitHub CLI is already installed and meets the minimum version
            # $minVersion = [version]"2.54.0"
            # $preValidationResult = Validate-GitHubCLIInstallation -MinVersion $minVersion
            
            
            $params = @{
                SoftwareName  = "Github CLI"
                MinVersion    = [version]"2.54"
                LatestVersion = [version]"2.54"
                # RegistryPath  = "HKLM:\SOFTWARE\7-Zip"
                ExePath       = "C:\Program Files\GitHub CLI\gh.exe"
            }
            $preValidationResult = Validate-SoftwareInstallation @params

            
            if ($preValidationResult.IsInstalled) {
                Write-EnhancedLog -Message "GitHub CLI is already installed and meets the minimum version. Version: $($preValidationResult.Version)" -Level "INFO"
                return
            }

            # Get the latest installer URL
            $installerUrl = Get-LatestGitHubCLIInstallerUrl -releasesUrl $releasesUrl

            # Download the installer using the Download-File function
            Download-File -Url $installerUrl -OutputPath $installerPath

            # Install the GitHub CLI
            Write-EnhancedLog -Message "Running the GitHub CLI installer..." -Level "INFO"
            $msiArgs = @(
                "/i"
                $installerPath
                "/quiet"
                "/norestart"
            )
            Start-Process msiexec.exe -ArgumentList $msiArgs -NoNewWindow -Wait

            # Post-validation: Verify the installation by calling Validate-GitHubCLIInstallation
            Write-EnhancedLog -Message "Verifying the GitHub CLI installation..." -Level "INFO"
            # $postValidationResult = Validate-GitHubCLIInstallation -MinVersion $minVersion


                        
            $params = @{
                SoftwareName  = "Github CLI"
                MinVersion    = [version]"2.54"
                LatestVersion = [version]"2.54"
                # RegistryPath  = "HKLM:\SOFTWARE\7-Zip"
                ExePath       = "C:\Program Files\GitHub CLI\gh.exe"
            }
            $postValidationResult = Validate-SoftwareInstallation @params

            if ($postValidationResult.IsInstalled) {
                Write-EnhancedLog -Message "GitHub CLI installed successfully. Version: $($postValidationResult.Version)" -Level "INFO"
            } else {
                Write-EnhancedLog -Message "GitHub CLI installation failed or does not meet the minimum version requirement." -Level "ERROR"
                throw "GitHub CLI installation validation failed."
            }
        } catch {
            Write-EnhancedLog -Message "Error during GitHub CLI installation: $_" -Level "ERROR"
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Install-GitHubCLI function execution completed." -Level "Notice"
    }
}