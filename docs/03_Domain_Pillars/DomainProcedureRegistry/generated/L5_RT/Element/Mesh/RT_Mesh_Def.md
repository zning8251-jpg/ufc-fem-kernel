# `RT_Mesh_Def.f90`

- **Source**: `L5_RT/Element/Mesh/RT_Mesh_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Mesh_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mesh_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mesh`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/Mesh/RT_Mesh_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mesh_Base_Desc` (lines 33–46)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Base_Desc
    !-- Runtime identification
    INTEGER(i4) :: runtime_id = 0_i4        ! Runtime mesh ID (unique in model)
    CHARACTER(LEN=64) :: mesh_label = ''    ! Human-readable label
    LOGICAL :: is_active = .FALSE.          ! Activation flag
    !-- Link to L3_MD registry (read-only reference)
    TYPE(MD_Mesh_Registry), POINTER :: md_registry => NULL()
    !-- Runtime caching
    INTEGER(i4) :: cached_nnodes = 0_i4     ! Cached node count
    INTEGER(i4) :: cached_nelems = 0_i4     ! Cached element count
    LOGICAL :: cache_valid = .FALSE.
    !-- Error tracking
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Base_Desc
```

### `RT_Mesh_Base_State` (lines 52–71)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Base_State
    !-- Node coordinates (current configuration, updated each increment)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! [nnodes, 3] current positions
    REAL(wp), ALLOCATABLE :: node_displ(:,:)   ! [nnodes, 3] displacements
    REAL(wp), ALLOCATABLE :: node_velocity(:,:)! [nnodes, 3] velocities
    REAL(wp), ALLOCATABLE :: node_accel(:,:)   ! [nnodes, 3] accelerations
    !-- DOF numbering (global equation numbers)
    INTEGER(i4), ALLOCATABLE :: dof_numbers(:,:) ! [nnodes, ndof_per_node]
    INTEGER(i4) :: total_active_dof = 0_i4    ! Total active DOFs in model
    !-- Element state
    INTEGER(i4), ALLOCATABLE :: elem_status(:)  ! [nelems] element flags
    !-- Partition information (for parallel computing)
    INTEGER(i4), ALLOCATABLE :: node_partition(:) ! [nnodes] partition ID
    INTEGER(i4), ALLOCATABLE :: elem_partition(:) ! [nelems] partition ID
    INTEGER(i4) :: n_partitions = 0_i4
    !-- Convergence bookkeeping
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: numbering_complete = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Base_State
```

### `RT_Mesh_Base_Algo` (lines 77–95)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Base_Algo
    !-- DOF numbering strategy
    INTEGER(i4) :: numbering_scheme = 1_i4  ! 1=node-wise, 2=element-wise, 3=optimal
    LOGICAL :: enforce_contiguous = .TRUE.  ! Try to keep DOF numbers contiguous
    LOGICAL :: use_reverse_cuthill_mckee = .FALSE. ! RCM reordering for bandwidth reduction
    !-- Mesh partitioning (for parallel computing)
    LOGICAL :: use_partitioning = .FALSE.   ! Enable domain decomposition
    INTEGER(i4) :: target_partitions = 1_i4 ! Number of partitions
    INTEGER(i4) :: partition_strategy = 1_i4 ! 1=geometric, 2=graph-based
    !-- Assembly optimization
    LOGICAL :: precompute_connectivity = .TRUE. ! Precompute sparse pattern
    LOGICAL :: cache_elem_matrices = .TRUE.     ! Cache element matrices
    INTEGER(i4) :: sparse_storage_format = 1_i4 ! 1=CSR, 2=CSC, 3=COO
    !-- Debug/diagnostics
    LOGICAL :: print_numbering_info = .FALSE.
    LOGICAL :: compute_bandwidth = .TRUE.     ! Compute matrix bandwidth profile
    !-- Status
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Base_Algo
```

