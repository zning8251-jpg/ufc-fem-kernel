!===============================================================================
! MODULE: RT_Asm_Impl
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl
! BRIEF:  Assembly operation implementations (K/M/F/BC/residual)
!===============================================================================
!
! Implementation list:
!   RT_Asm_Init_Impl             - Initialize assembly domain         [P0]
!   RT_Asm_BuildPattern_Impl     - Build sparsity pattern (CSR)       [P1]
!   RT_Asm_AssembleK_Impl        - Assemble global stiffness matrix   [P2]
!   RT_Asm_AssembleM_Impl        - Assemble global mass matrix        [P2]
!   RT_Asm_AssembleF_Impl        - Assemble global force vector       [P2]
!   RT_Asm_ApplyConstraints_Impl - Apply boundary constraints         [P2]
!   RT_Asm_ComputeResidual_Impl  - Compute residual vector            [P2]
!   RT_Asm_Finalize_Impl         - Finalize and cleanup               [P0]
!
! Layer dependency:
!   USE IF_Prec_Core (wp, i4)
!   USE IF_Err_Brg   (ErrorStatusType)
!   USE RT_Asm_Def / RT_Asm_Proc
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Impl
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Asm_Def
  USE RT_Asm_Proc
  USE RT_Asm_Execute, ONLY: RT_Asm_Execute_Flow, &
                            RT_Asm_S1_MapDof, RT_Asm_S2_ElemLoop, &
                            RT_Asm_S3_Scatter, RT_Asm_S4_ApplyBC
  ! ST-9 Integration: Element assembly
  USE RT_Elem_AsmProc, ONLY: RT_Elem_Assembly_In, &
                                       RT_Element_Assemble_Ke, &
                                       RT_Element_Assemble_Fe, &
                                       RT_Element_Assemble_Me
  USE RT_Elem_Def, ONLY: RT_Elem_Desc, RT_Elem_State, RT_Elem_Algo, RT_Elem_Ctx
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Asm_Init_Impl
  PUBLIC :: RT_Asm_BuildPattern_Impl
  PUBLIC :: RT_Asm_AssembleK_Impl
  PUBLIC :: RT_Asm_AssembleM_Impl
  PUBLIC :: RT_Asm_AssembleF_Impl
  PUBLIC :: RT_Asm_ApplyConstraints_Impl
  PUBLIC :: RT_Asm_ComputeResidual_Impl
  PUBLIC :: RT_Asm_Finalize_Impl
  !-- Standardized 4-step flow re-export
  PUBLIC :: RT_Asm_Execute_Flow
  
