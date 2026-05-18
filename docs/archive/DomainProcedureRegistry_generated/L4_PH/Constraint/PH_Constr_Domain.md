# `PH_Constr_Domain.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Constr_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Domain`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_Inc_Evo_Ctx` (lines 68–71)

```fortran
  TYPE, PUBLIC :: PH_Constr_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Constr_Inc_Evo_Ctx
```

### `PH_Constraint_Ctx` (lines 73–93)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Constr_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4)              :: step_idx     = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4)              :: incr_idx     = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4)              :: nActiveMPC    = 0_i4
    INTEGER(i4)              :: nActiveRBE    = 0_i4
    INTEGER(i4)              :: nActiveTie    = 0_i4
    INTEGER(i4), ALLOCATABLE :: activeMPCIds(:)
    INTEGER(i4), ALLOCATABLE :: activeRBEIds(:)
    INTEGER(i4), ALLOCATABLE :: activeTieIds(:)
    ! Constraint equation: coeff(j)*u(dof(j)) = rhs
    REAL(wp),    ALLOCATABLE :: mpcCoeffs(:,:)    ! (maxTerms, nMPC)
    INTEGER(i4), ALLOCATABLE :: mpcDofs(:,:)      ! (maxTerms, nMPC)
    REAL(wp),    ALLOCATABLE :: mpcRHS(:)          ! (nMPC)
    ! RBE master-slave connectivity
    INTEGER(i4), ALLOCATABLE :: rbeMasterNode(:)   ! (nRBE)
    INTEGER(i4), ALLOCATABLE :: rbeSlaveNodes(:,:) ! (maxSlaves, nRBE)
    REAL(wp),    ALLOCATABLE :: rbeWeights(:,:)    ! (maxSlaves, nRBE)
  END TYPE PH_Constraint_Ctx
```

### `PH_Constraint_State` (lines 95–102)

```fortran
  TYPE, PUBLIC :: PH_Constraint_State
    REAL(wp), ALLOCATABLE :: lambda_mpc(:)    ! Lagrange multipliers for MPC
    REAL(wp), ALLOCATABLE :: lambda_tie(:)    ! Lagrange multipliers for tie
    REAL(wp), ALLOCATABLE :: g_mpc(:)         ! Constraint residuals (MPC)
    REAL(wp), ALLOCATABLE :: g_tie(:)         ! Constraint residuals (tie)
    LOGICAL,  ALLOCATABLE :: isActive(:)      ! Active/inactive per constraint
    REAL(wp)              :: maxViolation = 0.0_wp
  END TYPE PH_Constraint_State
```

### `PH_Constraint_Params` (lines 104–109)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Params
    INTEGER(i4) :: enforcementMethod = PH_CONSTR_ELIMINATION  ! Preferred: DOF elimination + mask
    REAL(wp)    :: penaltyStiffness  = 1.0e+10_wp
    REAL(wp)    :: constraintTol     = 1.0e-8_wp
    INTEGER(i4) :: maxAugLagIter     = 10_i4
  END TYPE PH_Constraint_Params
```

### `PH_Constr_Register_Arg` (lines 114–118)

```fortran
  TYPE, PUBLIC :: PH_Constr_Register_Arg
    INTEGER(i4) :: constraintType = PH_CONSTR_TYPE_MPC  ! constraint type enum (IN)
    INTEGER(i4) :: constraintId   = 0_i4          ! user-provided id     (IN)
    TYPE(ErrorStatusType) :: status               !                      (OUT)
  END TYPE PH_Constr_Register_Arg
```

### `PH_Constr_GetSummary_Arg` (lines 120–123)

```fortran
  TYPE, PUBLIC :: PH_Constr_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE PH_Constr_GetSummary_Arg
```

### `PH_Constr_AddMPCEquation_Arg` (lines 126–133)

```fortran
  TYPE, PUBLIC :: PH_Constr_AddMPCEquation_Arg
    INTEGER(i4) :: nTerms   = 0_i4         ! IN: number of terms
    REAL(wp),    ALLOCATABLE :: coeffs(:)  ! IN: coefficients (nTerms)
    INTEGER(i4), ALLOCATABLE :: dofs(:)   ! IN: DOF indices (nTerms)
    REAL(wp)    :: rhs      = 0.0_wp      ! IN: RHS value
    INTEGER(i4) :: mpcId    = 0_i4        ! OUT: assigned MPC index
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_AddMPCEquation_Arg
```

