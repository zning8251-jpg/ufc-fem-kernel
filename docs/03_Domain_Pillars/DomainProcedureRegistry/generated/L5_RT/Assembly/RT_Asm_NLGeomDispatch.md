# `RT_Asm_NLGeomDispatch.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_NLGeomDispatch.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_NLGeomDispatch`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_NLGeomDispatch`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_NLGeomDispatch`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_NLGeomDispatch.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ElemNL_FuncPtr` (lines 92–96)

```fortran
  TYPE :: ElemNL_FuncPtr
    LOGICAL :: is_registered = .FALSE.
    INTEGER(i4) :: elem_type_id
    CHARACTER(LEN=32) :: elem_name
  END TYPE ElemNL_FuncPtr
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_NLGeom_Dispatch_Init` | 107 | `SUBROUTINE RT_Asm_NLGeom_Dispatch_Init(status)` |
| SUBROUTINE | `RT_Asm_NLGeom_RegElemFam` | 289 | `SUBROUTINE RT_Asm_NLGeom_RegElemFam(elem_type_id, elem_name, status)` |
| SUBROUTINE | `RT_Asm_NLGeom_Dispatch_TL` | 322 | `SUBROUTINE RT_Asm_NLGeom_Dispatch_TL(elem_type_id, coords_ref, u_elem, D, &` |
| SUBROUTINE | `RT_Asm_NLGeom_Dispatch_UL` | 856 | `SUBROUTINE RT_Asm_NLGeom_Dispatch_UL(elem_type_id, coords_prev, u_incr, D, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
