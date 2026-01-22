# Code Reviews

This directory contains code review documentation conducted using ClaudeCode CLI.

## Structure

Reviews are organized in the following directory structure:

```
/[PROJECT NAME]/[merge request id]/
```

Additional instructions specific to the project should be stored at the root of the project folder:

```
/[PROJECT NAME]/more_mr_info.md
```

## Usage

1. Create a folder for your project if it doesn't exist
2. Create a subfolder using the merge request ID
3. Store all code review artifacts and documentation within that folder

## Example

```
/my-application/
    /123/
        - review-notes.md
        - findings.md
    /124/
        - review-notes.md
```

## Guidelines

- Each merge request should have its own dedicated folder
- Use consistent naming conventions for project folders
- Include relevant documentation and findings in each review folder