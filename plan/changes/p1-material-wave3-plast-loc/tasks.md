# Tasks: p1-material-wave3-plast-loc

## 0. Workflow（S1–S7 映射）

| Step | 本 change 对应 |
|------|----------------|
| S1 | §1 读 CONTRACT + 本 spec |
| S2 | 已记入 [`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) |
| S3 | 本目录四制品 + TASK_RUN |
| S5 | §2–§3 实现 |
| S7 | §4 _closure |

---

## 1. Readiness

- [x] 1.1 Read `ufc_core/L4_PH/Material/CONTRACT.md` Plast/Dispatch 节 + `specs/**`
- [x] 1.2 Read [`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) §2.1
- [x] 1.3 Confirm **no overlap** with open edits in `intf001-mat-plast-spcl-arg` follow-ups (§5)

**In-scope files（J2 竖切）**：

- `Plast/PH_Mat_Plast_Def.f90`
- `Plast/PH_Mat_Plast_Core.f90`
- `Plast/PH_Mat_Plast_Eval.f90`
- `Plast/PH_Mat_Plast_J2_Iso_Core.f90`
- `Plast/PH_Mat_Plast_J2_UMAT_Core.f90`

## 2. P0 — DEP-001（必修）

- [x] 2.1 `PH_Mat_Plast_J2_UMAT_Core.f90`: remove `USE RT_Com_Def` / L5 dependency; use L1/L4 constant for `pnewdt` default
- [x] 2.2 `guardian .../PH_Mat_Plast_J2_UMAT_Core.f90 --fail-on-p0` → P0=0（2026-05-19）

## 3. P1 — INTF-001（预算 ≤2 公开入口）

- [x] 3.1 `PH_Mat_Plast_Eval` 已有 `PH_Mat_Plast_Eval_Arg`；J2 脊索 `PH_J2_ComputeStress(Arg)`
- [x] 3.2 `PH_J2_ComputeStress_Arg` + 更新 `PH_Mat_Reg`、集成测；`PH_J2_RadialReturn` 降为 module-private
- [x] 3.3 MOD-001：Eval / J2_Iso / J2_UMAT 模块头；四链：Eval IP_Incr、J2 ComputeStress(Arg/Core)

## 4. Harness gates

- [x] 4.1 `discipline verify --touch-path` — Eval / J2_Iso / J2_UMAT / `PH_Mat_Reg` → OK（2026-05-19）
- [x] 4.2 `guardian <touched.f90> --fail-on-p0` — 脊索三文件 P0=0（2026-05-19）
- [x] 4.3 `naming` — J2_Iso、J2_UMAT **OK**；Eval、Reg 各 **1× NAME-001 存量**（W0 基线范畴，本波不修）
- [x] 4.4 `change-package validate --change-id p1-material-wave3-plast-loc --strict` → rc=0
- [x] 4.5 `closure --skip-plan-checks` → `REPORTS/loop_run_20260519_110735.md`（exit 1：全库 naming 存量，非本 PR 脊索回归）

## 5. Roll-forward / deferred

- [x] 5.1 G1–G6 已写入 [`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) §4 + [`TASK_RUN`](../../tasks/p1-material-wave3-plast-loc/TASK_RUN.md)；PR 正文 [`PR_BODY.md`](PR_BODY.md)
- [x] 5.2 Deferred: Hill/Barlat/Crystal INTF-001; `PH_MatEval` FLOW-003 → 下一 change（`p1-material-wave4-dispatch-flow` 或等价 id）
- [x] 5.3 `intf001` tasks.md §3 follow-ups — **独立** change/task（不阻塞本 PR 合并）
