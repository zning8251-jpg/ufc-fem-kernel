# `PH_WB_Mgr.f90`

- **Source**: `L4_PH/Bridge/WriteBack/PH_WB_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_WB_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_WB_Mgr`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_WB`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Bridge/WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/WriteBack/PH_WB_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_WriteBack_Desc` (lines 33–44)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Desc
    LOGICAL :: write_disp = .TRUE.      ! Output displacement flag
    LOGICAL :: write_vel = .FALSE.      ! Output velocity flag (dynamic only)
    LOGICAL :: write_accel = .FALSE.    ! Output acceleration flag (dynamic only)
    LOGICAL :: write_stress = .TRUE.    ! Output stress flag
    LOGICAL :: write_strain = .TRUE.    ! Output strain flag
    INTEGER(i4) :: output_freq = 1_i4   ! Output frequency (every N increments)
    CHARACTER(LEN=256) :: output_dir = "" ! Output directory path
  CONTAINS
    PROCEDURE :: Init => PH_WriteBack_Desc_Init
    PROCEDURE :: Validate => PH_WriteBack_Desc_Validate
  END TYPE PH_WriteBack_Desc
```

### `PH_WriteBack_State` (lines 49–60)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_State
    INTEGER(i4) :: total_nodes = 0_i4         ! Total nodes written
    INTEGER(i4) :: total_elements = 0_i4      ! Total elements written
    INTEGER(i4) :: current_increment = 0_i4   ! Current increment counter
    REAL(wp), ALLOCATABLE :: disp_buffer(:,:) ! Displacement buffer (3, nnodes)
    REAL(wp), ALLOCATABLE :: stress_buffer(:,:) ! Stress buffer (6, nelems)
    REAL(wp), ALLOCATABLE :: strain_buffer(:,:) ! Strain buffer (6, nelems)
  CONTAINS
    PROCEDURE :: Init => PH_WriteBack_State_Init
    PROCEDURE :: Finalize => PH_WriteBack_State_Finalize
    PROCEDURE :: Reset => PH_WriteBack_State_Reset
  END TYPE PH_WriteBack_State
```

### `PH_WriteBack_Args` (lines 65–75)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Args
    INTEGER(i4) :: node_idx = 0_i4          ! Node index
    INTEGER(i4) :: elem_idx = 0_i4          ! Element index
    INTEGER(i4) :: ip_idx = 0_i4            ! Integration point index
    REAL(wp) :: disp(3) = 0.0_wp            ! Displacement vector
    REAL(wp) :: vel(3) = 0.0_wp             ! Velocity vector
    REAL(wp) :: accel(3) = 0.0_wp           ! Acceleration vector
    REAL(wp) :: stress(6) = 0.0_wp          ! Stress tensor (Voigt notation)
    REAL(wp) :: strain(6) = 0.0_wp          ! Strain tensor (Voigt notation)
    TYPE(ErrorStatusType) :: status         ! Error status
  END TYPE PH_WriteBack_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_WriteBack_Desc_Init` | 83 | `SUBROUTINE PH_WriteBack_Desc_Init(this)` |
| FUNCTION | `PH_WriteBack_Desc_Validate` | 95 | `FUNCTION PH_WriteBack_Desc_Validate(this) RESULT(is_valid)` |
| SUBROUTINE | `PH_WriteBack_State_Init` | 117 | `SUBROUTINE PH_WriteBack_State_Init(this, nnodes, nelems)` |
| SUBROUTINE | `PH_WriteBack_State_Finalize` | 138 | `SUBROUTINE PH_WriteBack_State_Finalize(this)` |
| SUBROUTINE | `PH_WriteBack_State_Reset` | 150 | `SUBROUTINE PH_WriteBack_State_Reset(this)` |
| SUBROUTINE | `PH_WriteBack_NodeDisp` | 166 | `SUBROUTINE PH_WriteBack_NodeDisp(node_idx, disp, status)` |
| SUBROUTINE | `PH_WriteBack_NodeVel` | 184 | `SUBROUTINE PH_WriteBack_NodeVel(node_idx, vel, status)` |
| SUBROUTINE | `PH_WriteBack_NodePos` | 202 | `SUBROUTINE PH_WriteBack_NodePos(node_idx, coords, status)` |
| SUBROUTINE | `PH_WriteBack_NodeAccel` | 220 | `SUBROUTINE PH_WriteBack_NodeAccel(node_idx, accel, status)` |
| SUBROUTINE | `PH_WriteBack_ElemStress` | 238 | `SUBROUTINE PH_WriteBack_ElemStress(elem_idx, ip_idx, stress, status)` |
| SUBROUTINE | `PH_WriteBack_ElemStrain` | 257 | `SUBROUTINE PH_WriteBack_ElemStrain(elem_idx, ip_idx, strain, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
