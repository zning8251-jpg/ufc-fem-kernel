!===============================================================================
! MODULE: PH_Elem_B32
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B32 element kernel for 3D Euler-Bernoulli beam
!===============================================================================
MODULE PH_Elem_B32
  !===========================================================================
  ! Module Dependencies (Layered Architecture)
  !===========================================================================
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF          ! Mathematical constants
  USE IF_Prec_Core,         ONLY: wp, i4                    ! Precision kinds
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID, &
                             IF_STATUS_ERROR, STATUS_SUCCESS  ! Error handling
  
  ! L3_MD: Model definitions
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState, &
                             UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib,      ONLY: MatProperties              ! Material library
  USE MD_Mat_Lib,      ONLY: MatPropertyDef
  USE UF_Material_Base
  
  ! L4_PH: Physics layer - material constitutive
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def,  ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  
  ! L4_PH: Runtime bridge for nonlinear geometry
  USE PH_ElemRT_Brg,    ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  
  ! L4_PH: Reuse B31 kernel for identical formulations
  USE PH_Elem_B31, ONLY: PH_Elem_B31_ConsMass, PH_Elem_B31_LumpMass, &
    PH_Elem_B31_EvalBeamStress, PH_Elem_B31_FormNodalForce, PH_Elem_B31_ThermStrainVector
  
  IMPLICIT NONE
  PRIVATE
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B32_DefInit                ! Element definition initialization
  PUBLIC :: PH_Elem_B32_FormStiffMatrix        ! Form stiffness matrix (12x12)
  PUBLIC :: PH_Elem_B32_FormStiffMatrixWithSection  ! Form stiffness with section props
  PUBLIC :: PH_Elem_B32_FormIntForce           ! Form internal force vector (12x1)
  PUBLIC :: PH_Elem_B32_ConsMass               ! Form consistent mass matrix (12x12)
  PUBLIC :: PH_Elem_B32_ConsMassWithSection    ! Form consistent mass with section
  PUBLIC :: PH_Elem_B32_LumpMass               ! Form lumped mass vector (12x1)
  PUBLIC :: PH_Elem_B32_LumpMassWithSection    ! Form lumped mass with section
  PUBLIC :: PH_Elem_B32_ThermStrainVector      ! Thermal strain vector
  PUBLIC :: PH_Elem_B32_NL_TL                  ! Total Lagrangian geometric nonlinear
  PUBLIC :: PH_Elem_B32_NL_UL                  ! Updated Lagrangian geometric nonlinear
  PUBLIC :: UF_Elem_B32_Calc                   ! Unified element calculation interface
  
  ! Legacy interfaces (kept for backward compatibility)
  PUBLIC :: PH_Elem_B32_GetArea                ! Get cross-sectional area (legacy)
  PUBLIC :: PH_Elem_B32_ApplyConstraint        ! Apply constraint (legacy)
  PUBLIC :: PH_Elem_B32_FormNodalForce         ! Form nodal force (legacy)
  PUBLIC :: PH_Elem_B32_EvalBeamStress         ! Evaluate beam stress (legacy)

  !===========================================================================
  ! CONSTANTS - Element topology and DOF information
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32_NNODE  = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32_NIP    = 1_i4   ! Integration points (axial)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32_NDOF   = 12_i4  ! Total DOF (per element)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32_NEDGE  = 0_i4   ! Number of edges
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32_NSVARS_PER_IP = 6_i4  ! SVARS per IP (stress resultants)
  
  !===========================================================================
  ! SVARS LAYOUT - State Variables Storage (per integration point)
  !===========================================================================
  ! Layout: axial_force + moment_y + moment_z + torque + shear_y + shear_z = 6
  !
  ! Slot Index | Variable        | Description
  ! -----------|-----------------|------------------------------------------
  !  1         | axial_force     | Axial force [N]
  !  2         | moment_y        | Bending moment about y-axis [N·m]
  !  3         | moment_z        | Bending moment about z-axis [N·m]
  !  4         | torque          | Torsional moment [N·m]
  !  5         | shear_y         | Shear force in y-direction [N]
  !  6         | shear_z         | Shear force in z-direction [N]
  !
  ! Note: For linear Euler-Bernoulli beam, these are computed at element centroid.
  !       Future extensions may include multiple IPs along length for plasticity.
  !===========================================================================

  !===========================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES (Principle #14)
  !===========================================================================
  
  !> @brief Input structure for stiffness matrix computation
  !> Purpose: Encapsulate all inputs for B32 stiffness formation
  !> Members:
  !   - coords: Nodal coordinates in global system (Desc)
  !   - E_young, nu: Elastic constants (Desc)
  
  !> @brief Output structure for stiffness matrix computation
  !> Purpose: Return computed stiffness and error status
  !> Members:
  !   - Ke: 12×12 element stiffness matrix in global coordinates (State)
  !   - status: Error handling status (required by SIO-03)
  TYPE, PUBLIC :: PH_Elem_B32_StiffMatrix_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    REAL(wp) :: area                   ! Cross-sectional area [m²]                   ! [IN]
    REAL(wp) :: Iy                     ! Bending inertia about local y-axis [m⁴]                   ! [IN]
    REAL(wp) :: Iz                     ! Bending inertia about local z-axis [m⁴]                   ! [IN]
    REAL(wp) :: J_torsion              ! Torsional constant [m⁴]                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_StiffMatrix_Arg


  !> @brief Input structure for internal force computation
  !> Purpose: Encapsulate inputs for B32 internal force formation
  !> Members:
  !   - coords: Nodal coordinates (Desc)
  !   - u: 12×1 displacement vector in global system (State)
  !   - E_young, nu: Material properties (Desc)
  
  !> @brief Output structure for internal force computation
  !> Purpose: Return computed internal force and error status
  !> Members:
  !   - R_int: 12×1 internal force vector (State)
  !   - status: Error handling status
  TYPE, PUBLIC :: PH_Elem_B32_IntForce_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_IntForce_Arg


  !> @brief Input structure for Total Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_B32_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_NL_TL_Arg


  !> @brief Input structure for Updated Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_B32_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_NL_UL_Arg


CONTAINS

  SUBROUTINE PH_Elem_B32_ThermStrainVector(alpha, deltaT, eps_th)
    !! Thermal strain vector stub (placeholder for future B32T extension)
    !!
    !! Theory: epsilon_th = alpha * T (axial thermal expansion)
    !!
    !! Args:
    !!   alpha    (in) : Coefficient of thermal expansion
    !!   deltaT   (in) : Temperature change
    !!   eps_th   (out): Thermal strain vector
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    CALL PH_Elem_B31_ThermStrainVector(alpha, deltaT, eps_th)
  END SUBROUTINE PH_Elem_B32_ThermStrainVector

  SUBROUTINE PH_Elem_B32_GetArea(coords, area)
    !! Compute element length (geometric property)
    !!
    !! Args:
    !!   coords (in) : 3×2 nodal coordinates
    !!   area   (out): Element length [m]
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: dx, dy, dz
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    dz = coords(3, 2) - coords(3, 1)
    area = SQRT(dx*dx + dy*dy + dz*dz)
  END SUBROUTINE PH_Elem_B32_GetArea

  SUBROUTINE PH_Elem_B32_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    !! Apply constraint using penalty method
    !!
    !! Args:
    !!   ctype    (in) : Constraint type (1=penalty)
    !!   idof     (in) : DOF index (1-12)
    !!   val      (in) : Prescribed value
    !!   penalty  (in) : Penalty factor
    !!   K_el     (inout): Element stiffness matrix
    !!   F_el     (inout): Element force vector
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
    IF (ctype /= 1_i4) RETURN
    IF (idof < 1 .OR. idof > 12) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_B32_ApplyConstraint

  SUBROUTINE PH_Elem_B32_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    !! Form equivalent nodal force from distributed load
    !!
    !! Args:
    !!   load_type (in) : Load type code
    !!   coords    (in) : Nodal coordinates
    !!   val       (in) : Load intensity
    !!   edge_id   (in) : Edge/face identifier (unused for beam)
    !!   F_eq      (out): Equivalent nodal forces
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(12)
    CALL PH_Elem_B31_FormNodalForce(load_type, coords, val, edge_id, F_eq)
  END SUBROUTINE PH_Elem_B32_FormNodalForce

  SUBROUTINE PH_Elem_B32_EvalBeamStress(coords, u, sigma, E_young, nu, area, Iy, Iz, J_torsion)
    !! Evaluate beam stress resultants at integration point
    !!
    !! Theory: Euler-Bernoulli beam theory - plane sections remain plane
    !!
    !! Args:
    !!   coords     (in) : Nodal coordinates
    !!   u          (in) : Nodal displacements (12×1)
    !!   sigma      (out): Stress resultants (6×1: N, My, Mz, T, Vy, Vz)
    !!   E_young    (in) : Young's modulus
    !!   nu         (in) : Poisson's ratio
    !!   area       (in) : Cross-sectional area
    !!   Iy, Iz     (in) : Bending inertias
    !!   J_torsion  (in) : Torsional constant
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(OUT) :: sigma(:)
    REAL(wp), INTENT(IN), OPTIONAL :: E_young, nu, area, Iy, Iz, J_torsion
    CALL PH_Elem_B31_EvalBeamStress(coords, u, sigma, E_young, nu, area, Iy, Iz, J_torsion)
  END SUBROUTINE PH_Elem_B32_EvalBeamStress

  SUBROUTINE PH_Elem_B32_ConsMass(coords, rho, Me)
    !! Form consistent mass matrix with translational and rotary inertia
    !!
    !! Theory: Consistent mass from shape function integration
    !!
    !! Args:
    !!   coords (in) : Nodal coordinates
    !!   rho    (in) : Material density
    !!   Me     (out): Consistent mass matrix (12×12)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(12, 12)
    CALL PH_Elem_B31_ConsMass(coords, rho, Me)
  END SUBROUTINE PH_Elem_B32_ConsMass

  SUBROUTINE PH_Elem_B32_DefInit()
    !! Initialize element definition (stub)
    !!
    !! Purpose: Setup element type descriptor, shape functions, and integration rules
    !! Note: Currently a stub - actual initialization done in ElemType system
  END SUBROUTINE PH_Elem_B32_DefInit

  SUBROUTINE PH_Elem_B32_FormIntForce(in, out)
    !! Form internal force vector R = K · u
    !!
    !! Args:
    !!   in   (in) : Input structure (coords, displacements, material)
    !!   out  (out): Output structure (internal force, status)
    TYPE(PH_Elem_B32_IntForce_Arg), INTENT(IN) :: in
    TYPE(PH_Elem_B32_IntForce_Arg), INTENT(OUT) :: out

    TYPE(PH_Elem_B32_StiffMatrix_Arg) :: in_stiff
    TYPE(PH_Elem_B32_StiffMatrix_Arg) :: out_stiff

    CALL init_error_status(out%status)
    
    ! Build stiffness matrix
    in_stiff%coords = in%coords
    in_stiff%E_young = in%E_young
    in_stiff%nu = in%nu
    CALL PH_Elem_B32_FormStiffMatrix(arg_stiff)
    IF (out_stiff%status%status_code /= IF_STATUS_OK) THEN
      out%status = out_stiff%status
      RETURN
    END IF
    
    ! Compute internal force
    out%evo%R_int = MATMUL(out_stiff%evo%Ke, in%u)
    
    out%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_B32_FormIntForce

  SUBROUTINE PH_Elem_B32_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    TYPE(PH_Elem_B32_StiffMatrix_Arg) :: in_stiff
    TYPE(PH_Elem_B32_StiffMatrix_Arg) :: out_stiff
    in_stiff%coords = coords
    in_stiff%E_young = E_young
    in_stiff%nu = nu
    CALL PH_Elem_B32_FormStiffMatrix(arg_stiff)
    Ke = out_stiff%evo%Ke
  END SUBROUTINE PH_Elem_B32_FormStiffMatrix_Legacy

  SUBROUTINE PH_Elem_B32_FormIntForce_Legacy(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(12)
    REAL(wp) :: Ke(12, 12)
    CALL PH_Elem_B32_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_B32_FormIntForce_Legacy

  SUBROUTINE PH_Elem_B32_FormStiffMatrix(arg)
    TYPE(PH_Elem_B32_StiffMatrix_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: p1(3), p2(3), e_x(3), e_y(3), e_z(3), L
    REAL(wp) :: E, A, Iy, Iz, G, J_torsion
    REAL(wp) :: Kloc(12, 12), T(12, 12), R(3, 3)
    REAL(wp) :: EA, EIy, EIz, GJ, L2, L3
    INTEGER(i4) :: i

    CALL init_error_status(arg%status)
    
    E = arg%E_young
    A = ONE
    Iy = ONE
    Iz = ONE
    G = E / (2.0_wp * (ONE + arg%nu))
    J_torsion = 2.0_wp * ONE
    p1 = arg%coords(1:3, 1)
    p2 = arg%coords(1:3, 2)
    e_x = p2 - p1
    L = SQRT(SUM(e_x * e_x))
    IF (L <= 1.0e-12_wp) THEN
      arg%evo%Ke = ZERO
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Zero or near-zero element length"
      RETURN
    END IF
    e_x = e_x / L
    IF (ABS(e_x(3)) < 0.9999_wp) THEN
      e_z(1) = -e_x(2)
      e_z(2) =  e_x(1)
      e_z(3) = ZERO
    ELSE
      e_z(1) = ZERO
      e_z(2) = -e_x(3)
      e_z(3) =  e_x(2)
    END IF
    e_z = e_z / SQRT(SUM(e_z * e_z))
    e_y(1) = e_z(2)*e_x(3) - e_z(3)*e_x(2)
    e_y(2) = e_z(3)*e_x(1) - e_z(1)*e_x(3)
    e_y(3) = e_z(1)*e_x(2) - e_z(2)*e_x(1)
    R(1:3, 1) = e_x
    R(1:3, 2) = e_y
    R(1:3, 3) = e_z
    T = ZERO
    DO i = 1, 4
      T(3*i-2:3*i, 3*i-2:3*i) = TRANSPOSE(R)
    END DO
    EA = E * A
    EIy = E * Iy
    EIz = E * Iz
    GJ = G * J_torsion
    L2 = L * L
    L3 = L2 * L
    Kloc = ZERO
    Kloc(1, 1) = EA / L
    Kloc(1, 7) = -EA / L
    Kloc(7, 1) = -EA / L
    Kloc(7, 7) = EA / L
    Kloc(4, 4) = GJ / L
    Kloc(4, 10) = -GJ / L
    Kloc(10, 4) = -GJ / L
    Kloc(10, 10) = GJ / L
    Kloc(2, 2) = 12.0_wp * EIz / L3
    Kloc(2, 6) = 6.0_wp * EIz / L2
    Kloc(2, 8) = -12.0_wp * EIz / L3
    Kloc(2, 12) = 6.0_wp * EIz / L2
    Kloc(6, 2) = 6.0_wp * EIz / L2
    Kloc(6, 6) = 4.0_wp * EIz / L
    Kloc(6, 8) = -6.0_wp * EIz / L2
    Kloc(6, 12) = 2.0_wp * EIz / L
    Kloc(8, 2) = -12.0_wp * EIz / L3
    Kloc(8, 6) = -6.0_wp * EIz / L2
    Kloc(8, 8) = 12.0_wp * EIz / L3
    Kloc(8, 12) = -6.0_wp * EIz / L2
    Kloc(12, 2) = 6.0_wp * EIz / L2
    Kloc(12, 6) = 2.0_wp * EIz / L
    Kloc(12, 8) = -6.0_wp * EIz / L2
    Kloc(12, 12) = 4.0_wp * EIz / L
    Kloc(3, 3) = 12.0_wp * EIy / L3
    Kloc(3, 5) = -6.0_wp * EIy / L2
    Kloc(3, 9) = -12.0_wp * EIy / L3
    Kloc(3, 11) = -6.0_wp * EIy / L2
    Kloc(5, 3) = -6.0_wp * EIy / L2
    Kloc(5, 5) = 4.0_wp * EIy / L
    Kloc(5, 9) = 6.0_wp * EIy / L2
    Kloc(5, 11) = 2.0_wp * EIy / L
    Kloc(9, 3) = -12.0_wp * EIy / L3
    Kloc(9, 5) = 6.0_wp * EIy / L2
    Kloc(9, 9) = 12.0_wp * EIy / L3
    Kloc(9, 11) = 6.0_wp * EIy / L2
    Kloc(11, 3) = -6.0_wp * EIy / L2
    Kloc(11, 5) = 2.0_wp * EIy / L
    Kloc(11, 9) = 6.0_wp * EIy / L2
    Kloc(11, 11) = 4.0_wp * EIy / L
    arg%evo%Ke = MATMUL(TRANSPOSE(T), MATMUL(Kloc, T))
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_B32_FormStiffMatrix

  SUBROUTINE PH_Elem_B32_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(12)
    CALL PH_Elem_B31_LumpMass(coords, rho, M_lumped)
  END SUBROUTINE PH_Elem_B32_LumpMass

  SUBROUTINE PH_Elem_B32_NL_TL(arg)
    TYPE(PH_Elem_B32_NL_TL_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: coords_curr(3, 2)
    REAL(wp) :: e_ref(3), e_curr(3), L_ref, L_curr, lambda, E_GL, S_PK2
    REAL(wp) :: dN_dX(2), B_mat(1, 12), D_tangent
    REAL(wp) :: wt
    INTEGER(i4) :: i
    
    ! Mat constitutive variables
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status

    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO

    DO i = 1, 2
      coords_curr(1, i) = arg%coords_ref(1, i) + arg%lcl%u_elem(6*(i-1)+1)
      coords_curr(2, i) = arg%coords_ref(2, i) + arg%lcl%u_elem(6*(i-1)+2)
      coords_curr(3, i) = arg%coords_ref(3, i) + arg%lcl%u_elem(6*(i-1)+3)
    END DO

    e_ref = arg%coords_ref(:, 2) - arg%coords_ref(:, 1)
    L_ref = SQRT(SUM(e_ref * e_ref))
    IF (L_ref <= 1.0e-12_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "B32 TL: zero reference length"
      RETURN
    END IF
    e_ref = e_ref / L_ref

    e_curr = coords_curr(:, 2) - coords_curr(:, 1)
    L_curr = SQRT(SUM(e_curr * e_curr))
    lambda = L_curr / L_ref
    E_GL = 0.5_wp * (lambda*lambda - ONE)
    
    ! ===== Mat Constitutive Call (TL mode, 1D axial stress) =====
    ss_gp%strain(1) = E_GL
    ss_gp%strain(2:6) = ZERO
    ss_gp%strain_inc(1) = E_GL
    ss_gp%strain_inc(2:6) = ZERO
    ss_gp%sigma = ZERO
    ss_gp%tangent = ZERO
    
    CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(1), ss_gp, mat_status)
    IF (mat_status%status_code /= IF_STATUS_OK) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "B32 TL: Mat constitutive failed"
      RETURN
    END IF
    
    S_PK2 = ss_gp%sigma(1)
    D_tangent = ss_gp%tangent(1,1) * lambda * lambda
    ! ===== End Mat Constitutive Call =====

    dN_dX(1) = -ONE / L_ref
    dN_dX(2) =  ONE / L_ref

    B_mat(1, 1) = dN_dX(1) * e_ref(1)
    B_mat(1, 2) = dN_dX(1) * e_ref(2)
    B_mat(1, 3) = dN_dX(1) * e_ref(3)
    B_mat(1, 7) = dN_dX(2) * e_ref(1)
    B_mat(1, 8) = dN_dX(2) * e_ref(2)
    B_mat(1, 9) = dN_dX(2) * e_ref(3)
    B_mat(1, 4:6) = ZERO
    B_mat(1, 10:12) = ZERO

    wt = L_ref
    arg%evo%Ke_mat(1:3, 1:3) = D_tangent * wt * (dN_dX(1)**2) * MATMUL(RESHAPE(e_ref, [3,1]), RESHAPE(e_ref, [1,3]))
    arg%evo%Ke_mat(1:3, 7:9) = D_tangent * wt * dN_dX(1)*dN_dX(2) * MATMUL(RESHAPE(e_ref, [3,1]), RESHAPE(e_ref, [1,3]))
    arg%evo%Ke_mat(7:9, 1:3) = D_tangent * wt * dN_dX(1)*dN_dX(2) * MATMUL(RESHAPE(e_ref, [3,1]), RESHAPE(e_ref, [1,3]))
    arg%evo%Ke_mat(7:9, 7:9) = D_tangent * wt * (dN_dX(2)**2) * MATMUL(RESHAPE(e_ref, [3,1]), RESHAPE(e_ref, [1,3]))

    arg%evo%Ke_geo(1:3, 1:3) = S_PK2 * wt * (dN_dX(1)**2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(1:3, 7:9) = S_PK2 * wt * dN_dX(1)*dN_dX(2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(7:9, 1:3) = S_PK2 * wt * dN_dX(1)*dN_dX(2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(7:9, 7:9) = S_PK2 * wt * (dN_dX(2)**2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])

    arg%evo%R_int(1:3) = S_PK2 * wt * dN_dX(1) * e_ref
    arg%evo%R_int(7:9) = S_PK2 * wt * dN_dX(2) * e_ref
  END SUBROUTINE PH_Elem_B32_NL_TL

  SUBROUTINE PH_Elem_B32_NL_UL(arg)
    TYPE(PH_Elem_B32_NL_UL_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: coords_curr(3, 2)
    REAL(wp) :: e_prev(3), e_curr(3), L_prev, L_curr, lambda, e_alm, sigma
    REAL(wp) :: dN_dx(2), B_mat(1, 12), D_tangent
    REAL(wp) :: wt
    INTEGER(i4) :: i
    
    ! Mat constitutive variables
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status

    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO

    DO i = 1, 2
      coords_curr(1, i) = arg%coords_prev(1, i) + arg%u_incr(6*(i-1)+1)
      coords_curr(2, i) = arg%coords_prev(2, i) + arg%u_incr(6*(i-1)+2)
      coords_curr(3, i) = arg%coords_prev(3, i) + arg%u_incr(6*(i-1)+3)
    END DO

    e_prev = arg%coords_prev(:, 2) - arg%coords_prev(:, 1)
    L_prev = SQRT(SUM(e_prev * e_prev))
    IF (L_prev <= 1.0e-12_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "B32 UL: zero previous length"
      RETURN
    END IF
    e_prev = e_prev / L_prev

    e_curr = coords_curr(:, 2) - coords_curr(:, 1)
    L_curr = SQRT(SUM(e_curr * e_curr))
    lambda = L_curr / L_prev
    e_alm = 0.5_wp * (ONE - ONE/(lambda*lambda))
    
    ! ===== Mat Constitutive Call (UL mode, 1D axial stress) =====
    ss_gp%strain(1) = e_alm
    ss_gp%strain(2:6) = ZERO
    ss_gp%strain_inc(1) = e_alm
    ss_gp%strain_inc(2:6) = ZERO
    ss_gp%sigma = ZERO
    ss_gp%tangent = ZERO
    
    CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(1), ss_gp, mat_status)
    IF (mat_status%status_code /= IF_STATUS_OK) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "B32 UL: Mat constitutive failed"
      RETURN
    END IF
    
    sigma = ss_gp%sigma(1)
    D_tangent = ss_gp%tangent(1,1)
    ! ===== End Mat Constitutive Call =====

    dN_dx(1) = -ONE / L_prev
    dN_dx(2) =  ONE / L_prev

    B_mat(1, 1) = dN_dx(1) * e_prev(1)
    B_mat(1, 2) = dN_dx(1) * e_prev(2)
    B_mat(1, 3) = dN_dx(1) * e_prev(3)
    B_mat(1, 7) = dN_dx(2) * e_prev(1)
    B_mat(1, 8) = dN_dx(2) * e_prev(2)
    B_mat(1, 9) = dN_dx(2) * e_prev(3)
    B_mat(1, 4:6) = ZERO
    B_mat(1, 10:12) = ZERO

    wt = L_prev
    arg%evo%Ke_mat(1:3, 1:3) = D_tangent * wt * (dN_dx(1)**2) * MATMUL(RESHAPE(e_prev, [3,1]), RESHAPE(e_prev, [1,3]))
    arg%evo%Ke_mat(1:3, 7:9) = D_tangent * wt * dN_dx(1)*dN_dx(2) * MATMUL(RESHAPE(e_prev, [3,1]), RESHAPE(e_prev, [1,3]))
    arg%evo%Ke_mat(7:9, 1:3) = D_tangent * wt * dN_dx(1)*dN_dx(2) * MATMUL(RESHAPE(e_prev, [3,1]), RESHAPE(e_prev, [1,3]))
    arg%evo%Ke_mat(7:9, 7:9) = D_tangent * wt * (dN_dx(2)**2) * MATMUL(RESHAPE(e_prev, [3,1]), RESHAPE(e_prev, [1,3]))

    arg%evo%Ke_geo(1:3, 1:3) = sigma * wt * (dN_dx(1)**2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(1:3, 7:9) = sigma * wt * dN_dx(1)*dN_dx(2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(7:9, 1:3) = sigma * wt * dN_dx(1)*dN_dx(2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])
    arg%evo%Ke_geo(7:9, 7:9) = sigma * wt * (dN_dx(2)**2) * RESHAPE([ONE, ZERO, ZERO, ZERO, ONE, ZERO, ZERO, ZERO, ONE], [3,3])

    arg%evo%R_int(1:3) = sigma * wt * dN_dx(1) * e_prev
    arg%evo%R_int(7:9) = sigma * wt * dN_dx(2) * e_prev
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_B32_NL_UL

  SUBROUTINE UF_Elem_B32_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: coords(3, 2)
    REAL(wp) :: u(12)
    REAL(wp) :: E, nu
    REAL(wp), ALLOCATABLE :: Ke_loc(:,:), Re_loc(:)
    TYPE(MatProperties) :: props

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    nNode = ElemType%numNodes
    nDim = 3_i4
    nDOF = PH_ELEM_B32_NDOF

    IF (nNode /= 2 .OR. ElemType%dim /= 3) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_B32_Calc: expected 2 nodes and ElemType%dim=3')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_B32_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    coords(1:3, 1:2) = Ctx%coords_ref(1:3, 1:2)
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 2) THEN
        u(1:6) = RESHAPE(Ctx%disp_total(1:3, 1:2), [6])
        IF (SIZE(Ctx%disp_total, 1) >= 6) THEN
          u(7:12) = RESHAPE(Ctx%disp_total(4:6, 1:2), [6])
        END IF
      END IF
    END IF

    E = 0.0_wp
    nu = 0.3_wp
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= UF_MAT_PROP_ELA) E = props%props(UF_MAT_PROP_ELA)
      IF (SIZE(props%props) >= UF_MAT_PROP_NU) nu = props%props(UF_MAT_PROP_NU)
    END IF

    IF (E <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B32_Calc: invalid Young modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ALLOCATE(Ke_loc(nDOF, nDOF))
    ALLOCATE(Re_loc(nDOF))
    CALL PH_Elem_B32_FormStiffMatrix_Legacy(coords, E, nu, Ke_loc)
    CALL PH_Elem_B32_FormIntForce_Legacy(coords, u, E, nu, Re_loc)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_B32_NIP)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

    DEALLOCATE(Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_B32_Calc
  
  !===========================================================================
  ! USAGE EXAMPLES AND INTEGRATION NOTES
  !===========================================================================
  !
  ! Example 1: Linear static analysis with structured interface
  ! -----------------------------------------------------------
  !   TYPE(PH_Elem_B32_StiffMatrix_Arg) :: stiff_in
  !   TYPE(PH_Elem_B32_StiffMatrix_Arg) :: stiff_out
  !   
  !   stiff_in%coords = coords_array
  !   stiff_in%E_young = 2.1e11_wp  ! Steel [Pa]
  !   stiff_in%nu = 0.3_wp
  !   stiff_in%area = 0.01_wp       ! 100 cm²
  !   stiff_in%Iy = 8.33e-6_wp      ! Iy [m⁴]
  !   stiff_in%Iz = 8.33e-6_wp      ! Iz [m⁴]
  !   stiff_in%J_torsion = 1.67e-5_wp  ! J [m⁴]
  !   
  !   CALL PH_Elem_B32_FormStiffMatrix(stiff_in, stiff_out)
  !   IF (stiff_out%status%status_code == IF_STATUS_OK) THEN
  !     ! Use stiff_out%Ke in global assembly
  !   END IF
  !
  ! Example 2: Nonlinear geometry with Total Lagrangian formulation
  ! ---------------------------------------------------------------
  !   TYPE(PH_Elem_B32_NL_TL_Arg) :: tl_in
  !   TYPE(PH_Elem_B32_NL_TL_Arg) :: tl_out
  !   
  !   tl_in%coords_ref = initial_coords
  !   tl_in%u_elem = total_displacements
  !   tl_in%mat_prop = material_descriptor
  !   tl_in%area = section_area
  !   tl_in%Iy = Iy_inertia
  !   tl_in%Iz = Iz_inertia
  !   tl_in%n_section_pts = 3  ! Gauss points through cross-section
  !   
  !   CALL PH_Elem_B32_NL_TL(tl_in, tl_out)
  !   ! Returns: tl_out%Ke_mat, tl_out%Ke_geo, tl_out%R_int
  !
  ! Example 3: Dynamic analysis - consistent mass matrix
  ! ----------------------------------------------------
  !   REAL(wp) :: Me(12, 12)
  !   CALL PH_Elem_B32_ConsMass(coords, density, Me)
  !   ! Me includes both translational and rotary inertia
  !
  ! Integration with UFC L3_MD layer:
  ! ----------------------------------
  !   The UF_Elem_B32_Calc subroutine provides the bridge to L3_MD:
  !   - ElemType: Element topology descriptor (2 nodes, 3D)
  !   - ElemCtx: Context with coordinates and displacements
  !   - MatProperties: Material parameters (E, ν, ρ, section props)
  !   - ElemState: Output storage for Ke, Re, Me, Ce
  !   - ElemFlags: Status flags and cutback indicators
  !
  ! Performance notes:
  ! ------------------
  !   - Local coordinate transformation dominates FLOP count
  !   - T matrix construction: O(1) but frequent access
  !   - Matrix multiplication: Tᵀ·Kloc·T can be optimized for sparse T
  !   - For repeated calls: Precompute and cache T if coords unchanged
  !
  ! Verification benchmarks:
  ! ------------------------
  !   1. Cantilever beam: Tip displacement δ = PL³/(3EI)
  !   2. Simply supported beam: Center deflection δ = 5qL?(384EI)
  !   3. Axial bar: Elongation ΔL = FL/(EA)
  !   4. Circular shaft: Twist angle θ = TL/(GJ)
  !
  ! Future extensions (TODO):
  ! -------------------------
  !   - B32T: Add temperature DOF for thermo-mechanical coupling
  !   - Plasticity: Multi-point cross-section integration
  !   - Shear deformation: Timoshenko beam theory (currently Euler-Bernoulli)
  !   - Large rotation: Co-rotational formulation for large rotations
  !   - Composite sections: Layered cross-section model
  !===========================================================================
  
END MODULE PH_Elem_B32
