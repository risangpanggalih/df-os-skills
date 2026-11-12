#!/usr/bin/env bash
# clio.sh — thin HTTP client for Clio, the DF Labs board.
#
# Every write is made as you, through Clio, and saved by Metis as a signed
# commit "<you> via clio"; it comes back with its hash. Sign-in is DF-OS's,
# shared by every DF Labs plugin (the block marked below): your DF-OS password
# once, or a terminal pass.
#
# Usage:
#   clio.sh board                                   the whole board (JSON)
#   clio.sh mine                                    your live tasks
#   clio.sh task    <id>                            one task (JSON), then its trail as lines, a tag as @Name
#   clio.sh members                                 who can be tagged in a report: slug, name (and viewers, marked)
#   clio.sh checkin <text> [id,id,...]              check in: what you're on today
#   clio.sh off     [text]                          check in as off today
#   clio.sh claim   <id> [YYYY-MM-DD]               put your name on an unclaimed task (the date when it is in a week with none)
#   clio.sh report  <id> <text> [status] [doneTest] [by=<id>] [due=<date>]
#                                                   the verb (status: done|dropped|doing|todo|blocked|on-hold);
#                                                   by= names the task a blocked one waits on / an on-hold one gave way to;
#                                                   due= is the new date a resume (blocked/on-hold → doing/todo) needs in an open week;
#                                                   @slug (or @Full Name) in the text tags a member: Clio tells them once (Iris DM)
#   clio.sh note    <text>                          off-board report → your day file
#   clio.sh new     <title> domain=<slug> [field=value ...]  mint a task (domain required unless project= given; project|sprint|assignee|doneTest|brief|unit|due)
#   clio.sh edit    <id> field=value ...            task properties (title|brief|domain|project|sprint|assignee|unit|doneTest|due|reason)
#   clio.sh due     <id> <YYYY-MM-DD> [reason]      set or move a task's due date (a later date needs the reason)
#   clio.sh focus   <slug> <line>                   set a dated project's current focus
#   clio.sh domain  [--all]                         every domain with its status, projects and their health (archived ones only with --all)
#   clio.sh domain  new <name> <colour> [text]      open a domain (colour: violet|orange|teal|pink|blue|olive|brown|green|slate, or a hex like #3a6ea5)
#   clio.sh domain  archive|restore|hold <slug>     set a domain's status (archive refuses while it has open work, and lists it;
#                                                   hold puts it on hold; `park` is the old name for hold)
#   clio.sh project new <name> field=value ...      open a project (domain|start|due|goal required; people|slug)
#   clio.sh project edit <slug> field=value ...     project properties (name|start|due|goal|domain|people|status|reason)
#   clio.sh checkout                                the end of your day: due today or late, checked in on, also worked on
#   clio.sh checkout [day=<words>] <id> [words=<text>] [status=done|dropped|doing|todo|blocked|on-hold] [by=<id>] [due=<date> reason=<text>] <id> ...
#                                                   check out: one commit (send alone, with no ids: `checkout send`)
#   clio.sh timeline [from] [to] [domain=<slug>]    projects with their dates, health and late marks (dates YYYY-MM-DD)
#   clio.sh raw     <METHOD> <path> [jsonBody]      escape hatch
#
# Config: ~/.config/dfos/ (see the sign-in block); Clio's address in its file `clio`.
set -euo pipefail

APP=clio
# ---- BEGIN DF-OS sign-in: the same lines in every DF Labs plugin ----
# One sign-in for every plugin, as in the apps (only DF-OS signs anyone in):
# your DF-OS password once, or a terminal pass from an admin (`hub token
# <slug>`, 90 days). Kept in ~/.config/dfos/ (or $DFOS_CONFIG), shared by
# every plugin; one session serves them all.
#   slug     your member slug     (or $DFOS_SLUG)
#   token    a terminal pass      (or $DFOS_TOKEN) — used if present
#   pass     password, chmod 600  (or $DFOS_PASSWORD; else asked once)
#   dfos     DF-OS's address      (default https://os.dflabs.id)
#   <app>    an app's address, e.g. a file `clio` (default https://<app>.dflabs.id)
#   ca       a CA certificate, only for a local stack with its own CA
#   cookie   the cached session   (managed here — do not edit)
CFG="${DFOS_CONFIG:-$HOME/.config/dfos}"
mkdir -p "$CFG"; chmod 700 "$CFG" 2>/dev/null || true
DFOS="$(cat "$CFG/dfos" 2>/dev/null || echo 'https://os.dflabs.id')"; DFOS="${DFOS%/}"
URL="$(cat "$CFG/$APP" 2>/dev/null || echo "https://$APP.dflabs.id")"; URL="${URL%/}"
SLUG="${DFOS_SLUG:-$(cat "$CFG/slug" 2>/dev/null || true)}"
TOKEN="${DFOS_TOKEN:-$(cat "$CFG/token" 2>/dev/null || true)}"
JAR="$CFG/cookie"
CURL=(curl -sS --max-time 60)
[ -f "$CFG/ca" ] && CURL+=(--cacert "$CFG/ca")

