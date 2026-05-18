!===============================================================================
! MODULE: PH_Elem_CAX3
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CAX3 element definition (3-node axisymmetric triangle)
!===============================================================================
MODULE PH_Elem_CAX3
!> [CORE] CAX3 axisymmetric triangle (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE

  ! Constants
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_NNODE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_NIP   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_NDOF  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_NEDGE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_EDGE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3_FACE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  REAL(wp), PARAMETER :: TWOPI = 6.283185307179586_wp
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: PH_Elem_CAX3_DefInit
  PUBLIC :: PH_Elem_CAX3_ShapeFunc
  PUBLIC :: PH_Elem_CAX3_Jac
  PUBLIC :: PH_Elem_CAX3_BMatrix
  PUBLIC :: PH_Elem_CAX3_GaussPoints
  PUBLIC :: PH_Elem_CAX3_JacB
  PUBLIC :: PH_Elem_CAX3_Strain
  PUBLIC :: PH_Elem_CAX3_Stress
  PUBLIC :: PH_Elem_CAX3_ConstMatrix
  PUBLIC :: PH_Elem_CAX3_FormStiffMatrix
  PUBLIC :: PH_Elem_CAX3_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_CAX3_FormIntForce
  PUBLIC :: PH_Elem_CAX3_FormIntForceFromStress
  PUBLIC :: PH_Elem_CAX3_ConsMass
  PUBLIC :: PH_Elem_CAX3_LumpMass
  PUBLIC :: PH_Elem_CAX3_ThermStrainVector
  PUBLIC :: PH_Elem_CAX3_NL_TL
  PUBLIC :: PH_Elem_CAX3_NL_UL
  PUBLIC :: PH_Elem_CAX3_GetArea
  PUBLIC :: PH_Elem_CAX3_GetVolume
  PUBLIC :: PH_Elem_CAX3_GetCentroid
  PUBLIC :: PH_Elem_CAX3_GetSectProps
  PUBLIC :: PH_Elem_CAX3_ApplyConstraint
  PUBLIC :: PH_Elem_CAX3_ApplyMPC
  PUBLIC :: PH_Elem_CAX3_FormContactContrib
  PUBLIC :: PH_Elem_CAX3_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CAX3_FormNodalForce
  PUBLIC :: PH_Elem_CAX3_FormBodyForce
  PUBLIC :: PH_Elem_CAX3_FormEdgePressure
  PUBLIC :: PH_Elem_CAX3_CollectIPVars
  PUBLIC :: PH_Elem_CAX3_MapToNode
  PUBLIC :: PH_Elem_CAX3_GetExtrapMat
  PUBLIC :: PH_Elem_CAX3_EvalVonMises
  PUBLIC :: PH_Elem_CAX3_EvalPrincStress
  PUBLIC :: PH_Elem_CAX3_EvalStressInvar
  PUBLIC :: PH_Elem_CAX3_Material_Update_Routed
  PUBLIC :: PH_ELEM_CAX3_NNODE, PH_ELEM_CAX3_NIP, PH_ELEM_CAX3_NDOF, PH_ELEM_CAX3_NEDGE
  PUBLIC :: PH_ELEM_CAX3_EDGE_NODES, PH_ELEM_CAX3_FACE_NODES, PH_ELEM_GAUSS_PT

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
  SUBROUTINE PH_ELEM_CAX3_VolInt(coords, area_r)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: area_r
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip
    area_r = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3)
      area_r = area_r + r_pt * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CAX3_VolInt

  SUBROUTINE PH_Elem_CAX3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(4)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = e
    eps_th(4) = ZERO
  END SUBROUTINE PH_Elem_CAX3_ThermStrainVector

  SUBROUTINE PH_Elem_CAX3_BMatrix(dNdx, N, r_pt, B)
    REAL(wp), INTENT(IN)  :: dNdx(2, 3)
    REAL(wp), INTENT(IN)  :: N(3)
    REAL(wp), INTENT(IN)  :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 6)
    INTEGER(i4) :: i
    REAL(wp) :: rinv
    B = ZERO
    rinv = ZERO
    IF (r_pt > 1.0e-20_wp) rinv = ONE / r_pt
    DO i = 1, 3
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = N(i) * rinv
      B(4, 2*i-1) = dNdx(2, i)
      B(4, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CAX3_BMatrix

  SUBROUTINE PH_Elem_CAX3_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 3
        DO j = 1, 3
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * TWOPI * r_pt * N(i)*N(j) * detJ * weights(ip)
          Me(2*i,   2*j)   = Me(2*i,   2*j)   + rho * TWOPI * r_pt * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3_ConsMass

  SUBROUTINE PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
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
  END SUBROUTINE PH_Elem_CAX3_ConstMatrix

  SUBROUTINE PH_Elem_CAX3_DefInit()
  END SUBROUTINE PH_Elem_CAX3_DefInit

  SUBROUTINE PH_Elem_CAX3_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(4, 6), D(4, 4), strain(4), sigma(4), detJ, r_pt
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      CALL PH_Elem_CAX3_Strain(B, u, strain)
      CALL PH_Elem_CAX3_Stress(strain, D, sigma)
      R_int = R_int + TWOPI * r_pt * MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormIntForce

  SUBROUTINE PH_Elem_CAX3_FormIntForceFromStress(coords, sigma4, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: sigma4(4)
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(4, 6), detJ, r_pt
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      R_int = R_int + TWOPI * r_pt * MATMUL(TRANSPOSE(B), sigma4) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormIntForceFromStress

  SUBROUTINE PH_Elem_CAX3_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(4, 6), D(4, 4), detJ, r_pt
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      Ke = Ke + TWOPI * r_pt * MATMUL(MATMUL(TRANSPOSE(B), D), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormStiffMatrix

  SUBROUTINE PH_Elem_CAX3_FormStiffMatrixFromD(coords, D_matrix, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: D_matrix(4, 4)
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), B(4, 6), detJ, r_pt
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      Ke = Ke + TWOPI * r_pt * MATMUL(MATMUL(TRANSPOSE(B), D_matrix), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_CAX3_GaussPoints(xi, eta, weights)
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
  END SUBROUTINE PH_Elem_CAX3_GaussPoints

  SUBROUTINE PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
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
  END SUBROUTINE PH_Elem_CAX3_Jac

  SUBROUTINE PH_Elem_CAX3_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(3)
    REAL(wp), INTENT(OUT) :: dNdx(2, 3)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: r_pt
    REAL(wp), INTENT(OUT) :: B(4, 6)
    REAL(wp) :: dNdxi(2, 3), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL PH_Elem_CAX3_ShapeFunc(xi_pt, eta_pt, N, dNdxi)
    CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
    r_pt = ZERO
    DO i = 1, 3
      r_pt = r_pt + N(i) * coords(1, i)
    END DO
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
    CALL PH_Elem_CAX3_BMatrix(dNdx, N, r_pt, B)
  END SUBROUTINE PH_Elem_CAX3_JacB

  SUBROUTINE PH_Elem_CAX3_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp) :: area_r, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CAX3_VolInt(coords, area_r)
    m = rho * TWOPI * area_r / 3.0_wp
    DO i = 1, 3
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CAX3_LumpMass

  SUBROUTINE PH_Elem_CAX3_ShapeFunc(xi, eta, N, dNdxi)
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
  END SUBROUTINE PH_Elem_CAX3_ShapeFunc

  SUBROUTINE PH_Elem_CAX3_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(4, 6)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(OUT) :: strain(4)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_CAX3_Strain

  SUBROUTINE PH_Elem_CAX3_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(4)
    REAL(wp), INTENT(IN)  :: D(4, 4)
    REAL(wp), INTENT(OUT) :: sigma(4)
    sigma(1) = D(1,1)*epsilon(1) + D(1,2)*epsilon(2) + D(1,3)*epsilon(3) + D(1,4)*epsilon(4)
    sigma(2) = D(2,1)*epsilon(1) + D(2,2)*epsilon(2) + D(2,3)*epsilon(3) + D(2,4)*epsilon(4)
    sigma(3) = D(3,1)*epsilon(1) + D(3,2)*epsilon(2) + D(3,3)*epsilon(3) + D(3,4)*epsilon(4)
    sigma(4) = D(4,1)*epsilon(1) + D(4,2)*epsilon(2) + D(4,3)*epsilon(3) + D(4,4)*epsilon(4)
  END SUBROUTINE PH_Elem_CAX3_Stress

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX3_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_GetArea

  SUBROUTINE PH_Elem_CAX3_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: area_r
    CALL PH_ELEM_CAX3_VolInt(coords, area_r)
    volume = TWOPI * area_r
  END SUBROUTINE PH_Elem_CAX3_GetVolume

  SUBROUTINE PH_Elem_CAX3_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: volume, dV
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3)
      dV = TWOPI * r_pt * detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 2
        DO j = 1, 3
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
    END IF
  END SUBROUTINE PH_Elem_CAX3_GetCentroid

  SUBROUTINE PH_Elem_CAX3_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CAX3_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_CAX3_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CAX3_ApplyConstraint

  SUBROUTINE PH_Elem_CAX3_ApplyMPC(c, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CAX3_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined) - axisymmetric: r_edge factor for 2*pi*r
  !=============================================================================
  SUBROUTINE PH_Elem_CAX3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, r_edge, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(3)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(IN)  :: r_edge
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 3
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * r_edge * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * r_edge * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 3
      DO b = 1, 3
        k_ab = penalty * N(a) * N(b) * edge_len * r_edge
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormContactContrib

  SUBROUTINE PH_Elem_CAX3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(6, 6)
    REAL(wp), INTENT(OUT) :: F_el(6)
    REAL(wp) :: xi, eta, N(3), n(2), dNdxi(2, 3)
    REAL(wp) :: t(2), len, rmid
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CAX3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX3_EDGE_NODES(2, edge_id)
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
    CALL PH_Elem_CAX3_ShapeFunc(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    rmid = (coords(1, n1) + coords(1, n2)) * HALF
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CAX3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, rmid, K_el, F_el)
  END SUBROUTINE PH_Elem_CAX3_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined) - axisymmetric: rmid factor for 2*pi*r
  !=============================================================================
  SUBROUTINE PH_Elem_CAX3_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: t(2), len, nr, nz, rmid
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CAX3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX3_EDGE_NODES(2, edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    nr = -t(2) / len
    nz =  t(1) / len
    rmid = (coords(1, n1) + coords(1, n2)) * HALF
    F_eq(2*n1-1) = F_eq(2*n1-1) + p * rmid * len * HALF * nr
    F_eq(2*n1)   = F_eq(2*n1)   + p * rmid * len * HALF * nz
    F_eq(2*n2-1) = F_eq(2*n2-1) + p * rmid * len * HALF * nr
    F_eq(2*n2)   = F_eq(2*n2)   + p * rmid * len * HALF * nz
  END SUBROUTINE PH_Elem_CAX3_FormEdgePressure

  SUBROUTINE PH_Elem_CAX3_FormBodyForce(coords, br, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: br, bz
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 3
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * br * TWOPI * r_pt * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * bz * TWOPI * r_pt * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3_FormBodyForce

  SUBROUTINE PH_Elem_CAX3_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CAX3_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX3_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CAX3_FormNodalForce

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

  SUBROUTINE PH_Elem_CAX3_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 9
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 3)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 4) out_vars(1:4, ip) = ip_stress(1:4, ip)
      IF (SIZE(ip_strain, 1) >= 4) out_vars(5:8, ip) = ip_strain(1:4, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(9, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_CAX3_CollectIPVars

  SUBROUTINE PH_Elem_CAX3_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_CAX3_EvalPrincStress

  SUBROUTINE PH_Elem_CAX3_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdevr, sdevz, sdevt
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdevr = sigma(1) - p
    sdevz = sigma(2) - p
    sdevt = sigma(3) - p
    J2 = HALF * (sdevr*sdevr + sdevz*sdevz + sdevt*sdevt) + sigma(4)*sigma(4)
  END SUBROUTINE PH_Elem_CAX3_EvalStressInvar

  SUBROUTINE PH_Elem_CAX3_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(4)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: sr, sz, st, srz
    sr = sigma(1)
    sz = sigma(2)
    st = sigma(3)
    srz = sigma(4)
    seq = SQRT(HALF*((sr-sz)**2 + (sz-st)**2 + (st-sr)**2) + 3.0_wp*srz*srz)
  END SUBROUTINE PH_Elem_CAX3_EvalVonMises

  SUBROUTINE PH_Elem_CAX3_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3)
    REAL(wp) :: A(3, 3)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 3
        A(i, ip) = N(i)
      END DO
    END DO
    E = TRANSPOSE(A)
    CALL invert_3x3(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_CAX3_GetExtrapMat

  SUBROUTINE PH_Elem_CAX3_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(3, 3)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CAX3_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 3
        DO j = 1, 3
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3_MapToNode

  !=============================================================================
  ! NL_TL / NL_UL - Legacy (for RT_AsmNLGeomDispatch)
  ! PH_Elem_CAX3_NL_TL(coords_ref(1:2,1:3), u_elem(1:6), D(1:4,1:4), Ke_mat, Ke_geo, R_int, status)
  !=============================================================================
  SUBROUTINE PH_Elem_CAX3_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 3)
    REAL(wp), INTENT(IN) :: u_elem(6)
    REAL(wp), INTENT(IN) :: D(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 3)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), dN_dX(2, 3)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: r_gp
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

    CALL PH_Elem_CAX3_GaussPoints(xi_gp, eta_gp, wt_gp)



    DO igp = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CAX3_Jac(dN_dxi, coords_ref, J_ref, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      r_gp = ZERO
      DO i = 1, 3
        r_gp = r_gp + N(i) * coords_ref(1, i)
      END DO
      IF (r_gp <= 1.0e-12_wp) CYCLE

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

      Ke_mat = Ke_mat + K_mat_gp * det_J * r_gp * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * r_gp * wt_gp(igp)
      R_int = R_int + R_gp * det_J * r_gp * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CAX3_NL_TL

  SUBROUTINE PH_Elem_CAX3_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 3)
    REAL(wp), INTENT(IN) :: u_incr(6)
    REAL(wp), INTENT(IN) :: D(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 3)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), dN_dx(2, 3)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: r_gp
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

    CALL PH_Elem_CAX3_GaussPoints(xi_gp, eta_gp, wt_gp)



    DO igp = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CAX3_Jac(dN_dxi, coords_prev, J_prev, det_J)

      IF (det_J <= 1.0e-12_wp) CYCLE

      r_gp = ZERO
      DO i = 1, 3
        r_gp = r_gp + N(i) * coords_prev(1, i)
      END DO
      IF (r_gp <= 1.0e-12_wp) CYCLE

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

      Ke_mat = Ke_mat + K_mat_gp * det_J * r_gp * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * r_gp * wt_gp(igp)
      R_int = R_int + R_gp * det_J * r_gp * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CAX3_NL_UL

  SUBROUTINE PH_Elem_CAX3_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_CAX3_Material_Update_Routed

END MODULE PH_Elem_CAX3

