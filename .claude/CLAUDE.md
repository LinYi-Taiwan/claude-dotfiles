@RTK.md

## Agent 工具使用紀律

內建系統指令有兩條互相衝突的規則：
1. "For broader codebase exploration and deep research, use the Agent tool with subagent_type=Explore"
2. "If the target is already known, use the direct tool: Read for a known path"

**永遠優先套用第 2 條。** 在開任何 Agent 之前，先問自己：「我能不能用 3-5 次 Read/Grep/WebFetch 直接完成？」如果可以，就不要開 Agent。

具體規則：
- 本地專案的檔案（App.tsx, package.json, target.md 等）→ 直接 Read，絕對不開 Agent
- 已知路徑或已知關鍵字的搜尋 → 直接 Grep/Glob
- Agent 會產生 cascading sub-agents（子 agent 再開子 agent），浪費大量 token 且難以控制
- 只有在真正不知道要找什麼、需要大範圍探索時才考慮開 Agent
