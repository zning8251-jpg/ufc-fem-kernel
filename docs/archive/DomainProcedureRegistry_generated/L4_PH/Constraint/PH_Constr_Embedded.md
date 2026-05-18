# `PH_Constr_Embedded.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Embedded.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Constr_Embedded`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Embedded`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr_Embedded`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Embedded.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `EmbeddedCore_SearchHostElem` | 36 | `SUBROUTINE EmbeddedCore_SearchHostElem(node_coords, candidate_hosts, &` |
| SUBROUTINE | `EmbeddedCore_TestPointInElem` | 58 | `SUBROUTINE EmbeddedCore_TestPointInElem(point_coords, elem_id, &` |
| SUBROUTINE | `EmbeddedCore_ComputeWeights` | 81 | `SUBROUTINE EmbeddedCore_ComputeWeights(xi_nat, elem_type, &` |
| SUBROUTINE | `EmbeddedCore_AssemblePenalty` | 95 | `SUBROUTINE EmbeddedCore_AssemblePenalty(constraint, alpha, &` |
| SUBROUTINE | `EmbeddedCore_AssembleLagrange` | 120 | `SUBROUTINE EmbeddedCore_AssembleLagrange(constraint, &` |
| SUBROUTINE | `EmbeddedCore_CheckViolation` | 141 | `SUBROUTINE EmbeddedCore_CheckViolation(constraint, &` |
| SUBROUTINE | `EmbeddedCore_FindNearestHost` | 163 | `SUBROUTINE EmbeddedCore_FindNearestHost(node_coords, candidate_hosts, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
