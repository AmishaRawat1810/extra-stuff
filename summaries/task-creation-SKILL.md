# task-creation/SKILL.md

This skill converts an agreed plan into a concrete task breakdown.

It reads `docs/<story_number>/plan.md`, then creates a task list with:

- task title and description
- acceptance criteria
- likely affected files
- test requirements
- dependencies
- estimated complexity

The skill checks for gaps, flags missing design decisions, and asks the user for
confirmation before saving `docs/<story_number>/tasks.md`. It also handles edge
cases like too many tasks, circular dependencies, and technology gaps.
