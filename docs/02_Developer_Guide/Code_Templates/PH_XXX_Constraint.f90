!===============================================================================
! Template: PH_XXX_Constraint.f90                               [Template v1.1]
! Layer:  L4_PH - Physics Layer
! Domain: Constraint / [Family] (e.g., MPC / UMPC / VMPC / UMESHMOTION)
!
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.1 (2026-03)  Single PH_XXX_Constr_Args (replaces _In/_Out); _Impl(args).
!
! HOW TO USE:
!   1. Copy to L4_PH/Constraint/[Family]/
!   2. Rename: PH_Constr_[Family]_[Type].f90
!              (e.g., PH_Constr_MPC_Linear.f90, PH_Constr_UMESHMOTION_ALE.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]   (e.g., MPC_Linear)
!   4. Replace XXX     -> [Type abbrev]     (e.g., Lin)
!   5. Wire up USE statements to the matching MD_Constr_XXX module
!   6. Implement PH_XXX_Constr_Impl — constraint physics (coefficient computation)
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Constr_Apply   (L5_RT Proc)
!             → PH_XXX_Constr_API     (THIS FILE — thin wrapper)
!             → PH_XXX_Constr_Impl    (THIS FILE — hot path physics)
!
! ABAQUS subroutine coverage:
!   UMPC         : User multi-point constraint (Implicit Standard)
!                  Returns: A(NDOFC), AN, RHS_VAL (constraint coefficients)
!   VMPC         : Vectorised MPC (Explicit); nblock-based
!   UMESHMOTION  : ALE adaptive mesh constraint velocity at surface nodes
!
! Principle #14 SIO compliance:
!   PH_XXX_Constr_API  : 6-parameter form (desc, ctx, state, md_algo, ph_algo, rt_ctx)
!   PH_XXX_Constr_Impl : 6th param PH_XXX_Constr_Args (INOUT unified bundle)
!   Unlike UMAT/UEL, Constraint does NOT return pnewdt.
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  PH_XXX_Constr_API: 6 params (desc, ctx, state, md_algo, ph_algo, rt_ctx)
!   SIO-02 ✓  PH_XXX_Constr_Impl: last param is PH_XXX_Constr_Args (INOUT)
!   SIO-03 ✓  PH_XXX_Constr_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!===============================================================================
MODULE PH_XXX_Constraint
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                 IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Constraint descriptor
  USE MD_Constr_XXX_XXX,   ONLY: MD_XXX_Constr_Desc
  USE MD_Constraint_Types, ONLY: MD_Constr_Base_Desc, &
                                 MD_Constr_Base_State, &
                                 MD_Constr_Base_Algo
  !-- [PH] Constraint base types
  USE PH_Constraint_Types, ONLY: PH_Constr_Base_Ctx, &
                                 PH_Constr_Base_State, &
                                 PH_Constr_Base_Algo, &
                                 PH_Constr_UMPC_Ctx, &
                                 PH_Constr_UMPC_State, &
                                 PH_Constr_UMPC_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types,        ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_Constr_State   ! PH-owned per-constraint state (exported for tests)
  PUBLIC :: PH_XXX_Constr_Args    ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_Constr_API     ! UFC-native Constraint entry (thin wrapper -> _Impl)
  ! NOTE: PH_XXX_Constr_Impl is PRIVATE — physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned constraint state variables.
  !   Stores constraint coefficients (A, AN, RHS_VAL) computed per call.
  !   These are written back to the solver's global constraint matrix.
  !
  !   PH_Constr_UMPC_State (base) provides:
  !     f_res(:)   — constraint residuals [nterms]
  !     a_jac(:,:) — Jacobian d(F)/d(u) [nterms, ndofel]
  !     u_eq(:)    — prescribed u at controlled DOF
  !     converged  — convergence flag
