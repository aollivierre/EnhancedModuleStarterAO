function Authenticate-GitHubCLI {
    <#
    .SYNOPSIS
    Authenticates with GitHub CLI using a token provided by the user or from a secrets file.

    .DESCRIPTION
    This function allows the user to authenticate with GitHub CLI by either entering a GitHub token manually or using a token from a secrets file located in the `$PSScriptRoot`.

    .PARAMETER GhPath
    The path to the GitHub CLI executable (gh.exe).

    .EXAMPLE
    Authenticate-GitHubCLI -GhPath "C:\Program Files\GitHub CLI\gh.exe"
    Prompts the user to choose between entering the GitHub token manually or using the token from the secrets file.

    .NOTES
    This function requires GitHub CLI (gh) to be installed and available at the specified path.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GhPath,
        [Parameter(Mandatory = $false)]
        [string]$ScriptDirectory
    )

    begin {
        Write-EnhancedLog -Message "Starting Authenticate-GitHubCLI function" -Level "NOTICE"



        
        # Define the URL for the GitHub CLI releases page
        $githubCLIReleasesUrl = "https://api.github.com/repos/cli/cli/releases/latest"

        # Define the local path to save the installer
        $installerPath = "$env:TEMP\gh_cli_installer.msi"

        # Example invocation to install GitHub CLI:
        Install-GitHubCLI -releasesUrl $githubCLIReleasesUrl -installerPath $installerPath


    }

    process {
        try {
            Write-EnhancedLog -Message "Authenticating with GitHub CLI..." -Level "INFO"
            
            # Define the secrets file path
            $secretsFilePath = Join-Path -Path $ScriptDirectory -ChildPath "secrets.psd1"

            if (-not (Test-Path -Path $secretsFilePath)) {
                # If the secrets file does not exist, prompt the user to enter the token
                Write-Warning "Secrets file not found. Please enter your GitHub token."
                $secureToken = Read-Host "Enter your GitHub token" -AsSecureString
                
                # Store the token securely in the secrets.psd1 file
                $secretsContent = @{
                    GitHubToken = $secureToken | ConvertFrom-SecureString
                }
                $secretsContent | Export-Clixml -Path $secretsFilePath
                Write-Host "GitHub token has been saved securely to $secretsFilePath." -ForegroundColor Green
            }
            else {
                # If the secrets file exists, import it
                $secrets = Import-Clixml -Path $secretsFilePath
                $secureToken = $secrets.GitHubToken | ConvertTo-SecureString

                if (-not $secureToken) {
                    $errorMessage = "GitHub token not found in the secrets file."
                    Write-EnhancedLog -Message $errorMessage -Level "ERROR"
                    throw $errorMessage
                }

                Write-EnhancedLog -Message "Using GitHub token from secrets file for authentication." -Level "INFO"
            }

            # Convert secure string back to plain text for GitHub CLI authentication
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
            $token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

            # Check if GitHub CLI is already authenticated
            $authArguments = @("auth", "status", "-h", "github.com")
            $authStatus = & $GhPath $authArguments 2>&1

            if ($authStatus -notlike "*Logged in to github.com*") {
                Write-EnhancedLog -Message "GitHub CLI is not authenticated. Attempting authentication using selected method..." -Level "WARNING"

                # Authenticate using the token
                $loginArguments = @("auth", "login", "--with-token")
                echo $token | & $GhPath $loginArguments

                # Re-check the authentication status
                $authStatus = & $GhPath $authArguments 2>&1
                if ($authStatus -like "*Logged in to github.com*") {
                    Write-EnhancedLog -Message "GitHub CLI successfully authenticated." -Level "INFO"
                }
                else {
                    $errorMessage = "Failed to authenticate GitHub CLI. Please check the token and try again."
                    Write-EnhancedLog -Message $errorMessage -Level "ERROR"
                    throw $errorMessage
                }
            }
            else {
                Write-EnhancedLog -Message "GitHub CLI is already authenticated." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during GitHub CLI authentication: $($_.Exception.Message)" -Level "ERROR"
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Authenticate-GitHubCLI function execution completed." -Level "NOTICE"
    }
}
