!===============================================================================
! Module:  TEST_Field_L3_L4_Closure
! Layer:   Tests
! Domain:  Field
! Purpose: Minimal closure test for the Field template domain.
!          Covers L3 Field definition, L4 Field Ops, Shape support, and
!          Temperature compute reachability.
!
! Status: ACTIVE | TEMPLATE CLOSURE | Last verified: 2026-04-27
!===============================================================================
MODULE TEST_Field_L3_L4_Closure
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  USE MD_Field_Def, ONLY: MD_Field_Desc, MD_Field_State, MD_Field_Ctx, &
                          MD_FieldEntry, MD_FieldRegionRef, &
                          MD_FieldInitCond, MD_FIELD_TEMPERATURE, &
                          MD_FIELD_ENTITY_NODE, MD_FIELD_REGION_SET_NAME, &
                          MD_FIELD_DIST_BY_SET
  USE MD_Field_Mgr, ONLY: MD_Field_Domain_Init, MD_Field_Define, &
                          MD_Field_Get_By_ID
  USE PH_Field_Def, ONLY: PH_Field_Desc, PH_Field_State, PH_Field_Algo, &
                          PH_Field_Ctx, &
                          PH_Temperature_Desc, PH_Temperature_Algo, &
                          PH_Temperature_Arg
  USE PH_Field_Ops, ONLY: PH_Field_Ops_Init, PH_Field_Interpolate_To_IP
  USE PH_Field_ShapeFunc, ONLY: PH_Field_GetShapeFunctions, &
                                PH_Field_ShapeFunc_Arg
  USE PH_Field_ComputeTemp, ONLY: PH_Field_Compute_Temperature_Explicit
  USE PH_L4_Populate, ONLY: PH_L4_Populate_Field
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Field_L3_L4_Closure_Test

  REAL(wp), PARAMETER :: TOL = 1.0E-10_wp

