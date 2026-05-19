# Change: p1-material-crystal-w2-multislip

## Why

**W1b**（#13）交付 mat_id **266** 的 **1-slip Schmid** UMAT。工业 CPFEM 需要 **多滑移系** 与 **潜硬化**（latent hardening）。本 change 在 **不改动** `UF_CrystalPlasticity_UMAT_Arg` 公开形状的前提下，扩展内核与 `props`/`statev` 合同。

## What Changes

| 项 | 说明 |
|----|------|
| **W2a** | **N=2** 滑移系（固定），各系 Schmid + 2×2 潜硬化矩阵 |
| **W2b**（可选后续） | 可配置 `N_slip`（`props` 头字段） |
| Core | `PH_Mat_Plast_Crystal_Core.f90` 或拆 `PH_Mat_Plast_Crystal_Kernel.f90` |
| CONTRACT | `statev`/`props` 表；W1b 单系为 **W2a 退化**（`N_slip=1`） |
| Registry | 收紧 mat_id 266 `nprops`/`nstatev` 范围（可选同 PR） |

## What NOT

- 有限应变 / 旋率更新（→ W3 或独立 change）
- 改 `PH_MatPLMEval` CASE 266 打包（除非 `nstatev` 上限需调）
- L3 `MD_MatPLMCrystal` Desc 类型（仍 `props` ABI）

## Preconditions

- `p1-material-crystal-impl` **COMPLETE**（#12–#13 on `main`）
- 至少一个 **双滑移** 解析算例（手算或文献）用于回归

## Links

- 前置：[`p1-material-crystal-impl`](../p1-material-crystal-impl/)
- 快照：[`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
