# `RT_WB_Core.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_WB_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_WB_Desc` (lines 18–22)

```fortran
  TYPE, PUBLIC :: RT_WB_Desc
    CHARACTER(LEN=256) :: wb_path    = ''
    INTEGER(i4)        :: wb_mode    = 0_i4
    LOGICAL            :: is_active  = .TRUE.
  END TYPE RT_WB_Desc
```

### `RT_WB_State` (lines 24–33)

```fortran
  TYPE, PUBLIC :: RT_WB_State
    INTEGER(i4) :: wb_count  = 0_i4
    REAL(wp)    :: last_time = 0.0_wp
    LOGICAL     :: is_open   = .FALSE.
    ! Storage arrays for write-back data (allocated by Init)
    REAL(wp), ALLOCATABLE :: u_store(:)           ! Displacement [ndof]
    REAL(wp), ALLOCATABLE :: stress_store(:,:,:)  ! Stress [ncomp, nip, n_elem]
    REAL(wp), ALLOCATABLE :: sdv_store(:,:,:)     ! SDV [nsdv, nip, n_elem]
    REAL(wp), ALLOCATABLE :: react_store(:)       ! Reactions [ndof]
  END TYPE RT_WB_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_WriteBack_Core_Init` | 45 | `SUBROUTINE RT_WriteBack_Core_Init(desc, state, status)` |
| SUBROUTINE | `RT_WriteBack_Core_Finalize` | 56 | `SUBROUTINE RT_WriteBack_Core_Finalize(state, status)` |
| SUBROUTINE | `RT_WriteBack_Displacements` | 66 | `SUBROUTINE RT_WriteBack_Displacements(desc, state, ndof, u, status)` |
| SUBROUTINE | `RT_WriteBack_Stresses` | 94 | `SUBROUTINE RT_WriteBack_Stresses(desc, state, n_elem, nip, ncomp, &` |
| SUBROUTINE | `RT_WriteBack_SDVs` | 129 | `SUBROUTINE RT_WriteBack_SDVs(desc, state, n_elem, nip, nsdv, sdv, status)` |
| SUBROUTINE | `RT_WriteBack_Reactions` | 162 | `SUBROUTINE RT_WriteBack_Reactions(desc, state, ndof, reactions, status)` |
| SUBROUTINE | `RT_WriteBack_Execute_All` | 189 | `SUBROUTINE RT_WriteBack_Execute_All(desc, state, time, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
