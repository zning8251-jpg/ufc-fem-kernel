!==============================================================================!
! MODULE MD_Amplitude_Types
! Layer  : L3_MD  (What / model description)
! Domain : Amplitude  �? time-history amplitude function definitions
!
! Covers all *AMPLITUDE variants supported in Abaqus:
!   MD_Amp_Tabular_Desc   �?tabular amplitude (*AMPLITUDE, DATA LINE)
!   MD_Amp_User_Desc        �?user-defined amplitude via UAMP / VUAMP
!   MD_Amp_Periodic_Desc    �?periodic (sinusoidal) amplitude
!   MD_Amp_Modulated_Desc   �?modulated amplitude (carrier × envelope)
!==============================================================================!
MODULE MD_Amplitude_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Interpolation method constants for tabular amplitudes
  RT_AMP_INTERP_LINEAR  ! DEPRECATED alias: AMP_INTERP_LINEAR 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AMP_INTERP_LOG         = 2_i4
  RT_AMP_INTERP_STEP  ! DEPRECATED alias: AMP_INTERP_STEP 3_i4  ! step function

  ! Time axis reference constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_AMP_AMP_TIME_STEP          = 1_i4  ! relative to step  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_AMP_AMP_TIME_TOTAL         = 2_i4  ! total time  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_AMP_AMP_TIME_CLOCK         = 3_i4  ! wall-clock (dynamic)  ! migrated

  ! ------------------------------------------------------------------ !
  ! MD_Amp_Tabular_Desc
  !   Tabular amplitude: piecewise-linear (or log/step) interpolation
  !   of (time, magnitude) pairs.  Corresponds to *AMPLITUDE keyword.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Amp_Tabular_Desc
    CHARACTER(LEN=80)     :: amp_name       = ' '     ! amplitude set name
    INTEGER(i4)           :: n_points       = 0_i4    ! number of (t, a) pairs
    REAL(wp), ALLOCATABLE :: t_vals(:)                ! time values [n_points]
    REAL(wp), ALLOCATABLE :: a_vals(:)                ! amplitude values [n_points]
    INTEGER(i4)           :: interp_method  = MD_AMP_AMP_INTERP_LINEAR
    INTEGER(i4)           :: time_ref       = AMP_TIME_STEP
    LOGICAL               :: smooth         = .FALSE. ! apply 5th-order smoothing
    REAL(wp)              :: smooth_width   = 0.05_wp ! smoothing half-width fraction
    LOGICAL               :: is_active      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_Tabular_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Amp_User_Desc
  !   User-subroutine amplitude: references UAMP (implicit) or
  !   VUAMP (vectorised explicit).  Parameters passed as props array.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Amp_User_Desc
    CHARACTER(LEN=80)     :: amp_name     = ' '
    LOGICAL               :: use_vuamp    = .FALSE.   ! .T. �?VUAMP, .F. �?UAMP
    INTEGER(i4)           :: nprops       = 0_i4      ! number of user parameters
    REAL(wp), ALLOCATABLE :: props(:)                 ! user parameter array
    INTEGER(i4)           :: nsvars       = 0_i4      ! solution-dependent variables
    INTEGER(i4)           :: n_outvars    = 0_i4      ! output variable count
    INTEGER(i4)           :: time_ref     = AMP_TIME_STEP
    LOGICAL               :: is_active    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_User_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Amp_Periodic_Desc
  !   Periodic (sinusoidal / Fourier) amplitude:
  !     a(t) = A0 + Σ_n [ A_n·cos(n·ω·t) + B_n·sin(n·ω·t) ]
  !   Corresponds to *AMPLITUDE, DEFINITION=PERIODIC.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Amp_Periodic_Desc
    CHARACTER(LEN=80)     :: amp_name    = ' '
    INTEGER(i4)           :: n_terms     = 0_i4    ! number of Fourier terms
    REAL(wp)              :: omega       = 0.0_wp  ! circular frequency [rad/time]
    REAL(wp)              :: t0          = 0.0_wp  ! starting time
    REAL(wp)              :: a0          = 0.0_wp  ! constant term
    REAL(wp), ALLOCATABLE :: a_coeff(:)            ! cosine coefficients [n_terms]
    REAL(wp), ALLOCATABLE :: b_coeff(:)            ! sine coefficients   [n_terms]
    INTEGER(i4)           :: time_ref    = AMP_TIME_STEP
    LOGICAL               :: is_active   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_Periodic_Desc

  ! ------------------------------------------------------------------ !
  ! MD_Amp_Modulated_Desc
  !   Modulated amplitude: product of a carrier amplitude and an
  !   envelope amplitude (both referenced by name).
  !   a(t) = A_carrier(t) × A_envelope(t)
  !   Corresponds to *AMPLITUDE, DEFINITION=MODULATED.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_Amp_Modulated_Desc
    CHARACTER(LEN=80) :: amp_name          = ' '
    CHARACTER(LEN=80) :: carrier_amp_name  = ' '   ! name of carrier amplitude set
    CHARACTER(LEN=80) :: envelope_amp_name = ' '   ! name of envelope amplitude set
    REAL(wp)          :: scale_carrier     = 1.0_wp
    REAL(wp)          :: scale_envelope    = 1.0_wp
    INTEGER(i4)       :: time_ref          = AMP_TIME_STEP
    LOGICAL           :: is_active         = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_Modulated_Desc

  !=============================================================================
  ! MD_Amplitude_Domain  Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Amplitude_Domain
    TYPE(MD_Amp_Tabular_Desc), ALLOCATABLE :: tabular(:)
    TYPE(MD_Amp_Periodic_Desc), ALLOCATABLE :: periodic(:)
    INTEGER(i4) :: n_tabular   = 0_i4
    INTEGER(i4) :: n_periodic  = 0_i4
    INTEGER(i4) :: max_amps    = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_Amplitude_Domain_Init
    PROCEDURE :: Finalize => MD_Amplitude_Domain_Finalize
  END TYPE MD_Amplitude_Domain

CONTAINS

  SUBROUTINE MD_Amplitude_Domain_Init(this, cap_amps, status)
    CLASS(MD_Amplitude_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                INTENT(IN)    :: cap_amps
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Amplitude_Domain_Finalize(this)
    IF (cap_amps < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Amplitude_Domain_Init: cap_amps must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%tabular(cap_amps/2+1))
    ALLOCATE(this%periodic(cap_amps/10+1))
    this%n_tabular   = 0_i4
    this%n_periodic  = 0_i4
    this%max_amps    = cap_amps
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Amplitude_Domain_Init

  SUBROUTINE MD_Amplitude_Domain_Finalize(this)
    CLASS(MD_Amplitude_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%tabular))    DEALLOCATE(this%tabular)
    IF (ALLOCATED(this%periodic))   DEALLOCATE(this%periodic)
    this%n_tabular   = 0_i4
    this%n_periodic  = 0_i4
    this%max_amps    = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Amplitude_Domain_Finalize

END MODULE MD_Amplitude_Types