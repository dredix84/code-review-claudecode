# Running an Ensemble Code Review

This document provides the exact instructions for Claude to execute an group code review.

## Quick Start

Tell Claude:
```
Run group review for [GITLAB_MR_URL]
```

Or:
```
Run group review for [PROJECT] MR ![ID]
```

## Detailed Execution Steps

### Phase 1: Setup

1. **Parse the MR URL** to extract:
   - Project name (from URL path)
   - MR ID (the number after `merge_requests/`)

2. **Fetch MR details** using:
   ```
   mcp__gitlab-mcp-code-review__fetch_merge_request(project_id, merge_request_iid)
   mcp__gitlab-mcp-code-review__fetch_merge_request_diff(project_id, merge_request_iid)
   ```

3. **Setup local codebase** (if needed):
   - Clone or update the repository in `./codebase/[PROJECT]/`
   - Checkout the source branch

4. **Create review folder**:
   ```
   mkdir -p reviews/[PROJECT]/[MR_ID]
   ```

### Phase 2: Parallel Agent Reviews

Launch 4 Task agents IN PARALLEL (same message, multiple tool calls):

**Agent 1 - Security:**
```
Task(
  subagent_type="general-purpose",
  description="Security code review",
  prompt="[Include security-agent.md prompt + MR diff + context]
          Write findings to: reviews/[PROJECT]/[MR_ID]/agent-security.md"
)
```

**Agent 2 - Logic:**
```
Task(
  subagent_type="general-purpose",
  description="Logic code review",
  prompt="[Include logic-agent.md prompt + MR diff + context]
          Write findings to: reviews/[PROJECT]/[MR_ID]/agent-logic.md"
)
```

**Agent 3 - Quality:**
```
Task(
  subagent_type="general-purpose",
  description="Quality code review",
  prompt="[Include quality-agent.md prompt + MR diff + context]
          Write findings to: reviews/[PROJECT]/[MR_ID]/agent-quality.md"
)
```

**Agent 4 - General:**
```
Task(
  subagent_type="general-purpose",
  description="General code review",
  prompt="[Include general-agent.md prompt + MR diff + context]
          Write findings to: reviews/[PROJECT]/[MR_ID]/agent-general.md"
)
```

### Phase 3: Synthesis

After all 4 agents complete, launch synthesis agent:

```
Task(
  subagent_type="general-purpose",
  description="Synthesize review findings",
  prompt="[Include synthesis-agent.md prompt]
          Read:
          - reviews/[PROJECT]/[MR_ID]/agent-security.md
          - reviews/[PROJECT]/[MR_ID]/agent-logic.md
          - reviews/[PROJECT]/[MR_ID]/agent-quality.md
          - reviews/[PROJECT]/[MR_ID]/agent-general.md

          Write final review to: reviews/[PROJECT]/[MR_ID]/review-notes-[N].md"
)
```

### Phase 4: Report

Present the final synthesized review to the user.

## Context to Provide Each Agent

Each agent needs:
1. Their specialized prompt (from `workflow/prompts/`)
2. The MR diff (full diff output)
3. MR metadata (title, description, author, target branch)
4. Project-specific instructions (if `more_mr_info.md` exists)
5. General reviewing guidelines (from `reviewing.md`)
6. Access to the local codebase for additional context

## Example Prompt Structure for Agents

```markdown
# Your Role
[Content from the agent's prompt file]

# MR Information
- **Title:** [MR Title]
- **Author:** [Author]
- **Source Branch:** [branch] -> **Target:** [target]
- **Description:** [MR description]

# Project-Specific Guidelines
[Content from more_mr_info.md if it exists]

# General Review Guidelines
[Content from reviewing.md]

# The Diff
[Full diff content]

# Your Task
Review the diff above from your specialized perspective.
Write your findings to: `[output file path]`
Use the output format specified in your role instructions.
Focus ONLY on the diff - don't review the entire codebase.
```

## File Naming

- Agent outputs: `agent-security.md`, `agent-logic.md`, `agent-quality.md`, `agent-general.md`
- Final review: `review-notes-[N].md` where N is the next increment
- Check existing files to determine the increment number
