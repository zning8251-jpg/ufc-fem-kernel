!===============================================================================
! MODULE: PH_Elem_CPS4
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Proc
! BRIEF:  CPS4 element definition (4-node plane stress)
!===============================================================================
MODULE PH_Elem_CPS4
!> [CORE] CPS4 plane stress quad (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE

  ! Constants
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_NNODE  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_NIP   = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_NDOF  = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4_FACE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp

  ! Constraints
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  !=============================================================================
  ! STRUCTURED TYPES (for AC2D4, etc.)
  !=============================================================================

  TYPE, PUBLIC :: PH_Elem_CPS4_ShapeFunc_Arg
    REAL(wp) :: xi                   ! [IN]
    REAL(wp) :: eta                  ! [IN]
    REAL(wp) :: N(4)                 ! [OUT]
    REAL(wp) :: dNdxi(2, 4)          ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_ShapeFunc_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_Jac_Arg
    REAL(wp) :: dNdxi(2, 4)          ! [IN]
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: J(2, 2)              ! [OUT]
    REAL(wp) :: detJ                 ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Jac_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_BMatrix_Arg
    REAL(wp) :: dNdx(2, 4)           ! [IN]
    REAL(wp) :: B(3, 8)              ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_BMatrix_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_JacB_Arg
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: xi                   ! [IN]
    REAL(wp) :: eta                  ! [IN]
    REAL(wp) :: N(4)                 ! [OUT]
    REAL(wp) :: dNdx(2, 4)           ! [OUT]
    REAL(wp) :: J(2, 2)              ! [OUT]
    REAL(wp) :: detJ                 ! [OUT]
    REAL(wp) :: B(3, 8)              ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_JacB_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_Strain_Arg
    REAL(wp) :: B(3, 8)              ! [IN]
    REAL(wp) :: u(8)                 ! [IN]
    REAL(wp) :: strain(3)            ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Strain_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_Stress_Arg
    REAL(wp) :: epsilon(3)           ! [IN]
    REAL(wp) :: D(3, 3)              ! [IN]
    REAL(wp) :: sigma(3)             ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Stress_Arg

  TYPE, PUBLIC :: PH_Elem_CPS4_StiffMatrix_Arg
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: D_matrix(3, 3)       ! [IN]
    REAL(wp) :: Ke(8, 8)             ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_StiffMatrix_Arg



  TYPE, PUBLIC :: PH_Elem_CPS4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS4_NL_TL_Arg



  TYPE, PUBLIC :: PH_Elem_CPS4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS4_NL_UL_Arg


  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_CPS4_DefInit
  PUBLIC :: PH_Elem_CPS4_ShapeFunc_Arg
  PUBLIC :: PH_Elem_CPS4_ShapeFunc
  PUBLIC :: PH_Elem_CPS4_Jac_Arg
  PUBLIC :: PH_Elem_CPS4_Jac
  PUBLIC :: PH_Elem_CPS4_BMatrix_Arg
  PUBLIC :: PH_Elem_CPS4_BMatrix
  PUBLIC :: PH_Elem_CPS4_JacB_Arg
  PUBLIC :: PH_Elem_CPS4_JacB
  PUBLIC :: PH_Elem_CPS4_Strain_Arg
  PUBLIC :: PH_Elem_CPS4_Strain
  PUBLIC :: PH_Elem_CPS4_Stress_Arg
  PUBLIC :: PH_Elem_CPS4_Stress
  PUBLIC :: PH_Elem_CPS4_StiffMatrix_Arg
  PUBLIC :: PH_Elem_CPS4_FormStiffMatrix
  PUBLIC :: PH_Elem_CPS4_NL_TL_Arg
  PUBLIC :: PH_Elem_CPS4_NL_TL, PH_Elem_CPS4_NL_TL_Structured, PH_Elem_CPS4_NL_TL_Legacy
  PUBLIC :: PH_Elem_CPS4_NL_UL_Arg
  PUBLIC :: PH_Elem_CPS4_NL_UL
  PUBLIC :: PH_Elem_CPS4_GaussPoints
  PUBLIC :: PH_Elem_CPS4_ConstMatrix
  PUBLIC :: PH_Elem_CPS4_FormIntForce
  PUBLIC :: PH_Elem_CPS4_FormIntForceFromStress
  PUBLIC :: PH_Elem_CPS4_ConsMass
  PUBLIC :: PH_Elem_CPS4_LumpMass
  PUBLIC :: PH_Elem_CPS4_ThermStrainVector
  PUBLIC :: PH_Elem_CPS4_GetArea
  PUBLIC :: PH_Elem_CPS4_GetCentroid
  PUBLIC :: PH_Elem_CPS4_GetSectProps
  PUBLIC :: PH_Elem_CPS4_ApplyConstraint
  PUBLIC :: PH_Elem_CPS4_ApplyMPC
  PUBLIC :: PH_Elem_CPS4_FormContactContrib
  PUBLIC :: PH_Elem_CPS4_FormContactEdgeCtr
  PUBLIC :: PH_Elem_CPS4_FormNodalForce
  PUBLIC :: PH_Elem_CPS4_FormBodyForce
  PUBLIC :: PH_Elem_CPS4_FormEdgePressure
  PUBLIC :: PH_Elem_CPS4_CollectIPVars
  PUBLIC :: PH_Elem_CPS4_MapToNode
  PUBLIC :: PH_Elem_CPS4_GetExtrapMat
  PUBLIC :: PH_Elem_CPS4_EvalVonMises
  PUBLIC :: PH_Elem_CPS4_EvalPrincStress
  PUBLIC :: PH_Elem_CPS4_EvalStressInvar
  PUBLIC :: PH_Elem_CPS4_Material_Update_Routed
  PUBLIC :: PH_ELEM_CPS4_NNODE, PH_ELEM_CPS4_NIP, PH_ELEM_CPS4_NDOF, PH_ELEM_CPS4_NEDGE
  PUBLIC :: PH_ELEM_CPS4_EDGE_NODES, PH_ELEM_CPS4_FACE_NODES, PH_ELEM_GAUSS_PT

  ! Generic interfaces for legacy + structured
  INTERFACE PH_Elem_CPS4_ShapeFunc
    MODULE PROCEDURE PH_Elem_CPS4_ShapeFunc_Legacy
    MODULE PROCEDURE PH_Elem_CPS4_ShapeFunc_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS4_Jac
    MODULE PROCEDURE PH_Elem_CPS4_Jac_Legacy
    MODULE PROCEDURE PH_Elem_CPS4_Jac_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS4_JacB
    MODULE PROCEDURE PH_Elem_CPS4_JacB_Legacy
    MODULE PROCEDURE PH_Elem_CPS4_JacB_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS4_Strain
    MODULE PROCEDURE PH_Elem_CPS4_Strain_Legacy
    MODULE PROCEDURE PH_Elem_CPS4_Strain_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS4_Stress
    MODULE PROCEDURE PH_Elem_CPS4_Stress_Legacy
    MODULE PROCEDURE PH_Elem_CPS4_Stress_InOut
  END INTERFACE

  INTERFACE PH_Elem_CPS4_NL_TL
    MODULE PROCEDURE PH_Elem_CPS4_NL_TL_Structured
    MODULE PROCEDURE PH_Elem_CPS4_NL_TL_Legacy
  END INTERFACE

  INTERFACE PH_Elem_CPS4_NL_UL
    MODULE PROCEDURE PH_Elem_CPS4_NL_UL_Legacy
  END INTERFACE

CONTAINS

  !=============================================================================
  ! LEGACY WRAPPERS (for Sect, Loads, Out, Cont)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 4)
    TYPE(PH_Elem_CPS4_ShapeFunc_Arg) :: arg
    arg%xi = xi
    arg%eta = eta
    CALL PH_Elem_CPS4_ShapeFunc_InOut(arg)
    N = arg%N
    dNdxi = arg%dNdxi
  END SUBROUTINE PH_Elem_CPS4_ShapeFunc_Legacy

  SUBROUTINE PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 4)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(PH_Elem_CPS4_Jac_Arg) :: arg
    arg%dNdxi = dNdxi
    arg%coords = coords
    CALL PH_Elem_CPS4_Jac_InOut(arg)
    J = arg%J
    detJ = arg%detJ
  END SUBROUTINE PH_Elem_CPS4_Jac_Legacy

  SUBROUTINE PH_Elem_CPS4_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdx(2, 4)
    REAL(wp), INTENT(OUT) :: J(2, 2)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(3, 8)
    TYPE(PH_Elem_CPS4_JacB_Arg) :: arg
    arg%coords = coords
    arg%xi = xi_pt
    arg%eta = eta_pt
    CALL PH_Elem_CPS4_JacB_InOut(arg)
    N = arg%N
    dNdx = arg%dNdx
    J = arg%J
    detJ = arg%detJ
    B = arg%B
  END SUBROUTINE PH_Elem_CPS4_JacB_Legacy

  SUBROUTINE PH_Elem_CPS4_Strain_Legacy(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(3, 8)
    REAL(wp), INTENT(IN)  :: u(8)
    REAL(wp), INTENT(OUT) :: strain(3)
    TYPE(PH_Elem_CPS4_Strain_Arg) :: arg
    arg%B = B
    arg%u = u
    CALL PH_Elem_CPS4_Strain_InOut(arg)
    strain = arg%strain
  END SUBROUTINE PH_Elem_CPS4_Strain_Legacy

  SUBROUTINE PH_Elem_CPS4_Stress_Legacy(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(3)
    REAL(wp), INTENT(IN)  :: D(3, 3)
    REAL(wp), INTENT(OUT) :: sigma(3)
    TYPE(PH_Elem_CPS4_Stress_Arg) :: arg
    arg%epsilon = epsilon
    arg%D = D
    CALL PH_Elem_CPS4_Stress_InOut(arg)
    sigma = arg%sigma
  END SUBROUTINE PH_Elem_CPS4_Stress_Legacy

  !=============================================================================
  ! DEFINITION (core)
  !=============================================================================
  SUBROUTINE PH_ELEM_CPS4_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_CPS4_AreaInt

  SUBROUTINE PH_Elem_CPS4_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(3)
    REAL(wp) :: e
    e = alpha * deltaT
    eps_th(1) = e
    eps_th(2) = e
    eps_th(3) = ZERO
  END SUBROUTINE PH_Elem_CPS4_ThermStrainVector

  SUBROUTINE PH_Elem_CPS4_BMatrix(arg)
    TYPE(PH_Elem_CPS4_BMatrix_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%B = ZERO
    DO i = 1, 4
      arg%B(1, 2*i-1) = arg%dNdx(1, i)
      arg%B(2, 2*i)   = arg%dNdx(2, i)
      arg%B(3, 2*i-1) = arg%dNdx(2, i)
      arg%B(3, 2*i)   = arg%dNdx(1, i)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_BMatrix

  SUBROUTINE PH_Elem_CPS4_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(8, 8)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        DO j = 1, 4
          Me(2*i-1, 2*j-1) = Me(2*i-1, 2*j-1) + rho * N(i)*N(j) * detJ * weights(ip)
          Me(2*i-1, 2*j)   = Me(2*i-1, 2*j)
          Me(2*i,   2*j-1) = Me(2*i, 2*j-1)
          Me(2*i,   2*j)   = Me(2*i, 2*j)   + rho * N(i)*N(j) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS4_ConsMass

  SUBROUTINE PH_Elem_CPS4_ConstMatrix(E_young, nu, D)
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
  END SUBROUTINE PH_Elem_CPS4_ConstMatrix

  SUBROUTINE PH_Elem_CPS4_DefInit()
  END SUBROUTINE PH_Elem_CPS4_DefInit

  SUBROUTINE PH_Elem_CPS4_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: u(8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(8)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdx(2, 4), J(2, 2), B(3, 8), D(3, 3), strain(3), sigma(3), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPS4_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_Elem_CPS4_Strain_Legacy(B, u, strain)
      CALL PH_Elem_CPS4_Stress_Legacy(strain, D, sigma)
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS4_FormIntForce

  SUBROUTINE PH_Elem_CPS4_FormIntForceFromStress(coords, sigma3, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: sigma3(3)
    REAL(wp), INTENT(OUT) :: R_int(8)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdx(2, 4), J(2, 2), B(3, 8), detJ
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_JacB_Legacy(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      R_int = R_int + MATMUL(TRANSPOSE(B), sigma3) * detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_CPS4_FormIntForceFromStress

  SUBROUTINE PH_Elem_CPS4_FormStiffMatrix(arg)
    TYPE(PH_Elem_CPS4_StiffMatrix_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: xi(4), eta(4), weights(4)
    TYPE(PH_Elem_CPS4_JacB_Arg) :: jb
    REAL(wp) :: BTD(8, 3), dV
    INTEGER(i4) :: ip
    CALL init_error_status(arg%status)
    arg%evo%Ke = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    jb%coords = arg%coords
    DO ip = 1, 4
      jb%xi = xi(ip)
      jb%eta = eta(ip)
      CALL PH_Elem_CPS4_JacB_InOut(jb)
      IF (jb%status%status_code /= IF_STATUS_OK .OR. ABS(jb%detJ) <= 1.0e-12_wp) CYCLE
      dV = jb%detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(jb%B), arg%D_matrix)
      arg%evo%Ke = arg%evo%Ke + dV * MATMUL(BTD, jb%B)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_FormStiffMatrix

  SUBROUTINE PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(4), eta(4), weights(4)
    REAL(wp) :: g
    g = PH_ELEM_GAUSS_PT
    xi(1) = -g
    eta(1) = -g
    weights(1) = ONE
    xi(2) =  g
    eta(2) = -g
    weights(2) = ONE
    xi(3) =  g
    eta(3) =  g
    weights(3) = ONE
    xi(4) = -g
    eta(4) =  g
    weights(4) = ONE
  END SUBROUTINE PH_Elem_CPS4_GaussPoints

  SUBROUTINE PH_Elem_CPS4_Jac_InOut(arg)
    TYPE(PH_Elem_CPS4_Jac_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%J = ZERO
    DO i = 1, 4
      arg%J(1, 1) = arg%J(1, 1) + arg%dNdxi(1, i) * arg%coords(1, i)
      arg%J(1, 2) = arg%J(1, 2) + arg%dNdxi(1, i) * arg%coords(2, i)
      arg%J(2, 1) = arg%J(2, 1) + arg%dNdxi(2, i) * arg%coords(1, i)
      arg%J(2, 2) = arg%J(2, 2) + arg%dNdxi(2, i) * arg%coords(2, i)
    END DO
    arg%detJ = arg%J(1, 1) * arg%J(2, 2) - arg%J(1, 2) * arg%J(2, 1)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_Jac_InOut

  SUBROUTINE PH_Elem_CPS4_JacB_InOut(arg)
    TYPE(PH_Elem_CPS4_JacB_Arg), INTENT(INOUT) :: arg
    TYPE(PH_Elem_CPS4_ShapeFunc_Arg) :: sf
    TYPE(PH_Elem_CPS4_Jac_Arg) :: jac
    TYPE(PH_Elem_CPS4_BMatrix_Arg) :: bm
    REAL(wp) :: dNdxi(2, 4), Jinv(2, 2)
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    sf%xi = arg%xi
    sf%eta = arg%eta
    CALL PH_Elem_CPS4_ShapeFunc_InOut(sf)
    IF (sf%status%status_code /= IF_STATUS_OK) THEN
      arg%status = sf%status
      RETURN
    END IF
    arg%N = sf%N
    dNdxi = sf%dNdxi
    jac%dNdxi = dNdxi
    jac%coords = arg%coords
    CALL PH_Elem_CPS4_Jac_InOut(jac)
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
      DO i = 1, 4
        arg%dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        arg%dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      bm%dNdx = arg%dNdx
      CALL PH_Elem_CPS4_BMatrix(bm)
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
  END SUBROUTINE PH_Elem_CPS4_JacB_InOut

  SUBROUTINE PH_Elem_CPS4_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(8)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_CPS4_AreaInt(coords, area)
    m = rho * area / 4.0_wp
    DO i = 1, 4
      M_lumped(2*i-1) = m
      M_lumped(2*i)   = m
    END DO
  END SUBROUTINE PH_Elem_CPS4_LumpMass

  SUBROUTINE PH_Elem_CPS4_ShapeFunc_InOut(arg)
    TYPE(PH_Elem_CPS4_ShapeFunc_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%N(1) = QUARTER * (ONE - arg%xi) * (ONE - arg%eta)
    arg%N(2) = QUARTER * (ONE + arg%xi) * (ONE - arg%eta)
    arg%N(3) = QUARTER * (ONE + arg%xi) * (ONE + arg%eta)
    arg%N(4) = QUARTER * (ONE - arg%xi) * (ONE + arg%eta)
    arg%dNdxi(1, 1) = -QUARTER * (ONE - arg%eta)
    arg%dNdxi(2, 1) = -QUARTER * (ONE - arg%xi)
    arg%dNdxi(1, 2) =  QUARTER * (ONE - arg%eta)
    arg%dNdxi(2, 2) = -QUARTER * (ONE + arg%xi)
    arg%dNdxi(1, 3) =  QUARTER * (ONE + arg%eta)
    arg%dNdxi(2, 3) =  QUARTER * (ONE + arg%xi)
    arg%dNdxi(1, 4) = -QUARTER * (ONE + arg%eta)
    arg%dNdxi(2, 4) =  QUARTER * (ONE - arg%xi)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_ShapeFunc_InOut

  SUBROUTINE PH_Elem_CPS4_Strain_InOut(arg)
    TYPE(PH_Elem_CPS4_Strain_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%strain = ZERO
    DO j = 1, 8
      arg%strain(1) = arg%strain(1) + arg%B(1, j) * arg%u(j)
      arg%strain(2) = arg%strain(2) + arg%B(2, j) * arg%u(j)
      arg%strain(3) = arg%strain(3) + arg%B(3, j) * arg%u(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_Strain_InOut

  SUBROUTINE PH_Elem_CPS4_Stress_InOut(arg)
    TYPE(PH_Elem_CPS4_Stress_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: j
    CALL init_error_status(arg%status)
    arg%sigma = ZERO
    DO j = 1, 3
      arg%sigma(1) = arg%sigma(1) + arg%D(1, j) * arg%epsilon(j)
      arg%sigma(2) = arg%sigma(2) + arg%D(2, j) * arg%epsilon(j)
      arg%sigma(3) = arg%sigma(3) + arg%D(3, j) * arg%epsilon(j)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_CPS4_Stress_InOut

  !=============================================================================
  ! NL_TL / NL_UL - Decoupled 2D Implementation
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 4)
    REAL(wp), INTENT(IN) :: u_elem(8)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8)
    REAL(wp), INTENT(OUT) :: Ke_geo(8, 8)
    REAL(wp), INTENT(OUT) :: R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_curr(2, 4)
    REAL(wp) :: xi_gp(4), eta_gp(4), wt_gp(4)
    REAL(wp) :: N(4), dN_dxi(2, 4), dN_dX(2, 4)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(2, 2), E_voigt(3), S_voigt(3)
    REAL(wp) :: B_u(3, 8), G(4, 8), S_hat(4, 4), Gt_S_hat(8, 4)
    REAL(wp) :: BTD(8, 3)
    INTEGER(i4) :: i, igp
    
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    
    DO i = 1, 4
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*i-1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*i)
    END DO
    
    CALL PH_Elem_CPS4_GaussPoints(xi_gp, eta_gp, wt_gp)
    
    DO igp = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_ref = ZERO
      DO i = 1, 4
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
      
      DO i = 1, 4
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO
      
      F = ZERO
      DO i = 1, 4
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dX(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dX(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dX(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dX(2, i)
      END DO
      
      E_voigt(1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) - ONE)
      E_voigt(2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) - ONE)
      E_voigt(3) = F(1,1)*F(1,2) + F(2,1)*F(2,2)
      
      S_voigt = MATMUL(D, E_voigt)
      
      ! Construct B_u matrix
      B_u = ZERO
      DO i = 1, 4
        B_u(1, 2*i-1) = F(1,1) * dN_dX(1, i)
        B_u(1, 2*i)   = F(2,1) * dN_dX(1, i)
        B_u(2, 2*i-1) = F(1,2) * dN_dX(2, i)
        B_u(2, 2*i)   = F(2,2) * dN_dX(2, i)
        B_u(3, 2*i-1) = F(1,2) * dN_dX(1, i) + F(1,1) * dN_dX(2, i)
        B_u(3, 2*i)   = F(2,2) * dN_dX(1, i) + F(2,1) * dN_dX(2, i)
      END DO
      
      ! Construct G matrix and S_hat
      G = ZERO
      DO i = 1, 4
        G(1, 2*i-1) = dN_dX(1, i)
        G(2, 2*i-1) = dN_dX(2, i)
        G(3, 2*i)   = dN_dX(1, i)
        G(4, 2*i)   = dN_dX(2, i)
      END DO
      
      S_hat = ZERO
      S_hat(1,1) = S_voigt(1); S_hat(1,2) = S_voigt(3)
      S_hat(2,1) = S_voigt(3); S_hat(2,2) = S_voigt(2)
      S_hat(3,3) = S_voigt(1); S_hat(3,4) = S_voigt(3)
      S_hat(4,3) = S_voigt(3); S_hat(4,4) = S_voigt(2)
      
      ! Accumulate
      BTD = MATMUL(TRANSPOSE(B_u), D)
      Ke_mat = Ke_mat + MATMUL(BTD, B_u) * det_J * wt_gp(igp)
      
      Gt_S_hat = MATMUL(TRANSPOSE(G), S_hat)
      Ke_geo = Ke_geo + MATMUL(Gt_S_hat, G) * det_J * wt_gp(igp)
      
      R_int = R_int + MATMUL(TRANSPOSE(B_u), S_voigt) * det_J * wt_gp(igp)
    END DO
  END SUBROUTINE PH_Elem_CPS4_NL_TL_Legacy

  SUBROUTINE PH_Elem_CPS4_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 4)
    REAL(wp), INTENT(IN) :: u_incr(8)
    REAL(wp), INTENT(IN) :: D(3, 3)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8)
    REAL(wp), INTENT(OUT) :: Ke_geo(8, 8)
    REAL(wp), INTENT(OUT) :: R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_curr(2, 4)
    REAL(wp) :: xi_gp(4), eta_gp(4), wt_gp(4)
    REAL(wp) :: N(4), dN_dxi(2, 4), dN_dx(2, 4)
    REAL(wp) :: J_prev(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(2, 2), b_tensor(2, 2), b_inv(2, 2), det_b
    REAL(wp) :: eps_voigt(3), sigma_voigt(3)
    REAL(wp) :: B_L(3, 8), G(4, 8), sigma_hat(4, 4), Gt_sigma_hat(8, 4)
    REAL(wp) :: BTD(8, 3)
    INTEGER(i4) :: i, igp
    
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%status_code = IF_STATUS_OK
    
    DO i = 1, 4
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*i-1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*i)
    END DO
    
    CALL PH_Elem_CPS4_GaussPoints(xi_gp, eta_gp, wt_gp)
    
    DO igp = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_prev = ZERO
      DO i = 1, 4
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
      
      DO i = 1, 4
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO
      
      F = ZERO
      DO i = 1, 4
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dx(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dx(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dx(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dx(2, i)
      END DO
      
      b_tensor = MATMUL(F, TRANSPOSE(F))
      det_b = b_tensor(1,1)*b_tensor(2,2) - b_tensor(1,2)*b_tensor(2,1)
      IF (ABS(det_b) <= 1.0e-14_wp) CYCLE
      
      b_inv(1,1) =  b_tensor(2,2) / det_b
      b_inv(1,2) = -b_tensor(1,2) / det_b
      b_inv(2,1) = -b_tensor(2,1) / det_b
      b_inv(2,2) =  b_tensor(1,1) / det_b
      
      eps_voigt(1) = HALF * (ONE - b_inv(1,1))
      eps_voigt(2) = HALF * (ONE - b_inv(2,2))
      eps_voigt(3) = -b_inv(1,2)
      
      sigma_voigt = MATMUL(D, eps_voigt)
      
      ! Construct standard linear B matrix (current config)
      B_L = ZERO
      DO i = 1, 4
        B_L(1, 2*i-1) = dN_dx(1, i)
        B_L(2, 2*i)   = dN_dx(2, i)
        B_L(3, 2*i-1) = dN_dx(2, i)
        B_L(3, 2*i)   = dN_dx(1, i)
      END DO
      
      ! Construct G matrix and sigma_hat
      G = ZERO
      DO i = 1, 4
        G(1, 2*i-1) = dN_dx(1, i)
        G(2, 2*i-1) = dN_dx(2, i)
        G(3, 2*i)   = dN_dx(1, i)
        G(4, 2*i)   = dN_dx(2, i)
      END DO
      
      sigma_hat = ZERO
      sigma_hat(1,1) = sigma_voigt(1); sigma_hat(1,2) = sigma_voigt(3)
      sigma_hat(2,1) = sigma_voigt(3); sigma_hat(2,2) = sigma_voigt(2)
      sigma_hat(3,3) = sigma_voigt(1); sigma_hat(3,4) = sigma_voigt(3)
      sigma_hat(4,3) = sigma_voigt(3); sigma_hat(4,4) = sigma_voigt(2)
      
      ! Accumulate
      BTD = MATMUL(TRANSPOSE(B_L), D)
      Ke_mat = Ke_mat + MATMUL(BTD, B_L) * det_J * wt_gp(igp)
      
      Gt_sigma_hat = MATMUL(TRANSPOSE(G), sigma_hat)
      Ke_geo = Ke_geo + MATMUL(Gt_sigma_hat, G) * det_J * wt_gp(igp)
      
      R_int = R_int + MATMUL(TRANSPOSE(B_L), sigma_voigt) * det_J * wt_gp(igp)
    END DO
  END SUBROUTINE PH_Elem_CPS4_NL_UL_Legacy

  SUBROUTINE PH_Elem_CPS4_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
    USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_Ctx
    USE MD_Field_Mgr, ONLY: MD_ElemIPData
    USE MD_Mat_BaseDef, ONLY: MD_Mat_Ctx
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_BuildElasticSlot, &
                                    PH_Elem_MatRoute_ElasticPlaneStress

    TYPE(PH_Elem_Desc), INTENT(IN) :: elem_cfg
    TYPE(MD_ElemIPData), INTENT(INOUT) :: elem_state
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: elem_ctx
    TYPE(MD_Mat_Ctx), INTENT(IN) :: mat_cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_curr(2, 4), coords_ref(2, 4)
    REAL(wp) :: xi_gp(4), eta_gp(4), wt_gp(4)
    REAL(wp) :: N(4), dN_dxi(2, 4), dN_dX(2, 4)
    REAL(wp) :: J_ref(2, 2), det_J, J_inv(2, 2)
    REAL(wp) :: F(2, 2), E_voigt(3), S_voigt(3), D_tangent(3, 3)
    REAL(wp) :: dStrain(3), strain_old(3)
    REAL(wp) :: B_u(3, 8), G(4, 8), S_hat(4, 4), Gt_S_hat(8, 4), BTD(8, 3)
    INTEGER(i4) :: i, igp, nsdv
    REAL(wp) :: sdv_old(max(1, elem_state%num_sdv)), sdv_new(max(1, elem_state%num_sdv))
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_mat_ctx
    TYPE(PH_Mat_Slot) :: mat_slot
    
    elem_ctx%evo%Ke_mat = ZERO
    elem_ctx%evo%Ke_geo = ZERO
    elem_ctx%evo%R_int = ZERO
    status%status_code = IF_STATUS_OK
    nsdv = elem_state%num_sdv

    CALL PH_Elem_MatRoute_BuildElasticSlot(elem_cfg%mat_id, rt_mat_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    coords_ref = elem_cfg%coords0(1:2, 1:4)
    
    DO i = 1, 4
      coords_curr(1, i) = coords_ref(1, i) + elem_ctx%lcl%u_elem(2*i-1)
      coords_curr(2, i) = coords_ref(2, i) + elem_ctx%lcl%u_elem(2*i)
    END DO
    
    CALL PH_Elem_CPS4_GaussPoints(xi_gp, eta_gp, wt_gp)
    
    DO igp = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      J_ref = ZERO
      DO i = 1, 4
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
      
      DO i = 1, 4
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i)
      END DO
      
      F = ZERO
      DO i = 1, 4
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dX(1, i)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dX(2, i)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dX(1, i)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dX(2, i)
      END DO
      
      E_voigt(1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) - ONE)
      E_voigt(2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) - ONE)
      E_voigt(3) = F(1,1)*F(1,2) + F(2,1)*F(2,2)
      
      strain_old = elem_state%strain_old(1:3, igp)
      dStrain = E_voigt - strain_old
      
      IF (nsdv > 0) sdv_old(1:nsdv) = elem_state%sdv_old(1:nsdv, igp)
      
      CALL PH_Elem_MatRoute_ElasticPlaneStress(rt_mat_ctx, mat_slot, dStrain, &
                                               elem_state%stress_old(1:3, igp), &
                                               S_voigt, D_tangent, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      IF (nsdv > 0) sdv_new(1:nsdv) = sdv_old(1:nsdv)
      
      elem_state%strain(1:3, igp) = E_voigt
      elem_state%stress(1:3, igp) = S_voigt
      IF (nsdv > 0) elem_state%sdv(1:nsdv, igp) = sdv_new(1:nsdv)
      
      B_u = ZERO
      DO i = 1, 4
        B_u(1, 2*i-1) = F(1,1) * dN_dX(1, i)
        B_u(1, 2*i)   = F(2,1) * dN_dX(1, i)
        B_u(2, 2*i-1) = F(1,2) * dN_dX(2, i)
        B_u(2, 2*i)   = F(2,2) * dN_dX(2, i)
        B_u(3, 2*i-1) = F(1,2) * dN_dX(1, i) + F(1,1) * dN_dX(2, i)
        B_u(3, 2*i)   = F(2,2) * dN_dX(1, i) + F(2,1) * dN_dX(2, i)
      END DO
      
      G = ZERO
      DO i = 1, 4
        G(1, 2*i-1) = dN_dX(1, i)
        G(2, 2*i-1) = dN_dX(2, i)
        G(3, 2*i)   = dN_dX(1, i)
        G(4, 2*i)   = dN_dX(2, i)
      END DO
      
      S_hat = ZERO
      S_hat(1,1) = S_voigt(1); S_hat(1,2) = S_voigt(3)
      S_hat(2,1) = S_voigt(3); S_hat(2,2) = S_voigt(2)
      S_hat(3,3) = S_voigt(1); S_hat(3,4) = S_voigt(3)
      S_hat(4,3) = S_voigt(3); S_hat(4,4) = S_voigt(2)
      
      BTD = MATMUL(TRANSPOSE(B_u), D_tangent)
      elem_ctx%evo%Ke_mat = elem_ctx%evo%Ke_mat + MATMUL(BTD, B_u) * det_J * wt_gp(igp)
      
      Gt_S_hat = MATMUL(TRANSPOSE(G), S_hat)
      elem_ctx%evo%Ke_geo = elem_ctx%evo%Ke_geo + MATMUL(Gt_S_hat, G) * det_J * wt_gp(igp)
      
      elem_ctx%evo%R_int = elem_ctx%evo%R_int + MATMUL(TRANSPOSE(B_u), S_voigt) * det_J * wt_gp(igp)
    END DO
    
    elem_ctx%evo%Ke = elem_ctx%evo%Ke_mat + elem_ctx%evo%Ke_geo
  END SUBROUTINE PH_Elem_CPS4_NL_TL_Structured

  SUBROUTINE PH_Elem_CPS4_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_CPS4_Material_Update_Routed

  !=============================================================================
  ! SECTION (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_CPS4_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_CPS4_GetArea

  SUBROUTINE PH_Elem_CPS4_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(OUT) :: centroid(2)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 2
        DO j = 1, 4
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
    END IF
  END SUBROUTINE PH_Elem_CPS4_GetCentroid

  SUBROUTINE PH_Elem_CPS4_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_CPS4_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_CPS4_GetSectProps

  !=============================================================================
  ! CONSTRAINTS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(8, 8)
    REAL(wp), INTENT(INOUT) :: F_el(8)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 8) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_CPS4_ApplyConstraint

  SUBROUTINE PH_Elem_CPS4_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(8)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(8, 8)
    REAL(wp), INTENT(INOUT) :: F_el(8)
    INTEGER(i4) :: i, j
    DO i = 1, 8
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 8
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS4_ApplyMPC

  !=============================================================================
  ! CONTACT (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(IN)  :: edge_len
    REAL(wp), INTENT(INOUT) :: K_el(8, 8)
    REAL(wp), INTENT(INOUT) :: F_el(8)
    REAL(wp) :: f_a(2), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 4
      ia = 2 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * edge_len * n(1)
      f_a(2) = penalty * gap * N(a) * edge_len * n(2)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
    END DO
    DO a = 1, 4
      DO b = 1, 4
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS4_FormContactContrib

  SUBROUTINE PH_Elem_CPS4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(8, 8)
    REAL(wp), INTENT(OUT) :: F_el(8)
    REAL(wp) :: xi, eta, N(4), n(2), dNdxi(2, 4)
    REAL(wp) :: t(2), len
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CPS4_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPS4_EDGE_NODES(2, edge_id)
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
    CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi, eta, N, dNdxi)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    CALL PH_Elem_CPS4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_CPS4_FormContactEdgeCtr

  !=============================================================================
  ! LOADS (inlined)
  !=============================================================================
  SUBROUTINE PH_Elem_CPS4_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(8)
    REAL(wp) :: t(2), len, nx, ny
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CPS4_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPS4_EDGE_NODES(2, edge_id)
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
  END SUBROUTINE PH_Elem_CPS4_FormEdgePressure

  SUBROUTINE PH_Elem_CPS4_FormBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(8)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        F_eq(2*i-1) = F_eq(2*i-1) + N(i) * bx * detJ * weights(ip)
        F_eq(2*i)   = F_eq(2*i)   + N(i) * by * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS4_FormBodyForce

  SUBROUTINE PH_Elem_CPS4_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(8)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_CPS4_FormBodyForce(coords, val(1), val(2), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPS4_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_CPS4_FormNodalForce

  !=============================================================================
  ! OUTPUT (inlined)
  !=============================================================================
  SUBROUTINE invert_4x4(A, info)
    REAL(wp), INTENT(INOUT) :: A(4, 4)
    INTEGER(i4), INTENT(OUT) :: info
    REAL(wp) :: B(4, 4)
    INTEGER(i4) :: i, k
    REAL(wp) :: fac
    B = A
    A = ZERO
    DO i = 1, 4
      A(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 4
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, :) = B(k, :) * fac
      A(k, :) = A(k, :) * fac
      DO i = 1, 4
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, :) = B(i, :) - fac * B(k, :)
        A(i, :) = A(i, :) - fac * A(k, :)
      END DO
    END DO
  END SUBROUTINE invert_4x4

  SUBROUTINE PH_Elem_CPS4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 7
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 4)
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
  END SUBROUTINE PH_Elem_CPS4_CollectIPVars

  SUBROUTINE PH_Elem_CPS4_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_CPS4_EvalPrincStress

  SUBROUTINE PH_Elem_CPS4_EvalStressInvar(sigma, I1, J2)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: I1, J2
    REAL(wp) :: p, sdev11, sdev22
    I1 = sigma(1) + sigma(2)
    p = I1 / 2.0_wp
    sdev11 = sigma(1) - p
    sdev22 = sigma(2) - p
    J2 = HALF * (sdev11*sdev11 + sdev22*sdev22) + sigma(3)*sigma(3)
  END SUBROUTINE PH_Elem_CPS4_EvalStressInvar

  SUBROUTINE PH_Elem_CPS4_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(3)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s11, s22, s12
    s11 = sigma(1)
    s22 = sigma(2)
    s12 = sigma(3)
    seq = SQRT(s11*s11 + s22*s22 - s11*s22 + 3.0_wp*s12*s12)
  END SUBROUTINE PH_Elem_CPS4_EvalVonMises

  SUBROUTINE PH_Elem_CPS4_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4)
    REAL(wp) :: A(4, 4), AT(4, 4)
    INTEGER(i4) :: ip, i, j, info
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    A = ZERO
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc_Legacy(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 4
        A(i, ip) = N(i)
      END DO
    END DO
    AT = TRANSPOSE(A)
    E = AT
    CALL invert_4x4(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_CPS4_GetExtrapMat

  SUBROUTINE PH_Elem_CPS4_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(4, 4)
    INTEGER(i4) :: ic, i, j, n_comp
    node_vars = ZERO
    CALL PH_Elem_CPS4_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 4
        DO j = 1, 4
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS4_MapToNode

END MODULE PH_Elem_CPS4