!     status     — structured ErrorStatusType status
  !
  !   Add constraint-family-specific state fields below.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(PH_Constr_UMPC_State) :: PH_XXX_Constr_State
    !-- Constraint equation coefficients (UMPC ABAQUS output: A, AN, RHS)
    REAL(wp) :: coeff_an    = 0.0_wp    ! AN: coefficient for constrained DOF
    REAL(wp) :: rhs_val     = 0.0_wp    ! RHS: constant term of constraint eq.
    REAL(wp) :: lmult       = 0.0_wp    ! Lagrange multiplier (if Lagrange method)
    !-- TODO: add constraint-family-specific state fields here
    !   e.g., for penalty: REAL(wp) :: violation = 0.0_wp (current violation)
    !         for augmented Lagrange: REAL(wp) :: aug_lmult = 0.0_wp
  END TYPE PH_XXX_Constr_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_Constr_Args — unified bundle (Principle #14, L4 adaptation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_Constr_Args
    !-- [IN]
    INTEGER(i4) :: jdof          = 0_i4
    INTEGER(i4) :: jtype         = 0_i4
    LOGICAL     :: is_linear     = .TRUE.
    LOGICAL     :: first_call    = .FALSE.
    !-- TODO: constraint-family [IN] fields
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success       = .FALSE.
    REAL(wp)              :: coeff_an      = 0.0_wp
    REAL(wp)              :: rhs_val       = 0.0_wp
    !-- TODO: constraint-family [OUT] diagnostics
  END TYPE PH_XXX_Constr_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH)
  !============================================================================
  !> PH_XXX_Constr_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_Constr_Args, delegates to PH_XXX_Constr_Impl.
  !>   DO NOT add constraint physics here; implement in PH_XXX_Constr_Impl.
  !>
  !> Parameters (6-parameter form, SIO-01):
  !>   MD_Constr_Desc  [MD] constraint parameters (read-only)
  !>   PH_Constr_Ctx   [PH] per-increment driving inputs (node IDs, u_current, etc.)
  !>   PH_Constr_State [PH] constraint state (coeff_a, rhs, lmult) — INOUT
  !>   MD_Constr_Algo  [MD] enforcement method config (Lagrange / penalty)
  !>   PH_Constr_Algo  [PH] per-increment iteration control
  !>   RT_Com_Ctx      [RT] runtime bookkeeping (kstep, kinc, time)
  !>
  !> Calling convention (L5_RT solver, UFC native UMPC path):
  !>   TYPE(MD_XXX_Constr_Desc) :: MD_Constr_Desc  ! pre-built at model load
  !>   TYPE(PH_Constr_UMPC_Ctx) :: PH_Constr_Ctx   ! filled by L5_RT per call
  !>   TYPE(PH_XXX_Constr_State):: PH_Constr_State ! per-constraint state
  !>   TYPE(MD_Constr_Base_Algo):: MD_Constr_Algo  ! enforcement method
  !>   TYPE(PH_Constr_UMPC_Algo):: PH_Constr_Algo  ! iteration params
  !>   TYPE(RT_Com_Base_Ctx)    :: RT_Com_Ctx       ! step/inc bookkeeping
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_Constr_API(MD_Constr_Desc, PH_Constr_Ctx, PH_Constr_State, &
                                MD_Constr_Algo, PH_Constr_Algo, RT_Com_Ctx)
    TYPE(MD_XXX_Constr_Desc),   INTENT(IN)    :: MD_Constr_Desc  ! [MD] parameters
    TYPE(PH_Constr_UMPC_Ctx),   INTENT(IN)    :: PH_Constr_Ctx   ! [PH] driving inputs
    TYPE(PH_XXX_Constr_State),  INTENT(INOUT) :: PH_Constr_State ! [PH] state (in/out)
    TYPE(MD_Constr_Base_Algo),  INTENT(IN)    :: MD_Constr_Algo  ! [MD] enforcement config
    TYPE(PH_Constr_UMPC_Algo),  INTENT(IN)    :: PH_Constr_Algo  ! [PH] iteration ctrl
    TYPE(RT_Com_Base_Ctx),      INTENT(IN)    :: RT_Com_Ctx      ! [RT] runtime context

    TYPE(PH_XXX_Constr_Args) :: constr_args

    constr_args%jdof       = PH_Constr_Ctx%jdof
    constr_args%jtype      = PH_Constr_Ctx%jtype
    constr_args%is_linear  = PH_Constr_Ctx%lmpc
    constr_args%first_call = (RT_Com_Ctx%kinc == 1_i4)
    !-- TODO: fill additional constr_args [IN] fields

    constr_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_Constr_Impl(MD_Constr_Desc, PH_Constr_Ctx, PH_Constr_State, &
                             MD_Constr_Algo, PH_Constr_Algo, constr_args)

    PH_Constr_State%coeff_an = constr_args%coeff_an
    PH_Constr_State%rhs_val  = constr_args%rhs_val
  END SUBROUTINE PH_XXX_Constr_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all constraint physics here
  !============================================================================
  !> PH_XXX_Constr_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_Constr_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%jdof        — constrained DOF index to compute coefficient for
  !>    args%is_linear   — .TRUE. → linear MPC; .FALSE. → nonlinear
  !>    args%success     — .TRUE. IFF coefficients computed successfully
  !>    args%coeff_an    — coefficient for the constrained DOF (AN in UMPC)
  !>    args%rhs_val     — RHS constant term
  !>    PH_Constr_State  — coeff_a(:), rhs_val, lmult updated in-place
  SUBROUTINE PH_XXX_Constr_Impl(MD_Constr_Desc, PH_Constr_Ctx, PH_Constr_State, &
                                 MD_Constr_Algo, PH_Constr_Algo, args)
    TYPE(MD_XXX_Constr_Desc),  INTENT(IN)    :: MD_Constr_Desc
    TYPE(PH_Constr_UMPC_Ctx),  INTENT(IN)    :: PH_Constr_Ctx
    TYPE(PH_XXX_Constr_State), INTENT(INOUT) :: PH_Constr_State
    TYPE(MD_Constr_Base_Algo), INTENT(IN)    :: MD_Constr_Algo
    TYPE(PH_Constr_UMPC_Algo), INTENT(IN)    :: PH_Constr_Algo
    TYPE(PH_XXX_Constr_Args),  INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    REAL(wp)    :: violation          ! Constraint violation: g = A*u - b [unit]
    REAL(wp)    :: coeff_an_computed  ! Computed AN coefficient
    REAL(wp)    :: rhs_computed       ! Computed RHS value
    INTEGER(i4) :: i                  ! Loop index
    LOGICAL     :: enforce_ok         ! Enforcement convergence flag

    !-- Initialize output
    CALL init_error_status(args%status)
    args%success    = .FALSE.
    args%coeff_an   = 0.0_wp
    args%rhs_val    = 0.0_wp

    !=========================================================================
    ! Step 1: Validate constraint type and DOF
    !=========================================================================
    IF (args%jdof < 1 .OR. args%jdof > PH_Constr_Ctx%mdof) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[PH_XXX_Constr_Impl]: jdof out of range')
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Compute constraint equation coefficients
    !   For linear MPC: A*u = b, compute A coefficients and RHS b.
    !   For UMPC: fill coeff_a(:) for independent DOFs, compute AN and RHS.
    !
    !   Linear MPC template (replace with actual constraint physics):
    !     If constraint is: u_c = sum_i(A_i * u_i) + b
    !     Then: coeff_an = 1.0 (constraining node coefficient)
    !           coeff_a(i) = -A_i (independent node coefficients)
    !           rhs_val = b
    !=========================================================================
    !-- STUB: default to identity constraint (u_c = u_ind(1) + const_b)
    coeff_an_computed = 1.0_wp        ! Coefficient for constrained DOF
    rhs_computed      = MD_Constr_Desc%const_b
    !-- TODO: replace with actual constraint coefficient computation
    !   Based on MD_Constr_Desc, PH_Constr_Ctx%u (independent DOF values),
    !   and PH_Constr_Ctx%x (node coordinates for geometric constraints).

    !=========================================================================
    ! Step 3: Compute violation and apply enforcement method
    !   Lagrange (method=1): pass A, AN, RHS directly to solver
    !   Penalty  (method=2): modify RHS via penalty * violation
    !   Augmented Lagrange (method=3): RHS += lmult + penalty * violation
    !=========================================================================
    SELECT CASE (MD_Constr_Algo%method)
      CASE (1)
        !-- Lagrange: pass coefficients as-is
        enforce_ok = .TRUE.
      CASE (2)
        !-- Penalty: compute violation g = u_c - (sum A_i*u_i + b)
        !            then rhs += penalty * g
        IF (ASSOCIATED(PH_Constr_Ctx%u)) THEN
          violation = PH_Constr_Ctx%u(args%jdof) - rhs_computed
        ELSE
          violation = 0.0_wp
        END IF
        rhs_computed = rhs_computed + MD_Constr_Desc%penalty_stiff * violation
        enforce_ok = .TRUE.
      CASE (3)
        !-- Augmented Lagrange: add Lagrange multiplier contribution
        IF (ASSOCIATED(PH_Constr_Ctx%u)) THEN
          violation = PH_Constr_Ctx%u(args%jdof) - rhs_computed
        ELSE
          violation = 0.0_wp
        END IF
        rhs_computed = rhs_computed + PH_Constr_State%lmult + &
                       MD_Constr_Desc%penalty_stiff * violation
        enforce_ok = .TRUE.
      CASE DEFAULT
        CALL init_error_status(args%status, IF_STATUS_ERROR, &
            message='[PH_XXX_Constr_Impl]: unknown enforcement method')
        RETURN
    END SELECT

    !=========================================================================
    ! Step 4: Write back computed coefficients to state
    !=========================================================================
    PH_Constr_State%converged = enforce_ok
    args%coeff_an              = coeff_an_computed
    args%rhs_val               = rhs_computed
    args%success               = enforce_ok
    args%status%status_code    = IF_STATUS_OK
  END SUBROUTINE PH_XXX_Constr_Impl

