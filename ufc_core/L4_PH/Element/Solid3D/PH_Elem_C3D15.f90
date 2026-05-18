!===============================================================================
! MODULE: PH_Elem_C3D15
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D15 element definition (15-node quadratic wedge)
!===============================================================================
MODULE PH_Elem_C3D15
!> Status: Production | Last verified: 2026-03-10
!> Merged: Defn + Sect + Constraints + Cont + Loads + Out
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_C3D15_DefInit
  PUBLIC :: PH_Elem_C3D15_ShapeFunc
  PUBLIC :: PH_Elem_C3D15_Jac
  PUBLIC :: PH_Elem_C3D15_BMatrix
  PUBLIC :: PH_Elem_C3D15_GaussPoints
  PUBLIC :: PH_Elem_C3D15_JacB
  PUBLIC :: PH_Elem_C3D15_Strain
  PUBLIC :: PH_Elem_C3D15_Stress
  PUBLIC :: PH_Elem_C3D15_ConstMatrix
  PUBLIC :: PH_Elem_C3D15_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D15_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_C3D15_FormIntForce
  PUBLIC :: PH_Elem_C3D15_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D15_ConsMass
  PUBLIC :: PH_Elem_C3D15_LumpMass
  PUBLIC :: PH_Elem_C3D15_ThermStrainVector
  PUBLIC :: PH_ELEM_C3D15_NNODE
  PUBLIC :: PH_ELEM_C3D15_NIP
  PUBLIC :: PH_ELEM_C3D15_NDOF
  PUBLIC :: PH_ELEM_C3D15_NFACE
  PUBLIC :: PH_ELEM_C3D15_FACE_NODES
  PUBLIC :: PH_Elem_C3D15_NL_TL
  PUBLIC :: PH_Elem_C3D15_NL_UL
  PUBLIC :: PH_Elem_C3D15_Material_Update_Routed
  PUBLIC :: PH_Elem_C3D15_GetVolume, PH_Elem_C3D15_GetSectProps, PH_Elem_C3D15_GetCentroid
  PUBLIC :: PH_Elem_C3D15_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D15_ApplyConstraint, PH_Elem_C3D15_ApplyMPC
  PUBLIC :: PH_Elem_C3D15_FormContactContrib, PH_Elem_C3D15_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D15_FormNodalForce, PH_Elem_C3D15_FormBodyForce, PH_Elem_C3D15_FormFacePressure
  PUBLIC :: PH_Elem_C3D15_CollectIPVars, PH_Elem_C3D15_MapToNode, PH_Elem_C3D15_GetExtrapMat
  PUBLIC :: PH_Elem_C3D15_EvalVonMises, PH_Elem_C3D15_EvalPrincStress
  PUBLIC :: PH_Elem_C3D15_EvalStressInvar, PH_Elem_C3D15_EvalStrainInvar, PH_Elem_C3D15_EvalTriaxiality
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15_NNODE  = 15_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15_NIP   = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15_NDOF  = 45_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15_NFACE = 5_i4
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp
  ! Face: 1=bottom(1,2,3), 2=top(4,5,6), 3=(1,2,5,4), 4=(2,3,6,5), 5=(3,1,4,6). Store 4 nodes; tri use 4th=0.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15_FACE_NODES(4, 5) = RESHAPE([ &
    1,2,3,0, 4,5,6,0, 1,2,5,4, 2,3,6,5, 3,1,4,6 ], [4, 5])
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld3D_Args
  TYPE :: PH_Elem_Sld3D_Args
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
  END TYPE PH_Elem_Sld3D_Args


