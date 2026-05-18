!===============================================================================
! MODULE: MD_Mat_Hyper_Def
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Hyperelastic
! Purpose: Family-level descriptor and state; SSOT sub-types from MD_Mat_Family_Def.
!          Four TYPE system: Desc/State/Algo/Ctx with auxiliary type nesting.
!===============================================================================
MODULE MD_Mat_Hyper_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_HYPERELASTIC, MD_MAT_PROP_NONE, &
    MD_MAT_HE_SUB_NEOHOOKEAN, MD_MAT_HE_SUB_MOONEY2, MD_MAT_HE_SUB_MOONEY5, &
    MD_MAT_HE_SUB_OGDEN2, MD_MAT_HE_SUB_OGDEN3, MD_MAT_HE_SUB_YEOH, &
    MD_MAT_HE_SUB_ARRUDA_BOYCE, MD_MAT_HE_SUB_GENT, MD_MAT_HE_SUB_HYPERFOAM, &
    MD_MAT_HE_SUB_MARLOW, MD_MAT_HE_SUB_VAN_DW
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_HYPER_MAX_COEFFS = 20_i4

  PUBLIC :: MD_MAT_FAMILY_HYPERELASTIC, MD_MAT_PROP_NONE
  PUBLIC :: MD_MAT_HE_SUB_NEOHOOKEAN, MD_MAT_HE_SUB_MOONEY2, MD_MAT_HE_SUB_MOONEY5
  PUBLIC :: MD_MAT_HE_SUB_OGDEN2, MD_MAT_HE_SUB_OGDEN3, MD_MAT_HE_SUB_YEOH
  PUBLIC :: MD_MAT_HE_SUB_ARRUDA_BOYCE, MD_MAT_HE_SUB_GENT, MD_MAT_HE_SUB_HYPERFOAM
  PUBLIC :: MD_MAT_HE_SUB_MARLOW, MD_MAT_HE_SUB_VAN_DW
  PUBLIC :: MD_HYPER_MAX_COEFFS
  PUBLIC :: MD_Mat_Hyper_Cfg_Init_Desc
  PUBLIC :: MD_Mat_Hyper_Pop_Vld_Desc
  PUBLIC :: MD_Mat_Hyper_Stp_Evo_Ctx
  PUBLIC :: MD_Mat_Hyper_Desc
  PUBLIC :: MD_Mat_Hyper_State
  PUBLIC :: MD_Mat_Hyper_Algo
  PUBLIC :: MD_Mat_Hyper_Ctx
  PUBLIC :: MD_Mat_Hyper_Reg_Arg

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Cfg_Init_Desc — configuration/initialization fields
  ! Nested inside Desc via %cfg component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = MD_MAT_FAMILY_HYPERELASTIC
    INTEGER(i4) :: sub_type       = MD_MAT_HE_SUB_NEOHOOKEAN
    INTEGER(i4) :: property_flags = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants  = 0_i4
    INTEGER(i4) :: dependencies   = 0_i4
  END TYPE MD_Mat_Hyper_Cfg_Init_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Pop_Vld_Desc — population/validation state
  ! Nested inside Desc via %pop component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Hyper_Pop_Vld_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Stp_Evo_Ctx — step evolution context
  ! Nested inside Ctx via %stp component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_Stp_Evo_Ctx
    REAL(wp) :: deformation_gradient(3,3) = 0.0_wp
    REAL(wp) :: J = 1.0_wp
  END TYPE MD_Mat_Hyper_Stp_Evo_Ctx

  !-----------------------------------------------------------------------------
  ! TYPE: MD_Mat_Hyper_Desc — hyperelastic (sub_type = MD_MAT_HE_SUB_*)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Hyper_Desc
    ! Nested auxiliary types
    TYPE(MD_Mat_Hyper_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Hyper_Pop_Vld_Desc) :: pop

    REAL(wp), ALLOCATABLE :: constants(:,:)

    REAL(wp) :: C10     = 0.0_wp
    REAL(wp) :: C01     = 0.0_wp
    REAL(wp) :: D1      = 0.0_wp
    REAL(wp) :: mu      = 0.0_wp
    REAL(wp) :: lambda  = 0.0_wp
    REAL(wp) :: coeffs(MD_HYPER_MAX_COEFFS) = 0.0_wp
    INTEGER(i4) :: n_coeffs = 0_i4
    REAL(wp) :: density = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => Desc_Init
    PROCEDURE :: Valid => Desc_Validate
    PROCEDURE :: ComputeDerived => MD_Mat_Hyper_ComputeDerived
    PROCEDURE :: Clean => MD_Mat_Hyper_Clean
  END TYPE MD_Mat_Hyper_Desc

  !-----------------------------------------------------------------------------
  ! TYPE: MD_Mat_Hyper_State
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_State
    REAL(wp) :: J = 1.0_wp
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean => State_Clean
  END TYPE MD_Mat_Hyper_State

  !-----------------------------------------------------------------------------
  ! TYPE: MD_Mat_Hyper_Algo — algorithm descriptor
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_Algo
    INTEGER(i4) :: formulation = 1  ! 1=neo-Hookean, 2=Mooney-Rivlin, 3=Ogden, etc.
  CONTAINS
    PROCEDURE :: Init => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Hyper_Algo

  !-----------------------------------------------------------------------------
  ! TYPE: MD_Mat_Hyper_Ctx — runtime context
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Hyper_Ctx
    TYPE(MD_Mat_Hyper_Stp_Evo_Ctx) :: stp
    REAL(wp) :: stress(6) = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
  END TYPE MD_Mat_Hyper_Ctx

