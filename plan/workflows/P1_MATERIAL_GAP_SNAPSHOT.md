# P1 Material — 差距快照（Registry + Guardian）

> **更新**：2026-05-19 · **消费方**：wave3–wave5 规划

---

## 1. 三层合同

| 层 | CONTRACT |
|----|----------|
| L3 | `ufc_core/L3_MD/Material/CONTRACT.md` |
| L4 | `ufc_core/L4_PH/Material/CONTRACT.md` |
| L5 | `ufc_core/L5_RT/Material/CONTRACT.md` |

---

## 2. Guardian 基线（`main` 上待合并 PR 前快照）

| 子树 | 命令 | P0 | 备注 |
|------|------|-----|------|
| `Plast/` 全域 | `guardian Plast --fail-on-p0` | **>0** | 非 J2 族 + 存量 |
| `Plast/PH_Mat_Plast_J2_*` | per-file | 0 | wave3 PR #1 |
| `Plast/PH_Mat_Plast_Hill_Core` | per-file | 0 | PR #3 `UF_Hill_UMAT_Arg` |
| `Plast/PH_Mat_Plast_Barlat_Core` | per-file | 0 | PR #3；NAME-001 存量 P2 |
| `Plast/PH_Mat_Plast_Crystal_Core` | per-file | 0 | PR #4 `UF_CrystalPlasticity_UMAT_Arg` |
| `Dispatch/` | `guardian Dispatch --fail-on-p0` | 0 | wave4 PR #2 |
| `Dispatch/PH_MatEval.f90` | INTF-001 | 0 | 过程已为 `Eval(arg)`；待 **API 文档化** |

---

## 3. 波次台账

| change_id | 范围 | 状态 |
|-----------|------|------|
| `rollout-l4-material-binary-trivium` | L4 脊索 | done |
| `rollout-l4-material-wave2-dispatch` | Dispatch 基线 | done |
| `intf001-mat-plast-spcl-arg` | bridge SIO | done |
| `p1-material-wave3-plast-loc` | Plast **J2** | PR [#1](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/1) |
| `p1-material-wave4-dispatch-flow` | Dispatch Eval+UMAT SIO | PR [#2](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/2) |
| **`p1-material-wave5-plast-nonj2`** | Plast Hill/Barlat/Crystal | PR [#3](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/3) + [#4](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/4) |
| **`p1-material-wave5-mateval-arg`** | `PH_MatEval` API 收口 | **planned** |

---

## 4. Roll-forward（wave5+）

1. **先做** `p1-material-wave5-plast-nonj2`（真实 INTF/MOD 缺口；与 J2/wave4 解耦）。
2. **再做** `p1-material-wave5-mateval-arg`（Guardian 已绿；合同/文档/MOD + 去遗留 In/Out 注释）。
3. `intf001` §3 statev/CTest — 仍独立 change。
4. `PH_Mat_Plast_Chaboche_Core` — **不在** wave5 三族内；另开 change。
