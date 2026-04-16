---
description: Execute the implementation plan using sub-agents with fresh context for each task group, preventing context-induced quality degradation
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before implementation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_implement` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## MANDATORY：Sub-Agent 執行模式

你是 **orchestrator**，不是 implementor。你自己不寫任何實作程式碼。

- 你 MUST 使用 `Agent(...)` 開 sub-agent 執行任務
- 你自己 **絕對不呼叫 Write/Edit 建立或修改應用程式檔案**
- 你的職責：解析 tasks → 分組 waves → spawn agents → 收集結果 → 更新 tasks.md
- 不是你的職責：寫應用程式碼、建立檔案、實作功能

如果你發現自己在寫實作程式碼，**立即停下**，改用 Agent tool 開 sub-agent。

---

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load **only metadata** for orchestration (do NOT read full file contents into this context):
   - **REQUIRED**: Read tasks.md for the complete task list
   - Note the paths of these context files (sub-agents will read them themselves):
     - plan.md, spec.md (always pass to sub-agents)
     - data-model.md, contracts/, research.md, quickstart.md (pass if they exist)

4. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `*.dll`, `autom4te.cache/`, `config.status`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. **Parse tasks.md into execution groups**:
   - Extract all phases (e.g., "Phase 1 - Setup", "Phase 2 - Core", etc.)
   - Within each phase, extract tasks with their IDs, descriptions, file paths, and `[P]` markers
   - Group tasks into execution units:
     - **Sequential tasks** (no `[P]`): Each task becomes its own execution unit, run in order
     - **Parallel tasks** (consecutive `[P]` marked tasks): Grouped into one parallel execution unit
     - **Same-file constraint**: Even if marked `[P]`, tasks touching the same file path must run sequentially
   - Output the execution plan for user visibility:

     ```text
     ## Execution Plan

     Phase 1 - Setup (3 tasks)
       Wave 1: T001 (sequential)
       Wave 2: T002, T003 (parallel)

     Phase 2 - Core (4 tasks)
       Wave 3: T004 (sequential)
       Wave 4: T005 (sequential, depends on T004)
       Wave 5: T006, T007 (parallel)
     ```

6. **Execute phase-by-phase using sub-agents**:

   **REMINDER: You are the orchestrator. You MUST use the Agent tool to spawn sub-agents. You do NOT write implementation code yourself.**

   For each phase, for each wave:

   **For sequential tasks** — call the Agent tool:
   ```
   Agent(
     model="sonnet",
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
   - [ ] If tests were written: no redundant or low-value tests (each test covers a distinct, meaningful scenario)
   - [ ] TypeScript code: no `any`, proper types, readable and maintainable
   </success_criteria>
   "
   )
   ```

   **For parallel tasks** — spawn multiple Agents simultaneously in a SINGLE message, each with `isolation: "worktree"`:
   ```
   # You MUST send all these Agent tool calls in ONE message (not sequentially)
   Agent(
     model="sonnet",
     isolation="worktree",
     prompt="<task>...</task> <files_to_read>...</files_to_read> <tasks>{single task}</tasks>"
   )
   Agent(
     model="sonnet",
     isolation="worktree",
     prompt="<task>...</task> <files_to_read>...</files_to_read> <tasks>{another task}</tasks>"
   )
   ```

   **After each wave completes**:
   - Parse each sub-agent's completion report
   - Update tasks.md: mark completed tasks as `[X]`
   - If any task FAILED:
     - For sequential tasks: halt and report the failure to the user
     - For parallel tasks: continue with successful ones, report failures
   - Display progress:

     ```text
     ## Progress: Phase 2 - Core
     ✓ T004 Create user model
     ✓ T005 Create user service
     ✗ T006 Add validation (error: missing dependency)
     ⧖ T007 Wire routes (pending - blocked by T006)
     ```

   **Proceed to next phase only after all tasks in current phase are complete.**

7. **Completion validation**:
   - Verify all required tasks are completed (all marked `[X]` in tasks.md)
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Report final status with summary of completed work

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.

8. **Check for extension hooks**: After completion validation, check if `.specify/extensions.yml` exists in the project root.
   - If it exists, read it and look for entries under the `hooks.after_implement` key
   - If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
   - Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
   - For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
     - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
     - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
   - For each executable hook, output the following based on its `optional` flag:
     - **Optional hook** (`optional: true`):
       ```
       ## Extension Hooks

       **Optional Hook**: {extension}
       Command: `/{command}`
       Description: {description}

       Prompt: {prompt}
       To execute: `/{command}`
       ```
     - **Mandatory hook** (`optional: false`):
       ```
       ## Extension Hooks

       **Automatic Hook**: {extension}
       Executing: `/{command}`
       EXECUTE_COMMAND: {command}
       ```
   - If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently
