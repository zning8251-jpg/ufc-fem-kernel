# `MD_Model_Core.f90`

- **Source**: `L3_MD/Model/MD_Model_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Model_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Model_Core_Init` | 35 | `SUBROUTINE MD_Model_Core_Init(desc, state, status)` |
| SUBROUTINE | `MD_Model_Core_Finalize` | 63 | `SUBROUTINE MD_Model_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `MD_Model_Core_Set_Name` | 87 | `SUBROUTINE MD_Model_Core_Set_Name(desc, name, status)` |
| FUNCTION | `MD_Model_Core_Get_NDim` | 109 | `FUNCTION MD_Model_Core_Get_NDim(desc) RESULT(ndim)` |
| SUBROUTINE | `MD_Model_Core_Register_Part` | 121 | `SUBROUTINE MD_Model_Core_Register_Part(desc, part_id, status)` |
| SUBROUTINE | `MD_Model_Core_Register_Step` | 145 | `SUBROUTINE MD_Model_Core_Register_Step(desc, step_id, status)` |
| FUNCTION | `MD_Model_Core_Get_N_Parts` | 169 | `FUNCTION MD_Model_Core_Get_N_Parts(desc) RESULT(n)` |
| FUNCTION | `MD_Model_Core_Get_N_Steps` | 181 | `FUNCTION MD_Model_Core_Get_N_Steps(desc) RESULT(n)` |
| SUBROUTINE | `MD_Model_Core_Validate_All` | 193 | `SUBROUTINE MD_Model_Core_Validate_All(desc, status)` |
| SUBROUTINE | `MD_Model_Core_Summary` | 221 | `SUBROUTINE MD_Model_Core_Summary(desc, unit_num, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
