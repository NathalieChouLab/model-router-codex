#!/usr/bin/env bash
# Installs the twenty-two router agents into ~/.codex/agents and the router rules into ~/.codex/AGENTS.md.
# Override models per tier: SCOUT_MODEL, BUILDER_MODEL, VERIFIER_MODEL, ARCHITECT_MODEL.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# PROJECT_DIR=/path/to/repo installs into that repo's .codex/agents and AGENTS.md (travels with the repo into Codex cloud).
if [ -n "${PROJECT_DIR:-}" ]; then CODEX_HOME="$PROJECT_DIR/.codex"; else CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"; fi
mkdir -p "$CODEX_HOME/agents"; BAK="$CODEX_HOME/agents-backup/$(date +%Y%m%d%H%M%S)"; mkdir -p "$BAK"
for a in scout researcher builder tester writer verifier architect auditor designer debugger analyst librarian coordinator promptsmith editor counsel operator monitor clerk runner digest quickfix; do
  [ -e "$CODEX_HOME/agents/$a.toml" ] && cp "$CODEX_HOME/agents/$a.toml" "$BAK/$a.toml"
  cp "$HERE/agents/$a.toml" "$CODEX_HOME/agents/$a.toml"
done
set_model(){ [ -n "${2:-}" ] && sed -i.tmp "s/^model = .*/model = \"$2\"/" "$CODEX_HOME/agents/$1.toml" && rm -f "$CODEX_HOME/agents/$1.toml.tmp"; true; }
set_model scout "${SCOUT_MODEL:-}"; set_model builder "${BUILDER_MODEL:-}"
set_model verifier "${VERIFIER_MODEL:-}"; set_model architect "${ARCHITECT_MODEL:-}"
set_model researcher "${RESEARCHER_MODEL:-}"; set_model writer "${WRITER_MODEL:-}"
set_model tester "${TESTER_MODEL:-}"; set_model auditor "${AUDITOR_MODEL:-}"
set_model designer "${DESIGNER_MODEL:-}"; set_model debugger "${DEBUGGER_MODEL:-}"
set_model analyst "${ANALYST_MODEL:-}"; set_model librarian "${LIBRARIAN_MODEL:-}"
for a in coordinator promptsmith editor counsel operator monitor clerk runner digest quickfix; do v="$(echo $a | tr a-z A-Z)_MODEL"; set_model $a "${!v:-}"; done

if [ -n "${PROJECT_DIR:-}" ]; then AG="$PROJECT_DIR/AGENTS.md"; else AG="$CODEX_HOME/AGENTS.md"; fi
if [ -f "$AG" ] && grep -q 'model-router:start' "$AG"; then
  python3 - "$AG" "$HERE/AGENTS.md" <<'PY'
import sys,re
ag,src=sys.argv[1],sys.argv[2]
old=open(ag).read(); new=open(src).read()
open(ag,'w').write(re.sub(r'<!-- model-router:start -->.*?<!-- model-router:end -->',lambda m:new.strip(),old,flags=re.S))
PY
else
  { [ -f "$AG" ] && printf '\n'; cat "$HERE/AGENTS.md"; } >> "$AG"
fi
echo "Installed agents to $CODEX_HOME/agents and router rules to $AG."
echo "Check with: codex doctor   |   list your models with /model inside codex and edit the model = lines if needed."
