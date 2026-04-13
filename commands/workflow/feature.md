---
name: feature
description: 用 Spec Kit 流程開發新功能，自動 orchestrate 各步驟（每步驟 fresh context）
---

你是一位資深工程師，請用 Spec-Driven Development 流程開發功能。

**功能描述：** $ARGUMENTS

---

## 執行方式

這個流程使用 **orchestrator 模式**：你負責流程控制，每個步驟用 **Agent tool** 開 sub-agent 執行。
每個 sub-agent 擁有 fresh context，確保品質不因 context 累積而下降。
所有中間產物寫入 `.specify/` 目錄，sub-agent 之間透過檔案傳遞狀態。

**不要停下來等使用者確認，完成一步就直接開下一步的 sub-agent。**

---

## 判斷目前進度

先執行 `.specify/scripts/bash/check-prerequisites.sh --json` 檢查目前狀態：

- **沒有 `.specify/` 目錄** → 從 Step 1 開始
- **有 spec.md 但沒有 plan.md** → 從 Step 2 開始
- **有 plan.md 但沒有 tasks.md** → 從 Step 2 開始
- **有 tasks.md 但任務未完成** → 從 Step 3 開始
- **所有任務已完成但尚未做品質審查** → 從 Step 4 開始
- **品質審查已完成** → 到 Step 5 報告結果

---

## Step 1 — Specify + Clarify

開一個 Agent，給它以下指令：

> 你是資深工程師。請依序執行：
> 1. 呼叫 Skill tool：`Skill(skill="speckit.specify", args="$ARGUMENTS")`
>    完成後驗證 spec.md 已建立。
> 2. 呼叫 Skill tool：`Skill(skill="speckit.clarify")`
>    讓 Skill 決定是否需要 clarify。
>
> 兩步都必須透過 Skill tool 呼叫，不要自己寫 spec 或判斷 clarify。完成後回報結果。

確認 spec.md 存在後，直接進入 Step 2。

## Step 2 — Plan + Analyze + Tasks

開一個 Agent，給它以下指令：

> 你是資深工程師。請依序執行：
> 1. 呼叫 Skill tool：`Skill(skill="speckit.plan")`
>    完成後驗證 plan.md 已建立。
> 2. 呼叫 Skill tool：`Skill(skill="speckit.analyze")`
>    這是交叉檢查 spec 和 plan 一致性的關鍵步驟，不可跳過。
> 3. 呼叫 Skill tool：`Skill(skill="speckit.tasks")`
>    完成後驗證 tasks.md 已建立。
>
> 每步都必須透過 Skill tool 呼叫，不要自己手寫任何產物。完成後回報結果。

確認 tasks.md 存在後，直接進入 Step 3。

## Step 3 — Implement

你自己作為 orchestrator 直接執行實作，**不要開中間 Agent 轉手**。

你自己不寫任何實作程式碼。你的職責：解析 tasks → 分組 waves → spawn sub-agents → 收集結果 → 更新 tasks.md。

### 3.1 準備

1. 執行 `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` 取得 FEATURE_DIR 和 AVAILABLE_DOCS。
2. 如果 FEATURE_DIR/checklists/ 存在，檢查所有 checklist 是否完成。有未完成的就問使用者是否繼續。
3. 讀取 tasks.md 取得完整任務清單。
4. 記下 context 檔案路徑（plan.md, spec.md, data-model.md, contracts/, research.md 等），sub-agents 會自己讀。

### 3.2 解析 tasks.md 為 execution waves

- 提取所有 phases（e.g., "Phase 1 - Setup", "Phase 2 - Core"）
- 每個 phase 內，提取 tasks 的 ID、描述、檔案路徑、`[P]` 標記
- 分組：
  - **Sequential tasks**（無 `[P]`）：每個 task 一個 wave
  - **Parallel tasks**（連續 `[P]`）：合併為一個 parallel wave
  - **Same-file constraint**：即使標 `[P]`，碰同一檔案的 tasks 必須 sequential
- 輸出 execution plan 讓使用者看到進度

### 3.3 逐 wave 執行

**Sequential tasks** — 直接開 Agent（使用 `subagent_type="speckit-executor"`）：

