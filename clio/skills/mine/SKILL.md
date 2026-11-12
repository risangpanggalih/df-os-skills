---
name: mine
description: Show the DF Labs (Clio) tasks assigned to you — your plate. Live tasks first (doing, then todo, then blocked and on hold), with their projects and how long each has been quiet. Use when the member asks "what's on my plate", "my clio tasks", "what am I on in DF", "tugasku di DF apa". Read-only.
---

# Your plate on Clio

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" mine
```

Print a tight list: `doing` first, then `todo`, then `blocked` and `on-hold`
together (each with its reason, the latest `[blocked]` or `[on-hold]` line, the
task it names from `waitsOn`, and how many days it has been there), then
anything closed only if asked. For each: id, title, project, and the last trail
line's date if it is old — a doing or todo task that has not moved in days is
the one to ask about. A blocked or on-hold task has no due date and is never
quiet: ask whether its blocker is gone, not why it is late.

If they then want to say what they are on today, that is `checkin`; if they
want to say what happened on one of these, that is `report`. Do not blur the two.

A report line may tag people (`@almer`, or `@Full Name`): say each as the person's name (the board's `members` give it; `clio.sh members` lists them), never the raw slug.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
