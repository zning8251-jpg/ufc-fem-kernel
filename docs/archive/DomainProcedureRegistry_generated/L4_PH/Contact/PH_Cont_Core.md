# `PH_Cont_Core.f90`

- **Source**: `L4_PH/Contact/PH_Cont_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/PH_Cont_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Contact_Core_Init` | 46 | `SUBROUTINE PH_Contact_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `PH_Contact_Core_Finalize` | 70 | `SUBROUTINE PH_Contact_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `PH_Contact_Compute_Gap` | 95 | `SUBROUTINE PH_Contact_Compute_Gap(desc, state, ctx, status)` |
| SUBROUTINE | `PH_Contact_Compute_Normal_Force` | 112 | `SUBROUTINE PH_Contact_Compute_Normal_Force(desc, state, status)` |
| SUBROUTINE | `PH_Contact_Compute_Friction_Force` | 129 | `SUBROUTINE PH_Contact_Compute_Friction_Force(desc, state, status)` |
| SUBROUTINE | `PH_Contact_Compute_Stiffness` | 161 | `SUBROUTINE PH_Contact_Compute_Stiffness(desc, state, ctx, status)` |
| FUNCTION | `PH_Contact_Penalty_Param` | 189 | `FUNCTION PH_Contact_Penalty_Param(E, h_elem, scale) RESULT(penalty)` |
| SUBROUTINE | `PH_Contact_Check_Status` | 198 | `SUBROUTINE PH_Contact_Check_Status(desc, state, status)` |
| SUBROUTINE | `PH_Cont_Core_Init` | 216 | `SUBROUTINE PH_Cont_Core_Init(desc, status)` |
| SUBROUTINE | `PH_Cont_Core_Finalize` | 229 | `SUBROUTINE PH_Cont_Core_Finalize(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
