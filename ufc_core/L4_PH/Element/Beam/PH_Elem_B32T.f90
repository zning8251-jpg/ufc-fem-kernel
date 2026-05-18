!===============================================================================
! MODULE: PH_Elem_B32T
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B32T 3D beam with thermal coupling
!===============================================================================
MODULE PH_Elem_B32T
  USE IF_Base_Def,        ONLY: ZERO, ONE
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Base_ElemLib
  USE MD_Elem_Mgr,    ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib,      ONLY: MatProperties
  
  IMPLICIT NONE
  PRIVATE
  
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32T_NNODE   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32T_NDOF    = 21_i4  ! 18 mech + 3 therm
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32T_NDOF_MECH = 18_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32T_NDOF_THERM = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_B32T_NEDGE   = 0_i4
  
  ! Property indices
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_E     = 1_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_NU    = 2_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_A     = 3_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_IY    = 4_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_IZ    = 5_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_J     = 6_i4
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_ALPHA = 7_i4  ! CTE
  INTEGER(i4), PARAMETER, PRIVATE :: PH_B32T_PROP_KTH   = 8_i4  ! Thermal cond.
  
  PUBLIC :: PH_Elem_B32T_DefInit
  PUBLIC :: PH_Elem_B32T_FormStiffMatrix
  PUBLIC :: PH_Elem_B32T_FormIntForce
  PUBLIC :: PH_Elem_B32T_ConsMassWithSection
  PUBLIC :: PH_Elem_B32T_LumpMassWithSection
  PUBLIC :: UF_Elem_B32T_Calc

