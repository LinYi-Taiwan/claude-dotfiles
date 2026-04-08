#!/bin/bash
set -e

CLAUDE_HOME="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_PLUGINS_DIR="$SCRIPT_DIR/plugins"

mkdir -p "$CLAUDE_HOME"

# Generate settings.json from template (replace local plugins path)
sed "s|__LOCAL_PLUGINS_PATH__|$LOCAL_PLUGINS_DIR|g" \
  "$SCRIPT_DIR/settings.template.json" > "$SCRIPT_DIR/settings.json"

# Backup existing settings.json if it's not already a symlink
if [ -e "$CLAUDE_HOME/settings.json" ] && [ ! -L "$CLAUDE_HOME/settings.json" ]; then
  echo "Backing up existing $CLAUDE_HOME/settings.json -> $CLAUDE_HOME/settings.json.bak"
  mv "$CLAUDE_HOME/settings.json" "$CLAUDE_HOME/settings.json.bak"
fi

# Symlink settings.json (single file, always from dotfiles)
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_HOME/settings.json"

# Symlink statusline script
if [ -f "$SCRIPT_DIR/.claude/statusline.sh" ]; then
  ln -sf "$SCRIPT_DIR/.claude/statusline.sh" "$CLAUDE_HOME/statusline.sh"
fi

# For directories (skills, commands, .agents): create real directories and
# symlink individual items inside. This allows the local machine to add its
# own items without polluting the dotfiles repo.
for dir in commands skills .agents; do
  src="$SCRIPT_DIR/$dir"
  dest="$CLAUDE_HOME/$dir"

  # If dest is currently a symlink to the dotfiles dir, remove it
  if [ -L "$dest" ]; then
    rm "$dest"
  fi

  mkdir -p "$dest"

  # Skip if source dir doesn't exist in dotfiles
  [ -d "$src" ] || continue

  # Symlink each item from dotfiles into the real directory
  for item in "$src"/*; do
    [ -e "$item" ] || continue
    item_name="$(basename "$item")"
    target="$dest/$item_name"

    # Don't overwrite local (non-symlink) items
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Skipping $target (local override exists)"
      continue
    fi

    ln -sfn "$item" "$target"
  done
done

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
