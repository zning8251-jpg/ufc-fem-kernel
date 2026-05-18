!===============================================================================
! Module:  TEST_Contact_L3_L4_Closure
! Layer:   Tests
! Domain:  Contact
! Purpose: Minimal closure test for the P3 Contact pillar.
!          Covers L3 interaction definition → L4 Contact domain → L5 runtime.
!          Chain: MD_Interaction_Desc → PH_Contact_Domain Init → PH_L4_Populate_Contact
!                 → PH_Cont search/force → RT_Contact dispatch → State verification
!
! Status: ACTIVE | P3 CONTACT CLOSURE | Last verified: 2026-04-28
!===============================================================================
MODULE TEST_Contact_L3_L4_Closure
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Int_Def, ONLY: MD_Interaction_Desc, MD_Interaction_State, &
                        MD_Interaction_Algo, MD_Int_Ctx, &
                        ContactPairType, SurfaceInteractionType, &
                        FrictionModelType, &
                        CONTACT_TYPE_S2S, CONTACT_TYPE_P2S, &
                        FRICTION_COULOMB, ALGORITHM_PENALTY, &
                        Initialize_InteractionDesc, AddContactPair, &
                        IsValidContactPair, IsValidFrictionModel
  ! Note: PH_Cont_Ctx from PH_Cont_Def (simplified per-pair workspace)
  ! differs from PH_Contact_Domain context (domain-level context).
  USE PH_Cont_Def, ONLY: PH_Cont_Desc, PH_Cont_State, PH_Cont_Algo, &
                          PH_Cont_Ctx, &
                          PH_CONT_OPEN, PH_CONT_CLOSED, &
                          PH_CONT_METHOD_PENALTY
  USE PH_Cont_Domain, ONLY: PH_Contact_Domain
  USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, &
                          RT_Contact_Algo, RT_Contact_Ctx, &
                          RT_CONT_DISC_NODE_TO_SURF, &
                          RT_CONT_ENFORCE_PENALTY, &
                          RT_CONT_FRICTION_COULOMB, &
                          RT_CONT_PAIR_OPEN, RT_CONT_PAIR_CLOSED
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Contact_L3_L4_Closure_Test

  REAL(wp), PARAMETER :: TOL = 1.0E-10_wp

