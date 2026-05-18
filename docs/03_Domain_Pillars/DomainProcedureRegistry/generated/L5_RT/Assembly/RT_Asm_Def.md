# `RT_Asm_Def.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Asm_Desc` (lines 68–95)

```fortran
  TYPE, PUBLIC :: RT_Asm_Desc
    !-- Assembly type flags
    LOGICAL     :: assemble_mass = .FALSE.
    LOGICAL     :: assemble_damping = .FALSE.
    LOGICAL     :: assemble_stiffness = .TRUE.
    LOGICAL     :: assemble_loads = .TRUE.
    
    !-- Assembly range
    INTEGER(i4) :: elem_start = 1_i4
    INTEGER(i4) :: elem_end = 0_i4
    INTEGER(i4) :: node_start = 1_i4
    INTEGER(i4) :: node_end = 0_i4
    
    !-- Constraint information
    INTEGER(i4), POINTER :: constrained_dofs(:) => NULL()
    INTEGER(i4), POINTER :: constraint_types(:) => NULL()  ! 1=Fixed/2=Prescribed/3=Symmetric
    REAL(wp), POINTER    :: constraint_values(:) => NULL()
    
    !-- Matrix properties
    LOGICAL     :: is_symmetric = .TRUE.
    LOGICAL     :: is_positive_definite = .TRUE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetRange
    PROCEDURE :: AddConstraint
    PROCEDURE :: Finalize
  END TYPE RT_Asm_Desc
```

### `RT_Asm_State` (lines 102–132)

```fortran
  TYPE, PUBLIC :: RT_Asm_State
    !-- Assembly progress
    INTEGER(i4) :: current_elem = 0_i4
    INTEGER(i4) :: assembled_elements = 0_i4
    INTEGER(i4) :: total_elements = 0_i4
    REAL(wp)    :: assembly_fraction = 0.0_wp
    
    !-- Matrix/vector status
    REAL(wp)    :: K_matrix_norm = 0.0_wp
    REAL(wp)    :: M_matrix_norm = 0.0_wp
    REAL(wp)    :: f_vector_norm = 0.0_wp
    REAL(wp)    :: assembly_time = 0.0_wp
    
    !-- Statistics
    INTEGER(i4) :: n_nonzero_entries = 0_i4
    INTEGER(i4) :: n_constraints_applied = 0_i4
    INTEGER(i4) :: n_assembled_dofs = 0_i4
    
    !-- Global matrix pointers (reference to memory pool)
    REAL(wp), POINTER :: K_global(:,:) => NULL()
    REAL(wp), POINTER :: M_global(:,:) => NULL()
    REAL(wp), POINTER :: C_global(:,:) => NULL()
    REAL(wp), POINTER :: f_global(:) => NULL()
    
  CONTAINS
    PROCEDURE :: Reset
    PROCEDURE :: UpdateProgress
    PROCEDURE :: ComputeNorms
    PROCEDURE :: AttachMatrices
    PROCEDURE :: Detach
  END TYPE RT_Asm_State
```

### `RT_Asm_Algo` (lines 139–162)

```fortran
  TYPE, PUBLIC :: RT_Asm_Algo
    !-- Assembly strategy
    INTEGER(i4) :: assembly_method = RT_ASM_METHOD_ELEMENT_WISE
    
    !-- Sparse storage format
    INTEGER(i4) :: sparse_format = RT_ASM_SPARSE_CSR
    
    !-- Parallel strategy
    INTEGER(i4) :: parallel_strategy = RT_ASM_PARALLEL_SERIAL
    INTEGER(i4) :: n_threads = 1_i4
    
    !-- Numerical integration
    INTEGER(i4) :: integration_order = 2  ! 2=2x2x2 Gauss points for C3D8
    
    !-- Scaling options
    LOGICAL     :: use_scaling = .FALSE.
    REAL(wp)    :: mass_scaling_factor = 1.0_wp
    REAL(wp)    :: stiffness_scaling_factor = 1.0_wp
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SelectMethod
    PROCEDURE :: ConfigureParallel
  END TYPE RT_Asm_Algo
```

### `RT_Asm_Arg` (lines 172–195)

```fortran
  TYPE, PUBLIC :: RT_Asm_Arg
    !-- DOF mapping (populated by S1_MapDof)
    INTEGER(i4), ALLOCATABLE :: dof_map(:)        ! Global DOF mapping array
    INTEGER(i4) :: n_total_eq = 0_i4              ! Total number of equations
    INTEGER(i4) :: n_nodes = 0_i4                 ! Number of nodes
    
    !-- Element loop results (populated by S2_ElemLoop)
    INTEGER(i4) :: n_elem_assembled = 0_i4        ! Elements assembled in this pass
    LOGICAL     :: elem_loop_done = .FALSE.       ! Flag: element loop completed
    
    !-- Scatter results (populated by S3_Scatter)
    LOGICAL     :: scatter_done = .FALSE.         ! Flag: scatter completed
    INTEGER(i4) :: n_entries_scattered = 0_i4     ! NNZ entries scattered
    
    !-- BC application (populated by S4_ApplyBC)
    INTEGER(i4) :: n_bc_applied = 0_i4            ! BCs applied count
    INTEGER(i4), ALLOCATABLE :: bc_dofs(:)        ! BC DOF indices
    REAL(wp),    ALLOCATABLE :: bc_values(:)      ! BC prescribed values
    INTEGER(i4) :: n_bc = 0_i4                    ! Number of BCs to apply
    
  CONTAINS
    PROCEDURE :: InitArg
    PROCEDURE :: ClearArg
  END TYPE RT_Asm_Arg
```

