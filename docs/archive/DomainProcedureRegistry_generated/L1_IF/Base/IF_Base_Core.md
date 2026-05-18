# `IF_Base_Core.f90`

- **Source**: `L1_IF/Base/IF_Base_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Base_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Base_Core_Init` | 28 | `SUBROUTINE IF_Base_Core_Init(desc, status)` |
| SUBROUTINE | `IF_Base_Core_Finalize` | 36 | `SUBROUTINE IF_Base_Core_Finalize(desc, status)` |
| FUNCTION | `IF_Base_Get_NDim` | 43 | `FUNCTION IF_Base_Get_NDim(desc) RESULT(ndim)` |
| FUNCTION | `IF_Base_Get_Analysis_Type` | 49 | `FUNCTION IF_Base_Get_Analysis_Type(desc) RESULT(atype)` |
| SUBROUTINE | `IF_Base_Get_Version` | 55 | `SUBROUTINE IF_Base_Get_Version(desc, version)` |
| SUBROUTINE | `IF_Base_Global_Init` | 62 | `SUBROUTINE IF_Base_Global_Init(desc, ndim, analysis_type, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
