!===============================================================================
! MODULE: PH_Elem_C3D13
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D13 13-node quadratic pyramid, 8-point integration (reduced)
!===============================================================================
MODULE PH_Elem_C3D13
!> Status: Production | Last verified: 2026-03-09
!> Merged: Defn + Sect + Constraints + Cont + Loads + Out
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_C3D13_DefInit
  PUBLIC :: PH_Elem_C3D13_ShapeFunc
  PUBLIC :: PH_Elem_C3D13_Jac
  PUBLIC :: PH_Elem_C3D13_BMatrix
  PUBLIC :: PH_Elem_C3D13_GaussPoints
  PUBLIC :: PH_Elem_C3D13_JacB
  PUBLIC :: PH_Elem_C3D13_Strain
  PUBLIC :: PH_Elem_C3D13_Stress
  PUBLIC :: PH_Elem_C3D13_ConstMatrix
  PUBLIC :: PH_Elem_C3D13_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D13_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_C3D13_FormIntForce
  PUBLIC :: PH_Elem_C3D13_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D13_ConsMass
  PUBLIC :: PH_Elem_C3D13_LumpMass
  PUBLIC :: PH_Elem_C3D13_ThermStrainVector
  PUBLIC :: PH_ELEM_C3D13_NNODE
  PUBLIC :: PH_ELEM_C3D13_NIP
  PUBLIC :: PH_ELEM_C3D13_NDOF
  PUBLIC :: PH_ELEM_C3D13_NFACE
  PUBLIC :: PH_ELEM_C3D13_FACE_NODES
  PUBLIC :: PH_Elem_C3D13_NL_TL
  PUBLIC :: PH_Elem_C3D13_NL_UL
  PUBLIC :: PH_Elem_C3D13_Material_Update_Routed
  PUBLIC :: PH_Elem_C3D13_GetVolume, PH_Elem_C3D13_GetSectProps, PH_Elem_C3D13_GetCentroid
  PUBLIC :: PH_Elem_C3D13_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D13_ApplyConstraint, PH_Elem_C3D13_ApplyMPC
  PUBLIC :: PH_Elem_C3D13_FormContactContrib, PH_Elem_C3D13_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D13_FormNodalForce, PH_Elem_C3D13_FormBodyForce, PH_Elem_C3D13_FormFacePressure
  PUBLIC :: PH_Elem_C3D13_CollectIPVars, PH_Elem_C3D13_MapToNode, PH_Elem_C3D13_GetExtrapMat
  PUBLIC :: PH_Elem_C3D13_EvalVonMises, PH_Elem_C3D13_EvalPrincStress
  PUBLIC :: PH_Elem_C3D13_EvalStressInvar, PH_Elem_C3D13_EvalStrainInvar, PH_Elem_C3D13_EvalTriaxiality
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D13_NNODE  = 13_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D13_NIP   = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D13_NDOF  = 39_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D13_NFACE = 5_i4
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp
  ! Face: 1=base quad(1,2,3,4); 2?=triangles to apex node 13. Tri: 4th=0.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D13_FACE_NODES(4, 5) = RESHAPE([ &
    1,2,3,4, 1,2,13,0, 2,3,13,0, 3,4,13,0, 4,1,13,0 ], [4, 5])
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

  SUBROUTINE PH_Elem_C3D13_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1:3) = alpha * deltaT
    eps_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D13_ThermStrainVector

  SUBROUTINE PH_Elem_C3D13_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 13)
    REAL(wp), INTENT(OUT) :: B(6, 39)
    INTEGER(i4) :: i, c
    B = ZERO
    DO i = 1, 13
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
  END SUBROUTINE PH_Elem_C3D13_BMatrix

  SUBROUTINE PH_Elem_C3D13_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(39, 39)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dV, nij
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 13
        DO j = 1, 13
          nij = dV * N(i) * N(j)
          Me(3*i-2, 3*j-2) = Me(3*i-2, 3*j-2) + nij
          Me(3*i-1, 3*j-1) = Me(3*i-1, 3*j-1) + nij
          Me(3*i, 3*j)     = Me(3*i, 3*j)     + nij
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D13_ConsMass

  SUBROUTINE PH_Elem_C3D13_ConstMatrix(E_young, nu, D)
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
  END SUBROUTINE PH_Elem_C3D13_ConstMatrix

  SUBROUTINE PH_Elem_C3D13_DefInit()
  END SUBROUTINE PH_Elem_C3D13_DefInit

  SUBROUTINE PH_Elem_C3D13_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: u(39)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(39)
    REAL(wp) :: Ke(39, 39)
    CALL PH_Elem_C3D13_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D13_FormIntForce

  SUBROUTINE PH_Elem_C3D13_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(39)
    REAL(wp) :: N(13), dNdx(3, 13), J(3, 3), detJ, B(6, 39)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma6)
    END DO
  END SUBROUTINE PH_Elem_C3D13_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D13_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(39, 39)
    REAL(wp) :: N(13), dNdx(3, 13), J(3, 3), detJ, B(6, 39), D(6, 6)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D13_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + detJ * weights(ip) * MATMUL(MATMUL(TRANSPOSE(B), D), B)
    END DO
  END SUBROUTINE PH_Elem_C3D13_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D13_FormStiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(39, 39)
    REAL(wp) :: N(13), dNdx(3, 13), J(3, 3), detJ, B(6, 39)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + detJ * weights(ip) * MATMUL(MATMUL(TRANSPOSE(B), D6), B)
    END DO
  END SUBROUTINE PH_Elem_C3D13_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(8), eta(8), zeta(8), weights(8)
    ! 2×2 GL on (xi,eta) in [-1,1]²; 2 GL levels on zeta in [0,1]; weight 0.5 per point (sum=4)
    REAL(wp) :: z1, z2, a
    INTEGER(i4) :: k, ix, iy
    a = PH_ELEM_GAUSS_PT
    z1 = HALF * (ONE - a)
    z2 = HALF * (ONE + a)
    k = 0
    DO iy = 1, 2
      DO ix = 1, 2
        k = k + 1
        xi(k) = MERGE(-a, a, ix == 1)
        eta(k) = MERGE(-a, a, iy == 1)
        zeta(k) = z1
        weights(k) = HALF
        k = k + 1
        xi(k) = MERGE(-a, a, ix == 1)
        eta(k) = MERGE(-a, a, iy == 1)
        zeta(k) = z2
        weights(k) = HALF
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D13_GaussPoints

  SUBROUTINE PH_Elem_C3D13_GetVolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D13_GetVolumeInt

  SUBROUTINE PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 13)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i, j
    J = ZERO
    DO j = 1, 3
      DO i = 1, 13
        J(1, j) = J(1, j) + coords(1, i) * dNdxi(j, i)
        J(2, j) = J(2, j) + coords(2, i) * dNdxi(j, i)
        J(3, j) = J(3, j) + coords(3, i) * dNdxi(j, i)
      END DO
    END DO
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
  END SUBROUTINE PH_Elem_C3D13_Jac

  SUBROUTINE PH_Elem_C3D13_JacB(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt, zeta_pt
    REAL(wp), INTENT(OUT) :: N(13)
    REAL(wp), INTENT(OUT) :: dNdx(3, 13)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 39)
    REAL(wp) :: dNdxi(3, 13), J_inv(3, 3)
    INTEGER(i4) :: i, j, k
    CALL PH_Elem_C3D13_ShapeFunc(xi_pt, eta_pt, zeta_pt, N, dNdxi)
    CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
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
    DO i = 1, 13
      DO j = 1, 3
        dNdx(j, i) = SUM(J_inv(j, 1:3) * dNdxi(1:3, i))
      END DO
    END DO
    CALL PH_Elem_C3D13_BMatrix(dNdx, B)
  END SUBROUTINE PH_Elem_C3D13_JacB

  SUBROUTINE PH_Elem_C3D13_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(39)
    REAL(wp) :: V, m
    INTEGER(i4) :: i
    CALL PH_Elem_C3D13_GetVolumeInt(coords, V)
    m = rho * V / 13.0_wp
    DO i = 1, 13
      M_lumped(3*i-2) = m
      M_lumped(3*i-1) = m
      M_lumped(3*i)   = m
    END DO
  END SUBROUTINE PH_Elem_C3D13_LumpMass

  SUBROUTINE PH_Elem_C3D13_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 13)
    REAL(wp), INTENT(IN) :: u_elem(39)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(39, 39)
    REAL(wp), INTENT(OUT) :: Ke_geo(39, 39)
    REAL(wp), INTENT(OUT) :: R_int(39)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 13)
    REAL(wp) :: xi_gp(8), eta_gp(8), zeta_gp(8), wt_gp(8)
    REAL(wp) :: N(13), dN_dxi(3, 13), dN_dX(3, 13)
    REAL(wp) :: J_ref(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(39, 39), K_geo_gp(39, 39), R_gp(39)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp, j

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 13
      coords_curr(1, i) = coords_ref(1, i) + u_elem(3*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(3*(i-1)+2)
      coords_curr(3, i) = coords_ref(3, i) + u_elem(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D13_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    cfg%formulation_typ = 1

    DO i = 1, 13
      cfg%coords_ref(i, 1)  = coords_ref(1, i)
      cfg%coords_ref(i, 2)  = coords_ref(2, i)
      cfg%coords_ref(i, 3)  = coords_ref(3, i)
      cfg%coords_curr(i, 1) = coords_curr(1, i)
      cfg%coords_curr(i, 2) = coords_curr(2, i)
      cfg%coords_curr(i, 3) = coords_curr(3, i)
    END DO

    DO igp = 1, PH_ELEM_C3D13_NIP
      CALL PH_Elem_C3D13_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D13_Jac(dN_dxi, coords_ref, J_ref, det_J)

      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_ref, J_inv, det_J)
      DO i = 1, 13
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dX(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 13
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
        cfg%lcl%dN_dX(i, 3) = dN_dX(3, i)
      END DO

      ! Compute deformation gradient F and Green-Lagrange strain E
      F = ZERO
      DO i = 1, 13
        DO j = 1, 3
          F(1, j) = F(1, j) + coords_curr(1, i) * dN_dX(j, i)
          F(2, j) = F(2, j) + coords_curr(2, i) * dN_dX(j, i)
          F(3, j) = F(3, j) + coords_curr(3, i) * dN_dX(j, i)
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

      ! Convert to Voigt notation
      E_voigt(1) = E(1,1)
      E_voigt(2) = E(2,2)
      E_voigt(3) = E(3,3)
      E_voigt(4) = 2.0_wp * E(1,2)
      E_voigt(5) = 2.0_wp * E(2,3)
      E_voigt(6) = 2.0_wp * E(1,3)

      ! Call Mat constitutive model for this Gauss point
      ss_gp%strain = E_voigt
      ss_gp%strain_inc = E_voigt
      CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        status%code = IF_STATUS_ERROR

        RETURN
      END IF

      ! Convert PK2 stress back to tensor form
      S(1,1) = ss_gp%sigma(1)
      S(2,2) = ss_gp%sigma(2)
      S(3,3) = ss_gp%sigma(3)
      S(1,2) = ss_gp%sigma(4); S(2,1) = S(1,2)
      S(2,3) = ss_gp%sigma(5); S(3,2) = S(2,3)
      S(1,3) = ss_gp%sigma(6); S(3,1) = S(1,3)

      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int  = R_int  + R_gp      * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(IN) :: det
      REAL(wp), INTENT(OUT) :: A_inv(3, 3)
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D13_NL_TL

  SUBROUTINE PH_Elem_C3D13_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 13)
    REAL(wp), INTENT(IN) :: u_incr(39)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(39, 39)
    REAL(wp), INTENT(OUT) :: Ke_geo(39, 39)
    REAL(wp), INTENT(OUT) :: R_int(39)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 13)
    REAL(wp) :: xi_gp(8), eta_gp(8), zeta_gp(8), wt_gp(8)
    REAL(wp) :: N(13), dN_dxi(3, 13), dN_dx(3, 13)
    REAL(wp) :: J_prev(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), epsilon(3, 3), sigma(3, 3)
    REAL(wp) :: epsilon_voigt(6)
    REAL(wp) :: b(3,3), b_inv(3,3), det_b
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(39, 39), K_geo_gp(39, 39), R_gp(39)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp, j

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 13
      coords_curr(1, i) = coords_prev(1, i) + u_incr(3*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(3*(i-1)+2)
      coords_curr(3, i) = coords_prev(3, i) + u_incr(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D13_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    cfg%formulation_typ = 2

    DO i = 1, 13
      cfg%coords_prev(i, 1) = coords_prev(1, i)
      cfg%coords_prev(i, 2) = coords_prev(2, i)
      cfg%coords_prev(i, 3) = coords_prev(3, i)
      cfg%coords_curr(i, 1) = coords_curr(1, i)
      cfg%coords_curr(i, 2) = coords_curr(2, i)
      cfg%coords_curr(i, 3) = coords_curr(3, i)
    END DO

    DO igp = 1, PH_ELEM_C3D13_NIP
      CALL PH_Elem_C3D13_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D13_Jac(dN_dxi, coords_prev, J_prev, det_J)

      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_prev, J_inv, det_J)
      DO i = 1, 13
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dx(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 13
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
        cfg%dN_dx(i, 3) = dN_dx(3, i)
      END DO

      ! Compute deformation gradient F
      F = ZERO
      DO i = 1, 13
        DO j = 1, 3
          F(1, j) = F(1, j) + coords_curr(1, i) * dN_dx(j, i)
          F(2, j) = F(2, j) + coords_curr(2, i) * dN_dx(j, i)
          F(3, j) = F(3, j) + coords_curr(3, i) * dN_dx(j, i)
        END DO
      END DO

      ! Almansi strain: epsilon = 0.5*(I - b^{-1}), b = F*F^T
      b = MATMUL(F, TRANSPOSE(F))
      det_b = b(1,1)*(b(2,2)*b(3,3)-b(2,3)*b(3,2)) - b(1,2)*(b(2,1)*b(3,3)-b(2,3)*b(3,1)) + b(1,3)*(b(2,1)*b(3,2)-b(2,2)*b(3,1))
      IF (ABS(det_b) <= 1.0e-30_wp) CYCLE
      CALL Invert3x3(b, b_inv, det_b)
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

      ! Call Mat constitutive model for this Gauss point
      ss_gp%strain = epsilon_voigt
      ss_gp%strain_inc = epsilon_voigt
      CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        status%code = IF_STATUS_ERROR

        RETURN
      END IF

      ! Convert Cauchy stress back to tensor form
      sigma(1,1) = ss_gp%sigma(1)
      sigma(2,2) = ss_gp%sigma(2)
      sigma(3,3) = ss_gp%sigma(3)
      sigma(1,2) = ss_gp%sigma(4); sigma(2,1) = sigma(1,2)
      sigma(2,3) = ss_gp%sigma(5); sigma(3,2) = sigma(2,3)
      sigma(1,3) = ss_gp%sigma(6); sigma(3,1) = sigma(1,3)

      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int  = R_int  + R_gp      * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(IN) :: det
      REAL(wp), INTENT(OUT) :: A_inv(3, 3)
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D13_NL_UL

  SUBROUTINE PH_Elem_C3D13_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(13)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 13)
    ! ABAQUS node order: 1? base corners, 5? base edge mids, 9?2 lateral mids, 13 apex.
    ! Isoparametric basis from VTK vtkQuadraticPyramid (r,s,t in [-1,1]) with t = 2*zeta - 1.
    REAL(wp) :: r, s, t, r2, s2, t2, rm, rp, sm, sp, tm, tvtk2
    REAL(wp) :: vtk_w(13), vtk_dr(13), vtk_ds(13), vtk_dt(13)
    INTEGER(i4) :: j
    INTEGER(i4), PARAMETER :: abq_to_vtk(13) = (/ 1_i4, 2_i4, 3_i4, 4_i4, 6_i4, 7_i4, 8_i4, 9_i4, &
      10_i4, 11_i4, 12_i4, 13_i4, 5_i4 /)

    r = xi
    s = eta
    t = 2.0_wp * zeta - ONE
    r2 = r * r
    s2 = s * s
    t2 = t * t
    rm = ONE - r
    rp = ONE + r
    sm = ONE - s
    sp = ONE + s
    tvtk2 = ONE - t2

    vtk_w(1) = -rm*sm*tm*(4.0_wp + 3.0_wp*r + 3.0_wp*s + 2.0_wp*r*s + 2.0_wp*t + r*t + s*t + 2.0_wp*r*s*t) / 16.0_wp
    vtk_w(2) = -rp*sm*tm*(4.0_wp - 3.0_wp*r + 3.0_wp*s - 2.0_wp*r*s + 2.0_wp*t - r*t + s*t - 2.0_wp*r*s*t) / 16.0_wp
    vtk_w(3) = -rp*sp*tm*(4.0_wp - 3.0_wp*r - 3.0_wp*s + 2.0_wp*r*s + 2.0_wp*t - r*t - s*t + 2.0_wp*r*s*t) / 16.0_wp
    vtk_w(4) = -rm*sp*tm*(4.0_wp + 3.0_wp*r - 3.0_wp*s - 2.0_wp*r*s + 2.0_wp*t + r*t - s*t - 2.0_wp*r*s*t) / 16.0_wp
    vtk_w(5) = t * (ONE + t) / 2.0_wp
    vtk_w(6) = (ONE - r2) * sm * tm * (2.0_wp + s + s*t) / 8.0_wp
    vtk_w(7) = rp * (ONE - s2) * tm * (2.0_wp - r - r*t) / 8.0_wp
    vtk_w(8) = (ONE - r2) * sp * tm * (2.0_wp - s - s*t) / 8.0_wp
    vtk_w(9) = rm * (ONE - s2) * tm * (2.0_wp + r + r*t) / 8.0_wp
    vtk_w(10) = rm * sm * tvtk2 / 4.0_wp
    vtk_w(11) = rp * sm * tvtk2 / 4.0_wp
    vtk_w(12) = rp * sp * tvtk2 / 4.0_wp
    vtk_w(13) = rm * sp * tvtk2 / 4.0_wp

    vtk_dr(1) = -0.125_wp * (sm*tm - 2.0_wp*r*sm*tm - s*sm*tm - t*sm*tm - 2.0_wp*sm*tm)
    vtk_dr(2) =  0.125_wp * (sm*tm + 2.0_wp*r*sm*tm - s*sm*tm - t*sm*tm - 2.0_wp*sm*tm)
    vtk_dr(3) =  0.125_wp * (sp*tm + 2.0_wp*r*sp*tm + s*sp*tm - t*sp*tm - 2.0_wp*sp*tm)
    vtk_dr(4) = -0.125_wp * (sp*tm - 2.0_wp*r*sp*tm + s*sp*tm - t*sp*tm - 2.0_wp*sp*tm)
    vtk_dr(5) = ZERO
    vtk_dr(6) = -0.5_wp * r * sm * tm
    vtk_dr(7) =  0.25_wp * (tm - s2*tm)
    vtk_dr(8) = -0.5_wp * r * sp * tm
    vtk_dr(9) = -0.25_wp * (tm - s2*tm)
    vtk_dr(10) = -0.25_wp * sm * tvtk2
    vtk_dr(11) =  0.25_wp * sm * tvtk2
    vtk_dr(12) =  0.25_wp * sp * tvtk2
    vtk_dr(13) = -0.25_wp * sp * tvtk2

    vtk_ds(1) = -0.125_wp * (rm*tm - 2.0_wp*s*rm*tm - r*rm*tm - t*rm*tm - 2.0_wp*rm*tm)
    vtk_ds(2) = -0.125_wp * (rp*tm - 2.0_wp*s*rp*tm + r*rp*tm - t*rp*tm - 2.0_wp*rp*tm)
    vtk_ds(3) =  0.125_wp * (rp*tm + 2.0_wp*s*rp*tm + r*rp*tm - t*rp*tm - 2.0_wp*rp*tm)
    vtk_ds(4) =  0.125_wp * (rm*tm + 2.0_wp*s*rm*tm - r*rm*tm - t*rm*tm - 2.0_wp*rm*tm)
    vtk_ds(5) = ZERO
    vtk_ds(6) = -0.25_wp * tm * (ONE - r2)
    vtk_ds(7) = -0.5_wp * tm * s * rp
    vtk_ds(8) =  0.25_wp * tm * (ONE - r2)
    vtk_ds(9) = -0.5_wp * tm * s * rm
    vtk_ds(10) = -0.25_wp * rm * tvtk2
    vtk_ds(11) = -0.25_wp * rp * tvtk2
    vtk_ds(12) =  0.25_wp * rp * tvtk2
    vtk_ds(13) =  0.25_wp * rm * tvtk2

    vtk_dt(1) = -0.125_wp * (rm*sm - 2.0_wp*t*rm*sm - r*rm*sm - s*rm*sm - 2.0_wp*rm*sm)
    vtk_dt(2) = -0.125_wp * (rp*sm - 2.0_wp*t*rp*sm + r*rp*sm - s*rp*sm - 2.0_wp*rp*sm)
    vtk_dt(3) = -0.125_wp * (rp*sp - 2.0_wp*t*rp*sp + r*rp*sp + s*rp*sp - 2.0_wp*rp*sp)
    vtk_dt(4) = -0.125_wp * (rm*sp - 2.0_wp*t*rm*sp - r*rm*sp + s*rm*sp - 2.0_wp*rm*sp)
    vtk_dt(5) =  0.5_wp + t
    vtk_dt(6) = -0.25_wp * (sm - r2*sm)
    vtk_dt(7) = -0.25_wp * (rp - s2*rp)
    vtk_dt(8) = -0.25_wp * (sp - r2*sp)
    vtk_dt(9) = -0.25_wp * (rm - s2*rm)
    vtk_dt(10) = -0.5_wp * rm * sm * t
    vtk_dt(11) = -0.5_wp * rp * sm * t
    vtk_dt(12) = -0.5_wp * rp * sp * t
    vtk_dt(13) = -0.5_wp * rm * sp * t

    DO j = 1, 13
      N(j) = vtk_w(abq_to_vtk(j))
      dNdxi(1, j) = vtk_dr(abq_to_vtk(j))
      dNdxi(2, j) = vtk_ds(abq_to_vtk(j))
      dNdxi(3, j) = vtk_dt(abq_to_vtk(j)) * 2.0_wp
    END DO
  END SUBROUTINE PH_Elem_C3D13_ShapeFunc

  SUBROUTINE PH_Elem_C3D13_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(6, 39)
    REAL(wp), INTENT(IN)  :: u(39)
    REAL(wp), INTENT(OUT) :: strain(6)
    strain = MATMUL(B, u)
  END SUBROUTINE PH_Elem_C3D13_Strain

  SUBROUTINE PH_Elem_C3D13_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(6)
    REAL(wp), INTENT(IN)  :: D(6, 6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    sigma = MATMUL(D, epsilon)
  END SUBROUTINE PH_Elem_C3D13_Stress

  ! --- Sect (merged from PH_Elem_C3D13_Sect) ---
  SUBROUTINE PH_Elem_C3D13_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: volume, dV
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 13
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid(1:3) = centroid(1:3) / volume
  END SUBROUTINE PH_Elem_C3D13_GetCentroid

  SUBROUTINE PH_Elem_C3D13_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x = ZERO
      DO k = 1, 13
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
  END SUBROUTINE PH_Elem_C3D13_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D13_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_C3D13_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D13_GetSectProps

  SUBROUTINE PH_Elem_C3D13_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D13_GetVolume

  ! --- Constraints (merged from PH_Elem_C3D13_Constraints) ---
  SUBROUTINE PH_Elem_C3D13_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(39, 39)
    REAL(wp), INTENT(INOUT) :: F_el(39)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 39) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D13_ApplyConstraint

  SUBROUTINE PH_Elem_C3D13_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(39)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(39, 39)
    REAL(wp), INTENT(INOUT) :: F_el(39)
    INTEGER(i4) :: i, j
    DO i = 1, 39
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 39
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D13_ApplyMPC

  ! --- Cont (merged from PH_Elem_C3D13_Cont) ---
  SUBROUTINE PH_Elem_C3D13_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(13)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(39, 39)
    REAL(wp), INTENT(INOUT) :: F_el(39)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib, i, j
    DO a = 1, 13
      ia = 3 * (a - 1) + 1
      f_a(1:3) = penalty * gap * N(a) * n(1:3)
      F_el(ia:ia+2) = F_el(ia:ia+2) + f_a(1:3)
    END DO
    DO a = 1, 13
      DO b = 1, 13
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
  END SUBROUTINE PH_Elem_C3D13_FormContactContrib

  SUBROUTINE PH_Elem_C3D13_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(39, 39)
    REAL(wp), INTENT(INOUT) :: F_el(39)
    REAL(wp) :: xi, eta, zeta, N(13), n(3), dNdxi(3, 13)
    REAL(wp) :: r1(3), r2(3)
    INTEGER(i4) :: nodes(4), i, nnode_face
    IF (face_id < 1 .OR. face_id > 5) RETURN
    nodes(1:4) = PH_ELEM_C3D13_FACE_NODES(1:4, face_id)
    nnode_face = 3
    IF (nodes(4) /= 0) nnode_face = 4
    IF (nnode_face == 3) THEN
      ! Lateral triangle: approximate interior parametric sample
      xi = ZERO
      eta = ZERO
      zeta = HALF
    ELSE
      ! Base quadrilateral: center of base (zeta=0)
      xi = ZERO
      eta = ZERO
      zeta = ZERO
    END IF
    CALL PH_Elem_C3D13_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r1(1:3) = coords(1:3, nodes(2)) - coords(1:3, nodes(1))
    r2(1:3) = coords(1:3, nodes(nnode_face)) - coords(1:3, nodes(1))
    n(1) = r1(2)*r2(3) - r1(3)*r2(2)
    n(2) = r1(3)*r2(1) - r1(1)*r2(3)
    n(3) = r1(1)*r2(2) - r1(2)*r2(1)
    IF (face_id == 1) n = -n
    IF (SUM(n**2) > 1.0e-20_wp) n = n / SQRT(SUM(n**2))
    CALL PH_Elem_C3D13_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D13_FormContactFaceCtr

  ! --- Loads (merged from PH_Elem_C3D13_Loads) ---
  SUBROUTINE PH_Elem_C3D13_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(39)
    REAL(wp) :: n(3), area
    INTEGER(i4) :: nodes(4), i, j, nnode_face
    F_eq = ZERO
    IF (face_id < 1 .OR. face_id > 5) RETURN
    nodes(1:4) = PH_ELEM_C3D13_FACE_NODES(1:4, face_id)
    nnode_face = 3
    IF (nodes(4) /= 0) nnode_face = 4
    IF (nnode_face == 3) THEN
      n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1)))
      n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1)))
      n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1)))
      area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
      IF (area < 1.0e-15_wp) RETURN
      n = n / (2.0_wp * area)
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
      IF (face_id == 1) n = -n
      DO j = 1, 4
        i = nodes(j)
        F_eq(3*i-2:3*i) = F_eq(3*i-2:3*i) + (p * area / 4.0_wp) * n(1:3)
      END DO
    END IF
  END SUBROUTINE PH_Elem_C3D13_FormFacePressure

  SUBROUTINE PH_Elem_C3D13_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(39)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(13), dNdxi(3, 13), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D13_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D13_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D13_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 13
        F_eq(3*i-2) = F_eq(3*i-2) + N(i) * bx * detJ * weights(ip)
        F_eq(3*i-1) = F_eq(3*i-1) + N(i) * by * detJ * weights(ip)
        F_eq(3*i)   = F_eq(3*i)   + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D13_FormBodyForce

  SUBROUTINE PH_Elem_C3D13_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 13)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(39)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D13_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D13_FormFacePressure(coords, val(1), face_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D13_FormNodalForce

  ! --- Out (merged from PH_Elem_C3D13_Out) ---
  SUBROUTINE PH_Elem_C3D13_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :), ip_strain(:, :), ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    INTEGER(i4), PARAMETER :: PH_ELEM_N_IP = 8
    nv = 13
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, PH_ELEM_N_IP)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 6) out_vars(1:6, ip) = ip_stress(1:6, ip)
      IF (SIZE(ip_strain, 1) >= 6) out_vars(7:12, ip) = ip_strain(1:6, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(13, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D13_CollectIPVars

  SUBROUTINE PH_Elem_C3D13_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_C3D13_EvalPrincStress

  SUBROUTINE PH_Elem_C3D13_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e
    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (SUM(edev(1:3)*edev(1:3)) + 2.0_wp*(edev(4)**2+edev(5)**2+edev(6)**2))
  END SUBROUTINE PH_Elem_C3D13_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D13_EvalStressInvar(sigma, I1, J2, J3)
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
  END SUBROUTINE PH_Elem_C3D13_EvalStressInvar

  SUBROUTINE PH_Elem_C3D13_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax
    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D13_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    triax = MERGE(p / seq, ZERO, seq > 1.0e-20_wp)
  END SUBROUTINE PH_Elem_C3D13_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D13_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s1, s2, s3, p, J2
    s1 = sigma(1)
    s2 = sigma(2)
    s3 = sigma(3)
    p = (s1 + s2 + s3) / 3.0_wp
    J2 = HALF * ((s1-p)**2 + (s2-p)**2 + (s3-p)**2) + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D13_EvalVonMises

  SUBROUTINE PH_Elem_C3D13_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(6, 6)
    E = ZERO
    E(1, 1) = ONE
    E(2, 2) = ONE
    E(3, 3) = ONE
    E(4, 4) = ONE
    E(5, 5) = ONE
    E(6, 6) = ONE
  END SUBROUTINE PH_Elem_C3D13_GetExtrapMat

  SUBROUTINE PH_Elem_C3D13_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :), weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    INTEGER(i4) :: ic, i, n_comp
    INTEGER(i4), PARAMETER :: PH_ELEM_N_NODE = 13
    node_vars = ZERO
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, PH_ELEM_N_NODE
        IF (SIZE(ip_vars, 1) >= 1) node_vars(i, ic) = ip_vars(1, ic)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D13_MapToNode

  SUBROUTINE PH_Elem_C3D13_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_C3D13_Material_Update_Routed

END MODULE PH_Elem_C3D13


