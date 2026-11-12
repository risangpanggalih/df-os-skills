---
name: today
description: See what's been going on in DF Labs (Clio) today — who checked in, who is off, and what got reported, across the team. Use when the member asks "what happened today in DF", "who checked in", "activity today", "siapa yang sudah check-in", "apa yang terjadi hari ini di clio". Read-only.
---

# Today on Clio

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" board
```

Read `views.today`: one flat list, sorted by time, of two kinds of line —

- **check-ins** — `kind: "commitment"`. What a person said they are on
  (`tasks`, `text`), or `off: true` for a rest day. Attendance and intent.
- **reports** — everything else. A trail line on a task (`task` set) or an
  off-board line (`task` null). What actually moved.

Present them apart, in two short groups, each line as `time · name · words`.
For check-ins, say plainly who is off today. Then `members[].today` tells you
who has said nothing at all — mention it as a fact, never as a verdict: the
board does not flag people.

A report line may tag people (`@almer`, or `@Full Name`): say each as the person's name (the board's `members` give it; `clio.sh members` lists them), never the raw slug.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
