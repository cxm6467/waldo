# waldo Config UI

Lightweight web UI for editing waldo personas. Single HTML file, no build step.

## Usage

### Local

```bash
# 1. Open in browser
open ui/index.html
# or
firefox ui/index.html
```

### GitHub Pages

The UI is served at: `https://caboose-mcp.github.io/waldo/ui/`

## Features

- **Visual editor** for tone sliders (formality, directness, humor, etc.)
- **Word management** for avoid/prefer/custom phrases (add/remove tags)
- **Live preview** — JSON output updates in real-time
- **Copy to clipboard** — JSON ready to import
- **Download MEML** — Export as `.meml` file for the repo
- **GitHub auth** — Optional token for future API sync

## How It Works

```
User edits tone sliders & word lists
         ↓
Vue.js updates persona object in real-time
         ↓
Preview panel shows live JSON
         ↓
Copy JSON or download MEML
```

## Requirements

- Modern browser (Chrome, Firefox, Safari, Edge)
- No server needed — runs entirely in browser
- GitHub token optional (for future API features)

## Setup

1. Open `ui/index.html` in any browser
2. Adjust tone sliders, add/remove words
3. Copy JSON or download MEML
4. Save to `~/.config/waldo/personas/agent/my-voice.meml`
5. Validate: `meml validate my-voice.meml`

## Default Persona

The UI loads with a default persona:

```
Name: my-voice
Formality: 0.3 (casual)
Directness: 0.8 (very direct)
Humor: 0.6 (moderate)
Hedging: 0.1 (confident)
Warmth: 0.5 (friendly)
```

Adjust and export.

## Future

- GitHub API integration: save personas directly to repo
- Load personas from `.meml` files
- Slack import UI
- Mood overlay builder

---

**Tech stack:**
- Vue 3 (CDN, no build)
- Vanilla CSS
- Single 600-line HTML file
