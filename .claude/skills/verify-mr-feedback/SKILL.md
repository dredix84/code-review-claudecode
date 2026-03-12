---
name: verify-mr-feedback
description: Verify if feedback comments posted to a GitLab merge request have been implemented in the code
argument-hint: <MR URL>
allowed-tools:
  - Bash
  - Write
  - Read
  - Glob
  - Grep
  - Edit
  - mcp__gitlab-mcp-code-review__fetch_merge_request
  - mcp__gitlab-mcp-code-review__fetch_merge_request_diff
  - mcp__gitlab-mcp-code-review__get_merge_request_comments
---

# Verify MR Feedback Implementation

Verify if the changes requested in comments posted to the GitLab merge request have been implemented.

$ARGUMENTS

## Workflow

1. **Parse & Validate URL** - Extract project name/group and MR IID from the URL.
   - Expected pattern: `http(s)://[gitlab-host]/[group]/[project]/-/merge_requests/[IID]`
   - If URL is missing or malformed, ask for a valid MR URL

2. **Fetch MR Data** - Call these in parallel:
   - `mcp__gitlab-mcp-code-review__fetch_merge_request` - Get MR details (title, author, branches, state)
   - `mcp__gitlab-mcp-code-review__get_merge_request_comments` - Get all comments/notes
   - `mcp__gitlab-mcp-code-review__fetch_merge_request_diff` - Get current code diff

3. **Run Setup Script** - Execute the setup script to ensure codebase is available with the MR's source branch:

   **For Windows (PowerShell):**
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .claude/skills/verify-mr-feedback/setup-verify.ps1 -ProjectName <PROJECT> -SourceBranch <BRANCH>
   ```

   **For Linux/macOS (Bash):**
   ```bash
   bash .claude/skills/verify-mr-feedback/setup-verify.sh <PROJECT_NAME> <SOURCE_BRANCH>
   ```

   The script handles:
   - Checking if the codebase directory exists
   - Cloning the repository if needed
   - Resetting dirty working tree to avoid checkout conflicts
   - Fetching latest changes from remote
   - Checking out the source branch
   - Pulling latest changes
   - Outputting `CODEBASE_DIR` and `CURRENT_COMMIT` for verification

4. **Filter Comments** - From all comments, filter to extract:
   - Non-system comments (`system === false`)
   - Comments from reviewers (not the MR author)
   - Focus on resolvable discussion threads with actionable feedback
   - Ignore system messages like "assigned to", "merged", etc.

5. **Parse Feedback Items** - For each reviewer comment, extract structured information:
   - **Title/Topic** - The issue being raised
   - **Severity** - If specified (Critical, High, Medium, Low)
   - **File & Location** - File path and line numbers
   - **Issue Description** - What the problem is
   - **Recommendation** - What was suggested to fix it

6. **Verify Implementation** - Compare each feedback item against both the diff AND the full codebase:
   - Check the diff for changes to the relevant code
   - Read the full file from codebase for context (some fixes may span multiple sections)
   - Check if the problematic code has been modified
   - Check if the recommended fix was applied
   - Check if an alternative solution addresses the issue
   - Note if the comment thread is marked as resolved

7. **Generate Report** - Output a structured verification report

## Output Format

### Summary Table

```markdown
## Review Comment Status

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | [Issue title] | [severity] | ✅ **Fixed** / ⚠️ **Partially Fixed** / ❌ **Not Fixed** / 🔍 **Needs Manual Check** |
```

### Verification Details

For each comment, provide:

```markdown
### [N]. [Issue Title]

- **Severity:** [severity]
- **File:** `path/to/file.ext`
- **Location:** Line X (or Lines X-Y)
- **GitLab Resolved:** Yes / No
- **Status:** ✅ Fixed / ⚠️ Partially Fixed / ❌ Not Fixed / 🔍 Needs Manual Check

**Original Issue:**
[Brief description of the problem]

**Recommendation Given:**
[What was suggested]

**Implementation Status:**
[Analysis of whether/how it was addressed. Reference specific code from the codebase (file:line), not just the diff. Include method/function names where helpful.]

---
```

### Summary Verdict

```markdown
## Summary

| Status | Count |
|--------|-------|
| ✅ Fixed | N |
| ⚠️ Partially Fixed | N |
| ❌ Not Fixed | N |
| 🔍 Needs Manual Check | N |

**Total Comments:** N
**All Addressed:** N (N%)

**Result:** All requested changes have been implemented. ✅ / N of N comments still require attention. ⚠️
```

[If all addressed] ✅ Ready for merge
[If issues remain] ⚠️ The following items still need attention: [list]
```

## Status Definitions

| Status | Description |
|--------|-------------|
| ✅ **Fixed** | The feedback was fully addressed |
| ⚠️ **Partially Fixed** | Some aspects addressed, others may remain |
| ❌ **Not Fixed** | No changes detected for this feedback item |
| 🔍 **Needs Manual Check** | Unable to automatically verify (requires human judgment) |
| ➖ **N/A** | Comment was not actionable (question, discussion, etc.) |

## Comment Parsing Patterns

Look for these common patterns in reviewer comments:

### Finding Header Pattern:
```
**[Title]** - [Severity]
#### N. [Title] - [Severity]
```

### Location Pattern:
```
**File:** `path/to/file.ext` (Lines X-Y)
**Location:** Line X
```

### Issue/Recommendation Pattern:
```
**Issue:**
[description]

**Recommendation:**
[suggestion]
```

### Fallback Parsing
If structured patterns aren't found, treat the comment body as the issue description and mark location as "General feedback" for manual verification.

## Handling Resolved Threads

- If a comment thread is marked `resolved: true`, note this in the report
- Resolved status from GitLab indicates the author believes the issue is addressed
- Still verify the actual implementation when possible
- A resolved thread without code changes may indicate the issue was clarified rather than fixed

## Error Handling

- **MR not found:** Report error and exit
- **No reviewer comments:** Report "No actionable feedback comments found on this MR"
- **Setup script fails:**
  - If clone fails, note that manual clone may be required
  - If checkout fails, list available branches and exit
  - Continue with diff-only verification if codebase unavailable
- **Diff too large:** Note which files couldn't be fully analyzed
- **Parse failures:** Include raw comment text for manual review

## Example Usage

```
/verify-mr-feedback https://gitlab.example.com/group/project/-/merge_requests/123
```

## Notes

- Focus on actionable feedback (bugs, improvements, security issues)
- Ignore stylistic debates that don't require code changes
- Be generous in interpretation - if the spirit of the feedback was addressed, mark as fixed
- When uncertain, mark as "Needs Manual Check" rather than guessing
- Always verify against the full codebase, not just the diff - some fixes may span multiple locations or require context beyond changed lines
- Reference specific code locations (file:line) from the codebase when explaining implementation status
