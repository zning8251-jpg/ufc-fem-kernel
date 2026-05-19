# Design: p1-material-plast-guardian-debt

## FLOW-003（Populate）

- **问题**：`PH_Mat_Plast_Populate_From_L3` 直写 `desc%E/nu/G/K/sigma_y/H_iso`，Guardian 视为 Desc 运行态污染。
- **方案**：冷路径只填充 `desc%cfg`、`desc%pop`、`desc%props(:)`；`Build_Elastic_Stiffness` / `Check_Yield` / `J2_Radial_Return` 经私有 `plast_desc_read_*` 从 `props` 读（保留标量字段向后兼容）。

## Chaboche SIO

- 镜像 `UF_Hill_UMAT_Arg` / `UF_CrystalPlasticity_UMAT_Arg`。
- 实现体保留为 `UF_Chaboche_UMAT_Legacy`（PRIVATE）；公开 `UF_Chaboche_UMAT(arg)`。
- `PH_MatPLMEval` `CASE (PH_MAT_CHABOCHE_MAT_ID)` 使用 Arg BLOCK（与 Hill 同型）。

## Harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast --fail-on-p0
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast
python ufc_harness/run_harness.py change-package validate --change-id p1-material-plast-guardian-debt --strict
```
