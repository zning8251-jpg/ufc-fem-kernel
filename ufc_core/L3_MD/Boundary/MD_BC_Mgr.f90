!===============================================================================
! MODULE:  MD_BC_Mgr
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Mgr
! BRIEF:   BC definition types, constants, Register/Query procedures.
! PILOT:   ufc-layer-l3-l4-l5-pilot.md P4 — nested cfg/tgt/val/stp + flat mirror dual-write.
!===============================================================================
MODULE MD_BC_Mgr
    USE ieee_arithmetic, ONLY: ieee_is_finite
    USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Load_Mgr,  ONLY: TARGET_NODE, TARGET_EDGE
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! BC Type Constants (MD_LBC_* prefix)
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: BC_DISPLACEMENT = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_VELOCITY     = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ACCELERATION = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_FIXED        = 4_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_SYMMETRY     = 5_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_NEUMANN      = 6_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ROBIN        = 7_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_PERIODIC     = 8_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_CONTACT      = 9_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_ROTATION     = 10_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_TEMPERATURE  = 11_i4
    INTEGER(i4), PARAMETER, PUBLIC :: BC_PRESSURE     = 12_i4

    !---------------------------------------------------------------------------
    ! Nested Desc slices (P4 pilot) + flat mirror dual-write
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_BC_Cfg_Init_Desc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = 1_i4
    END TYPE MD_BC_Cfg_Init_Desc

    TYPE, PUBLIC :: MD_BC_Pop_Tgt_Desc
        INTEGER(i4) :: targetType = 1_i4
        INTEGER(i4) :: targetId = 0_i4
    END TYPE MD_BC_Pop_Tgt_Desc

    TYPE, PUBLIC :: MD_BC_Pop_Val_Desc
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE MD_BC_Pop_Val_Desc

    TYPE, PUBLIC :: MD_BC_Stp_Window_Desc
        LOGICAL :: isActive = .TRUE.
        REAL(wp) :: startTime = 0.0_wp
        REAL(wp) :: endTime = 1.0e30_wp
    END TYPE MD_BC_Stp_Window_Desc

    !---------------------------------------------------------------------------
    ! TYPE:  BCDef
    ! KIND:  Desc
    ! DESC:  Boundary condition definition — nested + flat mirror.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: BCDef
        TYPE(MD_BC_Cfg_Init_Desc) :: cfg
        TYPE(MD_BC_Pop_Tgt_Desc) :: tgt
        TYPE(MD_BC_Pop_Val_Desc) :: val
        TYPE(MD_BC_Stp_Window_Desc) :: stp
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = BC_DISPLACEMENT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp)    :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
        LOGICAL     :: isActive = .TRUE.
        REAL(wp)    :: startTime = 0.0_wp
        REAL(wp)    :: endTime = 1.0e30_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => BCDef_Init
        PROCEDURE, PUBLIC :: Valid => BCDef_Valid
        PROCEDURE, PUBLIC :: Clear => BCDef_Clear
    END TYPE BCDef

    !---------------------------------------------------------------------------
    ! TYPE:  BCDef_Init_In
    ! KIND:  Arg
    ! DESC:  Arg bundle input for BC initialization
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: BCDef_Init_In
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=80) :: name = ""
        INTEGER(i4) :: bcType = BC_DISPLACEMENT
        INTEGER(i4) :: targetType = TARGET_NODE
        INTEGER(i4) :: targetId = 0_i4
        INTEGER(i4) :: dof = 0_i4
        REAL(wp) :: value = 0.0_wp
        INTEGER(i4) :: amplitudeId = 0_i4
    END TYPE BCDef_Init_In

    !---------------------------------------------------------------------------
    ! TYPE:  BCDef_Init_Out
    ! KIND:  Arg
    ! DESC:  Arg bundle output for BC initialization
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: BCDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE BCDef_Init_Out

    PUBLIC :: BCDef_Init_Structured

