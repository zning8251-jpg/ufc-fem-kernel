!===============================================================================
! MODULE: PH_Elem_S3
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  S3 shell element definition (3-node triangle)
!===============================================================================
MODULE PH_Elem_S3
!> [CORE] S3 shell element unified interface (merged 6 files)
!> Theory: K = K_mem, membrane from CPE3, 3 Gauss points triangle quadrature
!> Status: CORE | Last verified: 2026-02-28
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE MD_Sect_Mgr, ONLY: MatDesc
  USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_FormStiffMatrix, PH_Elem_CPE3_FormIntForce, &
       PH_Elem_CPE3_ConsMass, PH_Elem_CPE3_LumpMass, PH_Elem_CPE3_ThermStrainVector, &
       PH_Elem_CPE3_ShapeFunc, PH_Elem_CPE3_Jac, PH_Elem_CPE3_GaussPoints
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  USE UF_Section
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  ! Structured interfaces (new)
  PUBLIC :: PH_Elem_S3_StiffMatrix_Arg
  PUBLIC :: PH_Elem_S3_FormStiffMatrix
  PUBLIC :: PH_Elem_S3_IntForce_Arg
  PUBLIC :: PH_Elem_S3_FormIntForce
  PUBLIC :: PH_Elem_S3_NL_TL_Arg
  PUBLIC :: PH_Elem_S3_NL_TL
  PUBLIC :: PH_Elem_S3_NL_UL_Arg
  PUBLIC :: PH_Elem_S3_NL_UL
  
  ! Legacy interfaces (kept for backward compatibility)
  PUBLIC :: PH_Elem_S3_DefInit
  PUBLIC :: PH_Elem_S3_ConsMass
  PUBLIC :: PH_Elem_S3_LumpMass
  PUBLIC :: PH_Elem_S3_ThermStrainVector
  PUBLIC :: PH_ELEM_S3_NNODE
  PUBLIC :: PH_ELEM_S3_NIP
  PUBLIC :: PH_ELEM_S3_NDOF
  PUBLIC :: PH_ELEM_S3_NEDGE
  PUBLIC :: PH_ELEM_S3_EDGE_NODES
  PUBLIC :: PH_ELEM_S3_AreaInt
  PUBLIC :: UF_Elem_S3_Calc
  ! Sect, Constraints, Cont, Loads, Out (merged)
  PUBLIC :: PH_Elem_S3_GetArea
  PUBLIC :: PH_Elem_S3_GetSectProps
  PUBLIC :: PH_Elem_S3_GetCentroid
  PUBLIC :: PH_Elem_S3_ApplyConstraint
  PUBLIC :: PH_Elem_S3_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF
  PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_S3_FormContactContrib
  PUBLIC :: PH_Elem_S3_FormContactEdgeCtr
  PUBLIC :: PH_Elem_S3_FormNodalForce
  PUBLIC :: PH_Elem_S3_FormBodyForce
  PUBLIC :: PH_Elem_S3_FormEdgePressure
  PUBLIC :: PH_ELEM_LOAD_BODY
  PUBLIC :: PH_ELEM_LOAD_EDGE_P
  PUBLIC :: PH_Elem_S3_CollectIPVars
  PUBLIC :: PH_Elem_S3_MapToNode
  PUBLIC :: PH_Elem_S3_GetExtrapMat
  PUBLIC :: PH_Elem_S3_EvalVonMises
  PUBLIC :: PH_Elem_S3_Material_Update_Membrane_Routed

  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_S3_NNODE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S3_NIP   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S3_NDOF  = 18_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S3_NEDGE = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S3_EDGE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  ! Membrane DOF indices in 18-vector: node i -> (1:2) -> (i-1)*6+1, (i-1)*6+2
  INTEGER(i4), PARAMETER :: PH_ELEM_S3_MEM_DOF(6) = [ 1, 2, 7, 8, 13, 14 ]

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for stiffness matrix computation
  
  !> @brief Output structure for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_S3_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_StiffMatrix_Arg


  !> @brief Input structure for internal force computation
  
  !> @brief Output structure for internal force computation
  TYPE, PUBLIC :: PH_Elem_S3_IntForce_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_IntForce_Arg


  !> @brief Input structure for Total Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_S3_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness integration layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_NL_TL_Arg


  !> @brief Input structure for Updated Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_S3_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness integration layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_NL_UL_Arg


