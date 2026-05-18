! =============================================================================
! FILE: PH_CFD_Types.f90
! LAYER: L4_PH  —  Physical Handler Layer
! DOMAIN: CFD (Computational Fluid Dynamics) — Abaqus/CFD User Subroutines
!
! SUBROUTINES COVERED:
!   SMACfdUserPressureBC  — user-defined pressure BC for CFD analysis
!   SMACfdUserVelocityBC  — user-defined velocity BC for CFD analysis
!
! These are Abaqus/CFD-specific C/C++ callable user subroutines.
! The UFC Fortran TYPE wrappers here provide the equivalent data carriers
! for integration with the UFC L4_PH dispatch layer.
!
! PATTERN: Ctx / State / Algo  (3 TYPE per subroutine, 6 total)
! =============================================================================

MODULE PH_CFD_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! SMACfdUserPressureBC — user-defined pressure boundary condition (CFD)
  !   Called to prescribe the total or static pressure at a CFD boundary face.
  !   Ref: Abaqus User Subroutines Reference, SMACfdUserPressureBC section.
  !
  !   Note: The original interface is in C; this Fortran TYPE wraps the
  !         equivalent data for UFC L4_PH dispatch.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_CFD_PressureBC_Ctx
    ! --- Spatial / temporal inputs (I) ---
    REAL(wp)    :: coords(3)    = 0.0_wp   ! I  face centroid coordinates
    REAL(wp)    :: normal(3)    = 0.0_wp   ! I  outward face normal
    REAL(wp)    :: time_total   = 0.0_wp   ! I  total analysis time
    REAL(wp)    :: time_step    = 0.0_wp   ! I  step time
    REAL(wp)    :: dtime        = 0.0_wp   ! I  time increment
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    ! --- CFD-specific state inputs (I) ---
    REAL(wp)    :: pressure_ref = 0.0_wp   ! I  current pressure (iterate value)
    REAL(wp)    :: velocity(3)  = 0.0_wp   ! I  current velocity at boundary
    REAL(wp)    :: density      = 0.0_wp   ! I  fluid density
    REAL(wp)    :: temp_fluid   = 0.0_wp   ! I  fluid temperature
    INTEGER(i4) :: bc_type      = 0_i4     ! I  0=static, 1=total, 2=stagnation
    CHARACTER(LEN=80) :: bcname = ' '      ! I  boundary condition set name
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_PressureBC_Ctx

  TYPE, PUBLIC :: PH_CFD_PressureBC_State
    ! --- Outputs (O) ---
    REAL(wp)    :: pressure_bc  = 0.0_wp   ! O  prescribed pressure value (Pa)
    REAL(wp)    :: dp_dt        = 0.0_wp   ! O  d(pressure)/d(time)  for BDF
    REAL(wp)    :: dp_dv(3)     = 0.0_wp   ! O  d(pressure)/d(velocity)  Jacobian
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_PressureBC_State

  TYPE, PUBLIC :: PH_CFD_PressureBC_Algo
    INTEGER(i4) :: pressure_type    = 0_i4   ! 0=static, 1=total pressure
    LOGICAL     :: compressible      = .FALSE.
    LOGICAL     :: provide_jacobians = .TRUE.
    REAL(wp)    :: p_tol             = 1.0e-8_wp
    REAL(wp)    :: mach_ref          = 0.0_wp   ! reference Mach number (if compressible)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_PressureBC_Algo

  ! ---------------------------------------------------------------------------
  ! SMACfdUserVelocityBC — user-defined velocity boundary condition (CFD)
  !   Called to prescribe the velocity vector at a CFD boundary face.
  !   Ref: Abaqus User Subroutines Reference, SMACfdUserVelocityBC section.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_CFD_VelocityBC_Ctx
    ! --- Spatial / temporal inputs (I) ---
    REAL(wp)    :: coords(3)    = 0.0_wp   ! I  face centroid coordinates
    REAL(wp)    :: normal(3)    = 0.0_wp   ! I  outward face normal
    REAL(wp)    :: time_total   = 0.0_wp   ! I  total analysis time
    REAL(wp)    :: time_step    = 0.0_wp   ! I  step time
    REAL(wp)    :: dtime        = 0.0_wp   ! I  time increment
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    ! --- CFD-specific state inputs (I) ---
    REAL(wp)    :: velocity_ref(3) = 0.0_wp  ! I  current iterate velocity
    REAL(wp)    :: pressure_fluid  = 0.0_wp  ! I  current fluid pressure
    REAL(wp)    :: density         = 0.0_wp  ! I  fluid density
    REAL(wp)    :: temp_fluid      = 0.0_wp  ! I  fluid temperature
    INTEGER(i4) :: bc_type         = 0_i4   ! I  0=inflow, 1=wall, 2=slip-wall
    CHARACTER(LEN=80) :: bcname    = ' '    ! I  boundary condition set name
    INTEGER(i4) :: nprops          = 0_i4
    REAL(wp), POINTER :: props(:)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_VelocityBC_Ctx

  TYPE, PUBLIC :: PH_CFD_VelocityBC_State
    ! --- Outputs (O) ---
    REAL(wp)    :: velocity_bc(3)  = 0.0_wp  ! O  prescribed velocity vector (m/s)
    REAL(wp)    :: dv_dt(3)        = 0.0_wp  ! O  d(velocity)/d(time)  for BDF
    REAL(wp)    :: dv_dx(3,3)      = 0.0_wp  ! O  velocity gradient Jacobian
    LOGICAL     :: is_updated      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_VelocityBC_State

  TYPE, PUBLIC :: PH_CFD_VelocityBC_Algo
    INTEGER(i4) :: velocity_type    = 0_i4   ! 0=no-slip, 1=prescribed, 2=inlet
    LOGICAL     :: enforce_normal   = .FALSE. ! only prescribe normal component
    LOGICAL     :: provide_jacobians= .TRUE.
    REAL(wp)    :: v_tol            = 1.0e-8_wp
    REAL(wp)    :: ramp_time        = 0.0_wp  ! ramp from zero over this time
    TYPE(ErrorStatusType) :: status
  END TYPE PH_CFD_VelocityBC_Algo

END MODULE PH_CFD_Types
