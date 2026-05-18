# `PH_Elem_Reg.f90`

- **Source**: `L4_PH/Element/PH_Elem_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Reg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Reg_Entry` (lines 109–117)

```fortran
  TYPE, PUBLIC :: PH_Elem_Reg_Entry
    INTEGER(i4) :: elem_type = 0_i4
    INTEGER(i4) :: base_elem_type = 0_i4   ! 0 = self; else base for shape/B-matrix
    CHARACTER(LEN=16) :: name = ""
    INTEGER(i4) :: n_ip = 0_i4
    LOGICAL :: is_registered = .FALSE.
    TYPE(PH_Elem_Cfg_Init_Desc) :: cfg
    TYPE(PH_Elem_Pop_Vld_Desc) :: pop
  END TYPE PH_Elem_Reg_Entry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Reg_Add` | 143 | `SUBROUTINE PH_Elem_Reg_Add(elem_type, name, n_nodes, n_ip, n_dof, family_id, status, base_elem_type)` |
| FUNCTION | `PH_Elem_Reg_Get` | 202 | `FUNCTION PH_Elem_Reg_Get(elem_type) RESULT(entry)` |
| FUNCTION | `PH_Elem_Reg_GetBaseElemType` | 221 | `FUNCTION PH_Elem_Reg_GetBaseElemType(elem_type) RESULT(base_type)` |
| FUNCTION | `PH_Elem_Reg_IsRegistered` | 235 | `PURE FUNCTION PH_Elem_Reg_IsRegistered(elem_type) RESULT(ok)` |
| SUBROUTINE | `PH_Elem_Reg_InitAll` | 255 | `SUBROUTINE PH_Elem_Reg_InitAll(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
