! =============================================================================
! TEMPLATE FILE: PH_XXX_CFD_BC.f90
! LAYER: L4_PH  —  Physical Handler Layer
! DOMAIN: CFD  —  Computational Fluid Dynamics (Abaqus/CFD)
!
! PURPOSE:
!   UFC-layer wrapper for Abaqus/CFD user boundary condition subroutines.
!   Cover both CFD user subroutines:
!     1. SMACfdUserPressureBC  — user-defined pressure BC
!     2. SMACfdUserVelocityBC  — user-defined velocity BC
!
! USAGE:
!   Copy this file and rename:
!     PH_Fld_<BCName>_PressureBC.f90  for pressure BC specializations
!     PH_Fld_<BCName>_VelocityBC.f90  for velocity BC specializations
!   Examples:
!     PH_Fld_InletTotalPressure.f90
!     PH_Fld_InletPoiseuille.f90
!     PH_Fld_SlipWall.f90
!
! KEY DIFFERENCES VS UMAT/VUMAT:
!
!   UMAT/VUMAT (solid mechanics):
!     - Called at each integration POINT of a solid/structural element
!     - Primary unknowns: strain increment → stress + tangent
!     - UMAT must return ddsdde (tangent stiffness); VUMAT does not
!     - Material state tracked via SDV (state-dependent variables)
!
!   CFD BC Subroutines (SMACfdUser*BC):
!     - Called at each boundary FACE centroid in a CFD mesh
!     - Primary unknowns: velocity (v) and pressure (p) fields
!     - NO tangent matrix needed for BC specification
!       (Jacobians dp/dv, dv/dt are OPTIONAL, improve CFD solver convergence)
!     - No material state variables; boundary is purely output-driven
!     - Called from Abaqus/CFD (C/C++ interface); UFC provides Fortran wrapper
!     - Each call covers ONE boundary face (no NBLOCK vectorization)
!
!   Abaqus/CFD restrictions:
!     - Only 2 user subroutines available (vs 64 for Standard, 25 for Explicit)
!     - No CFD-UMAT equivalent: fluid constitutive models (turbulence, etc.)
!       are handled entirely by Abaqus/CFD internal kernel
!     - Abaqus/CFD uses Eulerian fixed mesh; no Lagrangian deformation tracked
!
! SIO PRINCIPLE #14 (Structured IO):
!   API subroutine signature: (MD_Desc, Ctx, State, Algo, RT_Com_Ctx, pnewdt)
!   All custom parameters bundled in *_Args TYPE with [IN]/[OUT] comments.
!
! =============================================================================

