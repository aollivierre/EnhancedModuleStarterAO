function Get-LatestChocoVersion {
    <#
    .SYNOPSIS
    Retrieves the latest version of a specified package from Chocolatey.

    .DESCRIPTION
    This function retrieves the latest version of a package from Chocolatey, given the package name. It includes logging for each step, handles cases where the package is not found, and supports pipeline input.

    .PARAMETER AppName
    The name of the application/package to search for in Chocolatey.

    .EXAMPLE
    $apps = 'GoogleChrome', 'MicrosoftEdge', 'Firefox'
    $apps | Get-LatestChocoVersion
    Retrieves the latest versions of Google Chrome, Microsoft Edge, and Firefox from Chocolatey.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$AppName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-LatestChocoVersion function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Check if choco.exe is available
        Write-EnhancedLog -Message "Checking if choco.exe is available..." -Level "INFO"
        if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
            Write-EnhancedLog -Message "choco.exe not found. Ensure Chocolatey is installed and available in PATH." -Level "ERROR"
            throw "Chocolatey is not installed or not available in PATH."
        }
    }

    Process {
        Write-EnhancedLog -Message "Finding the latest version of $AppName..." -Level "INFO"

        # Perform the search and capture raw output
        $rawOutput = choco search $AppName --exact --allversions
        Write-EnhancedLog -Message "Raw search output: `n$rawOutput" -Level "DEBUG"

        # Filter and extract the version information
        $versionLines = $rawOutput | ForEach-Object {
            if ($_ -match "$AppName\s+([\d\.]+)") {
                $matches[1]
            }
        }

        if ($versionLines) {
            # Sort the versions and select the latest one
            $latestVersion = $versionLines | Sort-Object { [version]$_ } -Descending | Select-Object -First 1

            if ($latestVersion) {
                Write-EnhancedLog -Message "The latest version of $AppName available in Chocolatey is: $latestVersion" -Level "INFO"
                [PSCustomObject]@{
                    AppName       = $AppName
                    LatestVersion = $latestVersion
                }
            } else {
                Write-EnhancedLog -Message "No version information found for $AppName." -Level "WARNING"
            }
        } else {
            Write-EnhancedLog -Message "No version information found for $AppName." -Level "WARNING"
            Write-EnhancedLog -Message "Possible reasons: the package name may be incorrect, or the package may not be available in the Chocolatey repository." -Level "INFO"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LatestChocoVersion function" -Level "Notice"
    }
}

# # Example usage
# $apps = 'GoogleChrome', 'MicrosoftEdge', 'Firefox'
# $apps | Get-LatestChocoVersion
