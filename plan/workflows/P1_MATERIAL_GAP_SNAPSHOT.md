# P1 Material — 差距快照（Registry + Guardian）

> **生成**：2026-05-19 · **任务**：[`plan/tasks/w0-registry-refresh/TASK_RUN.md`](../tasks/w0-registry-refresh/TASK_RUN.md)  
> **消费方**：wave3 Plast · wave4 Dispatch · wave5 非 J2 / mateval

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

## 2. L4 Guardian 基线

### 2.1 `Plast/`（wave3 — merged PR #1）

命令：`python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` → 非 J2 族仍失败；**J2 脊索**三文件 P0=0。

| 优先级 | 规则 | 说明 |
|--------|------|------|
| ~~**P0-1**~~ | DEP-001 | `PH_Mat_Plast_J2_UMAT_Core.f90` — **已修** |
| **P1-2** | INTF-001 | Hill/Barlat/Crystal — wave5 PR-A/B |
| **P2** | MOD-001 / CHAIN-001 | 非 J2 + Chaboche — **post-wave5 清债** |

**G1–G6（J2）**：见 [`plan/changes/p1-material-wave3-plast-loc/PR_BODY.md`](../changes/p1-material-wave3-plast-loc/PR_BODY.md)

### 2.2 `Dispatch/`（wave4 · PR #2）

命令：`python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` → **P0=0**（wave4 分支）

| 项 | 状态 | 说明 |
|----|------|------|
| **FLOW-003** | ✅ | `PH_MatEval`：`md_elas_wire`；`PH_MatPLMEval`：无 `%desc%=` 直写 |
| **INTF-001** | ✅ 脊索 | `UF_Plastic_Eval_Dispatch_Arg` + `UF_Plastic_UMAT_Dispatch_Arg` |
| **MOD-001** | 🔄 | `PH_MatPLMEval` 已补头 |

**change**：`p1-material-wave4-dispatch-flow`

---

## 3. 已完成 / 进行中波次

| change_id | 范围 | 状态 |
|-----------|------|------|
| `rollout-l4-material-binary-trivium` | L4 脊索 | done |
| `rollout-l4-material-wave2-dispatch` | Dispatch 基线 | done |
| `intf001-mat-plast-spcl-arg` | bridge SIO | done |
| `p1-material-wave3-plast-loc` | Plast J2 | **merged** #1 |
| `p1-material-wave4-dispatch-flow` | Dispatch Eval+UMAT SIO | PR #2 |
| `p1-material-wave5-plast-nonj2` | Hill/Barlat/Crystal Arg | PR #3 / #4 |
| `p1-material-wave5-mateval-arg` | PH_MatEval 文档 | PR #5 |

---

## 4. Roll-forward

- wave4–5 合并后：**Plast 清债**（Chaboche + 全 Plast guardian）· **C2 PH_MatEval 按族吸收** · **Crystal 实装**
- 编排：[`plan/backlog/p1-material-post-wave5-backlog.md`](../backlog/p1-material-post-wave5-backlog.md)

*维护：合并后在本节末追加 `（PR #___ / 日期）`。*
