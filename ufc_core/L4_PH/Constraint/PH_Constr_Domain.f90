!===============================================================================
! MODULE: PH_Constr_Domain
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Domain �?constraint domain container and enforcement algorithms
! BRIEF:  MPC/RBE/Tie constraint enforcement, Ctx/State/Params types,
!         constraint assembly (K_aux/F_aux), transformation, elimination.
!===============================================================================
!
! Theory chain:
! MPC: sum_i A_i u_i = rhs (linear constraint equations)
! RBE2: u_slave = u_master + theta_master x r (rigid body kinematics)
! RBE3: u_ref = sum_i w_i u_i (weighted average, distributing coupling)
! Tie: u_slave = N(xi_master) u_master (surface-to-surface tie)
! Lagrange: [K C^T; C 0][u; lambda] = [f; g] (augmented system)
!
! Data chain:
!   Container path: g_ufc_global%ph_layer%constraint
!   Ctx:    step_idx/incr_idx (three-step indexing), active constraint lists, constraint equation coefficients
!   State:  Lagrange multipliers, constraint residuals, active flags
!   Params: Enforcement method, tolerances
!   Lifecycle: Step-level; step_idx/incr_idx from L5 Runner at Init
!
! Contents:
!   Types: PH_Constraint_Ctx / PH_Constraint_State / PH_Constraint_Params
!          PH_Constraint_Domain
!   Subroutines: Init/Finalize/Register/AddMPCEquation/GetSummary;
!                Assemble_KauxFaux, Apply_Transformation, BuildDofMaskFromMPC,
!                ExtendCSRForMPC, Apply_Elimination_CSR, Update_Lambda;
!                Private: ph_constr_pick_mpc_dep (MPC pivot / dependent term)
!
! Design outline: L4_PH Constraint domain; see docs/UFC_Constraint_L3_PH_RT_Chain.md
! Contract: L4_PH/Constraint/CONTRACT.md; L3 Desc: L3_MD/Constraint/CONTRACT.md
! USE contract: L1_IF only in this module; L3 fill via PH_L4_Populate_Constraint (MD_Const_* read-only)
! Status: Phase B (Arg-wrapped)
! Last verified: 2026-03-11
!======================================================================
MODULE PH_Constr_Domain
  USE IF_Base_Def,   ONLY: ZERO
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! --- Enforcement method enums (PH_CONSTR_ prefix; PH_CONS_* legacy aliases) ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_ELIMINATION = 0_i4  ! DOF elimination + mask (preferred)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TRANSFORM  = 1_i4  ! Transformation
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_LAGRANGE   = 2_i4  ! Lagrange multiplier
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_PENALTY    = 3_i4  ! Penalty method
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_AUGLAG     = 4_i4  ! Augmented Lagrangian

  ! --- Constraint type enums (PH_CONSTR_TYPE_ prefix) ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_MPC      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_RBE2     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_RBE3     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_TIE      = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_COUPLING = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONSTR_TYPE_EMBEDDED = 6_i4

  !---------------------------------------------------------------------------
  ! TYPE: PH_Constr_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking
  !        for Constraint evolution. Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Constr_Inc_Evo_Ctx

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

  TYPE, PUBLIC :: PH_Constraint_State
    REAL(wp), ALLOCATABLE :: lambda_mpc(:)    ! Lagrange multipliers for MPC
    REAL(wp), ALLOCATABLE :: lambda_tie(:)    ! Lagrange multipliers for tie
    REAL(wp), ALLOCATABLE :: g_mpc(:)         ! Constraint residuals (MPC)
    REAL(wp), ALLOCATABLE :: g_tie(:)         ! Constraint residuals (tie)
    LOGICAL,  ALLOCATABLE :: isActive(:)      ! Active/inactive per constraint
    REAL(wp)              :: maxViolation = 0.0_wp
  END TYPE PH_Constraint_State

  TYPE, PUBLIC :: PH_Constraint_Params
    INTEGER(i4) :: enforcementMethod = PH_CONSTR_ELIMINATION  ! Preferred: DOF elimination + mask
    REAL(wp)    :: penaltyStiffness  = 1.0e+10_wp
    REAL(wp)    :: constraintTol     = 1.0e-8_wp
    INTEGER(i4) :: maxAugLagIter     = 10_i4
  END TYPE PH_Constraint_Params

  ! ------------------------------------------------------------------
  ! Arg types
  ! ------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_Register_Arg
    INTEGER(i4) :: constraintType = PH_CONSTR_TYPE_MPC  ! constraint type enum (IN)
    INTEGER(i4) :: constraintId   = 0_i4          ! user-provided id     (IN)
    TYPE(ErrorStatusType) :: status               !                      (OUT)
  END TYPE PH_Constr_Register_Arg

  TYPE, PUBLIC :: PH_Constr_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE PH_Constr_GetSummary_Arg

  ! > Add one MPC equation: coeffs(j)*u(dofs(j)) = rhs
  TYPE, PUBLIC :: PH_Constr_AddMPCEquation_Arg
    INTEGER(i4) :: nTerms   = 0_i4         ! IN: number of terms
    REAL(wp),    ALLOCATABLE :: coeffs(:)  ! IN: coefficients (nTerms)
    INTEGER(i4), ALLOCATABLE :: dofs(:)   ! IN: DOF indices (nTerms)
    REAL(wp)    :: rhs      = 0.0_wp      ! IN: RHS value
    INTEGER(i4) :: mpcId    = 0_i4        ! OUT: assigned MPC index
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_AddMPCEquation_Arg

  ! ------------------------------------------------------------------
  ! Algorithm Arg types (Phase B algo stubs)
  ! ------------------------------------------------------------------

  !> Assemble auxiliary stiffness K_aux and force F_aux from constraint equations
  !> Warm path: called once per increment; builds augmented system contributions
  TYPE, PUBLIC :: PH_Constr_Assemble_KauxFaux_Arg
    INTEGER(i4) :: nTotalDOF    = 0_i4    ! IN: total global DOF count
    INTEGER(i4) :: nLambda      = 0_i4    ! IN: number of Lagrange multipliers
    REAL(wp)    :: penaltyStiff = 0.0_wp  ! IN: penalty stiffness (method=Penalty)
    ! OUT: contributions to be added to global K and F by caller
    REAL(wp), ALLOCATABLE :: K_aux(:,:)   ! (nTotalDOF+nLambda, nTotalDOF+nLambda)
    REAL(wp), ALLOCATABLE :: F_aux(:)     ! (nTotalDOF+nLambda)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Assemble_KauxFaux_Arg

  !> Apply transformation matrix T to reduce constrained DOFs
  !> Called before solve when enforcementMethod = TRANSFORM
  !> Theory: K_red = T^T * K_full * T,  f_red = T^T * f_full
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

  !> Build dofMask from MPC equations (elimination method)
  !> For each MPC: pick one dependent DOF (|coeff| max), set dofMask(dep)=0
  TYPE, PUBLIC :: PH_Constr_BuildDofMask_Arg
    INTEGER(i4) :: nTotalDOF   = 0_i4    ! IN: total DOF count
    INTEGER(i4), ALLOCATABLE :: dofMask(:)       ! INOUT: 1=free, 0=eliminated (nTotalDOF)
    REAL(wp),    ALLOCATABLE :: constrained_value(:) ! INOUT: prescribed/rhs for eliminated (nTotalDOF)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_BuildDofMask_Arg

  !> Extend CSR pattern for MPC fill-in (add (i,j) where row i has K(i,dep) and j in MPC)
  !> Call before Apply_Elimination_CSR when pattern may lack MPC-induced entries
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

  !> Apply MPC elimination on CSR matrix (1D sparse)
  ! > Theory: u_dep = (rhs - c_i*u_i)/c_dep; substitute into K, R
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

  !> Update Lagrange multipliers lambda after solve
  !> Warm path: g = C*u - rhs; maxViolation = max|g_i|
  TYPE, PUBLIC :: PH_Constr_Update_Lambda_Arg
    INTEGER(i4) :: nLambda   = 0_i4       ! IN: number of Lagrange multipliers
    REAL(wp), ALLOCATABLE :: lambda(:)    ! IN: updated lambda from solve
    REAL(wp), ALLOCATABLE :: u(:)         ! IN: displacement for g=C*u-rhs
    REAL(wp)    :: maxViolation = 0.0_wp  ! OUT: max |g_i|
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_Constr_Update_Lambda_Arg

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

