# `PH_Ldbc_Load_Def.f90`

- **Source**: `L4_PH/LoadBC/PH_Ldbc_Load_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Ldbc_Load_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Ldbc_Load_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Ldbc_Load`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Ldbc_Load_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Ldbc_ElemEquivForce_Type` (lines 61–66)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_ElemEquivForce_Type
    INTEGER(i4) :: elemId = 0_i4               ! Element ID
    INTEGER(i4) :: nNodes = 0_i4               ! Number of element nodes
    INTEGER(i4), ALLOCATABLE :: nodeIds(:)     ! Node ID list
    REAL(wp), ALLOCATABLE :: equiv_forces(:,:) ! Equivalent nodal forces (nDofs, nNodes)
  END TYPE PH_Ldbc_ElemEquivForce_Type
```

### `PH_Ldbc_SurfaceTraction_Type` (lines 69–74)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_SurfaceTraction_Type
    CHARACTER(len=slen) :: surfaceName = ""
    INTEGER(i4) :: nFaces = 0_i4
    INTEGER(i4), ALLOCATABLE :: faceIds(:)     ! Face ID list
    REAL(wp), ALLOCATABLE :: traction(:,:)     ! Traction vector (3, nFaces)
  END TYPE PH_Ldbc_SurfaceTraction_Type
```

### `PH_Ldbc_LoadIntegration_Type` (lines 77–81)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_LoadIntegration_Type
    INTEGER(i4) :: quad_order = 2_i4           ! Gauss quadrature order
    LOGICAL :: use_nodal_lumping = .FALSE.     ! Nodal lumping
    LOGICAL :: use_reduced_integration = .FALSE. ! Reduced integration
  END TYPE PH_Ldbc_LoadIntegration_Type
```

### `PH_Ldbc_LoadCache_Type` (lines 84–91)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_LoadCache_Type
    INTEGER(i4) :: loadId = 0_i4               ! Load ID
    INTEGER(i4) :: loadType = 0_i4             ! MD_LBC_Domain LOAD_*
    CHARACTER(len=slen) :: target = ""         ! Target object (node set/element set/surface)
    REAL(wp) :: magnitude(3) = 0.0_wp          ! Load vector
    REAL(wp) :: current_time = 0.0_wp          ! Current time
    REAL(wp) :: amp_factor = 1.0_wp            ! Amplitude factor
  END TYPE PH_Ldbc_LoadCache_Type
```

### `PH_Ldbc_LoadCtrl_Type` (lines 94–118)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_LoadCtrl_Type
    ! Integration strategy
    TYPE(PH_Ldbc_LoadIntegration_Type) :: integration

    ! Load vector
    INTEGER(i4) :: nTotalDOFs = 0_i4
    REAL(wp), ALLOCATABLE :: load_vector(:)    ! Global load vector (nTotalDOFs)

    ! Element equivalent nodal forces
    INTEGER(i4) :: nElemLoads = 0_i4
    TYPE(PH_Ldbc_ElemEquivForce_Type), ALLOCATABLE :: elem_equiv_forces(:)

    ! Surface tractions
    INTEGER(i4) :: nSurfaceLoads = 0_i4
    TYPE(PH_Ldbc_SurfaceTraction_Type), ALLOCATABLE :: surface_tractions(:)

    ! Body loads (gravity, etc.)
    LOGICAL :: has_gravity = .FALSE.
    REAL(wp) :: gravity_vector(3) = 0.0_wp     ! Gravity vector (m/s^2)

    ! Cache current Step's Load list
    INTEGER(i4) :: nActiveLoads = 0_i4
    TYPE(PH_Ldbc_LoadCache_Type), ALLOCATABLE :: load_cache(:)

  END TYPE PH_Ldbc_LoadCtrl_Type
```

### `PH_Ldbc_LoadRhs_Type` (lines 125–127)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_LoadRhs_Type
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_Ldbc_LoadRhs_Type
```

### `PH_Ldbc_LoadMassRhs_Type` (lines 130–133)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_LoadMassRhs_Type
    REAL(wp), ALLOCATABLE :: M(:)
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_Ldbc_LoadMassRhs_Type
```

### `PH_Ldbc_Init_Arg` (lines 136–139)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Init_Arg
    INTEGER(i4) :: nTotalDOFs = 0_i4                  ! [IN]
    TYPE(PH_Ldbc_LoadCtrl_Type) :: ctrl               ! [OUT]
  END TYPE PH_Ldbc_Init_Arg
```

### `PH_Ldbc_SetGravity_Arg` (lines 142–147)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_SetGravity_Arg
    REAL(wp) :: gx = 0.0_wp                          ! [IN] gravity x
    REAL(wp) :: gy = 0.0_wp                          ! [IN] gravity y
    REAL(wp) :: gz = 0.0_wp                          ! [IN] gravity z
    TYPE(PH_Ldbc_LoadCtrl_Type) :: ctrl               ! [INOUT]
  END TYPE PH_Ldbc_SetGravity_Arg
```

### `PH_Ldbc_ApplyLoads_Arg` (lines 150–154)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_ApplyLoads_Arg
    INTEGER(i4) :: nLoads = 0_i4                     ! [IN] number of loads
    TYPE(PH_Ldbc_LoadCache_Type), ALLOCATABLE :: load_cache(:) ! [IN]
    TYPE(PH_Ldbc_LoadCtrl_Type) :: ctrl               ! [INOUT]
  END TYPE PH_Ldbc_ApplyLoads_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Ldbc_Init` | 169 | `SUBROUTINE PH_Ldbc_Init(arg)` |
| SUBROUTINE | `PH_Ldbc_Free` | 194 | `SUBROUTINE PH_Ldbc_Free(ctrl)` |
| SUBROUTINE | `PH_Ldbc_SetGravity` | 233 | `SUBROUTINE PH_Ldbc_SetGravity(arg)` |
| SUBROUTINE | `PH_Ldbc_ApplyLoads` | 244 | `SUBROUTINE PH_Ldbc_ApplyLoads(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
