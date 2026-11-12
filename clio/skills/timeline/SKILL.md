---
name: timeline
description: See the DF Labs (Clio) Timeline — every dated project with its start, due date, health and how late it is, by domain, and the late tasks in them. Use when the member asks "show the timeline", "what's due when", "which projects are late", "how are the projects going", "timeline for Sales", "roadmap". Read-only.
---

# The Timeline

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" timeline
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" timeline 2026-10-12 2026-11-08
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" timeline domain=sales
```

- Optional: a from date, a to date (`YYYY-MM-DD`) and `domain=<slug>`
  (slugs from `domain`). A project shows when its bar meets the window; a
  late one runs on to today. Archived domains are left out unless named with
  `domain=`.
- Each domain lists its dated projects: start → due, health (On track, At
  risk, Late, Done), done / doing / total tasks, and "N days late". Under a
  project, its late tasks with whose they are. Tasks with no project are not
  on it.
- Summarise: what is late first, then at risk, then the rest. Name the work,
  not the people, when something slips.
- It only reads. Dates move with `due` (a task) and `project edit` (a
  project); a later due date needs a reason.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
