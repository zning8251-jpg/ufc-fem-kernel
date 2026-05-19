# Design: p1-material-wave3-plast-loc

## Scope

| 项 | 值 |
|----|-----|
| **pillar_id** | P1 Material |
| **layers** | L4_PH（本波仅实现层） |
| **domain path** | `ufc_core/L4_PH/Material/Plast/` |
| **wave** | W1 / 波次1 · MR-W1-04 延续 |

---

## Methodology to UFC mapping (normative for this change)

| 方法论项 | 本变更 UFC 落点 | 验收挂钩 |
|----------|-----------------|----------|
| Desc | `PH_Mat_Plast_Def` · `MD_Mat_PLM_J2_Desc` 引用 | G2, CONTRACT |
| State | `PH_Mat_PLM_J2_State` / MatPoint 打包 | G2 |
| Algo | `PH_Mat_Plast_J2_Iso_Core` 径向回归/屈服 | G4 `_Loc` `_Eval` |
| Ctx | `PH_Mat_Krnl_Ctx` / UMAT context | G2, 热路径无堆分配 |
| Args | `PH_Mat_Plast_Eval_Args` 或 `PH_J2_*_Arg` 新 TYPE | G3, intf001 一致 |
| 主从 | `PH_Mat_Plast_Core` / Eval → J2 Iso/UMAT 核 | CONTRACT Dispatch 表 |
| 空间 Loc | IP 级 `PH_Mat_PLM_J2_UpdateStress` | G4 |
| 时间 Incr/Iter | `pnewdt` 仅步内标量 | DEP 修复后无 L5 USE |
| 动作 Eval | `PH_Mat_Plast_Eval` | G4 |

---

## Decisions

1. **Wave boundary**：仅 `tasks.md` §1 文件列表；`PH_Mat_Plast_Hill_Core` 等 **另开** change_id。
2. **SSOT**： [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) · [`DESIGN_Mat_FourTypes.md`](../../../ufc_core/L4_PH/Material/DESIGN_Mat_FourTypes.md)
3. **DEP-001 策略（首选）**：将 `RT_PNEWDT_NO_CHANGE` 的 **数值语义** 在 L4 侧以 `PH_Mat_Krnl_*` 或 `IF_*` 层常量/参数提供，使 `PH_Mat_Plast_J2_UMAT_Core` **不再 USE `RT_Com_Def`**；若需 `RT_Com_Base_Ctx` 形状，改为 L4 本地 `PH_*_Ctx` 或仅 USE L1。  
   **备选（驳回）**：保留 `USE RT_Com_Def` 并 waiver — 与 Guardian P0 及 L3-H01 精神冲突。
4. **INTF-001 预算**：本波 **最多 2** 个公开过程改为 `*_Arg`；其余记入 `tasks.md` §5 遗留。

---

## Acceptance (linked)

| 级别 | 命令/工件 | 通过条件 |
|------|-----------|----------|
| L-形式 | G1–G6（P1 表 Plast 行） | PR 附件 |
| L-合同 | A8 无 L4→L5 USE | Guardian DEP-001=0 on touched |
| L-物理 | 既有 J2 烟测 / `test_defn_invoke_umat` 若触及 | 不回归 |

```text
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave3-plast-loc --strict
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py discipline verify --touch-path <each touched>
```

---

## Open Questions

- `RT_PNEWDT_NO_CHANGE` 是否已有 L1 等价常量？（实现 S5 时 grep `IF_` / `PH_Mat_Integ`）

---

## Alternatives considered

- 整域 `Plast/` 一次清 INTF-001 — **驳回**（与 wave-2 教训相同，面过大）。
