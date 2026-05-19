# Design: contract-l4-element

> **Status**: S1–S3 **ACTIVE**（2026-05-19）— 计划包；实现波次另开 `p2-element-*`。

## 1. 柱定义（P2）

| 层 | 路径 | 合同 |
|----|------|------|
| L3 | `L3_MD/Element/`、`L3_MD/Element/Mesh/` | `Mesh/CONTRACT.md` |
| L4 | `L4_PH/Element/` | `Element/CONTRACT.md`、`DESIGN_Elem_FourTypes.md` |
| L5 | `L5_RT/Element/`、`L5_RT/Assembly/` | `Assembly/CONTRACT.md`（Ke 编排） |

**金线**（与 PR01 一致）：

```text
MD_Mesh + MD_Elem Desc
  → PH_L4_Populate_Element → elem_*_cache / elem_to_mat_map
  → PH_Element_Compute_Ke / Compute_Fe（族内核 + Material route）
  → RT_Asm_GlobalStiffness / RT_Asm_Solv_KeArg_AttachMatProps
```

## 2. S1 — 合同审计（checklist）

| # | 检查项 | 真源 | 通过标准 |
|---|--------|------|----------|
| S1-1 | `PH_Element_Compute_Ke_Arg` 字段与 L5 填充一致 | `PH_Elem_Def.f90`、`RT_Asm_Solv.f90` | 无未登记字段漂移 |
| S1-2 | `mat_pt_idx` / slot 路径与 Material CONTRACT R2 一致 | `Shared/PH_Elem_MaterialRoute*` | 热路径零 L3 |
| S1-3 | Populate 后 `elem_type_cache` 与 `PH_Elem_Reg` 对齐 | `CONTRACT_Populate_Layer.md` | 未注册类型行为已文档化 |
| S1-4 | `load_magn_in` vs L5 `F_ext` 无双重计数 | Element + Assembly CONTRACT §5.4 | 与 PR01 描述一致 |
| S1-5 | Legacy `PH_Elem_Contm` 标注与 G6 销项路径 | Element CONTRACT §2.1 | 实现波次不扩大 scope |

## 3. S2 — 差距快照

产出文件：**`plan/workflows/P2_ELEMENT_GAP_SNAPSHOT.md`**（本 change 的 S2 交付，可在同 PR 或 follow-up doc PR 落盘）。

| 门闩 | 主题 | 初判（2026-05-19） |
|------|------|-------------------|
| P2-G1 | L4 合同 + 文件清单 | **绿** — CONTRACT v2.6 较完整 |
| P2-G2 | 四型 Def/Ctx | **绿** — `PH_Elem_Def` / `PH_Elem_Ctx` |
| P2-G3 | Ke/Fe Arg / Harness | **黄** — Arg 存在；与 `RT_Elem_Proc` inp/out 未完全对齐 |
| P2-G4 | NLGeom / Eval 命名 | **黄** — `PH_NLGeomEval` 体量大；命名收敛待 MR |
| P2-G5 | L5 `RT_Elem_Proc` vs 生产 | **黄** — SIO 目标态差距（检查表 P2-G5） |
| P2-G6 | Legacy Contm | **红** — `USE MD_*` 技术债；销项需专用 change |

## 4. S3 — 实现波次切分（plan only）

| change_id（拟） | 范围 | 依赖 |
|-----------------|------|------|
| `p2-element-pr01-seam-doc` | PR01 接缝文档化 + guardian 锚点基线 | **已归档**（#20） |
| `p2-element-material-route-audit` | `PH_Elem_MaterialRoute`：销 DEP-001 P0；slot 只读审计 | **P0=0**（`ValidateRtCtx`）；P1/P2 命名债后续 |
| `p2-element-ke-arg-align` | `PH_Element_Compute_Ke_Arg` ↔ `RT_Asm_Solv`；L4 门控 | **已落地**（`CONTRACT` + `PH_Elem_Domain%Compute_Ke`） |
| `p2-element-legacy-contm-retire` | G6-W0 隔离 + verifier；W1/W2 裁剪 Contm | **G6-W0 进行中**（#22 拟） |
| `p2-element-l5-rt-elem-proc-sio` | `RT_Elem_Proc` → `*_Arg` | 可选，半柱 H3 接缝 |

**建议实现顺序**：pr01-seam → material-route-audit → ke-arg-align → legacy-contm → rt-elem-proc-sio。

## 5. Harness（S3 闸门）

```text
change-package validate --change-id contract-l4-element --strict
# S4+ 才要求：
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Element ufc_core/L5_RT/Assembly --fail-on-p0
```

## 6. 与 P1 并行策略

| 工作 | 可并行计划？ | 可并行代码？ |
|------|-------------|-------------|
| 本包 S1–S3 | 是 | 是（仅 `plan/` + 可选 snapshot md） |
| P1 W2 / NAME | 是 | **否** — 同一 MR 勿混 Material+Element 热路径 |
