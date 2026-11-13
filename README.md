# cbx for After Effects

Two panels for After Effects on macOS:

- **cbx agent**: type what you want ("rig the selected layers with a bounce control", "make this a number counter") and an AI agent builds it in your open project: scripts, expressions, clean control panels, custom GPU effects. Uses your own Claude (Claude Code) or ChatGPT (Codex) subscription. No API keys.
- **cbxpanel**: a quick-action toolbar. Tiles run scripts, expressions, effects, presets, menu commands or panels, with ⇧/⌥/⌘ variants. Imports KBar files. Your AI agent can add and edit tiles through its MCP server.

## Install (easiest: let your AI agent do it)

Paste this into Claude Code, Codex, Cursor or any agent that can run Terminal commands:

```
Install cbx for After Effects on my Mac. Follow https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/AGENTS.md
```

## Or install it yourself

Open Terminal and run:

```sh
curl -fsSL https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/install.sh | bash
```

(Or download the zip from [Releases](https://github.com/conrad-rd/cbx-ae/releases/latest), unzip it and run `bash install.sh` inside the folder.)

Then restart After Effects and open **Window > Extensions > cbx agent** and **Window > Extensions > cbxpanel**.

cbx agent needs one AI engine, signed in:
- **Claude Code** (Claude Pro/Max): `curl -fsSL https://claude.ai/install.sh | bash`, then run `claude` once and log in.
- **Codex** (ChatGPT Plus/Pro): `npm i -g @openai/codex`, then `codex login`.

The installer tells you which of these you already have.

## Requirements
- macOS (Apple silicon or Intel), After Effects 2022 or newer
- Node.js 18+ (installed automatically if missing, no admin password needed)

## Update / uninstall
- Update: run the install command again.
- Uninstall: `curl -fsSL https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/install.sh | bash -s -- --uninstall`

## Good to know
- The agent has full access: it runs scripts in After Effects and commands on your Mac. Use it on saved projects. Every prompt can be undone with **Undo this prompt**.
- Full manuals for both panels are inside the release zip (`payload/*/README.md`).
- Free to use. Not open source: no copying, modifying or redistributing (see LICENSE).
- Everything installs into your user folders (`~/Library/Application Support/cbx` and Adobe's per-user extension and plug-in folders).
