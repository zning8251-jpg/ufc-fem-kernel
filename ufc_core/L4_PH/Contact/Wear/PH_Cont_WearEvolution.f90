!===============================================================================
! MODULE: PH_Cont_WearEvolution
! LAYER:  L4_PH
! DOMAIN: Contact / Wear
! ROLE:   Core
! BRIEF:  Wear depth (Archard/energy-based) + friction coefficient evolution
!
! Theory: Archard (1953); Strömberg et al. (1996); Põdra & Andersson (1999)
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_WearEvolution
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, SMALL_VAL => SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  
  IMPLICIT NONE
  PRIVATE
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  PUBLIC :: PH_ContWE_WearLaw
  PUBLIC :: PH_ContWE_FrictionEvolution
  PUBLIC :: PH_ContWE_WearState
  
  ! ===================================================================
  ! Public Interfaces
  ! ===================================================================
  PUBLIC :: PH_ContWE_ComputeWearDepth
  PUBLIC :: PH_ContWE_UpdateFrictionCoeff
  PUBLIC :: PH_ContWE_EnergyBasedWear
  PUBLIC :: PH_ContWE_ArchardWear
  PUBLIC :: PH_ContWE_ThirdBodyEffect
  
  ! ===================================================================
  ! Type Definitions
  ! ===================================================================
  
  TYPE :: PH_ContWE_WearLaw
    ! Wear model parameters
    INTEGER(i4) :: law_type        ! 1=Archard, 2=Energy, 3=Modified
    REAL(wp) :: wear_coeff         ! Wear coefficient k_w or k_e
    REAL(wp) :: hardness           ! Material hardness H
    REAL(wp) :: exponent           ! Exponent for modified laws
    REAL(wp) :: threshold_pressure ! Pressure threshold for wear onset
    CHARACTER(LEN=32) :: name      ! Law name
  CONTAINS
    PROCEDURE :: ComputeRate => WearLaw_ComputeRate
  END TYPE PH_ContWE_WearLaw
  
  TYPE :: PH_ContWE_FrictionEvolution
    ! Friction coefficient evolution model
    INTEGER(i4) :: evol_type       ! 1=Exponential decay, 2=Linear, 3=Sigmoid
    REAL(wp) :: mu_initial         ! Initial friction coefficient μ_0
    REAL(wp) :: mu_residual        ! Residual friction after wear μ_res
    REAL(wp) :: decay_rate         ! Decay rate α
    REAL(wp) :: critical_wear      ! Critical wear depth for transition
  CONTAINS
    PROCEDURE :: Evaluate => FrictionEval
  END TYPE PH_ContWE_FrictionEvolution
  
  TYPE :: PH_ContWE_WearState
    ! Wear state at a contact point
    INTEGER(i4) :: point_id
    REAL(wp) :: wear_depth         ! Accumulated wear depth h_w
    REAL(wp) :: wear_rate          ! Current wear rate dh/dt
    REAL(wp) :: friction_current   ! Current friction coefficient
    REAL(wp) :: dissipated_energy  ! Total dissipated energy
    REAL(wp) :: sliding_distance   ! Total sliding distance
    LOGICAL :: is_active           ! Wear active flag
    REAL(wp) :: last_update_time   ! Time of last update
  END TYPE PH_ContWE_WearState
  
