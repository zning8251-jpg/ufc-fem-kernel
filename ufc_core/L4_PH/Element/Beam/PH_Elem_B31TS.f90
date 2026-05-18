!===============================================================================
! MODULE: PH_Elem_B31TS
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31TS Timoshenko beam with thermal coupling
!===============================================================================
MODULE PH_Elem_B31TS
  !===========================================================================
  ! Module Dependencies (Layered Architecture)
  !===========================================================================
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF, TWO, THREE      ! Math constants
  USE IF_Prec_Core,         ONLY: wp, i4                            ! Precision kinds
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID  ! Error handling
  
  ! L3_MD: Model definitions
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState, &
                             UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib,      ONLY: MatProperties
  USE MD_Mat_Lib,      ONLY: MatPropertyDef
  USE UF_Material_Base
  
  IMPLICIT NONE
  PRIVATE
  
  !===========================================================================
  ! Public Constants - Element DOF information
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NNODE   = 2_i4   ! Number of nodes
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NIP     = 2_i4   ! Integration points
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NDOF    = 14_i4  ! Total DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NDOF_MECH = 12_i4 ! Mechanical DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NDOF_THERM = 2_i4 ! Thermal DOF
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B31TS_NEDGE   = 0_i4   ! Number of edges
  
  ! Property indices (for props array access)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_E     = 1_i4   ! Young's modulus
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_NU    = 2_i4   ! Poisson's ratio
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_A     = 3_i4   ! Area
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_IY    = 4_i4   ! Inertia y
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_IZ    = 5_i4   ! Inertia z
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_J     = 6_i4   ! Torsion constant
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_KAPPA = 7_i4   ! Shear factor
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_ALPHA = 8_i4   ! CTE
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B31TS_PROP_KTH   = 9_i4   ! Thermal cond.
  
  ! Numerical tolerance
  REAL(wp), PARAMETER, PRIVATE :: PH_B31TS_TOL = 1.0e-8_wp
  
  ! Default shear correction factor (rectangular cross-section)
  REAL(wp), PARAMETER, PUBLIC :: PH_B31TS_KAPPA_DEFAULT = 5.0_wp / 6.0_wp
  
  !===========================================================================
  ! Public API - Core computational subroutines
  !===========================================================================
  PUBLIC :: PH_Elem_B31TS_DefInit               ! Element definition initialization
  PUBLIC :: PH_Elem_B31TS_FormStiffMatrixWithShear ! Form stiffness with shear (14x14)
  PUBLIC :: PH_Elem_B31TS_FormIntForce          ! Internal force vector (14x1)
  PUBLIC :: PH_Elem_B31TS_ConsMass              ! Consistent mass matrix (14x14)
  PUBLIC :: PH_Elem_B31TS_ConsMassWithSection   ! Consistent mass with section
  PUBLIC :: PH_Elem_B31TS_LumpMass              ! Lump mass vector (14x1)
  PUBLIC :: PH_Elem_B31TS_LumpMassWithSection   ! Lump mass with section
  PUBLIC :: UF_Elem_B31TS_Calc                  ! Unified element calculation interface

