---
name: review-status
description: Track and report the status of code reviews assigned to you across all GitLab projects, verifying if changes address posted comments
argument-hint: "[optional: project-name filter]"
allowed-tools:
  - Bash
  - Write
  - Read
  - Glob
  - Grep
  - Edit
  - Agent
  - TodoWrite
  - mcp__gitlab-mcp-code-review__get_project_merge_requests
  - mcp__gitlab-mcp-code-review__fetch_merge_request
  - mcp__gitlab-mcp-code-review__fetch_merge_request_diff
  - mcp__gitlab-mcp-code-review__get_merge_request_comments
---

# Code Review Status Report

Generate a comprehensive status report of all merge requests where you are assigned as a reviewer.

$ARGUMENTS

## How to Use Arguments

If `$ARGUMENTS` is provided, treat it as a project name filter — only check that project.
If blank or omitted, check all projects in the codebase directory.

## Configuration

Configuration is read from `.env` file in the repository root:

```bash
# .env file format
REVIEWER_ID=2
REVIEWER_USERNAME=andre.dixon
```

Read these values at startup using the Read tool on `.env`.

- **GitLab Group:** `candu` (hardcoded)
- **Output Directory:** reviews-statuses/

---

## Workflow

### Progress Tracking Approach

This skill uses **high-level todos** for major milestones and **printed progress** for granular updates. This provides visibility without cluttering the todo list.

**Todos track:**
- Fetching MRs from GitLab
- Processing each MR (one todo per MR)
- Generating report

**Printed progress shows:**
- Current MR being processed (e.g., "Processing MR 3/15: candu/bms-helper!281")
- Comment counts and verification results
- Status updates as each MR completes

### Phase 1: Setup and Configuration

1. Initialize todos:
   ```
   TodoWrite: [
     {content: "Fetch merge requests from GitLab", status: "in_progress", activeForm: "Fetching merge requests from GitLab"},
     {content: "Process merge requests and determine status", status: "pending", activeForm: "Processing merge requests and determining status"},
     {content: "Generate review status report", status: "pending", activeForm: "Generating review status report"}
   ]
   ```

2. Read `.env` file to get `REVIEWER_ID` and `REVIEWER_USERNAME`
3. Print: `⚙️  Configuration loaded: Reviewer ID=[id], Username=[username]`
4. Ensure output directory exists: `mkdir -p reviews-statuses`
5. Check if `glab` CLI is available: `glab version`
6. Print: `🔧 Using [glab CLI / GitLab MCP] for fetching MRs`

1. Read `.env` file to get `REVIEWER_ID` and `REVIEWER_USERNAME`
2. Ensure output directory exists: `mkdir -p reviews-statuses`
3. Check if `glab` CLI is available: `glab version`

### Phase 2: Fetch Merge Requests (Primary: glab, Fallback: MCP)

**IMPORTANT:** Process ALL MRs returned, not just those with projects in `codebase/`. MRs from projects without a local codebase clone should still be included in the report (marked for manual review).

**Option A: Using glab CLI (preferred if available)**

```bash
# List all open MRs where you are a reviewer across the candu group
glab mr list --group=candu --reviewer=@me -F json

# If project filter argument provided:
glab mr list -R candu/[project] --reviewer=@me -F json
```

Parse the JSON response to extract:
- `iid`, `title`, `state`, `created_at`, `updated_at`
- `author` object with `id`, `username`, `name`
- `reviewers` array
- `source_branch`, `target_branch`
- `web_url`
- `references.full` for project identification (e.g., "candu/bms!375")
- `user_notes_count` (number of comments)

**Option B: Using GitLab MCP (fallback if glab unavailable)**

For each project in `codebase/` directory:

```
mcp__gitlab-mcp-code-review__get_project_merge_requests(
  project_id="candu/[project]",
  state="opened",
  limit=50
)
```

Filter results to only MRs where:
- `reviewers` array contains a user with `id` matching `REVIEWER_ID` from .env

**Reconciliation Step:** After fetching all MRs, verify the total count matches expectations. If using glab, the JSON array length is the definitive count. Ensure all MRs are processed before proceeding.

7. Mark first todo complete and update second:
   ```
   TodoWrite: [
     {content: "Fetch merge requests from GitLab", status: "completed", activeForm: "Fetching merge requests from GitLab"},
     {content: "Process merge requests and determine status", status: "in_progress", activeForm: "Processing merge requests and determining status"},
     {content: "Generate review status report", status: "pending", activeForm: "Generating review status report"}
   ]
   ```

8. Print: `✓ Found N merge request(s) assigned to you`

### Phase 3: Fetch MR Details and Comments

For **each** matching MR (including those from projects not in codebase/), fetch full details including notes using GitLab MCP:

For each MR, print: `📄 [N/M] Fetching details for [project]![iid] - [title]`

Then call:

For **each** matching MR (including those from projects not in codebase/), fetch full details including notes using GitLab MCP:

```
mcp__gitlab-mcp-code-review__fetch_merge_request(
  project_id="candu/[project]",
  merge_request_iid=[iid]
)
```

