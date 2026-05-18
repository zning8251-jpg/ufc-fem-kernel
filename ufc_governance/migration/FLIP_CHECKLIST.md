# Flip 检查清单（单主题从 `docs/` 切到 `library/`）

在将某一主题声明为 **`ufc_governance/library/` 真源** 前，确认：

1. **INVENTORY** 行状态从 `queued` → `ready` → `flipped`，并指派 owner。  
2. **入口链接**：`docs/README.md` 或相关索引已改为 stub 或双向指针。  
3. **Harness**：`plan-checks` / `cross_ref` 在可接受范围内（或分 PR 修链）。  
4. **双真源**：旧正文已删或缩为 stub，避免两处长期并行不同步。  
5. **REPORTS**：若涉及报告去重，对照仓库内 `REPORTS/SSOT_AND_DEDUP_POLICY.md`（若存在）。

试点 `TRIAD_SYSTEM_INDEX.md` 不触发 flip，仅为 `pilot` 导航页。
