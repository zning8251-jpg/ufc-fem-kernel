!===============================================================================
! MODULE: MD_Mat_Plast_Def
! LAYER:  L3_MD
! DOMAIN: Material / Plast
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for plastic material family.
!         Implements three-level nesting: family_type + sub_type + property_flags
!         Supports 12 plastic variants: J2_ISO/KIN_LIN/KIN_COMB/HILL/JOHNSON_COOK/
!                                       GTN/ORNL/AF/CHABOCHE/BARLAT/CRYSTAL/J2_TAB
!
!         Design principle (UFC Architecture):
!         - Four TYPE system: Desc/State/Algo/Ctx
!         - Auxiliary type nesting: Cfg_Init_Desc, Pop_Vld_Desc, Stp_Evo_Ctx
!         - Three-level nesting: strictly limited to 3 levels
!         - L3_MD is the single source of truth (SSOT)
!
!         Mapping to ABAQUS keywords:
!         *PLASTIC, HARDENING=ISOTROPIC
!           └─ family_type = MD_MAT_FAMILY_PLASTIC
!              └─ sub_type = MD_MAT_PLAST_SUB_J2_ISO
!                 └─ property_flags = MD_MAT_PROP_NONE
!===============================================================================
MODULE MD_Mat_Plast_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_PLASTIC, &
                                MD_MAT_PLAST_SUB_J2_ISO, &
                                MD_MAT_PLAST_SUB_KIN_LIN, &
                                MD_MAT_PLAST_SUB_KIN_COMB, &
                                MD_MAT_PLAST_SUB_HILL, &
                                MD_MAT_PLAST_SUB_JOHNSON_C, &
                                MD_MAT_PLAST_SUB_GTN, &
                                MD_MAT_PLAST_SUB_ORNL, &
                                MD_MAT_PLAST_SUB_AF, &
                                MD_MAT_PLAST_SUB_CHABOCHE, &
                                MD_MAT_PLAST_SUB_BARLAT, &
                                MD_MAT_PLAST_SUB_CRYSTAL, &
                                MD_MAT_PLAST_SUB_J2_TAB, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP, &
                                MD_MAT_PROP_RATE_DEP
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Plastic sub-type constants (aligned with MD_Mat_Ids.f90)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_J2_ISO_LOCAL    = 201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_KIN_LIN_LOCAL   = 203_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_KIN_COMB_LOCAL  = 204_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_HILL_LOCAL      = 205_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_JOHNSON_C_LOCAL = 206_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_GTN_LOCAL       = 207_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_ORNL_LOCAL      = 208_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_AF_LOCAL        = 209_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_CHABOCHE_LOCAL  = 210_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_BARLAT_LOCAL    = 211_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_CRYSTAL_LOCAL   = 212_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_J2_TAB_LOCAL    = 219_i4

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Cfg_Init_Desc — configuration/initialization fields
  ! Nested inside Desc via %cfg component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_Cfg_Init_Desc
    INTEGER(i4) :: family_type     = MD_MAT_FAMILY_PLASTIC
    INTEGER(i4) :: sub_type        = MD_MAT_PLAST_SUB_J2_ISO
    INTEGER(i4) :: property_flags  = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants   = 0_i4
    INTEGER(i4) :: dependencies    = 0_i4
    INTEGER(i4) :: hardening_type  = 1_i4
  END TYPE MD_Mat_Plast_Cfg_Init_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Pop_Vld_Desc — population/validation state
  ! Nested inside Desc via %pop component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Plast_Pop_Vld_Desc

  !-----------------------------------------------------------------------------
  ! Auxiliary type: Stp_Evo_Ctx — step evolution context
  ! Nested inside Ctx via %stp component
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE MD_Mat_Plast_Stp_Evo_Ctx

  !-----------------------------------------------------------------------------
  ! Desc TYPE: Static descriptor (Level 1 of four TYPE system)
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Plast_Desc
    ! Nested auxiliary types
    TYPE(MD_Mat_Plast_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Plast_Pop_Vld_Desc) :: pop

    ! Material parameters
    REAL(wp), ALLOCATABLE :: constants(:,:)  ! Material constants table

    ! Elastic properties (required for plastic materials)
    REAL(wp) :: E = 0.0_wp          ! Young's modulus
    REAL(wp) :: nu = 0.0_wp         ! Poisson's ratio
    REAL(wp) :: G = 0.0_wp          ! Shear modulus
    REAL(wp) :: K = 0.0_wp          ! Bulk modulus

    ! Yield stress and hardening parameters
    REAL(wp) :: sigma_y = 0.0_wp    ! Initial yield stress
    REAL(wp) :: H_iso = 0.0_wp      ! Isotropic hardening modulus
    REAL(wp) :: H_kin = 0.0_wp      ! Kinematic hardening modulus

    ! Hardening curve (for tabular data)
    INTEGER(i4) :: num_hardening_points = 0
    REAL(wp), ALLOCATABLE :: hardening_curve(:,:)  ! (plastic_strain, stress)

    ! Hill anisotropic parameters (only for HILL sub-type)
    REAL(wp) :: F_hill = 0.0_wp, G_hill = 0.0_wp, H_hill = 0.0_wp
    REAL(wp) :: L_hill = 0.0_wp, M_hill = 0.0_wp, N_hill = 0.0_wp

    ! Johnson-Cook parameters (only for JOHNSON_COOK sub-type)
    REAL(wp) :: A_jc = 0.0_wp, B_jc = 0.0_wp, n_jc = 0.0_wp
    REAL(wp) :: C_jc = 0.0_wp, m_jc = 0.0_wp

    ! GTN porous metal parameters (only for GTN sub-type)
    REAL(wp) :: q1_gtn = 0.0_wp, q2_gtn = 0.0_wp, q3_gtn = 0.0_wp
    REAL(wp) :: f0_gtn = 0.0_wp, fc_gtn = 0.0_wp, ff_gtn = 0.0_wp

    ! Chaboche parameters (only for CHABOCHE sub-type)
    INTEGER(i4) :: num_backstress = 0
    REAL(wp), ALLOCATABLE :: C_chaboche(:)  ! Kinematic hardening moduli
    REAL(wp), ALLOCATABLE :: gamma_chaboche(:)  ! Recovery parameters

  CONTAINS
    PROCEDURE :: Init => Desc_Init
    PROCEDURE :: Valid => Desc_Validate
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean => Desc_Clean
  END TYPE MD_Mat_Plast_Desc

  !-----------------------------------------------------------------------------
  ! State TYPE: Runtime state (Level 2 of four TYPE system)
  ! Note: Plastic materials have internal state variables (plastic strain, etc.)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_State
    REAL(wp) :: stress(6) = 0.0_wp           ! Stress tensor (Voigt notation)
    REAL(wp) :: strain(6) = 0.0_wp           ! Total strain tensor
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain
    REAL(wp) :: plastic_strain(6) = 0.0_wp   ! Plastic strain
    REAL(wp) :: equiv_plastic_strain = 0.0_wp ! Equivalent plastic strain

    ! Internal state variables
    REAL(wp) :: backstress(6) = 0.0_wp       ! Backstress (kinematic hardening)
    REAL(wp) :: alpha_iso = 0.0_wp           ! Isotropic hardening variable
    REAL(wp) :: void_fraction = 0.0_wp       ! Void fraction (for GTN)

    ! State tracking
    LOGICAL :: is_plastic = .FALSE.          ! Whether material is yielding
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean => State_Clean
  END TYPE MD_Mat_Plast_State

  !-----------------------------------------------------------------------------
  ! Algo TYPE: Algorithm descriptor (Level 3 of four TYPE system)
  ! Lifecycle: Set during initialization, immutable during solve
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_Algo
    INTEGER(i4) :: integration_method = 1    ! 1=return mapping, 2=cutting plane
    INTEGER(i4) :: tangent_type = 1          ! 1=consistent, 2=continuum
    INTEGER(i4) :: max_iterations = 50       ! Max iterations for return mapping
    REAL(wp) :: tolerance = 1.0e-8_wp        ! Convergence tolerance
    LOGICAL :: use_numerical_tangent = .FALSE.
    REAL(wp) :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Plast_Algo

  !-----------------------------------------------------------------------------
  ! Ctx TYPE: Runtime context (Level 4 of four TYPE system)
  ! Lifecycle: Created per iteration, can be released after use
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Plast_Ctx
    ! Nested step evolution context
    TYPE(MD_Mat_Plast_Stp_Evo_Ctx) :: stp

    ! Workspace for elastic stiffness
    REAL(wp) :: D_el(6,6) = 0.0_wp           ! Elastic stiffness matrix

    ! Workspace for plastic computation
    REAL(wp) :: stress_trial(6) = 0.0_wp     ! Trial stress
    REAL(wp) :: strain_inc(6) = 0.0_wp       ! Strain increment
    REAL(wp) :: delta_lambda = 0.0_wp        ! Plastic multiplier increment
    REAL(wp) :: yield_function = 0.0_wp      ! Yield function value

    ! Field variable interpolation
    REAL(wp) :: field_var = 0.0_wp           ! Field variable

    ! Iteration tracking
    INTEGER(i4) :: num_iterations = 0
    LOGICAL :: converged = .FALSE.
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
  END TYPE MD_Mat_Plast_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Plast_Cfg_Init_Desc
  PUBLIC :: MD_Mat_Plast_Pop_Vld_Desc
  PUBLIC :: MD_Mat_Plast_Stp_Evo_Ctx
  PUBLIC :: MD_Mat_Plast_Desc
  PUBLIC :: MD_Mat_Plast_State
  PUBLIC :: MD_Mat_Plast_Algo
  PUBLIC :: MD_Mat_Plast_Ctx

  ! Helper functions
  PUBLIC :: Desc_Init
  PUBLIC :: Desc_Validate
  PUBLIC :: MD_Mat_Plast_Get_SubType_Name
  PUBLIC :: Desc_ComputeDerived
  PUBLIC :: Desc_Clean
  PUBLIC :: State_Init
  PUBLIC :: State_Update
  PUBLIC :: State_Clean
  PUBLIC :: Algo_Init
  PUBLIC :: Algo_Config
  PUBLIC :: Ctx_Init

