# `MD_KW_Dispatch.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Dispatch.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_Dispatch`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Dispatch`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Dispatch`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Dispatch.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_KW_Dispatch_Info` | 50 | `SUBROUTINE MD_KW_Dispatch_Info(domain_id, info_str, status)` |
| SUBROUTINE | `MD_KW_GetDomain` | 104 | `SUBROUTINE MD_KW_GetDomain(keyword_name, domain_id, status)` |
| SUBROUTINE | `MD_KW_GetTypeStr` | 190 | `SUBROUTINE MD_KW_GetTypeStr(keyword_name, type_str, status)` |
| SUBROUTINE | `to_upper` | 212 | `SUBROUTINE to_upper(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