CONTAINS

  SUBROUTINE PH_Elem_B32T_DefInit(ElemDef, status)
    TYPE(ElemType), INTENT(INOUT) :: ElemDef
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    ElemDef%numNodes = PH_ELEM_B32T_NNODE
    ElemDef%dim = 3_i4
    ElemDef%dofPerNode = 7_i4  ! 6 mech + 1 temp
    ElemDef%totalDOF = PH_ELEM_B32T_NDOF
    ElemDef%name = 'B32T'
    ElemDef%cfg%description = '3-node 3D beam with thermal coupling'
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B32T_DefInit

  SUBROUTINE PH_Elem_B32T_FormStiffMatrix(coords, props, Ke21)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(OUT) :: Ke21(21, 21)
    
    ! 21x21 thermo-mechanical stiffness
    ! DOF: [u1(6), u2(6), u3(6), T1, T2, T3]
    ! props: (1)E, (2)nu, (3)A, (4)Iy, (5)Iz, (6)J, (7)alpha_CTE, (8)k_th
    REAL(wp) :: E, nu, G, A, Iy, Iz, J_tors, alpha_CTE, k_th
    REAL(wp) :: L, dx, dy, dz
    REAL(wp) :: EA, EIy, EIz, GJ
    REAL(wp) :: Ke_mech(18, 18), Ke_therm(3, 3), Ke_coup(18, 3)
    INTEGER(i4) :: i, j
    
    Ke21 = ZERO
    
    ! Extract properties
    E = props(PH_B32T_PROP_E)
    nu = props(PH_B32T_PROP_NU)
    A = props(PH_B32T_PROP_A)
    Iy = props(PH_B32T_PROP_IY)
    Iz = props(PH_B32T_PROP_IZ)
    J_tors = props(PH_B32T_PROP_J)
    alpha_CTE = props(PH_B32T_PROP_ALPHA)
    k_th = props(PH_B32T_PROP_KTH)
    
    G = E / (2.0_wp * (ONE + nu))
    
    ! Element length
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L < 1.0e-14_wp) RETURN
    
    EA  = E * A
    EIy = E * Iy
    EIz = E * Iz
    GJ  = G * J_tors
    
    ! === Block 1: Mechanical stiffness K_mm (18x18) ===
    Ke_mech = ZERO
    
    ! Axial (DOF 1,7,13) - quadratic
    Ke_mech(1, 1)   =  7.0_wp * EA / (3.0_wp * L)
    Ke_mech(1, 7)   = -8.0_wp * EA / (3.0_wp * L)
    Ke_mech(1, 13)  =  1.0_wp * EA / (3.0_wp * L)
    Ke_mech(7, 1)   = Ke_mech(1, 7)
    Ke_mech(7, 7)   = 16.0_wp * EA / (3.0_wp * L)
    Ke_mech(7, 13)  = -8.0_wp * EA / (3.0_wp * L)
    Ke_mech(13, 1)  = Ke_mech(1, 13)
    Ke_mech(13, 7)  = Ke_mech(7, 13)
    Ke_mech(13, 13) =  7.0_wp * EA / (3.0_wp * L)
    
    ! Torsion (DOF 4,10,16)
    Ke_mech(4, 4)   =  7.0_wp * GJ / (3.0_wp * L)
    Ke_mech(4, 10)  = -8.0_wp * GJ / (3.0_wp * L)
    Ke_mech(4, 16)  =  1.0_wp * GJ / (3.0_wp * L)
    Ke_mech(10, 4)  = Ke_mech(4, 10)
    Ke_mech(10, 10) = 16.0_wp * GJ / (3.0_wp * L)
    Ke_mech(10, 16) = -8.0_wp * GJ / (3.0_wp * L)
    Ke_mech(16, 4)  = Ke_mech(4, 16)
    Ke_mech(16, 10) = Ke_mech(10, 16)
    Ke_mech(16, 16) =  7.0_wp * GJ / (3.0_wp * L)
    
    ! Bending y-z (EIz): DOF 2,6 / 8,12 / 14,18
    BLOCK
      REAL(wp) :: c1
      c1 = EIz / (L * L * L)
      Ke_mech(2, 2)   =  12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(2, 6)   =  6.0_wp * c1 * L
      Ke_mech(6, 2)   = Ke_mech(2, 6)
      Ke_mech(6, 6)   =  4.0_wp * c1 * L * L
      Ke_mech(2, 14)  = -12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(14, 2)  = Ke_mech(2, 14)
      Ke_mech(14, 14) =  12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(14, 18) = -6.0_wp * c1 * L
      Ke_mech(18, 14) = Ke_mech(14, 18)
      Ke_mech(18, 18) =  4.0_wp * c1 * L * L
      Ke_mech(6, 18)  =  2.0_wp * c1 * L * L
      Ke_mech(18, 6)  = Ke_mech(6, 18)
    END BLOCK
    
    ! Bending x-z (EIy): DOF 3,5 / 9,11 / 15,17
    BLOCK
      REAL(wp) :: c1
      c1 = EIy / (L * L * L)
      Ke_mech(3, 3)   =  12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(3, 5)   = -6.0_wp * c1 * L
      Ke_mech(5, 3)   = Ke_mech(3, 5)
      Ke_mech(5, 5)   =  4.0_wp * c1 * L * L
      Ke_mech(3, 15)  = -12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(15, 3)  = Ke_mech(3, 15)
      Ke_mech(15, 15) =  12.0_wp * c1 * 7.0_wp / 3.0_wp
      Ke_mech(15, 17) =  6.0_wp * c1 * L
      Ke_mech(17, 15) = Ke_mech(15, 17)
      Ke_mech(17, 17) =  4.0_wp * c1 * L * L
      Ke_mech(5, 17)  =  2.0_wp * c1 * L * L
      Ke_mech(17, 5)  = Ke_mech(5, 17)
    END BLOCK
    
    ! === Block 2: Thermal conductivity K_tt (3x3) ===
    ! 1D conduction: k_th * A / L * [7/3, -8/3, 1/3; ...]
    Ke_therm = ZERO
    BLOCK
      REAL(wp) :: c_th
      c_th = k_th * A / L
      Ke_therm(1, 1) =  7.0_wp * c_th / 3.0_wp
      Ke_therm(1, 2) = -8.0_wp * c_th / 3.0_wp
      Ke_therm(1, 3) =  1.0_wp * c_th / 3.0_wp
      Ke_therm(2, 1) = Ke_therm(1, 2)
      Ke_therm(2, 2) = 16.0_wp * c_th / 3.0_wp
      Ke_therm(2, 3) = -8.0_wp * c_th / 3.0_wp
      Ke_therm(3, 1) = Ke_therm(1, 3)
      Ke_therm(3, 2) = Ke_therm(2, 3)
      Ke_therm(3, 3) =  7.0_wp * c_th / 3.0_wp
    END BLOCK
    
    ! === Block 3: Coupling K_ut (18x3) ===
    ! K_ut = -int(B_m^T * D * alpha * N_t dV)
    ! Simplified: thermal expansion -> axial coupling only
    Ke_coup = ZERO
    BLOCK
      REAL(wp) :: c_coup
      c_coup = E * A * alpha_CTE * L / 6.0_wp
      ! Node 1 axial (DOF 1) coupled to T1, T2, T3
      Ke_coup(1, 1) = -c_coup * 2.0_wp
      Ke_coup(1, 2) = -c_coup
      ! Node 2 axial (DOF 7) coupled to T1, T2, T3
      Ke_coup(7, 1) = -c_coup
      Ke_coup(7, 2) = -c_coup * 4.0_wp
      Ke_coup(7, 3) = -c_coup
      ! Node 3 axial (DOF 13) coupled to T1, T2, T3
      Ke_coup(13, 2) = -c_coup
      Ke_coup(13, 3) = -c_coup * 2.0_wp
    END BLOCK
    
    ! === Assemble 21x21 ===
    ! K_mm block
    Ke21(1:18, 1:18) = Ke_mech
    ! K_tt block
    Ke21(19:21, 19:21) = Ke_therm
    ! K_ut coupling
    Ke21(1:18, 19:21) = Ke_coup
    ! K_tu = transpose of K_ut
    DO i = 1, 18
      DO j = 1, 3
        Ke21(18+j, i) = Ke_coup(i, j)
      END DO
    END DO
    
  END SUBROUTINE PH_Elem_B32T_FormStiffMatrix

  SUBROUTINE PH_Elem_B32T_FormIntForce(coords, props, u21, R21)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: props(:)
    REAL(wp), INTENT(IN)  :: u21(21)
    REAL(wp), INTENT(OUT) :: R21(21)
    REAL(wp) :: Ke21(21, 21)
    
    R21 = ZERO
    CALL PH_Elem_B32T_FormStiffMatrix(coords, props, Ke21)
    R21 = MATMUL(Ke21, u21)
  END SUBROUTINE PH_Elem_B32T_FormIntForce

  SUBROUTINE PH_Elem_B32T_ConsMassWithSection(coords, rho, area, Me21)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: Me21(21, 21)
    
    ! Consistent mass: thermal DOFs have no inertia
    ! M = diag(M_mech_18x18, 0_3x3)
    REAL(wp) :: L, dx, dy, dz, mL, I_rot
    INTEGER(i4) :: i
    
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    
    Me21 = ZERO
    IF (L < 1.0e-14_wp) RETURN
    
    mL = rho * area * L
    I_rot = rho * area * L / 12.0_wp
    
    ! Node 1 (DOF 1-6): 1/6
    DO i = 1, 3
      Me21(i, i) = mL / 6.0_wp
    END DO
    DO i = 4, 6
      Me21(i, i) = I_rot / 6.0_wp
    END DO
    ! Node 2 midside (DOF 7-12): 2/3
    DO i = 7, 9
      Me21(i, i) = mL * 2.0_wp / 3.0_wp
    END DO
    DO i = 10, 12
      Me21(i, i) = I_rot * 2.0_wp / 3.0_wp
    END DO
    ! Node 3 (DOF 13-18): 1/6
    DO i = 13, 15
      Me21(i, i) = mL / 6.0_wp
    END DO
    DO i = 16, 18
      Me21(i, i) = I_rot / 6.0_wp
    END DO
    ! Thermal DOFs (19-21): zero mass
  END SUBROUTINE PH_Elem_B32T_ConsMassWithSection

  SUBROUTINE PH_Elem_B32T_LumpMassWithSection(coords, rho, area, M_lump21)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho, area
    REAL(wp), INTENT(OUT) :: M_lump21(21)
    
    ! Lumped mass: thermal DOFs = 0
    REAL(wp) :: L, dx, dy, dz, mL, I_rot
    
    dx = coords(1, 3) - coords(1, 1)
    dy = coords(2, 3) - coords(2, 1)
    dz = coords(3, 3) - coords(3, 1)
    L = SQRT(dx*dx + dy*dy + dz*dz)
    
    M_lump21 = ZERO
    IF (L < 1.0e-14_wp) RETURN
    
    mL = rho * area * L
    I_rot = rho * area * L / 12.0_wp
    
    ! Node 1: 1/6
    M_lump21(1:3) = mL / 6.0_wp
    M_lump21(4:6) = I_rot / 6.0_wp
    ! Node 2 midside: 2/3
    M_lump21(7:9)   = mL * 2.0_wp / 3.0_wp
    M_lump21(10:12) = I_rot * 2.0_wp / 3.0_wp
    ! Node 3: 1/6
    M_lump21(13:15) = mL / 6.0_wp
    M_lump21(16:18) = I_rot / 6.0_wp
    ! Thermal DOFs (19-21): zero
  END SUBROUTINE PH_Elem_B32T_LumpMassWithSection

  SUBROUTINE UF_Elem_B32T_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ElemFormul), INTENT(IN) :: formul
    TYPE(ElemCtx), INTENT(IN) :: ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: mat_props
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    
    ! Coupled thermo-mechanical workflow:
    REAL(wp) :: coords_loc(3, 3), props_loc(8)
    REAL(wp) :: Ke21(21, 21), u21(21), R21(21)
    
    flags%failed = .FALSE.
    
    ! Extract coordinates
    IF (ALLOCATED(ctx%coords)) THEN
      coords_loc = RESHAPE(ctx%coords(1:9), [3, 3])
    ELSE
      flags%failed = .TRUE.
      RETURN
    END IF
    
    ! Extract material properties (8 params)
    IF (ALLOCATED(mat_props%props)) THEN
      props_loc = ZERO
      props_loc(1:MIN(SIZE(mat_props%props), 8)) = &
        mat_props%props(1:MIN(SIZE(mat_props%props), 8))
    ELSE
      flags%failed = .TRUE.
      RETURN
    END IF
    
    ! Step 1: Compute 21x21 coupled stiffness
    CALL PH_Elem_B32T_FormStiffMatrix(coords_loc, props_loc, Ke21)
    
    ! Step 2: Compute internal force (R = K * u)
    IF (ALLOCATED(state_in%displacement)) THEN
      u21 = ZERO
      u21(1:MIN(SIZE(state_in%displacement), 21)) = &
        state_in%displacement(1:MIN(SIZE(state_in%displacement), 21))
      CALL PH_Elem_B32T_FormIntForce(coords_loc, props_loc, u21, R21)
    END IF
    
    ! Step 3: Store results
    IF (ALLOCATED(state_out%stiffness)) THEN
      state_out%stiffness(1:21, 1:21) = Ke21
    END IF
    IF (ALLOCATED(state_out%internal_force)) THEN
      state_out%internal_force(1:21) = R21
    END IF
    
  END SUBROUTINE UF_Elem_B32T_Calc

END MODULE PH_Elem_B32T