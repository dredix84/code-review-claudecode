---
name: suggest-review-name
description: Suggest a predictable chat session name based on MR details
argument-hint: <MR URL>
---

# Suggest Chat Session Name

Generate a predictable name for a Claude Code chat session based on the merge request at: $ARGUMENTS

## Workflow

1. **Parse & Validate URL** - Extract project name and MR IID from the URL. The URL must match the pattern `http(s)://services.conexusnuclear.org:8929/<group>/<project>/-/merge_requests/<IID>`. If the URL is missing, malformed, or doesn't match this pattern, ask the user for a valid MR URL before proceeding.

2. **Fetch MR Data** - Use GitLab MCP tools to get MR details (title, description, etc.)

3. **Generate Session Name** - Create a session name using this pattern:

```
[project] MR[mr-id] - [short description]
```

Where:
- `[project]` - The project name from the URL (e.g., `bms-helper`)
- `[mr-id]` - The merge request IID (e.g., `298`)
- `[short description]` - A brief description derived from the MR title with these rules:
  - Keep it concise (3-6 words)
  - Use title case
  - Remove filler words (a, an, the, for, to, etc.)
  - If the title has a pipe (`|`), use the more distinctive part

## Examples

| MR Title | Generated Session Name |
|----------|------------------------|
| "Requesting permission to edit an unsubmitted timesheet \| Late timesheet approval notification" | `bms-helper MR298 - Late Timesheet Approval Notification` |
| "Add user authentication with OAuth2" | `bms MR123 - User Authentication OAuth2` |
| "Fix bug in payroll calculation" | `bms MR456 - Fix Payroll Calculation Bug` |
| "Update dependencies and refactor API endpoints" | `bms-helper MR789 - Update Dependencies Refactor API` |

## Output Format

Present the suggested session name in this format:

```
[bms-helper MR298 - Late Timesheet Approval Notification]
```

Just the name in brackets - ready to copy and use as the chat session title.

## Important Notes

- Keep it readable and descriptive
- The name should fit in a typical session list view
- Prioritize the most distinctive/significant words from the MR title
- The session name should be immediately recognizable when reviewing later
