# `RT_Shared_Def.f90`

- **Source**: `L5_RT/Bridge/Shared/RT_Shared_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Shared_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Shared_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Shared`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Bridge/Shared/RT_Shared_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Sol_Cfg` (lines 62–127)

```fortran
  type, public :: RT_Sol_Cfg
    character(len=80) :: name = ""

    ! Linear solver settings (K * du = R)
    integer(i4) :: linearsolvertyp = RT_SOL_LINSOL_I
    integer(i4) :: maxLinearIter    = 10000_i4
    real(wp)    :: linearTol        = 1.0e-6_wp
    integer(i4) :: nThreads         = 1_i4
    logical     :: useGPU           = .false.
    ! Phase7 P1.7.1: GPU configuration
    logical     :: use_gpu_linear = .false.
    logical     :: use_gpu_assembl = .false.
    logical     :: use_gpu_contact = .false.
    integer(i4) :: gpu_device_id = 0
    logical     :: gpu_fallback_to = .true.
    integer(i4) :: matrixStorage    = RT_Sol_Mat_CSR
    logical     :: symmetric        = .true.
    ! Phase3 S4.1: preconditioner (0=auto from symmetric, 1=Jacobi, 2=ILU0, 3=IC0; -1 lfil/droptol = use UF default)
    integer(i4) :: precondType      = 0_i4
    integer(i4) :: precondLfil      = -1_i4
    real(wp)    :: precondDroptol   = -1.0_wp

    ! Nonlinear Newton controls (static NR / implicit dynamics)
    integer(i4) :: maxNewtonIter    = 20_i4
    real(wp)    :: residualTol      = 1.0e-4_wp
    real(wp)    :: correctionTol    = 1.0e-6_wp
    real(wp)    :: energyTol        = 0.0_wp
    ! Phase3 S2.2/S2.4: line search & LBFGS (align with UF_NLParams)
    logical     :: use_line_search  = .false.
    real(wp)    :: ls_min           = 0.1_wp
    real(wp)    :: ls_max           = 1.0_wp
    integer(i4) :: lbfgs_m          = 10_i4
    ! Phase3 S2.3: arc-length (Crisfield/Riks, align with UF_NLParams)
    real(wp)    :: arc_length_init = 0.0_wp
    real(wp)    :: arc_min           = 1.0e-6_wp
    real(wp)    :: arc_max           = 1.0e+2_wp
    real(wp)    :: psi               = 1.0_wp
    ! Phase3 S6.1: convergence criterion (1=force, 2=disp, 3=energy, 4=mixed)
    integer(i4) :: conv_type        = 4_i4

    ! Analysis mode flag
    logical     :: isExplicit       = .false.

    ! Rayleigh damping parameters
    logical     :: useRayleigh      = .false.
    real(wp)    :: alphaRayleigh    = 0.0_wp
    real(wp)    :: betaRayleigh     = 0.0_wp
    logical     :: rayleighinclude = .true.

    ! Contact assembly path selection
    logical     :: usecontactmanag = .false.
    integer(i4) :: contactMethod = 0_i4

    ! HHT-alpha parameters
    logical     :: useHHT           = .false.
    real(wp)    :: alphaHHT         = 0.0_wp

    ! Explicit multi-field update switch
    logical     :: explicitmultifi = .false.
    real(wp)    :: thermalCapacity    = 0.0_wp
    real(wp)    :: poreCapacity       = 0.0_wp
    ! Phase2 N6.1.2/N6.4.2: Precision/Condition/Error estimation flags
    logical     :: enable_precision = .false.
    logical     :: enable_condition = .false.
    logical     :: enable_error_es   = .false.
  end type RT_Sol_Cfg
```

### `RT_Sol_DofMap` (lines 132–154)

```fortran
  type, public :: RT_Sol_DofMap
    integer(i4) :: nTotalEq = 0_i4
    
    ! Node to equation mapping
    integer(i4), allocatable :: nodeToEqStart(:)
    integer(i4), allocatable :: nodeNumDof(:)
    
    ! Equation to node mapping
    integer(i4), allocatable :: eqToNode(:)
    integer(i4), allocatable :: eqToLocal(:)
    
    ! Field info
    integer(i4) :: nFields = 0_i4
    integer(i4), allocatable :: eqFieldId(:)
    integer(i4), allocatable :: fieldEqCount(:)
    integer(i4), allocatable :: eqLocalInField(:)
    
    ! Boundary condition data
    integer(i4), allocatable :: dofMask(:)
    real(wp),    allocatable :: constrained_value(:)
  contains
    final :: RT_Sol_DofMap_Finalize
  end type RT_Sol_DofMap
