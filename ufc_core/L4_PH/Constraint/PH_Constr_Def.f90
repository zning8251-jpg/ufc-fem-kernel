!===============================================================================
! MODULE: PH_Constr_Def
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Def �?four-type definitions (Desc/Ctx/State/Algo) and context operations
! BRIEF:  Constraint descriptor, algo config, local context type, and
!         P0 lifecycle procedures (Init/Clear/Copy/Valid) with Arg bundles.
!===============================================================================
! Theory:
!   Constraint enforcement methods in FEM:
!   Enforcement codes: PH_CONS_* in PH_ConstraintDomain_Algo (e.g. PH_CONSTR_LAGRANGE,
!   PH_CONSTR_PENALTY, PH_CONSTR_ELIMINATION, PH_CONSTR_TRANSFORM, PH_CONSTR_AUGLAG).
!   Lagrange multiplier: [K G^T; G 0][u; λ] = [F; g]. Penalty: K_mod = K + α·G^T·G.
!   Elimination: reduced system K_red·u_red = F_red.
!   Constraint types:
!   - MPC (Multi-Point Constraint): A·u = b where A is constraint matrix, b is RHS vector
!   - Tie constraint: u_slave = u_master (slave DOFs equal master DOFs)
!   - RBE (Rigid Body Element): u_slave = T·u_master (transformation matrix T)
!   - Periodic constraint: u(x+L) = u(x) (periodic boundary conditions for RVE)
! References:
!   - Zienkiewicz, O.C. & Taylor, R.L. (2005). The Finite Element Method, 6th ed.
! Status: Production | Last verified: 2026-02-28
!
! Contents:
!   Types:
!     - PH_Constr_Ctx: Constraint context type (Ctx)
!     - PH_Constr_Ctx_Init_In/Out: Structured initialization interface
!     - PH_Constr_Ctx_Clear_In/Out: Structured clear interface
!     - PH_Constr_Ctx_Copy_In/Out: Structured copy interface
!     - PH_Constr_Ctx_Valid_In/Out: Structured validation interface
!   Subroutines:
!     - PH_Constr_Ctx_Init: Initialize constraint context
!     - PH_Constr_Ctx_Clear: Clear constraint context
!     - PH_Constr_Ctx_Copy: Copy constraint context
!     - PH_Constr_Ctx_Valid: Validate constraint context
!===============================================================================
MODULE PH_Constr_Def
!> [CORE] Constraint Context Module
!> Theory: Lagrange multiplier [K G^T; G 0][u; λ] = [F; g], penalty method K_mod = K + α·G^T·G, MPC A·u = b
!> Status: Production | Last verified: 2026-02-28
    USE IF_Base_Def, ONLY: ZERO, ONE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE PH_Constr_Domain, ONLY: PH_CONSTR_LAGRANGE, PH_CONSTR_PENALTY, &
                                PH_CONSTR_ELIMINATION, &
                                PH_Constraint_Ctx, PH_Constraint_State
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC TYPES AND SUBROUTINES
    ! ==========================================================================
    ! --- Four-type canonical set (Desc/State/Algo/Ctx) ---
    PUBLIC :: PH_Constraint_Desc
    PUBLIC :: PH_Constraint_State    ! re-export from PH_Constr_Domain
    PUBLIC :: PH_Constraint_Algo
    PUBLIC :: PH_Constraint_Ctx      ! re-export from PH_Constr_Domain
    ! --- Original Ctx and Arg types ---
    PUBLIC :: PH_Constr_Ctx
    PUBLIC :: PH_Constr_Ctx_Init_Arg
    PUBLIC :: PH_Constr_Ctx_Clear_Arg
    PUBLIC :: PH_Constr_Ctx_Copy_Arg
    PUBLIC :: PH_Constr_Ctx_Valid_Arg
    PUBLIC :: PH_Constr_Ctx_Init
    PUBLIC :: PH_Constr_Ctx_Clear
    PUBLIC :: PH_Constr_Ctx_Copy
    PUBLIC :: PH_Constr_Ctx_Valid
    ! --- Enforcement method constants (re-export from PH_Constr_Domain) ---
    PUBLIC :: PH_CONSTR_PENALTY, PH_CONSTR_LAGRANGE, PH_CONSTR_ELIMINATION
    
    ! ==========================================================================
    ! CONSTRAINT DESC TYPE (Desc - cold, Populate-injected)
    ! ==========================================================================
    !> @brief Constraint parameter descriptor (read-only after Populate)
    TYPE, PUBLIC :: PH_Constraint_Desc
        INTEGER(i4) :: n_terms   = 0        !< Number of constraint terms
        INTEGER(i4) :: dep_idx   = 0        !< Dependent DOF index
        REAL(wp)    :: rhs       = ZERO     !< Constraint RHS value
        INTEGER(i4) :: dof_ids(64) = 0      !< DOF indices involved
        REAL(wp)    :: coeffs(64)  = ZERO   !< Constraint coefficients
        INTEGER(i4) :: constraint_type = 0  !< 1=MPC, 2=Tie, 3=RBE, 4=Periodic
        INTEGER(i4) :: enforcement     = 0  !< PH_CONSTR_PENALTY / LAGRANGE / ELIMINATION
    END TYPE PH_Constraint_Desc
    
    ! ==========================================================================
    ! CONSTRAINT ALGO TYPE (Algo - cold, step-level)
    ! ==========================================================================
    !> @brief Constraint enforcement algorithm configuration
    TYPE, PUBLIC :: PH_Constraint_Algo
        INTEGER(i4) :: method = PH_CONSTR_PENALTY  !< Enforcement method (PH_CONS_*)
        REAL(wp)    :: alpha  = 1.0e6_wp         !< Penalty parameter
        REAL(wp)    :: tol    = 1.0e-8_wp        !< Constraint violation tolerance
        INTEGER(i4) :: max_iter = 10             !< Max Uzawa iterations (aug. Lagrange)
    END TYPE PH_Constraint_Algo
    
    ! ==========================================================================
    ! CONSTRAINT CONTEXT TYPE (Ctx - Context/Control)
    ! ==========================================================================
    
    !> @brief Constraint computation context type
    TYPE, PUBLIC :: PH_Constr_Ctx
        ! Constraint identification
        INTEGER(i4) :: constraint_id = 0
        INTEGER(i4) :: constraint_type = 0  ! 1=MPC, 2=Tie, 3=RBE, 4=Periodic
        
        ! Constraint parameters
        INTEGER(i4) :: n_dofs = 0
        INTEGER(i4), ALLOCATABLE :: dof_map(:)      ! DOF mapping
        REAL(wp), ALLOCATABLE :: constraint_matrix(:,:)  ! Constraint matrix A
        REAL(wp), ALLOCATABLE :: constraint_rhs(:)  ! Constraint RHS b
        
        ! Constraint state
        REAL(wp), ALLOCATABLE :: u_nodal(:)         ! Nodal displacements
        REAL(wp), ALLOCATABLE :: lambda(:)          ! Lagrange multipliers
        REAL(wp) :: violation_norm = ZERO
        REAL(wp) :: max_violation = ZERO
        
        ! Enforcement method
        INTEGER(i4) :: enforcement_method = PH_CONSTR_LAGRANGE  ! PH_CONS_* (PH_ConstraintDomain_Algo)
        REAL(wp) :: penalty_parameter = 1.0e6_wp
        
        ! Constraint forces
        REAL(wp), ALLOCATABLE :: constraint_forces(:)
        
        ! Convergence
        REAL(wp) :: tolerance = 1.0e-6_wp
        INTEGER(i4) :: iteration_count = 0
        LOGICAL :: converged = .FALSE.
        
        ! Flags
        LOGICAL :: is_initialized = .FALSE.
        LOGICAL :: is_active = .TRUE.
        
    END TYPE PH_Constr_Ctx
    
    ! ==========================================================================
    ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
    ! ==========================================================================
    
    !> @brief Input structure for constraint context initialization
    
    !> @brief Output structure for constraint context initialization
  TYPE, PUBLIC :: PH_Constr_Ctx_Init_Arg
    INTEGER(i4) :: constraint_id                   ! [IN]
    INTEGER(i4) :: constraint_type                   ! [IN]
    INTEGER(i4) :: n_dofs                   ! [IN]
    INTEGER(i4) :: enforcement_method  ! PH_CONS_* (PH_ConstraintDomain_Algo)                   ! [IN]
    REAL(wp) :: penalty_parameter                   ! [IN]
    TYPE(PH_Constr_Ctx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Init_Arg

    
    !> @brief Input structure for clearing constraint context
    
    !> @brief Output structure for clearing constraint context
  TYPE, PUBLIC :: PH_Constr_Ctx_Clear_Arg
    TYPE(PH_Constr_Ctx) :: ctx                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Clear_Arg

    
    !> @brief Input structure for copying constraint context
    
    !> @brief Output structure for copying constraint context
  TYPE, PUBLIC :: PH_Constr_Ctx_Copy_Arg
    TYPE(PH_Constr_Ctx) :: ctx_src                   ! [IN]
    TYPE(PH_Constr_Ctx) :: ctx_dst                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Copy_Arg

    
    !> @brief Input structure for validating constraint context
    
    !> @brief Output structure for validating constraint context
  TYPE, PUBLIC :: PH_Constr_Ctx_Valid_Arg
    TYPE(PH_Constr_Ctx) :: ctx                   ! [IN]
    LOGICAL :: is_valid                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Valid_Arg

    
CONTAINS
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Init
    ! Purpose: Initialize constraint context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Init(ctx, constraint_id, constraint_type, &
                                         n_dofs, enforcement_method, &
                                         penalty_parameter, status)
        TYPE(PH_Constr_Ctx), INTENT(INOUT) :: ctx
        INTEGER(i4), INTENT(IN) :: constraint_id, constraint_type
        INTEGER(i4), INTENT(IN) :: n_dofs
        INTEGER(i4), INTENT(IN) :: enforcement_method
        REAL(wp), INTENT(IN) :: penalty_parameter
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Clear existing Ctx
        CALL PH_Constr_Ctx_Clear(ctx, status)
        
        ! Set basic properties
        ctx%constraint_id = constraint_id
        ctx%constraint_type = constraint_type
        ctx%n_dofs = n_dofs
        ctx%enforcement_method = enforcement_method
        ctx%penalty_parameter = penalty_parameter
        
        ! Allocate arrays
        ALLOCATE(ctx%dof_map(n_dofs))
        ALLOCATE(ctx%u_nodal(n_dofs))
        ALLOCATE(ctx%constraint_forces(n_dofs))
        
        ! Init arrays
        ctx%dof_map = 0
        ctx%u_nodal = ZERO
        ctx%constraint_forces = ZERO
        
        ! Allocate constraint matrix and RHS (simplified: single constraint)
        ALLOCATE(ctx%constraint_matrix(1, n_dofs))
        ALLOCATE(ctx%constraint_rhs(1))
        ALLOCATE(ctx%lambda(1))
        
        ctx%constraint_matrix = ZERO
        ctx%constraint_rhs = ZERO
        ctx%lambda = ZERO
        
        ctx%is_initialized = .TRUE.
        ctx%is_active = .TRUE.
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE PH_Constr_Ctx_Init
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Init_Structured
    ! Purpose: Initialize constraint context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Init_Structured(arg)
        TYPE(PH_Constr_Ctx_Init_Arg), INTENT(INOUT) :: arg
        
        CALL init_error_status(arg%status)
        
        CALL PH_Constr_Ctx_Init(arg%ctx, arg%constraint_id, arg%constraint_type, &
                                        arg%n_dofs, arg%enforcement_method, &
                                        arg%penalty_parameter, arg%status)
        
    END SUBROUTINE PH_Constr_Ctx_Init_Structured
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Clear
    ! Purpose: Clear constraint context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Clear(ctx, status)
        TYPE(PH_Constr_Ctx), INTENT(INOUT) :: ctx
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Deallocate arrays
        IF (ALLOCATED(ctx%dof_map)) DEALLOCATE(ctx%dof_map)
        IF (ALLOCATED(ctx%constraint_matrix)) DEALLOCATE(ctx%constraint_matrix)
        IF (ALLOCATED(ctx%constraint_rhs)) DEALLOCATE(ctx%constraint_rhs)
        IF (ALLOCATED(ctx%u_nodal)) DEALLOCATE(ctx%u_nodal)
        IF (ALLOCATED(ctx%lambda)) DEALLOCATE(ctx%lambda)
        IF (ALLOCATED(ctx%constraint_forces)) DEALLOCATE(ctx%constraint_forces)
        
        ! Reset flags
        ctx%is_initialized = .FALSE.
        ctx%constraint_id = 0
        ctx%constraint_type = 0
        ctx%n_dofs = 0
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE PH_Constr_Ctx_Clear
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Clear_Structured
    ! Purpose: Clear constraint context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Clear_Structured(arg)
        TYPE(PH_Constr_Ctx_Clear_Arg), INTENT(INOUT) :: arg
        
        CALL init_error_status(arg%status)
        
        arg%ctx = arg%ctx
        CALL PH_Constr_Ctx_Clear(arg%ctx, arg%status)
        
    END SUBROUTINE PH_Constr_Ctx_Clear_Structured
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Copy
    ! Purpose: Copy constraint context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Copy(ctx_src, ctx_dst, status)
        TYPE(PH_Constr_Ctx), INTENT(IN) :: ctx_src
        TYPE(PH_Constr_Ctx), INTENT(INOUT) :: ctx_dst
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Clear destination
        CALL PH_Constr_Ctx_Clear(ctx_dst, status)
        
        ! Copy scalar values
        ctx_dst%constraint_id = ctx_src%constraint_id
        ctx_dst%constraint_type = ctx_src%constraint_type
        ctx_dst%n_dofs = ctx_src%n_dofs
        ctx_dst%enforcement_method = ctx_src%enforcement_method
        ctx_dst%penalty_parameter = ctx_src%penalty_parameter
        ctx_dst%violation_norm = ctx_src%violation_norm
        ctx_dst%max_violation = ctx_src%max_violation
        ctx_dst%tolerance = ctx_src%tolerance
        ctx_dst%iteration_count = ctx_src%iteration_count
        ctx_dst%converged = ctx_src%converged
        ctx_dst%is_initialized = ctx_src%is_initialized
        ctx_dst%is_active = ctx_src%is_active
        
        ! Copy arrays
        IF (ALLOCATED(ctx_src%dof_map)) THEN
            ALLOCATE(ctx_dst%dof_map(SIZE(ctx_src%dof_map)))
            ctx_dst%dof_map = ctx_src%dof_map
        END IF
        
        IF (ALLOCATED(ctx_src%constraint_matrix)) THEN
            ALLOCATE(ctx_dst%constraint_matrix(SIZE(ctx_src%constraint_matrix, 1), &
                                              SIZE(ctx_src%constraint_matrix, 2)))
            ctx_dst%constraint_matrix = ctx_src%constraint_matrix
        END IF
        
        IF (ALLOCATED(ctx_src%constraint_rhs)) THEN
            ALLOCATE(ctx_dst%constraint_rhs(SIZE(ctx_src%constraint_rhs)))
            ctx_dst%constraint_rhs = ctx_src%constraint_rhs
        END IF
        
        IF (ALLOCATED(ctx_src%u_nodal)) THEN
            ALLOCATE(ctx_dst%u_nodal(SIZE(ctx_src%u_nodal)))
            ctx_dst%u_nodal = ctx_src%u_nodal
        END IF
        
        IF (ALLOCATED(ctx_src%lambda)) THEN
            ALLOCATE(ctx_dst%lambda(SIZE(ctx_src%lambda)))
            ctx_dst%lambda = ctx_src%lambda
        END IF
        
        IF (ALLOCATED(ctx_src%constraint_forces)) THEN
            ALLOCATE(ctx_dst%constraint_forces(SIZE(ctx_src%constraint_forces)))
            ctx_dst%constraint_forces = ctx_src%constraint_forces
        END IF
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE PH_Constr_Ctx_Copy
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Copy_Structured
    ! Purpose: Copy constraint context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Copy_Structured(arg)
        TYPE(PH_Constr_Ctx_Copy_Arg), INTENT(INOUT) :: arg
        
        CALL init_error_status(arg%status)
        
        CALL PH_Constr_Ctx_Copy(arg%ctx_src, arg%ctx_dst, arg%status)
        
    END SUBROUTINE PH_Constr_Ctx_Copy_Structured
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Valid
    ! Purpose: Validate constraint context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Valid(ctx, is_valid, status)
        TYPE(PH_Constr_Ctx), INTENT(IN) :: ctx
        LOGICAL, INTENT(OUT) :: is_valid
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        is_valid = .TRUE.
        
        ! Check initialization
        IF (.NOT. ctx%is_initialized) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Constr_Ctx_Valid: Ctx not initialized'
            RETURN
        END IF
        
        ! Check basic properties
        IF (ctx%n_dofs <= 0) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Constr_Ctx_Valid: Invalid n_dofs'
            RETURN
        END IF
        
        ! Check arrays
        IF (.NOT. ALLOCATED(ctx%dof_map) .OR. &
            SIZE(ctx%dof_map) /= ctx%n_dofs) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Constr_Ctx_Valid: Invalid dof_map array'
            RETURN
        END IF
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE PH_Constr_Ctx_Valid
    
    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Constr_Ctx_Valid_Structured
    ! Purpose: Validate constraint context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Constr_Ctx_Valid_Structured(arg)
        TYPE(PH_Constr_Ctx_Valid_Arg), INTENT(INOUT) :: arg
        
        CALL init_error_status(arg%status)
        
        CALL PH_Constr_Ctx_Valid(arg%ctx, arg%is_valid, arg%status)
        
    END SUBROUTINE PH_Constr_Ctx_Valid_Structured
    
    PUBLIC :: PH_Constr_Ctx_Init_Structured
    PUBLIC :: PH_Constr_Ctx_Clear_Structured
    PUBLIC :: PH_Constr_Ctx_Copy_Structured
    PUBLIC :: PH_Constr_Ctx_Valid_Structured
    
END MODULE PH_Constr_Def
