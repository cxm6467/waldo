#!/bin/bash
# gh waldo — CLI for waldo via gh
# Install: gh extension install caboose-mcp/waldo

set -e

REPO="${1:-caboose-mcp/waldo}"
COMMAND="${2:-deploy}"

case "$COMMAND" in
  deploy)
    echo "📦 Deploying waldo UI to GitHub Pages..."
    gh workflow run pages.yml --repo "$REPO" || gh workflow run pages.yml
    echo "✓ UI deploying to: https://caboose-mcp.github.io/waldo/ui/"
    ;;

  setup)
    echo "🔧 Setting up waldo in $REPO..."
    gh workflow run gh-setup.yml --repo "$REPO" || gh workflow run gh-setup.yml
    echo "✓ Pages enabled"
    ;;

  open)
    echo "🌐 Opening waldo UI..."
    open "https://caboose-mcp.github.io/waldo/ui/" 2>/dev/null || \
    xdg-open "https://caboose-mcp.github.io/waldo/ui/" 2>/dev/null || \
    echo "https://caboose-mcp.github.io/waldo/ui/"
    ;;

  persona)
    PERSONA_NAME="${3:-my-voice}"
    echo "🎭 Creating persona: $PERSONA_NAME"
    gh issue create \
      --repo "$REPO" \
      --title "New persona: $PERSONA_NAME" \
      --body "Created via waldo CLI" \
      --label "persona" || echo "Failed to create issue"
    ;;

  *)
    cat <<EOF
waldo CLI — GitHub-native persona management

Usage:
  gh waldo [repo] <command>

Commands:
  deploy   — Deploy UI to GitHub Pages
  setup    — Enable Pages + deploy
  open     — Open UI in browser
  persona  — Create new persona (placeholder)

Examples:
  gh waldo deploy
  gh waldo caboose-mcp/waldo setup
  gh waldo open

Environment:
  GH_TOKEN — GitHub token (auto-detected by gh)
EOF
    ;;
esac
