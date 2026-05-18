!===============================================================================
! MODULE: PH_Elem_B22
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B22 element kernel for 2D Euler-Bernoulli beam (quadratic)
!===============================================================================
MODULE PH_Elem_B22
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
  
  IMPLICIT NONE
  PRIVATE
  
  !===========================================================================
  ! Public Constants - Element DOF information
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B22_NNODE  = 3_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B22_NIP    = 2_i4   ! Integration points (axial)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B22_NDOF   = 9_i4   ! Total DOF (per element)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B22_NEDGE  = 0_i4   ! Number of edges
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B22_PROP_E     = 1_i4   ! Young's modulus index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B22_PROP_NU    = 2_i4   ! Poisson's ratio index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B22_PROP_A     = 3_i4   ! Area index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B22_PROP_I     = 4_i4   ! Inertia index
  
  ! Numerical tolerance for convergence checks
  REAL(wp), PARAMETER, PRIVATE :: PH_B22_TOL = 1.0e-8_wp
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B22_DefInit                ! Element definition initialization
  PUBLIC :: PH_Elem_B22_FormStiffMatrix        ! Linear stiffness (small def)
  PUBLIC :: PH_Elem_B22_FormStiffMatrixWithSection  ! Form stiffness with section props
  PUBLIC :: PH_Elem_B22_FormIntForce           ! Internal force vector
  PUBLIC :: PH_Elem_B22_ConsMass               ! Consistent mass matrix
  PUBLIC :: PH_Elem_B22_ConsMassWithSection    ! Consistent mass with section
  PUBLIC :: PH_Elem_B22_LumpMass               ! Lump mass vector
  PUBLIC :: PH_Elem_B22_LumpMassWithSection    ! Lump mass with section
  PUBLIC :: UF_Elem_B22_Calc                   ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B22_DefInit(ElemDef, status)
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B22 element definition descriptor
    ! Args:
    !   ElemDef (inout): Element definition to initialize
    !   status  (out)  : Error status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ElemDef%numNodes = PH_ELEM_B22_NNODE
    ElemDef%dim = 2_i4
    ElemDef%dofPerNode = 3_i4  ! u_x, u_y, theta_z
    ElemDef%totalDOF = PH_ELEM_B22_NDOF
    ElemDef%name = 'B22'
    ElemDef%cfg%description = '3-node 2D beam with quadratic interpolation'
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B22_DefInit

  !===========================================================================
  ! Consistent Mass Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B22_ConsMassWithSection(coords, rho, area, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B22 beam element
    !          Translational DOF only (rotary inertia neglected in 2D beam)
    ! Args:
    !   coords (in)  : 3x3 nodal coordinates (x,y,z for 3 nodes)
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   Me     (out) : 9x9 consistent mass matrix
    ! Theory:
    !   Consistent mass: M = integral(rho * N^T * N dV)
    !   For 2D beam: only translational DOF (u_x, u_y) considered
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me(9, 9)
    REAL(wp) :: x1(2), x2(2), x3(2)
    REAL(wp) :: dx12(2), dx23(2), L12, L23, L_total
    REAL(wp) :: m_bar, xi_vals(2), w_vals(2)
    INTEGER(i4) :: i, j, ip
    
    Me = ZERO
    
    ! Extract 2D coordinates for 3 nodes
    x1(1) = coords(1, 1); x1(2) = coords(2, 1)  ! Node 1
    x2(1) = coords(1, 2); x2(2) = coords(2, 2)  ! Node 2 (corner)
    x3(1) = coords(1, 3); x3(2) = coords(2, 3)  ! Node 3 (mid-side)
    
    ! Compute total element length (approximate as sum of two segments)
    dx12 = x2 - x1
    dx23 = x3 - x2
    L12 = SQRT(dx12(1)*dx12(1) + dx12(2)*dx12(2))
    L23 = SQRT(dx23(1)*dx23(1) + dx23(2)*dx23(2))
    L_total = L12 + L23
    
    IF (L_total <= 1.0e-12_wp) RETURN
    
    ! Gauss integration for consistent mass
    ! 2-point Gauss quadrature: ξ = ±1/√3, w = 1
    xi_vals = [-ONE/SQRT(3.0_wp), ONE/SQRT(3.0_wp)]
    w_vals = [ONE, ONE]
    
    DO ip = 1, 2
      REAL(wp) :: xi, detJ, weight
      REAL(wp) :: N_u(3), N_v(3)  ! Shape functions for axial/transverse
      REAL(wp) :: M_ip(9, 9)
      
      xi = xi_vals(ip)
      weight = w_vals(ip)
      
      ! Quadratic shape functions for 3-node line element
      ! Axial displacement: u(ξ) = N1*u1 + N2*u2 + N3*u3
      N_u(1) = -HALF*xi*(ONE - xi)  ! Node 1
      N_u(2) =  HALF*xi*(ONE + xi)  ! Node 2
      N_u(3) =  ONE - xi*xi          ! Node 3 (mid-side)
      
      ! Transverse displacement uses same shape functions
      N_v = N_u
      
      ! Jacobian determinant (assuming uniform spacing)
      detJ = L_total / 2.0_wp
      
      ! Consistent mass contribution at this IP
      m_bar = rho * area * detJ * weight
      
      ! Assemble mass matrix (translational DOF only)
      ! DOF mapping: 1,2=u1,v1; 4,5=u2,v2; 7,8=u3,v3
      DO i = 1, 3
        DO j = 1, 3
          ! u-u coupling
          Me((i-1)*3+1, (j-1)*3+1) = Me((i-1)*3+1, (j-1)*3+1) + &
                                     m_bar * N_u(i) * N_u(j)
          ! v-v coupling
          Me((i-1)*3+2, (j-1)*3+2) = Me((i-1)*3+2, (j-1)*3+2) + &
                                     m_bar * N_v(i) * N_v(j)
        END DO
      END DO
    END DO
    
    ! Note: Rotary inertia (DOF 3, 6, 9) not included in this formulation
  END SUBROUTINE PH_Elem_B22_ConsMassWithSection

  !===========================================================================
  ! Stiffness Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B22_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 9x9 stiffness matrix for B22 beam element
    !          Includes axial and bending contributions with quadratic interpolation
    ! Args:
    !   coords   (in) : 3x3 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia about z-axis
    !   Ke       (out): 9x9 element stiffness matrix
    ! Theory:
    !   K = K_axial + K_bending
    !   K_axial: EA/L with quadratic displacement field
    !   K_bending: Curvature from quadratic rotation field
    !   Transformation: T^T * K_local * T
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: area, I_bend
    REAL(wp), INTENT(OUT) :: Ke(9, 9)
    REAL(wp) :: x1(2), x2(2), x3(2)
    REAL(wp) :: dx(2), L, c, s
    REAL(wp) :: E, A, I
    REAL(wp) :: Kloc(9, 9), T(9, 9)
    INTEGER(i4) :: i, j
    
    Ke = ZERO
    
    ! Extract 2D coordinates
    x1(1) = coords(1, 1); x1(2) = coords(2, 1)  ! Node 1
    x2(1) = coords(1, 2); x2(2) = coords(2, 2)  ! Node 2
    x3(1) = coords(1, 3); x3(2) = coords(2, 3)  ! Node 3
    
    ! Compute element length and orientation
    dx = x2 - x1  ! Using end nodes for length
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) THEN
      Ke(1, 1) = ONE  ! Prevent singularity
      RETURN
    END IF
    
    ! Direction cosines
    c = dx(1) / L
    s = dx(2) / L
    
    E = E_young
    A = area
    I = I_bend
    
    ! Initialize local stiffness and transformation matrices
    Kloc = ZERO
    T = ZERO
    
    ! =====================================================
    ! Local stiffness matrix (9x9) in element coordinates
    ! =====================================================
    
    ! --- Axial stiffness (quadratic) ---
    ! k_axial = EA/L * [7/3, 1/6, -8/3; 1/6, 7/3, -8/3; -8/3, -8/3, 16/3]
    REAL(wp) :: k_axial
    k_axial = E * A / L
    
    Kloc(1, 1) = k_axial * 7.0_wp / 3.0_wp
    Kloc(1, 4) = k_axial * 1.0_wp / 6.0_wp
    Kloc(1, 7) = -k_axial * 8.0_wp / 3.0_wp
    Kloc(4, 1) = Kloc(1, 4)
    Kloc(4, 4) = k_axial * 7.0_wp / 3.0_wp
    Kloc(4, 7) = -k_axial * 8.0_wp / 3.0_wp
    Kloc(7, 1) = Kloc(1, 7)
    Kloc(7, 4) = Kloc(4, 7)
    Kloc(7, 7) = k_axial * 16.0_wp / 3.0_wp
    
    ! --- Bending stiffness (quadratic rotation field) ---
    ! Based on quadratic Timoshenko beam formulation
    ! Simplified: EI/L³ coefficients for 3-node beam
    REAL(wp) :: k_bend
    k_bend = E * I / L**3
    
    ! Node 1 (DOF 2, 3)
    Kloc(2, 2) = k_bend * 12.0_wp
    Kloc(2, 3) = k_bend * 6.0_wp * L
    Kloc(2, 5) = -k_bend * 12.0_wp
    Kloc(2, 6) = k_bend * 6.0_wp * L
    Kloc(2, 8) = -k_bend * 24.0_wp
    Kloc(3, 2) = Kloc(2, 3)
    Kloc(3, 3) = k_bend * 4.0_wp * L**2
    Kloc(3, 5) = -k_bend * 6.0_wp * L
    Kloc(3, 6) = k_bend * 2.0_wp * L**2
    Kloc(3, 8) = -k_bend * 12.0_wp * L
    Kloc(5, 2) = Kloc(2, 5)
    Kloc(5, 3) = Kloc(3, 5)
    Kloc(5, 5) = k_bend * 12.0_wp
    Kloc(5, 6) = -k_bend * 6.0_wp * L
    Kloc(5, 8) = k_bend * 24.0_wp
    Kloc(6, 2) = Kloc(2, 6)
    Kloc(6, 3) = Kloc(3, 6)
    Kloc(6, 5) = Kloc(5, 6)
    Kloc(6, 6) = k_bend * 4.0_wp * L**2
    Kloc(6, 8) = -k_bend * 12.0_wp * L
    Kloc(8, 2) = Kloc(2, 8)
    Kloc(8, 3) = Kloc(3, 8)
    Kloc(8, 5) = Kloc(5, 8)
    Kloc(8, 6) = Kloc(6, 8)
    Kloc(8, 8) = k_bend * 48.0_wp
    
    ! Mid-side node coupling (simplified for quadratic interpolation)
    Kloc(7, 2) = -k_bend * 24.0_wp
    Kloc(7, 3) = -k_bend * 12.0_wp * L
    Kloc(7, 5) = k_bend * 24.0_wp
    Kloc(7, 6) = -k_bend * 12.0_wp * L
    Kloc(7, 8) = k_bend * 96.0_wp
    Kloc(8, 7) = Kloc(7, 8)
    
    ! =====================================================
    ! Transformation matrix (9x9) from local to global
    ! =====================================================
    ! For 2D beam: T rotates each node by angle θ
    ! T = diag([R, R, R]) where R = [[c, s, 0], [-s, c, 0], [0, 0, 1]]
    
    DO i = 1, 3
      T((i-1)*3+1, (i-1)*3+1) = c
      T((i-1)*3+1, (i-1)*3+2) = s
      T((i-1)*3+2, (i-1)*3+1) = -s
      T((i-1)*3+2, (i-1)*3+2) = c
      T((i-1)*3+3, (i-1)*3+3) = ONE
    END DO
    
    ! Transform to global coordinates: K_global = T^T * K_local * T
    Ke = MATMUL(MATMUL(TRANSPOSE(T), Kloc), T)
    
  END SUBROUTINE PH_Elem_B22_FormStiffMatrixWithSection

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B22_FormIntForce(coords, u, E_young, nu, area, I_bend, R_int)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    ! Args:
    !   coords   (in) : 3x3 nodal coordinates
    !   u        (in) : 9x1 displacement vector
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia
    !   R_int    (out): 9x1 internal force vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: u(9)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend
    REAL(wp), INTENT(OUT) :: R_int(9)
    REAL(wp) :: Ke(9, 9)
    
    R_int = ZERO
    
    ! Compute stiffness and multiply by displacements
    CALL PH_Elem_B22_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    R_int = MATMUL(Ke, u)
    
  END SUBROUTINE PH_Elem_B22_FormIntForce

  !===========================================================================
  ! Lumped Mass Vector Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B22_LumpMassWithSection(coords, rho, area, M_lump)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector for B22 beam element
    !          Using HRZ (Hinton-Rock-Zienkiewicz) lumping technique
    ! Args:
    !   coords (in)  : 3x3 nodal coordinates
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   M_lump (out) : 9x1 lumped mass vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lump(9)
    REAL(wp) :: x1(2), x2(2), x3(2)
    REAL(wp) :: L12, L23, L_total, m_total
    
    M_lump = ZERO
    
    ! Extract coordinates
    x1(1) = coords(1, 1); x1(2) = coords(2, 1)
    x2(1) = coords(1, 2); x2(2) = coords(2, 2)
    x3(1) = coords(1, 3); x3(2) = coords(2, 3)
    
    ! Compute segment lengths
    L12 = SQRT((x2(1)-x1(1))**2 + (x2(2)-x1(2))**2)
    L23 = SQRT((x3(1)-x2(1))**2 + (x3(2)-x2(2))**2)
    L_total = L12 + L23
    
    IF (L_total <= 1.0e-12_wp) RETURN
    
    ! Total mass
    m_total = rho * area * L_total
    
    ! Lumped mass distribution (HRZ technique for quadratic elements)
    ! Corner nodes: 1/6 of total mass each
    ! Mid-side node: 2/3 of total mass
    M_lump(1) = m_total / 6.0_wp  ! Node 1 u_x
    M_lump(2) = m_total / 6.0_wp  ! Node 1 u_y
    M_lump(4) = m_total / 6.0_wp  ! Node 2 u_x
    M_lump(5) = m_total / 6.0_wp  ! Node 2 u_y
    M_lump(7) = 2.0_wp * m_total / 3.0_wp  ! Node 3 u_x
    M_lump(8) = 2.0_wp * m_total / 3.0_wp  ! Node 3 u_y
    
    ! Note: Rotary inertia not included
  END SUBROUTINE PH_Elem_B22_LumpMassWithSection

  !===========================================================================
  ! Unified Element Calculation Interface (Structured IO)
  !===========================================================================
  SUBROUTINE UF_Elem_B22_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B22
    ! Interface: Legacy (to be migrated to structured *_Arg pattern)
    ! Args: See UFC L4_PH standard interface
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ElemFormul), INTENT(IN) :: formul
    TYPE(ElemCtx), INTENT(IN) :: ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: mat_props
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    
    ! TODO: Implement full UF_Elem_B22_Calc logic
    ! - Prepare storage
    ! - Call form stiffness/internal force
    ! - Handle nonlinear geometry if needed
    ! - Update state variables
    
    flags%failed = .FALSE.
    
  END SUBROUTINE UF_Elem_B22_Calc

END MODULE PH_Elem_B22