### `RT_Asm_Ctx` (lines 202–237)

```fortran
  TYPE, PUBLIC :: RT_Asm_Ctx
    !-- Element-level temporaries (stack space, C3D8 example)
    REAL(wp)    :: elem_ke(24,24)    ! Element stiffness
    REAL(wp)    :: elem_me(24,24)    ! Element mass
    REAL(wp)    :: elem_ce(24,24)    ! Element damping
    REAL(wp)    :: elem_fe(24)       ! Element force vector
    
    !-- Integration point temporaries
    REAL(wp)    :: gp_coords(3,8)    ! Gauss point coordinates
    REAL(wp)    :: gp_weights(8)     ! Gauss point weights
    REAL(wp)    :: shape_funcs(8)    ! Shape function values N_i
    REAL(wp)    :: dndx(3,8)         ! Shape function derivatives dN/dx
    
    !-- Jacobian at integration points
    REAL(wp)    :: jacobian(3,3)
    REAL(wp)    :: det_jacobian = 0.0_wp
    REAL(wp)    :: inv_jacobian(3,3)
    
    !-- Local indexing
    INTEGER(i4) :: elem_node_ids(8)  ! Element node numbers
    INTEGER(i4) :: elem_dof_map(24)  ! Element DOF mapping (8 nodes * 3 DOF)
    
    !-- Work pointers (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: temp_array1(:) => NULL()
    REAL(wp), POINTER :: temp_array2(:) => NULL()
    
    !-- Material state pointers (reference to L4_PH)
    REAL(wp), POINTER :: stress_gp(:,:,:) => NULL()  ! (n_gp, 6 components)
    REAL(wp), POINTER :: strain_gp(:,:,:) => NULL()
    
  CONTAINS
    PROCEDURE :: AttachToState
    PROCEDURE :: ClearElementData
    PROCEDURE :: ClearGPData
    PROCEDURE :: Detach
  END TYPE RT_Asm_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Asm_Desc_Init` | 250 | `SUBROUTINE Asm_Desc_Init(self, assemble_K, assemble_M, assemble_C, assemble_f)` |
| SUBROUTINE | `Asm_Desc_SetRange` | 276 | `SUBROUTINE Asm_Desc_SetRange(self, elem_start, elem_end, node_start, node_end)` |
| SUBROUTINE | `Asm_Desc_AddConstraint` | 291 | `SUBROUTINE Asm_Desc_AddConstraint(self, dof_idx, constraint_type, value)` |
| SUBROUTINE | `Asm_Desc_Finalize` | 330 | `SUBROUTINE Asm_Desc_Finalize(self)` |
| SUBROUTINE | `Asm_State_Reset` | 353 | `SUBROUTINE Asm_State_Reset(self)` |
| SUBROUTINE | `Asm_State_UpdateProgress` | 379 | `SUBROUTINE Asm_State_UpdateProgress(self, current_elem)` |
| SUBROUTINE | `Asm_State_ComputeNorms` | 395 | `SUBROUTINE Asm_State_ComputeNorms(self)` |
| SUBROUTINE | `Asm_State_AttachMatrices` | 441 | `SUBROUTINE Asm_State_AttachMatrices(self, K, M, C, f)` |
| SUBROUTINE | `Asm_State_Detach` | 467 | `SUBROUTINE Asm_State_Detach(self)` |
| SUBROUTINE | `Asm_Algo_Init` | 485 | `SUBROUTINE Asm_Algo_Init(self, method, sparse_fmt, parallel_strat, n_threads)` |
| SUBROUTINE | `Asm_Algo_SelectMethod` | 509 | `SUBROUTINE Asm_Algo_SelectMethod(self, method)` |
| SUBROUTINE | `Asm_Algo_ConfigureParallel` | 521 | `SUBROUTINE Asm_Algo_ConfigureParallel(self, strategy, n_threads)` |
| SUBROUTINE | `Asm_Ctx_AttachToState` | 540 | `SUBROUTINE Asm_Ctx_AttachToState(self, state)` |
| SUBROUTINE | `Asm_Ctx_ClearElementData` | 553 | `SUBROUTINE Asm_Ctx_ClearElementData(self)` |
| SUBROUTINE | `Asm_Ctx_ClearGPData` | 569 | `SUBROUTINE Asm_Ctx_ClearGPData(self)` |
| SUBROUTINE | `Asm_Ctx_Detach` | 586 | `SUBROUTINE Asm_Ctx_Detach(self)` |
| SUBROUTINE | `Asm_Arg_Init` | 604 | `SUBROUTINE Asm_Arg_Init(self, n_eq, n_nodes)` |
| SUBROUTINE | `Asm_Arg_Clear` | 630 | `SUBROUTINE Asm_Arg_Clear(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
