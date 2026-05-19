# Change: p1-material-plast-name-debt

## Why

post-wave5 主链刻意 **out of scope** 了全 `Plast/` **NAME-001**（及少量 CHAIN-001）重命名。当前基线（2026-05-19）：

```text
guardian ufc_core/L4_PH/Material/Plast → P0=0, P1=0, P2=17
```

全部为 **P2**；不阻塞功能，但污染 `guardian Plast` 全目录扫描。

## What Changes

- 仅 **重命名 + 调用点同步**（`PH_Mat_*` / `UF_*` 公开 API 若暴露则走 deprecation 别名或单 PR 原子改）
- 受影响文件（示例，以 guardian 为准）：`PH_Mat_Plast_Core`, `PH_Mat_Plast_J2_*`, `PH_Mat_Plast_Hill_Core`, `PH_Mat_Plast_Eval`, …
- 补缺失 **CHAIN-001** 四链注释（若同文件 touched）

## What NOT

- 本构算法 / Arg 合同变更（无功能 diff）
- 跨域 `Dispatch/` 大规模重命名（除非 Plast 公开符号被 USE）
- Crystal W2 / MatEval

## Strategy

1. `guardian Plast` 导出 NAME-001 清单 → `tasks.md` 附表  
2. 按文件 **小 PR** 或 **单 PR 原子**（≤10 文件）  
3. 每批 `naming` / `guardian` 回归

## Links

- 排除记录：[`p1-material-plast-guardian-debt`](../p1-material-plast-guardian-debt/) PR_BODY  
- 快照：[`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