CONTAINS

  !-----------------------------------------------------------------------------
  ! Desc_Init
  ! Initialize hyperelastic material descriptor
  ! TBP Init for MD_Mat_Hyper_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(desc, sub_type, num_constants, &
                                     dependencies, status)
    CLASS(MD_Mat_Hyper_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: num_constants
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    desc%cfg%family_type = MD_MAT_FAMILY_HYPERELASTIC
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
  ! Validate hyperelastic material descriptor
  ! TBP Valid for MD_Mat_Hyper_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Validate(desc, status)
    CLASS(MD_Mat_Hyper_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (.NOT. desc%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Hyperelastic material descriptor not initialized"
      RETURN
    END IF

    status%status_code = 0
  END SUBROUTINE Desc_Validate

  !-----------------------------------------------------------------------------
  ! MD_Mat_Hyper_ComputeDerived
  ! Compute derived properties (mu, lambda from C10, D1)
  ! TBP ComputeDerived for MD_Mat_Hyper_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Hyper_ComputeDerived(desc, status)
    CLASS(MD_Mat_Hyper_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (.NOT. desc%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Hyperelastic material descriptor not initialized"
      RETURN
    END IF

    ! mu = 2*(C10 + C01) for Mooney-Rivlin; mu = 2*C10 for neo-Hookean
    desc%mu = 2.0_wp * (desc%C10 + desc%C01)

    ! Bulk modulus from D1: K = 2/D1 (if D1 > 0)
    IF (desc%D1 > 0.0_wp) THEN
      desc%lambda = 2.0_wp / desc%D1
    ELSE
      desc%lambda = 0.0_wp
    END IF

    status%status_code = 0
  END SUBROUTINE MD_Mat_Hyper_ComputeDerived

  !-----------------------------------------------------------------------------
  ! MD_Mat_Hyper_Clean
  ! Deallocate and reset hyperelastic descriptor
  ! TBP Clean for MD_Mat_Hyper_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Hyper_Clean(desc, status)
    CLASS(MD_Mat_Hyper_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (ALLOCATED(desc%constants)) DEALLOCATE(desc%constants)

    desc%cfg%family_type = MD_MAT_FAMILY_HYPERELASTIC
    desc%cfg%sub_type = MD_MAT_HE_SUB_NEOHOOKEAN
    desc%cfg%property_flags = MD_MAT_PROP_NONE
    desc%cfg%num_constants = 0_i4
    desc%cfg%dependencies = 0_i4

    desc%pop%is_initialized = .FALSE.

    desc%C10 = 0.0_wp; desc%C01 = 0.0_wp; desc%D1 = 0.0_wp
    desc%mu = 0.0_wp; desc%lambda = 0.0_wp
    desc%coeffs = 0.0_wp; desc%n_coeffs = 0_i4
    desc%density = 0.0_wp

    status%status_code = 0
  END SUBROUTINE MD_Mat_Hyper_Clean

  !-----------------------------------------------------------------------------
  ! State_Init
  ! Initialize state
  ! TBP Init for MD_Mat_Hyper_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Init(state, status)
    CLASS(MD_Mat_Hyper_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%J = 1.0_wp
    status%status_code = 0
  END SUBROUTINE State_Init

  !-----------------------------------------------------------------------------
  ! State_Update
  ! Update state with new Jacobian
  ! TBP Update for MD_Mat_Hyper_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Update(state, J, status)
    CLASS(MD_Mat_Hyper_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: J
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%J = J
    status%status_code = 0
  END SUBROUTINE State_Update

  !-----------------------------------------------------------------------------
  ! State_Clean
  ! Reset state to initial values
  ! TBP Clean for MD_Mat_Hyper_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Clean(state, status)
    CLASS(MD_Mat_Hyper_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%J = 1.0_wp
    status%status_code = 0
  END SUBROUTINE State_Clean

  !-----------------------------------------------------------------------------
  ! Algo_Init
  ! Initialize algorithm parameters
  ! TBP Init for MD_Mat_Hyper_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Init(algo, status)
    CLASS(MD_Mat_Hyper_Algo), INTENT(INOUT) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    algo%formulation = 1
    status%status_code = 0
  END SUBROUTINE Algo_Init

  !-----------------------------------------------------------------------------
  ! Algo_Config
  ! Configure algorithm parameters
  ! TBP Config for MD_Mat_Hyper_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Config(algo, formulation, status)
    CLASS(MD_Mat_Hyper_Algo), INTENT(INOUT) :: algo
    INTEGER(i4), INTENT(IN) :: formulation
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    algo%formulation = formulation
    status%status_code = 0
  END SUBROUTINE Algo_Config

  !-----------------------------------------------------------------------------
  ! Ctx_Init
  ! Initialize runtime context
  ! TBP Init for MD_Mat_Hyper_Ctx
  !-----------------------------------------------------------------------------
  SUBROUTINE Ctx_Init(ctx, status)
    CLASS(MD_Mat_Hyper_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    ctx%stp%deformation_gradient = 0.0_wp
    ctx%stp%J = 1.0_wp
    ctx%stress = 0.0_wp
    status%status_code = 0
  END SUBROUTINE Ctx_Init

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Hyper_Reg_Arg
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
  END TYPE MD_Mat_Hyper_Reg_Arg

END MODULE MD_Mat_Hyper_Def
