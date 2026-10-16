---
name: gh44-handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Read `~/.claude/skills/handoff/SKILL.md` and follow it, passing on the user's arguments.

After saving, end your reply with the commands to start the next session, in one code block:

```sh
cd <working directory>
claude "read <handoff path> and continue"
```
