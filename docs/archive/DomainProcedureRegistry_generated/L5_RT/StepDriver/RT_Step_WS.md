# `RT_Step_WS.f90`

- **Source**: `L5_RT/StepDriver/RT_Step_WS.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_Step_WS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Step_WS`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Step_WS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_Step_WS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `JobMemEstimate` (lines 30–37)

```fortran
  TYPE, PUBLIC :: JobMemEstimate
    INTEGER(i4) :: maxStructDOF = 0_i4
    INTEGER(i4) :: maxThermalNodes = 0_i4
    INTEGER(i4) :: maxPoroNodes = 0_i4
    INTEGER(i4) :: maxTHMNodes = 0_i4
    INTEGER(i4) :: maxElementNodes = 0_i4
    REAL(wp) :: estimatedmemory = 0.0_wp
  END TYPE JobMemEstimate
```

### `JobWS` (lines 42–47)

```fortran
  TYPE, PUBLIC :: JobWS
    TYPE(UF_Model), POINTER :: model => NULL()
    TYPE(JobMemEstimate) :: mem_est
    INTEGER(i4) :: numThreads = 1_i4
    LOGICAL :: init = .FALSE.
  END TYPE JobWS
```

### `StructWS` (lines 52–59)

```fortran
  TYPE, PUBLIC :: StructWS
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    REAL(wp), ALLOCATABLE :: Me(:,:)
    REAL(wp), ALLOCATABLE :: Ce(:,:)
    REAL(wp), ALLOCATABLE :: B(:,:)
    REAL(wp), ALLOCATABLE :: Re(:)
    LOGICAL :: preheated = .FALSE.
  END TYPE StructWS
```

### `UelPools` (lines 64–79)

```fortran
  TYPE, PUBLIC :: UelPools
    REAL(wp), ALLOCATABLE :: RHS(:,:)
    REAL(wp), ALLOCATABLE :: COORDS(:,:)
    REAL(wp), ALLOCATABLE :: U(:)
    REAL(wp), ALLOCATABLE :: DU(:,:)
    REAL(wp), ALLOCATABLE :: V(:)
    REAL(wp), ALLOCATABLE :: A(:)
    REAL(wp), ALLOCATABLE :: PREDEF(:,:,:)
    REAL(wp), ALLOCATABLE :: ADLMAG(:,:)
    REAL(wp), ALLOCATABLE :: DDLMAG(:,:)
    INTEGER(i4), ALLOCATABLE :: JDLTYP(:,:)
    REAL(wp), ALLOCATABLE :: SVARS(:)
    REAL(wp), ALLOCATABLE :: PROPS(:)
    REAL(wp), ALLOCATABLE :: PARAMS(:)
    LOGICAL :: preheated = .FALSE.
  END TYPE UelPools
```

### `ThreadWS` (lines 84–113)

```fortran
  TYPE, PUBLIC :: ThreadWS
    TYPE(JobWS), POINTER :: job => NULL()
    INTEGER(i4) :: tid = -1_i4
    TYPE(StructWS) :: ws_struct
    TYPE(UelPools) :: uel_pools
    TYPE(UF_AbaqusUMATVars) :: umat_ws

    ! Solver workspace arrays
    REAL(wp), ALLOCATABLE :: solver_u(:)
    REAL(wp), ALLOCATABLE :: solver_du(:)
    REAL(wp), ALLOCATABLE :: solver_F_ext(:)
    REAL(wp), ALLOCATABLE :: solver_R(:)
    REAL(wp), ALLOCATABLE :: solver_u_ref(:)
    REAL(wp), ALLOCATABLE :: solver_R_int(:)

    ! PCG solver workspace vectors
    REAL(wp), ALLOCATABLE :: pcg_r(:)
    REAL(wp), ALLOCATABLE :: pcg_z(:)
    REAL(wp), ALLOCATABLE :: pcg_p(:)
    REAL(wp), ALLOCATABLE :: pcg_Ap(:)

    ! Iteration workspace
    REAL(wp), ALLOCATABLE :: iter_u_curr(:)
    REAL(wp), ALLOCATABLE :: iter_du_corr(:)
    REAL(wp), ALLOCATABLE :: iter_R_work(:)
    REAL(wp), ALLOCATABLE :: iter_u_prev(:)
    REAL(wp), ALLOCATABLE :: iter_F_int(:)
    INTEGER(i4) :: iter_max_nDOF = 0_i4
    LOGICAL :: iter_preheated = .FALSE.
  END TYPE ThreadWS
```

### `Owners` (lines 118–130)

```fortran
  TYPE, PUBLIC :: Owners
    TYPE(UF_Model)         :: model
    TYPE(RT_Sol_Cfg)            :: solver
    TYPE(GlobalState)       :: global
    TYPE(NodeState),    ALLOCATABLE :: nodeStates(:)
    TYPE(ElemState), ALLOCATABLE :: elemStates(:)
    TYPE(RT_Sol_DofMap)          :: dofMap
    TYPE(MeshGlobalNum)     :: globNum
    TYPE(ThreadWS), ALLOCATABLE :: workspaces(:)
  CONTAINS
    PROCEDURE :: Init
    FINAL :: Owners_Final
  END TYPE Owners
```

### `Ctx` (lines 135–137)

```fortran
  TYPE, PUBLIC :: Ctx
    TYPE(Owners), POINTER :: owners => NULL()
  END TYPE Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Owners_Init` | 144 | `SUBROUTINE Owners_Init(this, numThreads)` |
| SUBROUTINE | `Owners_Final` | 155 | `SUBROUTINE Owners_Final(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
