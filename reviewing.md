# Reviewing Code

1. When reviewing code and asked to post a comment to a merge/pull request, if lines affected/associated are available, please create the comment with the line position when calling the `add_merge_request_comment` function.
1. **Important!** Do not post comments unless instructed to do so.
1. WHen reviewing, no need for highlighting good practices as I am looking for issues which need addressing.
1. Do not nitpick at minor details.
1. No silent errors.

### Laravel Review Checklist
- Follows PSR-2/PSR-4 standards
- No SQL injection vulnerabilities (use Eloquent or parameterized queries)
- Mass assignment protected (use fillable/guarded properly)
- XSS prevention (use {{ }} for output, avoid {!! !!})
- CSRF tokens included on all forms
- File uploads validated and secured
- N+1 queries eliminated with eager loading
- Long-running tasks moved to queues/jobs
- Rate limiting applied to API routes
- Input validation using Form Requests
- Business logic in service classes, not controllers
- Tests covering critical functionality
- No sensitive data in code or committed files
- Commands should follow the name
- Commands should follow the namespace for the signature.
  - A command to deactivate users: `users:deactive`
  - Import new companies: `companies:import`
- When migrations are created, ensure the proper indexes are also applied. There is generally no need for an index if the field is a foreign key.
- **False Positive Prevention:** Before flagging a "missing import" for a class reference, verify whether the referenced class exists in the same namespace. In PHP, classes in the same namespace (e.g., `App\Models`) can reference each other without explicit imports. Always check the codebase for the class location before reporting an issue.