Extract from the response:
- MR metadata (title, author, state, dates, source_branch, target_branch)
- Notes/comments array with two filtering approaches:
  - **Reviewer comments (for status):** Filter where `system === false` AND `author.id` does NOT match the MR `author.id` — i.e., comments from any developer who is not the MR author
  - **Your comments (for verification tracking):** Filter where `system === false` AND `author.id` matches `REVIEWER_ID` — used to populate "Posted Comments Status" in the report and as input to the verification agent

### Phase 4: Determine Initial Status

For each MR, determine status using this logic:

```
FUNCTION determine_initial_status(mr, local_reviews, reviewer_comments, your_comments):
  // reviewer_comments = all non-system comments where author.id != mr.author.id
  // your_comments     = subset of reviewer_comments where author.id == REVIEWER_ID

  has_local_reviews     = local_reviews exist in reviews/[PROJECT]/[MR_ID]/
  has_reviewer_comments = reviewer_comments.length > 0
  has_your_comments     = your_comments.length > 0

  IF NOT has_reviewer_comments AND NOT has_local_reviews:
    RETURN "Not Reviewed"

  IF has_local_reviews AND NOT has_reviewer_comments:
    RETURN "Review Pending Post"

  IF has_reviewer_comments:
    last_comment_date = max(reviewer_comments.created_at)
    mr_updated_date   = mr.updated_at

    IF mr_updated_date > last_comment_date:
      RETURN "Needs Verification"
    ELSE:
      RETURN "Awaiting Author"
```

**Key rule:** `reviewer_comments` is any non-system comment from a developer who is NOT the MR author. This means comments from Eirian, Neha, Andre, or any other team member all count — as long as they didn't create the MR. This ensures an MR is not left as "Not Reviewed" when another developer has already left feedback on it.

**Empty State Handling:** If no MRs are found where you are assigned as reviewer, still generate a report with:
- Summary showing all counts as 0
- A note: "No open merge requests found where you are assigned as reviewer."
- List any projects that were checked

### Phase 5: Verify Changes (Sequential per Project)

**IMPORTANT:** Process projects SEQUENTIALLY to avoid git branch conflicts.

**CRITICAL: Branch Verification Requirement**
Before launching any verification agent, you MUST ensure you are on the correct source branch with the latest changes. Verifying against the wrong branch will produce INCORRECT RESULTS. Always:
1. Checkout the MR's source branch
2. Pull the latest changes
3. Verify current branch with `git branch --show-current`

For each project that has MRs with "Needs Verification" status:

Print: `🔍 Verifying changes for [N] MR(s) in [project]...`

