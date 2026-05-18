!===============================================================================
! MODULE: PH_Elem_C3D4P
! LAYER:  L4_PH
! DOMAIN: Element/Porous
! ROLE:   Proc
! BRIEF:  C3D4P 4-node 3D tetrahedron with pore pressure
!===============================================================================
MODULE PH_Elem_C3D4P
!> [CORE] C3D4P element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_C3D4, ONLY: &
    PH_Elem_C3D4_ShapeFunc, PH_Elem_C3D4_Jac, PH_Elem_C3D4_BMatrix, &
    PH_Elem_C3D4_GaussPoints, PH_Elem_C3D4_JacB, PH_ELEM_C3D4_FACE_NODES
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NNODE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NIP   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDPN_STRUCT = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDPN_PORE   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDPN_TOTAL  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDOF_STRUCT = 12_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDOF_PORE   = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4P_NDOF        = 16_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_PORE_SOURCE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_N_IP = 1, PH_ELEM_N_NODE = 4

  PUBLIC :: PH_Elem_C3D4P_DefInit, PH_Elem_C3D4P_ShapeFunc, PH_Elem_C3D4P_Jac
  PUBLIC :: PH_Elem_C3D4P_BMatrix, PH_Elem_C3D4P_BpMatrix, PH_Elem_C3D4P_GaussPoints
  PUBLIC :: PH_Elem_C3D4P_JacB, PH_Elem_C3D4P_FormStiffMatrix, PH_Elem_C3D4P_FormIntForce
  PUBLIC :: PH_ELEM_C3D4P_NNODE, PH_ELEM_C3D4P_NIP, PH_ELEM_C3D4P_NDOF, PH_ELEM_C3D4P_NDOF_STRUCT, PH_ELEM_C3D4P_NDOF_PORE
  PUBLIC :: PH_ELEM_C3D4P_NDPN_STRUCT, PH_ELEM_C3D4P_NDPN_PORE, PH_ELEM_C3D4P_NDPN_TOTAL
  PUBLIC :: PH_Elem_C3D4P_NL_TL, PH_Elem_C3D4P_NL_UL
  PUBLIC :: PH_Elem_C3D4P_GetVolume, PH_Elem_C3D4P_GetSectProps
  PUBLIC :: PH_Elem_C3D4P_GetCentroid, PH_Elem_C3D4P_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D4P_ApplyConstraint, PH_Elem_C3D4P_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_C3D4P_FormContactContrib, PH_Elem_C3D4P_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D4P_FormNodalForce, PH_Elem_C3D4P_FormBodyForce
  PUBLIC :: PH_Elem_C3D4P_FormFacePressure, PH_Elem_C3D4P_FormPoreSource
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P, PH_ELEM_LOAD_PORE_SOURCE
  PUBLIC :: PH_Elem_C3D4P_CollectIPVars, PH_Elem_C3D4P_MapToNode
  PUBLIC :: PH_Elem_C3D4P_GetExtrapMat, PH_Elem_C3D4P_EvalVonMises
  PUBLIC :: PH_Elem_C3D4P_EvalPrincStress, PH_Elem_C3D4P_EvalStressInvar

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

  SUBROUTINE PH_Elem_C3D4P_BpMatrix(dNdx, Bp)
    REAL(wp), INTENT(IN)  :: dNdx(3, 4)
    REAL(wp), INTENT(OUT) :: Bp(3, 4)
    INTEGER(i4) :: i
    DO i = 1, 4
      Bp(1, i) = dNdx(1, i)
      Bp(2, i) = dNdx(2, i)
      Bp(3, i) = dNdx(3, i)
    END DO
  END SUBROUTINE PH_Elem_C3D4P_BpMatrix

  SUBROUTINE PH_Elem_C3D4P_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 4)
    REAL(wp), INTENT(OUT) :: B(6, 12)
    CALL PH_Elem_C3D4_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_C3D4P_BMatrix

  SUBROUTINE PH_Elem_C3D4P_DefInit()
  END SUBROUTINE PH_Elem_C3D4P_DefInit

  SUBROUTINE PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(1), eta(1), zeta(1), weights(1)
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
  END SUBROUTINE PH_Elem_C3D4P_GaussPoints

  SUBROUTINE PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 4)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_C3D4P_Jac

  SUBROUTINE PH_Elem_C3D4P_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B, Bp)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12), Bp(3, 4)
    CALL PH_Elem_C3D4_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    CALL PH_Elem_C3D4P_BpMatrix(dNdx, Bp)
  END SUBROUTINE PH_Elem_C3D4P_JacB

  SUBROUTINE PH_Elem_C3D4P_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 4)
    CALL PH_Elem_C3D4_ShapeFunc(xi, eta, zeta, N, dNdxi)
  END SUBROUTINE PH_Elem_C3D4P_ShapeFunc

  SUBROUTINE PH_Elem_C3D4P_FormStiffMatrix(coords, D_struct, k_hyd, alpha_b, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: D_struct(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke(16, 16)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12), Bp(3, 4)
    REAL(wp) :: m_vec(6), dV
    REAL(wp) :: Kuu_block(12, 12), Kpp_block(4, 4)
    REAL(wp) :: Kup_block(12, 4)
    INTEGER(i4) :: ip, i, j
    Ke = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      Kuu_block = MATMUL(MATMUL(TRANSPOSE(B), D_struct), B) * dV
      Ke(1:12, 1:12) = Ke(1:12, 1:12) + Kuu_block
      Kpp_block = k_hyd * MATMUL(TRANSPOSE(Bp), Bp) * dV
      Ke(13:16, 13:16) = Ke(13:16, 13:16) + Kpp_block
      DO i = 1, 12
        DO j = 1, 4
          Kup_block(i, j) = alpha_b * DOT_PRODUCT(B(:, i), m_vec) * N(j) * dV
          Ke(i, 12+j) = Ke(i, 12+j) + Kup_block(i, j)
        END DO
      END DO
      DO i = 1, 4
        DO j = 1, 12
          Ke(12+i, j) = Ke(12+i, j) + Kup_block(j, i)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4P_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D4P_FormIntForce(coords, u_struct, p_pore, D_struct, k_hyd, alpha_b, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: u_struct(12), p_pore(4)
    REAL(wp), INTENT(IN)  :: D_struct(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: R_int(16)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12), Bp(3, 4)
    REAL(wp) :: m_vec(6), strain(6), sigma(6)
    REAL(wp) :: grad_p(3), dV
    INTEGER(i4) :: ip, i
    R_int = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      strain = MATMUL(B, u_struct)
      sigma = MATMUL(D_struct, strain)
      R_int(1:12) = R_int(1:12) + MATMUL(TRANSPOSE(B), sigma) * dV
      DO i = 1, 12
        R_int(i) = R_int(i) - alpha_b * DOT_PRODUCT(B(:, i), m_vec) * DOT_PRODUCT(N, p_pore) * dV
      END DO
      grad_p = MATMUL(Bp, p_pore)
      R_int(13:16) = R_int(13:16) + k_hyd * MATMUL(TRANSPOSE(Bp), grad_p) * dV
    END DO
  END SUBROUTINE PH_Elem_C3D4P_FormIntForce

  SUBROUTINE PH_Elem_C3D4P_NL_TL(coords_ref, u_elem, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 4)
    REAL(wp), INTENT(IN)  :: u_elem(16)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16), Ke_geo(16, 16), R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_C3D4P_FormStiffMatrix(coords_ref, D, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_C3D4P_FormIntForce(coords_ref, u_elem(1:12), u_elem(13:16), &
                                    D, k_hyd, alpha_b, R_int)
  END SUBROUTINE PH_Elem_C3D4P_NL_TL

  SUBROUTINE PH_Elem_C3D4P_NL_UL(coords_prev, u_incr, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 4)
    REAL(wp), INTENT(IN)  :: u_incr(16)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16), Ke_geo(16, 16), R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_C3D4P_FormStiffMatrix(coords_prev, D, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_C3D4P_FormIntForce(coords_prev, u_incr(1:12), u_incr(13:16), &
                                    D, k_hyd, alpha_b, R_int)
  END SUBROUTINE PH_Elem_C3D4P_NL_UL

  SUBROUTINE PH_Elem_C3D4P_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 4
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid = centroid / volume
  END SUBROUTINE PH_Elem_C3D4P_GetCentroid

  SUBROUTINE PH_Elem_C3D4P_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x = ZERO
      DO k = 1, 4
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
  END SUBROUTINE PH_Elem_C3D4P_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D4P_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_C3D4P_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D4P_GetSectProps

  SUBROUTINE PH_Elem_C3D4P_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D4P_GetVolume

  SUBROUTINE PH_Elem_C3D4P_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > PH_ELEM_C3D4P_NDOF) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D4P_ApplyConstraint

  SUBROUTINE PH_Elem_C3D4P_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(16)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    INTEGER(i4) :: i, j
    DO i = 1, PH_ELEM_C3D4P_NDOF
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, PH_ELEM_C3D4P_NDOF
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4P_ApplyMPC

  SUBROUTINE PH_Elem_C3D4P_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 4
      ia = 3 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * n(1)
      f_a(2) = penalty * gap * N(a) * n(2)
      f_a(3) = penalty * gap * N(a) * n(3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 4
      DO b = 1, 4
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
  END SUBROUTINE PH_Elem_C3D4P_FormContactContrib

  SUBROUTINE PH_Elem_C3D4P_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(16, 16)
    REAL(wp), INTENT(OUT) :: F_el(16)
    REAL(wp) :: xi, eta, zeta, N(4), n(3), dNdxi(3, 4)
    REAL(wp) :: r1(3), r2(3)
    INTEGER(i4) :: nodes(3)
    K_el = ZERO
    F_el = ZERO
    IF (face_id < 1 .OR. face_id > 4) RETURN
    nodes(1) = PH_ELEM_C3D4_FACE_NODES(1, face_id)
    nodes(2) = PH_ELEM_C3D4_FACE_NODES(2, face_id)
    nodes(3) = PH_ELEM_C3D4_FACE_NODES(3, face_id)
    SELECT CASE (face_id)
    CASE (1)
      xi = 1.0_wp / 3.0_wp; eta = 1.0_wp / 3.0_wp; zeta = 1.0_wp / 3.0_wp
    CASE (2)
      xi = 0.0_wp; eta = 1.0_wp / 3.0_wp; zeta = 1.0_wp / 3.0_wp
    CASE (3)
      xi = 1.0_wp / 3.0_wp; eta = 0.0_wp; zeta = 1.0_wp / 3.0_wp
    CASE (4)
      xi = 1.0_wp / 3.0_wp; eta = 1.0_wp / 3.0_wp; zeta = 0.0_wp
    END SELECT
    CALL PH_Elem_C3D4P_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r1(1) = coords(1, nodes(2)) - coords(1, nodes(1))
    r1(2) = coords(2, nodes(2)) - coords(2, nodes(1))
    r1(3) = coords(3, nodes(2)) - coords(3, nodes(1))
    r2(1) = coords(1, nodes(3)) - coords(1, nodes(1))
    r2(2) = coords(2, nodes(3)) - coords(2, nodes(1))
    r2(3) = coords(3, nodes(3)) - coords(3, nodes(1))
    n(1) = r1(2)*r2(3) - r1(3)*r2(2)
    n(2) = r1(3)*r2(1) - r1(1)*r2(3)
    n(3) = r1(1)*r2(2) - r1(2)*r2(1)
    IF (face_id == 1) n = -n
    IF (SUM(n**2) > 1.0e-20_wp) n = n / SQRT(SUM(n**2))
    CALL PH_Elem_C3D4P_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D4P_FormContactFaceCtr

  SUBROUTINE PH_Elem_C3D4P_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: n(3), area
    INTEGER(i4) :: nodes(3), i, j
    F_eq = ZERO
    IF (face_id < 1 .OR. face_id > 4) RETURN
    nodes(1) = PH_ELEM_C3D4_FACE_NODES(1, face_id)
    nodes(2) = PH_ELEM_C3D4_FACE_NODES(2, face_id)
    nodes(3) = PH_ELEM_C3D4_FACE_NODES(3, face_id)
    n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1)))
    n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1)))
    n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1)))
    area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
    IF (area < 1.0e-15_wp) RETURN
    n(1) = n(1) / (2.0_wp * area)
    n(2) = n(2) / (2.0_wp * area)
    n(3) = n(3) / (2.0_wp * area)
    IF (face_id == 1) n = -n
    DO j = 1, 3
      i = nodes(j)
      F_eq(3*i-2) = F_eq(3*i-2) + (p * area / 3.0_wp) * n(1)
      F_eq(3*i-1) = F_eq(3*i-1) + (p * area / 3.0_wp) * n(2)
      F_eq(3*i)   = F_eq(3*i)   + (p * area / 3.0_wp) * n(3)
    END DO
  END SUBROUTINE PH_Elem_C3D4P_FormFacePressure

  SUBROUTINE PH_Elem_C3D4P_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        F_eq(3*(i-1)+1) = F_eq(3*(i-1)+1) + N(i) * bx * detJ * weights(ip)
        F_eq(3*(i-1)+2) = F_eq(3*(i-1)+2) + N(i) * by * detJ * weights(ip)
        F_eq(3*(i-1)+3) = F_eq(3*(i-1)+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4P_FormBodyForce

  SUBROUTINE PH_Elem_C3D4P_FormPoreSource(coords, q_source, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: q_source
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D4P_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4P_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4P_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        F_eq(12+i) = F_eq(12+i) + N(i) * q_source * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4P_FormPoreSource

  SUBROUTINE PH_Elem_C3D4P_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D4P_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D4P_FormFacePressure(coords, val(1), face_id, F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_PORE_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D4P_FormPoreSource(coords, val(1), F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D4P_FormNodalForce

  SUBROUTINE PH_Elem_C3D4P_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_C3D4P_EvalPrincStress

  SUBROUTINE PH_Elem_C3D4P_EvalStressInvar(sigma, I1, J2, J3)
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
  END SUBROUTINE PH_Elem_C3D4P_EvalStressInvar

  SUBROUTINE PH_Elem_C3D4P_CollectIPVars(ip_stress, ip_strain, ip_pore, ip_peeq, n_ip, out_vars)
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
  END SUBROUTINE PH_Elem_C3D4P_CollectIPVars

  SUBROUTINE PH_Elem_C3D4P_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: p, J2
    p = (sigma(1) + sigma(2) + sigma(3)) / 3.0_wp
    J2 = HALF * ((sigma(1)-p)**2 + (sigma(2)-p)**2 + (sigma(3)-p)**2) &
         + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D4P_EvalVonMises

  SUBROUTINE PH_Elem_C3D4P_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 1)
    E(1:4, 1) = ONE
  END SUBROUTINE PH_Elem_C3D4P_GetExtrapMat

  SUBROUTINE PH_Elem_C3D4P_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    INTEGER(i4) :: ic, i, n_comp
    node_vars = ZERO
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 4
        IF (SIZE(ip_vars, 1) >= 1) node_vars(i, ic) = ip_vars(1, ic)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4P_MapToNode

END MODULE PH_Elem_C3D4P