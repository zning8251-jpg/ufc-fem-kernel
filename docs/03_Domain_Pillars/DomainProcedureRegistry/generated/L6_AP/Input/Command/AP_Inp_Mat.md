# `AP_Inp_Mat.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_Mat.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Mat`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Mat`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Mat`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_Mat.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Creep` | 45 | `subroutine Cmd_Creep(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Damping` | 140 | `subroutine Cmd_Damping(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Elastic` | 231 | `subroutine Cmd_Elastic(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Hyperelastic` | 350 | `subroutine Cmd_Hyperelastic(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Plastic` | 472 | `subroutine Cmd_Plastic(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_UserMaterial` | 593 | `subroutine Cmd_UserMaterial(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Viscoelastic` | 688 | `subroutine Cmd_Viscoelastic(cmd, ctx, status)` |
| SUBROUTINE | `ParseMaterialParams` | 784 | `subroutine ParseMaterialParams(param_str, mat_type, props, num_props, status)` |
| SUBROUTINE | `UF_Cmd_Mat_RegAll` | 924 | `subroutine UF_Cmd_Mat_RegAll(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
