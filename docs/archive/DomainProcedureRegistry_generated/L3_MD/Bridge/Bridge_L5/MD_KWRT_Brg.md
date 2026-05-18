# `MD_KWRT_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_KWRT_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_KWRT_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KWRT_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KWRT`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_KWRT_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_RT_KW_ParseComplexFrequency` | 56 | `SUBROUTINE MD_RT_KW_ParseComplexFrequency(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseDirect` | 74 | `SUBROUTINE MD_RT_KW_ParseDirect(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseModalDamping` | 92 | `SUBROUTINE MD_RT_KW_ParseModalDamping(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseModalDynamic` | 110 | `SUBROUTINE MD_RT_KW_ParseModalDynamic(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseResponseSpectrum` | 128 | `SUBROUTINE MD_RT_KW_ParseResponseSpectrum(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseSteadyState` | 146 | `SUBROUTINE MD_RT_KW_ParseSteadyState(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseSubstructure` | 164 | `SUBROUTINE MD_RT_KW_ParseSubstructure(node, props, status)` |
| SUBROUTINE | `MD_RT_KW_ParseStaticRiks` | 182 | `SUBROUTINE MD_RT_KW_ParseStaticRiks(node, riks_ctrl, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
