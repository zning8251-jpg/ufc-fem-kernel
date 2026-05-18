!===============================================================================
! MODULE: RT_Asm_Def
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Def
! BRIEF:  Four-type definitions for global stiffness/mass/damping assembly
!===============================================================================
!
! Type catalogue (4 TYPEs):
!   RT_Asm_Desc  -- Assembly configuration (element ranges, constraints)  [Desc]
!   RT_Asm_Ctx   -- Step-level context (increment/iteration numbers)      [Ctx]
!   RT_Asm_State -- Mutable runtime state (global K/F/M/C matrices)      [State]
!   RT_Asm_Algo  -- Algorithm configuration (sparse, parallel, scaling)   [Algo]
!
! Partial Pillar: H3 Assembly (L3 + L5)
!   L3: MD_Assembly_Domain / MD_Asm_Mgr (AUTHORITY for Part Instance / sets / surfaces)
!   L5: RT_Asm_Def (THIS MODULE -- AUTHORITY for global K/F assembly types)
!   L5 Golden Line: RT_Asm_Solv.f90 (production assembly hub)
!   L5 Bridge: RT_Asm_Brg.f90 (Populate from L3; UMAT/UEL IP ctx via
!     RT_Asm_Brg_ApplyMatBridge_Flat_IP / RT_Asm_Brg_ApplyElemBridge_Flat_IP + mirror sync)
!
! Layer dependency:
!   USE IF_Prec_Core (wp, i4)
!   USE IF_Err_Brg   (ErrorStatusType)
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Asm_Desc
  PUBLIC :: RT_Asm_Ctx
  PUBLIC :: RT_Asm_State
  PUBLIC :: RT_Asm_Algo
  PUBLIC :: RT_Asm_Arg
  ! REMOVED: RT_Asm legacy alias — migrated to RT_Asm_Algo
  
  !-- Assembly type flags
  LOGICAL, PARAMETER, PUBLIC :: RT_ASM_FLAG_MASS      = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: RT_ASM_FLAG_DAMPING   = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: RT_ASM_FLAG_STIFFNESS = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: RT_ASM_FLAG_LOADS     = .TRUE.
  
  !-- Assembly method constants: RT_ASM_METHOD_{NAME}
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_METHOD_DIRECT       = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_METHOD_ELEMENT_WISE = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_METHOD_DOMAIN_DECOMP = 2_i4
  
  !-- Sparse storage format constants: RT_ASM_SPARSE_{NAME}
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_SPARSE_DENSE   = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_SPARSE_CSR     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_SPARSE_CSC     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_SPARSE_SKYLINE = 3_i4
  
  !-- Parallel strategy constants: RT_ASM_PARALLEL_{NAME}
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_PARALLEL_SERIAL  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_PARALLEL_OMP     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_PARALLEL_MPI     = 2_i4
  
  !---------------------------------------------------------------------------
  ! TYPE: RT_Asm_Desc
  ! KIND: Desc
  ! DESC: Assembly configuration -- element ranges, constraints, matrix props
  !---------------------------------------------------------------------------
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
  
  !---------------------------------------------------------------------------
  ! TYPE: RT_Asm_State
  ! KIND: State
  ! DESC: Mutable runtime state -- global K/M/C/F matrices, progress, norms
  !---------------------------------------------------------------------------
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
  
  !---------------------------------------------------------------------------
  ! TYPE: RT_Asm_Algo
  ! KIND: Algo
  ! DESC: Algorithm configuration -- assembly strategy, sparse format, parallel
  !---------------------------------------------------------------------------
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
  
  ! REMOVED: RT_Asm legacy TYPE �?all references migrated to RT_Asm_Algo
  
  !---------------------------------------------------------------------------
  ! TYPE: RT_Asm_Arg
  ! KIND: Arg
  ! DESC: Step-level argument bundle for RT_Asm_Execute 4-step flow
  !       Carries intermediate data between S1..S4 steps
  !---------------------------------------------------------------------------
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
  
  !---------------------------------------------------------------------------
  ! TYPE: RT_Asm_Ctx
  ! KIND: Ctx
  ! DESC: Element-level hot-path context -- stack temporaries, no allocation
  !---------------------------------------------------------------------------
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
  
