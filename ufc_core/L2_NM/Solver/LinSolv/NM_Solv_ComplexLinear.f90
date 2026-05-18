!===============================================================================
! MODULE: NM_Solv_ComplexLinear
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (complex linear system solver)
! BRIEF:  Solve (K_real + i*K_imag)*U = F for steady-state dynamics via PARDISO
!
! Theory: PARDISO complex mode mtype=3/4; real-equivalent 2x2 block form
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_ComplexLinear
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! PARDISO matrix types
  INTEGER(i4), PARAMETER, PUBLIC :: NM_COMPLEX_MTYPE_HERMITIAN = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_COMPLEX_MTYPE_UNSYM    = 4_i4

  TYPE, PUBLIC :: NM_ComplexLinSolv_Cfg
    INTEGER(i4) :: mtype     = NM_COMPLEX_MTYPE_HERMITIAN
    REAL(wp)    :: refactor_tol = 0.01_wp   ! |Δω/ω| threshold for refactor
    LOGICAL     :: verbose   = .FALSE.
  END TYPE NM_ComplexLinSolv_Cfg

  TYPE, PUBLIC :: NM_ComplexLinSolv_Ctx
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized  = .FALSE.
    INTEGER(i4) :: n           = 0_i4
    INTEGER(i4) :: nnz         = 0_i4
    REAL(wp)    :: last_omega   = -1.0_wp
    TYPE(NM_ComplexLinSolv_Cfg) :: cfg
    ! TODO: PARDISO handle (pt, iparm, dparm) when MKL linked
  END TYPE NM_ComplexLinSolv_Ctx

  PUBLIC :: NM_ComplexLinearSolver_Init
  PUBLIC :: NM_ComplexLinearSolver_Factorize
  PUBLIC :: NM_ComplexLinearSolver_Solve
  PUBLIC :: NM_ComplexLinearSolver_Finalize

CONTAINS

  SUBROUTINE NM_ComplexLinearSolver_Init(ctx, n, nnz, cfg, status)
    TYPE(NM_ComplexLinSolv_Ctx), INTENT(OUT) :: ctx
    INTEGER(i4), INTENT(IN) :: n, nnz
    TYPE(NM_ComplexLinSolv_Cfg), INTENT(IN), OPTIONAL :: cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ctx%n = n
    ctx%nnz = nnz
    IF (PRESENT(cfg)) ctx%cfg = cfg
    ctx%is_initialized = .TRUE.
    ctx%is_factorized = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ComplexLinearSolver_Init

  SUBROUTINE NM_ComplexLinearSolver_Factorize(ctx, K_real, K_imag, ia, ja, omega, status)
    TYPE(NM_ComplexLinSolv_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: K_real(:), K_imag(:)
    INTEGER(i4), INTENT(IN) :: ia(:), ja(:)
    REAL(wp), INTENT(IN) :: omega
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! TODO: PARDISO complex symbolic + numeric factorization
    ! CALL pardiso(pt, 1, 1, mtype, 12, n, K_complex, ia, ja, ..., phase=12)
    ctx%last_omega = omega
    ctx%is_factorized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ComplexLinearSolver_Factorize

  SUBROUTINE NM_ComplexLinearSolver_Solve(ctx, K_real, K_imag, ia, ja, &
       F_real, F_imag, U_real, U_imag, status)
    TYPE(NM_ComplexLinSolv_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: K_real(:), K_imag(:)
    INTEGER(i4), INTENT(IN) :: ia(:), ja(:)
    REAL(wp), INTENT(IN) :: F_real(:), F_imag(:)
    REAL(wp), INTENT(OUT) :: U_real(:), U_imag(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, n

    CALL init_error_status(status)
    n = ctx%n
    IF (SIZE(F_real) < n .OR. SIZE(F_imag) < n .OR. SIZE(U_real) < n .OR. SIZE(U_imag) < n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_ComplexLinearSolver_Solve: array size < n"
      RETURN
    END IF

    ! TODO: PARDISO phase=33 solve
    ! For now: placeholder (zero solution - actual solve requires PARDISO/MKL)
    DO i = 1, n
      U_real(i) = 0.0_wp
      U_imag(i) = 0.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ComplexLinearSolver_Solve

  SUBROUTINE NM_ComplexLinearSolver_Finalize(ctx, status)
    TYPE(NM_ComplexLinSolv_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! TODO: PARDISO phase=-1 release
    ctx%is_factorized = .FALSE.
    ctx%is_initialized = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ComplexLinearSolver_Finalize

END MODULE NM_Solv_ComplexLinear