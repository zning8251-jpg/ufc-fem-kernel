!===============================================================================
! MODULE: PH_ConstrMPC_Brg
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Brg ??public API for MPC constraint operations
! BRIEF:  MPC setup, DOF elimination, Lagrange augmentation, and penalty
!         enforcement bridge procedures with Arg bundles.
! PILOT:   core �������`ErrorStatusType` �� `PH_Constr_IntCodeToStatus`��`PH_Constr_Core`������ģ�鲻����Ƕ `*_IntCodeToStatus`��
!===============================================================================
! Theory:
!   MPC constraint: A??u = b where A ??^(m??n), u ??^n, b ??^m
!   Stored enforcement_method uses PH_CONS_* (PH_ConstraintDomain_Algo).
!   Lagrange multiplier: [K  G^T] [u]   [F]
!                            [G  0  ] [??] = [g]
!   Penalty: K_mod = K + ???A^T??A, F_mod = F + ???A^T??b
!   Elimination: remove constrained DOFs, solve reduced system
! Status: CORE | Last verified: 2026-02-28
! API contract ( ?7.4): L5 ?Bridge ?L3 ?L3 ?
!
! Contents:
!   Types:
!     - PH_Constr_MPC_Apply_Desc: MPC descriptor (constraint definition)
!     - PH_Constr_MPC_Apply_Algo: Algorithm parameters (enforcement method, ??)
!     - PH_Constr_MPC_Apply_Ctx: Context (system matrices K, F)
!     - PH_Constr_MPC_Apply_State: State (modified K_mod, F_mod)
!     - PH_Constr_MPC_Apply_In: Input structure (nested Desc/Algo/Ctx/State)
!     - PH_Constr_MPC_Apply_Out: Output structure (modified system + status)
!   Subroutines:
!     - PH_Constr_MPC_Apply: Apply MPC constraint using structured interface
!     - PH_Constr_MPC_CheckViolation: Check constraint violation
!     - PH_Constr_MPC_AssembleMatrix: Assemble constraint matrix A
!===============================================================================
MODULE PH_ConstrMPC_Brg
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Constr_Domain, ONLY: PH_CONSTR_PENALTY, PH_CONSTR_AUGLAG
  USE PH_Constr_Core, ONLY: PH_Constr_IntCodeToStatus
  USE PH_Constr_MPC
  USE PH_ConstrMPC_Def
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
  !=============================================================================
  
  !> @brief Descriptor for MPC constraint application
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Desc
    TYPE(MPC_Constraint), ALLOCATABLE :: constraints(:)  ! MPC constraint definitions
    INTEGER(i4) :: num_constraints = 0_i4  ! Number of constraints
  END TYPE PH_Constr_MPC_Apply_Desc
  
  !> @brief Algorithm parameters for MPC enforcement
  !> enforcement_method: PH_CONS_* from PH_ConstraintDomain_Algo (not legacy 1/2/3)
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Algo
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY
    REAL(wp) :: penalty_factor = 1.0e12_wp  ! Penalty parameter ??
    REAL(wp) :: tolerance = 1.0e-8_wp  ! Constraint violation tolerance
  END TYPE PH_Constr_MPC_Apply_Algo
  
  !> @brief Context for MPC application (system matrices)
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Ctx
    REAL(wp), ALLOCATABLE :: stiffness_matrix(:,:)  ! Stiffness matrix K  ??^(n??n)
    REAL(wp), ALLOCATABLE :: force_vector(:)  ! Force vector F  ??^n
    INTEGER(i4) :: n_dofs = 0_i4  ! Number of DOFs
  END TYPE PH_Constr_MPC_Apply_Ctx
  
  !> @brief State for MPC application (modified system)
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_State
    REAL(wp), ALLOCATABLE :: stiffness_modified(:,:)  ! Modified stiffness K_mod
    REAL(wp), ALLOCATABLE :: force_modified(:)  ! Modified force F_mod
    TYPE(MPC_State) :: violation_state  ! Constraint violation state
  END TYPE PH_Constr_MPC_Apply_State
  
  !> @brief Input structure for MPC application
  
  !> @brief Output structure for MPC application
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Arg
    TYPE(PH_Constr_MPC_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_MPC_Apply_Arg

  
  !=============================================================================
  ! Public API
  !=============================================================================
  PUBLIC :: PH_Constr_MPC_Init
  PUBLIC :: PH_Constr_MPC_AddTerm
  PUBLIC :: PH_Constr_MPC_AssembleMatrix
  PUBLIC :: PH_Constr_MPC_ApplyConstraint
  PUBLIC :: PH_Constr_MPC_CheckViolation
  PUBLIC :: PH_Constr_MPC_AssemblePenalty
  PUBLIC :: PH_Constr_MPC_AssembleLagrangeBlock
  PUBLIC :: PH_Constr_MPC_Finalize
  PUBLIC :: PH_Constr_MPC_Opt
  PUBLIC :: PH_Constr_MPC_CheckConsistency
  PUBLIC :: PH_Constr_MPC_ComputeViolation
  PUBLIC :: PH_Constr_MPC_Apply
  PUBLIC :: PH_Constr_MPC_Apply_Arg
  PUBLIC :: PH_Constr_MPC_Apply_Desc, PH_Constr_MPC_Apply_Algo
  PUBLIC :: PH_Constr_MPC_Apply_Ctx, PH_Constr_MPC_Apply_State

CONTAINS

  !=============================================================================
  !> @brief Apply MPC constraint using structured interface
  !! @details Applies MPC constraints A??u = b to system K??u = F using specified
  !!   enforcement method (Lagrange multiplier, penalty, or elimination)
  !! @param[in] in Input structure (constraints, algorithm, system matrices)
  !! @param[out] out Output structure (modified system, violation state, status)
  !! @note Theory: K_mod = K + ???A^T??A, F_mod = F + ???A^T??b (penalty method)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_Apply(arg)
    TYPE(PH_Constr_MPC_Apply_Arg), INTENT(INOUT) :: arg
    
    TYPE(MPC_Params) :: params
    INTEGER(i4) :: n_dofs
    
    CALL init_error_status(arg%status)
    
    params%enforcement_method = arg%algo%enforcement_method
    params%penalty_factor = arg%algo%penalty_factor
    params%tolerance = arg%algo%tolerance
    
    n_dofs = arg%ctx%n_dofs
    IF (n_dofs <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_MPC_Apply: Invalid n_dofs"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%ctx%stiffness_matrix) .OR. .NOT. ALLOCATED(arg%ctx%force_vector)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_MPC_Apply: stiffness_matrix / force_vector not allocated"
      RETURN
    END IF
    IF (SIZE(arg%ctx%stiffness_matrix, 1) < n_dofs .OR. SIZE(arg%ctx%force_vector) < n_dofs) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_MPC_Apply: K/F size smaller than n_dofs"
      RETURN
    END IF
    
    IF (.NOT. ALLOCATED(arg%state%stiffness_modified)) THEN
      ALLOCATE(arg%state%stiffness_modified(n_dofs, n_dofs))
      ALLOCATE(arg%state%force_modified(n_dofs))
    END IF
    
    arg%state%stiffness_modified = arg%ctx%stiffness_matrix(1:n_dofs, 1:n_dofs)
    arg%state%force_modified = arg%ctx%force_vector(1:n_dofs)
    
    ! Apply constraint using legacy interface
    CALL PH_Constr_MPC_ApplyConstraint(params, arg%desc%constraints, &
                                       arg%desc%num_constraints, &
                                       arg%state%stiffness_modified, &
                                       arg%state%force_modified)
    
    ! Check violation
    CALL PH_Constr_MPC_CheckViolation(params, arg%desc%constraints, &
                                      arg%desc%num_constraints, &
                                      arg%ctx%force_vector(1:n_dofs), &
                                      arg%state%violation_state)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_MPC_Apply
  
  !=============================================================================
  !> @brief Initialize MPC state or definition
  !! @param[in] params MPC parameters (optional)
  !! @param[inout] state MPC state (optional)
  !! @param[out] mpc MPC definition (optional)
  !! @param[in] n_terms Number of terms (optional, required if mpc present)
  !! @param[in] ndof_per_node DOFs per node (optional, required if mpc present)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_Init(params, state, mpc, n_terms, ndof_per_node)
    TYPE(MPC_Params), INTENT(IN), OPTIONAL :: params
    TYPE(MPC_State), INTENT(INOUT), OPTIONAL :: state
    TYPE(PH_Constr_MPC_Def), INTENT(OUT), OPTIONAL :: mpc
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_terms, ndof_per_node
    
    ! Initialize MPC state (for constraint monitoring)
    IF (PRESENT(params) .AND. PRESENT(state)) THEN
      state%num_constraints = 0_i4
      state%max_violation = ZERO
      state%avg_violation = ZERO
      state%num_violations = 0_i4
      state%is_satisfied = .TRUE.
    END IF
    
    ! Initialize PH_Constr_MPC_Def (for RT layer)
    IF (PRESENT(mpc) .AND. PRESENT(n_terms) .AND. PRESENT(ndof_per_node)) THEN
      mpc%n_terms = n_terms
      mpc%ndof_per_node = ndof_per_node
      mpc%rhs = ZERO
      IF (ALLOCATED(mpc%node_ids)) DEALLOCATE(mpc%node_ids)
      IF (ALLOCATED(mpc%dof_ids)) DEALLOCATE(mpc%dof_ids)
      IF (ALLOCATED(mpc%coefficients)) DEALLOCATE(mpc%coefficients)
      ALLOCATE(mpc%node_ids(n_terms), mpc%dof_ids(n_terms), mpc%coefficients(n_terms))
      mpc%node_ids = 0_i4
      mpc%dof_ids = 0_i4
      mpc%coefficients = ZERO
    END IF
    
  END SUBROUTINE PH_Constr_MPC_Init

  !=============================================================================
  !> @brief Add a term to an MPC constraint
  !! @details Adds term a_i??u_i to MPC equation: ?? a_i??u_i = b
  !! @param[inout] constraint MPC constraint definition
  !! @param[in] node_id Node ID
  !! @param[in] dof_type DOF type (1=u ? 2=u ? 3=u ? 4=ur ? 5=ur ? 6=ur ?
  !! @param[in] coef Coefficient a_i
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_AddTerm(constraint, node_id, dof_type, coef)
    TYPE(MPC_Constraint), INTENT(INOUT) :: constraint
    INTEGER(i4), INTENT(IN) :: node_id, dof_type
    REAL(wp), INTENT(IN) :: coef
    
    TYPE(MPC_Term), ALLOCATABLE :: temp_terms(:)
    INTEGER(i4) :: n_old
    
    ! Resize terms array
    IF (ALLOCATED(constraint%terms)) THEN
      n_old = SIZE(constraint%terms)
      ALLOCATE(temp_terms(n_old))
      temp_terms = constraint%terms
      DEALLOCATE(constraint%terms)
      ALLOCATE(constraint%terms(n_old + 1))
      constraint%terms(1:n_old) = temp_terms
      DEALLOCATE(temp_terms)
    ELSE
      ALLOCATE(constraint%terms(1))
      n_old = 0_i4
    END IF
    
    ! Add new term
    constraint%terms(n_old + 1)%node_id = node_id
    constraint%terms(n_old + 1)%dof_type = dof_type
    constraint%terms(n_old + 1)%coef = coef
    constraint%num_terms = n_old + 1
    
  END SUBROUTINE PH_Constr_MPC_AddTerm

  !=============================================================================
  !> @brief Assemble MPC constraint matrix
  !! @details Assembles constraint matrix A ??^(m??n) and RHS vector b ??^m
  !!   from MPC constraints: A??u = b
  !! @param[in] constraints MPC constraint definitions
  !! @param[in] num_constraints Number of constraints m
  !! @param[out] constraint_matrix Constraint matrix A
  !! @param[out] rhs_vector RHS vector b
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_AssembleMatrix(constraints, num_constraints, &
                                          constraint_matrix, rhs_vector)
    TYPE(MPC_Constraint), INTENT(IN) :: constraints(:)
    INTEGER(i4), INTENT(IN) :: num_constraints
    REAL(wp), INTENT(OUT) :: constraint_matrix(:,:)
    REAL(wp), INTENT(OUT) :: rhs_vector(:)
    
    CALL PH_Constr_MPCCore_AssembleMatrix(constraints, num_constraints, &
                             constraint_matrix, rhs_vector)
    
  END SUBROUTINE PH_Constr_MPC_AssembleMatrix

  !=============================================================================
  !> @brief Apply MPC contribution to global system
  !! @details Applies MPC constraints to system K??u = F:
  !!   Penalty method: K_mod = K + ???A^T??A, F_mod = F + ???A^T??b
  !! @param[in] params MPC parameters (enforcement method, penalty factor ??)
  !! @param[in] constraints MPC constraint definitions
  !! @param[in] num_constraints Number of constraints
  !! @param[inout] stiffness_matrix Stiffness matrix K (modified in-place)
  !! @param[inout] force_vector Force vector F (modified in-place)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_ApplyConstraint(params, constraints, num_constraints, &
                                           stiffness_matrix, force_vector)
    TYPE(MPC_Params), INTENT(IN) :: params
    TYPE(MPC_Constraint), INTENT(IN) :: constraints(:)
    INTEGER(i4), INTENT(IN) :: num_constraints
    REAL(wp), INTENT(INOUT) :: stiffness_matrix(:,:)
    REAL(wp), INTENT(INOUT) :: force_vector(:)
    
    INTEGER(i4) :: i_constraint, i_term, j_term, dof_i, dof_j
    REAL(wp) :: penalty, coeff_i, coeff_j, rhs_val
    TYPE(MPC_Term) :: term_i, term_j
    
    IF (params%enforcement_method /= PH_CONSTR_PENALTY .AND. &
        params%enforcement_method /= PH_CONSTR_AUGLAG) RETURN  ! Penalty / aug-Lag stiffness path only
    
    penalty = params%penalty_factor
    
    ! Apply penalty method: K_mod = K + ???A^T??A, F_mod = F + ???A^T??b
    DO i_constraint = 1, num_constraints
      IF (.NOT. constraints(i_constraint)%is_active) CYCLE
      
      rhs_val = constraints(i_constraint)%rhs_value
      
      ! Stiffness contribution: K += ???A^T??A (???a_i??a_j)
      DO i_term = 1, constraints(i_constraint)%num_terms
        term_i = constraints(i_constraint)%terms(i_term)
        dof_i = (term_i%node_id - 1) * 3 + term_i%dof_type
        coeff_i = term_i%coef
        
        DO j_term = 1, constraints(i_constraint)%num_terms
          term_j = constraints(i_constraint)%terms(j_term)
          dof_j = (term_j%node_id - 1) * 3 + term_j%dof_type
          coeff_j = term_j%coef
          
          stiffness_matrix(dof_i, dof_j) = stiffness_matrix(dof_i, dof_j) + &
                                          penalty * coeff_i * coeff_j
        END DO
        
        ! Force contribution: F += ???A^T??b (???a_i??b)
        force_vector(dof_i) = force_vector(dof_i) + penalty * coeff_i * rhs_val
      END DO
    END DO
    
  END SUBROUTINE PH_Constr_MPC_ApplyConstraint

  !-----------------------------------------------------------------------------
  ! PH_Constr_MPC_CheckViolation: Check MPC constraint violation
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_MPC_CheckViolation(params, constraints, num_constraints, &
                                          displacement_vector, state)
    TYPE(MPC_Params), INTENT(IN) :: params
    TYPE(MPC_Constraint), INTENT(IN) :: constraints(:)
    INTEGER(i4), INTENT(IN) :: num_constraints
    REAL(wp), INTENT(IN) :: displacement_vector(:)
    TYPE(MPC_State), INTENT(OUT) :: state
    
    INTEGER(i4) :: i_constraint, i_term, dof_id
    REAL(wp) :: constraint_value, violation, total_violation
    TYPE(MPC_Term) :: term
    
    state%num_constraints = num_constraints
    state%max_violation = ZERO
    total_violation = ZERO
    state%num_violations = 0_i4
    
    ! Check each constraint
    DO i_constraint = 1, num_constraints
      IF (.NOT. constraints(i_constraint)%is_active) CYCLE
      
      ! Compute constraint value: A??u = ?? a_i??u_i
      constraint_value = ZERO
      DO i_term = 1, constraints(i_constraint)%num_terms
        term = constraints(i_constraint)%terms(i_term)
        dof_id = (term%node_id - 1) * 3 + term%dof_type
        constraint_value = constraint_value + term%coef * displacement_vector(dof_id)
      END DO
      
      ! Violation: r = |A??u - b|
      violation = ABS(constraint_value - constraints(i_constraint)%rhs_value)
      
      state%max_violation = MAX(state%max_violation, violation)
      total_violation = total_violation + violation
      
      IF (violation > params%tolerance) THEN
        state%num_violations = state%num_violations + 1
      END IF
    END DO
    
    ! Average violation
    IF (num_constraints > 0_i4) THEN
      state%avg_violation = total_violation / REAL(num_constraints, wp)
    END IF
    
    state%is_satisfied = (state%num_violations == 0_i4)
    
  END SUBROUTINE PH_Constr_MPC_CheckViolation

  !=============================================================================
  !> @brief Assemble penalty method contribution
  !! @details Applies penalty method: K_mod = K + ???A^T??A, R_mod = R + ???A^T??b
  !! @param[in] mpc MPC definition
  !! @param[in] n_dof_total Total number of DOFs
  !! @param[in] kappa Penalty parameter ??
  !! @param[inout] K Stiffness matrix (modified in-place)
  !! @param[inout] R Force vector (modified in-place)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_AssemblePenalty(mpc, n_dof_total, kappa, K, R)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    INTEGER(i4), INTENT(IN) :: n_dof_total
    REAL(wp), INTENT(IN) :: kappa
    REAL(wp), INTENT(INOUT) :: K(:,:)
    REAL(wp), INTENT(INOUT) :: R(:)
    
    CALL PH_Constr_MPCCore_AssemblePenalty(mpc, n_dof_total, kappa, K, R)
    
  END SUBROUTINE PH_Constr_MPC_AssemblePenalty

  !=============================================================================
  !> @brief Assemble Lagrange multiplier block
  !! @details Assembles constraint matrix row C_row for Lagrange multiplier method:
  !!   [K  G^T] [u]   [F]
  !!   [G  0  ] [??] = [g]
  !! @param[in] mpc MPC definition
  !! @param[in] n_dof_total Total number of DOFs
  !! @param[out] C_row Constraint matrix row G ??^n
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_AssembleLagrangeBlock(mpc, n_dof_total, C_row)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    INTEGER(i4), INTENT(IN) :: n_dof_total
    REAL(wp), INTENT(OUT) :: C_row(:)
    
    CALL PH_Constr_MPCCore_AssembleLagrangeBlock(mpc, n_dof_total, C_row)
    
  END SUBROUTINE PH_Constr_MPC_AssembleLagrangeBlock

  !-----------------------------------------------------------------------------
  ! PH_Constr_MPC_Finalize: Free memory
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_MPC_Finalize(mpc)
    TYPE(PH_Constr_MPC_Def), INTENT(INOUT) :: mpc
    
    IF (ALLOCATED(mpc%node_ids)) DEALLOCATE(mpc%node_ids)
    IF (ALLOCATED(mpc%dof_ids)) DEALLOCATE(mpc%dof_ids)
    IF (ALLOCATED(mpc%coefficients)) DEALLOCATE(mpc%coefficients)
    mpc%n_terms = 0_i4
    mpc%ndof_per_node = 0_i4
    mpc%rhs = ZERO
  END SUBROUTINE PH_Constr_MPC_Finalize

  !=============================================================================
  !> @brief Optimize MPC constraint
  !! @details Optimizes MPC constraint implementation (e.g., reordering, sparsity)
  !! @param[inout] mpc MPC definition (may be modified)
  !! @param[in] optimization_level Optimization level (0=none, 1=basic, 2=aggressive)
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_Opt(mpc, optimization_level, status)
    TYPE(PH_Constr_MPC_Def), INTENT(INOUT) :: mpc
    INTEGER(i4), INTENT(IN) :: optimization_level
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ic
    CALL PH_Constr_MPCCore_Opt(mpc, optimization_level, ic)
    CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_MPC')
  END SUBROUTINE PH_Constr_MPC_Opt

  !=============================================================================
  !> @brief Check MPC constraint consistency
  !! @details Checks if MPC constraint is consistent (e.g., rank of constraint matrix)
  !! @param[in] mpc MPC definition
  !! @param[out] is_consistent Whether constraint is consistent
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_CheckConsistency(mpc, is_consistent, status)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    LOGICAL, INTENT(OUT) :: is_consistent
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ic
    CALL PH_Constr_MPCCore_CheckConsistency(mpc, is_consistent, ic)
    CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_MPC')
  END SUBROUTINE PH_Constr_MPC_CheckConsistency

  !=============================================================================
  !> @brief Compute MPC constraint violation
  !! @details Computes violation r = |A??u - b| for MPC constraint
  !! @param[in] mpc MPC definition
  !! @param[in] u_nodal Nodal displacement vector u ??^n
  !! @param[out] violation Constraint violation r = |A??u - b|
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_MPC_ComputeViolation(mpc, u_nodal, violation, status)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    REAL(wp), INTENT(IN) :: u_nodal(:)
    REAL(wp), INTENT(OUT) :: violation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ic
    CALL PH_Constr_MPCCore_ComputeViolation(mpc, u_nodal, violation, ic)
    CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_MPC')
  END SUBROUTINE PH_Constr_MPC_ComputeViolation

END MODULE PH_ConstrMPC_Brg