CONTAINS

  ! ---- Defn ----
  SUBROUTINE PH_Elem_C3D15_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(45, 45)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45), D(6, 6)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D15_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + detJ * weights(ip) * MATMUL(MATMUL(TRANSPOSE(B), D), B)
    END DO
  END SUBROUTINE PH_Elem_C3D15_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D15_FormStiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(45, 45)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + detJ * weights(ip) * MATMUL(MATMUL(TRANSPOSE(B), D6), B)
    END DO
  END SUBROUTINE PH_Elem_C3D15_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_C3D15_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1:3) = alpha * deltaT
    eps_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D15_ThermStrainVector

  SUBROUTINE PH_Elem_C3D15_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 15)
    REAL(wp), INTENT(OUT) :: B(6, 45)
    INTEGER(i4) :: i, c
    B = ZERO
    DO i = 1, 15
      c = 3 * (i - 1) + 1
      B(1, c)   = dNdx(1, i)
      B(2, c+1) = dNdx(2, i)
      B(3, c+2) = dNdx(3, i)
      B(4, c)   = dNdx(2, i)
      B(4, c+1) = dNdx(1, i)
      B(5, c+1) = dNdx(3, i)
      B(5, c+2) = dNdx(2, i)
      B(6, c)   = dNdx(3, i)
      B(6, c+2) = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_C3D15_BMatrix

  SUBROUTINE PH_Elem_C3D15_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(45, 45)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: dV, nij
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          nij = dV * N(i) * N(j)
          Me(3*i-2, 3*j-2) = Me(3*i-2, 3*j-2) + nij
          Me(3*i-1, 3*j-1) = Me(3*i-1, 3*j-1) + nij
          Me(3*i, 3*j)     = Me(3*i, 3*j)     + nij
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_ConsMass

  SUBROUTINE PH_Elem_C3D15_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: c1, c2
    D = ZERO
    c1 = E_young / ((ONE + nu) * (ONE - 2.0_wp*nu))
    c2 = (ONE - nu) * c1
    D(1,1) = c2
    D(1,2) = nu*c1
    D(1,3) = nu*c1
    D(2,1) = nu*c1
    D(2,2) = c2
    D(2,3) = nu*c1
    D(3,1) = nu*c1
    D(3,2) = nu*c1
    D(3,3) = c2
    D(4,4) = HALF * E_young / (ONE + nu)
    D(5,5) = D(4,4)
    D(6,6) = D(4,4)
  END SUBROUTINE PH_Elem_C3D15_ConstMatrix

  SUBROUTINE PH_Elem_C3D15_DefInit()
  END SUBROUTINE PH_Elem_C3D15_DefInit

  SUBROUTINE PH_Elem_C3D15_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: u(45)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(45)
    REAL(wp) :: Ke(45, 45)
    CALL PH_Elem_C3D15_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D15_FormIntForce

  SUBROUTINE PH_Elem_C3D15_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(45)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma6)
    END DO
  END SUBROUTINE PH_Elem_C3D15_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp), PARAMETER :: sq35 = 0.774596669241483_wp
    REAL(wp), PARAMETER :: w5 = 5.0_wp / 54.0_wp
    REAL(wp), PARAMETER :: w8 = 8.0_wp / 54.0_wp
    xi(1) = 1.0_wp/6.0_wp
    xi(2) = 1.0_wp/6.0_wp
    xi(3) = 1.0_wp/6.0_wp
    xi(4) = 2.0_wp/3.0_wp
    xi(5) = 2.0_wp/3.0_wp
    xi(6) = 2.0_wp/3.0_wp
    xi(7) = 1.0_wp/6.0_wp
    xi(8) = 1.0_wp/6.0_wp
    xi(9) = 1.0_wp/6.0_wp
    eta(1) = 1.0_wp/6.0_wp
    eta(2) = 1.0_wp/6.0_wp
    eta(3) = 1.0_wp/6.0_wp
    eta(4) = 1.0_wp/6.0_wp
    eta(5) = 1.0_wp/6.0_wp
    eta(6) = 1.0_wp/6.0_wp
    eta(7) = 2.0_wp/3.0_wp
    eta(8) = 2.0_wp/3.0_wp
    eta(9) = 2.0_wp/3.0_wp
    zeta(1) = -sq35
    zeta(2) = ZERO
    zeta(3) = sq35
    zeta(4) = -sq35
    zeta(5) = ZERO
    zeta(6) = sq35
    zeta(7) = -sq35
    zeta(8) = ZERO
    zeta(9) = sq35
    weights(1) = w5
    weights(2) = w8
    weights(3) = w5
    weights(4) = w5
    weights(5) = w8
    weights(6) = w5
    weights(7) = w5
    weights(8) = w8
    weights(9) = w5
  END SUBROUTINE PH_Elem_C3D15_GaussPoints

  SUBROUTINE PH_Elem_C3D15_GetVolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D15_GetVolumeInt

  SUBROUTINE PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 15)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i, j
    J = ZERO
    DO j = 1, 3
      DO i = 1, 15
        J(1, j) = J(1, j) + coords(1, i) * dNdxi(j, i)
        J(2, j) = J(2, j) + coords(2, i) * dNdxi(j, i)
        J(3, j) = J(3, j) + coords(3, i) * dNdxi(j, i)
      END DO
    END DO
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
  END SUBROUTINE PH_Elem_C3D15_Jac

  SUBROUTINE PH_Elem_C3D15_JacB(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt, zeta_pt
    REAL(wp), INTENT(OUT) :: N(15)
    REAL(wp), INTENT(OUT) :: dNdx(3, 15)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 45)
    REAL(wp) :: dNdxi(3, 15), J_inv(3, 3)
    INTEGER(i4) :: i, j, k
    CALL PH_Elem_C3D15_ShapeFunc(xi_pt, eta_pt, zeta_pt, N, dNdxi)
    CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) <= 1.0e-20_wp) THEN
      dNdx = ZERO
      B = ZERO
      RETURN
    END IF
    J_inv(1,1) = (J(2,2)*J(3,3)-J(2,3)*J(3,2))/detJ
    J_inv(1,2) = -(J(1,2)*J(3,3)-J(1,3)*J(3,2))/detJ
    J_inv(1,3) = (J(1,2)*J(2,3)-J(1,3)*J(2,2))/detJ
    J_inv(2,1) = -(J(2,1)*J(3,3)-J(2,3)*J(3,1))/detJ
    J_inv(2,2) = (J(1,1)*J(3,3)-J(1,3)*J(3,1))/detJ
    J_inv(2,3) = -(J(1,1)*J(2,3)-J(1,3)*J(2,1))/detJ
    J_inv(3,1) = (J(2,1)*J(3,2)-J(2,2)*J(3,1))/detJ
    J_inv(3,2) = -(J(1,1)*J(3,2)-J(1,2)*J(3,1))/detJ
    J_inv(3,3) = (J(1,1)*J(2,2)-J(1,2)*J(2,1))/detJ
    DO i = 1, 15
      DO j = 1, 3
        dNdx(j, i) = SUM(J_inv(j, 1:3) * dNdxi(1:3, i))
      END DO
    END DO
    CALL PH_Elem_C3D15_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_C3D15_JacB

  SUBROUTINE PH_Elem_C3D15_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(45)
    REAL(wp) :: V, m
    INTEGER(i4) :: i
    CALL PH_Elem_C3D15_GetVolumeInt(coords, V)
    m = rho * V / 15.0_wp
    DO i = 1, 15
      M_lumped(3*i-2) = m
      M_lumped(3*i-1) = m
      M_lumped(3*i)   = m
    END DO
  END SUBROUTINE PH_Elem_C3D15_LumpMass

  SUBROUTINE PH_Elem_C3D15_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 15)
    REAL(wp), INTENT(IN) :: u_elem(45)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_mat(45, 45)
    REAL(wp), INTENT(OUT) :: Ke_geo(45, 45)
    REAL(wp), INTENT(OUT) :: R_int(45)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 15)
    REAL(wp) :: xi_gp(9), eta_gp(9), zeta_gp(9), wt_gp(9)
    REAL(wp) :: N(15), dN_dxi(3, 15), dN_dX(3, 15)
    REAL(wp) :: J_ref(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), E(6), S(6)
    REAL(wp) :: K_mat_gp(45, 45), K_geo_gp(45, 45), R_gp(45)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 15
      coords_curr(1, i) = coords_ref(1, i) + u_elem(3*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(3*(i-1)+2)
      coords_curr(3, i) = coords_ref(3, i) + u_elem(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D15_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    DO igp = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D15_Jac(dN_dxi, coords_ref, J_ref, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_ref, J_inv, det_J)
      DO i = 1, 15
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dX(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 15
        cfg%coords_ref(i, 1) = coords_ref(1, i)
        cfg%coords_ref(i, 2) = coords_ref(2, i)
        cfg%coords_ref(i, 3) = coords_ref(3, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%coords_curr(i, 3) = coords_curr(3, i)
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
        cfg%lcl%dN_dX(i, 3) = dN_dX(3, i)
      END DO

      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det_val)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(OUT) :: A_inv(3, 3), det_val
      det_val = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
      IF (ABS(det_val) <= 1.0e-20_wp) RETURN
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det_val
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det_val
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det_val
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det_val
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det_val
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det_val
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det_val
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det_val
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det_val
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D15_NL_TL

  SUBROUTINE PH_Elem_C3D15_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 15)
    REAL(wp), INTENT(IN) :: u_incr(45)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_mat(45, 45)
    REAL(wp), INTENT(OUT) :: Ke_geo(45, 45)
    REAL(wp), INTENT(OUT) :: R_int(45)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 15)
    REAL(wp) :: xi_gp(9), eta_gp(9), zeta_gp(9), wt_gp(9)
    REAL(wp) :: N(15), dN_dxi(3, 15), dN_dx(3, 15)
    REAL(wp) :: J_prev(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), e(6), sigma(6)
    REAL(wp) :: K_mat_gp(45, 45), K_geo_gp(45, 45), R_gp(45)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 15
      coords_curr(1, i) = coords_prev(1, i) + u_incr(3*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(3*(i-1)+2)
      coords_curr(3, i) = coords_prev(3, i) + u_incr(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D15_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    DO igp = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D15_Jac(dN_dxi, coords_prev, J_prev, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_prev, J_inv, det_J)
      DO i = 1, 15
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dx(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 15
        cfg%coords_prev(i, 1) = coords_prev(1, i)
        cfg%coords_prev(i, 2) = coords_prev(2, i)
        cfg%coords_prev(i, 3) = coords_prev(3, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%coords_curr(i, 3) = coords_curr(3, i)
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
        cfg%dN_dx(i, 3) = dN_dx(3, i)
      END DO

      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, e, sigma, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det_val)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(OUT) :: A_inv(3, 3), det_val
      det_val = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
      IF (ABS(det_val) <= 1.0e-20_wp) RETURN
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det_val
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det_val
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det_val
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det_val
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det_val
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det_val
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det_val
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det_val
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det_val
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D15_NL_UL

  SUBROUTINE PH_Elem_C3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(15)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 15)
    REAL(wp) :: L1, L2, L3, mz, pz, z2, L1mz, L2mz, L3mz, L1pz, L2pz, L3pz
    L1 = ONE - xi - eta
    L2 = xi
    L3 = eta
    mz = ONE - zeta
    pz = ONE + zeta
    z2 = ONE - zeta * zeta
    L1mz = L1 * mz
    L2mz = L2 * mz
    L3mz = L3 * mz
    L1pz = L1 * pz
    L2pz = L2 * pz
    L3pz = L3 * pz
    N(1) = HALF * L1 * mz * (L1mz - ONE)
    N(2) = HALF * L2 * mz * (L2mz - ONE)
    N(3) = HALF * L3 * mz * (L3mz - ONE)
    N(4) = HALF * L1 * pz * (L1pz - ONE)
    N(5) = HALF * L2 * pz * (L2pz - ONE)
    N(6) = HALF * L3 * pz * (L3pz - ONE)
    N(7)  = 2.0_wp * L1 * L2 * mz
    N(8)  = 2.0_wp * L2 * L3 * mz
    N(9)  = 2.0_wp * L3 * L1 * mz
    N(10) = 2.0_wp * L1 * L2 * pz
    N(11) = 2.0_wp * L2 * L3 * pz
    N(12) = 2.0_wp * L3 * L1 * pz
    N(13) = L1 * z2
    N(14) = L2 * z2
    N(15) = L3 * z2
    dNdxi(1, 1) = -HALF * mz * (2.0_wp * L1mz - ONE)
    dNdxi(2, 1) = -HALF * mz * (2.0_wp * L1mz - ONE)
    dNdxi(3, 1) = HALF * L1 * (ONE - 2.0_wp * L1mz)
    dNdxi(1, 2) =  HALF * mz * (2.0_wp * L2mz - ONE)
    dNdxi(2, 2) = ZERO
    dNdxi(3, 2) = HALF * L2 * (ONE - 2.0_wp * L2mz)
    dNdxi(1, 3) = ZERO
    dNdxi(2, 3) =  HALF * mz * (2.0_wp * L3mz - ONE)
    dNdxi(3, 3) = HALF * L3 * (ONE - 2.0_wp * L3mz)
    dNdxi(1, 4) = -HALF * pz * (2.0_wp * L1pz - ONE)
    dNdxi(2, 4) = -HALF * pz * (2.0_wp * L1pz - ONE)
    dNdxi(3, 4) = HALF * L1 * (2.0_wp * L1pz - ONE)
    dNdxi(1, 5) =  HALF * pz * (2.0_wp * L2pz - ONE)
    dNdxi(2, 5) = ZERO
    dNdxi(3, 5) = HALF * L2 * (2.0_wp * L2pz - ONE)
    dNdxi(1, 6) = ZERO
    dNdxi(2, 6) =  HALF * pz * (2.0_wp * L3pz - ONE)
    dNdxi(3, 6) = HALF * L3 * (2.0_wp * L3pz - ONE)
    dNdxi(1, 7)  = 2.0_wp * mz * (L1 - L2)
    dNdxi(2, 7)  = -2.0_wp * L1 * mz
    dNdxi(3, 7)  = -2.0_wp * L1 * L2
    dNdxi(1, 8)  = 2.0_wp * L3 * mz
    dNdxi(2, 8)  = 2.0_wp * L2 * mz
    dNdxi(3, 8)  = -2.0_wp * L2 * L3
    dNdxi(1, 9)  = -2.0_wp * L3 * mz
    dNdxi(2, 9)  = 2.0_wp * L1 * mz
    dNdxi(3, 9)  = -2.0_wp * L3 * L1
    dNdxi(1, 10) = 2.0_wp * pz * (L1 - L2)
    dNdxi(2, 10) = -2.0_wp * L1 * pz
    dNdxi(3, 10) = 2.0_wp * L1 * L2
    dNdxi(1, 11) = 2.0_wp * L3 * pz
    dNdxi(2, 11) = 2.0_wp * L2 * pz
    dNdxi(3, 11) = 2.0_wp * L2 * L3
    dNdxi(1, 12) = -2.0_wp * L3 * pz
    dNdxi(2, 12) = 2.0_wp * L1 * pz
    dNdxi(3, 12) = 2.0_wp * L3 * L1
    dNdxi(1, 13) = -z2
    dNdxi(2, 13) = -z2
    dNdxi(3, 13) = -2.0_wp * L1 * zeta
    dNdxi(1, 14) = z2
    dNdxi(2, 14) = ZERO
    dNdxi(3, 14) = -2.0_wp * L2 * zeta
    dNdxi(1, 15) = ZERO
    dNdxi(2, 15) = z2
    dNdxi(3, 15) = -2.0_wp * L3 * zeta
  END SUBROUTINE PH_Elem_C3D15_ShapeFunc

  SUBROUTINE PH_Elem_C3D15_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(6, 45)
    REAL(wp), INTENT(IN)  :: u(45)
    REAL(wp), INTENT(OUT) :: strain(6)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_C3D15_Strain

  SUBROUTINE PH_Elem_C3D15_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(6)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    sigma = MATMUL(D, epsilon)
  END SUBROUTINE PH_Elem_C3D15_Stress

  ! ---- Sect ----
  SUBROUTINE PH_Elem_C3D15_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: volume, dV
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 15
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid(1:3) = centroid(1:3) / volume
  END SUBROUTINE PH_Elem_C3D15_GetCentroid

  SUBROUTINE PH_Elem_C3D15_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x = ZERO
      DO k = 1, 15
        x(1) = x(1) + N(k) * coords(1, k)
        x(2) = x(2) + N(k) * coords(2, k)
        x(3) = x(3) + N(k) * coords(3, k)
      END DO
      r2 = x(1)*x(1) + x(2)*x(2) + x(3)*x(3)
      DO i = 1, 3
        DO j = 1, 3
          I_out(i, j) = I_out(i, j) - x(i) * x(j) * dV
        END DO
        I_out(i, i) = I_out(i, i) + r2 * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D15_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_C3D15_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D15_GetSectProps

  SUBROUTINE PH_Elem_C3D15_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D15_GetVolume

  ! ---- Constraints ----
  SUBROUTINE PH_Elem_C3D15_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(45, 45)
    REAL(wp), INTENT(INOUT) :: F_el(45)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 45) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D15_ApplyConstraint

  SUBROUTINE PH_Elem_C3D15_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(45)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(45, 45)
    REAL(wp), INTENT(INOUT) :: F_el(45)
    INTEGER(i4) :: i, j
    DO i = 1, 45
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 45
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_ApplyMPC

  ! ---- Cont ----
  SUBROUTINE PH_Elem_C3D15_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(15)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(45, 45)
    REAL(wp), INTENT(INOUT) :: F_el(45)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib, i, j
    DO a = 1, 15
      ia = 3 * (a - 1) + 1
      f_a(1:3) = penalty * gap * N(a) * n(1:3)
      F_el(ia:ia+2) = F_el(ia:ia+2) + f_a(1:3)
    END DO
    DO a = 1, 15
      DO b = 1, 15
        k_ab = penalty * N(a) * N(b)
        ia = 3 * (a - 1) + 1
        ib = 3 * (b - 1) + 1
        DO i = 1, 3
          DO j = 1, 3
            K_el(ia+i-1, ib+j-1) = K_el(ia+i-1, ib+j-1) + k_ab * n(i) * n(j)
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_FormContactContrib

  SUBROUTINE PH_Elem_C3D15_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(45, 45)
    REAL(wp), INTENT(INOUT) :: F_el(45)
    REAL(wp) :: xi, eta, zeta, N(15), n(3), dNdxi(3, 15)
    REAL(wp) :: r1(3), r2(3)
    INTEGER(i4) :: nodes(4), i, nnode_face
    IF (face_id < 1 .OR. face_id > 5) RETURN
    nodes(1:4) = PH_ELEM_C3D15_FACE_NODES(1:4, face_id)
    nnode_face = 3
    IF (nodes(4) /= 0) nnode_face = 4
    IF (nnode_face == 3) THEN
      xi = 1.0_wp/3.0_wp
      eta = 1.0_wp/3.0_wp
      zeta = MERGE(-ONE, ONE, face_id == 1)
    ELSE
      xi = 0.5_wp
      eta = 0.5_wp
      zeta = 0.0_wp
    END IF
    CALL PH_Elem_C3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r1(1:3) = coords(1:3, nodes(2)) - coords(1:3, nodes(1))
    r2(1:3) = coords(1:3, nodes(nnode_face)) - coords(1:3, nodes(1))
    n(1) = r1(2)*r2(3) - r1(3)*r2(2)
    n(2) = r1(3)*r2(1) - r1(1)*r2(3)
    n(3) = r1(1)*r2(2) - r1(2)*r2(1)
    IF (face_id == 1) n = -n
    IF (SUM(n**2) > 1.0e-20_wp) n = n / SQRT(SUM(n**2))
    CALL PH_Elem_C3D15_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D15_FormContactFaceCtr

  ! ---- Loads ----
  SUBROUTINE PH_Elem_C3D15_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(45)
    REAL(wp) :: n(3), area
    INTEGER(i4) :: nodes(4), i, j, nnode_face
    F_eq = ZERO
    IF (face_id < 1 .OR. face_id > 5) RETURN
    nodes(1:4) = PH_ELEM_C3D15_FACE_NODES(1:4, face_id)
    nnode_face = 3
    IF (nodes(4) /= 0) nnode_face = 4
    IF (nnode_face == 3) THEN
      n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1)))
      n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1)))
      n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1)))
      area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
      IF (area < 1.0e-15_wp) RETURN
      n = n / (2.0_wp * area)
      IF (face_id == 1) n = -n
      DO j = 1, 3
        i = nodes(j)
        F_eq(3*i-2:3*i) = F_eq(3*i-2:3*i) + (p * area / 3.0_wp) * n(1:3)
      END DO
    ELSE
      n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(4))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(4))-coords(2,nodes(1)))
      n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(4))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(4))-coords(3,nodes(1)))
      n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(4))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(4))-coords(1,nodes(1)))
      area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
      IF (area < 1.0e-15_wp) RETURN
      n = n / (2.0_wp * area)
      DO j = 1, 4
        i = nodes(j)
        F_eq(3*i-2:3*i) = F_eq(3*i-2:3*i) + (p * area / 4.0_wp) * n(1:3)
      END DO
    END IF
  END SUBROUTINE PH_Elem_C3D15_FormFacePressure

  SUBROUTINE PH_Elem_C3D15_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(45)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 15
        F_eq(3*i-2) = F_eq(3*i-2) + N(i) * bx * detJ * weights(ip)
        F_eq(3*i-1) = F_eq(3*i-1) + N(i) * by * detJ * weights(ip)
        F_eq(3*i)   = F_eq(3*i)   + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_FormBodyForce

  SUBROUTINE PH_Elem_C3D15_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(45)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D15_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D15_FormFacePressure(coords, val(1), face_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D15_FormNodalForce

  ! ---- Out ----
  SUBROUTINE PH_Elem_C3D15_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: principal(3)
    REAL(wp) :: s(3,3), p, q, r, phi, a
    INTEGER(i4) :: i
    s(1,1)=sigma(1)
    s(2,2)=sigma(2)
    s(3,3)=sigma(3)
    s(1,2)=sigma(4)
    s(2,1)=sigma(4)
    s(2,3)=sigma(5)
    s(3,2)=sigma(5)
    s(1,3)=sigma(6)
    s(3,1)=sigma(6)
    p = (s(1,1)+s(2,2)+s(3,3))/3.0_wp
    q = (s(1,1)*s(2,2)+s(2,2)*s(3,3)+s(3,3)*s(1,1)-s(1,2)**2-s(2,3)**2-s(1,3)**2)/3.0_wp - p**2
    r = (s(1,1)-p)*(s(2,2)-p)*(s(3,3)-p) + 2.0_wp*s(1,2)*s(2,3)*s(1,3) - (s(1,1)-p)*s(2,3)**2 - (s(2,2)-p)*s(1,3)**2 - (s(3,3)-p)*s(1,2)**2
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
    DO i = 1, 2
      IF (principal(1) < principal(2)) THEN
          a = principal(1)
          principal(1) = principal(2)
          principal(2) = a
      END IF
      IF (principal(2) < principal(3)) THEN
          a = principal(2)
          principal(2) = principal(3)
          principal(3) = a
      END IF
    END DO
  END SUBROUTINE PH_Elem_C3D15_EvalPrincStress

  SUBROUTINE PH_Elem_C3D15_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e
    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (SUM(edev(1:3)*edev(1:3)) + 2.0_wp*(edev(4)**2+edev(5)**2+edev(6)**2))
  END SUBROUTINE PH_Elem_C3D15_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D15_EvalStressInvar(sigma, I1, J2, J3)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: I1, J2, J3
    REAL(wp) :: p, sdev(6), s3(3, 3)
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdev(1:3) = sigma(1:3) - p
    sdev(4:6) = sigma(4:6)
    J2 = HALF * (SUM(sdev(1:3)*sdev(1:3)) + 2.0_wp*(sdev(4)**2+sdev(5)**2+sdev(6)**2))
    s3(1,1)=sdev(1)
    s3(1,2)=sdev(4)
    s3(1,3)=sdev(6)
    s3(2,1)=sdev(4)
    s3(2,2)=sdev(2)
    s3(2,3)=sdev(5)
    s3(3,1)=sdev(6)
    s3(3,2)=sdev(5)
    s3(3,3)=sdev(3)
    J3 = s3(1,1)*(s3(2,2)*s3(3,3)-s3(2,3)*s3(3,2)) - s3(1,2)*(s3(2,1)*s3(3,3)-s3(2,3)*s3(3,1)) + s3(1,3)*(s3(2,1)*s3(3,2)-s3(2,2)*s3(3,1))
  END SUBROUTINE PH_Elem_C3D15_EvalStressInvar

  SUBROUTINE PH_Elem_C3D15_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax
    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D15_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    triax = MERGE(p / seq, ZERO, seq > 1.0e-20_wp)
  END SUBROUTINE PH_Elem_C3D15_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D15_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :), ip_strain(:, :), ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 13
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 9)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 6) out_vars(1:6, ip) = ip_stress(1:6, ip)
      IF (SIZE(ip_strain, 1) >= 6) out_vars(7:12, ip) = ip_strain(1:6, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(13, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D15_CollectIPVars

  SUBROUTINE PH_Elem_C3D15_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s1, s2, s3, p, J2
    s1 = sigma(1)
    s2 = sigma(2)
    s3 = sigma(3)
    p = (s1 + s2 + s3) / 3.0_wp
    J2 = HALF * ((s1-p)**2 + (s2-p)**2 + (s3-p)**2) + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D15_EvalVonMises

  SUBROUTINE PH_Elem_C3D15_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(15, 9)
    INTEGER(i4) :: i, j
    E = ZERO
    DO i = 1, 9
      E(i, i) = ONE
    END DO
  END SUBROUTINE PH_Elem_C3D15_GetExtrapMat

  SUBROUTINE PH_Elem_C3D15_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :), weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    INTEGER(i4) :: ic, i, n_comp
    node_vars = ZERO
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 15
        IF (SIZE(ip_vars, 1) >= 1) node_vars(i, ic) = ip_vars(1, ic)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15_MapToNode

  SUBROUTINE PH_Elem_C3D15_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                  stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_Elastic3D

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dStrain, &
                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_C3D15_Material_Update_Routed

END MODULE PH_Elem_C3D15