CONTAINS

  !-----------------------------------------------------------------------------
  ! Desc_Init
  ! Initialize plastic material descriptor with three-level nesting
  ! Also serves as TBP Init for MD_Mat_Plast_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Init(desc, sub_type, num_constants, &
                                     dependencies, status)
    CLASS(MD_Mat_Plast_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: num_constants
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Initialize auxiliary config
    desc%cfg%family_type = MD_MAT_FAMILY_PLASTIC
    desc%cfg%sub_type = sub_type
    desc%cfg%property_flags = MD_MAT_PROP_NONE
    desc%cfg%num_constants = num_constants
    desc%cfg%dependencies = 0

    IF (PRESENT(dependencies)) THEN
      desc%cfg%dependencies = dependencies
      IF (dependencies == 1) THEN
        desc%cfg%property_flags = IOR(desc%cfg%property_flags, MD_MAT_PROP_TEMP_DEP)
      ELSE IF (dependencies == 2) THEN
        desc%cfg%property_flags = IOR(desc%cfg%property_flags, MD_MAT_PROP_FIELD_DEP)
      END IF
    END IF

    ! Allocate material constants table
    IF (desc%cfg%dependencies > 0) THEN
      ALLOCATE(desc%constants(desc%cfg%num_constants, desc%cfg%dependencies))
    ELSE
      ALLOCATE(desc%constants(desc%cfg%num_constants, 1))
    END IF

    desc%pop%is_initialized = .TRUE.
    status%status_code = 0  ! Success
  END SUBROUTINE Desc_Init

  !-----------------------------------------------------------------------------
  ! Desc_Validate
  ! Validate plastic material descriptor
  ! Also serves as TBP Valid for MD_Mat_Plast_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Validate(desc, status)
    CLASS(MD_Mat_Plast_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = 0  ! Success

    ! Check if initialized
    IF (.NOT. desc%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Plastic material descriptor not initialized"
      RETURN
    END IF

    ! Validate three-level nesting
    IF (desc%cfg%family_type /= MD_MAT_FAMILY_PLASTIC) THEN
      status%status_code = 2
      status%message = "Invalid family_type for plastic material"
      RETURN
    END IF

    ! Validate sub_type range
    IF (desc%cfg%sub_type < 201 .OR. desc%cfg%sub_type > 219) THEN
      status%status_code = 3
      status%message = "Invalid sub_type for plastic material"
      RETURN
    END IF

    ! Validate elastic properties
    IF (desc%E <= 0.0_wp) THEN
      status%status_code = 4
      status%message = "Young's modulus must be positive"
      RETURN
    END IF

    IF (desc%nu < -1.0_wp .OR. desc%nu >= 0.5_wp) THEN
      status%status_code = 5
      status%message = "Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF

    ! Validate yield stress
    IF (desc%sigma_y <= 0.0_wp) THEN
      status%status_code = 6
      status%message = "Initial yield stress must be positive"
      RETURN
    END IF
  END SUBROUTINE Desc_Validate

  !-----------------------------------------------------------------------------
  ! Desc_ComputeDerived
  ! Compute derived elastic properties (G, K) from E and nu
  ! TBP ComputeDerived for MD_Mat_Plast_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_ComputeDerived(desc, status)
    CLASS(MD_Mat_Plast_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)
    IF (.NOT. desc%pop%is_initialized) THEN
      status%status_code = 1
      status%message = "Plastic material descriptor not initialized"
      RETURN
    END IF

    ! Compute shear modulus G = E / (2*(1+nu))
    desc%G = desc%E / (2.0_wp * (1.0_wp + desc%nu))

    ! Compute bulk modulus K = E / (3*(1-2*nu))
    desc%K = desc%E / (3.0_wp * (1.0_wp - 2.0_wp * desc%nu))

    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  !-----------------------------------------------------------------------------
  ! Desc_Clean
  ! Deallocate and reset plastic descriptor
  ! TBP Clean for MD_Mat_Plast_Desc
  !-----------------------------------------------------------------------------
  SUBROUTINE Desc_Clean(desc, status)
    CLASS(MD_Mat_Plast_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    ! Deallocate material constants
    IF (ALLOCATED(desc%constants)) DEALLOCATE(desc%constants)
    IF (ALLOCATED(desc%hardening_curve)) DEALLOCATE(desc%hardening_curve)
    IF (ALLOCATED(desc%C_chaboche)) DEALLOCATE(desc%C_chaboche)
    IF (ALLOCATED(desc%gamma_chaboche)) DEALLOCATE(desc%gamma_chaboche)

    ! Reset config fields
    desc%cfg%family_type = MD_MAT_FAMILY_PLASTIC
    desc%cfg%sub_type = MD_MAT_PLAST_SUB_J2_ISO
    desc%cfg%property_flags = MD_MAT_PROP_NONE
    desc%cfg%num_constants = 0_i4
    desc%cfg%dependencies = 0_i4
    desc%cfg%hardening_type = 1_i4

    ! Reset validation
    desc%pop%is_initialized = .FALSE.

    ! Reset material properties
    desc%E = 0.0_wp; desc%nu = 0.0_wp; desc%G = 0.0_wp; desc%K = 0.0_wp
    desc%sigma_y = 0.0_wp; desc%H_iso = 0.0_wp; desc%H_kin = 0.0_wp
    desc%num_hardening_points = 0
    desc%F_hill = 0.0_wp; desc%G_hill = 0.0_wp; desc%H_hill = 0.0_wp
    desc%L_hill = 0.0_wp; desc%M_hill = 0.0_wp; desc%N_hill = 0.0_wp
    desc%A_jc = 0.0_wp; desc%B_jc = 0.0_wp; desc%n_jc = 0.0_wp
    desc%C_jc = 0.0_wp; desc%m_jc = 0.0_wp
    desc%q1_gtn = 0.0_wp; desc%q2_gtn = 0.0_wp; desc%q3_gtn = 0.0_wp
    desc%f0_gtn = 0.0_wp; desc%fc_gtn = 0.0_wp; desc%ff_gtn = 0.0_wp
    desc%num_backstress = 0

    status%status_code = 0
  END SUBROUTINE Desc_Clean

  !-----------------------------------------------------------------------------
  ! State_Init
  ! Initialize state variables
  ! TBP Init for MD_Mat_Plast_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Init(state, status)
    CLASS(MD_Mat_Plast_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%elastic_strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%backstress = 0.0_wp
    state%alpha_iso = 0.0_wp
    state%void_fraction = 0.0_wp
    state%is_plastic = .FALSE.
    state%initialized = .TRUE.
    state%num_evaluations = 0

    status%status_code = 0
  END SUBROUTINE State_Init

  !-----------------------------------------------------------------------------
  ! State_Update
  ! Update state variables with new values
  ! TBP Update for MD_Mat_Plast_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Update(state, stress, strain, eps_pl, &
                                        eqps, status)
    CLASS(MD_Mat_Plast_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(IN) :: eps_pl(6)
    REAL(wp), INTENT(IN) :: eqps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = stress
    state%strain = strain
    state%plastic_strain = eps_pl
    state%equiv_plastic_strain = eqps
    state%is_plastic = (eqps > 0.0_wp)
    state%num_evaluations = state%num_evaluations + 1

    status%status_code = 0
  END SUBROUTINE State_Update

  !-----------------------------------------------------------------------------
  ! State_Clean
  ! Reset state to initial values
  ! TBP Clean for MD_Mat_Plast_State
  !-----------------------------------------------------------------------------
  SUBROUTINE State_Clean(state, status)
    CLASS(MD_Mat_Plast_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%elastic_strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%backstress = 0.0_wp
    state%alpha_iso = 0.0_wp
    state%void_fraction = 0.0_wp
    state%is_plastic = .FALSE.
    state%initialized = .FALSE.
    state%num_evaluations = 0

    status%status_code = 0
  END SUBROUTINE State_Clean

  !-----------------------------------------------------------------------------
  ! Algo_Init
  ! Initialize algorithm parameters
  ! TBP Init for MD_Mat_Plast_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Init(algo, status)
    CLASS(MD_Mat_Plast_Algo), INTENT(INOUT) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    algo%integration_method = 1
    algo%tangent_type = 1
    algo%max_iterations = 50
    algo%tolerance = 1.0e-8_wp
    algo%use_numerical_tangent = .FALSE.

    status%status_code = 0
  END SUBROUTINE Algo_Init

  !-----------------------------------------------------------------------------
  ! Algo_Config
  ! Configure algorithm parameters
  ! TBP Config for MD_Mat_Plast_Algo
  !-----------------------------------------------------------------------------
  SUBROUTINE Algo_Config(algo, integration_method, tangent_type, &
                                       max_iter, tolerance, status)
    CLASS(MD_Mat_Plast_Algo), INTENT(INOUT) :: algo
    INTEGER(i4), INTENT(IN), OPTIONAL :: integration_method
    INTEGER(i4), INTENT(IN), OPTIONAL :: tangent_type
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter
    REAL(wp), INTENT(IN), OPTIONAL :: tolerance
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    IF (PRESENT(integration_method)) algo%integration_method = integration_method
    IF (PRESENT(tangent_type)) algo%tangent_type = tangent_type
    IF (PRESENT(max_iter)) algo%max_iterations = max_iter
    IF (PRESENT(tolerance)) algo%tolerance = tolerance

    status%status_code = 0
  END SUBROUTINE Algo_Config

  !-----------------------------------------------------------------------------
  ! Ctx_Init
  ! Initialize runtime context
  ! TBP Init for MD_Mat_Plast_Ctx
  !-----------------------------------------------------------------------------
  SUBROUTINE Ctx_Init(ctx, status)
    CLASS(MD_Mat_Plast_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    call init_error_status(status)

    ctx%stp%temperature = 293.15_wp
    ctx%D_el = 0.0_wp
    ctx%stress_trial = 0.0_wp
    ctx%strain_inc = 0.0_wp
    ctx%delta_lambda = 0.0_wp
    ctx%yield_function = 0.0_wp
    ctx%field_var = 0.0_wp
    ctx%num_iterations = 0
    ctx%converged = .FALSE.

    status%status_code = 0
  END SUBROUTINE Ctx_Init

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Get_SubType_Name
  ! Get the name of a plastic sub-type
  !-----------------------------------------------------------------------------
  FUNCTION MD_Mat_Plast_Get_SubType_Name(sub_type) RESULT(name)
    INTEGER(i4), INTENT(IN) :: sub_type
    CHARACTER(LEN=32) :: name

    SELECT CASE (sub_type)
    CASE (201)
      name = "J2 Isotropic"
    CASE (203)
      name = "Kinematic Linear"
    CASE (204)
      name = "Kinematic Combined"
    CASE (205)
      name = "Hill Anisotropic"
    CASE (206)
      name = "Johnson-Cook"
    CASE (207)
      name = "GTN Porous"
    CASE (208)
      name = "ORNL"
    CASE (209)
      name = "Armstrong-Frederick"
    CASE (210)
      name = "Chaboche"
    CASE (211)
      name = "Barlat"
    CASE (212)
      name = "Crystal Plasticity"
    CASE (219)
      name = "J2 Tabular"
    CASE DEFAULT
      name = "Unknown"
    END SELECT
  END FUNCTION MD_Mat_Plast_Get_SubType_Name

  !=============================================================================
  ! SIO Arg: Registration argument bundle
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Plast_Reg_Arg
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
  END TYPE MD_Mat_Plast_Reg_Arg

END MODULE MD_Mat_Plast_Def
