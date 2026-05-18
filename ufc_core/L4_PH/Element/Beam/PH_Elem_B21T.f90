!===============================================================================
! MODULE: PH_Elem_B21T
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B21T thermo-mechanical beam element (2-node plane)
!===============================================================================
MODULE PH_Elem_B21T
  !===========================================================================
  ! Module Dependencies (Layered Architecture)
  !===========================================================================
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF          ! Mathematical constants
  USE IF_Prec_Core,         ONLY: wp, i4                    ! Precision kinds
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID  ! Error handling
  
  ! L3_MD: Model definitions
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState       ! Element types
  USE MD_Mat_Lib,      ONLY: MatProperties              ! Material library
  
  ! L4_PH: Physics layer - reuse B23 mechanical kernel
  USE PH_Elem_B23, ONLY: PH_Elem_B23_FormStiffMatrixWithSection
  
  IMPLICIT NONE
  PRIVATE
  
  !===========================================================================
  ! Public Constants - Element DOF information
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B21T_NDOF_TOTAL  = 8_i4   ! Total DOF (6 mech + 2 therm)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B21T_NDOF_MECH   = 6_i4   ! Mechanical DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B21T_NDOF_THERM  = 2_i4   ! Thermal DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_B21T_NNODE       = 2_i4   ! Number of nodes
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21T_PROP_E     = 1_i4   ! Young's modulus index
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B21T_PROP_NU    = 2_i4   ! Poisson's ratio index
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B21T_FormStiffMatrix       ! Form total stiffness matrix (8x8)
  PUBLIC :: PH_Elem_B21T_FormIntForce          ! Form internal force vector (8x1)
  PUBLIC :: PH_Elem_B21T_ConsMassMatrix        ! Form consistent mass matrix (8x8)
  PUBLIC :: PH_Elem_B21T_LumpMassVector        ! Form lumped mass vector (8x1)
  PUBLIC :: UF_Elem_B21T_Calc                  ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Core Stiffness Matrix Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B21T_FormStiffMatrix(coords3, E_young, nu, area, I_bend, &
       k_thermal, alpha_cte, Ke8, status)
    !-------------------------------------------------------------------------
    ! Purpose: Form total 8x8 stiffness matrix including:
    !   - Mechanical block (6x6) from B23 beam theory
    !   - Thermal conduction block (2x2) 
    !   - Thermo-mechanical coupling K_ut/K_tu (axial thermal expansion)
    ! Args:
    !   coords3  (in) : 3x2 nodal coordinates (x,y,z for 2 nodes)
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia about z-axis
    !   k_thermal(in) : Thermal conductivity
    !   alpha_cte(in) : Coefficient of thermal expansion
    !   Ke8      (out): 8x8 element stiffness matrix
    !   status   (out): Error status
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend, k_thermal, alpha_cte
    REAL(wp), INTENT(OUT) :: Ke8(8, 8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: Ke6(6, 6), Ke_tt2(2, 2)
    REAL(wp) :: el_len, kfac

    CALL init_error_status(status)
    Ke8 = 0.0_wp
    
    ! Form mechanical stiffness (6x6) using B23 kernel
    CALL PH_Elem_B23_FormStiffMatrixWithSection(coords3, E_young, nu, area, I_bend, Ke6)
    
    ! Assemble mechanical block into 8x8 matrix
    Ke8(1:3, 1:3)   = Ke6(1:3, 1:3)    ! Node 1 mech-mech
    Ke8(1:3, 5:7)   = Ke6(1:3, 4:6)    ! Node 1 mech - Node 2 mech
    Ke8(5:7, 1:3)   = Ke6(4:6, 1:3)    ! Node 2 mech - Node 1 mech
    Ke8(5:7, 5:7)   = Ke6(4:6, 4:6)    ! Node 2 mech-mech
    
    ! Form thermal conduction matrix (1D link k_th/L)
    el_len = SQRT((coords3(1, 2) - coords3(1, 1))**2 + &
                  (coords3(2, 2) - coords3(2, 1))**2)
    Ke_tt2 = 0.0_wp
    IF (el_len > 1.0e-20_wp .AND. k_thermal > 1.0e-30_wp) THEN
      kfac = k_thermal / el_len
      Ke_tt2(1, 1) =  kfac
      Ke_tt2(1, 2) = -kfac
      Ke_tt2(2, 1) = -kfac
      Ke_tt2(2, 2) =  kfac
    END IF
    
    ! Assemble thermal block (DOF 4, 8 = temperatures)
    Ke8(4, 4) = Ke_tt2(1, 1)
    Ke8(4, 8) = Ke_tt2(1, 2)
    Ke8(8, 4) = Ke_tt2(2, 1)
    Ke8(8, 8) = Ke_tt2(2, 2)
    
    ! Add thermo-mechanical coupling if CTE is non-zero
    IF (ABS(alpha_cte) > 1.0e-30_wp .AND. el_len > 1.0e-20_wp .AND. &
        area > 1.0e-30_wp .AND. E_young > 1.0e-30_wp) THEN
      CALL PH_Elem_B21T_FillKutAxial(coords3, E_young, area, alpha_cte, el_len, Ke8)
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B21T_FormStiffMatrix

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B21T_FormIntForce(coords3, u8, E_young, nu, area, I_bend, &
       k_thermal, alpha_cte, R8, status)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    ! Args:
    !   coords3  (in) : 3x2 nodal coordinates
    !   u8       (in) : 8x1 displacement vector (mech + temp)
    !   E_young  (in) : Young's modulus
    !   nu       (in) : Poisson's ratio
    !   area     (in) : Cross-sectional area
    !   I_bend   (in) : Bending inertia
    !   k_thermal(in) : Thermal conductivity
    !   alpha_cte(in) : CTE
    !   R8       (out): 8x1 internal force vector
    !   status   (out): Error status
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: u8(8)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, I_bend, k_thermal, alpha_cte
    REAL(wp), INTENT(OUT) :: R8(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: Ke8(8, 8)

    CALL init_error_status(status)
    
    ! Compute stiffness and multiply by displacements
    CALL PH_Elem_B21T_FormStiffMatrix(coords3, E_young, nu, area, I_bend, &
         k_thermal, alpha_cte, Ke8, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    R8 = MATMUL(Ke8, u8)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B21T_FormIntForce
  
  !===========================================================================
  ! Consistent Mass Matrix Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B21T_ConsMassMatrix(coords3, rho, area, Me8, status)
    !-------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for B21T element
    !          Translational DOF only (rotary inertia neglected in 2D beam)
    ! Args:
    !   coords3  (in) : 3x2 nodal coordinates
    !   rho      (in) : Material density
    !   area     (in) : Cross-sectional area
    !   Me8      (out): 8x8 consistent mass matrix
    !   status   (out): Error status
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me8(8, 8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_bar
    
    CALL init_error_status(status)
    Me8 = ZERO
    
    ! Extract 2D coordinates and compute length
    x1(1) = coords3(1, 1)
    x1(2) = coords3(2, 1)
    x2(1) = coords3(1, 2)
    x2(2) = coords3(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) RETURN
    
    ! Consistent mass coefficients (translational DOF only)
    m_bar = rho * area * L / 6.0_wp
    
    ! Node 1 translational DOF (u_x, u_y)
    Me8(1, 1) = 2.0_wp * m_bar
    Me8(2, 2) = 2.0_wp * m_bar
    
    ! Node 2 translational DOF (u_x, u_y)
    Me8(5, 5) = 2.0_wp * m_bar
    Me8(6, 6) = 2.0_wp * m_bar
    
    ! Coupling terms (node 1 - node 2)
    Me8(1, 5) = m_bar
    Me8(2, 6) = m_bar
    Me8(5, 1) = m_bar
    Me8(6, 2) = m_bar
    
    ! Note: Rotary inertia (DOF 3, 7) and thermal DOF (4, 8) not included
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B21T_ConsMassMatrix
  
  !===========================================================================
  ! Lumped Mass Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B21T_LumpMassVector(coords3, rho, area, M_lumped8, status)
    !-------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector (diagonal mass matrix as vector)
    ! Args:
    !   coords3    (in) : 3x2 nodal coordinates
    !   rho        (in) : Material density
    !   area       (in) : Cross-sectional area
    !   M_lumped8  (out): 8x1 lumped mass vector
    !   status     (out): Error status
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lumped8(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: x1(2), x2(2), dx(2), L, m_half
    
    CALL init_error_status(status)
    M_lumped8 = ZERO
    
    ! Compute element length
    x1(1) = coords3(1, 1)
    x1(2) = coords3(2, 1)
    x2(1) = coords3(1, 2)
    x2(2) = coords3(2, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (L <= 1.0e-12_wp) RETURN
    
    ! Equal mass distribution to each node (translational DOF only)
    m_half = rho * area * L * 0.5_wp
    
    ! Node 1: u_x, u_y (DOF 1, 2)
    M_lumped8(1) = m_half
    M_lumped8(2) = m_half
    
    ! Node 2: u_x, u_y (DOF 5, 6)
    M_lumped8(5) = m_half
    M_lumped8(6) = m_half
    
    ! Note: Rotary inertia (DOF 3, 7) and thermal DOF (4, 8) = 0
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B21T_LumpMassVector

  !===========================================================================
  ! Unified Element Calculation Interface (UFC L3->L4 Bridge)
  !===========================================================================
  SUBROUTINE UF_Elem_B21T_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B21T
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
    REAL(wp) :: coords(3, 2)           ! Working coordinates (3D for B23 kernel)
    REAL(wp) :: u8(8)                  ! Displacement vector (6 mech + 2 therm)
    REAL(wp) :: E_young, nu, k_th, area_a, I_bend, alpha_cte
    REAL(wp) :: Ke8(8, 8), R8(8)       ! Element matrices
    TYPE(MatProperties) :: props       ! Material property wrapper
    TYPE(ErrorStatusType) :: st        ! Local error status

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    
    !-----------------------------------------------------------------------
    ! Validation: Element topology
    !-----------------------------------------------------------------------
    IF (ElemType%numNodes /= PH_B21T_NNODE .OR. ElemType%dim /= 2_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B21T_Calc: expect 2-node 2D beam (B21T)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Context data availability
    !-----------------------------------------------------------------------
    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < PH_B21T_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B21T_Calc: coords_ref missing or insufficient'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Extract coordinates (embed 2D beam in 3D space for B23 kernel)
    !-----------------------------------------------------------------------
    coords(1:2, 1:2) = Ctx%coords_ref(1:2, 1:2)
    coords(3, 1:2)   = 0.0_wp  ! z-coordinate = 0 for plane beam

    !-----------------------------------------------------------------------
    ! Extract displacement vector (8 DOF: 6 mech + 2 temp)
    !-----------------------------------------------------------------------
    u8 = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= PH_B21T_NNODE) THEN
      ! Mechanical DOF (u_x, u_y, theta_z)
      u8(1) = Ctx%disp_total(1, 1)  ! Node 1 u_x
      u8(2) = Ctx%disp_total(2, 1)  ! Node 1 u_y
      u8(3) = Ctx%disp_total(3, 1)  ! Node 1 theta_z
      u8(5) = Ctx%disp_total(1, 2)  ! Node 2 u_x
      u8(6) = Ctx%disp_total(2, 2)  ! Node 2 u_y
      u8(7) = Ctx%disp_total(3, 2)  ! Node 2 theta_z
      
      ! Thermal DOF (temperature)
      IF (SIZE(Ctx%disp_total, 1) >= 4_i4) THEN
        u8(4) = Ctx%disp_total(4, 1)  ! Node 1 T
        u8(8) = Ctx%disp_total(4, 2)  ! Node 2 T
      END IF
    END IF

    !-----------------------------------------------------------------------
    ! Extract material properties
    !-----------------------------------------------------------------------
    E_young   = 0.0_wp
    nu        = 0.3_wp
    k_th      = 50.0_wp   ! Default thermal conductivity
    alpha_cte = 0.0_wp    ! Default CTE = 0 (no coupling)
    
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      ! Elastic constants
      IF (SIZE(props%props) >= PH_B21T_PROP_E) &
        E_young = props%props(PH_B21T_PROP_E)
      IF (SIZE(props%props) >= PH_B21T_PROP_NU) &
        nu = props%props(PH_B21T_PROP_NU)
      
      ! Thermal conductivity (optional props(7))
      IF (SIZE(props%props) >= 7_i4) THEN
        IF (props%props(7) > 1.0e-6_wp .AND. props%props(7) < 500.0_wp) &
          k_th = props%props(7)
      END IF
      
      ! CTE (optional props(8))
      IF (SIZE(props%props) >= 8_i4) &
        alpha_cte = props%props(8)
    END IF

    !-----------------------------------------------------------------------
    ! Extract section properties (area, inertia)
    !-----------------------------------------------------------------------
    area_a = 1.0_wp
    I_bend = 1.0_wp
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= 3_i4 .AND. props%props(3) > 0.0_wp) &
        area_a = props%props(3)
      IF (SIZE(props%props) >= 4_i4 .AND. props%props(4) > 0.0_wp) &
        I_bend = props%props(4)
    END IF

    !-----------------------------------------------------------------------
    ! Validation: Material parameters
    !-----------------------------------------------------------------------
    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_B21T_Calc: invalid Young modulus (must be > 0)'
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Compute element stiffness matrix
    !-----------------------------------------------------------------------
    CALL PH_Elem_B21T_FormStiffMatrix(coords, E_young, nu, area_a, I_bend, &
         k_th, alpha_cte, Ke8, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Compute internal force vector
    !-----------------------------------------------------------------------
    CALL PH_Elem_B21T_FormIntForce(coords, u8, E_young, nu, area_a, I_bend, &
         k_th, alpha_cte, R8, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    !-----------------------------------------------------------------------
    ! Ensure output storage and assign results
    !-----------------------------------------------------------------------
    CALL PH_B21T_EnsureStorage8(state_out)
    state_out%evo%Ke(1:8, 1:8) = Ke8
    state_out%Re(1:8)      = R8

    !-----------------------------------------------------------------------
    ! Set output flags
    !-----------------------------------------------------------------------
    flags%status%status_code = IF_STATUS_OK
    flags%requires_reasse    = .TRUE.   ! Trigger global assembly
    state_out%failed         = flags%failed
    state_out%stableDt       = flags%stableDt
    
  END SUBROUTINE UF_Elem_B21T_Calc

  !===========================================================================
  ! Storage Management
  !===========================================================================
  SUBROUTINE PH_B21T_EnsureStorage8(state_out)
    !-------------------------------------------------------------------------
    ! Purpose: Ensure state_out has properly sized Ke and Re arrays
    ! Args:
    !   state_out (inout): Element state to allocate/resize
    !-------------------------------------------------------------------------
    TYPE(ElemState), INTENT(INOUT) :: state_out
    
    ! Allocate or resize stiffness matrix
    IF (.NOT. ASSOCIATED(state_out%evo%Ke)) THEN
      ALLOCATE(state_out%evo%Ke(8, 8))
    ELSE IF (SIZE(state_out%evo%Ke, 1) /= PH_B21T_NDOF_TOTAL .OR. &
             SIZE(state_out%evo%Ke, 2) /= PH_B21T_NDOF_TOTAL) THEN
      DEALLOCATE(state_out%evo%Ke)
      ALLOCATE(state_out%evo%Ke(8, 8))
    END IF
    
    ! Allocate or resize force vector
    IF (.NOT. ASSOCIATED(state_out%Re)) THEN
      ALLOCATE(state_out%Re(PH_B21T_NDOF_TOTAL))
    ELSE IF (SIZE(state_out%Re) /= PH_B21T_NDOF_TOTAL) THEN
      DEALLOCATE(state_out%Re)
      ALLOCATE(state_out%Re(PH_B21T_NDOF_TOTAL))
    END IF
  END SUBROUTINE PH_B21T_EnsureStorage8

  !===========================================================================
  ! Thermo-Mechanical Coupling Matrix (K_ut)
  !===========================================================================
  SUBROUTINE PH_Elem_B21T_FillKutAxial(coords3, E_young, area, alpha_cte, el_len, Ke8)
    !-------------------------------------------------------------------------
    ! Purpose: Fill axial thermal-mechanical coupling submatrices K_ut and K_tu
    ! Theory:
    !   Axial thermal strain: epsilon_th = alpha * T(xi)
    !   where T varies linearly between nodal temperatures (DOF 4, 8)
    !   
    !   Local coordinates: K_ut,loc = E*A*alpha * integral(B_axial^T * N_T dV)
    !   Global: K_ut,global = T^T * K_ut,loc (transformed to global coords)
    !   
    !   Sign convention: +alpha (matches B31T and continuum K_ut)
    ! Args:
    !   coords3  (in) : 3x2 nodal coordinates
    !   E_young  (in) : Young's modulus
    !   area     (in) : Cross-sectional area
    !   alpha_cte(in) : Coefficient of thermal expansion
    !   el_len   (in) : Element length
    !   Ke8      (inout): 8x8 stiffness matrix (K_ut, K_tu blocks filled here)
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, area, alpha_cte, el_len
    REAL(wp), INTENT(INOUT):: Ke8(8, 8)

    ! Local variables for coordinate transformation
    REAL(wp) :: x1(2), x2(2), dx(2), Lloc, c, s
    REAL(wp) :: T_mat(6, 6)          ! Transformation matrix (mechanical DOF)
    REAL(wp) :: bl(6)                ! Axial B-matrix row (local)
    REAL(wp) :: fac                  ! Scaling factor E*A*alpha*L/2
    REAL(wp) :: kut_l(6, 2)          ! Local K_ut (6 mech x 2 therm)
    REAL(wp) :: kut_g(6, 2)          ! Global K_ut (transformed)

    !-----------------------------------------------------------------------
    ! Compute element geometry and direction cosines
    !-----------------------------------------------------------------------
    x1(1) = coords3(1, 1)
    x1(2) = coords3(2, 1)
    x2(1) = coords3(1, 2)
    x2(2) = coords3(2, 2)
    dx = x2 - x1
    Lloc = SQRT(dx(1)*dx(1) + dx(2)*dx(2))
    
    IF (Lloc <= 1.0e-20_wp) RETURN  ! Degenerate element
    
    c = dx(1) / Lloc  ! cos(theta)
    s = dx(2) / Lloc  ! sin(theta)
    
    !-----------------------------------------------------------------------
    ! Build transformation matrix T (6x6 for 2D beam)
    ! Block diagonal: [R] for each node's mechanical DOF
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
    ! Axial B-matrix row (derivative of axial displacement)
    ! B_axial = [-1/L, 1/L] for linear shape functions
    !-----------------------------------------------------------------------
    bl = 0.0_wp
    bl(1) = -1.0_wp / el_len   ! Node 1 axial strain contribution
    bl(4) =  1.0_wp / el_len   ! Node 2 axial strain contribution
    
    !-----------------------------------------------------------------------
    ! Compute local K_ut matrix
    ! K_ut,loc = E*A*alpha * integral_0^L (B_axial^T * N_T dx)
    ! For linear N_T and constant B_axial: factor = E*A*alpha*L/2
    !-----------------------------------------------------------------------
    fac = E_young * area * alpha_cte * 0.5_wp * el_len
    kut_l(1:6, 1) = fac * bl(1:6)  ! Column for Node 1 temperature
    kut_l(1:6, 2) = kut_l(1:6, 1)  ! Column for Node 2 temperature (same)
    
    !-----------------------------------------------------------------------
    ! Transform to global coordinates
    !-----------------------------------------------------------------------
    kut_g = MATMUL(TRANSPOSE(T_mat), kut_l)

    !-----------------------------------------------------------------------
    ! Assemble into full 8x8 stiffness matrix
    ! K_ut: mech rows (1-3, 5-7), therm cols (4, 8)
    ! K_tu: therm rows (4, 8), mech cols (1-3, 5-7) = transpose
    !-----------------------------------------------------------------------
    ! K_ut block (mechanical DOF x thermal DOF)
    Ke8(1:3, 4)   = kut_g(1:3, 1)  ! Node 1 mech x Node 1 temp
    Ke8(5:7, 4)   = kut_g(4:6, 1)  ! Node 2 mech x Node 1 temp
    Ke8(1:3, 8)   = kut_g(1:3, 2)  ! Node 1 mech x Node 2 temp
    Ke8(5:7, 8)   = kut_g(4:6, 2)  ! Node 2 mech x Node 2 temp
    
    ! K_tu block (thermal DOF x mechanical DOF) = transpose of K_ut
    Ke8(4, 1:3)   = kut_g(1:3, 1)  ! Node 1 temp x Node 1 mech
    Ke8(4, 5:7)   = kut_g(4:6, 1)  ! Node 1 temp x Node 2 mech
    Ke8(8, 1:3)   = kut_g(1:3, 2)  ! Node 2 temp x Node 1 mech
    Ke8(8, 5:7)   = kut_g(4:6, 2)  ! Node 2 temp x Node 2 mech
    
  END SUBROUTINE PH_Elem_B21T_FillKutAxial

END MODULE PH_Elem_B21T