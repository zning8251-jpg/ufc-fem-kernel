!===============================================================================
! Module:  MD_Field_Test
! Layer:   L3_MD
! Domain:  Field
! Purpose: Minimal test framework for the Field domain.
!          Verifies Init/Finalize and basic smoke tests.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE MD_Field_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  USE MD_Field_Def, ONLY: MD_Field_Desc, MD_Field_State, MD_Field_Ctx, &
                          MD_FieldEntry, MD_FieldRegionRef, &
                          MD_FieldInitCond, MD_FIELD_TEMPERATURE, &
                          MD_FIELD_ENTITY_NODE, MD_FIELD_REGION_SET_NAME, &
                          MD_FIELD_DIST_BY_SET
  USE MD_Field_Mgr, ONLY: MD_Field_Domain_Init, MD_Field_Domain_Finalize, &
                          MD_Field_Define, MD_Field_Get_By_ID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Field_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  !---------------------------------------------------------------------------
  ! Test runner: execute all tests and report
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Field_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()
    CALL test_define_semantic_field()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[MD_Field_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE MD_Field_Run_Tests

  !---------------------------------------------------------------------------
  ! Test: Init and Finalize succeed without error
  !---------------------------------------------------------------------------
  SUBROUTINE test_init_finalize()
    TYPE(MD_Field_Desc) :: desc
    TYPE(MD_Field_State) :: state
    TYPE(MD_Field_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status

    CALL MD_Field_Domain_Init(desc, state, ctx, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize init"
      RETURN
    END IF

    CALL MD_Field_Domain_Finalize(desc, state, ctx, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize"
    END IF
  END SUBROUTINE test_init_finalize

  SUBROUTINE test_define_semantic_field()
    TYPE(MD_Field_Desc) :: desc
    TYPE(MD_Field_State) :: state
    TYPE(MD_Field_Ctx) :: ctx
    TYPE(MD_FieldRegionRef) :: region
    TYPE(MD_FieldInitCond) :: initial
    TYPE(MD_FieldEntry) :: field
    TYPE(ErrorStatusType) :: status

    CALL MD_Field_Domain_Init(desc, state, ctx, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_define_semantic_field init"
      RETURN
    END IF

    region%region_kind = MD_FIELD_REGION_SET_NAME
    region%entity_kind = MD_FIELD_ENTITY_NODE
    region%set_name = "ALLNODES"

    initial%field_id = 1_i4
    initial%distribution_kind = MD_FIELD_DIST_BY_SET
    initial%region = region
    initial%n_values = 1_i4
    ALLOCATE(initial%values(1))
    initial%values(1) = 300.0_wp

    CALL MD_Field_Define(desc, 1_i4, "TEMP", 1_i4, MD_FIELD_ENTITY_NODE, &
                         status, field_type=MD_FIELD_TEMPERATURE, &
                         distribution_kind=MD_FIELD_DIST_BY_SET, &
                         region=region, initial=initial)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_define_semantic_field define"
      RETURN
    END IF

    CALL MD_Field_Get_By_ID(desc, 1_i4, field, status)
    IF (status%status_code == IF_STATUS_OK .AND. &
        field%field_type == MD_FIELD_TEMPERATURE .AND. &
        field%distribution_kind == MD_FIELD_DIST_BY_SET .AND. &
        TRIM(field%region%set_name) == "ALLNODES" .AND. &
        field%init_val == 300.0_wp) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_define_semantic_field"
    END IF
  END SUBROUTINE test_define_semantic_field

END MODULE MD_Field_Test
