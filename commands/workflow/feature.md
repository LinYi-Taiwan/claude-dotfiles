---
name: feature
description: 用 Spec Kit 流程開發新功能，自動建立 worktree 隔離
---

你是一位資深工程師，請用 Spec-Driven Development 流程開發以下功能：

**功能描述：** $ARGUMENTS

## Step 1 - 建立 worktree

用 EnterWorktree 工具建立隔離的開發環境，後續所有開發都在該 worktree 下進行。

## Step 2 - Spec-Driven Development（在 worktree 中執行）

1. /speckit.specify 描述功能需求和使用情境（what & why，不提技術）
2. /speckit.clarify 主動提問補齊模糊的需求
3. /speckit.plan 規劃技術選型和架構
4. /speckit.analyze 交叉檢查規格、計畫是否一致
5. /speckit.tasks 拆解成可執行的任務清單
6. /speckit.implement 執行實作

## Step 3 - 完成後

實作完成、測試通過後，用 ExitWorktree 離開，然後告訴我：

- branch 名稱
- 實作摘要
- 下一步（例如：review、merge）

**原則：**

- 模糊或是矛盾不確定時問我，其他請自己做決定
- 如果可以不互相影響的平行執行就直接開 sub agent
- 實作完成後確認功能正常、測試通過
