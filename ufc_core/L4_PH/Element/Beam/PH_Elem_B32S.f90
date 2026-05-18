!===============================================================================
! MODULE: PH_Elem_B32S
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B32S 3D Timoshenko beam element
!===============================================================================
MODULE PH_Elem_B32S
  USE IF_Base_Def,        ONLY: ZERO, ONE, HALF
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Base_ElemLib
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib,      ONLY: MatProperties
  
  IMPLICIT NONE
  PRIVATE
  
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32S_NNODE   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32S_NDOF    = 18_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32S_NEDGE   = 0_i4
  
  REAL(wp), PARAMETER, PUBLIC :: PH_B32S_KAPPA_DEFAULT = 5.0_wp / 6.0_wp
  
  ! Property indices
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_E     = 1_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_NU    = 2_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_A     = 3_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_IY    = 4_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_IZ    = 5_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_J     = 6_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32S_PROP_KAPPA = 7_i4
  
  PUBLIC :: PH_Elem_B32S_DefInit
  PUBLIC :: PH_Elem_B32S_FormStiffMatrixWithShear
  PUBLIC :: PH_Elem_B32S_FormIntForce
  PUBLIC :: PH_Elem_B32S_ConsMassWithSection
  PUBLIC :: PH_Elem_B32S_LumpMassWithSection
  PUBLIC :: UF_Elem_B32S_Calc