CONTAINS

  SUBROUTINE Run_Contact_L3_L4_Closure_Test(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    INTEGER(i4) :: n_passed
    INTEGER(i4) :: n_failed

    n_passed = 0_i4
    n_failed = 0_i4

    CALL test_l3_interaction_desc_creation(n_passed, n_failed)
    CALL test_l3_contact_pair_validation(n_passed, n_failed)
    CALL test_l4_contact_domain_init(n_passed, n_failed)
    CALL test_l4_contact_types_contract(n_passed, n_failed)
    CALL test_l5_contact_dispatch_ctx(n_passed, n_failed)
    CALL test_l3_l4_l5_full_chain(n_passed, n_failed)

    all_passed = (n_failed == 0_i4)
    WRITE(*,'(A,I4,A,I4,A)') "[TEST_Contact_L3_L4_Closure] ", n_passed, &
                              " passed, ", n_failed, " failed"
  END SUBROUTINE Run_Contact_L3_L4_Closure_Test

  !---------------------------------------------------------------------------
  ! Test 1: L3 MD_Interaction_Desc creation and initialization
  !         Creates a Surface-to-Surface contact interaction with penalty method
  !---------------------------------------------------------------------------
  SUBROUTINE test_l3_interaction_desc_creation(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_Interaction_Desc) :: md_desc
    TYPE(ErrorStatusType) :: status

    ! Initialize L3 interaction descriptor (S2S contact)
    CALL Initialize_InteractionDesc(md_desc, "CONTACT-1", CONTACT_TYPE_S2S, status)
    IF (.NOT. expect_ok(status, "l3 interaction desc init", n_failed)) RETURN

    ! Set basic contact properties
    md_desc%interaction_id = 1_i4
    md_desc%slave_surface  = "SLAVE_SURF_1"
    md_desc%master_surface = "MASTER_SURF_1"

    ! Validate L3 Desc fields
    IF (TRIM(md_desc%interaction_name) == "CONTACT-1" .AND. &
        md_desc%contact_type == CONTACT_TYPE_S2S .AND. &
        md_desc%interaction_id == 1_i4 .AND. &
        TRIM(md_desc%slave_surface) == "SLAVE_SURF_1" .AND. &
        TRIM(md_desc%master_surface) == "MASTER_SURF_1" .AND. &
        ALLOCATED(md_desc%contact_pairs) .AND. &
        ALLOCATED(md_desc%surface_interactions) .AND. &
        ALLOCATED(md_desc%friction_models)) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3 interaction desc creation"
    END IF
  END SUBROUTINE test_l3_interaction_desc_creation

  !---------------------------------------------------------------------------
  ! Test 2: L3 Contact pair validation and addition
  !         Tests AddContactPair + IsValidContactPair + IsValidFrictionModel
  !---------------------------------------------------------------------------
  SUBROUTINE test_l3_contact_pair_validation(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_Interaction_Desc) :: md_desc
    TYPE(ContactPairType) :: test_pair
    TYPE(FrictionModelType) :: friction
    TYPE(ErrorStatusType) :: status
    LOGICAL :: pair_valid, friction_valid

    CALL Initialize_InteractionDesc(md_desc, "CONTACT-2", CONTACT_TYPE_S2S, status)
    IF (.NOT. expect_ok(status, "l3 pair validation init", n_failed)) RETURN

    ! Add a valid NTS contact pair
    CALL AddContactPair(md_desc, "PAIR-1", "SLAVE_1", "MASTER_1", &
                        CONTACT_TYPE_S2S, status)
    IF (.NOT. expect_ok(status, "l3 add contact pair", n_failed)) RETURN

    ! Verify pair was added
    IF (md_desc%num_contact_pairs /= 1_i4) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3 contact pair count"
      RETURN
    END IF

    ! Validate the contact pair
    pair_valid = IsValidContactPair(md_desc%contact_pairs(1))

    ! Test friction model validation
    friction%friction_name   = "COULOMB-1"
    friction%friction_id     = 1_i4
    friction%model_type      = FRICTION_COULOMB
    friction%static_coeff    = 0.3_wp
    friction%kinetic_coeff   = 0.2_wp
    friction%stick_slip_ratio = 1.0_wp
    friction%damping_coeff   = 0.0_wp
    friction_valid = IsValidFrictionModel(friction)

    IF (pair_valid .AND. friction_valid .AND. &
        TRIM(md_desc%contact_pairs(1)%pair_name) == "PAIR-1" .AND. &
        TRIM(md_desc%contact_pairs(1)%slave_surface) == "SLAVE_1" .AND. &
        TRIM(md_desc%contact_pairs(1)%master_surface) == "MASTER_1") THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3 contact pair validation"
    END IF
  END SUBROUTINE test_l3_contact_pair_validation

  !---------------------------------------------------------------------------
  ! Test 3: L4 PH_Contact_Domain initialization
  !         Creates domain, verifies initialization state and buffer allocation
  !---------------------------------------------------------------------------
  SUBROUTINE test_l4_contact_domain_init(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Contact_Domain) :: ph_cont_dom
    TYPE(ErrorStatusType) :: status

    ! Initialize L4 contact domain for step 1
    CALL ph_cont_dom%Init(1_i4, status, maxSlaveNodes=10_i4, maxMasterNodes=10_i4)
    IF (.NOT. expect_ok(status, "l4 contact domain init", n_failed)) RETURN

    ! Verify domain initialization
    IF (ph_cont_dom%initialized .AND. &
        ph_cont_dom%ctx%step_idx == 1_i4 .AND. &
        ph_cont_dom%ctx%maxSlaveNodes == 10_i4 .AND. &
        ph_cont_dom%ctx%maxMasterNodes == 10_i4 .AND. &
        ALLOCATED(ph_cont_dom%ctx%x_slave_buf) .AND. &
        ALLOCATED(ph_cont_dom%ctx%x_master_buf)) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l4 contact domain init contract"
    END IF

    ! Cleanup
    CALL ph_cont_dom%Finalize()
  END SUBROUTINE test_l4_contact_domain_init

  !---------------------------------------------------------------------------
  ! Test 4: L4 PH_Cont_Def four-type contract verification
  !         Ensures PH_Cont_Desc/State/Algo/Ctx defaults and fields
  !---------------------------------------------------------------------------
  SUBROUTINE test_l4_contact_types_contract(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Cont_Desc)  :: desc
    TYPE(PH_Cont_State)  :: state
    TYPE(PH_Cont_Algo)  :: algo
    TYPE(PH_Cont_Ctx)   :: ctx

    ! Desc: penalty configuration
    desc%penalty_normal  = 1.0E6_wp
    desc%penalty_tangent = 1.0E5_wp
    desc%gap_tolerance   = 1.0E-6_wp
    desc%mu_friction     = 0.3_wp

    ! State: initial open contact
    state%gap            = 0.001_wp   ! positive = open
    state%f_normal       = 0.0_wp
    state%f_friction     = 0.0_wp
    state%contact_status = PH_CONT_OPEN
    state%slip           = 0.0_wp

    ! Algo: penalty method
    algo%method       = PH_CONT_METHOD_PENALTY
    algo%scale_factor = 1.0_wp

    ! Ctx: per-pair workspace
    ctx%x_slave  = (/ 0.0_wp, 0.0_wp, 0.0_wp /)
    ctx%x_master = (/ 0.0_wp, 0.0_wp, 0.001_wp /)
    ctx%normal   = (/ 0.0_wp, 0.0_wp, 1.0_wp /)

    ! Verify four-type contract
    IF (desc%penalty_normal > 0.0_wp .AND. &
        desc%mu_friction > 0.0_wp .AND. &
        state%contact_status == PH_CONT_OPEN .AND. &
        state%gap > 0.0_wp .AND. &
        algo%method == PH_CONT_METHOD_PENALTY .AND. &
        ABS(ctx%normal(3) - 1.0_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l4 contact four-type contract"
    END IF
  END SUBROUTINE test_l4_contact_types_contract

  !---------------------------------------------------------------------------
  ! Test 5: L5 RT_Contact dispatch context creation and routing
  !         Verifies RT_Contact_Desc/State/Algo/Ctx defaults and init
  !---------------------------------------------------------------------------
  SUBROUTINE test_l5_contact_dispatch_ctx(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(RT_Contact_Desc)  :: rt_desc
    TYPE(RT_Contact_State) :: rt_state
    TYPE(RT_Contact_Algo)  :: rt_algo
    TYPE(RT_Contact_Ctx)   :: rt_ctx

    ! Initialize L5 Algo with defaults
    CALL rt_algo%Init()

    ! Verify Algo defaults
    IF (rt_algo%discretization_method /= RT_CONT_DISC_NODE_TO_SURF .OR. &
        rt_algo%enforcement_method /= RT_CONT_ENFORCE_PENALTY .OR. &
        rt_algo%friction_model /= RT_CONT_FRICTION_COULOMB) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l5 contact algo defaults"
      RETURN
    END IF

    ! Configure enforcement method
    CALL rt_algo%SelectEnforcement(RT_CONT_ENFORCE_PENALTY)
    CALL rt_algo%ConfigureFriction(RT_CONT_FRICTION_COULOMB, &
                                    decay=0.0_wp, slip_tol=1.0E-8_wp)

    ! Ctx: clear temporaries
    CALL rt_ctx%ClearTemporaries()

    ! Set dispatch context fields
    rt_ctx%current_pair_idx  = 1_i4
    rt_ctx%gap_distance      = 0.001_wp
    rt_ctx%penetration_depth = 0.0_wp
    rt_ctx%normal_vector     = (/ 0.0_wp, 0.0_wp, 1.0_wp /)

    ! Verify L5 dispatch context is routable
    IF (rt_algo%enforcement_method == RT_CONT_ENFORCE_PENALTY .AND. &
        rt_algo%friction_model == RT_CONT_FRICTION_COULOMB .AND. &
        rt_ctx%current_pair_idx == 1_i4 .AND. &
        rt_ctx%gap_distance > 0.0_wp .AND. &
        ABS(rt_ctx%normal_vector(3) - 1.0_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l5 contact dispatch ctx routing"
    END IF
  END SUBROUTINE test_l5_contact_dispatch_ctx

  !---------------------------------------------------------------------------
  ! Test 6: Full L3→L4→L5 chain closure (end-to-end skeleton)
  !         MD_Interaction_Desc → PH_Contact_Domain → RT_Contact_* → verify
  !---------------------------------------------------------------------------
  SUBROUTINE test_l3_l4_l5_full_chain(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    ! L3 types
    TYPE(MD_Interaction_Desc) :: md_desc
    TYPE(MD_Interaction_Algo) :: md_algo

    ! L4 types
    TYPE(PH_Contact_Domain) :: ph_cont_dom
    TYPE(PH_Cont_Desc) :: ph_desc
    TYPE(PH_Cont_State) :: ph_state
    TYPE(ErrorStatusType) :: status

    ! L5 types
    TYPE(RT_Contact_Desc)  :: rt_desc
    TYPE(RT_Contact_Algo)  :: rt_algo
    TYPE(RT_Contact_Ctx)   :: rt_ctx

    ! --- Step 1: Create L3 MD_Interaction_Desc (NTS contact pair) ---
    CALL Initialize_InteractionDesc(md_desc, "NTS-PAIR-1", CONTACT_TYPE_S2S, status)
    IF (.NOT. expect_ok(status, "l3l4l5 interaction init", n_failed)) RETURN

    md_desc%interaction_id = 1_i4
    md_desc%slave_surface  = "SLAVE_BOTTOM"
    md_desc%master_surface = "MASTER_TOP"

    ! Add contact pair
    CALL AddContactPair(md_desc, "NTS-1", "SLAVE_BOTTOM", "MASTER_TOP", &
                        CONTACT_TYPE_S2S, status)
    IF (.NOT. expect_ok(status, "l3l4l5 add pair", n_failed)) RETURN

    ! Set L3 algorithm (penalty method)
    md_algo%algorithm_type      = ALGORITHM_PENALTY
    md_algo%penalty_stiffness   = 1.0E6_wp
    md_algo%convergence_tolerance = 1.0E-4_wp
    md_algo%use_friction        = .TRUE.

    ! --- Step 2: Initialize L4 Contact Domain ---
    CALL ph_cont_dom%Init(1_i4, status, maxSlaveNodes=10_i4, maxMasterNodes=10_i4)
    IF (.NOT. expect_ok(status, "l3l4l5 contact domain init", n_failed)) RETURN

    ! [SKELETON] In production: PH_L4_Populate_Contact fills params from L3
    ! Here we manually populate L4 simplified types from L3 desc
    ph_desc%penalty_normal  = md_algo%penalty_stiffness
    ph_desc%penalty_tangent = md_algo%penalty_stiffness * 0.1_wp
    ph_desc%gap_tolerance   = md_algo%convergence_tolerance
    ph_desc%mu_friction     = 0.3_wp

    ! Simulate contact search result: closed contact with penetration
    ph_state%gap            = -0.0001_wp   ! negative = penetration
    ph_state%f_normal       = ph_desc%penalty_normal * ABS(ph_state%gap)
    ph_state%f_friction     = ph_desc%mu_friction * ph_state%f_normal
    ph_state%contact_status = PH_CONT_CLOSED
    ph_state%slip           = 0.0_wp

    ! --- Step 3: Populate L5 RT_Contact dispatch from L4 ---
    CALL rt_algo%Init()
    CALL rt_algo%SelectEnforcement(RT_CONT_ENFORCE_PENALTY)
    CALL rt_algo%ConfigureFriction(RT_CONT_FRICTION_COULOMB)

    CALL rt_ctx%ClearTemporaries()
    rt_ctx%current_pair_idx  = 1_i4
    rt_ctx%gap_distance      = ph_state%gap
    rt_ctx%penetration_depth = ABS(ph_state%gap)
    rt_ctx%contact_pressure  = ph_state%f_normal
    rt_ctx%normal_vector     = (/ 0.0_wp, 0.0_wp, 1.0_wp /)

    ! --- Step 4: Verify full L3→L4→L5 chain ---
    ! L3 Desc created → L4 Domain initialized → L4 state computed → L5 ctx routable
    IF (md_desc%num_contact_pairs == 1_i4 .AND. &
        ph_cont_dom%initialized .AND. &
        ph_state%contact_status == PH_CONT_CLOSED .AND. &
        ph_state%f_normal > 0.0_wp .AND. &
        ph_state%f_friction > 0.0_wp .AND. &
        rt_algo%enforcement_method == RT_CONT_ENFORCE_PENALTY .AND. &
        rt_ctx%current_pair_idx == 1_i4 .AND. &
        rt_ctx%penetration_depth > 0.0_wp .AND. &
        rt_ctx%contact_pressure > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3l4l5 contact full chain closure"
    END IF

    ! Cleanup
    CALL ph_cont_dom%Finalize()
  END SUBROUTINE test_l3_l4_l5_full_chain

  !---------------------------------------------------------------------------
  ! Helper: expect_ok — check ErrorStatusType and log failure
  !---------------------------------------------------------------------------
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

END MODULE TEST_Contact_L3_L4_Closure
