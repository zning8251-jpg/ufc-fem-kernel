!===============================================================================
! TEST: TEST_PH_UEL_Def_Bridge
! LAYER: L4_PH
! DOMAIN: Element
! BRIEF: Verify PH_UEL_Context (G6 U1) and PH_UEL_Bridge (G6 U2) operations.
!===============================================================================
PROGRAM TEST_PH_UEL_Def_Bridge
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_UEL_Def,   ONLY: PH_UEL_Context
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  USE PH_UEL_Brg, ONLY: PH_UEL_Populate_From_L3
  IMPLICIT NONE

  INTEGER(i4) :: n_pass, n_fail
  n_pass = 0
  n_fail = 0

  CALL test_uel_context_init(n_pass, n_fail)
  CALL test_uel_context_cleanup(n_pass, n_fail)
  CALL test_uel_bridge_populate(n_pass, n_fail)

  WRITE(*,*) '=== TEST_PH_UEL_Def_Bridge Summary ==='
  WRITE(*,*) 'PASS:', n_pass, '  FAIL:', n_fail
  IF (n_fail > 0) STOP 1

CONTAINS

  SUBROUTINE test_uel_context_init(np, nf)
    INTEGER(i4), INTENT(INOUT) :: np, nf
    TYPE(PH_UEL_Context) :: ctx
    TYPE(ErrorStatusType) :: st

    WRITE(*,*) '--- test_uel_context_init ---'
    CALL ctx%Init(ndofel=24, nrhs=1, nsvars=10, nprops=5, nnode=8, njprop=2)

    ! Verify dimensions
    IF (ctx%ndofel == 24 .AND. ctx%nrhs == 1 .AND. ctx%nsvars == 10 .AND. &
        ctx%nprops == 5 .AND. ctx%nnode == 8 .AND. ctx%njprop == 2) THEN
      np = np + 1
      WRITE(*,*) '  PASS: scalar dimensions correct'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: scalar dimensions mismatch'
    END IF

    ! Verify array allocation
    IF (ALLOCATED(ctx%rhs) .AND. SIZE(ctx%rhs,1)==24 .AND. SIZE(ctx%rhs,2)==1 .AND. &
        ALLOCATED(ctx%amatrx) .AND. SIZE(ctx%amatrx,1)==24 .AND. SIZE(ctx%amatrx,2)==24 .AND. &
        ALLOCATED(ctx%energy) .AND. SIZE(ctx%energy)==8 .AND. &
        ALLOCATED(ctx%svars) .AND. SIZE(ctx%svars)==10 .AND. &
        ALLOCATED(ctx%props) .AND. SIZE(ctx%props)==5 .AND. &
        ALLOCATED(ctx%u) .AND. SIZE(ctx%u)==24 .AND. &
        ALLOCATED(ctx%coords) .AND. SIZE(ctx%coords,1)==3 .AND. SIZE(ctx%coords,2)==8) THEN
      np = np + 1
      WRITE(*,*) '  PASS: array allocations correct'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: array allocation mismatch'
    END IF

    CALL ctx%Cleanup()
  END SUBROUTINE test_uel_context_init

  SUBROUTINE test_uel_context_cleanup(np, nf)
    INTEGER(i4), INTENT(INOUT) :: np, nf
    TYPE(PH_UEL_Context) :: ctx

    WRITE(*,*) '--- test_uel_context_cleanup ---'
    CALL ctx%Init(ndofel=6, nrhs=1, nsvars=2, nprops=3, nnode=2)
    CALL ctx%Cleanup()

    IF (.NOT. ALLOCATED(ctx%rhs) .AND. .NOT. ALLOCATED(ctx%amatrx) .AND. &
        .NOT. ALLOCATED(ctx%svars) .AND. .NOT. ALLOCATED(ctx%props) .AND. &
        .NOT. ALLOCATED(ctx%u) .AND. .NOT. ALLOCATED(ctx%coords)) THEN
      np = np + 1
      WRITE(*,*) '  PASS: all arrays deallocated'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: some arrays still allocated'
    END IF
  END SUBROUTINE test_uel_context_cleanup

  SUBROUTINE test_uel_bridge_populate(np, nf)
    INTEGER(i4), INTENT(INOUT) :: np, nf
    TYPE(PH_UEL_Context) :: uel_ctx
    TYPE(MD_Elem_UEL_Desc) :: uel_desc
    TYPE(ErrorStatusType) :: st

    WRITE(*,*) '--- test_uel_bridge_populate ---'

    ! Setup L3 Desc
    uel_desc%ndofel = 12
    uel_desc%nsvars = 4
    uel_desc%nprops = 3
    uel_desc%nnode = 4
    uel_desc%njprop = 0
    uel_desc%jtype = 1
    ALLOCATE(uel_desc%props(3))
    uel_desc%props = [1.0_wp, 2.0_wp, 3.0_wp]

    ! Populate via bridge
    CALL PH_UEL_Populate_From_L3(uel_ctx, uel_desc, st)

    IF (st%status_code == IF_STATUS_OK) THEN
      np = np + 1
      WRITE(*,*) '  PASS: Populate status OK'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: Populate status error'
    END IF

    ! Verify dimensions propagated
    IF (uel_ctx%ndofel == 12 .AND. uel_ctx%nsvars == 4 .AND. uel_ctx%nprops == 3) THEN
      np = np + 1
      WRITE(*,*) '  PASS: dimensions propagated'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: dimensions mismatch'
    END IF

    ! Verify props copied
    IF (ALLOCATED(uel_ctx%props) .AND. SIZE(uel_ctx%props)==3 .AND. &
        ABS(uel_ctx%props(1) - 1.0_wp) < 1.0e-12_wp .AND. &
        ABS(uel_ctx%props(2) - 2.0_wp) < 1.0e-12_wp .AND. &
        ABS(uel_ctx%props(3) - 3.0_wp) < 1.0e-12_wp) THEN
      np = np + 1
      WRITE(*,*) '  PASS: props copied correctly'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: props copy mismatch'
    END IF

    ! Verify jtype
    IF (uel_ctx%jtype == 1) THEN
      np = np + 1
      WRITE(*,*) '  PASS: jtype propagated'
    ELSE
      nf = nf + 1
      WRITE(*,*) '  FAIL: jtype mismatch'
    END IF

    CALL uel_ctx%Cleanup()
    IF (ALLOCATED(uel_desc%props)) DEALLOCATE(uel_desc%props)
  END SUBROUTINE test_uel_bridge_populate

END PROGRAM TEST_PH_UEL_Def_Bridge
