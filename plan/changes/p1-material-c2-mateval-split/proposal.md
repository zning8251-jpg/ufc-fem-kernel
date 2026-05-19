# Change: p1-material-c2-mateval-split (PR-A)

## Why

`PH_MatEval.f90` 仍为 **legacy aggregate**（mateval-arg 仅文档化）。plan **C2** 要求按族迁入 `Elas/`、`Plast/` 等；本包先做 **PR-A：Elas + Plast 点 Eval**，`PH_MatEval` 保留 **门面 re-export**（调用方 `USE PH_MatEval` 不变）。

## What Changes

| 迁出 | 新模块 |
|------|--------|
| `PH_Mat_ElasticIsotropic_*` / `PH_Mat_ElasticOrthotropic_*` | `Elas/PH_Mat_Elas_PointEval.f90` |
| `PH_Mat_PlasticVonMises_*` / `PH_Mat_PlasticHill_*` | `Plast/PH_Mat_Plast_PointEval.f90` |
| 其余 Hyper/Damage/Creep/Visco/Composite | 仍留在 `Dispatch/PH_MatEval.f90` |

- Orthotropic Arg 含 `strain`/`sigma`/`D_matrix`（与 #8 对齐，即使 #8 未合并）。
- `CONTRACT.md` Legacy 表增加 **C2 真源** 列。

## What NOT (PR-B+)

- Hyper / Damage / Creep / Visco / Composite 迁出。
- 删除 `PH_MatEval` 模块或改 `PH_Mat_Core` 金线路径。

## Links

- 前置：wave5-mateval-arg、orthotropic-eval-fix（#8）
- backlog §4 item 3
