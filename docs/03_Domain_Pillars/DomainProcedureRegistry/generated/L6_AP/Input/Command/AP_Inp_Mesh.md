# `AP_Inp_Mesh.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_Mesh.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Mesh`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Mesh`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Mesh`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_Mesh.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Elem` | 38 | `subroutine Cmd_Elem(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Elgen` | 113 | `subroutine Cmd_Elgen(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Elset` | 130 | `subroutine Cmd_Elset(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Ngen` | 181 | `subroutine Cmd_Ngen(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Node` | 199 | `subroutine Cmd_Node(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Nset` | 269 | `subroutine Cmd_Nset(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Orientation` | 339 | `subroutine Cmd_Orientation(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Surface` | 367 | `subroutine Cmd_Surface(cmd, ctx, status)` |
| SUBROUTINE | `map_Elem_type` | 414 | `subroutine map_Elem_type(type_str, type_code, num_nodes, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
