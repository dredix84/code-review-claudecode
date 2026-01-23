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
4. The number before the `.md` is the increment indicating that this is the first, second, third, etc review that was done. The increment used in the file name is created after each code review and a check should be done in the destination folder for to determine what the next increment.
  - `review-notes-1.md` would be the firt review.
  - `review-notes-2.md` would be the second review attempt

## Example

```
/my-application/
    /123/
        - review-notes-1.md
        - review-notes-2.md
    /124/
        - review-notes-1.md
```

## Guidelines

- Each merge request should have its own dedicated folder
- Use consistent naming conventions for project folders
- Include relevant documentation and findings in each review folder