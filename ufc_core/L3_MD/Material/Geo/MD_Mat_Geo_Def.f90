!===============================================================================
! MODULE: MD_Mat_Geo_Def
! LAYER:  L3_MD
! DOMAIN: Material / Geo
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for geotechnical material family.
!         Four TYPE system: Desc/State/Algo/Ctx with auxiliary type nesting.
!===============================================================================
MODULE MD_Mat_Geo_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_GEOTECHNICAL, &
                                MD_MAT_GEO_SUB_DP_LINEAR, &
                                MD_MAT_GEO_SUB_DP_CAP, &
                                MD_MAT_GEO_SUB_MC, &
                                MD_MAT_GEO_SUB_CC_CRIT, &
                                MD_MAT_GEO_SUB_CONCRETE, &
                                MD_MAT_GEO_SUB_FOAM_CRUSH, &
                                MD_MAT_GEO_SUB_CAM_CLAY, &
                                MD_MAT_GEO_SUB_HOEK_BROWN, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Cfg_Init_Desc — configuration/initialization fields
  ! Nested inside Desc via %cfg component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = MD_MAT_FAMILY_GEOTECHNICAL
    INTEGER(i4) :: sub_type       = MD_MAT_GEO_SUB_DP_LINEAR
    INTEGER(i4) :: property_flags = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants  = 0_i4
    INTEGER(i4) :: dependencies   = 0_i4
  END TYPE MD_Mat_Geo_Cfg_Init_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Pop_Vld_Desc — population/validation state
  ! Nested inside Desc via %pop component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Geo_Pop_Vld_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Stp_Evo_Ctx — step evolution context
  ! Nested inside Ctx via %stp component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE MD_Mat_Geo_Stp_Evo_Ctx

  !-----------------------------------------------------------------------------
  ! Desc TYPE: Static descriptor
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Geo_Desc
    ! Nested auxiliary types
    TYPE(MD_Mat_Geo_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Geo_Pop_Vld_Desc) :: pop

    REAL(wp), ALLOCATABLE :: constants(:,:)

    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: friction_angle = 0.0_wp
    REAL(wp) :: dilation_angle = 0.0_wp
    REAL(wp) :: cohesion = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => Desc_Init
    PROCEDURE :: Valid => Desc_Validate
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean => MD_Mat_Geo_Clean
  END TYPE MD_Mat_Geo_Desc

  !-----------------------------------------------------------------------------
  ! State TYPE: Runtime state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equivalent_plastic_strain = 0.0_wp
    REAL(wp) :: volumetric_plastic_strain = 0.0_wp
    REAL(wp) :: yield_surface_size = 0.0_wp
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean => State_Clean
  END TYPE MD_Mat_Geo_State

  !-----------------------------------------------------------------------------
  ! Algo TYPE: Algorithm descriptor
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_Algo
    INTEGER(i4) :: integration_method = 1
    INTEGER(i4) :: return_mapping = 1     ! 1=closest-point, 2=cutting-plane
    INTEGER(i4) :: max_iter = 50
    REAL(wp) :: tolerance = 1.0e-8_wp
  CONTAINS
    PROCEDURE :: Init => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Geo_Algo

  !-----------------------------------------------------------------------------
  ! Ctx TYPE: Runtime context
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Geo_Ctx
    TYPE(MD_Mat_Geo_Stp_Evo_Ctx) :: stp
    REAL(wp) :: field_var = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
  END TYPE MD_Mat_Geo_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Geo_Cfg_Init_Desc
  PUBLIC :: MD_Mat_Geo_Pop_Vld_Desc
  PUBLIC :: MD_Mat_Geo_Stp_Evo_Ctx
  PUBLIC :: MD_Mat_Geo_Desc
  PUBLIC :: MD_Mat_Geo_State
  PUBLIC :: MD_Mat_Geo_Algo
  PUBLIC :: MD_Mat_Geo_Ctx

  PUBLIC :: Desc_Init
  PUBLIC :: Desc_Validate
  PUBLIC :: Desc_ComputeDerived
  PUBLIC :: MD_Mat_Geo_Clean
  PUBLIC :: State_Init
  PUBLIC :: State_Update
  PUBLIC :: State_Clean
  PUBLIC :: Algo_Init
  PUBLIC :: Algo_Config
  PUBLIC :: Ctx_Init

