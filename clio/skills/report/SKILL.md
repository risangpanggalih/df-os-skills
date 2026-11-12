---
name: report
description: Report progress on a DF Labs (Clio) task, close it, or mark it blocked or on hold. The one verb the board has - a report on a waiting task starts it, a report carrying the proof marks it Done. Use when the member says "report to clio", "log progress on T-0xx", "T-0xx is done", "close this task", "lapor ke clio", "mark done", "drop T-0xx", "T-0xx is blocked", "put T-0xx on hold", "T-0xx can go again", or realizes something in the current session is reportable (backfill). Writes a signed commit on the task. NOT for saying what you're on today - that is checkin.
---

# Report on a Clio task — the verb

A report is one line about what actually happened, on one task, recorded
forever and never edited. Status is its shadow: a report on a `todo` task
starts it (`doing`); a report with `done` closes it and its words become the
receipt. The reporter's word is final — no approval step.

```
# progress (starts a todo, or adds a trail line to a doing task)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<what happened>"

# Done — the words are the receipt; a done-test is optional and, if given, is written in the same commit
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<what exists now that did not this morning>" done
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<what exists now that did not this morning>" done "<done-test>"

# drop / reopen / unstart (closed work is always `done`, never archived: Clio refuses archived)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<why>" dropped
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<note>" doing
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "<note>" todo

# blocked / on hold — words are the reason; by= optionally names the task
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "the venue has not confirmed the date" blocked by=T-038
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "the spring launch comes first" on-hold by=T-045

# resume (blocked or on hold → doing or todo): in the open week it needs the new due date
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" report T-041 "the venue confirmed" doing due=2026-11-20
```

**Tagging someone.** `@slug` in the words (or `@Full Name`, any case) tags a
member: Clio tells them once, as the report is posted (an Iris DM: who wrote
it, the task with its link, the line), never the writer. One of the task's
other assignees already told of a status move gets that one message. An
`@word` that is nobody stays plain words; the script says so before sending.
Who can be tagged, with their slugs:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" members
```

Use a slug from that list when the member names someone ("tell Almer" →
`@almer`); never guess a slug. After a report the script prints
`Notified: Almer (@almer)`: say who was told, by name. Tag only when the
member asks for it or names the person in the line; a tag sends a DM.

**Blocked and on hold** are live statuses that stand aside from the walk:
- `blocked`: the task cannot go on because of a real blocker, a person, a
  client, an outside thing or another task.
- `on-hold`: it is paused on purpose because another task is being
  prioritised.

Both need words (the reason). `by=T-NNN` is optional: for blocked, the task it
waits on; for on hold, the task that took priority. It cannot be the task
itself. Entering either **clears the due date**: a blocked or on-hold task has
none, is never late and never goes quiet. A plain report on one keeps it where
it is (only a todo task starts by itself). Moving it back to `doing` or `todo`
is a **resume**, and a task in the open week **needs its new due date**
(`due=YYYY-MM-DD`, today or later) in the same report; a backlog task does not.
Done or dropped straight from blocked or on hold is fine. The script checks
all of this before sending, as Clio does.

How to do it well:
1. **Do not launder the day.** If the plan said X and the day produced Y, the
   report says Y. Never rewrite the member's words into something rosier, and
   never invent progress they did not claim.
2. **One report per task that moved.** Several in a day is the design.
3. **Done asks for proof.** `done` makes the line the receipt, so it has
   to name what exists now — a link, a file, a number — concrete enough that
   someone else could check it. If they cannot name it, it is not done;
   report the progress instead.
4. **Backfill.** If the member realizes mid-conversation that something here is
   reportable, draft the line from what you both just discussed, show it with
   the target task, and CONFIRM before sending. A report is a signed commit;
   never fire one they have not seen.
5. **Say Done, never Finished.** It is the board's one word for a closed task.
6. Surface the commit hash the server returns, and who was notified. Relay refusals as-is (e.g.
   "T-099 is not a task on this board", "a report needs words — what happened?").

If the task id is unclear, run `mine` and let them pick.

**Report or check out.** Report is for one task, any time of day: it stays on
the task's row, in the drawer, and here. The end of the day is \`checkout\`
(Home's Check out button): it asks about each of the day's tasks and sends
those reports in one commit. Report words are permanent either way.

**Not this skill:** "today I'm on T-041", "I'm off today" — that is attendance.
Hand it to `checkin`.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