# JSON-encode one argument safely (quotes, newlines, unicode).
jenc() { python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1]))' "$1"; }
# Build a JSON object from key=value pairs whose values are already JSON.
jobj() { python3 - "$@" <<'PY'
import json,sys
o={}
for kv in sys.argv[1:]:
    k,_,v=kv.partition('=')
    o[k]=json.loads(v)
sys.stdout.write(json.dumps(o))
PY
}

req() { # METHOD PATH [JSONBODY]
  local m="$1" p="$2" body="${3:-}"
  local -a auth=()
  if [ -n "$TOKEN" ]; then auth=(-H "Authorization: Bearer $TOKEN"); else auth=(-b "$JAR"); fi
  if [ -n "$body" ]; then
    "${CURL[@]}" "${auth[@]}" -X "$m" "$URL$p" -H 'Content-Type: application/json' -d "$body"
  else
    "${CURL[@]}" "${auth[@]}" -X "$m" "$URL$p"
  fi
}

signed_in() { req GET /api/me 2>/dev/null | grep -q '"slug"'; }

# DF-OS remembers a sign-in for 30 days: a visit to /login with that cookie
# hands out a fresh 12-hour pass. Only when that fails is the password needed.
renew() { [ -f "$JAR" ] && "${CURL[@]}" -b "$JAR" -c "$JAR" -o /dev/null "$DFOS/login" 2>/dev/null && signed_in; }

login() {
  [ -n "$SLUG" ] || { printf 'Your DF Labs slug (e.g. ana): ' >&2; read -r SLUG; echo "$SLUG" > "$CFG/slug"; }
  local pw="${DFOS_PASSWORD:-$(cat "$CFG/pass" 2>/dev/null || true)}"
  if [ -z "$pw" ]; then printf 'DF-OS password for %s: ' "$SLUG" >&2; read -rs pw; echo >&2; fi
  local body; body="$(jobj "name=$(jenc "$SLUG")" "password=$(jenc "$pw")" "remember=true")"
  rm -f "$JAR"
  local code; code="$("${CURL[@]}" -c "$JAR" -o /dev/null -w '%{http_code}' \
    -X POST "$DFOS/api/login" -H 'Content-Type: application/json' -d "$body")"
  [ "$code" = "200" ] || { echo "sign-in failed ($code) — check your slug and DF-OS password, and dfos in $CFG" >&2; exit 1; }
  chmod 600 "$JAR" 2>/dev/null || true
  signed_in || { echo "signed in at DF-OS, but $URL does not know you yet — is your account switched on?" >&2; exit 1; }
}

ensure_auth() {
  if [ -n "$TOKEN" ]; then
    signed_in || { echo "that pass is not valid — ask an admin for a new one (hub token <slug>), or remove $CFG/token to sign in with your password" >&2; exit 1; }
  else
    signed_in || renew || login
  fi
}
# ---- END DF-OS sign-in ----

