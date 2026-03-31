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

## CRITICAL：每個步驟的執行方式

每個步驟都 **MUST** 使用 **Skill tool** 呼叫對應的 skill，不可以自己 inline 執行。

**正確做法**：呼叫 Skill tool → `Skill(skill="speckit.specify", args="...")` → 讓 Skill prompt 引導執行
**錯誤做法**：自己讀 skill 描述然後手動做一樣的事

**為什麼**：每個 Skill 包含專門的 prompt、template、驗證邏輯和 extension hook 處理，inline 做會跳過這些。如果你沒有呼叫 Skill tool，你就是在違反這個工作流的規範。

---

## 判斷目前進度

先執行 `.specify/scripts/bash/check-prerequisites.sh --json` 檢查目前狀態：

- **沒有 `.specify/` 目錄** → 從 Step 1 開始
- **有 spec.md 但沒有 plan.md** → 從 Step 3 開始
- **有 plan.md 但沒有 tasks.md** → 從 Step 4 開始
- **有 tasks.md 但任務未完成** → 從 Step 6 開始
- **所有任務已完成但尚未做品質審查** → 從 Step 7 開始
- **品質審查已完成** → 到 Step 8 報告結果

---

## Step 1 — Specify

現在呼叫 Skill tool：`Skill(skill="speckit.specify", args="$ARGUMENTS")`

不要自己寫 spec。不要跳過這個 tool call。Skill 包含 template、驗證邏輯和 extension hook 處理。

完成後驗證 spec.md 已建立，然後告訴使用者：

```
✓ spec.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 2 繼續）
```

## Step 2 — Clarify

現在呼叫 Skill tool：`Skill(skill="speckit.clarify")`

不要自己判斷「不需要 clarify」而跳過。讓 Skill 自己決定是否有需要釐清的地方。

完成後告訴使用者：

```
✓ 需求已釐清，spec.md 已更新
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 3 繼續）
```

## Step 3 — Plan

現在呼叫 Skill tool：`Skill(skill="speckit.plan")`

不要自己寫 plan。Skill 包含架構模板和 codebase 探索邏輯。

完成後驗證 plan.md 已建立，然後告訴使用者：

```
✓ plan.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 4 繼續）
```

## Step 4 — Analyze

現在呼叫 Skill tool：`Skill(skill="speckit.analyze")`

不要跳過這步。這是交叉檢查 spec 和 plan 一致性的關鍵步驟。

完成後告訴使用者：

```
✓ 分析完成，文件已一致
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 5 繼續）
```

## Step 5 — Tasks

現在呼叫 Skill tool：`Skill(skill="speckit.tasks")`

不要自己手寫 tasks.md。Skill 會根據 plan.md 生成正確格式的任務清單（含 [P] 標記和檔案路徑）。

完成後驗證 tasks.md 已建立，然後告訴使用者：

```
✓ tasks.md 已建立
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 6 繼續）
```

## Step 6 — Implement

現在呼叫 Skill tool：`Skill(skill="speckit.implement-opt")`

不要自己寫實作程式碼。這個 Skill 會以 orchestrator 模式運作，用 Agent tool 開 sub-agent 執行每個任務，確保 fresh context。

完成後告訴使用者：

```
✓ 實作完成
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 7 繼續）
```

## Step 7 — Quality Review

實作完成後，依序執行品質審查。每個步驟都 **MUST** 使用 Skill tool 呼叫。

1. 呼叫 Skill tool：`Skill(skill="lean-unit-testing")` — 審查測試品質，移除 redundant/low-value tests
2. 呼叫 Skill tool：`Skill(skill="clean-ts")` — 審查 TypeScript 程式碼品質

如果是 SHOPLINE 專案（檢查 package.json 或 repo 名稱含 shopline），額外執行：
3. `Skill(skill="shopline-frontend-coding")` — 前端 coding standards
4. `Skill(skill="shopline-e2e-attributes")` — data-e2e-id 命名規範

完成後告訴使用者：

```
✓ 品質審查完成
→ 請執行 /clear 然後輸入：/feature（我會自動從 Step 8 繼續）
```

## Step 8 — 完成報告

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
- **每個步驟 MUST 使用 Skill tool 呼叫對應的 skill，絕對不要自己 inline 執行**
- **Step 6 (implement-opt) MUST 使用 Agent tool 開 sub-agent 執行實作，自己只做 orchestration**
- **Step 7 (Quality Review) MUST 使用 Skill tool 執行品質審查，不可跳過**
- **如果發現自己在寫實作程式碼而不是呼叫 Skill tool 或 spawn Agent，立即停下來重新閱讀指令**
