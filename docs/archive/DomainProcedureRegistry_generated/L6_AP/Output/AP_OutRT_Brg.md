# `AP_OutRT_Brg.f90`

- **Source**: `L6_AP/Output/AP_OutRT_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_OutRT_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_OutRT_Brg`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_OutRT`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_OutRT_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Out_SyncToRT` | 41 | `SUBROUTINE AP_Out_SyncToRT(ap_domain, rt_cfg, status)` |
| SUBROUTINE | `AP_Out_EntryToFldReq` | 121 | `SUBROUTINE AP_Out_EntryToFldReq(entry, fld_req, status)` |
| SUBROUTINE | `AP_Out_EntryToHistReq` | 157 | `SUBROUTINE AP_Out_EntryToHistReq(entry, hist_req, status)` |
| SUBROUTINE | `AP_Out_ParseVariableStr` | 190 | `SUBROUTINE AP_Out_ParseVariableStr(variable_str, var_ids)` |
| FUNCTION | `VarNameToId` | 245 | `PURE FUNCTION VarNameToId(name) RESULT(id)` |
| SUBROUTINE | `ToUpper` | 269 | `SUBROUTINE ToUpper(s)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
