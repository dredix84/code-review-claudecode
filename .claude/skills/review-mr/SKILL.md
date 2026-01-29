---
name: review-mr
description: Review a GitLab merge request and generate structured review notes
argument-hint: <MR URL>
allowed-tools:
  - Bash
  - Write
  - Glob
  - Read
  - mcp__gitlab-mcp-code-review__fetch_merge_request
  - mcp__gitlab-mcp-code-review__fetch_merge_request_diff
---

# Review Merge Request

Review the GitLab merge request at: $ARGUMENTS

## Workflow

1. **Parse URL** - Extract project name and MR IID from the URL
2. **Create Directory** - Create `reviews/[PROJECT]/[MR_ID]/` if it doesn't exist
3. **Check Existing Reviews** - Find existing `review-notes-*.md` files and determine next increment
4. **Fetch MR Data** - Use GitLab MCP tools to get MR details and diff
5. **Analyze Diff** - Focus review on the diff, not the entire file.
6. **Analyze Supporting Files** - If needed, use the codebase to get better overall understanding to provide better feedbacks
**Write Review Notes** - Create `review-notes-[n].md` with findings

## Review Template

Use this structure for review notes. Sections marked as optional can be omitted if not applicable to the change being reviewed. Adapt the depth and focus based on the type of project (script, frontend, backend, config, etc.):

```markdown
# Code Review Notes - MR ![MR_IID]

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