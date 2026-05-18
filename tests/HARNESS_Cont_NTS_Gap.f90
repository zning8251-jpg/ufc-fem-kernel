!===============================================================================
! Module: HARNESS_Cont_NTS_Gap
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Contact
! Purpose: Harness acceptance test — Node-to-Surface gap detection.
!          Uses PH_Cont_Core::PH_Contact_Compute_Gap to verify normal gap
!          calculation for known geometry.
!
! Theory:
!   gap = dot(x_slave - x_master, normal)
!   gap > 0  => open (separated)
!   gap < 0  => penetration
!   gap = 0  => exact contact
!
! Test Cases:
!   TC-1: Separated pair (gap = +0.5)
!   TC-2: Penetrating pair (gap = -0.2)
!   TC-3: Exact contact (gap = 0)
!   TC-4: Oblique normal direction
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Cont_NTS_Gap
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_Core, ONLY: PH_Contact_Compute_Gap, PH_Contact_Core_Init
  USE PH_Cont_Def,  ONLY: PH_Cont_Desc, PH_Cont_State, &
                           PH_Cont_Algo, PH_Cont_Ctx, PH_CONT_OPEN
  USE IF_Err_Brg,    ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Cont_NTS_Gap

  REAL(wp), PARAMETER :: TOL = 1.0e-12_wp

CONTAINS

  SUBROUTINE Run_Harness_Cont_NTS_Gap()
    TYPE(PH_Cont_Desc)  :: desc
    TYPE(PH_Cont_State) :: state
    TYPE(PH_Cont_Algo)  :: algo
    TYPE(PH_Cont_Ctx)   :: ctx
    TYPE(ErrorStatusType)  :: status
    REAL(wp) :: gap_expected, err
    INTEGER(i4) :: n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Cont_NTS_Gap: Node-to-Surface Gap Detection'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! Initialize
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)

    ! ---------------------------------------------------------------
    ! TC-1: Separated pair — gap = +0.5
    !   slave  at (0, 0, 1.5)
    !   master at (0, 0, 1.0)
    !   normal = (0, 0, 1)
    !   gap = (1.5-1.0)*1 = 0.5
    ! ---------------------------------------------------------------
    ctx%x_slave  = [0.0_wp, 0.0_wp, 1.5_wp]
    ctx%x_master = [0.0_wp, 0.0_wp, 1.0_wp]
    ctx%normal   = [0.0_wp, 0.0_wp, 1.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    gap_expected = 0.5_wp
    err = ABS(state%gap - gap_expected)

    WRITE(*,*) '  TC-1: Separated pair (gap = +0.5)'
    WRITE(*,*) '    Expected gap = ', gap_expected
    WRITE(*,*) '    Computed gap = ', state%gap
    WRITE(*,*) '    Status code  = ', status%status_code

    IF (err < TOL .AND. status%status_code == IF_STATUS_OK) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL (err = ', err, ')'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-2: Penetrating pair — gap = -0.2
    !   slave  at (0, 0, 0.8)
    !   master at (0, 0, 1.0)
    !   normal = (0, 0, 1)
    !   gap = (0.8-1.0)*1 = -0.2
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    ctx%x_slave  = [0.0_wp, 0.0_wp, 0.8_wp]
    ctx%x_master = [0.0_wp, 0.0_wp, 1.0_wp]
    ctx%normal   = [0.0_wp, 0.0_wp, 1.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    gap_expected = -0.2_wp
    err = ABS(state%gap - gap_expected)

    WRITE(*,*) '  TC-2: Penetrating pair (gap = -0.2)'
    WRITE(*,*) '    Expected gap = ', gap_expected
    WRITE(*,*) '    Computed gap = ', state%gap

    IF (err < TOL .AND. state%gap < 0.0_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Exact contact — gap = 0
    !   slave and master at same location
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    ctx%x_slave  = [1.0_wp, 2.0_wp, 3.0_wp]
    ctx%x_master = [1.0_wp, 2.0_wp, 3.0_wp]
    ctx%normal   = [0.0_wp, 0.0_wp, 1.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    gap_expected = 0.0_wp
    err = ABS(state%gap - gap_expected)

    WRITE(*,*) '  TC-3: Exact contact (gap = 0)'
    WRITE(*,*) '    Computed gap = ', state%gap

    IF (err < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Oblique normal direction
    !   slave  at (1, 0, 0)
    !   master at (0, 0, 0)
    !   normal = (1/sqrt(2), 1/sqrt(2), 0)
    !   gap = (1,0,0) dot (1/sqrt(2), 1/sqrt(2), 0) = 1/sqrt(2)
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    ctx%x_slave  = [1.0_wp, 0.0_wp, 0.0_wp]
    ctx%x_master = [0.0_wp, 0.0_wp, 0.0_wp]
    ctx%normal   = [1.0_wp/SQRT(2.0_wp), 1.0_wp/SQRT(2.0_wp), 0.0_wp]

    CALL PH_Contact_Compute_Gap(desc, state, ctx, status)
    gap_expected = 1.0_wp / SQRT(2.0_wp)
    err = ABS(state%gap - gap_expected)

    WRITE(*,*) '  TC-4: Oblique normal (gap = 1/sqrt(2))'
    WRITE(*,*) '    Expected gap = ', gap_expected
    WRITE(*,*) '    Computed gap = ', state%gap
    WRITE(*,*) '    Abs error    = ', err

    IF (err < 1.0e-10_wp) THEN
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
    WRITE(*,*) '  HARNESS_Cont_NTS_Gap: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Cont_NTS_Gap

END MODULE HARNESS_Cont_NTS_Gap

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Cont_NTS_Gap_Runner
  USE HARNESS_Cont_NTS_Gap, ONLY: Run_Harness_Cont_NTS_Gap
  IMPLICIT NONE
  CALL Run_Harness_Cont_NTS_Gap()
END PROGRAM HARNESS_Cont_NTS_Gap_Runner
