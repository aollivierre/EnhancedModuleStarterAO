function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO'
    )

    # Check the global async logging setting and silent mode
    $Async = $global:LOG_ASYNC
    $Silent = $global:LOG_SILENT

    # Get the PowerShell call stack to determine the actual calling function
    $callStack = Get-PSCallStack
    $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }

    # Get the parent script name
    $parentScriptName = Get-ParentScriptName

    # Prepare the formatted message with the actual calling function information
    $formattedMessage = "[$Level] $Message"

    # In Silent mode, treat all levels as Debug
    if ($Silent) {
        $Level = 'DEBUG'
    }

    # Map custom levels to PSFramework levels based on async mode and log type
    $psfLevel = switch ($Level.ToUpper()) {
        # These levels always log to the console, synchronously
        'CRITICAL' { 'Critical' }  # Always log to console, sync (unless in silent mode)
        'ERROR'    { 'Error' }     # Always log to console, sync (unless in silent mode)
        'WARNING'  { 'Warning' }   # Always log to console, sync (unless in silent mode)

        # Other levels behave differently based on async mode
        'INFO'            { if ($Async) { 'Debug' } else { 'Host' } }
        'DEBUG'           { if ($Async) { 'Debug' } else { 'Host' } }
        'NOTICE'          { if ($Async) { 'Debug' } else { 'Important' } }
        'IMPORTANT'       { if ($Async) { 'Debug' } else { 'Important' } }
        'OUTPUT'          { if ($Async) { 'Debug' } else { 'Output' } }
        'SIGNIFICANT'     { if ($Async) { 'Debug' } else { 'Significant' } }
        'VERYVERBOSE'     { if ($Async) { 'Debug' } else { 'VeryVerbose' } }
        'VERBOSE'         { if ($Async) { 'Debug' } else { 'Verbose' } }
        'SOMEWHATVERBOSE' { if ($Async) { 'Debug' } else { 'SomewhatVerbose' } }
        'SYSTEM'          { if ($Async) { 'Debug' } else { 'System' } }
        'INTERNALCOMMENT' { if ($Async) { 'Debug' } else { 'InternalComment' } }

        # Default to 'Host' if no match is found (sync to console)
        default { 'Host' }
    }

    # Log the message using the mapped PSFramework log level
    Write-PSFMessage -Level $psfLevel -Message $formattedMessage -FunctionName "$parentScriptName.$callerFunction"
}