# A comma list of ids → JSON array, uppercased and trimmed.
jids() { python3 -c 'import json,sys; print(json.dumps([x.strip().upper() for x in sys.argv[1].split(",") if x.strip()]))' "$1"; }
# A comma list of slugs → JSON array, trimmed.
jslugs() { python3 -c 'import json,sys; print(json.dumps([x.strip() for x in sys.argv[1].split(",") if x.strip()]))' "$1"; }
# A refused call fails: print the answer, and exit 1 on a 4xx or 5xx (as the Calliope plugin does).
answer() { # "<body>\n<status>"
  local code="${1##*$'\n'}"
  printf '%s' "${1%$'\n'*}"
  case "$code" in [45][0-9][0-9]) echo; return 1 ;; esac
}
call() { local out; out="$(CURL+=(-w $'\n%{http_code}'); req "$@")"; answer "$out"; }
# req, and the HTTP code on the last line of its answer.
reqs() { local -a saved=("${CURL[@]}"); CURL+=(-w $'\n%{http_code}'); req "$@"; CURL=("${saved[@]}"); }
# A domain colour: one of the names, or a hex (#3a6ea5, or 3a6ea5); sent as given.
iscolour() {
  case "$1" in violet|orange|teal|pink|blue|olive|brown|green|slate) return 0 ;; esac
  [[ "$1" =~ ^#?[0-9a-fA-F]{6}$ ]] || { echo "not a colour: $1 (violet, orange, teal, pink, blue, olive, brown, green, slate, or a hex like #3a6ea5)" >&2; exit 2; }
}
# @-tags (Clio's report mentions, 12 Nov; Calliope's reading, app/mentions.js): `@` then a member's slug or full
# name, any case, not inside a word (an address), not followed by a letter, digit, _ or -; the longest name first.
# Reads the members JSON (GET /api/board) from $MEMBERS_JSON. `tags names <text>`: the text with each tag as @Name;
# `tags unknown <text>`: the @words that are nobody, one per line.
tags() { MEMBERS_JSON="${MEMBERS_JSON:-}" python3 - "$@" <<'PY'
import json,os,re,sys
mode,text=sys.argv[1],sys.argv[2]
APPS={'clio','metis','calliope','enodia','iris','muse','mimir','df-os','hub','system'}
try: ms=[m for m in json.loads(os.environ.get("MEMBERS_JSON") or "{}").get("members",[]) if m.get("slug") and m["slug"].lower() not in APPS]
except Exception: ms=[]
toks=sorted({(t.strip().lower(),m["slug"]) for m in ms for t in (m["slug"],m.get("name") or "") if t.strip()},key=lambda x:-len(x[0]))
name={m["slug"]:m.get("name") or m["slug"] for m in ms}
W=re.compile(r"[\w-]")
out,unknown,i,low=[],[],0,text.lower()
j=low.find("@")
while j!=-1:
    b=text[j-1] if j>0 else ""
    hit=None
    if not (b and (W.match(b) or b in "@.")):
        hit=next((t for t in toks if low.startswith(t[0],j+1) and not W.match(text[j+1+len(t[0]):j+2+len(t[0])] or " ")),None)
        if not hit:
            w=re.match(r"[\w-]+",text[j+1:])
            if w: unknown.append("@"+w.group(0))
    if hit:
        out.append(text[i:j]+"@"+name[hit[1]]); i=j+1+len(hit[0]); j=low.find("@",i)
    else: j=low.find("@",j+1)
out.append(text[i:])
print("\n".join(dict.fromkeys(unknown)) if mode=="unknown" else "".join(out))
PY
}
# The board's members (one call), for tags.
members_json() { req GET /api/board 2>/dev/null | python3 -c 'import json,sys
try: print(json.dumps({"members":json.load(sys.stdin).get("members",[])}))
except Exception: print("{}")'; }

# A date must be YYYY-MM-DD before it is sent.
isdate() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "not a date: $1 (use YYYY-MM-DD)" >&2; exit 2; }; }
# field=value pairs → JSON object parts in the array `parts`; dates are checked, people is a list.
fields() {
  local kv k v
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    case "$k" in
      due|start) if [ "$k" = due ] && [ -z "$v" ]; then parts+=("due=null"); else isdate "$v"; parts+=("$k=$(jenc "$v")"); fi ;;
      people)    parts+=("$k=$(jslugs "$v")") ;;
      *)         parts+=("$k=$(jenc "$v")") ;;
    esac
  done
}


