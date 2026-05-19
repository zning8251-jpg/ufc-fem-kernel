# Change: p1-material-crystal-impl

## Why

wave5 **PR-B (#6)** 已交付 Crystal **SIO 脊索**（`UF_CrystalPlasticity_UMAT_Arg` + `PH_MatPLMEval` CASE 266），但 `UF_CrystalPlasticity_UMAT` 仍返回 **`STATUS_UNSUPPORTED`**。Registry（L3 mat_id **266**）与热路径挂接已就绪；缺 **可运行的 W1 本构核** 与 **props/statev 合同**。

本 change 在 **#7 → #8 → #9 → #10** 合并并完成 C2 归档之后实施，避免与 MatEval 拆分、ortho 合同修复并行冲突。

## What Changes（实施 PR 范围，草案）

| 项 | 说明 |
|----|------|
| **W1 核** | `PH_Mat_Plast_Crystal_Core.f90`：`UF_CrystalPlasticity_UMAT` 从 stub → **最小可积 CPFEM 路径**（见 `design.md` §W1） |
| **合同** | `L4_PH/Material/CONTRACT.md`：mat_id 266、`props[]` 索引、`statev` 布局、与 `CrystalPlast_MatDesc` 金线 |
| **校验** | `UF_CrystalPlasticity_ValidateProps`（或等价）+ guardian P0=0 |
| **挂接** | **不改** `PH_MatPLMEval` CASE 266（已 Arg 化）；仅充实 Core 实现 |

## What NOT

- 全晶格纹理 / 有限应变 UEL 级 CPFEM（→ W2 或独立 change）
- 新建 L3 `MD_MatPLMCrystal.f90`（除非 W1 证明必须；默认 W1 仅用 `props` ABI）
- `PH_MatEval` 点 Eval（Crystal 仅 PLM/UMAT 路径）
- Hill/Barlat/Chaboche 清债（`p1-material-plast-guardian-debt`）

## Preconditions（合并闸门）

1. [#7](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/7) Plast guardian debt  
2. [#8](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/8) orthotropic eval fix  
3. [#9](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/9) + [#10](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/10) C2 MatEval split  
4. `plan/tasks/p1-material-c2-mateval-split/` 归档  

## Impact

- 调用方：`UF_Plastic_Eval_Dispatch` mat_id 266 由 **unsupported** → **OK/INVALID** 语义化返回  
- 与 J2 UMAT 对齐：复用 `PH_Mat_Integ_Shared` 弹性试应力；塑性部分在 Crystal Core 内局部实现  

## Links

- 前置 SIO：[`p1-material-wave5-plast-nonj2`](../p1-material-wave5-plast-nonj2/) PR-B  
- 快照：[`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) §2.1  
- backlog：[`p1-material-post-wave5-backlog.md`](../../backlog/p1-material-post-wave5-backlog.md) §4 item 4  
