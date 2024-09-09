# function Write-EnhancedModuleStarterLog {
#     param (
#         [string]$Message,
#         [string]$Level = "INFO"
#     )

#     # Get the PowerShell call stack to determine the actual calling function
#     $callStack = Get-PSCallStack
#     $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }

#     # Get the parent script name
#     $parentScriptName = Get-ParentScriptName

#     # Prepare the formatted message with the actual calling function information
#     $formattedMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] [$parentScriptName.$callerFunction] $Message"

#     # Display the log message based on the log level using Write-Host
#     switch ($Level.ToUpper()) {
#         "DEBUG" { Write-Host $formattedMessage -ForegroundColor DarkGray }
#         "INFO" { Write-Host $formattedMessage -ForegroundColor Green }
#         "NOTICE" { Write-Host $formattedMessage -ForegroundColor Cyan }
#         "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
#         "ERROR" { Write-Host $formattedMessage -ForegroundColor Red }
#         "CRITICAL" { Write-Host $formattedMessage -ForegroundColor Magenta }
#         default { Write-Host $formattedMessage -ForegroundColor White }
#     }

#     # Append to log file
#     $logFilePath = [System.IO.Path]::Combine($env:TEMP, 'Module-Starter.log')
#     $formattedMessage | Out-File -FilePath $logFilePath -Append -Encoding utf8
# }