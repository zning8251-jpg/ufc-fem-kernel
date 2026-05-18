# `MD_Base_Def.f90`

- **Source**: `L3_MD/Base/MD_Base_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Base_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_NodeTbl_Type` (lines 35–40)

```fortran
  TYPE, PUBLIC :: MD_NodeTbl_Type
    INTEGER(i4)              :: nNodes = 0_i4      ! node count
    INTEGER(i4)              :: nDim   = 3_i4      ! spatial dimension {2,3}
    REAL(wp), ALLOCATABLE    :: coords(:,:)        ! coordinates (nDim x nNodes)
    INTEGER(i4), ALLOCATABLE :: dofMap(:,:)        ! DOF map (maxDof x nNodes)
  END TYPE MD_NodeTbl_Type
```

### `MD_ElemTbl_Type` (lines 48–53)

```fortran
  TYPE, PUBLIC :: MD_ElemTbl_Type
    INTEGER(i4)              :: nElems = 0_i4      ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)          ! element IDs (nElems)
    INTEGER(i4), ALLOCATABLE :: typeId(:)          ! type IDs (nElems)
    INTEGER(i4), ALLOCATABLE :: conn(:,:)          ! connectivity (maxNodes x nElems)
  END TYPE MD_ElemTbl_Type
```

### `MD_ElemDef_Type` (lines 61–70)

```fortran
  TYPE, PUBLIC :: MD_ElemDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! element name (C3D8, S4R)
    CHARACTER(LEN=32)           :: family = ""     ! family (SOLID, SHELL, BEAM)
    INTEGER(i4) :: nNode   = 0_i4                  ! nodes per element
    INTEGER(i4) :: nDof    = 0_i4                  ! DOF per node
    INTEGER(i4) :: nGP     = 0_i4                  ! Gauss point count
    INTEGER(i4) :: nCoord  = 0_i4                  ! coordinate dimension
    INTEGER(i4) :: nStress = 0_i4                  ! stress component count
    LOGICAL     :: isNonlin = .FALSE.              ! nonlinear geometry flag
  END TYPE MD_ElemDef_Type
```

### `MD_ElemDefTbl_Type` (lines 78–81)

```fortran
  TYPE, PUBLIC :: MD_ElemDefTbl_Type
    INTEGER(i4) :: nElemTypes = 0_i4               ! type count
    TYPE(MD_ElemDef_Type), ALLOCATABLE :: ElemDefs(:)  ! definitions array
  END TYPE MD_ElemDefTbl_Type
```

### `MD_MeshCtrl_Type` (lines 89–93)

```fortran
  TYPE, PUBLIC :: MD_MeshCtrl_Type
    TYPE(MD_NodeTbl_Type)    :: NodeTbl            ! node table
    TYPE(MD_ElemTbl_Type)    :: ElemTbl            ! element table
    TYPE(MD_ElemDefTbl_Type) :: ElemDefTbl         ! element definition table
  END TYPE MD_MeshCtrl_Type
```

### `MD_MatDef_Type` (lines 104–112)

```fortran
  TYPE, PUBLIC :: MD_MatDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name     = ""   ! material name
    CHARACTER(LEN=32)           :: category = ""   ! category (Elastic, Plastic)
    CHARACTER(LEN=32)           :: type     = ""   ! type (Isotropic, Orthotropic)
    INTEGER(i4)                 :: nProps   = 0_i4 ! property count
    REAL(wp), ALLOCATABLE       :: props(:)        ! property values (nProps)
    INTEGER(i4)                 :: nState   = 0_i4 ! state variable count
    CHARACTER(LEN=32), ALLOCATABLE :: stateNames(:)  ! state variable names
  END TYPE MD_MatDef_Type
```

### `MD_MatLib_Type` (lines 120–123)

```fortran
  TYPE, PUBLIC :: MD_MatLib_Type
    INTEGER(i4) :: nMats = 0_i4                    ! material count
    TYPE(MD_MatDef_Type), ALLOCATABLE :: MatDefs(:)  ! material definitions
  END TYPE MD_MatLib_Type
```

### `MD_MatAssign_Type` (lines 131–133)

```fortran
  TYPE, PUBLIC :: MD_MatAssign_Type
    INTEGER(i4), ALLOCATABLE :: matIdOfElem(:)     ! material ID per element
  END TYPE MD_MatAssign_Type
```

