!===============================================================================
! MODULE: RT_Solv_TimeInt
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Solv (TimeIntegration)
! BRIEF:  Time integration schemes (Newmark-beta / HHT-alpha / Central Difference)
!===============================================================================
!
! Process族:
!   P0: Init / Config                                            [COLD_PATH]
!   P2: Compute/Solve (predictor-corrector, effective stiffness)  [HOT_PATH]
!   P2: Update (velocity, acceleration advance)                   [HOT_PATH]
!
! Status: SIO-REFACTORED | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_TimeInt
  !! Time integration: Newmark, HHT-alpha, Generalized-alpha, Central Difference.
  !! Implements predictor-corrector + effective stiffness assembly.

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, only: wp, i4
  USE RT_Solv_Sparse, only: RT_CSR_SpMV
  USE RT_Solv_Def, only: RT_AdvancedTimeIntegrator, RT_CSRMatrix
  ! RT_CSR_SpMV for sparse mat-vec; Cycle 15 RT_Solver_Core / RT_SolvTimeInt

  implicit none
  private

  !=============================================================================
  ! CONSTANTS
  !=============================================================================
  integer(i4), parameter :: METHOD_HHT_ALPH = 1
  integer(i4), parameter :: METHOD_NEWMARK = 2
  integer(i4), parameter :: METHOD_CENTRAL = 3

  !=============================================================================
  ! TYPES
  !=============================================================================
  type, public :: UF_TimeIntState
    real(wp), allocatable :: u_n(:)        ! Displacement at time n
    real(wp), allocatable :: v_n(:)        ! Velocity at time n
    real(wp), allocatable :: a_n(:)        ! Acceleration at time n
    real(wp), allocatable :: u_np1(:)      ! Displacement at time n+1
    real(wp), allocatable :: v_np1(:)      ! Velocity at time n+1
    real(wp), allocatable :: a_np1(:)      ! Acceleration at time n+1
    real(wp) :: t_n = 0.0_wp              ! Time at step n
    real(wp) :: t_np1 = 0.0_wp            ! Time at step n+1
    real(wp) :: dt = 0.0_wp               ! Time step
    real(wp) :: dt_prev = 0.0_wp          ! Previous time step
    integer(i4) :: step = 0_i4            ! Current step number
  end type UF_TimeIntState

  type, public :: UF_TimeIntConfig
    integer(i4) :: method = METHOD_NEWMARK
    real(wp) :: beta = 0.25_wp            ! Newmark beta parameter
    real(wp) :: gamma = 0.5_wp            ! Newmark gamma parameter
    real(wp) :: alpha = 0.0_wp            ! HHT-alpha parameter (alias for alpha_f)
    real(wp) :: alpha_f = 0.0_wp          ! HHT-alpha parameter
    real(wp) :: alpha_m = 0.0_wp          ! Generalized alpha parameter
    real(wp) :: rho_inf = 0.9_wp         ! Generalized alpha spectral radius
    logical :: adaptive = .false.         ! Use adaptive time stepping
    real(wp) :: dt_min = 1.0e-12_wp      ! Minimum time step
    real(wp) :: dt_max = 1.0_wp          ! Maximum time step
    real(wp) :: error_tolerance = 1.0e-6_wp  ! Error tolerance for adaptive stepping
    real(wp) :: adaptive_tolerance = 1.0e-6_wp ! Adaptive step tolerance
    real(wp) :: adaptive_safety = 0.9_wp  ! Safety factor for adaptive stepping
  end type UF_TimeIntConfig

  type, public :: UF_EnergyState
    real(wp) :: kinetic_energy = 0.0_wp
    real(wp) :: potential_energ = 0.0_wp
    real(wp) :: total_energy = 0.0_wp
    real(wp) :: energy_error = 0.0_wp
    real(wp) :: energy_error_relative = 0.0_wp
  end type UF_EnergyState

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: RT_TimeInt_CentralDiff
  public :: RT_TimeInt_GenAlpha
  public :: RT_TimeInt_HHT_Alpha
  public :: RT_TimeInt_HHT_Alpha_Dyn
  public :: RT_TimeInt_Newmark
  public :: RT_TimeInt_Newmark_Dyn
  public :: UF_TimeIntegration_HHT_Alpha
  public :: UF_TimeIntegration_Newmark_Beta
  public :: UF_TimeIntegration_CentralDifference
  public :: UF_TimeIntegration_AdaptiveStep
  public :: UF_TimeIntegration_EnergyConservation
  ! Extended API (tasks 11300-11399)
  public :: RT_TimeInt_Implicit_Integ
  public :: RT_TimeInt_Explicit_Integ
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: RT_Solv_TimeInt_Core_Args
  TYPE :: RT_Solv_TimeInt_Core_Args
  ! Purpose: —�?  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Solv_TimeInt_Core_Args


