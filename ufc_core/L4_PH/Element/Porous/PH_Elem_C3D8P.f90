!===============================================================================
! MODULE: PH_Elem_C3D8P
! LAYER:  L4_PH
! DOMAIN: Element/Porous
! ROLE:   Proc
! BRIEF:  C3D8P 8-node 3D continuum with pore pressure
!===============================================================================
MODULE PH_Elem_C3D8P
!> [CORE] C3D8P element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_C3D8, ONLY: &
    PH_Elem_C3D8_ShapeFunc, PH_Elem_C3D8_Jac, PH_Elem_C3D8_BMatrix, &
    PH_Elem_C3D8_GaussPoints, PH_Elem_C3D8_JacB, PH_ELEM_C3D8_NNODE, PH_ELEM_C3D8_NIP, &
    PH_ELEM_GAUSS_PT, PH_ELEM_C3D8_FACE_NODES
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PARAMETERS
  !=============================================================================
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NNODE = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NIP   = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDPN_STRUCT = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDPN_PORE   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDPN_TOTAL  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDOF_STRUCT = PH_ELEM_C3D8P_NNODE * PH_ELEM_C3D8P_NDPN_STRUCT
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDOF_PORE   = PH_ELEM_C3D8P_NNODE * PH_ELEM_C3D8P_NDPN_PORE
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8P_NDOF        = PH_ELEM_C3D8P_NNODE * PH_ELEM_C3D8P_NDPN_TOTAL
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_PORE_SOURCE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_NVAR_S11 = 1, PH_ELEM_NVAR_S22 = 2, PH_ELEM_NVAR_S33 = 3
  INTEGER(i4), PARAMETER :: PH_ELEM_NVAR_S12 = 4, PH_ELEM_NVAR_S23 = 5, PH_ELEM_NVAR_S13 = 6
  INTEGER(i4), PARAMETER :: PH_ELEM_NVAR_LE11 = 7, PH_ELEM_NVAR_LE22 = 8, PH_ELEM_NVAR_LE33 = 9
  INTEGER(i4), PARAMETER :: PH_ELEM_NVAR_LE12 = 10, PH_ELEM_NVAR_LE23 = 11, PH_ELEM_NVAR_LE13 = 12
  INTEGER(i4), PARAMETER :: PH_ELEM_NVAR_PORE = 13, PH_ELEM_NVAR_PEEQ = 14
  INTEGER(i4), PARAMETER :: PH_ELEM_N_IP = 8, PH_ELEM_N_NODE = 8

  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_C3D8P_DefInit
  PUBLIC :: PH_Elem_C3D8P_ShapeFunc, PH_Elem_C3D8P_Jac, PH_Elem_C3D8P_BMatrix
  PUBLIC :: PH_Elem_C3D8P_BpMatrix, PH_Elem_C3D8P_GaussPoints, PH_Elem_C3D8P_JacB
  PUBLIC :: PH_Elem_C3D8P_FormStiffMatrix, PH_Elem_C3D8P_FormStiffMatrix_MatAware
  PUBLIC :: PH_Elem_C3D8P_FormIntForce, PH_Elem_C3D8P_FormIntForce_MatAware
  PUBLIC :: PH_ELEM_C3D8P_NNODE, PH_ELEM_C3D8P_NIP, PH_ELEM_C3D8P_NDOF, PH_ELEM_C3D8P_NDOF_STRUCT, PH_ELEM_C3D8P_NDOF_PORE
  PUBLIC :: PH_ELEM_C3D8P_NDPN_STRUCT, PH_ELEM_C3D8P_NDPN_PORE, PH_ELEM_C3D8P_NDPN_TOTAL
  PUBLIC :: PH_Elem_C3D8P_NL_TL, PH_Elem_C3D8P_NL_UL
  PUBLIC :: PH_Elem_C3D8P_GetVolume, PH_Elem_C3D8P_GetSectProps
  PUBLIC :: PH_Elem_C3D8P_GetCentroid, PH_Elem_C3D8P_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D8P_ApplyConstraint, PH_Elem_C3D8P_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_C3D8P_FormContactContrib, PH_Elem_C3D8P_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D8P_FormNodalForce, PH_Elem_C3D8P_FormBodyForce
  PUBLIC :: PH_Elem_C3D8P_FormFacePressure, PH_Elem_C3D8P_FormPoreSource
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P, PH_ELEM_LOAD_PORE_SOURCE
  PUBLIC :: PH_Elem_C3D8P_CollectIPVars, PH_Elem_C3D8P_MapToNode
  PUBLIC :: PH_Elem_C3D8P_GetExtrapMat, PH_Elem_C3D8P_EvalVonMises
  PUBLIC :: PH_Elem_C3D8P_EvalPrincStress, PH_Elem_C3D8P_EvalStressInvar

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Porous_Args
  TYPE :: PH_Elem_Porous_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
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
  REAL(wp)              :: k_hyd       = 0.0_wp  ! hydraulic permeability scale
  REAL(wp)              :: alpha_b     = 1.0_wp ! Biot
  REAL(wp), POINTER     :: u_struct(:) => NULL()  ! packed structural displacement ptr
  REAL(wp), POINTER     :: p_pore(:)   => NULL()  ! nodal pore pressure ptr
  REAL(wp), POINTER     :: Kuu(:,:)    => NULL()  ! displacement-displacement block ptr
  REAL(wp), POINTER     :: Kpp(:,:)    => NULL()  ! pressure-pressure block ptr
  REAL(wp), POINTER     :: Kup(:,:)    => NULL()  ! displacement-pressure coupling block ptr
  REAL(wp), POINTER     :: ip_pore(:)  => NULL()  ! IP pore pressure ptr
  END TYPE PH_Elem_Porous_Args