CONTAINS

  !--------------------------------------------------------------------
  ! mpc_pick_dependent: pick dependent term row for MPC column `eq`
  !   Rule: term with dof>=1 and maximum |coefficient| (pivot stability).
  !--------------------------------------------------------------------
  SUBROUTINE ph_constr_pick_mpc_dep(maxTerms, eq, mpcDofs, mpcCoeffs, depIdx, c_dep)
    INTEGER(i4), INTENT(IN) :: maxTerms, eq
    INTEGER(i4), INTENT(IN) :: mpcDofs(:, :)
    REAL(wp), INTENT(IN) :: mpcCoeffs(:, :)
    INTEGER(i4), INTENT(OUT) :: depIdx
    REAL(wp), INTENT(OUT) :: c_dep
    INTEGER(i4) :: k

    depIdx = 1_i4
    c_dep = mpcCoeffs(1, eq)
    DO k = 2, maxTerms
      IF (mpcDofs(k, eq) < 1_i4) CYCLE
      IF (ABS(mpcCoeffs(k, eq)) > ABS(c_dep)) THEN
        c_dep = mpcCoeffs(k, eq)
        depIdx = k
      END IF
    END DO
  END SUBROUTINE ph_constr_pick_mpc_dep

  SUBROUTINE Finalize(this)
    CLASS(PH_Constraint_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%ctx%activeMPCIds))  DEALLOCATE(this%ctx%activeMPCIds)
    IF (ALLOCATED(this%ctx%activeRBEIds))  DEALLOCATE(this%ctx%activeRBEIds)
    IF (ALLOCATED(this%ctx%activeTieIds))  DEALLOCATE(this%ctx%activeTieIds)
    IF (ALLOCATED(this%ctx%mpcCoeffs))     DEALLOCATE(this%ctx%mpcCoeffs)
    IF (ALLOCATED(this%ctx%mpcDofs))       DEALLOCATE(this%ctx%mpcDofs)
    IF (ALLOCATED(this%ctx%mpcRHS))        DEALLOCATE(this%ctx%mpcRHS)
    IF (ALLOCATED(this%ctx%rbeMasterNode)) DEALLOCATE(this%ctx%rbeMasterNode)
    IF (ALLOCATED(this%ctx%rbeSlaveNodes)) DEALLOCATE(this%ctx%rbeSlaveNodes)
    IF (ALLOCATED(this%ctx%rbeWeights))    DEALLOCATE(this%ctx%rbeWeights)
    IF (ALLOCATED(this%state%lambda_mpc))  DEALLOCATE(this%state%lambda_mpc)
    IF (ALLOCATED(this%state%lambda_tie))  DEALLOCATE(this%state%lambda_tie)
    IF (ALLOCATED(this%state%g_mpc))       DEALLOCATE(this%state%g_mpc)
    IF (ALLOCATED(this%state%g_tie))       DEALLOCATE(this%state%g_tie)
    IF (ALLOCATED(this%state%isActive))    DEALLOCATE(this%state%isActive)
    this%state%maxViolation = 0.0_wp
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  !--------------------------------------------------------------------
  ! ClearMPCEquations: drop L4 MPC storage only (idempotent Populate).
  !   Does not Finalize the domain or reset params; safe before
  !   PH_L4_Populate_Constraint re-reads L3 constraint_union%mpc(:).
  !--------------------------------------------------------------------
  SUBROUTINE ClearMPCEquations(this)
    CLASS(PH_Constraint_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%ctx%mpcCoeffs)) DEALLOCATE(this%ctx%mpcCoeffs)
    IF (ALLOCATED(this%ctx%mpcDofs)) DEALLOCATE(this%ctx%mpcDofs)
    IF (ALLOCATED(this%ctx%mpcRHS)) DEALLOCATE(this%ctx%mpcRHS)
    this%ctx%nActiveMPC = 0_i4
    IF (ALLOCATED(this%state%lambda_mpc)) DEALLOCATE(this%state%lambda_mpc)
    IF (ALLOCATED(this%state%g_mpc)) DEALLOCATE(this%state%g_mpc)
    IF (ALLOCATED(this%state%isActive)) DEALLOCATE(this%state%isActive)
  END SUBROUTINE ClearMPCEquations

  !--------------------------------------------------------------------
  ! PrepareForPopulate: reset MPC storage + Tie/RBE registration counters
  !   before PH_L4_Populate_Constraint rebuilds from L3 (idempotent).
  !--------------------------------------------------------------------
  SUBROUTINE PrepareForPopulate(this)
    CLASS(PH_Constraint_Domain), INTENT(INOUT) :: this

    CALL this%ClearMPCEquations()
    this%ctx%nActiveTie = 0_i4
    this%ctx%nActiveRBE = 0_i4
    IF (ALLOCATED(this%ctx%activeMPCIds)) DEALLOCATE(this%ctx%activeMPCIds)
    IF (ALLOCATED(this%ctx%activeRBEIds)) DEALLOCATE(this%ctx%activeRBEIds)
    IF (ALLOCATED(this%ctx%activeTieIds)) DEALLOCATE(this%ctx%activeTieIds)
  END SUBROUTINE PrepareForPopulate

  SUBROUTINE Init(this, stepId, status, incr_idx)
    CLASS(PH_Constraint_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                 INTENT(IN)    :: stepId   ! step_idx (md_layer%step )
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4),                 INTENT(IN), OPTIONAL :: incr_idx
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%ctx%nActiveMPC = 0_i4
    this%ctx%nActiveRBE = 0_i4
    this%ctx%nActiveTie = 0_i4
    this%params         = PH_Constraint_Params()
    this%initialized    = .TRUE.
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE Init

  !====================================================================
  ! PH_Constraint_Domain_Register  (Arg-wrapped)
  !====================================================================
  SUBROUTINE Register(this, arg)
    CLASS(PH_Constraint_Domain),     INTENT(INOUT) :: this
    TYPE(PH_Constr_Register_Arg), INTENT(INOUT) :: arg
    CALL PH_Constraint_Register_Impl(this, arg%constraintType, &
                                               arg%constraintId, arg%status)
  END SUBROUTINE Register

  !--------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Register_Impl(this, constraintType, &
                                                    constraintId, status)
    CLASS(PH_Constraint_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                 INTENT(IN)    :: constraintType
    INTEGER(i4),                 INTENT(IN)    :: constraintId
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF

    IF (constraintType < PH_CONSTR_TYPE_MPC .OR. constraintType > PH_CONSTR_TYPE_EMBEDDED) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid constraint type"
      RETURN
    END IF

    SELECT CASE(constraintType)
    CASE(PH_CONSTR_TYPE_MPC)
      this%ctx%nActiveMPC = this%ctx%nActiveMPC + 1_i4
    CASE(PH_CONSTR_TYPE_RBE2, PH_CONSTR_TYPE_RBE3)
      this%ctx%nActiveRBE = this%ctx%nActiveRBE + 1_i4
    CASE(PH_CONSTR_TYPE_TIE)
      this%ctx%nActiveTie = this%ctx%nActiveTie + 1_i4
    CASE(PH_CONSTR_TYPE_COUPLING)
      this%ctx%nActiveRBE = this%ctx%nActiveRBE + 1_i4
    CASE(PH_CONSTR_TYPE_EMBEDDED)
      this%ctx%nActiveRBE = this%ctx%nActiveRBE + 1_i4
    END SELECT

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Constraint_Register_Impl

  !====================================================================
  ! PH_Constraint_Domain_GetSummary  (Arg-wrapped)
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(PH_Constraint_Domain),      INTENT(IN)    :: this
    TYPE(PH_Constr_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL PH_Constraint_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  !--------------------------------------------------------------------
  SUBROUTINE PH_Constraint_GetSummary_Impl(this, summary, status)
    CLASS(PH_Constraint_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),          INTENT(OUT) :: summary
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3)') &
      "Constraint Summary: MPC=", this%ctx%nActiveMPC, &
      ", RBE=", this%ctx%nActiveRBE, &
      ", Tie=", this%ctx%nActiveTie, &
      ", MaxViol=", this%state%maxViolation, &
      ", Penalty=", this%params%penaltyStiffness

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Constraint_GetSummary_Impl

  !====================================================================
  ! AddMPCEquation: append one MPC: coeffs(j)*u(dofs(j)) = rhs
  ! Populates mpcCoeffs, mpcDofs, mpcRHS; extends state arrays
  !====================================================================
  SUBROUTINE AddMPCEquation(this, arg)
    CLASS(PH_Constraint_Domain),            INTENT(INOUT) :: this
    TYPE(PH_Constr_AddMPCEquation_Arg), INTENT(INOUT) :: arg
    INTEGER(i4), PARAMETER :: MAX_TERMS_DEFAULT = 16_i4
    INTEGER(i4) :: nTerms, nNew, maxTerms, k, nOld
    REAL(wp),    ALLOCATABLE :: ctmp(:,:)
    INTEGER(i4), ALLOCATABLE :: dtmp(:,:)
    REAL(wp),    ALLOCATABLE :: rtmp(:)
    LOGICAL,     ALLOCATABLE :: ltmp(:)

    CALL init_error_status(arg%status)
    arg%mpcId = 0_i4
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    nTerms = arg%nTerms
    IF (nTerms < 1) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "AddMPCEquation: nTerms must be >= 1"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%coeffs) .OR. .NOT. ALLOCATED(arg%dofs)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "AddMPCEquation: coeffs/dofs must be allocated"
      RETURN
    END IF
    IF (SIZE(arg%coeffs) < nTerms .OR. SIZE(arg%dofs) < nTerms) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "AddMPCEquation: coeffs/dofs size < nTerms"
      RETURN
    END IF

    nNew = this%ctx%nActiveMPC + 1_i4
    maxTerms = MAX(nTerms, MAX_TERMS_DEFAULT)

    IF (.NOT. ALLOCATED(this%ctx%mpcCoeffs)) THEN
      ALLOCATE(this%ctx%mpcCoeffs(maxTerms, nNew))
      ALLOCATE(this%ctx%mpcDofs(maxTerms, nNew))
      ALLOCATE(this%ctx%mpcRHS(nNew))
      this%ctx%mpcCoeffs = ZERO
      this%ctx%mpcDofs = 0_i4
    ELSE IF (SIZE(this%ctx%mpcCoeffs,1) < maxTerms .OR. SIZE(this%ctx%mpcCoeffs,2) < nNew) THEN
      maxTerms = MAX(maxTerms, SIZE(this%ctx%mpcCoeffs,1))
      ALLOCATE(ctmp(maxTerms, nNew), dtmp(maxTerms, nNew), rtmp(nNew))
      ctmp = ZERO
      dtmp = 0_i4
      ctmp(1:SIZE(this%ctx%mpcCoeffs,1), 1:this%ctx%nActiveMPC) = this%ctx%mpcCoeffs
      dtmp(1:SIZE(this%ctx%mpcDofs,1), 1:this%ctx%nActiveMPC) = this%ctx%mpcDofs
      rtmp(1:this%ctx%nActiveMPC) = this%ctx%mpcRHS
      DEALLOCATE(this%ctx%mpcCoeffs, this%ctx%mpcDofs, this%ctx%mpcRHS)
      ALLOCATE(this%ctx%mpcCoeffs(maxTerms, nNew), this%ctx%mpcDofs(maxTerms, nNew), this%ctx%mpcRHS(nNew))
      this%ctx%mpcCoeffs = ctmp
      this%ctx%mpcDofs = dtmp
      this%ctx%mpcRHS = rtmp
      DEALLOCATE(ctmp, dtmp, rtmp)
    END IF

    IF (SIZE(this%ctx%mpcCoeffs,2) < nNew) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "AddMPCEquation: allocation failed"
      RETURN
    END IF

    DO k = 1, nTerms
      this%ctx%mpcCoeffs(k, nNew) = arg%coeffs(k)
      this%ctx%mpcDofs(k, nNew) = arg%dofs(k)
    END DO
    this%ctx%mpcRHS(nNew) = arg%rhs
    this%ctx%nActiveMPC = nNew

    ! Extend state arrays for Lagrange
    IF (ALLOCATED(this%state%lambda_mpc)) THEN
      IF (SIZE(this%state%lambda_mpc) < nNew) THEN
        nOld = SIZE(this%state%lambda_mpc)
        ALLOCATE(rtmp(nNew))
        rtmp = ZERO
        rtmp(1:nOld) = this%state%lambda_mpc(1:nOld)
        DEALLOCATE(this%state%lambda_mpc)
        ALLOCATE(this%state%lambda_mpc(nNew))
        this%state%lambda_mpc = rtmp
        DEALLOCATE(rtmp)
      END IF
    ELSE
      ALLOCATE(this%state%lambda_mpc(nNew))
      this%state%lambda_mpc = ZERO
    END IF
    IF (ALLOCATED(this%state%g_mpc)) THEN
      IF (SIZE(this%state%g_mpc) < nNew) THEN
        nOld = SIZE(this%state%g_mpc)
        ALLOCATE(rtmp(nNew))
        rtmp = ZERO
        rtmp(1:nOld) = this%state%g_mpc(1:nOld)
        DEALLOCATE(this%state%g_mpc)
        ALLOCATE(this%state%g_mpc(nNew))
        this%state%g_mpc = rtmp
        DEALLOCATE(rtmp)
      END IF
    ELSE
      ALLOCATE(this%state%g_mpc(nNew))
      this%state%g_mpc = ZERO
    END IF
    IF (ALLOCATED(this%state%isActive)) THEN
      IF (SIZE(this%state%isActive) < nNew) THEN
        nOld = SIZE(this%state%isActive)
        ALLOCATE(ltmp(nNew))
        ltmp(1:nOld) = this%state%isActive(1:nOld)
        ltmp(nOld+1:nNew) = .TRUE.
        DEALLOCATE(this%state%isActive)
        this%state%isActive = ltmp
      END IF
    ELSE
      ALLOCATE(this%state%isActive(nNew))
      this%state%isActive = .TRUE.
    END IF

    arg%mpcId = nNew
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE AddMPCEquation

  !====================================================================
  ! Algorithm: Assemble_KauxFaux
  ! Warm path: build augmented [K C^T; C 0] or penalty contributions
  ! Theory: Lagrange [K C^T; C 0][u; ]=[f;g]; Penalty K+= C^T C, f+= C^T g
  !====================================================================
  SUBROUTINE Assemble_KauxFaux(this, arg)
    ! [Theory] Lagrange [K C^T; C 0][u;lambda]=[f;g]; Penalty K+=alpha*C^T*C, f+=alpha*C^T*rhs
    ! [Logic] enforcementMethod selects Lagrange / Penalty / (Elimination elsewhere)
    ! [Compute] Lagrange: K_aux(dof,lam)+=c, K_aux(lam,dof)+=c, F_aux(lam)+=rhs; Penalty: K_ij += alpha*c_i*c_j
    ! [Data] mpcCoeffs, mpcDofs, mpcRHS -> arg%K_aux, arg%F_aux
    CLASS(PH_Constraint_Domain),               INTENT(INOUT) :: this
    TYPE(PH_Constr_Assemble_KauxFaux_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: nDOF, nLam, i, j, k, dof_i, dof_j, maxTerms
    REAL(wp) :: c_i, c_j, alpha

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    nDOF = arg%nTotalDOF
    nLam = arg%nLambda
    IF (nDOF < 1 .OR. nLam < 0) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%K_aux) .OR. .NOT. ALLOCATED(arg%F_aux)) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    arg%K_aux = ZERO
    arg%F_aux = ZERO

    IF (this%ctx%nActiveMPC < 1 .OR. .NOT. ALLOCATED(this%ctx%mpcCoeffs) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcDofs) .OR. .NOT. ALLOCATED(this%ctx%mpcRHS)) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    maxTerms = SIZE(this%ctx%mpcCoeffs, 1)
    alpha = MERGE(arg%penaltyStiff, 1.0e+10_wp, arg%penaltyStiff > 0.0_wp)

    SELECT CASE(this%params%enforcementMethod)
    CASE(PH_CONSTR_LAGRANGE)
      IF (nLam < this%ctx%nActiveMPC) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "Assemble_KauxFaux: nLambda < nActiveMPC for Lagrange MPC"
        RETURN
      END IF
      DO i = 1, this%ctx%nActiveMPC
        DO k = 1, maxTerms
          dof_i = this%ctx%mpcDofs(k, i)
          IF (dof_i < 1 .OR. dof_i > nDOF) CYCLE
          c_i = this%ctx%mpcCoeffs(k, i)
          arg%K_aux(dof_i, nDOF + i) = arg%K_aux(dof_i, nDOF + i) + c_i
          arg%K_aux(nDOF + i, dof_i) = arg%K_aux(nDOF + i, dof_i) + c_i
        END DO
        arg%F_aux(nDOF + i) = this%ctx%mpcRHS(i)
      END DO
    CASE(PH_CONSTR_PENALTY)
      DO i = 1, this%ctx%nActiveMPC
        DO k = 1, maxTerms
          dof_i = this%ctx%mpcDofs(k, i)
          IF (dof_i < 1 .OR. dof_i > nDOF) CYCLE
          c_i = this%ctx%mpcCoeffs(k, i)
          arg%F_aux(dof_i) = arg%F_aux(dof_i) + alpha * c_i * this%ctx%mpcRHS(i)
          DO j = 1, maxTerms
            dof_j = this%ctx%mpcDofs(j, i)
            IF (dof_j < 1 .OR. dof_j > nDOF) CYCLE
            c_j = this%ctx%mpcCoeffs(j, i)
            arg%K_aux(dof_i, dof_j) = arg%K_aux(dof_i, dof_j) + alpha * c_i * c_j
          END DO
        END DO
      END DO
    CASE DEFAULT
      ! ELIMINATION, TRANSFORM: handled by Apply_Elimination_CSR / Apply_Transformation
    END SELECT
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE Assemble_KauxFaux

  !====================================================================
  ! BuildDofMaskFromMPC: set dofMask(dep)=0 for each MPC's dependent DOF
  ! For each MPC: pick DOF with max |coeff| as dependent (numerical stability)
  !====================================================================
  SUBROUTINE BuildDofMaskFromMPC(this, arg)
    CLASS(PH_Constraint_Domain),            INTENT(INOUT) :: this
    TYPE(PH_Constr_BuildDofMask_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i, maxTerms, depIdx
    REAL(wp) :: c_dep

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    IF (arg%nTotalDOF < 1 .OR. .NOT. ALLOCATED(arg%dofMask) .OR. SIZE(arg%dofMask) < arg%nTotalDOF) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "BuildDofMask: dofMask required, size >= nTotalDOF"
      RETURN
    END IF
    IF (ALLOCATED(arg%constrained_value) .AND. SIZE(arg%constrained_value) < arg%nTotalDOF) THEN
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (this%ctx%nActiveMPC < 1 .OR. .NOT. ALLOCATED(this%ctx%mpcCoeffs) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcDofs)) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    maxTerms = SIZE(this%ctx%mpcCoeffs, 1)

    DO i = 1, this%ctx%nActiveMPC
      CALL ph_constr_pick_mpc_dep(maxTerms, i, this%ctx%mpcDofs, this%ctx%mpcCoeffs, depIdx, c_dep)
      IF (this%ctx%mpcDofs(depIdx, i) >= 1 .AND. this%ctx%mpcDofs(depIdx, i) <= arg%nTotalDOF) &
        arg%dofMask(this%ctx%mpcDofs(depIdx, i)) = 0_i4
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE BuildDofMaskFromMPC

  !====================================================================
  ! ExtendCSRForMPC: add fill-in pattern for MPC elimination
  ! New (i,j): rows i with K(i,dep) and j in MPC; merge with existing, build CSR
  !====================================================================
  SUBROUTINE ExtendCSRForMPC(this, arg)
    CLASS(PH_Constraint_Domain),                 INTENT(INOUT) :: this
    TYPE(PH_Constr_ExtendCSRForMPC_Arg),    INTENT(INOUT) :: arg
    INTEGER(i4) :: nDOF, nnz_in, m, k, dep, depIdx, dof_j, i, p, pStart, pEnd
    INTEGER(i4) :: maxTerms, nNew, nTotal, idx
    INTEGER(i4), ALLOCATABLE :: pairs(:,:)
    REAL(wp),    ALLOCATABLE :: valTmp(:)
    REAL(wp) :: c_pick
    LOGICAL :: hasDep

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    nDOF = MERGE(SIZE(arg%rowPtr_in) - 1, arg%nDOF, arg%nDOF < 1)
    IF (nDOF < 1 .OR. .NOT. ALLOCATED(arg%rowPtr_in) .OR. .NOT. ALLOCATED(arg%colInd_in) .OR. &
        .NOT. ALLOCATED(arg%values_in)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "ExtendCSRForMPC: rowPtr_in, colInd_in, values_in required"
      RETURN
    END IF
    nnz_in = arg%rowPtr_in(nDOF + 1) - 1
    IF (this%ctx%nActiveMPC < 1 .OR. .NOT. ALLOCATED(this%ctx%mpcCoeffs) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcDofs)) THEN
      IF (ALLOCATED(arg%rowPtr_out)) DEALLOCATE(arg%rowPtr_out)
      IF (ALLOCATED(arg%colInd_out)) DEALLOCATE(arg%colInd_out)
      IF (ALLOCATED(arg%values_out)) DEALLOCATE(arg%values_out)
      ALLOCATE(arg%rowPtr_out(nDOF + 1), arg%colInd_out(nnz_in), arg%values_out(nnz_in))
      arg%rowPtr_out = arg%rowPtr_in
      arg%colInd_out(1:nnz_in) = arg%colInd_in(1:nnz_in)
      arg%values_out(1:nnz_in) = arg%values_in(1:nnz_in)
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    maxTerms = SIZE(this%ctx%mpcCoeffs, 1)
    nNew = this%ctx%nActiveMPC * nDOF * maxTerms
    nTotal = nnz_in + nNew
    ALLOCATE(pairs(2, nTotal), valTmp(nTotal))
    idx = 0
    DO i = 1, nDOF
      pStart = arg%rowPtr_in(i)
      pEnd = arg%rowPtr_in(i + 1) - 1
      DO p = pStart, pEnd
        idx = idx + 1
        pairs(1, idx) = i
        pairs(2, idx) = arg%colInd_in(p)
        valTmp(idx) = arg%values_in(p)
      END DO
    END DO
    DO m = 1, this%ctx%nActiveMPC
      CALL ph_constr_pick_mpc_dep(maxTerms, m, this%ctx%mpcDofs, this%ctx%mpcCoeffs, depIdx, c_pick)
      dep = this%ctx%mpcDofs(depIdx, m)
      IF (dep < 1 .OR. dep > nDOF) CYCLE
      DO i = 1, nDOF
        hasDep = .FALSE.
        pStart = arg%rowPtr_in(i)
        pEnd = arg%rowPtr_in(i + 1) - 1
        DO p = pStart, pEnd
          IF (arg%colInd_in(p) == dep) THEN
            hasDep = .TRUE.
            EXIT
          END IF
        END DO
        IF (.NOT. hasDep) CYCLE
        DO k = 1, maxTerms
          dof_j = this%ctx%mpcDofs(k, m)
          IF (dof_j < 1 .OR. dof_j > nDOF .OR. dof_j == dep) CYCLE
          IF (idx >= SIZE(pairs, 2)) THEN
            arg%status%status_code = IF_STATUS_INVALID
            arg%status%message = "ExtendCSRForMPC: pair buffer exceeded (CSR+MPC fill-in)"
            DEALLOCATE(pairs, valTmp)
            RETURN
          END IF
          idx = idx + 1
          pairs(1, idx) = i
          pairs(2, idx) = dof_j
          valTmp(idx) = ZERO
        END DO
      END DO
    END DO
    nTotal = idx
    CALL PH_Constraint_MergePairsToCSR(nDOF, nTotal, pairs, valTmp, &
      arg%rowPtr_out, arg%colInd_out, arg%values_out, arg%status)
    DEALLOCATE(pairs, valTmp)
  END SUBROUTINE ExtendCSRForMPC

  !--------------------------------------------------------------------
  ! Merge (i,j,val) pairs: sort by (i,j), sum duplicates, build CSR
  !--------------------------------------------------------------------
  SUBROUTINE PH_Constraint_MergePairsToCSR(nDOF, n, pairs, valTmp, rowPtr_out, colInd_out, values_out, status)
    INTEGER(i4), INTENT(IN) :: nDOF, n
    INTEGER(i4), INTENT(IN) :: pairs(2, n)
    REAL(wp), INTENT(IN) :: valTmp(n)
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: rowPtr_out(:), colInd_out(:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: values_out(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ord(n), nnz, i, k, row, col, prevRow, prevCol
    INTEGER(i4), ALLOCATABLE :: rowCnt(:)

    CALL init_error_status(status)
    IF (n < 1) THEN
      ALLOCATE(rowPtr_out(nDOF + 1))
      rowPtr_out = 1
      rowPtr_out(nDOF + 1) = 1
      ALLOCATE(colInd_out(0), values_out(0))
      RETURN
    END IF
    DO i = 1, n
      ord(i) = i
    END DO
    CALL PH_Constraint_SortPairsByRowCol(n, pairs, ord)
    nnz = 1
    prevRow = pairs(1, ord(1))
    prevCol = pairs(2, ord(1))
    DO k = 2, n
      i = ord(k)
      row = pairs(1, i)
      col = pairs(2, i)
      IF (row == prevRow .AND. col == prevCol) CYCLE
      nnz = nnz + 1
      prevRow = row
      prevCol = col
    END DO
    IF (ALLOCATED(rowPtr_out)) DEALLOCATE(rowPtr_out)
    IF (ALLOCATED(colInd_out)) DEALLOCATE(colInd_out)
    IF (ALLOCATED(values_out)) DEALLOCATE(values_out)
    ALLOCATE(rowPtr_out(nDOF + 1), colInd_out(nnz), values_out(nnz), rowCnt(nDOF))
    rowCnt = 0
    nnz = 0
    prevRow = -1
    prevCol = -1
    DO k = 1, n
      i = ord(k)
      row = pairs(1, i)
      col = pairs(2, i)
      IF (row == prevRow .AND. col == prevCol) THEN
        values_out(nnz) = values_out(nnz) + valTmp(i)
        CYCLE
      END IF
      nnz = nnz + 1
      colInd_out(nnz) = col
      values_out(nnz) = valTmp(i)
      rowCnt(row) = rowCnt(row) + 1
      prevRow = row
      prevCol = col
    END DO
    rowPtr_out(1) = 1
    DO i = 1, nDOF
      rowPtr_out(i + 1) = rowPtr_out(i) + rowCnt(i)
    END DO
    DEALLOCATE(rowCnt)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_MergePairsToCSR

  !--------------------------------------------------------------------
  ! Insertion sort ord by pairs(1,ord), pairs(2,ord)
  !--------------------------------------------------------------------
  SUBROUTINE PH_Constraint_SortPairsByRowCol(n, pairs, ord)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: pairs(2, n)
    INTEGER(i4), INTENT(INOUT) :: ord(n)
    INTEGER(i4) :: i, j, tmp, r1, c1, r2, c2

    DO i = 2, n
      tmp = ord(i)
      j = i - 1
      r1 = pairs(1, tmp)
      c1 = pairs(2, tmp)
      DO WHILE (j >= 1)
        r2 = pairs(1, ord(j))
        c2 = pairs(2, ord(j))
        IF (r1 > r2 .OR. (r1 == r2 .AND. c1 >= c2)) EXIT
        ord(j + 1) = ord(j)
        j = j - 1
      END DO
      ord(j + 1) = tmp
    END DO
  END SUBROUTINE PH_Constraint_SortPairsByRowCol

  !====================================================================
  ! Apply_Elimination_CSR: MPC elimination on 1D sparse (CSR)
  ! Theory: u_dep = (rhs - c_j*u_j)/c_dep; substitute into K, R
  ! Modifies K(rowPtr,colInd,values) and R in-place
  !====================================================================
  SUBROUTINE Apply_Elimination_CSR(this, arg)
    CLASS(PH_Constraint_Domain),               INTENT(INOUT) :: this
    TYPE(PH_Constr_Apply_Elimination_CSR_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i, j, k, m, nDOF, dep, rowStart, rowEnd, p, maxTerms
    INTEGER(i4) :: depIdx, dof_j
    REAL(wp) :: c_dep, c_j, k_idep, fac

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    nDOF = arg%nDOF
    IF (nDOF < 1) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%rowPtr) .OR. .NOT. ALLOCATED(arg%colInd) .OR. .NOT. ALLOCATED(arg%values) .OR. &
        .NOT. ALLOCATED(arg%R)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Apply_Elimination_CSR: rowPtr, colInd, values, R required"
      RETURN
    END IF
    IF (this%ctx%nActiveMPC < 1 .OR. .NOT. ALLOCATED(this%ctx%mpcCoeffs) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcDofs) .OR. .NOT. ALLOCATED(this%ctx%mpcRHS)) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    maxTerms = SIZE(this%ctx%mpcCoeffs, 1)

    DO m = 1, this%ctx%nActiveMPC
      CALL ph_constr_pick_mpc_dep(maxTerms, m, this%ctx%mpcDofs, this%ctx%mpcCoeffs, depIdx, c_dep)
      dep = this%ctx%mpcDofs(depIdx, m)
      IF (dep < 1 .OR. dep > nDOF .OR. ABS(c_dep) < 1.0e-30_wp) CYCLE

      DO i = 1, nDOF
        IF (i == dep) CYCLE
        rowStart = arg%rowPtr(i)
        rowEnd = arg%rowPtr(i + 1) - 1
        k_idep = ZERO
        DO p = rowStart, rowEnd
          IF (arg%colInd(p) == dep) THEN
            k_idep = arg%values(p)
            EXIT
          END IF
        END DO
        IF (ABS(k_idep) < 1.0e-30_wp) CYCLE

        fac = k_idep / c_dep
        arg%R(i) = arg%R(i) + fac * this%ctx%mpcRHS(m)
        DO k = 1, maxTerms
          dof_j = this%ctx%mpcDofs(k, m)
          IF (dof_j < 1 .OR. dof_j > nDOF .OR. dof_j == dep) CYCLE
          c_j = this%ctx%mpcCoeffs(k, m)
          DO p = rowStart, rowEnd
            IF (arg%colInd(p) == dof_j) THEN
              arg%values(p) = arg%values(p) - fac * c_j
              EXIT
            END IF
          END DO
        END DO
        DO p = rowStart, rowEnd
          IF (arg%colInd(p) == dep) THEN
            arg%values(p) = ZERO
            EXIT
          END IF
        END DO
      END DO

      ! Row dep: K(dep,dep)=1, K(dep,j)=c_j/c_dep for j in MPC, R(dep)=rhs/c_dep
      rowStart = arg%rowPtr(dep)
      rowEnd = arg%rowPtr(dep + 1) - 1
      DO p = rowStart, rowEnd
        IF (arg%colInd(p) == dep) THEN
          arg%values(p) = 1.0_wp
        ELSE
          arg%values(p) = ZERO
          DO k = 1, maxTerms
            dof_j = this%ctx%mpcDofs(k, m)
            IF (dof_j == dep) CYCLE
            IF (arg%colInd(p) == dof_j) THEN
              arg%values(p) = this%ctx%mpcCoeffs(k, m) / c_dep
              EXIT
            END IF
          END DO
        END IF
      END DO
      arg%R(dep) = this%ctx%mpcRHS(m) / c_dep
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE Apply_Elimination_CSR

  !====================================================================
  ! Algorithm: Apply_Transformation
  ! Cold path: K_red = T^T * K_full * T,  f_red = T^T * f_full
  ! Theory: u_full = T * u_red; reduced system for constrained DOFs
  !====================================================================
  SUBROUTINE Apply_Transformation(this, arg)
    CLASS(PH_Constraint_Domain),                  INTENT(INOUT) :: this
    TYPE(PH_Constr_Apply_Transformation_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: nf, nr

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    IF (this%params%enforcementMethod /= PH_CONSTR_TRANSFORM) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    nf = arg%nDOF_full
    nr = arg%nDOF_reduced
    IF (nf < 1 .OR. nr < 1) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%T) .OR. .NOT. ALLOCATED(arg%K_full) .OR. &
        .NOT. ALLOCATED(arg%f_full) .OR. .NOT. ALLOCATED(arg%K_red) .OR. &
        .NOT. ALLOCATED(arg%f_red)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "T, K_full, f_full, K_red, f_red required"
      RETURN
    END IF
    IF (SIZE(arg%T,1) < nr .OR. SIZE(arg%T,2) < nf .OR. &
        SIZE(arg%K_full,1) < nf .OR. SIZE(arg%K_full,2) < nf .OR. &
        SIZE(arg%f_full) < nf .OR. SIZE(arg%K_red,1) < nr .OR. &
        SIZE(arg%K_red,2) < nr .OR. SIZE(arg%f_red) < nr) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Array size mismatch"
      RETURN
    END IF
    ! K_red = T^T * K_full * T
    arg%K_red(1:nr, 1:nr) = MATMUL(TRANSPOSE(arg%T(1:nr, 1:nf)), &
         MATMUL(arg%K_full(1:nf, 1:nf), arg%T(1:nr, 1:nf)))
    ! f_red = T^T * f_full
    arg%f_red(1:nr) = MATMUL(TRANSPOSE(arg%T(1:nr, 1:nf)), arg%f_full(1:nf))
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE Apply_Transformation

  !====================================================================
  ! Algorithm: Update_Lambda
  ! Warm path: lambda <- solve result; g = C*u - rhs; maxViolation = max|g|
  !====================================================================
  SUBROUTINE Update_Lambda(this, arg)
    CLASS(PH_Constraint_Domain),            INTENT(INOUT) :: this
    TYPE(PH_Constr_Update_Lambda_Arg),  INTENT(INOUT) :: arg
    INTEGER(i4) :: i, k, dof_k, maxTerms
    REAL(wp) :: g_i

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Constraint domain not initialized"
      RETURN
    END IF
    IF (ALLOCATED(arg%lambda) .AND. ALLOCATED(this%state%lambda_mpc) .AND. &
        SIZE(arg%lambda) >= this%ctx%nActiveMPC) THEN
      DO i = 1, this%ctx%nActiveMPC
        this%state%lambda_mpc(i) = arg%lambda(i)
      END DO
    END IF

    arg%maxViolation = 0.0_wp
    IF (this%ctx%nActiveMPC < 1 .OR. .NOT. ALLOCATED(arg%u) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcCoeffs) .OR. .NOT. ALLOCATED(this%ctx%mpcDofs) .OR. &
        .NOT. ALLOCATED(this%ctx%mpcRHS)) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    maxTerms = SIZE(this%ctx%mpcCoeffs, 1)
    DO i = 1, this%ctx%nActiveMPC
      g_i = -this%ctx%mpcRHS(i)
      DO k = 1, maxTerms
        dof_k = this%ctx%mpcDofs(k, i)
        IF (dof_k >= 1 .AND. dof_k <= SIZE(arg%u)) &
          g_i = g_i + this%ctx%mpcCoeffs(k, i) * arg%u(dof_k)
      END DO
      IF (ALLOCATED(this%state%g_mpc) .AND. SIZE(this%state%g_mpc) >= this%ctx%nActiveMPC) &
        this%state%g_mpc(i) = g_i
      arg%maxViolation = MAX(arg%maxViolation, ABS(g_i))
    END DO
    this%state%maxViolation = arg%maxViolation
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE Update_Lambda

END MODULE PH_Constr_Domain

