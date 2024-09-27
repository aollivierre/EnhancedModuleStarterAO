function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [switch]$Async = $false # Remove default value, it will be controlled by the environment variable
    )

    # Check if the Async switch is not set, then use the global variable
    if (-not $Async) {
        $Async = $global:LOG_ASYNC
        # Write-Host "Global LOG_ASYNC variable is set to $Async"
    }


    # Get the PowerShell call stack to determine the actual calling function
    $callStack = Get-PSCallStack
    $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }

    # Get the parent script name
    $parentScriptName = Get-ParentScriptName

    # Prepare the formatted message with the actual calling function information
    $formattedMessage = "[$Level] $Message"

    # Map custom levels to PSFramework levels
    $psfLevel = switch ($Level.ToUpper()) {
        'DEBUG' { 'Debug' }
        'INFO' { 'Host' }
        'NOTICE' { 'Important' }
        'WARNING' { 'Warning' }
        'ERROR' { 'Error' }
        'CRITICAL' { 'Critical' }
        'IMPORTANT' { 'Important' }
        'OUTPUT' { 'Output' }
        'SIGNIFICANT' { 'Significant' }
        'VERYVERBOSE' { 'VeryVerbose' }
        'VERBOSE' { 'Verbose' }
        'SOMEWHATVERBOSE' { 'SomewhatVerbose' }
        'SYSTEM' { 'System' }
        'INTERNALCOMMENT' { 'InternalComment' }
        default { 'Host' }
    }

    if ($Async) {
        # Enqueue the log message for async processing
        $logItem = [PSCustomObject]@{
            Level        = $psfLevel
            Message      = $formattedMessage
            FunctionName = "$parentScriptName.$callerFunction"
        }
        $global:LogQueue.Enqueue($logItem)
    }
    else {
        # Log the message synchronously
        Write-PSFMessage -Level $psfLevel -Message $formattedMessage -FunctionName "$parentScriptName.$callerFunction"
    }
}
