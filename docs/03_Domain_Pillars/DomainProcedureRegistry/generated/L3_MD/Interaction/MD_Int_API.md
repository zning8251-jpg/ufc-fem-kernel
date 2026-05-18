# `MD_Int_API.f90`

- **Source**: `L3_MD/Interaction/MD_Int_API.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_API`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_API`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_API`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_API.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cont_ApplyPenaltyMethod` | 216 | `SUBROUTINE Cont_ApplyPenaltyMethod(contact_nodes, displacements, velocities, &` |
| SUBROUTINE | `Cont_ApplyLagrangeMultiplier` | 297 | `SUBROUTINE Cont_ApplyLagrangeMultiplier(contact_nodes, displacements, &` |
| SUBROUTINE | `ContForceRes_Init_Structured` | 337 | `SUBROUTINE ContForceRes_Init_Structured(in, out, force_res)` |
| SUBROUTINE | `Cont_UpdateGeometry_Structured` | 350 | `SUBROUTINE Cont_UpdateGeometry_Structured(in, out, contact_node)` |
| SUBROUTINE | `Cont_ApplyFriction_Structured` | 363 | `SUBROUTINE Cont_ApplyFriction_Structured(in, out, contact_node)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
