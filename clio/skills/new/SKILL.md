---
name: new
description: Mint a new DF Labs (Clio) task. Use when the member says "new clio task", "add a task to DF", "buat task", or a brainstorm produces work worth tracking. Writes a signed commit and returns the new task id.
---

# Mint a task

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" new "<title — name the result, not the activity>" domain=operations
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" new "<title>" project=portfolio-site-v2 sprint=2026-W38 due=2026-09-25 doneTest="<how we will know it is done>"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" new "<title>" domain=df-os assignee=ana brief="<one paragraph of context>"
```

- **Every task has a domain.** Give `domain=<slug>`, or `project=<slug>` (a
  dated project; the task takes its domain). A project is optional: impromptu
  work is a task in its domain with no project. When the member names neither,
  list the domains (`clio.sh domain`) and ask; never guess one. An archived
  domain takes no new task (Clio answers "<Name> is archived").

Other fields (all optional): `project` (slug of a dated project), `sprint` (id),
`assignee` (slug — defaults to you), `doneTest`, `brief`, `unit`
(`task` or `question`), `due` (`YYYY-MM-DD`).

- The title names the result. "Poster public" beats "work on poster".
- **A task in a week needs a due date.** With `sprint=` set, ask for `due=`
  too; Clio refuses the task without it. A backlog task may have none.
- A done needs only the words, which become the receipt. A done-test is
  optional; offer one when the work is concrete enough to have it. A
  `question` unit is for open questions.
- Work you take on yourself is born `self-added`; work minted for someone
  else is born `planned`. The gate decides from the assignee.
- Confirm the title and fields before sending. Surface the returned id.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