cmd="${1:-mine}"; shift || true
case "$cmd" in
  board)   ensure_auth; call GET /api/board ;;
  mine)    ensure_auth; call GET "/api/tasks?mine=1" ;;
  task)    ensure_auth
           out="$(CURL+=(-w $'\n%{http_code}'); req GET "/api/tasks/$(echo "$1" | tr a-z A-Z)")"
           answer "$out" || exit 1
           # The trail as lines, a member's tag read as @Name (the JSON above keeps the words as written).
           MEMBERS_JSON="$(members_json)"; export MEMBERS_JSON
           body="${out%$'\n'*}"
           lines="$(printf '%s' "$body" | python3 -c 'import json,sys
t=json.load(sys.stdin)
for l in t.get("trail") or []: print("%s %s %s\t%s" % (l.get("date"),l.get("time"),l.get("by"),l.get("text","")))' 2>/dev/null || true)"
           if [ -n "$lines" ]; then
             echo; echo; echo "Trail:"
             while IFS=$'\t' read -r head said; do echo "  $head — $(tags names "$said")"; done <<< "$lines"
           fi ;;
  members) ensure_auth
           req GET /api/board | python3 -c 'import json,sys
APPS={"clio","metis","calliope","enodia","iris","muse","mimir","df-os","hub","system"}
try: ms=json.load(sys.stdin).get("members",[])
except Exception: sys.exit("Clio did not answer with its members")
for m in ms:
    if m.get("slug") and m["slug"] not in APPS: print("@%-14s %s%s" % (m["slug"],m.get("name") or m["slug"],"  (viewer)" if m.get("role")=="viewer" else ""))' ;;
  checkin) ensure_auth
           text="${1:-}"; ids="${2:-}"
           call POST /api/commit "$(jobj "text=$(jenc "$text")" "tasks=$(jids "$ids")")" ;;
  off)     ensure_auth
           call POST /api/commit "$(jobj "text=$(jenc "${1:-off today}")" "tasks=[]" "off=true")" ;;
  claim)   ensure_auth
           me="$(req GET /api/me | python3 -c 'import json,sys; print(json.load(sys.stdin)["slug"])')"
           id="$(echo "$1" | tr a-z A-Z)"; date="${2:-}"
           [ -n "$date" ] && isdate "$date"
           # The task as it stands: mine (already yours), dated:<date> (has a due date),
           # need (live, in the open week, no due date: Clio refuses the claim without one),
           # maybe (live, in a week, no due date, and the weeks could not be read), or ok.
           task="$(req GET "/api/tasks/$id" 2>/dev/null || true)"
           weeks=""
           if printf '%s' "$task" | python3 -c 'import json,sys; t=json.load(sys.stdin); sys.exit(0 if t.get("sprint") and not t.get("due") else 1)' 2>/dev/null; then
             weeks="$(req GET /api/sprints 2>/dev/null || true)"
           fi
           state="$(python3 -c 'import json,sys,datetime
try: t=json.loads(sys.argv[2])
except Exception: print("ok"); sys.exit()
if sys.argv[1] in (t.get("assignees") or []): print("mine"); sys.exit()
if t.get("due"):
    try: d=datetime.date.fromisoformat(str(t["due"])[:10]).strftime("%a %-d %b")
    except Exception: d=str(t["due"])
    print("dated:"+d); sys.exit()
