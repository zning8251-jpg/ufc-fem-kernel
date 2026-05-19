---
task_run_version: "1.1"
session: "p1-material-wave3-plast-loc"
status: completed
current_step_id: "S7"
updated_at: "2026-05-19T19:00:00Z"
governance_change_id: "p1-material-wave3-plast-loc"
pillar_id: "P1"
wave: "W1-wave3"
---

# TASK_RUN — `p1-material-wave3-plast-loc`

> **模板**：[`plan/workflows/templates/TASK_RUN_L3L4L5.md`](../../workflows/templates/TASK_RUN_L3L4L5.md)  
> **变更包**：[`plan/changes/p1-material-wave3-plast-loc/`](../../changes/p1-material-wave3-plast-loc/)  
> **前置**：[`w0-registry-refresh`](../w0-registry-refresh/TASK_RUN.md) done

---

## Meta

| 字段 | 值 |
|------|-----|
| **task_id** | `p1-material-wave3-plast-loc` |
| **pillar_id** | **P1** Material |
| **wave** | W1 · Plast Loc 竖切（波次1） |
| **change_id** | `p1-material-wave3-plast-loc` |
| **owner** | （待填） |
| **created** | 2026-05-19 |

---

## Goal

完成 L4 `Material/Plast/` **J2 竖切**：清除 `PH_Mat_Plast_J2_UMAT_Core` **DEP-001 P0**；在 SIO 预算内收拢 ≤2 个公开 `*_Arg` 入口；touched 文件 discipline/guardian/naming 绿；G1–G6 可勾选。

---

## References

| # | 路径 | 用途 |
|---|------|------|
| 1 | `ufc_core/L3_MD/Material/CONTRACT.md` | L3 四型 / Populate |
| 2 | `ufc_core/L4_PH/Material/CONTRACT.md` | L4 SSOT |
| 3 | `ufc_core/L5_RT/Material/CONTRACT.md` | L5 委托 / DELEGATED |
| 4 | `docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md` §P1 | G1–G6 |
| 5 | `plan/changes/p1-material-wave3-plast-loc/design.md` | 方法论映射 |
| 6 | `plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md` | Guardian 基线 |
| 7 | `plan/workflows/templates/HANDOFF_MATRIX.md` | 逐步交接 |

---

## 七步工序子任务

| Step | 名称 | state | 证据（路径 / rc） |
|------|------|-------|-------------------|
| S1 | 设计锚定 | done | spec + CONTRACT 指针已读 |
| S2 | 现状快照 | done | GAP_SNAPSHOT + registry 1067 md |
| S3 | 差距与计划 | done | change 四制品已建 |
| S4 | L3 数据面 | done | N/A — 本波仅 L4 Plast |
| S5 | L4 计算面 | done | §2 DEP + §3 SIO + MOD-001 |
| S6 | L5 编排面 | done | N/A |
| S7 | 验收闭环 | done | §4/§5 + PR_BODY.md |

---

## G1–G6 结果（S7 填写）

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1 | ✅ | CONTRACT 指针已对齐 |
| G2 | ✅ | `PH_Mat_Plast_Def` + J2 nested types |
| G3 | ✅ | `PH_Mat_Plast_Eval_Arg`, `PH_J2_ComputeStress_Arg` |
| G4 | ✅ | `PH_Mat_Plast_IP_Incr_Eval`, `PH_J2_ComputeStress` |
| G5 | ✅ | `PH_` 前缀 |
| G6 | ✅ | 无新 inp/out 对偶 |

---

## PR 主轴声明（草稿）

- **层**：L4_PH
- **域**：`ufc_core/L4_PH/Material/Plast/`
- **合同**：增量（若 DEP/Args 改边界）
- **Bridge**：无
- **SIO**：是（≤2 `*_Arg`，Principle #14）

---

## Harness Log

```text
# 2026-05-19 baseline (w0-registry-refresh)
guardian ufc_core/L4_PH/Material/Plast --fail-on-p0  → rc=1 (DEP-001 @ J2_UMAT_Core:52)

# 2026-05-19 S5 §2
guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90 --fail-on-p0  → P0=0
change-package validate --change-id p1-material-wave3-plast-loc --strict  → rc=0

# 2026-05-19 S5 §3
guardian .../PH_Mat_Plast_Eval.f90 --fail-on-p0  → P0=0
guardian .../PH_Mat_Plast_J2_Iso_Core.f90 --fail-on-p0  → P0=0 (INTF-001 on public spine cleared)

# 2026-05-19 S7 §4
discipline verify (Eval, J2_Iso, J2_UMAT, PH_Mat_Reg)  → OK
naming PH_Mat_Plast_J2_Iso_Core.f90 / PH_Mat_Plast_J2_UMAT_Core.f90  → OK
naming PH_Mat_Plast_Eval.f90 / PH_Mat_Reg.f90  → 1 issue each (NAME-001 legacy, W0 baseline)
closure --skip-plan-checks  → REPORTS/loop_run_20260519_110735.md
```

---

## Next action（只写一步）

**已收口**。开 PR 时粘贴 [`plan/changes/p1-material-wave3-plast-loc/PR_BODY.md`](../../changes/p1-material-wave3-plast-loc/PR_BODY.md)；合并后任务包迁至 `plan/archive/p1-material-wave3-plast-loc/`，下一 change 见 `tasks.md` §5.2。

---

## Handoff notes

| 自 Step | 至 Step | 交接人 | 日期 | 阻塞项 |
|---------|---------|--------|------|--------|
| w0-registry-refresh S2 | 本任务 S3 | Agent | 2026-05-19 | — |

---

## Log

- 2026-05-19：开立 change 包与 TASK_RUN；基线见 GAP_SNAPSHOT；S2/S3 done，S1 in_progress。
- 2026-05-19：§2 DEP-001 已修 — 移除 `USE RT_Com_Def`、删未用 `RT_Com_Base_Ctx` 实参、`PH_PNEWDT_NO_CHANGE`；单文件 guardian P0=0。
- 2026-05-19：§3 — `PH_J2_ComputeStress_Arg` 公开入口；`PH_J2_RadialReturn` 等降为 private；Eval/J2/UMAT 模块头+四链；`PH_Mat_Reg`+集成测适配。
- 2026-05-19：§4/§5 — naming/closure/validate 完成；`PR_BODY.md` 已起草；S7 done。
