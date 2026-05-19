!===============================================================================
! Module:  RT_Material_Test
! Layer:   L5_RT
! Domain:  Material
! Purpose: Test framework for the Material domain routing layer.
!          Verifies dispatch table init/finalize, route registration,
!          and context lookup.
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE RT_Mat_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Mat_Def
  USE RT_Mat_Core
  USE RT_Mat_Brg, ONLY: RT_Mat_Brg_BuildTable_FromMaterial, RT_Mat_Brg_MakeCtx, &
                        RT_Mat_Brg_WriteBackHook
  USE PH_Mat_Core, ONLY: PH_Mat_Core_Init
  USE PH_Mat_Plast_J2_Iso_Core, ONLY: PH_J2_Props, PH_J2_ComputeTrialStress, PH_J2_YieldCheck, PH_MAT_J2_HARD_LINEAR
  USE PH_Mat_Def, ONLY: PH_Mat_Domain, PH_Mat_AllocSlot_Idx, &
                                     PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
                                     PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, &
                                     PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, &
                                     PH_MAT_USER, PH_MAT_USER_VUMAT, &
                                     MAT_PLAST_J2_ISO
  USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_Elastic3D
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Material_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_Material_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_table_lifecycle()
    CALL test_route_register_and_lookup()
    CALL test_dispatch_validation()
    CALL test_populated_material_domain_bridge()
    CALL test_eleven_family_route_skeleton()
    CALL test_j2_radial_return_pilot()
    CALL test_writeback_hook_validation()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_Material_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_Material_Run_Tests

  !---------------------------------------------------------------------------
  ! Test: Table init and finalize succeed
  !---------------------------------------------------------------------------
  SUBROUTINE test_table_lifecycle()
    TYPE(RT_Mat_Dispatch_Table) :: table
    TYPE(ErrorStatusType) :: status

    CALL RT_Mat_Init_Table(table, status)
    IF (status%status_code == IF_STATUS_OK .AND. table%initialized &
        .AND. table%n_entries == 0) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_table_lifecycle - init"
    END IF

    CALL RT_Mat_Finalize_Table(table, status)
    IF (status%status_code == IF_STATUS_OK .AND. .NOT. table%initialized) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_table_lifecycle - finalize"
    END IF
  END SUBROUTINE test_table_lifecycle

  !---------------------------------------------------------------------------
  ! Test: Register a route and look it up
  !---------------------------------------------------------------------------
  SUBROUTINE test_route_register_and_lookup()
    TYPE(RT_Mat_Dispatch_Table) :: table
    TYPE(RT_Mat_Dispatch_Ctx)   :: ctx
    TYPE(ErrorStatusType) :: status

    CALL RT_Mat_Init_Table(table, status)

    CALL RT_Mat_Register_Route(table, 101_i4, 1_i4, 5_i4, .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_route_register - register"
      RETURN
    END IF

    IF (table%n_entries /= 1) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_route_register - n_entries"
      RETURN
    END IF

    CALL RT_Mat_Get_Route(table, 1_i4, ctx, status)
    IF (status%status_code == IF_STATUS_OK &
        .AND. ctx%mat_type == 101 &
        .AND. ctx%mat_pt_idx == 5 &
        .AND. .NOT. ctx%is_user_sub) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_route_register - lookup"
    END IF

    CALL RT_Mat_Finalize_Table(table, status)
  END SUBROUTINE test_route_register_and_lookup

  !---------------------------------------------------------------------------
  ! Test: Dispatch validation rejects invalid context
  !---------------------------------------------------------------------------
  SUBROUTINE test_dispatch_validation()
    TYPE(RT_Mat_Dispatch_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status

    ctx%mat_type   = 0_i4
    ctx%mat_pt_idx = 0_i4

    CALL RT_Mat_Dispatch_Stress(ctx, status)
    IF (status%status_code /= IF_STATUS_OK &
        .AND. ctx%route_status == RT_MAT_ROUTE_NOT_FOUND) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_dispatch_validation - reject invalid"
    END IF

    ctx%mat_type   = 101_i4
    ctx%mat_pt_idx = 1_i4
    CALL RT_Mat_Dispatch_Stress(ctx, status)
    IF (status%status_code == IF_STATUS_OK &
        .AND. ctx%route_status == RT_MAT_ROUTE_OK) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_dispatch_validation - accept valid"
    END IF
  END SUBROUTINE test_dispatch_validation

  !---------------------------------------------------------------------------
  ! Test: Build L5 route table from populated L4 material slots
  !---------------------------------------------------------------------------
  SUBROUTINE test_populated_material_domain_bridge()
    TYPE(PH_Mat_Domain) :: material_dom
    TYPE(RT_Mat_Dispatch_Table) :: table
    TYPE(RT_Mat_Dispatch_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: mat_pt_idx
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: tangent(6, 6)

    CALL material_dom%Init(1_i4, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - material init"
      RETURN
    END IF

    CALL RT_Mat_Init_Table(table, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - table init"
      RETURN
    END IF

    CALL PH_Mat_AllocSlot_Idx(material_dom, mat_pt_idx, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - alloc slot"
      RETURN
    END IF
    material_dom%slot_pool(mat_pt_idx)%desc%cfg%matId = 7_i4
    material_dom%slot_pool(mat_pt_idx)%desc%cfg%matModel = PH_MAT_ELASTIC
    material_dom%slot_pool(mat_pt_idx)%desc%pop%mat_model_id = 101_i4
    ALLOCATE(material_dom%slot_pool(mat_pt_idx)%desc%props(2_i4))
    material_dom%slot_pool(mat_pt_idx)%desc%props(1) = 210.0E9_wp
    material_dom%slot_pool(mat_pt_idx)%desc%props(2) = 0.30_wp

    CALL RT_Mat_Brg_BuildTable_FromMaterial(table, material_dom, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - build table"
      RETURN
    END IF

    CALL RT_Mat_Brg_MakeCtx(table, 7_i4, ctx, status)
    IF (status%status_code == IF_STATUS_OK .AND. table%n_entries == 1_i4 .AND. &
        ctx%mat_type == PH_MAT_ELASTIC .AND. ctx%mat_pt_idx == mat_pt_idx .AND. &
        .NOT. ctx%is_user_sub) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - make ctx"
    END IF

    CALL RT_Mat_Dispatch_Stress(ctx, status)
    IF (status%status_code /= IF_STATUS_OK .OR. ctx%route_status /= RT_MAT_ROUTE_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - dispatch ctx"
      CALL material_dom%Finalize()
      RETURN
    END IF

    dstrain = 0.0_wp
    stress_old = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    CALL PH_Elem_MatRoute_Elastic3D(ctx, material_dom%slot_pool(mat_pt_idx), &
                                    dstrain, stress_old, stress_new, tangent, status)
    IF (status%status_code == IF_STATUS_OK .AND. stress_new(1) > 0.0_wp .AND. &
        tangent(1, 1) > 0.0_wp) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_populated_material_domain_bridge - elastic response"
    END IF

    CALL material_dom%Finalize()
  END SUBROUTINE test_populated_material_domain_bridge

  !---------------------------------------------------------------------------
  ! Test: WriteBack hook validates finite stress for a routed user material
  !---------------------------------------------------------------------------
  SUBROUTINE test_eleven_family_route_skeleton()
    TYPE(PH_Mat_Domain) :: dom
    TYPE(RT_Mat_Dispatch_Table) :: table
    TYPE(RT_Mat_Dispatch_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: fams(11), k, mid, idx

    fams = (/PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
              PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, &
              PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, PH_MAT_USER_VUMAT/)

    CALL dom%Init(1_i4, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: eleven_family - domain init"
      RETURN
    END IF

    CALL RT_Mat_Init_Table(table, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: eleven_family - table init"
      CALL dom%Finalize()
      RETURN
    END IF

    CALL PH_Mat_Core_Init(status)

    DO k = 1, 11
      mid = 200_i4 + k
      CALL PH_Mat_AllocSlot_Idx(dom, idx, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        n_failed = n_failed + 1
        WRITE(*,'(A)') "  FAIL: eleven_family - alloc slot"
        CALL dom%Finalize()
        RETURN
      END IF
      dom%slot_pool(idx)%active = .TRUE.
      dom%slot_pool(idx)%desc%cfg%matId = mid
      dom%slot_pool(idx)%desc%cfg%matModel = fams(k)
      IF (k == 2_i4) THEN
        dom%slot_pool(idx)%desc%pop%mat_model_id = MAT_PLAST_J2_ISO
        IF (ALLOCATED(dom%slot_pool(idx)%desc%props)) &
          DEALLOCATE (dom%slot_pool(idx)%desc%props)
        ALLOCATE(dom%slot_pool(idx)%desc%props(4_i4))
        dom%slot_pool(idx)%desc%props(1) = 200.0E3_wp
        dom%slot_pool(idx)%desc%props(2) = 0.30_wp
        dom%slot_pool(idx)%desc%props(3) = 200.0_wp
        dom%slot_pool(idx)%desc%props(4) = 1000.0_wp
      ELSE
        dom%slot_pool(idx)%desc%pop%mat_model_id = 101_i4
        ALLOCATE(dom%slot_pool(idx)%desc%props(2_i4))
        dom%slot_pool(idx)%desc%props(1) = 210.0E9_wp
        dom%slot_pool(idx)%desc%props(2) = 0.30_wp
      END IF

      ALLOCATE(dom%slot_pool(idx)%state%comp%stress(6))
      dom%slot_pool(idx)%state%comp%stress = 0.0_wp
      ALLOCATE(dom%slot_pool(idx)%state%comp%C_tan(6, 6))
      dom%slot_pool(idx)%state%comp%C_tan = 0.0_wp
      IF (k == 2_i4) THEN
        ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars(7))
        ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars_n(7))
      ELSE
        ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars(1))
        ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars_n(1))
      END IF
      dom%slot_pool(idx)%state%evo%stateVars = 0.0_wp
      dom%slot_pool(idx)%state%evo%stateVars_n = 0.0_wp
      dom%slot_pool(idx)%ctx%inc%dt = 1.0_wp
      dom%slot_pool(idx)%ctx%lcl%dstrain = 0.0_wp
      dom%slot_pool(idx)%ctx%lcl%dstrain(1) = 1.0E-3_wp
    END DO

    CALL RT_Mat_Brg_BuildTable_FromMaterial(table, dom, status)
    IF (status%status_code /= IF_STATUS_OK .OR. table%n_entries /= 11_i4) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: eleven_family - build table"
      CALL dom%Finalize()
      RETURN
    END IF

    DO k = 1, 11
      mid = 200_i4 + k
      CALL RT_Mat_Brg_MakeCtx(table, mid, ctx, status)
      IF (status%status_code /= IF_STATUS_OK .OR. ctx%mat_type /= fams(k) .OR. &
          ctx%route_status /= RT_MAT_ROUTE_OK) THEN
        n_failed = n_failed + 1
        WRITE(*,'(A)') "  FAIL: eleven_family - make ctx"
        CALL dom%Finalize()
        RETURN
      END IF
      CALL RT_Mat_Dispatch_Stress(ctx, status)
      IF (status%status_code /= IF_STATUS_OK .OR. ctx%route_status /= RT_MAT_ROUTE_OK) THEN
        n_failed = n_failed + 1
        WRITE(*,'(A)') "  FAIL: eleven_family - dispatch stress (stub)"
        CALL dom%Finalize()
        RETURN
      END IF
      CALL RT_Mat_Dispatch_Stress(ctx, status, dom)
      IF (status%status_code /= IF_STATUS_OK .OR. ctx%route_status /= RT_MAT_ROUTE_OK) THEN
        n_failed = n_failed + 1
        WRITE(*,'(A)') "  FAIL: eleven_family - dispatch stress (L4 execute)"
        CALL dom%Finalize()
        RETURN
      END IF
      IF (k == 1_i4 .OR. k == 2_i4) THEN
        IF (.NOT. ALLOCATED(dom%slot_pool(ctx%mat_pt_idx)%state%comp%stress)) THEN
          n_failed = n_failed + 1
          WRITE(*,'(A)') "  FAIL: eleven_family - stress not allocated"
          CALL dom%Finalize()
          RETURN
        END IF
        IF (dom%slot_pool(ctx%mat_pt_idx)%state%comp%stress(1) <= 0.0_wp) THEN
          n_failed = n_failed + 1
          WRITE(*,'(A)') "  FAIL: eleven_family - stress(1) not positive (elas/plast)"
          CALL dom%Finalize()
          RETURN
        END IF
      END IF
    END DO

    n_passed = n_passed + 1
    CALL dom%Finalize()
  END SUBROUTINE test_eleven_family_route_skeleton

  SUBROUTINE test_j2_radial_return_pilot()
    TYPE(PH_Mat_Domain) :: dom
    TYPE(ErrorStatusType) :: status
    TYPE(RT_Mat_Dispatch_Ctx) :: ctx
    INTEGER(i4) :: idx
    REAL(wp) :: eqp, E, nu, sy0, H_iso, Gsh, dlam, eqp_ex
    REAL(wp) :: sn(6), de(6), D_el(6, 6), sig_tr(6), s_tr(6), q_tr, p_mean, f_tr, sig_y
    TYPE(PH_J2_Props) :: j2p

    CALL init_error_status(status)
    CALL PH_Mat_Core_Init(status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - PH_Mat_Core_Init"
      RETURN
    END IF

    CALL dom%Init(1_i4, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - domain init"
      RETURN
    END IF

    CALL PH_Mat_AllocSlot_Idx(dom, idx, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - alloc slot"
      CALL dom%Finalize()
      RETURN
    END IF

    dom%slot_pool(idx)%active = .TRUE.
    dom%slot_pool(idx)%desc%cfg%matId = 9901_i4
    dom%slot_pool(idx)%desc%cfg%matModel = PH_MAT_ELASTO_PLASTIC
    dom%slot_pool(idx)%desc%pop%mat_model_id = MAT_PLAST_J2_ISO
    ALLOCATE(dom%slot_pool(idx)%desc%props(4_i4))
    E = 200.0E3_wp
    nu = 0.30_wp
    sy0 = 200.0_wp
    H_iso = 1000.0_wp
    dom%slot_pool(idx)%desc%props(1) = E
    dom%slot_pool(idx)%desc%props(2) = nu
    dom%slot_pool(idx)%desc%props(3) = sy0
    dom%slot_pool(idx)%desc%props(4) = H_iso

    ALLOCATE(dom%slot_pool(idx)%state%comp%stress(6))
    dom%slot_pool(idx)%state%comp%stress = 0.0_wp
    ALLOCATE(dom%slot_pool(idx)%state%comp%C_tan(6, 6))
    dom%slot_pool(idx)%state%comp%C_tan = 0.0_wp
    ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars(7))
    ALLOCATE(dom%slot_pool(idx)%state%evo%stateVars_n(7))
    dom%slot_pool(idx)%state%evo%stateVars = 0.0_wp
    dom%slot_pool(idx)%state%evo%stateVars_n = 0.0_wp

    dom%slot_pool(idx)%ctx%inc%dt = 1.0_wp
    dom%slot_pool(idx)%ctx%lcl%dstrain = 0.0_wp
    dom%slot_pool(idx)%ctx%lcl%dstrain(1) = 0.005_wp

    ctx%mat_type = PH_MAT_ELASTO_PLASTIC
    ctx%mat_id = 9901_i4
    ctx%mat_pt_idx = idx
    ctx%is_user_sub = .FALSE.

    CALL RT_Mat_Dispatch_Stress(ctx, status, dom)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - dispatch"
      CALL dom%Finalize()
      RETURN
    END IF

    eqp = dom%slot_pool(idx)%state%evo%stateVars(1)
    sn = 0.0_wp
    de = 0.0_wp
    de(1) = dom%slot_pool(idx)%ctx%lcl%dstrain(1)
    j2p%elastic%E = E
    j2p%elastic%nu = nu
    j2p%yield%sigma_y0 = sy0
    j2p%harden%H = H_iso
    j2p%ctrl%hardening_type = PH_MAT_J2_HARD_LINEAR
    j2p%ctrl%use_kinematic = .FALSE.
    CALL PH_J2_ComputeTrialStress(j2p, sn, de, D_el, sig_tr, s_tr, q_tr, p_mean)
    CALL PH_J2_YieldCheck(j2p, 0.0_wp, q_tr, f_tr, sig_y)
    IF (f_tr <= 0.0_wp) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - trial should yield"
      CALL dom%Finalize()
      RETURN
    END IF
    Gsh = E / (2.0_wp * (1.0_wp + nu))
    dlam = f_tr / (3.0_wp * Gsh + H_iso)
    eqp_ex = dlam

    IF (ABS(eqp - eqp_ex) > 1.0E-6_wp) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: j2_pilot - eqplas mismatch"
      CALL dom%Finalize()
      RETURN
    END IF

    n_passed = n_passed + 1
    CALL dom%Finalize()
  END SUBROUTINE test_j2_radial_return_pilot

  SUBROUTINE test_writeback_hook_validation()
    TYPE(RT_Mat_Dispatch_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: stress(6)

    stress = 0.0_wp
    ctx%mat_type = PH_MAT_USER_VUMAT
    ctx%mat_id = 9_i4
    ctx%mat_pt_idx = 2_i4
    ctx%is_user_sub = .TRUE.
    ctx%route_status = RT_MAT_ROUTE_OK

    CALL RT_Mat_Brg_WriteBackHook(ctx, stress, 6_i4, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_writeback_hook_validation"
    END IF
  END SUBROUTINE test_writeback_hook_validation

END MODULE RT_Mat_Test