# Live: todo, doing, blocked, on-hold. Blocked and on-hold have no due date (Clio 3.2), so only todo and doing need one.
if t.get("status") not in ("todo","doing","blocked","on-hold"): print("ok"); sys.exit()
if not t.get("sprint") or t.get("status") in ("blocked","on-hold"): print("ok"); sys.exit()
try: ws=json.loads(sys.argv[3])["sprints"]
except Exception: print("maybe"); sys.exit()
w=[x for x in ws if x.get("id")==t["sprint"]]
print("need" if w and w[0].get("status")=="open" else "ok" if w else "maybe")' "$me" "$task" "$weeks")"
           [ "$state" = mine ] && { echo "$id is already yours."; exit 0; }
           case "$state" in
             dated:*) [ -n "$date" ] && echo "$id already has a due date (${state#dated:}); claimed without changing it." >&2
                      date="" ;;
             need)    [ -z "$date" ] && { echo "$id is in the open week and has no due date: claim it with one, e.g. claim $id 2026-10-30" >&2; exit 2; } ;;
             maybe)   [ -z "$date" ] && { echo "$id has no due date: if its week is still open, claim it with one, e.g. claim $id 2026-10-30" >&2; exit 2; } ;;
             *)       date="" ;;
           esac
           parts=("assignee=$(jenc "$me")" 'expect={"assignee":""}')
           [ -n "$date" ] && parts+=("due=$(jenc "$date")")
           # refused (409) if someone took it since you looked, as in the web face
           call PATCH "/api/tasks/$id" "$(jobj "${parts[@]}")" ;;
  report)  [ $# -ge 2 ] || { echo "usage: report <id> <text> [status] [doneTest] [by=<id>] [due=<date>]" >&2; exit 2; }
           id="$(echo "$1" | tr a-z A-Z)"; text="$2"; shift 2
           status=""; dt=""; by=""; due=""
           for a in "$@"; do
             case "$a" in
               by=*)  by="$(echo "${a#by=}" | tr a-z A-Z)" ;;
               due=*) due="${a#due=}"; isdate "$due" ;;
               *)     if [ -z "$status" ]; then status="$a"; elif [ -z "$dt" ]; then dt="$a"; else echo "too many arguments: $a" >&2; exit 2; fi ;;
             esac
           done
           # The same rules as Clio (SOLUTIONING 3.2), said before anything is sent.
           [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || { echo "a report needs words: what happened?" >&2; exit 2; }
           case "$status" in ""|todo|doing|done|dropped|blocked|on-hold) ;; *) echo "status is todo, doing, blocked, on-hold, done or dropped" >&2; exit 2 ;; esac
           case "$status" in blocked|on-hold) [ -n "$due" ] && { echo "$id: blocked and on-hold take no due date; it gets one when it resumes" >&2; exit 2; } ;; esac
           [ -n "$by" ] && { [[ "$by" =~ ^T-[0-9]+$ ]] || { echo "by= is a task id, e.g. by=T-012" >&2; exit 2; }; [ "$by" = "$id" ] && { echo "$id cannot wait on itself" >&2; exit 2; }; }
           ensure_auth
           # What the task is now decides by= (blocked or on-hold only) and a resume's date (in an open week).
           if [ -n "$by" ] || [ -n "$due" ] || [ "$status" = doing ] || [ "$status" = todo ]; then
             task="$(req GET "/api/tasks/$id")"
             weeks="$(req GET /api/sprints 2>/dev/null || true)"
             python3 -c '
import json,sys
id,status,by,due=sys.argv[1:5]
try: t=json.loads(sys.argv[5])
except Exception: sys.exit(0)
if "status" not in t: sys.stderr.write(sys.argv[5]+"\n"); sys.exit(1)
paused=("blocked","on-hold")
target=status or ("doing" if t["status"]=="todo" else t["status"])
resuming=status in ("doing","todo") and t["status"] in paused
def die(m): sys.stderr.write(id+": "+m+"\n"); sys.exit(2)
if by and target not in paused: die("by= goes only with blocked or on-hold")
if due and not resuming: die("due= goes on a report only when it resumes a blocked or on-hold task (move a date with: due "+id+" <date>)")
try: open_week=any(w.get("id")==t.get("sprint") and w.get("status")=="open" for w in json.loads(sys.argv[6])["sprints"])
except Exception: open_week=bool(t.get("sprint"))
if resuming and not due and open_week: die("it is "+t["status"].replace("-"," ")+": resuming it in the open week needs its new due date, e.g. due=2026-11-20")
' "$id" "$status" "$by" "$due" "$task" "$weeks" || exit 2
           fi
           parts=("text=$(jenc "$text")")
           [ -n "$status" ] && parts+=("status=$(jenc "$status")")
           [ -n "$dt" ]     && parts+=("doneTest=$(jenc "$dt")")
           [ -n "$by" ]     && parts+=("by=$(jenc "$by")")
           [ -n "$due" ]    && parts+=("due=$(jenc "$due")")
           # A tag that is nobody stays words and tells no one: said before sending, never refused.
           case "$text" in *@*) MEMBERS_JSON="$(members_json)"; export MEMBERS_JSON
                                nobody="$(tags unknown "$text")"
                                [ -n "$nobody" ] && echo "Not a member, kept as words: $(echo $nobody | tr ' ' ',' | sed 's/,/, /g') (clio.sh members lists who can be tagged)" >&2 ;; esac
           out="$(CURL+=(-w $'\n%{http_code}'); req POST "/api/tasks/$id/report" "$(jobj "${parts[@]}")")"
           answer "$out" || exit 1
           # Who Clio told (each once, by Iris DM): by name, so the member hears it plainly.
           told="$(printf '%s' "${out%$'\n'*}" | python3 -c 'import json,sys
