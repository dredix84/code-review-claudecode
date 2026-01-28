# Code Reviews

This directory contains code review documentation conducted using ClaudeCode CLI.

## Structure

Reviews are organized in the following directory structure:

```
/codebase/[PROJECT NAME]/     # Local clones of project repositories
/reviews/[PROJECT NAME]/[merge request id]/
```

### Codebase Folder

The `codebase` folder contains local clones of project repositories, allowing for full codebase access during reviews. This enables better context understanding and more comprehensive code reviews.

Additional instructions specific to the project should be stored at the root of the project folder:

```
/reviews/[PROJECT NAME]/more_mr_info.md
```

## Usage

### Starting a Code Review

1. **Setup Codebase** (if not already done):
   - Check if `./codebase/[PROJECT NAME]` exists
   - If not, clone the repository:
     ```bash
     git clone ssh://git@services.conexusnuclear.org:2224/[GROUP]/[PROJECT].git codebase/[PROJECT NAME]
     ```
   - Navigate to the codebase and fetch the specific branch:
     ```bash
     cd codebase/[PROJECT NAME]
     git fetch -p
     git checkout [SOURCE_BRANCH]  # or specific commit SHA
     git pull
     cd ../..
     ```

2. **Create Review Folder**:
   - Create a folder for your project if it doesn't exist: `mkdir -p "reviews/[PROJECT NAME]/[MR_ID]"`
   - Store all code review artifacts and documentation within that folder
4. The number before the `.md` is the increment indicating that this is the first, second, third, etc review that was done. The increment used in the file name is created after each code review and a check should be done in the destination folder for to determine what the next increment.
  - `review-notes-1.md` would be the firt review.
  - `review-notes-2.md` would be the second review attempt

## Example

```
/reviews
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