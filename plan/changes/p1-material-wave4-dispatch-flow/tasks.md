# Tasks: p1-material-wave4-dispatch-flow

## 0. Workflow（S1–S7）

| Step | 本 change |
|------|-----------|
| S1 | §1 CONTRACT Dispatch 行 + spec |
| S2 | [`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) §2.3 |
| S3 | 本目录四制品 + TASK_RUN |
| S5 | §2–§3 |
| S7 | §4 |

## 1. Readiness

- [x] 1.1 Read `ufc_core/L4_PH/Material/CONTRACT.md` Registry/Dispatch 行
- [x] 1.2 Confirm **no overlap** with open `p1-material-wave3-plast-loc` Plast edits
- [x] 1.3 Baseline: `guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` → **P0=0**（2026-05-19，FLOW-003 已绿）

**In-scope files**：

| 路径 | 角色 |
|------|------|
| `Dispatch/PH_MatEval.f90` | Legacy Eval；FLOW-003 复核（wire Desc） |
| `Dispatch/PH_MatPLMEval.f90` | 塑性 Eval dispatch 脊索 + MOD-001 |
| `L3_MD/.../MD_Mat_Plast_Dispatch.f90` | FromDesc → Arg |
| `L3_MD/.../MD_Mat_Lib.f90` | 范围 dispatch 挂接 |
| `L3_MD/Bridge/.../MD_MatLibPH_Brg.f90` | 再导出 Arg |

**Out of scope**：`PH_MatPLM_Kernels.f90`、`PH_MatPLM_LegacyFacadeUMATs.f90` 全量 INTF；`Plast/` 任意文件。

## 2. P0 — FLOW-003（维持）

- [x] 2.1 目录级 `guardian Dispatch --fail-on-p0` → P0=0
- [x] 2.2 `PH_MatEval`：有效模量写入 **`md_elas_wire`**，再赋 `elastic_in%mat_desc`（非 runtime 污染 inbound Desc）

## 3. P1 — SIO 脊索（预算 ≤2）

- [x] 3.1 `UF_Plastic_Eval_Dispatch_Arg` + `UF_Plastic_Eval_Dispatch(arg)`；`UF_Plastic_Eval_Dispatch_Core` 私有化；更新 L3 调用点
- [ ] 3.2 `UF_Plastic_UMAT_Dispatch_Arg` + 公开单参入口；内部 legacy 包装降为 private（或 P2 渐进）
- [ ] 3.3 `PH_MatEval`：复核公开 Eval 过程是否需 Arg（**defer** 若不在 §1 脊索）

## 4. Harness gates

- [x] 4.1 `discipline verify --touch-path` → `PH_MatPLMEval.f90`
- [x] 4.2 `guardian PH_MatPLMEval.f90 --fail-on-p0` → P0=0
- [ ] 4.3 `naming` touched（存量 NAME-001 不阻塞）
- [ ] 4.4 `change-package validate --change-id p1-material-wave4-dispatch-flow --strict`
- [ ] 4.5 `closure`（可选 `--skip-plan-checks`）

## 5. Roll-forward

- [ ] 5.1 G1–G6 勾选 + PR_BODY
- [ ] 5.2 下一 change：**Plast 非 J2**（Hill/Barlat/Crystal）或 **`PH_MatEval` Eval-In/Out 族 Arg 化**（独立 change_id）
- [ ] 5.3 `intf001` §3 statev/CTest — 仍独立
