!===============================================================================
! MODULE: PH_Elem_CPE3
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CPE3 element definition (3-node plane strain triangle)
!===============================================================================
MODULE PH_Elem_CPE3
!> [CORE] CPE3 plane strain triangle (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE

  ! Constants
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_NNODE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_NIP   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_NDOF  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_NEDGE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_EDGE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  ! For 2D: face = edge
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE3_FACE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp  ! 1/sqrt(3)

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: PH_Elem_CPE3_DefInit
  PUBLIC :: PH_Elem_CPE3_ShapeFunc
  PUBLIC :: PH_Elem_CPE3_Jac
  PUBLIC :: PH_Elem_CPE3_BMatrix
  PUBLIC :: PH_Elem_CPE3_GaussPoints
  PUBLIC :: PH_Elem_CPE3_JacB
  PUBLIC :: PH_Elem_CPE3_Strain
  PUBLIC :: PH_Elem_CPE3_Stress
  PUBLIC :: PH_Elem_CPE3_ConstMatrix
  PUBLIC :: PH_Elem_CPE3_FormStiffMatrix
  PUBLIC :: PH_Elem_CPE3_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_CPE3_FormIntForce
  PUBLIC :: PH_Elem_CPE3_FormIntForceFromStress
  PUBLIC :: PH_Elem_CPE3_ConsMass
  PUBLIC :: PH_Elem_CPE3_LumpMass
  PUBLIC :: PH_Elem_CPE3_ThermStrainVector
  PUBLIC :: PH_Elem_CPE3_NL_TL
  PUBLIC :: PH_Elem_CPE3_NL_UL
  PUBLIC :: PH_Elem_CPE3_GetArea
  PUBLIC :: PH_Elem_CPE3_GetCentroid
  PUBLIC :: PH_Elem_CPE3_GetSectProps
  PUBLIC :: PH_Elem_CPE3_ApplyConstraint
  PUBLIC :: PH_Elem_CPE3_ApplyMPC
  PUBLIC :: PH_Elem_CPE3_FormContactContrib
  PUBLIC :: PH_Elem_CPE3_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CPE3_FormNodalForce
  PUBLIC :: PH_Elem_CPE3_FormBodyForce
  PUBLIC :: PH_Elem_CPE3_FormEdgePressure
  PUBLIC :: PH_Elem_CPE3_CollectIPVars
  PUBLIC :: PH_Elem_CPE3_MapToNode
  PUBLIC :: PH_Elem_CPE3_GetExtrapMat
  PUBLIC :: PH_Elem_CPE3_EvalVonMises
  PUBLIC :: PH_Elem_CPE3_EvalPrincStress
  PUBLIC :: PH_Elem_CPE3_EvalStressInvar
  PUBLIC :: PH_Elem_CPE3_Material_Update_Routed
  PUBLIC :: PH_ELEM_CPE3_NNODE, PH_ELEM_CPE3_NIP, PH_ELEM_CPE3_NDOF, PH_ELEM_CPE3_NEDGE
  PUBLIC :: PH_ELEM_CPE3_EDGE_NODES, PH_ELEM_CPE3_FACE_NODES, PH_ELEM_GAUSS_PT

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
  ! DEFINITION (core element routines)
  !=============================================================================
  SUBROUTINE PH_ELEM_CPE3_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CPE3_AreaInt

  SUBROUTINE PH_Elem_CPE3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(3)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = ZERO
  END SUBROUTINE PH_Elem_CPE3_ThermStrainVector

  SUBROUTINE PH_Elem_CPE3_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(2, 3)
    REAL(wp), INTENT(OUT) :: B(3, 6)
    INTEGER(i4) :: i
    B = ZERO
    DO i = 1, 3
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = dNdx(2, i)
      B(3, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CPE3_BMatrix

  SUBROUTINE PH_Elem_CPE3_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 3
        DO j = 1, 3
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * N(i)*N(j) * detJ * weights(ip)
          Me(2*i,   2*j)   = Me(2*i,   2*j)   + rho * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE3_ConsMass

  SUBROUTINE PH_Elem_CPE3_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: D(3, 3)
    REAL(wp) :: c
    D = ZERO
    c = E_young / ((ONE + nu) * (ONE - 2.0_wp*nu))
    D(1, 1) = c * (ONE - nu)
    D(1, 2) = c * nu
    D(2, 1) = c * nu
    D(2, 2) = c * (ONE - nu)
    D(3, 3) = c * (ONE - 2.0_wp*nu) * HALF
  END SUBROUTINE PH_Elem_CPE3_ConstMatrix

  SUBROUTINE PH_Elem_CPE3_DefInit()
  END SUBROUTINE PH_Elem_CPE3_DefInit

  SUBROUTINE PH_Elem_CPE3_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(3, 6), D(3, 3), strain(3), sigma(3), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPE3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_Elem_CPE3_Strain(B, u, strain)
      CALL PH_Elem_CPE3_Stress(strain, D, sigma)
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormIntForce

  SUBROUTINE PH_Elem_CPE3_FormIntForceFromStress(coords, sigma3, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: sigma3(3)
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(3, 6), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma3) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormIntForceFromStress

  SUBROUTINE PH_Elem_CPE3_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(3, 6), D(3, 3), detJ
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CPE3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + MATMUL(MATMUL(TRANSPOSE(B), D), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormStiffMatrix

  SUBROUTINE PH_Elem_CPE3_FormStiffMatrixFromD(coords, D_matrix, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: D_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(3, 6), detJ
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + MATMUL(MATMUL(TRANSPOSE(B), D_matrix), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(3), eta(3), weights(3)
    REAL(wp), PARAMETER :: w6 = 1.0_wp / 6.0_wp
    xi(1) = HALF
    eta(1) = ZERO
    weights(1) = w6
    xi(2) = HALF
    eta(2) = HALF
    weights(2) = w6
    xi(3) = ZERO
    eta(3) = HALF
    weights(3) = w6
  END SUBROUTINE PH_Elem_CPE3_GaussPoints

  SUBROUTINE PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 3)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i
    J = ZERO
    DO i = 1, 3
      J(1, 1) = J(1, 1) + dNdxi(1, i) * coords(1, i)
      J(1, 2) = J(1, 2) + dNdxi(1, i) * coords(2, i)
      J(2, 1) = J(2, 1) + dNdxi(2, i) * coords(1, i)
      J(2, 2) = J(2, 2) + dNdxi(2, i) * coords(2, i)
    END DO
    detJ = J(1, 1) * J(2, 2) - J(1, 2) * J(2, 1)
  END SUBROUTINE PH_Elem_CPE3_Jac

  SUBROUTINE PH_Elem_CPE3_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(3)
    REAL(wp), INTENT(OUT) :: dNdx(2, 3)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(3, 6)
    REAL(wp) :: dNdxi(2, 3), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL PH_Elem_CPE3_ShapeFunc(xi_pt, eta_pt, N, dNdxi)
    CALL PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) > 1.0e-20_wp) THEN
      Jinv(1, 1) =  J(2, 2) / detJ
      Jinv(1, 2) = -J(1, 2) / detJ
      Jinv(2, 1) = -J(2, 1) / detJ
      Jinv(2, 2) =  J(1, 1) / detJ
      DO i = 1, 3
        dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
    ELSE
      dNdx = ZERO
    END IF
    CALL PH_Elem_CPE3_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_CPE3_JacB

  SUBROUTINE PH_Elem_CPE3_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CPE3_AreaInt(coords, area)
    m = rho * area / 3.0_wp
    DO i = 1, 3
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CPE3_LumpMass

  SUBROUTINE PH_Elem_CPE3_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(3)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 3)
    N(1) = ONE - xi - eta
    N(2) = xi
    N(3) = eta
    dNdxi(1, 1) = -ONE
    dNdxi(2, 1) = -ONE
    dNdxi(1, 2) =  ONE
    dNdxi(2, 2) = ZERO
    dNdxi(1, 3) = ZERO
    dNdxi(2, 3) =  ONE
  END SUBROUTINE PH_Elem_CPE3_ShapeFunc

  SUBROUTINE PH_Elem_CPE3_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(3, 6)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(OUT) :: strain(3)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_CPE3_Strain

  SUBROUTINE PH_Elem_CPE3_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(3)
    REAL(wp), INTENT(IN)  :: D(3, 3)
    REAL(wp), INTENT(OUT) :: sigma(3)
    sigma(1) = D(1,1)*epsilon(1) + D(1,2)*epsilon(2) + D(1,3)*epsilon(3)
    sigma(2) = D(2,1)*epsilon(1) + D(2,2)*epsilon(2) + D(2,3)*epsilon(3)
    sigma(3) = D(3,1)*epsilon(1) + D(3,2)*epsilon(2) + D(3,3)*epsilon(3)
  END SUBROUTINE PH_Elem_CPE3_Stress

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE3_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_CPE3_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_CPE3_GetArea

  SUBROUTINE PH_Elem_CPE3_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 2
        DO j = 1, 3
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
    END IF
  END SUBROUTINE PH_Elem_CPE3_GetCentroid

  SUBROUTINE PH_Elem_CPE3_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CPE3_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_CPE3_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 6) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_CPE3_ApplyConstraint

  SUBROUTINE PH_Elem_CPE3_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(6)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    INTEGER(i4) :: i, j
    DO i = 1, 6
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 6
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE3_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(3)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 3
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 3
      DO b = 1, 3
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormContactContrib

  SUBROUTINE PH_Elem_CPE3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(6, 6)
    REAL(wp), INTENT(OUT) :: F_el(6)
    REAL(wp) :: xi, eta, N(3), n(2), dNdxi(2, 3)
    REAL(wp) :: t(2), len
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CPE3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPE3_EDGE_NODES(2, edge_id)
    SELECT CASE (edge_id)
    CASE (1)
      xi = HALF
      eta = ZERO
    CASE (2)
      xi = HALF
      eta = HALF
    CASE (3)
      xi = ZERO
      eta = HALF
    END SELECT
    CALL PH_Elem_CPE3_ShapeFunc(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CPE3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_CPE3_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE3_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: t(2), len, nx, ny
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CPE3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPE3_EDGE_NODES(2, edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    nx = -t(2) / len
    ny =  t(1) / len
    F_eq(2*n1-1) = F_eq(2*n1-1) + p * len * HALF * nx
    F_eq(2*n1)   = F_eq(2*n1)   + p * len * HALF * ny
    F_eq(2*n2-1) = F_eq(2*n2-1) + p * len * HALF * nx
    F_eq(2*n2)   = F_eq(2*n2)   + p * len * HALF * ny
  END SUBROUTINE PH_Elem_CPE3_FormEdgePressure

  SUBROUTINE PH_Elem_CPE3_FormBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 3
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * bx * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * by * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE3_FormBodyForce

  SUBROUTINE PH_Elem_CPE3_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CPE3_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPE3_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CPE3_FormNodalForce

  !=============================================================================
  ! OUTPUT (inlined)
  !=============================================================================
  SUBROUTINE invert_3x3(A, info)
    REAL(wp), INTENT(INOUT) :: A(3, 3)
    INTEGER(i4), INTENT(OUT) :: info
    REAL(wp) :: B(3, 3)
    INTEGER(i4) :: i, k
    REAL(wp) :: fac
    B = A
    A = ZERO
    DO i = 1, 3
      A(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 3
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, :) = B(k, :) * fac
      A(k, :) = A(k, :) * fac
      DO i = 1, 3
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, :) = B(i, :) - fac * B(k, :)
        A(i, :) = A(i, :) - fac * A(k, :)
      END DO
    END DO
  END SUBROUTINE invert_3x3

  SUBROUTINE PH_Elem_CPE3_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 7
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 3)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 3) THEN
        out_vars(1:3, ip) = ip_stress(1:3, ip)
      END IF
      IF (SIZE(ip_strain, 1) >= 3) THEN
        out_vars(4:6, ip) = ip_strain(1:3, ip)
      END IF
      IF (SIZE(ip_peeq) >= ip) THEN
        out_vars(7, ip) = ip_peeq(ip)
      END IF
    END DO
  END SUBROUTINE PH_Elem_CPE3_CollectIPVars

  SUBROUTINE PH_Elem_CPE3_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: principal(2)
    REAL(wp) :: s11, s22, s12, p, q
    s11 = sigma(1)
    s22 = sigma(2)
    s12 = sigma(3)
    p = (s11 + s22) * HALF
    q = SQRT(((s11 - s22)*HALF)**2 + s12*s12)
    principal(1) = p + q
    principal(2) = p - q
  END SUBROUTINE PH_Elem_CPE3_EvalPrincStress

  SUBROUTINE PH_Elem_CPE3_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdev11, sdev22
    I1 = sigma(1) + sigma(2)
    p = I1 / 2.0_wp
    sdev11 = sigma(1) - p
    sdev22 = sigma(2) - p
    J2 = HALF * (sdev11*sdev11 + sdev22*sdev22) + sigma(3)*sigma(3)
  END SUBROUTINE PH_Elem_CPE3_EvalStressInvar

  SUBROUTINE PH_Elem_CPE3_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s11, s22, s12
    s11 = sigma(1)
    s22 = sigma(2)
    s12 = sigma(3)
    seq = SQRT(s11*s11 + s22*s22 - s11*s22 + 3.0_wp*s12*s12)
  END SUBROUTINE PH_Elem_CPE3_EvalVonMises

  SUBROUTINE PH_Elem_CPE3_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3)
    REAL(wp) :: A(3, 3)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 3
        A(i, ip) = N(i)
      END DO
    END DO
    E = TRANSPOSE(A)
    CALL invert_3x3(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_CPE3_GetExtrapMat

  SUBROUTINE PH_Elem_CPE3_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(3, 3)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CPE3_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 3
        DO j = 1, 3
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE3_MapToNode

  !=============================================================================
  ! NL_TL / NL_UL
  !=============================================================================
  SUBROUTINE PH_Elem_CPE3_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 3)
    REAL(wp), INTENT(IN) :: u_elem(6)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 3)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), dN_dX(2, 3)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(2, 2), E(3), S(3)
    REAL(wp) :: K_mat_gp(6, 6), K_geo_gp(6, 6), R_gp(6)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 3
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*(i-1)+2)
    END DO

    CALL PH_Elem_CPE3_GaussPoints(xi_gp, eta_gp, wt_gp)



    DO igp = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPE3_Jac(dN_dxi, coords_ref, J_ref, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      J_inv(1,1) =  J_ref(2,2) / det_J
      J_inv(1,2) = -J_ref(1,2) / det_J
      J_inv(2,1) = -J_ref(2,1) / det_J
      J_inv(2,2) =  J_ref(1,1) / det_J
      DO i = 1, 3
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO

      DO i = 1, 3
        cfg%coords_ref(i, 1) = coords_ref(1, i)
        cfg%coords_ref(i, 2) = coords_ref(2, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
      END DO

      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CPE3_NL_TL

  SUBROUTINE PH_Elem_CPE3_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 3)
    REAL(wp), INTENT(IN) :: u_incr(6)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 3)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), dN_dx(2, 3)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(2, 2), e(3), sigma(3)
    REAL(wp) :: K_mat_gp(6, 6), K_geo_gp(6, 6), R_gp(6)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 3
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*(i-1)+2)
    END DO

    CALL PH_Elem_CPE3_GaussPoints(xi_gp, eta_gp, wt_gp)



    DO igp = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPE3_Jac(dN_dxi, coords_prev, J_prev, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      J_inv(1,1) =  J_prev(2,2) / det_J
      J_inv(1,2) = -J_prev(1,2) / det_J
      J_inv(2,1) = -J_prev(2,1) / det_J
      J_inv(2,2) =  J_prev(1,1) / det_J
      DO i = 1, 3
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO

      DO i = 1, 3
        cfg%coords_prev(i, 1) = coords_prev(1, i)
        cfg%coords_prev(i, 2) = coords_prev(2, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
      END DO

      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, e, sigma, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CPE3_NL_UL

  SUBROUTINE PH_Elem_CPE3_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                 stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticPlaneStrain

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStrain(rt_ctx, mat_slot, dStrain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_CPE3_Material_Update_Routed

END MODULE PH_Elem_CPE3

