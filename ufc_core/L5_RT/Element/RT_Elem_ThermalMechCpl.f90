!===============================================================================
! MODULE: RT_Elem_ThermalMechCpl
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Brg — Thermal-mechanical coupling router to L4_PH kernels
! BRIEF:  Thin adapter: validates contract, routes to L4_PH thermal kernels.
!         No physics computation — pure routing.
! **W2**：**热-力耦合** 纯路由；校核合同后调 L4 热核，**无**本构/单元形函数重算。
!===============================================================================
MODULE RT_Elem_ThermalMechCpl
  !! Thermal-Mechanical Coupling Router (L5_RT Pure Routing)
  !!
  !! DESIGN PRINCIPLE: Thin Adapter Pattern
  !! - Validates input contract
  !! - Routes to L4_PH thermal kernels
  !! - NO physics computation here
  !!
  !! Responsibility:
  !!   - Data carrier: RT_Thermal_Load TYPE
  !!   - Routing: Dispatch temperature/stress requests to L4_PH
  !!   - Integration: Coordinate with RT_Elem_Assembly_Proc
  
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Elem_Def, ONLY: RT_Elem_Desc, RT_Elem_State, RT_Elem_Algo, RT_Elem_Ctx
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx, PH_Elem_State
  USE PH_Elem_ThermalStrainKernel, ONLY: PH_ThermalStrainKernel_Algo, PH_Thermal_Strain_Args
  USE PH_Elem_ThermalStressKernel, ONLY: PH_ThermalStressKernel_Algo, PH_Thermal_Stress_Args
  USE PH_Elem_ThermalForceAsm, ONLY: PH_ThermalForceAsm_Algo, PH_Thermal_Force_Args
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: RT_Thermal_Load
  ! Thermal loading data carrier (cold path descriptor)
  !============================================================================
  TYPE, PUBLIC :: RT_Thermal_Load
    !-- Temperature field (from MD/PH layer)
    REAL(wp), POINTER :: temperature(:) => NULL()  ! [n_nodes] temp field
    REAL(wp) :: ref_temp = 293.15_wp         ! Reference temp (K)
    
    !-- Material reference (pointer to MD registry)
    INTEGER(i4) :: material_id = 0           ! Material ID in registry
    
    !-- Output (computed by L4_PH kernels)
    REAL(wp), ALLOCATABLE :: thermal_strain(:) ! [6] Voigt: exx,eyy,ezz,gxy,gyz,gxz
    REAL(wp), ALLOCATABLE :: f_thermal(:)      ! Thermal force vector [n_dof]
    REAL(wp), ALLOCATABLE :: stress_thermal(:) ! Thermal stress [6]
    
    !-- Metadata
    LOGICAL :: is_isotropic = .TRUE.     ! Isotropic thermal expansion
    INTEGER(i4) :: n_integ_points = 0    ! Number of integration points
    
  END TYPE RT_Thermal_Load

  ! Public interfaces (Pure routing)
  PUBLIC :: RT_Thermal_Compute_Strain_Route
  PUBLIC :: RT_Thermal_Assemble_Force_Route
  PUBLIC :: RT_Thermal_Update_Stress_Route

