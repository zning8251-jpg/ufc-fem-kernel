# `PH_Field_ComputeConc.f90`

- **Source**: `L4_PH/Field/PH_Field_ComputeConc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Field_ComputeConc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_ComputeConc`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_ComputeConc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_ComputeConc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Field_Compute_Concentration_Explicit` | 36 | `SUBROUTINE PH_Field_Compute_Concentration_Explicit(desc, algo, in, out, status)` |
| SUBROUTINE | `PH_Field_Compute_Concentration_Implicit` | 91 | `SUBROUTINE PH_Field_Compute_Concentration_Implicit(desc, algo, in, out, status)` |
| SUBROUTINE | `PH_Field_Assemble_DiffusionLaplacian` | 130 | `SUBROUTINE PH_Field_Assemble_DiffusionLaplacian(coords, conn, diffusivity, &` |
| SUBROUTINE | `PH_Field_Assemble_ReactionMatrix` | 155 | `SUBROUTINE PH_Field_Assemble_ReactionMatrix(coords, conn, reaction_rate, &` |
| SUBROUTINE | `PH_Field_Assemble_ConcentrationSource` | 180 | `SUBROUTINE PH_Field_Assemble_ConcentrationSource(coords, conn, &` |
| SUBROUTINE | `PH_Field_Apply_ConcBC_Dirichlet` | 204 | `SUBROUTINE PH_Field_Apply_ConcBC_Dirichlet(K_global, F_global, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
