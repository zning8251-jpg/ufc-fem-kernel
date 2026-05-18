!===============================================================================
! MODULE: PH_Field_Def
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Def — four-type definitions (Desc/Ctx/State/Algo) + physics IO bundles
! BRIEF:  Generic field types plus temperature, pore-pressure, and concentration
!         IO bundles for L4 compute kernels. AUTHORITY for element-level field types.
!===============================================================================
MODULE PH_Field_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Temperature_Desc
  PUBLIC :: PH_Temperature_Algo
  PUBLIC :: PH_Temperature_Arg
  PUBLIC :: PH_PorePressure_Desc
  PUBLIC :: PH_PorePressure_Algo
  PUBLIC :: PH_PorePressure_In
  PUBLIC :: PH_PorePressure_Out
  PUBLIC :: PH_Concentration_Desc
  PUBLIC :: PH_Concentration_Algo
  PUBLIC :: PH_Concentration_In
  PUBLIC :: PH_Concentration_Out

  ! --------------------------------------------------------------------------
  ! Desc — cold element field description, INTENT(IN)
  ! --------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Field_Desc
    INTEGER(i4) :: nn      = 0   ! number of element nodes
    INTEGER(i4) :: nip     = 0   ! number of integration points
    INTEGER(i4) :: ndim    = 3   ! spatial dimension
    INTEGER(i4) :: n_comp  = 1   ! number of field components
    INTEGER(i4) :: n_nodes = 0   ! total nodes for global averaging
  END TYPE PH_Field_Desc

  ! --------------------------------------------------------------------------
  ! Ctx — hot per-element / per-IP workspace, INTENT(INOUT)
  ! Fixed-size arrays are dimensioned for the largest supported element
  ! (27-node hex, 27 IPs, 6 Voigt components).
  ! --------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Field_Ctx
    REAL(wp) :: N_shape(27)       = 0.0_wp   ! shape function values
    REAL(wp) :: dN_dx(3,27)       = 0.0_wp   ! shape function derivatives
    REAL(wp) :: E_mat(27,27)      = 0.0_wp   ! extrapolation matrix
    REAL(wp) :: ip_vals(6,27)     = 0.0_wp   ! IP values (n_comp, nip)
    REAL(wp) :: nodal_vals(6,27)  = 0.0_wp   ! nodal values (n_comp, nn)
    REAL(wp) :: grad(3)           = 0.0_wp   ! gradient result
    REAL(wp) :: stress_voigt(6)   = 0.0_wp   ! stress for invariants
    REAL(wp) :: I1                = 0.0_wp   ! first invariant
    REAL(wp) :: J2                = 0.0_wp   ! second deviatoric invariant
    REAL(wp) :: J3                = 0.0_wp   ! third deviatoric invariant
    ! Global averaging buffers (allocated externally)
    REAL(wp),    POINTER :: nodal_sum(:,:)   => NULL()  ! (n_comp, n_nodes)
    INTEGER(i4), POINTER :: nodal_count(:)   => NULL()  ! (n_nodes)
    REAL(wp),    POINTER :: nodal_avg(:,:)   => NULL()  ! (n_comp, n_nodes)
  END TYPE PH_Field_Ctx

  ! --------------------------------------------------------------------------
  ! State — persistent field status across steps, INTENT(OUT) on init
  ! --------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Field_State
    LOGICAL     :: allocated    = .FALSE.
    LOGICAL     :: values_set   = .FALSE.
    INTEGER(i4) :: n_dof_active = 0
    INTEGER(i4) :: current_step = 0
    INTEGER(i4) :: current_incr = 0
  END TYPE PH_Field_State

  ! --------------------------------------------------------------------------
  ! Algo — field computation algorithm configuration (v4.0)
  ! --------------------------------------------------------------------------
  !> @brief Time integration configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Field_Cfg_Time
    INTEGER(i4) :: time_integration = 1_i4    ! 1=backward Euler, 2=Crank-Nicolson
    REAL(wp)    :: theta             = 1.0_wp  ! time integration parameter
    REAL(wp)    :: dt                = 0.0_wp  ! current time step
    LOGICAL     :: lumped_capacity   = .FALSE. ! lumped vs consistent capacity
  END TYPE PH_Field_Cfg_Time

  !> @brief Solver control configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Field_Cfg_Control
    INTEGER(i4) :: extrapolation     = 1_i4    ! 1=IP-to-node, 2=L2 projection
    INTEGER(i4) :: max_field_iter    = 1_i4    ! field sub-iterations
    REAL(wp)    :: field_tol         = 1.0E-6_wp ! convergence tolerance
  END TYPE PH_Field_Cfg_Control

  TYPE, PUBLIC :: PH_Field_Algo
    TYPE(PH_Field_Cfg_Time)    :: time
    TYPE(PH_Field_Cfg_Control) :: ctrl
    ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Field_Algo

  ! --------------------------------------------------------------------------
  ! Domain container — aggregates four-kind types for Field domain (v4.0)
  ! --------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Field_Domain
    TYPE(PH_Field_Desc)  :: desc
    TYPE(PH_Field_State) :: state
    TYPE(PH_Field_Algo)  :: algo
    TYPE(PH_Field_Ctx)   :: ctx
    INTEGER(i4) :: domain_id    = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE PH_Field_Domain

  ! --------------------------------------------------------------------------
  ! Physics-specific field bundles used by Field compute modules.
  ! These are L4 hot-path IO contracts; L3 owns only the model Desc truth.
  ! --------------------------------------------------------------------------
  TYPE :: PH_Temperature_Desc
    REAL(wp) :: thermal_conductivity = 0.0_wp
    REAL(wp) :: heat_capacity        = 1.0_wp
    REAL(wp) :: density              = 1.0_wp
    REAL(wp) :: heat_source          = 0.0_wp
  END TYPE PH_Temperature_Desc

  TYPE :: PH_Temperature_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_Temperature_Algo

  TYPE :: PH_Temperature_Arg
    REAL(wp), POINTER     :: t_n(:,:) => NULL() ! [IN]
    REAL(wp), ALLOCATABLE :: temperature(:,:)   ! [OUT]
    REAL(wp), ALLOCATABLE :: heat_flux(:,:)     ! [OUT]
  END TYPE PH_Temperature_Arg

  TYPE :: PH_PorePressure_Desc
    REAL(wp) :: permeability    = 0.0_wp
    REAL(wp) :: storativity     = 1.0_wp
    REAL(wp) :: fluid_density   = 1.0_wp
    REAL(wp) :: fluid_viscosity = 1.0_wp
  END TYPE PH_PorePressure_Desc

  TYPE :: PH_PorePressure_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_PorePressure_Algo

  TYPE :: PH_PorePressure_In
    REAL(wp), POINTER :: pressure(:,:) => NULL() ! [IN]
  END TYPE PH_PorePressure_In

  TYPE :: PH_PorePressure_Out
    REAL(wp), ALLOCATABLE :: pressure(:,:) ! [OUT]
    REAL(wp), ALLOCATABLE :: velocity(:,:) ! [OUT]
  END TYPE PH_PorePressure_Out

  TYPE :: PH_Concentration_Desc
    REAL(wp) :: diffusivity    = 0.0_wp
    REAL(wp) :: reaction_rate  = 0.0_wp
    REAL(wp) :: source_rate    = 0.0_wp
    LOGICAL  :: has_reaction   = .FALSE.
  END TYPE PH_Concentration_Desc

  TYPE :: PH_Concentration_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_Concentration_Algo

  TYPE :: PH_Concentration_In
    REAL(wp), POINTER :: concentration(:,:) => NULL() ! [IN]
  END TYPE PH_Concentration_In

  TYPE :: PH_Concentration_Out
    REAL(wp), ALLOCATABLE :: concentration(:,:) ! [OUT]
    REAL(wp), ALLOCATABLE :: flux(:,:)          ! [OUT]
  END TYPE PH_Concentration_Out

END MODULE PH_Field_Def
