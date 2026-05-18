!===============================================================================
! Module: HARNESS_Cont_Penalty_Force
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Contact
! Purpose: Harness acceptance test — penalty method contact force.
!          Uses PH_Cont_Core to verify penalty force computation and
!          contact stiffness matrix for known penetration geometry.
!
! Theory:
!   Penalty contact force (normal):
!     f_n = -penalty * gap    (if gap < 0, i.e. penetration)
!     f_n = 0                 (if gap >= 0, i.e. open)
!   Contact stiffness contribution:
!     K_ij = penalty * n_i * n_j   (if gap < 0)
!
! Test Cases:
!   TC-1: Penetration force = penalty * |gap|
!   TC-2: No force when gap >= 0
!   TC-3: Contact stiffness matrix K = penalty * n (x) n
!   TC-4: Force direction aligned with normal
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Cont_Penalty_Force
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_Core, ONLY: PH_Contact_Core_Init, &
                           PH_Contact_Compute_Gap, &
                           PH_Contact_Compute_Normal_Force, &
                           PH_Contact_Compute_Stiffness
  USE PH_Cont_Def,  ONLY: PH_Cont_Desc, PH_Cont_State, &
                           PH_Cont_Algo, PH_Cont_Ctx
  USE IF_Err_Brg,    ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Cont_Penalty_Force

  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp

CONTAINS

  SUBROUTINE Run_Harness_Cont_Penalty_Force()
    TYPE(PH_Cont_Desc)  :: desc
    TYPE(PH_Cont_State) :: state
    TYPE(PH_Cont_Algo)  :: algo
    TYPE(PH_Cont_Ctx)   :: ctx
    TYPE(ErrorStatusType)  :: status
    REAL(wp) :: penalty, gap_val, force_expected
    REAL(wp) :: K_expected(3,3), K_err
    INTEGER(i4) :: i, j, n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Cont_Penalty_Force: Penalty Method Contact Force'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! TC-1: Penetration => force = penalty * |gap|
    !   penalty = 1e8, gap = -0.001 (1mm penetration)
    !   Expected force = 1e8 * 0.001 = 1e5 N
    ! ---------------------------------------------------------------
    penalty = 1.0e8_wp
    gap_val = -0.001_wp

    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%penalty_normal = penalty

    ! Set geometry for gap = -0.001 along z-normal
    ctx%x_slave  = [0.0_wp, 0.0_wp, 0.999_wp]
    ctx%x_master = [0.0_wp, 0.0_wp, 1.0_wp]
    ctx%normal   = [0.0_wp, 0.0_wp, 1.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    CALL PH_Contact_Compute_Normal_Force(desc, state, status)

    force_expected = penalty * ABS(gap_val)   ! = 1e5 N

    WRITE(*,*) '  TC-1: Penetration force'
    WRITE(*,*) '    penalty      = ', penalty
    WRITE(*,*) '    gap          = ', state%gap
    WRITE(*,*) '    Expected f_n = ', force_expected, ' N'
    WRITE(*,*) '    Computed f_n = ', state%f_normal, ' N'

    IF (ABS(state%f_normal - force_expected) / force_expected < 1.0e-10_wp .AND. &
        state%gap < 0.0_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-2: Open gap => no force
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%penalty_normal = penalty

    ctx%x_slave  = [0.0_wp, 0.0_wp, 1.5_wp]
    ctx%x_master = [0.0_wp, 0.0_wp, 1.0_wp]
    ctx%normal   = [0.0_wp, 0.0_wp, 1.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    CALL PH_Contact_Compute_Normal_Force(desc, state, status)

    WRITE(*,*) '  TC-2: Open gap — no force'
    WRITE(*,*) '    gap    = ', state%gap
    WRITE(*,*) '    f_n    = ', state%f_normal

    IF (ABS(state%f_normal) < TOL .AND. state%gap > 0.0_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Contact stiffness K_ij = penalty * n_i * n_j
    !   For normal = (0,0,1):
    !     K = penalty * [[0,0,0],[0,0,0],[0,0,1]]
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%penalty_normal = penalty
    ctx%normal = [0.0_wp, 0.0_wp, 1.0_wp]
    state%gap  = -0.001_wp   ! penetrating

    CALL PH_Contact_Compute_Stiffness(desc, state, ctx, status)

    ! Expected K(3x3 subblock)
    K_expected = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        K_expected(i,j) = penalty * ctx%normal(i) * ctx%normal(j)
      END DO
    END DO

    K_err = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        K_err = MAX(K_err, ABS(ctx%K_contact(i,j) - K_expected(i,j)))
      END DO
    END DO

    WRITE(*,*) '  TC-3: Contact stiffness K = penalty * n (x) n'
    WRITE(*,*) '    K(3,3) expected = ', K_expected(3,3)
    WRITE(*,*) '    K(3,3) computed = ', ctx%K_contact(3,3)
    WRITE(*,*) '    Max error = ', K_err

    IF (K_err < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Oblique normal — force direction
    !   normal = (0, 1/sqrt(2), 1/sqrt(2))
    !   Stiffness should have non-zero K(2,2), K(2,3), K(3,2), K(3,3)
    !   K(1,x) = 0
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%penalty_normal = penalty
    ctx%normal = [0.0_wp, 1.0_wp/SQRT(2.0_wp), 1.0_wp/SQRT(2.0_wp)]
    state%gap  = -0.002_wp

    CALL PH_Contact_Compute_Stiffness(desc, state, ctx, status)

    ! K(2,3) should = penalty * (1/sqrt(2)) * (1/sqrt(2)) = penalty/2
    WRITE(*,*) '  TC-4: Oblique normal stiffness'
    WRITE(*,*) '    K(2,3) expected = ', penalty * 0.5_wp
    WRITE(*,*) '    K(2,3) computed = ', ctx%K_contact(2,3)
    WRITE(*,*) '    K(1,1) expected = 0'
    WRITE(*,*) '    K(1,1) computed = ', ctx%K_contact(1,1)

    IF (ABS(ctx%K_contact(2,3) - penalty * 0.5_wp) < TOL .AND. &
        ABS(ctx%K_contact(1,1)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Summary
    ! ---------------------------------------------------------------
    WRITE(*,*) ''
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) '  HARNESS_Cont_Penalty_Force: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Cont_Penalty_Force

END MODULE HARNESS_Cont_Penalty_Force

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Cont_Penalty_Force_Runner
  USE HARNESS_Cont_Penalty_Force, ONLY: Run_Harness_Cont_Penalty_Force
  IMPLICIT NONE
  CALL Run_Harness_Cont_Penalty_Force()
END PROGRAM HARNESS_Cont_Penalty_Force_Runner