CONTAINS

    !=============================================================================
    !> @brief Initialize boundary condition definition
    !=============================================================================
    SUBROUTINE BCDef_Init(this, id, name, bcType, targetType, targetId, dof, value, amplitudeId, status)
        CLASS(BCDef),         INTENT(INOUT) :: this
        INTEGER(i4),             INTENT(IN)    :: id
        CHARACTER(LEN=*),        INTENT(IN)    :: name
        INTEGER(i4),             INTENT(IN)    :: bcType
        INTEGER(i4),             INTENT(IN)    :: targetType
        INTEGER(i4),             INTENT(IN)    :: targetId
        INTEGER(i4),             INTENT(IN)    :: dof
        REAL(wp),                INTENT(IN)    :: value
        INTEGER(i4),             INTENT(IN),    OPTIONAL :: amplitudeId
        TYPE(ErrorStatusType),   INTENT(OUT)   :: status

        CALL init_error_status(status)

        this%cfg%id = id
        this%cfg%name = TRIM(name)
        this%cfg%bcType = bcType
        this%tgt%targetType = targetType
        this%tgt%targetId = targetId
        this%val%dof = dof
        this%val%value = value

        IF (PRESENT(amplitudeId)) THEN
            this%val%amplitudeId = amplitudeId
        ELSE
            this%val%amplitudeId = 0_i4
        END IF

        this%stp%isActive = .TRUE.
        this%stp%startTime = 0.0_wp
        this%stp%endTime = 1.0e30_wp

        this%id = id
        this%name = TRIM(name)
        this%bcType = bcType
        this%targetType = targetType
        this%targetId = targetId
        this%dof = dof
        this%value = value
        this%amplitudeId = this%val%amplitudeId
        this%isActive = this%stp%isActive
        this%startTime = this%stp%startTime
        this%endTime = this%stp%endTime

        status%status_code = IF_STATUS_OK
    END SUBROUTINE BCDef_Init

    !=============================================================================
    !> @brief Validate boundary condition definition
    !=============================================================================
    SUBROUTINE BCDef_Valid(this, status)
        CLASS(BCDef),         INTENT(IN)  :: this
        TYPE(ErrorStatusType),   INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (this%cfg%id <= 0 .OR. this%id /= this%cfg%id) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid BC ID"
            RETURN
        END IF

        IF (LEN_TRIM(this%cfg%name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "BC name is empty"
            RETURN
        END IF

        IF (this%cfg%bcType < BC_DISPLACEMENT .OR. this%cfg%bcType > BC_PRESSURE .OR. &
            this%bcType /= this%cfg%bcType) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid BC type"
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
            status%message = "BC target ID must be defined"
            RETURN
        END IF

        IF (this%val%dof < 1 .OR. this%val%dof > 6 .OR. this%dof /= this%val%dof) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0)') "BC DOF must be in range 1-6, got: ", this%val%dof
            RETURN
        END IF

        IF (.NOT. ieee_is_finite(this%val%value)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "BC value must be finite"
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE BCDef_Valid

    !=============================================================================
    !> @brief Clear boundary condition definition
    !=============================================================================
    SUBROUTINE BCDef_Clear(this)
        CLASS(BCDef), INTENT(INOUT) :: this

        this%cfg%id = 0_i4
        this%cfg%name = ""
        this%cfg%bcType = BC_DISPLACEMENT
        this%tgt%targetType = TARGET_NODE
        this%tgt%targetId = 0_i4
        this%val%dof = 0_i4
        this%val%value = 0.0_wp
        this%val%amplitudeId = 0_i4
        this%stp%isActive = .FALSE.
        this%stp%startTime = 0.0_wp
        this%stp%endTime = 1.0e30_wp
        this%id = 0_i4
        this%name = ""
        this%bcType = BC_DISPLACEMENT
        this%targetType = TARGET_NODE
        this%targetId = 0_i4
        this%dof = 0_i4
        this%value = 0.0_wp
        this%amplitudeId = 0_i4
        this%isActive = .FALSE.
        this%startTime = 0.0_wp
        this%endTime = 1.0e30_wp
    END SUBROUTINE BCDef_Clear

    !=============================================================================
    !> Initialize boundary condition definition (structured interface)
    !=============================================================================
    SUBROUTINE BCDef_Init_Structured(in, out, bc)
        TYPE(BCDef_Init_In), INTENT(IN) :: in
        TYPE(BCDef_Init_Out), INTENT(OUT) :: out
        TYPE(BCDef), INTENT(INOUT) :: bc

        CALL init_error_status(out%status)
        CALL bc%Init(in%id, in%name, in%bcType, in%targetType, in%targetId, &
                     in%dof, in%value, in%amplitudeId, out%status)
    END SUBROUTINE BCDef_Init_Structured

END MODULE MD_BC_Mgr
