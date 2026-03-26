# waldo — 5-Minute Setup + Usage

## Setup (One Command)

Run this once from any directory:

```bash
curl -fsSL https://raw.githubusercontent.com/caboose-mcp/waldo/demo/dual-domain/setup-waldo.sh | bash
```

Or from the repo:

```bash
cd /path/to/waldo
bash setup-waldo.sh
```

What it does:
- ✓ Checks AWS credentials
- ✓ Creates `~/.claude/personas/` structure
- ✓ Sets up hooks
- ✓ Optional: Creates S3 bucket for cross-machine sync

**Time:** ~30 seconds (interactive, skip S3 for fastest)

---

## Usage Examples

### 1. List Your Personas

```bash
/waldo list
```

Output:
```
agent/default: Neutral baseline persona [active]
agent/waldo: Chill, snarky, direct (Example)
```

### 2. Create a New Persona from Your Slack

Paste 10+ Slack messages you wrote:

```bash
/waldo slack-import
```

Claude analyzes tone, gives you persona scores, saves it.

```
Formality: 0.25 — uses lowercase, contractions
Directness: 0.80 — short messages, leads with conclusion
Humor: 0.55 — occasional dry jokes
Hedging: 0.15 — confident assertions
Warmth: 0.60 — occasional emoji, "sounds good"

Save as: my-voice
```

### 3. Switch to Your Persona

```bash
/waldo use agent/my-voice
```

Now every response uses your tone + voice.

### 4. Tweak Tone Mid-Session (Mood Overlay)

Want to sound different for one conversation?

```bash
/waldo mood make me sound happier
```

```
/waldo mood pissed
```

```bash
/waldo mood more professional
```

Session-only. To keep it permanently:

```bash
/waldo mood save
```

Clear it anytime:

```bash
/waldo mood reset
```

### 5. Learn from Your Conversation

After talking for a bit, Claude notices patterns:

```bash
/waldo learn
```

Output:
```
Recorded deltas for my-voice:
- humor: 0.55 → 0.70  (0.8 confidence: more sarcastic this session)
- directness: 0.80 → 0.85  (0.9 confidence: leading with conclusions)
- response_length: adaptive → concise  (0.7 confidence: quick questions)

Apply these? (y/n)
```

Press `y` → merges updates into your persona JSON.

If S3 is configured, it auto-pushes. Other machines auto-pull on SessionStart.

### 6. See Your Code Style

Scan a repo for conventions:

```bash
/waldo code-scan /path/to/my-project
```

Claude finds indentation, naming patterns, line length, imports, error handling, types.

```bash
/waldo code-style
```

Shows what it learned. Claude follows it from now on.

---

## Real Workflow

**Machine A (MacBook):**

```bash
# 1. Create persona from your Slack
/waldo slack-import
→ Save as: chris-marasco

# 2. Use it
/waldo use agent/chris-marasco

# 3. Have a conversation
(chat with Claude...)

# 4. Learn from it
/waldo learn
→ Apply? (y/n) → yes
→ Auto-pushes to S3
```

**Machine B (Linux, 1 hour later):**

```bash
# SessionStart hook auto-pulls from S3

# Your persona from MacBook is active
/waldo list
→ agent/chris-marasco [active] ← with updates!

# Keep going with your exact tone
(continue chatting...)
```

**You:**
- Same voice everywhere
- Learns over time
- Zero friction

---

## Commands Cheat Sheet

| Command | What It Does |
|---------|-------------|
| `/waldo list` | Show all personas, mark active |
| `/waldo use <name>` | Switch persona |
| `/waldo new <name>` | Create manually |
| `/waldo slack-import` | Generate from Slack messages |
| `/waldo mood <desc>` | Temp tone (happier, pissed, professional, etc.) |
| `/waldo mood save` | Keep mood forever |
| `/waldo mood reset` | Clear mood |
| `/waldo learn` | Analyze conversation, suggest updates |
| `/waldo code-scan <path>` | Detect code style |
| `/waldo code-style` | View code conventions |
| `/waldo export <name>` | Share persona as JSON |
| `/waldo import` | Paste JSON from someone else |

---

## Agent Agnostic

Works the same in:
- **Claude Code** (main)
- **Cursor** (same skill, same hooks)
- **ChatGPT** (copy hooks into ~/.claude manually)
- **Gemini** (same)
- **Codeium** (same)

Setup once → use everywhere.

---

## FAQ

**Q: Do I need S3?**
Nope. Works locally. S3 is just for cross-machine sync (optional).

**Q: How do I turn it off?**
Delete `~/.claude/personas/.active` or switch to a neutral persona.

**Q: Can I share personas?**
Yeah:
```bash
/waldo export chris-marasco
# Copy JSON → send to friend
# Friend runs: /waldo import
# Friend pastes JSON
```

**Q: Does it know me?**
Only what you tell it. Creates fingerprints but doesn't store IP, location, or anything spooky.

**Q: What if I mess up my persona?**
Backups exist: `~/.claude/personas/agent/my-voice.json.backup.TIMESTAMP`

**Q: Can I reset to default?**
```bash
/waldo use agent/default
```

---

## Troubleshooting

**Persona not applying?**
```bash
echo '{}' | bash ~/.claude/hooks/waldo/inject-persona.sh
# Should output JSON with persona context
```

**S3 not syncing?**
```bash
aws s3 ls s3://my-personas/
# If fails, check AWS credentials: aws configure
```

**Mood not working?**
Moods have SFW guardrails. Can't use slurs, explicit stuff, or offensive language.

**Lost a persona?**
Check backups:
```bash
ls ~/.claude/personas/agent/*.backup.*
# Restore: cp persona.json.backup.TIMESTAMP persona.json
```

---

## Next Steps

1. **Run setup:** `curl -fsSL ... | bash`
2. **Create persona:** `/waldo slack-import` (or `/waldo new my-voice`)
3. **Use it:** `/waldo use agent/my-voice`
4. **Chat**
5. **Learn:** `/waldo learn` → apply deltas
6. **Sync to other machines:** Done automatically if S3 configured

That's it. You're done.

---

**Full docs:** [WALDO-SETUP.md](WALDO-SETUP.md)
**Skill reference:** [waldo-SKILL-v5.md](waldo-SKILL-v5.md)
**GitHub:** https://github.com/caboose-mcp/waldo
