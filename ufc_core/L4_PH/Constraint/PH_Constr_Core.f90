!===============================================================================
! MODULE: PH_Constr_Core
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Core � constraint enforcement computation kernels
! BRIEF:  MPC transformation, Lagrange multiplier, penalty enforcement,
!         constraint equation assembly using Desc/Algo/Ctx signatures.
!===============================================================================
MODULE PH_Constr_Core
  USE IF_Prec_Core,            ONLY: wp, i4
  USE IF_Err_Brg,         ONLY: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Constr_Def,  ONLY: PH_Constraint_Desc, PH_Constraint_State, &
                                PH_Constraint_Algo, PH_Constraint_Ctx,  &
                                PH_CONSTR_PENALTY, PH_CONSTR_LAGRANGE,      &
                                PH_CONSTR_ELIMINATION
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Constraint_Core_Init
  PUBLIC :: PH_Constraint_Core_Finalize
  PUBLIC :: PH_Constraint_Build_MPC_Transform
  PUBLIC :: PH_Constraint_Apply_Penalty
  PUBLIC :: PH_Constraint_Build_Lagrange
  PUBLIC :: PH_Constraint_Compute_Reaction
  PUBLIC :: PH_Constraint_Check_Violation
  PUBLIC :: PH_Constraint_Apply
  PUBLIC :: PH_Constraint_Release
  ! Tie/MPC Brg: shared integer core-return-code -> ErrorStatusType (pilot dedupe)
  PUBLIC :: PH_Constr_IntCodeToStatus

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Constr_IntCodeToStatus
  ! PURPOSE:    Map Tie/MPC core integer status (0=OK) to IF_Err_Brg bundle.
  ! NOTE:       Prefer this over duplicate *_IntCodeToStatus in *_Brg modules.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constr_IntCodeToStatus(icode, err, tag)
    INTEGER(i4), INTENT(IN) :: icode
    TYPE(ErrorStatusType), INTENT(OUT) :: err
    CHARACTER(LEN=*), INTENT(IN) :: tag

    CALL init_error_status(err)
    IF (icode == 0_i4) THEN
      err%status_code = IF_STATUS_OK
    ELSE
      err%status_code = IF_STATUS_INVALID
      WRITE (err%message, '(A,A,I0)') TRIM(tag), ': core returned code ', icode
    END IF
  END SUBROUTINE PH_Constr_IntCodeToStatus

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Core_Init(desc, state, algo, ctx, status)
    TYPE(PH_Constraint_Desc),  INTENT(IN)  :: desc
    TYPE(PH_Constraint_State), INTENT(OUT) :: state
    TYPE(PH_Constraint_Algo),  INTENT(IN)  :: algo
    TYPE(PH_Constraint_Ctx),   INTENT(OUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)

    state%assembled    = .FALSE.
    state%n_active     = 0
    state%current_step = 0

    ctx%T_row       = 0.0_wp
    ctx%rhs_contrib = 0.0_wp
    ctx%K_aug_row   = 0.0_wp
    ctx%F_aug       = 0.0_wp
    ctx%violation   = 0.0_wp
    ctx%is_violated = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Core_Init

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Core_Finalize(state, ctx, status)
    TYPE(PH_Constraint_State), INTENT(INOUT) :: state
    TYPE(PH_Constraint_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    state%assembled = .FALSE.

    ctx%T_row       = 0.0_wp
    ctx%rhs_contrib = 0.0_wp
    ctx%K_aug_row   = 0.0_wp
    ctx%F_aug       = 0.0_wp
    ctx%violation   = 0.0_wp
    ctx%is_violated = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Core_Finalize

  !---------------------------------------------------------------------------
  ! Build MPC transformation: u_dep = T * u_indep
  ! T_row(i) = -coeffs(i)/coeffs(dep_idx)  for i /= dep_idx
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Build_MPC_Transform(desc, ctx, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    TYPE(PH_Constraint_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i
    REAL(wp)    :: c_dep

    CALL init_error_status(status)
    ctx%T_row = 0.0_wp

    c_dep = desc%coeffs(desc%dep_idx)
    IF (ABS(c_dep) < 1.0E-30_wp) THEN
      ctx%rhs_contrib    = 0.0_wp
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO i = 1, desc%n_terms
      IF (i == desc%dep_idx) THEN
        ctx%T_row(i) = 0.0_wp
      ELSE
        ctx%T_row(i) = -desc%coeffs(i) / c_dep
      END IF
    END DO
    ctx%rhs_contrib    = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Build_MPC_Transform

  !---------------------------------------------------------------------------
  ! Apply penalty enforcement: modify K and F
  ! K += alpha * c * c^T,   F += alpha * c * rhs
  ! K_local and F_local are external arrays being modified.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Apply_Penalty(desc, algo, K_local, F_local, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    TYPE(PH_Constraint_Algo), INTENT(IN)    :: algo
    REAL(wp),                 INTENT(INOUT) :: K_local(:,:)
    REAL(wp),                 INTENT(INOUT) :: F_local(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, di, dj

    CALL init_error_status(status)
    DO i = 1, desc%n_terms
      di = desc%dof_ids(i)
      F_local(di) = F_local(di) + algo%alpha * desc%coeffs(i) * desc%rhs
      DO j = 1, desc%n_terms
        dj = desc%dof_ids(j)
        K_local(di, dj) = K_local(di, dj) + &
                           algo%alpha * desc%coeffs(i) * desc%coeffs(j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Apply_Penalty

  !---------------------------------------------------------------------------
  ! Build Lagrange multiplier augmentation row
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Build_Lagrange(desc, ctx, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    TYPE(PH_Constraint_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    ctx%K_aug_row = 0.0_wp
    DO i = 1, desc%n_terms
      ctx%K_aug_row(desc%dof_ids(i)) = desc%coeffs(i)
    END DO
    ctx%F_aug = desc%rhs
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Build_Lagrange

  !---------------------------------------------------------------------------
  ! Compute reaction force at constrained DOF
  ! reaction = sum(coeffs(i) * forces(i))
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Compute_Reaction(desc, forces, reaction, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)  :: desc
    REAL(wp),                 INTENT(IN)  :: forces(:)
    REAL(wp),                 INTENT(OUT) :: reaction
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    reaction = 0.0_wp
    DO i = 1, desc%n_terms
      reaction = reaction + desc%coeffs(i) * forces(i)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Compute_Reaction

  !---------------------------------------------------------------------------
  ! Check constraint violation: violation = sum(c_i * u_i) - rhs
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Check_Violation(desc, u_vals, ctx, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    REAL(wp),                 INTENT(IN)    :: u_vals(:)
    TYPE(PH_Constraint_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    ctx%violation = -desc%rhs
    DO i = 1, desc%n_terms
      ctx%violation = ctx%violation + desc%coeffs(i) * u_vals(i)
    END DO
    ctx%is_violated = (ABS(ctx%violation) > 1.0E-10_wp)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Check_Violation

  !---------------------------------------------------------------------------
  ! Apply constraint to system: dispatches to Penalty/Lagrange/Direct
  ! depending on algo%method. Modifies K and F in-place.
  ! Theory:
  !   PENALTY:  K += alpha * c * c^T,  F += alpha * c * rhs
  !   LAGRANGE: Build augmentation row in ctx (caller assembles K_aug)
  !   DIRECT:   u_dep = T * u_indep (transformation elimination)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Apply(desc, algo, ctx, K_local, F_local, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    TYPE(PH_Constraint_Algo), INTENT(IN)    :: algo
    TYPE(PH_Constraint_Ctx),  INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(INOUT) :: K_local(:,:)
    REAL(wp),                 INTENT(INOUT) :: F_local(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i, dep, indep_dof
    REAL(wp) :: c_dep

    CALL init_error_status(status)

    IF (desc%n_terms < 1) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    SELECT CASE (algo%method)
    CASE (PH_CONSTR_PENALTY)
      ! Penalty method: K += alpha * c * c^T, F += alpha * c * rhs
      CALL PH_Constraint_Apply_Penalty(desc, algo, K_local, F_local, status)

    CASE (PH_CONSTR_LAGRANGE)
      ! Lagrange: build augmentation row in ctx for assembly
      CALL PH_Constraint_Build_Lagrange(desc, ctx, status)

    CASE (PH_CONSTR_ELIMINATION)
      ! Direct elimination / transformation method
      ! Replace dependent DOF row/col using MPC transform
      CALL PH_Constraint_Build_MPC_Transform(desc, ctx, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN

      dep = desc%dof_ids(desc%dep_idx)
      c_dep = desc%coeffs(desc%dep_idx)

      IF (dep < 1 .OR. dep > SIZE(K_local, 1)) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF

      ! Zero out dependent DOF row and column
      K_local(dep, :) = 0.0_wp
      K_local(:, dep) = 0.0_wp
      K_local(dep, dep) = 1.0_wp

      ! Set dependent DOF force to reflect transformation
      F_local(dep) = desc%rhs / c_dep

      ! Transfer off-diagonal stiffness contributions
      DO i = 1, desc%n_terms
        IF (i == desc%dep_idx) CYCLE
        indep_dof = desc%dof_ids(i)
        IF (indep_dof < 1 .OR. indep_dof > SIZE(K_local, 1)) CYCLE
        ! F_indep -= T_i * F_dep_old (simplified)
        F_local(dep) = F_local(dep) - ctx%T_row(i) * F_local(indep_dof)
      END DO

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      RETURN
    END SELECT

  END SUBROUTINE PH_Constraint_Apply

  !---------------------------------------------------------------------------
  ! Release constraint: restore system to unconstrained state
  ! Removes penalty contribution or marks constraint as inactive.
  ! Theory:
  !   PENALTY:  K -= alpha * c * c^T,  F -= alpha * c * rhs
  !   LAGRANGE: Zero out augmentation row in ctx
  !   DIRECT:   Restore dependent DOF row/col to original
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Constraint_Release(desc, algo, ctx, K_local, F_local, status)
    TYPE(PH_Constraint_Desc), INTENT(IN)    :: desc
    TYPE(PH_Constraint_Algo), INTENT(IN)    :: algo
    TYPE(PH_Constraint_Ctx),  INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(INOUT) :: K_local(:,:)
    REAL(wp),                 INTENT(INOUT) :: F_local(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, di, dj

    CALL init_error_status(status)

    IF (desc%n_terms < 1) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    SELECT CASE (algo%method)
    CASE (PH_CONSTR_PENALTY)
      ! Remove penalty contribution: K -= alpha * c * c^T, F -= alpha * c * rhs
      DO i = 1, desc%n_terms
        di = desc%dof_ids(i)
        IF (di < 1 .OR. di > SIZE(F_local)) CYCLE
        F_local(di) = F_local(di) - algo%alpha * desc%coeffs(i) * desc%rhs
        DO j = 1, desc%n_terms
          dj = desc%dof_ids(j)
          IF (dj < 1 .OR. dj > SIZE(K_local, 1)) CYCLE
          K_local(di, dj) = K_local(di, dj) - &
                             algo%alpha * desc%coeffs(i) * desc%coeffs(j)
        END DO
      END DO

    CASE (PH_CONSTR_LAGRANGE)
      ! Zero out augmentation row (constraint no longer active)
      ctx%K_aug_row = 0.0_wp
      ctx%F_aug = 0.0_wp

    CASE (PH_CONSTR_ELIMINATION)
      ! Mark constraint as released (caller must re-assemble without constraint)
      ctx%T_row = 0.0_wp
      ctx%rhs_contrib = 0.0_wp

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      RETURN
    END SELECT

    ctx%violation = 0.0_wp
    ctx%is_violated = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Constraint_Release

END MODULE PH_Constr_Core
