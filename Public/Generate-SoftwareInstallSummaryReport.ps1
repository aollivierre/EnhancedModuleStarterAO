function Generate-SoftwareInstallSummaryReport {
    param (
        [PSCustomObject[]]$installationResults
    )

    $totalSoftware = $installationResults.Count
    $successfulInstallations = $installationResults | Where-Object { $_.Status -eq "Successfully Installed" }
    $alreadyInstalled = $installationResults | Where-Object { $_.Status -eq "Already Installed" }
    $failedInstallations = $installationResults | Where-Object { $_.Status -like "Failed*" }

    Write-Host "Total Software: $totalSoftware" -ForegroundColor Cyan
    Write-Host "Successful Installations: $($successfulInstallations.Count)" -ForegroundColor Green
    Write-Host "Already Installed: $($alreadyInstalled.Count)" -ForegroundColor Yellow
    Write-Host "Failed Installations: $($failedInstallations.Count)" -ForegroundColor Red

    # Detailed Summary
    Write-Host "`nDetailed Summary:" -ForegroundColor Cyan
    $installationResults | ForEach-Object {
        Write-Host "Software: $($_.SoftwareName)" -ForegroundColor White
        Write-Host "Status: $($_.Status)" -ForegroundColor White
        Write-Host "Version Found: $($_.VersionFound)" -ForegroundColor White
        Write-Host "----------------------------------------" -ForegroundColor Gray
    }
}