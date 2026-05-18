!===============================================================================
! MODULE: PH_ThermalCont_Def
! LAYER:  L4_PH
! DOMAIN: Contact / Thermal
! ROLE:   Def
! BRIEF:  Thermal contact four-type (Desc/State/Algo/Ctx) + conductance/friction models
!
! Four-Type: PH_Thermal_Cont_Desc, PH_Thermal_Cont_State,
!            PH_Thermal_Cont_Algo, PH_Thermal_Cont_Ctx
! Constants: PH_THERM_CONT_COND_*, PH_FRICTION_TEMP_*
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================

MODULE PH_ThermalCont_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Thermal_Cont_Desc
  PUBLIC :: PH_Thermal_Cont_State
  PUBLIC :: PH_Thermal_Cont_Algo
  PUBLIC :: PH_Thermal_Cont_Ctx
  
  !-- Thermal contact enums
  INTEGER(i4), PARAMETER, PUBLIC :: PH_THERM_CONT_COND_GAP = 1_i4      ! Gap-dependent
  INTEGER(i4), PARAMETER, PUBLIC :: PH_THERM_CONT_COND_CONST = 2_i4    ! Constant
  INTEGER(i4), PARAMETER, PUBLIC :: PH_THERM_CONT_COND_USER = 3_i4     ! User-defined
  
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_TEMP_LINEAR = 1_i4     ! Linear decay
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_TEMP_TABLE = 2_i4      ! Table lookup
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_TEMP_EXPONENTIAL = 3_i4 ! Exponential
  
  !===========================================================================
  !> @brief Thermal contact description (cold path, read-only)
  !! Stores thermal contact configuration and parameters
  !===========================================================================
  TYPE, PUBLIC :: PH_Thermal_Cont_Desc
    !-- Thermal contact flag
    LOGICAL :: thermal_contact_enabled = .FALSE.   ! Enable thermal coupling
    
    !-- Thermal contact conductance model
    INTEGER(i4) :: conductance_model = PH_THERM_CONT_COND_GAP
    
    !-- Conductance parameters
    REAL(wp) :: conductance_constant = 1000.0_wp   ! Constant conductance (W/m²·K)
    REAL(wp) :: conductance_gap_ref = 1.0e-6_wp    ! Reference gap (m)
    REAL(wp) :: conductance_exponent = 2.0_wp      ! Gap exponent
    
    !-- Gap conductance table (for table lookup)
    INTEGER(i4) :: n_table_points = 0_i4
    REAL(wp), ALLOCATABLE :: table_gaps(:)         ! Gap values
    REAL(wp), ALLOCATABLE :: table_conductance(:)  ! Conductance values
    
    !-- Friction heat generation
    LOGICAL :: friction_heat_enabled = .TRUE.      ! Enable frictional heating
    REAL(wp) :: heat_partition_coef = 0.5_wp       ! Heat partition to master (0~1)
    
    !-- Temperature-dependent friction
    INTEGER(i4) :: friction_temp_model = PH_FRICTION_TEMP_LINEAR
    REAL(wp) :: friction_ref_temp = 300.0_wp       ! Reference temperature (K)
    REAL(wp) :: friction_temp_coef = -0.001_wp     ! Temp coefficient (1/K)
    REAL(wp) :: friction_min_temp = 200.0_wp       ! Min friction temperature
    REAL(wp) :: friction_max_temp = 800.0_wp       ! Max friction temperature
    
    !-- Temperature table for friction (for table lookup)
    INTEGER(i4) :: n_friction_table_points = 0_i4
    REAL(wp), ALLOCATABLE :: friction_temp_table(:)    ! Temperature points
    REAL(wp), ALLOCATABLE :: friction_coef_table(:)    ! Friction coef values
    
    !-- Radiation (optional)
    LOGICAL :: radiation_enabled = .FALSE.
    REAL(wp) :: emissivity_master = 0.9_wp
    REAL(wp) :: emissivity_slave = 0.9_wp
    REAL(wp) :: ambient_temp = 300.0_wp
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Desc_Init
    PROCEDURE :: Set_Conductance => PH_Thermal_Cont_Desc_SetConductance
    PROCEDURE :: Set_FrictionTemp => PH_Thermal_Cont_Desc_SetFrictionTemp
    
  END TYPE PH_Thermal_Cont_Desc
  
  !===========================================================================
  !> @brief Thermal contact state (hot path, frequent read/write)
  !! Stores thermal contact dynamic state and intermediate results
  !===========================================================================
  TYPE, PUBLIC :: PH_Thermal_Cont_State
    !-- Temperature field
    REAL(wp), ALLOCATABLE :: temp_master(:)        ! Master surface temperatures
    REAL(wp), ALLOCATABLE :: temp_slave(:)         ! Slave surface temperatures
    REAL(wp), ALLOCATABLE :: temp_jump(:)          ! Temperature jump across interface
    
    !-- Heat flux
    REAL(wp), ALLOCATABLE :: heat_flux_normal(:)   ! Normal heat flux (W/m²)
    REAL(wp), ALLOCATABLE :: heat_flux_friction(:) ! Frictional heat generation
    REAL(wp), ALLOCATABLE :: heat_flux_total(:)    ! Total heat flux
    
    !-- Contact conductance (current state)
    REAL(wp), ALLOCATABLE :: conductance(:)        ! Current conductance per node
    
    !-- Gap distance (for conductance calculation)
    REAL(wp), ALLOCATABLE :: gap_distance(:)       ! Current gap per node
    
    !-- Friction heat partition
    REAL(wp), ALLOCATABLE :: heat_to_master(:)     ! Heat fraction to master
    REAL(wp), ALLOCATABLE :: heat_to_slave(:)      ! Heat fraction to slave
    
    !-- State variables
    INTEGER(i4) :: n_nodes = 0_i4
    LOGICAL :: initialized = .FALSE.
    
    !-- Statistics
    REAL(wp) :: total_heat_generation = 0.0_wp     ! Total frictional heat
    REAL(wp) :: max_temperature = 0.0_wp           ! Max temperature in step
    REAL(wp) :: avg_conductance = 0.0_wp           ! Average conductance
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_State_Init
    PROCEDURE :: Update_Temperature => PH_Thermal_Cont_State_UpdateTemp
    PROCEDURE :: Compute_HeatFlux => PH_Thermal_Cont_State_ComputeHeatFlux
    
  END TYPE PH_Thermal_Cont_State
  
  !===========================================================================
  !> @brief Thermal contact algorithm parameters (step-level cache)
  !! Stores solver parameters and hyperparameters
  !===========================================================================
  TYPE, PUBLIC :: PH_Thermal_Cont_Algo
    !-- Thermal time integration
    REAL(wp) :: thermal_time_integrator = 1_i4     ! 1=Forward Euler, 2=Crank-Nicolson
    REAL(wp) :: theta_factor = 0.5_wp              ! CN factor (0.5 = trapezoidal)
    
    !-- Conductance linearization
    LOGICAL :: linearize_conductance = .TRUE.      ! Tangent stiffness
    REAL(wp) :: conductance_tolerance = 1.0e-6_wp  ! Linearization tolerance
    
    !-- Friction heat smoothing
    LOGICAL :: smooth_friction_heat = .TRUE.       ! Time smoothing
    REAL(wp) :: smoothing_factor = 0.1_wp          ! Exponential smoothing
    
    !-- Temperature update
    INTEGER(i4) :: temp_update_scheme = 1_i4       ! 1=Explicit, 2=Semi-implicit
    REAL(wp) :: temp_relaxation = 0.8_wp           ! Relaxation factor
    
    !-- Convergence criteria
    REAL(wp) :: temp_residual_tolerance = 1.0e-4_wp ! Temperature residual
    INTEGER(i4) :: max_thermal_iterations = 50_i4  ! Max thermal iterations
    
    !-- Performance tuning
    LOGICAL :: adaptive_conductance = .TRUE.       ! Auto-tune conductance
    REAL(wp) :: conductance_scale_factor = 1.0_wp  ! Global scaling
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Algo_Init
    PROCEDURE :: Set_TimeIntegrator => PH_Thermal_Cont_Algo_SetTimeIntegrator
    
  END TYPE PH_Thermal_Cont_Algo
  
  !===========================================================================
  !> @brief Thermal contact context (temporary buffer, no dynamic allocation)
  !! Cross-layer/cross-domain variable transfer
  !===========================================================================
  !---------------------------------------------------------------------------
  ! TYPE: PH_ThermalCont_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking
  !        for Thermal Contact evolution. Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_ThermalCont_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_ThermalCont_Inc_Evo_Ctx

  TYPE, PUBLIC :: PH_Thermal_Cont_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_ThermalCont_Inc_Evo_Ctx) :: inc  ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: iter_idx = 0_i4
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dt = 0.0_wp
    REAL(wp) :: current_temp_ref = 0.0_wp
    
    !-- Temporary buffers (pre-allocated, no dynamic allocation)
    REAL(wp), POINTER :: temp_buffer_master(:) => NULL()
    REAL(wp), POINTER :: temp_buffer_slave(:) => NULL()
    REAL(wp), POINTER :: flux_buffer(:) => NULL()
    
    !-- Working arrays pointers
    REAL(wp), POINTER :: work1(:) => NULL()
    REAL(wp), POINTER :: work2(:) => NULL()
    INTEGER(i4), POINTER :: iwork1(:) => NULL()
    
    !-- Flags
    LOGICAL :: first_call = .TRUE.
    LOGICAL :: need_recompute = .FALSE.
    LOGICAL :: converged = .FALSE.
    
    !-- Debug output
    INTEGER(i4) :: print_level = 0_i4              ! 0=None, 1=Summary, 2=Full
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Ctx_Init
    PROCEDURE :: Set_Buffers => PH_Thermal_Cont_Ctx_SetBuffers
    
  END TYPE PH_Thermal_Cont_Ctx
  
