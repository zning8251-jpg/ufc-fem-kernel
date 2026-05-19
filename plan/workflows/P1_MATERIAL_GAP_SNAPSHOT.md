# P1 Material — 差距快照（Registry + Guardian）

> **生成**：2026-05-19 · **任务**：[`plan/tasks/w0-registry-refresh/TASK_RUN.md`](../tasks/w0-registry-refresh/TASK_RUN.md)  
> **消费方**：[`p1-material-wave3-plast-loc`](../tasks/p1-material-wave3-plast-loc/TASK_RUN.md) · change_id `p1-material-wave3-plast-loc`

---

## 1. Registry

| 项 | 值 |
|----|-----|
| 命令 | `python UFC/tools/domain_procedure_registry_scan.py` |
| 输出 | `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`（**1067** 篇 `.md`） |
| 索引 | `generated/_REGISTRY_STATS.md` |
| 设计真源 | `DomainProcedureRegistry/design/`（按域补 `INTENT.md` 时领先源码） |

**P1 三层合同（核对 G1）**：

| 层 | CONTRACT |
|----|----------|
| L3 | `ufc_core/L3_MD/Material/CONTRACT.md` |
| L4 | `ufc_core/L4_PH/Material/CONTRACT.md` |
| L5 | `ufc_core/L5_RT/Material/CONTRACT.md` |

---

## 2. L4 `Plast/` Guardian 基线（2026-05-19）

命令：`python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` → **rc=1**

### 2.1 优先修复（wave3 §2 预算）

| 优先级 | 规则 | 文件 | 行 | 说明 |
|--------|------|------|-----|------|
| ~~**P0-1**~~ | DEP-001 | `PH_Mat_Plast_J2_UMAT_Core.f90` | — | **已修 2026-05-19**：`PH_PNEWDT_NO_CHANGE`；去掉未用 `RT_Com_Base_Ctx` 与 `USE RT_Com_Def` |
| **P1-1** | INTF-001 | `PH_Mat_Plast_J2_Iso_Core.f90` | 136,309,337,449,613 | 公开过程参数>4；优先 **`PH_J2_*` 入口** 收拢为 `*_Arg`（与 intf001 一致） |
| **P1-2** | INTF-001 | `PH_Mat_Plast_Hill_Core.f90` | 499 | `UF_Hill_UMAT` 参数过多 |
| **P2** | MOD-001 | `PH_Mat_Plast_Eval.f90`, `PH_Mat_Plast_J2_Iso_Core.f90`, `PH_Mat_Plast_J2_UMAT_Core.f90` | 模块头 | 补 Purpose/Theory/Status |
| **P2** | CHAIN-001 | `PH_Mat_Plast_J2_Iso_Core.f90` | 136 | 四链注释 |
| **P2** | NAME-001 | 多文件 | — | 存量命名；本波 **不** 全量重命名，仅 touched 文件 |

### 2.2 Plast 目录文件清单（9）

| stem | wave3 默认范围 |
|------|----------------|
| `PH_Mat_Plast_Def.f90` | S5 · 四型核对 |
| `PH_Mat_Plast_Core.f90` | S5 · Loc Eval 门面 |
| `PH_Mat_Plast_Eval.f90` | S5 · Eval + Args |
| `PH_Mat_Plast_J2_Iso_Core.f90` | S5 · **J2 竖切核**（INTF 优先） |
| `PH_Mat_Plast_J2_UMAT_Core.f90` | S5 · **DEP-001 必修** |
| `PH_Mat_Plast_J2_UMAT_Core.f90` 以外族 | 本 change **不含**（另开 change_id） |

---

## 3. 已完成波次（勿重复开 change）

| change_id | 范围 | 状态 |
|-----------|------|------|
| `rollout-l4-material-binary-trivium` | L4 脊索 Def/Dsp/Populate | done |
| `rollout-l4-material-wave2-dispatch` | `Dispatch/` | done |
| `intf001-mat-plast-spcl-arg` | Dispatch SIO + bridge | done（follow-up 3.1–3.3 见该包 tasks §3） |

---

## 4. G1–G6（Plast/J2 脊索 — wave3 已验收）

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1 | ✅ | `L4_PH/Material/CONTRACT.md` Plast/Dispatch 一致 |
| G2 | ✅ | `PH_Mat_Plast_Def` + `PH_J2_*` nested types |
| G3 | ✅ | `PH_Mat_Plast_Eval_Arg`, `PH_J2_ComputeStress_Arg` |
| G4 | ✅ | `PH_Mat_Plast_IP_Incr_Eval`, `PH_J2_ComputeStress` |
| G5 | ✅ | `PH_` 前缀 |
| G6 | ✅ | 无新 inp/out 对偶 |

**PR 正文**：[`plan/changes/p1-material-wave3-plast-loc/PR_BODY.md`](../changes/p1-material-wave3-plast-loc/PR_BODY.md)

*维护：合并后在本节末追加 `（PR #___ / 日期）`。*
