!===============================================================================
! MODULE: MD_Mat_Acou_Def
! LAYER:  L3_MD
! DOMAIN: Material / Acoustic
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for acoustic material family.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Acou_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_ACOUSTIC, &
                                MD_MAT_ACOU_SUB_LINEAR, &
                                MD_MAT_ACOU_SUB_ABSORB, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Acou_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (ACOUSTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (LINEAR/ABSORB)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Acou_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Acou_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Acou_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Acou_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
  END TYPE MD_Mat_Acou_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc  -- Static material descriptor
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Acou_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Acou_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Acou_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Acoustic specific parameters
    REAL(wp) :: density         = 0.0_wp
    REAL(wp) :: bulk_modulus    = 0.0_wp
    REAL(wp) :: volumetric_drag = 0.0_wp
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Valid
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Acou_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Acou_State
    REAL(wp) :: acoustic_pressure = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Acou_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Acou_Algo
    INTEGER(i4) :: integration_method = 1_i4
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE MD_Mat_Acou_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Acou_Ctx
    TYPE(MD_Mat_Acou_Stp_Evo_Ctx) :: stp  ! Step-level context
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Acou_Ctx

CONTAINS

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Acou_Desc
  !=============================================================================

  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Acou_Desc), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: sub_type
    INTEGER(i4),             INTENT(IN)    :: num_constants
    INTEGER(i4),             INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    this%cfg%family_type    = MD_MAT_FAMILY_ACOUSTIC
    this%cfg%sub_type       = sub_type
    this%cfg%property_flags = MD_MAT_PROP_NONE
    this%cfg%num_constants  = num_constants
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
    CLASS(MD_Mat_Acou_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = -1; status%message = "Not initialized"; RETURN
    END IF
    IF (this%cfg%family_type /= MD_MAT_FAMILY_ACOUSTIC) THEN
      status%status_code = -2; status%message = "Not ACOUSTIC family"; RETURN
    END IF
    IF (this%cfg%sub_type < 1001 .OR. this%cfg%sub_type > 1002) THEN
      status%status_code = -3; status%message = "Invalid sub_type"; RETURN
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_ComputeDerived(this, status)
    CLASS(MD_Mat_Acou_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%cfg%num_constants >= 1) this%bulk_modulus    = this%constants(1, 1)
    IF (this%cfg%num_constants >= 2) this%volumetric_drag = this%constants(2, 1)
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  SUBROUTINE Desc_Clean(this)
    CLASS(MD_Mat_Acou_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    this%density         = 0.0_wp
    this%bulk_modulus    = 0.0_wp
    this%volumetric_drag = 0.0_wp
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Acou_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(MD_Mat_Acou_State), INTENT(OUT) :: this
    this%acoustic_pressure = 0.0_wp
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, pressure)
    CLASS(MD_Mat_Acou_State), INTENT(INOUT) :: this
    REAL(wp),                 INTENT(IN)    :: pressure
    this%acoustic_pressure = pressure
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Acou_State), INTENT(INOUT) :: this
    this%acoustic_pressure = 0.0_wp
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Acou_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(MD_Mat_Acou_Algo), INTENT(OUT) :: this
    this%integration_method = 1_i4
  END SUBROUTINE Algo_Init

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Acou_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Acou_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Acou_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Acou_Reg_Arg
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
  END TYPE MD_Mat_Acou_Reg_Arg

END MODULE MD_Mat_Acou_Def