### `PH_Constr_Assemble_KauxFaux_Arg` (lines 141–149)

```fortran
  TYPE, PUBLIC :: PH_Constr_Assemble_KauxFaux_Arg
    INTEGER(i4) :: nTotalDOF    = 0_i4    ! IN: total global DOF count
    INTEGER(i4) :: nLambda      = 0_i4    ! IN: number of Lagrange multipliers
    REAL(wp)    :: penaltyStiff = 0.0_wp  ! IN: penalty stiffness (method=Penalty)
    ! OUT: contributions to be added to global K and F by caller
    REAL(wp), ALLOCATABLE :: K_aux(:,:)   ! (nTotalDOF+nLambda, nTotalDOF+nLambda)
    REAL(wp), ALLOCATABLE :: F_aux(:)     ! (nTotalDOF+nLambda)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Assemble_KauxFaux_Arg
```

### `PH_Constr_Apply_Transformation_Arg` (lines 154–163)

```fortran
  TYPE, PUBLIC :: PH_Constr_Apply_Transformation_Arg
    INTEGER(i4) :: nDOF_full    = 0_i4    ! IN: full system DOF count
    INTEGER(i4) :: nDOF_reduced = 0_i4    ! IN: reduced DOF count (after elimination)
    REAL(wp), ALLOCATABLE :: T(:,:)       ! IN: transformation (nDOF_reduced, nDOF_full)
    REAL(wp), ALLOCATABLE :: K_full(:,:)   ! IN: full stiffness (nDOF_full, nDOF_full)
    REAL(wp), ALLOCATABLE :: f_full(:)     ! IN: full RHS (nDOF_full)
    REAL(wp), ALLOCATABLE :: K_red(:,:)   ! OUT: reduced stiffness (nDOF_reduced, nDOF_reduced)
    REAL(wp), ALLOCATABLE :: f_red(:)     ! OUT: reduced RHS (nDOF_reduced)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Apply_Transformation_Arg
```

### `PH_Constr_BuildDofMask_Arg` (lines 167–172)

```fortran
  TYPE, PUBLIC :: PH_Constr_BuildDofMask_Arg
    INTEGER(i4) :: nTotalDOF   = 0_i4    ! IN: total DOF count
    INTEGER(i4), ALLOCATABLE :: dofMask(:)       ! INOUT: 1=free, 0=eliminated (nTotalDOF)
    REAL(wp),    ALLOCATABLE :: constrained_value(:) ! INOUT: prescribed/rhs for eliminated (nTotalDOF)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_BuildDofMask_Arg
```

### `PH_Constr_ExtendCSRForMPC_Arg` (lines 176–185)

```fortran
  TYPE, PUBLIC :: PH_Constr_ExtendCSRForMPC_Arg
    INTEGER(i4) :: nDOF       = 0_i4    ! IN: system size (from rowPtr_in size - 1)
    INTEGER(i4), ALLOCATABLE :: rowPtr_in(:)   ! IN: input CSR (nDOF+1)
    INTEGER(i4), ALLOCATABLE :: colInd_in(:)   ! IN: input col indices
    REAL(wp),    ALLOCATABLE :: values_in(:)   ! IN: input values
    INTEGER(i4), ALLOCATABLE :: rowPtr_out(:)  ! OUT: extended CSR
    INTEGER(i4), ALLOCATABLE :: colInd_out(:)  ! OUT: extended col indices
    REAL(wp),    ALLOCATABLE :: values_out(:)   ! OUT: extended values (copied + zeros for new)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_ExtendCSRForMPC_Arg
```

### `PH_Constr_Apply_Elimination_CSR_Arg` (lines 189–198)

```fortran
  TYPE, PUBLIC :: PH_Constr_Apply_Elimination_CSR_Arg
    INTEGER(i4) :: nDOF       = 0_i4    ! IN: system size
    INTEGER(i4), ALLOCATABLE :: rowPtr(:)   ! INOUT: CSR row pointer (nDOF+1)
    INTEGER(i4), ALLOCATABLE :: colInd(:)   ! INOUT: CSR column indices (nnz)
    REAL(wp),    ALLOCATABLE :: values(:)   ! INOUT: CSR values (nnz)
    REAL(wp),    ALLOCATABLE :: R(:)        ! INOUT: RHS vector (nDOF)
    INTEGER(i4), ALLOCATABLE :: dofMask(:)  ! IN: 1=free, 0=eliminated
    REAL(wp),    ALLOCATABLE :: constrained_value(:) ! IN: for eliminated DOFs
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Apply_Elimination_CSR_Arg
```

