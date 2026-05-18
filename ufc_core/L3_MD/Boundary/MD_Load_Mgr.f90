!===============================================================================
! MODULE:  MD_Load_Mgr
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Mgr
! BRIEF:   Load definition types, constants, Register/Query procedures.
! PILOT:   ufc-layer-l3-l4-l5-pilot.md P4 — nested cfg/tgt/val/stp Desc (+ flat mirror dual-write
!          until Step4); Sync→UF_Step_BuildLegacyLoadDefs_FromLdbc→RT_Asm_Solv cold path.
!===============================================================================
MODULE MD_Load_Mgr
    USE ieee_arithmetic, ONLY: ieee_is_finite
    USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! Target Type Constants (MD_LBC_* prefix)
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: TARGET_NODE      = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: TARGET_NODESET   = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: TARGET_SURFACE   = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: TARGET_ELEMSET   = 4_i4
    INTEGER(i4), PARAMETER, PUBLIC :: TARGET_EDGE      = 5_i4

    !---------------------------------------------------------------------------
    ! Load Type Constants (MD_LBC_* prefix)
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CONCENTRAT = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_DISTRIBUTE   = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_PRESSURE      = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_BODY_FORCE    = 4_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_GRAVITY      = 5_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CENTRIFUGA  = 6_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CORIOLIS     = 7_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_THERMAL       = 8_i4
    INTEGER(i4), PARAMETER, PUBLIC :: LOAD_EDGE_DISTR = 9_i4

    !---------------------------------------------------------------------------
    ! Nested Desc slices (P4 pilot — Phase×Verb grouping; depth ≤ 3)
    ! Flat mirrors on LoadDef kept for dual-write migration window.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Load_Cfg_Init_Desc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: loadType = 1_i4
    END TYPE MD_Load_Cfg_Init_Desc

    TYPE, PUBLIC :: MD_Load_Pop_Tgt_Desc
        INTEGER(i4) :: targetType = 1_i4
        INTEGER(i4) :: targetId = 0_i4
    END TYPE MD_Load_Pop_Tgt_Desc

    TYPE, PUBLIC :: MD_Load_Pop_Val_Desc
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: magnitude = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE MD_Load_Pop_Val_Desc

    TYPE, PUBLIC :: MD_Load_Stp_Window_Desc
        LOGICAL :: isActive = .TRUE.
        REAL(wp) :: startTime = 0.0_wp
        REAL(wp) :: endTime = 1.0e30_wp
    END TYPE MD_Load_Stp_Window_Desc

    !---------------------------------------------------------------------------
    ! TYPE:  LoadDef
    ! KIND:  Desc
    ! DESC:  Load definition — nested semantic groups + flat mirror fields (dual-write).
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: LoadDef
        TYPE(MD_Load_Cfg_Init_Desc) :: cfg
        TYPE(MD_Load_Pop_Tgt_Desc) :: tgt
        TYPE(MD_Load_Pop_Val_Desc) :: val
        TYPE(MD_Load_Stp_Window_Desc) :: stp
        INTEGER(i4) :: id = 0_i4                    ! mirror cfg%*
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: loadType = LOAD_CONCENTRAT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp)    :: magnitude = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
        LOGICAL     :: isActive = .TRUE.
        REAL(wp)    :: startTime = 0.0_wp
        REAL(wp)    :: endTime = 1.0e30_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => LoadDef_Init
        PROCEDURE, PUBLIC :: Valid => LoadDef_Valid
        PROCEDURE, PUBLIC :: Clear => LoadDef_Clear
    END TYPE LoadDef

    !---------------------------------------------------------------------------
    ! TYPE:  LoadDef_Init_In
    ! KIND:  Arg
    ! DESC:  Arg bundle input for Load initialization
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: LoadDef_Init_In
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: loadType = LOAD_CONCENTRAT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: magnitude = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE LoadDef_Init_In

    !> @brief Load initialization output structure (State category)
    TYPE, PUBLIC :: LoadDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE LoadDef_Init_Out

    PUBLIC :: LoadDef_Init_Structured