1. **Check if project exists in codebase:**
   - If `codebase/[PROJECT]` does NOT exist:
     - If MR has reviewer comments → Mark as **"No Local Codebase"** (verification needed but can't be done)
     - If MR has NO reviewer comments → Should have already been marked as **"Not Reviewed"** in Phase 4
     - Note in report: "Clone codebase to enable verification"
     - Skip to next project
   - If it exists, proceed with verification

2. **Prepare Codebase:**
   ```bash
   cd codebase/[PROJECT]
   git fetch -p
   ```

3. **For Each MR in Project - CRITICAL STEP:**
   Print: `   ↳ Verifying [project]![iid] ([title]) - [N] comment(s) to check`
   ```bash
   # Checkout the MR's source branch
   git checkout [SOURCE_BRANCH]

   # Pull the latest changes from remote
   git pull

   # Verify you are on the correct branch before proceeding
   git branch --show-current
   ```

   **DO NOT proceed with verification if:**
   - The branch checkout failed
   - The pull failed
   - `git branch --show-current` does not match the expected source branch

4. **Launch Verification Agent:**
   Use the Agent tool with subagent_type="general-purpose" to:
   - Read all reviewer comments (all non-author comments, not just yours) provided in context
   - Parse each comment for:
     - **Issue Title:** Pattern like `#### N. [Title] - [Severity]`
     - **Location:** Pattern like `**Location:** Line X` or `Lines X-Y`
     - **Issue Description:** Text after `**Issue:**`
   - Read the current code at the specified locations
   - Determine if the issue has been addressed
   - Return a structured report

5. **Update Status Based on Verification:**
   - All issues addressed → **Changes Implemented** — Print: `      ✓ All [N] issue(s) addressed`
   - Some/none addressed → **Changes Not Implemented** — Print: `      ⚠ [N]/[M] issue(s) addressed`
   - Agent fails or errors → **Verification Failed** — Print: `      ✗ Verification failed: [error message]`

6. **Reset Branch After Each MR:**
   Return to the project's default branch (varies by project - check for `main`, `master`, or `develop`):
   ```bash
   git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout develop
   ```

### Phase 6: Generate Report

1. Update todos to mark processing complete and start report generation:
   ```
   TodoWrite: [
     {content: "Fetch merge requests from GitLab", status: "completed", activeForm: "Fetching merge requests from GitLab"},
     {content: "Process merge requests and determine status", status: "completed", activeForm: "Processing merge requests and determining status"},
     {content: "Generate review status report", status: "in_progress", activeForm: "Generating review status report"}
   ]
   ```

2. Print: `📝 Generating review status report...`

3. Create markdown report with current timestamp:

**Filename format:** `reviews-statuses/Reviews-[YYYY]-[MM]-[DD]-[HHMM].md`

Use this template:

```markdown
# Code Review Status Report

**Generated:** [YYYY-MM-DD] at [HH:MM]
**Reviewer:** Andre Dixon
**Projects Checked:** [comma-separated list]

---

## Summary

| Status | Count |
|--------|-------|
| Not Reviewed | [count] |
| Review Pending Post | [count] |
| Awaiting Author | [count] |
| Needs Verification | [count] |
| Changes Implemented | [count] |
| Changes Not Implemented | [count] |
| Verification Failed | [count] |
| No Local Codebase | [count] |
| **Total Open** | [total] |

---

## Pending Reviews

### [Project Name]

| MR | Title | Author | Created | Last Activity | Status |
|----|-------|--------|---------|---------------|--------|
| [![IID]](url) | [title] | [author] | [date] | [date] | [status] |

---

## Details: MRs Requiring Attention

### [Project]![IID] - [Title]

- **Status:** [status]
- **Author:** [author name]
- **MR Link:** [url]
- **Source Branch:** [branch]
- **Local Review:** [link to review-notes file if exists]

**Posted Comments Status:**

| Comment | Severity | Status |
|---------|----------|--------|
| [Issue title] (Line X) | [severity] | Addressed / Not Addressed |

**Action Required:** [summary of what needs to happen]

---

## Ready to Approve

| Project | MR | Title | All Issues Addressed |
|---------|----|-------|---------------------|
| [project] | [![IID]](url) | [title] | Yes |

---

*Report generated by /review-status skill*
```

---

## Comment Parsing Patterns

When parsing reviewer comments from MR notes, look for these patterns:

### Finding Header Pattern:
```
#### N. [Issue Title] - [Severity]
```
Example: `#### 1. Computed Property With Side Effects - High`

### Location Pattern:
```
**Location:** Line X
**Location:** Lines X-Y
```

### Issue Description Pattern:
```
**Issue:**
[description text]
```

### Recommendation Pattern:
```
**Recommendation:**
[recommendation text]
```

### Fallback Parsing

If the structured patterns above aren't found in a reviewer comment, treat the entire comment as a single verifiable item:
- Use the comment's first line (or first 50 chars) as the "title"
- Mark location as "General comment" (no specific line)
- The issue to verify is the full comment text

This ensures no reviewer comments are missed, even if they don't follow the standard format.

---

## Verification Agent Prompt

When launching the verification agent, use this prompt structure:

```
You are verifying if code changes have addressed reviewer comments.

## MR Information
- Project: [project]
- MR: [iid]
- Source Branch: [branch]
- Last Reviewer Comment: [date]

## Reviewer Comments to Verify:
[List of ALL non-author comments with author, title, location, and issue description]

## Your Task
1. Read the code at each location mentioned in the comments
2. Determine if the issue described has been addressed
3. Consider:
   - Has the problematic code been removed/modified?
   - Has the recommended fix been applied?
   - Is there a new implementation that solves the issue differently?

## Output Format
Return a JSON-like structure:
{
  "comments_verified": [
    {
      "title": "[issue title]",
      "location": "[line range]",
      "severity": "[severity]",
      "status": "Addressed" | "Not Addressed",
      "reason": "[brief explanation]"
    }
  ],
  "summary": {
    "total": N,
    "addressed": N,
    "not_addressed": N
  }
}
```

---

## Error Handling

- **glab not available:** Fall back to GitLab MCP for fetching MRs
- **glab authentication error:** Fall back to GitLab MCP, note in report
- **Project not in codebase:** Mark as "No Local Codebase" status, note in report that cloning is needed for verification
- **Git checkout fails:** Note error, skip that MR's verification
- **Agent verification fails:** Use "Verification Failed" status, note error
- **GitLab API errors:** Retry once, then note in report
- **Missing .env file:** Fall back to default values (REVIEWER_ID=2, REVIEWER_USERNAME=andre.dixon)

---

## Output

Save the final report to:
```
reviews-statuses/Reviews-[YYYY]-[MM]-[DD]-[HHMM].md
```

Example: `reviews-statuses/Reviews-2026-03-01-1430.md`

After saving, provide a brief summary to the user showing:
- Total MRs checked
- Breakdown by status
- MRs requiring immediate attention

4. Mark final todo complete:
   ```
   TodoWrite: [
     {content: "Fetch merge requests from GitLab", status: "completed", activeForm: "Fetching merge requests from GitLab"},
     {content: "Process merge requests and determine status", status: "completed", activeForm: "Processing merge requests and determining status"},
     {content: "Generate review status report", status: "completed", activeForm: "Generating review status report"}
   ]
   ```

5. Print: `✅ Review status report complete: [filename]`
