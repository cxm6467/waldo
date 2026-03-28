#!/bin/bash
# waldo zed-sync.sh — Sync active waldo persona into Zed's Rules Library
#
# Uses zed-prompts (github.com/rubiojr/zed-prompts) to write directly into
# Zed's LMDB-backed Rules Library so the persona appears globally — no per-
# project setup required. Falls back to writing a .rules file if zed-prompts
# is not available.
#
# Usage:
#   zed-sync.sh              # Import persona into Zed Rules Library (global)
#   zed-sync.sh project      # Write .rules to cwd instead
#   zed-sync.sh project DIR  # Write .rules to DIR
#   zed-sync.sh print        # Print rules markdown to stdout

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

WALDO_CONFIG="${WALDO_CONFIG:-$HOME/.config/waldo}"
PERSONAS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/personas"
ACTIVE_FILE="$WALDO_CONFIG/.active"
MOOD_FILE="$WALDO_CONFIG/.mood"

ZED_PROMPTS_BIN="${ZED_PROMPTS_BIN:-}"
ZED_PERSONA_TITLE="waldo: active persona"
ZED_PERSONA_UUID="00000000-w4ld-0000-0000-000000000001"

# ---------------------------------------------------------------------------
# Locate zed-prompts binary
# ---------------------------------------------------------------------------

find_zed_prompts() {
  # 1. Explicit env override
  if [[ -n "$ZED_PROMPTS_BIN" && -x "$ZED_PROMPTS_BIN" ]]; then
    echo "$ZED_PROMPTS_BIN"; return
  fi
  # 2. PATH
  if command -v zed-prompts &>/dev/null; then
    command -v zed-prompts; return
  fi
  # 3. GOBIN / mise-managed Go
  local gobin
  gobin="$(go env GOBIN 2>/dev/null || true)"
  if [[ -n "$gobin" && -x "$gobin/zed-prompts" ]]; then
    echo "$gobin/zed-prompts"; return
  fi
  # 4. Common fallback locations
  local candidates=(
    "$HOME/.local/share/mise/installs/go/*/bin/zed-prompts"
    "$HOME/go/bin/zed-prompts"
    "$HOME/.local/bin/zed-prompts"
  )
  for pattern in "${candidates[@]}"; do
    for f in $pattern; do
      [[ -x "$f" ]] && { echo "$f"; return; }
    done
  done
  echo ""
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

if ! command -v jq &>/dev/null; then
  echo "waldo zed-sync: jq is required (pacman -S jq)" >&2
  exit 1
fi

if [[ ! -f "$ACTIVE_FILE" ]]; then
  echo "waldo zed-sync: no active persona at $ACTIVE_FILE" >&2
  echo "  Run: /waldo use agent/<name>" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Load persona
# ---------------------------------------------------------------------------

ACTIVE=$(cat "$ACTIVE_FILE")
PERSONA_FILE="$PERSONAS_DIR/${ACTIVE}.json"

if [[ ! -f "$PERSONA_FILE" ]]; then
  echo "waldo zed-sync: persona file not found: $PERSONA_FILE" >&2
  exit 1
fi

jq_get() { jq -r "${1} // ${2}" "$PERSONA_FILE"; }

NAME=$(jq_get '.meta.name' '"unknown"')
DESC=$(jq_get '.meta.description' '""')
VERSION=$(jq_get '.meta.version' '"1.0.0"')

FORMALITY=$(jq_get   '.tone.formality'   '0.5')
DIRECTNESS=$(jq_get  '.tone.directness'  '0.5')
HUMOR=$(jq_get       '.tone.humor'       '0.5')
HEDGING=$(jq_get     '.tone.hedging'     '0.5')
WARMTH=$(jq_get      '.tone.warmth'      '0.5')

RESPONSE_LENGTH=$(jq_get '.verbosity.response_length'   '"adaptive"')
READING_LEVEL=$(jq_get   '.verbosity.reading_level'     '"professional"')
FORMAT_PREF=$(jq_get     '.verbosity.format_preference' '"adaptive"')
BULLET_THRESHOLD=$(jq_get '.verbosity.bullet_threshold' '"multi_step_only"')

AVOID_WORDS=$(jq -r   '.voice.avoid_words   // [] | if length > 0 then map("`\(.)`") | join(", ") else "" end' "$PERSONA_FILE")
PREFER_WORDS=$(jq -r  '.voice.prefer_words  // [] | if length > 0 then map("`\(.)`") | join(", ") else "" end' "$PERSONA_FILE")
CUSTOM_PHRASES=$(jq -r '.voice.custom_phrases // [] | if length > 0 then map("\"\(.)\"") | join(", ") else "" end' "$PERSONA_FILE")
SIGN_OFF=$(jq_get '.voice.sign_off' 'null')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

tone_label() {
  local val="$1" type="$2"
  awk -v v="$val" -v t="$type" 'BEGIN {
    if (t == "formality") {
      if      (v < 0.3) print "very casual"
      else if (v < 0.5) print "casual"
      else if (v < 0.7) print "professional"
      else              print "formal"
    } else if (t == "directness") {
      if      (v < 0.3) print "roundabout"
      else if (v < 0.6) print "balanced"
      else if (v < 0.85) print "direct"
      else               print "blunt, no fluff"
    } else if (t == "humor") {
      if      (v < 0.2) print "none"
      else if (v < 0.5) print "dry, occasional"
      else if (v < 0.75) print "moderate wit"
      else               print "frequent, casual"
    } else if (t == "hedging") {
      if      (v < 0.3) print "confident, no qualifiers"
      else if (v < 0.6) print "light hedging"
      else               print "heavily qualified"
    } else if (t == "warmth") {
      if      (v < 0.3) print "cold, transactional"
      else if (v < 0.6) print "neutral"
      else               print "warm, enthusiastic"
    }
  }'
}

