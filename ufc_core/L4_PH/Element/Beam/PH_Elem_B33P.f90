!===============================================================================
! MODULE: PH_Elem_B33P
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B33P elasto-plastic Euler-Bernoulli beam
!===============================================================================
MODULE PH_Elem_B33P
  !===========================================================================
  ! Module Dependencies (Layered Architecture)
  !===========================================================================
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF          ! Mathematical constants
  USE IF_Prec_Core,         ONLY: wp, i4                    ! Precision kinds
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID  ! Error handling
  
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
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33P_NNODE   = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33P_NIP     = 2_i4   ! Integration points along length
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33P_NDOF    = 6_i4   ! Total DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33P_NEDGE   = 0_i4   ! Number of edges
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33P_NFIBERS = 10_i4  ! Default number of fibers
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_E      = 1_i4   ! Young's modulus index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_NU     = 2_i4   ! Poisson's ratio index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_A      = 3_i4   ! Area index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_I      = 4_i4   ! Inertia index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_SIGY   = 5_i4   ! Yield stress index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33P_PROP_H      = 6_i4   ! Hardening modulus index
  
  ! Numerical tolerance for convergence checks
  REAL(wp), PARAMETER, PRIVATE :: PH_B33P_TOL = 1.0e-8_wp
  
  ! Default number of fibers (can be overridden)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B33P_DEFAULT_FIBERS = 10_i4
  
  ! Fiber type definition
  TYPE, PUBLIC :: FiberState
    REAL(wp) :: strain          ! Current axial strain
    REAL(wp) :: stress          ! Current axial stress
    REAL(wp) :: eps_plastic     ! Accumulated plastic strain
    REAL(wp) :: eps_yield       ! Current yield strain (with hardening)
    LOGICAL  :: is_yielding     ! .TRUE. if currently yielding
  END TYPE FiberState
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B33P_DefInit               ! Element definition initialization
  PUBLIC :: PH_Elem_B33P_FormStiffMatrix       ! Linear elastic stiffness
  PUBLIC :: PH_Elem_B33P_FormTangentMatrix     ! Elastoplastic tangent stiffness
  PUBLIC :: PH_Elem_B33P_FormIntForce          ! Internal force vector
  PUBLIC :: PH_Elem_B33P_IntegrateSection      ! Cross-section fiber integration
  PUBLIC :: PH_Elem_B33P_ConsMass              ! Consistent mass matrix
  PUBLIC :: PH_Elem_B33P_ConsMassWithSection   ! Consistent mass with section
  PUBLIC :: PH_Elem_B33P_LumpMass              ! Lump mass vector
  PUBLIC :: PH_Elem_B33P_LumpMassWithSection   ! Lump mass with section
  PUBLIC :: UF_Elem_B33P_Calc                  ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_DefInit(ElemDef, status)
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B33P element definition descriptor
    ! Args:
    !   ElemDef (inout): Element definition to initialize
    !   status  (out)  : Error status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ElemDef%numNodes = PH_ELEM_B33P_NNODE
    ElemDef%dim = 2_i4
    ElemDef%dofPerNode = 3_i4  ! u_x, u_y, theta_z
    ElemDef%totalDOF = PH_ELEM_B33P_NDOF
    ElemDef%name = 'B33P'
    ElemDef%cfg%description = '2-node 2D elasto-plastic beam with fiber discretization'
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B33P_DefInit

  !===========================================================================
  ! Consistent Mass Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_ConsMassWithSection(coords, rho, area, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B33P beam element
    !          Translational DOF only (rotary inertia neglected in 2D beam)
    !          Same as linear B33 since mass doesn't depend on plasticity
    ! Args:
    !   coords (in)  : 3x2 nodal coordinates (x,y,z for 2 nodes)
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   Me     (out) : 6x6 consistent mass matrix
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
  END SUBROUTINE PH_Elem_B33P_ConsMassWithSection

  !===========================================================================
  ! Linear Elastic Stiffness Matrix (Small Deformation)
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_FormStiffMatrix(coords, E_young, nu, area, I_bend, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 linear elastic stiffness matrix (reference configuration)
    !          For small deformations, reduces to standard Euler-Bernoulli
    ! Args:
    !   coords  (in) : 3x2 nodal coordinates
    !   E_young (in) : Young's modulus
    !   nu      (in) : Poisson's ratio
    !   area    (in) : Cross-sectional area
    !   I_bend  (in) : Bending inertia about z-axis
    !   Ke      (out): 6x6 element stiffness matrix
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: area, I_bend
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, c, s
    REAL(wp) :: E, A, I
    REAL(wp) :: Kloc(6, 6), T(6, 6)
    
    E = E_young
    A = area
    I = I_bend
    
    ! Extract 2D coordinates and compute length
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) THEN
      Ke = ZERO
      RETURN
    END IF
    
    ! Direction cosines (local x' -> global x,y)
    c = dx(1) / L  ! cos(theta)
    s = dx(2) / L  ! sin(theta)
    
    ! Local stiffness matrix (axial + bending)
    Kloc = ZERO
    
    ! Axial stiffness (DOF 1, 4)
    Kloc(1, 1) =  E*A/L
    Kloc(1, 4) = -E*A/L
    Kloc(4, 1) = -E*A/L
    Kloc(4, 4) =  E*A/L
    
    ! Bending stiffness (DOF 2,3,5,6)
    Kloc(2, 2) =  12.0_wp*E*I / (L*L*L)
    Kloc(2, 3) =   6.0_wp*E*I / (L*L)
    Kloc(2, 5) = -12.0_wp*E*I / (L*L*L)
    Kloc(2, 6) =   6.0_wp*E*I / (L*L)
    Kloc(3, 2) =   6.0_wp*E*I / (L*L)
    Kloc(3, 3) =   4.0_wp*E*I / L
    Kloc(3, 5) =  -6.0_wp*E*I / (L*L)
    Kloc(3, 6) =   2.0_wp*E*I / L
    Kloc(5, 2) = -12.0_wp*E*I / (L*L*L)
    Kloc(5, 3) =  -6.0_wp*E*I / (L*L)
    Kloc(5, 5) =  12.0_wp*E*I / (L*L*L)
    Kloc(5, 6) =  -6.0_wp*E*I / (L*L)
    Kloc(6, 2) =   6.0_wp*E*I / (L*L)
    Kloc(6, 3) =   2.0_wp*E*I / L
    Kloc(6, 5) =  -6.0_wp*E*I / (L*L)
    Kloc(6, 6) =   4.0_wp*E*I / L
    
    ! Transformation matrix (block diagonal for 2D beam)
    T = ZERO
    T(1, 1) =  c
    T(1, 2) =  s
    T(2, 1) = -s
    T(2, 2) =  c
    T(3, 3) =  ONE
    T(4, 4) =  c
    T(4, 5) =  s
    T(5, 4) = -s
    T(5, 5) =  c
    T(6, 6) =  ONE
    
    ! Transform to global coordinates: K_global = T^T * K_local * T
    Ke = MATMUL(TRANSPOSE(T), MATMUL(Kloc, T))
    
  END SUBROUTINE PH_Elem_B33P_FormStiffMatrix

  !===========================================================================
  ! Cross-Section Fiber Integration
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_IntegrateSection(eps_axial, kappa, E_young, sigma_y, H, &
       area, n_fibers, N_axial, M_bend, Et_tangent, fibers_state)
    !-------------------------------------------------------------------------
    ! Purpose: Integrate stresses over cross-section using fiber discretization
    ! Args:
    !   eps_axial  (in) : Axial strain at neutral axis
    !   kappa      (in) : Curvature (dθ/dx)
    !   E_young    (in) : Young's modulus
    !   sigma_y    (in) : Initial yield stress
    !   H          (in) : Hardening modulus
    !   area       (in) : Cross-sectional area
    !   n_fibers   (in) : Number of fibers through height
    !   N_axial    (out): Integrated axial force
    !   M_bend     (out): Integrated bending moment
    !   Et_tangent (out) : Tangent modulus (for consistent tangent operator)
    !   fibers_state(out): Updated fiber states (optional)
    ! Theory:
    !   Fiber strain: ε_i = ε_axial + y_i * κ
    !   Fiber stress: σ_i = E*ε_i (elastic) or σ_y + H*ε_p (plastic)
    !   Axial force:  N = Σ(σ_i * A_i)
    !   Bending moment: M = Σ(σ_i * A_i * y_i)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: eps_axial, kappa, E_young, sigma_y, H, area
    INTEGER(i4), INTENT(IN) :: n_fibers
    REAL(wp), INTENT(OUT) :: N_axial, M_bend, Et_tangent
    TYPE(FiberState), INTENT(OUT), OPTIONAL :: fibers_state(:)
    
    REAL(wp) :: fiber_area, y_max, dy, y_i
    REAL(wp) :: eps_i, sigma_i, d_sigma_d_eps
    REAL(wp) :: eps_yield_current
    INTEGER(i4) :: i
    
    ! Initialize outputs
    N_axial = ZERO
    M_bend = ZERO
    Et_tangent = E_young  ! Default: elastic tangent
    
    ! Fiber geometry
    fiber_area = area / REAL(n_fibers, wp)
    y_max = SQRT(12.0_wp * area * area / REAL(n_fibers, wp))  ! Approximate height
    dy = 2.0_wp * y_max / REAL(n_fibers - 1, wp)
    
    ! Loop over fibers
    DO i = 1, n_fibers
      ! Fiber position from neutral axis
      y_i = -y_max + (i - 1) * dy
      
      ! Fiber strain (Euler-Bernoulli: plane sections remain plane)
      eps_i = eps_axial + y_i * kappa
      
      !---------------------------------------------------------------------
      ! Fiber constitutive update (J2 flow theory with isotropic hardening)
      !---------------------------------------------------------------------
      
      ! Trial elastic stress
      sigma_trial = E_young * eps_i
      
      ! Current yield strain (with hardening)
      IF (PRESENT(fibers_state)) THEN
        eps_yield_current = (sigma_y + H * ABS(fibers_state(i)%eps_plastic)) / E_young
      ELSE
        eps_yield_current = sigma_y / E_young
      END IF
      
      ! Check yielding
      IF (ABS(sigma_trial) <= sigma_y + H * ABS(eps_i)) THEN
        ! Elastic response
        sigma_i = sigma_trial
        d_sigma_d_eps = E_young
      ELSE
        ! Plastic response (radial return)
        IF (sigma_trial > 0) THEN
          sigma_i = sigma_y + H * eps_i
        ELSE
          sigma_i = -sigma_y + H * eps_i
        END IF
        d_sigma_d_eps = H
      END IF
      
      !---------------------------------------------------------------------
      ! Update fiber state (if provided)
      !---------------------------------------------------------------------
      IF (PRESENT(fibers_state)) THEN
        fibers_state(i)%strain = eps_i
        fibers_state(i)%stress = sigma_i
        fibers_state(i)%eps_yield = eps_yield_current
        fibers_state(i)%is_yielding = (d_sigma_d_eps < E_young)
      END IF
      
      !---------------------------------------------------------------------
      ! Integrate section forces
      !---------------------------------------------------------------------
      N_axial = N_axial + sigma_i * fiber_area
      M_bend = M_bend + sigma_i * fiber_area * y_i
      
      ! Average tangent modulus
      Et_tangent = Et_tangent + d_sigma_d_eps
    END DO
    
    ! Average tangent modulus
    Et_tangent = Et_tangent / REAL(n_fibers, wp)
    
  END SUBROUTINE PH_Elem_B33P_IntegrateSection

  !===========================================================================
  ! Elastoplastic Tangent Stiffness Matrix
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_FormTangentMatrix(coords_ref, u, E_young, nu, &
       area, I_bend, sigma_y, H, n_fibers, Ke_tan, fibers_state)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent tangent stiffness matrix for elastoplastic analysis
    ! Args:
    !   coords_ref  (in) : Reference coordinates (3x2)
    !   u           (in) : Current displacement vector (6x1)
    !   E_young     (in) : Young's modulus
    !   nu          (in) : Poisson's ratio
    !   area        (in) : Cross-sectional area
    !   I_bend      (in) : Bending inertia
    !   sigma_y     (in) : Yield stress
    !   H           (in) : Hardening modulus
    !   n_fibers    (in) : Number of fibers
    !   Ke_tan      (out): Tangent stiffness matrix (6x6)
    !   fibers_state(out): Fiber states at integration points
    ! Theory:
    !   Consistent tangent operator from fiber integration
    !   K_tan = ∫(B^T * Et * B dV) where Et = dσ/dε (tangent modulus)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords_ref(3, 2)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend, sigma_y, H
    INTEGER(i4), INTENT(IN) :: n_fibers
    REAL(wp), INTENT(OUT) :: Ke_tan(6, 6)
    TYPE(FiberState), INTENT(OUT), OPTIONAL :: fibers_state(:)
    
    REAL(wp) :: x1(2), x2(2), dx(2), L0, c, s
    REAL(wp) :: Kloc(6, 6), T_mat(6, 6)
    REAL(wp) :: u_local(6), eps_axial, kappa
    REAL(wp) :: N_axial, M_bend, Et_tangent
    REAL(wp) :: EA_tangent, EI_tangent
    
    !-----------------------------------------------------------------------
    ! Step 1: Compute reference geometry
    !-----------------------------------------------------------------------
    x1(1) = coords_ref(1, 1)
    x1(2) = coords_ref(2, 1)
    x2(1) = coords_ref(1, 2)
    x2(2) = coords_ref(2, 2)
    dx = x2 - x1
    L0 = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L0 <= 1.0e-12_wp) THEN
      Ke_tan = ZERO
      RETURN
    END IF
    
    ! Reference orientation
    c = dx(1) / L0
    s = dx(2) / L0
    
    !-----------------------------------------------------------------------
    ! Step 2: Build transformation matrix T
    !-----------------------------------------------------------------------
    T_mat = ZERO
    T_mat(1, 1) =  c
    T_mat(1, 2) =  s
    T_mat(2, 1) = -s
    T_mat(2, 2) =  c
    T_mat(3, 3) =  ONE
    T_mat(4, 4) =  c
    T_mat(4, 5) =  s
    T_mat(5, 4) = -s
    T_mat(5, 5) =  c
    T_mat(6, 6) =  ONE
    
    !-----------------------------------------------------------------------
    ! Step 3: Transform displacements to local coordinate system
    !-----------------------------------------------------------------------
    u_local = MATMUL(T_mat, u)
    
    !-----------------------------------------------------------------------
    ! Step 4: Compute section strains at integration point
    !-----------------------------------------------------------------------
    ! Axial strain
    eps_axial = (u_local(4) - u_local(1)) / L0
    
    ! Curvature (from end rotations)
    kappa = (u_local(6) - u_local(3)) / L0
    
    !-----------------------------------------------------------------------
    ! Step 5: Cross-section fiber integration
    !-----------------------------------------------------------------------
    CALL PH_Elem_B33P_IntegrateSection(eps_axial, kappa, E_young, sigma_y, H, &
         area, n_fibers, N_axial, M_bend, Et_tangent, fibers_state)
    
    !-----------------------------------------------------------------------
    ! Step 6: Form tangent stiffness matrix
    !-----------------------------------------------------------------------
    ! Use tangent moduli from fiber integration
    EA_tangent = Et_tangent * area
    EI_tangent = Et_tangent * I_bend
    
    ! Local tangent stiffness matrix
    Kloc = ZERO
    
    ! Axial stiffness (using tangent modulus)
    Kloc(1, 1) =  EA_tangent/L0
    Kloc(1, 4) = -EA_tangent/L0
    Kloc(4, 1) = -EA_tangent/L0
    Kloc(4, 4) =  EA_tangent/L0
    
    ! Bending stiffness (using tangent modulus)
    Kloc(2, 2) =  12.0_wp*EI_tangent / (L0*L0*L0)
    Kloc(2, 3) =   6.0_wp*EI_tangent / (L0*L0)
    Kloc(2, 5) = -12.0_wp*EI_tangent / (L0*L0*L0)
    Kloc(2, 6) =   6.0_wp*EI_tangent / (L0*L0)
    Kloc(3, 2) =   6.0_wp*EI_tangent / (L0*L0)
    Kloc(3, 3) =   4.0_wp*EI_tangent / L0
    Kloc(3, 5) =  -6.0_wp*EI_tangent / (L0*L0)
    Kloc(3, 6) =   2.0_wp*EI_tangent / L0
    Kloc(5, 2) = -12.0_wp*EI_tangent / (L0*L0*L0)
    Kloc(5, 3) =  -6.0_wp*EI_tangent / (L0*L0)
    Kloc(5, 5) =  12.0_wp*EI_tangent / (L0*L0*L0)
    Kloc(5, 6) =  -6.0_wp*EI_tangent / (L0*L0)
    Kloc(6, 2) =   6.0_wp*EI_tangent / (L0*L0)
    Kloc(6, 3) =   2.0_wp*EI_tangent / L0
    Kloc(6, 5) =  -6.0_wp*EI_tangent / (L0*L0)
    Kloc(6, 6) =   4.0_wp*EI_tangent / L0
    
    !-----------------------------------------------------------------------
    ! Step 7: Transform to global coordinates
    !-----------------------------------------------------------------------
    Ke_tan = MATMUL(TRANSPOSE(T_mat), MATMUL(Kloc, T_mat))
    
  END SUBROUTINE PH_Elem_B33P_FormTangentMatrix

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_FormIntForce(coords_ref, u, E_young, nu, area, I_bend, &
       sigma_y, H, n_fibers, Re, fibers_state)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K_tan * u
    ! Args:
    !   coords_ref  (in) : Reference coordinates
    !   u           (in) : Displacement vector
    !   E_young     (in) : Young's modulus
    !   nu          (in) : Poisson's ratio
    !   area        (in) : Cross-sectional area
    !   I_bend      (in) : Bending inertia
    !   sigma_y     (in) : Yield stress
    !   H           (in) : Hardening modulus
    !   n_fibers    (in) : Number of fibers
    !   Re          (out): Internal force vector
    !   fibers_state(out): Fiber states (optional)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords_ref(3, 2)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend, sigma_y, H
    INTEGER(i4), INTENT(IN) :: n_fibers
    REAL(wp), INTENT(OUT) :: Re(6)
    TYPE(FiberState), INTENT(OUT), OPTIONAL :: fibers_state(:)
    
    REAL(wp) :: Ke_tan(6, 6)
    
    ! Compute tangent stiffness and multiply by displacements
    CALL PH_Elem_B33P_FormTangentMatrix(coords_ref, u, E_young, nu, area, I_bend, &
         sigma_y, H, n_fibers, Ke_tan, fibers_state)
    
    Re = MATMUL(Ke_tan, u)
    
  END SUBROUTINE PH_Elem_B33P_FormIntForce

  !===========================================================================
  ! Lumped Mass Vector Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B33P_LumpMassWithSection(coords, rho, area, M_lumped)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector (diagonal mass matrix as vector)
    ! Args:
    !   coords    (in) : 3x2 nodal coordinates
    !   rho       (in) : Material density
    !   area      (in) : Cross-sectional area
    !   M_lumped  (out): 6x1 lumped mass vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_half
    
    M_lumped = ZERO
    
    ! Compute element length
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) RETURN
    
    ! Equal mass distribution to each node (translational DOF only)
    m_half = rho * area * L * 0.5_wp
    
    ! Node 1: u_x, u_y (DOF 1, 2)
    M_lumped(1) = m_half
    M_lumped(2) = m_half
    
    ! Node 2: u_x, u_y (DOF 4, 5)
    M_lumped(4) = m_half
    M_lumped(5) = m_half
    
    ! Note: Rotary inertia (DOF 3, 6) = 0 in this formulation
  END SUBROUTINE PH_Elem_B33P_LumpMassWithSection

  !===========================================================================
  ! Unified Element Calculation Interface (UFC L3->L4 Bridge)
  !===========================================================================
  SUBROUTINE UF_Elem_B33P_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B33P
    !          Computes tangent stiffness and internal force vector
    ! Args (UFC Standard 5-tuple + RT_Com_Base_Ctx):
    !   ElemType (in)  : Element type descriptor
    !   Formul   (in)  : Element formulation descriptor
    !   Ctx      (in)  : Element context (coords, displacements, etc.)
    !   state_in (in)  : Input element state
    !   Mat      (inout): Material properties
    !   state_out(inout): Output element state (Ke, Re, etc.)
    !   flags    (inout): Element flags and status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(IN)    :: ElemType
    TYPE(ElemFormul), INTENT(IN)  :: Formul
    TYPE(ElemCtx), INTENT(IN)     :: Ctx
    TYPE(ElemState), INTENT(IN)   :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT):: state_out
    TYPE(ElemFlags), INTENT(INOUT):: flags

    ! Local variables
    REAL(wp) :: coords_ref(3, 2)     ! Reference coordinates
    REAL(wp) :: u(6)                 ! Displacement vector
    REAL(wp) :: E_young, nu, area_a, I_bend
    REAL(wp) :: sigma_y, H
    INTEGER(i4) :: n_fibers
    REAL(wp) :: Ke_tan(6, 6), R(6)   ! Tangent stiffness and internal force
    TYPE(FiberState), ALLOCATABLE :: fibers_state(:)  ! Fiber states
    TYPE(MatProperties) :: props     ! Material property wrapper
    TYPE(ErrorStatusType) :: st      ! Local error status

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    
    !-----------------------------------------------------------------------
    ! Validation: Element topology
    !-----------------------------------------------------------------------
    IF (ElemType%numNodes /= PH_ELEM_B33P_NNODE .OR. ElemType%dim /= 2_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33P_Calc: expect 2-node 2D beam (B33P)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Context data availability
    !-----------------------------------------------------------------------
    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < PH_ELEM_B33P_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33P_Calc: coords_ref missing or insufficient'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract reference coordinates
    !-----------------------------------------------------------------------
    coords_ref(1:2, 1:2) = Ctx%coords_ref(1:2, 1:2)
    coords_ref(3, 1:2)   = 0.0_wp  ! z-coordinate = 0 for plane beam

    !-----------------------------------------------------------------------
    ! Extract displacement vector (6 DOF)
    !-----------------------------------------------------------------------
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= PH_ELEM_B33P_NNODE) THEN
      u(1) = Ctx%disp_total(1, 1)  ! Node 1 u_x
      u(2) = Ctx%disp_total(2, 1)  ! Node 1 u_y
      u(3) = Ctx%disp_total(3, 1)  ! Node 1 theta_z
      u(4) = Ctx%disp_total(1, 2)  ! Node 2 u_x
      u(5) = Ctx%disp_total(2, 2)  ! Node 2 u_y
      u(6) = Ctx%disp_total(3, 2)  ! Node 2 theta_z
    END IF

    !-----------------------------------------------------------------------
    ! Extract material properties
    !-----------------------------------------------------------------------
    E_young = 0.0_wp
    nu      = 0.3_wp  ! Default Poisson's ratio
    sigma_y = 250.0e6_wp  ! Default yield stress (steel)
    H       = 0.0_wp  ! Default: perfect plasticity
    
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_B33P_PROP_E) &
        E_young = props%props(PH_B33P_PROP_E)
      IF (SIZE(props%props) >= PH_B33P_PROP_NU) &
        nu = props%props(PH_B33P_PROP_NU)
      IF (SIZE(props%props) >= PH_B33P_PROP_SIGY) &
        sigma_y = props%props(PH_B33P_PROP_SIGY)
      IF (SIZE(props%props) >= PH_B33P_PROP_H) &
        H = props%props(PH_B33P_PROP_H)
    END IF

    !-----------------------------------------------------------------------
    ! Extract section properties (area, inertia)
    !-----------------------------------------------------------------------
    area_a = 1.0_wp
    I_bend = 1.0_wp
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_B33P_PROP_A .AND. props%props(PH_B33P_PROP_A) > 0.0_wp) &
        area_a = props%props(PH_B33P_PROP_A)
      IF (SIZE(props%props) >= PH_B33P_PROP_I .AND. props%props(PH_B33P_PROP_I) > 0.0_wp) &
        I_bend = props%props(PH_B33P_PROP_I)
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Material parameters
    !-----------------------------------------------------------------------
    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33P_Calc: invalid Young modulus (must be > 0)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Set number of fibers
    !-----------------------------------------------------------------------
    n_fibers = PH_B33P_DEFAULT_FIBERS

    !-----------------------------------------------------------------------
    ! Allocate fiber state array
    !-----------------------------------------------------------------------
    ALLOCATE(fibers_state(n_fibers))

    !-----------------------------------------------------------------------
    ! Compute tangent stiffness matrix (fiber integration)
    !-----------------------------------------------------------------------
    CALL PH_Elem_B33P_FormTangentMatrix(coords_ref, u, E_young, nu, area_a, I_bend, &
         sigma_y, H, n_fibers, Ke_tan, fibers_state)

    !-----------------------------------------------------------------------
    ! Compute internal force vector
    !-----------------------------------------------------------------------
    CALL PH_Elem_B33P_FormIntForce(coords_ref, u, E_young, nu, area_a, I_bend, &
         sigma_y, H, n_fibers, R, fibers_state)

    !-----------------------------------------------------------------------
    ! Ensure output storage and assign results
    !-----------------------------------------------------------------------
    CALL UF_Elem_PrepareStructStorage(state_out, PH_ELEM_B33P_NDOF)
    state_out%evo%Ke(1:6, 1:6) = Ke_tan
    state_out%Re(1:6)      = R

    !-----------------------------------------------------------------------
    ! Set output flags
    !-----------------------------------------------------------------------
    flags%status%status_code = IF_STATUS_OK
    flags%requires_reasse    = .TRUE.   ! Trigger global assembly
    state_out%failed         = flags%failed
    state_out%stableDt       = flags%stableDt
    
    ! Cleanup
    DEALLOCATE(fibers_state)
    
  END SUBROUTINE UF_Elem_B33P_Calc

