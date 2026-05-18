!===============================================================================
! MODULE: PH_Elem_ThermalStrainKernel
! LAYER:  L4_PH
! DOMAIN: Element/Thermal
! ROLE:   Proc
! BRIEF:  Thermal strain computation kernel
!===============================================================================
MODULE PH_Elem_ThermalStrainKernel
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_ThermalStrainKernel_Algo
  PUBLIC :: PH_Thermal_Strain_Args

  !=============================================================================
  ! TYPE: PH_Thermal_Strain_Args
  ! Purpose: INTF-style argument bundle for thermal strain computation
  ! Status: INTF-001 Progressive Refactoring
  !=============================================================================
  TYPE :: PH_Thermal_Strain_Args
    !-- Input: Temperature field
    REAL(wp), POINTER     :: temperature(:) => NULL()  ! [n_nodes] nodal temp
    REAL(wp)              :: ref_temp = 293.15_wp      ! Reference temp (K)
    
    !-- Input: Material properties
    INTEGER(i4)           :: material_id = 0_i4        ! Material ID in registry
    REAL(wp)              :: alpha_iso = 0.0_wp        ! Isotropic CTE (1/K)
    REAL(wp)              :: alpha_ortho(3) = 0.0_wp   ! Orthotropic CTE [α_x, α_y, α_z]
    LOGICAL               :: is_isotropic = .TRUE._wp  ! Isotropic flag
    
    !-- Input: Element topology
    INTEGER(i4)           :: n_nodes = 0_i4            ! Number of nodes
    INTEGER(i4)           :: n_integ_pts = 0_i4        ! Integration points
    
    !-- Output: Thermal strain
    REAL(wp), ALLOCATABLE :: thermal_strain(:)         ! [6] Voigt strain
    REAL(wp), ALLOCATABLE :: delta_temp(:)             ! [n_integ_pts] ΔT per IP
    
  END TYPE PH_Thermal_Strain_Args

CONTAINS

  !============================================================================
  ! Subroutine: PH_ThermalStrainKernel_Algo
  ! Purpose: Compute thermal strain at integration points
  ! Contract: 
  !   [IN]  args%temperature - nodal temperature field
  !   [IN]  args%ref_temp - reference temperature
  !   [IN]  args%alpha_iso/alpha_ortho - CTE coefficients
  !   [OUT] args%thermal_strain - thermal strain vector (Voigt)
  !   [OUT] args%delta_temp - temperature difference per IP
  !============================================================================
  SUBROUTINE PH_ThermalStrainKernel_Algo(args, status)
    TYPE(PH_Thermal_Strain_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, ip
    REAL(wp) :: dtemp_avg, dtemp
    
    CALL init_error_status(status)
    
    !--------------------------------------------------------------------------
    ! Contract validation
    !--------------------------------------------------------------------------
    IF (.NOT. ASSOCIATED(args%temperature)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStrainKernel_Algo]: temperature not associated')
      RETURN
    END IF
    
    IF (args%pop%n_nodes <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStrainKernel_Algo]: n_nodes must be > 0')
      RETURN
    END IF
    
    IF (args%n_integ_pts <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalStrainKernel_Algo]: n_integ_pts must be > 0')
      RETURN
    END IF
    
    ! Validate CTE (at least one component must be non-zero)
    IF (args%is_isotropic) THEN
      IF (ABS(args%alpha_iso) < 1.0e-20_wp) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalStrainKernel_Algo]: alpha_iso must be non-zero')
        RETURN
      END IF
    ELSE
      IF (ALL(ABS(args%alpha_ortho) < 1.0e-20_wp)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalStrainKernel_Algo]: alpha_ortho must have non-zero component')
        RETURN
      END IF
    END IF
    
    !--------------------------------------------------------------------------
    ! Allocate output arrays
    !--------------------------------------------------------------------------
    IF (.NOT. ALLOCATED(args%thermal_strain)) THEN
      ALLOCATE(args%thermal_strain(6), stat=i)
      IF (i /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalStrainKernel_Algo]: failed to allocate thermal_strain')
        RETURN
      END IF
    END IF
    
    IF (.NOT. ALLOCATED(args%delta_temp)) THEN
      ALLOCATE(args%delta_temp(args%n_integ_pts), stat=i)
      IF (i /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalStrainKernel_Algo]: failed to allocate delta_temp')
        RETURN
      END IF
    END IF
    
    !--------------------------------------------------------------------------
    ! Compute average temperature difference (simplified: element-average)
    ! Note: For exact IP-level, interpolate using shape functions N_i(ξ_ip)
    !--------------------------------------------------------------------------
    dtemp_avg = 0.0_wp
    DO i = 1, args%pop%n_nodes
      dtemp_avg = dtemp_avg + args%temperature(i)
    END DO
    dtemp_avg = dtemp_avg / REAL(args%pop%n_nodes, wp) - args%ref_temp
    
    ! Store per-IP ΔT (uniform for now; can be extended to IP-level interpolation)
    args%delta_temp = dtemp_avg
    
    !--------------------------------------------------------------------------
    ! Compute thermal strain (Voigt notation)
    ! ε_th = [α·ΔT, α·ΔT, α·ΔT, 0, 0, 0]^T for isotropic
    ! ε_th = [α_x·ΔT, α_y·ΔT, α_z·ΔT, 0, 0, 0]^T for orthotropic
    !--------------------------------------------------------------------------
    args%thermal_strain = 0.0_wp
    
    IF (args%is_isotropic) THEN
      ! Isotropic thermal expansion
      args%thermal_strain(1) = args%alpha_iso * dtemp_avg  ! ε_xx
      args%thermal_strain(2) = args%alpha_iso * dtemp_avg  ! ε_yy
      args%thermal_strain(3) = args%alpha_iso * dtemp_avg  ! ε_zz
      ! Shear components remain zero (4:γ_xy, 5:γ_yz, 6:γ_xz)
    ELSE
      ! Orthotropic thermal expansion
      args%thermal_strain(1) = args%alpha_ortho(1) * dtemp_avg  ! ε_xx
      args%thermal_strain(2) = args%alpha_ortho(2) * dtemp_avg  ! ε_yy
      args%thermal_strain(3) = args%alpha_ortho(3) * dtemp_avg  ! ε_zz
      ! Shear components remain zero
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ThermalStrainKernel_Algo

END MODULE PH_Elem_ThermalStrainKernel