CONTAINS

  ! ===========================================================================
  ! Wear Law Methods
  ! ===========================================================================
  
  FUNCTION WearLaw_ComputeRate(this, pressure, slip_speed, temp) RESULT(dh_dt)
    !> Compute wear rate based on selected law
    CLASS(PH_ContWE_WearLaw), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: pressure, slip_speed, temp
    REAL(wp) :: dh_dt
    
    SELECT CASE(this%law_type)
    CASE(1_i4)  ! Archard: dh/dt = k * p * v / H
      IF (pressure > this%threshold_pressure) THEN
        dh_dt = this%wear_coeff * pressure * ABS(slip_speed) / this%hardness
      ELSE
        dh_dt = ZERO
      END IF
      
    CASE(2_i4)  ! Energy-based: dh/dt = k * (F_t * v) / A
      dh_dt = this%wear_coeff * pressure * ABS(slip_speed)**this%exponent
      
    CASE(3_i4)  ! Modified Archard with temperature
      IF (pressure > this%threshold_pressure) THEN
        dh_dt = this%wear_coeff * pressure * ABS(slip_speed) / this%hardness
        ! Temperature correction (Arrhenius-type)
        dh_dt = dh_dt * EXP(-5000.0_wp / MAX(temp, 100.0_wp))
      ELSE
        dh_dt = ZERO
      END IF
      
    CASE DEFAULT
      dh_dt = ZERO
    END SELECT
  END FUNCTION WearLaw_ComputeRate
  
  ! ===========================================================================
  ! Archard Wear Model
  ! ===========================================================================
  
  SUBROUTINE PH_ContWE_ArchardWear(state, law, pressure, slip_speed, dt, status)
    !> Classic Archard wear model: dh = k * p * v * dt / H
    TYPE(PH_ContWE_WearState), INTENT(INOUT) :: state
    TYPE(PH_ContWE_WearLaw), INTENT(IN) :: law
    REAL(wp), INTENT(IN) :: pressure, slip_speed, dt
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: wear_increment, wear_rate
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    IF (.NOT. state%is_active) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Compute wear rate
    wear_rate = law:ComputeRate(pressure, slip_speed, 300.0_wp)  ! T=300K placeholder
    state%wear_rate = wear_rate
    
    ! Incremental wear: Δh = dh/dt * Δt
    wear_increment = wear_rate * dt
    
    ! Update accumulated wear
    state%wear_depth = state%wear_depth + wear_increment
    
    ! Update sliding distance
    state%sliding_distance = state%sliding_distance + ABS(slip_speed) * dt
    
    ! Update time
    state%last_update_time = state%last_update_time + dt
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContWE_ArchardWear
  
  ! ===========================================================================
  ! Energy-Based Wear
  ! ===========================================================================
  
  SUBROUTINE PH_ContWE_EnergyBasedWear(state, law, tangential_force, &
                                       slip_speed, area, dt, status)
    !> Energy-based wear: dh = k * dW / A, dW = F_t * v * dt
    TYPE(PH_ContWE_WearState), INTENT(INOUT) :: state
    TYPE(PH_ContWE_WearLaw), INTENT(IN) :: law
    REAL(wp), INTENT(IN) :: tangential_force, slip_speed, area, dt
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: dissipated_work, wear_increment
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    IF (.NOT. state%is_active) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Dissipated work in this increment: dW = F_t * v * dt
    dissipated_work = ABS(tangential_force * slip_speed) * dt
    
    ! Accumulate energy
    state%dissipated_energy = state%dissipated_energy + dissipated_work
    
    ! Wear increment: dh = k * dW / A
    wear_increment = law%wear_coeff * dissipated_work / MAX(area, SMALL_VAL)
    
    ! Update wear depth
    state%wear_depth = state%wear_depth + wear_increment
    state%wear_rate = wear_increment / dt
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContWE_EnergyBasedWear
  
  ! ===========================================================================
  ! Friction Coefficient Evolution
  ! ===========================================================================
  
  FUNCTION FrictionEval(this, wear_depth) RESULT(mu)
    !> Evaluate current friction coefficient based on wear
    CLASS(PH_ContWE_FrictionEvolution), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: wear_depth
    REAL(wp) :: mu
    
    SELECT CASE(this%evol_type)
    CASE(1_i4)  ! Exponential decay: μ = μ_0*exp(-α*h) + μ_res
      mu = this%mu_initial * EXP(-this%decay_rate * wear_depth) + this%mu_residual
      
    CASE(2_i4)  ! Linear decay: μ = μ_0 - β*h until μ_res
      mu = MAX(this%mu_residual, &
               this%mu_initial - this%decay_rate * wear_depth)
      
    CASE(3_i4)  ! Sigmoid transition
      IF (wear_depth < this%critical_wear) THEN
        mu = this%mu_initial
      ELSE
        mu = this%mu_residual + &
             (this%mu_initial - this%mu_residual) * &
             EXP(-(wear_depth - this%critical_wear)/this%decay_rate)
      END IF
      
    CASE DEFAULT
      mu = this%mu_initial
    END SELECT
  END FUNCTION FrictionEval
  
  SUBROUTINE PH_ContWE_UpdateFrictionCoeff(state, friction_model, status)
    !> Update friction coefficient based on accumulated wear
    TYPE(PH_ContWE_WearState), INTENT(INOUT) :: state
    TYPE(PH_ContWE_FrictionEvolution), INTENT(IN) :: friction_model
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Evaluate new friction coefficient
    state%friction_current = friction_model:Evaluate(state%wear_depth)
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContWE_UpdateFrictionCoeff
  
  ! ===========================================================================
  ! Third Body Effects (Debris)
  ! ===========================================================================
  
  SUBROUTINE PH_ContWE_ThirdBodyEffect(state, debris_thickness, &
                                       effective_mu, effective_k, status)
    !> Compute effect of wear debris on contact behavior
    TYPE(PH_ContWE_WearState), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: debris_thickness
    REAL(wp), INTENT(OUT) :: effective_mu, effective_k
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: reduction_factor
    
    IF (PRESENT(status)) CALL init_error_status/status(status)
    
    ! Debris reduces friction and wear coefficient
    IF (debris_thickness > ZERO) THEN
      reduction_factor = EXP(-debris_thickness * 1000.0_wp)  ! Simplified
    ELSE
      reduction_factor = ONE
    END IF
    
    effective_mu = state%friction_current * reduction_factor
    effective_k = state%wear_rate * reduction_factor  ! Placeholder relationship
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContWE_ThirdBodyEffect
  
  ! ===========================================================================
  ! General Wear Computation
  ! ===========================================================================
  
  SUBROUTINE PH_ContWE_ComputeWearDepth(states, n_states, law, pressures, &
                                        slip_speeds, dt, status)
    !> Compute wear depth for all contact points
    TYPE(PH_ContWE_WearState), INTENT(INOUT) :: states(:)
    INTEGER(i4), INTENT(IN) :: n_states
    TYPE(PH_ContWE_WearLaw), INTENT(IN) :: law
    REAL(wp), INTENT(IN) :: pressures(:), slip_speeds(:), dt
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    DO i = 1, n_states
      IF (states(i)%is_active) THEN
        CALL PH_ContWE_ArchardWear(states(i), law, pressures(i), &
                                   slip_speeds(i), dt, status)
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContWE_ComputeWearDepth
  
END MODULE PH_Cont_WearEvolution