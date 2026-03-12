#!/bin/bash
# Setup script for MR feedback verification - handles codebase cloning/updating
# Usage: ./setup-verify.sh <PROJECT_NAME> <SOURCE_BRANCH> [BASE_DIR] [GIT_GROUP]

set -uo pipefail

PROJECT_NAME="$1"
SOURCE_BRANCH="$2"
BASE_DIR="${3:-.}"
GIT_GROUP="${4:-candu}"
CODEBASE_DIR="$(cd "$BASE_DIR/codebase/$PROJECT_NAME" 2>/dev/null && pwd)" || CODEBASE_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update codebase if it exists
if [ -n "$CODEBASE_DIR" ] && [ -d "$CODEBASE_DIR" ]; then
    log_info "Updating codebase at: $CODEBASE_DIR"

    cd "$CODEBASE_DIR"

    # Reset dirty working tree to avoid checkout conflicts
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        log_warn "Dirty working tree detected, resetting..."
        git reset --hard 2>/dev/null
        git clean -fd 2>/dev/null
    fi

    # Fetch all remote changes
    log_info "Fetching remote changes..."
    git fetch -p 2>/dev/null

    # Checkout source branch
    log_info "Checking out branch: $SOURCE_BRANCH"
    if git checkout "$SOURCE_BRANCH" 2>/dev/null; then
        log_info "Checked out $SOURCE_BRANCH"
    else
        log_error "Failed to checkout branch $SOURCE_BRANCH"
        log_info "Available branches:"
        git branch -a | head -20
        exit 1
    fi

    # Pull latest changes
    log_info "Pulling latest changes..."
    if git pull 2>/dev/null; then
        log_info "Codebase updated successfully"
    else
        log_warn "Git pull had issues, but continuing..."
    fi

    # Get current commit info
    CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    CURRENT_DATE=$(git log -1 --format=%ci 2>/dev/null || echo "unknown")
    log_info "Current commit: $CURRENT_COMMIT ($CURRENT_DATE)"
else
    log_warn "Codebase directory not found: $BASE_DIR/codebase/$PROJECT_NAME"
    log_info "Attempting to clone repository..."
    CLONE_URL="ssh://git@services.conexusnuclear.org:2224/$GIT_GROUP/$PROJECT_NAME.git"
    CLONE_TARGET="$BASE_DIR/codebase/$PROJECT_NAME"

    # Create codebase directory if needed
    mkdir -p "$BASE_DIR/codebase"

    if git clone "$CLONE_URL" "$CLONE_TARGET" 2>/dev/null; then
        log_info "Cloned repository successfully"
        CODEBASE_DIR="$(cd "$CLONE_TARGET" && pwd)"
        cd "$CODEBASE_DIR"
        log_info "Checking out branch: $SOURCE_BRANCH"
        git checkout "$SOURCE_BRANCH" 2>/dev/null
        CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        CURRENT_DATE=$(git log -1 --format=%ci 2>/dev/null || echo "unknown")
        log_info "Current commit: $CURRENT_COMMIT ($CURRENT_DATE)"
    else
        log_error "Failed to clone repository"
        log_warn "You may need to clone manually:"
        log_warn "  git clone $CLONE_URL \"codebase/$PROJECT_NAME\""
    fi
fi

# Output results for the agent
echo ""
echo "=== VERIFY SETUP RESULTS ==="
echo "CODEBASE_DIR=${CODEBASE_DIR:-<not found>}"
if [ -n "$CODEBASE_DIR" ]; then
    echo "CURRENT_COMMIT=$CURRENT_COMMIT"
fi
echo "==========================="
