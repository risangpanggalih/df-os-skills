---
name: due
description: Set or move a DF Labs (Clio) task's due date. Use when the member says "T-0xx is due Friday", "move T-0xx to next week", "push the deadline", "give my tasks due dates", "tenggatnya mundur". A later date needs a reason; Clio refuses it without one.
---

# Set or move a task's due date

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" due T-041 2026-10-30
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" due T-041 2026-11-03 "<why it moves later>"
```

The rules, as Clio holds them:
- **A task in a week needs a due date.** Creating one, or saving one that sits
  in a week, without a date is refused ("a task in a week needs a due date").
  A backlog task may have none. Done and dropped tasks are never asked.
- **Blocked and on-hold tasks have no due date.** Reporting one blocked or on
  hold clears its date, and Clio refuses a date on it here. It gets one when it
  resumes: `report <id> "<words>" doing due=<date>` (needed in the open week).
- **A first date, or an earlier one, needs no reason. A later one does.** The
  reason is written on the task's trail with the move, for good. Ask the
  member for it in their own words; never invent one.
- Dates are `YYYY-MM-DD`. Turn "Friday" into the date and say it back before
  sending.
- A report never needs a date, except a resume from blocked or on hold in the
  open week (see `report`).
- Each move is a signed commit; surface the hash. Relay a refusal as-is.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