### `RT_Mesh_Base_Ctx` (lines 101–123)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Base_Ctx
    !-- Current analysis step info
    INTEGER(i4) :: curr_step = 0_i4
    INTEGER(i4) :: curr_incr = 0_i4
    INTEGER(i4) :: curr_iter = 0_i4
    REAL(wp) :: curr_time = 0.0_wp
    REAL(wp) :: curr_dt = 0.0_wp
    !-- Operation flags
    LOGICAL :: update_coordinates = .FALSE. ! Update nodal coords this incr
    LOGICAL :: update_state = .FALSE.       ! Update element state this incr
    LOGICAL :: renumber_dofs = .FALSE.      ! Re-DOF numbering
    LOGICAL :: rebuild_connectivity = .FALSE. ! Rebuild sparse pattern
    !-- Spatial context (for localized operations)
    INTEGER(i4) :: elem_start = 1_i4        ! Start element index for partial update
    INTEGER(i4) :: elem_end = 0_i4          ! End element index
    INTEGER(i4) :: node_start = 1_i4        ! Start node index
    INTEGER(i4) :: node_end = 0_i4          ! End node index
    !-- Parallel context
    INTEGER(i4) :: thread_id = 0_i4         ! Thread ID for parallel ops
    INTEGER(i4) :: n_threads = 1_i4         ! Total threads in parallel region
    !-- Status
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Base_Ctx
```

### `RT_Mesh_NodeState` (lines 130–143)

```fortran
  TYPE, PUBLIC :: RT_Mesh_NodeState
    INTEGER(i4) :: node_id = 0_i4           ! Global node ID
    REAL(wp) :: coords_curr(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: coords_prev(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: displ(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: velocity(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: accel(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    INTEGER(i4) :: dof_ids(6) = 0           ! DOF labels (max 6 per node)
    INTEGER(i4) :: eq_nums(6) = 0           ! Global equation numbers
    INTEGER(i4) :: ndof = 0_i4              ! Active DOF count for this node
    LOGICAL :: is_constrained = .FALSE.     ! BC applied?
    INTEGER(i4) :: partition_id = 0_i4      ! Partition assignment
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_NodeState
```

### `RT_Mesh_ElementState` (lines 146–156)

```fortran
  TYPE, PUBLIC :: RT_Mesh_ElementState
    INTEGER(i4) :: elem_id = 0_i4           ! Global element ID
    INTEGER(i4) :: elem_type = 0_i4         ! Element family code
    INTEGER(i4), ALLOCATABLE :: node_ids(:) ! Connectivity (global IDs)
    INTEGER(i4), ALLOCATABLE :: ip_weights(:) ! Integration point weights
    REAL(wp) :: volume = 0.0_wp             ! Current element volume
    REAL(wp) :: volume_ref = 0.0_wp         ! Reference volume
    INTEGER(i4) :: status_flag = 0_i4       ! Element status (active/killed/failed)
    INTEGER(i4) :: partition_id = 0_i4      ! Partition assignment
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_ElementState
```

### `RT_Mesh_NumberingAlgo` (lines 159–172)

```fortran
  TYPE, PUBLIC :: RT_Mesh_NumberingAlgo
    TYPE(RT_Mesh_Base_Algo) :: base
    !-- Algorithm-specific parameters
    INTEGER(i4) :: max_bandwidth = 0_i4     ! Computed max bandwidth
    INTEGER(i4) :: profile_size = 0_i4      ! Matrix profile size
    REAL(wp) :: fill_ratio = 0.0_wp         ! Sparse matrix fill-in ratio
    !-- RCM parameters
    INTEGER(i4) :: rcm_start_node = 0_i4    ! Starting node for RCM
    LOGICAL :: use_level_structure = .TRUE. ! Use level-based ordering
    !-- Statistics
    INTEGER(i4) :: n_constrained_dof = 0_i4 ! Number of constrained DOFs
    INTEGER(i4) :: n_free_dof = 0_i4        ! Number of free DOFs
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_NumberingAlgo
```

### `RT_Mesh_AssemblyCtx` (lines 175–190)

```fortran
  TYPE, PUBLIC :: RT_Mesh_AssemblyCtx
    TYPE(RT_Mesh_Base_Ctx) :: base
    !-- Precomputed connectivity info
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)    ! CSR row pointers
    INTEGER(i4), ALLOCATABLE :: col_idx(:)    ! CSR column indices
    INTEGER(i4) :: nnz = 0_i4                 ! Number of non-zeros
    !-- Assembly work arrays
    REAL(wp), ALLOCATABLE :: elem_matrix(:,:) ! Temporary element matrix
    REAL(wp), ALLOCATABLE :: elem_vector(:)   ! Temporary element vector
    INTEGER(i4), ALLOCATABLE :: lm(:)         ! LM array (location matrix)
    !-- Parallel assembly
    TYPE(ThreadWS), POINTER :: thread_ws => NULL()
    LOGICAL :: use_atomic_assembly = .FALSE.  ! Use atomic operations
    !-- Status
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_AssemblyCtx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
