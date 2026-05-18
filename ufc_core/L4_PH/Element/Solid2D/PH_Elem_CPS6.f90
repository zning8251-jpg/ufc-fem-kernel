!===============================================================================
! MODULE: PH_Elem_CPS6
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CPS6 element definition (6-node plane stress triangle)
!===============================================================================
MODULE PH_Elem_CPS6
!> [CORE] CPS6 plane stress quadratic triangle (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE

  ! Constants
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_NNODE  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_NIP    = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_NDOF   = 12_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_NEDGE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_EDGE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS6_FACE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  !=============================================================================
  ! STRUCTURED TYPES
  !=============================================================================

  TYPE, PUBLIC :: PH_Elem_CPS6_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_ShapeFunc_Arg



  TYPE, PUBLIC :: PH_Elem_CPS6_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Jac_Arg



  TYPE, PUBLIC :: PH_Elem_CPS6_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_BMatrix_Arg



  TYPE, PUBLIC :: PH_Elem_CPS6_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_JacB_Arg



  TYPE, PUBLIC :: PH_Elem_CPS6_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Strain_Arg



  TYPE, PUBLIC :: PH_Elem_CPS6_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Stress_Arg


  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_CPS6_DefInit
  PUBLIC :: PH_Elem_CPS6_ShapeFunc_Arg
  PUBLIC :: PH_Elem_CPS6_ShapeFunc
  PUBLIC :: PH_Elem_CPS6_Jac_Arg
  PUBLIC :: PH_Elem_CPS6_Jac
  PUBLIC :: PH_Elem_CPS6_BMatrix_Arg
  PUBLIC :: PH_Elem_CPS6_BMatrix
  PUBLIC :: PH_Elem_CPS6_JacB_Arg
  PUBLIC :: PH_Elem_CPS6_JacB
  PUBLIC :: PH_Elem_CPS6_Strain_Arg
  PUBLIC :: PH_Elem_CPS6_Strain
  PUBLIC :: PH_Elem_CPS6_Stress_Arg
  PUBLIC :: PH_Elem_CPS6_Stress
  PUBLIC :: PH_Elem_CPS6_FormStiffMatrix
  PUBLIC :: PH_Elem_CPS6_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_CPS6_NL_TL
  PUBLIC :: PH_Elem_CPS6_NL_UL
  PUBLIC :: PH_Elem_CPS6_GaussPoints
  PUBLIC :: PH_Elem_CPS6_ConstMatrix
  PUBLIC :: PH_Elem_CPS6_FormIntForce
  PUBLIC :: PH_Elem_CPS6_FormIntForceFromStress
  PUBLIC :: PH_Elem_CPS6_ConsMass
  PUBLIC :: PH_Elem_CPS6_LumpMass
  PUBLIC :: PH_Elem_CPS6_ThermStrainVector
  PUBLIC :: PH_Elem_CPS6_GetArea
  PUBLIC :: PH_Elem_CPS6_GetCentroid
  PUBLIC :: PH_Elem_CPS6_GetSectProps
  PUBLIC :: PH_Elem_CPS6_ApplyConstraint
  PUBLIC :: PH_Elem_CPS6_ApplyMPC
  PUBLIC :: PH_Elem_CPS6_FormContactContrib
  PUBLIC :: PH_Elem_CPS6_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CPS6_FormNodalForce
  PUBLIC :: PH_Elem_CPS6_FormBodyForce
  PUBLIC :: PH_Elem_CPS6_FormEdgePressure
  PUBLIC :: PH_Elem_CPS6_CollectIPVars
  PUBLIC :: PH_Elem_CPS6_MapToNode
  PUBLIC :: PH_Elem_CPS6_GetExtrapMat
  PUBLIC :: PH_Elem_CPS6_EvalVonMises
  PUBLIC :: PH_Elem_CPS6_EvalPrincStress
  PUBLIC :: PH_Elem_CPS6_EvalStressInvar
  PUBLIC :: PH_Elem_CPS6_Material_Update_Routed
  PUBLIC :: PH_ELEM_CPS6_NNODE, PH_ELEM_CPS6_NIP, PH_ELEM_CPS6_NDOF, PH_ELEM_CPS6_NEDGE
  PUBLIC :: PH_ELEM_CPS6_EDGE_NODES, PH_ELEM_CPS6_FACE_NODES, PH_ELEM_GAUSS_PT

  ! Generic interfaces for legacy + structured
  INTERFACE PH_Elem_CPS6_ShapeFunc
    MODULE PROCEDURE PH_Elem_CPS6_ShapeFunc_Legacy
    MODULE PROCEDURE PH_Elem_CPS6_ShapeFunc_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS6_Jac
    MODULE PROCEDURE PH_Elem_CPS6_Jac_Legacy
    MODULE PROCEDURE PH_Elem_CPS6_Jac_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS6_JacB
    MODULE PROCEDURE PH_Elem_CPS6_JacB_Legacy
    MODULE PROCEDURE PH_Elem_CPS6_JacB_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS6_Strain
    MODULE PROCEDURE PH_Elem_CPS6_Strain_Legacy
    MODULE PROCEDURE PH_Elem_CPS6_Strain_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS6_Stress
    MODULE PROCEDURE PH_Elem_CPS6_Stress_Legacy
    MODULE PROCEDURE PH_Elem_CPS6_Stress_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS6_NL_TL
    MODULE PROCEDURE PH_Elem_CPS6_NL_TL_Legacy
  END INTERFACE

  INTERFACE PH_Elem_CPS6_NL_UL
    MODULE PROCEDURE PH_Elem_CPS6_NL_UL_Legacy
  END INTERFACE

CONTAINS

  !=============================================================================
  ! LEGACY WRAPPERS
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(6)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 6)
    TYPE(PH_Elem_CPS6_ShapeFunc_Arg) :: in
    TYPE(PH_Elem_CPS6_ShapeFunc_Arg) :: out
    in%xi = xi
    in%eta = eta
    CALL PH_Elem_CPS6_ShapeFunc_InOut(arg)
    N = out%N
    dNdxi = out%dNdxi
  END SUBROUTINE PH_Elem_CPS6_ShapeFunc_Legacy

  SUBROUTINE PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 6)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(PH_Elem_CPS6_Jac_Arg) :: in
    TYPE(PH_Elem_CPS6_Jac_Arg) :: out
    in%dNdxi = dNdxi
    in%coords = coords
    CALL PH_Elem_CPS6_Jac_InOut(arg)
    J = out%J
    detJ = out%detJ
  END SUBROUTINE PH_Elem_CPS6_Jac_Legacy

  SUBROUTINE PH_Elem_CPS6_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(6)
    REAL(wp), INTENT(OUT) :: dNdx(2, 6)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(3, 12)
    TYPE(PH_Elem_CPS6_JacB_Arg) :: in
    TYPE(PH_Elem_CPS6_JacB_Arg) :: out
    in%coords = coords
    in%xi = xi_pt
    in%eta = eta_pt
    CALL PH_Elem_CPS6_JacB_InOut(arg)
    N = out%N
    dNdx = out%dNdx
    J = out%J
    detJ = out%detJ
    B = out%B
  END SUBROUTINE PH_Elem_CPS6_JacB_Legacy

  SUBROUTINE PH_Elem_CPS6_Strain_Legacy(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(3, 12)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(OUT) :: strain(3)
    TYPE(PH_Elem_CPS6_Strain_Arg) :: in
    TYPE(PH_Elem_CPS6_Strain_Arg) :: out
    in%B = B
    in%u = u
    CALL PH_Elem_CPS6_Strain_InOut(arg)
    strain = out%strain
  END SUBROUTINE PH_Elem_CPS6_Strain_Legacy

  SUBROUTINE PH_Elem_CPS6_Stress_Legacy(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(3)
    REAL(wp), INTENT(IN)  :: D(3, 3)
    REAL(wp), INTENT(OUT) :: sigma(3)
    TYPE(PH_Elem_CPS6_Stress_Arg) :: in
    TYPE(PH_Elem_CPS6_Stress_Arg) :: out
    in%epsilon = epsilon
    in%D = D
    CALL PH_Elem_CPS6_Stress_InOut(arg)
    sigma = out%sigma
  END SUBROUTINE PH_Elem_CPS6_Stress_Legacy

  !=============================================================================
  ! DEFINITION (core)
  !=============================================================================
  SUBROUTINE PH_ELEM_CPS6_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CPS6_AreaInt

  SUBROUTINE PH_Elem_CPS6_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(3)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = ZERO
  END SUBROUTINE PH_Elem_CPS6_ThermStrainVector

  SUBROUTINE PH_Elem_CPS6_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(2, 6)
    REAL(wp), INTENT(OUT) :: B(3, 12)
    INTEGER(i4) :: i
    B = ZERO
    DO i = 1, 6
      B(1, 2*i-1) = dNdx(1, i)
      B(2, 2*i)   = dNdx(2, i)
      B(3, 2*i-1) = dNdx(2, i)
      B(3, 2*i)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_CPS6_BMatrix

  SUBROUTINE PH_Elem_CPS6_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: D(3, 3)
    REAL(wp) :: c
    D = ZERO
    c = E_young / (ONE - nu*nu)
    D(1, 1) = c
    D(1, 2) = c * nu
    D(2, 1) = c * nu
    D(2, 2) = c
    D(3, 3) = E_young / (2.0_wp * (ONE + nu))
  END SUBROUTINE PH_Elem_CPS6_ConstMatrix

  SUBROUTINE PH_Elem_CPS6_DefInit()
  END SUBROUTINE PH_Elem_CPS6_DefInit

  SUBROUTINE PH_Elem_CPS6_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: u(12)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), B(3, 12), D(3, 3), strain(3), sigma(3), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPS6_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_Elem_CPS6_Strain_Legacy(B, u, strain)
      CALL PH_Elem_CPS6_Stress_Legacy(strain, D, sigma)
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormIntForce

  SUBROUTINE PH_Elem_CPS6_FormIntForceFromStress(coords, sigma3, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: sigma3(3)
    REAL(wp), INTENT(OUT) :: R_int(12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), B(3, 12), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma3) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormIntForceFromStress

  SUBROUTINE PH_Elem_CPS6_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), B(3, 12), D(3, 3), detJ
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CPS6_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + MATMUL(MATMUL(TRANSPOSE(B), D), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormStiffMatrix

  SUBROUTINE PH_Elem_CPS6_FormStiffMatrixFromD(coords, D3, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: D3(3, 3)
    REAL(wp), INTENT(OUT) :: Ke(12, 12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdx(2, 6), J(2, 2), B(3, 12), detJ
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke = Ke + MATMUL(MATMUL(TRANSPOSE(B), D3), B) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(3), eta(3), weights(3)
    REAL(wp), PARAMETER :: w6 = 1.0_wp / 6.0_wp
    REAL(wp), PARAMETER :: s16 = 1.0_wp / 6.0_wp
    REAL(wp), PARAMETER :: s23 = 2.0_wp / 3.0_wp
    xi(1) = s16
    eta(1) = s16
    weights(1) = w6
    xi(2) = s23
    eta(2) = s16
    weights(2) = w6
    xi(3) = s16
    eta(3) = s23
    weights(3) = w6
  END SUBROUTINE PH_Elem_CPS6_GaussPoints

  SUBROUTINE PH_Elem_CPS6_ShapeFunc_InOut(arg)
    TYPE(PH_Elem_CPS6_ShapeFunc_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: L1, L2, L3, dL1dxi, dL1deta, dL2dxi, dL2deta, dL3dxi, dL3deta
    CALL init_error_status(arg%status)
    L1 = ONE - arg%xi - arg%eta
    L2 = arg%xi
    L3 = arg%eta
    dL1dxi = -ONE
    dL1deta = -ONE
    dL2dxi = ONE
    dL2deta = ZERO
    dL3dxi = ZERO
    dL3deta = ONE
    arg%N(1) = L1 * (2.0_wp*L1 - ONE)
    arg%N(2) = L2 * (2.0_wp*L2 - ONE)
    arg%N(3) = L3 * (2.0_wp*L3 - ONE)
    arg%N(4) = 4.0_wp * L1 * L2
    arg%N(5) = 4.0_wp * L2 * L3
    arg%N(6) = 4.0_wp * L3 * L1
    arg%dNdxi(1, 1) = (4.0_wp*L1 - ONE) * dL1dxi
    arg%dNdxi(2, 1) = (4.0_wp*L1 - ONE) * dL1deta
    arg%dNdxi(1, 2) = (4.0_wp*L2 - ONE) * dL2dxi
    arg%dNdxi(2, 2) = (4.0_wp*L2 - ONE) * dL2deta
    arg%dNdxi(1, 3) = (4.0_wp*L3 - ONE) * dL3dxi
    arg%dNdxi(2, 3) = (4.0_wp*L3 - ONE) * dL3deta
    arg%dNdxi(1, 4) = 4.0_wp * (dL1dxi*L2 + L1*dL2dxi)
    arg%dNdxi(2, 4) = 4.0_wp * (dL1deta*L2 + L1*dL2deta)
    arg%dNdxi(1, 5) = 4.0_wp * (dL2dxi*L3 + L2*dL3dxi)
    arg%dNdxi(2, 5) = 4.0_wp * (dL2deta*L3 + L2*dL3deta)
    arg%dNdxi(1, 6) = 4.0_wp * (dL3dxi*L1 + L3*dL1dxi)
    arg%dNdxi(2, 6) = 4.0_wp * (dL3deta*L1 + L3*dL1deta)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS6_ShapeFunc_InOut

  SUBROUTINE PH_Elem_CPS6_Jac_InOut(arg)
    TYPE(PH_Elem_CPS6_Jac_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%J = ZERO
    DO i = 1, 6
      arg%J(1, 1) = arg%J(1, 1) + arg%dNdxi(1, i) * arg%coords(1, i)
      arg%J(1, 2) = arg%J(1, 2) + arg%dNdxi(1, i) * arg%coords(2, i)
      arg%J(2, 1) = arg%J(2, 1) + arg%dNdxi(2, i) * arg%coords(1, i)
      arg%J(2, 2) = arg%J(2, 2) + arg%dNdxi(2, i) * arg%coords(2, i)
    END DO
    arg%detJ = arg%J(1, 1) * arg%J(2, 2) - arg%J(1, 2) * arg%J(2, 1)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS6_Jac_InOut

  SUBROUTINE PH_Elem_CPS6_JacB_InOut(arg)
    TYPE(PH_Elem_CPS6_JacB_Arg), INTENT(INOUT) :: arg
    TYPE(PH_Elem_CPS6_ShapeFunc_Arg) :: sf
    TYPE(PH_Elem_CPS6_Jac_Arg) :: jac
    REAL(wp) :: dNdxi(2, 6), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    sf%xi = arg%xi
    sf%eta = arg%eta
    CALL PH_Elem_CPS6_ShapeFunc_InOut(sf)
    IF (sf%status%status_code /= IF_STATUS_OK) THEN
      arg%status = sf%status
      RETURN
    END IF
    arg%N = sf%N
    dNdxi = sf%dNdxi
    jac%dNdxi = dNdxi
    jac%coords = arg%coords
    CALL PH_Elem_CPS6_Jac_InOut(jac)
    IF (jac%status%status_code /= IF_STATUS_OK) THEN
      arg%status = jac%status
      RETURN
    END IF
    arg%J = jac%J
    arg%detJ = jac%detJ
    IF (ABS(arg%detJ) > 1.0e-20_wp) THEN
      Jinv(1, 1) =  arg%J(2, 2) / arg%detJ
      Jinv(1, 2) = -arg%J(1, 2) / arg%detJ
      Jinv(2, 1) = -arg%J(2, 1) / arg%detJ
      Jinv(2, 2) =  arg%J(1, 1) / arg%detJ
      DO i = 1, 6
        arg%dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        arg%dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      CALL PH_Elem_CPS6_BMatrix(arg%dNdx, arg%B)
    ELSE
      arg%dNdx = ZERO
      arg%B = ZERO
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS6_JacB_InOut

  SUBROUTINE PH_Elem_CPS6_Strain_InOut(arg)
    TYPE(PH_Elem_CPS6_Strain_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%strain = ZERO
    DO j = 1, 12
      arg%strain(1) = arg%strain(1) + arg%B(1, j) * arg%u(j)
      arg%strain(2) = arg%strain(2) + arg%B(2, j) * arg%u(j)
      arg%strain(3) = arg%strain(3) + arg%B(3, j) * arg%u(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS6_Strain_InOut

  SUBROUTINE PH_Elem_CPS6_Stress_InOut(arg)
    TYPE(PH_Elem_CPS6_Stress_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%sigma = ZERO
    DO j = 1, 3
      arg%sigma(1) = arg%sigma(1) + arg%D(1, j) * arg%epsilon(j)
      arg%sigma(2) = arg%sigma(2) + arg%D(2, j) * arg%epsilon(j)
      arg%sigma(3) = arg%sigma(3) + arg%D(3, j) * arg%epsilon(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS6_Stress_InOut

  SUBROUTINE PH_Elem_CPS6_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(12, 12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 6
        DO j = 1, 6
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * N(i)*N(j) * detJ * weights(ip)
          Me(2*i,   2*j)   = Me(2*i,   2*j)   + rho * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS6_ConsMass

  SUBROUTINE PH_Elem_CPS6_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(12)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CPS6_AreaInt(coords, area)
    m = rho * area / 6.0_wp
    DO i = 1, 6
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CPS6_LumpMass

  !=============================================================================
  ! NL_TL / NL_UL - Legacy (for RT_AsmNLGeomDispatch)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 6)
    REAL(wp), INTENT(IN) :: u_elem(12)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12)
    REAL(wp), INTENT(OUT) :: Ke_geo(12, 12)
    REAL(wp), INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 6)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(6), dN_dxi(2, 6), dN_dX(2, 6)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt(3), S_voigt(3)
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(12, 12), K_geo_gp(12, 12), R_gp(12)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    DO i = 1, 6
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*(i-1)+2)
    END DO
    CALL PH_Elem_CPS6_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 1
    DO i = 1, 6
      cfg%coords_ref(i, 1:2) = coords_ref(1:2, i)
      cfg%coords_ref(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO
    D6 = ZERO
    D6(1:3, 1:3) = D(1:3, 1:3)
    DO igp = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_ref = ZERO
      DO i = 1, 6
        J_ref(1, 1) = J_ref(1, 1) + dN_dxi(1, i) * coords_ref(1, i)
        J_ref(1, 2) = J_ref(1, 2) + dN_dxi(1, i) * coords_ref(2, i)
        J_ref(2, 1) = J_ref(2, 1) + dN_dxi(2, i) * coords_ref(1, i)
        J_ref(2, 2) = J_ref(2, 2) + dN_dxi(2, i) * coords_ref(2, i)
      END DO
      det_J = J_ref(1, 1)*J_ref(2, 2) - J_ref(1, 2)*J_ref(2, 1)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
      J_inv(1,1) =  J_ref(2,2) / det_J
      J_inv(1,2) = -J_ref(1,2) / det_J
      J_inv(2,1) = -J_ref(2,1) / det_J
      J_inv(2,2) =  J_ref(1,1) / det_J
      DO i = 1, 6
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO
      DO i = 1, 6
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
        cfg%lcl%dN_dX(i, 3) = ZERO
      END DO
      F = ZERO
      F(3, 3) = ONE
      DO i = 1, 6
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dX(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dX(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dX(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dX(2, i)
      END DO
      E(1,1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) - ONE)
      E(2,2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) - ONE)
      E(1,2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2))
      E(2,1) = E(1,2)
      E(3,3) = ZERO
      E_voigt(1) = E(1,1)
      E_voigt(2) = E(2,2)
      E_voigt(3) = 2.0_wp * E(1,2)
      S_voigt = MATMUL(D, E_voigt)
      S(1,1) = S_voigt(1)
      S(2,2) = S_voigt(2)
      S(1,2) = S_voigt(3)
      S(2,1) = S_voigt(3)
      S(3,3) = ZERO
      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, D6)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CPS6_NL_TL_Legacy

  SUBROUTINE PH_Elem_CPS6_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 6)
    REAL(wp), INTENT(IN) :: u_incr(12)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12)
    REAL(wp), INTENT(OUT) :: Ke_geo(12, 12)
    REAL(wp), INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 6)
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(6), dN_dxi(2, 6), dN_dx(2, 6)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(3, 3), eps(3, 3), sigma(3, 3)
    REAL(wp) :: eps_voigt(3), sigma_voigt(3)
    REAL(wp) :: b(2,2), b_inv(2,2), det_b
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(12, 12), K_geo_gp(12, 12), R_gp(12)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    DO i = 1, 6
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*(i-1)+2)
    END DO
    CALL PH_Elem_CPS6_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 2
    DO i = 1, 6
      cfg%coords_prev(i, 1:2) = coords_prev(1:2, i)
      cfg%coords_prev(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO
    D6 = ZERO
    D6(1:3, 1:3) = D(1:3, 1:3)
    DO igp = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_prev = ZERO
      DO i = 1, 6
        J_prev(1, 1) = J_prev(1, 1) + dN_dxi(1, i) * coords_prev(1, i)
        J_prev(1, 2) = J_prev(1, 2) + dN_dxi(1, i) * coords_prev(2, i)
        J_prev(2, 1) = J_prev(2, 1) + dN_dxi(2, i) * coords_prev(1, i)
        J_prev(2, 2) = J_prev(2, 2) + dN_dxi(2, i) * coords_prev(2, i)
      END DO
      det_J = J_prev(1, 1)*J_prev(2, 2) - J_prev(1, 2)*J_prev(2, 1)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
      J_inv(1,1) =  J_prev(2,2) / det_J
      J_inv(1,2) = -J_prev(1,2) / det_J
      J_inv(2,1) = -J_prev(2,1) / det_J
      J_inv(2,2) =  J_prev(1,1) / det_J
      DO i = 1, 6
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO
      DO i = 1, 6
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
        cfg%dN_dx(i, 3) = ZERO
      END DO
      F = ZERO
      F(3, 3) = ONE
      DO i = 1, 6
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dx(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dx(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dx(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dx(2, i)
      END DO
      b = MATMUL(F(1:2,1:2), TRANSPOSE(F(1:2,1:2)))
      det_b = b(1,1)*b(2,2) - b(1,2)*b(2,1)
      IF (ABS(det_b) <= 1.0e-14_wp) CYCLE
      b_inv(1,1) =  b(2,2) / det_b
      b_inv(1,2) = -b(1,2) / det_b
      b_inv(2,1) = -b(2,1) / det_b
      b_inv(2,2) =  b(1,1) / det_b
      eps(1,1) = HALF * (ONE - b_inv(1,1))
      eps(2,2) = HALF * (ONE - b_inv(2,2))
      eps(1,2) = -HALF * b_inv(1,2)
      eps(2,1) = eps(1,2)
      eps(3,3) = ZERO
      eps_voigt(1) = eps(1,1)
      eps_voigt(2) = eps(2,2)
      eps_voigt(3) = 2.0_wp * eps(1,2)
      sigma_voigt = MATMUL(D, eps_voigt)
      sigma(1,1) = sigma_voigt(1)
      sigma(2,2) = sigma_voigt(2)
      sigma(1,2) = sigma_voigt(3)
      sigma(2,1) = sigma_voigt(3)
      sigma(3,3) = ZERO
      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, eps, sigma, K_mat_gp, K_geo_gp, status, R_gp, D6)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  END SUBROUTINE PH_Elem_CPS6_NL_UL_Legacy

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_CPS6_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_CPS6_GetArea

  SUBROUTINE PH_Elem_CPS6_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 2
        DO j = 1, 6
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
    END IF
  END SUBROUTINE PH_Elem_CPS6_GetCentroid

  SUBROUTINE PH_Elem_CPS6_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CPS6_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_CPS6_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CPS6_ApplyConstraint

  SUBROUTINE PH_Elem_CPS6_ApplyMPC(c, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CPS6_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(6)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(INOUT) :: K_el(12, 12)
    REAL(wp), INTENT(INOUT) :: F_el(12)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 6
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 6
      DO b = 1, 6
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormContactContrib

  SUBROUTINE PH_Elem_CPS6_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(12, 12)
    REAL(wp), INTENT(OUT) :: F_el(12)
    REAL(wp) :: xi, eta, N(6), n(2), dNdxi(2, 6)
    REAL(wp) :: t(2), len
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CPS6_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPS6_EDGE_NODES(2, edge_id)
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
    CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CPS6_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_CPS6_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS6_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(12)
    REAL(wp) :: t(2), len, nx, ny, f3
    INTEGER(i4) :: n1, n2, nmid, ia
    INTEGER(i4), PARAMETER :: EDGE_MID(3) = [4, 5, 6]
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CPS6_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPS6_EDGE_NODES(2, edge_id)
    nmid = EDGE_MID(edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    nx = -t(2) / len
    ny =  t(1) / len
    f3 = p * len / 3.0_wp
    ia = 2 * n1 - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nx
    F_eq(ia+1) = F_eq(ia+1) + f3 * ny
    ia = 2 * n2 - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nx
    F_eq(ia+1) = F_eq(ia+1) + f3 * ny
    ia = 2 * nmid - 1
    F_eq(ia)   = F_eq(ia)   + f3 * nx
    F_eq(ia+1) = F_eq(ia+1) + f3 * ny
  END SUBROUTINE PH_Elem_CPS6_FormEdgePressure

  SUBROUTINE PH_Elem_CPS6_FormBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(12)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 6
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * bx * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * by * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS6_FormBodyForce

  SUBROUTINE PH_Elem_CPS6_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 6)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(12)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CPS6_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPS6_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CPS6_FormNodalForce

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

  SUBROUTINE PH_Elem_CPS6_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
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
  END SUBROUTINE PH_Elem_CPS6_CollectIPVars

  SUBROUTINE PH_Elem_CPS6_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_CPS6_EvalPrincStress

  SUBROUTINE PH_Elem_CPS6_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdev11, sdev22
    I1 = sigma(1) + sigma(2)
    p = I1 / 2.0_wp
    sdev11 = sigma(1) - p
    sdev22 = sigma(2) - p
    J2 = HALF * (sdev11*sdev11 + sdev22*sdev22) + sigma(3)*sigma(3)
  END SUBROUTINE PH_Elem_CPS6_EvalStressInvar

  SUBROUTINE PH_Elem_CPS6_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s11, s22, s12
    s11 = sigma(1)
    s22 = sigma(2)
    s12 = sigma(3)
    seq = SQRT(s11*s11 + s22*s22 - s11*s22 + 3.0_wp*s12*s12)
  END SUBROUTINE PH_Elem_CPS6_EvalVonMises

  SUBROUTINE PH_Elem_CPS6_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(6, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(6), dNdxi(2, 6)
    REAL(wp) :: A(3, 3)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CPS6_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 3
      CALL PH_Elem_CPS6_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 3
        A(i, ip) = N(i)
      END DO
    END DO
    CALL invert_3x3(A, info)
    IF (info /= 0) THEN
      E = ZERO
      RETURN
    END IF
    E = ZERO
    DO i = 1, 3
      DO ip = 1, 3
        E(i, ip) = A(i, ip)
      END DO
    END DO
    E(4, :) = HALF * (E(1, :) + E(2, :))
    E(5, :) = HALF * (E(2, :) + E(3, :))
    E(6, :) = HALF * (E(3, :) + E(1, :))
  END SUBROUTINE PH_Elem_CPS6_GetExtrapMat

  SUBROUTINE PH_Elem_CPS6_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(6, 3)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CPS6_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 6
        DO j = 1, 3
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS6_MapToNode

  SUBROUTINE PH_Elem_CPS6_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                 stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticPlaneStress

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dStrain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_CPS6_Material_Update_Routed

END MODULE PH_Elem_CPS6


