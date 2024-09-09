function Download-Psd1File {
    <#
    .SYNOPSIS
    Downloads a PSD1 file from a specified URL and saves it to a local destination.

    .DESCRIPTION
    This function downloads a PowerShell Data file (PSD1) from a given URL and saves it to the specified local path. 
    If the download fails, an error is logged and the function throws an exception.

    .PARAMETER url
    The URL of the PSD1 file to be downloaded.

    .PARAMETER destinationPath
    The local path where the PSD1 file will be saved.

    .EXAMPLE
    Download-Psd1File -url "https://example.com/modules.psd1" -destinationPath "$env:TEMP\modules.psd1"
    Downloads the PSD1 file from the specified URL and saves it to the provided local path.

    .NOTES
    This function requires internet access to download the PSD1 file from the specified URL.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$url,

        [Parameter(Mandatory = $true)]
        [string]$destinationPath
    )

    begin {
        Write-EnhancedLog -Message "Starting Download-Psd1File function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate destination directory
        $destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
        if (-not (Test-Path -Path $destinationDirectory)) {
            Write-EnhancedLog -Message "Destination directory not found at path: $destinationDirectory" -Level "ERROR"
            throw "Destination directory not found."
        }

        Write-EnhancedLog -Message "Validated destination directory at path: $destinationDirectory" -Level "INFO"
    }

    process {
        try {
            Write-EnhancedLog -Message "Downloading PSD1 file from URL: $url" -Level "INFO"
            Invoke-WebRequest -Uri $url -OutFile $destinationPath -UseBasicParsing
            Write-EnhancedLog -Message "Downloaded PSD1 file to: $destinationPath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to download PSD1 file from $url. Error: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Download-Psd1File function execution completed." -Level "NOTICE"
    }
}