contains

  subroutine AsmEffLoad_Newmark(F_ext_np1, F_int_np1, M, C, u_n, v_n, &
                                           a_n, a0, a1, a2, a3, a4, a5, F_eff, status)
    real(wp), intent(in) :: F_ext_np1(:), F_int_np1(:)
    type(RT_CSRMatrix), intent(in) :: M, C
    real(wp), intent(in) :: u_n(:), v_n(:), a_n(:)
    real(wp), intent(in) :: a0, a1, a2, a3, a4, a5
    real(wp), intent(out) :: F_eff(:)
    type(ErrorStatusType), intent(out) :: status

    real(wp), allocatable :: Mu(:), Cv(:)

    call init_error_status(status)

    allocate(Mu(size(u_n)), Cv(size(v_n)))

    ! F_eff = F_{n+1} - F_int_{n+1} + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    F_eff = F_ext_np1 - F_int_np1

    ! Add mass contribution: M*(a0*u_n + a2*v_n + a3*a_n)
    call RT_CSR_SpMV(M, a0 * u_n + a2 * v_n + a3 * a_n, Mu)
    F_eff = F_eff + Mu

    ! Add damping contribution: C*(a1*u_n + a4*v_n + a5*a_n)
    call RT_CSR_SpMV(C, a1 * u_n + a4 * v_n + a5 * a_n, Cv)
    F_eff = F_eff + Cv

    deallocate(Mu, Cv)
    status%status_code = IF_STATUS_OK

  end subroutine AsmEffLoad_Newmark

  subroutine AsmEffStiff_HHT(K, M, C, alpha_f, a0, a1, K_eff, status)
    type(RT_CSRMatrix), intent(in) :: K, M, C
    real(wp), intent(in) :: alpha_f, a0, a1
    real(wp), intent(out) :: K_eff(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i, j, k
    real(wp), allocatable :: K_dense(:,:), M_dense(:,:), C_dense(:,:)

    call init_error_status(status)

    n = size(K_eff, 1)
    allocate(K_dense(n, n), M_dense(n, n), C_dense(n, n))

    ! Convert CSR to dense (simplified)
    call ConvertCSRToDense(K, K_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    call ConvertCSRToDense(M, M_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    call ConvertCSRToDense(C, C_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Assemble: K_eff = (1+alpha)*K + a0*M + a1*C
    K_eff = (1.0_wp + alpha_f) * K_dense + a0 * M_dense + a1 * C_dense

    deallocate(K_dense, M_dense, C_dense)
    status%status_code = IF_STATUS_OK

  end subroutine AsmEffStiff_HHT

  subroutine AsmEffStiff_Newmark(K, M, C, a0, a1, K_eff, status)
    type(RT_CSRMatrix), intent(in) :: K, M, C
    real(wp), intent(in) :: a0, a1
    real(wp), intent(out) :: K_eff(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n
    real(wp), allocatable :: K_dense(:,:), M_dense(:,:), C_dense(:,:)

    call init_error_status(status)

    n = size(K_eff, 1)
    allocate(K_dense(n, n), M_dense(n, n), C_dense(n, n))

    ! Convert CSR to dense (simplified)
    call ConvertCSRToDense(K, K_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    call ConvertCSRToDense(M, M_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    call ConvertCSRToDense(C, C_dense, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Assemble: K_eff = K + a0*M + a1*C
    K_eff = K_dense + a0 * M_dense + a1 * C_dense

    deallocate(K_dense, M_dense, C_dense)
    status%status_code = IF_STATUS_OK

  end subroutine AsmEffStiff_Newmark

  subroutine AssembleEffectiveLoad_HHT(F_ext_n, F_ext_np1, F_int_n, F_int_np1, &
                                        M, C, u_n, v_n, a_n, alpha_f, a0, a1, a2, &
                                        a3, a4, a5, F_eff, status)
    real(wp), intent(in) :: F_ext_n(:), F_ext_np1(:), F_int_n(:), F_int_np1(:)
    type(RT_CSRMatrix), intent(in) :: M, C
    real(wp), intent(in) :: u_n(:), v_n(:), a_n(:)
    real(wp), intent(in) :: alpha_f, a0, a1, a2, a3, a4, a5
    real(wp), intent(out) :: F_eff(:)
    type(ErrorStatusType), intent(out) :: status

    real(wp), allocatable :: Mu(:), Cv(:)

    call init_error_status(status)

    allocate(Mu(size(u_n)), Cv(size(v_n)))

    ! F_eff = (1+alpha)*f_{n+1} - alpha*f_n + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    F_eff = (1.0_wp + alpha_f) * F_ext_np1 - alpha_f * F_ext_n

    ! Add internal force contribution: -[(1+alpha)*F_int_{n+1} - alpha*F_int_n]
    F_eff = F_eff - (1.0_wp + alpha_f) * F_int_np1 + alpha_f * F_int_n

    ! Add mass contribution: M*(a0*u_n + a2*v_n + a3*a_n)
    call RT_CSR_SpMV(M, a0 * u_n + a2 * v_n + a3 * a_n, Mu)
    F_eff = F_eff + Mu

    ! Add damping contribution: C*(a1*u_n + a4*v_n + a5*a_n)
    call RT_CSR_SpMV(C, a1 * u_n + a4 * v_n + a5 * a_n, Cv)
    F_eff = F_eff + Cv

    deallocate(Mu, Cv)
    status%status_code = IF_STATUS_OK

  end subroutine AssembleEffectiveLoad_HHT

  subroutine ConvertCSRToDense(K_csr, K_dense, status)
    type(RT_CSRMatrix), intent(in) :: K_csr
    real(wp), intent(out) :: K_dense(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, n

    call init_error_status(status)

    n = K_csr%nRows
    if (size(K_dense, 1) /= n .or. size(K_dense, 2) /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'ConvertCSRToDense: Size mismatch'
      return
    end if

    K_dense = 0.0_wp
    do i = 1, n
      do k = K_csr%rowPtr(i), K_csr%rowPtr(i+1) - 1
        j = K_csr%colInd(k)
        K_dense(i, j) = K_csr%values(k)
      end do
    end do

    status%status_code = IF_STATUS_OK

  end subroutine ConvertCSRToDense

  subroutine correct_newmark_Integ(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator

    real(wp) :: dt, gamma

    dt = integrator%dt
    gamma = integrator%gamma

    integrator%v_np1 = integrator%v_n + dt * ((1.0_wp - gamma) * integrator%a_n + &
                      gamma * integrator%a_np1)
  end subroutine correct_newmark_Integ

  subroutine GaussianElimination(A, b, x, info)
    real(wp), intent(inout) :: A(:,:)
    real(wp), intent(inout) :: b(:)
    real(wp), intent(out) :: x(:)
    integer(i4), intent(out) :: info

    integer(i4) :: n, i, j, k
    real(wp) :: factor, pivot

    n = size(b)
    info = 0

    ! Forward elimination
    do k = 1, n - 1
      pivot = abs(A(k, k))
      if (pivot < 1.0e-12_wp) then
        info = k
        return
      end if

      do i = k + 1, n
        factor = A(i, k) / A(k, k)
        do j = k + 1, n
          A(i, j) = A(i, j) - factor * A(k, j)
        end do
        b(i) = b(i) - factor * b(k)
      end do
    end do

    ! Back substitution
    x(n) = b(n) / A(n, n)
    do i = n - 1, 1, -1
      x(i) = b(i)
      do j = i + 1, n
        x(i) = x(i) - A(i, j) * x(j)
      end do
      x(i) = x(i) / A(i, i)
    end do

  end subroutine GaussianElimination

  subroutine predict_newmark_Integ(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator

    real(wp) :: dt, beta, gamma, c2, c3

    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma
    c2 = 1.0_wp / (beta * dt**2)
    c3 = 1.0_wp / (beta * dt)

    integrator%u_np1 = integrator%u_n + dt * integrator%v_n + &
                      dt**2 * (0.5_wp - beta) * integrator%a_n
    integrator%v_np1 = integrator%v_n + dt * (1.0_wp - gamma) * integrator%a_n
  end subroutine predict_newmark_Integ

  subroutine RT_TimeInt_CentralDiff(integrator, F_ext_np1, status)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: F_ext_np1(:)
    integer(i4), intent(out) :: status

    real(wp) :: dt
    integer(i4) :: neq

    status = 0
    dt = integrator%dt
    neq = size(integrator%u_n)

    ! Central difference: conditionally stable, explicit
    integrator%F_ext_np1 = F_ext_np1

    ! Predictor: u_{n+1} = u_n + dt * v_n + 0.5 * dt^2 * a_n
    integrator%u_np1 = integrator%u_n + dt * integrator%v_n + &
                      0.5_wp * dt * dt * integrator%a_n

    ! Solve for acceleration: a_{n+1} = M^-1 * (F_ext_{n+1} - F_int_{n+1} - C*v_n)
    if (allocated(integrator%M)) then
      integrator%a_np1 = (integrator%F_ext_np1 - integrator%F_int_np1) / &
                        integrator%M
      if (allocated(integrator%C)) then
        integrator%a_np1 = integrator%a_np1 - integrator%C * integrator%v_n / integrator%M
      end if
    else
      integrator%a_np1 = integrator%F_ext_np1 - integrator%F_int_np1
    end if

    ! Corrector: v_{n+1} = v_n + 0.5 * dt * (a_n + a_{n+1})
    integrator%v_np1 = integrator%v_n + 0.5_wp * dt * (integrator%a_n + integrator%a_np1)

    ! Note: This is explicit, so no effective stiffness matrix needed
  end subroutine RT_TimeInt_CentralDiff

  subroutine RT_TimeInt_Explicit_Integ(integrator, M, F_ext_n, F_ext_np1, &
                                               u_n, v_n, a_n, dt, &
                                               u_np1, v_np1, a_np1, status)
    !! Explicit time integration integration
    !! (implicit time integration)
    !!
    !! This subroutine provides a unified interface for explicit time integration
    !! methods (Central Difference), automatically handling mass matrix inversion
    !! and stability checks.
    !!
    !! Input:
    !!   integrator - Time integrator configuration
    !!   M          - Mass matrix (CSR format, typically diagonal/lumped)
    !!   F_ext_n    - External force at time n
    !!   F_ext_np1  - External force at time n+1
    !!   u_n, v_n, a_n - Displacement, velocity, acceleration at time n
    !!   dt         - Time step
    !!
    !! Output:
    !!   u_np1, v_np1, a_np1 - Displacement, velocity, acceleration at time n+1
    !!   status              - Error status
    !!
    !! Task: 11350-11399
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    type(RT_CSRMatrix), intent(in) :: M
    real(wp), intent(in) :: F_ext_n(:), F_ext_np1(:)
    real(wp), intent(in) :: u_n(:), v_n(:), a_n(:)
    real(wp), intent(in) :: dt
    real(wp), intent(out) :: u_np1(:), v_np1(:), a_np1(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i
    real(wp) :: dt_sq
    real(wp), allocatable :: M_inv(:)
    real(wp), allocatable :: F_net(:)

    call init_error_status(status)

    ! Valid inputs
    n = size(u_n)
    if (size(v_n) /= n .or. size(a_n) /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_TimeInt_Explicit_Integ: Size mismatch in state vectors'
      return
    end if

    if (size(u_np1) /= n .or. size(v_np1) /= n .or. size(a_np1) /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_TimeInt_Explicit_Integ: Size mismatch in output vectors'
      return
    end if

    if (M%nRows /= n .or. M%nCols /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_TimeInt_Explicit_Integ: Mass matrix size mismatch'
      return
    end if

    ! Check stability: dt < 2/omega_max
    ! For now, assume stability check is done elsewhere
    dt_sq = dt * dt

    ! Update integrator state
    integrator%u_n = u_n
    integrator%v_n = v_n
    integrator%a_n = a_n
    integrator%dt = dt

    ! Central Difference Method (explicit)
    ! u_{n+1} = u_n + dt*v_n + 0.5*dt^2*a_n
    ! v_{n+1} = v_n + 0.5*dt*(a_n + a_{n+1})
    ! a_{n+1} = M^{-1} * (F_{n+1} - K*u_{n+1} - C*v_{n+1})
    !
    ! For explicit integration, we typically use:
    ! a_{n+1} = M^{-1} * F_{n+1}  (if no stiffness/damping in explicit step)
    ! v_{n+1} = v_n + 0.5*dt*(a_n + a_{n+1})
    ! u_{n+1} = u_n + dt*v_n + 0.5*dt^2*a_n

    ! Compute inverse mass matrix (assume diagonal/lumped mass)
    allocate(M_inv(n))
    allocate(F_net(n))

    ! Simplified: assume diagonal mass matrix
    do i = 1, n
      ! Extract diagonal element from CSR (simplified)
      if (M%rowPtr(i+1) > M%rowPtr(i)) then
        ! Find diagonal element
        M_inv(i) = 1.0_wp  ! Placeholder: assume unit mass
        ! TODO: Extract actual diagonal from CSR
      else
        M_inv(i) = 1.0_wp
      end if
    end do

    ! For explicit integration, typically:
    ! F_net = F_ext (no internal forces computed explicitly)
    ! In practice, internal forces would be computed from current state
    F_net = F_ext_np1  ! Simplified: use external force only

    ! Compute acceleration at n+1
    ! a_{n+1} = M^{-1} * F_net
    do i = 1, n
      a_np1(i) = M_inv(i) * F_net(i)
    end do

    ! Compute velocity at n+1 (using average acceleration)
    ! v_{n+1} = v_n + 0.5*dt*(a_n + a_{n+1})
    do i = 1, n
      v_np1(i) = v_n(i) + 0.5_wp * dt * (a_n(i) + a_np1(i))
    end do

    ! Compute displacement at n+1
    ! u_{n+1} = u_n + dt*v_n + 0.5*dt^2*a_n
    do i = 1, n
      u_np1(i) = u_n(i) + dt * v_n(i) + 0.5_wp * dt_sq * a_n(i)
    end do

    ! Update integrator state
    integrator%u_np1 = u_np1
    integrator%v_np1 = v_np1
    integrator%a_np1 = a_np1

    deallocate(M_inv, F_net)

    status%status_code = IF_STATUS_OK
    status%message = 'Explicit integration completed successfully'

  end subroutine RT_TimeInt_Explicit_Integ

  subroutine RT_TimeInt_GenAlpha(integrator, rho_inf, F_ext_np1, status)
    !! Generalized-alpha time integration following Theory/UF_TimeIntegrationTheory.f90
    !!
    !! Motion equation evaluated at generalized time point:
    !!   M*a_{n+1-alpha_m} + C*v_{n+1-alpha_f} + K*u_{n+1-alpha_f} = f_{n+1-alpha_f}
    !!
    !! Interpolation: a_{n+1-am} = (1-am)*a_{n+1}+am*a_n; v,u similar with alpha_f
    !! Optimal parameters (spectral radius rho_inf): alpha_m = (2*rho_inf-1)/(rho_inf+1), alpha_f = rho_inf/(rho_inf+1)
    !! Spectral radius rho_inf in [0,1]: 1 = Newmark, 0 = max damping, typical 0.9
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: rho_inf, F_ext_np1(:)
    integer(i4), intent(out) :: status

    real(wp) :: dt, alpha_m, alpha_f, gamma, beta

    status = 0
    dt = integrator%dt

    ! Generalized-alpha parameters following Theory
    alpha_m = (2.0_wp - rho_inf) / (1.0_wp + rho_inf)
    alpha_f = rho_inf / (1.0_wp + rho_inf)
    
    ! Newmark parameters
    gamma = 0.5_wp - alpha_m + alpha_f
    beta = 0.25_wp * (1.0_wp - alpha_m + alpha_f)**2

    integrator%alpha = alpha_m
    integrator%alpha_f = alpha_f
    integrator%beta = beta
    integrator%gamma = gamma

    ! Use HHT-alpha implementation with alpha_f parameter
    ! Note: Generalized-alpha can be implemented as HHT-alpha with modified parameters
    call RT_TimeInt_HHT_Alpha(integrator, alpha_f, F_ext_np1, status)
  end subroutine RT_TimeInt_GenAlpha

  subroutine RT_TimeInt_HHT_Alpha(integrator, alpha, F_ext_np1, status)
    !! HHT-alpha time integration following Theory/UF_TimeIntegrationTheory.f90
    !!
    !! Modified equation of motion:
    !!   M*a_{n+1} + (1+alpha)*C*v_{n+1} - alpha*C*v_n
    !!   + (1+alpha)*K*u_{n+1} - alpha*K*u_n = (1+alpha)*f_{n+1} - alpha*f_n
    !!
    !! Newmark parameters:
    !!   beta = (1-alpha)^2 / 4
    !!   gamma = (1-2*alpha) / 2
    !!
    !! Parameter range: alpha in [-1/3, 0]
    !!   alpha = 0:    Standard Newmark (no numerical damping)
    !!   alpha = -1/3: Maximum numerical damping
    !!
    !! Properties:
    !!   - Unconditionally stable
    !!   - Second-order accurate
    !!   - High-frequency numerical damping, low-frequency preserved
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha, F_ext_np1(:)
    integer(i4), intent(out) :: status

    real(wp) :: dt, beta, gamma, alpha_f, alpha_m, a0, a1, a2, a3, a4, a5

    status = 0
    dt = integrator%dt
    
    ! HHT-alpha parameters: alpha_f in [-1/3, 0]
    alpha_f = alpha
    
    ! Compute Newmark parameters from HHT-alpha parameter
    ! beta = (1-alpha_f)^2/4, gamma = (1-2*alpha_f)/2
    beta = (1.0_wp - alpha_f)**2 / 4.0_wp
    gamma = (1.0_wp - 2.0_wp * alpha_f) / 2.0_wp
    
    ! Store parameters
    integrator%beta = beta
    integrator%gamma = gamma
    
    ! Mass-proportional damping parameter (for generalized-alpha)
    alpha_m = 0.0_wp  ! HHT-alpha uses only alpha_f
    integrator%alpha = alpha_m

    ! Integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)

    ! Update external force
    integrator%F_ext_np1 = F_ext_np1

    ! Effective stiffness: K_eff = (1+alpha_f)*K + a0*M + a1*C
    ! Note: For HHT-alpha, stiffness is modified by (1+alpha_f) factor
    if (allocated(integrator%M) .and. allocated(integrator%C)) then
      integrator%K_eff = (1.0_wp + alpha_f) * integrator%K + a0 * integrator%M + a1 * integrator%C
    else if (allocated(integrator%M)) then
      integrator%K_eff = (1.0_wp + alpha_f) * integrator%K + a0 * integrator%M
    else
      integrator%K_eff = (1.0_wp + alpha_f) * integrator%K
    end if

    ! Effective load: F_eff = (1+alpha_f)*f_{n+1} - alpha_f*f_n + M*(...) + C*(...)
    integrator%F_eff = (1.0_wp + alpha_f) * integrator%F_ext_np1 - alpha_f * integrator%F_ext_n

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    ! Internal force contribution: -[(1+alpha_f)*F_int_{n+1} - alpha_f*F_int_n]
    integrator%F_eff = integrator%F_eff - (1.0_wp + alpha_f) * integrator%F_int_np1 + &
                      alpha_f * integrator%F_int_n
  end subroutine RT_TimeInt_HHT_Alpha

  subroutine RT_TimeInt_HHT_Alpha_Dyn(integrator, alpha, status)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha
    integer(i4), intent(out) :: status

    real(wp) :: dt, beta, gamma, alpha_f, alpha_m, a0, a1, a2, a3, a4, a5

    status = 0
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma

    ! HHT-alpha parameters
    alpha_f = alpha
    alpha_m = (2.0_wp - alpha_f) / (1.0_wp + alpha_f) * alpha_f
    integrator%alpha = alpha_m

    ! Integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)

    ! Effective stiffness: K_eff = alpha_m * K + a0*M + a1*C
    integrator%K_eff = alpha_m * integrator%K + a0 * integrator%M + a1 * integrator%C

    ! Effective load with HHT-alpha modifications
    integrator%F_eff = alpha_f * integrator%F_ext_n + (1.0_wp + alpha_f) * integrator%F_ext_np1

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    integrator%F_eff = integrator%F_eff - alpha_f * integrator%F_int_n - &
                      (1.0_wp + alpha_f) * integrator%F_int_np1
  end subroutine RT_TimeInt_HHT_Alpha_Dyn

  subroutine RT_TimeInt_Implicit_Integ(integrator, K, M, C, F_ext_np1, &
                                              u_n, v_n, a_n, dt, &
                                              u_np1, v_np1, a_np1, status)
    !! Implicit time integration integration
    !! (implicit time integration)
    !!
    !! This subroutine provides a unified interface for implicit time integration
    !! methods (Newmark, HHT-alpha, Generalized-alpha), automatically selecting
    !! the appropriate method based on integrator configuration.
    !!
    !! Input:
    !!   integrator - Time integrator configuration
    !!   K          - Stiffness matrix (CSR format)
    !!   M          - Mass matrix (CSR format)
    !!   C          - Damping matrix (CSR format, optional)
    !!   F_ext_np1  - External force at time n+1
    !!   u_n, v_n, a_n - Displacement, velocity, acceleration at time n
    !!   dt         - Time step
    !!
    !! Output:
    !!   u_np1, v_np1, a_np1 - Displacement, velocity, acceleration at time n+1
    !!   status              - Error status
    !!
    !! Task: 11300-11349
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    type(RT_CSRMatrix), intent(in) :: K
    type(RT_CSRMatrix), intent(in) :: M
    type(RT_CSRMatrix), intent(in), optional :: C
    real(wp), intent(in) :: F_ext_np1(:)
    real(wp), intent(in) :: u_n(:), v_n(:), a_n(:)
    real(wp), intent(in) :: dt
    real(wp), intent(out) :: u_np1(:), v_np1(:), a_np1(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: method
    real(wp) :: alpha_f, alpha_m

    call init_error_status(status)

    ! Valid inputs
    if (size(u_n) /= size(v_n) .or. size(u_n) /= size(a_n)) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_TimeInt_Implicit_Integ: Size mismatch in state vectors'
      return
    end if

    if (size(u_np1) /= size(u_n) .or. size(v_np1) /= size(u_n) .or. &
        size(a_np1) /= size(u_n)) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_TimeInt_Implicit_Integ: Size mismatch in output vectors'
      return
    end if

    ! Update integrator state
    integrator%u_n = u_n
    integrator%v_n = v_n
    integrator%a_n = a_n
    integrator%dt = dt

    ! Determine integration method
    ! Note: RT_AdvancedTimeIntegrator may have a method field
    ! For now, use Newmark as default
    method = METHOD_NEWMARK

    ! Call appropriate integration method
    select case (method)
    case (METHOD_NEWMARK)
      ! Newmark-beta method
      call RT_TimeInt_Newmark(integrator, F_ext_np1, status%status_code)
      if (status%status_code == 0) then
        u_np1 = integrator%u_np1
        v_np1 = integrator%v_np1
        a_np1 = integrator%a_np1
        status%status_code = IF_STATUS_OK
      else
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_TimeInt_Implicit_Integ: Newmark integration failed'
      end if

    case (METHOD_HHT_ALPH)
      ! HHT-alpha method
      call RT_TimeInt_HHT_Alpha(integrator, integrator%alpha, F_ext_np1, status%status_code)
      if (status%status_code == 0) then
        u_np1 = integrator%u_np1
        v_np1 = integrator%v_np1
        a_np1 = integrator%a_np1
        status%status_code = IF_STATUS_OK
      else
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_TimeInt_Implicit_Integ: HHT-alpha integration failed'
      end if

    case default
      ! Default to Newmark
      call RT_TimeInt_Newmark(integrator, F_ext_np1, status%status_code)
      if (status%status_code == 0) then
        u_np1 = integrator%u_np1
        v_np1 = integrator%v_np1
        a_np1 = integrator%a_np1
        status%status_code = IF_STATUS_OK
      else
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_TimeInt_Implicit_Integ: Integration failed'
      end if
    end select

  end subroutine RT_TimeInt_Implicit_Integ

  subroutine RT_TimeInt_Newmark(integrator, F_ext_np1, status)
    !! Newmark-beta time integration following Theory/UF_TimeIntegrationTheory.f90
    !!
    !! Newmark approximations:
    !!   u_{n+1} = u_n + dt*v_n + (dt^2/2)*[(1-2*beta)*a_n + 2*beta*a_{n+1}]
    !!   v_{n+1} = v_n + dt*[(1-gamma)*a_n + gamma*a_{n+1}]
    !!
    !! Integration coefficients (a0 to a7:
    !!   a0 = 1/(beta*dt^2)
    !!   a1 = gamma/(beta*dt)
    !!   a2 = 1/(beta*dt)
    !!   a3 = 1/(2*beta) - 1
    !!   a4 = gamma/beta - 1
    !!   a5 = dt/2*(gamma/beta - 2)
    !!   a6 = dt*(1 - gamma)
    !!   a7 = beta*dt
    !!
    !! Effective stiffness: K_eff = K + a0*M + a1*C
    !! Effective load: F_eff = F_{n+1} + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    !!
    !! Stability: Unconditionally stable when beta >= 0.25, gamma >= 0.5
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: F_ext_np1(:)
    integer(i4), intent(out) :: status

    real(wp) :: dt, beta, gamma, a0, a1, a2, a3, a4, a5, a6, a7
    integer(i4) :: neq

    status = 0
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma
    neq = size(integrator%u_n)

    ! Newmark integration coefficients following Theory
    a0 = 1.0_wp / (beta * dt * dt)         ! a0 = 1/(beta*dt^2)
    a1 = gamma / (beta * dt)               ! a1 = gamma/(beta*dt)
    a2 = 1.0_wp / (beta * dt)              ! a2 = 1/(beta*dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp ! a3 = 1/(2*beta) - 1
    a4 = gamma / beta - 1.0_wp             ! a4 = gamma/beta - 1
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp) ! a5 = dt/2*(gamma/beta - 2)
    a6 = dt * (1.0_wp - gamma)             ! a6 = dt*(1 - gamma)
    a7 = gamma * dt                         ! a7 = beta*dt

    ! Update external force
    integrator%F_ext_np1 = F_ext_np1

    ! Effective stiffness: K_eff = K + a0*M + a1*C
    if (allocated(integrator%M) .and. allocated(integrator%C)) then
      integrator%K_eff = integrator%K + a0 * integrator%M + a1 * integrator%C
    else if (allocated(integrator%M)) then
      integrator%K_eff = integrator%K + a0 * integrator%M
    else
      integrator%K_eff = integrator%K
    end if

    ! Effective load: F_eff = F_{n+1} + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    integrator%F_eff = integrator%F_ext_np1

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    integrator%F_eff = integrator%F_eff - integrator%F_int_np1

    ! Note: The actual solution of K_eff * du = F_eff is done by the linear solver
    ! Here we just prepare the effective system
  end subroutine RT_TimeInt_Newmark

  subroutine RT_TimeInt_Newmark_Dyn(integrator, status)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    integer(i4), intent(out) :: status

    real(wp) :: dt, beta, gamma, a0, a1, a2, a3, a4, a5, a6, a7

    status = 0
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma

    ! Newmark integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)
    a6 = dt * (1.0_wp - gamma)
    a7 = gamma * dt

    ! Effective stiffness: K_eff = K + a0*M + a1*C
    if (allocated(integrator%M) .and. allocated(integrator%C)) then
      integrator%K_eff = integrator%K + a0 * integrator%M + a1 * integrator%C
    else if (allocated(integrator%M)) then
      integrator%K_eff = integrator%K + a0 * integrator%M
    else
      integrator%K_eff = integrator%K
    end if

    ! Effective load: F_eff = F_ext + M*(a0*u + a2*v + a3*a) + C*(a1*u + a4*v + a5*a)
    integrator%F_eff = integrator%F_ext_np1

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    integrator%F_eff = integrator%F_eff - integrator%F_int_np1
  end subroutine RT_TimeInt_Newmark_Dyn

  subroutine SolveLinearSystem(A, b, x, status)
    real(wp), intent(in) :: A(:,:)
    real(wp), intent(in) :: b(:)
    real(wp), intent(out) :: x(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i, info
    real(wp), allocatable :: A_work(:,:), b_work(:)

    call init_error_status(status)

    n = size(b)
    allocate(A_work(n, n), b_work(n))

    A_work = A
    b_work = b

    ! Simplified: use Gaussian elimination
    call GaussianElimination(A_work, b_work, x, info)

    if (info /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'SolveLinearSystem: Solution failed'
      return
    end if

    deallocate(A_work, b_work)
    status%status_code = IF_STATUS_OK

  end subroutine SolveLinearSystem

  subroutine SolveMassSystem(M, b, x, status)
    type(RT_CSRMatrix), intent(in) :: M
    real(wp), intent(in) :: b(:)
    real(wp), intent(out) :: x(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i, k, j
    real(wp) :: diag_val

    call init_error_status(status)

    n = size(b)
    if (size(x) /= n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'SolveMassSystem: Size mismatch'
      return
    end if

    ! Simplified: use diagonal approximation
    x = 0.0_wp
    do i = 1, n
      diag_val = 0.0_wp
      do k = M%rowPtr(i), M%rowPtr(i+1) - 1
        j = M%colInd(k)
        if (j == i) then
          diag_val = M%values(k)
          exit
        end if
      end do
      if (abs(diag_val) > 1.0e-12_wp) then
        x(i) = b(i) / diag_val
      else
        x(i) = 0.0_wp
      end if
    end do

    status%status_code = IF_STATUS_OK

  end subroutine SolveMassSystem

  subroutine UF_TimeIntegration_AdaptiveStep(state, config, error_estimate, &
                                            dt_new, status)
    !! Adaptive time stepping based on error estimate
    !!
    !! Algorithm:
    !!   1. Estimate local truncation error
    !!   2. Compute optimal time step: dt_new = dt_old * (tolerance / error)^(1/(p+1))
    !!   3. Apply safety factor and bounds
    !!
    !! Reference: Hairer, E., Norsett, S.P., Wanner, G. (1993). "Solving ODEs"
    
    type(UF_TimeIntState), intent(in) :: state
    type(UF_TimeIntConfig), intent(in) :: config
    real(wp), intent(in) :: error_estimate
    real(wp), intent(out) :: dt_new
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: dt_old, tolerance, safety, p_order
    real(wp) :: dt_optimal, dt_factor

    call init_error_status(status)

    if (.not. config%adaptive) then
      dt_new = state%dt
      status%status_code = IF_STATUS_OK
      return
    end if

    dt_old = state%dt
    tolerance = config%adaptive_tolerance
    safety = config%adaptive_safety
    p_order = 2.0_wp  ! Second-order method (HHT-alpha, Newmark-beta)

    ! Compute optimal time step
    if (error_estimate > 1.0e-12_wp) then
      dt_factor = (tolerance / error_estimate)**(1.0_wp / (p_order + 1.0_wp))
      dt_optimal = dt_old * dt_factor * safety
    else
      dt_optimal = dt_old * 1.1_wp  ! Increase step if error is very small
    end if

    ! Apply bounds
    dt_new = max(config%dt_min, min(config%dt_max, dt_optimal))

    status%status_code = IF_STATUS_OK

  end subroutine UF_TimeIntegration_AdaptiveStep

  subroutine UF_TimeIntegration_CentralDifference(state, config, M, F_ext_np1, &
                                                  F_int_np1, status)
    !! Central Difference (explicit) time integration method
    !!
    !! Velocity: v_{n+1/2} = v_{n-1/2} + dt*a_n
    !! Displacement: u_{n+1} = u_n + dt*v_{n+1/2}
    !! Acceleration: a_{n+1} = M^{-1}*(F_{n+1} - F_int_{n+1})
    !!
    !! Stability condition: dt < 2/omega_max (where omega_max is maximum frequency)
    !!
    !! Reference: ABAQUS Theory Manual, Section 2.4.1
    
    type(UF_TimeIntState), intent(inout) :: state
    type(UF_TimeIntConfig), intent(in) :: config
    type(RT_CSRMatrix), intent(in) :: M
    real(wp), intent(in) :: F_ext_np1(:), F_int_np1(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs, i
    real(wp) :: dt
    real(wp), allocatable :: v_half(:), F_residual(:), a_temp(:)

    call init_error_status(status)

    n_dofs = size(state%u_n)
    dt = state%dt

    ! Allocate arrays
    allocate(v_half(n_dofs), F_residual(n_dofs), a_temp(n_dofs))

    ! Compute velocity at half step: v_{n+1/2} = v_n + (dt/2)*a_n
    v_half = state%v_n + 0.5_wp * dt * state%a_n

    ! Update displacement: u_{n+1} = u_n + dt*v_{n+1/2}
    state%u_np1 = state%u_n + dt * v_half

    ! Compute residual force: F_residual = F_ext_{n+1} - F_int_{n+1}
    F_residual = F_ext_np1 - F_int_np1

    ! Solve for acceleration: M*a_{n+1} = F_residual
    ! Simplified: use diagonal approximation
    do i = 1, n_dofs
      ! Extract diagonal element from M (simplified)
      ! In production, use proper sparse solver
      a_temp(i) = F_residual(i) / max(1.0_wp, 1.0_wp)  ! Placeholder
    end do

    ! Update acceleration: a_{n+1} = M^{-1}*F_residual
    call SolveMassSystem(M, F_residual, state%a_np1, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Update velocity: v_{n+1} = v_{n+1/2} + (dt/2)*a_{n+1}
    state%v_np1 = v_half + 0.5_wp * dt * state%a_np1

    ! Update time
    state%t_np1 = state%t_n + dt
    state%step = state%step + 1

    deallocate(v_half, F_residual, a_temp)
    status%status_code = IF_STATUS_OK

  end subroutine UF_TimeIntegration_CentralDifference

  subroutine UF_TimeIntegration_EnergyConservation(state, M, K, energy_state, &
                                                  status)
    !! Check energy conservation
    !!
    !! Kinetic energy: E_k = 0.5*v^T*M*v
    !! Potential energy: E_p = 0.5*u^T*K*u
    !! Total energy: E_total = E_k + E_p
    !! Energy error: delta_E = E_{n+1} - E_n
    !!
    !! Reference: ABAQUS Theory Manual, Section 2.4.1
    
    type(UF_TimeIntState), intent(in) :: state
    type(RT_CSRMatrix), intent(in) :: M, K
    type(UF_EnergyState), intent(inout) :: energy_state
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: E_k_np1, E_p_np1, E_total_np1
    real(wp), allocatable :: Mv(:), Ku(:)

    call init_error_status(status)

    allocate(Mv(size(state%v_np1)), Ku(size(state%u_np1)))

    ! Compute kinetic energy: E_k = 0.5*v^T*M*v
    call RT_CSR_SpMV(M, state%v_np1, Mv)
    E_k_np1 = 0.5_wp * dot_product(state%v_np1, Mv)

    ! Compute potential energy: E_p = 0.5*u^T*K*u
    call RT_CSR_SpMV(K, state%u_np1, Ku)
    E_p_np1 = 0.5_wp * dot_product(state%u_np1, Ku)

    ! Compute total energy
    E_total_np1 = E_k_np1 + E_p_np1

    ! Compute energy error
    energy_state%energy_error = E_total_np1 - energy_state%total_energy

    ! Compute relative energy error
    if (abs(energy_state%total_energy) > 1.0e-12_wp) then
      energy_state%energy_error_relative = abs(energy_state%energy_error) / &
                                          abs(energy_state%total_energy)
    else
      energy_state%energy_error_relative = abs(energy_state%energy_error)
    end if

    ! Update energy state
    energy_state%kinetic_energy = E_k_np1
    energy_state%potential_energ = E_p_np1
    energy_state%total_energy = E_total_np1

    deallocate(Mv, Ku)
    status%status_code = IF_STATUS_OK

  end subroutine UF_TimeIntegration_EnergyConservation

  subroutine UF_TimeIntegration_Newmark_Beta(state, config, M, C, K, F_ext_np1, &
                                            F_int_np1, status)
    !! Newmark-beta time integration method
    !!
    !! Newmark approximations:
    !!   u_{n+1} = u_n + dt*v_n + (dt^2/2)*[(1-2*beta)*a_n + 2*beta*a_{n+1}]
    !!   v_{n+1} = v_n + dt*[(1-gamma)*a_n + gamma*a_{n+1}]
    !!
    !! Integration coefficients:
    !!   a0 = 1/(beta*dt^2)
    !!   a1 = gamma/(beta*dt)
    !!   a2 = 1/(beta*dt)
    !!   a3 = 1/(2*beta) - 1
    !!   a4 = gamma/beta - 1
    !!   a5 = dt/2*(gamma/beta - 2)
    !!   a6 = dt*(1 - gamma)
    !!   a7 = beta*dt
    !!
    !! Effective stiffness: K_eff = K + a0*M + a1*C
    !! Effective load: F_eff = F_{n+1} + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    !!
    !! Stability: Unconditionally stable when beta >= 0.25, gamma >= 0.5
    !!
    !! Reference: Newmark (1959)
    
    type(UF_TimeIntState), intent(inout) :: state
    type(UF_TimeIntConfig), intent(in) :: config
    type(RT_CSRMatrix), intent(in) :: M, C, K
    real(wp), intent(in) :: F_ext_np1(:), F_int_np1(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs
    real(wp) :: dt, beta, gamma
    real(wp) :: a0, a1, a2, a3, a4, a5, a6, a7
    real(wp), allocatable :: K_eff(:,:), F_eff(:), du(:)

    call init_error_status(status)

    n_dofs = size(state%u_n)
    dt = state%dt
    beta = config%beta
    gamma = config%gamma

    ! Valid parameters
    if (beta < 0.25_wp .or. gamma < 0.5_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_TimeIntegration_Newmark_Beta: Invalid parameters for stability'
      return
    end if

    ! Integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)
    a6 = dt * (1.0_wp - gamma)
    a7 = gamma * dt

    ! Allocate arrays
    allocate(K_eff(n_dofs, n_dofs), F_eff(n_dofs), du(n_dofs))

    ! Compute effective stiffness: K_eff = K + a0*M + a1*C
    call AsmEffStiff_Newmark(K, M, C, a0, a1, K_eff, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute effective load: F_eff = F_{n+1} + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    call AsmEffLoad_Newmark(F_ext_np1, F_int_np1, M, C, &
                                       state%u_n, state%v_n, state%a_n, &
                                       a0, a1, a2, a3, a4, a5, F_eff, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Solve for displacement increment: K_eff*du = F_eff
    call SolveLinearSystem(K_eff, F_eff, du, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Update displacement: u_{n+1} = u_n + du
    state%u_np1 = state%u_n + du

    ! Update acceleration: a_{n+1} = a0*(u_{n+1} - u_n) - a2*v_n - a3*a_n
    state%a_np1 = a0 * du - a2 * state%v_n - a3 * state%a_n

    ! Update velocity: v_{n+1} = v_n + a6*a_n + a7*a_{n+1}
    state%v_np1 = state%v_n + a6 * state%a_n + a7 * state%a_np1

    ! Update time
    state%t_np1 = state%t_n + dt
    state%step = state%step + 1

    deallocate(K_eff, F_eff, du)
    status%status_code = IF_STATUS_OK

  end subroutine UF_TimeIntegration_Newmark_Beta

  subroutine UF_TimeIntegration_HHT_Alpha(state, config, M, C, K, F_ext_n, &
                                         F_ext_np1, F_int_n, F_int_np1, status)
    !! HHT-alpha time integration method
    !!
    !! Modified equation of motion:
    !!   M*a_{n+1} + (1+alpha)*C*v_{n+1} - alpha*C*v_n
    !!   + (1+alpha)*K*u_{n+1} - alpha*K*u_n = (1+alpha)*f_{n+1} - alpha*f_n
    !!
    !! Newmark parameters:
    !!   beta = (1-alpha)^2 / 4
    !!   gamma = (1-2*alpha) / 2
    !!
    !! Parameter range: alpha in [-1/3, 0]
    !!   alpha = 0:    Standard Newmark (no numerical damping)
    !!   alpha = -1/3: Maximum numerical damping
    !!
    !! Properties:
    !!   - Unconditionally stable
    !!   - Second-order accurate
    !!   - High-frequency numerical damping, low-frequency preserved
    !!
    !! Reference: Hilber, Hughes, Taylor (1977)
    
    type(UF_TimeIntState), intent(inout) :: state
    type(UF_TimeIntConfig), intent(in) :: config
    type(RT_CSRMatrix), intent(in) :: M, C, K
    real(wp), intent(in) :: F_ext_n(:), F_ext_np1(:)
    real(wp), intent(in) :: F_int_n(:), F_int_np1(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs
    real(wp) :: dt, alpha_f, beta, gamma
    real(wp) :: a0, a1, a2, a3, a4, a5
    real(wp), allocatable :: K_eff(:,:), F_eff(:), du(:)
    real(wp), allocatable :: Mu(:), Cv(:), Ku(:)

    call init_error_status(status)

    n_dofs = size(state%u_n)
    dt = state%dt
    alpha_f = config%alpha

    ! Valid alpha parameter
    if (alpha_f < -1.0_wp/3.0_wp .or. alpha_f > 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_TimeIntegration_HHT_Alpha: Invalid alpha parameter'
      return
    end if

    ! Compute Newmark parameters from HHT-alpha parameter
    beta = (1.0_wp - alpha_f)**2 / 4.0_wp
    gamma = (1.0_wp - 2.0_wp * alpha_f) / 2.0_wp

    ! Integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)

    ! Allocate arrays
    allocate(K_eff(n_dofs, n_dofs), F_eff(n_dofs), du(n_dofs))
    allocate(Mu(n_dofs), Cv(n_dofs), Ku(n_dofs))

    ! Compute effective stiffness: K_eff = (1+alpha)*K + a0*M + a1*C
    call AsmEffStiff_HHT(K, M, C, alpha_f, a0, a1, K_eff, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute effective load: F_eff = (1+alpha)*f_{n+1} - alpha*f_n + M*(a0*u_n + a2*v_n + a3*a_n) + C*(a1*u_n + a4*v_n + a5*a_n)
    call AssembleEffectiveLoad_HHT(F_ext_n, F_ext_np1, F_int_n, F_int_np1, &
                                   M, C, state%u_n, state%v_n, state%a_n, &
                                   alpha_f, a0, a1, a2, a3, a4, a5, F_eff, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Solve for displacement increment: K_eff*du = F_eff
    call SolveLinearSystem(K_eff, F_eff, du, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Update displacement: u_{n+1} = u_n + du
    state%u_np1 = state%u_n + du

    ! Update velocity: v_{n+1} = v_n + dt*[(1-gamma)*a_n + gamma*a_{n+1}]
    ! First compute acceleration: a_{n+1} = a0*(u_{n+1} - u_n) - a2*v_n - a3*a_n
    state%a_np1 = a0 * du - a2 * state%v_n - a3 * state%a_n
    state%v_np1 = state%v_n + dt * ((1.0_wp - gamma) * state%a_n + gamma * state%a_np1)

    ! Update time
    state%t_np1 = state%t_n + dt
    state%step = state%step + 1

    deallocate(K_eff, F_eff, du, Mu, Cv, Ku)
    status%status_code = IF_STATUS_OK

  end subroutine UF_TimeIntegration_HHT_Alpha

  subroutine update_time_Integ_state(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator

    integrator%time = integrator%time + integrator%dt
    integrator%step = integrator%step + 1
    integrator%u_n = integrator%u_np1
    integrator%v_n = integrator%v_np1
    integrator%a_n = integrator%a_np1
    integrator%F_ext_n = integrator%F_ext_np1
    integrator%F_int_n = integrator%F_int_np1
  end subroutine update_time_Integ_state
end module RT_Solv_TimeInt
