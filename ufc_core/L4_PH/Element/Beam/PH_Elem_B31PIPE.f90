!===============================================================================
! MODULE: PH_Elem_B31PIPE
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31PIPE element with internal/external pressure
!===============================================================================
MODULE PH_Elem_B31PIPE
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF, TWO, PI
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID
  
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState
  USE MD_Mat_Lib,      ONLY: MatProperties
  
  USE PH_Elem_B31, ONLY: PH_Elem_B31_FormStiffMatrixWithSection
  
  IMPLICIT NONE
  PRIVATE

  !-- Public Constants
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B31PIPE_NDOF_TOTAL  = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B31PIPE_NDOF_MECH   = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B31PIPE_NDOF_PRES   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B31PIPE_NNODE       = 2_i4
  
  !-- Property indices
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_E       = 1_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_NU      = 2_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_A       = 3_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_IY      = 4_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_IZ      = 5_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_J       = 6_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_D_OUTER = 7_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_D_INNER = 8_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31PIPE_PROP_T_WALL  = 9_i4
  
  !-- Public API
  PUBLIC :: PH_Elem_B31PIPE_FormStiffMatrix
  PUBLIC :: PH_Elem_B31PIPE_FormIntForce
  PUBLIC :: PH_Elem_B31PIPE_PressureLoad
  PUBLIC :: PH_Elem_B31PIPE_ConsMassMatrix
  PUBLIC :: PH_Elem_B31PIPE_LumpMassVector
  PUBLIC :: PH_Elem_B31PIPE_RecoverStress
  PUBLIC :: UF_Elem_B31PIPE_Calc

