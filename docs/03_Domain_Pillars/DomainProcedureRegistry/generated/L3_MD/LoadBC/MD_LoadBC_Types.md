# `MD_LoadBC_Types.f90`

- **Source**: `L3_MD/LoadBC/MD_LoadBC_Types.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LoadBC_Types`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LoadBC_Types`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LoadBC`
- **第四段角色（四段式）**: `_Types`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/LoadBC/MD_LoadBC_Types.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_LoadBC_Ctrl_Type` (lines 19–27)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Ctrl_Type
    TYPE(MD_Load_Desc),  ALLOCATABLE :: loads(:)
    TYPE(MD_BC_Desc),    ALLOCATABLE :: bcs(:)
    TYPE(MD_Load_State), ALLOCATABLE :: load_state(:)
    TYPE(MD_BC_State),   ALLOCATABLE :: bc_state(:)
    INTEGER(i4) :: n_loads = 0_i4
    INTEGER(i4) :: n_bcs   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  END TYPE MD_LoadBC_Ctrl_Type
```

### `MD_LoadBC_StepCtx_Type` (lines 29–35)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_StepCtx_Type
    INTEGER(i4) :: step_idx   = 0_i4
    INTEGER(i4) :: incr_idx   = 0_i4
    REAL(wp)    :: time_curr  = 0.0_wp
    REAL(wp)    :: time_prev  = 0.0_wp
    REAL(wp)    :: dt         = 0.0_wp
  END TYPE MD_LoadBC_StepCtx_Type
```

### `MD_BC_Def_Type` (lines 37–43)

```fortran
  TYPE, PUBLIC :: MD_BC_Def_Type
    INTEGER(i4) :: bc_id    = 0_i4
    INTEGER(i4) :: bc_type  = 0_i4
    INTEGER(i4) :: node_id  = 0_i4
    INTEGER(i4) :: dof      = 0_i4
    REAL(wp)    :: value    = 0.0_wp
  END TYPE MD_BC_Def_Type
```

### `MD_Load_Def_Type` (lines 45–50)

```fortran
  TYPE, PUBLIC :: MD_Load_Def_Type
    INTEGER(i4) :: load_id   = 0_i4
    INTEGER(i4) :: load_type = 0_i4
    INTEGER(i4) :: node_id   = 0_i4
    REAL(wp)    :: magnitude = 0.0_wp
  END TYPE MD_Load_Def_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_LoadBC_Ctrl_Init` | 57 | `SUBROUTINE MD_LoadBC_Ctrl_Init(ctrl)` |
| SUBROUTINE | `MD_LoadBC_Ctrl_Free` | 64 | `SUBROUTINE MD_LoadBC_Ctrl_Free(ctrl)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