CONTAINS

    !=============================================================================
    !> @brief Initialize load definition
    !=============================================================================
    SUBROUTINE LoadDef_Init(this, id, name, loadType, targetType, targetId, dof, magnitude, amplitudeId, status)
        CLASS(LoadDef),       INTENT(INOUT) :: this
        INTEGER(i4),             INTENT(IN)    :: id
        CHARACTER(LEN=*),        INTENT(IN)    :: name
        INTEGER(i4),             INTENT(IN)    :: loadType
        INTEGER(i4),             INTENT(IN)    :: targetType
        INTEGER(i4),             INTENT(IN)    :: targetId
        INTEGER(i4),             INTENT(IN)    :: dof
        REAL(wp),                INTENT(IN)    :: magnitude
        INTEGER(i4),             INTENT(IN),    OPTIONAL :: amplitudeId
        TYPE(ErrorStatusType),   INTENT(OUT)   :: status

        CALL init_error_status(status)

        this%cfg%id = id
        this%cfg%name = TRIM(name)
        this%cfg%loadType = loadType
        this%tgt%targetType = targetType
        this%tgt%targetId = targetId
        this%val%dof = dof
        this%val%magnitude = magnitude

        IF (PRESENT(amplitudeId)) THEN
            this%val%amplitudeId = amplitudeId
        ELSE
            this%val%amplitudeId = 0_i4
        END IF

        this%stp%isActive = .TRUE.
        this%stp%startTime = 0.0_wp
        this%stp%endTime = 1.0e30_wp

        ! Flat mirror (dual-write migration window — Step4 removes mirrors per pilot)
        this%id = id
        this%name = TRIM(name)
        this%loadType = loadType
        this%targetType = targetType
        this%targetId = targetId
        this%dof = dof
        this%magnitude = magnitude
        this%amplitudeId = this%val%amplitudeId
        this%isActive = this%stp%isActive
        this%startTime = this%stp%startTime
        this%endTime = this%stp%endTime

        status%status_code = IF_STATUS_OK
    END SUBROUTINE LoadDef_Init

    !=============================================================================
    !> @brief Validate load definition
    !=============================================================================
    SUBROUTINE LoadDef_Valid(this, status)
        CLASS(LoadDef),       INTENT(IN)  :: this
        TYPE(ErrorStatusType),   INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (this%cfg%id <= 0 .OR. this%id /= this%cfg%id) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid load ID"
            RETURN
        END IF

        IF (LEN_TRIM(this%cfg%name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Load name is empty"
            RETURN
        END IF

        IF (this%cfg%loadType < LOAD_CONCENTRAT .OR. this%cfg%loadType > LOAD_EDGE_DISTR .OR. &
            this%loadType /= this%cfg%loadType) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid load type"
            RETURN
        END IF

        IF (this%tgt%targetType < TARGET_NODE .OR. this%tgt%targetType > TARGET_EDGE .OR. &
            this%targetType /= this%tgt%targetType) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid target type"
            RETURN
        END IF

        IF (this%tgt%targetId <= 0 .OR. this%targetId /= this%tgt%targetId) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Load target ID must be defined"
            RETURN
        END IF

        IF (this%val%dof < 1 .OR. this%val%dof > 6 .OR. this%dof /= this%val%dof) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0)') "Load DOF must be in range 1-6, got: ", this%val%dof
            RETURN
        END IF

        IF (.NOT. ieee_is_finite(this%val%magnitude)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Load magnitude must be finite"
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE LoadDef_Valid

    !=============================================================================
    !> @brief Clear load definition
    !=============================================================================
    SUBROUTINE LoadDef_Clear(this)
        CLASS(LoadDef), INTENT(INOUT) :: this

        this%cfg%id = 0_i4
        this%cfg%name = ""
        this%cfg%loadType = LOAD_CONCENTRAT
        this%tgt%targetType = TARGET_NODE
        this%tgt%targetId = 0_i4
        this%val%dof = 0_i4
        this%val%magnitude = 0.0_wp
        this%val%amplitudeId = 0_i4
        this%stp%isActive = .FALSE.
        this%stp%startTime = 0.0_wp
        this%stp%endTime = 1.0e30_wp
        this%id = 0_i4
        this%name = ""
        this%loadType = LOAD_CONCENTRAT
        this%targetType = TARGET_NODE
        this%targetId = 0_i4
        this%dof = 0_i4
        this%magnitude = 0.0_wp
        this%amplitudeId = 0_i4
        this%isActive = .FALSE.
        this%startTime = 0.0_wp
        this%endTime = 1.0e30_wp
    END SUBROUTINE LoadDef_Clear

    !=============================================================================
    !> Initialize load definition (structured interface)
    !=============================================================================
    SUBROUTINE LoadDef_Init_Structured(in, out, load)
        TYPE(LoadDef_Init_In), INTENT(IN) :: in
        TYPE(LoadDef_Init_Out), INTENT(OUT) :: out
        TYPE(LoadDef), INTENT(INOUT) :: load

        CALL init_error_status(out%status)
        CALL load%Init(in%id, in%name, in%loadType, in%targetType, in%targetId, &
                       in%dof, in%magnitude, in%amplitudeId, out%status)
    END SUBROUTINE LoadDef_Init_Structured

END MODULE MD_Load_Mgr
