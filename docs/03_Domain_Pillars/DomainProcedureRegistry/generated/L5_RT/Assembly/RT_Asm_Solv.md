# `RT_Asm_Solv.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Solv.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Solv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Solv`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Solv`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Solv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Asm_Cfg` (lines 188–211)

```fortran
  TYPE, PUBLIC :: RT_Asm_Cfg  ! RT_Assembly_Config
    LOGICAL :: use_parallel = .FALSE.        ! Legacy flag; prefer assembly_mode
    INTEGER(i4) :: assembly_mode = 0_i4      ! 0=SERIAL, 1=OMP_COLORING, 2=OMP_ATOMIC
    LOGICAL :: assemble_stiffness = .TRUE.  ! Assemble K matrix
    LOGICAL :: assemble_load = .TRUE.       ! Assemble F_ext
    LOGICAL :: apply_bc = .TRUE.            ! Apply boundary conditions
    LOGICAL :: apply_contact = .FALSE.      ! Apply contact constraints
    LOGICAL :: apply_l3_constraints = .TRUE. ! Tie/MPC/Cpl/Rigid from L3 constraint_union (penalty, dense patch)
    REAL(wp) :: constraint_penalty = 0.0_wp  ! <=0: use RT_Ldbc default penalty
    LOGICAL :: mpc_penalty_triplet_merge = .TRUE.  ! MPC via triplet merge (large models)
    LOGICAL :: l3_non_mpc_triplet_merge = .TRUE.   ! Tie/Cpl/Rigid penalty via triplet merge
    LOGICAL :: verbose = .FALSE.            ! Verbose output
    INTEGER(i4) :: n_threads = 0_i4         ! 0 = use default
    LOGICAL :: reuse_sparsity = .TRUE.     ! zero values + accumulate into existing CSR
    LOGICAL :: contact_csr_delta_merge = .FALSE.
    INTEGER(i4) :: contact_dense_dof_cap = 0_i4
    LOGICAL :: contact_try_ph_search = .FALSE.
    LOGICAL :: contact_use_triplet_merge = .FALSE.
    INTEGER(i4) :: contact_triplet_merge_max_dof = 0_i4
    ! .TRUE.: LOAD_BODY_FORCE on _Idx path is lumped into F_ext (default, matches legacy).
    ! .FALSE.: skip BODY in RT_Asm_GlobalLoad _Idx; RT_Asm_ComputeResidual injects rho*g into
    !          PH_Element_Compute_Fe_Arg%load_magn_in (do not also call RT_Asm_AddGeostaticGravity).
    LOGICAL :: body_force_lumped_to_fext = .TRUE.
  END TYPE RT_Asm_Cfg
```

### `RT_Asm_Solv_Args` (lines 216–242)

```fortran
  TYPE :: RT_Asm_Solv_Args
  ! Purpose: —�?  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Asm_Solv_Args
```

### `RT_Asm_GlobalStiffness_Arg` (lines 245–249)

```fortran
  TYPE, PUBLIC :: RT_Asm_GlobalStiffness_Arg
    TYPE(RT_CSRMatrix) :: K
    TYPE(RT_Asm_Cfg) :: config
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Asm_GlobalStiffness_Arg
```

### `RT_Asm_ComputeResidual_Arg` (lines 250–257)

