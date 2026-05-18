!===============================================================================
! MODULE: PH_Elem_CAX8
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CAX8 element definition (8-node axisymmetric Serendipity)
!===============================================================================
MODULE PH_Elem_CAX8
!> [CORE] CAX8 axisymmetric 8-node Serendipity quad (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE

  ! Constants
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_NNODE  = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_NIP   = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_NDOF  = 16_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX8_FACE_NODES(3, 4) = RESHAPE([ 1,2,5, 2,3,6, 3,4,7, 4,1,8 ], [3, 4])
  INTEGER(i4), PARAMETER :: EDGE_MID(4) = [5, 6, 7, 8]
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.774596669241483_wp
  REAL(wp), PARAMETER :: TWOPI = 6.283185307179586_wp

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_CAX8_DefInit
  PUBLIC :: PH_Elem_CAX8_ShapeFunc
  PUBLIC :: PH_Elem_CAX8_Jac
  PUBLIC :: PH_Elem_CAX8_BMatrix
  PUBLIC :: PH_Elem_CAX8_GaussPoints
  PUBLIC :: PH_Elem_CAX8_JacB
  PUBLIC :: PH_Elem_CAX8_Strain
  PUBLIC :: PH_Elem_CAX8_Stress
  PUBLIC :: PH_Elem_CAX8_ConstMatrix
  PUBLIC :: PH_Elem_CAX8_FormStiffMatrix
  PUBLIC :: PH_Elem_CAX8_FormIntForce
  PUBLIC :: PH_Elem_CAX8_FormIntForceFromStress
  PUBLIC :: PH_Elem_CAX8_ConsMass
  PUBLIC :: PH_Elem_CAX8_LumpMass
  PUBLIC :: PH_Elem_CAX8_ThermStrainVector
  PUBLIC :: PH_Elem_CAX8_NL_TL
  PUBLIC :: PH_Elem_CAX8_NL_UL
  PUBLIC :: PH_ELEM_CAX8_NNODE, PH_ELEM_CAX8_NIP, PH_ELEM_CAX8_NDOF, PH_ELEM_CAX8_NEDGE
  PUBLIC :: PH_ELEM_CAX8_EDGE_NODES, PH_ELEM_CAX8_FACE_NODES, PH_ELEM_GAUSS_PT
  PUBLIC :: PH_Elem_CAX8_GetArea
  PUBLIC :: PH_Elem_CAX8_GetVolume
  PUBLIC :: PH_Elem_CAX8_GetCentroid
  PUBLIC :: PH_Elem_CAX8_GetSectProps
  PUBLIC :: PH_Elem_CAX8_ApplyConstraint
  PUBLIC :: PH_Elem_CAX8_ApplyMPC
  PUBLIC :: PH_Elem_CAX8_FormContactContrib
  PUBLIC :: PH_Elem_CAX8_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CAX8_FormNodalForce
  PUBLIC :: PH_Elem_CAX8_FormBodyForce
  PUBLIC :: PH_Elem_CAX8_FormEdgePressure
  PUBLIC :: PH_Elem_CAX8_CollectIPVars
  PUBLIC :: PH_Elem_CAX8_MapToNode
  PUBLIC :: PH_Elem_CAX8_GetExtrapMat
  PUBLIC :: PH_Elem_CAX8_EvalVonMises
  PUBLIC :: PH_Elem_CAX8_EvalPrincStress
  PUBLIC :: PH_Elem_CAX8_EvalStressInvar
  PUBLIC :: PH_Elem_CAX8_Material_Update_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld2D_Args
  TYPE :: PH_Elem_Sld2D_Args
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
  END TYPE PH_Elem_Sld2D_Args


CONTAINS

  !=============================================================================
  ! DEFINITION (core)
  !=============================================================================
  SUBROUTINE PH_ELEM_CAX8_VolInt(coords, area_r)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area_r
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i
    area_r = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
      r_pt = ZERO
      DO i = 1, 8
        r_pt = r_pt + N(i) * coords(1, i)
      END DO
      area_r = area_r + r_pt * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CAX8_VolInt

  SUBROUTINE PH_Elem_CAX8_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(4)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = e
    eps_th(4) = ZERO
  END SUBROUTINE PH_Elem_CAX8_ThermStrainVector

  SUBROUTINE PH_Elem_CAX8_BMatrix_4x16(dNdx, N, r_pt, B)
    REAL(wp), INTENT(IN)  :: dNdx(2, 8)
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 16)
    INTEGER(i4) :: i
    REAL(wp) :: rinv
    B = ZERO
    rinv = ZERO
    IF (r_pt > 1.0e-20_wp) rinv = ONE / r_pt
    DO i = 1, 8
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = N(i) * rinv
      B(4, 2*i-1) = dNdx(2, i)
      B(4, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CAX8_BMatrix_4x16

  ! Overload for CAX8P (plane strain B 3x16, 2-arg)
  SUBROUTINE PH_Elem_CAX8_BMatrix_3x16(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 8)
    REAL(wp), INTENT(OUT) :: B(3, 16)
    INTEGER(i4) :: i
    B = ZERO
    DO i = 1, 8
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = dNdx(2, i)
      B(3, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CAX8_BMatrix_3x16

  INTERFACE PH_Elem_CAX8_BMatrix
    MODULE PROCEDURE PH_Elem_CAX8_BMatrix_4x16
    MODULE PROCEDURE PH_Elem_CAX8_BMatrix_3x16
  END INTERFACE

  SUBROUTINE PH_Elem_CAX8_ShapeFunc_2D(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 8)
    N(1) = QUARTER * (ONE - xi) * (ONE - eta) * (-ONE - xi - eta)
    N(2) = QUARTER * (ONE + xi) * (ONE - eta) * (-ONE + xi - eta)
    N(3) = QUARTER * (ONE + xi) * (ONE + eta) * (-ONE + xi + eta)
    N(4) = QUARTER * (ONE - xi) * (ONE + eta) * (-ONE - xi + eta)
    N(5) = HALF * (ONE - xi*xi) * (ONE - eta)
    N(6) = HALF * (ONE + xi) * (ONE - eta*eta)
    N(7) = HALF * (ONE - xi*xi) * (ONE + eta)
    N(8) = HALF * (ONE - xi) * (ONE - eta*eta)
    dNdxi(1, 1) = QUARTER * (ONE - eta) * (2.0_wp*xi + eta)
    dNdxi(2, 1) = QUARTER * (ONE - xi) * (2.0_wp*eta + xi)
    dNdxi(1, 2) = QUARTER * (ONE - eta) * (2.0_wp*xi - eta)
    dNdxi(2, 2) = QUARTER * (ONE + xi) * (2.0_wp*eta - xi)
    dNdxi(1, 3) = QUARTER * (ONE + eta) * (2.0_wp*xi + eta)
    dNdxi(2, 3) = QUARTER * (ONE + xi) * (2.0_wp*eta + xi)
    dNdxi(1, 4) = QUARTER * (ONE + eta) * (2.0_wp*xi - eta)
    dNdxi(2, 4) = QUARTER * (ONE - xi) * (2.0_wp*eta - xi)
    dNdxi(1, 5) = -xi * (ONE - eta)
    dNdxi(2, 5) = -HALF * (ONE - xi*xi)
    dNdxi(1, 6) = HALF * (ONE - eta*eta)
    dNdxi(2, 6) = -(ONE + xi) * eta
    dNdxi(1, 7) = -xi * (ONE + eta)
    dNdxi(2, 7) = HALF * (ONE - xi*xi)
    dNdxi(1, 8) = -HALF * (ONE - eta*eta)
    dNdxi(2, 8) = -(ONE - xi) * eta
  END SUBROUTINE PH_Elem_CAX8_ShapeFunc_2D

  ! Overload for CAX8P (3D interface, zeta ignored)
  SUBROUTINE PH_Elem_CAX8_ShapeFunc_3D(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 8)
    REAL(wp) :: dNdxi_2d(2, 8)
    CALL PH_Elem_CAX8_ShapeFunc_2D(xi, eta, N, dNdxi_2d)
    dNdxi(1:2, :) = dNdxi_2d
    dNdxi(3, :) = ZERO
  END SUBROUTINE PH_Elem_CAX8_ShapeFunc_3D

  INTERFACE PH_Elem_CAX8_ShapeFunc
    MODULE PROCEDURE PH_Elem_CAX8_ShapeFunc_2D
    MODULE PROCEDURE PH_Elem_CAX8_ShapeFunc_3D
  END INTERFACE

  SUBROUTINE PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 8)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i
    J = ZERO
    DO i = 1, 8
      J(1, 1) = J(1, 1) + dNdxi(1, i) * coords(1, i)
      J(1, 2) = J(1, 2) + dNdxi(1, i) * coords(2, i)
      J(2, 1) = J(2, 1) + dNdxi(2, i) * coords(1, i)
      J(2, 2) = J(2, 2) + dNdxi(2, i) * coords(2, i)
    END DO
    detJ = J(1, 1) * J(2, 2) - J(1, 2) * J(2, 1)
  END SUBROUTINE PH_Elem_CAX8_Jac_2D

  ! Overload for CAX8P (3D interface, uses 2D block)
  SUBROUTINE PH_Elem_CAX8_Jac_3D(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 8)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp) :: J2(2, 2), detJ2
    CALL PH_Elem_CAX8_Jac_2D(dNdxi(1:2, :), coords(1:2, :), J2, detJ2)
    J = ZERO
    J(1:2, 1:2) = J2
    J(3, 3) = ONE
    detJ = detJ2
  END SUBROUTINE PH_Elem_CAX8_Jac_3D

  INTERFACE PH_Elem_CAX8_Jac
    MODULE PROCEDURE PH_Elem_CAX8_Jac_2D
    MODULE PROCEDURE PH_Elem_CAX8_Jac_3D
  END INTERFACE

  SUBROUTINE PH_Elem_CAX8_JacB_2D(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdx(2, 8)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 16)
    REAL(wp) :: dNdxi(2, 8), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL PH_Elem_CAX8_ShapeFunc_2D(xi_pt, eta_pt, N, dNdxi)
    CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
    r_pt = ZERO
    DO i = 1, 8
      r_pt = r_pt + N(i) * coords(1, i)
    END DO
    IF (ABS(detJ) > 1.0e-20_wp) THEN
      Jinv(1, 1) =  J(2, 2) / detJ
      Jinv(1, 2) = -J(1, 2) / detJ
      Jinv(2, 1) = -J(2, 1) / detJ
      Jinv(2, 2) =  J(1, 1) / detJ
      DO i = 1, 8
        dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      CALL PH_Elem_CAX8_BMatrix_4x16(dNdx, N, r_pt, B)
    ELSE
      dNdx = ZERO
      B = ZERO
    END IF
  END SUBROUTINE PH_Elem_CAX8_JacB_2D

  ! Overload for CAX8P (3D coords, plane strain B 3x16)
  SUBROUTINE PH_Elem_CAX8_JacB_3D(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt, zeta_pt
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdx(3, 8)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(3, 16)
    REAL(wp) :: dNdx_2d(2, 8), J_2d(2, 2), detJ_2d, r_pt
    REAL(wp) :: B_ax(4, 16)
    CALL PH_Elem_CAX8_JacB_2D(coords(1:2, :), xi_pt, eta_pt, N, dNdx_2d, J_2d, detJ_2d, r_pt, B_ax)
    dNdx(1:2, :) = dNdx_2d
    dNdx(3, :) = ZERO
    J = ZERO
    J(1:2, 1:2) = J_2d
    J(3, 3) = ONE
    detJ = detJ_2d
    CALL PH_Elem_CAX8_BMatrix_3x16(dNdx, B)
  END SUBROUTINE PH_Elem_CAX8_JacB_3D

  INTERFACE PH_Elem_CAX8_JacB
    MODULE PROCEDURE PH_Elem_CAX8_JacB_2D
    MODULE PROCEDURE PH_Elem_CAX8_JacB_3D
  END INTERFACE

  SUBROUTINE PH_Elem_CAX8_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(4, 16)
    REAL(wp), INTENT(IN)  :: u(16)
    REAL(wp), INTENT(OUT) :: strain(4)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_CAX8_Strain

  SUBROUTINE PH_Elem_CAX8_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(4)
    REAL(wp), INTENT(IN)  :: D(4, 4)
    REAL(wp), INTENT(OUT) :: sigma(4)
    sigma = MATMUL(D, epsilon)
  END SUBROUTINE PH_Elem_CAX8_Stress

  SUBROUTINE PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(9), eta(9), weights(9)
    REAL(wp), PARAMETER :: g = 0.774596669241483_wp
    REAL(wp), PARAMETER :: wc = 0.555555555555556_wp
    REAL(wp), PARAMETER :: we = 0.888888888888889_wp
    xi(1) = -g
    eta(1) = -g
    weights(1) = wc * wc
    xi(2) = 0.0_wp
    eta(2) = -g
    weights(2) = we * wc
    xi(3) = g
    eta(3) = -g
    weights(3) = wc * wc
    xi(4) = -g
    eta(4) = 0.0_wp
    weights(4) = wc * we
    xi(5) = 0.0_wp
    eta(5) = 0.0_wp
    weights(5) = we * we
    xi(6) = g
    eta(6) = 0.0_wp
    weights(6) = wc * we
    xi(7) = -g
    eta(7) = g
    weights(7) = wc * wc
    xi(8) = 0.0_wp
    eta(8) = g
    weights(8) = we * wc
    xi(9) = g
    eta(9) = g
    weights(9) = wc * wc
  END SUBROUTINE PH_Elem_CAX8_GaussPoints_2D

  ! Overload for CAX8P (zeta output, same as 2D)
  SUBROUTINE PH_Elem_CAX8_GaussPoints_3D(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(9), eta(9), zeta(9), weights(9)
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    zeta = 0.0_wp
  END SUBROUTINE PH_Elem_CAX8_GaussPoints_3D

  INTERFACE PH_Elem_CAX8_GaussPoints
    MODULE PROCEDURE PH_Elem_CAX8_GaussPoints_2D
    MODULE PROCEDURE PH_Elem_CAX8_GaussPoints_3D
  END INTERFACE

  SUBROUTINE PH_Elem_CAX8_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: D(4, 4)
    REAL(wp) :: c, c1, c2
    D = ZERO
    c = E_young / ((ONE + nu) * (ONE - 2.0_wp*nu))
    c1 = c * (ONE - nu)
    c2 = c * nu
    D(1, 1) = c1
    D(1, 2) = c2
    D(1, 3) = c2
    D(2, 1) = c2
    D(2, 2) = c1
    D(2, 3) = c2
    D(3, 1) = c2
    D(3, 2) = c2
    D(3, 3) = c1
    D(4, 4) = c * (ONE - 2.0_wp*nu) * HALF
  END SUBROUTINE PH_Elem_CAX8_ConstMatrix

  SUBROUTINE PH_Elem_CAX8_DefInit()
  END SUBROUTINE PH_Elem_CAX8_DefInit

  SUBROUTINE PH_Elem_CAX8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(16, 16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
      r_pt = ZERO
      DO i = 1, 8
        r_pt = r_pt + N(i) * coords(1, i)
      END DO
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 8
        DO j = 1, 8
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * TWOPI * r_pt * N(i)*N(j) * detJ * weights(ip)
          Me(2*i,   2*j)   = Me(2*i,   2*j)   + rho * TWOPI * r_pt * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX8_ConsMass

  SUBROUTINE PH_Elem_CAX8_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: u(16)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(4, 16), D(4, 4), strain(4), sigma(4), detJ, r_pt
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CAX8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      CALL PH_Elem_CAX8_Strain(B, u, strain)
      CALL PH_Elem_CAX8_Stress(strain, D, sigma)
      R_int = R_int + TWOPI * r_pt * MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX8_FormIntForce

  SUBROUTINE PH_Elem_CAX8_FormIntForceFromStress(coords, sigma4, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: sigma4(4)
    REAL(wp), INTENT(OUT) :: R_int(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(4, 16), detJ, r_pt
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      R_int = R_int + TWOPI * r_pt * MATMUL(TRANSPOSE(B), sigma4) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX8_FormIntForceFromStress

  SUBROUTINE PH_Elem_CAX8_FormStiffMatrix(coords, D_matrix, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: D_matrix(4, 4)
    REAL(wp), INTENT(OUT) :: Ke(16, 16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(4, 16), detJ, r_pt, dV
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      dV = TWOPI * r_pt * detJ * weights(ip)
      Ke = Ke + dV * MATMUL(MATMUL(TRANSPOSE(B), D_matrix), B)
    END DO
  END SUBROUTINE PH_Elem_CAX8_FormStiffMatrix

  SUBROUTINE PH_Elem_CAX8_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(16)
    REAL(wp) :: area_r, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CAX8_VolInt(coords, area_r)
    m = rho * TWOPI * area_r / 8.0_wp
    DO i = 1, 8
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CAX8_LumpMass

  !=============================================================================
  ! NL_TL / NL_UL - Legacy (for RT_AsmNLGeomDispatch)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX8_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 8)
    REAL(wp), INTENT(IN) :: u_elem(16)
    REAL(wp), INTENT(IN) :: D(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16)
    REAL(wp), INTENT(OUT) :: Ke_geo(16, 16)
    REAL(wp), INTENT(OUT) :: R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 8)
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), dN_dX(2, 8)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: r_gp
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt_4(4), S_voigt_4(4)
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(16, 16), K_geo_gp(16, 16), R_gp(16)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    status%code = STATUS_SUCCESS

    DO i = 1, 8
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*(i-1)+2)
    END DO

    CALL PH_Elem_CAX8_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 1
    DO i = 1, 8
      cfg%coords_ref(i, 1:2) = coords_ref(1:2, i)
      cfg%coords_ref(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO

    D6 = ZERO
    D6(1:4, 1:4) = D(1:4, 1:4)

    DO igp = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CAX8_Jac(dN_dxi, coords_ref, J_ref, det_J)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      r_gp = ZERO
      DO i = 1, 8
        r_gp = r_gp + N(i) * coords_ref(1, i)
      END DO
      IF (r_gp <= 1.0e-12_wp) CYCLE

      J_inv(1,1) =  J_ref(2,2) / det_J
      J_inv(1,2) = -J_ref(1,2) / det_J
      J_inv(2,1) = -J_ref(2,1) / det_J
      J_inv(2,2) =  J_ref(1,1) / det_J
      DO i = 1, 8
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO

      DO i = 1, 8
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
        cfg%lcl%dN_dX(i, 3) = ZERO
      END DO

      F = ZERO
      F(3, 3) = ONE
      DO i = 1, 8
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dX(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dX(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dX(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dX(2, i)
      END DO

      E = ZERO
      E(1, 1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) - ONE)
      E(2, 2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) - ONE)
      E(3, 3) = ZERO
      DO i = 1, 8
        IF (coords_ref(1, i) > 1.0e-20_wp) E(3, 3) = E(3, 3) + N(i) * u_elem(2*(i-1)+1) / coords_ref(1, i)
      END DO
      E(1, 2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2))
      E(2, 1) = E(1, 2)

      E_voigt_4(1) = E(1, 1)
      E_voigt_4(2) = E(2, 2)
      E_voigt_4(3) = E(3, 3)
      E_voigt_4(4) = 2.0_wp * E(1, 2)

      S_voigt_4 = MATMUL(D, E_voigt_4)
      S = ZERO
      S(1, 1) = S_voigt_4(1)
      S(2, 2) = S_voigt_4(2)
      S(3, 3) = S_voigt_4(3)
      S(1, 2) = S_voigt_4(4)
      S(2, 1) = S_voigt_4(4)

      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, D6)
      IF (status%status_code /= IF_STATUS_OK .AND. status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * r_gp * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * r_gp * wt_gp(igp)
      R_int = R_int + R_gp * det_J * r_gp * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CAX8_NL_TL

  SUBROUTINE PH_Elem_CAX8_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 8)
    REAL(wp), INTENT(IN) :: u_incr(16)
    REAL(wp), INTENT(IN) :: D(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16)
    REAL(wp), INTENT(OUT) :: Ke_geo(16, 16)
    REAL(wp), INTENT(OUT) :: R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 8)
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), dN_dx(2, 8)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: r_gp
    REAL(wp) :: F(3, 3), eps(3, 3), sigma(3, 3)
    REAL(wp) :: eps_voigt_4(4), sigma_voigt_4(4)
    REAL(wp) :: b(2,2), b_inv(2,2), det_b
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(16, 16), K_geo_gp(16, 16), R_gp(16)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    status%code = STATUS_SUCCESS

    DO i = 1, 8
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*(i-1)+2)
    END DO

    CALL PH_Elem_CAX8_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 2
    DO i = 1, 8
      cfg%coords_prev(i, 1:2) = coords_prev(1:2, i)
      cfg%coords_prev(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO

    D6 = ZERO
    D6(1:4, 1:4) = D(1:4, 1:4)

    DO igp = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CAX8_Jac(dN_dxi, coords_prev, J_prev, det_J)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      r_gp = ZERO
      DO i = 1, 8
        r_gp = r_gp + N(i) * coords_prev(1, i)
      END DO
      IF (r_gp <= 1.0e-12_wp) CYCLE

      J_inv(1,1) =  J_prev(2,2) / det_J
      J_inv(1,2) = -J_prev(1,2) / det_J
      J_inv(2,1) = -J_prev(2,1) / det_J
      J_inv(2,2) =  J_prev(1,1) / det_J
      DO i = 1, 8
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO

      DO i = 1, 8
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
        cfg%dN_dx(i, 3) = ZERO
      END DO

      F = ZERO
      F(3, 3) = ONE
      DO i = 1, 8
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dx(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dx(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dx(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dx(2, i)
      END DO

      b = MATMUL(F(1:2,1:2), TRANSPOSE(F(1:2,1:2)))
      det_b = b(1,1)*b(2,2) - b(1,2)*b(2,1)
      IF (ABS(det_b) <= 1.0e-12_wp) CYCLE
      b_inv(1,1) =  b(2,2) / det_b
      b_inv(1,2) = -b(1,2) / det_b
      b_inv(2,1) = -b(2,1) / det_b
      b_inv(2,2) =  b(1,1) / det_b

      eps = ZERO
      eps(1, 1) = HALF * (ONE - b_inv(1,1))
      eps(2, 2) = HALF * (ONE - b_inv(2,2))
      eps(3, 3) = ZERO
      DO i = 1, 8
        IF (coords_prev(1, i) > 1.0e-20_wp) eps(3, 3) = eps(3, 3) + N(i) * u_incr(2*(i-1)+1) / coords_prev(1, i)
      END DO
      eps(1, 2) = -HALF * b_inv(1,2)
      eps(2, 1) = eps(1, 2)

      eps_voigt_4(1) = eps(1, 1)
      eps_voigt_4(2) = eps(2, 2)
      eps_voigt_4(3) = eps(3, 3)
      eps_voigt_4(4) = 2.0_wp * eps(1, 2)

      sigma_voigt_4 = MATMUL(D, eps_voigt_4)
      sigma = ZERO
      sigma(1, 1) = sigma_voigt_4(1)
      sigma(2, 2) = sigma_voigt_4(2)
      sigma(3, 3) = sigma_voigt_4(3)
      sigma(1, 2) = sigma_voigt_4(4)
      sigma(2, 1) = sigma_voigt_4(4)

      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, eps, sigma, K_mat_gp, K_geo_gp, status, R_gp, D6)
      IF (status%status_code /= IF_STATUS_OK .AND. status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * r_gp * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * r_gp * wt_gp(igp)
      R_int = R_int + R_gp * det_J * r_gp * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CAX8_NL_UL

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX8_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX8_GetArea

  SUBROUTINE PH_Elem_CAX8_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: area_r
    CALL PH_ELEM_CAX8_VolInt(coords, area_r)
    volume = TWOPI * area_r
  END SUBROUTINE PH_Elem_CAX8_GetVolume

  SUBROUTINE PH_Elem_CAX8_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: volume, dV
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
      r_pt = ZERO
      DO i = 1, 8
        r_pt = r_pt + N(i) * coords(1, i)
      END DO
      dV = TWOPI * r_pt * detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 2
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
    END IF
  END SUBROUTINE PH_Elem_CAX8_GetCentroid

  SUBROUTINE PH_Elem_CAX8_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CAX8_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_CAX8_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 16) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_CAX8_ApplyConstraint

  SUBROUTINE PH_Elem_CAX8_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(16)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    INTEGER(i4) :: i, j
    DO i = 1, 16
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 16
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX8_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined) - axisymmetric: r_edge factor for 2*pi*r
  !=============================================================================
  SUBROUTINE PH_Elem_CAX8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, r_edge, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(IN)  :: r_edge
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 8
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * r_edge * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * r_edge * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 8
      DO b = 1, 8
        k_ab = penalty * N(a) * N(b) * edge_len * r_edge
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX8_FormContactContrib

  SUBROUTINE PH_Elem_CAX8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(16, 16)
    REAL(wp), INTENT(OUT) :: F_el(16)
    REAL(wp) :: xi, eta, N(8), n(2), dNdxi(2, 8)
    REAL(wp) :: t(2), len, rmid
    INTEGER(i4) :: n1, n2, nmid
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CAX8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX8_EDGE_NODES(2, edge_id)
    nmid = EDGE_MID(edge_id)
    SELECT CASE (edge_id)
    CASE (1); xi = 0.0_wp; eta = -ONE
    CASE (2); xi = ONE; eta = 0.0_wp
    CASE (3); xi = 0.0_wp; eta = ONE
    CASE (4); xi = -ONE; eta = 0.0_wp
    END SELECT
    CALL PH_Elem_CAX8_ShapeFunc(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    rmid = (coords(1, n1) + coords(1, n2) + coords(1, nmid)) / 3.0_wp
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CAX8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, rmid, K_el, F_el)
  END SUBROUTINE PH_Elem_CAX8_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined) - axisymmetric: rmid factor for 2*pi*r
  !=============================================================================
  SUBROUTINE PH_Elem_CAX8_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: t(2), len, nr, nz, rmid, f3
    INTEGER(i4) :: n1, n2, nmid, ia
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CAX8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX8_EDGE_NODES(2, edge_id)
    nmid = EDGE_MID(edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    nr = -t(2) / len
    nz =  t(1) / len
    rmid = (coords(1, n1) + coords(1, n2) + coords(1, nmid)) / 3.0_wp
    f3 = p * rmid * len / 3.0_wp
    ia = 2 * n1 - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nr
    F_eq(ia+1) = F_eq(ia+1) + f3 * nz
    ia = 2 * n2 - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nr
    F_eq(ia+1) = F_eq(ia+1) + f3 * nz
    ia = 2 * nmid - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nr
    F_eq(ia+1) = F_eq(ia+1) + f3 * nz
  END SUBROUTINE PH_Elem_CAX8_FormEdgePressure

  SUBROUTINE PH_Elem_CAX8_FormBodyForce(coords, br, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: br, bz
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX8_Jac_2D(dNdxi, coords, J, detJ)
      r_pt = ZERO
      DO i = 1, 8
        r_pt = r_pt + N(i) * coords(1, i)
      END DO
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * br * TWOPI * r_pt * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * bz * TWOPI * r_pt * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX8_FormBodyForce

  SUBROUTINE PH_Elem_CAX8_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CAX8_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX8_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CAX8_FormNodalForce

  !=============================================================================
  ! OUTPUT (inlined)
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

  SUBROUTINE PH_Elem_CAX8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 9
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 9)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 4) out_vars(1:4, ip) = ip_stress(1:4, ip)
      IF (SIZE(ip_strain, 1) >= 4) out_vars(5:8, ip) = ip_strain(1:4, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(9, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX8_CollectIPVars

  SUBROUTINE PH_Elem_CAX8_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_CAX8_EvalPrincStress

  SUBROUTINE PH_Elem_CAX8_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdevr, sdevz, sdevt
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdevr = sigma(1) - p
    sdevz = sigma(2) - p
    sdevt = sigma(3) - p
    J2 = HALF * (sdevr*sdevr + sdevz*sdevz + sdevt*sdevt) + sigma(4)*sigma(4)
  END SUBROUTINE PH_Elem_CAX8_EvalStressInvar

  SUBROUTINE PH_Elem_CAX8_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: sr, sz, st, srz
    sr = sigma(1)
    sz = sigma(2)
    st = sigma(3)
    srz = sigma(4)
    seq = SQRT(HALF*((sr-sz)**2 + (sz-st)**2 + (st-sr)**2) + 3.0_wp*srz*srz)
  END SUBROUTINE PH_Elem_CAX8_EvalVonMises

  SUBROUTINE PH_Elem_CAX8_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(8, 9)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8)
    REAL(wp) :: A(8, 9), B(8, 8), Binv(8, 8)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CAX8_GaussPoints_2D(xi, eta, weights)
    A = ZERO
    DO ip = 1, 9
      CALL PH_Elem_CAX8_ShapeFunc_2D(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 8
        A(i, ip) = N(i)
      END DO
    END DO
    B = MATMUL(A(1:8, 1:9), TRANSPOSE(A(1:8, 1:9)))
    Binv = B
    CALL invert_8x8(Binv, info)
    IF (info /= 0) THEN
      E = ZERO
      RETURN
    END IF
    E = MATMUL(Binv, A)
  END SUBROUTINE PH_Elem_CAX8_GetExtrapMat

  SUBROUTINE PH_Elem_CAX8_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(8, 9)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CAX8_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 8
        DO j = 1, 9
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX8_MapToNode

  SUBROUTINE PH_Elem_CAX8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                 stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticAxisymmetric

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(4)
    REAL(wp),                  INTENT(IN)    :: stress_old(4)
    REAL(wp),                  INTENT(OUT)   :: stress_new(4)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(4, 4)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticAxisymmetric(rt_ctx, mat_slot, dStrain, &
                                              stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_CAX8_Material_Update_Routed

END MODULE PH_Elem_CAX8


