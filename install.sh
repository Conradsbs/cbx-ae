#!/bin/bash
# cbx for After Effects (macOS): installs cbx agent (AI prompt bar) and cbxpanel (quick-action toolbar).
#
#   curl -fsSL https://raw.githubusercontent.com/conrad-rd/cbx-ae/main/install.sh | bash
#   ...or from the release zip:  bash install.sh
#   Update: run it again.   Uninstall: bash install.sh --uninstall
#
# Needs no administrator password. Touches only your user folders:
#   ~/Library/Application Support/cbx                          the two tools (+ Node.js if it had to be installed)
#   ~/Library/Application Support/Adobe/CEP/extensions        links so After Effects finds the panels
#   ~/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore   the cbx Shader + cbx Controls effects
#   the cbxpanel MCP entry in the agent apps you have (so your AI agent can edit cbxpanel; no skill is installed)
set -euo pipefail

REPO="conrad-rd/cbx-ae"
APP="$HOME/Library/Application Support/cbx"
EXT_DIR="$HOME/Library/Application Support/Adobe/CEP/extensions"
PLUGIN_DIR="$HOME/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore"
LOCAL_BIN="$HOME/.local/bin"

say()  { printf '  %-13s %s\n' "$1" "$2"; }
step() { printf '\n== %s\n' "$1"; }
die()  { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "This installer is for macOS. On Windows use cbx-agent/install.cmd."

node_ok() { [ -x "$1" ] && "$1" -e 'process.exit(+process.versions.node.split(".")[0] >= 18 ? 0 : 1)' 2>/dev/null; }
find_bin() { # <name>: the panel looks in these folders, then in your login shell's PATH
  local c
  for c in "$(command -v "$1" 2>/dev/null || true)" "/opt/homebrew/bin/$1" "/usr/local/bin/$1" "$LOCAL_BIN/$1" "$HOME/.npm-global/bin/$1"; do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  c="$(/bin/zsh -ilc "command -v $1" 2>/dev/null </dev/null | grep '^/' | tail -1 || true)"
  [ -n "$c" ] && [ -x "$c" ] && echo "$c"
  return 0
}

# ---------------------------------------------------------------- uninstall
if [ "${1:-}" = "--uninstall" ]; then
  step "Removing cbx"
  N=""; for c in "$(find_bin node)" "$APP/node/bin/node"; do node_ok "$c" && { N="$c"; break; }; done
  if [ -n "$N" ] && [ -f "$APP/cbxpanel/tools/setup-agents.sh" ]; then
    P="$(dirname "$N")"; for b in "$(find_bin claude)" "$(find_bin codex)"; do [ -n "$b" ] && P="$P:$(dirname "$b")"; done
    PATH="$P:$PATH" bash "$APP/cbxpanel/tools/setup-agents.sh" --uninstall >/dev/null 2>&1 || true
  fi
  for l in com.cbx.agent com.cbx.cbxpanel; do [ -L "$EXT_DIR/$l" ] && rm "$EXT_DIR/$l"; done
  rm -rf "$PLUGIN_DIR/cbx Shader.plugin" "$PLUGIN_DIR/cbx Controls.plugin"
  for b in node npm npx; do
    [ -L "$LOCAL_BIN/$b" ] && case "$(readlink "$LOCAL_BIN/$b")" in "$APP"/*) rm "$LOCAL_BIN/$b";; esac
  done
  rm -rf "$APP"
  echo "Removed. Restart After Effects."
  echo "Your chats and tiles were kept in ~/Library/Application Support/cbx agent and .../cbxpanel (delete them by hand if you want)."
  exit 0
fi

# ---------------------------------------------------------------- get the files
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
if [ -n "$HERE" ] && [ -d "$HERE/payload/cbx-agent/extension" ]; then
  SRC="$HERE/payload"
else
  step "Downloading cbx"
  curl -fsSL "https://github.com/$REPO/releases/latest/download/cbx-ae-mac.zip" -o "$TMP/cbx.zip" || die "Download failed. Check the internet connection and try again."
  ditto -x -k "$TMP/cbx.zip" "$TMP/x"
  SRC="$(echo "$TMP"/x/*/payload)"
  [ -d "$SRC/cbx-agent/extension" ] || die "The download didn't contain the payload folder."