```fortran
  TYPE, PUBLIC :: RT_Asm_ComputeResidual_Arg
    REAL(wp), ALLOCATABLE :: u(:)
    REAL(wp) :: lambda = 1.0_wp
    REAL(wp), ALLOCATABLE :: F_ext(:)
    REAL(wp), ALLOCATABLE :: R(:)
    TYPE(RT_CSRMatrix), POINTER :: K_tangent => NULL()
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Asm_ComputeResidual_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_ApplyBC` | 266 | `SUBROUTINE RT_Asm_ApplyBC(model, step, time, dofMap, K, F, dof_mask, config, status)` |
| SUBROUTINE | `RT_Asm_ApplyBC_Displacement_Penalty` | 426 | `SUBROUTINE RT_Asm_ApplyBC_Displacement_Penalty(bc, model, time, dofMap, K, F, &` |
| SUBROUTINE | `RT_Asm_ApplyContact` | 483 | `SUBROUTINE RT_Asm_ApplyContact(model, step, state, K, F, config, status, dofMap, l3_csr_reanalyze_required)` |
| SUBROUTINE | `RT_Asm_MPCPenalty_MergeIntoCSR` | 845 | `SUBROUTINE RT_Asm_MPCPenalty_MergeIntoCSR(K, F, mpc_list, n_mpc, kappa, ndofpn, status, dof_map)` |
| SUBROUTINE | `RT_Asm_ApplyL3Constraints` | 918 | `SUBROUTINE RT_Asm_ApplyL3Constraints(K, F, cfg, status, dofMap, l3_csr_reanalyze_required)` |
| SUBROUTINE | `RT_Asm_Complete` | 1182 | `SUBROUTINE RT_Asm_Complete(model, step, state, time, dofMap, &` |
| SUBROUTINE | `RT_Asm_ComputeResidual` | 1299 | `SUBROUTINE RT_Asm_ComputeResidual(model, step, state, dofMap, u, lambda, &` |
| SUBROUTINE | `RT_Asm_ComputeTangent` | 1416 | `SUBROUTINE RT_Asm_ComputeTangent(model, step, state, dofMap, u, K, config, status)` |
| SUBROUTINE | `RT_Asm_GlobalLoad` | 1431 | `SUBROUTINE RT_Asm_GlobalLoad(model, step, time, dofMap, F_ext, config, status)` |
| SUBROUTINE | `RT_Asm_GlobalStiffness` | 1750 | `SUBROUTINE RT_Asm_GlobalStiffness(model, step, state, dofMap, K, config, status)` |
| SUBROUTINE | `RT_Asm_GlobalStiffness_Idx` | 1965 | `SUBROUTINE RT_Asm_GlobalStiffness_Idx(step_idx, arg, status)` |
| SUBROUTINE | `RT_Asm_ComputeResidual_Idx` | 1988 | `SUBROUTINE RT_Asm_ComputeResidual_Idx(step_idx, arg, status)` |
| SUBROUTINE | `RT_Asm_AssembleK_M_ForModal` | 2012 | `SUBROUTINE RT_Asm_AssembleK_M_ForModal(model, step, K_dense, M_dense, nDOF, status, Kg_dense)` |
| SUBROUTINE | `RT_Asm_AssembleHeatMatrices` | 2104 | `SUBROUTINE RT_Asm_AssembleHeatMatrices(model, K_cond, C_cap, Q_total, nDOF, status)` |
| SUBROUTINE | `RT_Asm_AssembleThermalForce` | 2262 | `SUBROUTINE RT_Asm_AssembleThermalForce(model, T, dofMap, F_th, status, T_ref, alpha)` |
| SUBROUTINE | `RT_Asm_AssembleElectricMatrices` | 2400 | `SUBROUTINE RT_Asm_AssembleElectricMatrices(model, K_elec, Q_elec, nDOF, status, j_body)` |
| SUBROUTINE | `RT_Asm_AssembleAcousticMatrices` | 2537 | `SUBROUTINE RT_Asm_AssembleAcousticMatrices(model, K_ac, Q_ac, nDOF, status)` |
| SUBROUTINE | `RT_Asm_AssembleElectroMagMatrices` | 2656 | `SUBROUTINE RT_Asm_AssembleElectroMagMatrices(model, K_curl, J_s, nDOF, status)` |
| SUBROUTINE | `RT_Asm_AssembleTransportMatrices` | 2774 | `SUBROUTINE RT_Asm_AssembleTransportMatrices(model, K_trans, Q, nDOF, status, v_transport)` |
| SUBROUTINE | `RT_Asm_AssemblePiezoCoupling` | 2889 | `SUBROUTINE RT_Asm_AssemblePiezoCoupling(model, n_u, n_phi, K_ue, status)` |
| SUBROUTINE | `RT_Asm_AssembleJouleHeat` | 3006 | `SUBROUTINE RT_Asm_AssembleJouleHeat(model, phi, Q_joule, nDOF, status)` |
| SUBROUTINE | `RT_Asm_CoupledTE_AssembleThermalBranch` | 3099 | `SUBROUTINE RT_Asm_CoupledTE_AssembleThermalBranch(model, phi_io, solve_electric, &` |
| SUBROUTINE | `RT_Asm_AssembleCreepForce` | 3152 | `SUBROUTINE RT_Asm_AssembleCreepForce(model, step, state, dofMap, u, F_cr, status)` |
| SUBROUTINE | `RT_Asm_AssembleSoilsBlock` | 3274 | `SUBROUTINE RT_Asm_AssembleSoilsBlock(model, step, state, dofMap, K_uu, F_u, status)` |
| SUBROUTINE | `RT_Asm_AddGeostaticGravity` | 3302 | `SUBROUTINE RT_Asm_AddGeostaticGravity(step, F_ext, status)` |
| FUNCTION | `RT_Asm_Solv_LocalJToEqId` | 3329 | `FUNCTION RT_Asm_Solv_LocalJToEqId(dofMap, connect, npe, elem_typ, n_dof, jDOF) RESULT(eq_id)` |
| SUBROUTINE | `RT_Asm_ScatterKe_CSR_Atomic` | 3445 | `SUBROUTINE RT_Asm_ScatterKe_CSR_Atomic(K, Ke, elem_dofs, n_dof)` |
| SUBROUTINE | `RT_Asm_Solv_KeArg_AttachMatProps` | 3477 | `SUBROUTINE RT_Asm_Solv_KeArg_AttachMatProps(ke_arg)` |
| SUBROUTINE | `RT_Asm_Solv_KeArg_ClearMatProps` | 3495 | `SUBROUTINE RT_Asm_Solv_KeArg_ClearMatProps(ke_arg)` |
| SUBROUTINE | `RT_Asm_Solv_FeArg_AttachLoadMagn` | 3505 | `SUBROUTINE RT_Asm_Solv_FeArg_AttachLoadMagn(fe_arg, step, spatial_dim, iElem, asm_cfg)` |
| SUBROUTINE | `RT_Asm_Solv_FeArg_ClearLoadMagn` | 3540 | `SUBROUTINE RT_Asm_Solv_FeArg_ClearLoadMagn(fe_arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