END MODULE PH_XXX_Constraint
!===============================================================================
! CALL CHAIN DIAGRAM — PH_XXX_Constraint
!
! L5_RT (RT_XXX_Constr_Apply)
!   │
!   ├─ Assembles: MD_XXX_Constr_Desc, PH_Constr_UMPC_Ctx, PH_XXX_Constr_State,
!   │             MD_Constr_Base_Algo, PH_Constr_UMPC_Algo, RT_Com_Base_Ctx
!   │
!   ├─ CALL PH_XXX_Constr_API(...)  [L4_PH thin wrapper — THIS FILE]
!   │      Fills PH_XXX_Constr_Args; CALL PH_XXX_Constr_Impl(..., constr_args)
!   │
!   │    PH_XXX_Constr_Impl  [L4_PH hot path — THIS FILE]
!   │      Step 1: Validate jdof & constraint type
!   │      Step 2: Compute A coefficients and RHS
!   │      Step 3: Apply enforcement method (Lagrange/penalty/augmented)
!   │      Step 4: Write coeff_an, rhs_val back to state
!   │
!   └─ L5_RT reads PH_Constr_State%coeff_an, %rhs_val
!      → writes to global constraint matrix (K_constr, F_constr)
!
! ABAQUS UMPC parameter map:
!   A(NDOFC)  ← PH_Constr_State%f_res(:)   (independent DOF coefficients)
!   AN        ← PH_Constr_State%coeff_an   (constrained DOF coefficient)
!   RHS       ← PH_Constr_State%rhs_val    (constant RHS term)
!   LMULT     ← PH_Constr_State%lmult      (Lagrange multiplier, if applicable)
!===============================================================================
