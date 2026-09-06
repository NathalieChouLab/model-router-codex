#!/usr/bin/env bash
# Installs the four router agents into ~/.codex/agents and the router rules into ~/.codex/AGENTS.md.
# Override models per tier: SCOUT_MODEL, BUILDER_MODEL, VERIFIER_MODEL, ARCHITECT_MODEL.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/agents"
for a in scout builder verifier architect; do
  [ -e "$CODEX_HOME/agents/$a.toml" ] && cp "$CODEX_HOME/agents/$a.toml" "$CODEX_HOME/agents/$a.toml.bak"
  cp "$HERE/agents/$a.toml" "$CODEX_HOME/agents/$a.toml"
done
set_model(){ [ -n "${2:-}" ] && sed -i.tmp "s/^model = .*/model = \"$2\"/" "$CODEX_HOME/agents/$1.toml" && rm -f "$CODEX_HOME/agents/$1.toml.tmp"; true; }
set_model scout "${SCOUT_MODEL:-}"; set_model builder "${BUILDER_MODEL:-}"
set_model verifier "${VERIFIER_MODEL:-}"; set_model architect "${ARCHITECT_MODEL:-}"

AG="$CODEX_HOME/AGENTS.md"
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
