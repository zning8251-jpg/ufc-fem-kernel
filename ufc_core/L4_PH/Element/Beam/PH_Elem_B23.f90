!===============================================================================
! MODULE: PH_Elem_B23
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B23 element kernel for 2D Euler-Bernoulli beam
!===============================================================================
MODULE PH_Elem_B23
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
  USE UF_Material_Base
  
  IMPLICIT NONE
  PRIVATE
  !===========================================================================
  ! Public Constants - Element DOF information
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B23_NNODE  = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B23_NIP    = 1_i4   ! Integration points
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B23_NDOF   = 6_i4   ! Total DOF (per element)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B23_NEDGE  = 0_i4   ! Number of edges
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B23_DefInit                ! Element definition initialization
  PUBLIC :: PH_Elem_B23_FormStiffMatrix        ! Form stiffness matrix (6x6)
  PUBLIC :: PH_Elem_B23_FormStiffMatrixWithSection  ! Form stiffness with section props
  PUBLIC :: PH_Elem_B23_FormIntForce           ! Form internal force vector (6x1)
  PUBLIC :: PH_Elem_B23_ConsMass               ! Form consistent mass matrix (6x6)
  PUBLIC :: PH_Elem_B23_ConsMassWithSection    ! Form consistent mass with section
  PUBLIC :: PH_Elem_B23_LumpMass               ! Form lumped mass vector (6x1)
  PUBLIC :: PH_Elem_B23_LumpMassWithSection    ! Form lumped mass with section
  PUBLIC :: PH_Elem_B23_ThermStrainVector      ! Thermal strain vector (stub)
  PUBLIC :: UF_Elem_B23_Calc                   ! Unified element calculation interface
  
  !===========================================================================
  ! INTF-001 Arg TYPE - Unified argument bundle for element operations
  !===========================================================================
  PUBLIC :: PH_Elem_Beam_Args
  TYPE :: PH_Elem_Beam_Args
    ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
    !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
    !          FormBodyForce/FormNodalForce/CollectIPVars
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
  END TYPE PH_Elem_Beam_Args


