---
name: checkout
description: Check out of the day on the DF Labs board (Clio) — the end-of-day close, like Home's Check out button. Use when the member says "check out", "end my day", "wrap up the day", "close the day on clio", "aku mau check out", "selesai hari ini". Walks the day's tasks (due today or late, checked in on, also worked on), takes words per task, Done or a moved date for late ones, and sends it all as one commit.
---

# Check out — the end of the day

Check out closes the day on what really happened. It is one commit: each task
given words gets an ordinary report (the same as `report`), each moved date a
`[due]` line, and the day file gets the check-out line naming the tasks.

```
# 1. the day's lists (read only)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkout

# 2. send it: each id starts an item, its fields follow; day= is optional words for the line
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkout day="<optional>" \
  T-135 due=2026-10-23 reason="<why it moves later>" \
  T-152 words="<what happened>" status=done \
  T-158 words="<what happened>" \
  T-160 words="<why it cannot go on>" status=blocked by=T-152 \
  T-161 words="<what happened>" status=doing due=2026-11-20 \
  T-163

# nothing to say on any task: the line alone
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkout send
```

Walk the member through it the way the form does, in this order:

1. **Due today or late** (`due`). Each one needs a choice: **Done**, with words
   (they are the receipt), or **Move date**, with the new date and a reason
   ("Why?"); a late task always needs the reason. Clio does not refuse a
   check-out that leaves one alone, but the form does, so do the same: ask
   until the member picks one. Words without a status are also fine as a
   report, alongside a move.
2. **You checked in on** (`checkedIn`). Ask what happened on each. A task
   left without words is still named on the line (send just its id) and gets
   nothing written on it.
3. **Also worked on today** (`also`): tasks they reported on without checking
   in on them.
4. **Another task?** Any other task they worked on, with words.

Rules:
- **Never invent words.** Ask; use the member's own. A task with a
  `reported` line already has today's report: show it and need nothing more
  unless they want to add.
- `status` is `done`, `dropped`, `doing`, `todo`, `blocked` or `on-hold`.
  Any status needs words. Done and Dropped take no due date.
- **Blocked** (a real blocker) and **On hold** (another task took priority)
  need words (the reason) and take no due date; `by=T-NNN` optionally names
  the task it waits on or that took priority. A blocked or on-hold task that
  goes back to `doing` or `todo` is a resume and, in the open week, needs
  `due=` with its new date. A later date needs a reason; an earlier one
  does not. Dates are `YYYY-MM-DD`, never before today.
- One refused item refuses the whole check-out; nothing is written. Relay the
  reason as-is and fix that item.
- **A second check-out the same day** replaces the line, which names every
  task reported on today, so nothing from the first is lost. Report words are
  permanent: they are never edited or taken back.
- Say Done, never Finished. Show the whole check-out and confirm before
  sending. Surface the commit hash.

**Not this skill:** progress on one task during the day is `report`; the
morning's plan is `checkin`.

A report line may tag people (`@almer`, or `@Full Name`): say each as the person's name (the board's `members` give it; `clio.sh members` lists them), never the raw slug.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
