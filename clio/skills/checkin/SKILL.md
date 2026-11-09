---
name: checkin
description: Check in on the DF Labs board (Clio) — the daily attendance. Say what you are on today (tasks and/or a line of words), say you are off today, or take an unclaimed task from this week's sprint. Use when the member says "check in", "today I'm on ...", "hari ini aku ngerjain ...", "I'm off today", "libur hari ini", "check-in ke clio", "aku ambil T-0xx". Writes to your own day file only; no task's trail changes. NOT for progress — that is report.
---

# Check in — the attendance

A check-in is a fact about **your day**: what you are on, in your words, with
the tasks it touches. It lands in your own day file and touches no task's
trail. The house expects one every day — on the days you work, and on the days
you rest, so silence never has to be guessed at.

```
# what you're on, with the tasks it touches
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkin "<the plan in your words>" T-041,T-043

# words only, or tasks only — either half may be empty
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkin "<the plan in your words>"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkin "" T-041

# off today — a check-in with no tasks, said out loud
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" off
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" off "sick, back tomorrow"

# take an unclaimed task from this week's sprint (puts your name on it),
# then check in on it
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" claim T-055
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" claim T-055 2026-10-30   # when it has no due date
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" checkin "taking the poster" T-055
```

Rules:
- Every id must exist (an unknown id is refused). Get ids from `mine`, or
  from `board` → tasks on `currentSprint` with an empty `assignees` for
  the unclaimed ones.
- **One check-in a day, edited in place:** checking in again replaces it.
  The same words again change nothing. An `off` followed by a check-in on
  tasks means the day turned into a working day.
- **Claiming a live task in the open week that has no due date needs one.** Ask the
  member when it will be done and pass the date (`YYYY-MM-DD`) to `claim`;
  without it the script stops and says so. Never pick a date for them. A task
  that already has a due date keeps it; the date argument is then ignored.
  A blocked or on-hold task is live but has no due date: it is claimed without one.
- It is planning and presence, not proof. No done-test, no status.
- Keep the member's own words. Confirm the line and the ids before sending —
  it is a signed commit.

**The day has two ends.** Check in says what the day is for; Check out
(\`checkout\`) closes it with what happened. Home's buttons are Check in and
Check out.

**Not this skill:** "T-041 is done", "the deck is done", "moved it to
doing" — that is progress on a task. Hand it to `report`.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
