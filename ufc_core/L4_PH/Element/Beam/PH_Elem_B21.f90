!===============================================================================
! MODULE: PH_Elem_B21
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B21 element kernel for 2D Euler-Bernoulli beam
!===============================================================================
MODULE PH_Elem_B21
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
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B21_NNODE  = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B21_NIP    = 1_i4   ! Integration points
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B21_NDOF   = 6_i4   ! Total DOF (per element)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B21_NEDGE  = 0_i4   ! Number of edges
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21_PROP_E     = 1_i4   ! Young's modulus index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21_PROP_NU    = 2_i4   ! Poisson's ratio index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21_PROP_A     = 3_i4   ! Area index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21_PROP_I     = 4_i4   ! Inertia index
  
  ! Numerical tolerance for convergence checks
  REAL(wp), PARAMETER, PRIVATE :: PH_B21_TOL = 1.0e-8_wp
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B21_DefInit                ! Element definition initialization
  PUBLIC :: PH_Elem_B21_FormStiffMatrix        ! Linear stiffness (small def)
  PUBLIC :: PH_Elem_B21_FormStiffMatrixWithSection  ! Form stiffness with section props
  PUBLIC :: PH_Elem_B21_FormIntForce           ! Internal force vector
  PUBLIC :: PH_Elem_B21_ConsMass               ! Consistent mass matrix
  PUBLIC :: PH_Elem_B21_ConsMassWithSection    ! Consistent mass with section
  PUBLIC :: PH_Elem_B21_LumpMass               ! Lump mass vector
  PUBLIC :: PH_Elem_B21_LumpMassWithSection    ! Lump mass with section
  PUBLIC :: UF_Elem_B21_Calc                   ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B21_DefInit(ElemDef, status)
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B21 element definition descriptor
    ! Args:
    !   ElemDef (inout): Element definition to initialize
    !   status  (out)  : Error status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ElemDef%numNodes = PH_ELEM_B21_NNODE
    ElemDef%dim = 2_i4
    ElemDef%dofPerNode = 3_i4  ! u_x, u_y, theta_z
    ElemDef%totalDOF = PH_ELEM_B21_NDOF
    ElemDef%name = 'B21'
    ElemDef%cfg%description = '2-node 2D beam with linear interpolation'
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B21_DefInit

  !===========================================================================
  ! Stiffness Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B21_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 stiffness matrix for B21 beam element
    !          Includes axial and bending contributions
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia about z-axis
    !   Ke       (out): 6x6 element stiffness matrix
    ! Theory:
    !   K = K_axial + K_bending
    !   K_axial = EA/L (bar action)
    !   K_bending = Classical Euler-Bernoulli beam coefficients
    !   Transformation: T^T * K_local * T
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: area, I_bend
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, c, s
    REAL(wp) :: E, A, I
    REAL(wp) :: Kloc(6, 6), T(6, 6)
    
    Ke = ZERO
    
    ! Extract 2D coordinates and compute length
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
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
    ! Local stiffness matrix (6x6) in element coordinates
    ! =====================================================
    
    ! --- Axial stiffness ---
    Kloc(1, 1) =  E * A / L
    Kloc(1, 4) = -E * A / L
    Kloc(4, 1) =  Kloc(1, 4)
    Kloc(4, 4) =  E * A / L
    
    ! --- Bending stiffness ---
    ! Coefficients from classical beam theory
    Kloc(2, 2) =  12.0_wp * E * I / L**3
    Kloc(2, 3) =   6.0_wp * E * I / L**2
    Kloc(2, 5) = -12.0_wp * E * I / L**3
    Kloc(2, 6) =   6.0_wp * E * I / L**2
    
    Kloc(3, 2) =   Kloc(2, 3)
    Kloc(3, 3) =   4.0_wp * E * I / L
    Kloc(3, 5) =  -6.0_wp * E * I / L**2
    Kloc(3, 6) =   2.0_wp * E * I / L
    
    Kloc(5, 2) =   Kloc(2, 5)
    Kloc(5, 3) =   Kloc(3, 5)
    Kloc(5, 5) =   12.0_wp * E * I / L**3
    Kloc(5, 6) =  -6.0_wp * E * I / L**2
    
    Kloc(6, 2) =   Kloc(2, 6)
    Kloc(6, 3) =   Kloc(3, 6)
    Kloc(6, 5) =   Kloc(5, 6)
    Kloc(6, 6) =   4.0_wp * E * I / L
    
    ! =====================================================
    ! Transformation matrix (6x6) from local to global
    ! =====================================================
    ! For 2D beam: T rotates each node by angle θ
    ! T = diag([R, R]) where R = [[c, s, 0], [-s, c, 0], [0, 0, 1]]
    
    T(1, 1) = c
    T(1, 2) = s
    T(2, 1) = -s
    T(2, 2) = c
    T(3, 3) = ONE
    
    T(4, 4) = c
    T(4, 5) = s
    T(5, 4) = -s
    T(5, 5) = c
    T(6, 6) = ONE
    
    ! Transform to global coordinates: K_global = T^T * K_local * T
    Ke = MATMUL(MATMUL(TRANSPOSE(T), Kloc), T)
    
  END SUBROUTINE PH_Elem_B21_FormStiffMatrixWithSection

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B21_FormIntForce(coords, u, E_young, nu, area, I_bend, R_int)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   u        (in) : 6x1 displacement vector
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia
    !   R_int    (out): 6x1 internal force vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: Ke(6, 6)
    
    R_int = ZERO
    
    ! Compute stiffness and multiply by displacements
    CALL PH_Elem_B21_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    R_int = MATMUL(Ke, u)
    
  END SUBROUTINE PH_Elem_B21_FormIntForce

  !===========================================================================
  ! Consistent Mass Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B21_ConsMassWithSection(coords, rho, area, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B21 beam element
    !          Translational DOF only (rotary inertia neglected in 2D beam)
    ! Args:
    !   coords (in)  : 3x2 nodal coordinates (x,y,z for 2 nodes)
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   Me     (out) : 6x6 consistent mass matrix
    ! Theory:
    !   Consistent mass: M = integral(rho * N^T * N dV)
    !   For 2D beam: only translational DOF (u_x, u_y) considered
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_bar
    
    Me = ZERO
    
    ! Extract 2D coordinates and compute length
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) RETURN
    
    ! Consistent mass coefficients (translational DOF only)
    m_bar = rho * area * L / 6.0_wp
    
    ! Node 1 translational DOF (u_x=1, u_y=2)
    Me(1, 1) = 2.0_wp * m_bar
    Me(2, 2) = 2.0_wp * m_bar
    
    ! Node 2 translational DOF (u_x=4, u_y=5)
    Me(4, 4) = 2.0_wp * m_bar
    Me(5, 5) = 2.0_wp * m_bar
    
    ! Coupling terms (node 1 - node 2)
    Me(1, 4) = m_bar
    Me(2, 5) = m_bar
    Me(4, 1) = m_bar
    Me(5, 2) = m_bar
    
    ! Note: Rotary inertia (DOF 3, 6) not included in this formulation
  END SUBROUTINE PH_Elem_B21_ConsMassWithSection

  !===========================================================================
  ! Lumped Mass Vector Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B21_LumpMassWithSection(coords, rho, area, M_lump)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector for B21 beam element
    !          Using HRZ (Hinton-Rock-Zienkiewicz) lumping technique
    ! Args:
    !   coords (in)  : 3x2 nodal coordinates
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   M_lump (out) : 6x1 lumped mass vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lump(6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_total
    
    M_lump = ZERO
    
    ! Extract coordinates and compute length
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) RETURN
    
    ! Total mass
    m_total = rho * area * L
    
    ! Lumped mass distribution (HRZ technique)
    ! Each node gets half the total mass
    M_lump(1) = m_total / 2.0_wp  ! Node 1 u_x
    M_lump(2) = m_total / 2.0_wp  ! Node 1 u_y
    M_lump(4) = m_total / 2.0_wp  ! Node 2 u_x
    M_lump(5) = m_total / 2.0_wp  ! Node 2 u_y
    
    ! Note: Rotary inertia not included
  END SUBROUTINE PH_Elem_B21_LumpMassWithSection

  !===========================================================================
  ! Unified Element Calculation Interface (Structured IO)
  !===========================================================================
  SUBROUTINE UF_Elem_B21_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B21
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
    
    ! TODO: Implement full UF_Elem_B21_Calc logic
    ! - Prepare storage
    ! - Call form stiffness/internal force
    ! - Handle nonlinear geometry if needed
    ! - Update state variables
    
    flags%failed = .FALSE.
    
  END SUBROUTINE UF_Elem_B21_Calc

END MODULE PH_Elem_B21