CONTAINS

  SUBROUTINE PH_Elem_S3_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(18, 18)
    REAL(wp) :: Me_m(6, 6)
    INTEGER(i4) :: i, j
    Me = ZERO
    CALL PH_Elem_CPE3_ConsMass(coords(1:2, 1:3), rho, Me_m)
    DO i = 1, 6
      DO j = 1, 6
        Me(PH_ELEM_S3_MEM_DOF(i), PH_ELEM_S3_MEM_DOF(j)) = Me_m(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S3_ConsMass

  SUBROUTINE PH_Elem_S3_DefInit()
  END SUBROUTINE PH_Elem_S3_DefInit

  SUBROUTINE PH_Elem_S3_FormIntForce(arg)
    TYPE(PH_Elem_S3_IntForce_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: u_m(6), R_m(6)
    INTEGER(i4) :: i
    
    CALL init_error_status(arg%status)
    
    arg%evo%R_int = ZERO
    
    ! Extract membrane DOF
    DO i = 1, 6
      u_m(i) = arg%u(PH_ELEM_S3_MEM_DOF(i))
    END DO
    
    ! Compute membrane internal force using CPE3
    CALL PH_Elem_CPE3_FormIntForce(arg%coords(1:2, 1:3), u_m, arg%E_young, arg%nu, R_m)
    
    ! Scatter membrane internal force to shell DOF
    DO i = 1, 6
      arg%evo%R_int(PH_ELEM_S3_MEM_DOF(i)) = R_m(i)
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_S3_FormIntForce

  SUBROUTINE PH_Elem_S3_FormIntForce_Legacy(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: u(18)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(18)
    TYPE(PH_Elem_S3_IntForce_Arg) :: in_struct
    TYPE(PH_Elem_S3_IntForce_Arg) :: out_struct
    in_struct%coords = coords
    in_struct%u = u
    in_struct%E_young = E_young
    in_struct%nu = nu
    CALL PH_Elem_S3_FormIntForce(arg_struct)
    R_int = out_struct%evo%R_int
  END SUBROUTINE PH_Elem_S3_FormIntForce_Legacy

  SUBROUTINE PH_Elem_S3_FormStiffMatrix(arg)
    TYPE(PH_Elem_S3_StiffMatrix_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: Ke_m(6, 6)
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    arg%evo%Ke = ZERO
    
    ! Compute membrane stiffness using CPE3
    CALL PH_Elem_CPE3_FormStiffMatrix(arg%coords(1:2, 1:3), arg%E_young, arg%nu, Ke_m)
    
    ! Scatter membrane stiffness to shell DOF
    DO i = 1, 6
      DO j = 1, 6
        arg%evo%Ke(PH_ELEM_S3_MEM_DOF(i), PH_ELEM_S3_MEM_DOF(j)) = Ke_m(i, j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_S3_FormStiffMatrix

  SUBROUTINE PH_Elem_S3_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(18, 18)
    TYPE(PH_Elem_S3_StiffMatrix_Arg) :: in_struct
    TYPE(PH_Elem_S3_StiffMatrix_Arg) :: out_struct
    in_struct%coords = coords
    in_struct%E_young = E_young
    in_struct%nu = nu
    CALL PH_Elem_S3_FormStiffMatrix(arg_struct)
    Ke = out_struct%evo%Ke
  END SUBROUTINE PH_Elem_S3_FormStiffMatrix_Legacy

  SUBROUTINE PH_Elem_S3_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(18)
    REAL(wp) :: M_m(6)
    INTEGER(i4) :: i
    M_lumped = ZERO
    CALL PH_Elem_CPE3_LumpMass(coords(1:2, 1:3), rho, M_m)
    DO i = 1, 3
      M_lumped(PH_ELEM_S3_MEM_DOF(2*i-1)) = M_m(2*i-1)
      M_lumped(PH_ELEM_S3_MEM_DOF(2*i))   = M_m(2*i)
    END DO
  END SUBROUTINE PH_Elem_S3_LumpMass

  SUBROUTINE PH_Elem_S3_NL_TL(arg)
    TYPE(PH_Elem_S3_NL_TL_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: coords_curr(3, 3)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), J_ref(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: zeta_layer, wt_layer
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: K_mat_gp(18, 18), K_geo_gp(18, 18), R_gp(18)
    INTEGER(i4) :: i, igp, ilayer, gp_id
    ! Mat constitutive variables
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: E_voigt(6), C_GL(3,3)
    
    CALL init_error_status(arg%status)
    
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO
    
    ! Compute current coordinates
    DO i = 1, 3
      coords_curr(:, i) = arg%coords_ref(:, i) + arg%lcl%u_elem(6*(i-1)+1:6*(i-1)+3)
    END DO

    cfg%formulation_typ = 1
    DO i = 1, 3
      cfg%coords_ref(i, :) = arg%coords_ref(:, i)
      cfg%coords_curr(i, :) = coords_curr(:, i)
    END DO
    
    CALL PH_Elem_CPE3_GaussPoints(xi_gp, eta_gp, wt_gp)
    gp_id = 0
    DO igp = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPE3_Jac(dN_dxi, arg%coords_ref(1:2, 1:3), J_ref, det_J)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
      CALL Invert2x2(J_ref, J_inv, det_J)
      
      DO i = 1, 3
        cfg%lcl%dN_dX(i, 1:2) = MATMUL(dN_dxi(:, i), J_inv)
        cfg%lcl%dN_dX(i, 3) = ZERO
      END DO
      
      DO ilayer = 1, arg%n_layers
        gp_id = gp_id + 1
        zeta_layer = -1.0_wp + (2.0_wp * (ilayer - 0.5_wp)) / REAL(arg%n_layers, wp)
        wt_layer = arg%thickness / REAL(arg%n_layers, wp)
        
        ! Update dN_dX for thickness direction
        DO i = 1, 3
          cfg%lcl%dN_dX(i, 3) = N(i) * zeta_layer * 0.5_wp
        END DO
        
        ! ===== Mat Constitutive Call (TL mode, shell 3D state) =====
        ! Compute 3D deformation gradient F = ?x/?X
        F = ZERO
        DO i = 1, 3
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
        
        ! Right Cauchy-Green tensor C = F^T*F
        C_GL(1,1) = F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1)
        C_GL(1,2) = F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2)
        C_GL(1,3) = F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3)
        C_GL(2,1) = C_GL(1,2)
        C_GL(2,2) = F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2)
        C_GL(2,3) = F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3)
        C_GL(3,1) = C_GL(1,3)
        C_GL(3,2) = C_GL(2,3)
        C_GL(3,3) = F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3)
        
        ! Green-Lagrange strain E = 0.5*(C - I)
        E(1,1) = 0.5_wp * (C_GL(1,1) - ONE)
        E(2,2) = 0.5_wp * (C_GL(2,2) - ONE)
        E(3,3) = 0.5_wp * (C_GL(3,3) - ONE)
        E(1,2) = 0.5_wp * C_GL(1,2)
        E(2,3) = 0.5_wp * C_GL(2,3)
        E(1,3) = 0.5_wp * C_GL(1,3)
        E(2,1) = E(1,2)
        E(3,2) = E(2,3)
        E(3,1) = E(1,3)
        
        ! Voigt notation
        E_voigt(1) = E(1,1)
        E_voigt(2) = E(2,2)
        E_voigt(3) = E(3,3)
        E_voigt(4) = E(1,2)
        E_voigt(5) = E(2,3)
        E_voigt(6) = E(1,3)
        
        ! Call Mat constitutive
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= IF_STATUS_OK) THEN
          arg%status%status_code = IF_STATUS_INVALID
          arg%status%message = "S3 TL: Material constitutive failed"

          RETURN
        END IF
        
        ! Extract 2nd Piola-Kirchhoff stress
        S(1,1) = ss_gp%sigma(1)
        S(2,2) = ss_gp%sigma(2)
        S(3,3) = ss_gp%sigma(3)
        S(1,2) = ss_gp%sigma(4)
        S(2,3) = ss_gp%sigma(5)
        S(1,3) = ss_gp%sigma(6)
        S(2,1) = S(1,2)
        S(3,2) = S(2,3)
        S(3,1) = S(1,3)
        ! ===== End Mat Constitutive Call =====
        
        CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, mat_status, R_gp, ss_gp%tangent)
        IF (mat_status%status_code /= IF_STATUS_OK) THEN
          arg%status = mat_status

          RETURN
        END IF
        
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%R_int = arg%evo%R_int + R_gp * det_J * wt_gp(igp) * wt_layer
      END DO
    END DO

    IF (arg%status%status_code == IF_STATUS_OK) THEN
      arg%status%status_code = IF_STATUS_OK
    END IF
    
  CONTAINS
    SUBROUTINE Invert2x2(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(2, 2)
      REAL(wp), INTENT(OUT) :: A_inv(2, 2), det
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) > 1.0e-20_wp) THEN
        A_inv(1,1) =  A(2,2)/det
        A_inv(1,2) = -A(1,2)/det
        A_inv(2,1) = -A(2,1)/det
        A_inv(2,2) =  A(1,1)/det
      ELSE
        A_inv = ZERO
      END IF
    END SUBROUTINE Invert2x2
  END SUBROUTINE PH_Elem_S3_NL_TL

  SUBROUTINE PH_Elem_S3_NL_TL_Legacy(coords_ref, u_elem, mat_prop, mat_state, thickness, n_layers, &
                                      Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 3)
    REAL(wp), INTENT(IN)  :: u_elem(18)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: thickness
    INTEGER(i4), INTENT(IN) :: n_layers
    REAL(wp), INTENT(OUT) :: Ke_mat(18, 18)
    REAL(wp), INTENT(OUT) :: Ke_geo(18, 18)
    REAL(wp), INTENT(OUT) :: R_int(18)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PH_Elem_S3_NL_TL_Arg) :: in_struct
    TYPE(PH_Elem_S3_NL_TL_Arg) :: out_struct
    in_struct%coords_ref = coords_ref
    in_struct%lcl%u_elem = u_elem
    in_struct%mat_prop = mat_prop
    ALLOCATE(in_struct%mat_state(SIZE(mat_state)))
    in_struct%mat_state = mat_state
    in_struct%thickness = thickness
    in_struct%n_layers = n_layers
    CALL PH_Elem_S3_NL_TL(arg_struct)
    Ke_mat = out_struct%evo%Ke_mat
    Ke_geo = out_struct%evo%Ke_geo
    R_int = out_struct%evo%R_int
    status = out_struct%status
    mat_state = out_struct%mat_state
  END SUBROUTINE PH_Elem_S3_NL_TL_Legacy

  SUBROUTINE PH_Elem_S3_NL_UL(arg)
    TYPE(PH_Elem_S3_NL_UL_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: coords_curr(3, 3)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(3), eta_gp(3), wt_gp(3)
    REAL(wp) :: N(3), dN_dxi(2, 3), J_prev(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: zeta_layer, wt_layer
    REAL(wp) :: F(3,3), epsilon(3,3), sigma(3,3)
    REAL(wp) :: K_mat_gp(18,18), K_geo_gp(18,18), R_gp(18)
    INTEGER(i4) :: i, igp, ilayer, gp_id
    ! Mat constitutive variables
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: E_voigt(6), b(3,3), b_inv(3,3), e_Almansi(3,3), det_b
    
    CALL init_error_status(arg%status)
    
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int = ZERO
    
    ! Compute current coordinates
    DO i = 1, 3
      coords_curr(:, i) = arg%coords_prev(:, i) + arg%u_incr(6*(i-1)+1:6*(i-1)+3)
    END DO

    cfg%formulation_typ = 2
    DO i = 1, 3
      cfg%coords_prev(i,:) = arg%coords_prev(:,i)
      cfg%coords_curr(i,:) = coords_curr(:,i)
    END DO
    
    CALL PH_Elem_CPE3_GaussPoints(xi_gp, eta_gp, wt_gp)
    gp_id = 0
    DO igp = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi_gp(igp), eta_gp(igp), N, dN_dxi)
      CALL PH_Elem_CPE3_Jac(dN_dxi, arg%coords_prev(1:2, 1:3), J_prev, det_J)
      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
      CALL Invert2x2(J_prev, J_inv, det_J)
      
      DO i = 1, 3
        cfg%dN_dx(i, 1:2) = MATMUL(dN_dxi(:, i), J_inv)
        cfg%dN_dx(i, 3) = ZERO
      END DO
      
      DO ilayer = 1, arg%n_layers
        gp_id = gp_id + 1
        zeta_layer = -1.0_wp + (2.0_wp * (ilayer - 0.5_wp)) / REAL(arg%n_layers, wp)
        wt_layer = arg%thickness / REAL(arg%n_layers, wp)
        
        ! Update dN_dx for thickness direction
        DO i = 1, 3
          cfg%dN_dx(i, 3) = N(i) * zeta_layer * 0.5_wp
        END DO
        
        ! ===== Mat Constitutive Call (UL mode, shell 3D state) =====
        ! Compute 3D deformation gradient F = ?x_{n+1}/?x_n
        F = ZERO
        DO i = 1, 3
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
        
        ! Left Cauchy-Green tensor b = F*F^T
        b(1,1) = F(1,1)*F(1,1) + F(1,2)*F(1,2) + F(1,3)*F(1,3)
        b(1,2) = F(1,1)*F(2,1) + F(1,2)*F(2,2) + F(1,3)*F(2,3)
        b(1,3) = F(1,1)*F(3,1) + F(1,2)*F(3,2) + F(1,3)*F(3,3)
        b(2,1) = b(1,2)
        b(2,2) = F(2,1)*F(2,1) + F(2,2)*F(2,2) + F(2,3)*F(2,3)
        b(2,3) = F(2,1)*F(3,1) + F(2,2)*F(3,2) + F(2,3)*F(3,3)
        b(3,1) = b(1,3)
        b(3,2) = b(2,3)
        b(3,3) = F(3,1)*F(3,1) + F(3,2)*F(3,2) + F(3,3)*F(3,3)
        
        ! Compute b^{-1}
        det_b = b(1,1)*(b(2,2)*b(3,3) - b(2,3)*b(3,2)) &
              - b(1,2)*(b(2,1)*b(3,3) - b(2,3)*b(3,1)) &
              + b(1,3)*(b(2,1)*b(3,2) - b(2,2)*b(3,1))
        
        b_inv(1,1) = (b(2,2)*b(3,3) - b(2,3)*b(3,2)) / det_b
        b_inv(1,2) = (b(1,3)*b(3,2) - b(1,2)*b(3,3)) / det_b
        b_inv(1,3) = (b(1,2)*b(2,3) - b(1,3)*b(2,2)) / det_b
        b_inv(2,1) = (b(2,3)*b(3,1) - b(2,1)*b(3,3)) / det_b
        b_inv(2,2) = (b(1,1)*b(3,3) - b(1,3)*b(3,1)) / det_b
        b_inv(2,3) = (b(1,3)*b(2,1) - b(1,1)*b(2,3)) / det_b
        b_inv(3,1) = (b(2,1)*b(3,2) - b(2,2)*b(3,1)) / det_b
        b_inv(3,2) = (b(1,2)*b(3,1) - b(1,1)*b(3,2)) / det_b
        b_inv(3,3) = (b(1,1)*b(2,2) - b(1,2)*b(2,1)) / det_b
        
        ! Almansi strain e = 0.5*(I - b^{-1})
        e_Almansi(1,1) = 0.5_wp * (ONE - b_inv(1,1))
        e_Almansi(2,2) = 0.5_wp * (ONE - b_inv(2,2))
        e_Almansi(3,3) = 0.5_wp * (ONE - b_inv(3,3))
        e_Almansi(1,2) = 0.5_wp * (- b_inv(1,2))
        e_Almansi(2,3) = 0.5_wp * (- b_inv(2,3))
        e_Almansi(1,3) = 0.5_wp * (- b_inv(1,3))
        e_Almansi(2,1) = e_Almansi(1,2)
        e_Almansi(3,2) = e_Almansi(2,3)
        e_Almansi(3,1) = e_Almansi(1,3)
        
        ! Voigt notation
        E_voigt(1) = e_Almansi(1,1)
        E_voigt(2) = e_Almansi(2,2)
        E_voigt(3) = e_Almansi(3,3)
        E_voigt(4) = e_Almansi(1,2)
        E_voigt(5) = e_Almansi(2,3)
        E_voigt(6) = e_Almansi(1,3)
        
        ! Call Mat constitutive
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= IF_STATUS_OK) THEN
          arg%status%status_code = IF_STATUS_INVALID
          arg%status%message = "S3 UL: Material constitutive failed"

          RETURN
        END IF
        
        ! Extract Cauchy stress
        sigma(1,1) = ss_gp%sigma(1)
        sigma(2,2) = ss_gp%sigma(2)
        sigma(3,3) = ss_gp%sigma(3)
        sigma(1,2) = ss_gp%sigma(4)
        sigma(2,3) = ss_gp%sigma(5)
        sigma(1,3) = ss_gp%sigma(6)
        sigma(2,1) = sigma(1,2)
        sigma(3,2) = sigma(2,3)
        sigma(3,1) = sigma(1,3)
        ! ===== End Mat Constitutive Call =====
        
        CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, mat_status, R_gp, ss_gp%tangent)
        IF (mat_status%status_code /= IF_STATUS_OK) THEN
          arg%status = mat_status

          RETURN
        END IF
        
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp(igp) * wt_layer
        arg%evo%R_int = arg%evo%R_int + R_gp * det_J * wt_gp(igp) * wt_layer
      END DO
    END DO

    IF (arg%status%status_code == IF_STATUS_OK) THEN
      arg%status%status_code = IF_STATUS_OK
    END IF
    
  CONTAINS
    SUBROUTINE Invert2x2(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(2,2)
      REAL(wp), INTENT(OUT) :: A_inv(2,2), det
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) > 1.0e-20_wp) THEN
        A_inv(1,1) =  A(2,2)/det
        A_inv(1,2) = -A(1,2)/det
        A_inv(2,1) = -A(2,1)/det
        A_inv(2,2) =  A(1,1)/det
      ELSE
        A_inv = ZERO
      END IF
    END SUBROUTINE Invert2x2
  END SUBROUTINE PH_Elem_S3_NL_UL

  SUBROUTINE PH_Elem_S3_NL_UL_Legacy(coords_prev, u_incr, mat_prop, mat_state, thickness, n_layers, &
                                      Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 3)
    REAL(wp), INTENT(IN)  :: u_incr(18)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: thickness
    INTEGER(i4), INTENT(IN) :: n_layers
    REAL(wp), INTENT(OUT) :: Ke_mat(18, 18), Ke_geo(18, 18), R_int(18)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PH_Elem_S3_NL_UL_Arg) :: in_struct
    TYPE(PH_Elem_S3_NL_UL_Arg) :: out_struct
    in_struct%coords_prev = coords_prev
    in_struct%u_incr = u_incr
    in_struct%mat_prop = mat_prop
    ALLOCATE(in_struct%mat_state(SIZE(mat_state)))
    in_struct%mat_state = mat_state
    in_struct%thickness = thickness
    in_struct%n_layers = n_layers
    CALL PH_Elem_S3_NL_UL(arg_struct)
    Ke_mat = out_struct%evo%Ke_mat
    Ke_geo = out_struct%evo%Ke_geo
    R_int = out_struct%evo%R_int
    status = out_struct%status
    mat_state = out_struct%mat_state
  END SUBROUTINE PH_Elem_S3_NL_UL_Legacy

  SUBROUTINE PH_Elem_S3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    REAL(wp) :: e(3)
    CALL PH_Elem_CPE3_ThermStrainVector(alpha, deltaT, e)
    eps_th = ZERO
    IF (SIZE(eps_th) >= 3) eps_th(1:3) = e(1:3)
  END SUBROUTINE PH_Elem_S3_ThermStrainVector

  SUBROUTINE PH_ELEM_S3_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords(1:2, 1:3), J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_S3_AreaInt

  SUBROUTINE UF_Elem_S3_Calc(ElemType, Formul, Ctx, state_in, &
                              Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_S3_NNODE)
    REAL(wp) :: u(PH_ELEM_S3_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_S3_NDOF, PH_ELEM_S3_NDOF)
    REAL(wp) :: R_int(PH_ELEM_S3_NDOF)
    INTEGER(i4) :: i, j
    TYPE(MatDesc) :: sec_desc

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Extract coordinates from Ctx
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S3_Calc: coords_ref not allocated'
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_S3_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S3_Calc: insufficient nodes in coords_ref'
      RETURN
    END IF

    DO i = 1, PH_ELEM_S3_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
      IF (SIZE(Ctx%coords_ref, 1) < 3) THEN
        coords(3, i) = 0.0_wp
      END IF
    END DO

    ! Extract displacement from state_in
    u = 0.0_wp
    IF (ALLOCATED(state_in%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S3_NDOF, SIZE(state_in%Re))
        u(i) = state_in%Re(i)
      END DO
    END IF

    ! Extract Mat properties
    E_young = 0.0_wp
    nu = 0.0_wp
    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) E_young = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) nu = Mat%props%props(2)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S3_Calc: invalid E_young'
      RETURN
    END IF

    ! Call S3-specific functions
    CALL PH_Elem_S3_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)
    CALL PH_Elem_S3_FormIntForce_Legacy(coords, u, E_young, nu, R_int)

    ! Prepare output storage
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Write results to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_S3_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_S3_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S3_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    flags%status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_S3_Calc

  !-----------------------------------------------------------------------------
  ! Sect (merged from PH_Elem_S3_Sect)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S3_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_S3_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_S3_GetArea

  SUBROUTINE PH_Elem_S3_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords(1:2, 1:3), J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 3
        DO j = 1, 3
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
      centroid(3) = centroid(3) / area
    END IF
  END SUBROUTINE PH_Elem_S3_GetCentroid

  SUBROUTINE PH_Elem_S3_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_S3_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_S3_GetSectProps

  !-----------------------------------------------------------------------------
  ! Constraints (merged from PH_Elem_S3_Constraints)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 18) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_S3_ApplyConstraint

  SUBROUTINE PH_Elem_S3_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(18)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    INTEGER(i4) :: i, j
    DO i = 1, 18
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 18
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S3_ApplyMPC

  !-----------------------------------------------------------------------------
  ! Contact (merged from PH_Elem_S3_Cont)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_ELEM_S3_CrossProduct(a, b, c)
    REAL(wp), INTENT(IN)  :: a(3), b(3)
    REAL(wp), INTENT(OUT) :: c(3)
    c(1) = a(2)*b(3) - a(3)*b(2)
    c(2) = a(3)*b(1) - a(1)*b(3)
    c(3) = a(1)*b(2) - a(2)*b(1)
  END SUBROUTINE PH_ELEM_S3_CrossProduct

  SUBROUTINE PH_Elem_S3_FormContactContrib(coords, gap_field, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: gap_field(3)
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(OUT) :: K_el(18, 18)
    REAL(wp), INTENT(OUT) :: F_el(18)
    INTEGER(i4) :: e
    K_el = ZERO
    F_el = ZERO
    DO e = 1, 3
      CALL PH_Elem_S3_FormContactEdgeCtr(e, coords, gap_field(e), penalty, K_el, F_el)
    END DO
  END SUBROUTINE PH_Elem_S3_FormContactContrib

  SUBROUTINE PH_Elem_S3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(18, 18)
    REAL(wp), INTENT(INOUT) :: F_el(18)
    REAL(wp) :: n(3), t(3), len
    INTEGER(i4) :: n1, n2
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_S3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S3_EDGE_NODES(2, edge_id)
    t(1:3) = coords(1:3, n2) - coords(1:3, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2) + t(3)*t(3))
    IF (len < 1.0e-15_wp) RETURN
    t = t / len
    CALL PH_ELEM_S3_CrossProduct(t, [0.0_wp, 0.0_wp, 1.0_wp], n)
    len = SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
    IF (len > 1.0e-15_wp) n = n / len
    K_el((n1-1)*6+1, (n1-1)*6+1) = K_el((n1-1)*6+1, (n1-1)*6+1) + penalty * len
    K_el((n1-1)*6+2, (n1-1)*6+2) = K_el((n1-1)*6+2, (n1-1)*6+2) + penalty * len
    K_el((n1-1)*6+3, (n1-1)*6+3) = K_el((n1-1)*6+3, (n1-1)*6+3) + penalty * len
    K_el((n2-1)*6+1, (n2-1)*6+1) = K_el((n2-1)*6+1, (n2-1)*6+1) + penalty * len
    K_el((n2-1)*6+2, (n2-1)*6+2) = K_el((n2-1)*6+2, (n2-1)*6+2) + penalty * len
    K_el((n2-1)*6+3, (n2-1)*6+3) = K_el((n2-1)*6+3, (n2-1)*6+3) + penalty * len
    F_el((n1-1)*6+1) = F_el((n1-1)*6+1) + penalty * gap * n(1) * len
    F_el((n1-1)*6+2) = F_el((n1-1)*6+2) + penalty * gap * n(2) * len
    F_el((n1-1)*6+3) = F_el((n1-1)*6+3) + penalty * gap * n(3) * len
    F_el((n2-1)*6+1) = F_el((n2-1)*6+1) + penalty * gap * n(1) * len
    F_el((n2-1)*6+2) = F_el((n2-1)*6+2) + penalty * gap * n(2) * len
    F_el((n2-1)*6+3) = F_el((n2-1)*6+3) + penalty * gap * n(3) * len
  END SUBROUTINE PH_Elem_S3_FormContactEdgeCtr

  !-----------------------------------------------------------------------------
  ! Loads (merged from PH_Elem_S3_Loads)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S3_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(18)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPE3_Jac(dNdxi, coords(1:2, 1:3), J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 3
        F_eq((i-1)*6+1) = F_eq((i-1)*6+1) + N(i) * bx * detJ * weights(ip)
        F_eq((i-1)*6+2) = F_eq((i-1)*6+2) + N(i) * by * detJ * weights(ip)
        F_eq((i-1)*6+3) = F_eq((i-1)*6+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S3_FormBodyForce

  SUBROUTINE PH_Elem_S3_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(18)
    REAL(wp) :: v1(3), v2(3), n_el(3), len, t(3)
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_S3_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S3_EDGE_NODES(2, edge_id)
    v1(1:3) = coords(1:3, 2) - coords(1:3, 1)
    v2(1:3) = coords(1:3, 3) - coords(1:3, 1)
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
  END SUBROUTINE PH_Elem_S3_FormEdgePressure

  SUBROUTINE PH_Elem_S3_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(18)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 3) THEN
      CALL PH_Elem_S3_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_S3_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_S3_FormNodalForce

  !-----------------------------------------------------------------------------
  ! Output (merged from PH_Elem_S3_Out)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S3_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 3)
      IF (SIZE(out_vars, 1) >= 3 .AND. SIZE(ip_stress, 1) >= 3) out_vars(1:3, ip) = ip_stress(1:3, ip)
      IF (SIZE(ip_strain, 1) >= 3) out_vars(4:6, ip) = ip_strain(1:3, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(7, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_S3_CollectIPVars

  SUBROUTINE PH_Elem_S3_EvalVonMises(sigma, seq)
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
  END SUBROUTINE PH_Elem_S3_EvalVonMises

  SUBROUTINE PH_Elem_S3_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3)
    INTEGER(i4) :: ip, i
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
    E = ZERO
    DO ip = 1, 3
      CALL PH_Elem_CPE3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 3
        E(i, ip) = N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S3_GetExtrapMat

  SUBROUTINE PH_Elem_S3_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(3, 3)
    INTEGER(i4) :: nv, n_ip
    node_vars = ZERO
    CALL PH_Elem_S3_GetExtrapMat(E)
    nv = MIN(SIZE(ip_vars, 1), SIZE(node_vars, 1))
    n_ip = MIN(SIZE(ip_vars, 2), SIZE(weights), 3)
    IF (nv >= 1 .AND. n_ip >= 1) THEN
      node_vars(1:nv, 1:3) = MATMUL(ip_vars(1:nv, 1:n_ip), TRANSPOSE(E(1:3, 1:n_ip)))
    END IF
  END SUBROUTINE PH_Elem_S3_MapToNode

  SUBROUTINE PH_Elem_S3_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                        stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticPlaneStrain

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStrain(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_S3_Material_Update_Membrane_Routed

END MODULE PH_Elem_S3


