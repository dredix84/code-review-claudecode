# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory contains code review documentation conducted using ClaudeCode CLI. This is NOT a software development project - it's a structured repository for storing code review artifacts and findings.

## Important
- Do not post comments to the any merge request unless told to do so.
- Use the MCP to get the diff and do not diff directly from the filesystem.
- Your code review should concentrate mainly on the diff and not an overall review of the file you an looking at. Reduce noise in the reviews. For ouce outside the diff, only when something is considered critical or a breaking change should you mention it in your notes. Reduce you noise and contentrate mostly on the diff.
- The project name is based on the git repo, example:
  - `http://services.conexusnuclear.org:8929/candu/bms-helper/-/merge_requests/281` would be `bms-helper`
  - `http://services.conexusnuclear.org:8929/candu/bms/-/merge_requests/281` would be `bms`

## Directory Structure

Reviews are organized hierarchically:

```
/codebase              # Local clones of project repositories for full codebase access
   /[PROJECT NAME]/    # Git repository cloned from GitLab

/reviews
   /[PROJECT NAME]/
      /[MERGE REQUEST ID]/
         - review-notes-[increment].md
         - review-notes-2.md
         - review-notes-3.md
         - other review artifacts
      /more_mr_info.md  (optional project-specific instructions)
```
When `review-notes-2.md` would be the second review and `review-notes-3.md` would be the third review, and so on.

## Code Review Workflow

When conducting a code review in this directory:

1. **Create Project Structure**: If the project folder doesn't exist, create it: `mkdir -p "reviews/[PROJECT NAME]/[MR_ID]"`

2. **Setup/Update Local Codebase**: Before reviewing, ensure you have access to the full codebase:
   - Check if the project exists in `./codebase/[PROJECT NAME]`
   - If the folder doesn't exist, clone the repository:
     ```bash
     git clone 
     git clone ssh://git@services.conexusnuclear.org:2224/[GROUP]/[PROJECT].git codebase/[PROJECT NAME]
     ```
   - Navigate to the codebase folder: `cd codebase/[PROJECT NAME]`
   - Fetch the latest changes: `git fetch -p`
   - Determine the source branch from the merge request
   - Checkout the source branch: `git checkout [SOURCE_BRANCH]` or `git checkout [COMMIT_SHA]`
   - Also ensure you are on the right branch before going further.
   - Pull latest changes: `git pull`
   - Return to the reviews directory when ready: `cd ../..`

3. **Fetch Merge Request**: Use the GitLab MCP tools to fetch the merge request:
   - `mcp__gitlab-mcp-code-review__fetch_merge_request` - Get MR details
   - `mcp__gitlab-mcp-code-review__fetch_merge_request_diff` - Get code diffs
   - `mcp__gitlab-mcp-code-review__get_project_merge_requests` - List MRs

3. **Review Process**: Analyze the code changes focusing on:
   - Code quality and maintainability
   - Security vulnerabilities (OWASP top 10, injection attacks, XSS, etc.)
   - Logic errors and edge cases
   - Performance implications
   - Test coverage
   - Documentation completeness

4. **Document Findings**: Create review artifacts in the MR folder:
   - `review-notes-[increment].md` - Detailed review notes and recommendations
   - Additional files as needed for specific findings

5. **Add Comments**: Use GitLab MCP tools to add comments directly to the MR:
   - `mcp__gitlab-mcp-code-review__add_merge_request_comment`
   - `mcp__gitlab-mcp-code-review__approve_merge_request` or `unapprove_merge_request`

For additional general instruction for all code reviews, please see `reviewing.md`.

## Project-Specific Instructions

Check for `more_mr_info.md` in the project root directory for additional context, coding standards, or review focus areas specific to that project.

## Posting Comments
- No fluff in the title, just the short description. Nothing  like "Code Review Comment: ..." or  "2. ..."

## Ensemble Review Workflow (Multi-Agent)

For more thorough reviews, use the ensemble workflow which runs 4 agents in parallel:

- **Security Agent** - Focuses on vulnerabilities, OWASP, injection attacks
- **Logic Agent** - Focuses on correctness, edge cases, error handling
- **Quality Agent** - Focuses on code quality, performance, maintainability
- **General Agent** - Holistic review, no specialization, catches cross-cutting issues

**To run an ensemble review:**
```
Run ensemble review for [MR_URL]
```

The workflow:
1. Runs 4 agents in parallel, each writing to `agent-*.md` files
2. A synthesis agent combines findings into the final `review-notes-[N].md`
3. Consensus findings (2+ agents) are higher confidence

See `workflow/ensemble-review.md` for full documentation.
See `workflow/run-ensemble.md` for execution instructions.

## GitLab Integration

This workspace has GitLab MCP servers configured for both code review and issue management. Use these tools to fetch MRs, view diffs, compare versions, and interact with GitLab directly from the review process.