try: n=json.load(sys.stdin).get("notified") or []
except Exception: n=[]
print(", ".join("%s (@%s)" % (x.get("name") or x["slug"], x["slug"]) for x in n))' 2>/dev/null || true)"
           [ -n "$told" ] && { echo; echo "Notified: $told"; }
           exit 0 ;;
  note)    ensure_auth; call POST /api/report "$(jobj "text=$(jenc "$1")")" ;;
  new)     ensure_auth
           title="$1"; shift
           parts=("title=$(jenc "$title")")
           fields "$@"
           call POST /api/tasks "$(jobj "${parts[@]}")" ;;
  edit)    ensure_auth
           id="$(echo "$1" | tr a-z A-Z)"; shift
           parts=()
           fields "$@"
           [ ${#parts[@]} -eq 0 ] && { echo "usage: edit <id> field=value ...  (title|brief|project|sprint|assignee|unit|doneTest|due|reason)" >&2; exit 2; }
           call PATCH "/api/tasks/$id" "$(jobj "${parts[@]}")" ;;
  due)     [ $# -ge 2 ] || { echo "usage: due <id> <YYYY-MM-DD> [reason]" >&2; exit 2; }
           isdate "$2"; ensure_auth
           id="$(echo "$1" | tr a-z A-Z)"
           parts=("due=$(jenc "$2")")
           [ -n "${3:-}" ] && parts+=("reason=$(jenc "$3")")
           call PATCH "/api/tasks/$id" "$(jobj "${parts[@]}")" ;;
  focus)   ensure_auth; call PATCH "/api/projects/$1" "$(jobj "focus=$(jenc "$2")")" ;;
  domain)  dusage="usage: domain [--all] | domain new <name> <colour> [description] | domain archive|restore|hold <slug>"
           case "${1:-}" in
             ""|--all|all)
                  all="${1:-}"; ensure_auth
                  # Each domain with its status; archived ones only with --all (as Clio's Domains page keeps them apart).
                  req GET /api/domains | python3 -c '
import json,sys
raw=sys.stdin.read()
try: t=json.loads(raw)
except Exception: print(raw); sys.exit()
if "domains" not in t: print(raw); sys.exit()
everything=sys.argv[1]!=""
H={"on_track":"On track","on-track":"On track","at_risk":"At risk","at-risk":"At risk","late":"Late","done":"Done","on-hold":"On hold","parked":"On hold"}
WORD={"on-hold":"on hold","parked":"on hold"}  # an old parked is on hold (12 Nov)
shown=[d for d in t["domains"] if everything or d.get("status")!="archived"]
hidden=len(t["domains"])-len(shown)
if not shown: print("No domains.")
for d in shown:
    st=d.get("status") or "active"; st=WORD.get(st,st)
    if st=="archived" and d.get("archived"): st+=" "+str(d["archived"])
    print("%s (%s)  %s  %s" % (d.get("name",d.get("slug")),d.get("slug"),st,d.get("colour") or "no colour"))
    ps=d.get("projects") or []
    if not ps: print("  (no project)")
    for p in ps:
        h=p.get("health") or p.get("status") or ""; h=H.get(h,h.replace("_"," ").capitalize())
        print("  %s  %s -> %s  %s  done %s, doing %s, of %s" % (p.get("name"),p.get("start"),p.get("due"),h,p.get("done",0),p.get("doing",0),p.get("total",0)))
        extra=[x for x in (p.get("goal") and "goal: "+p["goal"], p.get("people") and "people: "+", ".join(p["people"])) if x]
        if extra: print("    "+"; ".join(extra))
