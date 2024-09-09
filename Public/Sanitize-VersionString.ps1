function Sanitize-VersionString {
    param (
        [string]$versionString
    )

    try {
        # Remove any non-numeric characters and additional segments like ".windows"
        $sanitizedVersion = $versionString -replace '[^0-9.]', '' -replace '\.\.+', '.'

        # Convert to System.Version
        $version = [version]$sanitizedVersion
        return $version
    }
    catch {
        Write-EnhancedModuleStarterLog -Message "Failed to convert version string: $versionString. Error: $_" -Level "ERROR"
        return $null
    }
}