bullet_prose() {
  case "$1" in
    always)                 echo "always" ;;
    never)                  echo "never — prose only" ;;
    multi_step_only)        echo "only for multi-step sequences" ;;
    only_when_truly_a_list) echo "only when content is genuinely a list" ;;
    *)                      echo "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# Voice block
# ---------------------------------------------------------------------------

VOICE_BLOCK=""
[[ -n "$AVOID_WORDS" ]]    && VOICE_BLOCK+="- **Never use:** $AVOID_WORDS"$'\n'
[[ -n "$PREFER_WORDS" ]]   && VOICE_BLOCK+="- **Prefer:** $PREFER_WORDS"$'\n'
[[ -n "$CUSTOM_PHRASES" ]] && VOICE_BLOCK+="- **Use occasionally:** $CUSTOM_PHRASES"$'\n'
[[ -n "$SIGN_OFF" && "$SIGN_OFF" != "null" ]] && VOICE_BLOCK+="- **Sign off with:** ${SIGN_OFF}"$'\n'
[[ -n "$VOICE_BLOCK" ]] && VOICE_BLOCK=$'\n## Voice\n\n'"$VOICE_BLOCK"

# ---------------------------------------------------------------------------
# Mood overlay
# ---------------------------------------------------------------------------

MOOD_BLOCK=""
if [[ -f "$MOOD_FILE" ]]; then
  MOOD=$(cat "$MOOD_FILE")
  MOOD_BLOCK="

## Active Mood Overlay

Session mood is active: **${MOOD}**

Adjust tone to reflect this mood while keeping the base persona intact. This overlay is temporary and not saved to the persona file.
"
fi

# ---------------------------------------------------------------------------
# Build rules markdown
# ---------------------------------------------------------------------------

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