CONTAINS

  !===========================================================================
  ! Element Definition Initialization
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_DefInit(ElemDef, status)
    !-------------------------------------------------------------------------
    ! Purpose: Initialize B31TS element definition descriptor
    ! Args:
    !   ElemDef (inout): Element definition to initialize
    !   status  (out)  : Error status
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ElemDef%numNodes = PH_ELEM_B31TS_NNODE
    ElemDef%dim = 3_i4
    ElemDef%dofPerNode = 7_i4  ! 6 mech + 1 temp
    ElemDef%totalDOF = PH_ELEM_B31TS_NDOF
    ElemDef%name = 'B31TS'
    ElemDef%cfg%description = '2-node 3D Timoshenko beam + thermal'
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31TS_DefInit

  !===========================================================================
  ! Stiffness Matrix Formation (with Shear + Thermal Coupling)
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_FormStiffMatrixWithShear(coords, props, Ke14)
    !-------------------------------------------------------------------------
    ! Purpose: Form 14x14 stiffness matrix including:
    !   - Mechanical block (12x12) with Timoshenko shear deformation
    !   - Thermal conduction block (2x2)
    !   - Thermo-mechanical coupling (12x2)
    ! Args:
    !   coords   (in) : 3x2 nodal coordinates
    !   props    (in) : Material/section properties array
    !   Ke14     (out): 14x14 stiffness matrix
    ! Theory:
    !   K_total = K_axial + K_bending + K_shear + K_torsion + K_thermal
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(OUT) :: Ke14(14, 14)
    
    REAL(wp) :: Ke_mech(12, 12), Ke_tt(2, 2), Ke_ut(12, 2), Ke_tu(2, 12)
    REAL(wp) :: x1(3), x2(3), dx(3), L
    REAL(wp) :: E, G, A, Iy, Iz, J_tors, kappa
    REAL(wp) :: alpha_cte, k_th
    REAL(wp) :: c(3), s(3), R_local(3,3), R_global(3,3)
    INTEGER(i4) :: i, j
    
    Ke14 = ZERO
    
    ! Extract coordinates and compute length
    x1 = coords(:, 1)
    x2 = coords(:, 2)
    dx = x2 - x1
    L = SQRT(dx(1)*dx(1) + dx(2)*dx(2) + dx(3)*dx(3))
    
    IF (L <= 1.0e-12_wp) THEN
      Ke14(1, 1) = ONE
      RETURN
    END IF
    
    ! Extract material/section properties
    E       = props(PH_B31TS_PROP_E)
    G       = props(PH_B31TS_PROP_NU)  ! Note: Pass G directly or compute from E,nu
    A       = props(PH_B31TS_PROP_A)
    Iy      = props(PH_B31TS_PROP_IY)
    Iz      = props(PH_B31TS_PROP_IZ)
    J_tors  = props(PH_B31TS_PROP_J)
    kappa   = props(PH_B31TS_PROP_KAPPA)
    alpha_cte = props(PH_B31TS_PROP_ALPHA)
    k_th    = props(PH_B31TS_PROP_KTH)
    
    ! =====================================================
    ! 1. Local coordinate system
    ! =====================================================
    ! Basis vectors
    c = dx / L  ! Axial direction
    
    ! Construct local-to-global transformation
    R_global = RESHAPE([ &
      c(1), c(2), c(3), &
      -c(2), c(1), ZERO, &
      -c(1)*c(3), -c(2)*c(3), c(1)*c(1)+c(2)*c(2) ], [3,3])
    
    ! Normalize
    REAL(wp) :: norm2, norm3
    norm2 = SQRT(R_global(2,1)**2 + R_global(2,2)**2 + R_global(2,3)**2)
    IF (norm2 > PH_B31TS_TOL) R_global(2,:) = R_global(2,:) / norm2
    
    norm3 = SQRT(R_global(3,1)**2 + R_global(3,2)**2 + R_global(3,3)**2)
    IF (norm3 > PH_B31TS_TOL) R_global(3,:) = R_global(3,:) / norm3
    
    ! =====================================================
    ! 2. Mechanical stiffness (12x12) with TIMOSHENKO shear
    ! =====================================================
    CALL PH_Elem_B31TS_FormLocalStiffMat(L, E, G, A, Iy, Iz, J_tors, kappa, Ke_mech)
    
    ! Transform to GLOBAL coordinates
    CALL PH_Elem_B31TS_TransformStiffness(Ke_mech, R_global)
    
    ! =====================================================
    ! 3. Thermal conduction matrix (2x2)
    ! =====================================================
    REAL(wp) :: kfac
    IF (k_th > 1.0e-30_wp .AND. L > 1.0e-20_wp) THEN
      kfac = k_th / L
      Ke_tt(1, 1) =  kfac
      Ke_tt(1, 2) = -kfac
      Ke_tt(2, 1) = -kfac
      Ke_tt(2, 2) =  kfac
    END IF
    
    ! Assemble thermal block (DOF 7, 14 = temperatures)
    Ke14(7, 7)   = Ke_tt(1, 1)
    Ke14(7, 14)  = Ke_tt(1, 2)
    Ke14(14, 7)  = Ke_tt(2, 1)
    Ke14(14, 14) = Ke_tt(2, 2)
    
    ! =====================================================
    ! 4. Thermo-mechanical coupling
    ! =====================================================
    IF (ABS(alpha_cte) > 1.0e-30_wp .AND. E > 1.0e-30_wp .AND. A > 1.0e-30_wp) THEN
      REAL(wp) :: k_therm_mech
      k_therm_mech = -E * A * alpha_cte / L
      
      ! Coupling between temperature and axial DOF
      Ke14(1, 7)  = k_therm_mech
      Ke14(8, 7)  = -k_therm_mech
      Ke14(1, 14) = k_therm_mech
      Ke14(8, 14) = -k_therm_mech
      
      ! Symmetric K_tu
      Ke14(7, 1)  = k_therm_mech
      Ke14(7, 8)  = -k_therm_mech
      Ke14(14, 1) = k_therm_mech
      Ke14(14, 8) = -k_therm_mech
    END IF
    
    ! =====================================================
    ! 5. Assemble mechanical block into 14x14
    ! =====================================================
    Ke14(1:6, 1:6)     = Ke_mech(1:6, 1:6)
    Ke14(1:6, 8:13)    = Ke_mech(1:6, 7:12)
    Ke14(8:13, 1:6)    = Ke_mech(7:12, 1:6)
    Ke14(8:13, 8:13)   = Ke_mech(7:12, 7:12)
    
  END SUBROUTINE PH_Elem_B31TS_FormStiffMatrixWithShear

  !===========================================================================
  ! Helper: Form Local Stiffness Matrix (12x12) - TIMOSHENKO
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_FormLocalStiffMat(L, E, G, A, Iy, Iz, J_tors, kappa, Ke_loc)
    !-------------------------------------------------------------------------
    ! Purpose: Form 12x12 stiffness matrix in LOCAL coordinates
    !          WITH Timoshenko shear deformation
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: L, E, G, A, Iy, Iz, J_tors, kappa
    REAL(wp), INTENT(OUT) :: Ke_loc(12, 12)
    
    REAL(wp) :: k_axial, k_shear_y, k_shear_z, k_tors
    REAL(wp) :: k_bend_y, k_bend_z
    REAL(wp) :: phi_y, phi_z  ! Shear deformation parameters
    REAL(wp) :: denom_y, denom_z
    
    Ke_loc = ZERO
    
    ! Basic stiffness coefficients
    k_axial = E * A / L
    k_tors  = G * J_tors / L
    
    ! Shear stiffness (TIMOSHENKO)
    k_shear_y = kappa * G * A / L
    k_shear_z = kappa * G * A / L
    
    ! Bending stiffness
    k_bend_y = E * Iy / L
    k_bend_z = E * Iz / L
    
    ! Shear deformation parameter (phi = 12EI/(kGA*L²))
    phi_z = 12.0_wp * E * Iz / (kappa * G * A * L**2)
    phi_y = 12.0_wp * E * Iy / (kappa * G * A * L**2)
    
    ! --- Axial (DOF 1, 7) ---
    Ke_loc(1, 1) =  k_axial
    Ke_loc(1, 7) = -k_axial
    Ke_loc(7, 1) = -k_axial
    Ke_loc(7, 7) =  k_axial
    
    ! --- Torsion (DOF 4, 10) ---
    Ke_loc(4, 4) =  k_tors
    Ke_loc(4, 10) = -k_tors
    Ke_loc(10, 4) = -k_tors
    Ke_loc(10, 10) = k_tors
    
    ! --- Bending about y-axis (DOF 2, 5, 8, 11) with SHEAR ---
    denom_y = 1.0_wp + phi_y
    
    Ke_loc(2, 2) =   12.0_wp * k_bend_y / (L**2 * denom_y)
    Ke_loc(2, 5) =    6.0_wp * k_bend_y / (L * denom_y)
    Ke_loc(2, 8) =  -12.0_wp * k_bend_y / (L**2 * denom_y)
    Ke_loc(2, 11) =   6.0_wp * k_bend_y / (L * denom_y)
    
    Ke_loc(5, 2) =    Ke_loc(2, 5)
    Ke_loc(5, 5) =  (4.0_wp + phi_y) * k_bend_y / denom_y
    Ke_loc(5, 8) =   -6.0_wp * k_bend_y / (L * denom_y)
    Ke_loc(5, 11) = (2.0_wp - phi_y) * k_bend_y / denom_y
    
    Ke_loc(8, 2) =    Ke_loc(2, 8)
    Ke_loc(8, 5) =    Ke_loc(5, 8)
    Ke_loc(8, 8) =    12.0_wp * k_bend_y / (L**2 * denom_y)
    Ke_loc(8, 11) =  -6.0_wp * k_bend_y / (L * denom_y)
    
    Ke_loc(11, 2) =   Ke_loc(2, 11)
    Ke_loc(11, 5) =   Ke_loc(5, 11)
    Ke_loc(11, 8) =   Ke_loc(8, 11)
    Ke_loc(11, 11) = (4.0_wp + phi_y) * k_bend_y / denom_y
    
    ! --- Bending about z-axis (DOF 3, 6, 9, 12) with SHEAR ---
    denom_z = 1.0_wp + phi_z
    
    Ke_loc(3, 3) =    12.0_wp * k_bend_z / (L**2 * denom_z)
    Ke_loc(3, 6) =   -6.0_wp * k_bend_z / (L * denom_z)
    Ke_loc(3, 9) =   -12.0_wp * k_bend_z / (L**2 * denom_z)
    Ke_loc(3, 12) =  -6.0_wp * k_bend_z / (L * denom_z)
    
    Ke_loc(6, 3) =   -6.0_wp * k_bend_z / (L * denom_z)
    Ke_loc(6, 6) =  (4.0_wp + phi_z) * k_bend_z / denom_z
    Ke_loc(6, 9) =    6.0_wp * k_bend_z / (L * denom_z)
    Ke_loc(6, 12) =  (2.0_wp - phi_z) * k_bend_z / denom_z
    
    Ke_loc(9, 3) =    Ke_loc(3, 9)
    Ke_loc(9, 6) =    Ke_loc(6, 9)
    Ke_loc(9, 9) =    12.0_wp * k_bend_z / (L**2 * denom_z)
    Ke_loc(9, 12) =   6.0_wp * k_bend_z / (L * denom_z)
    
    Ke_loc(12, 3) =   Ke_loc(3, 12)
    Ke_loc(12, 6) =   Ke_loc(6, 12)
    Ke_loc(12, 9) =   Ke_loc(9, 12)
    Ke_loc(12, 12) = (4.0_wp + phi_z) * k_bend_z / denom_z
    
  END SUBROUTINE PH_Elem_B31TS_FormLocalStiffMat

  !===========================================================================
  ! Helper: Transform Stiffness to Global Coordinates
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_TransformStiffness(Ke_loc, R_global, Ke_glob)
    !-------------------------------------------------------------------------
    ! Purpose: Transform local stiffness to global coordinates
    ! Args:
    !   Ke_loc   (in)  : 12x12 local stiffness
    !   R_global (in)  : 3x3 rotation matrix
    !   Ke_glob  (out) : 12x12 global stiffness
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: Ke_loc(12, 12)
    REAL(wp), INTENT(IN)  :: R_global(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_glob(12, 12)
    
    REAL(wp) :: T_rot(12, 12)
    INTEGER(i4) :: i
    
    ! Build transformation matrix (block diagonal)
    T_rot = ZERO
    DO i = 1, 2  ! Per node
      ! Translational DOF
      T_rot((i-1)*6+1:(i-1)*6+3, (i-1)*6+1:(i-1)*6+3) = R_global
      ! Rotational DOF
      T_rot((i-1)*6+4:(i-1)*6+6, (i-1)*6+4:(i-1)*6+6) = R_global
    END DO
    
    ! Transform: K_global = T^T * K_local * T
    Ke_glob = MATMUL(MATMUL(TRANSPOSE(T_rot), Ke_loc), T_rot)
    
  END SUBROUTINE PH_Elem_B31TS_TransformStiffness

  !===========================================================================
  ! Internal Force Vector Formation
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_FormIntForce(coords, props, u14, R14)
    !-------------------------------------------------------------------------
    ! Purpose: Form internal force vector R = K * u
    !-------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(IN)  :: u14(14)
    REAL(wp), INTENT(OUT) :: R14(14)
    REAL(wp) :: Ke14(14, 14)
    
    R14 = ZERO
    CALL PH_Elem_B31TS_FormStiffMatrixWithShear(coords, props, Ke14)
    R14 = MATMUL(Ke14, u14)
    
  END SUBROUTINE PH_Elem_B31TS_FormIntForce

  !===========================================================================
  ! Mass Matrix Functions (same as B31T - independent of shear deformation)
  !===========================================================================
  SUBROUTINE PH_Elem_B31TS_ConsMassWithSection(coords, rho, area, Me14)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me14(14, 14)
    ! TODO: Implement consistent mass (reuse B31T)
    Me14 = ZERO
  END SUBROUTINE PH_Elem_B31TS_ConsMassWithSection

  SUBROUTINE PH_Elem_B31TS_LumpMassWithSection(coords, rho, area, M_lump14)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lump14(14)
    ! TODO: Implement lumped mass (reuse B31T)
    M_lump14 = ZERO
  END SUBROUTINE PH_Elem_B31TS_LumpMassWithSection

  !===========================================================================
  ! Unified Element Calculation Interface
  !===========================================================================
  SUBROUTINE UF_Elem_B31TS_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)
    !-------------------------------------------------------------------------
    ! Purpose: Unified element calculation interface for B31TS
    !-------------------------------------------------------------------------
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ElemFormul), INTENT(IN) :: formul
    TYPE(ElemCtx), INTENT(IN) :: ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: mat_props
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    
    ! TODO: Implement full B31TS calculation logic
    ! - Form stiffness with Timoshenko shear
    ! - Compute internal forces
    ! - Handle thermal coupling
    
    flags%failed = .FALSE.
    
  END SUBROUTINE UF_Elem_B31TS_Calc

END MODULE PH_Elem_B31TS