```

### `RT_CSRMatrix` (lines 159–170)

```fortran
  type, public :: RT_CSRMatrix
    integer(i4) :: nRows = 0_i4
    integer(i4) :: nCols = 0_i4
    integer(i4) :: nnz = 0_i4
    integer(i4), allocatable :: rowPtr(:)
    integer(i4), allocatable :: colInd(:)
    real(wp), allocatable :: values(:)
    logical :: is_symmetric = .false.
    logical :: init = .false.
  contains
    procedure :: matvec
  end type RT_CSRMatrix
```

### `RT_Sol_State` (lines 175–221)

```fortran
  type, public :: RT_Sol_State
    ! Solution vectors (unified memory: pointer + id)
    real(wp), pointer :: u(:) => null()          ! Current displacement (total inc)
    integer(i4) :: u_id = -1
    real(wp), pointer :: du(:) => null()         ! Displacement increment/correction
    integer(i4) :: du_id = -1
    real(wp), pointer :: u_ref(:) => null()      ! Reference displacement
    integer(i4) :: u_ref_id = -1
    real(wp), pointer :: R(:) => null()          ! Residual vector
    integer(i4) :: R_id = -1
    real(wp), pointer :: F_ext(:) => null()     ! External load vector
    integer(i4) :: F_ext_id = -1
    real(wp), pointer :: F_int(:) => null()     ! Internal force vector
    integer(i4) :: F_int_id = -1
    real(wp), pointer :: R_int(:) => null()      ! Internal residual
    integer(i4) :: R_int_id = -1
    
    ! Matrix
    type(RT_CSRMatrix) :: K                ! Tangent stiffness matrix
    
    ! Load factor
    real(wp) :: lambda = 1.0_wp            ! Current load factor
    
    ! State flags
    logical :: initialized = .false.
    integer(i4) :: nDOF = 0_i4
    ! Linear solver statistics
    integer(i4) :: nLinearIter = 0_i4
    real(wp)    :: linearResidual = 0.0_wp
    real(wp)    :: linearSolveTime = 0.0_wp
    ! Nonlinear result
    integer(i4) :: nNewtonIter = 0_i4
    integer(i4) :: nlConverged = 0_i4
    real(wp)    :: nlResidualNorm = 0.0_wp
    real(wp)    :: nlDispNorm = 0.0_wp
    real(wp)    :: nlEnergyNorm = 0.0_wp
    ! Arc-length result
    real(wp)    :: nlLoadFactor = 0.0_wp
    real(wp)    :: nlArcLength  = 0.0_wp
    ! Condition and error estimation
    real(wp)    :: last_condition = 0.0_wp
    real(wp)    :: last_error_esti   = 0.0_wp
  contains
    procedure, public :: Init => RT_Sol_State_Init
    procedure, public :: Destroy => RT_Sol_State_Destroy
    procedure, public :: Clear => RT_Sol_State_Clear
  end type RT_Sol_State
```

### `UF_RT_JobStatus` (lines 230–244)

```fortran
  type, public :: UF_RT_JobStatus
    integer(i4) :: code    = 0_i4  ! Status code
    character(len=256) :: message = ''
    integer(i4) :: id = 0_i4
    integer(i4) :: incId  = 0_i4
    
    integer(i4) :: nStepsTotal      = 0_i4
    integer(i4) :: nStepsCompleted  = 0_i4
    integer(i4) :: nIncsTotal       = 0_i4
    integer(i4) :: nIncsConverged   = 0_i4
    integer(i4) :: totalNewtonIter  = 0_i4
    integer(i4) :: maxNewtonIter    = 0_i4
    integer(i4) :: totalLinearIter  = 0_i4
    integer(i4) :: maxLinearIter    = 0_i4
  end type UF_RT_JobStatus
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Sol_DofMap_Finalize` | 251 | `subroutine RT_Sol_DofMap_Finalize(this)` |
| SUBROUTINE | `RT_CSRMatrix_matvec` | 269 | `subroutine RT_CSRMatrix_matvec(this, x, y)` |
| SUBROUTINE | `RT_Sol_State_Init` | 293 | `subroutine RT_Sol_State_Init(this, nDOF)` |
| SUBROUTINE | `RT_Sol_State_Destroy` | 313 | `subroutine RT_Sol_State_Destroy(this)` |
| SUBROUTINE | `RT_Sol_State_Clear` | 337 | `subroutine RT_Sol_State_Clear(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
