# P2 Element — 差距快照（GAP）

> **更新**：2026-05-19  
> **change_id**：`contract-l4-element`（S2 交付）  
> **真源检查表**：[`UFC_L345_形式对齐域级检查表_P1-P6.md`](../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md) § P2

---

## 汇总

| 门闩 | 状态 | 说明 |
|------|------|------|
| P2-G1 | 绿 | `L4_PH/Element/CONTRACT.md` §2 文件矩阵 |
| P2-G2 | 绿 | `PH_Elem_Def` / `PH_Elem_Ctx` 四型 |
| P2-G3 | 黄 | `PH_Element_Compute_Ke_Arg` 存在；L5 `RT_Elem_Proc` 对偶未收敛 |
| P2-G4 | 黄 | `PH_NLGeomEval` / `PH_Elem_Eval` 命名与体积 |
| P2-G5 | 黄 | `RT_Elem_Proc` 骨架 vs `RT_Asm_Solv` 生产路径 |
| P2-G6 | 红 | `PH_Elem_Contm` legacy + `USE MD_*` 热路径债 |

**柱级 S7**：**未**达成 — 需 G3–G6 实现波次 + guardian 全绿。

---

## 接缝（P1∩P2）

| 接缝 | L4 锚点 | L5 锚点 | 备注 |
|------|---------|---------|------|
| 材料 → Ke | `Shared/PH_Elem_MaterialRoute*` | `RT_Asm_Solv_KeArg_AttachMatProps` | 见 PR01 |
| 拓扑 | Populate `elem_*_cache` | `MD_Mesh_GetElemConnect_*` | 冷路径 |
| 载荷 | `load_magn_in` / `PH_Elem_Eval_Fe` | `RT_Asm_GlobalLoad` / `F_ext` | 防双重计数 |

---

## 建议 change 队列

见 [`plan/changes/contract-l4-element/design.md`](../changes/contract-l4-element/design.md) §4。

| change_id | 状态（2026-05-19） |
|-----------|-------------------|
| `p2-element-pr01-seam-doc` | **已归档**（#20）— [`design.md`](../changes/p2-element-pr01-seam-doc/design.md) |
| `p2-element-material-route-audit` | **P0 已销**（`PH_Elem_MatRoute_ValidateRtCtx`）— PR 待合并 |
| `p2-element-ke-arg-align` | **已落地** — `CONTRACT` Ke_Arg 表 + `PH_Elem_Domain` 门控 |
