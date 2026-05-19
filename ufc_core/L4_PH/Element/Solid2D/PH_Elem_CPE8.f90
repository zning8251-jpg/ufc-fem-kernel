!===============================================================================
! MODULE: PH_Elem_CPE8
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CPE8 element definition (8-node plane strain Serendipity)
!===============================================================================
MODULE PH_Elem_CPE8
!> [CORE] CPE8 plane strain Serendipity quad (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
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
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_NNODE  = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_NIP   = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_NDOF  = 16_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  ! For CPE8P: face = edge in 2D quad
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE8_FACE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  !=============================================================================
  ! STRUCTURED TYPES (for structured interfaces)
  !=============================================================================

  TYPE, PUBLIC :: PH_Elem_CPE8_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_ShapeFunc_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Jac_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_BMatrix_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_JacB_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Strain_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Stress_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_StiffMatrix_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_NL_TL_Arg



  TYPE, PUBLIC :: PH_Elem_CPE8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_NL_UL_Arg


  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_CPE8_DefInit
  PUBLIC :: PH_Elem_CPE8_ShapeFunc_Arg
  PUBLIC :: PH_Elem_CPE8_ShapeFunc
  PUBLIC :: PH_Elem_CPE8_Jac_Arg
  PUBLIC :: PH_Elem_CPE8_Jac
  PUBLIC :: PH_Elem_CPE8_BMatrix_Arg
  PUBLIC :: PH_Elem_CPE8_BMatrix
  PUBLIC :: PH_Elem_CPE8_JacB_Arg
  PUBLIC :: PH_Elem_CPE8_JacB
  PUBLIC :: PH_Elem_CPE8_Strain_Arg
  PUBLIC :: PH_Elem_CPE8_Strain
  PUBLIC :: PH_Elem_CPE8_Stress_Arg
  PUBLIC :: PH_Elem_CPE8_Stress
  PUBLIC :: PH_Elem_CPE8_StiffMatrix_Arg
  PUBLIC :: PH_Elem_CPE8_FormStiffMatrix
  PUBLIC :: PH_Elem_CPE8_NL_TL_Arg
  PUBLIC :: PH_Elem_CPE8_NL_TL
  PUBLIC :: PH_Elem_CPE8_NL_UL_Arg
  PUBLIC :: PH_Elem_CPE8_NL_UL
  PUBLIC :: PH_Elem_CPE8_GaussPoints
  PUBLIC :: PH_Elem_CPE8_ConstMatrix
  PUBLIC :: PH_Elem_CPE8_FormIntForce
  PUBLIC :: PH_Elem_CPE8_FormIntForceFromStress
  PUBLIC :: PH_Elem_CPE8_StiffMatrix
  PUBLIC :: PH_Elem_CPE8_ConsMass
  PUBLIC :: PH_Elem_CPE8_LumpMass
  PUBLIC :: PH_Elem_CPE8_ThermStrainVector
  PUBLIC :: PH_Elem_CPE8_GetArea
  PUBLIC :: PH_Elem_CPE8_GetCentroid
  PUBLIC :: PH_Elem_CPE8_GetSectProps
  PUBLIC :: PH_Elem_CPE8_ApplyConstraint
  PUBLIC :: PH_Elem_CPE8_ApplyMPC
  PUBLIC :: PH_Elem_CPE8_FormContactContrib
  PUBLIC :: PH_Elem_CPE8_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CPE8_FormNodalForce
  PUBLIC :: PH_Elem_CPE8_FormBodyForce
  PUBLIC :: PH_Elem_CPE8_FormEdgePressure
  PUBLIC :: PH_Elem_CPE8_CollectIPVars
  PUBLIC :: PH_Elem_CPE8_MapToNode
  PUBLIC :: PH_Elem_CPE8_GetExtrapMat
  PUBLIC :: PH_Elem_CPE8_EvalVonMises
  PUBLIC :: PH_Elem_CPE8_EvalPrincStress
  PUBLIC :: PH_Elem_CPE8_EvalStressInvar
  PUBLIC :: PH_Elem_CPE8_Material_Update_Routed
  PUBLIC :: PH_ELEM_CPE8_NNODE, PH_ELEM_CPE8_NIP, PH_ELEM_CPE8_NDOF, PH_ELEM_CPE8_NEDGE
  PUBLIC :: PH_ELEM_CPE8_EDGE_NODES, PH_ELEM_CPE8_FACE_NODES, PH_ELEM_GAUSS_PT

  ! Generic interfaces for legacy + structured
  INTERFACE PH_Elem_CPE8_ShapeFunc
    MODULE PROCEDURE PH_Elem_CPE8_ShapeFunc_Legacy
    MODULE PROCEDURE PH_Elem_CPE8_ShapeFunc_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPE8_Jac
    MODULE PROCEDURE PH_Elem_CPE8_Jac_Legacy
    MODULE PROCEDURE PH_Elem_CPE8_Jac_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPE8_JacB
    MODULE PROCEDURE PH_Elem_CPE8_JacB_Legacy
    MODULE PROCEDURE PH_Elem_CPE8_JacB_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPE8_Strain
    MODULE PROCEDURE PH_Elem_CPE8_Strain_Legacy
    MODULE PROCEDURE PH_Elem_CPE8_Strain_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPE8_Stress
    MODULE PROCEDURE PH_Elem_CPE8_Stress_Legacy
    MODULE PROCEDURE PH_Elem_CPE8_Stress_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPE8_NL_TL
    MODULE PROCEDURE PH_Elem_CPE8_NL_TL_Structured
    MODULE PROCEDURE PH_Elem_CPE8_NL_TL_Legacy
  END INTERFACE

  INTERFACE PH_Elem_CPE8_NL_UL
    MODULE PROCEDURE PH_Elem_CPE8_NL_UL_Structured
    MODULE PROCEDURE PH_Elem_CPE8_NL_UL_Legacy
  END INTERFACE

CONTAINS

  !=============================================================================
  ! LEGACY WRAPPERS (for Sect, Loads, Out, Cont)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 8)
    TYPE(PH_Elem_CPE8_ShapeFunc_Arg) :: in
    TYPE(PH_Elem_CPE8_ShapeFunc_Arg) :: out
    in%xi = xi
    in%eta = eta
    CALL PH_Elem_CPE8_ShapeFunc_InOut(arg)
    N = out%N
    dNdxi = out%dNdxi
  END SUBROUTINE PH_Elem_CPE8_ShapeFunc_Legacy

  SUBROUTINE PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 8)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(PH_Elem_CPE8_Jac_Arg) :: in
    TYPE(PH_Elem_CPE8_Jac_Arg) :: out
    in%dNdxi = dNdxi
    in%coords = coords
    CALL PH_Elem_CPE8_Jac_InOut(arg)
    J = out%J
    detJ = out%detJ
  END SUBROUTINE PH_Elem_CPE8_Jac_Legacy

  SUBROUTINE PH_Elem_CPE8_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(8)
    REAL(wp), INTENT(OUT) :: dNdx(2, 8)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(3, 16)
    TYPE(PH_Elem_CPE8_JacB_Arg) :: in
    TYPE(PH_Elem_CPE8_JacB_Arg) :: out
    in%coords = coords
    in%xi = xi_pt
    in%eta = eta_pt
    CALL PH_Elem_CPE8_JacB_InOut(arg)
    N = out%N
    dNdx = out%dNdx
    J = out%J
    detJ = out%detJ
    B = out%B
  END SUBROUTINE PH_Elem_CPE8_JacB_Legacy

  SUBROUTINE PH_Elem_CPE8_Strain_Legacy(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(3, 16)
    REAL(wp), INTENT(IN)  :: u(16)
    REAL(wp), INTENT(OUT) :: strain(3)
    TYPE(PH_Elem_CPE8_Strain_Arg) :: in
    TYPE(PH_Elem_CPE8_Strain_Arg) :: out
    in%B = B
    in%u = u
    CALL PH_Elem_CPE8_Strain_InOut(arg)
    strain = out%strain
  END SUBROUTINE PH_Elem_CPE8_Strain_Legacy

  SUBROUTINE PH_Elem_CPE8_Stress_Legacy(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(3)
    REAL(wp), INTENT(IN)  :: D(3, 3)
    REAL(wp), INTENT(OUT) :: sigma(3)
    TYPE(PH_Elem_CPE8_Stress_Arg) :: in
    TYPE(PH_Elem_CPE8_Stress_Arg) :: out
    in%epsilon = epsilon
    in%D = D
    CALL PH_Elem_CPE8_Stress_InOut(arg)
    sigma = out%sigma
  END SUBROUTINE PH_Elem_CPE8_Stress_Legacy

  !=============================================================================
  ! DEFINITION (core)
  !=============================================================================
  SUBROUTINE PH_ELEM_CPE8_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CPE8_AreaInt

  SUBROUTINE PH_Elem_CPE8_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(3)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = ZERO
  END SUBROUTINE PH_Elem_CPE8_ThermStrainVector

  SUBROUTINE PH_Elem_CPE8_BMatrix(arg)
    TYPE(PH_Elem_CPE8_BMatrix_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%B = ZERO
    DO i = 1, 8
      arg%B(1, 2*i-1) = arg%dNdx(1, i)
      arg%B(2, 2*i)   = arg%dNdx(2, i)
      arg%B(3, 2*i-1) = arg%dNdx(2, i)
      arg%B(3, 2*i)   = arg%dNdx(1, i)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_BMatrix

  SUBROUTINE PH_Elem_CPE8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(16, 16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        DO j = 1, 8
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * N(i)*N(j) * detJ * weights(ip)
          Me(2*i,   2*j)   = Me(2*i,   2*j)   + rho * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE8_ConsMass

  SUBROUTINE PH_Elem_CPE8_ConstMatrix(E_young, nu, D)
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
  END SUBROUTINE PH_Elem_CPE8_ConstMatrix

  SUBROUTINE PH_Elem_CPE8_DefInit()
  END SUBROUTINE PH_Elem_CPE8_DefInit

  SUBROUTINE PH_Elem_CPE8_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: u(16)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(3, 16), D(3, 3), strain(3), sigma(3), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPE8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_Elem_CPE8_Strain_Legacy(B, u, strain)
      CALL PH_Elem_CPE8_Stress_Legacy(strain, D, sigma)
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE8_FormIntForce

  SUBROUTINE PH_Elem_CPE8_FormIntForceFromStress(coords, sigma3, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: sigma3(3)
    REAL(wp), INTENT(OUT) :: R_int(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(3, 16), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma3) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPE8_FormIntForceFromStress

  SUBROUTINE PH_Elem_CPE8_StiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(16, 16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), B(3, 16), D(3, 3)
    REAL(wp) :: BTD(16, 3), detJ, dV
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_CPE8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_CPE8_StiffMatrix

  SUBROUTINE PH_Elem_CPE8_FormStiffMatrix(arg)
    TYPE(PH_Elem_CPE8_StiffMatrix_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: xi(9), eta(9), weights(9)
    TYPE(PH_Elem_CPE8_JacB_Arg) :: jb
    REAL(wp) :: BTD(16, 3), dV
    INTEGER(i4) :: ip
    CALL init_error_status(arg%status)
    arg%evo%Ke = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    jb%coords = arg%coords
    DO ip = 1, 9
      jb%xi = xi(ip)
      jb%eta = eta(ip)
      CALL PH_Elem_CPE8_JacB_InOut(jb)
      IF (jb%status%status_code /= IF_STATUS_OK .OR. ABS(jb%detJ) <= 1.0e-12_wp) CYCLE
      dV = jb%detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(jb%B), arg%D_matrix)
      arg%evo%Ke = arg%evo%Ke + dV * MATMUL(BTD, jb%B)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_FormStiffMatrix

  SUBROUTINE PH_Elem_CPE8_GaussPoints(xi, eta, weights)
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
  END SUBROUTINE PH_Elem_CPE8_GaussPoints

  SUBROUTINE PH_Elem_CPE8_Jac_InOut(arg)
    TYPE(PH_Elem_CPE8_Jac_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%J = ZERO
    DO i = 1, 8
      arg%J(1, 1) = arg%J(1, 1) + arg%dNdxi(1, i) * arg%coords(1, i)
      arg%J(1, 2) = arg%J(1, 2) + arg%dNdxi(1, i) * arg%coords(2, i)
      arg%J(2, 1) = arg%J(2, 1) + arg%dNdxi(2, i) * arg%coords(1, i)
      arg%J(2, 2) = arg%J(2, 2) + arg%dNdxi(2, i) * arg%coords(2, i)
    END DO
    arg%detJ = arg%J(1, 1) * arg%J(2, 2) - arg%J(1, 2) * arg%J(2, 1)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_Jac_InOut

  SUBROUTINE PH_Elem_CPE8_JacB_InOut(arg)
    TYPE(PH_Elem_CPE8_JacB_Arg), INTENT(INOUT) :: arg
    TYPE(PH_Elem_CPE8_ShapeFunc_Arg) :: sf
    TYPE(PH_Elem_CPE8_Jac_Arg) :: jac
    TYPE(PH_Elem_CPE8_BMatrix_Arg) :: bm
    REAL(wp) :: dNdxi(2, 8), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    sf%xi = arg%xi
    sf%eta = arg%eta
    CALL PH_Elem_CPE8_ShapeFunc_InOut(sf)
    IF (sf%status%status_code /= IF_STATUS_OK) THEN
      arg%status = sf%status
      RETURN
    END IF
    arg%N = sf%N
    dNdxi = sf%dNdxi
    jac%dNdxi = dNdxi
    jac%coords = arg%coords
    CALL PH_Elem_CPE8_Jac_InOut(jac)
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
      DO i = 1, 8
        arg%dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        arg%dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      bm%dNdx = arg%dNdx
      CALL PH_Elem_CPE8_BMatrix(bm)
      IF (bm%status%status_code /= IF_STATUS_OK) THEN
        arg%status = bm%status
        RETURN
      END IF
      arg%B = bm%B
    ELSE
      arg%dNdx = ZERO
      arg%B = ZERO
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_JacB_InOut

  SUBROUTINE PH_Elem_CPE8_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(16)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CPE8_AreaInt(coords, area)
    m = rho * area / 8.0_wp
    DO i = 1, 8
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CPE8_LumpMass

  SUBROUTINE PH_Elem_CPE8_ShapeFunc_InOut(arg)
    TYPE(PH_Elem_CPE8_ShapeFunc_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: xi, eta
    CALL init_error_status(arg%status)
    xi = arg%xi
    eta = arg%eta
    ! Serendipity 8-node shape functions
    arg%N(1) = QUARTER * (ONE - xi) * (ONE - eta) * (-ONE - xi - eta)
    arg%N(2) = QUARTER * (ONE + xi) * (ONE - eta) * (-ONE + xi - eta)
    arg%N(3) = QUARTER * (ONE + xi) * (ONE + eta) * (-ONE + xi + eta)
    arg%N(4) = QUARTER * (ONE - xi) * (ONE + eta) * (-ONE - xi + eta)
    arg%N(5) = HALF * (ONE - xi*xi) * (ONE - eta)
    arg%N(6) = HALF * (ONE + xi) * (ONE - eta*eta)
    arg%N(7) = HALF * (ONE - xi*xi) * (ONE + eta)
    arg%N(8) = HALF * (ONE - xi) * (ONE - eta*eta)
    arg%dNdxi(1, 1) = QUARTER * (ONE - eta) * (2.0_wp*xi + eta)
    arg%dNdxi(2, 1) = QUARTER * (ONE - xi) * (2.0_wp*eta + xi)
    arg%dNdxi(1, 2) = QUARTER * (ONE - eta) * (2.0_wp*xi - eta)
    arg%dNdxi(2, 2) = QUARTER * (ONE + xi) * (2.0_wp*eta - xi)
    arg%dNdxi(1, 3) = QUARTER * (ONE + eta) * (2.0_wp*xi + eta)
    arg%dNdxi(2, 3) = QUARTER * (ONE + xi) * (2.0_wp*eta + xi)
    arg%dNdxi(1, 4) = QUARTER * (ONE + eta) * (2.0_wp*xi - eta)
    arg%dNdxi(2, 4) = QUARTER * (ONE - xi) * (2.0_wp*eta - xi)
    arg%dNdxi(1, 5) = -xi * (ONE - eta)
    arg%dNdxi(2, 5) = -HALF * (ONE - xi*xi)
    arg%dNdxi(1, 6) = HALF * (ONE - eta*eta)
    arg%dNdxi(2, 6) = -(ONE + xi) * eta
    arg%dNdxi(1, 7) = -xi * (ONE + eta)
    arg%dNdxi(2, 7) = HALF * (ONE - xi*xi)
    arg%dNdxi(1, 8) = -HALF * (ONE - eta*eta)
    arg%dNdxi(2, 8) = -(ONE - xi) * eta
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_ShapeFunc_InOut

  SUBROUTINE PH_Elem_CPE8_Strain_InOut(arg)
    TYPE(PH_Elem_CPE8_Strain_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%strain = ZERO
    DO j = 1, 16
      arg%strain(1) = arg%strain(1) + arg%B(1, j) * arg%u(j)
      arg%strain(2) = arg%strain(2) + arg%B(2, j) * arg%u(j)
      arg%strain(3) = arg%strain(3) + arg%B(3, j) * arg%u(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_Strain_InOut

  SUBROUTINE PH_Elem_CPE8_Stress_InOut(arg)
    TYPE(PH_Elem_CPE8_Stress_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%sigma = ZERO
    DO j = 1, 3
      arg%sigma(1) = arg%sigma(1) + arg%D(1, j) * arg%epsilon(j)
      arg%sigma(2) = arg%sigma(2) + arg%D(2, j) * arg%epsilon(j)
      arg%sigma(3) = arg%sigma(3) + arg%D(3, j) * arg%epsilon(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPE8_Stress_InOut

  !=============================================================================
  ! NL_TL / NL_UL - Legacy (for RT_AsmNLGeomDispatch) and Structured
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 8)
    REAL(wp), INTENT(IN) :: u_elem(16)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16)
    REAL(wp), INTENT(OUT) :: Ke_geo(16, 16)
    REAL(wp), INTENT(OUT) :: R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 8)
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), dN_dX(2, 8)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt(3), S_voigt(3)
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(16, 16), K_geo_gp(16, 16), R_gp(16)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    DO i = 1, 8
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*(i-1)+2)
    END DO
    CALL PH_Elem_CPE8_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 1
    DO i = 1, 8
      cfg%coords_ref(i, 1:2) = coords_ref(1:2, i)
      cfg%coords_ref(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO
    D6 = ZERO
    D6(1:3, 1:3) = D(1:3, 1:3)
    DO igp = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_ref = ZERO
      DO i = 1, 8
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

  END SUBROUTINE PH_Elem_CPE8_NL_TL_Legacy

  SUBROUTINE PH_Elem_CPE8_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 8)
    REAL(wp), INTENT(IN) :: u_incr(16)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(16, 16)
    REAL(wp), INTENT(OUT) :: Ke_geo(16, 16)
    REAL(wp), INTENT(OUT) :: R_int(16)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: coords_curr(2, 8)
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), dN_dx(2, 8)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(3, 3), eps(3, 3), sigma(3, 3)
    REAL(wp) :: eps_voigt(3), sigma_voigt(3)
    REAL(wp) :: b(2,2), b_inv(2,2), det_b
    REAL(wp) :: D6(6, 6)
    REAL(wp) :: K_mat_gp(16, 16), K_geo_gp(16, 16), R_gp(16)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    DO i = 1, 8
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*(i-1)+2)
    END DO
    CALL PH_Elem_CPE8_GaussPoints(xi_gp, eta_gp, wt_gp)



    cfg%formulation_typ = 2
    DO i = 1, 8
      cfg%coords_prev(i, 1:2) = coords_prev(1:2, i)
      cfg%coords_prev(i, 3) = ZERO
      cfg%coords_curr(i, 1:2) = coords_curr(1:2, i)
      cfg%coords_curr(i, 3) = ZERO
    END DO
    D6 = ZERO
    D6(1:3, 1:3) = D(1:3, 1:3)
    DO igp = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_prev = ZERO
      DO i = 1, 8
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

  END SUBROUTINE PH_Elem_CPE8_NL_UL_Legacy

  ! Structured NL_TL/NL_UL (delegate to legacy with D from mat_prop)
  SUBROUTINE PH_Elem_CPE8_NL_TL_Structured(arg)
    TYPE(PH_Elem_CPE8_NL_TL_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: D(3, 3), E_young, nu
    D = ZERO
    D(1, 1) = ONE
    D(2, 2) = ONE
    D(3, 3) = HALF
    IF (ALLOCATED(arg%mat_prop%props) .AND. SIZE(arg%mat_prop%props) >= 2) THEN
      E_young = arg%mat_prop%props(1)
      nu = arg%mat_prop%props(2)
      CALL PH_Elem_CPE8_ConstMatrix(E_young, nu, D)
    END IF
    CALL PH_Elem_CPE8_NL_TL_Legacy(arg%coords_ref, arg%lcl%u_elem, D, &
      arg%evo%Ke_mat, arg%evo%Ke_geo, arg%evo%R_int, arg%status)
    IF (ALLOCATED(arg%mat_state)) arg%mat_state = arg%mat_state
  END SUBROUTINE PH_Elem_CPE8_NL_TL_Structured

  SUBROUTINE PH_Elem_CPE8_NL_UL_Structured(arg)
    TYPE(PH_Elem_CPE8_NL_UL_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: D(3, 3), E_young, nu
    D = ZERO
    D(1, 1) = ONE
    D(2, 2) = ONE
    D(3, 3) = HALF
    IF (ALLOCATED(arg%mat_prop%props) .AND. SIZE(arg%mat_prop%props) >= 2) THEN
      E_young = arg%mat_prop%props(1)
      nu = arg%mat_prop%props(2)
      CALL PH_Elem_CPE8_ConstMatrix(E_young, nu, D)
    END IF
    CALL PH_Elem_CPE8_NL_UL_Legacy(arg%coords_prev, arg%u_incr, D, &
      arg%evo%Ke_mat, arg%evo%Ke_geo, arg%evo%R_int, arg%status)
    IF (ALLOCATED(arg%mat_state)) arg%mat_state = arg%mat_state
  END SUBROUTINE PH_Elem_CPE8_NL_UL_Structured

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_CPE8_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_CPE8_GetArea

  SUBROUTINE PH_Elem_CPE8_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 2
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
    END IF
  END SUBROUTINE PH_Elem_CPE8_GetCentroid

  SUBROUTINE PH_Elem_CPE8_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CPE8_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_CPE8_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CPE8_ApplyConstraint

  SUBROUTINE PH_Elem_CPE8_ApplyMPC(c, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_CPE8_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(INOUT) :: K_el(16, 16)
    REAL(wp), INTENT(INOUT) :: F_el(16)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 8
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 8
      DO b = 1, 8
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE8_FormContactContrib

  SUBROUTINE PH_Elem_CPE8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(16, 16)
    REAL(wp), INTENT(OUT) :: F_el(16)
    REAL(wp) :: xi, eta, N(8), n(2), dNdxi(2, 8)
    REAL(wp) :: t(2), len
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CPE8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPE8_EDGE_NODES(2, edge_id)
    SELECT CASE (edge_id)
    CASE (1)
      xi = 0.0_wp
      eta = -ONE
    CASE (2)
      xi = ONE
      eta = 0.0_wp
    CASE (3)
      xi = 0.0_wp
      eta = ONE
    CASE (4)
      xi = -ONE
      eta = 0.0_wp
    END SELECT
    CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CPE8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_CPE8_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPE8_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: t(2), len, nx, ny, f3
    INTEGER(i4) :: n1, n2, nmid, ia
    INTEGER(i4), PARAMETER :: EDGE_MID(4) = [5, 6, 7, 8]
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CPE8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPE8_EDGE_NODES(2, edge_id)
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
  END SUBROUTINE PH_Elem_CPE8_FormEdgePressure

  SUBROUTINE PH_Elem_CPE8_FormBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * bx * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * by * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE8_FormBodyForce

  SUBROUTINE PH_Elem_CPE8_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(16)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CPE8_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPE8_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CPE8_FormNodalForce

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

  SUBROUTINE PH_Elem_CPE8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 7
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 9)
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
  END SUBROUTINE PH_Elem_CPE8_CollectIPVars

  SUBROUTINE PH_Elem_CPE8_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_CPE8_EvalPrincStress

  SUBROUTINE PH_Elem_CPE8_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdev11, sdev22
    I1 = sigma(1) + sigma(2)
    p = I1 / 2.0_wp
    sdev11 = sigma(1) - p
    sdev22 = sigma(2) - p
    J2 = HALF * (sdev11*sdev11 + sdev22*sdev22) + sigma(3)*sigma(3)
  END SUBROUTINE PH_Elem_CPE8_EvalStressInvar

  SUBROUTINE PH_Elem_CPE8_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s11, s22, s12
    s11 = sigma(1)
    s22 = sigma(2)
    s12 = sigma(3)
    seq = SQRT(s11*s11 + s22*s22 - s11*s22 + 3.0_wp*s12*s12)
  END SUBROUTINE PH_Elem_CPE8_EvalVonMises

  SUBROUTINE PH_Elem_CPE8_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(8, 9)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8)
    REAL(wp) :: A(8, 9), B(8, 8), Binv(8, 8)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CPE8_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 9
      CALL PH_Elem_CPE8_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
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
  END SUBROUTINE PH_Elem_CPE8_GetExtrapMat

  SUBROUTINE PH_Elem_CPE8_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(8, 9)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CPE8_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 8
        DO j = 1, 9
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPE8_MapToNode

  SUBROUTINE PH_Elem_CPE8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_CPE8_Material_Update_Routed

END MODULE PH_Elem_CPE8


