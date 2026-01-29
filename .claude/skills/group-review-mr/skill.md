---
name: group-review-mr
description: Run a multi-agent ensemble code review on a GitLab merge request (4 parallel agents + synthesis)
argument-hint: <MR URL>
allowed-tools:
  - Bash
  - Write
  - Glob
  - Read
  - Task
  - mcp__gitlab-mcp-code-review__fetch_merge_request
  - mcp__gitlab-mcp-code-review__fetch_merge_request_diff
---

# Group Review (Ensemble) - Merge Request

Review the GitLab merge request at: $ARGUMENTS

This uses a multi-agent ensemble approach with 4 specialized reviewers running in parallel, followed by a synthesis step.

## Phase 1: Setup

1. **Parse URL** - Extract project name and MR IID from the URL
2. **Create Directory** - Create `reviews/[PROJECT]/[MR_ID]/` if it doesn't exist
3. **Check Existing Reviews** - Find existing `review-notes-*.md` files and determine next increment
4. **Fetch MR Data** - Use GitLab MCP tools to get MR details and diff
5. **Setup Local Codebase** - Clone/update repo in `./codebase/[PROJECT]/` and checkout source branch

## Phase 2: Launch Parallel Agents

Launch 4 Task agents IN PARALLEL (single message, multiple tool calls) with these prompts:

### Agent 1 - Security
Read `workflow/prompts/security-agent.md` for the full prompt. Key focus areas:
- Injection vulnerabilities (SQL, command, LDAP, template)
- XSS (cross-site scripting)
- Authentication & authorization issues
- Data protection (sensitive data exposure, hardcoded secrets)
- Input validation
- Security misconfigurations
- CSRF & request forgery

Output to: `reviews/[PROJECT]/[MR_ID]/agent-security.md`

### Agent 2 - Logic
Read `workflow/prompts/logic-agent.md` for the full prompt. Key focus areas:
- Logic errors (conditionals, algorithms, race conditions)
- Edge cases (null handling, boundaries, empty collections)
- Error handling (missing try/catch, silent failures)
- Business logic correctness
- Data integrity
- Control flow issues
- API contract issues

Output to: `reviews/[PROJECT]/[MR_ID]/agent-logic.md`

### Agent 3 - Quality
Read `workflow/prompts/quality-agent.md` for the full prompt. Key focus areas:
- Code design (SOLID violations, coupling, abstraction)
- Maintainability (complexity, duplication, naming)
- Performance (N+1 queries, missing indexes, inefficient algorithms)
- Database concerns
- API design
- Testing concerns
- Framework best practices

Output to: `reviews/[PROJECT]/[MR_ID]/agent-quality.md`

### Agent 4 - General
Read `workflow/prompts/general-agent.md` for the full prompt.
- Holistic review without specialization
- Catches cross-cutting issues
- Typical senior developer perspective

Output to: `reviews/[PROJECT]/[MR_ID]/agent-general.md`

## Context to Provide Each Agent

Include in each agent's prompt:

```markdown
# Your Role
[Content from the agent's prompt file in workflow/prompts/]

# MR Information
- **Title:** [MR title]
- **Author:** [author name]
- **Source Branch:** [source] -> **Target:** [target]
- **Description:** [MR description]

# Project-Specific Guidelines
[Content from reviews/[PROJECT]/more_mr_info.md if it exists]

# General Review Guidelines
[Content from reviewing.md]

# The Diff
[Full diff content from GitLab MCP]

# Your Task
Review the diff above from your specialized perspective.
Write your findings to: `reviews/[PROJECT]/[MR_ID]/agent-[type].md`
Use the output format specified in your role instructions.
Focus ONLY on the diff - don't review the entire codebase.
```

## Phase 3: Synthesis

After all 4 agents complete, launch synthesis agent:

Read `workflow/prompts/synthesis-agent.md` for instructions. The synthesis agent should:
1. Read all 4 agent outputs
2. Identify consensus findings (2+ agents = high confidence)
3. Deduplicate overlapping issues
4. Validate single-agent findings
5. Prioritize by severity
6. Write final review to: `reviews/[PROJECT]/[MR_ID]/review-notes-[N].md`

## Phase 4: Report

Present the final synthesized review to the user, including:
- Summary of findings
- Issues by severity (with consensus indicators)
- Agent agreement table

## Output Format for Each Agent

```markdown
## [Agent Type] Review

### Critical
- [ID-001] **[Title]** - file:line
  - Description: [What the issue is]
  - Impact/Risk: [What could happen]
  - Recommendation: [How to fix]

### Major
- [ID-002] ...

### Minor
- [ID-003] ...

### Notes
- [Observations]
```

## Important Notes

- Run the 4 review agents IN PARALLEL (single message with multiple Task tool calls)
- Wait for all 4 to complete before running synthesis
- Focus on the DIFF. The entire file and the rest of the codebase is there to gain a better understand in relation to the diff
- Only flag issues outside the diff if Critical/Major severity
- Check for `more_mr_info.md` in the project folder for project-specific guidelines
- Follow CLAUDE.md and reviewing.md for general review practices
