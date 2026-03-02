# Code Reviews

This directory contains code review documentation conducted using ClaudeCode CLI.

## Skills

Two custom skills are available for streamlined code reviews:

| Skill | Description | Usage |
|-------|-------------|-------|
| `/review-mr` | Review a GitLab merge request and generate structured review notes | `/review-mr <MR_URL>` |
| `/review-status` | Track status of all MRs where you're assigned as reviewer, verify if changes address posted comments | `/review-status` or `/review-status <project-name>` |

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
REVIEWER_ID=2              # Your GitLab user ID
REVIEWER_USERNAME=andre.dixon
```

### Optional: glab CLI

Installing [glab](https://gitlab.com/gitlab-org/cli) (GitLab CLI) improves `/review-status` performance by fetching MRs across all projects in a single query:

```bash
# Windows (winget)
winget install glab.glab

# macOS
brew install glab

# Linux
# See https://gitlab.com/gitlab-org/cli/-/releases
```

After installation, authenticate: `glab auth login`

## Structure

Reviews are organized in the following directory structure:

```
/codebase/[PROJECT NAME]/     # Local clones of project repositories
/reviews/[PROJECT NAME]/[merge request id]/
```

### Codebase Folder

The `codebase` folder contains local clones of project repositories, allowing for full codebase access during reviews. This enables better context understanding and more comprehensive code reviews.

Project-specific instructions are stored in the `project-instructions` folder:

```
/project-instructions/[PROJECT NAME].md
```

## Usage

### Starting a Code Review

1. **Setup Codebase** (if not already done):
   - Check if `./codebase/[PROJECT NAME]` exists
   - If not, clone the repository:
     ```bash
     git clone ssh://git@services.conexusnuclear.org:2224/[GROUP]/[PROJECT].git codebase/[PROJECT NAME]
     ```
   - Navigate to the codebase and fetch the specific branch:
     ```bash
     cd codebase/[PROJECT NAME]
     git fetch -p
     git checkout [SOURCE_BRANCH]  # or specific commit SHA
     git pull
     cd ../..
     ```

2. **Create Review Folder**:
   - Create a folder for your project if it doesn't exist: `mkdir -p "reviews/[PROJECT NAME]/[MR_ID]"`
   - Store all code review artifacts and documentation within that folder
4. The number before the `.md` is the increment indicating that this is the first, second, third, etc review that was done. The increment used in the file name is created after each code review and a check should be done in the destination folder for to determine what the next increment.
  - `review-notes-1.md` would be the firt review.
  - `review-notes-2.md` would be the second review attempt

## Example

```
/reviews
    /my-application/
        /123/
            - review-notes-1.md
            - review-notes-2.md
        /124/
            - review-notes-1.md
```

## Guidelines

- Each merge request should have its own dedicated folder
- Use consistent naming conventions for project folders
- Include relevant documentation and findings in each review folder