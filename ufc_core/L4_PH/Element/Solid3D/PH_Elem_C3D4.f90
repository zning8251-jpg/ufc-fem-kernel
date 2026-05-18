!===============================================================================
! MODULE: PH_Elem_C3D4
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D4 element definition (4-node tetrahedron)
!===============================================================================
MODULE PH_Elem_C3D4
!> Status: Production | Last verified: 2026-03-01
!> Theory: Element definition and shape functions | Ref: Hughes(2000) FEM Ch.3
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_C3D4_DefInit
  PUBLIC :: PH_Elem_C3D4_ShapeFunc
  PUBLIC :: PH_Elem_C3D4_Jac
  PUBLIC :: PH_Elem_C3D4_BMatrix
  PUBLIC :: PH_Elem_C3D4_GaussPoints
  PUBLIC :: PH_Elem_C3D4_JacB
  PUBLIC :: PH_Elem_C3D4_Strain
  PUBLIC :: PH_Elem_C3D4_Stress
  PUBLIC :: PH_Elem_C3D4_ConstMatrix
  PUBLIC :: PH_Elem_C3D4_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D4_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_C3D4_FormIntForce
  PUBLIC :: PH_Elem_C3D4_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D4_ConsMass
  PUBLIC :: PH_Elem_C3D4_LumpMass
  PUBLIC :: PH_Elem_C3D4_ThermStrainVector
  PUBLIC :: PH_ELEM_C3D4_NNODE
  PUBLIC :: PH_ELEM_C3D4_NIP
  PUBLIC :: PH_ELEM_C3D4_NDOF
  PUBLIC :: PH_ELEM_C3D4_NFACE
  PUBLIC :: PH_ELEM_C3D4_FACE_NODES
  PUBLIC :: PH_Elem_C3D4_NL_TL
  PUBLIC :: PH_Elem_C3D4_NL_UL
  PUBLIC :: PH_Elem_C3D4_GetVolume, PH_Elem_C3D4_GetSectProps, PH_Elem_C3D4_GetCentroid
  PUBLIC :: PH_Elem_C3D4_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D4_ApplyConstraint, PH_Elem_C3D4_ApplyMPC
  PUBLIC :: PH_Elem_C3D4_FormContactContrib, PH_Elem_C3D4_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D4_FormNodalForce, PH_Elem_C3D4_FormBodyForce, PH_Elem_C3D4_FormFacePressure
  PUBLIC :: PH_Elem_C3D4_CollectIPVars, PH_Elem_C3D4_MapToNode, PH_Elem_C3D4_GetExtrapMat
  PUBLIC :: PH_Elem_C3D4_EvalVonMises, PH_Elem_C3D4_EvalPrincStress
  PUBLIC :: PH_Elem_C3D4_EvalStressInvar, PH_Elem_C3D4_EvalStrainInvar, PH_Elem_C3D4_EvalTriaxiality
  PUBLIC :: PH_Elem_C3D4_Material_Update_Routed
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4_NNODE  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4_NIP   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4_NDOF  = 12_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4_NFACE = 4_i4
  ! Face topology: face k has 3 nodes (triangle). Order for outward normal.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D4_FACE_NODES(3, 4) = RESHAPE([ &
    2,3,4, 1,3,4, 1,2,4, 1,2,3 ], [3, 4])
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4, PH_ELEM_CTYPE_MPC_LINEAR = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4, PH_ELEM_LOAD_FACE_P = 2_i4

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

  SUBROUTINE PH_Elem_C3D4_Defn_Init()
  END SUBROUTINE PH_Elem_C3D4_Defn_Init

  ! Volume coordinates: N1=1-xi-eta-zeta, N2=xi, N3=eta, N4=zeta
  SUBROUTINE PH_Elem_C3D4_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 4)
    N(1) = ONE - xi - eta - zeta
    N(2) = xi
    N(3) = eta
    N(4) = zeta
    dNdxi(1, 1) = -ONE
    dNdxi(2, 1) = -ONE
    dNdxi(3, 1) = -ONE
    dNdxi(1, 2) = ONE
    dNdxi(2, 2) = ZERO
    dNdxi(3, 2) = ZERO
    dNdxi(1, 3) = ZERO
    dNdxi(2, 3) = ONE
    dNdxi(3, 3) = ZERO
    dNdxi(1, 4) = ZERO
    dNdxi(2, 4) = ZERO
    dNdxi(3, 4) = ONE
  END SUBROUTINE PH_Elem_C3D4_ShapeFunc

  SUBROUTINE PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 4)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i, j
    J = ZERO
    DO j = 1, 3
      DO i = 1, 4
        J(1, j) = J(1, j) + coords(1, i) * dNdxi(j, i)
        J(2, j) = J(2, j) + coords(2, i) * dNdxi(j, i)
        J(3, j) = J(3, j) + coords(3, i) * dNdxi(j, i)
      END DO
    END DO
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
  END SUBROUTINE PH_Elem_C3D4_Jac

  SUBROUTINE PH_Elem_C3D4_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 4)
    REAL(wp), INTENT(OUT) :: B(6, 12)
    INTEGER(i4) :: i
    B = ZERO
    DO i = 1, 4
      B(1, 3*i-2) = dNdx(1, i)
      B(2, 3*i-1) = dNdx(2, i)
      B(3, 3*i)   = dNdx(3, i)
      B(4, 3*i-2) = dNdx(2, i)
      B(4, 3*i-1) = dNdx(1, i)
      B(5, 3*i-1) = dNdx(3, i)
      B(5, 3*i)   = dNdx(2, i)
      B(6, 3*i-2) = dNdx(3, i)
      B(6, 3*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_C3D4_BMatrix

  ! 1-point: (1/4,1/4,1/4), weight = 1/6 (ref tet volume)
  SUBROUTINE PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(1), eta(1), zeta(1), weights(1)
    xi(1) = 0.25_wp
    eta(1) = 0.25_wp
    zeta(1) = 0.25_wp
    weights(1) = 1.0_wp / 6.0_wp
  END SUBROUTINE PH_Elem_C3D4_GaussPoints

  SUBROUTINE PH_Elem_C3D4_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdx(3, 4)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 12)
    REAL(wp) :: dNdxi(3, 4), J_inv(3, 3)
    INTEGER(i4) :: i, j
    CALL PH_Elem_C3D4_ShapeFunc(xi, eta, zeta, N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
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
    DO i = 1, 4
      DO j = 1, 3
        dNdx(j, i) = J_inv(j,1)*dNdxi(1,i) + J_inv(j,2)*dNdxi(2,i) + J_inv(j,3)*dNdxi(3,i)
      END DO
    END DO
    CALL PH_Elem_C3D4_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_C3D4_JacB

  SUBROUTINE PH_Elem_C3D4_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(6, 12)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(OUT) :: strain(6)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_C3D4_Strain

  SUBROUTINE PH_Elem_C3D4_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(6)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    sigma = MATMUL(D, epsilon)
  END SUBROUTINE PH_Elem_C3D4_Stress

  SUBROUTINE PH_Elem_C3D4_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1) = alpha * deltaT
    eps_th(2) = alpha * deltaT
    eps_th(3) = alpha * deltaT
    eps_th(4) = ZERO
    eps_th(5) = ZERO
    eps_th(6) = ZERO
  END SUBROUTINE PH_Elem_C3D4_ThermStrainVector

  SUBROUTINE PH_Elem_C3D4_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: c1, c2
    D = ZERO
    c1 = E_young / ((ONE + nu) * (ONE - 2.0_wp*nu))
    c2 = (ONE - nu) * c1
    D(1,1) = c2
    D(1,2) = nu * c1
    D(1,3) = nu * c1
    D(2,1) = nu * c1
    D(2,2) = c2
    D(2,3) = nu * c1
    D(3,1) = nu * c1
    D(3,2) = nu * c1
    D(3,3) = c2
    D(4,4) = 0.5_wp * E_young / (ONE + nu)
    D(5,5) = D(4,4)
    D(6,6) = D(4,4)
  END SUBROUTINE PH_Elem_C3D4_ConstMatrix

  SUBROUTINE PH_Elem_C3D4_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12), D(6, 6)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    Ke = ZERO
    CALL PH_Elem_C3D4_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_JacB(coords, xi(1), eta(1), zeta(1), N, dNdx, J, detJ, B)
    IF (ABS(detJ) <= 1.0e-12_wp) RETURN
    dV = detJ * weights(1)
    Ke = dV * MATMUL(MATMUL(TRANSPOSE(B), D), B)
  END SUBROUTINE PH_Elem_C3D4_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D4_FormStiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    Ke = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_JacB(coords, xi(1), eta(1), zeta(1), N, dNdx, J, detJ, B)
    IF (ABS(detJ) <= 1.0e-12_wp) RETURN
    dV = detJ * weights(1)
    Ke = dV * MATMUL(MATMUL(TRANSPOSE(B), D6), B)
  END SUBROUTINE PH_Elem_C3D4_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_C3D4_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(12)
    REAL(wp) :: Ke(12, 12)
    CALL PH_Elem_C3D4_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D4_FormIntForce

  SUBROUTINE PH_Elem_C3D4_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(12)
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_JacB(coords, xi(1), eta(1), zeta(1), N, dNdx, J, detJ, B)
    IF (ABS(detJ) <= 1.0e-12_wp) THEN
      R_int = ZERO
      RETURN
    END IF
    dV = detJ * weights(1)
    R_int = dV * MATMUL(TRANSPOSE(B), sigma6)
  END SUBROUTINE PH_Elem_C3D4_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D4_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(12, 12)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    INTEGER(i4) :: i, j
    Me = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) <= 1.0e-12_wp) RETURN
    dV = rho * detJ * weights(1)
    DO i = 1, 4
      DO j = 1, 4
        Me(3*i-2, 3*j-2) = Me(3*i-2, 3*j-2) + dV * N(i) * N(j)
        Me(3*i-1, 3*j-1) = Me(3*i-1, 3*j-1) + dV * N(i) * N(j)
        Me(3*i, 3*j)     = Me(3*i, 3*j)     + dV * N(i) * N(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4_ConsMass

  SUBROUTINE PH_Elem_C3D4_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(12)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: V, m
    INTEGER(i4) :: i
    M_lumped = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) <= 1.0e-12_wp) RETURN
    V = detJ * weights(1)
    m = rho * V / 4.0_wp
    DO i = 1, 4
      M_lumped(3*i-2) = m
      M_lumped(3*i-1) = m
      M_lumped(3*i)   = m
    END DO
  END SUBROUTINE PH_Elem_C3D4_LumpMass

