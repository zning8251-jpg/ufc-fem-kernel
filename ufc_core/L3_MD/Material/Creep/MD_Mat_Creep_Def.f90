!===============================================================================
! MODULE: MD_Mat_Creep_Def
! LAYER:  L3_MD
! DOMAIN: Material / Creep
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for creep material family.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!         Supports creep variants: POWER/USER/TWO_LAYER/ANNEAL/GAROFALO/
!                                  PERZYNA/DUVAUT/BODNER
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Creep_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_CREEP, &
                                MD_MAT_CREEP_SUB_POWER, &
                                MD_MAT_CREEP_SUB_USER, &
                                MD_MAT_CREEP_SUB_TWO_LAYER, &
                                MD_MAT_CREEP_SUB_ANNEAL, &
                                MD_MAT_CREEP_SUB_GAROFALO, &
                                MD_MAT_CREEP_SUB_PERZYNA, &
                                MD_MAT_CREEP_SUB_DUVAUT, &
                                MD_MAT_CREEP_SUB_BODNER, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Creep_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Level 1: Main family (CREEP)
    INTEGER(i4) :: sub_type         = 0_i4   ! Level 2: Variant (POWER/GAROFALO/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Level 3: Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! DEPENDENCIES parameter (0=none, 1=temp, 2=field)
  END TYPE MD_Mat_Creep_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Creep_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Creep_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Creep_Stp_Evo_Ctx
    REAL(wp)   :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp)   :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id      = 0_i4        ! Integration point number
    INTEGER(i4) :: elem_id    = 0_i4        ! Element ID
  END TYPE MD_Mat_Creep_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc -- Static material descriptor
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Creep_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Creep_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Creep_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Derived parameters (for performance)
    REAL(wp) :: A_norton       = 0.0_wp   ! Norton creep coefficient (if POWER)
    REAL(wp) :: n_norton       = 1.0_wp   ! Norton stress exponent (if POWER)
    REAL(wp) :: m_norton       = 0.0_wp   ! Norton time exponent (if POWER)
    REAL(wp) :: Q_activation   = 0.0_wp   ! Activation energy [J/mol]
    REAL(wp) :: R_gas          = 8.314_wp ! Universal gas constant [J/(mol*K)]
    REAL(wp) :: ref_temp       = 0.0_wp   ! Reference temperature [K]

    ! Density parameter (Week 3 Phase 3)
    REAL(wp) :: density = 0.0_wp    ! Material density (mass/volume)
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Validate
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Creep_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Creep_State
    REAL(wp) :: creep_strain(6)       = 0.0_wp  ! Creep strain tensor (Voigt)
    REAL(wp) :: equiv_creep_strain    = 0.0_wp  ! Equivalent creep strain
    REAL(wp) :: creep_strain_rate     = 0.0_wp  ! Current equivalent creep strain rate
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Creep_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  ! Lifecycle: Set during initialization, immutable during solve
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Creep_Algo
    INTEGER(i4) :: integration_method    = 1_i4   ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: tolerance             = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.   ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Creep_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  ! Lifecycle: Created per iteration, can be released after use
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Creep_Ctx
    TYPE(MD_Mat_Creep_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp)   :: time           = 0.0_wp   ! Current total time
    REAL(wp)   :: dt             = 0.0_wp   ! Time increment
    INTEGER(i4) :: increment_num = 0_i4     ! Increment number
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Creep_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces (types automatically public via TYPE statement)
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Creep_Desc
  PUBLIC :: MD_Mat_Creep_State
  PUBLIC :: MD_Mat_Creep_Algo
  PUBLIC :: MD_Mat_Creep_Ctx

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
  ! TBP IMPLEMENTATIONS: MD_Mat_Creep_Desc
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! [IN/OUT] this: Material descriptor to initialize
  ! [IN] sub_type: Creep sub-type (POWER, GAROFALO, etc.)
  ! [IN] num_constants: Number of constants per temperature/field point
  ! [IN] dependencies: 0=none, 1=temp, 2=field
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Creep_Desc), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: sub_type
    INTEGER(i4),              INTENT(IN)    :: num_constants
    INTEGER(i4),              INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Initialize three-level nesting
    this%cfg%family_type    = MD_MAT_FAMILY_CREEP
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
    CLASS(MD_Mat_Creep_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Check if initialized
    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Creep material descriptor not initialized"
      RETURN
    END IF

    ! Validate three-level nesting
    IF (this%cfg%family_type /= MD_MAT_FAMILY_CREEP) THEN
      status%status_code = 2
      status%message = "Invalid family_type for creep material"
      RETURN
    END IF

    ! Validate sub_type range (601 to 608)
    IF (this%cfg%sub_type < 601 .OR. this%cfg%sub_type > 608) THEN
      status%status_code = 3
      status%message = "Invalid sub_type for creep material"
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
    CLASS(MD_Mat_Creep_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    SELECT CASE (this%cfg%sub_type)
    CASE (MD_MAT_CREEP_SUB_POWER)
      ! For POWER-law creep: constants = [A, n, m]
      IF (this%cfg%num_constants >= 3) THEN
        this%A_norton = this%constants(1, 1)
        this%n_norton = this%constants(2, 1)
        this%m_norton = this%constants(3, 1)
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
    CLASS(MD_Mat_Creep_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Creep_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(MD_Mat_Creep_State), INTENT(OUT) :: this
    this%creep_strain       = 0.0_wp
    this%equiv_creep_strain = 0.0_wp
    this%creep_strain_rate  = 0.0_wp
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, creep_strain, equiv_creep_strain, creep_strain_rate)
    CLASS(MD_Mat_Creep_State), INTENT(INOUT) :: this
    REAL(wp),                  INTENT(IN)    :: creep_strain(6)
    REAL(wp),                  INTENT(IN)    :: equiv_creep_strain
    REAL(wp),                  INTENT(IN)    :: creep_strain_rate
    this%creep_strain       = creep_strain
    this%equiv_creep_strain = equiv_creep_strain
    this%creep_strain_rate  = creep_strain_rate
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Creep_State), INTENT(INOUT) :: this
    this%creep_strain       = 0.0_wp
    this%equiv_creep_strain = 0.0_wp
    this%creep_strain_rate  = 0.0_wp
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Creep_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(MD_Mat_Creep_Algo), INTENT(OUT) :: this
    this%integration_method    = 1_i4
    this%tolerance             = 1.0e-5_wp
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Creep_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Creep_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Creep_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Creep_Reg_Arg
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
  END TYPE MD_Mat_Creep_Reg_Arg

END MODULE MD_Mat_Creep_Def
