# `MD_BaseTypes.f90`

- **Source**: `L3_MD/Base/MD_BaseTypes.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_BaseTypes`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_BaseTypes`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_BaseTypes`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_BaseTypes.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_ElemDef_Type` (lines 32–41)

```fortran
  TYPE, PUBLIC :: MD_ElemDef_Type
    CHARACTER(LEN=16) :: name     = ""       ! element name
    CHARACTER(LEN=8)  :: family   = ""       ! element family
    INTEGER(i4)       :: nNode    = 0_i4     ! nodes per element
    INTEGER(i4)       :: nDof     = 0_i4     ! DOF per node
    INTEGER(i4)       :: nGP      = 0_i4     ! Gauss point count
    INTEGER(i4)       :: nCoord   = 0_i4     ! coordinate dimension
    INTEGER(i4)       :: nStress  = 0_i4     ! stress component count
    LOGICAL           :: isNonlin = .FALSE.  ! nonlinear geometry flag
  END TYPE MD_ElemDef_Type
```

### `MD_NodeTbl_Type` (lines 49–54)

```fortran
  TYPE, PUBLIC :: MD_NodeTbl_Type
    INTEGER(i4)              :: nNodes = 0_i4  ! node count
    INTEGER(i4)              :: nDim   = 3_i4  ! spatial dimension
    REAL(wp), ALLOCATABLE    :: coords(:,:)    ! coordinates (nDim x nNodes)
    INTEGER(i4), ALLOCATABLE :: dofMap(:,:)    ! DOF map
  END TYPE MD_NodeTbl_Type
```

### `MD_ElemTbl_Type` (lines 62–67)

```fortran
  TYPE, PUBLIC :: MD_ElemTbl_Type
    INTEGER(i4)              :: nElems = 0_i4  ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)      ! element IDs
    INTEGER(i4), ALLOCATABLE :: typeId(:)      ! type IDs
    INTEGER(i4), ALLOCATABLE :: conn(:,:)      ! connectivity
  END TYPE MD_ElemTbl_Type
```

### `MD_ElemDefTbl_Type` (lines 75–78)

```fortran
  TYPE, PUBLIC :: MD_ElemDefTbl_Type
    INTEGER(i4) :: nElemTypes = 0_i4                   ! type count
    TYPE(MD_ElemDef_Type), ALLOCATABLE :: ElemDefs(:)   ! definitions
  END TYPE MD_ElemDefTbl_Type
```

### `MD_MeshCtrl_Type` (lines 86–90)

```fortran
  TYPE, PUBLIC :: MD_MeshCtrl_Type
    TYPE(MD_NodeTbl_Type)    :: NodeTbl     ! node table
    TYPE(MD_ElemTbl_Type)    :: ElemTbl     ! element table
    TYPE(MD_ElemDefTbl_Type) :: ElemDefTbl  ! element definitions
  END TYPE MD_MeshCtrl_Type
```

### `MD_MatDef_Type` (lines 98–106)

```fortran
  TYPE, PUBLIC :: MD_MatDef_Type
    CHARACTER(LEN=32) :: name     = ""       ! material name
    CHARACTER(LEN=16) :: category = ""       ! category
    CHARACTER(LEN=16) :: type     = ""       ! type
    INTEGER(i4)       :: nProps   = 0_i4     ! property count
    REAL(wp), ALLOCATABLE :: props(:)        ! properties
    INTEGER(i4)       :: nState   = 0_i4     ! state variable count
    CHARACTER(LEN=32), ALLOCATABLE :: stateNames(:)  ! state names
  END TYPE MD_MatDef_Type
```

### `MD_MatLib_Type` (lines 114–117)

```fortran
  TYPE, PUBLIC :: MD_MatLib_Type
    INTEGER(i4) :: nMats = 0_i4                        ! material count
    TYPE(MD_MatDef_Type), ALLOCATABLE :: MatDefs(:)    ! materials
  END TYPE MD_MatLib_Type
```

### `MD_MatAssign_Type` (lines 125–127)

```fortran
  TYPE, PUBLIC :: MD_MatAssign_Type
    INTEGER(i4), ALLOCATABLE :: matIdOfElem(:)  ! mat ID per element
  END TYPE MD_MatAssign_Type
```

### `MD_MatCtrl_Type` (lines 135–138)

```fortran
  TYPE, PUBLIC :: MD_MatCtrl_Type
    TYPE(MD_MatLib_Type)    :: MatLib     ! material library
    TYPE(MD_MatAssign_Type) :: MatAssign  ! assignment
  END TYPE MD_MatCtrl_Type
```

### `MD_SectDef_Type` (lines 146–151)

```fortran
  TYPE, PUBLIC :: MD_SectDef_Type
    INTEGER(i4)       :: sectId    = 0_i4    ! section ID
    CHARACTER(LEN=32) :: name      = ""      ! section name
    CHARACTER(LEN=16) :: type      = ""      ! section type
    REAL(wp)          :: thickness = 0.0_wp  ! thickness
  END TYPE MD_SectDef_Type
```

### `MD_SectCtrl_Type` (lines 159–162)

```fortran
  TYPE, PUBLIC :: MD_SectCtrl_Type
    INTEGER(i4) :: nSects = 0_i4                       ! section count
    TYPE(MD_SectDef_Type), ALLOCATABLE :: SectDefs(:)  ! sections
  END TYPE MD_SectCtrl_Type
```

### `MD_NodeSet_Type` (lines 170–174)

```fortran
  TYPE, PUBLIC :: MD_NodeSet_Type
    CHARACTER(LEN=32) :: name   = ""       ! set name
    INTEGER(i4)       :: nNodes = 0_i4     ! node count
    INTEGER(i4), ALLOCATABLE :: nodeId(:)  ! node IDs
  END TYPE MD_NodeSet_Type
