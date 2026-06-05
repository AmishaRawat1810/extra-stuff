# story-planning/SKILL.md

This skill turns confirmed issue context into an agreed written plan.

It expects `docs/<story_number>/context.md` to already exist and then:

- Summarizes the story in plain language
- Identifies scope, impact areas, open questions, and assumptions
- Iterates with the user until they explicitly reply `Agreed`
- Saves the final plan as `docs/<story_number>/plan.md`

The plan structure includes objective, in/out scope, approach, affected areas,
assumptions, resolved questions, and risks. The skill emphasizes numbered
clarification questions and explicit agreement before moving on.
