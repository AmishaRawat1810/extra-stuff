# implement-user-story/scripts/setup-story-dir.sh

A small bash helper used by the implement-user-story skill to prepare the story workspace.

What it does:
- Validates a single argument: the story number.
- Creates `docs/<story_number>/` if missing.
- Detects existing markdown files in that directory.
- Prints `CLEAN` and exits 0 when the directory is empty or newly created.
- Prints `PARTIAL_RUN`, lists existing `.md` files, and exits 2 when artifacts are found.

This enables the orchestrator to decide whether to resume a previous run or start fresh.