CONTAINS

  !===========================================================================
  ! Stiffness Matrix Formation (14x14)
  !===========================================================================
  SUBROUTINE PH_Elem_B31PIPE_FormStiffMatrix(coords3, E_young, nu, area, Iy, Iz, J_tors, &
                                              D_outer, D_inner, t_wall, Ke14, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, Iy, Iz, J_tors
    REAL(wp), INTENT(IN)  :: D_outer, D_inner, t_wall
    REAL(wp), INTENT(OUT) :: Ke14(14, 14)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: Ke12(12, 12), el_len, pressure_area
    
    CALL init_error_status(status)
    Ke14 = ZERO
    
    ! Mechanical stiffness (12x12) from B31
    CALL PH_Elem_B31_FormStiffMatrixWithSection(coords3, E_young, nu, area, Iy, Iz, J_tors, Ke12)
    Ke14(1:12, 1:12) = Ke12(1:12, 1:12)
    
    ! Element length
    el_len = SQRT(SUM((coords3(:, 2) - coords3(:, 1))**2))
    IF (el_len <= 1.0e-20_wp) THEN
      Ke14(1, 1) = ONE
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    
    ! Pressure area (end cap)
    pressure_area = PI * D_inner**2 / 4.0_wp
    
    ! TODO: Pressure stiffening matrix (K_geo from hoop stress)
    ! For now: Only mechanical stiffness
    ! Future: Add geometric stiffness from σ_θ = p*D/(2t)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31PIPE_FormStiffMatrix

  !===========================================================================
  ! Internal Force Vector (14x1)
  !===========================================================================
  SUBROUTINE PH_Elem_B31PIPE_FormIntForce(coords3, u14, D_mat, ip_stress, Rint14, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: u14(14)
    REAL(wp), INTENT(IN)  :: D_mat(:,:)
    REAL(wp), INTENT(IN)  :: ip_stress(:,:)
    REAL(wp), INTENT(OUT) :: Rint14(14)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Rint12(12)
    
    CALL init_error_status(status)
    Rint14 = ZERO
    
    ! Mechanical internal force (12x1)
    ! TODO: Call B31 internal force routine
    ! CALL PH_Elem_B31_FormIntForce(coords3, u14(1:12), D_mat, ip_stress, Rint12)
    
    ! Pressure contribution will be added separately via PH_Elem_B31PIPE_PressureLoad
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31PIPE_FormIntForce

  !===========================================================================
  ! Pressure Load Vector (End Cap Effect)
  !===========================================================================
  SUBROUTINE PH_Elem_B31PIPE_PressureLoad(coords3, p_inner, D_inner, t_wall, &
                                           F_pressure, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: p_inner, D_inner, t_wall
    REAL(wp), INTENT(OUT) :: F_pressure(14)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: el_len(3), ex(3), ey(3), ez(3)
    REAL(wp) :: pressure_area, F_cap
    REAL(wp) :: hoop_stress, axial_stress
    
    CALL init_error_status(status)
    F_pressure = ZERO
    
    ! Element direction vector
    el_len = SQRT(SUM((coords3(:, 2) - coords3(:, 1))**2))
    IF (el_len <= 1.0e-20_wp) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    
    ! Unit vector in axial direction
    ex = (coords3(:, 2) - coords3(:, 1)) / el_len
    
    ! Pressure area (end cap)
    pressure_area = PI * D_inner**2 / 4.0_wp
    
    ! End cap force magnitude: F = p * A
    F_cap = p_inner * pressure_area
    
    ! Apply end cap forces at nodes (axial direction)
    ! Node 1: -F_cap * ex (compressive)
    ! Node 2: +F_cap * ex (tensile)
    F_pressure(1:3) = -F_cap * ex
    F_pressure(8:10) = F_cap * ex
    
    ! Distributed pressure load along element length
    ! For internal pressure, this creates uniform radial expansion
    ! Simplified: equivalent nodal forces from surface traction
    REAL(wp) :: q_radial, L, force_per_node
    L = el_len
    q_radial = p_inner * D_inner  ! Force per unit length
    force_per_node = q_radial * L / 2.0_wp  ! Half at each node
    
    ! Radial forces (simplified - assuming vertical pipe for demo)
    ! Full implementation needs transformation to local coordinate system
    F_pressure(2) = F_pressure(2) - force_per_node  ! Node 1 y-direction
    F_pressure(9) = F_pressure(9) - force_per_node  ! Node 2 y-direction
    
    ! Store stresses in state variables (for post-processing)
    stress_out(1) = axial_stress        ! σ_x (axial)
    stress_out(2) = hoop_stress         ! σ_y (hoop/circumferential)
    stress_out(3) = -p_inner / 2.0_wp   ! σ_z (radial, average through thickness)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31PIPE_PressureLoad

  !===========================================================================
  ! Mass Matrices
  !===========================================================================
  SUBROUTINE PH_Elem_B31PIPE_ConsMassMatrix(coords3, rho, area, Me14, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me14(14, 14)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Me12(12, 12)
    
    CALL init_error_status(status)
    Me14 = ZERO
    
    ! Consistent mass for mechanical DOF (same as B31)
    CALL PH_Elem_B31_ConsMassMatrix(coords3, rho, area, Me12, status)
    
    ! Copy to 14x14 matrix
    Me14(1:12, 1:12) = Me12(1:12, 1:12)
    
    ! Pressure DOF (7, 14): no mass contribution
    ! Fluid-structure interaction would add fluid mass terms
  END SUBROUTINE PH_Elem_B31PIPE_ConsMassMatrix
  
  SUBROUTINE PH_Elem_B31PIPE_LumpMassVector(coords3, rho, area, M_lumped14, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lumped14(14)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: el_len, m_total
    
    CALL init_error_status(status)
    M_lumped14 = ZERO
    
    el_len = SQRT(SUM((coords3(:, 2) - coords3(:, 1))**2))
    m_total = rho * area * el_len
    
    ! Lumped mass: half at each node (mechanical DOF only)
    M_lumped14(1:6) = m_total / 2.0_wp
    M_lumped14(8:13) = m_total / 2.0_wp
    ! Pressure DOF (7, 14): zero mass
  END SUBROUTINE PH_Elem_B31PIPE_LumpMassVector

  !===========================================================================
  ! Stress Recovery
  !===========================================================================
  SUBROUTINE PH_Elem_B31PIPE_RecoverStress(coords3, u14, p_inner, D_inner, t_wall, &
                                            stress_out, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: u14(14)
    REAL(wp), INTENT(IN)  :: p_inner
    REAL(wp), INTENT(IN)  :: D_inner, t_wall
    REAL(wp), INTENT(OUT) :: stress_out(6)  ! [σ_x, σ_y, σ_z, τ_xy, τ_yz, τ_zx]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: hoop_stress, axial_stress_pres
    
    CALL init_error_status(status)
    stress_out = ZERO
    
    ! Pressure-induced stresses
    hoop_stress = p_inner * D_inner / (2.0_wp * t_wall)       ! σ_θ (circumferential)
    axial_stress_pres = p_inner * D_inner / (4.0_wp * t_wall) ! σ_x (axial from pressure)
    
    ! TODO: Add mechanical stress from displacement u14
    ! σ_mech = E * ε(u)
    ! Full implementation: call B31 stress recovery
    REAL(wp) :: sigma_mech_axial, L, eps_axial
    
    L = SQRT(SUM((coords3(:, 2) - coords3(:, 1))**2))
    IF (L > 1.0e-6_wp) THEN
      eps_axial = (u14(8) - u14(1)) / L  ! Axial strain
      sigma_mech_axial = mat%props(1) * eps_axial  ! E * ε
    ELSE
      sigma_mech_axial = 0.0_wp
    END IF
    
    ! Combined stress (pressure + mechanical)
    stress_out(1) = axial_stress_pres + sigma_mech_axial  ! σ_x (total)
    stress_out(2) = hoop_stress                            ! σ_y (hoop)
    stress_out(3) = -p_inner / 2.0_wp                      ! σ_z (radial)
    
    ! Von Mises equivalent stress
    ! σ_eq = √(σ_x² + σ_y² - σ_x*σ_y + 3*τ_xy²)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31PIPE_RecoverStress

  !===========================================================================
  ! Unified Interface
  !===========================================================================
  SUBROUTINE UF_Elem_B31PIPE_Calc(elem_type, formul, ctx, state_in, mat, &
                                   state_out, flags)
    INTEGER(i4), INTENT(IN) :: elem_type
    TYPE(FormulType), INTENT(IN) :: formul
    TYPE(ElemCtxType), INTENT(IN) :: ctx
    TYPE(StateType), INTENT(IN) :: state_in
    TYPE(MatType), INTENT(IN) :: mat
    TYPE(StateType), INTENT(OUT) :: state_out
    TYPE(FlagsType), INTENT(OUT) :: flags
    
    REAL(wp) :: coords3(3, 2)
    REAL(wp) :: E, nu, A, Iy, Iz, J
    REAL(wp) :: D_outer, D_inner, t_wall
    REAL(wp) :: Ke14(14, 14), Rint14(14)
    REAL(wp) :: p_inner
    
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    
    ! Extract properties from material/section
    E       = mat%props(PH_B31PIPE_PROP_E)
    nu      = mat%props(PH_B31PIPE_PROP_NU)
    A       = mat%props(PH_B31PIPE_PROP_A)
    Iy      = mat%props(PH_B31PIPE_PROP_IY)
    Iz      = mat%props(PH_B31PIPE_PROP_IZ)
    J       = mat%props(PH_B31PIPE_PROP_J)
    D_outer = mat%props(PH_B31PIPE_PROP_D_OUTER)
    D_inner = mat%props(PH_B31PIPE_PROP_D_INNER)
    t_wall  = mat%props(PH_B31PIPE_PROP_T_WALL)
    
    ! Extract coordinates from element context
    coords3(:, 1) = ctx%coords(1:3, 1)  ! Node 1
    coords3(:, 2) = ctx%coords(1:3, 2)  ! Node 2
    
    ! Form stiffness matrix
    CALL PH_Elem_B31PIPE_FormStiffMatrix(coords3, E, nu, A, Iy, Iz, J, &
                                         D_outer, D_inner, t_wall, Ke14, flags%status)
    
    ! Form internal force
    CALL PH_Elem_B31PIPE_FormIntForce(coords3, state_in%u, state_in%D, &
                                      state_in%stress, Rint14, flags%status)
    
    ! Apply pressure load
    p_inner = state_in%p(1)  ! Assuming pressure stored in state
    CALL PH_Elem_B31PIPE_PressureLoad(coords3, p_inner, D_inner, t_wall, &
                                      Rint14, flags%status)
    
    ! Output
    state_out%evo%Ke = Ke14
    state_out%Rint = Rint14
    
    IF (.NOT. STATUS_SUCCESS(flags%status)) THEN
      flags%failed = .TRUE.
    END IF
    
  END SUBROUTINE UF_Elem_B31PIPE_Calc

END MODULE PH_Elem_B31PIPE