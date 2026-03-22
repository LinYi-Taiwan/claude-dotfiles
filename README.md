# Claude Code Dotfiles

個人 Claude Code 設定，跨機器、跨專案統一管理。

## 包含什麼

| 路徑 | 說明 |
|------|------|
| `settings.json` | 全域權限、plugins、marketplace 設定 |
| `commands/` | Slash commands（speckit、workflow） |
| `skills/` | 自訂 skills（vercel-react-best-practices 等） |

## 新機器 / 新公司設定

```bash
# 1. Clone
git clone <your-repo-url> ~/claude-dotfiles

# 2. 執行 setup
cd ~/claude-dotfiles
./setup.sh
```

`setup.sh` 會把 `~/.claude/settings.json`、`commands/`、`skills/` 用 symlink 指向這個 repo。如果原本已有設定，會自動備份成 `.bak`。

## 日常修改

因為是 symlink，所以不管你改 `~/.claude/settings.json` 還是改 `~/claude-dotfiles/settings.json`，都是同一個檔案。

```bash
# 改完設定後
cd ~/claude-dotfiles
git add -A
git commit -m "update: ..."
git push
```

## 其他機器同步

```bash
cd ~/claude-dotfiles
git pull
```

因為是 symlink，pull 下來就直接生效，不用再跑 `setup.sh`。

## 注意事項

- `settings.local.json` 不會進 repo（已加入 `.gitignore`），各機器的一次性權限、token 等留在本地
- 各專案的 `.claude/CLAUDE.md` 是專案層級設定，不在這裡管理
- 如果新公司有自己的 Claude Code 設定，可以先跑 `setup.sh`，再手動合併衝突的部分
