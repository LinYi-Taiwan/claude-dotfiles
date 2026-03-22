#!/bin/bash
set -e

CLAUDE_HOME="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$CLAUDE_HOME"

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
