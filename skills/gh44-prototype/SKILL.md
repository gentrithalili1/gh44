---
name: gh44-prototype
description: Build a throwaway prototype to settle a UI or state question before planning.
argument-hint: "[the question, or a Linear ticket]"
disable-model-invocation: true
---

If given a Linear ticket, read it first (read-only) and name the question the prototype settles.

Then call the Skill tool with "prototype".

Linear stays read-only: where it says to leave a pointer on the issue, tell him the `prototype/<name>` branch and the verdict instead, so `/gh44-plan` builds on them.
