!==============================================================================!
! MODULE MD_Material_Types
! Layer  : L3_MD  (What / model description)
! Domain : Material  –  generic material behaviour category descriptions
!
! Provides top-level INP-driven descriptors for broad material categories
! that span multiple specific subroutines (UMAT/VUMAT/UHYPER/CREEP…).
!
!   MD_Aniso_Desc         – anisotropic elasticity (*ELASTIC, ANISOTROPIC)
!   MD_HyperelasticGen_Desc– generic hyperelastic description (NEO-HOOKEAN/OGDEN…)
!   MD_ViscoMat_Desc      – viscoelastic / rate-dependent material description
!   MD_Plastic_Desc       – general plasticity description (J2/Drucker/Hill…)
!   MD_Damage_Desc        – continuum damage mechanics material descriptor
!   MD_CoupledMat_Desc    – coupled thermo-mechanical material descriptor
!==============================================================================!
MODULE MD_Material_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Elasticity type constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_ELAS_ISOTROPIC     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_ELAS_ORTHOTROPIC   = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_ELAS_ANISOTROPIC   = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_ELAS_COUPLED_TEMP  = 4_i4  ! migrated

  ! Hyperelastic model constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_NEO_HOOKEAN  = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_MOONEY_RIVLIN= 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_OGDEN        = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_POLYNOMIAL   = 4_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_YEOH         = 5_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HYPER_HYPER_USER         = 9_i4  ! UHYPER  ! migrated

  ! Plasticity model constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_PLAST_J2           = 1_i4  ! von Mises  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_PLAST_HILL         = 2_i4  ! Hill orthotropic  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_PLAST_DRUCKER      = 3_i4  ! Drucker-Prager  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_PLAST_CAP          = 4_i4  ! cap model  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_PLAST_USER         = 9_i4  ! UMAT  ! migrated

  ! ------------------------------------------------------------------ !
  ! MD_Aniso_Desc
  !   21 independent elastic stiffness constants for fully anisotropic
  !   elasticity.  Corresponds to *ELASTIC, TYPE=ANISOTROPIC.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Aniso_Desc
    CHARACTER(LEN=80) :: mat_name    = ' '
    INTEGER(i4)       :: elas_type   = MD_MAT_ELAS_ANISOTROPIC
    REAL(wp)          :: cij(21)     = 0.0_wp  ! upper-triangular Cij [21 values]
    REAL(wp)          :: temp_ref    = 0.0_wp  ! reference temperature
    LOGICAL           :: temp_dep    = .FALSE. ! temperature-dependent
    INTEGER(i4)       :: n_temp_pts  = 0_i4
    REAL(wp), ALLOCATABLE :: cij_t(:,:)     ! [21, n_temp_pts]
    REAL(wp), ALLOCATABLE :: temp_pts(:)       ! [n_temp_pts]
    LOGICAL           :: is_active   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Aniso_Desc

  ! ------------------------------------------------------------------ !
  ! MD_HyperelasticGen_Desc
  !   Generic hyperelastic material description covering built-in
  !   Abaqus models and user-defined (UHYPER) variants.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_HyperelasticGen_Desc
    CHARACTER(LEN=80)     :: mat_name    = ' '
    INTEGER(i4)           :: model_type  = MD_MAT_HYPER_NEO_HOOKEAN
    INTEGER(i4)           :: n_params    = 0_i4   ! number of model parameters
    REAL(wp), ALLOCATABLE :: params(:)            ! [n_params] model constants
    INTEGER(i4)           :: n_terms     = 1_i4   ! Ogden/polynomial order
    LOGICAL               :: compressible= .FALSE.
    REAL(wp)              :: d_bulk      = 0.0_wp ! bulk compressibility coeff D
    LOGICAL               :: is_active   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_HyperelasticGen_Desc

  ! ------------------------------------------------------------------ !
  ! MD_ViscoMat_Desc
  !   Viscoelastic / rate-dependent material description.
  !   Covers *VISCOELASTIC (Prony) and creep (*CREEP, *VISCO).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_ViscoMat_Desc
    CHARACTER(LEN=80)     :: mat_name     = ' '
    INTEGER(i4)           :: n_prony      = 0_i4   ! number of Prony terms
    REAL(wp), ALLOCATABLE :: g_k(:)                ! shear relaxation moduli
    REAL(wp), ALLOCATABLE :: tau_k(:)              ! shear relaxation times
    REAL(wp), ALLOCATABLE :: k_k(:)                ! bulk relaxation moduli
    REAL(wp)              :: g_inf        = 0.0_wp ! long-term shear modulus
    REAL(wp)              :: k_inf        = 0.0_wp ! long-term bulk modulus
    LOGICAL               :: has_creep    = .FALSE.! coupled creep
    LOGICAL               :: is_active    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_ViscoMat_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Plastic_Desc
  !   General plasticity material description (yield surface + hardening).
  !   Pairs with UMAT/UHARD user subroutines.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Plastic_Desc
    CHARACTER(LEN=80)     :: mat_name       = ' '
    INTEGER(i4)           :: plast_model    = MD_MAT_PLAST_J2
    INTEGER(i4)           :: n_hard_pts     = 0_i4   ! hardening data points
    REAL(wp), ALLOCATABLE :: yield_stress(:)          ! [n_hard_pts]
    REAL(wp), ALLOCATABLE :: eqpl_strain(:)           ! [n_hard_pts]
    REAL(wp)              :: temp_ref       = 0.0_wp
    LOGICAL               :: kinematic_hard = .FALSE. ! kinematic hardening
    LOGICAL               :: isotropic_hard = .TRUE.
    LOGICAL               :: user_hard      = .FALSE. ! use UHARD
    LOGICAL               :: is_active      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Plastic_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Damage_Desc
  !   Continuum damage mechanics material descriptor.
  !   Covers *DAMAGE INITIATION + *DAMAGE EVOLUTION blocks.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Damage_Desc
    CHARACTER(LEN=80) :: mat_name        = ' '
    INTEGER(i4)       :: n_damage_vars   = 0_i4   ! number of damage variables
    REAL(wp)          :: d_init          = 0.0_wp  ! damage initiation threshold
    REAL(wp)          :: d_max           = 0.999_wp ! maximum damage (caps at 1)
    REAL(wp)          :: gc              = 0.0_wp  ! fracture energy [energy/area]
    LOGICAL           :: viscous_reg     = .FALSE. ! viscous regularization
    REAL(wp)          :: visc_eta        = 1.0e-5_wp ! viscous factor
    LOGICAL           :: delete_elem     = .FALSE. ! element deletion flag
    LOGICAL           :: is_active       = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Damage_Desc

  ! ------------------------------------------------------------------ !
  ! MD_CoupledMat_Desc
  !   Coupled thermo-mechanical material descriptor.
  !   Captures conductivity, specific heat, and expansion in one type.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_CoupledMat_Desc
    CHARACTER(LEN=80)     :: mat_name     = ' '
    REAL(wp)              :: kappa        = 0.0_wp  ! thermal conductivity
    REAL(wp)              :: cp           = 0.0_wp  ! specific heat
    REAL(wp)              :: rho          = 0.0_wp  ! density
    REAL(wp)              :: inelastic_frac= 0.9_wp  ! inelastic heat fraction
    LOGICAL               :: temp_dep     = .FALSE.
    INTEGER(i4)           :: n_temp_pts   = 0_i4
    REAL(wp), ALLOCATABLE :: temp_pts(:)
    REAL(wp), ALLOCATABLE :: kappa_t(:)             ! k(T)
    REAL(wp), ALLOCATABLE :: cp_t(:)                ! cp(T)
    LOGICAL               :: is_active    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_CoupledMat_Desc

END MODULE MD_Material_Types
