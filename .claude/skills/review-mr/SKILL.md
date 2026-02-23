---
name: review-mr
description: Review a GitLab merge request and generate structured review notes
argument-hint: <MR URL>
allowed-tools:
  - Bash
  - Write
  - Edit
  - Glob
  - Read
  - Grep
  - mcp__gitlab-mcp-code-review__fetch_merge_request
  - mcp__gitlab-mcp-code-review__fetch_merge_request_diff
  - Task
---

# Review Merge Request

Review the GitLab merge request at: $ARGUMENTS

## Workflow

1. **Parse & Validate URL** - Extract project name and MR IID from the URL. The URL must match the pattern `http(s)://services.conexusnuclear.org:8929/<group>/<project>/-/merge_requests/<IID>`. If the URL is missing, malformed, or doesn't match this pattern, ask the user for a valid MR URL before proceeding.
2. **Fetch MR Data** - Use GitLab MCP tools to get MR details and diff (needed for source branch)
3. **Run Setup Script** - Execute the setup script to automate filesystem and git operations. Detect OS and use appropriate script:

   **For Windows (PowerShell):**
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .claude/skills/review-mr/setup-review.ps1 -ProjectName <PROJECT> -MrId <MR_ID> -SourceBranch <BRANCH>
   ```

   **For Linux/macOS (Bash):**
   ```bash
   bash .claude/skills/review-mr/setup-review.sh <PROJECT_NAME> <MR_ID> <SOURCE_BRANCH>
   ```

   The `-GitGroup`/`GIT_GROUP` parameter defaults to `candu`. Extract the group from the MR URL (e.g., `/candu/` → `candu`) and pass it explicitly.

   This script handles:
   - Creating review directory
   - Finding existing reviews and determining next increment
   - Cloning the repository if the codebase directory doesn't exist
   - Resetting dirty working tree before checkout (codebase is read-only for reviews)
   - Fetching latest code from git
   - Checking out the source branch
   - Pulling latest changes
   - Outputting `NEXT_REVIEW_NUM` and `CURRENT_COMMIT` for use in review

4. **Read Guidelines** - Read `reviewing.md` and `project-instructions/[PROJECT].md` (if exists) for review guidance. Use retry logic: if Read fails, wait 1 second and retry once.
5. **Analyze Diff** - Focus review on the diff, not the entire file. Use the MCP diff, not filesystem diff.
6. **Analyze Supporting Files** - If needed, use the codebase to get better overall understanding to provide better feedbacks
7. **Write Review Notes** - Create `review-notes-[n].md` with findings (use NEXT_REVIEW_NUM from script output)

## Review Template

Use this structure for review notes. Sections marked as optional can be omitted if not applicable to the change being reviewed. Adapt the depth and focus based on the type of project (script, frontend, backend, config, etc.):

```markdown
# Code Review Notes - MR !MR_IID

- **Project:** [project name]
- **MR Title:** [title]
- **Author:** [author name]
- **Reviewer:** Andre Dixon
- **Date:** [YYYY-MM-DD]
- **Review #:** [increment]
- **MR Link:** [full MR URL]
- **Source Branch:** [source] → **Target Branch:** [target]
- **Date Reviewed:** [current date and time]
- **Review Model:** [model used to conduct review]
---

## Summary

[2-3 sentence description of what this MR accomplishes]

---

## Files Changed

| File | Change Type | Lines |Finds|
|------|-------------|-------|-----|
| `path/to/file.ext` | Added/Modified/Deleted | +X/-Y |[count|skipped]

---

## Findings

### [filename]

#### 1. [Short Title] - [Severity]

**Location:** Line X (or Lines X-Y)

**Issue:**
[Description of the problem]

**Code:**
```[language]
// problematic code snippet
```

**Recommendation:**
[How to fix it, with code example if helpful]

---

[Repeat for each finding, ordered by severity: Critical > High > Medium > Low > Trivial > Suggestion]

---

## Security Concerns

[Only include this section if security-relevant issues were identified. Omit entirely if not applicable.]

---

## Questions for Author

[Only include if there are clarifying questions. Omit if none.]

---

## Overall Assessment

[Summarize the key issues found, if any. Include an issues count table only if there are multiple findings.]

**Recommendation:** [Approve / Approve with Comments / Request Changes / Needs Discussion]

[Brief justification for the recommendation]
```

## Severity Definitions

- **Critical**: Security vulnerability, data loss risk, or system-breaking bug. Must fix before merge.
- **High**: Significant bug, performance issue, or architectural problem. Should fix before merge.
- **Medium**: Code quality issue, potential bug, or maintainability concern. Should address.
- **Low**: Minor issue, style inconsistency, or small improvement. Nice to fix.
- **Trivial**: Nitpick, formatting, typo. Optional fix.
- **Suggestion**: Improvement idea for future consideration. Not blocking.

## Review Focus Areas

Adapt focus based on what's relevant to the change:

- **Correctness** - Logic errors, edge cases, unexpected behavior
- **Security** - Only when handling user input, auth, data access, or external systems
- **Performance** - Only when the change could impact response times or resource usage
- **Error Handling** - Appropriate to the language and context
- **Maintainability** - Readability, duplication, complexity

Not all focus areas apply to every review. A CSS fix doesn't need security analysis. A config change doesn't need performance review.

## Important Notes

- Focus on the DIFF, not the entire file
- Only flag issues outside the diff if they are Critical or High severity
- Reduce noise - don't nitpick on style if it matches existing codebase patterns
- Be constructive - provide solutions, not just problems
- Omit sections that don't apply (e.g., no Security Concerns section for a README change)
- Check for `project-instructions/[PROJECT].md` for project-specific guidelines
- You can add more to the code review
- If there are no issues found with a file, not need to add an issues section for it and mark it as skipped in the table
- Please ensure you get guidance from CLAUDE.md and reviewing.md
- **Retry Logic**: When reading guideline files (reviewing.md, project-instructions/*.md), if the Read tool fails with "Sibling tool call errored" or similar transient errors, retry the read operation once after a brief pause. Read files sequentially, not in parallel, to avoid this issue.
- **Large Diffs**: For MRs with more than 30 changed files, prioritize non-generated files (e.g., skip vendor, compiled, or auto-generated files). Note which files were skipped and why in the Files Changed table. For large MRs, consider using the Task tool to delegate analysis of independent file groups to sub-agents in parallel.