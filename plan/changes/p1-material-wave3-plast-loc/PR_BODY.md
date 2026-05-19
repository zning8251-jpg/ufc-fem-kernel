## Summary

P1 Material **wave3** — L4 `Plast/` **J2 竖切**脊索对齐二元结构工作流（`change_id`: `p1-material-wave3-plast-loc`）。

- 清除 **`PH_Mat_Plast_J2_UMAT_Core`** 的 **DEP-001 P0**（移除 `USE RT_Com_Def` / 未使用的 `RT_Com_Base_Ctx`；本地 `PH_PNEWDT_NO_CHANGE`）。
- 公开 SIO：**`PH_J2_ComputeStress(PH_J2_ComputeStress_Arg)`**；`PH_Mat_Plast_Eval` 沿用既有 **`PH_Mat_Plast_Eval_Arg`**。
- **`PH_J2_RadialReturn`** 等步骤过程改为 **module-private**（不占用 ≤2 公开 `*_Arg` 预算）。
- 补 **MOD-001** 模块头（Purpose/Theory/Status）与关键过程 **四链** 注释。
- 适配 **`PH_Mat_Reg`** 与 J2 相关集成测（唯一生产调用点）。

**不在本 PR**：`Plast/` 下 Hill/Barlat/Crystal；`Dispatch/` 的 FLOW-003；全目录 `guardian Plast` 存量 P0。

---

## 主轴声明（工作流五元）

| 项 | 内容 |
|----|------|
| **层** | L4_PH（调用适配：`PH_Mat_Reg.f90`；测试在 `tests/`) |
| **域** | `ufc_core/L4_PH/Material/Plast/`（J2 脊索） |
| **合同** | 未改 `CONTRACT.md` 正文（边界未变；若 Review 要求可补 Plast 三轴登记表增量） |
| **Bridge** | 无 |
| **SIO** | 是 — `PH_J2_ComputeStress_Arg`、`PH_Mat_Plast_Eval_Arg`（Principle #14） |

---

## G1–G6（P1 Material · 本 PR 范围）

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1 | ✅ | 与 `L4_PH/Material/CONTRACT.md` Plast/Dispatch 节一致 |
| G2 | ✅ | `PH_Mat_Plast_Def` / J2 nested types；`PH_J2_ComputeStress_Arg` |
| G3 | ✅ | Eval + J2 公开入口均为 `*_Arg` |
| G4 | ✅ | `PH_Mat_Plast_IP_Incr_Eval`；`PH_J2_ComputeStress` |
| G5 | ✅ | `PH_` 层缀 |
| G6 | ✅ | 无新 inp/out 对偶 |

---

## Harness / 验证

```text
# discipline（touched）
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Eval.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/PH_Mat_Reg.f90

# guardian（脊索 — fail-on-p0）
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Eval.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90 --fail-on-p0

# naming（touched）
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.f90   # OK
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90 # OK
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Eval.f90         # 1× NAME-001 存量（IP_Incr 段）
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/PH_Mat_Reg.f90                      # 1× 存量

python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave3-plast-loc --strict
# closure: REPORTS/loop_run_20260519_110735.md
```

**说明**：按 W0 口径，命名 **存量告警** 不阻塞本波；全目录 `guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` 仍会因 **非 J2 族文件** 失败，不纳入本 PR DoD。

**物理 / 编译（建议 CI 或本地）**：

- `tests/integration/E2E_C2_02_Uniaxial_J2Plastic_Integrated.f90`
- `tests/integration/test_elem_mat_ip_loop.f90`（Case 1/4/7 J2）
- 可选：工程构建 / `test_defn_invoke_umat`（未改 UMAT bridge 本波）

---

## Changed files

| 路径 | 摘要 |
|------|------|
| `ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90` | DEP-001；`PH_PNEWDT_NO_CHANGE`；模块头 |
| `ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.f90` | `PH_J2_ComputeStress_Arg`；Core 私有化；SIO 入口 |
| `ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Eval.f90` | 模块头 + 四链 |
| `ufc_core/L4_PH/Material/PH_Mat_Reg.f90` | `PH_J2_ComputeStress(j2arg)` |
| `tests/integration/E2E_C2_02_Uniaxial_J2Plastic_Integrated.f90` | Arg 调用 |
| `tests/integration/test_elem_mat_ip_loop.f90` | 3× J2 case + `PH_MAT_J2_HARD_LINEAR` |
| `tests/L5_RT/RT_Mat_Test.f90` | `PH_MAT_J2_HARD_LINEAR` 符号 |

---

## Roll-forward

- 下一 `change_id`：**Dispatch FLOW-003**（`PH_MatEval` / `PH_MatPLMEval`）或 **Plast 非 J2 族** — 见 `plan/changes/p1-material-wave3-plast-loc/tasks.md` §5.2。
- `intf001-mat-plast-spcl-arg` §3（statev / CTest）独立任务。

---

## Refs

- 工作流：`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md`
- 任务卡：`plan/tasks/p1-material-wave3-plast-loc/TASK_RUN.md`
- 差距快照：`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`
