#!/bin/bash
set -e

CLAUDE_HOME="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_PLUGINS_DIR="$SCRIPT_DIR/plugins"

mkdir -p "$CLAUDE_HOME"

# Generate settings.json from template (replace local plugins path)
sed "s|__LOCAL_PLUGINS_PATH__|$LOCAL_PLUGINS_DIR|g" \
  "$SCRIPT_DIR/settings.template.json" > "$SCRIPT_DIR/settings.json"

# Backup existing files if they're not already symlinks
for item in settings.json commands skills; do
  target="$CLAUDE_HOME/$item"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
done

# Symlink
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_HOME/settings.json"
ln -sfn "$SCRIPT_DIR/commands" "$CLAUDE_HOME/commands"
ln -sfn "$SCRIPT_DIR/skills" "$CLAUDE_HOME/skills"

echo "Claude dotfiles linked to $CLAUDE_HOME"

# Install plugins (requires `claude` CLI)
if command -v claude &> /dev/null; then
  echo "Installing plugins..."
  PLUGINS=(
    "ralph-wiggum"
    "ralph-loop"
    "feature-dev"
    "frontend-design"
    "issue-to-dev@local-plugins"
    "developer-kit-typescript@developer-kit"
    "github-spec-kit@developer-kit"
  )
  for plugin in "${PLUGINS[@]}"; do
    echo "  Installing $plugin..."
    claude plugins install "$plugin" 2>/dev/null || echo "  ⚠ Failed to install $plugin"
  done
  echo "Plugins installed."
else
  echo "⚠ claude CLI not found — install Claude Code first, then re-run this script."
fi
