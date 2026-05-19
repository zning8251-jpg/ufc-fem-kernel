!===============================================================================
! MODULE: PH_Elem_S8
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  S8 shell element definition (8-node)
!===============================================================================
MODULE PH_Elem_S8
!> [CORE] S8 shell element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE MD_Sect_Mgr, ONLY: MatDesc
  USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_StiffMatrix, PH_Elem_CPS8_FormIntForce, &
       PH_Elem_CPS8_ConsMass, PH_Elem_CPS8_LumpMass, PH_Elem_CPS8_ThermStrainVector, &
       PH_Elem_CPS8_ShapeFunc, PH_Elem_CPS8_Jac, PH_Elem_CPS8_GaussPoints
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  USE UF_Section
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_S8_StiffMatrix_Arg
  PUBLIC :: PH_Elem_S8_FormStiffMatrix
  PUBLIC :: PH_Elem_S8_StiffMatrix
  PUBLIC :: PH_Elem_S8_IntForce_Arg
  PUBLIC :: PH_Elem_S8_FormIntForce
  PUBLIC :: PH_Elem_S8_NL_TL_Arg, PH_Elem_S8_NL_TL
  PUBLIC :: PH_Elem_S8_NL_UL_Arg, PH_Elem_S8_NL_UL
  PUBLIC :: PH_Elem_S8_DefInit, PH_Elem_S8_ConsMass, PH_Elem_S8_LumpMass, PH_Elem_S8_ThermStrainVector
  PUBLIC :: PH_ELEM_S8_NNODE, PH_ELEM_S8_NIP, PH_ELEM_S8_NDOF, PH_ELEM_S8_NEDGE, PH_ELEM_S8_EDGE_NODES, PH_ELEM_S8_AreaInt
  PUBLIC :: UF_Elem_S8_Calc
  ! Sect, Constraints, Cont, Loads, Out (merged)
  PUBLIC :: PH_Elem_S8_GetArea, PH_Elem_S8_GetSectProps, PH_Elem_S8_GetCentroid
  PUBLIC :: PH_Elem_S8_ApplyConstraint, PH_Elem_S8_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_S8_FormContactContrib, PH_Elem_S8_FormContactEdgeCtr
  PUBLIC :: PH_Elem_S8_FormNodalForce, PH_Elem_S8_FormBodyForce, PH_Elem_S8_FormEdgePressure
  PUBLIC :: PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_EDGE_P
  PUBLIC :: PH_Elem_S8_CollectIPVars, PH_Elem_S8_MapToNode, PH_Elem_S8_GetExtrapMat, PH_Elem_S8_EvalVonMises
  PUBLIC :: PH_Elem_S8_Material_Update_Membrane_Routed

  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_S8_NNODE  = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S8_NIP   = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S8_NDOF  = 48_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S8_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S8_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  INTEGER(i4), PARAMETER :: PH_ELEM_S8_MEM_DOF(16) = [ 1, 2, 7, 8, 13, 14, 19, 20, 25, 26, 31, 32, 37, 38, 43, 44 ]

  !=============================================================================
  ! TYPES
  !=============================================================================

  TYPE, PUBLIC :: PH_Elem_S8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_StiffMatrix_Arg



  TYPE, PUBLIC :: PH_Elem_S8_IntForce_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_IntForce_Arg



  TYPE, PUBLIC :: PH_Elem_S8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    REAL(wp) :: thickness                   ! [IN]
    INTEGER(i4) :: n_layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_NL_TL_Arg



  TYPE, PUBLIC :: PH_Elem_S8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    REAL(wp) :: thickness                   ! [IN]
    INTEGER(i4) :: n_layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_NL_UL_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Defn (core)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(48, 48)
    REAL(wp) :: Me_m(16, 16)
    INTEGER(i4) :: i, j
    Me = ZERO
    CALL PH_Elem_CPS8_ConsMass(coords(1:2, 1:8), rho, Me_m)
    DO i = 1, 16
      DO j = 1, 16
        Me(PH_ELEM_S8_MEM_DOF(i), PH_ELEM_S8_MEM_DOF(j)) = Me_m(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S8_ConsMass

  SUBROUTINE PH_Elem_S8_DefInit()
  END SUBROUTINE PH_Elem_S8_DefInit

  SUBROUTINE PH_Elem_S8_FormIntForce_Legacy(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(48)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(48)
    TYPE(PH_Elem_S8_IntForce_Arg) :: in
    TYPE(PH_Elem_S8_IntForce_Arg) :: out
    in%coords = coords
    in%u = u
    in%E_young = E_young
    in%nu = nu
    CALL PH_Elem_S8_FormIntForce(arg)
    R_int = out%evo%R_int
  END SUBROUTINE PH_Elem_S8_FormIntForce_Legacy

  SUBROUTINE PH_Elem_S8_FormIntForce(arg)
    TYPE(PH_Elem_S8_IntForce_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: u_m(16), R_m(16)
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    arg%evo%R_int = ZERO
    DO i = 1, 16
      u_m(i) = arg%u(PH_ELEM_S8_MEM_DOF(i))
    END DO
    CALL PH_Elem_CPS8_FormIntForce(arg%coords(1:2, 1:8), u_m, arg%E_young, arg%nu, R_m)
    DO i = 1, 16
      arg%evo%R_int(PH_ELEM_S8_MEM_DOF(i)) = R_m(i)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S8_FormIntForce

  SUBROUTINE PH_Elem_S8_StiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(48, 48)
    REAL(wp) :: Ke_m(16, 16)
    INTEGER(i4) :: i, j

    Ke = ZERO
    CALL PH_Elem_CPS8_StiffMatrix(coords(1:2, 1:8), E_young, nu, Ke_m)
    DO i = 1, 16
      DO j = 1, 16
        Ke(PH_ELEM_S8_MEM_DOF(i), PH_ELEM_S8_MEM_DOF(j)) = Ke_m(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S8_StiffMatrix

  SUBROUTINE PH_Elem_S8_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(48, 48)
    CALL PH_Elem_S8_StiffMatrix(coords, E_young, nu, Ke)
  END SUBROUTINE PH_Elem_S8_FormStiffMatrix_Legacy

  SUBROUTINE PH_Elem_S8_FormStiffMatrix(arg)
    TYPE(PH_Elem_S8_StiffMatrix_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: Ke_m(16, 16)
    INTEGER(i4) :: i, j
    CALL init_error_status(arg%status)
    arg%evo%Ke = ZERO
    CALL PH_Elem_CPS8_StiffMatrix(arg%coords(1:2, 1:8), arg%E_young, arg%nu, Ke_m)
    DO i = 1, 16
      DO j = 1, 16
        arg%evo%Ke(PH_ELEM_S8_MEM_DOF(i), PH_ELEM_S8_MEM_DOF(j)) = Ke_m(i, j)
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S8_FormStiffMatrix

  SUBROUTINE PH_Elem_S8_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(48)
    REAL(wp) :: M_m(16)
    INTEGER(i4) :: i
    M_lumped = ZERO
    CALL PH_Elem_CPS8_LumpMass(coords(1:2, 1:8), rho, M_m)
    DO i = 1, 8
      M_lumped(PH_ELEM_S8_MEM_DOF(2*i-1)) = M_m(2*i-1)
      M_lumped(PH_ELEM_S8_MEM_DOF(2*i))   = M_m(2*i)
    END DO
  END SUBROUTINE PH_Elem_S8_LumpMass

  SUBROUTINE PH_Elem_S8_NL_TL(arg)
    TYPE(PH_Elem_S8_NL_TL_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: coords_curr(3, 8)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), J_ref(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: zeta_layer, wt_layer
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: K_mat_gp(48, 48), K_geo_gp(48, 48), R_gp(48)
    INTEGER(i4) :: i, igp, ilayer, gp_id
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: E_voigt(6), C_GL(3,3)

    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) ALLOCATE(arg%mat_state(SIZE(arg%mat_state)))
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO

    DO i = 1, 8
      coords_curr(:, i) = arg%coords_ref(:, i) + arg%lcl%u_elem(6*(i-1)+1:6*(i-1)+3)
    END DO

    cfg%formulation_typ = 1
    DO i = 1, 8
      cfg%coords_ref(i, :) = arg%coords_ref(:, i)
      cfg%coords_curr(i, :) = coords_curr(:, i)
    END DO

    CALL PH_Elem_CPS8_GaussPoints(xi_gp, eta_gp, wt_gp)
    gp_id = 0
    DO igp = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPS8_Jac(dN_dxi, arg%coords_ref(1:2, 1:8), J_ref, det_J)
      CALL Invert2x2(J_ref, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF

      DO i = 1, 8
        cfg%lcl%dN_dX(i, 1:2) = MATMUL(dN_dxi(:, i), J_inv)
        cfg%lcl%dN_dX(i, 3) = ZERO
      END DO

      DO ilayer = 1, arg%n_layers
        gp_id = gp_id + 1
        zeta_layer = -1.0_wp + (2.0_wp * (ilayer - 0.5_wp)) / REAL(arg%n_layers, wp)
        wt_layer = arg%thickness / REAL(arg%n_layers, wp)
        DO i = 1, 8
          cfg%lcl%dN_dX(i, 3) = N(i) * zeta_layer * 0.5_wp
        END DO
        F = ZERO
        DO i = 1, 8
          F(1, 1) = F(1, 1) + coords_curr(1, i) * cfg%lcl%dN_dX(i, 1)
          F(1, 2) = F(1, 2) + coords_curr(1, i) * cfg%lcl%dN_dX(i, 2)
          F(1, 3) = F(1, 3) + coords_curr(1, i) * cfg%lcl%dN_dX(i, 3)
          F(2, 1) = F(2, 1) + coords_curr(2, i) * cfg%lcl%dN_dX(i, 1)
          F(2, 2) = F(2, 2) + coords_curr(2, i) * cfg%lcl%dN_dX(i, 2)
          F(2, 3) = F(2, 3) + coords_curr(2, i) * cfg%lcl%dN_dX(i, 3)
          F(3, 1) = F(3, 1) + coords_curr(3, i) * cfg%lcl%dN_dX(i, 1)
          F(3, 2) = F(3, 2) + coords_curr(3, i) * cfg%lcl%dN_dX(i, 2)
          F(3, 3) = F(3, 3) + coords_curr(3, i) * cfg%lcl%dN_dX(i, 3)
        END DO
        C_GL(1,1) = F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1)
        C_GL(1,2) = F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2)
        C_GL(1,3) = F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3)
        C_GL(2,1) = C_GL(1,2)
        C_GL(2,2) = F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2)
        C_GL(2,3) = F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3)
        C_GL(3,1) = C_GL(1,3)
        C_GL(3,2) = C_GL(2,3)
        C_GL(3,3) = F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3)
        E(1,1) = 0.5_wp * (C_GL(1,1) - ONE)
        E(2,2) = 0.5_wp * (C_GL(2,2) - ONE)
        E(3,3) = 0.5_wp * (C_GL(3,3) - ONE)
        E(1,2) = 0.5_wp * C_GL(1,2)
        E(2,3) = 0.5_wp * C_GL(2,3)
        E(1,3) = 0.5_wp * C_GL(1,3)
        E(2,1) = E(1,2)
        E(3,2) = E(2,3)
        E(3,1) = E(1,3)
        E_voigt = [E(1,1), E(2,2), E(3,3), E(1,2), E(2,3), E(1,3)]
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= STATUS_SUCCESS) THEN
          arg%status%status_code = IF_STATUS_ERROR

          RETURN
        END IF
        S(1,1) = ss_gp%sigma(1)
        S(2,2) = ss_gp%sigma(2)
        S(3,3) = ss_gp%sigma(3)
        S(1,2) = ss_gp%sigma(4)
        S(2,3) = ss_gp%sigma(5)
        S(1,3) = ss_gp%sigma(6)
        S(2,1) = S(1,2)
        S(3,2) = S(2,3)
        S(3,1) = S(1,3)
        CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
        IF (arg%status%status_code /= STATUS_SUCCESS) THEN

          RETURN
        END IF
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%R_int = arg%evo%R_int + R_gp * det_J * wt_gp(igp) * wt_layer
      END DO
    END DO

  CONTAINS
    SUBROUTINE Invert2x2(A, A_inv, det, stat)
      REAL(wp), INTENT(IN) :: A(2, 2)
      REAL(wp), INTENT(OUT) :: A_inv(2, 2), det
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: tol
      tol = 1.0e-14_wp
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) < tol) THEN
        stat%status_code = IF_STATUS_ERROR
        RETURN
      END IF
      A_inv(1,1) =  A(2,2) / det
      A_inv(1,2) = -A(1,2) / det
      A_inv(2,1) = -A(2,1) / det
      A_inv(2,2) =  A(1,1) / det
      stat%status_code = STATUS_SUCCESS
    END SUBROUTINE Invert2x2
  END SUBROUTINE PH_Elem_S8_NL_TL

  SUBROUTINE PH_Elem_S8_NL_UL(arg)
    TYPE(PH_Elem_S8_NL_UL_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: coords_curr(3, 8)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(9), eta_gp(9), wt_gp(9)
    REAL(wp) :: N(8), dN_dxi(2, 8), J_prev(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: zeta_layer, wt_layer
    REAL(wp) :: F(3,3), epsilon(3,3), sigma(3,3)
    REAL(wp) :: K_mat_gp(48,48), K_geo_gp(48,48), R_gp(48)
    INTEGER(i4) :: i, igp, ilayer, gp_id
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: E_voigt(6), b(3,3), b_inv(3,3), e_Almansi(3,3), det_b

    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) ALLOCATE(arg%mat_state(SIZE(arg%mat_state)))
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO

    DO i = 1, 8
      coords_curr(:, i) = arg%coords_prev(:, i) + arg%u_incr(6*(i-1)+1:6*(i-1)+3)
    END DO

    cfg%formulation_typ = 2
    DO i = 1, 8
      cfg%coords_prev(i,:) = arg%coords_prev(:,i)
      cfg%coords_curr(i,:) = coords_curr(:,i)
    END DO

    CALL PH_Elem_CPS8_GaussPoints(xi_gp, eta_gp, wt_gp)
    gp_id = 0
    DO igp = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPS8_Jac(dN_dxi, arg%coords_prev(1:2, 1:8), J_prev, det_J)
      CALL Invert2x2(J_prev, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF

      DO i = 1, 8
        cfg%dN_dx(i, 1:2) = MATMUL(dN_dxi(:, i), J_inv)
        cfg%dN_dx(i, 3) = ZERO
      END DO

      DO ilayer = 1, arg%n_layers
        gp_id = gp_id + 1
        zeta_layer = -1.0_wp + (2.0_wp * (ilayer - 0.5_wp)) / REAL(arg%n_layers, wp)
        wt_layer = arg%thickness / REAL(arg%n_layers, wp)
        DO i = 1, 8
          cfg%dN_dx(i, 3) = N(i) * zeta_layer * 0.5_wp
        END DO
        F = ZERO
        DO i = 1, 8
          F(1, 1) = F(1, 1) + coords_curr(1, i) * cfg%dN_dx(i, 1)
          F(1, 2) = F(1, 2) + coords_curr(1, i) * cfg%dN_dx(i, 2)
          F(1, 3) = F(1, 3) + coords_curr(1, i) * cfg%dN_dx(i, 3)
          F(2, 1) = F(2, 1) + coords_curr(2, i) * cfg%dN_dx(i, 1)
          F(2, 2) = F(2, 2) + coords_curr(2, i) * cfg%dN_dx(i, 2)
          F(2, 3) = F(2, 3) + coords_curr(2, i) * cfg%dN_dx(i, 3)
          F(3, 1) = F(3, 1) + coords_curr(3, i) * cfg%dN_dx(i, 1)
          F(3, 2) = F(3, 2) + coords_curr(3, i) * cfg%dN_dx(i, 2)
          F(3, 3) = F(3, 3) + coords_curr(3, i) * cfg%dN_dx(i, 3)
        END DO
        b(1,1) = F(1,1)*F(1,1) + F(1,2)*F(1,2) + F(1,3)*F(1,3)
        b(1,2) = F(1,1)*F(2,1) + F(1,2)*F(2,2) + F(1,3)*F(2,3)
        b(2,1) = b(1,2)
        b(1,3) = F(1,1)*F(3,1) + F(1,2)*F(3,2) + F(1,3)*F(3,3)
        b(3,1) = b(1,3)
        b(2,2) = F(2,1)*F(2,1) + F(2,2)*F(2,2) + F(2,3)*F(2,3)
        b(2,3) = F(2,1)*F(3,1) + F(2,2)*F(3,2) + F(2,3)*F(3,3)
        b(3,2) = b(2,3)
        b(3,3) = F(3,1)*F(3,1) + F(3,2)*F(3,2) + F(3,3)*F(3,3)
        det_b = b(1,1)*(b(2,2)*b(3,3) - b(2,3)*b(3,2)) - b(1,2)*(b(2,1)*b(3,3) - b(2,3)*b(3,1)) + b(1,3)*(b(2,1)*b(3,2) - b(2,2)*b(3,1))
        b_inv(1,1) = (b(2,2)*b(3,3) - b(2,3)*b(3,2)) / det_b
        b_inv(1,2) = (b(1,3)*b(3,2) - b(1,2)*b(3,3)) / det_b
        b_inv(1,3) = (b(1,2)*b(2,3) - b(1,3)*b(2,2)) / det_b
        b_inv(2,1) = (b(2,3)*b(3,1) - b(2,1)*b(3,3)) / det_b
        b_inv(2,2) = (b(1,1)*b(3,3) - b(1,3)*b(3,1)) / det_b
        b_inv(2,3) = (b(1,3)*b(2,1) - b(1,1)*b(2,3)) / det_b
        b_inv(3,1) = (b(2,1)*b(3,2) - b(2,2)*b(3,1)) / det_b
        b_inv(3,2) = (b(1,2)*b(3,1) - b(1,1)*b(3,2)) / det_b
        b_inv(3,3) = (b(1,1)*b(2,2) - b(1,2)*b(2,1)) / det_b
        e_Almansi(1,1) = 0.5_wp * (ONE - b_inv(1,1))
        e_Almansi(2,2) = 0.5_wp * (ONE - b_inv(2,2))
        e_Almansi(3,3) = 0.5_wp * (ONE - b_inv(3,3))
        e_Almansi(1,2) = 0.5_wp * (- b_inv(1,2))
        e_Almansi(2,3) = 0.5_wp * (- b_inv(2,3))
        e_Almansi(1,3) = 0.5_wp * (- b_inv(1,3))
        e_Almansi(2,1) = e_Almansi(1,2)
        e_Almansi(3,2) = e_Almansi(2,3)
        e_Almansi(3,1) = e_Almansi(1,3)
        E_voigt = [e_Almansi(1,1), e_Almansi(2,2), e_Almansi(3,3), e_Almansi(1,2), e_Almansi(2,3), e_Almansi(1,3)]
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= STATUS_SUCCESS) THEN
          arg%status%status_code = IF_STATUS_ERROR

          RETURN
        END IF
        sigma(1,1) = ss_gp%sigma(1)
        sigma(2,2) = ss_gp%sigma(2)
        sigma(3,3) = ss_gp%sigma(3)
        sigma(1,2) = ss_gp%sigma(4)
        sigma(2,3) = ss_gp%sigma(5)
        sigma(1,3) = ss_gp%sigma(6)
        sigma(2,1) = sigma(1,2)
        sigma(3,2) = sigma(2,3)
        sigma(3,1) = sigma(1,3)
        CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
        IF (arg%status%status_code /= STATUS_SUCCESS) THEN

          RETURN
        END IF
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%R_int = arg%evo%R_int + R_gp * det_J * wt_gp(igp) * wt_layer
      END DO
    END DO

  CONTAINS
    SUBROUTINE Invert2x2(A, A_inv, det, stat)
      REAL(wp), INTENT(IN) :: A(2,2)
      REAL(wp), INTENT(OUT) :: A_inv(2,2), det
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: tol
      tol = 1.0e-14_wp
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) < tol) THEN
        stat%status_code = IF_STATUS_ERROR
        RETURN
      END IF
      A_inv(1,1) =  A(2,2) / det
      A_inv(1,2) = -A(1,2) / det
      A_inv(2,1) = -A(2,1) / det
      A_inv(2,2) =  A(1,1) / det
      stat%status_code = STATUS_SUCCESS
    END SUBROUTINE Invert2x2
  END SUBROUTINE PH_Elem_S8_NL_UL

  SUBROUTINE PH_Elem_S8_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    REAL(wp) :: e(3)
    CALL PH_Elem_CPS8_ThermStrainVector(alpha, deltaT, e)
    eps_th = ZERO
    IF (SIZE(eps_th) >= 3) eps_th(1:3) = e(1:3)
  END SUBROUTINE PH_Elem_S8_ThermStrainVector

  SUBROUTINE PH_ELEM_S8_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS8_Jac(dNdxi, coords(1:2, 1:8), J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_S8_AreaInt

  SUBROUTINE UF_Elem_S8_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    REAL(wp) :: coords(3, PH_ELEM_S8_NNODE)
    REAL(wp) :: u(PH_ELEM_S8_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_S8_NDOF, PH_ELEM_S8_NDOF)
    REAL(wp) :: R_int(PH_ELEM_S8_NDOF)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.
    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < PH_ELEM_S8_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S8_Calc: invalid coords_ref'
      RETURN
    END IF

    DO i = 1, PH_ELEM_S8_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
      IF (SIZE(Ctx%coords_ref, 1) < 3) coords(3, i) = 0.0_wp
    END DO

    u = 0.0_wp
    IF (ALLOCATED(state_in%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S8_NDOF, SIZE(state_in%Re))
        u(i) = state_in%Re(i)
      END DO
    END IF

    E_young = 0.0_wp
    nu = 0.0_wp
    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) E_young = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) nu = Mat%props%props(2)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S8_Calc: invalid E_young'
      RETURN
    END IF

    CALL PH_Elem_S8_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    CALL PH_Elem_S8_FormIntForce_Legacy(coords, u, E_young, nu, R_int)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, needMass=.FALSE., needDamp=.FALSE.)

    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_S8_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_S8_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S8_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    flags%status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_S8_Calc

  !-----------------------------------------------------------------------------
  ! Sect (merged)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_S8_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_S8_GetArea

  SUBROUTINE PH_Elem_S8_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS8_Jac(dNdxi, coords(1:2, 1:8), J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 3
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
      centroid(3) = centroid(3) / area
    END IF
  END SUBROUTINE PH_Elem_S8_GetCentroid

  SUBROUTINE PH_Elem_S8_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_S8_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_S8_GetSectProps

  !-----------------------------------------------------------------------------
  ! Constraints (merged)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(48, 48)
    REAL(wp), INTENT(INOUT) :: F_el(48)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 48) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_S8_ApplyConstraint

  SUBROUTINE PH_Elem_S8_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(48)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(48, 48)
    REAL(wp), INTENT(INOUT) :: F_el(48)
    INTEGER(i4) :: i, j
    DO i = 1, 48
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 48
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S8_ApplyMPC

  !-----------------------------------------------------------------------------
  ! Cont (merged) - FormContactEdgeCtr uses INOUT for K_el, F_el and ADD
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(48, 48)
    REAL(wp), INTENT(INOUT) :: F_el(48)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 8
      ia = (a - 1) * 6 + 1
      f_a(1:3) = penalty * gap * N(a) * edge_len * n(1:3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 8
      DO b = 1, 8
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = (a - 1) * 6 + 1
        ib = (b - 1) * 6 + 1
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
  END SUBROUTINE PH_Elem_S8_FormContactContrib

  SUBROUTINE PH_Elem_S8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(48, 48)
    REAL(wp), INTENT(INOUT) :: F_el(48)
    REAL(wp) :: xi, eta, N(8), n(3), dNdxi(2, 8)
    REAL(wp) :: t(3), len
    INTEGER(i4) :: n1, n2
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_S8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S8_EDGE_NODES(2, edge_id)
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
    CALL PH_Elem_CPS8_ShapeFunc(xi, eta, N, dNdxi)
    t(1:3) = coords(1:3, n2) - coords(1:3, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2) + t(3)*t(3))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    n(3) = 0.0_wp
    CALL PH_Elem_S8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_S8_FormContactEdgeCtr

  !-----------------------------------------------------------------------------
  ! Loads (merged)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(48)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS8_Jac(dNdxi, coords(1:2, 1:8), J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq((i-1)*6+1) = F_eq((i-1)*6+1) + N(i) * bx * detJ * weights(ip)
        F_eq((i-1)*6+2) = F_eq((i-1)*6+2) + N(i) * by * detJ * weights(ip)
        F_eq((i-1)*6+3) = F_eq((i-1)*6+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S8_FormBodyForce

  SUBROUTINE PH_Elem_S8_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(48)
    REAL(wp) :: v1(3), v2(3), n_el(3), len, t(3)
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_S8_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S8_EDGE_NODES(2, edge_id)
    v1(1:3) = coords(1:3, 2) - coords(1:3, 1)
    v2(1:3) = coords(1:3, 4) - coords(1:3, 1)
    n_el(1) = v1(2)*v2(3) - v1(3)*v2(2)
    n_el(2) = v1(3)*v2(1) - v1(1)*v2(3)
    n_el(3) = v1(1)*v2(2) - v1(2)*v2(1)
    len = SQRT(n_el(1)*n_el(1) + n_el(2)*n_el(2) + n_el(3)*n_el(3))
    IF (len < 1.0e-15_wp) RETURN
    n_el = n_el / len
    t(1:3) = coords(1:3, n2) - coords(1:3, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2) + t(3)*t(3))
    IF (len < 1.0e-15_wp) RETURN
    F_eq((n1-1)*6+1) = F_eq((n1-1)*6+1) + p * len * HALF * n_el(1)
    F_eq((n1-1)*6+2) = F_eq((n1-1)*6+2) + p * len * HALF * n_el(2)
    F_eq((n1-1)*6+3) = F_eq((n1-1)*6+3) + p * len * HALF * n_el(3)
    F_eq((n2-1)*6+1) = F_eq((n2-1)*6+1) + p * len * HALF * n_el(1)
    F_eq((n2-1)*6+2) = F_eq((n2-1)*6+2) + p * len * HALF * n_el(2)
    F_eq((n2-1)*6+3) = F_eq((n2-1)*6+3) + p * len * HALF * n_el(3)
  END SUBROUTINE PH_Elem_S8_FormEdgePressure

  SUBROUTINE PH_Elem_S8_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(48)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 3) THEN
      CALL PH_Elem_S8_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_S8_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_S8_FormNodalForce

  !-----------------------------------------------------------------------------
  ! Out (merged)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 9)
      IF (SIZE(out_vars, 1) >= 3 .AND. SIZE(ip_stress, 1) >= 3) out_vars(1:3, ip) = ip_stress(1:3, ip)
      IF (SIZE(ip_strain, 1) >= 3) out_vars(4:6, ip) = ip_strain(1:3, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(7, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_S8_CollectIPVars

  SUBROUTINE PH_Elem_S8_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s11, s22, s12
    seq = ZERO
    IF (SIZE(sigma) >= 3) THEN
      s11 = sigma(1)
      s22 = sigma(2)
      s12 = sigma(3)
      seq = SQRT(s11*s11 + s22*s22 - s11*s22 + 3.0_wp*s12*s12)
    END IF
  END SUBROUTINE PH_Elem_S8_EvalVonMises

  SUBROUTINE PH_Elem_S8_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(8, 9)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8)
    INTEGER(i4) :: ip, i
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    E = ZERO
    DO ip = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 8
        E(i, ip) = N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S8_GetExtrapMat

  SUBROUTINE PH_Elem_S8_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(8, 9)
    INTEGER(i4) :: nv, n_ip
    node_vars = ZERO
    CALL PH_Elem_S8_GetExtrapMat(E)
    nv = MIN(SIZE(ip_vars, 1), SIZE(node_vars, 1))
    n_ip = MIN(SIZE(ip_vars, 2), SIZE(weights), 9)
    IF (nv >= 1 .AND. n_ip >= 1) THEN
      node_vars(1:nv, 1:8) = MATMUL(ip_vars(1:nv, 1:n_ip), TRANSPOSE(E(1:8, 1:n_ip)))
    END IF
  END SUBROUTINE PH_Elem_S8_MapToNode

  SUBROUTINE PH_Elem_S8_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                        stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticPlaneStress

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_S8_Material_Update_Membrane_Routed

END MODULE PH_Elem_S8


