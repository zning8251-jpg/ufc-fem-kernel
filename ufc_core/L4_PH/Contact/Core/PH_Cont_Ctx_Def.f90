! MODULE: PH_Cont_Ctx_Def
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Ctx
! BRIEF:  Contact computation context (PH_ContactCtx) + time descriptor + Arg bundles
!
! Four-Type: PH_ContactCtx (Ctx), PH_Cont_Time_Desc (Desc-fragment)
!
! Theory:
!   KKT: g>=0, lambda>=0, lambda*g=0
!   AugLag L_rho, Coulomb |tau|<=mu*sigma_n
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Contact | Role:Ctx | FuncSet?Context | 热路�?�?!>>> Basis:PLAN/04_实施路线�任务规�?实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md ��?5.1�L4 PH_ContactCtx?!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md

MODULE PH_Cont_Ctx_Def
!> [CORE] Contact Context Module
!> Theory: KKT (g>=0, lambda>=0, lambda*g=0), AugLag L_rho, Coulomb |tau|<=mu*sigma_n
!> Status: Production | Last verified: 2026-02-28
    USE IF_Base_Def, ONLY: ZERO, ONE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC TYPES AND SUBROUTINES
    ! ==========================================================================
    PUBLIC :: PH_ContactCtx
    PUBLIC :: PH_Cont_Time_Desc
    PUBLIC :: PH_Cont_Ctx_Init_Arg
    PUBLIC :: PH_Cont_Ctx_Clear_Arg
    PUBLIC :: PH_Cont_Ctx_Copy_Arg
    PUBLIC :: PH_Cont_Ctx_Valid_Arg
    PUBLIC :: PH_Cont_Ctx_Init
    PUBLIC :: PH_Cont_Ctx_Clear
    PUBLIC :: PH_Cont_Ctx_Copy
    PUBLIC :: PH_Cont_Ctx_Valid
    PUBLIC :: PH_Cont_Ctx_Init_Structured
    PUBLIC :: PH_Cont_Ctx_Clear_Structured
    PUBLIC :: PH_Cont_Ctx_Copy_Structured
    PUBLIC :: PH_Cont_Ctx_Valid_Structured

    ! ==========================================================================
    ! CONTACT CONTEXT TYPE (Ctx - Context/Control)
    ! ==========================================================================

    !> @brief Contact computation context type
    TYPE, PUBLIC :: PH_ContactCtx
        ! ========== three-step indexing (L3→L5 ) ==========
        INTEGER(i4) :: step_idx = 0_i4   ! Step
        INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
        ! ========== Contact Pair Identification ==========
        INTEGER(i4) :: contact_pair_id = 0
        INTEGER(i4) :: slave_surface_id = 0
        INTEGER(i4) :: master_surface_id = 0
        CHARACTER(LEN=64) :: contact_algorithm = "Penalty"  ! Penalty, Lagrange, Augmented

        ! ========== Contact State and Geometry ==========
        INTEGER(i4) :: contact_state = 0  ! 0=separate, 1=contact, 2=sticking, 3=sliding, 4=welded
        REAL(wp) :: gap = ZERO
        REAL(wp) :: penetration = ZERO
        REAL(wp) :: previous_gap = ZERO
        REAL(wp), ALLOCATABLE :: normal_vector(:)    ! (3) - Unit normal
        REAL(wp), ALLOCATABLE :: tangent_vector1(:)  ! (3) - First tangent
        REAL(wp), ALLOCATABLE :: tangent_vector2(:)  ! (3) - Second tangent

        ! ========== Contact Forces and Tractions ==========
        REAL(wp), ALLOCATABLE :: normal_force(:)     ! (3) - Normal force vector
        REAL(wp), ALLOCATABLE :: friction_force(:)   ! (3) - Friction force vector
        REAL(wp) :: normal_force_magnitude = ZERO
        REAL(wp) :: friction_force_magnitude = ZERO
        REAL(wp), ALLOCATABLE :: contact_traction(:)  ! (3) - Total traction
        REAL(wp) :: contact_pressure = ZERO
        REAL(wp) :: shear_traction = ZERO

        ! ========== Contact Stiffness and Compliance ==========
        REAL(wp) :: penalty_parameter = 1.0e6_wp
        REAL(wp) :: adaptive_penalty_factor = 1.0_wp
        REAL(wp), ALLOCATABLE :: K_contact(:,:)      ! (3,3) - Contact stiffness matrix
        REAL(wp), ALLOCATABLE :: C_contact(:,:)      ! (3,3) - Contact compliance matrix
        REAL(wp) :: normal_stiffness = ZERO
        REAL(wp) :: tangential_stiffness = ZERO
        LOGICAL :: stiffness_adaptation = .TRUE.

        ! ========== Advanced Friction Model ==========
        INTEGER(i4) :: friction_model = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent
        REAL(wp) :: friction_coefficient = ZERO
        REAL(wp) :: static_friction_coeff = ZERO
        REAL(wp) :: dynamic_friction_coeff = ZERO
        REAL(wp), ALLOCATABLE :: slip_velocity(:)     ! (3) - Slip velocity
        REAL(wp) :: slip_magnitude = ZERO
        REAL(wp) :: accumulated_slip = ZERO
        REAL(wp) :: slip_rate = ZERO

        ! ========== Contact Area and Pressure Distribution ==========
        REAL(wp) :: contact_area = ZERO

        ! ========== Thermal Contact Parameters ==========
        LOGICAL :: thermal_contact_enabled = .FALSE.
        REAL(wp) :: thermal_contact_conductance = ZERO
        REAL(wp) :: thermal_gap_conductance = ZERO
        REAL(wp) :: heat_flux_contact = ZERO
        REAL(wp) :: interface_temperature = ZERO
        REAL(wp) :: temperature_dependence = ZERO

        ! ========== Dynamic Contact Parameters ==========
        LOGICAL :: dynamic_contact_enabled = .FALSE.
        REAL(wp) :: impact_velocity = ZERO
        REAL(wp) :: effective_mass = ZERO
        REAL(wp) :: contact_damping = ZERO
        REAL(wp) :: restitution_coefficient = ZERO

        ! ========== Convergence and Algorithm Ctrl ==========
        REAL(wp) :: residual_norm = ZERO
        REAL(wp) :: tolerance = 1.0e-6_wp
        REAL(wp) :: relative_tolerance = 1.0e-6_wp
        INTEGER(i4) :: iteration_count = 0
        INTEGER(i4) :: max_iterations = 50
        LOGICAL :: converged = .FALSE.
        REAL(wp) :: convergence_rate = ZERO
        CHARACTER(LEN=100) :: convergence_status = "Not Started"

        ! ========== Error Estimation and Quality Ctrl ==========
        REAL(wp) :: error_estimate = ZERO
        REAL(wp) :: error_bound = ZERO
        INTEGER(i4) :: error_indicator = 0
        LOGICAL :: quality_control_passed = .TRUE.

        ! ========== Flags and Status ==========
        LOGICAL :: is_initialized = .FALSE.
        LOGICAL :: is_active = .TRUE.
        LOGICAL :: requires_update = .TRUE.
        INTEGER(i4) :: contact_history_count = 0

        ! ========== AP-8 Warm-path buffers (pre-allocated in Init) ==========
        REAL(wp), ALLOCATABLE :: penetration_depth_buf(:)  ! (max_surfaces) penetration per face
        INTEGER(i4), ALLOCATABLE :: collision_ids_buf(:)   ! BVH_Query work buffer
        INTEGER(i4), ALLOCATABLE :: nearby_ids_buf(:)       ! SpatialHash_Query work buffer
        INTEGER(i4) :: max_penetration_buf = 0
        INTEGER(i4) :: max_collision_buf = 0
        INTEGER(i4) :: max_nearby_buf = 0

    END TYPE PH_ContactCtx

    ! ==========================================================================
    ! DESC TYPE (Description/Configuration)
    ! ==========================================================================

    !> @brief Time-integration descriptor for contact (??t etc.)
    TYPE, PUBLIC :: PH_Cont_Time_Desc
        REAL(wp) :: dt = 0.0_wp
    END TYPE PH_Cont_Time_Desc

    ! ==========================================================================
    ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
    ! ==========================================================================

    !> @brief Input structure for contact context initialization

    !> @brief Output structure for contact context initialization
  TYPE, PUBLIC :: PH_Cont_Ctx_Init_Arg
    INTEGER(i4) :: contact_pair_id                   ! [IN]
    INTEGER(i4) :: slave_surface_id                   ! [IN]
    INTEGER(i4) :: master_surface_id                   ! [IN]
    REAL(wp) :: penalty_parameter                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    TYPE(PH_ContactCtx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Init_Arg


    !> @brief Input structure for clearing contact context

    !> @brief Output structure for clearing contact context
  TYPE, PUBLIC :: PH_Cont_Ctx_Clear_Arg
    TYPE(PH_ContactCtx) :: ctx                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Clear_Arg


    !> @brief Input structure for copying contact context

    !> @brief Output structure for copying contact context
  TYPE, PUBLIC :: PH_Cont_Ctx_Copy_Arg
    TYPE(PH_ContactCtx) :: ctx_src                   ! [IN]
    TYPE(PH_ContactCtx) :: ctx_dst                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Copy_Arg


    !> @brief Input structure for validating contact context

    !> @brief Output structure for validating contact context
  TYPE, PUBLIC :: PH_Cont_Ctx_Valid_Arg
    TYPE(PH_ContactCtx) :: ctx                   ! [IN]
    LOGICAL :: is_valid                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Valid_Arg


CONTAINS

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Init
    ! Purpose: Initialize contact context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Init(ctx, contact_pair_id, &
                                       slave_surface_id, master_surface_id, &
                                       penalty_parameter, friction_coeff, status, &
                                       max_penetration_buf, max_collision_buf, max_nearby_buf, &
                                       step_idx, incr_idx)
        TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
        INTEGER(i4), INTENT(IN) :: contact_pair_id
        INTEGER(i4), INTENT(IN) :: slave_surface_id, master_surface_id
        REAL(wp), INTENT(IN) :: penalty_parameter, friction_coeff
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_penetration_buf, max_collision_buf, max_nearby_buf
        INTEGER(i4), INTENT(IN), OPTIONAL :: step_idx, incr_idx
        INTEGER(i4) :: mp, mc, mn

        CALL init_error_status(status)

        ! AP-8: Buffer sizes (defaults for warm-path pre-allocation)
        mp = 2048
        mc = 4096
        mn = 256
        IF (PRESENT(max_penetration_buf)) mp = MAX(1, max_penetration_buf)
        IF (PRESENT(max_collision_buf))   mc = MAX(1, max_collision_buf)
        IF (PRESENT(max_nearby_buf))     mn = MAX(1, max_nearby_buf)

        ! Clear existing Ctx
        CALL PH_Cont_Ctx_Clear(ctx, status)

        ! Set basic properties
        ctx%contact_pair_id = contact_pair_id
        ctx%slave_surface_id = slave_surface_id
        ctx%master_surface_id = master_surface_id
        ctx%penalty_parameter = penalty_parameter
        ctx%friction_coefficient = friction_coeff
        IF (PRESENT(step_idx)) ctx%inc%step_idx = step_idx
        IF (PRESENT(incr_idx)) ctx%inc%incr_idx = incr_idx

        ! Allocate arrays
        ALLOCATE(ctx%normal_vector(3))
        ALLOCATE(ctx%normal_force(3))
        ALLOCATE(ctx%friction_force(3))
        ALLOCATE(ctx%slip_velocity(3))
        ALLOCATE(ctx%K_contact(3, 3))
        ALLOCATE(ctx%C_contact(3, 3))
        ALLOCATE(ctx%contact_traction(3))
        ALLOCATE(ctx%tangent_vector1(3))
        ALLOCATE(ctx%tangent_vector2(3))

        ! Init arrays
        ctx%normal_vector = [ZERO, ZERO, ONE]
        ctx%normal_force = ZERO
        ctx%friction_force = ZERO
        ctx%slip_velocity = ZERO
        ctx%K_contact = ZERO
        ctx%C_contact = ZERO
        ctx%contact_traction = ZERO
        ctx%tangent_vector1 = [ONE, ZERO, ZERO]
        ctx%tangent_vector2 = [ZERO, ONE, ZERO]

        ! AP-8: Pre-allocate warm-path buffers (cold path)
        ALLOCATE(ctx%penetration_depth_buf(mp))
        ALLOCATE(ctx%collision_ids_buf(mc))
        ALLOCATE(ctx%nearby_ids_buf(mn))
        ctx%penetration_depth_buf = ZERO
        ctx%collision_ids_buf = 0
        ctx%nearby_ids_buf = 0
        ctx%max_penetration_buf = mp
        ctx%max_collision_buf = mc
        ctx%max_nearby_buf = mn

        ctx%is_initialized = .TRUE.
        ctx%contact_state = 0

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Cont_Ctx_Init

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Init_Structured
    ! Purpose: Initialize contact context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Init_Structured(arg)
        TYPE(PH_Cont_Ctx_Init_Arg), INTENT(INOUT) :: arg

        CALL init_error_status(arg%status)

        CALL PH_Cont_Ctx_Init(arg%ctx, arg%contact_pair_id, &
                                    arg%slave_surface_id, arg%master_surface_id, &
                                    arg%penalty_parameter, arg%friction_coeff, arg%status, &
                                    arg%max_penetration_buf, arg%max_collision_buf, arg%max_nearby_buf)

    END SUBROUTINE PH_Cont_Ctx_Init_Structured

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Clear
    ! Purpose: Clear contact context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Clear(ctx, status)
        TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Deallocate arrays
        IF (ALLOCATED(ctx%normal_vector)) DEALLOCATE(ctx%normal_vector)
        IF (ALLOCATED(ctx%normal_force)) DEALLOCATE(ctx%normal_force)
        IF (ALLOCATED(ctx%friction_force)) DEALLOCATE(ctx%friction_force)
        IF (ALLOCATED(ctx%slip_velocity)) DEALLOCATE(ctx%slip_velocity)
        IF (ALLOCATED(ctx%K_contact)) DEALLOCATE(ctx%K_contact)
        IF (ALLOCATED(ctx%C_contact)) DEALLOCATE(ctx%C_contact)
        IF (ALLOCATED(ctx%contact_traction)) DEALLOCATE(ctx%contact_traction)
        IF (ALLOCATED(ctx%tangent_vector1)) DEALLOCATE(ctx%tangent_vector1)
        IF (ALLOCATED(ctx%tangent_vector2)) DEALLOCATE(ctx%tangent_vector2)
        IF (ALLOCATED(ctx%penetration_depth_buf)) DEALLOCATE(ctx%penetration_depth_buf)
        IF (ALLOCATED(ctx%collision_ids_buf)) DEALLOCATE(ctx%collision_ids_buf)
        IF (ALLOCATED(ctx%nearby_ids_buf)) DEALLOCATE(ctx%nearby_ids_buf)

        ! Reset flags
        ctx%is_initialized = .FALSE.
        ctx%contact_pair_id = 0
        ctx%contact_state = 0
        ctx%is_active = .TRUE.
        ctx%requires_update = .TRUE.

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Cont_Ctx_Clear

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Clear_Structured
    ! Purpose: Clear contact context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Clear_Structured(arg)
        TYPE(PH_Cont_Ctx_Clear_Arg), INTENT(INOUT) :: arg

        CALL init_error_status(arg%status)

        arg%ctx = arg%ctx
        CALL PH_Cont_Ctx_Clear(arg%ctx, arg%status)

    END SUBROUTINE PH_Cont_Ctx_Clear_Structured

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Copy
    ! Purpose: Copy contact context
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Copy(ctx_src, ctx_dst, status)
        TYPE(PH_ContactCtx), INTENT(IN) :: ctx_src
        TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx_dst
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Clear destination
        CALL PH_Cont_Ctx_Clear(ctx_dst, status)

        ! Copy scalar values
        ctx_dst%contact_pair_id = ctx_src%contact_pair_id
        ctx_dst%slave_surface_id = ctx_src%slave_surface_id
        ctx_dst%master_surface_id = ctx_src%master_surface_id
        ctx_dst%contact_algorithm = ctx_src%contact_algorithm
        ctx_dst%contact_state = ctx_src%contact_state
        ctx_dst%gap = ctx_src%gap
        ctx_dst%penetration = ctx_src%penetration
        ctx_dst%previous_gap = ctx_src%previous_gap
        ctx_dst%penalty_parameter = ctx_src%penalty_parameter
        ctx_dst%adaptive_penalty_factor = ctx_src%adaptive_penalty_factor
        ctx_dst%normal_stiffness = ctx_src%normal_stiffness
        ctx_dst%tangential_stiffness = ctx_src%tangential_stiffness
        ctx_dst%stiffness_adaptation = ctx_src%stiffness_adaptation
        ctx_dst%friction_model = ctx_src%friction_model
        ctx_dst%friction_coefficient = ctx_src%friction_coefficient
        ctx_dst%static_friction_coeff = ctx_src%static_friction_coeff
        ctx_dst%dynamic_friction_coeff = ctx_src%dynamic_friction_coeff
        ctx_dst%slip_magnitude = ctx_src%slip_magnitude
        ctx_dst%accumulated_slip = ctx_src%accumulated_slip
        ctx_dst%slip_rate = ctx_src%slip_rate
        ctx_dst%contact_area = ctx_src%contact_area
        ctx_dst%residual_norm = ctx_src%residual_norm
        ctx_dst%tolerance = ctx_src%tolerance
        ctx_dst%relative_tolerance = ctx_src%relative_tolerance
        ctx_dst%iteration_count = ctx_src%iteration_count
        ctx_dst%max_iterations = ctx_src%max_iterations
        ctx_dst%converged = ctx_src%converged
        ctx_dst%convergence_rate = ctx_src%convergence_rate
        ctx_dst%convergence_status = ctx_src%convergence_status
        ctx_dst%error_estimate = ctx_src%error_estimate
        ctx_dst%error_bound = ctx_src%error_bound
        ctx_dst%error_indicator = ctx_src%error_indicator
        ctx_dst%quality_control_passed = ctx_src%quality_control_passed
        ctx_dst%is_initialized = ctx_src%is_initialized
        ctx_dst%is_active = ctx_src%is_active
        ctx_dst%requires_update = ctx_src%requires_update
        ctx_dst%contact_history_count = ctx_src%contact_history_count
        ctx_dst%normal_force_magnitude = ctx_src%normal_force_magnitude
        ctx_dst%friction_force_magnitude = ctx_src%friction_force_magnitude
        ctx_dst%contact_pressure = ctx_src%contact_pressure
        ctx_dst%shear_traction = ctx_src%shear_traction
        ctx_dst%max_penetration_buf = ctx_src%max_penetration_buf
        ctx_dst%max_collision_buf = ctx_src%max_collision_buf
        ctx_dst%max_nearby_buf = ctx_src%max_nearby_buf

        ! Copy arrays
        IF (ALLOCATED(ctx_src%normal_vector)) THEN
            ALLOCATE(ctx_dst%normal_vector(SIZE(ctx_src%normal_vector)))
            ctx_dst%normal_vector = ctx_src%normal_vector
        END IF

        IF (ALLOCATED(ctx_src%normal_force)) THEN
            ALLOCATE(ctx_dst%normal_force(SIZE(ctx_src%normal_force)))
            ctx_dst%normal_force = ctx_src%normal_force
        END IF

        IF (ALLOCATED(ctx_src%friction_force)) THEN
            ALLOCATE(ctx_dst%friction_force(SIZE(ctx_src%friction_force)))
            ctx_dst%friction_force = ctx_src%friction_force
        END IF

        IF (ALLOCATED(ctx_src%slip_velocity)) THEN
            ALLOCATE(ctx_dst%slip_velocity(SIZE(ctx_src%slip_velocity)))
            ctx_dst%slip_velocity = ctx_src%slip_velocity
        END IF

        IF (ALLOCATED(ctx_src%K_contact)) THEN
            ALLOCATE(ctx_dst%K_contact(SIZE(ctx_src%K_contact,1), SIZE(ctx_src%K_contact,2)))
            ctx_dst%K_contact = ctx_src%K_contact
        END IF

        IF (ALLOCATED(ctx_src%C_contact)) THEN
            ALLOCATE(ctx_dst%C_contact(SIZE(ctx_src%C_contact,1), SIZE(ctx_src%C_contact,2)))
            ctx_dst%C_contact = ctx_src%C_contact
        END IF

        IF (ALLOCATED(ctx_src%contact_traction)) THEN
            ALLOCATE(ctx_dst%contact_traction(SIZE(ctx_src%contact_traction)))
            ctx_dst%contact_traction = ctx_src%contact_traction
        END IF

        IF (ALLOCATED(ctx_src%tangent_vector1)) THEN
            ALLOCATE(ctx_dst%tangent_vector1(SIZE(ctx_src%tangent_vector1)))
            ctx_dst%tangent_vector1 = ctx_src%tangent_vector1
        END IF

        IF (ALLOCATED(ctx_src%tangent_vector2)) THEN
            ALLOCATE(ctx_dst%tangent_vector2(SIZE(ctx_src%tangent_vector2)))
            ctx_dst%tangent_vector2 = ctx_src%tangent_vector2
        END IF

        IF (ALLOCATED(ctx_src%penetration_depth_buf)) THEN
            ALLOCATE(ctx_dst%penetration_depth_buf(SIZE(ctx_src%penetration_depth_buf)))
            ctx_dst%penetration_depth_buf = ctx_src%penetration_depth_buf
        END IF
        IF (ALLOCATED(ctx_src%collision_ids_buf)) THEN
            ALLOCATE(ctx_dst%collision_ids_buf(SIZE(ctx_src%collision_ids_buf)))
            ctx_dst%collision_ids_buf = ctx_src%collision_ids_buf
        END IF
        IF (ALLOCATED(ctx_src%nearby_ids_buf)) THEN
            ALLOCATE(ctx_dst%nearby_ids_buf(SIZE(ctx_src%nearby_ids_buf)))
            ctx_dst%nearby_ids_buf = ctx_src%nearby_ids_buf
        END IF

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Cont_Ctx_Copy

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Copy_Structured
    ! Purpose: Copy contact context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Copy_Structured(arg)
        TYPE(PH_Cont_Ctx_Copy_Arg), INTENT(INOUT) :: arg

        CALL init_error_status(arg%status)

        CALL PH_Cont_Ctx_Copy(arg%ctx_src, arg%ctx_dst, arg%status)

    END SUBROUTINE PH_Cont_Ctx_Copy_Structured

    !-----------------------------------------------------------------------------
    ! Function: PH_Cont_Ctx_Valid
    ! Purpose: Validate contact context
    !-----------------------------------------------------------------------------
    FUNCTION PH_Cont_Ctx_Valid(ctx) RESULT(is_valid)
        TYPE(PH_ContactCtx), INTENT(IN) :: ctx
        LOGICAL :: is_valid

        is_valid = .TRUE.

        ! Check initialization
        IF (.NOT. ctx%is_initialized) THEN
            is_valid = .FALSE.
            RETURN
        END IF

        ! Check required arrays
        IF (.NOT. ALLOCATED(ctx%normal_vector)) THEN
            is_valid = .FALSE.
            RETURN
        END IF

        IF (.NOT. ALLOCATED(ctx%normal_force)) THEN
            is_valid = .FALSE.
            RETURN
        END IF

        IF (.NOT. ALLOCATED(ctx%K_contact)) THEN
            is_valid = .FALSE.
            RETURN
        END IF

        ! Check penalty parameter
        IF (ctx%penalty_parameter <= ZERO) THEN
            is_valid = .FALSE.
            RETURN
        END IF

    END FUNCTION PH_Cont_Ctx_Valid

    !-----------------------------------------------------------------------------
    ! Subroutine: PH_Cont_Ctx_Valid_Structured
    ! Purpose: Validate contact context using structured interface
    ! Interface: Structured (In/Out types)
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_Cont_Ctx_Valid_Structured(arg)
        TYPE(PH_Cont_Ctx_Valid_Arg), INTENT(INOUT) :: arg

        CALL init_error_status(arg%status)

        arg%is_valid = PH_Cont_Ctx_Valid(arg%ctx)

        IF (.NOT. arg%is_valid) THEN
            arg%status%status_code = IF_STATUS_INVALID
            arg%status%message = 'PH_Cont_Ctx_Valid_Structured: Context validation failed'
        ELSE
            arg%status%status_code = IF_STATUS_OK
        END IF

    END SUBROUTINE PH_Cont_Ctx_Valid_Structured

END MODULE PH_Cont_Ctx_Def