CONTAINS

  SUBROUTINE Run_Field_L3_L4_Closure_Test(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    INTEGER(i4) :: n_passed
    INTEGER(i4) :: n_failed

    n_passed = 0_i4
    n_failed = 0_i4

    CALL test_l3_define_temperature(n_passed, n_failed)
    CALL test_field_populate_contract(n_passed, n_failed)
    CALL test_l4_ops_shape_compute(n_passed, n_failed)

    all_passed = (n_failed == 0_i4)
    WRITE(*,'(A,I4,A,I4,A)') "[TEST_Field_L3_L4_Closure] ", n_passed, &
                              " passed, ", n_failed, " failed"
  END SUBROUTINE Run_Field_L3_L4_Closure_Test

  SUBROUTINE test_l3_define_temperature(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_Field_Desc) :: md_desc
    TYPE(MD_Field_State) :: md_state
    TYPE(MD_Field_Ctx) :: md_ctx
    TYPE(MD_FieldRegionRef) :: region
    TYPE(MD_FieldInitCond) :: initial
    TYPE(MD_FieldEntry) :: field
    TYPE(ErrorStatusType) :: status

    CALL MD_Field_Domain_Init(md_desc, md_state, md_ctx, status)
    IF (.NOT. expect_ok(status, "l3 init", n_failed)) RETURN

    region%region_kind = MD_FIELD_REGION_SET_NAME
    region%entity_kind = MD_FIELD_ENTITY_NODE
    region%set_name = "ALLNODES"

    initial%field_id = 1_i4
    initial%distribution_kind = MD_FIELD_DIST_BY_SET
    initial%region = region
    initial%n_values = 1_i4
    ALLOCATE(initial%values(1))
    initial%values(1) = 300.0_wp

    CALL MD_Field_Define(md_desc, 1_i4, "TEMP", 1_i4, MD_FIELD_ENTITY_NODE, &
                         status, field_type=MD_FIELD_TEMPERATURE, &
                         distribution_kind=MD_FIELD_DIST_BY_SET, &
                         region=region, initial=initial)
    IF (.NOT. expect_ok(status, "l3 define temperature", n_failed)) RETURN

    CALL MD_Field_Get_By_ID(md_desc, 1_i4, field, status)
    IF (.NOT. expect_ok(status, "l3 get temperature", n_failed)) RETURN

    IF (field%field_type == MD_FIELD_TEMPERATURE .AND. &
        field%distribution_kind == MD_FIELD_DIST_BY_SET .AND. &
        TRIM(field%region%set_name) == "ALLNODES" .AND. &
        ABS(field%init_val - 300.0_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3 semantic field contract"
    END IF
  END SUBROUTINE test_l3_define_temperature

  SUBROUTINE test_field_populate_contract(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_Field_Desc) :: md_desc
    TYPE(MD_Field_State) :: md_state
    TYPE(MD_Field_Ctx) :: md_ctx
    TYPE(MD_FieldRegionRef) :: region
    TYPE(MD_FieldInitCond) :: initial
    TYPE(PH_Field_Desc) :: ph_desc
    TYPE(PH_Field_State) :: ph_state
    TYPE(PH_Field_Algo) :: ph_algo
    TYPE(ErrorStatusType) :: status

    CALL MD_Field_Domain_Init(md_desc, md_state, md_ctx, status)
    IF (.NOT. expect_ok(status, "populate l3 init", n_failed)) RETURN

    region%region_kind = MD_FIELD_REGION_SET_NAME
    region%entity_kind = MD_FIELD_ENTITY_NODE
    region%set_name = "ALLNODES"

    initial%field_id = 1_i4
    initial%distribution_kind = MD_FIELD_DIST_BY_SET
    initial%region = region
    initial%n_values = 1_i4
    ALLOCATE(initial%values(1))
    initial%values(1) = 300.0_wp

    CALL MD_Field_Define(md_desc, 1_i4, "TEMP", 1_i4, MD_FIELD_ENTITY_NODE, &
                         status, field_type=MD_FIELD_TEMPERATURE, &
                         distribution_kind=MD_FIELD_DIST_BY_SET, &
                         region=region, initial=initial)
    IF (.NOT. expect_ok(status, "populate l3 define", n_failed)) RETURN

    CALL PH_L4_Populate_Field(md_desc, ph_desc, ph_state, ph_algo, 1_i4, status)
    IF (.NOT. expect_ok(status, "populate field", n_failed)) RETURN

    IF (ph_state%allocated .AND. ph_state%values_set .AND. &
        ph_state%n_dof_active == 1_i4 .AND. ph_state%current_step == 1_i4 .AND. &
        ph_desc%n_comp == 1_i4) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: field populate contract"
    END IF
  END SUBROUTINE test_field_populate_contract

  SUBROUTINE test_l4_ops_shape_compute(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Field_Desc) :: ph_desc
    TYPE(PH_Field_State) :: ph_state
    TYPE(PH_Field_Ctx) :: ph_ctx
    TYPE(PH_Field_ShapeFunc_Arg) :: shape_arg
    TYPE(PH_Temperature_Desc) :: temp_desc
    TYPE(PH_Temperature_Algo) :: temp_algo
    TYPE(PH_Temperature_Arg) :: temp_arg
    TYPE(ErrorStatusType) :: status
    REAL(wp), TARGET :: t_n(1, 2)
    INTEGER(i4) :: i

    ph_desc%nn = 8_i4
    ph_desc%nip = 1_i4
    ph_desc%ndim = 3_i4
    ph_desc%n_comp = 1_i4
    ph_desc%n_nodes = 8_i4

    CALL PH_Field_Ops_Init(ph_desc, ph_state, ph_ctx, status)
    IF (.NOT. expect_ok(status, "l4 ops init", n_failed)) RETURN

    CALL PH_Field_GetShapeFunctions("C3D8", 0.0_wp, 0.0_wp, 0.0_wp, 8_i4, shape_arg)
    IF (.NOT. expect_ok(shape_arg%status, "l4 shape support", n_failed)) RETURN

    ph_ctx%N_shape(1:8) = shape_arg%N(1:8)
    DO i = 1, 8
      ph_ctx%nodal_vals(1, i) = REAL(i, wp)
    END DO

    CALL PH_Field_Interpolate_To_IP(ph_desc, ph_ctx, status)
    IF (.NOT. expect_ok(status, "l4 interpolate to ip", n_failed)) RETURN

    IF (ABS(ph_ctx%ip_vals(1, 1) - 4.5_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l4 interpolation closure"
      RETURN
    END IF

    temp_desc%thermal_conductivity = 10.0_wp
    temp_desc%heat_capacity = 2.0_wp
    temp_desc%density = 5.0_wp
    temp_algo%dt = 1.0_wp
    t_n(1, 1) = 300.0_wp
    t_n(1, 2) = 310.0_wp
    temp_arg%t_n => t_n

    CALL PH_Field_Compute_Temperature_Explicit(temp_desc, temp_algo, temp_arg, status)
    IF (.NOT. expect_ok(status, "l4 temperature compute", n_failed)) RETURN

    IF (ALLOCATED(temp_arg%temperature) .AND. ALLOCATED(temp_arg%heat_flux) .AND. &
        ABS(temp_arg%temperature(1, 2) - 310.0_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l4 temperature compute closure"
    END IF
  END SUBROUTINE test_l4_ops_shape_compute

  LOGICAL FUNCTION expect_ok(status, label, n_failed)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    CHARACTER(LEN=*), INTENT(IN) :: label
    INTEGER(i4), INTENT(INOUT) :: n_failed

    expect_ok = (status%status_code == IF_STATUS_OK)
    IF (.NOT. expect_ok) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A)') "  FAIL: ", TRIM(label)
    END IF
  END FUNCTION expect_ok

END MODULE TEST_Field_L3_L4_Closure
