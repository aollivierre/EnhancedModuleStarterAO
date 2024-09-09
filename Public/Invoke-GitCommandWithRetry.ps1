
function Invoke-GitCommandWithRetry {
    param (
        [string]$GitPath,
        [string]$Arguments,
        [int]$MaxRetries = 3,
        [int]$DelayBetweenRetries = 5
    )

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            # Split the arguments string into an array for correct parsing
            $argumentArray = $Arguments -split ' '
            $output = & "$GitPath" @argumentArray
            if ($output -match "fatal:") {
                Write-EnhancedLog -Message "Git command failed: $output" -Level "WARNING"
                if ($i -lt ($MaxRetries - 1)) {
                    Write-EnhancedLog -Message "Retrying in $DelayBetweenRetries seconds..." -Level "INFO"
                    Start-Sleep -Seconds $DelayBetweenRetries
                }
                else {
                    Write-EnhancedLog -Message "Git command failed after $MaxRetries retries." -Level "ERROR"
                    throw "Git command failed: $output"
                }
            }
            else {
                return $output
            }
        }
        catch {
            Write-EnhancedLog -Message "Error executing Git command: $_" -Level "ERROR"
            if ($i -lt ($MaxRetries - 1)) {
                Write-EnhancedLog -Message "Retrying in $DelayBetweenRetries seconds..." -Level "INFO"
                Start-Sleep -Seconds $DelayBetweenRetries
            }
            else {
                throw $_
            }
        }
    }
}
