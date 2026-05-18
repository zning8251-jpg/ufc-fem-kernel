# `PH_WB_Def.f90`

- **Source**: `L4_PH/WriteBack/PH_WB_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_WB_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_WB_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_WB`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/WriteBack/PH_WB_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_WB_Desc` (lines 33–43)

```fortran
  TYPE, PUBLIC :: PH_WB_Desc
    LOGICAL :: write_disp   = .TRUE.    ! Write displacement
    LOGICAL :: write_vel    = .FALSE.   ! Write velocity
    LOGICAL :: write_accel  = .FALSE.   ! Write acceleration
    LOGICAL :: write_stress = .TRUE.    ! Write stress
    LOGICAL :: write_strain = .TRUE.    ! Write strain
    INTEGER(i4) :: output_freq = 1_i4   ! Every N increments
  CONTAINS
    PROCEDURE :: Init     => PH_WB_Desc_Init
    PROCEDURE :: Validate => PH_WB_Desc_Validate
  END TYPE PH_WB_Desc
```

### `PH_WB_State` (lines 50–61)

```fortran
  TYPE, PUBLIC :: PH_WB_State
    INTEGER(i4) :: total_nodes_written = 0_i4
    INTEGER(i4) :: total_elems_written = 0_i4
    REAL(wp), ALLOCATABLE :: disp_buffer(:,:)
    REAL(wp), ALLOCATABLE :: stress_buffer(:,:)
    REAL(wp), ALLOCATABLE :: strain_buffer(:,:)
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init     => PH_WB_State_Init
    PROCEDURE :: Finalize => PH_WB_State_Finalize
    PROCEDURE :: Reset    => PH_WB_State_Reset
  END TYPE PH_WB_State
```

### `PH_WB_Algo` (lines 68–73)

```fortran
  TYPE, PUBLIC :: PH_WB_Algo
    INTEGER(i4) :: format_id        = 1_i4  ! 1=binary, 2=HDF5, 3=ASCII
    LOGICAL     :: validate_checksum = .TRUE.
    LOGICAL     :: compress_buffer   = .FALSE.
    REAL(wp)    :: compression_tol   = 1.0e-12_wp
  END TYPE PH_WB_Algo
```

### `PH_WB_Ctx` (lines 80–86)

```fortran
  TYPE, PUBLIC :: PH_WB_Ctx
    INTEGER(i4) :: current_step_id  = 0_i4
    INTEGER(i4) :: current_inc_id   = 0_i4
    INTEGER(i4) :: buffer_head      = 1_i4
    INTEGER(i4) :: buffer_tail      = 0_i4
    LOGICAL     :: buffer_full      = .FALSE.
  END TYPE PH_WB_Ctx
```

### `PH_WB_Arg` (lines 92–100)

```fortran
  TYPE, PUBLIC :: PH_WB_Arg
    TYPE(PH_WB_Desc)  :: desc     ! [IN]  config
    TYPE(PH_WB_State) :: state    ! [INOUT] state
    TYPE(PH_WB_Algo)  :: algo     ! [IN]  algo
    TYPE(PH_WB_Ctx)   :: ctx      ! [IN]  context
    INTEGER(i4)        :: n_values = 0_i4
    REAL(wp), ALLOCATABLE :: buffer(:)  ! [OUT] formatted buffer
    TYPE(ErrorStatusType) :: status
  END TYPE PH_WB_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_WB_Desc_Init` | 104 | `SUBROUTINE PH_WB_Desc_Init(this)` |
| SUBROUTINE | `PH_WB_Desc_Validate` | 114 | `SUBROUTINE PH_WB_Desc_Validate(this, status)` |
| SUBROUTINE | `PH_WB_State_Init` | 126 | `SUBROUTINE PH_WB_State_Init(this, n_nodes, n_elems)` |
| SUBROUTINE | `PH_WB_State_Finalize` | 147 | `SUBROUTINE PH_WB_State_Finalize(this)` |
| SUBROUTINE | `PH_WB_State_Reset` | 154 | `SUBROUTINE PH_WB_State_Reset(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
