# Change: p1-material-wave5-plast-nonj2

## Why

wave3 仅竖切 **J2 脊索**（`PH_Mat_Plast_J2_Iso_Core` / `J2_UMAT_Core`）。`Plast/` 内 **Hill / Barlat / Crystal** 仍保留 legacy UMAT 多参公开 API（Guardian **INTF-001 P1**），且经 `PH_MatPLM_Kernels` → `PH_MatPLMEval` 热路径调用。本 change 与 **Dispatch wave4**、**MatEval wave5** 分轨，避免混 PR。

## What Changes

- **范围**（仅 L4 `Plast/` 三文件，见 `tasks.md` §1）：
  - `PH_Mat_Plast_Hill_Core.f90` — `UF_Hill_UMAT` → **`UF_Hill_UMAT_Arg`**（SIO 预算 1/2）
  - `PH_Mat_Plast_Barlat_Core.f90` — **`PH_Mat_Barlat_Calc_Stress_Arg`**（或合同指定唯一入口；预算 2/2）
  - `PH_Mat_Plast_Crystal_Core.f90` — **`UF_CrystalPlasticity_UMAT_Arg`**
- **预期**：touched 文件 `guardian --fail-on-p0`；INTF-001 在 **公开入口** 清零；MOD-001 模块头；**不**改 `PH_Mat_Plast_J2_*`（wave3 已交付）。
- **挂接**：更新 `PH_MatPLM_Kernels` / `PH_MatPLMEval` 内对 `UF_Hill_UMAT` 的调用为 Arg（最小 diff）。

## What NOT

- `PH_Mat_Plast_Chaboche_Core.f90`、全目录 `guardian Plast` 清零、Registry 机械刷新。
- `Dispatch/PH_MatEval`（见 **`p1-material-wave5-mateval-arg`**）。

## Impact

- `UF_Hill_UMAT` 定义于 `PH_Mat_Plast_Hill_Core`，由 `PH_MatPLM_Kernels` USE — 改签名须同步 **一处** dispatch CASE。
- Populate / slot 金线不变。

## Links

- 前置：[`p1-material-wave3-plast-loc`](../p1-material-wave3-plast-loc/)
- 并行：[`p1-material-wave5-mateval-arg`](../p1-material-wave5-mateval-arg/)
- 快照：[`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
