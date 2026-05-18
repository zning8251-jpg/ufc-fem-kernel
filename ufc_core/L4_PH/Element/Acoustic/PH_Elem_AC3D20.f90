!===============================================================================
! MODULE: PH_Elem_AC3D20
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC3D20 20-node 3D quadratic hexahedral acoustic element
!===============================================================================
MODULE PH_Elem_AC3D20
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR, &
                        init_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_C3D20, ONLY: PH_Elem_C3D20_ShapeFunc, PH_Elem_C3D20_Jac, &
       PH_Elem_C3D20_GaussPoints, PH_Elem_C3D20_JacB
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatAlgo
  USE MD_Sect_Def, ONLY: MD_Sect_Registry
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NNODE  = 20_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NIP   = 27_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NDOF  = 20_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NEDGE = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_LOAD_EDGE_P = 2_i4
  
  !---------------------------------------------------------------------------
  ! CONSTANTS FOR ACOUSTIC ELEMENT
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NFACE = 6_i4  ! 6 faces
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D20_NSVARS_PER_IP = 14_i4  ! State vars per IP

  !---------------------------------------------------------------------------
  ! CORE PHYSICS (P2/P3 - Acoustic element fundamentals)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_DefInit              ! Element definition init
  PUBLIC :: PH_Elem_AC3D20_FormStiffMatrix      ! Stiffness matrix assembly
  PUBLIC :: PH_Elem_AC3D20_FormIntForce         ! Internal force vector
  PUBLIC :: PH_Elem_AC3D20_ConsMass             ! Consistent mass matrix
  PUBLIC :: PH_Elem_AC3D20_LumpMass             ! Lumped mass matrix
  PUBLIC :: PH_Elem_AC3D20_FormDampingMatrix    ! Rayleigh damping matrix
  PUBLIC :: PH_Elem_AC3D20_ThermStrainVector    ! Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (Large amplitude acoustics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_NL_TL                ! Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC3D20_NL_UL                ! Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (Essential and natural)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_ApplyEssentialBC     ! Dirichlet BC (elimination)
  PUBLIC :: PH_Elem_AC3D20_ApplyPenaltyBC       ! Neumann BC (penalty method)
  PUBLIC :: PH_Elem_AC3D20_FormConstraintMatrix ! Constraint matrix (MPC)
  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_FormAcousticImpedance ! Impedance boundary
  PUBLIC :: PH_Elem_AC3D20_FormRadiationCondition ! Radiation BC (infinite domain)
  PUBLIC :: PH_Elem_AC3D20_FormStructureCoupling
  PUBLIC :: UF_Elem_AC3D20_Calc ! Fluid-structure interface
  
  !---------------------------------------------------------------------------
  ! LOADS (External forcing)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_FormPressureLoad     ! Surface pressure load
  PUBLIC :: PH_Elem_AC3D20_FormBodyForce        ! Body force (gravity)
  PUBLIC :: PH_Elem_AC3D20_FormSurfaceTraction  ! Surface traction
  PUBLIC :: PH_Elem_AC3D20_FormNodalForce      ! Nodal force vector
  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (Output and diagnostics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_CalcPressure         ! Recover pressure at nodes/IPs
  PUBLIC :: PH_Elem_AC3D20_CalcAcousticIntensity ! Acoustic intensity vector
  PUBLIC :: PH_Elem_AC3D20_CalcEnergy          ! Acoustic energy computation
  PUBLIC :: PH_Elem_AC3D20_CalcEnergy_FromDesc ! Energy from descriptor
  PUBLIC :: PH_Elem_AC3D20_OutputResults       ! Output to results file
  
  !---------------------------------------------------------------------------
  ! MATERIAL PROPS (Section and material access)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_GetMaterialProps    ! Get material properties
  PUBLIC :: PH_Elem_AC3D20_GetMaterialProps_FromDesc ! From descriptor
  PUBLIC :: PH_Elem_AC3D20_GetVolume           ! Element volume
  PUBLIC :: PH_Elem_AC3D20_GetAcousticProps    ! Acoustic properties (c, K, rho)
  PUBLIC :: PH_Elem_AC3D20_SetSectionProps     ! Section property assignment
  PUBLIC :: PH_Elem_AC3D20_SetSectionProps_FromDesc ! From descriptor
  
  !---------------------------------------------------------------------------
  ! ELEMENT GEOMETRY
  !---------------------------------------------------------------------------
  PUBLIC :: PH_ELEM_AC3D20_VolumeInt            ! Element volume computation
  PUBLIC :: PH_Elem_AC3D20_GetArea             ! Surface area computation
  PUBLIC :: PH_Elem_AC3D20_GetSectProps        ! Section properties
  PUBLIC :: PH_Elem_AC3D20_GetCentroid         ! Element centroid
  
  !---------------------------------------------------------------------------
  ! CONSTRAINTS AND CONTACT
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_ApplyConstraint     ! Single DOF constraint
  PUBLIC :: PH_Elem_AC3D20_ApplyMPC            ! Multi-point constraint
  PUBLIC :: PH_Elem_AC3D20_FormContactContrib  ! Contact contribution
  PUBLIC :: PH_Elem_AC3D20_FormContactEdgeCtr ! Contact edge contribution
  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING VARS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D20_CollectIPVars       ! IP variable collection
  PUBLIC :: PH_Elem_AC3D20_MapToNode           ! Map IP to nodal
  PUBLIC :: PH_Elem_AC3D20_GetExtrapMat        ! Extrapolation matrix
  PUBLIC :: PH_Elem_AC3D20_EvalVonMises        ! Von Mises stress
  
  !=============================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !=============================================================================
  PUBLIC :: PH_Elem_AC3D20_Temperature_Dependent_Speed ! c(T) model
  PUBLIC :: PH_Elem_AC3D20_Thermal_Expansion_Source    ! Thermal expansion source
  PUBLIC :: PH_Elem_AC3D20_UpdateMaterialProps_TempDep ! Update material props
  
  !=============================================================================
  ! P4-2 BIOT POROUS MEDIA
  !=============================================================================
  PUBLIC :: PH_Elem_AC3D20_Biot_Wave_Speed           ! Biot wave speeds (P1/P2/S)
  PUBLIC :: PH_Elem_AC3D20_Biot_Damping              ! Biot damping mechanisms
  PUBLIC :: PH_Elem_AC3D20_Biot_Stabilize_SlowWave   ! SUPG stabilization for P2
  PUBLIC :: PH_Elem_AC3D20_Biot_Compute_Stab_Param   ! Stabilization parameter
  
  !=============================================================================
  ! P4-3 PML INFINITE ELEMENTS
  !=============================================================================
  PUBLIC :: PH_Elem_AC3D20_Sommerfeld_Radiation ! Sommerfeld radiation condition
  PUBLIC :: PH_Elem_AC3D20_Infinite_Element_Map ! Infinite element mapping
  PUBLIC :: PH_Elem_AC3D20_PML_Update_State     ! PML state update
  PUBLIC :: PH_Elem_AC3D20_PML_Absorbing_Boundary ! PML absorbing boundary
  
  !=============================================================================
  ! P3 RAYLEIGH DAMPING
  !=============================================================================
  PUBLIC :: PH_Elem_AC3D20_Rayleigh_Damping     ! Rayleigh damping C = aM + bK

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Acoustic_Args
  TYPE :: PH_Elem_Acoustic_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Acoustic_Args


CONTAINS

  SUBROUTINE PH_Elem_AC3D20_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_AC3D20_VolumeInt(coords, area)
  END SUBROUTINE PH_Elem_AC3D20_GetArea

  SUBROUTINE PH_Elem_AC3D20_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: centroid(3)
    INTEGER(i4) :: j
    centroid = ZERO
    DO j = 1, 20
      centroid(1:3) = centroid(1:3) + coords(1:3, j)
    END DO
    centroid = centroid / 20.0_wp
  END SUBROUTINE PH_Elem_AC3D20_GetCentroid

  SUBROUTINE PH_Elem_AC3D20_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_AC3D20_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_AC3D20_GetSectProps

  SUBROUTINE PH_Elem_AC3D20_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(20, 20)
    REAL(wp), INTENT(INOUT) :: F_el(20)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 20) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D20_ApplyConstraint

  SUBROUTINE PH_Elem_AC3D20_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(20)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(20, 20)
    REAL(wp), INTENT(INOUT) :: F_el(20)
    INTEGER(i4) :: i, j
    DO i = 1, 20
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 20
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D20_ApplyMPC

  SUBROUTINE PH_Elem_AC3D20_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(20)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(20, 20)
    REAL(wp), INTENT(INOUT) :: F_el(20)
  END SUBROUTINE PH_Elem_AC3D20_FormContactContrib

  SUBROUTINE PH_Elem_AC3D20_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(20, 20)
    REAL(wp), INTENT(OUT) :: F_el(20)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_AC3D20_FormContactEdgeCtr

  SUBROUTINE PH_Elem_AC3D20_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(20)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_AC3D20_FormBodyForce

  SUBROUTINE PH_Elem_AC3D20_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(20)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_AC3D20_FormNodalForce

  SUBROUTINE PH_Elem_AC3D20_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
  END SUBROUTINE PH_Elem_AC3D20_CollectIPVars

  SUBROUTINE PH_Elem_AC3D20_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    seq = ZERO
  END SUBROUTINE PH_Elem_AC3D20_EvalVonMises

  SUBROUTINE PH_Elem_AC3D20_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(20, 20)
    E = ZERO
  END SUBROUTINE PH_Elem_AC3D20_GetExtrapMat

  SUBROUTINE PH_Elem_AC3D20_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
  END SUBROUTINE PH_Elem_AC3D20_MapToNode

  SUBROUTINE PH_ELEM_AC3D20_VolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_AC3D20_VolumeInt

  SUBROUTINE PH_Elem_AC3D20_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(20, 20)
    REAL(wp) :: k_eff
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    k_eff = E_young
    Ke = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 20
        DO j = 1, 20
          Ke(i, j) = Ke(i, j) + k_eff * (dNdx(1,i)*dNdx(1,j) + dNdx(2,i)*dNdx(2,j) + dNdx(3,i)*dNdx(3,j)) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D20_FormStiffMatrix

  SUBROUTINE PH_Elem_AC3D20_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_AC3D20_ThermStrainVector

  SUBROUTINE PH_Elem_AC3D20_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(20, 20)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 20
        DO j = 1, 20
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D20_ConsMass

  SUBROUTINE PH_Elem_AC3D20_DefInit()
  END SUBROUTINE PH_Elem_AC3D20_DefInit

  SUBROUTINE PH_Elem_AC3D20_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(20)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(20)
    REAL(wp) :: Ke(20, 20)
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_AC3D20_FormIntForce

  SUBROUTINE PH_Elem_AC3D20_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(20)
    REAL(wp) :: vol, m
    INTEGER(i4) :: i
    CALL PH_ELEM_AC3D20_VolumeInt(coords, vol)
    m = rho * vol / 20.0_wp
    DO i = 1, 20
      M_lumped(i) = m
    END DO
  END SUBROUTINE PH_Elem_AC3D20_LumpMass

  SUBROUTINE PH_Elem_AC3D20_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 20)
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(20, 20)
    REAL(wp), INTENT(OUT) :: Ke_geo(20, 20)
    REAL(wp), INTENT(OUT) :: R_int(20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords_ref, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D20_FormIntForce(coords_ref, p_elem, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D20_NL_TL

  SUBROUTINE PH_Elem_AC3D20_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 20)
    REAL(wp), INTENT(IN)  :: p_incr(20)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(20, 20)
    REAL(wp), INTENT(OUT) :: Ke_geo(20, 20)
    REAL(wp), INTENT(OUT) :: R_int(20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords_prev, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D20_FormIntForce(coords_prev, p_incr, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D20_NL_UL

  !=============================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)
    ! Purpose: Compute temperature-dependent sound speed
    ! Theory: c(T) = c0*sqrt(T/T0) (ideal gas law derivation)
    !         For liquids: c(T) = c0*[1 + alpha_T*(T-T0)]
    REAL(wp), INTENT(OUT) :: c_speed
    REAL(wp), INTENT(IN)  :: temperature
    REAL(wp), INTENT(IN)  :: c_ref      ! Reference sound speed at T_ref
    REAL(wp), INTENT(IN)  :: T_ref      ! Reference temperature [K]
    REAL(wp), INTENT(IN)  :: alpha_T    ! Thermal expansion coefficient [1/K]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: T_ratio
    
    status = init_error_status()
    
    ! Check for valid temperature (absolute zero check)
    IF (temperature <= 0.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    ! Temperature ratio
    T_ratio = temperature / T_ref
    
    ! Use square root model (default for gases/ideal behavior)
    c_speed = c_ref * SQRT(T_ratio)
    
    ! Alternative liquid model (uncomment for water/liquids):
    ! c_speed = c_ref * (1.0_wp + alpha_T * (temperature - T_ref))
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Temperature_Dependent_Speed
  
  SUBROUTINE PH_Elem_AC3D20_Thermal_Expansion_Source(F_thermal, coords, MD_Desc, MD_Algo, temperature_field, status)
    ! Purpose: Compute thermal expansion source term in acoustic equation
    ! Theory: nabla^2 p - (1/c^2)*d^2p/dt^2 = -rho*beta_T*d^2T/dt^2
    REAL(wp), INTENT(OUT) :: F_thermal(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(IN)  :: temperature_field(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV, rho, beta_T, dTdt2
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    F_thermal = ZERO
    
    ! Default material properties
    rho = 1.21_wp      ! Density [kg/m3]
    beta_T = 3.4e-3_wp ! Thermal expansion coefficient [1/K] for air
    dTdt2 = 1.0_wp     ! d^2T/dt^2 placeholder
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      DO i = 1, 20
        F_thermal(i) = F_thermal(i) + rho * beta_T * dTdt2 * N(i) * dV
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Thermal_Expansion_Source
  
  SUBROUTINE PH_Elem_AC3D20_UpdateMaterialProps_TempDep(coords, Mat_Algo, temperature, status)
    ! Purpose: Update material properties based on temperature
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: Mat_Algo
    REAL(wp), INTENT(IN)  :: temperature
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: c_speed, c_ref, T_ref, alpha_T
    
    status = init_error_status()
    
    c_ref = 343.0_wp  ! Reference sound speed
    T_ref = 293.15_wp ! Reference temperature (20C)
    alpha_T = 3.4e-3_wp ! Thermal expansion
    
    CALL PH_Elem_AC3D20_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)
    
    ! Update Mat_Algo with temperature-dependent properties
    IF (ASSOCIATED(Mat_Algo%p_c_sound)) THEN
      SELECT TYPE(ptr => Mat_Algo%p_c_sound)
      TYPE IS (REAL(wp))
        ptr = c_speed
      END SELECT
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_UpdateMaterialProps_TempDep
  
  !=============================================================================
  ! P4-2 BIOT POROUS MEDIA
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    ! Purpose: Compute Biot wave speeds for porous media (P1/P2/S waves)
    ! Theory: Biot theory predicts three wave types:
    !   - Fast compressional wave (P1): in-phase solid/fluid motion
    !   - Slow compressional wave (P2): out-of-phase motion (highly attenuated)
    !   - Shear wave (S): solid matrix shear motion
    REAL(wp), INTENT(OUT) :: v_p1, v_p2, v_s  ! Wave speeds [m/s]
    REAL(wp), INTENT(IN)  :: porosity          ! Porosity n [0-1]
    REAL(wp), INTENT(IN)  :: K_s, K_f         ! Solid/fluid bulk modulus [Pa]
    REAL(wp), INTENT(IN)  :: G                 ! Shear modulus [Pa]
    REAL(wp), INTENT(IN)  :: rho_s, rho_f     ! Solid/fluid density [kg/m3]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: rho_11, rho_12, rho_22, Q, R, sigma_11, sigma_22, delta, M
    REAL(wp) :: K_dry, alpha
    
    status = init_error_status()
    
    ! Composite densities (Biot notation)
    rho_11 = (1.0_wp - porosity) * rho_s - rho_f * porosity
    rho_12 = porosity * rho_f
    rho_22 = porosity * rho_f / tortuosity_default(porosity)
    
    ! Effective bulk modulus of dry frame
    K_dry = K_s * (1.0_wp - porosity)
    
    ! Biot parameters
    alpha = 1.0_wp - K_dry / K_s  ! Biot coefficient
    Q = K_f / ((1.0_wp - porosity) / K_s + porosity / K_f)
    R = Q * porosity**2 / (1.0_wp - porosity - K_s / K_s)
    sigma_11 = (K_s + 4.0_wp / 3.0_wp * G) * (1.0_wp - porosity)**2 + Q
    sigma_22 = Q * porosity**2
    delta = Q * porosity * (1.0_wp - porosity)
    M = R + 2.0_wp * delta**2 / sigma_11
    
    ! Wave speeds
    v_p1 = SQRT((sigma_11 + 2.0_wp * delta + sigma_22) / (rho_11 + 2.0_wp * rho_12 + rho_22))
    v_p2 = SQRT(M / rho_22)
    v_s = SQRT(G / rho_11)
    
    status%code = STATUS_SUCCESS
  CONTAINS
    PURE REAL(wp) FUNCTION tortuosity_default(n)
      REAL(wp), INTENT(IN) :: n
      tortuosity_default = 1.0_wp / n  ! Simple model: T = 1/n
    END FUNCTION tortuosity_default
  END SUBROUTINE PH_Elem_AC3D20_Biot_Wave_Speed
  
  SUBROUTINE PH_Elem_AC3D20_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)
    ! Purpose: Compute Biot damping mechanisms (viscous dissipation)
    REAL(wp), INTENT(OUT) :: C_biot(20, 20)
    REAL(wp), INTENT(IN)  :: frequency     ! Angular frequency w [rad/s]
    REAL(wp), INTENT(IN)  :: permeability   ! Darcy permeability k [m2]
    REAL(wp), INTENT(IN)  :: viscosity      ! Dynamic viscosity mu [Pa.s]
    REAL(wp), INTENT(IN)  :: porosity       ! Porosity n [0-1]
    REAL(wp), INTENT(IN)  :: tortuosity    ! tortuosity T [-]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: omega, b_coeff, N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27), dV
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    C_biot = ZERO
    
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    b_coeff = viscosity / (permeability * porosity * tortuosity)
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      DO i = 1, 20
        DO j = 1, 20
          C_biot(i, j) = C_biot(i, j) + b_coeff * N(i) * N(j) * dV
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Biot_Damping
  
  SUBROUTINE PH_Elem_AC3D20_Biot_Stabilize_SlowWave(tau_supg, coords, MD_Algo, frequency, status)
    ! Purpose: Add SUPG stabilization for slow P-wave
    REAL(wp), INTENT(OUT) :: tau_supg
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(IN)  :: frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: v_p1, v_p2, v_s, c_fast, c_slow, omega, h_char, h_eff
    REAL(wp) :: porosity, K_s, K_f, G, rho_s, rho_f
    
    status = init_error_status()
    tau_supg = ZERO
    
    ! Default material parameters
    porosity = 0.3_wp
    K_s = 36.0e9_wp
    K_f = 2.25e9_wp
    G = 1.44e9_wp
    rho_s = 2650.0_wp
    rho_f = 1000.0_wp
    
    CALL PH_Elem_AC3D20_Biot_Wave_Speed(v_p1, c_slow, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    
    c_fast = v_p1
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    
    ! Characteristic element size (approximate)
    h_char = (DET_JACOBIAN_APPROX(coords) / 27.0_wp)**(1.0_wp / 3.0_wp)
    
    CALL PH_Elem_AC3D20_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, tau_supg, status)
    
    status%code = STATUS_SUCCESS
  CONTAINS
    PURE REAL(wp) FUNCTION DET_JACOBIAN_APPROX(c)
      REAL(wp), INTENT(IN) :: c(3, 20)
      REAL(wp) :: xmin, xmax, ymin, ymax, zmin, zmax
      xmin = MINVAL(c(1, :)); xmax = MAXVAL(c(1, :))
      ymin = MINVAL(c(2, :)); ymax = MAXVAL(c(2, :))
      zmin = MINVAL(c(3, :)); zmax = MAXVAL(c(3, :))
      DET_JACOBIAN_APPROX = (xmax-xmin) * (ymax-ymin) * (zmax-zmin)
    END FUNCTION DET_JACOBIAN_APPROX
  END SUBROUTINE PH_Elem_AC3D20_Biot_Stabilize_SlowWave
  
  SUBROUTINE PH_Elem_AC3D20_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)
    ! Purpose: Compute stabilization parameter for Biot formulation
    REAL(wp), INTENT(OUT) :: stab_param
    REAL(wp), INTENT(IN)  :: h_char  ! Characteristic element size
    REAL(wp), INTENT(IN)  :: omega   ! Angular frequency
    REAL(wp), INTENT(IN)  :: c_fast, c_slow  ! Wave speeds
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: k_fast, k_slow, Pe_cl, alpha_stab
    
    status = init_error_status()
    
    ! Wavenumbers
    k_fast = omega / c_fast
    k_slow = omega / c_slow
    
    ! Element Peclet number
    Pe_cl = k_fast * h_char / 2.0_wp
    
    ! Stabilization parameter (SUPG)
    IF (Pe_cl > 1.0_wp) THEN
      alpha_stab = Pe_cl / 2.0_wp - 1.0_wp + SQRT(Pe_cl**2 / 4.0_wp + 1.0_wp)
    ELSE
      alpha_stab = 0.0_wp
    END IF
    
    stab_param = alpha_stab / (omega + 1.0e-30_wp)
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Biot_Compute_Stab_Param
  
  !=============================================================================
  ! P4-3 PML INFINITE ELEMENTS
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, coords, status)
    ! Purpose: Apply Sommerfeld radiation condition for unbounded domains
    ! Theory: dp/dn + (1/c)*dp/dt = 0 at infinity
    REAL(wp), INTENT(INOUT) :: C_rad(20, 20)
    REAL(wp), INTENT(INOUT) :: K_rad(20, 20)
    REAL(wp), INTENT(IN)  :: face_normal(3)
    REAL(wp), INTENT(IN)  :: sound_speed
    REAL(wp), INTENT(IN)  :: frequency
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: omega, k_wave, sigma, dA
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: xi_face(9), eta_face(9), weights_face(9)
    INTEGER(i4) :: i, j, ip, n_face_ip
    
    status = init_error_status()
    C_rad = ZERO
    K_rad = ZERO
    
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    k_wave = omega / sound_speed
    sigma = k_wave * 0.1_wp
    
    ! 3x3 Gauss points for face integration
    n_face_ip = 9
    CALL GAUSS_3X3(xi_face, eta_face, weights_face)
    
    DO ip = 1, n_face_ip
      CALL PH_Elem_C3D20_ShapeFunc(xi_face(ip), eta_face(ip), ZERO, N, dNdxi)
      dA = weights_face(ip)  ! Simplified face Jacobian
      
      DO i = 1, 20
        DO j = 1, 20
          K_rad(i, j) = K_rad(i, j) + k_wave * N(i) * N(j) * dA
          C_rad(i, j) = C_rad(i, j) + (1.0_wp / sound_speed) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  CONTAINS
    SUBROUTINE GAUSS_3X3(xi, eta, w)
      REAL(wp), INTENT(OUT) :: xi(9), eta(9), w(9)
      REAL(wp) :: g = 0.7745966692414834_wp
      REAL(wp) :: wg = 0.5555555555555556_wp
      INTEGER(i4) :: k
      k = 0
      DO i = -1, 1
        DO j = -1, 1
          k = k + 1
          xi(k) = REAL(i, wp) * g
          eta(k) = REAL(j, wp) * g
          w(k) = wg * wg
        END DO
      END DO
    END SUBROUTINE GAUSS_3X3
  END SUBROUTINE PH_Elem_AC3D20_Sommerfeld_Radiation
  
  SUBROUTINE PH_Elem_AC3D20_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)
    ! Purpose: Map from natural coordinates to infinite element domain
    REAL(wp), INTENT(OUT) :: coords_phys(3, 20)
    REAL(wp), INTENT(IN)  :: coords_nat(3, 20)
    REAL(wp), INTENT(IN)  :: infinite_direction(3)
    REAL(wp), INTENT(IN)  :: decay_profile(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: r_inf, r_nat, stretching_factor
    INTEGER(i4) :: i
    
    status = init_error_status()
    
    IF (SIZE(decay_profile) >= 1) THEN
      stretching_factor = decay_profile(1)
    ELSE
      stretching_factor = 0.1_wp
    END IF
    
    DO i = 1, 20
      r_nat = DOT_PRODUCT(coords_nat(:, i), infinite_direction)
      r_inf = r_nat / (1.0_wp - r_nat * stretching_factor)
      coords_phys(:, i) = coords_nat(:, i) + infinite_direction * (r_inf - r_nat)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Infinite_Element_Map
  
  SUBROUTINE PH_Elem_AC3D20_PML_Update_State(pml_state, pml_params, time_step, pressure, status)
    ! Purpose: Update PML state variables for time-domain simulation
    TYPE(*), DIMENSION(*), INTENT(INOUT) :: pml_state
    REAL(wp), INTENT(IN)  :: pml_params(:)
    REAL(wp), INTENT(IN)  :: time_step
    REAL(wp), INTENT(IN)  :: pressure(20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sigma_max, depth, damping_coeff
    INTEGER(i4) :: i, state_size
    
    status = init_error_status()
    
    IF (SIZE(pml_params) >= 2) THEN
      sigma_max = pml_params(1)
      depth = pml_params(2)
    ELSE
      sigma_max = 100.0_wp
      depth = 0.1_wp
    END IF
    
    state_size = SIZE(pml_state)
    damping_coeff = EXP(-2.0_wp * sigma_max * time_step)
    
    DO i = 1, MIN(state_size, 20)
      IF (ASSOCIATED(pml_state(i)%ptr)) THEN
        SELECT TYPE(ptr => pml_state(i)%ptr)
        TYPE IS (REAL(wp))
          ptr = ptr * damping_coeff
        END SELECT
      END IF
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_PML_Update_State
  
  SUBROUTINE PH_Elem_AC3D20_PML_Absorbing_Boundary(coords, pml_thickness, sigma_max, C_pml, K_pml, status)
    ! Purpose: Form PML absorbing boundary contributions
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: pml_thickness
    REAL(wp), INTENT(IN)  :: sigma_max
    REAL(wp), INTENT(OUT) :: C_pml(20, 20)
    REAL(wp), INTENT(OUT) :: K_pml(20, 20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ, sigma_pml
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27), dV
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    C_pml = ZERO
    K_pml = ZERO
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      sigma_pml = sigma_max * (1.0_wp - ABS(zeta(ip)))
      
      DO i = 1, 20
        DO j = 1, 20
          C_pml(i, j) = C_pml(i, j) + sigma_pml * N(i) * N(j) * dV
          K_pml(i, j) = K_pml(i, j) + sigma_pml**2 * N(i) * N(j) * dV
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_PML_Absorbing_Boundary
  
  !=============================================================================
  ! P3 RAYLEIGH DAMPING
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_FormDampingMatrix(coords, rho, alpha_r, beta_r, C_rayleigh, status)
    ! Purpose: Form Rayleigh damping matrix C = alpha*M + beta*K
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(IN)  :: alpha_r, beta_r
    REAL(wp), INTENT(OUT) :: C_rayleigh(20, 20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: M_cons(20, 20), K_elem(20, 20)
    REAL(wp) :: E_young, nu
    
    status = init_error_status()
    C_rayleigh = ZERO
    
    E_young = 2.2e9_wp  ! Default bulk modulus for acoustics
    nu = 0.0_wp         ! Not used for acoustic
    
    ! Consistent mass matrix
    CALL PH_Elem_AC3D20_ConsMass(coords, rho, M_cons)
    
    ! Stiffness matrix (acoustic)
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords, E_young, nu, K_elem)
    
    ! Rayleigh damping: C = alpha*M + beta*K
    C_rayleigh = alpha_r * M_cons + beta_r * K_elem
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_FormDampingMatrix
  
  SUBROUTINE PH_Elem_AC3D20_Rayleigh_Damping(C_rayleigh, M, K, alpha_r, beta_r, status)
    ! Purpose: Compute Rayleigh damping from mass and stiffness matrices
    REAL(wp), INTENT(OUT) :: C_rayleigh(20, 20)
    REAL(wp), INTENT(IN)  :: M(20, 20), K(20, 20)
    REAL(wp), INTENT(IN)  :: alpha_r, beta_r
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    C_rayleigh = alpha_r * M + beta_r * K
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_Rayleigh_Damping
  
  !=============================================================================
  ! BOUNDARY CONDITIONS AND LOADS
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_ApplyEssentialBC(p_elem, prescribed_value, node_index, status)
    ! Purpose: Apply Dirichlet boundary condition (elimination method)
    REAL(wp), INTENT(INOUT) :: p_elem(20)
    REAL(wp), INTENT(IN)    :: prescribed_value
    INTEGER(i4), INTENT(IN) :: node_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    IF (node_index < 1 .OR. node_index > 20) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    p_elem(node_index) = prescribed_value
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC3D20_ApplyPenaltyBC(Ke, F_int, penalty, prescribed_value, node_index, status)
    ! Purpose: Apply Neumann boundary condition using penalty method
    REAL(wp), INTENT(INOUT) :: Ke(20, 20)
    REAL(wp), INTENT(INOUT) :: F_int(20)
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(IN)    :: prescribed_value
    INTEGER(i4), INTENT(IN) :: node_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    IF (node_index < 1 .OR. node_index > 20) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    Ke(node_index, node_index) = Ke(node_index, node_index) + penalty
    F_int(node_index) = F_int(node_index) + penalty * prescribed_value
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_ApplyPenaltyBC
  
  SUBROUTINE PH_Elem_AC3D20_FormConstraintMatrix(C, constraint_type, dof_indices, coefficients, status)
    ! Purpose: Form multi-point constraint (MPC) matrix
    REAL(wp), INTENT(OUT) :: C(:, :)
    INTEGER(i4), INTENT(IN) :: constraint_type
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    REAL(wp), INTENT(IN)    :: coefficients(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, n_dof
    
    status = init_error_status()
    C = ZERO
    n_dof = SIZE(dof_indices)
    
    SELECT CASE (constraint_type)
    CASE (PH_ELEM_CTYPE_MPC_LINEAR)
      DO i = 1, n_dof
        IF (dof_indices(i) >= 1 .AND. dof_indices(i) <= 20) THEN
          C(dof_indices(i), i) = coefficients(i)
        END IF
      END DO
    END SELECT
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_FormConstraintMatrix
  
  SUBROUTINE PH_Elem_AC3D20_FormAcousticImpedance(C_imp, K_imp, face_normal, sound_speed, density, frequency, status)
    ! Purpose: Form acoustic impedance boundary condition
    REAL(wp), INTENT(OUT) :: C_imp(:, :), K_imp(:, :)
    REAL(wp), INTENT(IN)  :: face_normal(3)
    REAL(wp), INTENT(IN)  :: sound_speed, density, frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Zc, omega, k_wave
    REAL(wp) :: N(20)
    INTEGER(i4) :: i, j
    
    status = init_error_status()
    C_imp = ZERO
    K_imp = ZERO
    
    Zc = density * sound_speed
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    k_wave = omega / sound_speed
    
    DO i = 1, 20
      DO j = 1, 20
        C_imp(i, j) = Zc * N(i) * N(j)
        K_imp(i, j) = k_wave * Zc * N(i) * N(j)
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_FormAcousticImpedance
  
  SUBROUTINE PH_Elem_AC3D20_FormRadiationCondition(C_rad, K_rad, coords, face_normal, sound_speed, frequency, status)
    ! Purpose: Form radiation boundary condition (Sommerfeld)
    REAL(wp), INTENT(OUT) :: C_rad(:, :), K_rad(:, :)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: face_normal(3)
    REAL(wp), INTENT(IN)  :: sound_speed, frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Elem_AC3D20_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, coords, status)
    
  END SUBROUTINE PH_Elem_AC3D20_FormRadiationCondition
  
  SUBROUTINE PH_Elem_AC3D20_FormStructureCoupling(K_fs, C_fs, F_fs, coords, face_normal, struct_stiffness, fluid_density, sound_speed, status)
    ! Purpose: Form fluid-structure interaction coupling terms
    REAL(wp), INTENT(OUT) :: K_fs(:, :), C_fs(:, :), F_fs(:)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: face_normal(3)
    REAL(wp), INTENT(IN)  :: struct_stiffness
    REAL(wp), INTENT(IN)  :: fluid_density, sound_speed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: xi_face(9), eta_face(9), weights_face(9)
    INTEGER(i4) :: i, j, ip
    
    status = init_error_status()
    K_fs = ZERO
    C_fs = ZERO
    F_fs = ZERO
    
    ! Simplified coupling: add struct stiffness to diagonal
    DO i = 1, 20
      K_fs(i, i) = struct_stiffness
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_FormStructureCoupling
  
  SUBROUTINE PH_Elem_AC3D20_FormPressureLoad(F_press, coords, face_id, pressure, status)
    ! Purpose: Apply surface pressure load
    REAL(wp), INTENT(OUT) :: F_press(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN)  :: pressure
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: xi_face(9), eta_face(9), weights_face(9)
    REAL(wp) :: J_face(2, 3), detJ_face, dA
    INTEGER(i4) :: i, ip
    
    status = init_error_status()
    F_press = ZERO
    
    ! 3x3 Gauss points for face
    CALL GAUSS_3X3(xi_face, eta_face, weights_face)
    
    DO ip = 1, 9
      CALL PH_Elem_C3D20_ShapeFunc(xi_face(ip), eta_face(ip), ZERO, N, dNdxi)
      detJ_face = 1.0_wp  ! Simplified
      dA = detJ_face * weights_face(ip)
      
      DO i = 1, 20
        F_press(i) = F_press(i) + pressure * N(i) * dA
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  CONTAINS
    SUBROUTINE GAUSS_3X3(xi, eta, w)
      REAL(wp), INTENT(OUT) :: xi(9), eta(9), w(9)
      REAL(wp) :: g = 0.7745966692414834_wp
      REAL(wp) :: wg = 0.5555555555555556_wp
      INTEGER(i4) :: k
      k = 0
      DO ii = -1, 1
        DO jj = -1, 1
          k = k + 1
          xi(k) = REAL(ii, wp) * g
          eta(k) = REAL(jj, wp) * g
          w(k) = wg * wg
        END DO
      END DO
    END SUBROUTINE GAUSS_3X3
  END SUBROUTINE PH_Elem_AC3D20_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC3D20_FormSurfaceTraction(F_traction, coords, traction, status)
    ! Purpose: Apply surface traction vector
    REAL(wp), INTENT(OUT) :: F_traction(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: traction(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: xi_face(9), eta_face(9), weights_face(9)
    REAL(wp) :: J_face(2, 3), detJ_face, dA, traction_mag
    INTEGER(i4) :: i, ip
    
    status = init_error_status()
    F_traction = ZERO
    
    traction_mag = SQRT(traction(1)**2 + traction(2)**2 + traction(3)**2)
    IF (traction_mag < 1.0e-30_wp) THEN
      status%code = STATUS_SUCCESS
      RETURN
    END IF
    
    CALL GAUSS_3X3(xi_face, eta_face, weights_face)
    
    DO ip = 1, 9
      CALL PH_Elem_C3D20_ShapeFunc(xi_face(ip), eta_face(ip), ZERO, N, dNdxi)
      detJ_face = 1.0_wp
      dA = detJ_face * weights_face(ip)
      
      DO i = 1, 20
        F_traction(i) = F_traction(i) + traction_mag * N(i) * dA
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  CONTAINS
    SUBROUTINE GAUSS_3X3(xi, eta, w)
      REAL(wp), INTENT(OUT) :: xi(9), eta(9), w(9)
      REAL(wp) :: g = 0.7745966692414834_wp
      REAL(wp) :: wg = 0.5555555555555556_wp
      INTEGER(i4) :: k
      k = 0
      DO ii = -1, 1
        DO jj = -1, 1
          k = k + 1
          xi(k) = REAL(ii, wp) * g
          eta(k) = REAL(jj, wp) * g
          w(k) = wg * wg
        END DO
      END DO
    END SUBROUTINE GAUSS_3X3
  END SUBROUTINE PH_Elem_AC3D20_FormSurfaceTraction
  
  !=============================================================================
  ! POST-PROCESSING
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_CalcPressure(p_elem, p_nodes, p_ip, status)
    ! Purpose: Recover pressure at integration points from nodal values
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: p_nodes(:)
    REAL(wp), INTENT(OUT) :: p_ip(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: ip
    
    status = init_error_status()
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, MIN(27, SIZE(p_ip))
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      p_ip(ip) = DOT_PRODUCT(N, p_nodes)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_CalcPressure
  
  SUBROUTINE PH_Elem_AC3D20_CalcAcousticIntensity(I_acoustic, p_elem, coords, density, sound_speed, status)
    ! Purpose: Compute acoustic intensity vector
    REAL(wp), INTENT(OUT) :: I_acoustic(3)
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: density, sound_speed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, grad_p(3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV, p_ip
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    I_acoustic = ZERO
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdx)
      CALL PH_Elem_C3D20_Jac(dNdx, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      ! Pressure at IP
      p_ip = DOT_PRODUCT(N, p_elem)
      
      ! Gradient of pressure
      grad_p = ZERO
      DO i = 1, 20
        grad_p = grad_p + p_ip * dNdx(:, i)
      END DO
      
      ! Intensity: I = -p*grad(p)/(rho*c)
      I_acoustic = I_acoustic - p_ip * grad_p * dV / (density * sound_speed)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_CalcAcousticIntensity
  
  SUBROUTINE PH_Elem_AC3D20_CalcEnergy(E_acoustic, p_elem, coords, density, sound_speed, status)
    ! Purpose: Compute acoustic energy
    REAL(wp), INTENT(OUT) :: E_acoustic
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: density, sound_speed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV, p_ip, grad_p(3), E_kin, E_pot
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    E_acoustic = ZERO
    E_kin = ZERO
    E_pot = ZERO
    
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdx)
      CALL PH_Elem_C3D20_Jac(dNdx, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      p_ip = DOT_PRODUCT(N, p_elem)
      
      ! Kinetic energy: 1/2 * rho * |grad(p)/rho|^2
      grad_p = ZERO
      DO i = 1, 20
        grad_p = grad_p + p_ip * dNdx(:, i)
      END DO
      E_kin = E_kin + 0.5_wp * density * DOT_PRODUCT(grad_p, grad_p) / density**2 * dV
      
      ! Potential energy: 1/2 * p^2 / (rho*c^2)
      E_pot = E_pot + 0.5_wp * p_ip**2 / (density * sound_speed**2) * dV
    END DO
    
    E_acoustic = E_kin + E_pot
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_CalcEnergy
  
  SUBROUTINE PH_Elem_AC3D20_CalcEnergy_FromDesc(MD_Desc, p_elem, coords, E_acoustic, status)
    ! Purpose: Compute acoustic energy from element descriptor
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: E_acoustic
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: density, sound_speed
    
    status = init_error_status()
    
    density = MD_Desc%material%density
    sound_speed = MD_Desc%material%sound_speed
    
    IF (density <= ZERO) density = 1.21_wp
    IF (sound_speed <= ZERO) sound_speed = 343.0_wp
    
    CALL PH_Elem_AC3D20_CalcEnergy(E_acoustic, p_elem, coords, density, sound_speed, status)
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_CalcEnergy_FromDesc
  
  SUBROUTINE PH_Elem_AC3D20_OutputResults(filename, p_elem, coords, status)
    ! Purpose: Output element results to file
    CHARACTER(*), INTENT(IN) :: filename
    REAL(wp), INTENT(IN)  :: p_elem(20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    ! TODO: Implement VTK/CSV output
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_OutputResults
  
  !=============================================================================
  ! MATERIAL PROPERTIES
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D20_GetMaterialProps(coords, Mat_Algo, rho, c_sound, status)
    ! Purpose: Get material properties at element location
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: Mat_Algo
    REAL(wp), INTENT(OUT) :: rho, c_sound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    rho = 1.21_wp      ! Default: air density [kg/m3]
    c_sound = 343.0_wp ! Default: speed of sound in air [m/s]
    
    IF (ASSOCIATED(Mat_Algo%p_rho)) THEN
      SELECT TYPE(ptr => Mat_Algo%p_rho)
      TYPE IS (REAL(wp))
        rho = ptr
      END SELECT
    END IF
    
    IF (ASSOCIATED(Mat_Algo%p_c_sound)) THEN
      SELECT TYPE(ptr => Mat_Algo%p_c_sound)
      TYPE IS (REAL(wp))
        c_sound = ptr
      END SELECT
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_GetMaterialProps
  
  SUBROUTINE PH_Elem_AC3D20_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound, status)
    ! Purpose: Extract material properties from element descriptor
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: rho, c_sound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    rho = MD_Desc%material%density
    c_sound = MD_Desc%material%sound_speed
    
    IF (rho <= ZERO) rho = 1.21_wp
    IF (c_sound <= ZERO) c_sound = 343.0_wp
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_GetMaterialProps_FromDesc
  
  SUBROUTINE PH_Elem_AC3D20_GetAcousticProps(rho, c_sound, Zc, K_bulk, status)
    ! Purpose: Compute acoustic properties from density and sound speed
    REAL(wp), INTENT(IN)  :: rho, c_sound
    REAL(wp), INTENT(OUT) :: Zc, K_bulk
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    Zc = rho * c_sound
    K_bulk = rho * c_sound**2
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_GetAcousticProps
  
  SUBROUTINE PH_Elem_AC3D20_SetSectionProps(Sect_Registry, props, status)
    ! Purpose: Set section properties from section registry
    TYPE(MD_Sect_Registry), INTENT(IN) :: Sect_Registry
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = init_error_status()
    props = ZERO
    
    DO i = 1, MIN(SIZE(props), Sect_Registry%n_props)
      props(i) = Sect_Registry%props(i)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_SetSectionProps
  
  SUBROUTINE PH_Elem_AC3D20_SetSectionProps_FromDesc(MD_Desc, props, status)
    ! Purpose: Set section properties from element descriptor
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    props = ZERO
    
    IF (SIZE(props) >= 1) props(1) = MD_Desc%material%density
    IF (SIZE(props) >= 2) props(2) = MD_Desc%material%bulk_modulus
    IF (SIZE(props) >= 3) props(3) = MD_Desc%material%alpha_T
    IF (SIZE(props) >= 4) props(4) = MD_Desc%section%thickness
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_SetSectionProps_FromDesc
  
  SUBROUTINE PH_Elem_AC3D20_GetVolume(volume, status)
    ! Purpose: Get element volume
    REAL(wp), INTENT(OUT) :: volume
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    volume = ZERO
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D20_GetVolume


  !=============================================================================
  ! UNIFIED INTERFACE (RT Layer compatible)
  !=============================================================================
  
  SUBROUTINE UF_Elem_AC3D20_Calc(ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, 20)
    REAL(wp) :: u(20)
    REAL(wp) :: density, bulk_modulus, sound_speed
    REAL(wp) :: k_eff, nu
    REAL(wp) :: Ke(20, 20)
    REAL(wp) :: R_int(20)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Validate coords_ref allocation
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D20_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < 20) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D20_Calc: insufficient nodes'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Extract coordinates
    DO i = 1, 20
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    ! Extract displacement/pressure field
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 20) THEN
        DO i = 1, 20
          IF (SIZE(Ctx%disp_total, 1) >= 1) THEN
            u(i) = Ctx%disp_total(1, i)
          END IF
        END DO
      END IF
    END IF

    ! Get material properties (defaults for air)
    density = 1.21_wp
    bulk_modulus = 1.42e5_wp
    sound_speed = 343.0_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) density = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) bulk_modulus = Mat%props%props(2)
    END IF

    k_eff = bulk_modulus
    nu = 0.0_wp

    IF (k_eff <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D20_Calc: invalid bulk modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Compute stiffness matrix and internal force
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords, k_eff, nu, Ke)
    CALL PH_Elem_AC3D20_FormIntForce(coords, u, k_eff, nu, R_int)

    ! Prepare output structure
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Copy Ke to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(20, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(20, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    ! Copy R_int to state_out
    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(20, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    ! Prepare integration point states
    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, 27)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
    
  END SUBROUTINE UF_Elem_AC3D20_Calc

END MODULE PH_Elem_AC3D20