### `MD_MatCtrl_Type` (lines 141–144)

```fortran
  TYPE, PUBLIC :: MD_MatCtrl_Type
    TYPE(MD_MatLib_Type)    :: MatLib               ! material library
    TYPE(MD_MatAssign_Type) :: MatAssign            ! material assignment
  END TYPE MD_MatCtrl_Type
```

### `MD_SectDef_Type` (lines 155–162)

```fortran
  TYPE, PUBLIC :: MD_SectDef_Type
    INTEGER(i4)                 :: sectId    = 0_i4   ! section ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name      = ""     ! section name
    CHARACTER(LEN=32)           :: type      = ""     ! type (SOLID, SHELL, BEAM)
    REAL(wp)                    :: thickness = 0.0_wp ! section thickness
    CHARACTER(LEN=MD_BASE_SLEN) :: matName   = ""     ! assigned material name
    CHARACTER(LEN=MD_BASE_SLEN) :: elemSet   = ""     ! assigned element set
  END TYPE MD_SectDef_Type
```

### `MD_SectCtrl_Type` (lines 170–173)

```fortran
  TYPE, PUBLIC :: MD_SectCtrl_Type
    INTEGER(i4) :: nSects = 0_i4                   ! section count
    TYPE(MD_SectDef_Type), ALLOCATABLE :: SectDefs(:)  ! section definitions
  END TYPE MD_SectCtrl_Type
```

### `MD_NodeSet_Type` (lines 184–188)

```fortran
  TYPE, PUBLIC :: MD_NodeSet_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! set name
    INTEGER(i4)                 :: nNodes = 0_i4   ! node count
    INTEGER(i4), ALLOCATABLE    :: nodeId(:)       ! node IDs
  END TYPE MD_NodeSet_Type
```

### `MD_ElemSet_Type` (lines 196–200)

```fortran
  TYPE, PUBLIC :: MD_ElemSet_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! set name
    INTEGER(i4)                 :: nElems = 0_i4   ! element count
    INTEGER(i4), ALLOCATABLE    :: elemId(:)       ! element IDs
  END TYPE MD_ElemSet_Type
```

### `MD_Surface_Type` (lines 208–214)

```fortran
  TYPE, PUBLIC :: MD_Surface_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! surface name
    CHARACTER(LEN=32)           :: type   = ""     ! type: ELEMENT, NODE
    INTEGER(i4)                 :: nFaces = 0_i4   ! face count
    INTEGER(i4), ALLOCATABLE    :: elemId(:)       ! element IDs
    INTEGER(i4), ALLOCATABLE    :: faceId(:)       ! face IDs
  END TYPE MD_Surface_Type
```

### `MD_SetCtrl_Type` (lines 222–229)

```fortran
  TYPE, PUBLIC :: MD_SetCtrl_Type
    INTEGER(i4) :: nNodeSets = 0_i4                ! node set count
    INTEGER(i4) :: nElemSets = 0_i4                ! element set count
    INTEGER(i4) :: nSurfaces = 0_i4                ! surface count
    TYPE(MD_NodeSet_Type), ALLOCATABLE  :: NodeSets(:)  ! node sets
    TYPE(MD_ElemSet_Type), ALLOCATABLE  :: ElemSets(:)  ! element sets
    TYPE(MD_Surface_Type), ALLOCATABLE  :: Surfaces(:)  ! surfaces
  END TYPE MD_SetCtrl_Type
```

### `MD_AmpDef_Type` (lines 240–246)

```fortran
  TYPE, PUBLIC :: MD_AmpDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name    = ""    ! amplitude name
    CHARACTER(LEN=32)           :: type    = ""    ! type: TABULAR, SMOOTH, PERIODIC
    INTEGER(i4)                 :: nPoints = 0_i4  ! data point count
    REAL(wp), ALLOCATABLE       :: time(:)         ! time values
    REAL(wp), ALLOCATABLE       :: value(:)        ! amplitude values
  END TYPE MD_AmpDef_Type
```

### `MD_AmpCtrl_Type` (lines 254–257)

```fortran
  TYPE, PUBLIC :: MD_AmpCtrl_Type
    INTEGER(i4) :: nAmps = 0_i4                    ! amplitude count
    TYPE(MD_AmpDef_Type), ALLOCATABLE :: AmpDefs(:)  ! amplitude definitions
  END TYPE MD_AmpCtrl_Type
```

