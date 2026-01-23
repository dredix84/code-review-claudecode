# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory contains code review documentation conducted using ClaudeCode CLI. This is NOT a software development project - it's a structured repository for storing code review artifacts and findings.

## Important
- Do not post comments to the any merge request unless told to do so.
- The project name is based on the git repo, example:
  - `http://services.conexusnuclear.org:8929/candu/bms-helper/-/merge_requests/281` would be `bms-helper`
  - `http://services.conexusnuclear.org:8929/candu/bms/-/merge_requests/281` would be `bms`

## Directory Structure

Reviews are organized hierarchically:

```
/[PROJECT NAME]/
    /[MERGE REQUEST ID]/
        - review-notes-[increment].md
        - other review artifacts
    /more_mr_info.md  (optional project-specific instructions)
```

## Code Review Workflow

When conducting a code review in this directory:

1. **Create Project Structure**: If the project folder doesn't exist, create it: `mkdir -p "[PROJECT NAME]/[MR_ID]"`

2. **Fetch Merge Request**: Use the GitLab MCP tools to fetch the merge request:
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

## GitLab Integration

This workspace has GitLab MCP servers configured for both code review and issue management. Use these tools to fetch MRs, view diffs, compare versions, and interact with GitLab directly from the review process.



