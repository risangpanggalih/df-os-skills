---
name: domain
description: List, open, park, archive or restore DF Labs (Clio) domains, the areas of work that hold projects (DF-OS, Sales & Business). Use when the member says "what domains are there", "show projects by domain", "how are the projects doing", "which project is late", "new domain", "archive the Sales domain", "park it", "bring it back". Lists every domain with its status, projects and their health.
---

# Domains

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain --all
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain new "Sales & Business" "#3a6ea5" "<optional description>"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain archive sales
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain restore sales
bash "${CLAUDE_PLUGIN_ROOT}/scripts/clio.sh" domain park sales
```

- `domain` lists each domain with its status (active, parked) and colour,
  then its projects: dates, health (On track, At risk, Late, Done), done /
  doing / total task counts, goal and people. Archived domains are left out
  and counted at the end; `domain --all` lists them too, with the date they
  were archived. Summarise it. A domain is never done and has no due date; it
  clusters projects.
- A new domain needs a name and a colour: a hex like `#3a6ea5`, or one of the
  older names `violet`, `orange`, `teal`, `pink`, `blue`, `olive`, `brown`,
  `green`, `slate`. Clio refuses a hex another domain already uses and says
  which one. The description is optional. Clio answers its slug.
- **Status.** `park` sets a domain aside (it stays on the board); `archive`
  is a soft delete: the domain leaves the lists and takes no new task or
  project, and its history stays. `restore` makes an archived or parked
  domain active again. Clio refuses an archive while the domain has running
  projects or open tasks: the script prints them, one per line, and exits 1.
  Tell the member what holds it; close or move that work first. Confirm
  before archiving.
- A domain has no owner and no person. Do not ask for one.
- Confirm the name and colour before sending; surface the hash.

<!-- AUTH: calls go through the plugin's script, which signs in the way every DF Labs plugin does: if ~/.config/dfos/token (or $DFOS_TOKEN) exists it is used as a terminal pass; otherwise it signs in at DF-OS once with the member's slug and DF-OS password (from ~/.config/dfos/{slug,pass} or $DFOS_PASSWORD, else asked) and keeps the session under ~/.config/dfos/ for 30 days, shared by every plugin. On a sign-in error, tell them to set ~/.config/dfos/slug and give their DF-OS password once; dfos defaults to https://os.dflabs.id. Never echo the password, the pass, or the cookie. -->
