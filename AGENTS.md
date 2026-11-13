# Installing cbx for After Effects (instructions for an AI agent)

You are installing two After Effects panels on this user's Mac:
- **cbx agent**: an AI prompt bar inside After Effects (runs Claude Code or Codex with the user's own login).
- **cbxpanel**: a quick-action toolbar (KBar-style) with its own MCP server.

Everything is prebuilt. The installer needs no admin password and only writes to the user's own Library folders, `~/.local/bin` (Node.js, only if missing) and agent-app config (cbxpanel skill + MCP entry).

## Steps
1. Run the installer and read its whole output:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/install.sh | bash
   ```
   (If you cloned this repo, `bash install.sh` does the same from the local copy.)
   It ends with `CBX_INSTALL_OK ai_ready=1` (all good) or `ai_ready=0` (no signed-in AI engine yet). Any `ERROR:` line says what to fix; fix it and run it again.
2. If `ai_ready=0`, cbx agent needs Claude Code or Codex, signed in:
   - Claude Code missing: run `curl -fsSL https://claude.ai/install.sh | bash`.
   - Signing in is a browser login only the user can do. Ask them to open Terminal and run `claude` (or `codex login` for GPT) and finish the login, then run the installer once more to confirm `ai_ready=1`.
   - If you are Claude Code or Codex yourself, the user is probably already signed in: the installer checks it.
3. After Effects only loads new panels at launch. If it is open, ask the user to save and restart it. Do not quit it for them (unsaved work).
4. Tell the user, briefly: open **Window > Extensions > cbx agent** and **Window > Extensions > cbxpanel**, dock them, then select a layer in cbx agent and type what they want ("make this bounce in", "rig a wiggle control").

## Good to know
- Update: run the same command again. Uninstall: `curl -fsSL https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/install.sh | bash -s -- --uninstall`.
- cbxpanel's narrow-panel sizing optionally wants Screen Recording permission for After Effects (System Settings > Privacy & Security). The panel works without it.
- Requirements: macOS, After Effects 2022 or newer. Node.js 18+ is installed automatically if missing.
- Do not change anything else on the Mac. Do not edit the files under `~/Library/Application Support/cbx`; they are replaced on update.
