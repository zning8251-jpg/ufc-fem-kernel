!===============================================================================
! MODULE: RT_Cont_AugLagSolv
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Solv — Augmented Lagrange (Uzawa outer iteration)
! BRIEF:  Uzawa scheduling: AugLag_Solve / UpdateLambda / CheckConv.
!===============================================================================
!             Check ||R|| < tol_nr
!         if ||delta_lambda||_inf < tol_aug: converged, EXIT
!         lambda_n <- lambda_trial  (AugLagCommit)
!
!   All physical contact force evaluations are delegated to L4_PH (PH_Cont_Algo).
!   This module is a pure scheduling layer per UFC L5_RT discipline.
!
! Interface Catalogue (UFC Principle #14 - six-parameter convention):
!   RT_Cont_AugLag_Solve    - Main entry: Uzawa outer iteration control
!   RT_Cont_AugLag_UpdateLambda - Uzawa lambda update: lambda_trial(i) = lambda_n(i) + rho*gap(i)
!   RT_Cont_AugLag_CheckConv    - Convergence check for Uzawa outer iteration
!
! Structured IO types:
!   RT_Cont_AugLag_In    - Input bundle (six-param inp)
!   RT_Cont_AugLag_Out   - Output bundle (six-param out)
!
! Theory:
!   Simo & Laursen (1992) "An augmented Lagrangian treatment..."
!   Wriggers, Computational Contact Mechanics §9.2
!   Laursen, Computational Contact and Impact Mechanics §5.4
!
! Status: CORE | Last verified: 2026-04-01
!===============================================================================
MODULE RT_Cont_AugLagSolv
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                             IF_STATUS_INVALID
  USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, &
                              RT_Contact_Ctx, RT_CONT_ENFORCE_AUG_LAGRANGE, &
                              RT_CONT_PAIR_OPEN, RT_CONT_PAIR_CLOSED
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Public API
  !============================================================================
  PUBLIC :: RT_Cont_AugLag_Solve
  PUBLIC :: RT_Cont_AugLag_UpdateLambda
  PUBLIC :: RT_Cont_AugLag_CheckConv

  ! Structured IO types (Principle #14)
  PUBLIC :: RT_Cont_AugLag_In
  PUBLIC :: RT_Cont_AugLag_Out

  !============================================================================
  ! Structured Input type
  ! NOTE: members MUST NOT have INTENT (UFC P#14 §3.2)
  !       Pointers are NON_OWNING: caller retains ownership.
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_AugLag_In
    !-- Geometry (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()   !< [3, n_nodes]  current coords
    REAL(wp), POINTER :: node_disp(:,:)   => NULL()   !< [3, n_nodes]  incremental disp
    !-- Gap function values from last search (NON_OWNING_PTR)
    REAL(wp), POINTER :: gap(:) => NULL()             !< [n_pairs]  gap < 0 => penetration
    !-- Global residual norm from last NR solve (scalar pass-back)
    REAL(wp) :: nr_residual_norm = 0.0_wp
    !-- Flags
    LOGICAL :: compute_tangent = .TRUE.
    LOGICAL :: is_first_uzawa  = .FALSE.  !< .TRUE. on first call per increment
  END TYPE RT_Cont_AugLag_In

  !============================================================================
  ! Structured Output type
  ! NOTE: must contain ErrorStatusType (UFC P#14 §4)
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_AugLag_Out
    TYPE(ErrorStatusType) :: status
    !-- Uzawa convergence result
    LOGICAL     :: uzawa_converged   = .FALSE.  !< .TRUE. if ||delta_lambda|| < tol_aug
    REAL(wp)    :: delta_lambda_norm = 0.0_wp   !< ||lambda_trial - lambda_n||_inf
    INTEGER(i4) :: uzawa_iters_done  = 0_i4     !< Number of Uzawa iters completed
    !-- Aggregate contact info
    INTEGER(i4) :: n_active_pairs    = 0_i4     !< Number of pairs in contact
    REAL(wp)    :: max_lambda        = 0.0_wp   !< Max Lagrange multiplier (diagnostics)
    CHARACTER(LEN=256) :: message    = ''
  END TYPE RT_Cont_AugLag_Out

CONTAINS

  !============================================================================
  ! RT_Cont_AugLag_Solve
  ! Main Uzawa outer-iteration scheduler.
  !
  ! Calling convention (UFC Principle #14 six-param):
  !   (desc, state, algo, ctx, inp, out)
  !
  ! Responsibilities (L5_RT scheduling only):
  !   1. Validate enforcement_method == RT_CONT_ENFORCE_AUG_LAGRANGE
  !   2. Initialise lambda buffers on first call (state%AugLagInit)
  !   3. Loop Uzawa iters:
  !        a. Call RT_Cont_AugLag_UpdateLambda  (compute lambda_trial)
  !        b. Caller must drive global NR from outside (L5_RT Step loop)
  !        c. Call RT_Cont_AugLag_CheckConv     (assess convergence)
  !        d. If converged: break; else commit and repeat
  !   NOTE: Global NR is driven by the enclosing L5_RT step scheduler.
  !         This subroutine is called once per Uzawa iteration.
  !============================================================================
  SUBROUTINE RT_Cont_AugLag_Solve(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_Contact_State),  INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),   INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),    INTENT(INOUT) :: ctx
    TYPE(RT_Cont_AugLag_In), INTENT(IN)    :: inp
    TYPE(RT_Cont_AugLag_Out),INTENT(OUT)   :: out

    INTEGER(i4) :: n_pairs
    REAL(wp)    :: delta_norm

    CALL init_error_status(out%status)
    out%uzawa_converged  = .FALSE.
    out%delta_lambda_norm = 0.0_wp
    out%uzawa_iters_done  = state%uzawa_iter
    out%n_active_pairs    = state%n_active_pairs
    out%message           = ''

    !-- Validate enforcement method
    IF (algo%enforcement_method /= RT_CONT_ENFORCE_AUG_LAGRANGE) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%message        = 'RT_Cont_AugLag_Solve: enforcement_method is not AUG_LAGRANGE'
      RETURN
    END IF

    n_pairs = desc%n_contact_pairs
    IF (n_pairs <= 0) THEN
      out%uzawa_converged = .TRUE.
      out%message = 'No contact pairs: trivially converged'
      RETURN
    END IF

    !-- Initialise lambda buffers on first Uzawa call per increment
    IF (inp%is_first_uzawa) THEN
      CALL state%AugLagInit(n_pairs, algo%lagrange_init)
      state%uzawa_iter      = 0_i4
      state%uzawa_converged = .FALSE.
    END IF

    !-- Guard: max Uzawa iterations exceeded
    IF (state%uzawa_iter >= algo%n_aug_max) THEN
      out%uzawa_converged   = .FALSE.
      out%uzawa_iters_done  = state%uzawa_iter
      out%message = 'RT_Cont_AugLag_Solve: max Uzawa iterations reached without convergence'
      RETURN
    END IF

    !-- Step (a): update trial lambda using current gap function
    CALL RT_Cont_AugLag_UpdateLambda(desc, state, algo, ctx, inp, out)
    IF (out%status%status_code /= IF_STATUS_OK) RETURN

    !-- Step (c): assess Uzawa convergence (commit + measure delta_lambda)
    CALL RT_Cont_AugLag_CheckConv(desc, state, algo, ctx, inp, out)

    !-- Update aggregate diagnostics
    out%uzawa_iters_done = state%uzawa_iter
    IF (ASSOCIATED(state%lambda_n)) THEN
      out%max_lambda = MAXVAL(ABS(state%lambda_n))
    END IF

    IF (out%uzawa_converged) THEN
      state%uzawa_converged = .TRUE.
      out%message = 'AugLag Uzawa converged'
    END IF

  END SUBROUTINE RT_Cont_AugLag_Solve

  !============================================================================
  ! RT_Cont_AugLag_UpdateLambda
  ! Uzawa update rule:
  !   lambda_trial(i) = max(0, lambda_n(i) + rho * (-gap(i)))
  !
  ! Only active (closed) pairs contribute positive lambda.
  ! Open pairs: lambda_trial(i) = 0  (Karush-Kuhn-Tucker complementarity).
  !
  ! Notation:  gap(i) < 0  ==> penetration  ==>  contact force present
  !            gap(i) >= 0 ==> open          ==>  lambda = 0
  !============================================================================
  SUBROUTINE RT_Cont_AugLag_UpdateLambda(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Contact_State),  INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),   INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),    INTENT(IN)    :: ctx
    TYPE(RT_Cont_AugLag_In), INTENT(IN)    :: inp
    TYPE(RT_Cont_AugLag_Out),INTENT(INOUT) :: out

    INTEGER(i4) :: i, n
    REAL(wp)    :: gn, lam_new

    CALL init_error_status(out%status)

    IF (.NOT. ASSOCIATED(state%lambda_n) .OR. .NOT. ASSOCIATED(state%lambda_trial)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%message = 'RT_Cont_AugLag_UpdateLambda: lambda buffers not initialised'
      RETURN
    END IF

    IF (.NOT. ASSOCIATED(inp%gap)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%message = 'RT_Cont_AugLag_UpdateLambda: inp%gap pointer is not associated'
      RETURN
    END IF

    n = SIZE(state%lambda_n)
    out%n_active_pairs = 0_i4

    DO i = 1, n
      !-- gap < 0 => penetration => enforce contact
      gn = inp%gap(i)
      lam_new = state%lambda_n(i) - algo%rho_aug * gn  ! rho * (-gap): gap sign convention
      !-- KKT complementarity: lambda >= 0 (normal contact, compressive only)
      state%lambda_trial(i) = MAX(0.0_wp, lam_new)
      !-- Count active pairs
      IF (state%lambda_trial(i) > 0.0_wp) THEN
        out%n_active_pairs = out%n_active_pairs + 1_i4
      END IF
    END DO

  END SUBROUTINE RT_Cont_AugLag_UpdateLambda

  !============================================================================
  ! RT_Cont_AugLag_CheckConv
  ! Commits the Uzawa update (lambda_n <- lambda_trial) and checks convergence:
  !   converged = (||lambda_trial - lambda_n||_inf < algo%tol_aug)
  !
  ! Note: The commit uses state%AugLagCommit which copies trial -> committed
  !       and increments uzawa_iter.
  ! If the caller decides the global NR diverged, it should call
  !   state%AugLagRollback instead and set out%status accordingly.
  !============================================================================
  SUBROUTINE RT_Cont_AugLag_CheckConv(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Contact_State),  INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),   INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),    INTENT(IN)    :: ctx
    TYPE(RT_Cont_AugLag_In), INTENT(IN)    :: inp
    TYPE(RT_Cont_AugLag_Out),INTENT(INOUT) :: out

    REAL(wp) :: delta_norm

    CALL init_error_status(out%status)

    !-- Commit: compute delta_norm and advance lambda_n <- lambda_trial
    CALL state%AugLagCommit(delta_norm)

    out%delta_lambda_norm = delta_norm
    out%uzawa_converged   = (delta_norm < algo%tol_aug)

  END SUBROUTINE RT_Cont_AugLag_CheckConv

END MODULE RT_Cont_AugLagSolv