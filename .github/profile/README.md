# caboose-mcp

We build tools and systems for AI developers.

## Projects

### [**waldo**](https://github.com/caboose-mcp/waldo)
Persistent persona system for Claude Code, Cursor, and other AI tools. Define your voice once, apply it everywhere.

- Personas stored as MEML config files with emoji annotations
- Learns your tone from your Slack messages
- Syncs across machines via S3
- Works with Claude Code, Cursor, ChatGPT, Gemini, Codeium

**Quick start:**
```bash
curl -fsSL https://raw.githubusercontent.com/caboose-mcp/waldo/main/setup-waldo.sh | bash
/waldo slack-import
/waldo use agent/your-voice
```

### [**meml**](https://github.com/caboose-mcp/meml)
Lightweight config language. TOML-inspired with first-class emoji support.

```meml
[🔧 server]
host = "0.0.0.0"
port = 8080
status = 🟢
```

CLI tools:
- `meml validate` — syntax check
- `meml dump` — convert to JSON
- `meml env` — emit shell exports

---

**Built with:** Go, Bash, TypeScript, Terraform
