---
name: project
description: Open or edit a DF Labs (Clio) project inside a domain, with its start, due date and goal. Use when the member says "new project", "start a project for ...", "the project is due ...", "move the project's deadline", "add people to the project". A later due date needs a reason.
---

# Open or edit a project

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" project new "Calliope: first prototype" domain=df-os start=2026-10-26 due=2026-11-20 goal="<what done looks like>" people=shean,eferist
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" project edit calliope-first-prototype due=2026-11-27 reason="<why it moves later>"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" project edit calliope-first-prototype goal="<new goal>" people=shean,eferist,risang
```

- **A new project needs a domain, a start, a due date not before the start,
  and a goal.** Domain slugs come from `domain`; an archived domain takes no
  new project. `people` is optional, a
  comma list of slugs.
- **Moving the due date later needs a reason**, written on the project's trail.
  An earlier date needs none.
- Edit fields: `name`, `start`, `due`, `goal`, `domain`, `people`,
  `status` (`active` or `parked`), `reason`. Closing a project is Mark done
  in Clio, with what landed; it is not an edit.
- Dates are `YYYY-MM-DD`. Confirm the fields before sending; surface the hash.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