if hidden: print("\n%d archived domain%s not shown (domain --all)" % (hidden,"" if hidden==1 else "s"))
' "$all"; exit 0 ;;
             new) [ $# -ge 3 ] || { echo "usage: domain new <name> <colour> [description]" >&2; exit 2; }
                  iscolour "$3"; ensure_auth
                  parts=("name=$(jenc "$2")" "colour=$(jenc "$3")")
                  [ -n "${4:-}" ] && parts+=("description=$(jenc "$4")")
                  call POST /api/domains "$(jobj "${parts[@]}")" ;;
             archive|restore|hold|park)
                  [ $# -eq 2 ] && [ -n "$2" ] || { echo "usage: domain $1 <slug>" >&2; exit 2; }
                  case "$1" in archive) st=archived ;; restore) st=active ;; hold|park) st=on-hold ;; esac
                  ensure_auth
                  out="$(reqs PATCH "/api/domains/$2" "$(jobj "status=$(jenc "$st")")")"
                  code="${out##*$'\n'}"; body="${out%$'\n'*}"
                  [[ "$code" =~ ^2 ]] && { printf '%s\n' "$body"; exit 0; }
                  # Refused: the reason, and on an archive the open work that holds it, one line each.
                  printf '%s' "$body" | python3 -c '
import json,sys
raw=sys.stdin.read()
try: e=json.loads(raw)
except Exception: sys.stderr.write((raw or "no answer")+"\n"); sys.exit()
sys.stderr.write((e.get("error") or raw)+"\n")
o=e.get("open") or {}
ps,ts=o.get("projects") or [],o.get("tasks") or []
if ps:
    sys.stderr.write("Running projects:\n")
    for p in ps: sys.stderr.write("  %s (%s)%s, %s open task%s\n" % (p.get("name"),p.get("slug"),", due "+p["due"] if p.get("due") else "",p.get("openTasks",0),"" if p.get("openTasks")==1 else "s"))
if ts:
    sys.stderr.write("Open tasks:\n")
    for t in ts: sys.stderr.write("  %s %s (%s%s)\n" % (t.get("id"),t.get("title",""),t.get("status",""),", "+t["project"] if t.get("project") else ""))
