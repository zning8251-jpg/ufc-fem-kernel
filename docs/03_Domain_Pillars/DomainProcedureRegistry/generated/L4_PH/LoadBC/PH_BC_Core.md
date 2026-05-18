# `PH_BC_Core.f90`

- **Source**: `L4_PH/LoadBC/PH_BC_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_BC_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_BC_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_BC`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_BC_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_BC_Core_Init` | 22 | `SUBROUTINE PH_BC_Core_Init(status)` |
| SUBROUTINE | `PH_BC_Core_Finalize` | 28 | `SUBROUTINE PH_BC_Core_Finalize(status)` |
| SUBROUTINE | `PH_BC_Apply_Dirichlet` | 34 | `SUBROUTINE PH_BC_Apply_Dirichlet(dof, value, big_num, K, F, status)` |
| SUBROUTINE | `PH_BC_Apply_Dirichlet_CSR` | 62 | `SUBROUTINE PH_BC_Apply_Dirichlet_CSR(dof, value, big_num, K_csr, F, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