RULES=$(cat <<MARKDOWN
# Waldo Persona: ${NAME}

> Generated ${TIMESTAMP} · \`${ACTIVE}\` · v${VERSION}
> ${DESC}

Apply these preferences to every response in this session.

## Tone

| Dimension  | Score | Style |
|------------|-------|-------|
| Formality  | ${FORMALITY} | $(tone_label "$FORMALITY" formality) |
| Directness | ${DIRECTNESS} | $(tone_label "$DIRECTNESS" directness) |
| Humor      | ${HUMOR} | $(tone_label "$HUMOR" humor) |
| Hedging    | ${HEDGING} | $(tone_label "$HEDGING" hedging) |
| Warmth     | ${WARMTH} | $(tone_label "$WARMTH" warmth) |

## Verbosity

- **Response length:** ${RESPONSE_LENGTH}
- **Reading level:** ${READING_LEVEL}
- **Format preference:** ${FORMAT_PREF}
- **Bullets:** $(bullet_prose "$BULLET_THRESHOLD")
${VOICE_BLOCK}${MOOD_BLOCK}
---
*Managed by [waldo](https://github.com/caboose-mcp/waldo) · re-run \`bash ~/.claude/hooks/waldo/zed-sync.sh\` after switching personas.*
MARKDOWN
)

# ---------------------------------------------------------------------------
# Output routing
# ---------------------------------------------------------------------------

MODE="${1:-global}"

case "$MODE" in

  # ── Global: write directly into Zed's Rules Library ──────────────────────
  global)
    ZED_PROMPTS=$(find_zed_prompts)

    if [[ -z "$ZED_PROMPTS" ]]; then
      echo "waldo zed-sync: zed-prompts not found — installing..." >&2
      go install github.com/rubiojr/zed-prompts@latest 2>&1 >&2
      ZED_PROMPTS=$(find_zed_prompts)
      if [[ -z "$ZED_PROMPTS" ]]; then
        echo "waldo zed-sync: install failed. Falling back to .rules in cwd." >&2
        printf '%s\n' "$RULES" > ".rules"
        echo "waldo: ✓ wrote .rules (fallback) → $(pwd)/.rules"
        exit 0
      fi
    fi

    # Build the JSON payload zed-prompts expects
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    JSON=$(jq -n \
      --arg uuid  "$ZED_PERSONA_UUID" \
      --arg title "$ZED_PERSONA_TITLE" \
      --arg body  "$RULES" \
      --arg now   "$NOW" \
      '[{
        "metadata": {
          "id": { "kind": "User", "uuid": $uuid },
          "title": $title,
          "default": true,
          "saved_at": $now
        },
        "content": $body
      }]')

    # zed-prompts import reads from stdin
    printf '%s\n' "$JSON" | "$ZED_PROMPTS" import --input - 2>&1

    echo ""
    echo "waldo: ✓ persona '${NAME}' written to Zed Rules Library"
    echo "  Title:   $ZED_PERSONA_TITLE"
    echo "  Default: true (auto-injected into every Agent Panel session)"
    echo ""
    echo "  If Zed is open, restart the Agent Panel to pick up the new rule."
    ;;

  # ── Per-project: write a .rules file ─────────────────────────────────────
  project)
    TARGET_DIR="${2:-.}"
    OUTPUT="$TARGET_DIR/.rules"
    printf '%s\n' "$RULES" > "$OUTPUT"
    echo "waldo: ✓ wrote .rules → $OUTPUT"
    echo "  Zed auto-loads this in the Agent Panel for this project."
    ;;

  # ── Stdout ────────────────────────────────────────────────────────────────
  print)
    printf '%s\n' "$RULES"
    ;;

  # ── Unknown: treat as a directory path ───────────────────────────────────
  *)
    OUTPUT="${1}/.rules"
    printf '%s\n' "$RULES" > "$OUTPUT"
    echo "waldo: ✓ wrote .rules → $OUTPUT"
    echo "  Zed auto-loads this in the Agent Panel for this project."
    ;;

esac
