function Compare-SoftwareVersion {
    param (
        [Parameter(Mandatory = $true)]
        [version]$InstalledVersion,

        [Parameter(Mandatory = $false)]
        [version]$MinVersion = [version]"0.0.0.0",

        [Parameter(Mandatory = $false)]
        [version]$LatestVersion
    )

    $meetsMinRequirement = $InstalledVersion -ge $MinVersion
    
    if ($LatestVersion) {
        $isUpToDate = $InstalledVersion -ge $LatestVersion
    }
    else {
        $isUpToDate = $meetsMinRequirement
    }

    return [PSCustomObject]@{
        MeetsMinRequirement = $meetsMinRequirement
        IsUpToDate          = $isUpToDate
    }
}
