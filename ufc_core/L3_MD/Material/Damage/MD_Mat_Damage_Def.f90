!===============================================================================
! MODULE: MD_Mat_Damage_Def
! LAYER:  L3_MD
! DOMAIN: Material / Damage
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for damage material family.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!         Supports damage variants: DUCTILE/SHEAR/BRITTLE/FLD/CZM/CONCRETE
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Damage_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_DAMAGE, &
                                MD_MAT_DMG_SUB_DUCTILE, &
                                MD_MAT_DMG_SUB_SHEAR, &
                                MD_MAT_DMG_SUB_BRITTLE, &
                                MD_MAT_DMG_SUB_FLD, &
                                MD_MAT_DMG_SUB_CZM, &
                                MD_MAT_DMG_SUB_CONCRETE, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Damage_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Level 1: Main family (DAMAGE)
    INTEGER(i4) :: sub_type         = 0_i4   ! Level 2: Variant (DUCTILE/SHEAR/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Level 3: Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! DEPENDENCIES parameter (0=none, 1=temp, 2=field)
  END TYPE MD_Mat_Damage_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Damage_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Damage_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Damage_Stp_Evo_Ctx
    REAL(wp)   :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp)   :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id      = 0_i4        ! Integration point number
    INTEGER(i4) :: elem_id    = 0_i4        ! Element ID
  END TYPE MD_Mat_Damage_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc -- Static material descriptor
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Damage_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Damage_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Damage_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Derived parameters (for performance)
    REAL(wp) :: damage_threshold  = 0.0_wp   ! Damage initiation threshold
    REAL(wp) :: damage_exponent   = 1.0_wp   ! Damage evolution exponent
    REAL(wp) :: critical_damage   = 1.0_wp   ! Critical damage value (Dc)
    REAL(wp) :: fracture_energy   = 0.0_wp   ! Fracture energy Gf [J/m2]

    ! Density parameter (Week 3 Phase 3)
    REAL(wp) :: density = 0.0_wp    ! Material density (mass/volume)
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Validate
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Damage_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Damage_State
    REAL(wp) :: damage_variable     = 0.0_wp  ! Current damage D in [0, Dc]
    REAL(wp) :: energy_release_rate = 0.0_wp  ! Elastic energy release rate Y
    LOGICAL  :: is_fully_damaged    = .FALSE. ! Element deletion flag
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Damage_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  ! Lifecycle: Set during initialization, immutable during solve
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Damage_Algo
    INTEGER(i4) :: integration_method    = 1_i4   ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: softening_law         = 1.0_wp ! Softening law type (1=linear, 2=exponential, etc.)
    REAL(wp)    :: damage_threshold      = 0.0_wp ! Damage threshold parameter
    REAL(wp)    :: tolerance             = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.   ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Damage_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  ! Lifecycle: Created per iteration, can be released after use
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Damage_Ctx
    TYPE(MD_Mat_Damage_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp)   :: time           = 0.0_wp   ! Current total time
    REAL(wp)   :: dt             = 0.0_wp   ! Time increment
    INTEGER(i4) :: increment_num = 0_i4     ! Increment number
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Damage_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces (types automatically public via TYPE statement)
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Damage_Desc
  PUBLIC :: MD_Mat_Damage_State
  PUBLIC :: MD_Mat_Damage_Algo
  PUBLIC :: MD_Mat_Damage_Ctx

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
  ! TBP IMPLEMENTATIONS: MD_Mat_Damage_Desc
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to initialize
  ! [IN] sub_type: Damage sub-type (DUCTILE, SHEAR, etc.)
  ! [IN] num_constants: Number of constants per temperature/field point
  ! [IN] dependencies: 0=none, 1=temp, 2=field
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Damage_Desc), INTENT(INOUT) :: this
    INTEGER(i4),               INTENT(IN)    :: sub_type
    INTEGER(i4),               INTENT(IN)    :: num_constants
    INTEGER(i4),               INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Initialize three-level nesting
    this%cfg%family_type    = MD_MAT_FAMILY_DAMAGE
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

    ! Allocate material constants table
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
    CLASS(MD_Mat_Damage_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Check if initialized
    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Damage material descriptor not initialized"
      RETURN
    END IF

    ! Validate three-level nesting
    IF (this%cfg%family_type /= MD_MAT_FAMILY_DAMAGE) THEN
      status%status_code = 2
      status%message = "Invalid family_type for damage material"
      RETURN
    END IF

    ! Validate sub_type range (701 to 706)
    IF (this%cfg%sub_type < 701 .OR. this%cfg%sub_type > 706) THEN
      status%status_code = 3
      status%message = "Invalid sub_type for damage material"
      RETURN
    END IF

    ! Validate material constants
    IF (this%cfg%num_constants <= 0) THEN
      status%status_code = 4
      status%message = "Invalid number of material constants"
      RETURN
    END IF

    ! Density validation
    IF (this%density < 0.0_wp) THEN
      status%status_code = 5
      status%message = "Density must be non-negative"
      RETURN
    END IF

    status%status_code = 0
  END SUBROUTINE Desc_Validate

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to compute derived parameters for
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_ComputeDerived(this, status)
    CLASS(MD_Mat_Damage_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    SELECT CASE (this%cfg%sub_type)
    CASE (MD_MAT_DMG_SUB_DUCTILE)
      ! For DUCTILE: constants = [threshold, critical, exponent, ...]
      IF (this%cfg%num_constants >= 3) THEN
        this%damage_threshold = this%constants(1, 1)
        this%critical_damage  = this%constants(2, 1)
        this%damage_exponent  = this%constants(3, 1)
      END IF
    CASE DEFAULT
      ! Other sub-types: derived properties setup
      CONTINUE
    END SELECT
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to clean
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Clean(this)
    CLASS(MD_Mat_Damage_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Damage_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(MD_Mat_Damage_State), INTENT(OUT) :: this
    this%damage_variable     = 0.0_wp
    this%energy_release_rate = 0.0_wp
    this%is_fully_damaged    = .FALSE.
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, damage, energy, fully_damaged)
    CLASS(MD_Mat_Damage_State), INTENT(INOUT) :: this
    REAL(wp),                   INTENT(IN)    :: damage
    REAL(wp),                   INTENT(IN)    :: energy
    LOGICAL,                    INTENT(IN)    :: fully_damaged
    this%damage_variable     = damage
    this%energy_release_rate = energy
    this%is_fully_damaged    = fully_damaged
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Damage_State), INTENT(INOUT) :: this
    this%damage_variable     = 0.0_wp
    this%energy_release_rate = 0.0_wp
    this%is_fully_damaged    = .FALSE.
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Damage_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this, softening_law)
    CLASS(MD_Mat_Damage_Algo), INTENT(OUT) :: this
    REAL(wp), INTENT(IN), OPTIONAL :: softening_law

    this%integration_method    = 1_i4
    this%tolerance             = 1.0e-5_wp
    this%use_numerical_tangent = .FALSE.
    this%damage_threshold      = 0.0_wp
    this%softening_law         = 1.0_wp  ! Default: linear

    IF (PRESENT(softening_law)) THEN
      this%softening_law = softening_law
    END IF
  END SUBROUTINE Algo_Init

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Damage_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Damage_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Damage_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Damage_Reg_Arg
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
  END TYPE MD_Mat_Damage_Reg_Arg

END MODULE MD_Mat_Damage_Def
