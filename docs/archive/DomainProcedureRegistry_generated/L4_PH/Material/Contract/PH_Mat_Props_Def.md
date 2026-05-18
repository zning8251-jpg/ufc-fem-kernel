# `PH_Mat_Props_Def.f90`

- **Source**: `L4_PH/Material/Contract/PH_Mat_Props_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Props_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Props_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Props`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Contract/PH_Mat_Props_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Extract_Elastic_Props` | 220 | `SUBROUTINE Extract_Elastic_Props(ctx, PH_MAT_E, nu, alpha, status)` |
| SUBROUTINE | `Extract_Plastic_Props` | 233 | `SUBROUTINE Extract_Plastic_Props(ctx, PH_MAT_E, nu, sy, h, fric, coh, dil, status)` |
| SUBROUTINE | `Extract_Hyperelastic_Props` | 250 | `SUBROUTINE Extract_Hyperelastic_Props(ctx, c10, c01, d1, status)` |
| SUBROUTINE | `Extract_Deformation_Gradient` | 266 | `SUBROUTINE Extract_Deformation_Gradient(statev, F, status)` |
| SUBROUTINE | `Pack_Deformation_Gradient` | 285 | `SUBROUTINE Pack_Deformation_Gradient(F, statev, status)` |
| SUBROUTINE | `Extract_Plastic_State` | 301 | `SUBROUTINE Extract_Plastic_State(statev, eqp, volp, eps_p, status)` |
| SUBROUTINE | `Pack_Plastic_State` | 319 | `SUBROUTINE Pack_Plastic_State(eqp, volp, eps_p, statev, status)` |
| SUBROUTINE | `Extract_Damage_State` | 336 | `SUBROUTINE Extract_Damage_State(statev, d, f_void, status)` |
| SUBROUTINE | `Pack_Damage_State` | 347 | `SUBROUTINE Pack_Damage_State(d, f_void, statev, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
