# `MD_Int_Parser.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Parser.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Parser`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Parser`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Parser`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Parser.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Convert_To_Upper` | 61 | `SUBROUTINE Convert_To_Upper(str)` |
| SUBROUTINE | `MD_Parse_ContactPair` | 153 | `SUBROUTINE MD_Parse_ContactPair(lines, num_lines, pair_name, slave_surf, &` |
| SUBROUTINE | `MD_Parse_SurfaceInteraction` | 229 | `SUBROUTINE MD_Parse_SurfaceInteraction(lines, num_lines, interaction_name, &` |
| SUBROUTINE | `MD_Parse_Friction` | 297 | `SUBROUTINE MD_Parse_Friction(lines, num_lines, friction_name, model_type, &` |
| SUBROUTINE | `MD_Parse_InteractionVariables` | 370 | `SUBROUTINE MD_Parse_InteractionVariables(lines, num_lines, variables, num_vars, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
