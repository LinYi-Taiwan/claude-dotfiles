---
name: feature
description: 用 Spec Kit 流程開發新功能，每步驟間 /clear 節省 token
---

你是一位資深工程師，請用 Spec-Driven Development 流程開發功能。

**功能描述：** $ARGUMENTS

---

## 執行方式

這個流程分成多個步驟，每個步驟執行完後請 `/clear` 再繼續下一步，以節省 token。
所有中間產物都會寫入 `.specify/` 目錄，`/clear` 後不會遺失。

---

## 判斷目前進度

先執行 `.specify/scripts/bash/check-prerequisites.sh --json` 檢查目前狀態：

- **沒有 `.specify/` 目錄** → 從 Step 1 開始
- **有 spec.md 但沒有 plan.md** → 從 Step 3 開始
- **有 plan.md 但沒有 tasks.md** → 從 Step 4 開始
- **有 tasks.md 但任務未完成** → 從 Step 6 開始
- **所有任務已完成** → 到 Step 7 報告結果

---

## Step 1 — Specify

執行 `/speckit.specify` 描述功能需求和使用情境（what & why，不提技術）。

完成後告訴使用者：

```
✓ spec.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 2 繼續）
```

## Step 2 — Clarify

執行 `/speckit.clarify` 主動提問補齊模糊的需求。

完成後告訴使用者：

```
✓ 需求已釐清，spec.md 已更新
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 3 繼續）
```

## Step 3 — Plan

執行 `/speckit.plan` 規劃技術選型和架構。

完成後告訴使用者：

```
✓ plan.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 4 繼續）
```

## Step 4 — Analyze

執行 `/speckit.analyze` 交叉檢查規格、計畫是否一致。

完成後告訴使用者：

```
✓ 分析完成，文件已一致
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 5 繼續）
```

## Step 5 — Tasks

執行 `/speckit.tasks` 拆解成可執行的任務清單。

完成後告訴使用者：

```
✓ tasks.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 6 繼續）
```

## Step 6 — Implement

執行 `/speckit.implement-opt` 執行實作（用 sub-agent 保持 fresh context）。

## Step 7 — 完成報告

實作完成、測試通過後，告訴使用者：

- branch 名稱
- 實作摘要
- 改了哪些檔案

---

## 原則

- 模糊或是矛盾不確定時問我，其他請自己做決定
- 如果可以不互相影響的平行執行就直接開 sub agent
- 實作完成後確認功能正常、測試通過
- **每個步驟完成後提醒使用者 `/clear`，不要自動繼續下一步**
