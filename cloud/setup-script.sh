#!/usr/bin/env bash
# Codex cloud-environment setup script: installs model-router into the sandbox's ~/.codex
# (22 custom agents + router rules in ~/.codex/AGENTS.md) so cloud tasks route across pinned agents.
# Paste into the Codex environment's Setup script field. Safe to re-run; never fails the session.
RAW="https://raw.githubusercontent.com/NathalieChouLab/model-router-codex/main"
DEST="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$DEST/agents" 2>/dev/null || exit 0
curl -fsSL "$RAW/cloud/manifest.txt" -o /tmp/mrc-manifest.txt || { echo "model-router-codex: manifest fetch failed"; exit 0; }
while read -r f; do
  case "$f" in
    agents/*) curl -fsSL "$RAW/$f" -o "$DEST/$f" || true ;;
    AGENTS.md) curl -fsSL "$RAW/$f" -o /tmp/mrc-AGENTS.md || true ;;
  esac
done < /tmp/mrc-manifest.txt
AG="$DEST/AGENTS.md"
if [ -s /tmp/mrc-AGENTS.md ]; then
  if [ -f "$AG" ] && grep -q 'model-router:start' "$AG"; then
    python3 - "$AG" /tmp/mrc-AGENTS.md <<'PY' 2>/dev/null || cat /tmp/mrc-AGENTS.md > "$AG"
import sys,re
ag,src=sys.argv[1],sys.argv[2]
old=open(ag).read(); new=open(src).read().strip()
open(ag,'w').write(re.sub(r'<!-- model-router:start -->.*?<!-- model-router:end -->',lambda m:new,old,flags=re.S))
PY
  else
    { [ -f "$AG" ] && printf '\n'; cat /tmp/mrc-AGENTS.md; } >> "$AG"
  fi
fi
echo "model-router-codex installed to $DEST: $(ls "$DEST/agents" | wc -l | tr -d ' ') agents"
true
