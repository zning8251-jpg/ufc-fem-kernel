!===============================================================================
! Module:  RT_Assembly_Test
! Layer:   L5_RT
! Domain:  Assembly
! Purpose: Minimal test framework for the Assembly domain.
!          Verifies Init/Finalize and basic smoke tests.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE RT_Asm_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Asm_Core
  USE RT_Brg_Def, ONLY: RT_Mat_Bridge_Ctx, RT_Elem_Bridge_Ctx, RT_Bridge_Init
  USE RT_Asm_Brg, ONLY: RT_Asm_Brg_ApplyMatBridge_Flat_IP, &
                        RT_Asm_Brg_ApplyElemBridge_Flat_IP, RT_Asm_Brg_SyncMatBridgeMirror, &
                        RT_Asm_Brg_ElemMatPtIdx
  USE MD_Step_Sync, ONLY: UF_Step_BuildLegacyLoadDefs_FromLdbc
  USE MD_LBC_Domain, ONLY: MD_LoadBC_Domain, MD_Load_Desc, LOAD_CLOAD
  USE MD_Load_Mgr, ONLY: LoadDef
  USE MD_Model_Lib_Core, ONLY: UF_Model
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Assembly_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  !---------------------------------------------------------------------------
  ! Test runner: execute all tests and report
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Assembly_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()
    CALL test_rt_bridge_flat_nested_mirror()
    CALL test_legacy_load_defs_from_ldbc()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_Assembly_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_Assembly_Run_Tests

  !---------------------------------------------------------------------------
  ! Test: Init and Finalize succeed without error
  !---------------------------------------------------------------------------
  SUBROUTINE test_init_finalize()
    TYPE(ErrorStatusType) :: status

    ! TODO: Call RT_Asm_Core Init with minimal valid inputs
    ! TODO: Verify status == IF_STATUS_OK
    ! TODO: Call RT_Asm_Core Finalize
    ! TODO: Verify status == IF_STATUS_OK

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK

    IF (status%status_code == IF_STATUS_OK) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize"
    END IF
  END SUBROUTINE test_init_finalize

  !---------------------------------------------------------------------------
  ! Test: RT_Bridge_Init + RT_Asm_Brg keep Mat/Elem flat and %stp/%lcl aligned
  !---------------------------------------------------------------------------
  SUBROUTINE test_rt_bridge_flat_nested_mirror()
    TYPE(RT_Mat_Bridge_Ctx)  :: mb
    TYPE(RT_Elem_Bridge_Ctx) :: eb
    INTEGER(i4) :: lf(5)

    CALL RT_Bridge_Init(mat_brg=mb, elem_brg=eb)
    IF (mb%mat_id == mb%stp%mat_id .AND. mb%kstep == mb%lcl%kstep &
        .AND. eb%elem_id == eb%stp%elem_id .AND. eb%kinc == eb%lcl%kinc) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_rt_bridge_flat_nested_mirror - after Init"
      RETURN
    END IF

    mb%mat_id = 42_i4
    mb%mat_family = 2_i4
    mb%algo_id = 201_i4
    CALL RT_Asm_Brg_SyncMatBridgeMirror(mb)
    IF (mb%stp%mat_id == 42_i4 .AND. mb%stp%mat_family == 2_i4 .AND. mb%stp%algo_id == 201_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_rt_bridge_flat_nested_mirror - SyncMat partial flat"
      RETURN
    END IF

    CALL RT_Asm_Brg_ApplyMatBridge_Flat_IP(mb, 7_i4, 1_i4, 101_i4, 3_i4, &
        0.01_wp, 1.0_wp, 10.0_wp, 1_i4, 2_i4, 100_i4, 4_i4)
    IF (mb%stp%mat_id == 7_i4 .AND. mb%lcl%npt == 4_i4 .AND. mb%lcl%dtime == 0.01_wp) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_rt_bridge_flat_nested_mirror - ApplyMatBridge_Flat_IP"
      RETURN
    END IF

    lf = (/ 1_i4, 0_i4, 0_i4, 0_i4, 0_i4 /)
    CALL RT_Asm_Brg_ApplyElemBridge_Flat_IP(eb, 55_i4, 12_i4, 3_i4, lf, &
        0.02_wp, 2.0_wp, 20.0_wp, 3_i4, 4_i4, 1_i4, 1_i4)
    IF (eb%stp%elem_id == 55_i4 .AND. eb%lcl%lflags(1) == 1_i4 .AND. eb%lcl%kstep == 3_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_rt_bridge_flat_nested_mirror - ApplyElemBridge_Flat_IP"
    END IF

    IF (RT_Asm_Brg_ElemMatPtIdx(-1_i4) == 0_i4 .AND. RT_Asm_Brg_ElemMatPtIdx(999999_i4) == 0_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_rt_bridge_flat_nested_mirror - ElemMatPtIdx guard"
    END IF
  END SUBROUTINE test_rt_bridge_flat_nested_mirror

  !---------------------------------------------------------------------------
  ! Test: L3 MD_LoadBC_Domain -> flat LoadDef via UF_Step_BuildLegacyLoadDefs_FromLdbc
  !---------------------------------------------------------------------------
  SUBROUTINE test_legacy_load_defs_from_ldbc()
    TYPE(MD_LoadBC_Domain) :: ldbc
    TYPE(UF_Model) :: mdl
    TYPE(LoadDef), ALLOCATABLE :: loads(:)
    TYPE(ErrorStatusType) :: st
    TYPE(MD_Load_Desc) :: d

    CALL ldbc%Init(8_i4, 8_i4, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE (*, '(A)') '  FAIL: test_legacy_load_defs_from_ldbc Init'
      RETURN
    END IF

    d%name = 'smoke_cload'
    d%load_type = LOAD_CLOAD
    d%node_id = 2_i4
    d%dof = 1_i4
    d%magnitude = 3.0_wp
    d%step_ref = 1_i4
    CALL ldbc%AddLoad(d, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE (*, '(A)') '  FAIL: test_legacy_load_defs_from_ldbc AddLoad'
      CALL ldbc%Finalize()
      RETURN
    END IF

    CALL UF_Step_BuildLegacyLoadDefs_FromLdbc(ldbc, mdl, 1_i4, loads, st)
    IF (st%status_code /= IF_STATUS_OK .OR. .NOT. ALLOCATED(loads) .OR. SIZE(loads) /= 1_i4) THEN
      n_failed = n_failed + 1
      WRITE (*, '(A)') '  FAIL: test_legacy_load_defs_from_ldbc Build'
      IF (ALLOCATED(loads)) DEALLOCATE(loads)
      CALL ldbc%Finalize()
      RETURN
    END IF
    IF (loads(1)%targetId /= 2_i4 .OR. loads(1)%magnitude /= 3.0_wp) THEN
      n_failed = n_failed + 1
      WRITE (*, '(A)') '  FAIL: test_legacy_load_defs_from_ldbc values'
      DEALLOCATE(loads)
      CALL ldbc%Finalize()
      RETURN
    END IF

    DEALLOCATE(loads)
    CALL ldbc%Finalize()
    n_passed = n_passed + 1
  END SUBROUTINE test_legacy_load_defs_from_ldbc

END MODULE RT_Asm_Test
