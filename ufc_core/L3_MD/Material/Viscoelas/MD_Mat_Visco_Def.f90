!===============================================================================
! MODULE: MD_Mat_Visco_Def
! LAYER:  L3_MD
! DOMAIN: Material / Viscoelastic
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for viscoelastic material family.
!         Implements three-level nesting: family_type + sub_type + property_flags
!         Supports viscoelastic variants: PRONY_DEV/PRONY_VOL/KELVIN/WLF_SHIFT
!
!         Design principle (UFC Architecture):
!         - Four TYPE system: Desc/State/Algo/Ctx
!         - Three-level nesting: strictly limited to 3 levels
!         - L3_MD is the single source of truth (SSOT)
!
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Visco_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_VISCOELASTIC, &
                                MD_MAT_VE_SUB_PRONY_DEV, &
                                MD_MAT_VE_SUB_PRONY_VOL, &
                                MD_MAT_VE_SUB_KELVIN, &
                                MD_MAT_VE_SUB_WLF_SHIFT, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Visco_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (VISCOELASTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (PRONY_DEV/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
    INTEGER(i4) :: n_prony_terms    = 0_i4   ! Number of Prony series terms
  END TYPE MD_Mat_Visco_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Visco_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Visco_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Visco_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    REAL(wp) :: time        = 0.0_wp      ! Current total time
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
    INTEGER(i4) :: inc_num   = 0_i4       ! Increment number
  END TYPE MD_Mat_Visco_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc  -- Static material descriptor
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Visco_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Visco_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Visco_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Viscoelastic specific parameters
    INTEGER(i4) :: num_terms        ! Number of Prony/Kelvin terms
    REAL(wp), ALLOCATABLE :: G_i(:), tau_i(:) ! Shear moduli and relaxation times

    ! Density parameter (Week 3 Phase 3)
    REAL(wp) :: density = 0.0_wp    ! Material density (mass/volume)
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Valid
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Visco_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Visco_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: s_k_6(:)        ! Viscoelastic stress deviator history
    REAL(wp), ALLOCATABLE :: internal_vars(:,:) ! History variables per term
    LOGICAL  :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Visco_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  ! Lifecycle: Set during initialization, immutable during solve
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Visco_Algo
    INTEGER(i4) :: integration_method = 1_i4  ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: tolerance          = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.  ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Visco_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  ! Lifecycle: Created per iteration, can be released after use
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Visco_Ctx
    TYPE(MD_Mat_Visco_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp) :: relaxation_modulus = 0.0_wp
    REAL(wp) :: dt = 0.0_wp                ! Time increment
    INTEGER(i4) :: integration_point = 0   ! Integration point number
    INTEGER(i4) :: element_id = 0          ! Element ID
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Visco_Ctx

  !=======================================================================
  ! Public exports
  !=======================================================================
  PUBLIC :: MD_Mat_Visco_Desc
  PUBLIC :: MD_Mat_Visco_State
  PUBLIC :: MD_Mat_Visco_Algo
  PUBLIC :: MD_Mat_Visco_Ctx

CONTAINS

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Visco_Desc
  !=============================================================================

  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Visco_Desc), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: sub_type
    INTEGER(i4),              INTENT(IN)    :: num_constants
    INTEGER(i4),              INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    this%cfg%family_type    = MD_MAT_FAMILY_VISCOELASTIC
    this%cfg%sub_type       = sub_type
    this%cfg%property_flags = MD_MAT_PROP_NONE
    this%cfg%num_constants  = num_constants
    this%cfg%n_prony_terms  = 0_i4
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

  SUBROUTINE Desc_Valid(this, status)
    CLASS(MD_Mat_Visco_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = -1; status%message = "Not initialized"; RETURN
    END IF
    IF (this%cfg%family_type /= MD_MAT_FAMILY_VISCOELASTIC) THEN
      status%status_code = -2; status%message = "Not VISCOELASTIC family"; RETURN
    END IF
    IF (this%cfg%sub_type < 501 .OR. this%cfg%sub_type > 504) THEN
      status%status_code = -3; status%message = "Invalid sub_type"; RETURN
    END IF
    IF (this%cfg%num_constants <= 0) THEN
      status%status_code = -4; status%message = "No constants"; RETURN
    END IF
    IF (this%density < 0.0_wp) THEN
      status%status_code = -5; status%message = "Density must be non-negative"; RETURN
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_ComputeDerived(this, status)
    CLASS(MD_Mat_Visco_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Populate G_i and tau_i for Prony series from constants array if applicable
    IF (this%cfg%sub_type == MD_MAT_VE_SUB_PRONY_DEV .OR. &
        this%cfg%sub_type == MD_MAT_VE_SUB_PRONY_VOL) THEN
      this%num_terms = this%cfg%num_constants / 2
      IF (this%num_terms > 0) THEN
        this%cfg%n_prony_terms = this%num_terms
        IF (.NOT. ALLOCATED(this%G_i)) ALLOCATE(this%G_i(this%num_terms))
        IF (.NOT. ALLOCATED(this%tau_i)) ALLOCATE(this%tau_i(this%num_terms))
        DO i = 1, this%num_terms
          this%G_i(i) = this%constants(2*i-1, 1)
          this%tau_i(i) = this%constants(2*i, 1)
        END DO
      END IF
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  SUBROUTINE Desc_Clean(this)
    CLASS(MD_Mat_Visco_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    IF (ALLOCATED(this%G_i))       DEALLOCATE(this%G_i)
    IF (ALLOCATED(this%tau_i))     DEALLOCATE(this%tau_i)
    this%num_terms          = 0
    this%density            = 0.0_wp
    this%cfg%n_prony_terms = 0
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Visco_State
  !=============================================================================

  SUBROUTINE State_Init(this, n_terms)
    CLASS(MD_Mat_Visco_State), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_terms

    this%stress = 0.0_wp
    this%strain = 0.0_wp
    this%initialized = .FALSE.

    IF (ALLOCATED(this%s_k_6)) DEALLOCATE(this%s_k_6)
    IF (ALLOCATED(this%internal_vars)) DEALLOCATE(this%internal_vars)

    IF (PRESENT(n_terms) .AND. n_terms > 0) THEN
      ALLOCATE(this%s_k_6(6))
      this%s_k_6 = 0.0_wp
      ALLOCATE(this%internal_vars(6, n_terms))
      this%internal_vars = 0.0_wp
    END IF
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, stress, strain)
    CLASS(MD_Mat_Visco_State), INTENT(INOUT) :: this
    REAL(wp),                  INTENT(IN)    :: stress(6)
    REAL(wp),                  INTENT(IN)    :: strain(6)

    this%stress = stress
    this%strain = strain
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Visco_State), INTENT(INOUT) :: this

    this%stress = 0.0_wp
    this%strain = 0.0_wp
    IF (ALLOCATED(this%s_k_6))        DEALLOCATE(this%s_k_6)
    IF (ALLOCATED(this%internal_vars)) DEALLOCATE(this%internal_vars)
    this%initialized = .FALSE.
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Visco_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(MD_Mat_Visco_Algo), INTENT(OUT) :: this
    this%integration_method      = 1_i4
    this%tolerance               = 1.0e-5_wp
    this%use_numerical_tangent   = .FALSE.
  END SUBROUTINE Algo_Init

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Visco_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Visco_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Visco_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Visco_Reg_Arg
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
  END TYPE MD_Mat_Visco_Reg_Arg

END MODULE MD_Mat_Visco_Def