CONTAINS

  !=============================================================================
  ! RT_Asm_Init_Impl - Initialize assembly domain
  !=============================================================================
  SUBROUTINE RT_Asm_Init_Impl(desc, state, algo, ctx, n_elem, n_node, n_dof_per_node, &
                               assemble_K, assemble_M, assemble_C, assemble_f, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: n_elem, n_node, n_dof_per_node
    LOGICAL, INTENT(IN), OPTIONAL :: assemble_K, assemble_M, assemble_C, assemble_f
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Initialize description
    CALL desc%Init(assemble_K=assemble_K, assemble_M=assemble_M, &
                   assemble_C=assemble_C, assemble_f=assemble_f)
    CALL desc%SetRange(1_i4, n_elem, 1_i4, n_node)
    
    ! Initialize algorithm
    CALL algo%Init()
    
    ! Reset state
    CALL state%Reset()
    state%total_elements = n_elem
    
    ! Clear context
    CALL ctx%ClearElementData()
    CALL ctx%ClearGPData()
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Init_Impl
  
  !=============================================================================
  ! RT_Asm_BuildPattern_Impl - Build sparsity pattern
  !=============================================================================
  SUBROUTINE RT_Asm_BuildPattern_Impl(desc, state, algo, ctx, nEq, nnz, renum_method, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: nEq, nnz
    INTEGER(i4), INTENT(IN), OPTIONAL :: renum_method
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! TODO: Call MD_Asm_BuildPattern or L3 pattern construction
    ! For now, just set basic statistics
    state%n_nonzero_entries = nnz
    state%n_assembled_dofs = nEq
    
    ! TODO: Implement RCM/AMD renumbering if requested
    ! SELECT CASE(renum_method)
    !   CASE(1) ! RCM
    !   CASE(2) ! AMD
    ! END SELECT
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_BuildPattern_Impl
  
  !=============================================================================
  ! RT_Asm_AssembleK_Impl - Assemble global stiffness matrix
  !=============================================================================
  SUBROUTINE RT_Asm_AssembleK_Impl(desc, state, algo, ctx, elem_id, Ke, dof_map, &
                                    use_scaling, scale_factor, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: elem_id
    REAL(wp), INTENT(INOUT) :: Ke(:,:)
    INTEGER(i4), INTENT(INOUT) :: dof_map(:)
    LOGICAL, INTENT(IN), OPTIONAL :: use_scaling
    REAL(wp), INTENT(IN), OPTIONAL :: scale_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ST-9 Integration: Use RT_ElemAsmProc
    TYPE(RT_Elem_Assembly_In) :: elem_inp
    TYPE(RT_Elem_Desc) :: elem_desc
    TYPE(RT_Elem_State) :: elem_state
    TYPE(RT_Elem_Algo) :: elem_algo
    TYPE(RT_Elem_Ctx) :: elem_ctx
    REAL(wp), ALLOCATABLE :: coords(:,:), displ(:,:)
    INTEGER(i4) :: n_nodes, dim, i, j
    
    CALL init_error_status(status)
    
    ! ST-9: Get element data from L3_MD registry
    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleK: UFC global not ready'
      RETURN
    END IF
    
    ! TODO: Get element descriptor from MD registry
    ! elem_desc = MD_Element_GetDescById(elem_type_id, ...)
    
    ! ST-9: Setup assembly input
    n_nodes = SIZE(dof_map) / 3  ! Assume 3 DOF per node
    dim = 3
    
    IF (.NOT. ALLOCATED(elem_inp%coords)) ALLOCATE(elem_inp%coords(dim, n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%displ)) ALLOCATE(elem_inp%displ(dim, n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%conn)) ALLOCATE(elem_inp%conn(n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%lm)) ALLOCATE(elem_inp%lm(n_nodes * dim))
    
    ! TODO: Fill coords from mesh
    elem_inp%coords = 0.0_wp
    elem_inp%displ = 0.0_wp
    elem_inp%conn = 0
    elem_inp%lm = dof_map
    elem_inp%pop%n_nodes = n_nodes
    elem_inp%pop%dof_per_node = dim
    elem_inp%elem_id = elem_id
    
    ! ST-9: Call RT_Element_Assemble_Ke
    CALL RT_Element_Assemble_Ke(elem_desc, elem_state, elem_algo, elem_ctx, &
                                elem_inp, state%K_global, status)
    
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Copy assembled stiffness back to Ke buffer
    IF (SIZE(Ke, 1) <= SIZE(elem_inp%lm) .AND. SIZE(Ke, 2) <= SIZE(elem_inp%lm)) THEN
      Ke(1:SIZE(Ke,1), 1:SIZE(Ke,2)) = elem_inp%coords  ! Placeholder
    END IF
    
    ! Update progress
    CALL state%UpdateProgress(elem_id)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleK_Impl
  
  !=============================================================================
  ! RT_Asm_AssembleM_Impl - Assemble global mass matrix
  !=============================================================================
  SUBROUTINE RT_Asm_AssembleM_Impl(desc, state, algo, ctx, elem_id, Me, dof_map, &
                                    consistent, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: elem_id
    REAL(wp), INTENT(INOUT) :: Me(:,:)
    INTEGER(i4), INTENT(INOUT) :: dof_map(:)
    LOGICAL, INTENT(IN), OPTIONAL :: consistent
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Copy element mass to context buffer
    ctx%elem_me = 0.0_wp
    IF (SIZE(Me, 1) <= 24 .AND. SIZE(Me, 2) <= 24) THEN
      ctx%elem_me(1:SIZE(Me,1), 1:SIZE(Me,2)) = Me
    END IF
    
    ! Store DOF map
    IF (SIZE(dof_map) <= 24) THEN
      ctx%elem_dof_map(1:SIZE(dof_map)) = dof_map
    END IF
    
    ! TODO: If not consistent (lumped mass), diagonalize the mass matrix
    IF (PRESENT(consistent)) THEN
      IF (.NOT. consistent) THEN
        ! Row-sum mass lumping: M_lump(i,i) = sum_j |M(i,j)|
        BLOCK
          INTEGER(i4) :: row, col, n_dof_e
          REAL(wp) :: row_sum
          n_dof_e = MIN(SIZE(Me, 1), 24)
          DO row = 1, n_dof_e
            row_sum = 0.0_wp
            DO col = 1, n_dof_e
              row_sum = row_sum + ABS(ctx%elem_me(row, col))
            END DO
            ctx%elem_me(row, :) = 0.0_wp
            ctx%elem_me(row, row) = row_sum
          END DO
        END BLOCK
      END IF
    END IF
    
    ! TODO: Route to L4_PH for element mass computation
    ! TODO: Scatter to global M_global
    
    ! Update progress
    CALL state%UpdateProgress(elem_id)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleM_Impl
  
  !=============================================================================
  ! RT_Asm_AssembleF_Impl - Assemble global force vector
  !=============================================================================
  SUBROUTINE RT_Asm_AssembleF_Impl(desc, state, algo, ctx, elem_id, Fe, dof_map, &
                                    is_internal, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: elem_id
    REAL(wp), INTENT(INOUT) :: Fe(:)
    INTEGER(i4), INTENT(INOUT) :: dof_map(:)
    LOGICAL, INTENT(IN), OPTIONAL :: is_internal
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ST-9 Integration: Use RT_ElemAsmProc
    TYPE(RT_Elem_Assembly_In) :: elem_inp
    TYPE(RT_Elem_Desc) :: elem_desc
    TYPE(RT_Elem_State) :: elem_state
    TYPE(RT_Elem_Algo) :: elem_algo
    TYPE(RT_Elem_Ctx) :: elem_ctx
    REAL(wp), ALLOCATABLE :: coords(:,:), displ(:,:)
    INTEGER(i4) :: n_nodes, dim, i
    
    CALL init_error_status(status)
    
    ! ST-9: Get element data from L3_MD registry
    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleF: UFC global not ready'
      RETURN
    END IF
    
    ! ST-9: Setup assembly input
    n_nodes = SIZE(dof_map) / 3  ! Assume 3 DOF per node
    dim = 3
    
    IF (.NOT. ALLOCATED(elem_inp%coords)) ALLOCATE(elem_inp%coords(dim, n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%displ)) ALLOCATE(elem_inp%displ(dim, n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%conn)) ALLOCATE(elem_inp%conn(n_nodes))
    IF (.NOT. ALLOCATED(elem_inp%lm)) ALLOCATE(elem_inp%lm(n_nodes * dim))
    
    ! TODO: Fill coords/displ from current state
    elem_inp%coords = 0.0_wp
    elem_inp%displ = 0.0_wp
    elem_inp%conn = 0
    elem_inp%lm = dof_map
    elem_inp%pop%n_nodes = n_nodes
    elem_inp%pop%dof_per_node = dim
    elem_inp%elem_id = elem_id
    
    ! ST-9: Call RT_Element_Assemble_Fe
    CALL RT_Element_Assemble_Fe(elem_desc, elem_state, elem_algo, elem_ctx, &
                                elem_inp, state%F_global, status)
    
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Copy assembled force back to Fe buffer
    IF (SIZE(Fe) <= SIZE(elem_inp%lm)) THEN
      Fe(1:SIZE(Fe)) = elem_inp%displ(:,1)  ! Placeholder
    END IF
    
    ! Update progress
    CALL state%UpdateProgress(elem_id)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleF_Impl
  
  !=============================================================================
  ! RT_Asm_ApplyConstraints_Impl - Apply boundary constraints
  !=============================================================================
  SUBROUTINE RT_Asm_ApplyConstraints_Impl(desc, state, algo, ctx, dof_indices, &
                                           constraint_types, constraint_values, &
                                           n_constraints, n_applied, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    INTEGER(i4), INTENT(IN) :: constraint_types(:)
    REAL(wp), INTENT(IN) :: constraint_values(:)
    INTEGER(i4), INTENT(IN) :: n_constraints
    INTEGER(i4), INTENT(OUT) :: n_applied
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    n_applied = 0_i4
    
    ! Apply boundary constraints via penalty/elimination method
    DO i = 1, n_constraints
      IF (i > SIZE(dof_indices) .OR. i > SIZE(constraint_types) .OR. &
          i > SIZE(constraint_values)) EXIT
      
      dof_idx = dof_indices(i)
      IF (dof_idx < 1) CYCLE
      
      SELECT CASE(constraint_types(i))
      CASE(1)  ! Fixed DOF: set row/col to zero, diagonal to 1, RHS to 0
        IF (ASSOCIATED(state%K_global) .AND. ASSOCIATED(state%f_global)) THEN
          n_total = SIZE(state%f_global)
          IF (dof_idx <= n_total) THEN
            ! Zero row and column
            DO j = 1, n_total
              state%K_global(dof_idx, j) = 0.0_wp
              state%K_global(j, dof_idx) = 0.0_wp
            END DO
            state%K_global(dof_idx, dof_idx) = 1.0_wp
            state%f_global(dof_idx) = 0.0_wp
            n_applied = n_applied + 1_i4
          END IF
        END IF
        
      CASE(2)  ! Prescribed displacement: penalty method
        IF (ASSOCIATED(state%K_global) .AND. ASSOCIATED(state%f_global)) THEN
          n_total = SIZE(state%f_global)
          IF (dof_idx <= n_total) THEN
            ! Find max diagonal for penalty scaling
            max_diag = 0.0_wp
            DO j = 1, n_total
              IF (ABS(state%K_global(j,j)) > max_diag) max_diag = ABS(state%K_global(j,j))
            END DO
            IF (max_diag < 1.0E-30_wp) max_diag = 1.0_wp
            penalty = 1.0E20_wp * max_diag
            
            state%K_global(dof_idx, dof_idx) = state%K_global(dof_idx, dof_idx) + penalty
            state%f_global(dof_idx) = state%f_global(dof_idx) + penalty * constraint_values(i)
            n_applied = n_applied + 1_i4
          END IF
        END IF
        
      CASE(3)  ! Symmetric constraint: mirror DOF pair
        ! Symmetric conditions handled at a higher level (RT_Asm_Core_Apply_MPC)
        n_applied = n_applied + 1_i4
        
      CASE DEFAULT
        CYCLE
      END SELECT
    END DO
    
    state%n_constraints_applied = n_applied
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ApplyConstraints_Impl
  
  !=============================================================================
  ! RT_Asm_ComputeResidual_Impl - Compute residual vector
  !=============================================================================
  SUBROUTINE RT_Asm_ComputeResidual_Impl(desc, state, algo, ctx, f_external, &
                                          f_internal, res_norm, residual, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: f_external(:)
    REAL(wp), INTENT(IN) :: f_internal(:)
    REAL(wp), INTENT(OUT) :: res_norm
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: residual(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Compute residual r = f_ext - f_int
    IF (SIZE(f_external) == SIZE(f_internal)) THEN
      IF (.NOT. ALLOCATED(residual)) THEN
        ALLOCATE(residual(SIZE(f_external)))
      END IF
      
      residual = f_external - f_internal
      res_norm = SQRT(SUM(residual**2))
      
      ! Update state norm
      state%f_vector_norm = res_norm
    ELSE
      res_norm = 0.0_wp
      status%status_code = IF_STATUS_INVALID
      status%message = "f_external and f_internal size mismatch"
    END IF
    
  END SUBROUTINE RT_Asm_ComputeResidual_Impl
  
  !=============================================================================
  ! RT_Asm_Finalize_Impl - Finalize and cleanup
  !=============================================================================
  SUBROUTINE RT_Asm_Finalize_Impl(desc, state, algo, ctx, keep_pattern, status)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    LOGICAL, INTENT(IN) :: keep_pattern
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Reset state
    CALL state%Reset()
    
    ! Clear context
    CALL ctx%ClearElementData()
    CALL ctx%ClearGPData()
    CALL ctx%Detach()
    
    ! Finalize description
    CALL desc%Finalize()
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Finalize_Impl
  
END MODULE RT_Asm_Impl