CONTAINS

  !===========================================================================
  ! Consistent Mass Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_ConsMassWithSection(coords, rho, area, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B23 beam element
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
  END SUBROUTINE PH_Elem_B23_ConsMassWithSection

  !===========================================================================
  ! Stiffness Matrix Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form 6x6 stiffness matrix for B23 beam element
    !          Includes axial and bending contributions
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio (not used in classical beam theory)
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia about z-axis
    !   Ke       (out): 6x6 element stiffness matrix
    ! Theory:
    !   K = K_axial + K_bending
    !   K_axial = EA/L (bar action)
    !   K_bending = Classical Euler-Bernoulli beam coefficients
    !   Transformation: T^T * K_local * T (local to global)
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
  END SUBROUTINE PH_Elem_B23_FormStiffMatrixWithSection

  !===========================================================================
  ! Lumped Mass Vector Formation (with Section Properties)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_LumpMassWithSection(coords, rho, area, M_lumped)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector (diagonal mass matrix as vector)
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   rho      (in) : Material density
    !   area     (in) : Cross-sectional area
    !   M_lumped (out): 6x1 lumped mass vector
    ! Theory:
    !   Lumped mass: Equal distribution to each node (translational DOF only)
    !   Total mass = rho * A * L
    !   Each node gets half: m_node = rho * A * L / 2
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_half
    
    M_lumped = ZERO
    
    ! Extract 2D coordinates and compute length
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
  END SUBROUTINE PH_Elem_B23_LumpMassWithSection

  !===========================================================================
  ! Thermal Strain Vector (Stub for Future Thermo-Mechanical Coupling)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_ThermStrainVector(alpha, deltaT, eps_th)
    !-------------------------------------------------------------------------
    ! Purpose: Compute thermal strain vector for B23 beam
    !          Currently a stub - B23 is mechanical-only
    ! Args:
    !   alpha    (in) : Coefficient of thermal expansion
    !   deltaT   (in) : Temperature change
    !   eps_th   (out): Thermal strain vector
    ! Note: For thermo-mechanical coupling, use B21T element instead
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_B23_ThermStrainVector

  !===========================================================================
  ! Consistent Mass Matrix Formation (Default Section)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_ConsMass(coords, rho, Me)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix with default section (A=1)
    ! Args:
    !   coords (in)  : 3x2 nodal coordinates
    !   rho    (in)  : Material density
    !   Me     (out) : 6x6 consistent mass matrix
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    CALL PH_Elem_B23_ConsMassWithSection(coords, rho, ONE, Me)
  END SUBROUTINE PH_Elem_B23_ConsMass

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B23_DefInit()
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B23 element definition
    !          Currently a no-op stub for API compatibility
    !-------------------------------------------------------------------------
  END SUBROUTINE PH_Elem_B23_DefInit

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B23_FormIntForce(coords, u, E_young, nu, R_int)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   u        (in) : 6x1 displacement vector
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   R_int    (out): 6x1 internal force vector
    ! Theory: Linear elastic: R_int = K * u
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: Ke(6, 6)
    
    ! Compute stiffness matrix
    CALL PH_Elem_B23_FormStiffMatrix(coords, E_young, nu, Ke)
    
    ! Internal forces = stiffness * displacements
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_B23_FormIntForce

  !===========================================================================
  ! Stiffness Matrix Formation (Default Section)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_FormStiffMatrix(coords, E_young, nu, Ke)
    !-------------------------------------------------------------------------
    ! Purpose: Form stiffness matrix with default section (A=1, I=1)
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   Ke       (out): 6x6 element stiffness matrix
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    CALL PH_Elem_B23_FormStiffMatrixWithSection(coords, E_young, nu, ONE, ONE, Ke)
  END SUBROUTINE PH_Elem_B23_FormStiffMatrix

  !===========================================================================
  ! Lumped Mass Vector Formation (Default Section)
  !===========================================================================
  SUBROUTINE PH_Elem_B23_LumpMass(coords, rho, M_lumped)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector with default section (A=1)
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   rho      (in) : Material density
    !   M_lumped (out): 6x1 lumped mass vector
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    CALL PH_Elem_B23_LumpMassWithSection(coords, rho, ONE, M_lumped)
  END SUBROUTINE PH_Elem_B23_LumpMass

  !===========================================================================
  ! Unified Element Calculation Interface (UFC L3->L4 Bridge)
  !===========================================================================
  SUBROUTINE UF_Elem_B23_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B23
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
    INTEGER(i4) :: nNode, nDOF
    REAL(wp) :: coords(3, 2)           ! Working coordinates (3D for compatibility)
    REAL(wp) :: u(6)                   ! Displacement vector (6 DOF)
    REAL(wp) :: x1(2), x2(2), dx(2), L ! Element geometry
    REAL(wp) :: E, nu, A, I_bend       ! Material and section properties
    REAL(wp), ALLOCATABLE :: Ke_loc(:,:), Re_loc(:) ! Element matrices
    TYPE(MatProperties) :: props       ! Material property wrapper

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    
    !-----------------------------------------------------------------------
    ! Validation: Element topology
    !-----------------------------------------------------------------------
    nNode = ElemType%numNodes
    nDOF = PH_ELEM_B23_NDOF
    
    IF (nNode /= 2_i4 .OR. ElemType%dim /= 2_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B23_Calc: expected 2-node 2D beam (B23)'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Context data availability
    !-----------------------------------------------------------------------
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B23_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract coordinates (embed 2D beam in 3D space for compatibility)
    !-----------------------------------------------------------------------
    coords(1:2, 1:2) = Ctx%coords_ref(1:2, 1:2)
    coords(3, 1:2)   = ZERO  ! z-coordinate = 0 for plane beam
    x1(1) = coords(1, 1)
    x1(2) = coords(2, 1)
    x2(1) = coords(1, 2)
    x2(2) = coords(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))

    !-----------------------------------------------------------------------
    ! Validation: Element length
    !-----------------------------------------------------------------------
    IF (L <= 1.0e-12_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B23_Calc: element length too small'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%requires_reasse = .FALSE.
      flags%stableDt = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract displacement vector (6 DOF)
    !-----------------------------------------------------------------------
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= 2_i4) THEN
      ! Node 1 DOF
      u(1) = Ctx%disp_total(1, 1)  ! u_x
      u(2) = Ctx%disp_total(2, 1)  ! u_y
      u(3) = Ctx%disp_total(3, 1)  ! theta_z
      
      ! Node 2 DOF
      u(4) = Ctx%disp_total(1, 2)  ! u_x
      u(5) = Ctx%disp_total(2, 2)  ! u_y
      u(6) = Ctx%disp_total(3, 2)  ! theta_z
    END IF

    !-----------------------------------------------------------------------
    ! Extract material properties
    !-----------------------------------------------------------------------
    E  = 0.0_wp
    nu = 0.3_wp  ! Default Poisson's ratio
    props = Mat%props
    
    IF (ALLOCATED(props%props)) THEN
      ! Young's modulus (required)
      IF (SIZE(props%props) >= UF_MAT_PROP_ELA) THEN
        E = props%props(UF_MAT_PROP_ELA)
      END IF
      
      ! Poisson's ratio (optional)
      IF (SIZE(props%props) >= UF_MAT_PROP_NU) THEN
        nu = props%props(UF_MAT_PROP_NU)
      END IF
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Material parameters
    !-----------------------------------------------------------------------
    IF (E <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B23_Calc: invalid Young modulus (must be > 0)'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract section properties (defaults: A=1, I=1)
    !-----------------------------------------------------------------------
    A = 1.0_wp
    I_bend = 1.0_wp
    ! Note: Section properties typically come from MD_Sect_Registry in production

    !-----------------------------------------------------------------------
    ! Compute element matrices
    !-----------------------------------------------------------------------
    ALLOCATE(Ke_loc(nDOF, nDOF))
    ALLOCATE(Re_loc(nDOF))
    
    ! Form stiffness matrix with section properties
    CALL PH_Elem_B23_FormStiffMatrixWithSection(coords, E, nu, A, I_bend, Ke_loc)
    
    ! Compute internal forces
    CALL PH_Elem_B23_FormIntForce(coords, u, E, nu, Re_loc)

    !-----------------------------------------------------------------------
    ! Prepare output storage and assign results
    !-----------------------------------------------------------------------
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)

    !-----------------------------------------------------------------------
    ! Prepare integration point states
    !-----------------------------------------------------------------------
    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_B23_NIP)
    IF (ALLOCATED(state_out%ipStates)) THEN
      IF (SIZE(state_out%ipStates) >= 1) THEN
        ! Store basic state information at IP
        ! TODO: Add stress/strain recovery for post-processing
      END IF
    END IF

    !-----------------------------------------------------------------------
    ! Set output flags
    !-----------------------------------------------------------------------
    flags%failed              = .FALSE.
    flags%suggest_cutback     = .FALSE.
    flags%requires_reasse     = .TRUE.   ! Trigger global assembly
    flags%stableDt            = 0.0_wp
    flags%status%status_code  = IF_STATUS_OK
    
    state_out%failed          = flags%failed
    state_out%stableDt        = flags%stableDt

    ! Cleanup
    DEALLOCATE(Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_B23_Calc
  !===========================================================================
  ! End of Unified Element Calculation Interface
  !===========================================================================

END MODULE PH_Elem_B23
!===============================================================================
! End of Module PH_ElemB23_Algo
!
! Summary of Refactoring (v2.0):
!   - Enhanced module documentation and theory comments
!   - Improved error handling and validation in UF interface
!   - Added detailed comments to all computational subroutines
!   - Aligned code structure with UFC templates and B21T patterns
!   - Better separation of concerns (geometry, material, section)
!
! API Reference:
!   Core Functions:
!     - PH_Elem_B23_FormStiffMatrixWithSection: Full stiffness with section props
!     - PH_Elem_B23_FormStiffMatrix: Default section (A=1, I=1)
!     - PH_Elem_B23_FormIntForce: Internal force vector R = K*u
!     - PH_Elem_B23_ConsMassWithSection: Consistent mass matrix
!     - PH_Elem_B23_LumpMassWithSection: Lumped mass vector
!   
!   UFC Bridge:
!     - UF_Elem_B23_Calc: Unified element calculation interface
!
! Related Modules:
!     - PH_ElemB21T_Algo: Thermo-mechanical coupling extension
!     - PH_ElemB31_Algo: 3D beam elements
!     - PH_ElemB31T_Algo: 3D beam with thermal coupling
!===============================================================================