!===============================================================================
! Subroutine: PH_Elem_C3D4_NL_TL
! Purpose: Total Lagrangian geometric nonlinearity for C3D4 (4-node linear tet)
! Theory: 1 Gauss point at centroid (1/4,1/4,1/4), weight 1/6
! Input: coords_ref(3,4), u_elem(12), mat_prop, mat_state(1)
! Output: Ke_mat(12,12), Ke_geo(12,12), R_int(12), status
!===============================================================================
  SUBROUTINE PH_Elem_C3D4_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag
    IMPLICIT NONE

    REAL(wp), INTENT(IN)  :: coords_ref(3, 4)
    REAL(wp), INTENT(IN)  :: u_elem(12)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12)
    REAL(wp), INTENT(OUT) :: Ke_geo(12, 12)
    REAL(wp), INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 4)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(1), eta_gp(1), zeta_gp(1), wt_gp(1)
    REAL(wp) :: N(4), dN_dxi(3, 4), J_ref(3, 3), J_inv(3, 3), det_J
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(12, 12), K_geo_gp(12, 12), R_gp(12)
    INTEGER(i4) :: i, j

        Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 4
      coords_curr(:, i) = coords_ref(:, i) + u_elem(3*(i-1)+1:3*i)
    END DO

    cfg%formulation_typ = 1
    DO i = 1, 4
      cfg%coords_ref(i, :) = coords_ref(:, i)
      cfg%coords_curr(i, :) = coords_curr(:, i)
    END DO

    CALL PH_Elem_C3D4_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)
    CALL PH_Elem_C3D4_ShapeFunc(xi_gp(1), eta_gp(1), zeta_gp(1), N, dN_dxi)
    CALL PH_Elem_C3D4_Jac(dN_dxi, coords_ref, J_ref, det_J)
    IF (ABS(det_J) <= 1.0e-12_wp) RETURN

    CALL InvertMat3x3(J_ref, J_inv, det_J)
    DO i = 1, 4
      DO j = 1, 3
        cfg%lcl%dN_dX(i, j) = J_inv(j,1)*dN_dxi(1,i) + J_inv(j,2)*dN_dxi(2,i) + J_inv(j,3)*dN_dxi(3,i)
      END DO
    END DO

    ! Compute deformation gradient F and Green-Lagrange strain E
    F = ZERO
    DO i = 1, 4
      DO j = 1, 3
        F(1, j) = F(1, j) + coords_curr(1, i) * cfg%lcl%dN_dX(i, j)
        F(2, j) = F(2, j) + coords_curr(2, i) * cfg%lcl%dN_dX(i, j)
        F(3, j) = F(3, j) + coords_curr(3, i) * cfg%lcl%dN_dX(i, j)
      END DO
    END DO

    ! Green-Lagrange strain: E = 0.5*(F^T*F - I)
    E(1,1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
    E(2,2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
    E(3,3) = HALF * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
    E(1,2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2))
    E(2,1) = E(1,2)
    E(1,3) = HALF * (F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3))
    E(3,1) = E(1,3)
    E(2,3) = HALF * (F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3))
    E(3,2) = E(2,3)

    ! Convert to Voigt notation: [E11, E22, E33, 2*E12, 2*E23, 2*E13]
    E_voigt(1) = E(1,1)
    E_voigt(2) = E(2,2)
    E_voigt(3) = E(3,3)
    E_voigt(4) = 2.0_wp * E(1,2)
    E_voigt(5) = 2.0_wp * E(2,3)
    E_voigt(6) = 2.0_wp * E(1,3)

    ! Call Mat constitutive model
    ss_gp%strain = E_voigt
    ss_gp%strain_inc = E_voigt
    CALL PH_UpdateStress(mat_prop, mat_state(1), ss_gp, mat_status)
    IF (mat_status%status_code /= 0) THEN
      status%code = STATUS_SUCCESS + 1
      RETURN
    END IF

    ! Convert PK2 stress back to tensor form
    S(1,1) = ss_gp%sigma(1)
    S(2,2) = ss_gp%sigma(2)
    S(3,3) = ss_gp%sigma(3)
    S(1,2) = ss_gp%sigma(4); S(2,1) = S(1,2)
    S(2,3) = ss_gp%sigma(5); S(3,2) = S(2,3)
    S(1,3) = ss_gp%sigma(6); S(3,1) = S(1,3)

    ! Pass external stress and tangent to RT layer
    CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
    IF (status%code /= STATUS_SUCCESS) RETURN

    Ke_mat = K_mat_gp * det_J * wt_gp(1)
    Ke_geo = K_geo_gp * det_J * wt_gp(1)
    R_int = R_gp * det_J * wt_gp(1)

  CONTAINS
    SUBROUTINE InvertMat3x3(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(3,3)
      REAL(wp), INTENT(OUT) :: A_inv(3,3), det
      det = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
            A_inv(1,1) = (A(2,2)*A(3,3)-A(2,3)*A(3,2))/det
            A_inv(1,2) = (A(1,3)*A(3,2)-A(1,2)*A(3,3))/det
            A_inv(1,3) = (A(1,2)*A(2,3)-A(1,3)*A(2,2))/det
            A_inv(2,1) = (A(2,3)*A(3,1)-A(2,1)*A(3,3))/det
            A_inv(2,2) = (A(1,1)*A(3,3)-A(1,3)*A(3,1))/det
            A_inv(2,3) = (A(1,3)*A(2,1)-A(1,1)*A(2,3))/det
            A_inv(3,1) = (A(2,1)*A(3,2)-A(2,2)*A(3,1))/det
            A_inv(3,2) = (A(1,2)*A(3,1)-A(1,1)*A(3,2))/det
      A_inv(3,3) = (A(1,1)*A(2,2)-A(1,2)*A(2,1))/det
    END SUBROUTINE InvertMat3x3
  END SUBROUTINE PH_Elem_C3D4_NL_TL

!===============================================================================
! Subroutine: PH_Elem_C3D4_NL_UL
!===============================================================================
  SUBROUTINE PH_Elem_C3D4_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_UpdLag
    IMPLICIT NONE

    REAL(wp), INTENT(IN)  :: coords_prev(3, 4), u_incr(12)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12), Ke_geo(12, 12), R_int(12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 4)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(1), eta_gp(1), zeta_gp(1), wt_gp(1)
    REAL(wp) :: N(4), dN_dxi(3, 4), J_prev(3, 3), J_inv(3, 3), det_J
    REAL(wp) :: F(3,3), epsilon(3,3), sigma(3,3)
    REAL(wp) :: epsilon_voigt(6)
    REAL(wp) :: b(3,3), b_inv(3,3), det_b
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(12,12), K_geo_gp(12,12), R_gp(12)
    INTEGER(i4) :: i, j

        Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 4
      coords_curr(:, i) = coords_prev(:, i) + u_incr(3*(i-1)+1:3*i)
    END DO

    cfg%formulation_typ = 2
    DO i = 1, 4
      cfg%coords_prev(i,:) = coords_prev(:,i); cfg%coords_curr(i,:) = coords_curr(:,i)
    END DO

    CALL PH_Elem_C3D4_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)
    CALL PH_Elem_C3D4_ShapeFunc(xi_gp(1), eta_gp(1), zeta_gp(1), N, dN_dxi)
    CALL PH_Elem_C3D4_Jac(dN_dxi, coords_prev, J_prev, det_J)
    IF (ABS(det_J) <= 1.0e-12_wp) RETURN

    CALL InvertMat3x3(J_prev, J_inv, det_J)
    DO i = 1, 4
      DO j = 1, 3
        cfg%dN_dx(i,j) = J_inv(j,1)*dN_dxi(1,i) + J_inv(j,2)*dN_dxi(2,i) + J_inv(j,3)*dN_dxi(3,i)
      END DO
    END DO

    ! Compute deformation gradient F
    F = ZERO
    DO i = 1, 4
      DO j = 1, 3
        F(1, j) = F(1, j) + coords_curr(1, i) * cfg%dN_dx(i, j)
        F(2, j) = F(2, j) + coords_curr(2, i) * cfg%dN_dx(i, j)
        F(3, j) = F(3, j) + coords_curr(3, i) * cfg%dN_dx(i, j)
      END DO
    END DO

    ! Almansi strain: epsilon = 0.5*(I - b^{-1}), b = F*F^T
    b = MATMUL(F, TRANSPOSE(F))
    CALL InvertMat3x3(b, b_inv, det_b)
    epsilon = ZERO
    epsilon(1,1) = HALF * (ONE - b_inv(1,1))
    epsilon(2,2) = HALF * (ONE - b_inv(2,2))
    epsilon(3,3) = HALF * (ONE - b_inv(3,3))
    epsilon(1,2) = -HALF * b_inv(1,2); epsilon(2,1) = epsilon(1,2)
    epsilon(1,3) = -HALF * b_inv(1,3); epsilon(3,1) = epsilon(1,3)
    epsilon(2,3) = -HALF * b_inv(2,3); epsilon(3,2) = epsilon(2,3)

    ! Convert to Voigt notation
    epsilon_voigt(1) = epsilon(1,1)
    epsilon_voigt(2) = epsilon(2,2)
    epsilon_voigt(3) = epsilon(3,3)
    epsilon_voigt(4) = 2.0_wp * epsilon(1,2)
    epsilon_voigt(5) = 2.0_wp * epsilon(2,3)
    epsilon_voigt(6) = 2.0_wp * epsilon(1,3)

    ! Call Mat constitutive model
    ss_gp%strain = epsilon_voigt
    ss_gp%strain_inc = epsilon_voigt
    CALL PH_UpdateStress(mat_prop, mat_state(1), ss_gp, mat_status)
    IF (mat_status%status_code /= 0) THEN
      status%code = STATUS_SUCCESS + 1
      RETURN
    END IF

    ! Convert Cauchy stress back to tensor form
    sigma(1,1) = ss_gp%sigma(1)
    sigma(2,2) = ss_gp%sigma(2)
    sigma(3,3) = ss_gp%sigma(3)
    sigma(1,2) = ss_gp%sigma(4); sigma(2,1) = sigma(1,2)
    sigma(2,3) = ss_gp%sigma(5); sigma(3,2) = sigma(2,3)
    sigma(1,3) = ss_gp%sigma(6); sigma(3,1) = sigma(1,3)

    ! Pass external stress and tangent to RT layer
    CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
    IF (status%code /= STATUS_SUCCESS) RETURN

    Ke_mat = K_mat_gp * det_J * wt_gp(1)
    Ke_geo = K_geo_gp * det_J * wt_gp(1)
    R_int = R_gp * det_J * wt_gp(1)

  CONTAINS
    SUBROUTINE InvertMat3x3(A, A_inv, det)
            REAL(wp), INTENT(IN) :: A(3,3)
            REAL(wp), INTENT(OUT) :: A_inv(3,3), det
      det = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
            A_inv(1,1) = (A(2,2)*A(3,3)-A(2,3)*A(3,2))/det
            A_inv(1,2) = (A(1,3)*A(3,2)-A(1,2)*A(3,3))/det
            A_inv(1,3) = (A(1,2)*A(2,3)-A(1,3)*A(2,2))/det
            A_inv(2,1) = (A(2,3)*A(3,1)-A(2,1)*A(3,3))/det
            A_inv(2,2) = (A(1,1)*A(3,3)-A(1,3)*A(3,1))/det
            A_inv(2,3) = (A(1,3)*A(2,1)-A(1,1)*A(2,3))/det
            A_inv(3,1) = (A(2,1)*A(3,2)-A(2,2)*A(3,1))/det
            A_inv(3,2) = (A(1,2)*A(3,1)-A(1,1)*A(3,2))/det
      A_inv(3,3) = (A(1,1)*A(2,2)-A(1,2)*A(2,1))/det
    END SUBROUTINE InvertMat3x3
  END SUBROUTINE PH_Elem_C3D4_NL_UL

  SUBROUTINE PH_Elem_C3D4_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_C3D4_Material_Update_Routed

  ! --- Sect (merged from PH_Elem_C3D4_Sect) ---
  SUBROUTINE PH_Elem_C3D4_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: volume, dV
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    INTEGER(i4) :: i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    dV = detJ * weights(1)
    volume = dV
    DO i = 1, 3
      DO j = 1, 4
        centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
      centroid(3) = centroid(3) / volume
    END IF
  END SUBROUTINE PH_Elem_C3D4_GetCentroid

  SUBROUTINE PH_Elem_C3D4_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    dV = rho * detJ * weights(1)
    x(1) = ZERO
    x(2) = ZERO
    x(3) = ZERO
    DO k = 1, 4
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
  END SUBROUTINE PH_Elem_C3D4_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D4_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_C3D4_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D4_GetSectProps

  SUBROUTINE PH_Elem_C3D4_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    volume = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    volume = detJ * weights(1)
  END SUBROUTINE PH_Elem_C3D4_GetVolume

  ! --- Constraints (merged from PH_Elem_C3D4_Constraints) ---
  SUBROUTINE PH_Elem_C3D4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 12) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D4_ApplyConstraint

  SUBROUTINE PH_Elem_C3D4_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(12)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
    INTEGER(i4) :: i, j
    DO i = 1, 12
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 12
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4_ApplyMPC

  ! --- Cont (merged from PH_Elem_C3D4_Cont) ---
  SUBROUTINE PH_Elem_C3D4_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
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
  END SUBROUTINE PH_Elem_C3D4_FormContactContrib

  SUBROUTINE PH_Elem_C3D4_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
    REAL(wp) :: xi, eta, zeta, N(4), n(3), dNdxi(3, 4)
    REAL(wp) :: r1(3), r2(3), r3(3)
    INTEGER(i4) :: nodes(3), i
    IF (face_id < 1 .OR. face_id > 4) RETURN
    nodes(1) = PH_ELEM_C3D4_FACE_NODES(1, face_id)
    nodes(2) = PH_ELEM_C3D4_FACE_NODES(2, face_id)
    nodes(3) = PH_ELEM_C3D4_FACE_NODES(3, face_id)
    SELECT CASE (face_id)
    CASE (1)
      xi = 1.0_wp / 3.0_wp
      eta = 1.0_wp / 3.0_wp
      zeta = 1.0_wp / 3.0_wp
    CASE (2)
      xi = 0.0_wp
      eta = 1.0_wp / 3.0_wp
      zeta = 1.0_wp / 3.0_wp
    CASE (3)
      xi = 1.0_wp / 3.0_wp
      eta = 0.0_wp
      zeta = 1.0_wp / 3.0_wp
    CASE (4)
      xi = 1.0_wp / 3.0_wp
      eta = 1.0_wp / 3.0_wp
      zeta = 0.0_wp
    END SELECT
    CALL PH_Elem_C3D4_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r1(1) = coords(1, nodes(2)) - coords(1, nodes(1))
    r1(2) = coords(2, nodes(2)) - coords(2, nodes(1))
    r1(3) = coords(3, nodes(2)) - coords(3, nodes(1))
    r2(1) = coords(1, nodes(3)) - coords(1, nodes(1))
    r2(2) = coords(2, nodes(3)) - coords(2, nodes(1))
    r2(3) = coords(3, nodes(3)) - coords(3, nodes(1))
    n(1) = r1(2)*r2(3) - r1(3)*r2(2)
    n(2) = r1(3)*r2(1) - r1(1)*r2(3)
    n(3) = r1(1)*r2(2) - r1(2)*r2(1)
    IF (face_id == 1) THEN
      n(1) = -n(1)
      n(2) = -n(2)
      n(3) = -n(3)
    END IF
    IF (SUM(n**2) > 1.0e-20_wp) THEN
      r1(1) = SQRT(SUM(n**2))
      n(1) = n(1) / r1(1)
      n(2) = n(2) / r1(1)
      n(3) = n(3) / r1(1)
    END IF
    CALL PH_Elem_C3D4_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D4_FormContactFaceCtr

  ! --- Loads (merged from PH_Elem_C3D4_Loads) ---
  SUBROUTINE PH_Elem_C3D4_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(12)
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
    IF (face_id == 1) THEN
      n(1) = -n(1)
      n(2) = -n(2)
      n(3) = -n(3)
    END IF
    DO j = 1, 3
      i = nodes(j)
      F_eq(3*i-2) = F_eq(3*i-2) + (p * area / 3.0_wp) * n(1)
      F_eq(3*i-1) = F_eq(3*i-1) + (p * area / 3.0_wp) * n(2)
      F_eq(3*i)   = F_eq(3*i)   + (p * area / 3.0_wp) * n(3)
    END DO
  END SUBROUTINE PH_Elem_C3D4_FormFacePressure

  SUBROUTINE PH_Elem_C3D4_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(12)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        F_eq(3*i-2) = F_eq(3*i-2) + N(i) * bx * detJ * weights(ip)
        F_eq(3*i-1) = F_eq(3*i-1) + N(i) * by * detJ * weights(ip)
        F_eq(3*i)   = F_eq(3*i)   + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4_FormBodyForce

  SUBROUTINE PH_Elem_C3D4_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(12)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D4_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D4_FormFacePressure(coords, val(1), face_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D4_FormNodalForce

  ! --- Out (merged from PH_Elem_C3D4_Out) ---
  SUBROUTINE PH_Elem_C3D4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 13
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 1)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 6) THEN
        out_vars(1:6, ip) = ip_stress(1:6, ip)
      END IF
      IF (SIZE(ip_strain, 1) >= 6) THEN
        out_vars(7:12, ip) = ip_strain(1:6, ip)
      END IF
      IF (SIZE(ip_peeq) >= ip) THEN
        out_vars(13, ip) = ip_peeq(ip)
      END IF
    END DO
  END SUBROUTINE PH_Elem_C3D4_CollectIPVars

  SUBROUTINE PH_Elem_C3D4_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: principal(3)
    REAL(wp) :: s(3,3), p, q, r, phi, a
    INTEGER(i4) :: i
    s(1,1) = sigma(1)
    s(2,2) = sigma(2)
    s(3,3) = sigma(3)
    s(1,2) = sigma(4)
    s(2,1) = sigma(4)
    s(2,3) = sigma(5)
    s(3,2) = sigma(5)
    s(1,3) = sigma(6)
    s(3,1) = sigma(6)
    p = (s(1,1) + s(2,2) + s(3,3)) / 3.0_wp
    q = (s(1,1)*s(2,2) + s(2,2)*s(3,3) + s(3,3)*s(1,1) - s(1,2)**2 - s(2,3)**2 - s(1,3)**2) / 3.0_wp - p**2
    r = (s(1,1)-p)*(s(2,2)-p)*(s(3,3)-p) + 2.0_wp*s(1,2)*s(2,3)*s(1,3) &
        - (s(1,1)-p)*s(2,3)**2 - (s(2,2)-p)*s(1,3)**2 - (s(3,3)-p)*s(1,2)**2
    r = r / 2.0_wp
    IF (q <= 1.0e-20_wp) THEN
      principal(1) = p
      principal(2) = p
      principal(3) = p
      RETURN
    END IF
    a = SQRT(MAX(q, ZERO))
    IF (ABS(a) < 1.0e-20_wp) THEN
      principal(1) = p
      principal(2) = p
      principal(3) = p
      RETURN
    END IF
    r = MAX(-ONE, MIN(ONE, r / (a**3)))
    phi = ACOS(r) / 3.0_wp
    principal(1) = p + 2.0_wp * a * COS(phi)
    principal(2) = p + 2.0_wp * a * COS(phi - 8.0_wp*ATAN(1.0_wp)/3.0_wp)
    principal(3) = p + 2.0_wp * a * COS(phi + 8.0_wp*ATAN(1.0_wp)/3.0_wp)
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
    IF (principal(1) < principal(2)) THEN
      a = principal(1)
      principal(1) = principal(2)
      principal(2) = a
    END IF
  END SUBROUTINE PH_Elem_C3D4_EvalPrincStress

  SUBROUTINE PH_Elem_C3D4_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e
    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (edev(1)*edev(1) + edev(2)*edev(2) + edev(3)*edev(3)) &
          + edev(4)*edev(4) + edev(5)*edev(5) + edev(6)*edev(6)
  END SUBROUTINE PH_Elem_C3D4_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D4_EvalStressInvar(sigma, I1, J2, J3)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: I1, J2, J3
    REAL(wp) :: p, sdev(6), s3(3, 3)
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdev(1:3) = sigma(1:3) - p
    sdev(4:6) = sigma(4:6)
    J2 = HALF * (sdev(1)*sdev(1) + sdev(2)*sdev(2) + sdev(3)*sdev(3)) &
         + sdev(4)*sdev(4) + sdev(5)*sdev(5) + sdev(6)*sdev(6)
    s3(1,1) = sdev(1)
    s3(1,2) = sdev(4)
    s3(1,3) = sdev(6)
    s3(2,1) = sdev(4)
    s3(2,2) = sdev(2)
    s3(2,3) = sdev(5)
    s3(3,1) = sdev(6)
    s3(3,2) = sdev(5)
    s3(3,3) = sdev(3)
    J3 = s3(1,1)*(s3(2,2)*s3(3,3) - s3(2,3)*s3(3,2)) &
       - s3(1,2)*(s3(2,1)*s3(3,3) - s3(2,3)*s3(3,1)) &
       + s3(1,3)*(s3(2,1)*s3(3,2) - s3(2,2)*s3(3,1))
  END SUBROUTINE PH_Elem_C3D4_EvalStressInvar

  SUBROUTINE PH_Elem_C3D4_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax
    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D4_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    IF (seq > 1.0e-20_wp) THEN
      triax = p / seq
    ELSE
      triax = ZERO
    END IF
  END SUBROUTINE PH_Elem_C3D4_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D4_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s1, s2, s3, p, J2
    s1 = sigma(1)
    s2 = sigma(2)
    s3 = sigma(3)
    p = (s1 + s2 + s3) / 3.0_wp
    J2 = HALF * ((s1-p)**2 + (s2-p)**2 + (s3-p)**2) &
         + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D4_EvalVonMises

  SUBROUTINE PH_Elem_C3D4_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 1)
    E(1:4, 1) = ONE
  END SUBROUTINE PH_Elem_C3D4_GetExtrapMat

  SUBROUTINE PH_Elem_C3D4_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    INTEGER(i4) :: ic, i, n_comp
    node_vars = ZERO
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 4
        IF (SIZE(ip_vars, 1) >= 1) THEN
          node_vars(i, ic) = ip_vars(1, ic)
        END IF
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D4_MapToNode

END MODULE PH_Elem_C3D4