if ps or ts: sys.stderr.write("Close or move them first, then archive again.\n")
'
                  exit 1 ;;
             *)   echo "$dusage" >&2; exit 2 ;;
           esac ;;
  project) ensure_auth
           case "${1:-}" in
             new)  [ $# -ge 2 ] || { echo "usage: project new <name> domain=<slug> start=<date> due=<date> goal=<text> [people=a,b]" >&2; exit 2; }
                   parts=("name=$(jenc "$2")"); shift 2
                   fields "$@"
                   call POST /api/projects "$(jobj "${parts[@]}")" ;;
             edit) [ $# -ge 3 ] || { echo "usage: project edit <slug> field=value ...  (name|start|due|goal|domain|people|status|reason)" >&2; exit 2; }
                   slug="$2"; shift 2; parts=()
                   fields "$@"
                   call PATCH "/api/projects/$slug" "$(jobj "${parts[@]}")" ;;
             *)    echo "usage: project new <name> field=value ... | project edit <slug> field=value ..." >&2; exit 2 ;;
           esac ;;
  checkout)
           if [ $# -eq 0 ]; then ensure_auth; call GET /api/checkout; echo; exit 0; fi
           [ "$1" = send ] && shift
           # Each id starts an item; the field=value pairs after it belong to it. day= is the line's own words.
           body="$(python3 -c '
import json,re,sys
items,day,cur=[],None,None
def die(m): sys.stderr.write(m+"\n"); sys.exit(2)
for a in sys.argv[1:]:
    if re.fullmatch(r"[A-Za-z]-\d+",a):
        cur={"id":a.upper()}; items.append(cur); continue
    k,eq,v=a.partition("=")
    if not eq: die("not an id or field=value: "+a)
    if k=="day": day=v; continue
    if cur is None: die(k+"= comes after a task id (day= is the only field before one)")
    if k not in ("words","status","due","reason","by"): die("unknown field: "+k+" (words|status|by|due|reason)")
    if k=="status" and v not in ("todo","doing","done","dropped","blocked","on-hold"): die("status is todo, doing, blocked, on-hold, done or dropped")
    if k=="by":
        v=v.upper()
        if not re.fullmatch(r"T-\d+",v): die("by= is a task id, e.g. by=T-012")
    if k=="due" and not re.fullmatch(r"\d{4}-\d{2}-\d{2}",v): die("not a date: "+v+" (use YYYY-MM-DD)")
    cur[k]=v
ids=[i["id"] for i in items]
if len(ids)!=len(set(ids)): die("a task is named twice")
for i in items:
    if i.get("status") and not i.get("words","").strip(): die(i["id"]+": "+i["status"]+" needs words")
    if i.get("status") in ("blocked","on-hold") and i.get("due"): die(i["id"]+": blocked and on-hold take no due date; it gets one when it resumes")
    if i.get("by") and i.get("status") not in ("blocked","on-hold"): die(i["id"]+": by= goes with status=blocked or status=on-hold")
    if i.get("by")==i["id"]: die(i["id"]+" cannot wait on itself")
    if i.get("status") in ("done","dropped") and i.get("due"): die(i["id"]+": "+i["status"]+" takes no due date")
    if i.get("reason") and not i.get("due"): die(i["id"]+": reason= goes with due=")
o={"items":items}
if day: o["words"]=day
print(json.dumps(o))' "$@")" || exit 2
           ensure_auth
           # A resume (a blocked or on-hold task to doing or todo) in the open week needs its new due date, as in Clio.
           resumes="$(printf '%s' "$body" | python3 -c 'import json,sys; print(" ".join(i["id"] for i in json.load(sys.stdin)["items"] if i.get("status") in ("doing","todo") and not i.get("due")))')"
           if [ -n "$resumes" ]; then
             weeks="$(req GET /api/sprints 2>/dev/null || true)"
             for rid in $resumes; do
               python3 -c '
import json,sys
try: t=json.loads(sys.argv[2])
except Exception: sys.exit(0)
if t.get("status") not in ("blocked","on-hold"): sys.exit(0)
try: open_week=any(w.get("id")==t.get("sprint") and w.get("status")=="open" for w in json.loads(sys.argv[3])["sprints"])
except Exception: open_week=bool(t.get("sprint"))
if open_week: sys.stderr.write(sys.argv[1]+" is "+t["status"].replace("-"," ")+": resuming it in the open week needs due=<date>\n"); sys.exit(2)
' "$rid" "$(req GET "/api/tasks/$rid")" "$weeks" || exit 2
             done
           fi
           call POST /api/checkout "$body" ;;
  timeline)
           q=()
           for a in "$@"; do
             case "$a" in
               domain=*) q+=("domain=${a#domain=}") ;;
               *) isdate "$a"; if [ ${#q[@]} -eq 0 ] || [[ "${q[0]}" != from=* ]]; then q=("from=$a" ${q[@]+"${q[@]}"}); else q+=("to=$a"); fi ;;
             esac
           done
           qs="$(IFS='&'; echo "${q[*]+${q[*]}}")"
           ensure_auth
           req GET "/api/timeline${qs:+?$qs}" | python3 -c '
import json,sys
raw=sys.stdin.read()
try: t=json.loads(raw)
except Exception: print(raw); sys.exit()
if "domains" not in t: print(raw); sys.exit()
H={"on_track":"On track","on-track":"On track","at_risk":"At risk","at-risk":"At risk","late":"Late","done":"Done"}
print("Timeline %s to %s (today %s)" % (t.get("from"),t.get("to"),t.get("today")))
for d in t["domains"]:
    print("\n"+d.get("name",d.get("slug","")))
    if not d.get("projects"): print("  (no dated project in this window)")
    for p in d.get("projects",[]):
        h=p.get("health") or ""; h=H.get(h,h.replace("_"," ").capitalize())
        late="  %d days late" % p["late"] if p.get("late") else ""
        print("  %s  %s -> %s  %s  done %s, doing %s, of %s%s" % (p.get("name"),p.get("start"),p.get("due"),h,p.get("done",0),p.get("doing",0),p.get("total",0),late))
        for k in p.get("tasks",[]):
            if k.get("late"): print("    %s %s  due %s  %d days late (%s)" % (k["id"],k.get("title",""),k.get("due"),k["late"],", ".join(k.get("assignees") or []) or "nobody"))
' ; exit 0 ;;
  raw)     ensure_auth; call "$1" "$2" "${3:-}" ;;
  *)       echo "unknown command: $cmd (see header for usage)" >&2; exit 2 ;;
esac
echo
