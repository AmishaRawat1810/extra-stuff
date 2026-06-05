# issue-context/SKILL.md

This skill gathers all the information needed to understand a GitHub issue and
its repo context.

It performs four main steps:

1. Fetch the primary issue and any linked issues using `gh issue view`.
2. Extract and download attached images referenced in issue text and comments.
3. Survey the repository structure, relevant files, test conventions, tech
   stack, and existing docs.
4. Produce a structured `Context Summary` and save it to
   `docs/<story_number>/context.md` after user confirmation.

Important rules:

- Do not proceed to planning until the context is complete and agreed.
- Use concrete file names and evidence, not vague descriptions.
- Handle authentication issues, inaccessible images, and missing repo context
  explicitly.
- Capture image captions alongside URLs for the planning phase.
