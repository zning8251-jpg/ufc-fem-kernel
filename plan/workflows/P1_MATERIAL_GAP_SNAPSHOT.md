# P1 Material — 差距快照（Registry + Guardian）

> **生成**：2026-05-19 · **消费方**：wave3 Plast · wave4 Dispatch

---

## 1. Registry

| 项 | 值 |
|----|-----|
| 命令 | `python UFC/tools/domain_procedure_registry_scan.py` |
| 输出 | `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`（**1067** 篇 `.md`） |

**P1 三层合同**：`L3_MD` / `L4_PH` / `L5_RT` `Material/CONTRACT.md`

---

## 2. L4 Guardian 基线

### 2.1 `Plast/`（wave3 — 见 PR #1）

`guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` → 非 J2 族仍失败；J2 脊索三文件 P0=0。

### 2.2 `Dispatch/`（wave4 · 2026-05-19）

命令：`python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` → **P0=0**

| 项 | 状态 | 说明 |
|----|------|------|
| **FLOW-003** | ✅ | `PH_MatEval`：`md_elas_wire`；`PH_MatPLMEval`：无 `%desc%=` 直写 |
| **INTF-001** | ✅ 脊索 | `UF_Plastic_Eval_Dispatch_Arg` + `UF_Plastic_UMAT_Dispatch_Arg`；`UF_Plastic_Leg_*` P2 渐进 |
| **MOD-001** | 🔄 | `PH_MatPLMEval` 已补头 |

**change**：`p1-material-wave4-dispatch-flow` · [`TASK_RUN`](../tasks/p1-material-wave4-dispatch-flow/TASK_RUN.md)

---

## 3. 已完成 / 进行中波次

| change_id | 范围 | 状态 |
|-----------|------|------|
| `rollout-l4-material-binary-trivium` | L4 脊索 | done |
| `rollout-l4-material-wave2-dispatch` | Dispatch 基线 | done |
| `intf001-mat-plast-spcl-arg` | bridge SIO | done |
| `p1-material-wave3-plast-loc` | Plast J2 | PR #1 |
| `p1-material-wave4-dispatch-flow` | Dispatch Eval+UMAT SIO | PR（与 #1 并行） |

---

## 4. Roll-forward

- wave4 完成后：**Plast 非 J2** 或 **`PH_MatEval` Eval 族 Arg 化**（独立 change_id）
- `intf001` §3 statev/CTest — 独立
