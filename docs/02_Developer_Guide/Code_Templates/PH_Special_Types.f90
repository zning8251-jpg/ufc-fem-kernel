! =============================================================================
! FILE: PH_Special_Types.f90
! LAYER: L4_PH  —  Physical Handler Layer
! DOMAIN: Special / Miscellaneous Standard Subroutines
!
! SUBROUTINES COVERED (Standard):
!   DFLOW   — pore-fluid seepage velocity (unsaturated flow)
!   HARDINI — initial equivalent plastic strain / backstress
!   RSURFU  — rigid surface definition (analytical rigid body)
!   UCORR   — correlation functions for random response analysis
!   UGENS   — general section stiffness (beam/shell)
!
! PATTERN: each subroutine → Ctx / State / Algo  (3 TYPE per subroutine)
! Total new TYPE: 15
! =============================================================================

MODULE PH_Special_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! DFLOW — pore-fluid seepage velocity (Abaqus/Standard, unsaturated)
  !   Called to define the seepage velocity in porous-media analyses.
  !   Ref: Abaqus User Subroutines Reference, DFLOW section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Spec_DFLOW_Ctx
    ! --- Inputs (I) ---
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  COORDS  current position
    REAL(wp)    :: pore        = 0.0_wp   ! I  PORE    pore pressure
    REAL(wp)    :: amagc       = 0.0_wp   ! I  AMAGC   total seepage velocity magnitude
    REAL(wp)    :: time(2)     = 0.0_wp   ! I  TIME(1)=step, TIME(2)=total
    REAL(wp)    :: dtime       = 0.0_wp   ! I  DTIME
    INTEGER(i4) :: noel        = 0_i4     ! I  NOEL    element number
    INTEGER(i4) :: npt         = 0_i4     ! I  NPT     integration point
    INTEGER(i4) :: kstep       = 0_i4     ! I  KSTEP
    INTEGER(i4) :: kinc        = 0_i4     ! I  KINC
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_DFLOW_Ctx

  TYPE, PUBLIC :: PH_Spec_DFLOW_State
    ! --- Output (O) ---
    REAL(wp)    :: seep_vel(3) = 0.0_wp   ! O  VELSEEP seepage velocity vector
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_DFLOW_State

  TYPE, PUBLIC :: PH_Spec_DFLOW_Algo
    LOGICAL     :: use_darcy         = .TRUE.   ! standard Darcy law
    REAL(wp)    :: permeability_ref  = 1.0e-3_wp
    REAL(wp)    :: saturation_tol    = 1.0e-8_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_DFLOW_Algo

  ! ---------------------------------------------------------------------------
  ! HARDINI — initial hardening state (plasticity)
  !   Called once at the start to define initial equivalent plastic strain
  !   and, optionally, backstress tensor for kinematic hardening.
  !   Ref: Abaqus User Subroutines Reference, HARDINI section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Spec_HARDINI_Ctx
    ! --- Inputs (I) ---
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  COORDS  material point coords
    INTEGER(i4) :: noel        = 0_i4     ! I  NOEL
    INTEGER(i4) :: npt         = 0_i4     ! I  NPT
    INTEGER(i4) :: layer       = 0_i4     ! I  LAYER
    INTEGER(i4) :: kspt        = 0_i4     ! I  KSPT
    INTEGER(i4) :: nstatv      = 0_i4
    INTEGER(i4) :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)     ! material constants
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_HARDINI_Ctx

  TYPE, PUBLIC :: PH_Spec_HARDINI_State
    ! --- Output (O) ---
    REAL(wp)    :: eqplas       = 0.0_wp  ! O  EQPLAS  init equiv plastic strain
    REAL(wp)    :: backstress(6)= 0.0_wp  ! O  BACK    init backstress (kinematic)
    REAL(wp), ALLOCATABLE :: statev(:)    ! O  STATEV  general SDV initialisation
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_HARDINI_State

  TYPE, PUBLIC :: PH_Spec_HARDINI_Algo
    LOGICAL     :: use_backstress   = .FALSE.  ! provide backstress initialisation
    LOGICAL     :: use_sdv_override = .FALSE.  ! override STATEV array too
    REAL(wp)    :: eqplas_floor     = 0.0_wp   ! minimum admissible EQPLAS
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_HARDINI_Algo

  ! ---------------------------------------------------------------------------
  ! RSURFU — user-defined analytical rigid surface geometry
  !   Defines the outward normal and position on a rigid surface for contact.
  !   Ref: Abaqus User Subroutines Reference, RSURFU section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Spec_RSURFU_Ctx
    ! --- Inputs (I) ---
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  point on the rigid surface
    REAL(wp)    :: time(2)     = 0.0_wp   ! I  TIME
    REAL(wp)    :: dtime       = 0.0_wp   ! I  DTIME
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    CHARACTER(LEN=80) :: surfname = ' '   ! I  surface name
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_RSURFU_Ctx

  TYPE, PUBLIC :: PH_Spec_RSURFU_State
    ! --- Output (O) ---
    REAL(wp)    :: f_surf(3)   = 0.0_wp   ! O  FSURF   surface position vector
    REAL(wp)    :: dfsurf(3,3) = 0.0_wp   ! O  DFSURF  d(FSURF)/d(COORDS)
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_RSURFU_State

  TYPE, PUBLIC :: PH_Spec_RSURFU_Algo
    LOGICAL     :: smooth_surface    = .TRUE.
    REAL(wp)    :: tol_normal        = 1.0e-10_wp
    INTEGER(i4) :: max_projection    = 20_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_RSURFU_Algo

  ! ---------------------------------------------------------------------------
  ! UCORR — correlation function for random-response analysis
  !   Defines user spatial/temporal correlation between load components.
  !   Ref: Abaqus User Subroutines Reference, UCORR section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Spec_UCORR_Ctx
    ! --- Inputs (I) ---
    REAL(wp)    :: x1(3)       = 0.0_wp   ! I  coords of point 1
    REAL(wp)    :: x2(3)       = 0.0_wp   ! I  coords of point 2
    REAL(wp)    :: freq         = 0.0_wp   ! I  frequency (rad/s)
    INTEGER(i4) :: kcomp       = 0_i4     ! I  load component index
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    CHARACTER(LEN=8) :: corrname = ' '    ! I  correlation definition name
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UCORR_Ctx

  TYPE, PUBLIC :: PH_Spec_UCORR_State
    ! --- Output (O) ---
    REAL(wp)    :: corr_real   = 0.0_wp   ! O  real part of correlation
    REAL(wp)    :: corr_imag   = 0.0_wp   ! O  imaginary part
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UCORR_State

  TYPE, PUBLIC :: PH_Spec_UCORR_Algo
    LOGICAL     :: is_fully_correlated = .FALSE.
    REAL(wp)    :: decay_length        = 1.0_wp    ! characteristic length scale
    REAL(wp)    :: phase_shift         = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UCORR_Algo

  ! ---------------------------------------------------------------------------
  ! UGENS — general cross-section stiffness for beam/shell elements
  !   Returns the 6×6 (beam) or higher-order section stiffness matrix.
  !   Ref: Abaqus User Subroutines Reference, UGENS section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Spec_UGENS_Ctx
    ! --- Inputs (I) ---
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  COORDS  position of section
    REAL(wp)    :: time(2)     = 0.0_wp   ! I  TIME
    REAL(wp)    :: dtime       = 0.0_wp   ! I  DTIME
    REAL(wp)    :: temp         = 0.0_wp  ! I  TEMP
    REAL(wp)    :: dtemp        = 0.0_wp  ! I  DTEMP
    INTEGER(i4) :: noel        = 0_i4     ! I  NOEL
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: nsecv       = 0_i4    ! number of section variables
    INTEGER(i4) :: ngenshr     = 0_i4    ! number of generalised shear strains
    INTEGER(i4) :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UGENS_Ctx

  TYPE, PUBLIC :: PH_Spec_UGENS_State
    ! --- Output/IO (O/IO) ---
    REAL(wp)    :: stiff(6,6)  = 0.0_wp   ! O  STIFF   section stiffness matrix
    REAL(wp)    :: forces(6)   = 0.0_wp   ! O  FORCE   generalised section forces
    REAL(wp), ALLOCATABLE :: secv(:)       ! IO SECV    section variables (SDV-like)
    REAL(wp)    :: pnewdt      = 1.0_wp   ! O  PNEWDT
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UGENS_State

  TYPE, PUBLIC :: PH_Spec_UGENS_Algo
    LOGICAL     :: use_full_stiff      = .TRUE.   ! return full 6×6 tangent
    LOGICAL     :: use_nonsymmetric    = .FALSE.
    REAL(wp)    :: stiff_tol           = 1.0e-12_wp
    INTEGER(i4) :: max_iter            = 30_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Spec_UGENS_Algo

END MODULE PH_Special_Types