```
Agent(
  subagent_type="speckit-executor",
  prompt="
<task>
Implement the following speckit tasks for feature: {feature_name}
</task>

<files_to_read>
- {FEATURE_DIR}/plan.md
- {FEATURE_DIR}/spec.md
- {FEATURE_DIR}/data-model.md (if exists)
- {FEATURE_DIR}/contracts/ (if exists)
- {FEATURE_DIR}/research.md (if exists)
- CLAUDE.md (if exists)
</files_to_read>

<tasks>
{task ID, description, and file paths — copied from tasks.md}
</tasks>

<success_criteria>
- [ ] All tasks implemented
- [ ] Each task committed individually
- [ ] Code follows plan.md architecture
- [ ] If tests were written: no redundant or low-value tests
- [ ] TypeScript code: no `any`, proper types, readable and maintainable
</success_criteria>
"
)
```

**Parallel tasks** — 同一個 message 開多個 Agents，每個加 `isolation: "worktree"`：

```
# MUST send all Agent tool calls in ONE message
Agent(
  subagent_type="speckit-executor",
  isolation="worktree",
  prompt="<task>...</task> <files_to_read>...</files_to_read> <tasks>{single task}</tasks>"
)
Agent(
  subagent_type="speckit-executor",
  isolation="worktree",
  prompt="<task>...</task> <files_to_read>...</files_to_read> <tasks>{another task}</tasks>"
)
```

**每個 wave 完成後**：
- 更新 tasks.md：標記完成的 tasks 為 `[X]`
- 失敗的 sequential task → 停止並報告
- 失敗的 parallel task → 繼續其他，報告失敗
- 顯示進度

### 3.4 完成驗證

- 確認所有 tasks 都標為 `[X]`
- 確認實作符合 spec
- 確認測試通過

完成後直接進入 Step 4。

## Step 4 — Quality Review

開一個 Agent，給它以下指令：

> 你是資深工程師。請依序執行品質審查，每個步驟都必須使用 Skill tool 呼叫：
> 1. `Skill(skill="lean-unit-testing")` — 審查測試品質
> 2. `Skill(skill="clean-ts")` — 審查 TypeScript 程式碼品質
>
> 如果是 SHOPLINE 專案（檢查 package.json 或 repo 名稱含 shopline），額外執行：
> 3. `Skill(skill="shopline-frontend-coding")`
> 4. `Skill(skill="shopline-e2e-attributes")`
>
> 完成後回報結果。

### Step 4.5 — Playwright MCP Self-QA（有 UI 變更時）

檢查 Step 3 修改的檔案中是否包含 UI 檔案（`.tsx`, `.jsx`, `.vue`, `.html`, `.liquid`, `.erb`, `.svelte`）。

**如果有 UI 變更**，開一個 Agent，給它以下指令：

> 你是 QA 工程師。請使用 Playwright MCP tools 驗證剛實作的 UI 功能。
>
> **前置條件**：先讀取 `.specify/spec.md` 了解功能需求和 user journey。
>
> **驗證流程**：
> 1. 確認 dev server 已在執行（嘗試用 Playwright MCP 導航到 baseURL，如果失敗就提醒使用者啟動 server）
> 2. 根據 spec.md 描述的核心 user journey，用 Playwright MCP 逐步操作：
>    - 導航到受影響的頁面
>    - 執行主要互動流程（填表單、點按鈕、檢查回饋）
>    - 對每個關鍵狀態截圖
> 3. 驗證結果：
>    - 頁面是否正常渲染（無 crash、無空白）
>    - 核心互動是否有預期回饋
>    - 錯誤狀態是否正確顯示
>
> **輸出格式**：
> ```
> ## Playwright Self-QA 結果
>
> | 驗證項目 | 結果 | 備註 |
> |---------|------|------|
> | 頁面渲染 | PASS/FAIL | ... |
> | [user journey 1] | PASS/FAIL | ... |
> | [user journey 2] | PASS/FAIL | ... |
>
> 截圖：[列出截圖路徑]
> ```
>
> 如果有 FAIL，詳細描述問題和重現步驟。

**如果沒有 UI 變更**，跳過此步驟。

完成後直接進入 Step 5。

## Step 5 — 完成報告

自己直接輸出（不需要開 Agent）：

- branch 名稱
- 實作摘要
- 改了哪些檔案

---

## 原則

- 模糊或是矛盾不確定時問使用者，其他自己做決定
- **Step 1、2、4 用 Agent tool 開 sub-agent 執行，確保 fresh context**
- **Step 3 由你自己 orchestrate，直接 spawn speckit-executor sub-agents，不要再包一層 Agent**
- **不要停下來等使用者確認，完成一步就直接繼續下一步**
- **每個 sub-agent 內 MUST 使用 Skill tool 呼叫對應的 skill，不可 inline 執行**
- 如果可以平行執行的步驟就平行開 sub-agent（但大部分步驟有依賴關係需循序執行）
- 實作完成後確認功能正常、測試通過
