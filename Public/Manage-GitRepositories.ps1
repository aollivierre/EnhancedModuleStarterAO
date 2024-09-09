function Manage-GitRepositories {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulesBasePath
    )

    begin {
        Write-EnhancedModuleStarterLog -Message "Starting Manage-GitRepositories function" -Level "INFO"

        # Initialize lists for tracking repository statuses
        $reposWithPushChanges = [System.Collections.Generic.List[string]]::new()
        $reposSummary = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Validate ModulesBasePath
        if (-not (Test-Path -Path $ModulesBasePath)) {
            Write-EnhancedModuleStarterLog -Message "Modules base path not found: $ModulesBasePath" -Level "ERROR"
            throw "Modules base path not found."
        }

        Write-EnhancedModuleStarterLog -Message "Found modules base path: $ModulesBasePath" -Level "INFO"

        # Get the Git path
        $GitPath = Get-GitPath
        if (-not $GitPath) {
            throw "Git executable not found."
        }

        # Set environment variable to avoid interactive Git prompts
        $env:GIT_TERMINAL_PROMPT = "0"
    }

    process {
        try {
            $repos = Get-ChildItem -Path $ModulesBasePath -Directory

            foreach ($repo in $repos) {
                Set-Location -Path $repo.FullName

                # Add the repository to Git's safe directories
                $repoPath = $repo.FullName
                $arguments = "config --global --add safe.directory `"$repoPath`""
                Invoke-GitCommandWithRetry -GitPath $GitPath -Arguments $arguments



                # Remove any existing .gitconfig.lock file to avoid rename prompt
                $lockFilePath = "$HOME\.gitconfig.lock"
                if (Test-Path $lockFilePath) {
                    Remove-Item $lockFilePath -Force
                    Write-EnhancedModuleStarterLog -Message "Removed .gitconfig.lock file for repository $($repo.Name)" -Level "INFO"
                }

                # Fetch the latest changes with a retry mechanism
                Invoke-GitCommandWithRetry -GitPath $GitPath -Arguments "fetch"



                # Check for pending changes
                $arguments = "status"
                Invoke-GitCommandWithRetry -GitPath $GitPath -Arguments $arguments

                if ($status -match "fatal:") {
                    Write-EnhancedModuleStarterLog -Message "Error during status check in repository $($repo.Name): $status" -Level "ERROR"
                    continue
                }

                $repoStatus = "Up to Date"
                if ($status -match "Your branch is behind") {
                    Write-EnhancedModuleStarterLog -Message "Repository $($repo.Name) is behind the remote. Pulling changes..." -Level "INFO"
                    # Pull changes if needed
                    Invoke-GitCommandWithRetry -GitPath $GitPath -Arguments "pull"
                    $repoStatus = "Pulled"
                }

                if ($status -match "Your branch is ahead") {
                    Write-EnhancedModuleStarterLog -Message "Repository $($repo.Name) has unpushed changes." -Level "WARNING"
                    $reposWithPushChanges.Add($repo.FullName)
                    $repoStatus = "Pending Push"
                }

                # Add the repository status to the summary list
                $reposSummary.Add([pscustomobject]@{
                        RepositoryName = $repo.Name
                        Status         = $repoStatus
                        LastChecked    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    })
            }

            # Summary of repositories with pending push changes
            if ($reposWithPushChanges.Count -gt 0) {
                Write-EnhancedModuleStarterLog -Message "The following repositories have pending push changes:" -Level "WARNING"
                $reposWithPushChanges | ForEach-Object { Write-EnhancedModuleStarterLog -Message $_ -Level "WARNING" }

                Write-EnhancedModuleStarterLog -Message "Please manually commit and push the changes in these repositories." -Level "WARNING"
            }
            else {
                Write-EnhancedModuleStarterLog -Message "All repositories are up to date." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedModuleStarterLog -Message "An error occurred while managing Git repositories: $_" -Level "ERROR"
            throw $_
        }
    }

    end {
        # Summary output in the console with color coding
        $totalRepos = $reposSummary.Count
        $pulledRepos = $reposSummary | Where-Object { $_.Status -eq "Pulled" }
        $pendingPushRepos = $reposSummary | Where-Object { $_.Status -eq "Pending Push" }
        $upToDateRepos = $reposSummary | Where-Object { $_.Status -eq "Up to Date" }

        Write-Host "---------- Summary Report ----------" -ForegroundColor Cyan
        Write-Host "Total Repositories: $totalRepos" -ForegroundColor Cyan
        Write-Host "Repositories Pulled: $($pulledRepos.Count)" -ForegroundColor Green
        Write-Host "Repositories with Pending Push: $($pendingPushRepos.Count)" -ForegroundColor Yellow
        Write-Host "Repositories Up to Date: $($upToDateRepos.Count)" -ForegroundColor Green

        # Return to the original location
        Set-Location -Path $ModulesBasePath

        Write-EnhancedModuleStarterLog -Message "Manage-GitRepositories function execution completed." -Level "INFO"
    }
}