!===============================================================================
! MODULE: PH_Elem_ThermalStressKernel
! LAYER:  L4_PH
! DOMAIN: Element/Thermal
! ROLE:   Proc
! BRIEF:  Thermal stress computation kernel
!===============================================================================
MODULE PH_Elem_ThermalStressKernel
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_ThermalStressKernel_Algo
  PUBLIC :: PH_Thermal_Stress_Args

  !=============================================================================
  ! TYPE: PH_Thermal_Stress_Args
  ! Purpose: INTF-style argument bundle for thermal stress computation
  ! Status: INTF-001 Progressive Refactoring
  !=============================================================================
  TYPE :: PH_Thermal_Stress_Args
    !-- Input: Material properties
    INTEGER(i4)           :: material_id = 0_i4        ! Material ID in registry
    REAL(wp)              :: young_mod = 0.0_wp        ! Young's modulus E (Pa)
    REAL(wp)              :: poisson_ratio = 0.0_wp    ! Poisson's ratio ν
    REAL(wp), POINTER     :: D(:,:) => NULL()          ! [6x6] Stiffness matrix (optional)
    
    !-- Input: Thermal strain
    REAL(wp), POINTER     :: thermal_strain(:) => NULL() ! [6] Voigt thermal strain
    
    !-- Input: Initial stress state (optional)
    REAL(wp), POINTER     :: initial_stress(:) => NULL() ! [6] Pre-existing stress
    
    !-- Output: Thermal stress
    REAL(wp), ALLOCATABLE :: thermal_stress(:)         ! [6] Voigt thermal stress
    LOGICAL               :: compute_total = .FALSE._wp ! Include initial stress flag
    
  END TYPE PH_Thermal_Stress_Args

CONTAINS

  !============================================================================
  ! Subroutine: PH_ThermalStressKernel_Algo
  ! Purpose: Compute thermal stress using Hooke's law
  ! Contract: 
  !   [IN]  args%young_mod, args%poisson_ratio - elastic constants
  !   [IN]  args%thermal_strain - thermal strain vector (Voigt)
  !   [IN]  args%D (optional) - pre-computed stiffness matrix
  !   [OUT] args%thermal_stress - thermal stress vector (Voigt)
  !============================================================================
  SUBROUTINE PH_ThermalStressKernel_Algo(args, status)
    TYPE(PH_Thermal_Stress_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, stat
    REAL(wp) :: lambda, mu, trace_eps
    REAL(wp) :: D_local(6,6)
    
    CALL init_error_status(status)
    
    !--------------------------------------------------------------------------
    ! Contract validation
    !--------------------------------------------------------------------------
    IF (.NOT. ASSOCIATED(args%thermal_strain)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStressKernel_Algo]: thermal_strain not associated')
      RETURN
    END IF
    
    IF (SIZE(args%thermal_strain) /= 6) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStressKernel_Algo]: thermal_strain must be size 6 (Voigt)')
      RETURN
    END IF
    
    ! Validate elastic constants
    IF (args%young_mod <= 0.0_wp) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStressKernel_Algo]: young_mod must be > 0')
      RETURN
    END IF
    
    IF (args%poisson_ratio < 0.0_wp .OR. args%poisson_ratio > 0.5_wp) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStressKernel_Algo]: poisson_ratio must be in [0, 0.5]')
      RETURN
    END IF
    
    !--------------------------------------------------------------------------
    ! Allocate output array
    !--------------------------------------------------------------------------
    IF (.NOT. ALLOCATED(args%thermal_stress)) THEN
      ALLOCATE(args%thermal_stress(6), stat=stat)
      IF (stat /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalStressKernel_Algo]: failed to allocate thermal_stress')
        RETURN
      END IF
    END IF
    
    !--------------------------------------------------------------------------
    ! Compute stiffness matrix D (if not provided)
    ! For isotropic linear elasticity (Voigt notation)
    !--------------------------------------------------------------------------
    IF (ASSOCIATED(args%D)) THEN
      ! Use pre-computed stiffness matrix
      D_local = args%D
    ELSE
      ! Compute isotropic stiffness from E, ν
      ! D = E/((1+ν)(1-2ν)) * [...]
      lambda = args%young_mod * args%poisson_ratio / ((1.0_wp + args%poisson_ratio) * &
                                                       (1.0_wp - 2.0_wp * args%poisson_ratio))
      mu = args%young_mod / (2.0_wp * (1.0_wp + args%poisson_ratio))
      
      ! Isotropic stiffness matrix (Voigt 6x6)
      D_local = 0.0_wp
      
      ! Normal components (1-3)
      D_local(1,1) = lambda + 2.0_wp * mu
      D_local(2,2) = lambda + 2.0_wp * mu
      D_local(3,3) = lambda + 2.0_wp * mu
      
      ! Coupling terms
      D_local(1,2) = lambda
      D_local(1,3) = lambda
      D_local(2,1) = lambda
      D_local(2,3) = lambda
      D_local(3,1) = lambda
      D_local(3,2) = lambda
      
      ! Shear components (4-6)
      D_local(4,4) = mu
      D_local(5,5) = mu
      D_local(6,6) = mu
    END IF
    
    !--------------------------------------------------------------------------
    ! Compute thermal stress: σ_th = D : ε_th
    ! Matrix-vector multiplication in Voigt notation
    !--------------------------------------------------------------------------
    args%thermal_stress = 0.0_wp
    
    DO i = 1, 6
      DO j = 1, 6
        args%thermal_stress(i) = args%thermal_stress(i) + D_local(i,j) * args%thermal_strain(j)
      END DO
    END DO
    
    !--------------------------------------------------------------------------
    ! Add initial stress if requested (for total stress calculation)
    ! σ_total = σ_th + σ_initial
    !--------------------------------------------------------------------------
    IF (args%compute_total .AND. ASSOCIATED(args%initial_stress)) THEN
      args%thermal_stress = args%thermal_stress + args%initial_stress
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ThermalStressKernel_Algo

END MODULE PH_Elem_ThermalStressKernel