fi

# ---------------------------------------------------------------- checks
step "Checking this Mac"
AE="$(ls -d /Applications/Adobe\ After\ Effects\ 20* 2>/dev/null | sort | tail -1 || true)"
if [ -n "$AE" ]; then say "After Effects" "$(basename "$AE")"; else say "After Effects" "not found in /Applications (installing anyway; needs AE 2022 or newer)"; fi

NODE=""
for c in "$(find_bin node)" "$APP/node/bin/node"; do node_ok "$c" && { NODE="$c"; break; }; done
if [ -z "$NODE" ]; then
  say "Node.js" "missing (needed, version 18+): installing it for this user..."
  ARCH="$(uname -m)"; [ "$ARCH" = "x86_64" ] && ARCH="x64"
  BASE="https://nodejs.org/dist/latest-v22.x"
  curl -fsSL "$BASE/SHASUMS256.txt" -o "$TMP/SHASUMS256.txt" || die "Couldn't reach nodejs.org to install Node.js."
  FILE="$(grep -o "node-v[0-9.]*-darwin-$ARCH\.tar\.gz" "$TMP/SHASUMS256.txt" | head -1)"
  [ -n "$FILE" ] || die "Couldn't find a Node.js build for darwin-$ARCH."
  curl -fsSL "$BASE/$FILE" -o "$TMP/$FILE"
  (cd "$TMP" && grep " $FILE\$" SHASUMS256.txt | shasum -a 256 -c - >/dev/null) || die "Node.js download failed its checksum."
  rm -rf "$TMP/node-x" && mkdir -p "$TMP/node-x" && tar -xzf "$TMP/$FILE" -C "$TMP/node-x" --strip-components 1
  mkdir -p "$APP" && rm -rf "$APP/node" && mv "$TMP/node-x" "$APP/node"
  mkdir -p "$LOCAL_BIN"
  for b in node npm npx; do [ -e "$LOCAL_BIN/$b" ] && [ ! -L "$LOCAL_BIN/$b" ] || ln -sfn "$APP/node/bin/$b" "$LOCAL_BIN/$b"; done
  NODE="$APP/node/bin/node"
fi
say "Node.js" "$("$NODE" -v)  ($NODE)"

# ---------------------------------------------------------------- install
step "Installing"
mkdir -p "$APP" "$EXT_DIR"
for t in cbx-agent cbxpanel; do
  rm -rf "$APP/$t.new"
  cp -R "$SRC/$t" "$APP/$t.new"
  xattr -dr com.apple.quarantine "$APP/$t.new" 2>/dev/null || true
  rm -rf "$APP/$t" && mv "$APP/$t.new" "$APP/$t"
done
for l in com.cbx.agent com.cbx.cbxpanel; do
  if [ -e "$EXT_DIR/$l" ] && [ ! -L "$EXT_DIR/$l" ]; then
    mv "$EXT_DIR/$l" "$TMP/" 2>/dev/null || die "$EXT_DIR/$l is an old copy that couldn't be replaced. Delete it and run this again."
    say "old copy" "replaced $l"
  fi
done

# cbx agent: CEP link, unsigned-extension switch, cbx Shader effect (its own installer).
PATH="$(dirname "$NODE"):$PATH" bash "$APP/cbx-agent/install.sh" >"$TMP/agent.log" 2>&1 || { cat "$TMP/agent.log"; die "cbx agent install failed."; }
# cbx Controls effect too, so one After Effects restart is enough (the panel would otherwise copy it on first use).
if [ -d "$APP/cbx-agent/extension/native/mac/cbx Controls.plugin" ]; then
  mkdir -p "$PLUGIN_DIR"
  rm -rf "$PLUGIN_DIR/cbx Controls.plugin.new"
  cp -R "$APP/cbx-agent/extension/native/mac/cbx Controls.plugin" "$PLUGIN_DIR/cbx Controls.plugin.new"
  rm -rf "$PLUGIN_DIR/cbx Controls.plugin" && mv "$PLUGIN_DIR/cbx Controls.plugin.new" "$PLUGIN_DIR/cbx Controls.plugin"