### `MD_StepCfg_Type` (lines 268–276)

```fortran
  TYPE, PUBLIC :: MD_StepCfg_Type
    INTEGER(i4)                 :: stepId   = 0_i4   ! step ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name     = ""     ! step name
    CHARACTER(LEN=32)           :: analysis = ""     ! type: STATIC, DYNAMIC, FREQ
    REAL(wp)                    :: totalTime = 0.0_wp ! total step time
    REAL(wp)                    :: dt       = 0.0_wp  ! time increment
    INTEGER(i4)                 :: nIncs    = 0_i4   ! increment count
    LOGICAL                     :: nlgeom   = .FALSE. ! nonlinear geometry flag
  END TYPE MD_StepCfg_Type
```

### `MD_StepDef_Type` (lines 284–287)

```fortran
  TYPE, PUBLIC :: MD_StepDef_Type
    INTEGER(i4) :: nSteps = 0_i4                   ! step count
    TYPE(MD_StepCfg_Type), ALLOCATABLE :: StepCfg(:)  ! step configurations
  END TYPE MD_StepDef_Type
```

### `MD_MPC_Constraint_Type` (lines 298–307)

```fortran
  TYPE, PUBLIC :: MD_MPC_Constraint_Type
    INTEGER(i4)                 :: id     = 0_i4   ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! constraint name
    INTEGER(i4)                 :: stepId = 0_i4   ! active step ID
    INTEGER(i4)                 :: nNodes = 0_i4   ! node count
    INTEGER(i4), ALLOCATABLE    :: nodeIds(:)      ! node IDs
    INTEGER(i4), ALLOCATABLE    :: dofIds(:)       ! DOF IDs
    REAL(wp), ALLOCATABLE       :: coeffs(:)       ! coefficients
    REAL(wp)                    :: rhs    = 0.0_wp ! right-hand side value
  END TYPE MD_MPC_Constraint_Type
```

### `MD_Eq_Constraint_Type` (lines 315–324)

```fortran
  TYPE, PUBLIC :: MD_Eq_Constraint_Type
    INTEGER(i4)                 :: id     = 0_i4   ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! constraint name
    INTEGER(i4)                 :: stepId = 0_i4   ! active step ID
    INTEGER(i4)                 :: nTerms = 0_i4   ! term count
    INTEGER(i4), ALLOCATABLE    :: nodeIds(:)      ! node IDs
    INTEGER(i4), ALLOCATABLE    :: dofIds(:)       ! DOF IDs
    REAL(wp), ALLOCATABLE       :: coeffs(:)       ! coefficients
    REAL(wp)                    :: rhs    = 0.0_wp ! right-hand side value
  END TYPE MD_Eq_Constraint_Type
```

### `MD_Coupling_Constraint_Type` (lines 332–339)

```fortran
  TYPE, PUBLIC :: MD_Coupling_Constraint_Type
    INTEGER(i4)                 :: id           = 0_i4  ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name         = ""    ! constraint name
    INTEGER(i4)                 :: stepId       = 0_i4  ! active step ID
    INTEGER(i4)                 :: refNodeId    = 0_i4  ! reference node ID
    CHARACTER(LEN=MD_BASE_SLEN) :: surfaceSet   = ""    ! surface set name
    CHARACTER(LEN=32)           :: couplingType = ""    ! KINEMATIC, DISTRIBUTING
  END TYPE MD_Coupling_Constraint_Type
```

### `MD_RigidBody_Constraint_Type` (lines 347–353)

```fortran
  TYPE, PUBLIC :: MD_RigidBody_Constraint_Type
    INTEGER(i4)                 :: id        = 0_i4  ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name      = ""    ! constraint name
    INTEGER(i4)                 :: stepId    = 0_i4  ! active step ID
    INTEGER(i4)                 :: refNodeId = 0_i4  ! reference node ID
    CHARACTER(LEN=MD_BASE_SLEN) :: bodySet   = ""    ! body set name
  END TYPE MD_RigidBody_Constraint_Type
```

### `MD_ConstCtrl_Type` (lines 361–370)

