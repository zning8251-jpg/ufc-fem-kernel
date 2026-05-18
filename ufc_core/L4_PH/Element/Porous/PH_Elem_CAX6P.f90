!===============================================================================
! MODULE: PH_Elem_CAX6P
! LAYER:  L4_PH
! DOMAIN: Element/Porous
! ROLE:   Proc
! BRIEF:  CAX6P 6-node axisymmetric triangle with pore pressure
!===============================================================================
MODULE PH_Elem_CAX6P
!> [CORE] CAX6P element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_CAX6, ONLY: &
    PH_Elem_CAX6_ShapeFunc, PH_Elem_CAX6_Jac, PH_Elem_CAX6_JacB, &
    PH_Elem_CAX6_GaussPoints, PH_ELEM_CAX6_FACE_NODES, PH_ELEM_CAX6_EDGE_NODES
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NNODE = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NIP   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDPN_STRUCT = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDPN_PORE   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDPN_TOTAL  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDOF_STRUCT = 12_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDOF_PORE   = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX6P_NDOF        = 18_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_PORE_SOURCE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_N_IP = 3, PH_ELEM_N_NODE = 6
  REAL(wp), PARAMETER :: TWOPI = 6.283185307179586_wp

  PUBLIC :: PH_Elem_CAX6P_DefInit, PH_Elem_CAX6P_ShapeFunc, PH_Elem_CAX6P_Jac
  PUBLIC :: PH_Elem_CAX6P_BMatrix, PH_Elem_CAX6P_BpMatrix, PH_Elem_CAX6P_GaussPoints
  PUBLIC :: PH_Elem_CAX6P_JacB, PH_Elem_CAX6P_FormStiffMatrix, PH_Elem_CAX6P_FormIntForce
  PUBLIC :: PH_ELEM_CAX6P_NNODE, PH_ELEM_CAX6P_NIP, PH_ELEM_CAX6P_NDOF, PH_ELEM_CAX6P_NDOF_STRUCT, PH_ELEM_CAX6P_NDOF_PORE
  PUBLIC :: PH_ELEM_CAX6P_NDPN_STRUCT, PH_ELEM_CAX6P_NDPN_PORE, PH_ELEM_CAX6P_NDPN_TOTAL
  PUBLIC :: PH_Elem_CAX6P_NL_TL, PH_Elem_CAX6P_NL_UL
  PUBLIC :: PH_Elem_CAX6P_GetArea, PH_Elem_CAX6P_GetVolume, PH_Elem_CAX6P_GetSectProps
  PUBLIC :: PH_Elem_CAX6P_GetCentroid, PH_Elem_CAX6P_GetInertiaOrig
  PUBLIC :: PH_Elem_CAX6P_ApplyConstraint, PH_Elem_CAX6P_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_CAX6P_FormContactContrib, PH_Elem_CAX6P_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CAX6P_FormNodalForce, PH_Elem_CAX6P_FormBodyForce
  PUBLIC :: PH_Elem_CAX6P_FormFacePressure, PH_Elem_CAX6P_FormPoreSource
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P, PH_ELEM_LOAD_PORE_SOURCE
  PUBLIC :: PH_Elem_CAX6P_CollectIPVars, PH_Elem_CAX6P_MapToNode
  PUBLIC :: PH_Elem_CAX6P_GetExtrapMat, PH_Elem_CAX6P_EvalVonMises
  PUBLIC :: PH_Elem_CAX6P_EvalPrincStress, PH_Elem_CAX6P_EvalStressInvar

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

  SUBROUTINE PH_Elem_CAX6P_BpMatrix(dNdx, Bp)
    REAL(wp), INTENT(IN)  :: dNdx(2, 6)
    REAL(wp), INTENT(OUT) :: Bp(2, 6)
    INTEGER(i4) :: i
    DO i = 1, 6
      Bp(1, i) = dNdx(1, i)
      Bp(2, i) = dNdx(2, i)
    END DO
  END SUBROUTINE PH_Elem_CAX6P_BpMatrix

  SUBROUTINE PH_Elem_CAX6P_BMatrix(dNdx, N, r_pt, B)
    REAL(wp), INTENT(IN)  :: dNdx(2, 6)
    REAL(wp), INTENT(IN)  :: N(6)
    REAL(wp), INTENT(IN)  :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 12)
    INTEGER(i4) :: i
    REAL(wp) :: rinv
    B = ZERO
    rinv = ZERO
    IF (r_pt > 1.0e-20_wp) rinv = ONE / r_pt
    DO i = 1, 6
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = N(i) * rinv
      B(4, 2*i-1) = dNdx(2, i)
      B(4, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CAX6P_BMatrix

  SUBROUTINE PH_Elem_CAX6P_DefInit()
  END SUBROUTINE PH_Elem_CAX6P_DefInit

  SUBROUTINE PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(3), eta(3), weights(3)
    CALL PH_Elem_CAX6_GaussPoints(xi, eta, weights)
  END SUBROUTINE PH_Elem_CAX6P_GaussPoints

  SUBROUTINE PH_Elem_CAX6P_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(6)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 6)
    CALL PH_Elem_CAX6_ShapeFunc(xi, eta, N, dNdxi)
  END SUBROUTINE PH_Elem_CAX6P_ShapeFunc

  SUBROUTINE PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 6)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    CALL PH_Elem_CAX6_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_CAX6P_Jac

  SUBROUTINE PH_Elem_CAX6P_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B, Bp)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(6)
    REAL(wp), INTENT(OUT) :: dNdx(2, 6)
    REAL(wp), INTENT(OUT) :: J(2, 2), detJ
    REAL(wp), INTENT(OUT) :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 12), Bp(2, 6)
    CALL PH_Elem_CAX6_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)
    CALL PH_Elem_CAX6P_BpMatrix(dNdx, Bp)
  END SUBROUTINE PH_Elem_CAX6P_JacB

  SUBROUTINE PH_Elem_CAX6P_FormStiffMatrix(coords, D_struct, k_hyd, alpha_b, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: D_struct(4, 4)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke(18, 18)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), detJ, r_pt
    REAL(wp) :: B(4, 12), Bp(2, 6)
    REAL(wp) :: m_vec(4), dV
    REAL(wp) :: Kuu_block(12, 12), Kpp_block(6, 6)
    REAL(wp) :: Kup_block(12, 6)
    INTEGER(i4) :: ip, i, j
    Ke = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      dV = TWOPI * r_pt * detJ * weights(ip)
      Kuu_block = MATMUL(MATMUL(TRANSPOSE(B), D_struct), B) * dV
      Ke(1:12, 1:12) = Ke(1:12, 1:12) + Kuu_block
      Kpp_block = k_hyd * MATMUL(TRANSPOSE(Bp), Bp) * dV
      Ke(13:18, 13:18) = Ke(13:18, 13:18) + Kpp_block
      DO i = 1, 12
        DO j = 1, 6
          Kup_block(i, j) = alpha_b * DOT_PRODUCT(B(:, i), m_vec) * N(j) * dV
          Ke(i, 12+j) = Ke(i, 12+j) + Kup_block(i, j)
        END DO
      END DO
      DO i = 1, 6
        DO j = 1, 12
          Ke(12+i, j) = Ke(12+i, j) + Kup_block(j, i)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_FormStiffMatrix

  SUBROUTINE PH_Elem_CAX6P_FormIntForce(coords, u_struct, p_pore, D_struct, k_hyd, alpha_b, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: u_struct(12), p_pore(6)
    REAL(wp), INTENT(IN)  :: D_struct(4, 4)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: R_int(18)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), detJ, r_pt
    REAL(wp) :: B(4, 12), Bp(2, 6)
    REAL(wp) :: m_vec(4), strain(4), sigma(4)
    REAL(wp) :: grad_p(2), dV
    INTEGER(i4) :: ip, i
    R_int = ZERO
    m_vec = ZERO
    m_vec(1:3) = ONE
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B, Bp)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      dV = TWOPI * r_pt * detJ * weights(ip)
      strain = MATMUL(B, u_struct)
      sigma = MATMUL(D_struct, strain)
      R_int(1:12) = R_int(1:12) + MATMUL(TRANSPOSE(B), sigma) * dV
      DO i = 1, 12
        R_int(i) = R_int(i) - alpha_b * DOT_PRODUCT(B(:, i), m_vec) * DOT_PRODUCT(N, p_pore) * dV
      END DO
      grad_p = MATMUL(Bp, p_pore)
      R_int(13:18) = R_int(13:18) + k_hyd * MATMUL(TRANSPOSE(Bp), grad_p) * dV
    END DO
  END SUBROUTINE PH_Elem_CAX6P_FormIntForce

  SUBROUTINE PH_Elem_CAX6P_NL_TL(coords_ref, u_elem, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(2, 6)
    REAL(wp), INTENT(IN)  :: u_elem(18)
    REAL(wp), INTENT(IN)  :: D(4, 4)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(18, 18), Ke_geo(18, 18), R_int(18)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_CAX6P_FormStiffMatrix(coords_ref, D, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_CAX6P_FormIntForce(coords_ref, u_elem(1:12), u_elem(13:18), &
                                    D, k_hyd, alpha_b, R_int)
  END SUBROUTINE PH_Elem_CAX6P_NL_TL

  SUBROUTINE PH_Elem_CAX6P_NL_UL(coords_prev, u_incr, D, k_hyd, alpha_b, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(2, 6)
    REAL(wp), INTENT(IN)  :: u_incr(18)
    REAL(wp), INTENT(IN)  :: D(4, 4)
    REAL(wp), INTENT(IN)  :: k_hyd, alpha_b
    REAL(wp), INTENT(OUT) :: Ke_mat(18, 18), Ke_geo(18, 18), R_int(18)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    CALL PH_Elem_CAX6P_FormStiffMatrix(coords_prev, D, k_hyd, alpha_b, Ke_mat)
    CALL PH_Elem_CAX6P_FormIntForce(coords_prev, u_incr(1:12), u_incr(13:18), &
                                    D, k_hyd, alpha_b, R_int)
  END SUBROUTINE PH_Elem_CAX6P_NL_UL

  SUBROUTINE PH_Elem_CAX6P_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ, r_pt
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3) + N(4)*coords(1,4) + N(5)*coords(1,5) + N(6)*coords(1,6)
      dV = TWOPI * r_pt * detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 2
        DO j = 1, 6
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid = centroid / volume
  END SUBROUTINE PH_Elem_CAX6P_GetCentroid

  SUBROUTINE PH_Elem_CAX6P_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(2, 2)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ, r_pt
    REAL(wp) :: x(2), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3) + N(4)*coords(1,4) + N(5)*coords(1,5) + N(6)*coords(1,6)
      IF (r_pt < 1.0e-12_wp) CYCLE
      dV = rho * TWOPI * r_pt * detJ * weights(ip)
      x = ZERO
      DO k = 1, 6
        x = x + N(k) * coords(:, k)
      END DO
      r2 = SUM(x**2)
      DO i = 1, 2
        DO j = 1, 2
          I_out(i, j) = I_out(i, j) - x(i) * x(j) * dV
        END DO
        I_out(i, i) = I_out(i, i) + r2 * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_GetInertiaOrig

  SUBROUTINE PH_Elem_CAX6P_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_CAX6P_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_CAX6P_GetSectProps

  SUBROUTINE PH_Elem_CAX6P_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX6P_GetArea

  SUBROUTINE PH_Elem_CAX6P_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3) + N(4)*coords(1,4) + N(5)*coords(1,5) + N(6)*coords(1,6)
    volume = volume + TWOPI * r_pt * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX6P_GetVolume

  SUBROUTINE PH_Elem_CAX6P_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > PH_ELEM_CAX6P_NDOF) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_CAX6P_ApplyConstraint

  SUBROUTINE PH_Elem_CAX6P_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(18)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    INTEGER(i4) :: i, j
    DO i = 1, PH_ELEM_CAX6P_NDOF
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, PH_ELEM_CAX6P_NDOF
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_ApplyMPC

  SUBROUTINE PH_Elem_CAX6P_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, r_edge, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(6)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(IN)  :: r_edge
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 6
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * r_edge * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * r_edge * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 6
      DO b = 1, 6
        k_ab = penalty * N(a) * N(b) * edge_len * r_edge
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_FormContactContrib

  SUBROUTINE PH_Elem_CAX6P_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(18, 18)
    REAL(wp), INTENT(OUT) :: F_el(18)
    REAL(wp) :: xi, eta, N(6), n(2), dNdxi(2, 6)
    REAL(wp) :: t(2), len, rmid
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CAX6_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX6_EDGE_NODES(2, edge_id)
    SELECT CASE (edge_id)
    CASE (1); xi = HALF; eta = HALF
    CASE (2); xi = ZERO; eta = HALF
    CASE (3); xi = HALF; eta = ZERO
    END SELECT
    CALL PH_Elem_CAX6P_ShapeFunc(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    rmid = (coords(1, n1) + coords(1, n2)) * HALF
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CAX6P_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, rmid, K_el, F_el)
  END SUBROUTINE PH_Elem_CAX6P_FormContactEdgeCtr

  SUBROUTINE PH_Elem_CAX6P_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(18)
    REAL(wp) :: t(2), len, nr, nz, rmid, f3
    INTEGER(i4) :: n1, n2, nmid
    INTEGER(i4), PARAMETER :: EDGE_MID(3) = [4, 5, 6]
    F_eq = ZERO
    IF (face_id < 1 .OR. face_id > 3) RETURN
    n1 = PH_ELEM_CAX6_FACE_NODES(1, face_id)
    n2 = PH_ELEM_CAX6_FACE_NODES(2, face_id)
    nmid = EDGE_MID(face_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    nr = -t(2) / len
    nz =  t(1) / len
    rmid = (coords(1, n1) + coords(1, n2) + coords(1, nmid)) / 3.0_wp
    f3 = p * rmid * len / 3.0_wp
    F_eq(2*n1-1) = F_eq(2*n1-1) + f3 * nr
    F_eq(2*n1)   = F_eq(2*n1)   + f3 * nz
    F_eq(2*n2-1) = F_eq(2*n2-1) + f3 * nr
    F_eq(2*n2)   = F_eq(2*n2)   + f3 * nz
    F_eq(2*nmid-1) = F_eq(2*nmid-1) + f3 * nr
    F_eq(2*nmid)   = F_eq(2*nmid)   + f3 * nz
  END SUBROUTINE PH_Elem_CAX6P_FormFacePressure

  SUBROUTINE PH_Elem_CAX6P_FormBodyForce(coords, br, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: br, bz
    REAL(wp), INTENT(OUT) :: F_eq(18)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3) + N(4)*coords(1,4) + N(5)*coords(1,5) + N(6)*coords(1,6)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 6
        F_eq(2*(i-1)+1) = F_eq(2*(i-1)+1) + N(i) * br * TWOPI * r_pt * detJ * weights(ip)
        F_eq(2*(i-1)+2) = F_eq(2*(i-1)+2) + N(i) * bz * TWOPI * r_pt * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_FormBodyForce

  SUBROUTINE PH_Elem_CAX6P_FormPoreSource(coords, q_source, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: q_source
    REAL(wp), INTENT(OUT) :: F_eq(18)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX6P_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3) + N(4)*coords(1,4) + N(5)*coords(1,5) + N(6)*coords(1,6)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 6
        F_eq(12+i) = F_eq(12+i) + N(i) * q_source * TWOPI * r_pt * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_FormPoreSource

  SUBROUTINE PH_Elem_CAX6P_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(18)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CAX6P_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX6P_FormFacePressure(coords, val(1), face_id, F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_PORE_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX6P_FormPoreSource(coords, val(1), F_eq)
    END IF
  END SUBROUTINE PH_Elem_CAX6P_FormNodalForce

  SUBROUTINE PH_Elem_CAX6P_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: principal(3)
    REAL(wp) :: sr, sz, st, srz, p, q
    sr = sigma(1)
    sz = sigma(2)
    st = sigma(3)
    srz = sigma(4)
    p = (sr + sz + st) / 3.0_wp
    q = SQRT(HALF*((sr-sz)**2 + (sz-st)**2 + (st-sr)**2) + 3.0_wp*srz*srz)
    principal(1) = p + q
    principal(2) = p
    principal(3) = p - q
  END SUBROUTINE PH_Elem_CAX6P_EvalPrincStress

  SUBROUTINE PH_Elem_CAX6P_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdevr, sdevz, sdevt
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdevr = sigma(1) - p
    sdevz = sigma(2) - p
    sdevt = sigma(3) - p
    J2 = HALF * (sdevr*sdevr + sdevz*sdevz + sdevt*sdevt) + sigma(4)*sigma(4)
  END SUBROUTINE PH_Elem_CAX6P_EvalStressInvar

  SUBROUTINE PH_Elem_CAX6P_CollectIPVars(ip_stress, ip_strain, ip_pore, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_pore(:)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, PH_ELEM_N_IP)
      IF (SIZE(out_vars, 1) >= 14 .AND. SIZE(ip_stress, 1) >= 4) out_vars(1:4, ip) = ip_stress(1:4, ip)
      IF (SIZE(ip_strain, 1) >= 4) out_vars(5:8, ip) = ip_strain(1:4, ip)
      IF (SIZE(ip_pore) >= ip) out_vars(9, ip) = ip_pore(ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(10, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX6P_CollectIPVars

  SUBROUTINE PH_Elem_CAX6P_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: sr, sz, st, srz
    sr = sigma(1)
    sz = sigma(2)
    st = sigma(3)
    srz = sigma(4)
    seq = SQRT(HALF*((sr-sz)**2 + (sz-st)**2 + (st-sr)**2) + 3.0_wp*srz*srz)
  END SUBROUTINE PH_Elem_CAX6P_EvalVonMises

  SUBROUTINE PH_Elem_CAX6P_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(6, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6)
    REAL(wp) :: A(6, 3)
    INTEGER(i4) :: ip, i
    CALL PH_Elem_CAX6P_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 3
      CALL PH_Elem_CAX6P_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 6
        A(i, ip) = N(i)
      END DO
    END DO
    E = TRANSPOSE(A)
  END SUBROUTINE PH_Elem_CAX6P_GetExtrapMat

  SUBROUTINE PH_Elem_CAX6P_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(6, 3)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CAX6P_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 6
        DO j = 1, 3
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX6P_MapToNode

END MODULE PH_Elem_CAX6P