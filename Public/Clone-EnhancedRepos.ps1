function Clone-EnhancedRepos {
    <#
    .SYNOPSIS
    Clones all repositories from a GitHub account that start with the word "Enhanced" to a specified directory using GitHub CLI.

    .DESCRIPTION
    This function uses GitHub CLI to list and clone repositories from a GitHub account that start with "Enhanced" into the specified directory.

    .PARAMETER githubUsername
    The GitHub username to retrieve repositories from.

    .PARAMETER targetDirectory
    The directory to clone the repositories into.

    .EXAMPLE
    Clone-EnhancedRepos -githubUsername "aollivierre" -targetDirectory "C:\Code\modules-beta4"
    Clones all repositories starting with "Enhanced" from the specified GitHub account to the target directory.

    .NOTES
    This function requires GitHub CLI (gh) and git to be installed and available in the system's PATH.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$githubUsername,

        [Parameter(Mandatory = $true)]
        [string]$targetDirectory
    )

    begin {
        Write-Log -Message "Starting Clone-EnhancedRepos function" -Level "Notice"

        # Create the target directory if it doesn't exist
        if (-not (Test-Path -Path $targetDirectory)) {
            Write-Log -Message "Creating target directory: $targetDirectory" -Level "INFO"
            New-Item -Path $targetDirectory -ItemType Directory
        }
    }

    process {
     
   
        
        try {
            # Get the Git executable path
            Write-Log -Message "Attempting to find Git executable path..." -Level "INFO"
            $gitPath = Get-GitPath
            if (-not $gitPath) {
                throw "Git executable not found. Please install Git or ensure it is in your PATH."
            }
            Write-Log -Message "Git found at: $gitPath" -Level "INFO"
        
            # Set the GitHub CLI path
            $ghPath = "C:\Program Files\GitHub CLI\gh.exe"
            
            # Define arguments for GitHub CLI as an array
            $ghArguments = @("repo", "list", "aollivierre", "--json", "name,url")

            # Set the path to GitHub CLI executable
            $ghPath = "C:\Program Files\GitHub CLI\gh.exe"

            # Authenticate with GitHub CLI
            Authenticate-GitHubCLI -GhPath $ghPath

        
            # Execute the GitHub CLI command using the argument array
            Write-Log -Message "Retrieving repositories for user $githubUsername using GitHub CLI..." -Level "INFO"
            $reposJson = & $ghPath $ghArguments
            Write-Log -Message "Raw GitHub CLI output: $reposJson" -Level "DEBUG"
            
            if (-not $reposJson) {
                throw "No repositories found or an error occurred while retrieving repositories."
            }
        
            $repos = $reposJson | ConvertFrom-Json
            Write-Log -Message "Converted JSON output: $repos" -Level "DEBUG"
        
            $filteredRepos = $repos | Where-Object { $_.name -like "Enhanced*" }
            if ($filteredRepos.Count -eq 0) {
                Write-Log -Message "No repositories found that match 'Enhanced*'." -Level "WARNING"
            }
            Write-Log -Message "Filtered repositories count: $($filteredRepos.Count)" -Level "INFO"
            
            # Clone each repository using the full path to Git
            foreach ($repo in $filteredRepos) {
                $repoName = $repo.name
                $repoTargetPath = Join-Path -Path $targetDirectory -ChildPath $repoName
        
                # Check if the repository already exists in the target directory
                if (Test-Path $repoTargetPath) {
                    Write-Log -Message "Repository $repoName already exists in $repoTargetPath. Skipping clone." -Level "INFO"
                    continue
                }
        
                $repoCloneUrl = $repo.url
        
                # Define arguments for Git as an array
                $gitArguments = @("clone", $repoCloneUrl, $repoTargetPath)
        
                Write-Log -Message "Cloning repository $repoName to $repoTargetPath..." -Level "INFO"
                & $gitPath $gitArguments
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to clone repository $repoName. Git returned exit code $LASTEXITCODE."
                }
                Write-Log -Message "Successfully cloned repository $repoName." -Level "INFO"
            }
        
            Write-Log -Message "Cloning process completed." -Level "INFO"
        }
        catch {
            Write-Log -Message "Error during cloning process: $_" -Level "ERROR"
            throw $_
        }
        
        
        
        

    }

    end {
        Write-Log -Message "Clone-EnhancedRepos function execution completed." -Level "Notice"
    }
}