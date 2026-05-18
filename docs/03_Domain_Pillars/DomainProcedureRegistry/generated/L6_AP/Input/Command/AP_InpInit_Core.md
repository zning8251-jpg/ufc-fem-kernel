# `AP_InpInit_Core.f90`

- **Source**: `L6_AP/Input/Command/AP_InpInit_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpInit_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpInit_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpInit`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_InpInit_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_GeostaticStress` | 38 | `subroutine Cmd_GeostaticStress(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_InitialState` | 106 | `subroutine Cmd_InitialState(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_InitialTemperature` | 194 | `subroutine Cmd_InitialTemperature(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_PredefinedField` | 276 | `subroutine Cmd_PredefinedField(cmd, ctx, status)` |
| SUBROUTINE | `UF_Cmd_Initial_RegAll` | 362 | `subroutine UF_Cmd_Initial_RegAll(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