```

### `MD_ElemSet_Type` (lines 182–186)

```fortran
  TYPE, PUBLIC :: MD_ElemSet_Type
    CHARACTER(LEN=32) :: name   = ""       ! set name
    INTEGER(i4)       :: nElems = 0_i4     ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)  ! element IDs
  END TYPE MD_ElemSet_Type
```

### `MD_SetCtrl_Type` (lines 194–197)

```fortran
  TYPE, PUBLIC :: MD_SetCtrl_Type
    TYPE(MD_NodeSet_Type), ALLOCATABLE :: NodeSets(:)  ! node sets
    TYPE(MD_ElemSet_Type), ALLOCATABLE :: ElemSets(:)  ! element sets
  END TYPE MD_SetCtrl_Type
```

### `MD_AmpDef_Type` (lines 205–209)

```fortran
  TYPE, PUBLIC :: MD_AmpDef_Type
    CHARACTER(LEN=32) :: name = ""          ! amplitude name
    REAL(wp), ALLOCATABLE :: time(:)        ! time values
    REAL(wp), ALLOCATABLE :: value(:)       ! amplitude values
  END TYPE MD_AmpDef_Type
```

### `MD_AmpCtrl_Type` (lines 217–220)

```fortran
  TYPE, PUBLIC :: MD_AmpCtrl_Type
    INTEGER(i4) :: nAmps = 0_i4                       ! amplitude count
    TYPE(MD_AmpDef_Type), ALLOCATABLE :: AmpDefs(:)   ! amplitudes
  END TYPE MD_AmpCtrl_Type
```

### `MD_StepCfg_Type` (lines 228–233)

```fortran
  TYPE, PUBLIC :: MD_StepCfg_Type
    CHARACTER(LEN=32) :: name      = ""      ! step name
    CHARACTER(LEN=16) :: analysis  = ""      ! analysis type
    REAL(wp)          :: totalTime = 0.0_wp  ! total step time
    REAL(wp)          :: dt        = 0.0_wp  ! time increment
  END TYPE MD_StepCfg_Type
```

### `MD_StepDef_Type` (lines 241–244)

```fortran
  TYPE, PUBLIC :: MD_StepDef_Type
    INTEGER(i4) :: nSteps = 0_i4                       ! step count
    TYPE(MD_StepCfg_Type), ALLOCATABLE :: StepCfg(:)   ! step configs
  END TYPE MD_StepDef_Type
```

### `MD_ModelCtrl_Type` (lines 252–259)

```fortran
  TYPE, PUBLIC :: MD_ModelCtrl_Type
    TYPE(MD_MeshCtrl_Type) :: mesh       ! mesh domain
    TYPE(MD_MatCtrl_Type)  :: material   ! material domain
    TYPE(MD_SectCtrl_Type) :: section    ! section domain
    TYPE(MD_SetCtrl_Type)  :: sets       ! set domain
    TYPE(MD_AmpCtrl_Type)  :: amplitude  ! amplitude domain
    TYPE(MD_StepDef_Type)  :: step       ! step domain
  END TYPE MD_ModelCtrl_Type
```

### `ShapeFuncResult` (lines 308–320)

```fortran
  TYPE, PUBLIC :: ShapeFuncResult
    INTEGER(i4) :: numNodes     = 0_i4     ! node count
    INTEGER(i4) :: numIntPoints = 0_i4     ! integration point count
    REAL(wp), ALLOCATABLE :: N(:,:)        ! shape functions (nNode x nIP)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:,:)  ! derivatives in natural coords
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:)   ! (nNode x nDim) for Jacobian
    REAL(wp), ALLOCATABLE :: dNdx(:,:,:)   ! derivatives in physical coords
    REAL(wp), ALLOCATABLE :: detJ(:)       ! Jacobian determinants
    REAL(wp), ALLOCATABLE :: weights(:)    ! integration weights
  CONTAINS
    PROCEDURE, PUBLIC :: Init  => ShapeFuncResult_Init
    PROCEDURE, PUBLIC :: Clear => ShapeFuncResult_Clear
  END TYPE ShapeFuncResult
```

### `UF_ElemFormul` (lines 428–437)

```fortran
  TYPE, PUBLIC :: UF_ElemFormul
    INTEGER(i4) :: formulationType    = 0                    ! formulation type ID
    INTEGER(i4) :: order              = 1                    ! polynomial order
    INTEGER(i4) :: nIntPoints         = 0                    ! integration point count
    LOGICAL     :: reducedintegrat    = .FALSE.              ! reduced integration flag
    LOGICAL     :: hourglasscontro    = .FALSE.              ! hourglass control flag
    INTEGER(i4) :: integration_scheme = MD_MODEL_UF_INT_Full ! integration scheme
    INTEGER(i4) :: kineFormulation    = MD_MODEL_UF_FORM_UL  ! kinematic formulation
    LOGICAL     :: use_bbar           = .FALSE.              ! B-bar method flag
  END TYPE UF_ElemFormul
```

### `State_Instance` (lines 516–519)

```fortran
  TYPE, PUBLIC :: State_Instance
    INTEGER(i4) :: id     = 0_i4    ! instance ID
    LOGICAL     :: active = .FALSE. ! active flag
  END TYPE State_Instance
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ShapeFuncResult_Init` | 329 | `SUBROUTINE ShapeFuncResult_Init(this, numNodes, numIntPoints)` |
| SUBROUTINE | `ShapeFuncResult_Clear` | 356 | `SUBROUTINE ShapeFuncResult_Clear(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