### `PH_Constr_Update_Lambda_Arg` (lines 202–208)

```fortran
  TYPE, PUBLIC :: PH_Constr_Update_Lambda_Arg
    INTEGER(i4) :: nLambda   = 0_i4       ! IN: number of Lagrange multipliers
    REAL(wp), ALLOCATABLE :: lambda(:)    ! IN: updated lambda from solve
    REAL(wp), ALLOCATABLE :: u(:)         ! IN: displacement for g=C*u-rhs
    REAL(wp)    :: maxViolation = 0.0_wp  ! OUT: max |g_i|
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Update_Lambda_Arg
```

### `PH_Constraint_Domain` (lines 210–230)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Domain
    TYPE(PH_Constraint_Ctx)    :: ctx
    TYPE(PH_Constraint_State)  :: state
    TYPE(PH_Constraint_Params) :: params
    LOGICAL                    :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: ClearMPCEquations
    PROCEDURE :: PrepareForPopulate
    PROCEDURE :: Register
    PROCEDURE :: AddMPCEquation
    PROCEDURE :: GetSummary
    ! --- Algorithm (Phase B) ---
    PROCEDURE :: Assemble_KauxFaux
    PROCEDURE :: Apply_Transformation
    PROCEDURE :: BuildDofMaskFromMPC
    PROCEDURE :: ExtendCSRForMPC
    PROCEDURE :: Apply_Elimination_CSR
    PROCEDURE :: Update_Lambda
  END TYPE PH_Constraint_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ph_constr_pick_mpc_dep` | 238 | `SUBROUTINE ph_constr_pick_mpc_dep(maxTerms, eq, mpcDofs, mpcCoeffs, depIdx, c_dep)` |
| SUBROUTINE | `Finalize` | 257 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `ClearMPCEquations` | 283 | `SUBROUTINE ClearMPCEquations(this)` |
| SUBROUTINE | `PrepareForPopulate` | 300 | `SUBROUTINE PrepareForPopulate(this)` |
| SUBROUTINE | `Init` | 311 | `SUBROUTINE Init(this, stepId, status, incr_idx)` |
| SUBROUTINE | `Register` | 333 | `SUBROUTINE Register(this, arg)` |
| SUBROUTINE | `PH_Constraint_Register_Impl` | 341 | `SUBROUTINE PH_Constraint_Register_Impl(this, constraintType, &` |
| SUBROUTINE | `GetSummary` | 382 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `PH_Constraint_GetSummary_Impl` | 389 | `SUBROUTINE PH_Constraint_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `AddMPCEquation` | 417 | `SUBROUTINE AddMPCEquation(this, arg)` |
| SUBROUTINE | `Assemble_KauxFaux` | 543 | `SUBROUTINE Assemble_KauxFaux(this, arg)` |
| SUBROUTINE | `BuildDofMaskFromMPC` | 624 | `SUBROUTINE BuildDofMaskFromMPC(this, arg)` |
| SUBROUTINE | `ExtendCSRForMPC` | 665 | `SUBROUTINE ExtendCSRForMPC(this, arg)` |
| SUBROUTINE | `PH_Constraint_MergePairsToCSR` | 756 | `SUBROUTINE PH_Constraint_MergePairsToCSR(nDOF, n, pairs, valTmp, rowPtr_out, colInd_out, values_out, status)` |
| SUBROUTINE | `PH_Constraint_SortPairsByRowCol` | 824 | `SUBROUTINE PH_Constraint_SortPairsByRowCol(n, pairs, ord)` |
| SUBROUTINE | `Apply_Elimination_CSR` | 851 | `SUBROUTINE Apply_Elimination_CSR(this, arg)` |
| SUBROUTINE | `Apply_Transformation` | 949 | `SUBROUTINE Apply_Transformation(this, arg)` |
| SUBROUTINE | `Update_Lambda` | 997 | `SUBROUTINE Update_Lambda(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