```fortran
  TYPE, PUBLIC :: MD_ConstCtrl_Type
    INTEGER(i4) :: nMPCs        = 0_i4             ! MPC count
    INTEGER(i4) :: nEquations   = 0_i4             ! equation count
    INTEGER(i4) :: nCouplings   = 0_i4             ! coupling count
    INTEGER(i4) :: nRigidBodies = 0_i4             ! rigid body count
    TYPE(MD_MPC_Constraint_Type), ALLOCATABLE       :: mpcs(:)
    TYPE(MD_Eq_Constraint_Type), ALLOCATABLE        :: equations(:)
    TYPE(MD_Coupling_Constraint_Type), ALLOCATABLE  :: couplings(:)
    TYPE(MD_RigidBody_Constraint_Type), ALLOCATABLE :: rigidbodies(:)
  END TYPE MD_ConstCtrl_Type
```

### `MD_Part_Type` (lines 381–387)

```fortran
  TYPE, PUBLIC :: MD_Part_Type
    INTEGER(i4)                 :: partId = 0_i4   ! part ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! part name
    TYPE(MD_MeshCtrl_Type)      :: localMesh       ! part-local mesh data
    INTEGER(i4), ALLOCATABLE    :: matIds(:)       ! assigned material IDs
    INTEGER(i4), ALLOCATABLE    :: sectIds(:)      ! assigned section IDs
  END TYPE MD_Part_Type
```

### `MD_Instance_Type` (lines 395–402)

```fortran
  TYPE, PUBLIC :: MD_Instance_Type
    INTEGER(i4)                 :: instId  = 0_i4  ! instance ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name    = ""    ! instance name
    INTEGER(i4)                 :: partId  = 0_i4  ! referenced part ID
    REAL(wp)                    :: translation(3) = 0.0_wp  ! translation vector
    REAL(wp)                    :: rotation(3,3)   ! rotation matrix
    LOGICAL                     :: isDep   = .FALSE.  ! dependent instance flag
  END TYPE MD_Instance_Type
```

### `MD_Assembly_Type` (lines 410–414)

```fortran
  TYPE, PUBLIC :: MD_Assembly_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name       = ""   ! assembly name
    INTEGER(i4)                 :: nInstances = 0_i4 ! instance count
    TYPE(MD_Instance_Type), ALLOCATABLE :: instances(:)  ! instance array
  END TYPE MD_Assembly_Type
```

### `MD_PartCtrl_Type` (lines 422–426)

```fortran
  TYPE, PUBLIC :: MD_PartCtrl_Type
    INTEGER(i4) :: nParts = 0_i4                   ! part count
    TYPE(MD_Part_Type), ALLOCATABLE :: parts(:)    ! part array
    TYPE(MD_Assembly_Type)          :: assembly    ! assembly container
  END TYPE MD_PartCtrl_Type
```

### `MD_ModelCtrl_Type` (lines 437–452)

```fortran
  TYPE, PUBLIC :: MD_ModelCtrl_Type
    ! Core domain controllers
    TYPE(MD_MeshCtrl_Type)     :: mesh          ! mesh domain
    TYPE(MD_MatCtrl_Type)      :: material      ! material domain
    TYPE(MD_SectCtrl_Type)     :: section       ! section domain
    TYPE(MD_SetCtrl_Type)      :: sets          ! set domain
    TYPE(MD_AmpCtrl_Type)      :: amplitude     ! amplitude domain
    TYPE(MD_StepDef_Type)      :: step          ! step domain
    ! P0 domain controllers
    TYPE(MD_ConstCtrl_Type)    :: constraint    ! constraint domain
    TYPE(MD_PartCtrl_Type)     :: part          ! part/assembly domain
    ! P1 domain controllers (imported)
    TYPE(MD_LoadBC_Ctrl_Type)  :: loadbc        ! load & BC domain
    TYPE(MD_ContactCtrl_Type)  :: interaction   ! contact domain
    TYPE(MD_OutCtrl_Type)      :: output        ! output domain
  END TYPE MD_ModelCtrl_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_ModelCtrl_Init` | 467 | `SUBROUTINE MD_ModelCtrl_Init(ctrl)` |
| SUBROUTINE | `MD_ModelCtrl_Free` | 490 | `SUBROUTINE MD_ModelCtrl_Free(ctrl)` |
| SUBROUTINE | `MD_Base_Free_LocalMesh` | 610 | `SUBROUTINE MD_Base_Free_LocalMesh(mesh)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
