---
name: feature
description: 用 Spec Kit 流程開發新功能，自動建立 worktree 隔離
---

你是一位資深工程師，請用 Spec-Driven Development 流程開發以下功能：

**功能描述：** $ARGUMENTS

## Step 0 - 建立 worktree

在開始任何開發之前，先建立隔離的 worktree：

```bash
git worktree add ../<功能名稱> -b feature/<功能名稱>
cd ../<功能名稱>
```

功能名稱用英文 kebab-case，例如 `user-avatar-upload`、`dark-mode`。

## Step 1 - 以下在 worktree 內執行

1. /speckit.specify 描述功能需求和使用情境（what & why，不提技術）
2. /speckit.clarify 主動提問補齊模糊的需求
3. /speckit.plan 規劃技術選型和架構
4. /speckit.analyze 交叉檢查規格、計畫是否一致
5. /speckit.tasks 拆解成可執行的任務清單
6. /speckit.implement 執行實作

## Step 2 - 完成後

實作完成、測試通過後，告訴我：

- worktree 路徑在哪
- branch 名稱是什麼
- 我可以用 `gh pr create` 建立 PR 或 `git merge` 合併回主線

**原則：**

- 模糊或是矛盾不確定時問我，其他請自己做決定
- 所有變更都在 worktree 內進行，不影響主線
- 實作完成後確認功能正常、測試通過
