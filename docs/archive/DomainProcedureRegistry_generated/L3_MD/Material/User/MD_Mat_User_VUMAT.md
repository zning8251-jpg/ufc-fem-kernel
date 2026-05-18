# `MD_Mat_User_VUMAT.f90`

- **Source**: `L3_MD/Material/User/MD_Mat_User_VUMAT.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_User_VUMAT`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_User_VUMAT`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_User_VUMAT`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/User`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/User/MD_Mat_User_VUMAT.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Usr_VUMAT_ValidateProps` | 40 | `SUBROUTINE MD_Usr_VUMAT_ValidateProps(self, nprops, props, st)` |
| SUBROUTINE | `MD_Usr_VUMAT_InitFromProps` | 56 | `SUBROUTINE MD_Usr_VUMAT_InitFromProps(self, nprops, props, st)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
