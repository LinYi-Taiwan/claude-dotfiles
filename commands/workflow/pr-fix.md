---
name: pr-fix
description: 回應 PR reviewer 意見：評估 comments、必要時實作修改、產生回覆
---

你是一位資深工程師，請處理 PR 上收到的 reviewer comments。

**參數：** $ARGUMENTS

---

## Step 0 - 取得 PR

1. 用 `git config user.email` 取得當前使用者 email
2. 用 `git remote -v` 取得 repo 的 workspace 和 repo slug

**如果有參數：**
- 參數是 PR URL → 解析出 workspace、repo slug、PR number
- 參數是數字 → 當作 PR number

**如果沒參數：**
- 用 Bitbucket MCP `getPullRequests` 查當前 repo 的 open PR
- 過濾出 author 是自己的 PR
- 用 `getPullRequestComments` 檢查哪些有 unresolved comment
- 列出有 comment 的 PR 讓使用者選擇
- 如果只有一個，直接使用

---

## Step 1 - 讀取 comments

1. `getPullRequestComments` 取得所有 reviewer comments
2. 過濾出 unresolved / open 的 comments（排除自己留的）
3. `getPullRequestDiff` 取得 PR diff，理解每個 comment 對應的 code context
4. 如果沒有未處理的 comment → 告知「沒有需要處理的 reviewer comment」並結束

---

## Step 2 - 評估（最重要的步驟）

**不要急著開發，先評估每一個 comment。**

閱讀每個 comment + 對應的 code，分成四類：

| 分類 | 說明 |
|------|------|
| 需實作 | 同意，需要改 code |
| 小修 | 同意，小改（命名、typo、格式） |
| 回覆解釋 | 不同意或不需要改，需要解釋理由 |
| 問使用者 | 不確定，需要使用者判斷 |

**列出完整評估表給使用者確認，格式如下：**

```
## 評估結果

### 需實作
- Comment #1: "建議把 X 改成 Y" → 同意，Y 的做法更好
  檔案：src/foo.ts:42

### 小修
- Comment #3: "typo: recieve → receive" → 直接修
  檔案：src/bar.ts:15

### 回覆解釋
- Comment #2: "為什麼不用 Z？" → 因為 Z 不支援 ABC 情境

### 問使用者
- Comment #4: "考慮加上 error handling" → 不確定這邊的 scope

請確認評估，或調整分類後繼續。
```

**等使用者確認後才進入 Step 3。** 使用者可能會覆寫判斷。

---

## Step 3 - 實作修改

**僅在有「需實作」或「小修」項目時執行。如果全部都是「回覆解釋」，跳到 Step 4。**

1. 取得 PR 的 source branch 名稱
2. 建 worktree（基於 PR 的 source branch）
3. 根據修改性質決定做法：
   - **小修**（命名、typo、格式）→ 直接改，不需要跑流程
   - **Bug fix 性質** → 參考 bug.md 的「快速修復流程」：只改必要的地方，確認沒有 regression
   - **Feature 增強性質** → 參考 feature.md 的 speckit 流程來規劃和實作
4. commit message 格式：`fix(pr): {comment 摘要}`

---

## Step 4 - 產生回覆 markdown

在主 repo（不是 worktree）建立 `pr-responses/{PR-number}.md`：

```markdown
# PR #{number} - {title} 回覆

## Comment 1 - @{reviewer}
> {reviewer 原始 comment}

**回覆：** {給 reviewer 看的回覆文字}
**處理方式：** 已修改 / 不需修改
{如有改 code：**變更：** 簡述改了什麼}

---

## Comment 2 - @{reviewer}
...
```

---

## Step 5 - 報告

告訴使用者：

- 評估摘要：幾個需實作 / 幾個小修 / 幾個回覆解釋
- worktree branch 名稱和路徑（如果有實作）
- `pr-responses/{PR-number}.md` 位置
- 接下來你要做的：
  1. 看 `pr-responses/` 的回覆內容，調整語氣或補充
  2. 如果有 worktree，決定是否 merge 修改
  3. 決定是否 push 並在 PR 上逐一留言回覆

---

## 原則

- **評估優先**：不要看到 comment 就急著改，先判斷需不需要
- **不確定就問**：不猜 reviewer 的意圖
- **不需要改就不改**：寫清楚理由即可
- **回覆語氣專業友善**
- **worktree 基於 PR branch**，不是 main