CONTAINS

  !=============================================================================
  ! RT_Asm_Desc implementations
  !=============================================================================

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Desc_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize assembly descriptor with optional matrix flags
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Desc_Init(self, assemble_K, assemble_M, assemble_C, assemble_f)
    CLASS(RT_Asm_Desc), INTENT(INOUT) :: self
    LOGICAL, INTENT(IN), OPTIONAL :: assemble_K, assemble_M, assemble_C, assemble_f
    
    self%assemble_mass = .FALSE.
    self%assemble_damping = .FALSE.
    self%assemble_stiffness = .TRUE.
    self%assemble_loads = .TRUE.
    self%elem_start = 1_i4
    self%elem_end = 0_i4
    self%node_start = 1_i4
    self%node_end = 0_i4
    self%is_symmetric = .TRUE.
    self%is_positive_definite = .TRUE.
    
    IF (PRESENT(assemble_K)) self%assemble_stiffness = assemble_K
    IF (PRESENT(assemble_M)) self%assemble_mass = assemble_M
    IF (PRESENT(assemble_C)) self%assemble_damping = assemble_C
    IF (PRESENT(assemble_f)) self%assemble_loads = assemble_f
  END SUBROUTINE Asm_Desc_Init
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Desc_SetRange
  ! PHASE:      P1
  ! PURPOSE:    Set element/node range for assembly
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Desc_SetRange(self, elem_start, elem_end, node_start, node_end)
    CLASS(RT_Asm_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: elem_start, elem_end, node_start, node_end
    
    self%elem_start = elem_start
    self%elem_end = elem_end
    self%node_start = node_start
    self%node_end = node_end
  END SUBROUTINE Asm_Desc_SetRange
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Desc_AddConstraint
  ! PHASE:      P1
  ! PURPOSE:    Add a single constraint (DOF index, type, value)
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Desc_AddConstraint(self, dof_idx, constraint_type, value)
    CLASS(RT_Asm_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: dof_idx
    INTEGER(i4), INTENT(IN) :: constraint_type
    REAL(wp), INTENT(IN) :: value
    
    INTEGER(i4) :: n_old, n_new
    INTEGER(i4), POINTER :: new_dofs(:), new_types(:)
    REAL(wp), POINTER    :: new_vals(:)
    
    ! Grow constraint arrays by 1
    n_old = 0_i4
    IF (ASSOCIATED(self%constrained_dofs)) n_old = SIZE(self%constrained_dofs)
    n_new = n_old + 1_i4
    
    ALLOCATE(new_dofs(n_new), new_types(n_new), new_vals(n_new))
    IF (n_old > 0) THEN
      new_dofs(1:n_old) = self%constrained_dofs(1:n_old)
      new_types(1:n_old) = self%constraint_types(1:n_old)
      new_vals(1:n_old) = self%constraint_values(1:n_old)
    END IF
    new_dofs(n_new) = dof_idx
    new_types(n_new) = constraint_type  ! 1=Fixed/2=Prescribed/3=Symmetric
    new_vals(n_new) = value
    
    ! Replace old arrays
    IF (ASSOCIATED(self%constrained_dofs)) DEALLOCATE(self%constrained_dofs)
    IF (ASSOCIATED(self%constraint_types)) DEALLOCATE(self%constraint_types)
    IF (ASSOCIATED(self%constraint_values)) DEALLOCATE(self%constraint_values)
    self%constrained_dofs => new_dofs
    self%constraint_types => new_types
    self%constraint_values => new_vals
  END SUBROUTINE Asm_Desc_AddConstraint
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Desc_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Finalize descriptor and release constraint arrays
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Desc_Finalize(self)
    CLASS(RT_Asm_Desc), INTENT(INOUT) :: self
    
    IF (ASSOCIATED(self%constrained_dofs)) THEN
      NULLIFY(self%constrained_dofs)
    END IF
    IF (ASSOCIATED(self%constraint_types)) THEN
      NULLIFY(self%constraint_types)
    END IF
    IF (ASSOCIATED(self%constraint_values)) THEN
      NULLIFY(self%constraint_values)
    END IF
  END SUBROUTINE Asm_Desc_Finalize
  
  !=============================================================================
  ! RT_Asm_State implementations
  !=============================================================================

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_State_Reset
  ! PHASE:      P0
  ! PURPOSE:    Reset assembly state to initial values
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_State_Reset(self)
    CLASS(RT_Asm_State), INTENT(INOUT) :: self
    
    self%itr%current_elem = 0_i4
    self%assembled_elements = 0_i4
    self%total_elements = 0_i4
    self%assembly_fraction = 0.0_wp
    self%K_matrix_norm = 0.0_wp
    self%M_matrix_norm = 0.0_wp
    self%f_vector_norm = 0.0_wp
    self%assembly_time = 0.0_wp
    self%n_nonzero_entries = 0_i4
    self%n_constraints_applied = 0_i4
    self%n_assembled_dofs = 0_i4
    
    IF (ASSOCIATED(self%K_global)) NULLIFY(self%K_global)
    IF (ASSOCIATED(self%M_global)) NULLIFY(self%M_global)
    IF (ASSOCIATED(self%C_global)) NULLIFY(self%C_global)
    IF (ASSOCIATED(self%f_global)) NULLIFY(self%f_global)
  END SUBROUTINE Asm_State_Reset
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_State_UpdateProgress
  ! PHASE:      P2
  ! PURPOSE:    Update element assembly progress counter
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_State_UpdateProgress(self, current_elem)
    CLASS(RT_Asm_State), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: current_elem
    
    self%itr%current_elem = current_elem
    self%assembled_elements = current_elem
    IF (self%total_elements > 0) THEN
      self%assembly_fraction = REAL(current_elem, wp) / REAL(self%total_elements, wp)
    END IF
  END SUBROUTINE Asm_State_UpdateProgress
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_State_ComputeNorms
  ! PHASE:      P3
  ! PURPOSE:    Compute Frobenius/L2 norms of global matrices/vectors
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_State_ComputeNorms(self)
    CLASS(RT_Asm_State), INTENT(INOUT) :: self
    
    INTEGER(i4) :: i, j, n
    REAL(wp) :: sum_k, sum_m, sum_f
    
    ! Compute Frobenius norm of K_global
    sum_k = 0.0_wp
    IF (ASSOCIATED(self%K_global)) THEN
      n = SIZE(self%K_global, 1)
      DO j = 1, n
        DO i = 1, n
          sum_k = sum_k + self%K_global(i,j)**2
        END DO
      END DO
      self%K_matrix_norm = SQRT(sum_k)
    END IF
    
    ! Compute Frobenius norm of M_global
    sum_m = 0.0_wp
    IF (ASSOCIATED(self%M_global)) THEN
      n = SIZE(self%M_global, 1)
      DO j = 1, n
        DO i = 1, n
          sum_m = sum_m + self%M_global(i,j)**2
        END DO
      END DO
      self%M_matrix_norm = SQRT(sum_m)
    END IF
    
    ! Compute L2 norm of f_global
    sum_f = 0.0_wp
    IF (ASSOCIATED(self%f_global)) THEN
      n = SIZE(self%f_global)
      DO i = 1, n
        sum_f = sum_f + self%f_global(i)**2
      END DO
      self%f_vector_norm = SQRT(sum_f)
    END IF
  END SUBROUTINE Asm_State_ComputeNorms
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_State_AttachMatrices
  ! PHASE:      P1
  ! PURPOSE:    Attach global K/M/C/f matrix pointers to state
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_State_AttachMatrices(self, K, M, C, f)
    CLASS(RT_Asm_State), INTENT(INOUT) :: self
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: K(:,:)
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: M(:,:)
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: C(:,:)
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: f(:)
    
    IF (PRESENT(K)) THEN
      self%K_global => K
    END IF
    IF (PRESENT(M)) THEN
      self%M_global => M
    END IF
    IF (PRESENT(C)) THEN
      self%C_global => C
    END IF
    IF (PRESENT(f)) THEN
      self%f_global => f
    END IF
  END SUBROUTINE Asm_State_AttachMatrices
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_State_Detach
  ! PHASE:      P0
  ! PURPOSE:    Detach all global matrix pointers
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_State_Detach(self)
    CLASS(RT_Asm_State), INTENT(INOUT) :: self
    
    IF (ASSOCIATED(self%K_global)) NULLIFY(self%K_global)
    IF (ASSOCIATED(self%M_global)) NULLIFY(self%M_global)
    IF (ASSOCIATED(self%C_global)) NULLIFY(self%C_global)
    IF (ASSOCIATED(self%f_global)) NULLIFY(self%f_global)
  END SUBROUTINE Asm_State_Detach
  
  !=============================================================================
  ! RT_Asm_Algo implementations
  !=============================================================================

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Algo_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize algorithm configuration with optional overrides
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Algo_Init(self, method, sparse_fmt, parallel_strat, n_threads)
    CLASS(RT_Asm_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: method, sparse_fmt, parallel_strat, n_threads
    
    self%assembly_method = RT_ASM_METHOD_ELEMENT_WISE
    self%sparse_format = RT_ASM_SPARSE_CSR
    self%parallel_strategy = RT_ASM_PARALLEL_SERIAL
    self%n_threads = 1_i4
    self%stp%integration_order = 2
    self%use_scaling = .FALSE.
    self%mass_scaling_factor = 1.0_wp
    self%stiffness_scaling_factor = 1.0_wp
    
    IF (PRESENT(method)) self%assembly_method = method
    IF (PRESENT(sparse_fmt)) self%sparse_format = sparse_fmt
    IF (PRESENT(parallel_strat)) self%parallel_strategy = parallel_strat
    IF (PRESENT(n_threads)) self%n_threads = n_threads
  END SUBROUTINE Asm_Algo_Init
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Algo_SelectMethod
  ! PHASE:      P0
  ! PURPOSE:    Select assembly method (direct/element-wise/domain decomp)
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Algo_SelectMethod(self, method)
    CLASS(RT_Asm_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: method
    
    self%assembly_method = method
  END SUBROUTINE Asm_Algo_SelectMethod
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Algo_ConfigureParallel
  ! PHASE:      P0
  ! PURPOSE:    Configure parallel strategy and thread count
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Algo_ConfigureParallel(self, strategy, n_threads)
    CLASS(RT_Asm_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: strategy, n_threads
    
    self%parallel_strategy = strategy
    self%n_threads = n_threads
  END SUBROUTINE Asm_Algo_ConfigureParallel
  
  ! REMOVED: Legacy RT_Asm wrapper implementations �?migrated to RT_Asm_Algo TBPs

  !=============================================================================
  ! RT_Asm_Ctx implementations
  !=============================================================================

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Ctx_AttachToState
  ! PHASE:      P1
  ! PURPOSE:    Attach context to assembly state for buffer access
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Ctx_AttachToState(self, state)
    CLASS(RT_Asm_Ctx), INTENT(INOUT) :: self
    TYPE(RT_Asm_State), INTENT(INOUT), TARGET :: state
    
    ! Attach context to state for buffer access
    ! Placeholder - actual implementation depends on memory management strategy
  END SUBROUTINE Asm_Ctx_AttachToState
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Ctx_ClearElementData
  ! PHASE:      P0
  ! PURPOSE:    Zero out element-level buffers (Ke, Me, Ce, Fe, maps)
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Ctx_ClearElementData(self)
    CLASS(RT_Asm_Ctx), INTENT(INOUT) :: self
    
    self%elem_ke = 0.0_wp
    self%elem_me = 0.0_wp
    self%elem_ce = 0.0_wp
    self%elem_fe = 0.0_wp
    self%elem_node_ids = 0_i4
    self%elem_dof_map = 0_i4
  END SUBROUTINE Asm_Ctx_ClearElementData
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Ctx_ClearGPData
  ! PHASE:      P0
  ! PURPOSE:    Zero out integration-point buffers (GP coords, N, dNdx, J)
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Ctx_ClearGPData(self)
    CLASS(RT_Asm_Ctx), INTENT(INOUT) :: self
    
    self%gp_coords = 0.0_wp
    self%gp_weights = 0.0_wp
    self%shape_funcs = 0.0_wp
    self%dndx = 0.0_wp
    self%jacobian = 0.0_wp
    self%det_jacobian = 0.0_wp
    self%inv_jacobian = 0.0_wp
  END SUBROUTINE Asm_Ctx_ClearGPData
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Ctx_Detach
  ! PHASE:      P0
  ! PURPOSE:    Nullify all work and material state pointers
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Ctx_Detach(self)
    CLASS(RT_Asm_Ctx), INTENT(INOUT) :: self
    
    IF (ASSOCIATED(self%temp_array1)) NULLIFY(self%temp_array1)
    IF (ASSOCIATED(self%temp_array2)) NULLIFY(self%temp_array2)
    IF (ASSOCIATED(self%stress_gp)) NULLIFY(self%stress_gp)
    IF (ASSOCIATED(self%strain_gp)) NULLIFY(self%strain_gp)
  END SUBROUTINE Asm_Ctx_Detach
  
  !=============================================================================
  ! RT_Asm_Arg implementations
  !=============================================================================

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Arg_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize Arg bundle for a new assembly pass
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Arg_Init(self, n_eq, n_nodes)
    CLASS(RT_Asm_Arg), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_eq, n_nodes
    
    self%n_total_eq = 0_i4
    self%pop%n_nodes = 0_i4
    self%n_elem_assembled = 0_i4
    self%elem_loop_done = .FALSE.
    self%scatter_done = .FALSE.
    self%n_entries_scattered = 0_i4
    self%n_bc_applied = 0_i4
    self%n_bc = 0_i4
    
    IF (ALLOCATED(self%dof_map))   DEALLOCATE(self%dof_map)
    IF (ALLOCATED(self%bc_dofs))   DEALLOCATE(self%bc_dofs)
    IF (ALLOCATED(self%bc_values)) DEALLOCATE(self%bc_values)
    
    IF (PRESENT(n_eq)) self%n_total_eq = n_eq
    IF (PRESENT(n_nodes)) self%pop%n_nodes = n_nodes
  END SUBROUTINE Asm_Arg_Init
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: Asm_Arg_Clear
  ! PHASE:      P0
  ! PURPOSE:    Clear Arg bundle and release memory
  !---------------------------------------------------------------------------
  SUBROUTINE Asm_Arg_Clear(self)
    CLASS(RT_Asm_Arg), INTENT(INOUT) :: self
    
    IF (ALLOCATED(self%dof_map))   DEALLOCATE(self%dof_map)
    IF (ALLOCATED(self%bc_dofs))   DEALLOCATE(self%bc_dofs)
    IF (ALLOCATED(self%bc_values)) DEALLOCATE(self%bc_values)
    self%n_total_eq = 0_i4
    self%pop%n_nodes = 0_i4
    self%n_elem_assembled = 0_i4
    self%elem_loop_done = .FALSE.
    self%scatter_done = .FALSE.
    self%n_entries_scattered = 0_i4
    self%n_bc_applied = 0_i4
    self%n_bc = 0_i4
  END SUBROUTINE Asm_Arg_Clear
  
END MODULE RT_Asm_Def
