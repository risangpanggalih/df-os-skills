---
name: task
description: Read one DF Labs (Clio) task in full — its brief, done-test, assignee, sprint, and the whole trail of reports on it. Use when the member asks "what happened on T-041", "show me T-052", "status of that task", "ceritain T-0xx". Read-only.
---

# One task, with its trail

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" task T-041
```

Tell the story in order: what it is (title, brief, done-test), who holds it,
which sprint, then the trail newest-last — each line is a signed report and
says what moved. If the task is `done`, the receipt is the proof; quote it.
If it is doing or todo and the trail is old, say how many days since it last
moved. If it is `blocked` or `on-hold`, say why (its latest `[blocked]` or
`[on-hold]` line), the task it names (`waitsOn`, "waits on T-NNN" or "for
T-NNN") and since when; it has no due date until it resumes.

The script prints the task as JSON, then `Trail:` with each line as
`date time slug — words`, where a member's tag reads as their name (`@Almer`,
the JSON keeps `@almer` as written). Tell it with the names, as people read
it in Clio; `members` lists who is who.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