CONTAINS

  !=============================================================================
  ! DEFINITION
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &
                                                    k_hyd, alpha_b, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke(32, 32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), Bp(3, 8)
    REAL(wp) :: m_vec(6), Np(8), dV
    REAL(wp) :: D_tangent(6, 6)
    REAL(wp) :: Kuu_block(24, 24), Kpp_block(8, 8)
    REAL(wp) :: Kup_block(24, 8)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i, j
    Ke = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      Np = N
      ss_gp%strain = ZERO
      ss_gp%strain_inc = ZERO
      ss_gp%sigma = ZERO
      ss_gp%tangent = ZERO
      CALL PH_UpdateStress(mat_prop, mat_state(ip), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) CYCLE
      D_tangent = ss_gp%tangent
      Kuu_block = MATMUL(MATMUL(TRANSPOSE(B), D_tangent), B) * dV
      DO i = 1, 24
        DO j = 1, 24
          Ke(i, j) = Ke(i, j) + Kuu_block(i, j)
        END DO
      END DO
      Kpp_block = k_hyd * MATMUL(TRANSPOSE(Bp), Bp) * dV
      DO i = 1, 8
        DO j = 1, 8
          Ke(24+i, 24+j) = Ke(24+i, 24+j) + Kpp_block(i, j)
        END DO
      END DO
      DO i = 1, 24
        DO j = 1, 8
          Kup_block(i, j) = alpha_b * DOT_PRODUCT(B(:, i), m_vec) * Np(j) * dV
          Ke(i, 24+j) = Ke(i, 24+j) + Kup_block(i, j)
        END DO
      END DO
      DO i = 1, 8
        DO j = 1, 24
          Ke(24+i, j) = Ke(24+i, j) + Kup_block(j, i)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix_MatAware

  SUBROUTINE PH_Elem_C3D8P_FormIntForce_MatAware(coords, u_struct, p_pore, mat_prop, &
                                                 mat_state, k_hyd, alpha_b, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u_struct(24), p_pore(8)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: R_int(32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), Bp(3, 8)
    REAL(wp) :: m_vec(6), strain_mech(6), sigma_eff(6), sigma_total(6)
    REAL(wp) :: grad_p(3), dV, p_gp
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i
    R_int = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      strain_mech = MATMUL(B, u_struct)
      ss_gp%strain = strain_mech
      ss_gp%strain_inc = strain_mech
      ss_gp%sigma = ZERO
      ss_gp%tangent = ZERO
      CALL PH_UpdateStress(mat_prop, mat_state(ip), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) CYCLE
      sigma_eff = ss_gp%sigma
      p_gp = DOT_PRODUCT(N, p_pore)
      sigma_total = sigma_eff - alpha_b * p_gp * m_vec
      R_int(1:24) = R_int(1:24) + MATMUL(TRANSPOSE(B), sigma_total) * dV
      grad_p = MATMUL(Bp, p_pore)
      R_int(25:32) = R_int(25:32) + k_hyd * MATMUL(TRANSPOSE(Bp), grad_p) * dV
    END DO
  END SUBROUTINE PH_Elem_C3D8P_FormIntForce_MatAware

  SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix(coords, D_struct, k_hyd, alpha_b, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: D_struct(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke(32, 32)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(8)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(6))
    mat_prop_dummy%props(1) = D_struct(1,1)
    mat_prop_dummy%props(2) = D_struct(1,2) / D_struct(1,1)
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 8
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    CALL PH_Elem_C3D8P_FormStiffMatrix_MatAware(coords, mat_prop_dummy, mat_state_dummy, &
                                               k_hyd, alpha_b, Ke)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D8P_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 8)
    REAL(wp), INTENT(OUT) :: B(6, 24)
    CALL PH_Elem_C3D8_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_C3D8P_BMatrix

  SUBROUTINE PH_Elem_C3D8P_BpMatrix(dNdx, Bp)
    REAL(wp), INTENT(IN)  :: dNdx(3, 8)
    REAL(wp), INTENT(OUT) :: Bp(3, 8)
    INTEGER(i4) :: i
    DO i = 1, 8
      Bp(1, i) = dNdx(1, i)
      Bp(2, i) = dNdx(2, i)
      Bp(3, i) = dNdx(3, i)
    END DO
  END SUBROUTINE PH_Elem_C3D8P_BpMatrix

  SUBROUTINE PH_Elem_C3D8P_DefInit()
  END SUBROUTINE PH_Elem_C3D8P_DefInit

  SUBROUTINE PH_Elem_C3D8P_FormIntForce(coords, u_struct, p_pore, D_struct, &
                                         k_hyd, alpha_b, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u_struct(24), p_pore(8)
    REAL(wp), INTENT(IN)  :: D_struct(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: R_int(32)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(8)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(6))
    mat_prop_dummy%props(1) = D_struct(1,1)
    mat_prop_dummy%props(2) = D_struct(1,2) / D_struct(1,1)
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 8
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    CALL PH_Elem_C3D8P_FormIntForce_MatAware(coords, u_struct, p_pore, mat_prop_dummy, &
                                             mat_state_dummy, k_hyd, alpha_b, R_int)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D8P_FormIntForce

  SUBROUTINE PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(8), eta(8), zeta(8), weights(8)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
  END SUBROUTINE PH_Elem_C3D8P_GaussPoints

  SUBROUTINE PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 8)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_C3D8P_Jac

  SUBROUTINE PH_Elem_C3D8P_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B, Bp)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), Bp(3, 8)
    CALL PH_Elem_C3D8_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    CALL PH_Elem_C3D8P_BpMatrix(dNdx, Bp)
  END SUBROUTINE PH_Elem_C3D8P_JacB

  SUBROUTINE PH_Elem_C3D8P_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 8)
    CALL PH_Elem_C3D8_ShapeFunc(xi, eta, zeta, N, dNdxi)
  END SUBROUTINE PH_Elem_C3D8P_ShapeFunc

  ! NL_TL/NL_UL: Dispatch-compatible interface (D = elasticity matrix)
  SUBROUTINE PH_Elem_C3D8P_NL_TL(coords_ref, u_elem, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 8)
    REAL(wp), INTENT(IN)  :: u_elem(32)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(32, 32), Ke_geo(32, 32), R_int(32)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State) :: mat_state(8)
    INTEGER(i4) :: i
    mat_prop%mat_id = 1
    mat_prop%num_props = 2
    ALLOCATE(mat_prop%props(6))
    mat_prop%props(1) = D(1,1)
    mat_prop%props(2) = D(1,2) / MAX(D(1,1), 1.0e-20_wp)
    mat_prop%num_state_vars = 0
    DO i = 1, 8
      mat_state(i)%mat_id = 1
      mat_state(i)%nStatev = 0
      mat_state(i)%is_initialized = .TRUE.
    END DO
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_C3D8P_FormStiffMatrix_MatAware(coords_ref, mat_prop, mat_state, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_C3D8P_FormIntForce_MatAware(coords_ref, u_elem(1:24), u_elem(25:32), &
                                           mat_prop, mat_state, k_hyd, alpha_b, R_int)
    DEALLOCATE(mat_prop%props)
  END SUBROUTINE PH_Elem_C3D8P_NL_TL

  SUBROUTINE PH_Elem_C3D8P_NL_UL(coords_prev, u_incr, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 8)
    REAL(wp), INTENT(IN)  :: u_incr(32)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(32, 32), Ke_geo(32, 32), R_int(32)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State) :: mat_state(8)
    INTEGER(i4) :: i
    mat_prop%mat_id = 1
    mat_prop%num_props = 2
    ALLOCATE(mat_prop%props(6))
    mat_prop%props(1) = D(1,1)
    mat_prop%props(2) = D(1,2) / MAX(D(1,1), 1.0e-20_wp)
    mat_prop%num_state_vars = 0
    DO i = 1, 8
      mat_state(i)%mat_id = 1
      mat_state(i)%nStatev = 0
      mat_state(i)%is_initialized = .TRUE.
    END DO
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_C3D8P_FormStiffMatrix_MatAware(coords_prev, mat_prop, mat_state, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_C3D8P_FormIntForce_MatAware(coords_prev, u_incr(1:24), u_incr(25:32), &
                                             mat_prop, mat_state, k_hyd, alpha_b, R_int)
    DEALLOCATE(mat_prop%props)
  END SUBROUTINE PH_Elem_C3D8P_NL_UL

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8P_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid = centroid / volume
  END SUBROUTINE PH_Elem_C3D8P_GetCentroid

  SUBROUTINE PH_Elem_C3D8P_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x = ZERO
      DO k = 1, 8
        x = x + N(k) * coords(:, k)
      END DO
      r2 = SUM(x**2)
      DO i = 1, 3
        DO j = 1, 3
          I_out(i, j) = I_out(i, j) - x(i) * x(j) * dV
        END DO
        I_out(i, i) = I_out(i, i) + r2 * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D8P_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_C3D8P_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D8P_GetSectProps

  SUBROUTINE PH_Elem_C3D8P_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D8P_GetVolume

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8P_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(32, 32)
    REAL(wp), INTENT(INOUT) :: F_el(32)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > PH_ELEM_C3D8P_NDOF) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D8P_ApplyConstraint

  SUBROUTINE PH_Elem_C3D8P_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(32)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(32, 32)
    REAL(wp), INTENT(INOUT) :: F_el(32)
    INTEGER(i4) :: i, j
    DO i = 1, PH_ELEM_C3D8P_NDOF
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, PH_ELEM_C3D8P_NDOF
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_ApplyMPC

  !=============================================================================
  ! CONTACT
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8P_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(32, 32)
    REAL(wp), INTENT(INOUT) :: F_el(32)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 8
      ia = 3 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * n(1)
      f_a(2) = penalty * gap * N(a) * n(2)
      f_a(3) = penalty * gap * N(a) * n(3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 8
      DO b = 1, 8
        k_ab = penalty * N(a) * N(b)
        ia = 3 * (a - 1) + 1
        ib = 3 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia,   ib+2) = K_el(ia,   ib+2) + k_ab * n(1) * n(3)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
        K_el(ia+1, ib+2) = K_el(ia+1, ib+2) + k_ab * n(2) * n(3)
        K_el(ia+2, ib)   = K_el(ia+2, ib)   + k_ab * n(3) * n(1)
        K_el(ia+2, ib+1) = K_el(ia+2, ib+1) + k_ab * n(3) * n(2)
        K_el(ia+2, ib+2) = K_el(ia+2, ib+2) + k_ab * n(3) * n(3)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_FormContactContrib

  SUBROUTINE PH_Elem_C3D8P_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(32, 32)
    REAL(wp), INTENT(OUT) :: F_el(32)
    REAL(wp) :: xi, eta, zeta, N(8), n(3), dNdxi(3, 8)
    REAL(wp) :: r(3), dr_dxi(3), dr_deta(3)
    INTEGER(i4) :: nodes(4), i
    K_el = ZERO
    F_el = ZERO
    SELECT CASE (face_id)
    CASE (1)
      xi = 0.0_wp; eta = 0.0_wp; zeta = -ONE
      nodes(1:4) = [1, 2, 3, 4]
    CASE (2)
      xi = 0.0_wp; eta = 0.0_wp; zeta = ONE
      nodes(1:4) = [5, 8, 7, 6]
    CASE (3)
      xi = 0.0_wp; eta = -ONE; zeta = 0.0_wp
      nodes(1:4) = [1, 2, 6, 5]
    CASE (4)
      xi = 0.0_wp; eta = ONE; zeta = 0.0_wp
      nodes(1:4) = [4, 3, 7, 8]
    CASE (5)
      xi = -ONE; eta = 0.0_wp; zeta = 0.0_wp
      nodes(1:4) = [1, 4, 8, 5]
    CASE (6)
      xi = ONE; eta = 0.0_wp; zeta = 0.0_wp
      nodes(1:4) = [2, 6, 7, 3]
    CASE DEFAULT
      RETURN
    END SELECT
    CALL PH_Elem_C3D8P_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r = ZERO
    dr_dxi = ZERO
    dr_deta = ZERO
    DO i = 1, 4
      r = r + N(nodes(i)) * coords(:, nodes(i))
      dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
      dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
    END DO
    n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
    n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
    n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
    IF (face_id == 1 .OR. face_id == 3 .OR. face_id == 5) n = -n
    IF (SUM(n**2) > 1.0e-20_wp) n = n / SQRT(SUM(n**2))
    CALL PH_Elem_C3D8P_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D8P_FormContactFaceCtr

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8P_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(32)
    REAL(wp) :: N(8), dNdxi(3, 8)
    REAL(wp) :: dr_dxi(3), dr_deta(3), nvec(3), dA
    REAL(wp) :: xi_f(4), eta_f(4), w_f(4)
    INTEGER(i4) :: ip, i, nodes(4)
    REAL(wp) :: zet
    F_eq = ZERO
    xi_f = [-PH_ELEM_GAUSS_PT, PH_ELEM_GAUSS_PT, -PH_ELEM_GAUSS_PT, PH_ELEM_GAUSS_PT]
    eta_f = [-PH_ELEM_GAUSS_PT, -PH_ELEM_GAUSS_PT, PH_ELEM_GAUSS_PT, PH_ELEM_GAUSS_PT]
    w_f = ONE
    SELECT CASE (face_id)
    CASE (1)
      nodes = [1, 2, 3, 4]
      zet = -ONE
      DO ip = 1, 4
        CALL PH_Elem_C3D8P_ShapeFunc(xi_f(ip), eta_f(ip), zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = &
            F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (2)
      nodes = [5, 8, 7, 6]
      zet = ONE
      DO ip = 1, 4
        CALL PH_Elem_C3D8P_ShapeFunc(xi_f(ip), eta_f(ip), zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = &
            F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE DEFAULT
    END SELECT
  END SUBROUTINE PH_Elem_C3D8P_FormFacePressure

  SUBROUTINE PH_Elem_C3D8P_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq(3*(i-1)+1) = F_eq(3*(i-1)+1) + N(i) * bx * detJ * weights(ip)
        F_eq(3*(i-1)+2) = F_eq(3*(i-1)+2) + N(i) * by * detJ * weights(ip)
        F_eq(3*(i-1)+3) = F_eq(3*(i-1)+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_FormBodyForce

  SUBROUTINE PH_Elem_C3D8P_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(32)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D8P_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8P_FormFacePressure(coords, val(1), face_id, F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_PORE_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8P_FormPoreSource(coords, val(1), F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D8P_FormNodalForce

  SUBROUTINE PH_Elem_C3D8P_FormPoreSource(coords, q_source, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: q_source
    REAL(wp), INTENT(OUT) :: F_eq(32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq(24+i) = F_eq(24+i) + N(i) * q_source * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_FormPoreSource

  !=============================================================================
  ! OUTPUT
  !=============================================================================
  SUBROUTINE invert_8x8(A, info)
    REAL(wp), INTENT(INOUT) :: A(8, 8)
    INTEGER(i4), INTENT(OUT) :: info
    REAL(wp) :: B(8, 8)
    INTEGER(i4) :: i, k
    REAL(wp) :: fac
    B = A
    A = ZERO
    DO i = 1, 8
      A(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 8
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, :) = B(k, :) * fac
      A(k, :) = A(k, :) * fac
      DO i = 1, 8
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, :) = B(i, :) - fac * B(k, :)
        A(i, :) = A(i, :) - fac * A(k, :)
      END DO
    END DO
  END SUBROUTINE invert_8x8

  SUBROUTINE PH_Elem_C3D8P_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: principal(3)
    REAL(wp) :: s(3,3), p, q, r, phi, a
    s(1,1) = sigma(1); s(2,2) = sigma(2); s(3,3) = sigma(3)
    s(1,2) = sigma(4); s(2,1) = sigma(4)
    s(2,3) = sigma(5); s(3,2) = sigma(5)
    s(1,3) = sigma(6); s(3,1) = sigma(6)
    p = (s(1,1) + s(2,2) + s(3,3)) / 3.0_wp
    q = (s(1,1)*s(2,2) + s(2,2)*s(3,3) + s(3,3)*s(1,1) - s(1,2)**2 - s(2,3)**2 - s(1,3)**2) / 3.0_wp - p**2
    r = (s(1,1)-p)*(s(2,2)-p)*(s(3,3)-p) + 2.0_wp*s(1,2)*s(2,3)*s(1,3) &
        - (s(1,1)-p)*s(2,3)**2 - (s(2,2)-p)*s(1,3)**2 - (s(3,3)-p)*s(1,2)**2
    r = r / 2.0_wp
    IF (q <= 1.0e-20_wp) THEN
      principal = p
      RETURN
    END IF
    a = SQRT(MAX(q, ZERO))
    IF (ABS(a) < 1.0e-20_wp) THEN
      principal = p
      RETURN
    END IF
    r = MAX(-ONE, MIN(ONE, r / (a**3)))
    phi = ACOS(r) / 3.0_wp
    principal(1) = p + 2.0_wp * a * COS(phi)
    principal(2) = p + 2.0_wp * a * COS(phi - 8.0_wp*ATAN(1.0_wp)/3.0_wp)
    principal(3) = p + 2.0_wp * a * COS(phi + 8.0_wp*ATAN(1.0_wp)/3.0_wp)
  END SUBROUTINE PH_Elem_C3D8P_EvalPrincStress

  SUBROUTINE PH_Elem_C3D8P_EvalStressInvar(sigma, I1, J2, J3)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: I1, J2, J3
    REAL(wp) :: p, sdev(6)
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdev(1:3) = sigma(1:3) - p
    sdev(4:6) = sigma(4:6)
    J2 = HALF * (sdev(1)*sdev(1) + sdev(2)*sdev(2) + sdev(3)*sdev(3)) &
         + sdev(4)*sdev(4) + sdev(5)*sdev(5) + sdev(6)*sdev(6)
    J3 = sdev(1)*(sdev(2)*sdev(3) - sdev(5)*sdev(5)) &
       - sdev(4)*(sdev(4)*sdev(3) - sdev(5)*sdev(6)) &
       + sdev(6)*(sdev(4)*sdev(5) - sdev(2)*sdev(6))
  END SUBROUTINE PH_Elem_C3D8P_EvalStressInvar

  SUBROUTINE PH_Elem_C3D8P_CollectIPVars(ip_stress, ip_strain, ip_pore, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_pore(:)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, PH_ELEM_N_IP)
      IF (SIZE(out_vars, 1) >= 14 .AND. SIZE(ip_stress, 1) >= 6) out_vars(1:6, ip) = ip_stress(1:6, ip)
      IF (SIZE(ip_strain, 1) >= 6) out_vars(7:12, ip) = ip_strain(1:6, ip)
      IF (SIZE(ip_pore) >= ip) out_vars(13, ip) = ip_pore(ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(14, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D8P_CollectIPVars

  SUBROUTINE PH_Elem_C3D8P_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: p, J2
    p = (sigma(1) + sigma(2) + sigma(3)) / 3.0_wp
    J2 = HALF * ((sigma(1)-p)**2 + (sigma(2)-p)**2 + (sigma(3)-p)**2) &
         + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D8P_EvalVonMises

  SUBROUTINE PH_Elem_C3D8P_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(8, 8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8)
    REAL(wp) :: A(8, 8)
    INTEGER(i4) :: ip, i, j, info
    CALL PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)
    A = ZERO
    DO ip = 1, 8
      CALL PH_Elem_C3D8P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      DO i = 1, 8
        A(i, ip) = N(i)
      END DO
    END DO
    E = TRANSPOSE(A)
    CALL invert_8x8(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_C3D8P_GetExtrapMat

  SUBROUTINE PH_Elem_C3D8P_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(8, 8)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_C3D8P_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 8
        DO j = 1, 8
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8P_MapToNode

END MODULE PH_Elem_C3D8P
