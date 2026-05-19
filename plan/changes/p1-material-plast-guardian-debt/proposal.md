# Change: p1-material-plast-guardian-debt

## Why

wave3–5 已交付 J2 / Dispatch / Hill·Barlat·Crystal Arg / MatEval 文档，但 **`guardian Plast --fail-on-p0` 仍失败**（2026-05-19 基线：**P0=6, P1=1, P2=20**）。本 change 清 **P0/P1 必修债**，并为 touched 文件补 **MOD-001**；**不**做全目录 NAME-001 重命名。

## What Changes

| 优先级 | 规则 | 文件 | 修复 |
|--------|------|------|------|
| P0 | FLOW-003 | `PH_Mat_Plast_Core.f90` | `Populate_From_L3` 仅写 `cfg`/`pop`/`props`；弹性模量经 `props` 读取 |
| P1 | INTF-001 | `PH_Mat_Plast_Chaboche_Core.f90` | `UF_Chaboche_UMAT_Arg` + `UF_Chaboche_UMAT(arg)` |
| — | 挂接 | `PH_MatPLMEval.f90`, `PH_MatPLM_Kernels.f90` | Chaboche CASE → Arg（对齐 Hill） |
| P2 | MOD-001 | touched `Core` / `Chaboche` | Purpose / Theory / Status |

**验收**：`guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` → **P0=0**；touched 文件 INTF P1 清零。

## What NOT

- 全 `Plast/` NAME-001 / CHAIN-001 存量清扫（另开或后续波次）。
- C2 `PH_MatEval` 按族吸收、Orthotropic dummy、Crystal 实装。

## Links

- 前置：wave3–5 已合并（`plan/backlog/p1-material-post-wave5-backlog.md`）
- 快照：`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`
