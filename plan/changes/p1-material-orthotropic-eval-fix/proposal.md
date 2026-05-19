# Change: p1-material-orthotropic-eval-fix

## Why

`PH_Mat_ElasticOrthotropic_Eval` 在 mateval 文档包中刻意未改：过程体使用 **单参 `arg`**，但过程内残留 **第二套 dummy 声明**（`mat_desc`/`strain`/`sigma`/`D_matrix`/`status`），与 `PH_Mat_ElasticOrthotropic_Eval_Arg` 不同步（Arg 缺 `strain`/`sigma`/`D_matrix`）。属 **合同/编译卫生** 小修，独立 PR。

## What Changes

- `PH_Mat_ElasticOrthotropic_Eval_Arg`：对齐 `PH_Mat_ElasticIsotropic_Eval_Arg`（`mat_desc` + `strain` + `sigma` + `D_matrix` + `status`）。
- `PH_Mat_ElasticOrthotropic_Eval`：删除多余 dummy；仅通过 `arg%` 读写。
- 可选：`CONTRACT.md` Legacy 表补 orthotropic 行字段说明。

## What NOT

- 正交刚度求逆算法升级、`TEST_PH_Mat_Eval.f90` 旧 In/Out 测试迁移、C2 MatEval 拆族。

## Links

- 前置：[`p1-material-wave5-mateval-arg`](../p1-material-wave5-mateval-arg/)
- backlog：[`p1-material-post-wave5-backlog.md`](../../backlog/p1-material-post-wave5-backlog.md) §4
