!===============================================================================
! MODULE: MD_Mat_Therm_Def
! LAYER:  L3_MD
! DOMAIN: Material / Thermal
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for thermal material family.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!         Supports thermal variants: ISO/ORTHO/PHASE_CHG
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Therm_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_THERMAL, &
                                MD_MAT_HEAT_SUB_ISO, &
                                MD_MAT_HEAT_SUB_ORTHO, &
                                MD_MAT_HEAT_SUB_PHASE_CHG, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Therm_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (THERMAL)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (ISO/ORTHO/PHASE_CHG)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Therm_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Therm_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Therm_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Therm_Stp_Evo_Ctx
    REAL(wp)   :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp)   :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id      = 0_i4        ! Integration point number
    INTEGER(i4) :: elem_id    = 0_i4        ! Element ID
  END TYPE MD_Mat_Therm_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc -- Static material descriptor
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Therm_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Therm_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Therm_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Thermal properties
    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: conductivity(3) = 0.0_wp
    REAL(wp) :: specific_heat = 0.0_wp
    REAL(wp) :: latent_heat = 0.0_wp
    REAL(wp) :: solid_temp = 0.0_wp
    REAL(wp) :: liquid_temp = 0.0_wp
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Validate
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Therm_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Therm_State
    REAL(wp) :: heat_flux(3) = 0.0_wp
    REAL(wp) :: temperature  = 293.15_wp  ! Current temperature
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Therm_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  ! Lifecycle: Set during initialization, immutable during solve
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Therm_Algo
    INTEGER(i4) :: integration_method    = 1_i4   ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: tolerance             = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.   ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Therm_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  ! Lifecycle: Created per iteration, can be released after use
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Therm_Ctx
    TYPE(MD_Mat_Therm_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp)   :: time           = 0.0_wp   ! Current total time
    REAL(wp)   :: dt             = 0.0_wp   ! Time increment
    INTEGER(i4) :: increment_num = 0_i4     ! Increment number
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Therm_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces (types automatically public via TYPE statement)
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Therm_Desc
  PUBLIC :: MD_Mat_Therm_State
  PUBLIC :: MD_Mat_Therm_Algo
  PUBLIC :: MD_Mat_Therm_Ctx

  ! Backward-compatible direct procedure access
  PUBLIC :: Desc_Init
  PUBLIC :: Desc_Validate
  PUBLIC :: Desc_ComputeDerived
  PUBLIC :: Desc_Clean

  PUBLIC :: State_Init
  PUBLIC :: State_Update
  PUBLIC :: State_Clean

  PUBLIC :: Algo_Init

  PUBLIC :: Ctx_Init
  PUBLIC :: Ctx_Clean

CONTAINS

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Therm_Desc
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to initialize
  ! [IN] sub_type: Thermal sub-type (ISO, ORTHO, PHASE_CHG)
  ! [IN] num_constants: Number of constants per temperature/field point
  ! [IN] dependencies: 0=none, 1=temp, 2=field
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Therm_Desc), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: sub_type
    INTEGER(i4),              INTENT(IN)    :: num_constants
    INTEGER(i4),              INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    this%cfg%family_type    = MD_MAT_FAMILY_THERMAL
    this%cfg%sub_type       = sub_type
    this%cfg%num_constants  = num_constants
    this%cfg%property_flags = MD_MAT_PROP_NONE
    this%cfg%dependencies   = 0_i4

    IF (PRESENT(dependencies)) THEN
      this%cfg%dependencies = dependencies
      IF (dependencies == 1) THEN
        this%cfg%property_flags = IOR(this%cfg%property_flags, MD_MAT_PROP_TEMP_DEP)
      ELSE IF (dependencies == 2) THEN
        this%cfg%property_flags = IOR(this%cfg%property_flags, MD_MAT_PROP_FIELD_DEP)
      END IF
    END IF

    ! Allocate constants table
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    IF (this%cfg%dependencies > 0) THEN
      ALLOCATE(this%constants(num_constants, this%cfg%dependencies))
    ELSE
      ALLOCATE(this%constants(num_constants, 1))
    END IF
    this%constants = 0.0_wp

    this%pop%is_initialized = .TRUE.
    status%status_code = 0
  END SUBROUTINE Desc_Init

  !-----------------------------------------------------------------------------
  ! [IN] this: Material descriptor to validate
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Validate(this, status)
    CLASS(MD_Mat_Therm_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Thermal desc not initialized"
      RETURN
    END IF
    IF (this%cfg%family_type /= MD_MAT_FAMILY_THERMAL) THEN
      status%status_code = 2
      status%message = "Invalid family_type"
      RETURN
    END IF
    IF (this%cfg%sub_type < 901 .OR. this%cfg%sub_type > 903) THEN
      status%status_code = 3
      status%message = "Invalid sub_type"
      RETURN
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_Validate

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to compute derived parameters for
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_ComputeDerived(this, status)
    CLASS(MD_Mat_Therm_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%cfg%sub_type == MD_MAT_HEAT_SUB_ISO .AND. this%cfg%num_constants >= 1) THEN
      this%conductivity(1) = this%constants(1, 1)
      this%conductivity(2) = this%constants(1, 1)
      this%conductivity(3) = this%constants(1, 1)
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to clean
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Clean(this)
    CLASS(MD_Mat_Therm_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Therm_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(MD_Mat_Therm_State), INTENT(OUT) :: this
    this%heat_flux   = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, heat_flux, temperature)
    CLASS(MD_Mat_Therm_State), INTENT(INOUT) :: this
    REAL(wp),                  INTENT(IN)    :: heat_flux(3)
    REAL(wp),                  INTENT(IN)    :: temperature
    this%heat_flux   = heat_flux
    this%temperature = temperature
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Therm_State), INTENT(INOUT) :: this
    this%heat_flux   = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Therm_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(MD_Mat_Therm_Algo), INTENT(OUT) :: this
    this%integration_method    = 1_i4
    this%tolerance             = 1.0e-5_wp
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Therm_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Therm_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Therm_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Therm_Reg_Arg
    ! [IN] properties
    INTEGER(i4) :: sub_type         ! [IN]  sub-type ID
    INTEGER(i4) :: nprops           ! [IN]  number of properties
    REAL(wp)    :: E                ! [IN]  Young's modulus
    REAL(wp)    :: nu               ! [IN]  Poisson ratio
    REAL(wp), ALLOCATABLE :: props(:) ! [IN]  material properties array
    INTEGER(i4) :: dependencies     ! [IN]  temp/field dependencies

    ! [OUT] results
    INTEGER(i4) :: mat_id           ! [OUT] assigned material ID
    INTEGER(i4) :: status_code      ! [OUT] exit status
    CHARACTER(len=256) :: message   ! [OUT] status message
  END TYPE MD_Mat_Therm_Reg_Arg

END MODULE MD_Mat_Therm_Def