CONTAINS

  !===========================================================================
  !> @brief Initialize thermal contact Desc
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Desc_Init(this, status)
    CLASS(PH_Thermal_Cont_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    
    ! Validate parameters
    IF (this%conductance_constant <= 0.0_wp) THEN
      PRINT *, 'ERROR: Conductance must be positive'
      status = -1_i4
      RETURN
    END IF
    
    IF (this%heat_partition_coef < 0.0_wp .OR. this%heat_partition_coef > 1.0_wp) THEN
      PRINT *, 'ERROR: Heat partition coef must be in [0, 1]'
      status = -2_i4
      RETURN
    END IF
    
    IF (this%n_table_points > 0) THEN
      IF (.NOT. ALLOCATED(this%table_gaps) .OR. .NOT. ALLOCATED(this%table_conductance)) THEN
        PRINT *, 'ERROR: Table arrays not allocated'
        status = -3_i4
        RETURN
      END IF
    END IF
    
    PRINT *, 'Thermal contact Desc initialized'
    
  END SUBROUTINE PH_Thermal_Cont_Desc_Init
  
  !===========================================================================
  !> @brief Set conductance model parameters
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Desc_SetConductance(this, model, cond_const, &
                                                 gap_ref, exponent, status)
    CLASS(PH_Thermal_Cont_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: model
    REAL(wp), INTENT(IN), OPTIONAL :: cond_const
    REAL(wp), INTENT(IN), OPTIONAL :: gap_ref
    REAL(wp), INTENT(IN), OPTIONAL :: exponent
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    this%conductance_model = model
    
    IF (PRESENT(cond_const)) this%conductance_constant = cond_const
    IF (PRESENT(gap_ref)) this%conductance_gap_ref = gap_ref
    IF (PRESENT(exponent)) this%conductance_exponent = exponent
    
  END SUBROUTINE PH_Thermal_Cont_Desc_SetConductance
  
  !===========================================================================
  !> @brief Set temperature-dependent friction parameters
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Desc_SetFrictionTemp(this, model, ref_temp, &
                                                  temp_coef, status)
    CLASS(PH_Thermal_Cont_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: model
    REAL(wp), INTENT(IN), OPTIONAL :: ref_temp
    REAL(wp), INTENT(IN), OPTIONAL :: temp_coef
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    this%friction_temp_model = model
    
    IF (PRESENT(ref_temp)) this%friction_ref_temp = ref_temp
    IF (PRESENT(temp_coef)) this%friction_temp_coef = temp_coef
    
  END SUBROUTINE PH_Thermal_Cont_Desc_SetFrictionTemp
  
  !===========================================================================
  !> @brief Initialize thermal contact State
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_State_Init(this, n_nodes, status)
    CLASS(PH_Thermal_Cont_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_nodes
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    this%pop%n_nodes = n_nodes
    
    IF (n_nodes <= 0) THEN
      PRINT *, 'ERROR: Invalid node count'
      status = -1_i4
      RETURN
    END IF
    
    ! Allocate state arrays
    ALLOCATE(this%temp_master(3, n_nodes))
    ALLOCATE(this%temp_slave(3, n_nodes))
    ALLOCATE(this%temp_jump(n_nodes))
    ALLOCATE(this%heat_flux_normal(n_nodes))
    ALLOCATE(this%heat_flux_friction(n_nodes))
    ALLOCATE(this%heat_flux_total(n_nodes))
    ALLOCATE(this%conductance(n_nodes))
    ALLOCATE(this%gap_distance(n_nodes))
    ALLOCATE(this%heat_to_master(n_nodes))
    ALLOCATE(this%heat_to_slave(n_nodes))
    
    ! Initialize to zero
    this%temp_master = 0.0_wp
    this%temp_slave = 0.0_wp
    this%temp_jump = 0.0_wp
    this%heat_flux_normal = 0.0_wp
    this%heat_flux_friction = 0.0_wp
    this%heat_flux_total = 0.0_wp
    this%conductance = 0.0_wp
    this%gap_distance = 0.0_wp
    this%heat_to_master = 0.0_wp
    this%heat_to_slave = 0.0_wp
    
    this%initialized = .TRUE.
    this%total_heat_generation = 0.0_wp
    this%max_temperature = 0.0_wp
    this%avg_conductance = 0.0_wp
    
    PRINT *, 'Thermal contact State initialized with ', n_nodes, ' nodes'
    
  END SUBROUTINE PH_Thermal_Cont_State_Init
  
  !===========================================================================
  !> @brief Update temperature field
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_State_UpdateTemp(this, temp_master, temp_slave, status)
    CLASS(PH_Thermal_Cont_State), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: temp_master(:)
    REAL(wp), INTENT(IN) :: temp_slave(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = 0_i4
    
    IF (.NOT. this%initialized) THEN
      status = -1_i4
      RETURN
    END IF
    
    ! Update temperatures
    DO i = 1, this%pop%n_nodes
      this%temp_master(1, i) = temp_master(i)
      this%temp_slave(1, i) = temp_slave(i)
      this%temp_jump(i) = temp_master(i) - temp_slave(i)
      
      ! Track maximum
      this%max_temperature = MAX(this%max_temperature, &
                                temp_master(i), temp_slave(i))
    END DO
    
  END SUBROUTINE PH_Thermal_Cont_State_UpdateTemp
  
  !===========================================================================
  !> @brief Compute heat flux from temperature jump
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_State_ComputeHeatFlux(this, status)
    CLASS(PH_Thermal_Cont_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = 0_i4
    
    IF (.NOT. this%initialized) THEN
      status = -1_i4
      RETURN
    END IF
    
    ! Compute normal heat flux: q = h * ΔT
    DO i = 1, this%pop%n_nodes
      this%heat_flux_normal(i) = this%conductance(i) * this%temp_jump(i)
    END DO
    
    ! Compute average conductance
    this%avg_conductance = SUM(this%conductance) / REAL(this%pop%n_nodes, wp)
    
  END SUBROUTINE PH_Thermal_Cont_State_ComputeHeatFlux
  
  !===========================================================================
  !> @brief Initialize thermal contact Algo
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Algo_Init(this, status)
    CLASS(PH_Thermal_Cont_Algo), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    
    ! Validate parameters
    IF (this%theta_factor < 0.0_wp .OR. this%theta_factor > 1.0_wp) THEN
      PRINT *, 'ERROR: Theta factor must be in [0, 1]'
      status = -1_i4
      RETURN
    END IF
    
    IF (this%temp_relaxation <= 0.0_wp .OR. this%temp_relaxation > 1.0_wp) THEN
      PRINT *, 'ERROR: Relaxation factor must be in (0, 1]'
      status = -2_i4
      RETURN
    END IF
    
    PRINT *, 'Thermal contact Algo initialized'
    
  END SUBROUTINE PH_Thermal_Cont_Algo_Init
  
  !===========================================================================
  !> @brief Set time integration scheme
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Algo_SetTimeIntegrator(this, scheme, theta, status)
    CLASS(PH_Thermal_Cont_Algo), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: scheme
    REAL(wp), INTENT(IN), OPTIONAL :: theta
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    this%thermal_time_integrator = scheme
    
    IF (PRESENT(theta)) THEN
      IF (theta >= 0.0_wp .AND. theta <= 1.0_wp) THEN
        this%theta_factor = theta
      ELSE
        PRINT *, 'WARNING: Invalid theta, using default 0.5'
        this%theta_factor = 0.5_wp
      END IF
    END IF
    
  END SUBROUTINE PH_Thermal_Cont_Algo_SetTimeIntegrator
  
  !===========================================================================
  !> @brief Initialize thermal contact Ctx
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Ctx_Init(this, status)
    CLASS(PH_Thermal_Cont_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    
    this%inc%step_idx = 0_i4
    this%inc%incr_idx = 0_i4
    this%inc%step_idx = 0_i4
    this%inc%incr_idx = 0_i4
    this%iter_idx = 0_i4
    this%time = 0.0_wp
    this%dt = 0.0_wp
    this%current_temp_ref = 0.0_wp
    
    this%first_call = .TRUE.
    this%need_recompute = .FALSE.
    this%converged = .FALSE.
    this%print_level = 0_i4
    
    NULLIFY(this%temp_buffer_master)
    NULLIFY(this%temp_buffer_slave)
    NULLIFY(this%flux_buffer)
    NULLIFY(this%work1)
    NULLIFY(this%work2)
    NULLIFY(this%iwork1)
    
    PRINT *, 'Thermal contact Ctx initialized'
    
  END SUBROUTINE PH_Thermal_Cont_Ctx_Init
  
  !===========================================================================
  !> @brief Set buffer pointers
  !===========================================================================
  SUBROUTINE PH_Thermal_Cont_Ctx_SetBuffers(this, temp_m, temp_s, flux, &
                                           w1, w2, iw1, status)
    CLASS(PH_Thermal_Cont_Ctx), INTENT(INOUT) :: this
    REAL(wp), TARGET, INTENT(IN) :: temp_m(:)
    REAL(wp), TARGET, INTENT(IN) :: temp_s(:)
    REAL(wp), TARGET, INTENT(IN) :: flux(:)
    REAL(wp), TARGET, INTENT(IN), OPTIONAL :: w1(:)
    REAL(wp), TARGET, INTENT(IN), OPTIONAL :: w2(:)
    INTEGER(i4), TARGET, INTENT(IN), OPTIONAL :: iw1(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0_i4
    
    this%temp_buffer_master => temp_m
    this%temp_buffer_slave => temp_s
    this%flux_buffer => flux
    
    IF (PRESENT(w1)) this%work1 => w1
    IF (PRESENT(w2)) this%work2 => w2
    IF (PRESENT(iw1)) this%iwork1 => iw1
    
  END SUBROUTINE PH_Thermal_Cont_Ctx_SetBuffers
  
END MODULE PH_ThermalCont_Def
