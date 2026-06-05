# implement-user-story/SKILL.md

This skill is the orchestrator for implementing a GitHub issue end-to-end. It
defines a sequential workflow of five phases: fetch & understand, planning, task
creation, task implementation, and wrap-up.

Key behavior:

- Resolves or creates `docs/<story_number>/` via `setup-story-dir.sh`.
- Loads sub-skills only when a phase begins, keeping context scoped.
- Requires explicit phase gates before moving forward.
- Handles resume vs fresh-start scenarios when a story directory already exists.
- Presents checkpoints between tasks and supports backward navigation to earlier
  phases.
- Finalizes the story with a full test run, completion note, and optional PR
  creation.
