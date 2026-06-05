# task-implementation/SKILL.md

This skill implements one task from `docs/<story_number>/tasks.md` at a time.

It requires the current task definition, context from Phase 0, and all prior
tasks committed. The implementation workflow includes:

- announcing the task and approach
- writing code and following project conventions
- adding tests for every acceptance criterion
- running the appropriate test suite until all tests pass
- presenting the change for review with a checklist
- handling feedback cycles and re-running tests
- committing once the user approves

It also defines commit message conventions and explicitly returns control to the
orchestrator after each completed task.
