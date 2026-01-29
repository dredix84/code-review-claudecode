# Ensemble Code Review Workflow

This document describes the multi-agent ensemble approach to code reviews, designed to improve consistency and coverage.

## Overview

Instead of a single review pass, this workflow uses 3 specialized agents reviewing in parallel, followed by a synthesis step to combine findings.

## Agents

| Agent | Focus Area | File |
|-------|------------|------|
| Security Agent | Vulnerabilities, OWASP, injection, auth issues | `prompts/security-agent.md` |
| Logic Agent | Correctness, edge cases, error handling, business logic | `prompts/logic-agent.md` |
| Quality Agent | Code quality, maintainability, patterns, performance | `prompts/quality-agent.md` |
| General Agent | Holistic review, no specialization, catches cross-cutting issues | `prompts/general-agent.md` |

## Workflow Steps

### Step 1: Setup
1. Create/update local codebase clone
2. Fetch MR details and diff using GitLab MCP
3. Create review folder: `reviews/[PROJECT]/[MR_ID]/`

### Step 2: Parallel Reviews
Run 4 Task agents in parallel, each writing to their own file:
- `reviews/[PROJECT]/[MR_ID]/agent-security.md`
- `reviews/[PROJECT]/[MR_ID]/agent-logic.md`
- `reviews/[PROJECT]/[MR_ID]/agent-quality.md`
- `reviews/[PROJECT]/[MR_ID]/agent-general.md`

Each agent:
- Receives the MR diff and context
- Reviews from their perspective (specialized or holistic)
- Outputs findings in a structured format

### Step 3: Synthesis
A synthesis agent reads all 4 review files and:
- Identifies consensus findings (flagged by 2+ agents) - HIGH confidence
- Evaluates single-agent findings for validity
- Removes duplicates and overlapping comments
- Prioritizes by severity
- Produces final `review-notes-[N].md`

## Running an Ensemble Review

To run an ensemble review, use this command format:

```
Review MR [URL] using the ensemble workflow
```

Or manually:

```
1. Fetch MR: [PROJECT] MR ![ID]
2. Run ensemble review agents in parallel
3. Synthesize results into final review notes
```

## Output Format

Each agent outputs findings in this structure:

```markdown
## [Agent Name] Review

### Critical
- [Finding with file:line reference]

### Major
- [Finding with file:line reference]

### Minor
- [Finding with file:line reference]

### Notes
- [Observations that don't require action]
```

## Synthesis Output

The final review notes include:

```markdown
## Summary
[Brief overview of findings]

## Findings

### Critical (Consensus: X/4 agents)
[Issues that must be addressed]

### Major
[Important issues to address]

### Minor
[Nice-to-have improvements]

## Review Metadata
- Agents used: Security, Logic, Quality, General
- Consensus threshold: 2/4
- Date: [DATE]
```
