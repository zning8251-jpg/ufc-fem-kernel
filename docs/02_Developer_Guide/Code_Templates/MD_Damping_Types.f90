!==============================================================================!
! MODULE MD_Damping_Types
! Layer  : L3_MD  (What / model description)
! Domain : Damping  –  structural damping and dynamic dissipation definitions
!
! Four TYPE kinds:
!   MD_RayleighDamp_Desc  – Rayleigh (mass+stiffness proportional) damping
!   MD_CompDamp_Desc      – composite damping (modal, fraction of critical)
!   MD_StructDamp_Desc    – structural (hysteretic) damping coefficient
!   MD_Damp_Algo          – algorithmic parameters for damping assembly
!==============================================================================!
MODULE MD_Damping_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Damping model selector constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_RAYLEIGH    = 1_i4  ! C = α·M + β·K  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_COMPOSITE   = 2_i4  ! per-material fraction  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_STRUCTURAL  = 3_i4  ! s·K (hysteretic)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_NONE        = 0_i4  ! migrated

  ! Stiffness matrix variant for β·K term
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_K_CURRENT   = 1_i4  ! current stiffness  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_K_INITIAL   = 2_i4  ! initial stiffness  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DAMP_DAMP_K_LAST_NR   = 3_i4  ! last NR iteration K  ! migrated

  ! ------------------------------------------------------------------ !
  ! MD_RayleighDamp_Desc
  !   Mass-proportional (α) and stiffness-proportional (β) Rayleigh
  !   damping coefficients.  Corresponds to *DAMPING keyword.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_RayleighDamp_Desc
    REAL(wp)    :: alpha         = 0.0_wp  ! mass-proportional coeff  [1/time]
    REAL(wp)    :: beta          = 0.0_wp  ! stiffness-proportional coeff [time]
    INTEGER(i4) :: k_variant     = MD_DAMP_DAMP_K_CURRENT
    LOGICAL     :: frequency_dep = .FALSE. ! .T. → α/β depend on frequency
    INTEGER(i4) :: n_freq_pts    = 0_i4   ! if frequency-dependent: number of pts
    REAL(wp), ALLOCATABLE :: freq(:)       ! frequencies [n_freq_pts]
    REAL(wp), ALLOCATABLE :: alpha_f(:)    ! α at each frequency
    REAL(wp), ALLOCATABLE :: beta_f(:)     ! β at each frequency
    LOGICAL     :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_RayleighDamp_Desc

  ! ------------------------------------------------------------------ !
  ! MD_CompDamp_Desc
  !   Composite (modal) damping: fraction of critical damping per mode
  !   or per frequency range.  Used with *DAMPING, COMPOSITE.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_CompDamp_Desc
    INTEGER(i4)           :: n_regions    = 0_i4    ! number of modal/freq regions
    REAL(wp), ALLOCATABLE :: f_lower(:)             ! lower frequency bound [n_regions]
    REAL(wp), ALLOCATABLE :: f_upper(:)             ! upper frequency bound
    REAL(wp), ALLOCATABLE :: zeta(:)                ! fraction of critical damping
    REAL(wp)              :: zeta_global  = 0.0_wp  ! global fallback if n_regions=0
    LOGICAL               :: is_active    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_CompDamp_Desc

  ! ------------------------------------------------------------------ !
  ! MD_StructDamp_Desc
  !   Structural (hysteretic) damping: C = s·K/ω  in frequency domain.
  !   Corresponds to *DAMPING, STRUCTURAL or material-level SDAMP.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_StructDamp_Desc
    REAL(wp)    :: s_coeff       = 0.0_wp  ! structural damping coefficient s
    REAL(wp)    :: ref_freq      = 0.0_wp  ! reference frequency [Hz], 0 = default
    LOGICAL     :: material_level= .FALSE. ! .T. → defined per-material
    CHARACTER(LEN=80) :: mat_name= ' '     ! material name if material_level
    LOGICAL     :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_StructDamp_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Damp_Algo
  !   Algorithmic parameters controlling how damping matrices are
  !   assembled and applied during the time integration.
  !   This is L3_MD level (INP-driven, not per-increment tuning).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Damp_Algo
    INTEGER(i4) :: damp_model       = MD_DAMP_DAMP_NONE  ! primary damping model selector
    LOGICAL     :: apply_to_mass    = .TRUE.      ! include α·M term
    LOGICAL     :: apply_to_stiff   = .TRUE.      ! include β·K term
    LOGICAL     :: lump_damp_matrix = .FALSE.     ! lump C to diagonal
    REAL(wp)    :: scale_factor     = 1.0_wp      ! global damping scale
    LOGICAL     :: update_each_iter = .FALSE.     ! reform C each NR iteration
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Damp_Algo

END MODULE MD_Damping_Types
