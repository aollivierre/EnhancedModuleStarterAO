
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
        [string]$GhPath
    )

    begin {
        Write-Log -Message "Starting Authenticate-GitHubCLI function" -Level "NOTICE"
        # Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    process {
        try {
            Write-Log -Message "Authenticating with GitHub CLI..." -Level "INFO"

            # Prompt user to choose the authentication method
            $choice = Read-Host "Select authentication method: 1) Enter GitHub token manually 2) Use secrets file in `$PSScriptRoot"

            if ($choice -eq '1') {
                # Option 1: Enter GitHub token manually
                $secureToken = Read-Host "Enter your GitHub token" -AsSecureString
                $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                $token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
                Write-Log -Message "Using manually entered GitHub token for authentication." -Level "INFO"
            }
            elseif ($choice -eq '2') {
                # Option 2: Use secrets file in $PSScriptRoot
                $secretsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.psd1"

                if (-not (Test-Path -Path $secretsFilePath)) {
                    $errorMessage = "Secrets file not found at path: $secretsFilePath"
                    Write-Log -Message $errorMessage -Level "ERROR"
                    throw $errorMessage
                }

                $secrets = Import-PowerShellDataFile -Path $secretsFilePath
                $token = $secrets.GitHubToken

                if (-not $token) {
                    $errorMessage = "GitHub token not found in the secrets file."
                    Write-Log -Message $errorMessage -Level "ERROR"
                    throw $errorMessage
                }

                Write-Log -Message "Using GitHub token from secrets file for authentication." -Level "INFO"
            }
            else {
                $errorMessage = "Invalid selection. Please choose 1 or 2."
                Write-Log -Message $errorMessage -Level "ERROR"
                throw $errorMessage
            }

            # Check if GitHub CLI is already authenticated
            $authArguments = @("auth", "status", "-h", "github.com")
            $authStatus = & $GhPath $authArguments 2>&1

            if ($authStatus -notlike "*Logged in to github.com*") {
                Write-Log -Message "GitHub CLI is not authenticated. Attempting authentication using selected method..." -Level "WARNING"

                # Authenticate using the selected method
                $loginArguments = @("auth", "login", "--with-token")
                echo $token | & $GhPath $loginArguments

                # Re-check the authentication status
                $authStatus = & $GhPath $authArguments 2>&1
                if ($authStatus -like "*Logged in to github.com*") {
                    Write-Log -Message "GitHub CLI successfully authenticated." -Level "INFO"
                }
                else {
                    $errorMessage = "Failed to authenticate GitHub CLI. Please check the token and try again."
                    Write-Log -Message $errorMessage -Level "ERROR"
                    throw $errorMessage
                }
            }
            else {
                Write-Log -Message "GitHub CLI is already authenticated." -Level "INFO"
            }
        }
        catch {
            Write-Log -Message "An error occurred during GitHub CLI authentication: $($_.Exception.Message)" -Level "ERROR"
            throw $_
        }
    }

    end {
        Write-Log -Message "Authenticate-GitHubCLI function execution completed." -Level "NOTICE"
    }
}