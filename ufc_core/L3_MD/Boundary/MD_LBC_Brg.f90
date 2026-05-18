!===============================================================================
! MODULE:  MD_LBC_Brg
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Brg
! BRIEF:   LoadBC API bridge types — UF_BCDef/CLoad/DLoad/BodyForce/Thermal/Mgr.
!===============================================================================

MODULE MD_LBC_Brg
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE MD_LBC_Domain, ONLY: LOAD_CLOAD, LOAD_DLOAD, LOAD_PRESSURE, &
                         LOAD_BODY_FORCE, LOAD_GRAVITY, LOAD_CENTRIFUGAL, &
                         LOAD_TEMPERATURE
    USE MD_BC_Def, ONLY: MD_BC_Base_Desc, MD_BC_Base_State, MD_BC_Base_Algo, &
                          MD_BC_UPOT_Desc, MD_BC_UTEMP_Desc, MD_BC_UMASFL_Desc, &
                          MD_BC_DISP_Desc, MD_BC_Disp_Desc, MD_BC_Base_Ctx
    USE MD_Load_Def, ONLY: MD_Load_Base_Desc, MD_Load_Base_State, MD_Load_Base_Algo, &
                           MD_Load_DFLUX_Desc, MD_Load_FILM_Desc, MD_Load_HETVAL_Desc, &
                           MD_Load_UWAVE_Desc, MD_Load_DLOAD_Desc, MD_Load_Dist_Desc, &
                           MD_Load_Base_Ctx, MD_LoadBC_State, MD_LoadBC_Algo, MD_LoadBC_Ctx
    IMPLICIT NONE

    PRIVATE

    ! Local constants for load types not in MD_LBC_Domain
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_TRACTION    = 20_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_BODYFORCE   = LOAD_BODY_FORCE
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CORIOLIS    = 21_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CFLUX       = 22_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_DFLUX       = 23_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_SFILM       = 24_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_SRADIATE    = 25_i4
    
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_LOADBC_NAME = 64_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_LOADS_PER_STEP = 500_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_BCS_PER_STEP = 500_i4
    
    ! BC Types (Abaqus compatible)
    INTEGER(i4), PARAMETER, PUBLIC :: BC_DISPLACEMENT = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_VELOCITY = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ACCELERATION = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_TEMPERATURE = 11_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_PORE_PRESSURE = 12_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ELECTRIC_POTENTIAL = 21_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ENCASTRE = 101_i4   ! All DOFs fixed
    INTEGER(i4), PARAMETER, PUBLIC :: BC_PINNED = 102_i4     ! Translations fixed
    INTEGER(i4), PARAMETER, PUBLIC :: BC_XSYMM = 103_i4      ! X-symmetry
    INTEGER(i4), PARAMETER, PUBLIC :: BC_YSYMM = 104_i4      ! Y-symmetry
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ZSYMM = 105_i4      ! Z-symmetry
    INTEGER(i4), PARAMETER, PUBLIC :: BC_XASYMM = 106_i4     ! X-antisymmetry
    INTEGER(i4), PARAMETER, PUBLIC :: BC_YASYMM = 107_i4     ! Y-antisymmetry
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ZASYMM = 108_i4     ! Z-antisymmetry
    
    ! Load Types (Abaqus compatible)
    !   Load types: LOAD_CLOAD (concentrated), LOAD_DLOAD (distributed), LOAD_PRESSURE,
    !   LOAD_TRACTION, LOAD_BODYFORCE, LOAD_GRAVITY, LOAD_CENTRIFUGAL, LOAD_CORIOLIS,
    !   LOAD_CFLUX (concentrated flux), LOAD_DFLUX (distributed flux),
    !   LOAD_SFILM (surface convection), LOAD_SRADIATE (surface radiation) 
    
    ! Distribution type
    INTEGER(i4), PARAMETER, PUBLIC :: DIST_UNIFORM = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: DIST_USER = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: DIST_ANALYTICAL = 3_i4

    !--------------------------------------------------------------------------
    ! Re-export from MD_BC_Def (four-kind aligned)
    !--------------------------------------------------------------------------
    PUBLIC :: MD_BC_Base_Desc, MD_BC_Base_State, MD_BC_Base_Algo
    PUBLIC :: MD_BC_UPOT_Desc, MD_BC_UTEMP_Desc, MD_BC_UMASFL_Desc
    PUBLIC :: MD_BC_DISP_Desc, MD_BC_Disp_Desc, MD_BC_Base_Ctx

    !--------------------------------------------------------------------------
    ! Re-export from MD_Load_Def (four-kind aligned)
    !--------------------------------------------------------------------------
    PUBLIC :: MD_Load_Base_Desc, MD_Load_Base_State, MD_Load_Base_Algo
    PUBLIC :: MD_Load_DFLUX_Desc, MD_Load_FILM_Desc, MD_Load_HETVAL_Desc
    PUBLIC :: MD_Load_UWAVE_Desc, MD_Load_DLOAD_Desc, MD_Load_Dist_Desc
    PUBLIC :: MD_Load_Base_Ctx, MD_LoadBC_State, MD_LoadBC_Algo, MD_LoadBC_Ctx
    

    !---------------------------------------------------------------------------
    ! TYPE:  UF_BCDef
    ! KIND:  Desc
    ! DESC:  Boundary condition API descriptor — type, region, DOF range, value.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_BCDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        INTEGER(i4) :: bc_type = BC_DISPLACEMENT
        CHARACTER(LEN=MAX_LOADBC_NAME) :: region_name = ""
        INTEGER(i4) :: region_type = 0          ! 1=nset, 2=surface, 0=node_id
        INTEGER(i4) :: node_id = 0              ! Direct node ID referencing
        ! DOF specification (1-6 for mechanical)
        INTEGER(i4) :: dof_first = 1
        INTEGER(i4) :: dof_last = 1
        REAL(wp) :: magnitude = 0.0_wp
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: is_active = .TRUE.
        LOGICAL :: op_new = .TRUE.              ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => bc_init
        PROCEDURE :: set_displacement => bc_set_displacement
        PROCEDURE :: set_fixed => bc_set_fixed
        PROCEDURE :: set_symmetry => bc_set_symmetry
        PROCEDURE :: get_value_at_time => bc_get_value_at_time
        PROCEDURE :: print_info => bc_print_info
    END TYPE UF_BCDef
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_CLoadDef
    ! KIND:  Desc
    ! DESC:  Concentrated load API descriptor — node/nodeSet, DOF, magnitude.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_CLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""              ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: nset_name = ""         ! Node set name
        INTEGER(i4) :: node_id = 0                                ! Direct node ID
        INTEGER(i4) :: dof = 1                                    ! DOF direction
        REAL(wp) :: magnitude = 0.0_wp                            ! Load magnitude F_0

        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: follower = .FALSE.                              ! Follower force flag
        LOGICAL :: is_active = .TRUE.                              ! Active flag
        LOGICAL :: op_new = .TRUE.                                 ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => cload_init
        PROCEDURE :: set_value => cload_set_value
        PROCEDURE :: get_value_at_time => cload_get_value_at_time
        PROCEDURE :: print_info => cload_print_info
    END TYPE UF_CLoadDef

    !---------------------------------------------------------------------------
    ! TYPE:  CLoadDef_Init_In
    ! KIND:  Arg
    ! DESC:  Arg bundle for concentrated load Init — input parameters.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: CLoadDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: nset_name = ""
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: dof = 1
        REAL(wp) :: magnitude = 0.0_wp
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: follower = .FALSE.
    END TYPE CLoadDef_Init_In

    !---------------------------------------------------------------------------
    ! TYPE:  CLoadDef_Init_Out
    ! KIND:  Arg
    ! DESC:  Arg bundle for concentrated load Init — output status.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: CLoadDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE CLoadDef_Init_Out
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_DLoadDef
    ! KIND:  Desc
    ! DESC:  Distributed load API descriptor — surface, type, magnitude, direction.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_DLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""               ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""       ! Surface name
        INTEGER(i4) :: load_type = LOAD_PRESSURE                 ! Load type
        INTEGER(i4) :: distribution = DIST_UNIFORM                ! Distribution type
        REAL(wp) :: magnitude = 0.0_wp                           ! Load magnitude
        REAL(wp) :: direction(3) = [0.0_wp, 0.0_wp, 0.0_wp]     ! Direction vector
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: is_active = .TRUE.                             ! Active flag
        LOGICAL :: op_new = .TRUE.                                ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => dload_init
        PROCEDURE :: set_pressure => dload_set_pressure
        PROCEDURE :: set_traction => dload_set_traction
        PROCEDURE :: get_value_at_time => dload_get_value_at_time
        PROCEDURE :: print_info => dload_print_info
    END TYPE UF_DLoadDef

    !---------------------------------------------------------------------------
    ! TYPE:  DLoadDef_Init_In
    ! KIND:  Arg
    ! DESC:  Arg bundle for distributed load Init — input parameters.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: DLoadDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""
        INTEGER(i4) :: load_type = LOAD_PRESSURE
        INTEGER(i4) :: distribution = DIST_UNIFORM
        REAL(wp) :: magnitude = 0.0_wp
        REAL(wp) :: direction(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
    END TYPE DLoadDef_Init_In

    !---------------------------------------------------------------------------
    ! TYPE:  DLoadDef_Init_Out
    ! KIND:  Arg
    ! DESC:  Arg bundle for distributed load Init — output status.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: DLoadDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE DLoadDef_Init_Out
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_BodyForceDef
    ! KIND:  Desc
    ! DESC:  Body force API descriptor — gravity/centrifugal, components, axis.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_BodyForceDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""               ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: elset_name = ""         ! Element set name
        INTEGER(i4) :: load_type = LOAD_BODYFORCE                 ! Load type
        REAL(wp) :: components(3) = [0.0_wp, 0.0_wp, 0.0_wp]     ! Force components
        REAL(wp) :: omega = 0.0_wp                                ! Angular velocity
        REAL(wp) :: axis(3) = [0.0_wp, 0.0_wp, 1.0_wp]          ! Rotation axis
        REAL(wp) :: center(3) = [0.0_wp, 0.0_wp, 0.0_wp]        ! Center c
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: is_active = .TRUE.                             ! Active flag
    CONTAINS
        PROCEDURE :: init => bforce_init
        PROCEDURE :: set_gravity => bforce_set_gravity
        PROCEDURE :: set_centrifugal => bforce_set_centrifugal
        PROCEDURE :: print_info => bforce_print_info
    END TYPE UF_BodyForceDef

    !---------------------------------------------------------------------------
    ! TYPE:  BodyForceDef_Init_In
    ! KIND:  Arg
    ! DESC:  Arg bundle for body force Init — input parameters.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: BodyForceDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: elset_name = ""
        INTEGER(i4) :: load_type = LOAD_BODYFORCE
        REAL(wp) :: components(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        REAL(wp) :: omega = 0.0_wp
        REAL(wp) :: axis(3) = [0.0_wp, 0.0_wp, 1.0_wp]
        REAL(wp) :: center(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
    END TYPE BodyForceDef_Init_In

    !---------------------------------------------------------------------------
    ! TYPE:  BodyForceDef_Init_Out
    ! KIND:  Arg
    ! DESC:  Arg bundle for body force Init — output status.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: BodyForceDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE BodyForceDef_Init_Out
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_ThermalLoadDef
    ! KIND:  Desc
    ! DESC:  Thermal load API descriptor — convection/radiation/flux parameters.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ThermalLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""
        INTEGER(i4) :: load_type = LOAD_SFILM
        REAL(wp) :: film_coeff = 0.0_wp         ! Convection coefficient

        REAL(wp) :: sink_temp = 0.0_wp          ! Sink temperature
        REAL(wp) :: emissivity = 0.0_wp         ! Radiation emissivity
        REAL(wp) :: flux_magnitude = 0.0_wp     ! Heat flux
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: is_active = .TRUE.
    CONTAINS
        PROCEDURE :: init => thermal_init
        PROCEDURE :: set_convection => thermal_set_convection
        PROCEDURE :: set_radiation => thermal_set_radiation
        PROCEDURE :: set_flux => thermal_set_flux
        PROCEDURE :: print_info => thermal_print_info
    END TYPE UF_ThermalLoadDef
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_LoadBCManager
    ! KIND:  Ctx
    ! DESC:  LoadBC manager — aggregates all BC/load definitions for a step.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_LoadBCManager
        INTEGER(i4) :: num_bcs = 0
        INTEGER(i4) :: num_cloads = 0
        INTEGER(i4) :: num_dloads = 0
        INTEGER(i4) :: num_bforces = 0
        INTEGER(i4) :: num_thermal = 0
        TYPE(UF_BCDef), ALLOCATABLE :: bcs(:)
        TYPE(UF_CLoadDef), ALLOCATABLE :: cloads(:)
        TYPE(UF_DLoadDef), ALLOCATABLE :: dloads(:)
        TYPE(UF_BodyForceDef), ALLOCATABLE :: bforces(:)
        TYPE(UF_ThermalLoadDef), ALLOCATABLE :: thermals(:)
    CONTAINS
        PROCEDURE :: init => manager_init
        PROCEDURE :: add_bc => manager_add_bc
        PROCEDURE :: add_bc_simple => manager_add_bc_simple
        PROCEDURE :: add_cload => manager_add_cload
        PROCEDURE :: add_dload => manager_add_dload
        PROCEDURE :: add_bforce => manager_add_bforce
        PROCEDURE :: add_thermal => manager_add_thermal
        PROCEDURE :: get_bc => manager_get_bc
        PROCEDURE :: get_cload => manager_get_cload
        PROCEDURE :: deactivate_all => manager_deactivate_all
        PROCEDURE :: print_summary => manager_print_summary
        PROCEDURE :: destroy => manager_destroy
    END TYPE UF_LoadBCManager
    
CONTAINS

    !--------------------------------------------------------------------------
    ! BC Methods
    !--------------------------------------------------------------------------
    SUBROUTINE bc_init(this)
        CLASS(UF_BCDef), INTENT(INOUT) :: this
        this%name = ""
        this%bc_type = BC_DISPLACEMENT
        this%region_name = ""
        this%region_type = 0
        this%node_id = 0
        this%magnitude = 0.0_wp
        this%is_active = .TRUE.
    END SUBROUTINE bc_init
    
    SUBROUTINE bc_set_displacement(this, name, nset, dof1, dof2, value)
        CLASS(UF_BCDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, nset
        INTEGER(i4), INTENT(IN) :: dof1, dof2
        REAL(wp), INTENT(IN) :: value
        this%name = TRIM(name)
        this%region_name = TRIM(nset)
        this%region_type = 1
        this%bc_type = BC_DISPLACEMENT
        this%dof_first = dof1
        this%dof_last = dof2
        this%magnitude = value
    END SUBROUTINE bc_set_displacement
    
    SUBROUTINE bc_set_fixed(this, name, nset, bc_type)
        CLASS(UF_BCDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, nset
        INTEGER(i4), INTENT(IN) :: bc_type
        this%name = TRIM(name)
        this%region_name = TRIM(nset)
        this%region_type = 1
        this%bc_type = bc_type
        SELECT CASE(bc_type)
            CASE(BC_ENCASTRE)
                this%dof_first = 1
                this%dof_last = 6
            CASE(BC_PINNED)
                this%dof_first = 1
                this%dof_last = 3
            CASE DEFAULT
                this%dof_first = 1
                this%dof_last = 6
        END SELECT
        this%magnitude = 0.0_wp
    END SUBROUTINE bc_set_fixed
    
    SUBROUTINE bc_set_symmetry(this, name, nset, bc_type)
        CLASS(UF_BCDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, nset
        INTEGER(i4), INTENT(IN) :: bc_type
        this%name = TRIM(name)
        this%region_name = TRIM(nset)
        this%bc_type = bc_type
        this%magnitude = 0.0_wp
    END SUBROUTINE bc_set_symmetry
    
    FUNCTION bc_get_value_at_time(this, time, amp_value) RESULT(val)
        CLASS(UF_BCDef), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: time, amp_value
        REAL(wp) :: val
        val = this%magnitude * amp_value
    END FUNCTION bc_get_value_at_time
    
    SUBROUTINE bc_print_info(this, unit_num)
        CLASS(UF_BCDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  BC: ', TRIM(this%name)
        WRITE(unit_num, '(A,I3,A,I3,A,I3)') '    Type=', this%bc_type, &
            ', DOF=', this%dof_first, '-', this%dof_last
        WRITE(unit_num, '(A,ES12.4)') '    Magnitude=', this%magnitude
    END SUBROUTINE bc_print_info

    !--------------------------------------------------------------------------
    ! CLoad Methods
    !--------------------------------------------------------------------------
    !=============================================================================
    !> @brief Initialize concentrated load definition (legacy interface)
    !! @details Initializes concentrated load with default values
    !! @param[inout] this Concentrated load definition instance
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use CLoadDef_Init_In type to encapsulate all initialization parameters
    !=============================================================================
    SUBROUTINE cload_init(this)
        CLASS(UF_CLoadDef), INTENT(INOUT) :: this
        this%name = ""
        this%nset_name = ""
        this%node_id = 0
        this%dof = 1
        this%magnitude = 0.0_wp
        this%is_active = .TRUE.
    END SUBROUTINE cload_init
    
    !=============================================================================
    !> @brief Set concentrated load value (legacy interface)
    !! @details Sets load name, node set, DOF, and magnitude F_0 

    !! @param[inout] this Concentrated load definition instance
    !! @param[in] name Load name
    !! @param[in] nset Node set name
    !! @param[in] dof DOF direction 

    !! @param[in] value Load magnitude F_0 

    !! @param[in] follower Follower force flag (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE cload_set_value(this, name, nset, dof, value, follower)
        CLASS(UF_CLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, nset
        INTEGER(i4), INTENT(IN) :: dof
        REAL(wp), INTENT(IN) :: value
        LOGICAL, INTENT(IN), OPTIONAL :: follower
        this%name = TRIM(name)
        this%nset_name = TRIM(nset)
        this%node_id = 0
        this%dof = dof
        this%magnitude = value
        IF (PRESENT(follower)) this%follower = follower
    END SUBROUTINE cload_set_value
    
    !=============================================================================
    !> @brief Get concentrated load value at time
    !! @details Computes F(t) = F_0 �?A(t), where F_0 


    !! @param[in] this Concentrated load definition instance
    !! @param[in] amp_value Amplitude value A(t) 

    !! @return Load value F(t) 

    !=============================================================================
    FUNCTION cload_get_value_at_time(this, amp_value) RESULT(val)
        CLASS(UF_CLoadDef), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: amp_value
        REAL(wp) :: val
        val = this%magnitude * amp_value
    END FUNCTION cload_get_value_at_time
    
    SUBROUTINE cload_print_info(this, unit_num)
        CLASS(UF_CLoadDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  CLOAD: ', TRIM(this%name)
        WRITE(unit_num, '(A,I2,A,ES12.4)') '    DOF=', this%dof, ', Magnitude=', this%magnitude
    END SUBROUTINE cload_print_info
    
    !--------------------------------------------------------------------------
    ! DLoad Methods
    !--------------------------------------------------------------------------
    !=============================================================================
    !> @brief Initialize distributed load definition (legacy interface)
    !! @details Initializes distributed load with default values
    !! @param[inout] this Distributed load definition instance
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use DLoadDef_Init_In type to encapsulate all initialization parameters
    !=============================================================================
    SUBROUTINE dload_init(this)
        CLASS(UF_DLoadDef), INTENT(INOUT) :: this
        this%name = ""
        this%surface_name = ""
        this%load_type = LOAD_PRESSURE
        this%magnitude = 0.0_wp
        this%is_active = .TRUE.
    END SUBROUTINE dload_init
    
    !=============================================================================
    !> @brief Set distributed load as pressure (legacy interface)
    !! @details Sets load name, surface, and pressure magnitude p_0 

    !! @param[inout] this Distributed load definition instance
    !! @param[in] name Load name
    !! @param[in] surface Surface name
    !! @param[in] value Pressure magnitude p_0 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE dload_set_pressure(this, name, surface, value)
        CLASS(UF_DLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, surface
        REAL(wp), INTENT(IN) :: value
        this%name = TRIM(name)
        this%surface_name = TRIM(surface)
        this%load_type = LOAD_PRESSURE
        this%magnitude = value
        this%direction = [0.0_wp, 0.0_wp, 0.0_wp]
    END SUBROUTINE dload_set_pressure
    
    !=============================================================================
    !> @brief Set distributed load as traction (legacy interface)
    !! @details Sets load name, surface, and traction vector t 鈩漗3
    !! @param[inout] this Distributed load definition instance
    !! @param[in] name Load name
    !! @param[in] surface Surface name
    !! @param[in] tx Traction x-component t_x 

    !! @param[in] ty Traction y-component t_y 

    !! @param[in] tz Traction z-component t_z 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE dload_set_traction(this, name, surface, tx, ty, tz)
        CLASS(UF_DLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, surface
        REAL(wp), INTENT(IN) :: tx, ty, tz
        this%name = TRIM(name)
        this%surface_name = TRIM(surface)
        this%load_type = LOAD_TRACTION
        this%direction = [tx, ty, tz]
        this%magnitude = SQRT(tx**2 + ty**2 + tz**2)
    END SUBROUTINE dload_set_traction
    
    !=============================================================================
    !> @brief Get distributed load value at time
    !! @details Computes p(t) = p_0 �?A(t), where p_0 


    !! @param[in] this Distributed load definition instance
    !! @param[in] amp_value Amplitude value A(t) 

    !! @return Load value p(t) 

    !=============================================================================
    FUNCTION dload_get_value_at_time(this, amp_value) RESULT(val)
        CLASS(UF_DLoadDef), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: amp_value
        REAL(wp) :: val
        val = this%magnitude * amp_value
    END FUNCTION dload_get_value_at_time
    
    SUBROUTINE dload_print_info(this, unit_num)
        CLASS(UF_DLoadDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  DLOAD: ', TRIM(this%name)
        WRITE(unit_num, '(A,I3,A,ES12.4)') '    Type=', this%load_type, ', Magnitude=', this%magnitude
    END SUBROUTINE dload_print_info

    !--------------------------------------------------------------------------
    ! BodyForce Methods
    !--------------------------------------------------------------------------
    !=============================================================================
    !> @brief Initialize body force definition (legacy interface)
    !! @details Initializes body force with default values
    !! @param[inout] this Body force definition instance
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use BodyForceDef_Init_In type to encapsulate all initialization parameters
    !=============================================================================
    SUBROUTINE bforce_init(this)
        CLASS(UF_BodyForceDef), INTENT(INOUT) :: this
        this%name = ""
        this%elset_name = ""
        this%load_type = LOAD_BODYFORCE
        this%components = [0.0_wp, 0.0_wp, 0.0_wp]
        this%is_active = .TRUE.
    END SUBROUTINE bforce_init
    
    !=============================================================================
    !> @brief Set body force as gravity (legacy interface)
    !! @details Sets load name, element set, and gravity vector g 鈩漗3
    !! @param[inout] this Body force definition instance
    !! @param[in] name Load name
    !! @param[in] elset Element set name
    !! @param[in] gx Gravity x-component g_x 

    !! @param[in] gy Gravity y-component g_y 

    !! @param[in] gz Gravity z-component g_z 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE bforce_set_gravity(this, name, elset, gx, gy, gz)
        CLASS(UF_BodyForceDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, elset
        REAL(wp), INTENT(IN) :: gx, gy, gz
        this%name = TRIM(name)
        this%elset_name = TRIM(elset)
        this%load_type = LOAD_GRAVITY
        this%components = [gx, gy, gz]
    END SUBROUTINE bforce_set_gravity
    
    !=============================================================================
    !> @brief Set body force as centrifugal (legacy interface)
    !! @details Sets load name, element set, angular velocity �?

! (doc) rotation axis 
    !!   Theory: Centrifugal force b = 蠅虏 �?(r - c) �?axis
    !! @param[inout] this Body force definition instance
    !! @param[in] name Load name
    !! @param[in] elset Element set name
    !! @param[in] omega Angular velocity �?

    !! @param[in] ax Rotation axis x-component 

    !! @param[in] ay Rotation axis y-component 

    !! @param[in] az Rotation axis z-component 

    !! @param[in] cx Center x-component c_x 

    !! @param[in] cy Center y-component c_y 

    !! @param[in] cz Center z-component c_z 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE bforce_set_centrifugal(this, name, elset, omega, ax, ay, az, cx, cy, cz)
        CLASS(UF_BodyForceDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, elset
        REAL(wp), INTENT(IN) :: omega, ax, ay, az, cx, cy, cz
        this%name = TRIM(name)
        this%elset_name = TRIM(elset)
        this%load_type = LOAD_CENTRIFUGAL
        this%omega = omega
        this%axis = [ax, ay, az]
        this%center = [cx, cy, cz]
    END SUBROUTINE bforce_set_centrifugal
    
    SUBROUTINE bforce_print_info(this, unit_num)
        CLASS(UF_BodyForceDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  BFORCE: ', TRIM(this%name)
        WRITE(unit_num, '(A,I3)') '    Type=', this%load_type
    END SUBROUTINE bforce_print_info
    
    !--------------------------------------------------------------------------
    ! Thermal Methods
    !--------------------------------------------------------------------------
    !=============================================================================
    !> @brief Initialize thermal load definition (legacy interface)
    !! @details Initializes thermal load with default values
    !! @param[inout] this Thermal load definition instance
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use ThermalLoadDef_Init_In type to encapsulate all initialization parameters
    !=============================================================================
    SUBROUTINE thermal_init(this)
        CLASS(UF_ThermalLoadDef), INTENT(INOUT) :: this
        this%name = ""
        this%surface_name = ""
        this%load_type = LOAD_SFILM
        this%is_active = .TRUE.
    END SUBROUTINE thermal_init

    !=============================================================================
    !> @brief Set thermal load as convection (legacy interface)
    !! @details Sets load name, surface, film coefficient h 

! (doc) and sink temperature T_sink 

    !!   Theory: Convection q = h �?(T_surface - T_sink)
    !! @param[inout] this Thermal load definition instance
    !! @param[in] name Load name
    !! @param[in] surface Surface name
    !! @param[in] h Film coefficient h 

    !! @param[in] sink_T Sink temperature T_sink 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE thermal_set_convection(this, name, surface, h, sink_T)
        CLASS(UF_ThermalLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, surface
        REAL(wp), INTENT(IN) :: h, sink_T
        this%name = TRIM(name)
        this%surface_name = TRIM(surface)
        this%load_type = LOAD_SFILM
        this%film_coeff = h
        this%sink_temp = sink_T
    END SUBROUTINE thermal_set_convection

    !=============================================================================
    !> @brief Set thermal load as radiation (legacy interface)
    !! @details Sets load name, surface, emissivity �?

! (doc) and sink temperature T_sink 

    !!   Theory: Radiation q = �?�?�?�?(T_surface - T_sink , where �?is Stefan-Boltzmann constant
    !! @param[inout] this Thermal load definition instance
    !! @param[in] name Load name
    !! @param[in] surface Surface name
    !! @param[in] eps Emissivity �?

    !! @param[in] sink_T Sink temperature T_sink 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE thermal_set_radiation(this, name, surface, eps, sink_T)
        CLASS(UF_ThermalLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, surface
        REAL(wp), INTENT(IN) :: eps, sink_T
        this%name = TRIM(name)
        this%surface_name = TRIM(surface)
        this%load_type = LOAD_SRADIATE
        this%emissivity = eps
        this%sink_temp = sink_T
    END SUBROUTINE thermal_set_radiation

    !=============================================================================
    !> @brief Set thermal load as heat flux (legacy interface)
    !! @details Sets load name, surface, and heat flux magnitude q_0 

    !! @param[inout] this Thermal load definition instance
    !! @param[in] name Load name
    !! @param[in] surface Surface name
    !! @param[in] flux Heat flux magnitude q_0 

    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE thermal_set_flux(this, name, surface, flux)
        CLASS(UF_ThermalLoadDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, surface
        REAL(wp), INTENT(IN) :: flux
        this%name = TRIM(name)
        this%surface_name = TRIM(surface)
        this%load_type = LOAD_DFLUX
        this%flux_magnitude = flux
    END SUBROUTINE thermal_set_flux
    
    SUBROUTINE thermal_print_info(this, unit_num)
        CLASS(UF_ThermalLoadDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  THERMAL: ', TRIM(this%name)
        WRITE(unit_num, '(A,I3)') '    Type=', this%load_type
    END SUBROUTINE thermal_print_info

    !--------------------------------------------------------------------------
    ! LoadBC Manager Methods
    !--------------------------------------------------------------------------
    !=============================================================================
    !> @brief Initialize load/BC manager (legacy interface)
    !! @details Initializes manager with optional maximum counts for BCs and loads
    !! @param[inout] this Load/BC manager instance
    !! @param[in] max_bc Maximum number of BCs 

! (doc) (optional)
    !! @param[in] max_load Maximum number of loads 

! (doc) (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE manager_init(this, max_bc, max_load)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_bc, max_load
        INTEGER(i4) :: nb, nl
        nb = MAX_BCS_PER_STEP
        nl = MAX_LOADS_PER_STEP
        IF (PRESENT(max_bc)) nb = max_bc
        IF (PRESENT(max_load)) nl = max_load
        ALLOCATE(this%bcs(nb))
        ALLOCATE(this%cloads(nl))
        ALLOCATE(this%dloads(nl))
        ALLOCATE(this%bforces(nl))
        ALLOCATE(this%thermals(nl))
        this%num_bcs = 0
        this%num_cloads = 0
        this%num_dloads = 0
        this%num_bforces = 0
        this%num_thermal = 0
    END SUBROUTINE manager_init
    
    SUBROUTINE manager_add_bc(this, bc)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        TYPE(UF_BCDef), INTENT(IN) :: bc
        IF (this%num_bcs >= SIZE(this%bcs)) RETURN
        this%num_bcs = this%num_bcs + 1
        this%bcs(this%num_bcs) = bc
    END SUBROUTINE manager_add_bc
    
    SUBROUTINE manager_add_bc_simple(this, name, nset, bc_type, dof1, dof2, value, amp_name)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, nset
        INTEGER(i4), INTENT(IN) :: bc_type, dof1, dof2
        REAL(wp), INTENT(IN) :: value
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: amp_name
        
        TYPE(UF_BCDef) :: bc
        
        CALL bc%init()
        bc%name = TRIM(name)
        bc%region_name = TRIM(nset)
        bc%bc_type = bc_type
        bc%dof_first = dof1
        bc%dof_last = dof2
        bc%magnitude = value
        IF (PRESENT(amp_name)) bc%amplitude_name = TRIM(amp_name)
        
        CALL this%add_bc(bc)
    END SUBROUTINE manager_add_bc_simple
    
    SUBROUTINE manager_add_cload(this, load)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        TYPE(UF_CLoadDef), INTENT(IN) :: load
        IF (this%num_cloads >= SIZE(this%cloads)) RETURN
        this%num_cloads = this%num_cloads + 1
        this%cloads(this%num_cloads) = load
    END SUBROUTINE manager_add_cload
    
    SUBROUTINE manager_add_dload(this, load)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        TYPE(UF_DLoadDef), INTENT(IN) :: load
        IF (this%num_dloads >= SIZE(this%dloads)) RETURN
        this%num_dloads = this%num_dloads + 1
        this%dloads(this%num_dloads) = load
    END SUBROUTINE manager_add_dload
    
    SUBROUTINE manager_add_bforce(this, load)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        TYPE(UF_BodyForceDef), INTENT(IN) :: load
        IF (this%num_bforces >= SIZE(this%bforces)) RETURN
        this%num_bforces = this%num_bforces + 1
        this%bforces(this%num_bforces) = load
    END SUBROUTINE manager_add_bforce
    
    SUBROUTINE manager_add_thermal(this, load)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        TYPE(UF_ThermalLoadDef), INTENT(IN) :: load
        IF (this%num_thermal >= SIZE(this%thermals)) RETURN
        this%num_thermal = this%num_thermal + 1
        this%thermals(this%num_thermal) = load
    END SUBROUTINE manager_add_thermal
    
    FUNCTION manager_get_bc(this, name) RESULT(ptr)
        CLASS(UF_LoadBCManager), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_BCDef), POINTER :: ptr
        INTEGER(i4) :: i
        ptr => NULL()
        DO i = 1, this%num_bcs
            IF (TRIM(this%bcs(i)%name) == TRIM(name)) THEN
                ptr => this%bcs(i)
                RETURN
            END IF
        END DO
    END FUNCTION manager_get_bc
    
    FUNCTION manager_get_cload(this, name) RESULT(ptr)
        CLASS(UF_LoadBCManager), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_CLoadDef), POINTER :: ptr
        INTEGER(i4) :: i
        ptr => NULL()
        DO i = 1, this%num_cloads
            IF (TRIM(this%cloads(i)%name) == TRIM(name)) THEN
                ptr => this%cloads(i)
                RETURN
            END IF
        END DO
    END FUNCTION manager_get_cload
    
    SUBROUTINE manager_deactivate_all(this)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_bcs
            this%bcs(i)%is_active = .FALSE.
        END DO
        DO i = 1, this%num_cloads
            this%cloads(i)%is_active = .FALSE.
        END DO
        DO i = 1, this%num_dloads
            this%dloads(i)%is_active = .FALSE.
        END DO
    END SUBROUTINE manager_deactivate_all
    
    SUBROUTINE manager_print_summary(this, unit_num)
        CLASS(UF_LoadBCManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A)') '=== LoadBC Summary ==='
        WRITE(unit_num, '(A,I5)') '  Boundary Conditions: ', this%num_bcs
        WRITE(unit_num, '(A,I5)') '  Concentrated Loads:  ', this%num_cloads
        WRITE(unit_num, '(A,I5)') '  Distributed Loads:   ', this%num_dloads
        WRITE(unit_num, '(A,I5)') '  Body Forces:         ', this%num_bforces
        WRITE(unit_num, '(A,I5)') '  Thermal Loads:       ', this%num_thermal
    END SUBROUTINE manager_print_summary
    
    SUBROUTINE manager_destroy(this)
        CLASS(UF_LoadBCManager), INTENT(INOUT) :: this
        IF (ALLOCATED(this%bcs)) DEALLOCATE(this%bcs)
        IF (ALLOCATED(this%cloads)) DEALLOCATE(this%cloads)
        IF (ALLOCATED(this%dloads)) DEALLOCATE(this%dloads)
        IF (ALLOCATED(this%bforces)) DEALLOCATE(this%bforces)
        IF (ALLOCATED(this%thermals)) DEALLOCATE(this%thermals)
        this%num_bcs = 0
        this%num_cloads = 0
        this%num_dloads = 0
        this%num_bforces = 0
        this%num_thermal = 0
    END SUBROUTINE manager_destroy

END MODULE MD_LBC_Brg