CONTAINS

  !-----------------------------------------------------------------------------
  ! Desc_Init
  ! Initialize geotechnical material descriptor
  ! TBP Init for MD_Mat_Geo_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(desc, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Geo_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: num_constants
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    desc%cfg%family_type = MD_MAT_FAMILY_GEOTECHNICAL
    desc%cfg%sub_type = sub_type
    desc%cfg%property_flags = MD_MAT_PROP_NONE
    desc%cfg%num_constants = num_constants
    desc%cfg%dependencies = 0

    IF (PRESENT(dependencies)) THEN
      desc%cfg%dependencies = dependencies
      IF (dependencies == 1) desc%cfg%property_flags = IOR(desc%cfg%property_flags, MD_MAT_PROP_TEMP_DEP)
      IF (dependencies == 2) desc%cfg%property_flags = IOR(desc%cfg%property_flags, MD_MAT_PROP_FIELD_DEP)
    END IF

    IF (desc%cfg%dependencies > 0) THEN
      ALLOCATE(desc%constants(desc%cfg%num_constants, desc%cfg%dependencies))
    ELSE
      ALLOCATE(desc%constants(desc%cfg%num_constants, 1))
    END IF

    desc%pop%is_initialized = .TRUE.
    status%status_code = 0
  END SUBROUTINE Desc_Init

  !-----------------------------------------------------------------------------
  ! Desc_Validate
  ! Validate geotechnical material descriptor
  ! TBP Valid for MD_Mat_Geo_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Validate(desc, status)
    CLASS(MD_Mat_Geo_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (.NOT. desc%pop%is_initialized) THEN
      status%status_code = 1; RETURN
    END IF
    IF (desc%cfg%family_type /= MD_MAT_FAMILY_GEOTECHNICAL) THEN
      status%status_code = 2; RETURN
    END IF
    IF (desc%cfg%sub_type < 301 .OR. desc%cfg%sub_type > 308) THEN
      status%status_code = 3; RETURN
    END IF
  END SUBROUTINE Desc_Validate

  !-----------------------------------------------------------------------------
  ! Desc_ComputeDerived
  ! Compute derived properties from constants table
  ! TBP ComputeDerived for MD_Mat_Geo_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_ComputeDerived(desc, status)
    CLASS(MD_Mat_Geo_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (desc%cfg%num_constants >= 3) THEN
      desc%friction_angle = desc%constants(1, 1)
      desc%dilation_angle = desc%constants(2, 1)
      desc%cohesion = desc%constants(3, 1)
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  !-----------------------------------------------------------------------------
  ! MD_Mat_Geo_Clean
  ! Deallocate and reset geotechnical descriptor
  ! TBP Clean for MD_Mat_Geo_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Geo_Clean(desc, status)
    CLASS(MD_Mat_Geo_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (ALLOCATED(desc%constants)) DEALLOCATE(desc%constants)

    desc%cfg%family_type = MD_MAT_FAMILY_GEOTECHNICAL
    desc%cfg%sub_type = MD_MAT_GEO_SUB_DP_LINEAR
    desc%cfg%property_flags = MD_MAT_PROP_NONE
    desc%cfg%num_constants = 0_i4
    desc%cfg%dependencies = 0_i4

    desc%pop%is_initialized = .FALSE.

    desc%density = 0.0_wp
    desc%friction_angle = 0.0_wp
    desc%dilation_angle = 0.0_wp
    desc%cohesion = 0.0_wp

    status%status_code = 0
  END SUBROUTINE MD_Mat_Geo_Clean

  !-----------------------------------------------------------------------------
  ! State_Init
  ! Initialize state variables
  ! TBP Init for MD_Mat_Geo_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Init(state, status)
    CLASS(MD_Mat_Geo_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equivalent_plastic_strain = 0.0_wp
    state%volumetric_plastic_strain = 0.0_wp
    state%yield_surface_size = 0.0_wp
    state%initialized = .TRUE.

    status%status_code = 0
  END SUBROUTINE State_Init

  !-----------------------------------------------------------------------------
  ! State_Update
  ! Update state with new values
  ! TBP Update for MD_Mat_Geo_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Update(state, stress, strain, eps_pl, &
                                      eqps, vol_eps, status)
    CLASS(MD_Mat_Geo_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(IN) :: eps_pl(6)
    REAL(wp), INTENT(IN) :: eqps
    REAL(wp), INTENT(IN) :: vol_eps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = stress
    state%strain = strain
    state%plastic_strain = eps_pl
    state%equivalent_plastic_strain = eqps
    state%volumetric_plastic_strain = vol_eps

    status%status_code = 0
  END SUBROUTINE State_Update

  !-----------------------------------------------------------------------------
  ! State_Clean
  ! Reset state to initial values
  ! TBP Clean for MD_Mat_Geo_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Clean(state, status)
    CLASS(MD_Mat_Geo_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equivalent_plastic_strain = 0.0_wp
    state%volumetric_plastic_strain = 0.0_wp
    state%yield_surface_size = 0.0_wp
    state%initialized = .FALSE.

    status%status_code = 0
  END SUBROUTINE State_Clean

  !-----------------------------------------------------------------------------
  ! Algo_Init
  ! Initialize algorithm parameters
  ! TBP Init for MD_Mat_Geo_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Init(algo, status)
    CLASS(MD_Mat_Geo_Algo), INTENT(INOUT) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    algo%integration_method = 1
    algo%return_mapping = 1
    algo%max_iter = 50
    algo%tolerance = 1.0e-8_wp

    status%status_code = 0
  END SUBROUTINE Algo_Init

  !-----------------------------------------------------------------------------
  ! Algo_Config
  ! Configure algorithm parameters
  ! TBP Config for MD_Mat_Geo_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Config(algo, return_mapping, max_iter, &
                                     tolerance, status)
    CLASS(MD_Mat_Geo_Algo), INTENT(INOUT) :: algo
    INTEGER(i4), INTENT(IN), OPTIONAL :: return_mapping
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter
    REAL(wp), INTENT(IN), OPTIONAL :: tolerance
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (PRESENT(return_mapping)) algo%return_mapping = return_mapping
    IF (PRESENT(max_iter)) algo%max_iter = max_iter
    IF (PRESENT(tolerance)) algo%tolerance = tolerance

    status%status_code = 0
  END SUBROUTINE Algo_Config

  !-----------------------------------------------------------------------------
  ! Ctx_Init
  ! Initialize runtime context
  ! TBP Init for MD_Mat_Geo_Ctx
  !-----------------------------------------------------------------------------
  SUBROUTINE Ctx_Init(ctx, status)
    CLASS(MD_Mat_Geo_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    ctx%stp%temperature = 293.15_wp
    ctx%field_var = 0.0_wp

    status%status_code = 0
  END SUBROUTINE Ctx_Init

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Geo_Reg_Arg
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
  END TYPE MD_Mat_Geo_Reg_Arg

END MODULE MD_Mat_Geo_Def