CONTAINS

  SUBROUTINE PH_Elem_B32S_DefInit(ElemDef, status)
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    ElemDef%numNodes = PH_ELEM_B32S_NNODE
    ElemDef%dim = 3_i4
    ElemDef%dofPerNode = 6_i4
    ElemDef%totalDOF = PH_ELEM_B32S_NDOF
    ElemDef%name = 'B32S'
    ElemDef%cfg%description = '3-node 3D Timoshenko beam with shear'
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B32S_DefInit

  SUBROUTINE PH_Elem_B32S_FormStiffMatrixWithShear(coords, props, Ke18)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(OUT) :: Ke18(18, 18)
    
    ! 3-node Timoshenko beam: K = K_bending + K_shear
    ! props: (1)E, (2)nu, (3)A, (4)Iy, (5)Iz, (6)J, (7)kappa
    REAL(wp) :: E, nu, G, A, Iy, Iz, J_tors, kappa
    REAL(wp) :: L, dx, dy, dz
    REAL(wp) :: phi_y, phi_z
    REAL(wp) :: EIy, EIz, EA, GJ, kGA
    REAL(wp) :: Ke_loc(18, 18)
    INTEGER(i4) :: i
    
    Ke18 = ZERO
    
    ! Extract properties
    E = props(PH_B32S_PROP_E)
    nu = props(PH_B32S_PROP_NU)
    A = props(PH_B32S_PROP_A)
    Iy = props(PH_B32S_PROP_IY)
    Iz = props(PH_B32S_PROP_IZ)
    J_tors = props(PH_B32S_PROP_J)
    IF (SIZE(props) >= PH_B32S_PROP_KAPPA) THEN
      kappa = props(PH_B32S_PROP_KAPPA)
    ELSE
      kappa = PH_B32S_KAPPA_DEFAULT
    END IF
    
    G = E / (2.0_wp * (1.0_wp + nu))
    
    ! Element length (distance node1 to node3, node2=midside)
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L < 1.0e-14_wp) RETURN
    
    ! Derived quantities
    EA  = E * A
    EIy = E * Iy
    EIz = E * Iz
    GJ  = G * J_tors
    kGA = kappa * G * A
    
    ! Shear deformation parameters
    phi_y = 12.0_wp * EIz / (kGA * L * L)
    phi_z = 12.0_wp * EIy / (kGA * L * L)
    
    ! Build local stiffness in element coords
    ! 3-node beam: nodes at s=-1, 0, +1 (parametric)
    ! Using condensed form with shear correction
    Ke_loc = ZERO
    
    ! Axial DOFs (1, 7, 13) - quadratic interpolation
    Ke_loc(1, 1)   =  7.0_wp * EA / (3.0_wp * L)
    Ke_loc(1, 7)   = -8.0_wp * EA / (3.0_wp * L)
    Ke_loc(1, 13)  =  1.0_wp * EA / (3.0_wp * L)
    Ke_loc(7, 7)   = 16.0_wp * EA / (3.0_wp * L)
    Ke_loc(7, 13)  = -8.0_wp * EA / (3.0_wp * L)
    Ke_loc(13, 13) =  7.0_wp * EA / (3.0_wp * L)
    
    ! Torsion DOFs (4, 10, 16) - quadratic interpolation
    Ke_loc(4, 4)   =  7.0_wp * GJ / (3.0_wp * L)
    Ke_loc(4, 10)  = -8.0_wp * GJ / (3.0_wp * L)
    Ke_loc(4, 16)  =  1.0_wp * GJ / (3.0_wp * L)
    Ke_loc(10, 10) = 16.0_wp * GJ / (3.0_wp * L)
    Ke_loc(10, 16) = -8.0_wp * GJ / (3.0_wp * L)
    Ke_loc(16, 16) =  7.0_wp * GJ / (3.0_wp * L)
    
    ! Bending in y-z plane (DOF 2,6 / 8,12 / 14,18) with shear correction
    ! K_bend = EIz * [...] / (1 + phi_y)
    BLOCK
      REAL(wp) :: c1, c2, c3, c4
      c1 = EIz / (L * L * L * (1.0_wp + phi_y))
      
      ! Node 1-1 block (2x2: v, theta_z)
      Ke_loc(2, 2)   = c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(2, 6)   = c1 * 6.0_wp * L
      Ke_loc(6, 6)   = c1 * (4.0_wp + phi_y) * L * L
      
      ! Node 1-3 block
      Ke_loc(2, 14)  = -c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(2, 18)  = c1 * 6.0_wp * L
      Ke_loc(6, 14)  = -c1 * 6.0_wp * L
      Ke_loc(6, 18)  = c1 * (2.0_wp - phi_y) * L * L
      
      ! Node 3-3 block
      Ke_loc(14, 14) = c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(14, 18) = -c1 * 6.0_wp * L
      Ke_loc(18, 18) = c1 * (4.0_wp + phi_y) * L * L
      
      ! Midside coupling (node 2: DOF 8, 12)
      Ke_loc(2, 8)   = c1 * (-16.0_wp * 12.0_wp / 3.0_wp)
      Ke_loc(8, 8)   = c1 * 16.0_wp * 12.0_wp / 3.0_wp * 2.0_wp
      Ke_loc(8, 14)  = c1 * (-16.0_wp * 12.0_wp / 3.0_wp)
      Ke_loc(8, 12)  = ZERO
      Ke_loc(12, 12) = c1 * 16.0_wp * L * L / 3.0_wp
    END BLOCK
    
    ! Bending in x-z plane (DOF 3,5 / 9,11 / 15,17) with shear correction
    BLOCK
      REAL(wp) :: c1
      c1 = EIy / (L * L * L * (1.0_wp + phi_z))
      
      Ke_loc(3, 3)   = c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(3, 5)   = -c1 * 6.0_wp * L
      Ke_loc(5, 5)   = c1 * (4.0_wp + phi_z) * L * L
      
      Ke_loc(3, 15)  = -c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(3, 17)  = -c1 * 6.0_wp * L
      Ke_loc(5, 15)  = c1 * 6.0_wp * L
      Ke_loc(5, 17)  = c1 * (2.0_wp - phi_z) * L * L
      
      Ke_loc(15, 15) = c1 * 12.0_wp * 7.0_wp / 3.0_wp
      Ke_loc(15, 17) = c1 * 6.0_wp * L
      Ke_loc(17, 17) = c1 * (4.0_wp + phi_z) * L * L
      
      Ke_loc(3, 9)   = c1 * (-16.0_wp * 12.0_wp / 3.0_wp)
      Ke_loc(9, 9)   = c1 * 16.0_wp * 12.0_wp / 3.0_wp * 2.0_wp
      Ke_loc(9, 15)  = c1 * (-16.0_wp * 12.0_wp / 3.0_wp)
      Ke_loc(11, 11) = c1 * 16.0_wp * L * L / 3.0_wp
    END BLOCK
    
    ! Symmetrize
    DO i = 1, 18
      Ke_loc(i+1:18, i) = Ke_loc(i, i+1:18)
    END DO
    
    Ke18 = Ke_loc
  END SUBROUTINE PH_Elem_B32S_FormStiffMatrixWithShear

  SUBROUTINE PH_Elem_B32S_FormIntForce(coords, props, u18, R18)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(IN)  :: u18(18)
    REAL(wp), INTENT(OUT) :: R18(18)
    REAL(wp) :: Ke18(18, 18)
    
    R18 = ZERO
    CALL PH_Elem_B32S_FormStiffMatrixWithShear(coords, props, Ke18)
    R18 = MATMUL(Ke18, u18)
  END SUBROUTINE PH_Elem_B32S_FormIntForce

  SUBROUTINE PH_Elem_B32S_ConsMassWithSection(coords, rho, area, Me18)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me18(18, 18)
    
    ! Consistent mass with rotary inertia for Timoshenko beam
    ! M = int(rho * [N_u^T N_u + I_rho * N_theta^T N_theta] dV)
    REAL(wp) :: L, dx, dy, dz, mL
    REAL(wp) :: m_trans, I_rot
    INTEGER(i4) :: i
    
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L < 1.0e-14_wp) THEN
      Me18 = ZERO
      RETURN
    END IF
    
    mL = rho * area * L
    ! Rotary inertia: I_rho = rho * I_p (polar moment)
    I_rot = rho * area * L / 12.0_wp  ! simplified
    
    Me18 = ZERO
    
    ! 3-node quadratic: mass distribution [1/6, 2/3, 1/6]
    ! Node 1 (DOF 1-6): translational + rotational
    DO i = 1, 3
      Me18(i, i) = mL / 6.0_wp  ! translational
    END DO
    DO i = 4, 6
      Me18(i, i) = I_rot / 6.0_wp  ! rotational inertia
    END DO
    
    ! Node 2 midside (DOF 7-12): 2/3 mass
    DO i = 7, 9
      Me18(i, i) = mL * 2.0_wp / 3.0_wp
    END DO
    DO i = 10, 12
      Me18(i, i) = I_rot * 2.0_wp / 3.0_wp
    END DO
    
    ! Node 3 (DOF 13-18): 1/6 mass
    DO i = 13, 15
      Me18(i, i) = mL / 6.0_wp
    END DO
    DO i = 16, 18
      Me18(i, i) = I_rot / 6.0_wp
    END DO
  END SUBROUTINE PH_Elem_B32S_ConsMassWithSection

  SUBROUTINE PH_Elem_B32S_LumpMassWithSection(coords, rho, area, M_lump18)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lump18(18)
    
    ! HRZ lumped mass for 3-node Timoshenko beam
    ! Distribution: [1/6, 2/3, 1/6] (Simpson's rule)
    REAL(wp) :: L, dx, dy, dz, mL, I_rot
    
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L < 1.0e-14_wp) THEN
      M_lump18 = ZERO
      RETURN
    END IF
    
    mL = rho * area * L
    I_rot = rho * area * L / 12.0_wp
    
    M_lump18 = ZERO
    ! Node 1: 1/6
    M_lump18(1:3) = mL / 6.0_wp
    M_lump18(4:6) = I_rot / 6.0_wp
    ! Node 2 (midside): 2/3
    M_lump18(7:9)   = mL * 2.0_wp / 3.0_wp
    M_lump18(10:12) = I_rot * 2.0_wp / 3.0_wp
    ! Node 3: 1/6
    M_lump18(13:15) = mL / 6.0_wp
    M_lump18(16:18) = I_rot / 6.0_wp
  END SUBROUTINE PH_Elem_B32S_LumpMassWithSection

  SUBROUTINE UF_Elem_B32S_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ElemFormul), INTENT(IN) :: formul
    TYPE(ElemCtx), INTENT(IN) :: ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: mat_props
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    
    ! Full B32S calculation workflow:
    ! 1. Extract coordinates and properties from ctx/mat_props
    ! 2. Compute stiffness with shear correction
    ! 3. Compute internal force
    ! 4. Optionally compute mass
    REAL(wp) :: coords_loc(3, 3), props_loc(7)
    REAL(wp) :: Ke18(18, 18), u18(18), R18(18)
    
    flags%failed = .FALSE.
    
    ! Extract coordinates (assuming ctx has nodal coords)
    IF (ALLOCATED(ctx%coords)) THEN
      coords_loc = RESHAPE(ctx%coords(1:9), [3, 3])
    ELSE
      flags%failed = .TRUE.
      RETURN
    END IF
    
    ! Extract material properties
    IF (ALLOCATED(mat_props%props)) THEN
      props_loc = ZERO
      props_loc(1:MIN(SIZE(mat_props%props), 7)) = &
        mat_props%props(1:MIN(SIZE(mat_props%props), 7))
    ELSE
      flags%failed = .TRUE.
      RETURN
    END IF
    
    ! Step 1: Compute stiffness
    CALL PH_Elem_B32S_FormStiffMatrixWithShear(coords_loc, props_loc, Ke18)
    
    ! Step 2: Compute internal force (R = Ke * u)
    IF (ALLOCATED(state_in%displacement)) THEN
      u18 = ZERO
      u18(1:MIN(SIZE(state_in%displacement), 18)) = &
        state_in%displacement(1:MIN(SIZE(state_in%displacement), 18))
      CALL PH_Elem_B32S_FormIntForce(coords_loc, props_loc, u18, R18)
    END IF
    
    ! Step 3: Store results in state_out
    IF (ALLOCATED(state_out%stiffness)) THEN
      state_out%stiffness(1:18, 1:18) = Ke18
    END IF
    IF (ALLOCATED(state_out%internal_force)) THEN
      state_out%internal_force(1:18) = R18
    END IF
    
  END SUBROUTINE UF_Elem_B32S_Calc

END MODULE PH_Elem_B32S