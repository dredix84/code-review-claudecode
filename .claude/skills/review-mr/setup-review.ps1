# Setup script for code review - handles directory creation and codebase updates
# Usage: .\setup-review.ps1 -ProjectName <PROJECT> -MrId <MR_ID> -SourceBranch <BRANCH> [-ReviewsDir <PATH>] [-GitGroup <GROUP>]

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,

    [Parameter(Mandatory=$true)]
    [string]$MrId,

    [Parameter(Mandatory=$true)]
    [string]$SourceBranch,

    [Parameter(Mandatory=$false)]
    [string]$ReviewsDir = ".",

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

# Create review directory
$ReviewDir = Join-Path $ReviewsDir "reviews\$ProjectName\$MrId"
New-Item -ItemType Directory -Force -Path $ReviewDir | Out-Null
Log-Info "Created review directory: $ReviewDir"

# Check for existing reviews
$ExistingReviews = Get-ChildItem -Path $ReviewDir -Filter "review-notes-*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'review-notes-(\d+)\.md' } |
    Sort-Object { if ($_.Name -match 'review-notes-(\d+)\.md') { [int]$matches[1] } else { 0 } } -Descending

if ($ExistingReviews) {
    $null = $ExistingReviews[0].Name -match 'review-notes-(\d+)\.md'
    $LastNum = [int]$matches[1]
    $NextNum = $LastNum + 1
    Log-Info "Found existing reviews (last: $LastNum), next will be: $NextNum"
} else {
    $NextNum = 1
    Log-Info "No existing reviews found, this will be review #1"
}

# Update codebase if it exists
$CodebaseDir = Join-Path $ReviewsDir "..\codebase\$ProjectName"
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
    $CloneTarget = Join-Path $ReviewsDir "..\codebase\$ProjectName"
    $CloneTarget = [System.IO.Path]::GetFullPath($CloneTarget)
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
Write-Host "=== REVIEW SETUP RESULTS ===" -ForegroundColor Cyan
Write-Host "REVIEW_DIR=$ReviewDir"
Write-Host "NEXT_REVIEW_NUM=$NextNum"
Write-Host "CODEBASE_DIR=$CodebaseDir"
if ($CurrentCommit -ne "<not found>") {
    Write-Host "CURRENT_COMMIT=$CurrentCommit"
}
Write-Host "============================="
