#!/bin/bash
# waldo status line hook — displays current persona in editor status bars
# Works with Claude Code, Cursor, VS Code, etc. via XDG standard paths

WALDO_CONFIG="${WALDO_CONFIG:-$HOME/.config/waldo}"
ACTIVE_FILE="$WALDO_CONFIG/.active"
MOOD_FILE="$WALDO_CONFIG/.mood"

# Read active persona
if [[ -f "$ACTIVE_FILE" ]]; then
  PERSONA=$(cat "$ACTIVE_FILE")
else
  PERSONA="agent/default"
fi

# Extract persona name (strip agent/ prefix for brevity)
PERSONA_NAME="${PERSONA##*/}"

# Check for active mood overlay
MOOD_INDICATOR=""
if [[ -f "$MOOD_FILE" ]]; then
  MOOD_INDICATOR=" [mood]"
fi

# Emit status
# Format: "waldo: persona-name [mood]"
echo "waldo: $PERSONA_NAME$MOOD_INDICATOR"