CONTAINS

  !============================================================================
  ! Subroutine: RT_Thermal_Compute_Strain_Route
  ! Purpose: ROUTE thermal strain calculation to L4_PH kernel
  ! Design:  Thin adapter - validates & dispatches only
  !============================================================================
  SUBROUTINE RT_Thermal_Compute_Strain_Route(thermal_load, ph_ctx, status)
    TYPE(RT_Thermal_Load), INTENT(INOUT) :: thermal_load
    TYPE(PH_Elem_Ctx), INTENT(IN) :: ph_ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Local args for PH kernel
    TYPE(PH_Thermal_Strain_Args) :: thermal_args
    
    ! Contract validation (thin)
    CALL init_error_status(status)
    
    IF (.NOT. ASSOCIATED(thermal_load%temperature)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Thermal_Compute_Strain_Route]: temperature not associated')
      RETURN
    END IF
    
    IF (thermal_load%material_id <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Thermal_Compute_Strain_Route]: material_id must be > 0')
      RETURN
    END IF
    
    ! Map RT carrier to PH args
    thermal_args%temperature => thermal_load%temperature
    thermal_args%ref_temp = thermal_load%ref_temp
    thermal_args%material_id = thermal_load%material_id
    thermal_args%is_isotropic = thermal_load%is_isotropic
    thermal_args%pop%n_nodes = SIZE(thermal_load%temperature)
    thermal_args%n_integ_pts = thermal_load%n_integ_points
    
    ! Set material properties (would come from MD registry in production)
    ! TODO: Query material registry by material_id
    thermal_args%alpha_iso = 1.2e-5_wp  ! Example: steel CTE
    
    ! Route to L4_PH thermal strain kernel
    ! Note: Actual computation in PH_ThermalStrainKernel_Algo
    CALL PH_ThermalStrainKernel_Algo(thermal_args, status)
    
    ! Copy results from args to carrier
    IF (ALLOCATED(thermal_args%thermal_strain)) THEN
      IF (.NOT. ALLOCATED(thermal_load%thermal_strain)) THEN
        ALLOCATE(thermal_load%thermal_strain(6))
      END IF
      thermal_load%thermal_strain = thermal_args%thermal_strain
    END IF
    
  END SUBROUTINE RT_Thermal_Compute_Strain_Route

  !============================================================================
  ! Subroutine: RT_Thermal_Assemble_Force_Route
  ! Purpose: ROUTE thermal force assembly to L4_PH kernel
  ! Design:  Thin adapter - coordinates routing, no computation
  !============================================================================
  SUBROUTINE RT_Thermal_Assemble_Force_Route(elem_desc, elem_state, elem_algo, &
                                             elem_ctx, ph_ctx, ph_state, &
                                             thermal_load, status)
    TYPE(RT_Elem_Desc), INTENT(IN) :: elem_desc
    TYPE(RT_Elem_State), INTENT(INOUT) :: elem_state
    TYPE(RT_Elem_Algo), INTENT(IN) :: elem_algo
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: elem_ctx
    TYPE(PH_Elem_Ctx), INTENT(IN) :: ph_ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: ph_state
    TYPE(RT_Thermal_Load), INTENT(INOUT) :: thermal_load
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Local args for PH kernel
    TYPE(PH_Thermal_Force_Args) :: force_args
    
    ! Validate contract
    CALL init_error_status(status)
    
    IF (elem_desc%pop%n_dof <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Thermal_Assemble_Force_Route]: n_dof must be > 0')
      RETURN
    END IF
    
    ! First compute thermal strain (via routing)
    CALL RT_Thermal_Compute_Strain_Route(thermal_load, ph_ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Map RT carrier to PH force args
    force_args%pop%n_nodes = elem_desc%n_node
    force_args%n_dof_per_node = elem_desc%pop%n_dof / elem_desc%n_node
    force_args%n_integ_pts = thermal_load%n_integ_points
    force_args%thermal_stress => thermal_load%stress_thermal
    ! TODO: Bind B matrix from element state or context
    ! force_args%B => elem_state%B_matrix
    
    ! Route to L4_PH thermal force kernel
    ! Note: Actual assembly in PH_ThermalForceAsm_Algo
    CALL PH_ThermalForceAsm_Algo(force_args, status)
    
    ! Copy results back to carrier
    IF (ALLOCATED(force_args%f_thermal)) THEN
      IF (.NOT. ALLOCATED(thermal_load%f_thermal)) THEN
        ALLOCATE(thermal_load%f_thermal(elem_desc%pop%n_dof))
      END IF
      thermal_load%f_thermal = force_args%f_thermal
    END IF
    
  END SUBROUTINE RT_Thermal_Assemble_Force_Route

  !============================================================================
  ! Subroutine: RT_Thermal_Update_Stress_Route
  ! Purpose: ROUTE thermal stress update to L4_PH kernel
  ! Design:  Thin adapter - dispatches only
  !============================================================================
  SUBROUTINE RT_Thermal_Update_Stress_Route(ph_state, thermal_load, status)
    TYPE(PH_Elem_State), INTENT(INOUT) :: ph_state
    TYPE(RT_Thermal_Load), INTENT(IN) :: thermal_load
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Local args for PH kernel
    TYPE(PH_Thermal_Stress_Args) :: stress_args
    
    ! Validate contract
    CALL init_error_status(status)
    
    IF (.NOT. ALLOCATED(thermal_load%thermal_strain)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Thermal_Update_Stress_Route]: thermal_strain not allocated')
      RETURN
    END IF
    
    ! Map RT carrier to PH args
    stress_args%thermal_strain => thermal_load%thermal_strain
    ! TODO: Query material registry for E, nu by material_id
    stress_args%young_mod = 210.0e9_wp      ! Example: steel Young's modulus
    stress_args%poisson_ratio = 0.3_wp      ! Poisson's ratio
    
    ! Route to L4_PH thermal stress kernel
    ! Note: Actual stress update in PH_ThermalStressKernel_Algo
    CALL PH_ThermalStressKernel_Algo(stress_args, status)
    
    ! Copy results back to carrier
    IF (ALLOCATED(stress_args%thermal_stress)) THEN
      IF (.NOT. ALLOCATED(thermal_load%stress_thermal)) THEN
        ALLOCATE(thermal_load%stress_thermal(6))
      END IF
      thermal_load%stress_thermal = stress_args%thermal_stress
    END IF
    
  END SUBROUTINE RT_Thermal_Update_Stress_Route

END MODULE RT_Elem_ThermalMechCpl