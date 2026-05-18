!===============================================================================
! MODULE: PH_Elem_B33S
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B33S 2D Timoshenko beam element
!===============================================================================
MODULE PH_Elem_B33S
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
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33S_NNODE  = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33S_NIP    = 1_i4   ! Integration points
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33S_NDOF   = 6_i4   ! Total DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B33S_NEDGE  = 0_i4   ! Number of edges
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33S_PROP_E     = 1_i4   ! Young's modulus index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33S_PROP_NU    = 2_i4   ! Poisson's ratio index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33S_PROP_A     = 3_i4   ! Area index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B33S_PROP_I     = 4_i4   ! Inertia index
  
  ! Default shear correction factor (rectangular cross-section)
  REAL(wp), PARAMETER, PUBLIC :: PH_B33S_KAPPA_DEFAULT = 5.0_wp / 6.0_wp
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B33S_DefInit               ! Element definition initialization
  PUBLIC :: PH_Elem_B33S_FormStiffMatrix       ! Form stiffness matrix (6x6, Euler-Bernoulli)
  PUBLIC :: PH_Elem_B33S_FormStiffMatrixWithShear  ! Form stiffness with shear (6x6)
  PUBLIC :: PH_Elem_B33S_FormStiffMatrixWithSection ! Form stiffness with section props
  PUBLIC :: PH_Elem_B33S_FormIntForce          ! Form internal force vector (6x1)
  PUBLIC :: PH_Elem_B33S_ConsMass              ! Form consistent mass matrix (6x6)
  PUBLIC :: PH_Elem_B33S_ConsMassWithSection   ! Form consistent mass with section
  PUBLIC :: PH_Elem_B33S_LumpMass              ! Form lumped mass vector (6x1)
  PUBLIC :: PH_Elem_B33S_LumpMassWithSection   ! Form lumped mass with section
  PUBLIC :: UF_Elem_B33S_Calc                  ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_DefInit(ElemDef, status)
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B33S element definition descriptor
    ! Args:
    !   ElemDef (inout): Element definition to initialize
    !   status  (out)  : Error status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ElemDef%numNodes = PH_ELEM_B33S_NNODE
    ElemDef%dim = 2_i4
    ElemDef%dofPerNode = 3_i4  ! u_x, u_y, theta_z
    ElemDef%totalDOF = PH_ELEM_B33S_NDOF
    ElemDef%name = 'B33S'
    ElemDef%cfg%description = '2-node 2D Timoshenko beam with shear deformation'
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B33S_DefInit

  !===========================================================================
  ! Consistent Mass Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_ConsMassWithSection(coords, rho, area, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B33S Timoshenko beam element
    !          Translational DOF only (rotary inertia neglected in 2D beam)
    ! Args:
    !   coords (in)  : 3x2 nodal coordinates (x,y,z for 2 nodes)
    !   rho    (in)  : Material density
    !   area   (in)  : Cross-sectional area
    !   Me     (out) : 6x6 consistent mass matrix
    ! Theory:
    !   Consistent mass: M = integral(rho * N^T * N dV)
    !   For 2D beam: only translational DOF (u_x, u_y) considered
    !   Same as B23/B33 since rotary inertia not included
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
  END SUBROUTINE PH_Elem_B33S_ConsMassWithSection

  !===========================================================================
  ! Stiffness Matrix Formation (Euler-Bernoulli, no shear)
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_FormStiffMatrix(coords, E_young, nu, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 stiffness matrix for B33S beam element (no shear def)
    !          Includes axial and bending contributions (classical theory)
    ! Args:
    !   coords  (in) : 3x2 nodal coordinates
    !   E_young (in) : Young's modulus
    !   nu      (in) : Poisson's ratio (not used in classical beam theory)
    !   Ke      (out): 6x6 element stiffness matrix
    ! Theory:
    !   K = K_axial + K_bending
    !   K_axial = EA/L (bar action)
    !   K_bending = Classical Euler-Bernoulli beam coefficients
    !   Transformation: T^T * K_local * T (local to global)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    
    ! Use default section properties (A=1, I=1)
    CALL PH_Elem_B33S_FormStiffMatrixWithSection(coords, E_young, nu, &
         1.0_wp, 1.0_wp, Ke)
  END SUBROUTINE PH_Elem_B33S_FormStiffMatrix

  !===========================================================================
  ! Stiffness Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 stiffness matrix for B33S beam element (no shear def)
    !          Includes axial and bending contributions
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia about z-axis
    !   Ke       (out): 6x6 element stiffness matrix
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: area, I_bend
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    
    ! Call full Timoshenko implementation with zero shear contribution
    CALL PH_Elem_B33S_FormStiffMatrixWithShear(coords, E_young, nu, area, I_bend, &
         0.0_wp, Ke)  ! kappa=0 means no shear
  END SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithSection

  !===========================================================================
  ! Stiffness Matrix Formation (Full Timoshenko with Shear)
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithShear(coords, E_young, nu, area, I_bend, kappa_shear, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 stiffness matrix for B33S Timoshenko beam element
    !          Includes axial, bending, AND transverse shear contributions
    ! Args:
    !   coords     (in) : 3x2 nodal coordinates
    !   E_young    (in) : Young's modulus
    !   nu         (in) : Poisson's ratio
    !   area       (in) : Cross-sectional area
    !   I_bend     (in) : Bending inertia about z-axis
    !   kappa_shear(in) : Shear correction factor (use 5/6 for rectangular)
    !                     Set to 0 to disable shear (Euler-Bernoulli)
    !   Ke         (out): 6x6 element stiffness matrix
    ! Theory:
    !   K_total = K_axial + K_bending + K_shear
    !   
    !   K_axial: EA/L (same as Euler-Bernoulli)
    !   
    !   K_bending: EI/L^3 * [12  6L -12  6L
    !                        6L 4L² -6L 2L²
    !                       -12 -6L  12 -6L
    !                        6L 2L² -6L 4L²]
    !   
    !   K_shear: kGA/L * [0  0  0  0  0  0
    !                     0  1  L/2  0 -1  L/2
    !                     0 L/2 L²/4  0 -L/2 L²/4
    !                     0  0  0  0  0  0
    !                     0 -1 -L/2  0  1 -L/2
    !                     0 L/2 L²/4  0 -L/2 L²/4]
    !                     
    !   where k = kappa_shear (shear correction factor)
    !         G = E/(2*(1+nu)) (shear modulus)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: area, I_bend
    REAL(wp), INTENT(IN)  :: kappa_shear
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, c, s
    REAL(wp) :: E, A, I, G, k, phi
    REAL(wp) :: Kloc(6, 6), T(6, 6)
    
    E = E_young
    A = area
    I = I_bend
    G = E / (2.0_wp * (ONE + nu))  ! Shear modulus
    k = kappa_shear
    
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
    
    ! Local stiffness matrix (axial + bending + shear)
    Kloc = ZERO
    
    !-----------------------------------------------------------------------
    ! Axial stiffness (DOF 1, 4) - same as Euler-Bernoulli
    !-----------------------------------------------------------------------
    Kloc(1, 1) =  E*A/L
    Kloc(1, 4) = -E*A/L
    Kloc(4, 1) = -E*A/L
    Kloc(4, 4) =  E*A/L
    
    !-----------------------------------------------------------------------
    ! Bending + Shear stiffness (DOF 2,3,5,6)
    ! Using Timoshenko beam theory with shear parameter phi
    !-----------------------------------------------------------------------
    
    ! Shear flexibility parameter (dimensionless)
    ! phi = 12*E*I / (k*G*A*L^2)
    ! Large phi → slender beam (shear negligible)
    ! Small phi → thick beam (shear important)
    IF (k > 1.0e-6_wp .AND. G > 1.0e-6_wp .AND. A > 1.0e-6_wp) THEN
      phi = 12.0_wp * E * I / (k * G * A * L * L)
    ELSE
      phi = 0.0_wp  ! No shear (Euler-Bernoulli limit)
    END IF
    
    ! Denominator for Timoshenko coefficients
    ! D = L^3 * (1 + phi)
    REAL(wp) :: denom
    denom = L * L * L * (ONE + phi)
    
    ! Bending stiffness coefficients (modified by shear)
    ! These reduce to Euler-Bernoulli when phi -> infinity
    Kloc(2, 2) =  (12.0_wp*E*I / denom)
    Kloc(2, 3) =   (6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(2, 5) = -(12.0_wp*E*I / denom)
    Kloc(2, 6) =   (6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(3, 2) =   (6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(3, 3) =   (4.0_wp + phi)*E*I / (L*(ONE + phi))
    Kloc(3, 5) =  -(6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(3, 6) =   (2.0_wp - phi)*E*I / (L*(ONE + phi))
    Kloc(5, 2) = -(12.0_wp*E*I / denom)
    Kloc(5, 3) =  -(6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(5, 5) =  (12.0_wp*E*I / denom)
    Kloc(5, 6) =  -(6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(6, 2) =   (6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(6, 3) =   (2.0_wp - phi)*E*I / (L*(ONE + phi))
    Kloc(6, 5) =  -(6.0_wp*E*I / (L*L*(ONE + phi)))
    Kloc(6, 6) =   (4.0_wp + phi)*E*I / (L*(ONE + phi))
    
    !-----------------------------------------------------------------------
    ! Transformation matrix (block diagonal for 2D beam)
    !-----------------------------------------------------------------------
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
    
  END SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithShear

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_FormIntForce(coords, u, E_young, nu, Re)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    ! Args:
    !   coords  (in) : 3x2 nodal coordinates
    !   u       (in) : 6x1 displacement vector
    !   E_young (in) : Young's modulus
    !   nu      (in) : Poisson's ratio
    !   Re      (out): 6x1 internal force vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Re(6)
    
    ! Use default section properties (A=1, I=1)
    CALL PH_Elem_B33S_FormStiffMatrixWithSection(coords, E_young, nu, &
         1.0_wp, 1.0_wp, Re)
    Re = MATMUL(Re, u)
  END SUBROUTINE PH_Elem_B33S_FormIntForce

  !===========================================================================
  ! Lumped Mass Vector Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B33S_LumpMassWithSection(coords, rho, area, M_lumped)
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
  END SUBROUTINE PH_Elem_B33S_LumpMassWithSection

  !===========================================================================
  ! Unified Element Calculation Interface (UFC L3->L4 Bridge)
  !===========================================================================
  SUBROUTINE UF_Elem_B33S_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B33S
    !          Computes element stiffness matrix and internal force vector
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
    REAL(wp) :: coords(3, 2)           ! Working coordinates
    REAL(wp) :: u(6)                   ! Displacement vector
    REAL(wp) :: E_young, nu, area_a, I_bend, kappa_shear
    REAL(wp) :: Ke(6, 6), R(6)         ! Element matrices
    TYPE(MatProperties) :: props       ! Material property wrapper
    TYPE(ErrorStatusType) :: st        ! Local error status

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    
    !-----------------------------------------------------------------------
    ! Validation: Element topology
    !-----------------------------------------------------------------------
    IF (ElemType%numNodes /= PH_ELEM_B33S_NNODE .OR. ElemType%dim /= 2_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33S_Calc: expect 2-node 2D beam (B33S)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Context data availability
    !-----------------------------------------------------------------------
    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < PH_ELEM_B33S_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33S_Calc: coords_ref missing or insufficient'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract coordinates (embed 2D beam in 3D space)
    !-----------------------------------------------------------------------
    coords(1:2, 1:2) = Ctx%coords_ref(1:2, 1:2)
    coords(3, 1:2)   = 0.0_wp  ! z-coordinate = 0 for plane beam

    !-----------------------------------------------------------------------
    ! Extract displacement vector (6 DOF)
    !-----------------------------------------------------------------------
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= PH_ELEM_B33S_NNODE) THEN
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
    
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_B33S_PROP_E) &
        E_young = props%props(PH_B33S_PROP_E)
      IF (SIZE(props%props) >= PH_B33S_PROP_NU) &
        nu = props%props(PH_B33S_PROP_NU)
    END IF

    !-----------------------------------------------------------------------
    ! Extract section properties (area, inertia)
    !-----------------------------------------------------------------------
    area_a = 1.0_wp
    I_bend = 1.0_wp
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_B33S_PROP_A .AND. props%props(PH_B33S_PROP_A) > 0.0_wp) &
        area_a = props%props(PH_B33S_PROP_A)
      IF (SIZE(props%props) >= PH_B33S_PROP_I .AND. props%props(PH_B33S_PROP_I) > 0.0_wp) &
        I_bend = props%props(PH_B33S_PROP_I)
    END IF

    !-----------------------------------------------------------------------
    ! Shear correction factor (default 5/6 for rectangular section)
    !-----------------------------------------------------------------------
    kappa_shear = PH_B33S_KAPPA_DEFAULT

    !-----------------------------------------------------------------------
    ! Validation: Material parameters
    !-----------------------------------------------------------------------
    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B33S_Calc: invalid Young modulus (must be > 0)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Compute element stiffness matrix (full Timoshenko with shear)
    !-----------------------------------------------------------------------
    CALL PH_Elem_B33S_FormStiffMatrixWithShear(coords, E_young, nu, area_a, I_bend, &
         kappa_shear, Ke)

    !-----------------------------------------------------------------------
    ! Compute internal force vector
    !-----------------------------------------------------------------------
    R = MATMUL(Ke, u)

    !-----------------------------------------------------------------------
    ! Ensure output storage and assign results
    !-----------------------------------------------------------------------
    CALL UF_Elem_PrepareStructStorage(state_out, PH_ELEM_B33S_NDOF)
    state_out%evo%Ke(1:6, 1:6) = Ke
    state_out%Re(1:6)      = R

    !-----------------------------------------------------------------------
    ! Set output flags
    !-----------------------------------------------------------------------
    flags%status%status_code = IF_STATUS_OK
    flags%requires_reasse    = .TRUE.   ! Trigger global assembly
    state_out%failed         = flags%failed
    state_out%stableDt       = flags%stableDt
    
  END SUBROUTINE UF_Elem_B33S_Calc

END MODULE PH_Elem_B33S
!===============================================================================
! End of Module PH_ElemB33S_Algo
!
! Summary of Implementation (v1.0):
!   - Complete Timoshenko beam theory with transverse shear deformation
!   - Shear correction factor kappa (default 5/6 for rectangular sections)
!   - Shear flexibility parameter phi = 12EI/(kGA*L^2)
!   - Reduces to Euler-Bernoulli when kappa -> 0 or L/h >> 10
!   - UFC-compliant UF_Elem_B33S_Calc interface
!
! API Reference:
!   Core Functions:
!     - PH_Elem_B33S_FormStiffMatrix: Classical (no shear)
!     - PH_Elem_B33S_FormStiffMatrixWithShear: Full Timoshenko implementation
!     - PH_Elem_B33S_FormIntForce: Internal force vector R = K*u
!     - PH_Elem_B33S_ConsMassWithSection: Consistent mass (translational only)
!     - PH_Elem_B33S_LumpMassWithSection: Lumped mass vector
!   
!   UFC Bridge:
!     - UF_Elem_B33S_Calc: Unified element calculation interface
!
! Key Parameters:
!   - kappa_shear: Shear correction factor (5/6 for rectangular, 9/10 for circular)
!   - phi: Dimensionless shear flexibility (large = slender, small = thick)
!   - G: Shear modulus = E/(2*(1+nu))
!
! Related Modules:
!     - PH_ElemB23_Algo: 2D Euler-Bernoulli beam (no shear)
!     - PH_ElemB33_Algo: 2D Euler-Bernoulli beam (alternative)
!     - PH_ElemB31_Algo: 3D beam (reference for NL formulations)
!===============================================================================