MODULE PH_Fld_XXX_CFD_BC
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status,  &
                           IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE PH_CFD_Types, ONLY: PH_CFD_PressureBC_Ctx,   &
                           PH_CFD_PressureBC_State, &
                           PH_CFD_PressureBC_Algo,  &
                           PH_CFD_VelocityBC_Ctx,   &
                           PH_CFD_VelocityBC_State, &
                           PH_CFD_VelocityBC_Algo
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! Public symbols
  ! ---------------------------------------------------------------------------
  PUBLIC :: PH_Fld_XXX_PressureBC_Args
  PUBLIC :: PH_Fld_XXX_PressureBC_API

  PUBLIC :: PH_Fld_XXX_VelocityBC_Args
  PUBLIC :: PH_Fld_XXX_VelocityBC_API

  ! ---------------------------------------------------------------------------
  ! Algorithm / control parameters (bundle per SIO Principle #14)
  !
  ! PH_Fld_XXX_PressureBC_Args — all custom pressure BC parameters
  ! ---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fld_XXX_PressureBC_Args
    ! [IN]  Boundary condition sub-type
    !   0 = static pressure            (default)
    !   1 = total (stagnation) pressure
    !   2 = user tabulated (time/space)
    INTEGER(i4)           :: bc_subtype     = 0_i4

    ! [IN]  If .TRUE., pressure varies in time and/or space
    LOGICAL               :: time_varying   = .FALSE.

    ! [IN]  Reference pressure offset (for gauge vs absolute distinction)
    REAL(wp)              :: p_gauge_ref    = 0.0_wp

    ! [OUT] Convergence flag (set by _Impl)
    LOGICAL               :: converged      = .FALSE.

    ! [OUT] Error status
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fld_XXX_PressureBC_Args

  ! ---------------------------------------------------------------------------
  ! PH_Fld_XXX_VelocityBC_Args — all custom velocity BC parameters
  ! ---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fld_XXX_VelocityBC_Args
    ! [IN]  Boundary condition sub-type
    !   0 = no-slip wall               (u=0)
    !   1 = prescribed uniform velocity
    !   2 = parabolic / Poiseuille inlet profile
    !   3 = log-law inlet (turbulent)
    !   4 = user tabulated
    INTEGER(i4)           :: bc_subtype     = 0_i4

    ! [IN]  Enforce only normal component? (slip-wall)
    LOGICAL               :: normal_only    = .FALSE.

    ! [IN]  Ramp factor (0→1 over initial time steps for soft start)
    REAL(wp)              :: ramp_factor    = 1.0_wp

    ! [OUT] Convergence flag
    LOGICAL               :: converged      = .FALSE.

    ! [OUT] Error status
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fld_XXX_VelocityBC_Args

CONTAINS

  ! ===========================================================================
  !  P R E S S U R E   B O U N D A R Y   C O N D I T I O N
  ! ===========================================================================

  !> Thin API wrapper for the user pressure BC.
  !> Signature follows SIO 6-parameter convention:
  !>   (MD_Fld_Desc, BC_Ctx, BC_State, BC_Algo, RT_Com_Ctx, pnewdt)
  !>
  !> Called from the UFC L5_RT adapter which wraps SMACfdUserPressureBC.
  SUBROUTINE PH_Fld_XXX_PressureBC_API( &
      MD_Fld_Desc,  &  ! [IN]  L3 fluid material descriptor
      BC_Ctx,       &  ! [IN]  CFD boundary face context (coords, v, p, ρ …)
      BC_State,     &  ! [INOUT] Output: prescribed pressure + Jacobians
      BC_Algo,      &  ! [IN]  Solver-level algorithm settings
      RT_Com_Ctx,   &  ! [IN]  Runtime common context (kstep, kinc, time …)
      pnewdt)          ! [INOUT] Time step size control (analogous to PNEWDT)

    USE MD_Fld_Types, ONLY: MD_Fld_NewtViscous_Desc   ! ← replace as needed
    TYPE(MD_Fld_NewtViscous_Desc),    INTENT(IN)    :: MD_Fld_Desc
    TYPE(PH_CFD_PressureBC_Ctx),      INTENT(IN)    :: BC_Ctx
    TYPE(PH_CFD_PressureBC_State),    INTENT(INOUT) :: BC_State
    TYPE(PH_CFD_PressureBC_Algo),     INTENT(IN)    :: BC_Algo
    TYPE(RT_Com_Base_Ctx),            INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                         INTENT(INOUT) :: pnewdt

    TYPE(PH_Fld_XXX_PressureBC_Args) :: args

    !-- Build args bundle from Algo + RT context --------------------
    args%bc_subtype   = BC_Algo%pressure_type
    args%time_varying = (RT_Com_Ctx%kstep > 0)
    args%p_gauge_ref  = 0.0_wp   ! TODO: read from MD_Fld_Desc if needed

    !-- Delegate to implementation ---------------------------------
    CALL PH_Fld_XXX_PressureBC_Impl(MD_Fld_Desc, BC_Ctx, BC_State, BC_Algo, args)

    !-- Optional: request smaller time step if BC is stiff ----------
    ! IF (args%converged .EQV. .FALSE.) pnewdt = 0.5_wp

  END SUBROUTINE PH_Fld_XXX_PressureBC_API

  ! ---------------------------------------------------------------------------

  !> Core implementation — edit THIS subroutine to define the pressure BC.
  !>
  !> Inputs available via BC_Ctx:
  !>   coords(3)     : face centroid position [m]
  !>   normal(3)     : outward face normal
  !>   time_total    : total analysis time [s]
  !>   time_step     : step time [s]
  !>   dtime         : time increment [s]
  !>   pressure_ref  : current iterate pressure at face [Pa]
  !>   velocity(3)   : current iterate velocity at face [m/s]
  !>   density       : fluid density [kg/m³]
  !>   temp_fluid    : fluid temperature [K]
  !>   nprops/props  : user-defined material property array
  !>   bcname        : boundary set name (CHARACTER)
  !>
  !> Outputs required in BC_State:
  !>   pressure_bc   : prescribed pressure value [Pa]       REQUIRED
  !>   dp_dt         : d(p_bc)/d(time)                      OPTIONAL
  !>   dp_dv(3)      : d(p_bc)/d(velocity)                  OPTIONAL (Jacobian)
  !>   is_updated    : set .TRUE. on success
  SUBROUTINE PH_Fld_XXX_PressureBC_Impl( &
      MD_Fld_Desc,  &
      BC_Ctx,       &
      BC_State,     &
      BC_Algo,      &
      args)
    !$UFC HOT_PATH

    USE MD_Fld_Types, ONLY: MD_Fld_NewtViscous_Desc
    TYPE(MD_Fld_NewtViscous_Desc),    INTENT(IN)    :: MD_Fld_Desc
    TYPE(PH_CFD_PressureBC_Ctx),      INTENT(IN)    :: BC_Ctx
    TYPE(PH_CFD_PressureBC_State),    INTENT(INOUT) :: BC_State
    TYPE(PH_CFD_PressureBC_Algo),     INTENT(IN)    :: BC_Algo
    TYPE(PH_Fld_XXX_PressureBC_Args), INTENT(INOUT) :: args

    REAL(wp) :: v_sq   ! velocity magnitude squared

    CALL init_error_status(args%status)

    SELECT CASE (args%bc_subtype)

      ! ---- Case 0: Static pressure (most common outlet BC) ----
      CASE (0)
        !  props(1) stores the prescribed static pressure value [Pa]
        BC_State%pressure_bc = BC_Ctx%props(1) + args%p_gauge_ref

      ! ---- Case 1: Total (stagnation) pressure ----
      !   p_total = p_static + 0.5 * rho * |v|^2
      !   Prescribed total pressure → compute effective static pressure
      CASE (1)
        v_sq = DOT_PRODUCT(BC_Ctx%velocity, BC_Ctx%velocity)
        BC_State%pressure_bc = BC_Ctx%props(1) &
          - 0.5_wp * BC_Ctx%density * v_sq + args%p_gauge_ref

        ! Jacobian: d(p_static)/d(v_i) = -rho * v_i
        IF (BC_Algo%provide_jacobians) THEN
          BC_State%dp_dv(1) = -BC_Ctx%density * BC_Ctx%velocity(1)
          BC_State%dp_dv(2) = -BC_Ctx%density * BC_Ctx%velocity(2)
          BC_State%dp_dv(3) = -BC_Ctx%density * BC_Ctx%velocity(3)
        END IF

      ! ---- Case 2: Time-varying prescribed pressure ----
      CASE (2)
        ! TODO: implement time/space-dependent pressure
        !   e.g. amplitude table lookup, analytical function, co-simulation data
        BC_State%pressure_bc = BC_Ctx%props(1) * BC_Ctx%time_total / &
          MAX(BC_Ctx%props(2), 1.0e-12_wp)   ! linear ramp example

      CASE DEFAULT
        args%status%status_code = IF_STATUS_WARN
        args%status%message = 'Unknown bc_subtype; using props(1) directly'
        BC_State%pressure_bc = BC_Ctx%props(1)

    END SELECT

    ! Optional: time derivative (for BDF integration in CFD solver)
    IF (BC_Algo%provide_jacobians) THEN
      BC_State%dp_dt = 0.0_wp   ! TODO: fill if time-varying
    END IF

    BC_State%is_updated = .TRUE.
    args%converged      = .TRUE.
  END SUBROUTINE PH_Fld_XXX_PressureBC_Impl

  ! ===========================================================================
  !  V E L O C I T Y   B O U N D A R Y   C O N D I T I O N
  ! ===========================================================================

  !> Thin API wrapper for the user velocity BC.
  SUBROUTINE PH_Fld_XXX_VelocityBC_API( &
      MD_Fld_Desc,  &  ! [IN]  L3 fluid material descriptor
      BC_Ctx,       &  ! [IN]  CFD boundary face context
      BC_State,     &  ! [INOUT] Output: prescribed velocity + Jacobians
      BC_Algo,      &  ! [IN]  Solver-level algorithm settings
      RT_Com_Ctx,   &  ! [IN]  Runtime common context
      pnewdt)          ! [INOUT] Time step control

    USE MD_Fld_Types, ONLY: MD_Fld_NewtViscous_Desc
    TYPE(MD_Fld_NewtViscous_Desc),    INTENT(IN)    :: MD_Fld_Desc
    TYPE(PH_CFD_VelocityBC_Ctx),      INTENT(IN)    :: BC_Ctx
    TYPE(PH_CFD_VelocityBC_State),    INTENT(INOUT) :: BC_State
    TYPE(PH_CFD_VelocityBC_Algo),     INTENT(IN)    :: BC_Algo
    TYPE(RT_Com_Base_Ctx),            INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                         INTENT(INOUT) :: pnewdt

    TYPE(PH_Fld_XXX_VelocityBC_Args) :: args

    args%bc_subtype  = BC_Algo%velocity_type
    args%normal_only = BC_Algo%enforce_normal
    args%ramp_factor = MIN(1.0_wp, BC_Ctx%time_total / MAX(BC_Algo%ramp_time, 1.0e-30_wp))

    CALL PH_Fld_XXX_VelocityBC_Impl(MD_Fld_Desc, BC_Ctx, BC_State, BC_Algo, args)

  END SUBROUTINE PH_Fld_XXX_VelocityBC_API

  ! ---------------------------------------------------------------------------

  !> Core implementation — edit THIS subroutine to define the velocity BC.
  !>
  !> Inputs available via BC_Ctx:
  !>   coords(3)       : face centroid position [m]
  !>   normal(3)       : outward face normal
  !>   velocity_ref(3) : current iterate velocity [m/s]
  !>   pressure_fluid  : current fluid pressure [Pa]
  !>   density         : fluid density [kg/m³]
  !>   temp_fluid      : fluid temperature [K]
  !>   nprops/props    : user property array
  !>   bcname          : boundary set name
  !>
  !> Outputs required in BC_State:
  !>   velocity_bc(3)  : prescribed velocity vector [m/s]    REQUIRED
  !>   dv_dt(3)        : d(v_bc)/d(time)                     OPTIONAL
  !>   dv_dx(3,3)      : velocity gradient Jacobian          OPTIONAL
  !>   is_updated      : set .TRUE. on success
  SUBROUTINE PH_Fld_XXX_VelocityBC_Impl( &
      MD_Fld_Desc,  &
      BC_Ctx,       &
      BC_State,     &
      BC_Algo,      &
      args)
    !$UFC HOT_PATH

    USE MD_Fld_Types, ONLY: MD_Fld_NewtViscous_Desc
    TYPE(MD_Fld_NewtViscous_Desc),    INTENT(IN)    :: MD_Fld_Desc
    TYPE(PH_CFD_VelocityBC_Ctx),      INTENT(IN)    :: BC_Ctx
    TYPE(PH_CFD_VelocityBC_State),    INTENT(INOUT) :: BC_State
    TYPE(PH_CFD_VelocityBC_Algo),     INTENT(IN)    :: BC_Algo
    TYPE(PH_Fld_XXX_VelocityBC_Args), INTENT(INOUT) :: args

    REAL(wp) :: r, R_pipe, v_max, y, z, v_norm

    CALL init_error_status(args%status)

    SELECT CASE (args%bc_subtype)

      ! ---- Case 0: No-slip wall  (v = 0) ----
      CASE (0)
        BC_State%velocity_bc = 0.0_wp

      ! ---- Case 1: Uniform prescribed velocity ----
      !   props(1:3) = prescribed (vx, vy, vz) in global coordinates
      CASE (1)
        BC_State%velocity_bc(1) = BC_Ctx%props(1) * args%ramp_factor
        BC_State%velocity_bc(2) = BC_Ctx%props(2) * args%ramp_factor
        BC_State%velocity_bc(3) = BC_Ctx%props(3) * args%ramp_factor

      ! ---- Case 2: Parabolic inlet (Poiseuille / laminar pipe flow) ----
      !   props(1) = pipe radius R [m]
      !   props(2) = centerline velocity v_max [m/s]
      !   props(3) = pipe axis (0=x, 1=y, 2=z)
      !   Face coordinates relative to pipe axis → radial distance r
      CASE (2)
        R_pipe = MAX(BC_Ctx%props(1), 1.0e-30_wp)
        v_max  = BC_Ctx%props(2) * args%ramp_factor

        y = BC_Ctx%coords(2)
        z = BC_Ctx%coords(3)
        r = SQRT(y**2 + z**2)
        r = MIN(r, R_pipe)

        ! Poiseuille: v(r) = v_max * (1 - (r/R)^2)
        v_norm = v_max * (1.0_wp - (r / R_pipe)**2)

        ! Apply along the specified pipe axis
        BC_State%velocity_bc    = 0.0_wp
        SELECT CASE (INT(BC_Ctx%props(3)))
          CASE (0)
            BC_State%velocity_bc(1) = v_norm
          CASE (1)
            BC_State%velocity_bc(2) = v_norm
          CASE DEFAULT
            BC_State%velocity_bc(3) = v_norm
        END SELECT

      ! ---- Case 3: Slip wall (zero normal velocity, free tangential) ----
      !   Remove only the normal component; tangential slides freely.
      CASE (3)
        v_norm = DOT_PRODUCT(BC_Ctx%velocity_ref, BC_Ctx%normal(1:3))
        BC_State%velocity_bc(1) = BC_Ctx%velocity_ref(1) - v_norm * BC_Ctx%normal(1)
        BC_State%velocity_bc(2) = BC_Ctx%velocity_ref(2) - v_norm * BC_Ctx%normal(2)
        BC_State%velocity_bc(3) = BC_Ctx%velocity_ref(3) - v_norm * BC_Ctx%normal(3)

      ! ---- Case 4: Time-varying inlet velocity ----
      CASE (4)
        ! TODO: implement amplitude table lookup or co-simulation data import
        BC_State%velocity_bc(1) = BC_Ctx%props(1) * args%ramp_factor
        BC_State%velocity_bc(2) = 0.0_wp
        BC_State%velocity_bc(3) = 0.0_wp

      CASE DEFAULT
        args%status%status_code = IF_STATUS_WARN
        args%status%message = 'Unknown bc_subtype; using zero velocity'
        BC_State%velocity_bc = 0.0_wp

    END SELECT

    ! Optional time derivative (BDF integration)
    IF (BC_Algo%provide_jacobians) THEN
      BC_State%dv_dt  = 0.0_wp   ! TODO: fill if time-varying
      BC_State%dv_dx  = 0.0_wp   ! TODO: fill if spatially varying
    END IF

    BC_State%is_updated = .TRUE.
    args%converged      = .TRUE.
  END SUBROUTINE PH_Fld_XXX_VelocityBC_Impl

END MODULE PH_Fld_XXX_CFD_BC
