# Setup script for MR feedback verification - handles codebase cloning/updating
# Usage: .\setup-verify.ps1 -ProjectName <PROJECT> -SourceBranch <BRANCH> [-CodebaseDir <PATH>] [-GitGroup <GROUP>]

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,

    [Parameter(Mandatory=$true)]
    [string]$SourceBranch,

    [Parameter(Mandatory=$false)]
    [string]$BaseDir = ".",

    [Parameter(Mandatory=$false)]
    [string]$GitGroup = "candu"
)

$ErrorActionPreference = "Continue"

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Log-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check for codebase
$CodebaseDir = Join-Path $BaseDir "codebase\$ProjectName"
$CodebaseDir = [System.IO.Path]::GetFullPath($CodebaseDir)

if (Test-Path $CodebaseDir) {
    Log-Info "Updating codebase at: $CodebaseDir"

    Push-Location $CodebaseDir

    # Reset dirty working tree to avoid checkout conflicts
    $Status = git status --porcelain 2>&1
    if ($Status) {
        Log-Warn "Dirty working tree detected, resetting..."
        git reset --hard 2>&1 | Out-Null
        git clean -fd 2>&1 | Out-Null
    }

    # Fetch all remote changes
    Log-Info "Fetching remote changes..."
    git fetch -p 2>&1 | Out-Null

    # Checkout source branch
    Log-Info "Checking out branch: $SourceBranch"
    git checkout $SourceBranch 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Error "Failed to checkout branch $SourceBranch"
        Log-Info "Available branches:"
        git branch -a | Select-Object -First 20
        Pop-Location
        exit 1
    }
    Log-Info "Checked out $SourceBranch"

    # Pull latest changes
    Log-Info "Pulling latest changes..."
    git pull 2>&1 | Out-Null
    Log-Info "Codebase updated successfully"

    # Get current commit info
    $CurrentCommit = git rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        $CommitDate = git log -1 --format=%ci 2>$null
        Log-Info "Current commit: $CurrentCommit ($CommitDate)"
    } else {
        $CurrentCommit = "unknown"
    }

    Pop-Location
} else {
    Log-Warn "Codebase directory not found: $CodebaseDir"
    Log-Info "Attempting to clone repository..."
    $CloneUrl = "ssh://git@services.conexusnuclear.org:2224/$GitGroup/$ProjectName.git"
    $CloneTarget = Join-Path $BaseDir "codebase\$ProjectName"
    $CloneTarget = [System.IO.Path]::GetFullPath($CloneTarget)

    # Create codebase directory if needed
    $CodebaseParent = Split-Path $CloneTarget -Parent
    if (-not (Test-Path $CodebaseParent)) {
        New-Item -ItemType Directory -Force -Path $CodebaseParent | Out-Null
    }

    $CloneResult = git clone $CloneUrl $CloneTarget 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Info "Cloned repository successfully to $CloneTarget"
        $CodebaseDir = $CloneTarget
        Push-Location $CodebaseDir
        Log-Info "Checking out branch: $SourceBranch"
        git checkout $SourceBranch 2>&1 | Out-Null
        $CurrentCommit = git rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            $CommitDate = git log -1 --format=%ci 2>$null
            Log-Info "Current commit: $CurrentCommit ($CommitDate)"
        } else {
            $CurrentCommit = "unknown"
        }
        Pop-Location
    } else {
        Log-Error "Failed to clone repository: $CloneResult"
        Log-Warn "You may need to clone manually:"
        Log-Warn "  git clone $CloneUrl codebase\$ProjectName"
        $CurrentCommit = "<not found>"
    }
}

# Output results for the agent
Write-Host ""
Write-Host "=== VERIFY SETUP RESULTS ===" -ForegroundColor Cyan
Write-Host "CODEBASE_DIR=$CodebaseDir"
if ($CurrentCommit -ne "<not found>" -and $CurrentCommit -ne "unknown") {
    Write-Host "CURRENT_COMMIT=$CurrentCommit"
}
Write-Host "============================="