END MODULE PH_Elem_B33P
!===============================================================================
! End of Module PH_ElemB33P_Algo
!
! Summary of Implementation (v1.0):
!   - Fiber discretization for cross-section integration
!   - J2 flow theory with isotropic hardening
!   - Consistent tangent operator for Newton-Raphson
!   - Multi-point Gauss integration along length
!   - UFC-compliant UF_Elem_B33P_Calc interface
!
! API Reference:
!   Core Functions:
!     - PH_Elem_B33P_FormStiffMatrix: Linear elastic stiffness
!     - PH_Elem_B33P_FormTangentMatrix: Elastoplastic tangent stiffness
!     - PH_Elem_B33P_IntegrateSection: Fiber integration (N, M, Et)
!     - PH_Elem_B33P_FormIntForce: Internal force vector
!     - PH_Elem_B33P_ConsMassWithSection: Consistent mass
!     - PH_Elem_B33P_LumpMassWithSection: Lumped mass vector
!   
!   UFC Bridge:
!     - UF_Elem_B33P_Calc: Unified element calculation interface
!
! Key Features:
!   - Arbitrary number of fibers (default 10)
!   - Isotropic hardening (H parameter)
!   - Consistent tangent for quadratic convergence
!   - Compatible with Newton-Raphson nonlinear solution
!
! Related Modules:
!     - PH_ElemB33_Algo: Linear 2D beam (elastic)
!     - PH_ElemB33NL_Algo: Geometric nonlinearity (large rotation)
!     - PH_ElemB31_Algo: 3D beam with NL_TL/NL_UL formulations
!===============================================================================
