---
name: orient
description: Get oriented on the whole DF Labs board (Clio) — this week's sprint, what's moving, what's gone quiet, what's in the backlog — so the assistant has context before a brainstorm or a planning talk. Use when the member asks "what's going on in clio", "show the board", "give me the state of DF", "reorient me", "apa kabar board". Read-only, covers everyone's work, not just theirs.
---

# Orient on the DF Labs board

Pull the whole board and summarize it in your own words — never dump raw JSON.

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" board
```

From the payload:
- `currentSprint` and `week` — the week the house is on, and how it stands.
- `tasks` — live work by status (`doing` vs waiting `todo`, and `blocked` / `on-hold` with their reason and `waitsOn`), grouped by project.
- `views.stale` — **gone quiet**: doing and todo tasks in this week (blocked and on hold never go quiet: their reason is on the task) whose trail has been silent for days; the backlog is never counted as quiet. The alarm sits on the work, never on a person; say which tasks, not who.
- `views.backlog` — **the backlog**: live work not planned into the open week.
- `views.committed` and each member's `today` — who has checked in today and on what.
- `projects` — each one's current focus line, which IS the house's prioritisation.

Keep it short: the sprint in one line, then moving / blocked and on hold / quiet / backlog, then the
focus lines. End by asking what the member wants to dig into.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