fi
say "cbx agent" "$(sed -n 's/.*ExtensionBundleVersion="\([^"]*\)".*/\1/p' "$APP/cbx-agent/extension/CSXS/manifest.xml")"

# cbxpanel: CEP link, data folder, MCP server for the agent apps on this Mac (older versions' cbxpanel skill is removed).
ln -sfn "$APP/cbxpanel/extension" "$EXT_DIR/com.cbx.cbxpanel"
for v in 9 10 11 12 13 14 15 16; do defaults write "com.adobe.CSXS.$v" PlayerDebugMode 1; done
"$NODE" "$APP/cbxpanel/tools/cli.js" init >/dev/null
# Agent CLIs installed moments ago may not be on this shell's PATH yet; give their folders to the setup step.
CLAUDE="$(find_bin claude)"; CODEX="$(find_bin codex)"
AGENT_PATH="$(dirname "$NODE")"
for b in "$CLAUDE" "$CODEX"; do [ -n "$b" ] && AGENT_PATH="$AGENT_PATH:$(dirname "$b")"; done
PATH="$AGENT_PATH:$PATH" bash "$APP/cbxpanel/tools/setup-agents.sh" >"$TMP/agents.log" 2>&1 || { cat "$TMP/agents.log"; die "cbxpanel MCP setup failed."; }
APPS="$(sed -n 's/^mcp  *\([^:]*\)$/\1/p' "$TMP/agents.log" | paste -sd, - | sed 's/,/, /g')"
say "cbxpanel" "$(sed -n 's/.*ExtensionBundleVersion="\([^"]*\)".*/\1/p' "$APP/cbxpanel/extension/CSXS/manifest.xml")  (MCP for: ${APPS:-no agent apps found})"

# ---------------------------------------------------------------- AI engines
step "AI engine (cbx agent needs at least one, signed in)"
AI_READY=0
if [ -n "$CLAUDE" ]; then
  if "$CLAUDE" auth status --json 2>/dev/null </dev/null | grep -q '"loggedIn": *true'; then
    say "Claude Code" "ready ($("$CLAUDE" --version 2>/dev/null | head -1))"; AI_READY=1
  else
    say "Claude Code" "installed, NOT signed in -> run: claude   (in Terminal, once, and log in)"
  fi
else
  say "Claude Code" "not installed -> curl -fsSL https://claude.ai/install.sh | bash   then run: claude"
fi
if [ -n "$CODEX" ]; then
  if "$CODEX" login status </dev/null 2>&1 | grep -qi 'logged in'; then
    say "Codex (GPT)" "ready"; AI_READY=1
  else
    say "Codex (GPT)" "installed, NOT signed in -> run: codex login"
  fi
else
  say "Codex (GPT)" "not installed (optional) -> npm i -g @openai/codex   then: codex login"
fi

# ---------------------------------------------------------------- next steps
step "Next"
if pgrep -qf "Adobe After Effects 20[0-9][0-9].app/Contents/MacOS"; then
  echo "  1. After Effects is open: save your work, quit it and open it again (it only loads new panels at launch)."
else
  echo "  1. Open After Effects."
fi
echo "  2. Window > Extensions > cbx agent   (the AI prompt bar; dock it wherever you like)"
echo "     Window > Extensions > cbxpanel    (the quick-action toolbar)"
[ $AI_READY = 1 ] || echo "  !  Sign in to Claude Code or Codex first (see above), otherwise cbx agent can't answer."
echo
echo "CBX_INSTALL_OK ai_ready=$AI_READY"
