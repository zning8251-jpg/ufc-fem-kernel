!======================================================================
! MODULE:  MD_Int_Ctx (LEGACY multi-module file)
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact interaction sub-option types (34 modules).
!          Clearance, Controls, Initialization, Interference,
!          Output, Stabilization, Friction, StickSlip, UserContact,
!          plus per-type Validate, Parse, and Ctx_Core/Ctx_Mgr.
!          LEGACY-EXEMPT: multi-module file retained as-is;
!          splitting blocked by 92 USE references across 15 modules.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header only)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_ContClearance_Type
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContClearanceProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        REAL(wp) :: clearanceValue = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContClearanceProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContClearanceProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContClearanceProperties_Clear
    END TYPE ContClearanceProperties

    PUBLIC :: ContClearanceProperties

CONTAINS

    !> Purpose: Clear ContClearanceProperties
    SUBROUTINE ContClearanceProperties_Clear(this)
        CLASS(ContClearanceProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%clearanceValue = 0.0_wp
    END SUBROUTINE ContClearanceProperties_Clear

    !> Purpose: Validate ContClearanceProperties
    FUNCTION ContClearanceProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ContClearanceProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ContClearanceProperties_Valid_Fn

    !> Purpose: Initialize ContClearanceProperties
    SUBROUTINE ContClearanceProperties_Init(this, name, status)
        CLASS(ContClearanceProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%clearanceValue = 0.0_wp
    END SUBROUTINE ContClearanceProperties_Init

END MODULE MD_Int_ContClearance_Type

MODULE MD_Int_ContactControls_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContControlsProperties
        CHARACTER(LEN=64) :: name = ""
        REAL(wp) :: stabilizationFactor = 0.0_wp
        REAL(wp) :: penetrationTolerance = 0.0_wp
        INTEGER(i4) :: maxIterations = 10
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContControlsProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContControlsProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContControlsProperties_Clear
    END TYPE ContControlsProperties

    PUBLIC :: ContControlsProperties

CONTAINS

    !> Purpose: Clear ContControlsProperties
    SUBROUTINE ContControlsProperties_Clear(this)
        CLASS(ContControlsProperties), INTENT(INOUT) :: this
        this%name = ""
        this%stabilizationFactor = 0.0_wp
        this%penetrationTolerance = 0.0_wp
        this%maxIterations = 10
    END SUBROUTINE ContControlsProperties_Clear

    !> Purpose: Validate ContControlsProperties
    SUBROUTINE ContControlsProperties_Validate(this, status)
        CLASS(ContControlsProperties), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (this%maxIterations <= 0) THEN
            status%status_code = 1
            status%message = "CONTACT CONTROLS: Max iterations must be positive"
            RETURN
        END IF
    END SUBROUTINE ContControlsProperties_Validate

    !> Purpose: Initialize ContControlsProperties
    SUBROUTINE ContControlsProperties_Init(this, name, status)
        CLASS(ContControlsProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%stabilizationFactor = 0.0_wp
        this%penetrationTolerance = 0.0_wp
        this%maxIterations = 10
    END SUBROUTINE ContControlsProperties_Init

END MODULE MD_Int_ContactControls_Type

MODULE MD_Int_ContactInitialization_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContInitializationProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        INTEGER(i4) :: initializationType = 1
        REAL(wp) :: tolerance = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContInitializationProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContInitializationProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContInitializationProperties_Clear
    END TYPE ContInitializationProperties

    PUBLIC :: ContInitializationProperties

CONTAINS

    !> Purpose: Clear ContInitializationProperties
    SUBROUTINE ContInitializationProperties_Clear(this)
        CLASS(ContInitializationProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%initializationType = 1
        this%tolerance = 0.0_wp
    END SUBROUTINE ContInitializationProperties_Clear

    !> Purpose: Validate ContInitializationProperties
    FUNCTION ContInitializationProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ContInitializationProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ContInitializationProperties_Valid_Fn

    !> Purpose: Initialize ContInitializationProperties
    SUBROUTINE ContInitializationProperties_Init(this, name, status)
        CLASS(ContInitializationProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%initializationType = 1
        this%tolerance = 0.0_wp
    END SUBROUTINE ContInitializationProperties_Init

END MODULE MD_Int_ContactInitialization_Type

MODULE MD_Int_ContactInterference_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContInterferenceProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        REAL(wp) :: interferenceValue = 0.0_wp
        LOGICAL :: adjustNodes = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContInterferenceProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContInterferenceProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContInterferenceProperties_Clear
    END TYPE ContInterferenceProperties

    PUBLIC :: ContInterferenceProperties

CONTAINS

    !> Purpose: Clear ContInterferenceProperties
    SUBROUTINE ContInterferenceProperties_Clear(this)
        CLASS(ContInterferenceProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%interferenceValue = 0.0_wp
        this%adjustNodes = .FALSE.
    END SUBROUTINE ContInterferenceProperties_Clear

    !> Purpose: Validate ContInterferenceProperties
    FUNCTION ContInterferenceProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ContInterferenceProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ContInterferenceProperties_Valid_Fn

    !> Purpose: Initialize ContInterferenceProperties
    SUBROUTINE ContInterferenceProperties_Init(this, name, status)
        CLASS(ContInterferenceProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%interferenceValue = 0.0_wp
        this%adjustNodes = .FALSE.
    END SUBROUTINE ContInterferenceProperties_Init

END MODULE MD_Int_ContactInterference_Type

MODULE MD_Int_ContactOutput_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContOutputProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        LOGICAL :: outputPressure = .TRUE.
        LOGICAL :: outputGap = .TRUE.
        LOGICAL :: outputSlip = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContOutputProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContOutputProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContOutputProperties_Clear
    END TYPE ContOutputProperties

    PUBLIC :: ContOutputProperties

CONTAINS

    !> Purpose: Clear ContOutputProperties
    SUBROUTINE ContOutputProperties_Clear(this)
        CLASS(ContOutputProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%outputPressure = .TRUE.
        this%outputGap = .TRUE.
        this%outputSlip = .TRUE.
    END SUBROUTINE ContOutputProperties_Clear

    !> Purpose: Validate ContOutputProperties
    FUNCTION ContOutputProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ContOutputProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ContOutputProperties_Valid_Fn

    !> Purpose: Initialize ContOutputProperties
    SUBROUTINE ContOutputProperties_Init(this, name, status)
        CLASS(ContOutputProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%outputPressure = .TRUE.
        this%outputGap = .TRUE.
        this%outputSlip = .TRUE.
    END SUBROUTINE ContOutputProperties_Init

END MODULE MD_Int_ContactOutput_Type

MODULE MD_Int_ContactStabilization_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: ContStabilizationProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        REAL(wp) :: stabilizationFactor = 1.0_wp
        LOGICAL :: automatic = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ContStabilizationProperties_Init
        PROCEDURE, PUBLIC :: Valid => ContStabilizationProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ContStabilizationProperties_Clear
    END TYPE ContStabilizationProperties

    PUBLIC :: ContStabilizationProperties

CONTAINS

    !> Purpose: Clear ContStabilizationProperties
    SUBROUTINE ContStabilizationProperties_Clear(this)
        CLASS(ContStabilizationProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%stabilizationFactor = 1.0_wp
        this%automatic = .TRUE.
    END SUBROUTINE ContStabilizationProperties_Clear

    !> Purpose: Validate ContStabilizationProperties
    FUNCTION ContStabilizationProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ContStabilizationProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%stabilizationFactor < 0.0_wp) ok = .FALSE.
    END FUNCTION ContStabilizationProperties_Valid_Fn

    !> Purpose: Initialize ContStabilizationProperties
    SUBROUTINE ContStabilizationProperties_Init(this, name, status)
        CLASS(ContStabilizationProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%stabilizationFactor = 1.0_wp
        this%automatic = .TRUE.
    END SUBROUTINE ContStabilizationProperties_Init

END MODULE MD_Int_ContactStabilization_Type

MODULE MD_Int_Friction_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: FrictionProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: frictionType = 1
        REAL(wp) :: coef = 0.0_wp
        REAL(wp) :: slipTolerance = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => FrictionProperties_Init
        PROCEDURE, PUBLIC :: Valid => FrictionProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => FrictionProperties_Clear
    END TYPE FrictionProperties

    PUBLIC :: FrictionProperties

CONTAINS

    !> Purpose: Clear FrictionProperties
    SUBROUTINE FrictionProperties_Clear(this)
        CLASS(FrictionProperties), INTENT(INOUT) :: this
        this%name = ""
        this%frictionType = 1
        this%coef = 0.0_wp
        this%slipTolerance = 0.0_wp
    END SUBROUTINE FrictionProperties_Clear

    !> Purpose: Validate FrictionProperties
    FUNCTION FrictionProperties_Valid_Fn(this) RESULT(ok)
        CLASS(FrictionProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%coef < 0.0_wp) ok = .FALSE.
    END FUNCTION FrictionProperties_Valid_Fn

    !> Purpose: Initialize FrictionProperties
    SUBROUTINE FrictionProperties_Init(this, name, status)
        CLASS(FrictionProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%frictionType = 1
        this%coef = 0.0_wp
        this%slipTolerance = 0.0_wp
    END SUBROUTINE FrictionProperties_Init

END MODULE MD_Int_Friction_Type

MODULE MD_Int_FrictionCoefficient_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: FrictionCoefficientProperties
        CHARACTER(LEN=64) :: name = ""
        REAL(wp) :: staticCoefficient = 0.0_wp
        REAL(wp) :: kineticCoefficient = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => FrictionCoefficientProperties_Init
        PROCEDURE, PUBLIC :: Valid => FrictionCoefficientProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => FrictionCoefficientProperties_Clear
    END TYPE FrictionCoefficientProperties

    PUBLIC :: FrictionCoefficientProperties

CONTAINS

    !> Purpose: Clear FrictionCoefficientProperties
    SUBROUTINE FrictionCoefficientProperties_Clear(this)
        CLASS(FrictionCoefficientProperties), INTENT(INOUT) :: this
        this%name = ""
        this%staticCoefficient = 0.0_wp
        this%kineticCoefficient = 0.0_wp
    END SUBROUTINE FrictionCoefficientProperties_Clear

    !> Purpose: Validate FrictionCoefficientProperties
    FUNCTION FrictionCoefficientProperties_Valid_Fn(this) RESULT(ok)
        CLASS(FrictionCoefficientProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%staticCoefficient < 0.0_wp .OR. this%kineticCoefficient < 0.0_wp) ok = .FALSE.
    END FUNCTION FrictionCoefficientProperties_Valid_Fn

    !> Purpose: Initialize FrictionCoefficientProperties
    SUBROUTINE FrictionCoefficientProperties_Init(this, name, status)
        CLASS(FrictionCoefficientProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%staticCoefficient = 0.0_wp
        this%kineticCoefficient = 0.0_wp
    END SUBROUTINE FrictionCoefficientProperties_Init

END MODULE MD_Int_FrictionCoefficient_Type

MODULE MD_Int_FrictionOutput_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: FrictionOutputProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: contactPair = ""
        LOGICAL :: outputFrictionForce = .TRUE.
        LOGICAL :: outputSlipDistance = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => FrictionOutputProperties_Init
        PROCEDURE, PUBLIC :: Valid => FrictionOutputProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => FrictionOutputProperties_Clear
    END TYPE FrictionOutputProperties

    PUBLIC :: FrictionOutputProperties

CONTAINS

    !> Purpose: Clear FrictionOutputProperties
    SUBROUTINE FrictionOutputProperties_Clear(this)
        CLASS(FrictionOutputProperties), INTENT(INOUT) :: this
        this%name = ""
        this%contactPair = ""
        this%outputFrictionForce = .TRUE.
        this%outputSlipDistance = .TRUE.
    END SUBROUTINE FrictionOutputProperties_Clear

    !> Purpose: Validate FrictionOutputProperties
    FUNCTION FrictionOutputProperties_Valid_Fn(this) RESULT(ok)
        CLASS(FrictionOutputProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION FrictionOutputProperties_Valid_Fn

    !> Purpose: Initialize FrictionOutputProperties
    SUBROUTINE FrictionOutputProperties_Init(this, name, status)
        CLASS(FrictionOutputProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%contactPair = ""
        this%outputFrictionForce = .TRUE.
        this%outputSlipDistance = .TRUE.
    END SUBROUTINE FrictionOutputProperties_Init

END MODULE MD_Int_FrictionOutput_Type

MODULE MD_Int_StickSlip_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: StickSlipProperties
        CHARACTER(LEN=64) :: name = ""
        REAL(wp) :: staticCoefficient = 0.0_wp
        REAL(wp) :: kineticCoefficient = 0.0_wp
        REAL(wp) :: criticalSlipVelocity = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init => StickSlipProperties_Init
        PROCEDURE, PUBLIC :: Valid => StickSlipProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => StickSlipProperties_Clear
    END TYPE StickSlipProperties

    PUBLIC :: StickSlipProperties

CONTAINS

    !> Purpose: Clear StickSlipProperties
    SUBROUTINE StickSlipProperties_Clear(this)
        CLASS(StickSlipProperties), INTENT(INOUT) :: this
        this%name = ""
        this%staticCoefficient = 0.0_wp
        this%kineticCoefficient = 0.0_wp
        this%criticalSlipVelocity = 0.0_wp
    END SUBROUTINE StickSlipProperties_Clear

    !> Purpose: Validate StickSlipProperties
    FUNCTION StickSlipProperties_Valid_Fn(this) RESULT(ok)
        CLASS(StickSlipProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%staticCoefficient < 0.0_wp .OR. this%kineticCoefficient < 0.0_wp) ok = .FALSE.
    END FUNCTION StickSlipProperties_Valid_Fn

    !> Purpose: Initialize StickSlipProperties
    SUBROUTINE StickSlipProperties_Init(this, name, status)
        CLASS(StickSlipProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%staticCoefficient = 0.0_wp
        this%kineticCoefficient = 0.0_wp
        this%criticalSlipVelocity = 0.0_wp
    END SUBROUTINE StickSlipProperties_Init

END MODULE MD_Int_StickSlip_Type

MODULE MD_Int_UserContact_Type
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    IMPLICIT NONE
    PRIVATE

    TYPE, PUBLIC, EXTENDS(DescBase) :: UserContactProperties
        CHARACTER(LEN=64) :: interactionName = ""
        CHARACTER(LEN=512) :: libraryPath = ""
        CHARACTER(LEN=64) :: subroutineName = "FRIC"
    CONTAINS
        PROCEDURE, PUBLIC :: Init => UserContactProperties_Init
        PROCEDURE, PUBLIC :: Valid => UserContactProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => UserContactProperties_Clear
    END TYPE UserContactProperties

    PUBLIC :: UserContactProperties

CONTAINS

    !> Purpose: Clear UserContactProperties
    SUBROUTINE UserContactProperties_Clear(this)
        CLASS(UserContactProperties), INTENT(INOUT) :: this
        this%interactionName = ""
        this%libraryPath = ""
        this%subroutineName = "FRIC"
    END SUBROUTINE UserContactProperties_Clear

    !> Purpose: Validate UserContactProperties
    FUNCTION UserContactProperties_Valid_Fn(this) RESULT(ok)
        CLASS(UserContactProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION UserContactProperties_Valid_Fn

    !> Purpose: Initialize UserContactProperties
    SUBROUTINE UserContactProperties_Init(this, interactionName, status)
        CLASS(UserContactProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: interactionName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%interactionName = TRIM(interactionName)
    END SUBROUTINE UserContactProperties_Init

END MODULE MD_Int_UserContact_Type

MODULE MD_Int_ContactClearance_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContClearance_Type, ONLY: ContClearanceProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_CONTACT_CLEARANCE_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate CONTACT CLEARANCE Keyword
    SUBROUTINE Va_CO_CL_Keyword(contactClearance, status)
        TYPE(ContClearanceProperties), INTENT(IN) :: contactClearance
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactClearance%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact clearance properties"
            RETURN
        END IF
    END SUBROUTINE Validate_CONTACT_CLEARANCE_Keyword

END MODULE MD_Int_ContactClearance_Validate

MODULE MD_Int_ContactControls_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactControls_Type, ONLY: ContControlsProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_CONTACT_CONTROLS_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate CONTACT CONTROLS Keyword
    SUBROUTINE Va_CO_CO_Keyword(contactControls, status)
        TYPE(ContControlsProperties), INTENT(IN) :: contactControls
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactControls%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact controls properties"
            RETURN
        END IF
    END SUBROUTINE Validate_CONTACT_CONTROLS_Keyword

END MODULE MD_Int_ContactControls_Validate

MODULE MD_Int_ContactInitialization_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactInitialization_Type, ONLY: ContInitializationProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Valid_CONTACT_Init_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Valid CONTACT Init Keyword
    SUBROUTINE Valid_CONTACT_Init_Keyword(contactInit, status)
        TYPE(ContInitializationProperties), INTENT(IN) :: contactInit
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactInit%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact initialization properties"
            RETURN
        END IF
    END SUBROUTINE Valid_CONTACT_Init_Keyword

END MODULE MD_Int_ContactInitialization_Validate

MODULE MD_Int_ContactInterference_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactInterference_Type, ONLY: ContInterferenceProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_CONTACT_INTERFERENCE_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate CONTACT INTERFERENCE Keyword
    SUBROUTINE Va_CO_IN_Keyword(contactInterference, status)
        TYPE(ContInterferenceProperties), INTENT(IN) :: contactInterference
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactInterference%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact interference properties"
            RETURN
        END IF
    END SUBROUTINE Validate_CONTACT_INTERFERENCE_Keyword

END MODULE MD_Int_ContactInterference_Validate

MODULE MD_Int_ContactOutput_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactOutput_Type, ONLY: ContOutputProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Valid_CONTACT_OUTPUT_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Valid CONTACT OUTPUT Keyword
    SUBROUTINE Valid_CONTACT_OUTPUT_Keyword(contactOutput, status)
        TYPE(ContOutputProperties), INTENT(IN) :: contactOutput
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactOutput%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact output properties"
            RETURN
        END IF
    END SUBROUTINE Valid_CONTACT_OUTPUT_Keyword

END MODULE MD_Int_ContactOutput_Validate

MODULE MD_Int_ContactStabilization_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactStabilization_Type, ONLY: ContStabilizationProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_CONTACT_STABILIZATION_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate CONTACT STABILIZATION Keyword
    SUBROUTINE Va_CO_ST_Keyword(contactStab, status)
        TYPE(ContStabilizationProperties), INTENT(IN) :: contactStab
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. contactStab%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact stabilization properties"
            RETURN
        END IF
    END SUBROUTINE Validate_CONTACT_STABILIZATION_Keyword

END MODULE MD_Int_ContactStabilization_Validate

MODULE MD_Int_Friction_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_Friction_Type, ONLY: FrictionProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Valid_FRICTION_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Valid FRICTION Keyword
    SUBROUTINE Valid_FRICTION_Keyword(friction, status)
        TYPE(FrictionProperties), INTENT(IN) :: friction
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. friction%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction properties"
            RETURN
        END IF
    END SUBROUTINE Valid_FRICTION_Keyword

END MODULE MD_Int_Friction_Validate

MODULE MD_Int_FrictionCoefficient_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_FrictionCoefficient_Type, ONLY: FrictionCoefficientProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_FRICTION_COEFFICIENT_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate FRICTION coef Keyword
    SUBROUTINE Va_FR_CO_Keyword(frictionCoeff, status)
        TYPE(FrictionCoefficientProperties), INTENT(IN) :: frictionCoeff
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. frictionCoeff%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction coefficient properties"
            RETURN
        END IF
    END SUBROUTINE Validate_FRICTION_COEFFICIENT_Keyword

END MODULE MD_Int_FrictionCoefficient_Validate

MODULE MD_Int_FrictionOutput_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_FrictionOutput_Type, ONLY: FrictionOutputProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Validate_FRICTION_OUTPUT_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Validate FRICTION OUTPUT Keyword
    SUBROUTINE Va_FR_OU_Keyword(frictionOutput, status)
        TYPE(FrictionOutputProperties), INTENT(IN) :: frictionOutput
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. frictionOutput%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction output properties"
            RETURN
        END IF
    END SUBROUTINE Validate_FRICTION_OUTPUT_Keyword

END MODULE MD_Int_FrictionOutput_Validate

MODULE MD_Int_StickSlip_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_StickSlip_Type, ONLY: StickSlipProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Valid_STICK_SLIP_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Valid STICK SLIP Keyword
    SUBROUTINE Valid_STICK_SLIP_Keyword(stickSlip, status)
        TYPE(StickSlipProperties), INTENT(IN) :: stickSlip
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. stickSlip%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid stick slip properties"
            RETURN
        END IF
    END SUBROUTINE Valid_STICK_SLIP_Keyword

END MODULE MD_Int_StickSlip_Validate

MODULE MD_Int_UserContact_Validate
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_UserContact_Type, ONLY: UserContactProperties
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Valid_USER_CONTACT_Keyword

CONTAINS

CONTAINS

    !> Purpose: Process Valid USER CONTACT Keyword
    SUBROUTINE Valid_USER_CONTACT_Keyword(userContact, status)
        TYPE(UserContactProperties), INTENT(IN) :: userContact
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. userContact%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid user contact properties"
            RETURN
        END IF
    END SUBROUTINE Valid_USER_CONTACT_Keyword

END MODULE MD_Int_UserContact_Validate

MODULE MD_Int_ContactClearance_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContClearance_Type, ONLY: ContClearanceProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_CLEARANCE_Keyword
    !  /  (task25300-25399)
    PUBLIC :: MD_Interaction_ContactClearance_Unified_Parse
    PUBLIC :: MD_Interaction_ContactClearance_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContClearance Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25350-25399
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactClearance_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactClearance_Unified_Configure

    !> Purpose: Parse MD Interaction ContClearance Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactClearance, context_name, status)
        !! Unified parse: int_type 'CONTACT_CLEARANCE' -> Parse_CONTACT_CLEARANCE_Keyword. Task: 25300-25349.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContClearanceProperties), INTENT(OUT) :: contactClearance
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_CLEARANCE' .OR. TRIM(int_type) == 'CONTACT CLEARANCE') THEN
            CALL Parse_CONTACT_CLEARANCE_Keyword(ast_node, contactClearance, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactClearance_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactClearance_Unified_Parse

    !> Purpose: Process Parse CONTACT CLEARANCE Keyword
    SUBROUTINE Pa_CO_CL_Keyword(ast_node, contactClearance, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContClearanceProperties), INTENT(OUT) :: contactClearance
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactClearance%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 1) THEN
            contactClearance%clearanceValue = ast_node%data_lines(1)%real_values(1)
        END IF
        IF (.NOT. contactClearance%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact clearance properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_CLEARANCE_Keyword

END MODULE MD_Int_ContactClearance_Parse

MODULE MD_Int_ContactControls_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactControls_Type, ONLY: ContControlsProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_CONTROLS_Keyword
    !  /  (task24800-24899)
    PUBLIC :: MD_Interaction_ContactControls_Unified_Parse
    PUBLIC :: MD_Interaction_ContactControls_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContControls Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 24850-24899
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactControls_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactControls_Unified_Configure

    !> Purpose: Parse MD Interaction ContControls Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactControls, context_name, status)
        !! Unified parse: int_type 'CONTACT_CONTROLS' or 'CONTACT CONTROLS' -> Parse_CONTACT_CONTROLS_Keyword. Task: 24800-24849.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContControlsProperties), INTENT(OUT) :: contactControls
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_CONTROLS' .OR. TRIM(int_type) == 'CONTACT CONTROLS') THEN
            CALL Parse_CONTACT_CONTROLS_Keyword(ast_node, contactControls, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactControls_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactControls_Unified_Parse

    !> Purpose: Process Parse CONTACT CONTROLS Keyword
    SUBROUTINE Pa_CO_CO_Keyword(ast_node, contactControls, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContControlsProperties), INTENT(OUT) :: contactControls
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactControls%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 3) THEN
            contactControls%stabilizationFactor = ast_node%data_lines(1)%real_values(1)
            contactControls%penetrationTolerance = ast_node%data_lines(1)%real_values(2)
            contactControls%maxIterations = INT(ast_node%data_lines(1)%real_values(3))
        END IF
        IF (.NOT. contactControls%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact controls properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_CONTROLS_Keyword

END MODULE MD_Int_ContactControls_Parse

MODULE MD_Int_ContactInitialization_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactInitialization_Type, ONLY: ContInitializationProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_Init_Keyword
    !  /  (task25200-25299)
    PUBLIC :: MD_Interaction_ContactInitialization_Unified_Parse
    PUBLIC :: MD_Interaction_ContactInitialization_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContInitialization Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25250-25299
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactInitialization_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactInitialization_Unified_Configure

    !> Purpose: Parse MD Interaction ContInitialization Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactInit, context_name, status)
        !! Unified parse: int_type 'CONTACT_INITIALIZATION' -> Parse_CONTACT_Init_Keyword. Task: 25200-25249.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContInitializationProperties), INTENT(OUT) :: contactInit
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_INITIALIZATION' .OR. TRIM(int_type) == 'CONTACT INITIALIZATION') THEN
            CALL Parse_CONTACT_Init_Keyword(ast_node, contactInit, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactInitialization_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactInitialization_Unified_Parse

    !> Purpose: Process Parse CONTACT Init Keyword
    SUBROUTINE Parse_CONTACT_Init_Keyword(ast_node, contactInit, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContInitializationProperties), INTENT(OUT) :: contactInit
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactInit%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 1) THEN
            contactInit%tolerance = ast_node%data_lines(1)%real_values(1)
        END IF
        IF (.NOT. contactInit%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact initialization properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_Init_Keyword

END MODULE MD_Int_ContactInitialization_Parse

MODULE MD_Int_ContactInterference_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactInterference_Type, ONLY: ContInterferenceProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_INTERFERENCE_Keyword
    !  /  (task25400-25499)
    PUBLIC :: MD_Interaction_ContactInterference_Unified_Parse
    PUBLIC :: MD_Interaction_ContactInterference_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContInterference Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25450-25499
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactInterference_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactInterference_Unified_Configure

    !> Purpose: Parse MD Interaction ContInterference Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactInterference, context_name, status)
        !! Unified parse: int_type 'CONTACT_INTERFERENCE' -> Parse_CONTACT_INTERFERENCE_Keyword. Task: 25400-25449.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContInterferenceProperties), INTENT(OUT) :: contactInterference
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_INTERFERENCE' .OR. TRIM(int_type) == 'CONTACT INTERFERENCE') THEN
            CALL Parse_CONTACT_INTERFERENCE_Keyword(ast_node, contactInterference, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactInterference_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactInterference_Unified_Parse

    !> Purpose: Process Parse CONTACT INTERFERENCE Keyword
    SUBROUTINE Pa_CO_IN_Keyword(ast_node, contactInterference, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContInterferenceProperties), INTENT(OUT) :: contactInterference
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactInterference%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 1) THEN
            contactInterference%interferenceValue = ast_node%data_lines(1)%real_values(1)
        END IF
        IF (.NOT. contactInterference%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact interference properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_INTERFERENCE_Keyword

END MODULE MD_Int_ContactInterference_Parse

MODULE MD_Int_ContactOutput_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactOutput_Type, ONLY: ContOutputProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_OUTPUT_Keyword
    !  /  (task25100-25199)
    PUBLIC :: MD_Interaction_ContactOutput_Unified_Parse
    PUBLIC :: MD_Interaction_ContactOutput_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContOutput Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25150-25199
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactOutput_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactOutput_Unified_Configure

    !> Purpose: Parse MD Interaction ContOutput Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactOutput, context_name, status)
        !! Unified parse: int_type 'CONTACT_OUTPUT' -> Parse_CONTACT_OUTPUT_Keyword. Task: 25100-25149.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContOutputProperties), INTENT(OUT) :: contactOutput
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_OUTPUT' .OR. TRIM(int_type) == 'CONTACT OUTPUT') THEN
            CALL Parse_CONTACT_OUTPUT_Keyword(ast_node, contactOutput, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactOutput_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactOutput_Unified_Parse

    !> Purpose: Process Parse CONTACT OUTPUT Keyword
    SUBROUTINE Parse_CONTACT_OUTPUT_Keyword(ast_node, contactOutput, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContOutputProperties), INTENT(OUT) :: contactOutput
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactOutput%Init(TRIM(name), status)
        IF (.NOT. contactOutput%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact output properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_OUTPUT_Keyword

END MODULE MD_Int_ContactOutput_Parse

MODULE MD_Int_ContactStabilization_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_ContactStabilization_Type, ONLY: ContStabilizationProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_CONTACT_STABILIZATION_Keyword
    !  /  (task24700-24799)
    PUBLIC :: MD_Interaction_ContactStabilization_Unified_Parse
    PUBLIC :: MD_Interaction_ContactStabilization_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction ContStabilization Unified Configure
    SUBROUTINE MD_In_Co_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 24750-24799
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactStabilization_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_ContactStabilization_Unified_Configure

    !> Purpose: Parse MD Interaction ContStabilization Unified
    SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactStab, context_name, status)
        !! Unified parse: int_type 'CONTACT_STABILIZATION' or 'CONTACT STABILIZATION' -> Parse_CONTACT_STABILIZATION_Keyword. Task: 24700-24749.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContStabilizationProperties), INTENT(OUT) :: contactStab
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'CONTACT_STABILIZATION' .OR. TRIM(int_type) == 'CONTACT STABILIZATION') THEN
            CALL Parse_CONTACT_STABILIZATION_Keyword(ast_node, contactStab, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_ContactStabilization_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_ContactStabilization_Unified_Parse

    !> Purpose: Process Parse CONTACT STABILIZATION Keyword
    SUBROUTINE Pa_CO_ST_Keyword(ast_node, contactStab, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ContStabilizationProperties), INTENT(OUT) :: contactStab
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL contactStab%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 1) THEN
            contactStab%stabilizationFactor = ast_node%data_lines(1)%real_values(1)
        END IF
        IF (.NOT. contactStab%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid contact stabilization properties"
            RETURN
        END IF
    END SUBROUTINE Parse_CONTACT_STABILIZATION_Keyword

END MODULE MD_Int_ContactStabilization_Parse

MODULE MD_Int_Friction_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_Friction_Type, ONLY: FrictionProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_FRICTION_Keyword
    !  /  (task24500-24599)
    PUBLIC :: MD_Interaction_Friction_Unified_Parse
    PUBLIC :: MD_Interaction_Friction_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction Friction Unified Configure
    SUBROUTINE MD_In_Fr_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 24550-24599
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_Friction_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_Friction_Unified_Configure

    !> Purpose: Parse MD Interaction Friction Unified
    SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, friction, context_name, status)
        !! Unified parse: int_type 'FRICTION' -> Parse_FRICTION_Keyword. Task: 24500-24549.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionProperties), INTENT(OUT) :: friction
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'FRICTION') THEN
            CALL Parse_FRICTION_Keyword(ast_node, friction, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_Friction_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_Friction_Unified_Parse

    !> Purpose: Process Parse FRICTION Keyword
    SUBROUTINE Parse_FRICTION_Keyword(ast_node, friction, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionProperties), INTENT(OUT) :: friction
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL friction%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 1) THEN
            friction%coef = ast_node%data_lines(1)%real_values(1)
        END IF
        IF (.NOT. friction%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction properties"
            RETURN
        END IF
    END SUBROUTINE Parse_FRICTION_Keyword

END MODULE MD_Int_Friction_Parse

MODULE MD_Int_FrictionCoefficient_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_FrictionCoefficient_Type, ONLY: FrictionCoefficientProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_FRICTION_COEFFICIENT_Keyword
    !  /  (task24600-24699)
    PUBLIC :: MD_Interaction_FrictionCoefficient_Unified_Parse
    PUBLIC :: MD_Interaction_FrictionCoefficient_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction FrictionCoefficient Unified Configure
    SUBROUTINE MD_In_Fr_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 24650-24699
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_FrictionCoefficient_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_FrictionCoefficient_Unified_Configure

    !> Purpose: Parse MD Interaction FrictionCoefficient Unified
    SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, frictionCoeff, context_name, status)
        !! Unified parse: int_type 'FRICTION_COEFFICIENT' or 'FRICTION coef' -> Parse_FRICTION_COEFFICIENT_Keyword. Task: 24600-24649.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionCoefficientProperties), INTENT(OUT) :: frictionCoeff
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'FRICTION_COEFFICIENT' .OR. TRIM(int_type) == 'FRICTION coef') THEN
            CALL Parse_FRICTION_COEFFICIENT_Keyword(ast_node, frictionCoeff, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_FrictionCoefficient_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_FrictionCoefficient_Unified_Parse

    !> Purpose: Process Parse FRICTION coef Keyword
    SUBROUTINE Pa_FR_CO_Keyword(ast_node, frictionCoeff, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionCoefficientProperties), INTENT(OUT) :: frictionCoeff
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL frictionCoeff%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 2) THEN
            frictionCoeff%staticCoefficient = ast_node%data_lines(1)%real_values(1)
            frictionCoeff%kineticCoefficient = ast_node%data_lines(1)%real_values(2)
        END IF
        IF (.NOT. frictionCoeff%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction coefficient properties"
            RETURN
        END IF
    END SUBROUTINE Parse_FRICTION_COEFFICIENT_Keyword

END MODULE MD_Int_FrictionCoefficient_Parse

MODULE MD_Int_FrictionOutput_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_FrictionOutput_Type, ONLY: FrictionOutputProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_FRICTION_OUTPUT_Keyword
    !  /  (task24900-24999)
    PUBLIC :: MD_Interaction_FrictionOutput_Unified_Parse
    PUBLIC :: MD_Interaction_FrictionOutput_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction FrictionOutput Unified Configure
    SUBROUTINE MD_In_Fr_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 24950-24999
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_FrictionOutput_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_FrictionOutput_Unified_Configure

    !> Purpose: Parse MD Interaction FrictionOutput Unified
    SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, frictionOutput, context_name, status)
        !! Unified parse: int_type 'FRICTION_OUTPUT' -> Parse_FRICTION_OUTPUT_Keyword. Task: 24900-24949.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionOutputProperties), INTENT(OUT) :: frictionOutput
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'FRICTION_OUTPUT' .OR. TRIM(int_type) == 'FRICTION OUTPUT') THEN
            CALL Parse_FRICTION_OUTPUT_Keyword(ast_node, frictionOutput, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_FrictionOutput_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_FrictionOutput_Unified_Parse

    !> Purpose: Process Parse FRICTION OUTPUT Keyword
    SUBROUTINE Pa_FR_OU_Keyword(ast_node, frictionOutput, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FrictionOutputProperties), INTENT(OUT) :: frictionOutput
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL frictionOutput%Init(TRIM(name), status)
        IF (.NOT. frictionOutput%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid friction output properties"
            RETURN
        END IF
    END SUBROUTINE Parse_FRICTION_OUTPUT_Keyword

END MODULE MD_Int_FrictionOutput_Parse

MODULE MD_Int_StickSlip_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_StickSlip_Type, ONLY: StickSlipProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_STICK_SLIP_Keyword
    !  /  (task25000-25099)
    PUBLIC :: MD_Interaction_StickSlip_Unified_Parse
    PUBLIC :: MD_Interaction_StickSlip_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction StickSlip Unified Configure
    SUBROUTINE MD_In_St_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25050-25099
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_StickSlip_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_StickSlip_Unified_Configure

    !> Purpose: Parse MD Interaction StickSlip Unified
    SUBROUTINE MD_In_St_Un_Parse(int_type, ast_node, stickSlip, context_name, status)
        !! Unified parse: int_type 'STICK_SLIP' -> Parse_STICK_SLIP_Keyword. Task: 25000-25049.
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(StickSlipProperties), INTENT(OUT) :: stickSlip
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'STICK_SLIP' .OR. TRIM(int_type) == 'STICK SLIP') THEN
            CALL Parse_STICK_SLIP_Keyword(ast_node, stickSlip, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_StickSlip_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_StickSlip_Unified_Parse

    !> Purpose: Process Parse STICK SLIP Keyword
    SUBROUTINE Parse_STICK_SLIP_Keyword(ast_node, stickSlip, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(StickSlipProperties), INTENT(OUT) :: stickSlip
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL stickSlip%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 3) THEN
            stickSlip%staticCoefficient = ast_node%data_lines(1)%real_values(1)
            stickSlip%kineticCoefficient = ast_node%data_lines(1)%real_values(2)
            stickSlip%criticalSlipVelocity = ast_node%data_lines(1)%real_values(3)
        END IF
        IF (.NOT. stickSlip%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid stick slip properties"
            RETURN
        END IF
    END SUBROUTINE Parse_STICK_SLIP_Keyword

END MODULE MD_Int_StickSlip_Parse

MODULE MD_Int_UserContact_Parse
!> [STUB]
!> Theory: (TODO)
!> Status: (TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_UserContact_Type, ONLY: UserContactProperties
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: Parse_USER_CONTACT_Keyword
    !  /  (task25500-25599)
    PUBLIC :: MD_Interaction_UserContact_Unified_Parse
    PUBLIC :: MD_Interaction_UserContact_Unified_Configure

CONTAINS

CONTAINS

    !> Purpose: Process MD Interaction UserContact Unified Configure
    SUBROUTINE MD_In_Us_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 25550-25599
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_UserContact_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Interaction_UserContact_Unified_Configure

    !> Purpose: Parse MD Interaction UserContact Unified
    SUBROUTINE MD_In_Us_Un_Parse(int_type, ast_node, userContact, context_name, status)
        !! Unified parse: int_type 'USER_CONTACT' -> Parse_USER_CONTACT_Keyword. Task: 25500-25549. (context_name unused; Keyword has no name param)
        CHARACTER(LEN=*), INTENT(IN) :: int_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(UserContactProperties), INTENT(OUT) :: userContact
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(int_type) == 'USER_CONTACT' .OR. TRIM(int_type) == 'USER CONTACT') THEN
            CALL Parse_USER_CONTACT_Keyword(ast_node, userContact, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Interaction_UserContact_Unified_Parse: unsupported int_type ' // TRIM(int_type)
        END IF
    END SUBROUTINE MD_Interaction_UserContact_Unified_Parse

    !> Purpose: Process Parse USER CONTACT Keyword
    SUBROUTINE Parse_USER_CONTACT_Keyword(ast_node, userContact, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(UserContactProperties), INTENT(OUT) :: userContact
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL userContact%Init("USER_CONTACT", status)
        IF (.NOT. userContact%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid user contact properties"
            RETURN
        END IF
    END SUBROUTINE Parse_USER_CONTACT_Keyword

END MODULE MD_Int_UserContact_Parse

!===============================================================================
! Module: MD_Int
! Layer:  L3_MD - Model Definition Layer
! Domain: Contact - Contact
! Feature: Interaction_Core (Interaction Core Types)
! Purpose:
!   Core interaction types for model definition layer. Provides interaction descriptor
!   types (MD_InterDesc, MD_ContDesc, MD_TieDesc, MD_CouplingDesc, MD_MPCDesc),
!   interaction state type (MD_InterSta), and interaction context type (MD_InterCtx).
!   Supports interaction initialization, layout registration for data platform
!   integration, and struct array creation. Types follow Desc/State/Ctx pattern:
!   Desc for read-only configuration, State for runtime state, Ctx for context
!   aggregation. Used by interaction manager and constraint commands for interaction
!   definition and management.
!
! Theory chain:
!   Interaction theory: Interactions define relationships between model entities (surfaces,
!   nodes, elements). Contact interaction: Defines contact between master and slave surfaces
!   with friction coefficient. Tie interaction: Binds slave surface to master surface
!   with no separation. Coupling interaction: Links reference node to surface nodes with
!   coupling type (kinematic/distributing). MPC interaction: Multi-point constraint
!   enforcing linear relationships between degrees of freedom. Interaction descriptor theory:
!   Descriptor types (Desc) contain read-only configuration data (IDs, names, surfaces,
!   properties). Interaction state theory: State types (State) contain runtime state data
!   (active flags, interaction IDs). Interaction context theory: Context types (Ctx)
!   aggregate references to descriptors and states. Data platform integration theory:
!   Register struct layouts and create struct arrays in data platform for persistence.
!   Layout registration: Define field names, types, offsets for struct serialization.
!   Struct array creation: Create arrays in data platform for storage. Ref: UFC Chapter
!   8 (Interaction types), Desc/State/Ctx pattern, data platform integration.
!
! Logic chain:
!   Interaction descriptor initialization: MD_InterDesc_Init -> Init DescBase (CAT_DESC,
!   'DESC::INTERACTION') -> Set interactionId, name, interactionType -> MD_InterDesc_RegLayout
!   -> Register fields (interactionId INT, name CHAR64, interactionType CHAR32) ->
!   MD_InterDesc_Ensure -> Create struct array. Contact descriptor: MD_ContDesc_Init ->
!   Init DescBase (CAT_DESC, 'DESC::CONTACT') -> Set contactId, name, masterSurface,
!   slaveSurface, frictionCoeff -> MD_ContDesc_RegLayout -> Register fields ->
!   MD_ContDesc_Ensure -> Create struct array. Tie descriptor: MD_TieDesc_Init -> Init DescBase
!   (CAT_DESC, 'DESC::TIE') -> Set tieId, name, masterSurface, slaveSurface ->
!   MD_TieDesc_RegLayout -> Register fields -> MD_TieDesc_Ensure -> Create struct array.
!   Coupling descriptor: MD_CouplingDesc_Init -> Init DescBase (CAT_DESC, 'DESC::COUPLING') ->
!   Set couplingId, name, couplingType, referenceNode, surface -> MD_CouplingDesc_RegLayout ->
!   Register fields -> MD_CouplingDesc_Ensure -> Create struct array. MPC descriptor:
!   MD_MPCDesc_Init -> Init DescBase (CAT_DESC, 'DESC::MPC') -> Set mpcId, name ->
!   MD_MPCDesc_RegLayout -> Register fields -> MD_MPCDesc_Ensure -> Create struct array.
!   Interaction state: MD_InterSta_Init -> Set category = CAT_STATE -> Set interactionId ->
!   MD_InterSta_RegLayout -> Register fields (interactionId INT, isActive INT) ->
!   MD_InterSta_Ensure -> Create struct array. Interaction context: MD_InterCtx_Init ->
!   Init CtxBase (CAT_CTX, 'CTX::INTERACTION') -> Set interactionId -> MD_InterCtx_RegLayout ->
!   Register fields (interactionId INT) -> MD_InterCtx_Ensure -> Create struct array.
!   Dependency: L3_MD Interaction Core -> L1 IF (DataPlatform, Error API, Precision),
!   L3_MD (Base ObjModel Core).
!
! Computation chain:
!   InterDesc_Init: Init CoreBase (CAT_DESC, 'DESC::INTERACTION') -> Set interactionId
!   (if present) -> Set name (if present) -> Set interactionType (if present).
!   InterDesc_RegLayout: Define fields array (3 fields) -> Set field names/types/offsets
!   (interactionId INT offset 0, name CHAR64 offset 4, interactionType CHAR32 offset 68) ->
!   Register struct type to data platform. InterDesc_Ensure: Check varName -> If empty,
!   set to 'UF_INTERACTIONDESC_' // interactionId -> Create struct array in data platform.
!   ContDesc_Init: Init CoreBase (CAT_DESC, 'DESC::CONTACT') -> Set contactId, name,
!   masterSurface, slaveSurface, frictionCoeff (if present). ContDesc_RegLayout: Register
!   fields (contactId INT, name CHAR64, masterSurface CHAR64, slaveSurface CHAR64,
!   frictionCoeff DP). ContDesc_Ensure: Set varName to 'UF_CONTACTDESC_' // contactId ->
!   Create struct array. TieDesc_Init: Init DescBase (CAT_DESC, 'DESC::TIE') -> Set tieId,
!   name, masterSurface, slaveSurface. TieDesc_RegLayout: Register fields (tieId INT, name
!   CHAR64, masterSurface CHAR64, slaveSurface CHAR64). TieDesc_Ensure: Set varName to
!   'UF_TIEDESC_' // tieId -> Create struct array. CouplingDesc_Init: Init CoreBase
!   (CAT_DESC, 'DESC::COUPLING') -> Set couplingId, name, couplingType, referenceNode,
!   surface. CouplingDesc_RegLayout: Register fields (couplingId INT, name CHAR64,
!   couplingType CHAR64, referenceNode CHAR64, surface CHAR64). CouplingDesc_Ensure: Set
!   varName to 'UF_COUPLINGDESC_' // couplingId -> Create struct array. MPCDesc_Init: Init
!   CoreBase (CAT_DESC, 'DESC::MPC') -> Set mpcId, name. MPCDesc_RegLayout: Register fields
!   (mpcId INT, name CHAR64). MPCDesc_Ensure: Set varName to 'UF_MPCDESC_' // mpcId ->
!   Create struct array. InterSta_Init: Set category = CAT_STATE -> Set interactionId
!   (if present). InterSta_RegLayout: Register fields (interactionId INT, isActive INT).
!   InterSta_Ensure: Set varName to 'UF_INTERACTIONSTATE_' // interactionId -> Create
!   struct array. InterCtx_Init: Init CoreBase (CAT_CTX, 'CTX::INTERACTION') -> Set
!   interactionId (if present). InterCtx_RegLayout: Register fields (interactionId INT).
!   InterCtx_Ensure: Set varName to 'UF_INTERACTIONCTX_' // interactionId -> Create struct
!   array.
!
! Data chain:
!   Input: interactionId, name, interactionType (for MD_InterDesc), contactId, name,
!   masterSurface, slaveSurface, frictionCoeff (for MD_ContDesc), tieId, name, masterSurface,
!   slaveSurface (for MD_TieDesc), couplingId, name, couplingType, referenceNode, surface
!   (for MD_CouplingDesc), mpcId, name (for MD_MPCDesc). Output: Initialized interaction
!   descriptors (MD_InterDesc, MD_ContDesc, MD_TieDesc, MD_CouplingDesc, MD_MPCDesc),
!   interaction state (MD_InterSta), interaction context (MD_InterCtx), registered struct
!   layouts in data platform, created struct arrays in data platform, status (error status).
!   State: Interaction descriptor state (initialized descriptors with IDs, names, surfaces,
!   properties), interaction state (interactionId, isActive flag), interaction context state
!   (interactionId), data platform state (registered struct types, created struct arrays).
!
! Data structure:
!   Container path: Contact (interaction core).
!   - Desc: MD_InterDesc (interaction descriptor with interactionId, name, interactionType),
!   MD_ContDesc (contact descriptor with contactId, name, masterSurface, slaveSurface,
!   frictionCoeff), MD_TieDesc (tie descriptor with tieId, name, masterSurface, slaveSurface),
!   MD_CouplingDesc (coupling descriptor with couplingId, name, couplingType, referenceNode,
!   surface), MD_MPCDesc (MPC descriptor with mpcId, name). Descriptors are read-only
!   configuration data.
!   - Algo: Initialization algorithms (MD_InterDesc_Init, MD_ContDesc_Init, etc.), layout
!   registration algorithms (MD_InterDesc_RegLayout, etc.), ensure algorithms (MD_InterDesc_Ensure,
!   etc.) for data platform integration.
!   - Ctx: MD_InterCtx (interaction context aggregating interactionId, providing context for
!   interaction operations).
!   - State: MD_InterSta (interaction state with interactionId, isActive flag for runtime
!   state management). Supporting types: DescBase, StateBase, CtxBase (base types from
!   MD_BaseObjModel), ErrorStatusType, StructFieldDesc (for data platform integration).
!
! Three-step mapping:
!   Interaction definition: Step level (define interactions with descriptors).
!   Layout registration: Step level (register struct layouts to data platform).
!   State management: Increment/iteration level (manage interaction state, active flags).
!
! Contents (A-Z):
!   Functions: (None - all subroutines)
!   Subroutines: MD_ContDesc_Ensure, MD_ContDesc_Init, MD_ContDesc_RegLayout,
!     MD_CouplingDesc_Ensure, MD_CouplingDesc_Init, MD_CouplingDesc_RegLayout,
!     MD_InterCtx_Ensure, MD_InterCtx_Init, MD_InterCtx_RegLayout, MD_InterDesc_Ensure,
!     MD_InterDesc_Init, MD_InterDesc_RegLayout, MD_InterSta_Ensure, MD_InterSta_Init,
!     MD_InterSta_RegLayout, MD_MPCDesc_Ensure, MD_MPCDesc_Init, MD_MPCDesc_RegLayout,
!     MD_TieDesc_Ensure, MD_TieDesc_Init, MD_TieDesc_RegLayout
!   Types: MD_ContDesc, MD_CouplingDesc, MD_InterCtx, MD_InterDesc, MD_InterSta, MD_MPCDesc,
!     MD_TieDesc
!
! Notes:
!   Core interaction types: Provides fundamental interaction type definitions following
!   Desc/State/Ctx pattern. Data platform integration: Registers struct layouts and creates
!   struct arrays in data platform for persistence. Type hierarchy: Types extend DescBase,
!   StateBase, or CtxBase for consistent interface. Layout registration: Defines field names,
!   types, offsets for struct serialization. Struct array creation: Creates arrays in data
!   platform with automatic varName generation. Used by interaction manager: Types are used
!   by MD_IntMgr for interaction management. Logic/Computation chain diagrams:
!   see MD_Interaction_Core_Chains.md
!
! Status: PROD | Last verified: 2026-03-02
!===============================================================================
MODULE MD_Int_Ctx_Core
    USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                               IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CtxBase, CAT_DESC, CAT_STATE, CAT_CTX
    USE IF_Err_Brg, ONLY: uf_set_error
    IMPLICIT NONE
    PRIVATE

    ! PUBLIC types (A-Z)
    PUBLIC :: MD_ContDesc, MD_CouplingDesc, MD_InterCtx, MD_InterDesc
    PUBLIC :: MD_InterSta, MD_MPCDesc, MD_TieDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_InterDesc
    INTEGER(i4) :: interactionId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=32) :: interactionType = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_InterDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_InterDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_InterDesc_Init
  END TYPE MD_InterDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_InterSta
    INTEGER(i4) :: interactionId = 0_i4
    LOGICAL :: isActive = .false.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_InterSta_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_InterSta_Ensure
    PROCEDURE, PUBLIC :: Init => MD_InterSta_Init
  END TYPE MD_InterSta

  TYPE, PUBLIC, EXTENDS(CtxBase) :: MD_InterCtx
    INTEGER(i4) :: interactionId = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_InterCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_InterCtx_Ensure
    PROCEDURE, PUBLIC :: Init => MD_InterCtx_Init
  END TYPE MD_InterCtx

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_ContDesc
    INTEGER(i4) :: contactId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: masterSurface = ""
    CHARACTER(len=64) :: slaveSurface = ""
    REAL(wp) :: frictionCoeff = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_ContDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_ContDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_ContDesc_Init
  END TYPE MD_ContDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_TieDesc
    INTEGER(i4) :: tieId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: masterSurface = ""
    CHARACTER(len=64) :: slaveSurface = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_TieDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_TieDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_TieDesc_Init
  END TYPE MD_TieDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_CouplingDesc
    INTEGER(i4) :: couplingId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: couplingType = ""
    CHARACTER(len=64) :: referenceNode = ""
    CHARACTER(len=64) :: surface = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_CouplingDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_CouplingDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_CouplingDesc_Init
  END TYPE MD_CouplingDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_MPCDesc
    INTEGER(i4)       :: mpcId    = 0
    CHARACTER(len=64) :: name     = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_MPCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure    => MD_MPCDesc_Ensure
    PROCEDURE, PUBLIC :: Init      => MD_MPCDesc_Init
  END TYPE MD_MPCDesc


CONTAINS

    !===========================================================================
    ! Subroutine Index (Alphabetical Order A-Z)
    !===========================================================================

    ! MD_TieDesc_Ensure - Process MD TieDesc Ensure
    ! MD_CouplingDesc_Init - Initialize MD CplDesc
    ! MD_TieDesc_RegLayout - Process MD TieDesc RegLayout
    ! MD_ContDesc_Ensure - Process MD ContDesc Ensure
    ! MD_TieDesc_Init - Initialize MD TieDesc
    ! MD_MPCDesc_RegLayout - Process MD MPCDesc RegLayout
    ! MD_MPCDesc_Ensure - Process MD MPCDesc Ensure
    ! MD_MPCDesc_Init - Initialize MD MPCDesc
    ! MD_CouplingDesc_RegLayout - Process MD CplDesc RegLayout
    ! MD_CouplingDesc_Ensure - Process MD CplDesc Ensure
    ! MD_ContDesc_RegLayout - Process MD ContDesc RegLayout
    ! MD_InterSta_Init - Initialize MD InterSta
    ! MD_InterSta_RegLayout - Process MD InterSta RegLayout
    ! MD_InterDesc_Ensure - Process MD InterDesc Ensure
    ! MD_InterDesc_Init - Initialize MD InterDesc
    ! MD_InterDesc_RegLayout - Process MD InterDesc RegLayout
    ! MD_InterCtx_Ensure - Process MD InterCtx Ensure
    ! MD_ContDesc_Init - Initialize MD ContDesc
    ! MD_InterCtx_RegLayout - Process MD InterCtx RegLayout
    ! MD_InterSta_Ensure - Process MD InterSta Ensure
    ! MD_InterCtx_Init - Initialize MD InterCtx

    !===========================================================================

    !> Purpose: Process MD TieDesc Ensure
  SUBROUTINE MD_TieDesc_Ensure(this)
    CLASS(MD_TieDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_TIEDESC_', this%tieId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_TieDesc_Ensure")
  END SUBROUTINE MD_TieDesc_Ensure

    !> Purpose: Initialize MD CplDesc
  SUBROUTINE MD_CouplingDesc_Init(this, couplingId, name, couplingType, referenceNode, surface)
    CLASS(MD_CouplingDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: couplingId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, couplingType, referenceNode, surface
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::COUPLING')
    IF (PRESENT(couplingId)) this%couplingId = couplingId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(couplingType)) this%couplingType = couplingType
    IF (PRESENT(referenceNode)) this%referenceNode = referenceNode
    IF (PRESENT(surface)) this%surface = surface
  END SUBROUTINE MD_CouplingDesc_Init

    !> Purpose: Process MD TieDesc RegLayout
  SUBROUTINE MD_TieDesc_RegLayout(this)
    CLASS(MD_TieDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(4)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'tieId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'masterSurface'
    fields(3)%data_type = IF_DATA_TYPE_CHAR
    fields(3)%elem_len = 64
    fields(3)%offset_bytes = offset
    offset = offset + 64
    fields(4)%field_name = 'slaveSurface'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 64
    fields(4)%offset_bytes = offset
    offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 4, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_TieDesc_RegLayout")
  END SUBROUTINE MD_TieDesc_RegLayout

    !> Purpose: Process MD ContDesc Ensure
  SUBROUTINE MD_ContDesc_Ensure(this)
    CLASS(MD_ContDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_CONTACTDESC_', this%contactId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_ContDesc_Ensure")
  END SUBROUTINE MD_ContDesc_Ensure

    !> Purpose: Initialize MD TieDesc
  SUBROUTINE MD_TieDesc_Init(this, tieId, name, masterSurface, slaveSurface)
    CLASS(MD_TieDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: tieId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, masterSurface, slaveSurface
    CALL this%DescBase%Init(CAT_DESC, 'DESC::TIE')
    IF (PRESENT(tieId)) this%tieId = tieId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(masterSurface)) this%masterSurface = masterSurface
    IF (PRESENT(slaveSurface)) this%slaveSurface = slaveSurface
  END SUBROUTINE MD_TieDesc_Init

    !> Purpose: Process MD MPCDesc RegLayout
  SUBROUTINE MD_MPCDesc_RegLayout(this)
    CLASS(MD_MPCDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'mpcId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_MPCDesc_RegLayout")
  END SUBROUTINE MD_MPCDesc_RegLayout

    !> Purpose: Process MD MPCDesc Ensure
  SUBROUTINE MD_MPCDesc_Ensure(this)
    CLASS(MD_MPCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MPCDESC_', this%mpcId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_MPCDesc_Ensure")
  END SUBROUTINE MD_MPCDesc_Ensure

    !> Purpose: Initialize MD MPCDesc
  SUBROUTINE MD_MPCDesc_Init(this, mpcId, name)
    CLASS(MD_MPCDesc),    INTENT(INOUT) :: this
    INTEGER(i4),       INTENT(IN),    OPTIONAL :: mpcId
    CHARACTER(len=*),  INTENT(IN),    OPTIONAL :: name
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::MPC')
    IF (PRESENT(mpcId)) this%mpcId = mpcId
    IF (PRESENT(name))  this%name  = name
  END SUBROUTINE MD_MPCDesc_Init

    !> Purpose: Process MD CplDesc RegLayout
  SUBROUTINE MD_CouplingDesc_RegLayout(this)
    CLASS(MD_CouplingDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'couplingId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'couplingType'
    fields(3)%data_type = IF_DATA_TYPE_CHAR
    fields(3)%elem_len = 64
    fields(3)%offset_bytes = offset
    offset = offset + 64
    fields(4)%field_name = 'referenceNode'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 64
    fields(4)%offset_bytes = offset
    offset = offset + 64
    fields(5)%field_name = 'surface'
    fields(5)%data_type = IF_DATA_TYPE_CHAR
    fields(5)%elem_len = 64
    fields(5)%offset_bytes = offset
    offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_CouplingDesc_RegLayout")
  END SUBROUTINE MD_CouplingDesc_RegLayout

    !> Purpose: Process MD CplDesc Ensure
  SUBROUTINE MD_CouplingDesc_Ensure(this)
    CLASS(MD_CouplingDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_COUPLINGDESC_', this%couplingId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_CouplingDesc_Ensure")
  END SUBROUTINE MD_CouplingDesc_Ensure

    !> Purpose: Process MD ContDesc RegLayout
  SUBROUTINE MD_ContDesc_RegLayout(this)
    CLASS(MD_ContDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'contactId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'masterSurface'
    fields(3)%data_type = IF_DATA_TYPE_CHAR
    fields(3)%elem_len = 64
    fields(3)%offset_bytes = offset
    offset = offset + 64
    fields(4)%field_name = 'slaveSurface'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 64
    fields(4)%offset_bytes = offset
    offset = offset + 64
    fields(5)%field_name = 'frictionCoeff'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_ContDesc_RegLayout")
  END SUBROUTINE MD_ContDesc_RegLayout

    !> Purpose: Initialize MD InterSta
  SUBROUTINE MD_InterSta_Init(this, interactionId)
    CLASS(MD_InterSta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: interactionId
    this%category = CAT_STATE
    IF (PRESENT(interactionId)) this%interactionId = interactionId
  END SUBROUTINE MD_InterSta_Init

    !> Purpose: Process MD InterSta RegLayout
  SUBROUTINE MD_InterSta_RegLayout(this)
    CLASS(MD_InterSta), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'interactionId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'isActive'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterSta_RegLayout")
  END SUBROUTINE MD_InterSta_RegLayout

    !> Purpose: Process MD InterDesc Ensure
  SUBROUTINE MD_InterDesc_Ensure(this)
    CLASS(MD_InterDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_INTERACTIONDESC_', this%interactionId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterDesc_Ensure")
  END SUBROUTINE MD_InterDesc_Ensure

    !> Purpose: Initialize MD InterDesc
  SUBROUTINE MD_InterDesc_Init(this, interactionId, name, interactionType)
    CLASS(MD_InterDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: interactionId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, interactionType
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::INTERACTION')
    IF (PRESENT(interactionId)) this%interactionId = interactionId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(interactionType)) this%interactionType = interactionType
  END SUBROUTINE MD_InterDesc_Init

    !> Purpose: Process MD InterDesc RegLayout
  SUBROUTINE MD_InterDesc_RegLayout(this)
    CLASS(MD_InterDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'interactionId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'interactionType'
    fields(3)%data_type = IF_DATA_TYPE_CHAR
    fields(3)%elem_len = 32
    fields(3)%offset_bytes = offset
    offset = offset + 32
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterDesc_RegLayout")
  END SUBROUTINE MD_InterDesc_RegLayout

    !> Purpose: Process MD InterCtx Ensure
  SUBROUTINE MD_InterCtx_Ensure(this)
    CLASS(MD_InterCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_INTERACTIONCTX_', this%interactionId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterCtx_Ensure")
  END SUBROUTINE MD_InterCtx_Ensure

    !> Purpose: Initialize MD ContDesc
  SUBROUTINE MD_ContDesc_Init(this, contactId, name, masterSurface, slaveSurface, frictionCoeff)
    CLASS(MD_ContDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: contactId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, masterSurface, slaveSurface
    REAL(wp), INTENT(IN), OPTIONAL :: frictionCoeff
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::CONTACT')
    IF (PRESENT(contactId)) this%contactId = contactId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(masterSurface)) this%masterSurface = masterSurface
    IF (PRESENT(slaveSurface)) this%slaveSurface = slaveSurface
    IF (PRESENT(frictionCoeff)) this%frictionCoeff = frictionCoeff
  END SUBROUTINE MD_ContDesc_Init

    !> Purpose: Process MD InterCtx RegLayout
  SUBROUTINE MD_InterCtx_RegLayout(this)
    CLASS(MD_InterCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(1)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'interactionId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 1, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterCtx_RegLayout")
  END SUBROUTINE MD_InterCtx_RegLayout

    !> Purpose: Process MD InterSta Ensure
  SUBROUTINE MD_InterSta_Ensure(this)
    CLASS(MD_InterSta), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_INTERACTIONSTATE_', this%interactionId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_InterSta_Ensure")
  END SUBROUTINE MD_InterSta_Ensure

    !> Purpose: Initialize MD InterCtx
  SUBROUTINE MD_InterCtx_Init(this, interactionId)
    CLASS(MD_InterCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: interactionId
    CALL this%CoreBase%Init(CAT_CTX, 'CTX::INTERACTION')
    IF (PRESENT(interactionId)) this%interactionId = interactionId
  END SUBROUTINE MD_InterCtx_Init

END MODULE MD_Int_Ctx_Core
!===============================================================================
! Module: MD_IntMgr
! Layer:  L3_MD - Model Definition Layer
! Domain: Contact - Contact
! Feature: Interaction_Mgr (Interaction Manager)
! Purpose:
!   Unified interaction manager module for interaction lifecycle management. Provides
!   interaction creation, deletion, queries, manipulation operations, and relationship
!   queries. Manages interactions in model (contact, tie, coupling, MPC). Supports
!   interaction addition to steps, removal from steps, property ID management, active
!   state management, type queries. Extends BaseManager for consistent manager interface.
!   Uses global instance g_interaction_m for module-level access. Provides both manager
!   interface (MD_Inter_Mgr methods) and legacy UF_Interaction interface for backward
!   compatibility.
!
! Theory chain:
!   Interaction manager theory: Unified interface for interaction lifecycle management
!   (create, delete, find, get, list, validate, get statistics). Manager pattern: Extends
!   BaseManager for consistent manager interface across model entities. Interaction lifecycle:
!   Creation -> Validation -> Storage -> Query -> Deletion. Interaction relationships:
!   Interactions linked to steps, properties, surfaces. Step association theory: Interactions
!   can be added to or removed from analysis steps. Property association theory: Interactions
!   reference property IDs for contact properties, friction properties, etc. Active state
!   theory: Interactions can be activated/deactivated for runtime control. Type queries:
!   Query interaction type (contact, tie, coupling, MPC). Consistency validation: Validate
!   interaction consistency (surfaces exist, properties valid, etc.). Statistics: Get
!   interaction statistics (count, types, etc.). Ref: Manager pattern, BaseManager interface,
!   interaction lifecycle management.
!
! Logic chain:
!   Manager initialization: MD_Inter_Mgr_Init -> Set max_capacity -> Initialize BaseManager ->
!   Set model pointer -> Mark initialized. Interaction creation: MD_Inter_Mgr_Create ->
!   Validate name -> Check if exists -> Create interaction -> Add to model -> Return ID.
!   Interaction deletion: MD_Inter_Mgr_Delete -> Validate ID -> Remove from model ->
!   Update indices. Interaction find: MD_Inter_Mgr_Find -> Search by name -> Return ID or 0.
!   Interaction get: MD_Inter_Mgr_Get -> Validate ID -> Return interaction pointer.
!   Interaction list: MD_Inter_Mgr_List -> Collect all interaction names -> Return count.
!   Interaction validation: MD_Inter_Mgr_Valid -> Validate ID range -> Check if exists.
!   Consistency validation: MD_Inter_Mgr_ValidCons -> Validate all interactions -> Check
!   surfaces, properties -> Return status. Statistics: MD_Inter_Mgr_GetStat -> Collect
!   statistics -> Format string -> Return. Legacy interface: UF_Interaction_Add -> Create
!   interaction via manager -> Set master/slave surfaces -> Set property ID. UF_Interaction_FindByName
!   -> Find via manager -> Return index. UF_Interaction_Delete -> Delete via manager.
!   UF_Interaction_AddToStep -> Add interaction to step -> Update step interactions.
!   UF_Interact_RemoveFromStep -> Remove interaction from step. UF_Interaction_GetType ->
!   Get interaction type from model. UF_Interaction_SetActive -> Set active flag in state.
!   UF_Interaction_GetPropertyId -> Get property ID from interaction. UF_Interaction_SetPropertyId
!   -> Set property ID in interaction. Dependency: L3_MD Interaction Mgr -> L1 IF (Error API,
!   Precision), L3_MD (Base ObjModel Core, TypeSystem).
!
! Computation chain:
!   Init: Validate max_capacity -> Call BaseManager%Init -> Set model pointer -> Mark
!   initialized. Create: Validate name (non-empty) -> Check if name exists (via Find) ->
!   If exists, return error -> Get next ID -> Create interaction in model -> Set name,
!   type -> Add to interactions array -> Return ID. Delete: Validate ID -> Check if exists
!   -> Remove interaction from array -> Shift remaining interactions -> Update indices ->
!   Decrement count. Find: Loop through interactions -> Compare names -> Return index if
!   found -> Return 0 if not found. Get: Validate ID -> Check if exists -> Return pointer
!   to interaction -> Return NULL if invalid. List: Allocate names array -> Loop through
!   interactions -> Copy names -> Return count. Valid: Check if ID >= 1 AND ID <= count ->
!   Return IF_STATUS_OK if valid -> Return IF_STATUS_INVALID if invalid. ValidCons: Loop through
!   interactions -> Validate surfaces exist -> Validate properties exist -> Check consistency
!   -> Return IF_STATUS_OK if all valid -> Return IF_STATUS_INVALID if any invalid. GetStat: Count
!   interactions by type -> Format statistics string -> Return. UF_Interaction_Add: Validate
!   inputs -> Find or create interaction -> Set masterSurfId, slaveSurfId -> Set propertyId
!   -> Set type -> Add to model. UF_Interaction_FindByName: Call manager Find -> Return
!   index. UF_Interaction_Delete: Validate index -> Call manager Delete -> Remove from
!   model. UF_Interaction_AddToStep: Validate stepIndex -> Find interaction -> Add to step
!   interactions array. UF_Interact_RemoveFromStep: Validate stepIndex -> Find interaction
!   -> Remove from step interactions array. UF_Interaction_GetType: Find interaction -> Get
!   type from interaction -> Return type. UF_Interaction_SetActive: Find interaction -> Set
!   isActive flag in state. UF_Interaction_GetPropertyId: Find interaction -> Get propertyId
!   from interaction -> Return propertyId. UF_Interaction_SetPropertyId: Find interaction ->
!   Set propertyId in interaction.
!
! Data chain:
!   Input: max_capacity (manager capacity), name (interaction name), intType (interaction
!   type), masterSurfId, slaveSurfId (surface IDs), propertyId (property ID), id (interaction
!   ID), stepIndex (step index), interactionName (interaction name for lookup), isActive
!   (active flag). Output: Created interaction (with assigned ID), interaction ID (from Find),
!   interaction pointer (from Get), interaction names array (from List), validation status,
!   consistency status, statistics string, error status (ierr). State: MD_Inter_Mgr state
!   (model pointer, BaseManager state with capacity, count, storage), model state (interactions
!   array with interaction definitions), interaction state (active flags, property IDs),
!   step state (step interactions arrays).
!
! Data structure:
!   Container path: Contact (interaction manager).
!   - Desc: Interaction descriptors (MD_InterDesc, MD_ContDesc, MD_TieDesc, MD_CouplingDesc,
!   MD_MPCDesc) stored in model%desc%interactions. Descriptors contain interaction configuration
!   (IDs, names, types, surfaces, properties).
!   - Algo: Manager algorithms (MD_Inter_Mgr_Init, MD_Inter_Mgr_Create, MD_Inter_Mgr_Delete,
!   MD_Inter_Mgr_Find, MD_Inter_Mgr_Get, MD_Inter_Mgr_List, MD_Inter_Mgr_Valid,
!   MD_Inter_Mgr_ValidCons, MD_Inter_Mgr_GetStat), legacy interface algorithms
!   (UF_Interaction_Add, UF_Interaction_FindByName, UF_Interaction_Delete,
!   UF_Interaction_AddToStep, UF_Interact_RemoveFromStep, UF_Interaction_GetType,
!   UF_Interaction_SetActive, UF_Interaction_GetPropertyId, UF_Interaction_SetPropertyId).
!   - Ctx: MD_Inter_Mgr (interaction manager context aggregating model pointer, providing
!   manager interface), g_interaction_m (global manager instance for module-level access).
!   - State: Interaction state (MD_InterSta with interactionId, isActive flag) stored in
!   model state, step interactions (arrays of interaction IDs per step). Supporting types:
!   BaseManager (base manager type), UF_Model, UF_Interaction (from MD_TypeSystem).
!
! Three-step mapping:
!   Interaction management: Step level (create, delete, manage interactions).
!   Step association: Step level (add/remove interactions from steps).
!   State management: Increment/iteration level (manage active flags, property IDs).
!
! Contents (A-Z):
!   Functions: MD_Inter_Mgr_Find, MD_Inter_Mgr_GetCnt
!   Subroutines: MD_Inter_Mgr_Create, MD_Inter_Mgr_Delete, MD_Inter_Mgr_Final,
!     MD_Inter_Mgr_Get, MD_Inter_Mgr_GetStat, MD_Inter_Mgr_Init, MD_Inter_Mgr_List,
!     MD_Inter_Mgr_Valid, MD_Inter_Mgr_ValidCons, UF_Interact_RemoveFromStep,
!     UF_Interaction_Add, UF_Interaction_AddToStep, UF_Interaction_Delete,
!     UF_Interaction_FindByName, UF_Interaction_GetPropertyId, UF_Interaction_GetType,
!     UF_Interaction_SetActive, UF_Interaction_SetPropertyId
!   Types: MD_Inter_Mgr, g_interaction_m (global instance)
!
! Notes:
!   Unified interaction manager: Provides unified interface for interaction lifecycle management.
!   BaseManager extension: Extends BaseManager for consistent manager interface. Global instance:
!   Uses g_interaction_m for module-level access. Legacy interface: Maintains backward
!   compatibility with UF_Interaction interface. Step association: Supports adding/removing
!   interactions from steps. Property management: Supports getting/setting property IDs.
!   Active state: Supports activating/deactivating interactions. Consistency validation:
!   Validates interaction consistency (surfaces, properties). Statistics: Provides interaction
!   statistics. Logic/Computation chain diagrams: see MD_Interaction_Mgr_Chains.md
!
! Status: PROD | Last verified: 2026-03-02
!===============================================================================
MODULE MD_Int_Ctx_Mgr
    USE IF_Err_Brg, ONLY: init_error_status
    USE IF_Prec_Core, ONLY: wp, i4
      USE MD_Base_ObjModel, ONLY: BaseManager, ErrorStatusType, IF_STATUS_OK, IF_STATUS_INVALID, STATUS_NOT_FOUNDD
    USE MD_TypeSystem, ONLY: UF_Model, UF_Interaction

    IMPLICIT NONE
    PRIVATE

    !===========================================================================
    ! Interaction Manager Type (extends BaseManager)
    !===========================================================================
    TYPE, PUBLIC, EXTENDS(BaseManager) :: MD_Inter_Mgr
        TYPE(UF_Model), POINTER :: model => NULL()
    CONTAINS
        ! BaseManager interface implementation
        PROCEDURE :: Init => MD_Inter_Mgr_Init
        PROCEDURE :: Final => MD_Inter_Mgr_Final
        PROCEDURE :: Create => MD_Inter_Mgr_Create
        PROCEDURE :: Delete => MD_Inter_Mgr_Delete
        PROCEDURE :: Find => MD_Inter_Mgr_Find
        PROCEDURE :: Get => MD_Inter_Mgr_Get
        PROCEDURE :: GetCount => MD_Inter_Mgr_GetCnt
        PROCEDURE :: List => MD_Inter_Mgr_List
        PROCEDURE :: Valid => MD_Inter_Mgr_Valid
        PROCEDURE :: ValidateConsistency => MD_Inter_Mgr_ValidCons
        PROCEDURE :: GetStatistics => MD_Inter_Mgr_GetStat
    END TYPE MD_Inter_Mgr

    ! Global instance
    TYPE(MD_Inter_Mgr), SAVE, PUBLIC :: g_interaction_m

    !===========================================================================
    ! PUBLIC interfaces (A-Z)
    !===========================================================================
    PUBLIC :: UF_Interact_RemoveFromStep, UF_Interaction_Add
    PUBLIC :: UF_Interaction_AddToStep, UF_Interaction_Delete
    PUBLIC :: UF_Interaction_FindByName, UF_Interaction_GetPropertyId
    PUBLIC :: UF_Interaction_GetType, UF_Interaction_SetActive
    PUBLIC :: UF_Interaction_SetPropertyId

CONTAINS

    !===========================================================================
    ! Subroutine Index (Alphabetical Order A-Z)
    !===========================================================================

    ! UF_Interaction_Delete - Process UF Interaction Delete
    ! UF_Interaction_AddToStep - Process UF Interaction AddToStep
    ! UF_Interaction_Delete - Process UF Interaction Delete
    ! UF_Interaction_Add - Add UF Interaction
    ! UF_Interaction_FindByName - Process UF Interaction FindByName
    ! UF_Interaction_GetPropertyId - Process UF Interaction GetPropertyId
    ! UF_Interaction_SetPropertyId - Process UF Interaction SetPropertyId
    ! UF_Interaction_SetActive - Process UF Interaction SetActive
    ! UF_Interact_RemoveFromStep - Process UF Interact RemoveFromStep
    ! UF_Interaction_GetType - Process UF Interaction GetType
    ! MD_Inter_Mgr_GetStat - Process MD Inter Mgr GetStat
    ! MD_Inter_Mgr_Delete - Process MD Inter Mgr Delete
    ! MD_Inter_Mgr_Find - Find MD Inter Mgr
    ! MD_Inter_Mgr_Create - Process MD Inter Mgr Create
    ! MD_Inter_Mgr_Init - Initialize MD Inter Mgr
    ! MD_Inter_Mgr_Final - Process MD Inter Mgr Final
    ! MD_Inter_Mgr_Valid - Validate MD Inter Mgr
    ! MD_Inter_Mgr_ValidCons - Process MD Inter Mgr ValidCons
    ! MD_Inter_Mgr_List - Process MD Inter Mgr List
    ! MD_Inter_Mgr_Get - Get MD Inter Mgr
    ! MD_Inter_Mgr_GetCnt - Process MD Inter Mgr GetCnt

    !===========================================================================

    !> Purpose: Process UF Interaction Delete
  subroutine UF_Interaction_Delete(model, name, ierr)
    !! Delete interaction by name
    type(UF_Model), intent(inout) :: model
    character(len=*), intent(in) :: name
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: idx

    call UF_Interaction_FindByName(model, name, idx, ierr)
    if (idx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      return
    end if

    call UF_Interaction_Delete(model, idx, ierr)
  end subroutine UF_Interaction_Delete

    !> Purpose: Process UF Interaction AddToStep
  subroutine UF_Interaction_AddToStep(model, stepIndex, interactionName, ierr)
    !! Add interaction to step
    type(UF_Model), intent(inout) :: model
    integer(i4), intent(in) :: stepIndex
    character(len=*), intent(in) :: interactionName
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx, i, n_interactions
    type(UF_Interaction), allocatable :: tmp(:)

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      return
    end if

    ! Check if stepIndex is valid
    if (stepIndex < 1_i4 .or. stepIndex > size(model%steps)) then
      if (present(ierr)) ierr = 3_i4  ! Invalid step index
      return
    end if

    ! Add the interaction to the step
    if (.not. allocated(model%steps(stepIndex)%interactions)) then
      ! First interaction in this step
      allocate(model%steps(stepIndex)%interactions(1_i4))
      model%steps(stepIndex)%interactions(1) = interactionIdx
    else
      ! Check if the interaction is already in the step
      n_interactions = size(model%steps(stepIndex)%interactions)
      do i = 1_i4, n_interactions
        if (model%steps(stepIndex)%interactions(i) == interactionIdx) then
          ! Interaction already in step
          return
        end if
      end do

      ! Add the interaction to the step
      allocate(tmp(n_interactions + 1_i4))
      tmp(1:n_interactions) = model%steps(stepIndex)%interactions
      tmp(n_interactions + 1) = interactionIdx
      call MOVE_ALLOC(tmp, model%steps(stepIndex)%interactions)
    end if
  end subroutine UF_Interaction_AddToStep

    !> Purpose: Process UF Interaction Delete
  subroutine UF_Interaction_Delete(model, idx, ierr)
    !! Delete interaction by index
    type(UF_Model), intent(inout) :: model
    integer(i4), intent(in) :: idx
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: n, i
    type(UF_Interaction), allocatable :: tmp(:)

    if (present(ierr)) ierr = 0_i4

    if (.not. allocated(model%desc%interactions)) then
      if (present(ierr)) ierr = 1_i4  ! No interactions defined
      return
    end if

    n = size(model%desc%interactions)
    if (idx < 1_i4 .or. idx > n) then
      if (present(ierr)) ierr = 2_i4  ! Invalid index
      return
    end if

    if (n == 1_i4) then
      ! Only one interaction, deallocate it
      call RW_Deallocate(model%desc%interactions)
    else
      ! More than one interaction, remove the specified one
      call RW_Allocate(tmp, n-1)
      do i = 1_i4, n-1
        if (i < idx) then
          tmp(i) = model%desc%interactions(i)
        else
          tmp(i) = model%desc%interactions(i+1)
        end if
      end do
      call RW_Deallocate(model%desc%interactions)
      call RW_Allocate(model%desc%interactions, n-1)
      model%desc%interactions = tmp
      call RW_Deallocate(tmp)
    end if
  end subroutine UF_Interaction_Delete

    !> Purpose: Add UF Interaction
  subroutine UF_Interaction_Add(model, name, intType, masterSurfId, slaveSurfId, &
                                propertyId, idx, ierr)
    !! Add interaction to model
    type(UF_Model), intent(inout) :: model
    character(len=*), intent(in) :: name
    integer(i4), intent(in) :: intType
    integer(i4), intent(in) :: masterSurfId, slaveSurfId
    integer(i4), intent(in), optional :: propertyId
    integer(i4), intent(out), optional :: idx
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: n
    type(UF_Interaction), allocatable :: tmp(:)

    if (allocated(model%desc%interactions)) then
      n = size(model%desc%interactions)
      call RW_Allocate(tmp, n)
      tmp = model%desc%interactions
      call RW_Deallocate(model%desc%interactions)
      call RW_Allocate(model%desc%interactions, n+1)
      model%desc%interactions(1:n) = tmp
      call RW_Deallocate(tmp)
    else
      n = 0
      call RW_Allocate(model%desc%interactions, 1)
    end if

    model%desc%interactions(n+1)%name = name
    model%desc%interactions(n+1)%interactionType = intType
    model%desc%interactions(n+1)%masterSurfId = masterSurfId
    model%desc%interactions(n+1)%slaveSurfId = slaveSurfId
    if (present(propertyId)) then
      model%desc%interactions(n+1)%propertyId = propertyId
    else
      model%desc%interactions(n+1)%propertyId = 0_i4
    end if

    if (present(idx)) idx = n+1
    if (present(ierr)) ierr = 0_i4
  end subroutine UF_Interaction_Add

    !> Purpose: Process UF Interaction FindByName
  subroutine UF_Interaction_FindByName(model, name, idx, ierr)
    !! Find interaction by name
    type(UF_Model), intent(in) :: model
    character(len=*), intent(in) :: name
    integer(i4), intent(out) :: idx
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: i

    idx = 0_i4
    if (present(ierr)) ierr = 0_i4

    if (.not. allocated(model%desc%interactions)) then
      if (present(ierr)) ierr = 1_i4  ! No interactions defined
      return
    end if

    do i = 1_i4, size(model%desc%interactions)
      if (trim(model%desc%interactions(i)%name) == trim(name)) then
        idx = i
        return
      end if
    end do

    if (present(ierr)) ierr = 2_i4  ! Interaction not found
  end subroutine UF_Interaction_FindByName

    !> Purpose: Process UF Interaction GetPropertyId
  subroutine UF_Interaction_GetPropertyId(model, interactionName, propertyId, ierr)
    !! Get interaction property ID
    type(UF_Model), intent(in) :: model
    character(len=*), intent(in) :: interactionName
    integer(i4), intent(out) :: propertyId
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      propertyId = 0_i4
      return
    end if

    ! Return the property ID
    propertyId = model%desc%interactions(interactionIdx)%propertyId
  end subroutine UF_Interaction_GetPropertyId

    !> Purpose: Process UF Interaction SetPropertyId
  subroutine UF_Interaction_SetPropertyId(model, interactionName, propertyId, ierr)
    !! Set interaction property ID
    type(UF_Model), intent(inout) :: model
    character(len=*), intent(in) :: interactionName
    integer(i4), intent(in) :: propertyId
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      return
    end if

    ! Set the property ID
    model%desc%interactions(interactionIdx)%propertyId = propertyId
  end subroutine UF_Interaction_SetPropertyId

    !> Purpose: Process UF Interaction SetActive
  subroutine UF_Interaction_SetActive(model, interactionName, isActive, ierr)
    !! Set interaction active state
    type(UF_Model), intent(inout) :: model
    character(len=*), intent(in) :: interactionName
    logical, intent(in) :: isActive
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      return
    end if

    ! Set the interaction's active state
    model%desc%interactions(interactionIdx)%isActive = isActive
  end subroutine UF_Interaction_SetActive

    !> Purpose: Process UF Interact RemoveFromStep
  subroutine UF_Interact_RemoveFromStep(model, stepIndex, interactionName, ierr)
    !! Remove interaction from step
    type(UF_Model), intent(inout) :: model
    integer(i4), intent(in) :: stepIndex
    character(len=*), intent(in) :: interactionName
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx, i, n_interactions, found_idx
    type(UF_Interaction), allocatable :: tmp(:)

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      return
    end if

    ! Check if stepIndex is valid
    if (stepIndex < 1_i4 .or. stepIndex > size(model%steps)) then
      if (present(ierr)) ierr = 3_i4  ! Invalid step index
      return
    end if

    ! Check if the step has any interactions
    if (.not. allocated(model%steps(stepIndex)%interactions)) then
      ! No interactions in this step
      return
    end if

    ! Find the interaction in the step
    n_interactions = size(model%steps(stepIndex)%interactions)
    found_idx = 0_i4
    do i = 1_i4, n_interactions
      if (model%steps(stepIndex)%interactions(i) == interactionIdx) then
        found_idx = i
        exit
      end if
    end do

    if (found_idx == 0_i4) then
      ! Interaction not in this step
      return
    end if

    ! Remove the interaction from the step
    if (n_interactions == 1_i4) then
      ! Only one interaction in this step, deallocate it
      deallocate(model%steps(stepIndex)%interactions)
    else
      ! More than one interaction, remove the specified one
      allocate(tmp(n_interactions - 1_i4))
      tmp(1:found_idx-1) = model%steps(stepIndex)%interactions(1:found_idx-1)
      tmp(found_idx:n_interactions-1) = model%steps(stepIndex)%interactions(found_idx+1:n_interactions)
      call MOVE_ALLOC(tmp, model%steps(stepIndex)%interactions)
    end if
  end subroutine UF_Interact_RemoveFromStep

    !> Purpose: Process UF Interaction GetType
  subroutine UF_Interaction_GetType(model, interactionName, interactionType, ierr)
    !! Get interaction type
    type(UF_Model), intent(in) :: model
    character(len=*), intent(in) :: interactionName
    character(len=*), intent(out) :: interactionType
    integer(i4), intent(out), optional :: ierr

    integer(i4) :: interactionIdx

    if (present(ierr)) ierr = 0_i4

    ! Find the interaction by name
    call UF_Interaction_FindByName(model, interactionName, interactionIdx, ierr)
    if (interactionIdx == 0_i4) then
      ! Interaction not found, error already set by UF_Interaction_FindByName
      interactionType = ""
      return
    end if

    ! Return the interaction type
    interactionType = model%desc%interactions(interactionIdx)%interactionType
  end subroutine UF_Interaction_GetType

    !> Purpose: Process MD Inter Mgr GetStat
  SUBROUTINE MD_Inter_Mgr_GetStat(this, stats, status)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      ! Note: stats parameter not used in base interface
      
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Inter_Mgr_GetStat

    !> Purpose: Process MD Inter Mgr Delete
  SUBROUTINE MD_Inter_Mgr_Delete(this, id, status)
      CLASS(MD_Inter_Mgr), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      INTEGER(i4) :: ierr
      
      CALL init_error_status(local_status)
      
      IF (.NOT. ASSOCIATED(this%model)) THEN
          local_status%status_code = IF_STATUS_INVALID
          IF (PRESENT(status)) status = local_status
          RETURN
      END IF
      
      CALL UF_Interaction_Delete(this%model, id, ierr)
      IF (ierr /= 0_i4) THEN
          local_status%status_code = IF_STATUS_INVALID
      ELSE
          this%count = MAX(0_i4, this%count - 1_i4)
      END IF
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_Delete

    !> Purpose: Find MD Inter Mgr
  FUNCTION MD_Inter_Mgr_Find(this, name) RESULT(id)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      CHARACTER(LEN=*), INTENT(IN) :: name
      INTEGER(i4) :: id
      
      INTEGER(i4) :: idx, ierr
      
      id = 0_i4
      
      IF (.NOT. ASSOCIATED(this%model)) RETURN
      
      CALL UF_Interaction_FindByName(this%model, name, idx, ierr)
      IF (ierr == 0_i4 .AND. idx > 0_i4) THEN
          id = idx
      END IF
  END FUNCTION MD_Inter_Mgr_Find

    !> Purpose: Process MD Inter Mgr Create
  SUBROUTINE MD_Inter_Mgr_Create(this, id, name, status)
      CLASS(MD_Inter_Mgr), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(OUT), OPTIONAL :: id
      CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      INTEGER(i4) :: idx
      
      CALL init_error_status(local_status)
      
      IF (.NOT. ASSOCIATED(this%model)) THEN
          local_status%status_code = IF_STATUS_INVALID
          local_status%message = "Model not associated"
          IF (PRESENT(status)) status = local_status
          RETURN
      END IF
      
      ! Note: Interaction creation requires more parameters
      ! This is a placeholder - actual creation should use UF_Interaction_Add
      IF (.NOT. PRESENT(name)) THEN
          local_status%status_code = IF_STATUS_INVALID
          local_status%message = "Interaction name is required"
          IF (PRESENT(status)) status = local_status
          RETURN
      END IF
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_Create

    !> Purpose: Initialize MD Inter Mgr
  SUBROUTINE MD_Inter_Mgr_Init(this, max_capacity, status)
      CLASS(MD_Inter_Mgr), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN), OPTIONAL :: max_capacity
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      
      CALL init_error_status(local_status)
      
      IF (PRESENT(max_capacity)) THEN
          this%max_capacity = MAX(1_i4, max_capacity)
      ELSE
          this%max_capacity = 100_i4
      END IF
      
      this%count = 0_i4
      this%init = .TRUE.
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_Init

    !> Purpose: Process MD Inter Mgr Final
  SUBROUTINE MD_Inter_Mgr_Final(this, status)
      CLASS(MD_Inter_Mgr), INTENT(INOUT) :: this
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      
      CALL init_error_status(local_status)
      
      this%count = 0_i4
      this%init = .FALSE.
      this%model => null()
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_Final

    !> Purpose: Validate MD Inter Mgr
  SUBROUTINE MD_Inter_Mgr_Valid(this, id, status)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      INTEGER(i4), INTENT(IN) :: id
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      CALL init_error_status(status)
      
      IF (.NOT. this%init) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "InteractionManager is not initialized"
          RETURN
      END IF
      
      IF (.NOT. ASSOCIATED(this%model)) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "Model not associated"
          RETURN
      END IF
      
      status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Inter_Mgr_Valid

    !> Purpose: Process MD Inter Mgr ValidCons
  SUBROUTINE MD_Inter_Mgr_ValidCons(this, status)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      CALL init_error_status(status)
      
      IF (.NOT. this%init) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "InteractionManager is not initialized"
          RETURN
      END IF
      
      status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Inter_Mgr_ValidCons

    !> Purpose: Process MD Inter Mgr List
  SUBROUTINE MD_Inter_Mgr_List(this, names, count, status)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      CHARACTER(LEN=*), INTENT(OUT) :: names(:)
      INTEGER(i4), INTENT(OUT) :: count
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      INTEGER(i4) :: i, n
      
      CALL init_error_status(local_status)
      
      count = 0_i4
      
      IF (ASSOCIATED(this%model) .AND. ALLOCATED(this%model%desc%interactions)) THEN
          n = MIN(SIZE(this%model%desc%interactions), SIZE(names))
          DO i = 1, n
              names(i) = this%model%desc%interactions(i)%name
          END DO
          count = n
      END IF
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_List

    !> Purpose: Get MD Inter Mgr
  SUBROUTINE MD_Inter_Mgr_Get(this, id, status)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      INTEGER(i4), INTENT(IN) :: id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(ErrorStatusType) :: local_status
      
      CALL init_error_status(local_status)
      
      IF (.NOT. ASSOCIATED(this%model)) THEN
          local_status%status_code = IF_STATUS_INVALID
          IF (PRESENT(status)) status = local_status
          RETURN
      END IF
      
      IF (.NOT. ALLOCATED(this%model%desc%interactions)) THEN
          local_status%status_code = IF_STATUS_NOT_FOUND
          IF (PRESENT(status)) status = local_status
          RETURN
      END IF
      
      IF (id < 1_i4 .OR. id > SIZE(this%model%desc%interactions)) THEN
          local_status%status_code = IF_STATUS_NOT_FOUND
          local_status%message = "Interaction not found"
      END IF
      
      IF (PRESENT(status)) status = local_status
  END SUBROUTINE MD_Inter_Mgr_Get

    !> Purpose: Process MD Inter Mgr GetCnt
  FUNCTION MD_Inter_Mgr_GetCnt(this) RESULT(count)
      CLASS(MD_Inter_Mgr), INTENT(IN) :: this
      INTEGER(i4) :: count
      
      count = 0_i4
      
      IF (ASSOCIATED(this%model) .AND. ALLOCATED(this%model%desc%interactions)) THEN
          count = SIZE(this%model%desc%interactions)
      END IF
  END FUNCTION MD_Inter_Mgr_GetCnt

END MODULE MD_Int_Ctx_Mgr
