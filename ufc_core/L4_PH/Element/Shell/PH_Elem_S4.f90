!===============================================================================
! MODULE: PH_Elem_S4
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  S4 shell element definition (4-node)
!===============================================================================
MODULE PH_Elem_S4
!> [CORE] S4 shell element unified interface (merged 6 files)
!> Theory: K = K_mem + K_bend, membrane from CPS4, bending from Euler-Bernoulli edges
!> Status: CORE | Last verified: 2026-02-28
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatPropertyDef, UF_MatProp_Init
  USE MD_Sect_Mgr, ONLY: MatDesc
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_FormStiffMatrix, PH_Elem_CPS4_FormIntForce, &
       PH_Elem_CPS4_ConsMass, PH_Elem_CPS4_LumpMass, PH_Elem_CPS4_ThermStrainVector, &
       PH_Elem_CPS4_ShapeFunc, PH_Elem_CPS4_Jac, PH_Elem_CPS4_GaussPoints, &
       PH_Elem_CPS4_BMatrix, PH_Elem_CPS4_ConstMatrix
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  USE UF_Section
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  ! Structured interfaces (new)
  PUBLIC :: PH_Elem_S4_StiffMatrix_Arg
  PUBLIC :: PH_Elem_S4_FormStiffMatrix
  PUBLIC :: PH_Elem_S4_IntForce_Arg
  PUBLIC :: PH_Elem_S4_FormIntForce
  PUBLIC :: PH_Elem_S4_NL_TL_Arg
  PUBLIC :: PH_Elem_S4_NL_TL
  PUBLIC :: PH_Elem_S4_NL_UL_Arg
  PUBLIC :: PH_Elem_S4_NL_UL
  
  ! Legacy interfaces (kept for backward compatibility)
  PUBLIC :: PH_Elem_S4_DefInit
  PUBLIC :: PH_Elem_S4_FormStiffMatrixWithBending
  PUBLIC :: PH_Elem_S4_ConsMass
  PUBLIC :: PH_Elem_S4_LumpMass
  PUBLIC :: PH_Elem_S4_ThermStrainVector
  PUBLIC :: PH_ELEM_S4_NNODE
  PUBLIC :: PH_ELEM_S4_NIP
  PUBLIC :: PH_ELEM_S4_NDOF
  PUBLIC :: PH_ELEM_S4_NEDGE
  PUBLIC :: PH_ELEM_S4_EDGE_NODES
  PUBLIC :: PH_ELEM_S4_AreaInt
  ! Unified API for S4 family variants
  PUBLIC :: PH_ELEM_S4_INTEGRATION_FULL
  PUBLIC :: PH_ELEM_S4_INTEGRATION_REDUCED
  PUBLIC :: PH_Elem_S4_FormStiffMatrix_Unified
  PUBLIC :: PH_Elem_S4_FormIntForce_Unified
  PUBLIC :: UF_Elem_S4_Calc
  ! Sect, Constraints, Cont, Loads, Out (merged)
  PUBLIC :: PH_Elem_S4_GetArea
  PUBLIC :: PH_Elem_S4_GetSectProps
  PUBLIC :: PH_Elem_S4_GetCentroid
  PUBLIC :: PH_Elem_S4_ApplyConstraint
  PUBLIC :: PH_Elem_S4_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF
  PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_S4_FormContactContrib
  PUBLIC :: PH_Elem_S4_FormContactEdgeCtr
  PUBLIC :: PH_Elem_S4_FormNodalForce
  PUBLIC :: PH_Elem_S4_FormBodyForce
  PUBLIC :: PH_Elem_S4_FormEdgePressure
  PUBLIC :: PH_ELEM_LOAD_BODY
  PUBLIC :: PH_ELEM_LOAD_EDGE_P
  PUBLIC :: PH_Elem_S4_CollectIPVars
  PUBLIC :: PH_Elem_S4_MapToNode
  PUBLIC :: PH_Elem_S4_GetExtrapMat
  PUBLIC :: PH_Elem_S4_EvalVonMises
  PUBLIC :: PH_Elem_S4_Material_Update_Membrane_Routed

  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_S4_NNODE  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_NIP   = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_NDOF  = 24_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  ! Membrane DOF indices in 24-vector: node i -> (1:2) -> (i-1)*6+1, (i-1)*6+2
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_MEM_DOF(8) = [ 1, 2, 7, 8, 13, 14, 19, 20 ]
  ! Integration scheme constants for unified API
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_INTEGRATION_FULL = 1_i4      ! 4 Gauss points (2?)
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_INTEGRATION_REDUCED = 2_i4  ! 1 Gauss point (center, weight=4)
  REAL(wp), PARAMETER :: PH_ELEM_S4_REDUCED_WEIGHT = 4.0_wp        ! Weight for reduced integration
  ! Edge bending DOF (u,v,rot_z per node): edge e -> dof 6 (node n1: 1,2,6; n2: 7,8,12 in local 6?)
  INTEGER(i4), PARAMETER :: PH_ELEM_S4_EDGE_BEND_DOF(6, 4) = RESHAPE( &
    [ 1, 2, 6,  7, 8, 12,  7, 8, 12, 13, 14, 18,  13, 14, 18, 19, 20, 24,  19, 20, 24, 1, 2, 6 ], [6, 4] )

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for stiffness matrix computation
  
  !> @brief Output structure for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_S4_StiffMatrix_Arg
    INTEGER(i4) :: integration_scheme  ! Integration scheme: FULL or REDUCED (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_StiffMatrix_Arg


  !> @brief Input structure for internal force computation
  
  !> @brief Output structure for internal force computation
  TYPE, PUBLIC :: PH_Elem_S4_IntForce_Arg
    INTEGER(i4) :: integration_scheme  ! Integration scheme: FULL or REDUCED (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_IntForce_Arg


  !> @brief Input structure for Total Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_S4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_NL_TL_Arg


  !> @brief Input structure for Updated Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_S4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_NL_UL_Arg


CONTAINS

  SUBROUTINE PH_El_S4_Fo_Unified(coords, E_young, nu, integration_scheme, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    INTEGER(i4), INTENT(IN) :: integration_scheme  ! FULL or REDUCED
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    
    REAL(wp) :: Ke_m(8, 8)
    REAL(wp) :: N(4), dNdxi(2, 4), dNdx(2, 4), J(2, 2), Jinv(2, 2), detJ, B(3, 8), D(3, 3)
    INTEGER(i4) :: i, j
    
    Ke = ZERO
    
    SELECT CASE (integration_scheme)
    CASE (PH_ELEM_S4_INTEGRATION_FULL)
      ! Full integration: 4 Gauss points (22)
      CALL PH_Elem_CPS4_FormStiffMatrix(coords(1:2, 1:4), E_young, nu, Ke_m)
      DO i = 1, 8
        DO j = 1, 8
          Ke(PH_ELEM_S4_MEM_DOF(i), PH_ELEM_S4_MEM_DOF(j)) = Ke_m(i, j)
        END DO
      END DO
      
    CASE (PH_ELEM_S4_INTEGRATION_REDUCED)
      ! Reduced integration: 1 Gauss point at center (0,0) with weight 4
      CALL PH_Elem_CPS4_ShapeFunc(0.0_wp, 0.0_wp, N, dNdxi)
      CALL PH_Elem_CPS4_Jac(dNdxi, coords(1:2, 1:4), J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      
      ! Invert Jacobian
      Jinv(1, 1) =  J(2, 2) / detJ
      Jinv(1, 2) = -J(1, 2) / detJ
      Jinv(2, 1) = -J(2, 1) / detJ
      Jinv(2, 2) =  J(1, 1) / detJ
      
      ! Compute dN/dx
      DO i = 1, 4
        dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      
      ! Compute B matrix and stiffness
      CALL PH_Elem_CPS4_BMatrix(dNdx, B)
      CALL PH_Elem_CPS4_ConstMatrix(E_young, nu, D)
      Ke_m = MATMUL(MATMUL(TRANSPOSE(B), D), B) * detJ * PH_ELEM_S4_REDUCED_WEIGHT
      
      ! Scatter to 2424
      DO i = 1, 8
        DO j = 1, 8
          Ke(PH_ELEM_S4_MEM_DOF(i), PH_ELEM_S4_MEM_DOF(j)) = Ke_m(i, j)
        END DO
      END DO
      
    CASE DEFAULT
      ! Default to full integration
      CALL PH_Elem_CPS4_FormStiffMatrix(coords(1:2, 1:4), E_young, nu, Ke_m)
      DO i = 1, 8
        DO j = 1, 8
          Ke(PH_ELEM_S4_MEM_DOF(i), PH_ELEM_S4_MEM_DOF(j)) = Ke_m(i, j)
        END DO
      END DO
    END SELECT
  END SUBROUTINE PH_Elem_S4_FormStiffMatrix_Unified

  SUBROUTINE PH_El_S4_Fo_Unified(coords, u, E_young, nu, integration_scheme, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young, nu
    INTEGER(i4), INTENT(IN) :: integration_scheme  ! FULL or REDUCED
    REAL(wp), INTENT(OUT) :: R_int(24)
    
    REAL(wp) :: u_m(8), R_m(8)
    REAL(wp) :: N(4), dNdxi(2, 4), dNdx(2, 4), J(2, 2), Jinv(2, 2), detJ, B(3, 8), D(3, 3)
    REAL(wp) :: strain(3), sigma(3)
    INTEGER(i4) :: i
    
    R_int = ZERO
    
    ! Extract membrane DOF
    DO i = 1, 8
      u_m(i) = u(PH_ELEM_S4_MEM_DOF(i))
    END DO
    
    SELECT CASE (integration_scheme)
    CASE (PH_ELEM_S4_INTEGRATION_FULL)
      ! Full integration: use CPS4 function
      CALL PH_Elem_CPS4_FormIntForce(coords(1:2, 1:4), u_m, E_young, nu, R_m)
      DO i = 1, 8
        R_int(PH_ELEM_S4_MEM_DOF(i)) = R_m(i)
      END DO
      
    CASE (PH_ELEM_S4_INTEGRATION_REDUCED)
      ! Reduced integration: 1 Gauss point at center
      CALL PH_Elem_CPS4_ShapeFunc(0.0_wp, 0.0_wp, N, dNdxi)
      CALL PH_Elem_CPS4_Jac(dNdxi, coords(1:2, 1:4), J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      
      ! Invert Jacobian
      Jinv(1, 1) =  J(2, 2) / detJ
      Jinv(1, 2) = -J(1, 2) / detJ
      Jinv(2, 1) = -J(2, 1) / detJ
      Jinv(2, 2) =  J(1, 1) / detJ
      
      ! Compute dN/dx
      DO i = 1, 4
        dNdx(1, i) = Jinv(1, 1) * dNdxi(1, i) + Jinv(1, 2) * dNdxi(2, i)
        dNdx(2, i) = Jinv(2, 1) * dNdxi(1, i) + Jinv(2, 2) * dNdxi(2, i)
      END DO
      
      ! Compute B matrix, strain, stress, and internal force
      CALL PH_Elem_CPS4_BMatrix(dNdx, B)
      CALL PH_Elem_CPS4_ConstMatrix(E_young, nu, D)
      strain = MATMUL(B, u_m)
      sigma(1) = D(1,1)*strain(1) + D(1,2)*strain(2) + D(1,3)*strain(3)
      sigma(2) = D(2,1)*strain(1) + D(2,2)*strain(2) + D(2,3)*strain(3)
      sigma(3) = D(3,1)*strain(1) + D(3,2)*strain(2) + D(3,3)*strain(3)
      R_int(PH_ELEM_S4_MEM_DOF(1:8)) = MATMUL(TRANSPOSE(B), sigma) * detJ * PH_ELEM_S4_REDUCED_WEIGHT
      
    CASE DEFAULT
      ! Default to full integration
      CALL PH_Elem_CPS4_FormIntForce(coords(1:2, 1:4), u_m, E_young, nu, R_m)
      DO i = 1, 8
        R_int(PH_ELEM_S4_MEM_DOF(i)) = R_m(i)
      END DO
    END SELECT
  END SUBROUTINE PH_Elem_S4_FormIntForce_Unified

  SUBROUTINE PH_El_S4_FormStiffMatrixWith(coords, E_young, nu, thickness, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: thickness
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    REAL(wp) :: Ke_m(8, 8)
    REAL(wp) :: x1(2), x2(2), dx_e(2), L_e, c_e, s_e
    REAL(wp) :: A_bend, I_bend
    REAL(wp) :: Kloc_e(6, 6), T_e(6, 6), Kglob_e(6, 6)
    INTEGER(i4) :: i, j, e, ir, ic
    Ke = ZERO
    CALL PH_Elem_CPS4_FormStiffMatrix(coords(1:2, 1:4), E_young, nu, Ke_m)
    DO i = 1, 8
      DO j = 1, 8
        Ke(PH_ELEM_S4_MEM_DOF(i), PH_ELEM_S4_MEM_DOF(j)) = Ke_m(i, j)
      END DO
    END DO
    IF (thickness <= 1.0e-12_wp) RETURN
    A_bend = thickness
    I_bend = thickness**3 / 12.0_wp
    DO e = 1, 4
      x1(1) = coords(1, PH_ELEM_S4_EDGE_NODES(1, e))
      x1(2) = coords(2, PH_ELEM_S4_EDGE_NODES(1, e))
      x2(1) = coords(1, PH_ELEM_S4_EDGE_NODES(2, e))
      x2(2) = coords(2, PH_ELEM_S4_EDGE_NODES(2, e))
      dx_e = x2 - x1
      L_e = SQRT(dx_e(1)*dx_e(1) + dx_e(2)*dx_e(2))
      IF (L_e <= 1.0e-12_wp) CYCLE
      c_e = dx_e(1) / L_e
      s_e = dx_e(2) / L_e
      Kloc_e = ZERO
      Kloc_e(1, 1) =  E_young * A_bend / L_e
      Kloc_e(1, 4) = -E_young * A_bend / L_e
      Kloc_e(4, 1) = -E_young * A_bend / L_e
      Kloc_e(4, 4) =  E_young * A_bend / L_e
      Kloc_e(2, 2) =  12.0_wp * E_young * I_bend / (L_e**3)
      Kloc_e(2, 3) =   6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(2, 5) = -12.0_wp * E_young * I_bend / (L_e**3)
      Kloc_e(2, 6) =   6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(3, 2) =   6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(3, 3) =   4.0_wp * E_young * I_bend / L_e
      Kloc_e(3, 5) =  -6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(3, 6) =   2.0_wp * E_young * I_bend / L_e
      Kloc_e(5, 2) = -12.0_wp * E_young * I_bend / (L_e**3)
      Kloc_e(5, 3) =  -6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(5, 5) =  12.0_wp * E_young * I_bend / (L_e**3)
      Kloc_e(5, 6) =  -6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(6, 2) =   6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(6, 3) =   2.0_wp * E_young * I_bend / L_e
      Kloc_e(6, 5) =  -6.0_wp * E_young * I_bend / (L_e**2)
      Kloc_e(6, 6) =   4.0_wp * E_young * I_bend / L_e
      T_e = ZERO
      T_e(1, 1) =  c_e
      T_e(1, 2) =  s_e
      T_e(2, 1) = -s_e
      T_e(2, 2) =  c_e
      T_e(3, 3) =  ONE
      T_e(4, 4) =  c_e
      T_e(4, 5) =  s_e
      T_e(5, 4) = -s_e
      T_e(5, 5) =  c_e
      T_e(6, 6) =  ONE
      Kglob_e = MATMUL(TRANSPOSE(T_e), MATMUL(Kloc_e, T_e))
      DO ir = 1, 6
        DO ic = 1, 6
          Ke(PH_ELEM_S4_EDGE_BEND_DOF(ir, e), PH_ELEM_S4_EDGE_BEND_DOF(ic, e)) = &
            Ke(PH_ELEM_S4_EDGE_BEND_DOF(ir, e), PH_ELEM_S4_EDGE_BEND_DOF(ic, e)) + Kglob_e(ir, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_S4_FormStiffMatrixWithBending

  SUBROUTINE PH_Elem_S4_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(24, 24)
    REAL(wp) :: Me_m(8, 8)
    INTEGER(i4) :: i, j
    Me = ZERO
    CALL PH_Elem_CPS4_ConsMass(coords(1:2, 1:4), rho, Me_m)
    DO i = 1, 8
      DO j = 1, 8
        Me(PH_ELEM_S4_MEM_DOF(i), PH_ELEM_S4_MEM_DOF(j)) = Me_m(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S4_ConsMass

  SUBROUTINE PH_Elem_S4_DefInit()
  END SUBROUTINE PH_Elem_S4_DefInit

  SUBROUTINE PH_Elem_S4_FormIntForce(arg)
    TYPE(PH_Elem_S4_IntForce_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    
    ! Use unified interface
    CALL PH_Elem_S4_FormIntForce_Unified(arg%coords, arg%u, arg%E_young, arg%nu, &
                                         arg%integration_scheme, arg%evo%R_int)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_S4_FormIntForce

  SUBROUTINE PH_Elem_S4_FormStiffMatrix(arg)
    TYPE(PH_Elem_S4_StiffMatrix_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    
    ! Use unified interface with full integration
    CALL PH_Elem_S4_FormStiffMatrix_Unified(arg%coords, arg%E_young, arg%nu, &
                                            arg%integration_scheme, arg%evo%Ke)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_S4_FormStiffMatrix

  SUBROUTINE PH_Elem_S4_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(24)
    REAL(wp) :: M_m(8)
    INTEGER(i4) :: i
    M_lumped = ZERO
    CALL PH_Elem_CPS4_LumpMass(coords(1:2, 1:4), rho, M_m)
    DO i = 1, 4
      M_lumped(PH_ELEM_S4_MEM_DOF(2*i-1)) = M_m(2*i-1)
      M_lumped(PH_ELEM_S4_MEM_DOF(2*i))   = M_m(2*i)
    END DO
  END SUBROUTINE PH_Elem_S4_LumpMass

  SUBROUTINE PH_Elem_S4_NL_TL(arg)
    TYPE(PH_Elem_S4_NL_TL_Arg), INTENT(INOUT) :: arg
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
    USE MD_Mat_Lib, ONLY: MatPropertyDef
    USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag
    IMPLICIT NONE
    
    ! Local variables (TL Formul)
    REAL(wp) :: coords_curr(3, 4)
    REAL(wp) :: xi_gp(2), eta_gp, zeta_layer
    REAL(wp) :: wt_gp, wt_layer
    REAL(wp) :: N(4), dN_dxi(4, 2)
    REAL(wp) :: J_ref(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: dN_dX(4, 2)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: K_mat_gp(24, 24), K_geo_gp(24, 24), R_gp(24)
    INTEGER(i4) :: igp, ilayer, i, gp_id
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
    arg%evo%R_int  = ZERO
    
    ! Step 1: Current mid-surface x = X + u
    DO i = 1, 4
      coords_curr(1, i) = arg%coords_ref(1, i) + arg%lcl%u_elem(6*(i-1) + 1)
      coords_curr(2, i) = arg%coords_ref(2, i) + arg%lcl%u_elem(6*(i-1) + 2)
      coords_curr(3, i) = arg%coords_ref(3, i) + arg%lcl%u_elem(6*(i-1) + 3)
    END DO
    
    ! Step 2: Allocate RT_LagrCfg (TL uses coords_ref)



    cfg%formulation_typ = 1  ! TL
    
    DO i = 1, 4
      cfg%coords_ref(i, 1:3) = arg%coords_ref(1:3, i)
      cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
    END DO
    
    ! Step 3: Gauss integration (in-plane + through-thickness)
    gp_id = 0
    DO igp = 1, PH_ELEM_S4_NIP
      CALL PH_Elem_CPS4_GaussPoints_Single(igp, xi_gp, eta_gp, wt_gp)
      CALL PH_Elem_S4_ShapeFunc_2D(xi_gp(1), eta_gp, N, dN_dxi)
      
      ! Jacobian at REFERENCE config
      J_ref = ZERO
      DO i = 1, 4
        J_ref(1, 1) = J_ref(1, 1) + dN_dxi(i, 1) * arg%coords_ref(1, i)
        J_ref(1, 2) = J_ref(1, 2) + dN_dxi(i, 1) * arg%coords_ref(2, i)
        J_ref(2, 1) = J_ref(2, 1) + dN_dxi(i, 2) * arg%coords_ref(1, i)
        J_ref(2, 2) = J_ref(2, 2) + dN_dxi(i, 2) * arg%coords_ref(2, i)
      END DO
      
      CALL Invert2x2(J_ref, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      DO i = 1, 4
        dN_dX(i, 1:2) = MATMUL(dN_dxi(i, 1:2), J_inv)
      END DO
      
      ! Through-thickness layers
      DO ilayer = 1, n_layers
        gp_id = gp_id + 1
        zeta_layer = -ONE + (2.0_wp * REAL(ilayer - 1, wp) / REAL(n_layers - 1, wp))
        wt_layer = thickness / REAL(n_layers, wp)
        
        DO i = 1, 4
          cfg%lcl%dN_dX(i, 1) = dN_dX(i, 1)
          cfg%lcl%dN_dX(i, 2) = dN_dX(i, 2)
          cfg%lcl%dN_dX(i, 3) = N(i) * zeta_layer * HALF
        END DO
        
        ! ===== Mat Constitutive Call (TL mode, shell 3D state) =====
        ! Compute 3D deformation gradient F = dx/dX
        F = ZERO
        DO i = 1, 4
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
        
        ! Voigt notation [E11, E22, E33, E12, E23, E13]
        E_voigt(1) = E(1,1)
        E_voigt(2) = E(2,2)
        E_voigt(3) = E(3,3)
        E_voigt(4) = E(1,2)
        E_voigt(5) = E(2,3)
        E_voigt(6) = E(1,3)
        
        ! Initialize and call Mat constitutive
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= STATUS_SUCCESS) THEN
          arg%status%status_code = IF_STATUS_ERROR

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
        
        CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
        IF (arg%status%status_code /= STATUS_SUCCESS) THEN

          RETURN
        END IF
        
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp * wt_layer
        arg%evo%R_int  = arg%evo%R_int  + R_gp * det_J * wt_gp * wt_layer
      END DO
    END DO

  CONTAINS
    ! Helper functions (same as UL)
    SUBROUTINE Invert2x2(A, A_inv, det_A, stat)
      REAL(wp), INTENT(IN)  :: A(2,2)
      REAL(wp), INTENT(OUT) :: A_inv(2,2), det_A
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: tol
      
      tol = 1.0e-14_wp
      det_A = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      
      IF (ABS(det_A) < tol) THEN
        stat%code = IF_STATUS_ERROR
        RETURN
      END IF
      
      A_inv(1,1) =  A(2,2) / det_A
      A_inv(1,2) = -A(1,2) / det_A
      A_inv(2,1) = -A(2,1) / det_A
      A_inv(2,2) =  A(1,1) / det_A
      stat%code = STATUS_SUCCESS
    END SUBROUTINE Invert2x2
    
    SUBROUTINE PH_Elem_S4_ShapeFunc_2D(xi, eta, N, dN_dxi)
      REAL(wp), INTENT(IN)  :: xi, eta
      REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4, 2)
      
      N(1) = 0.25_wp * (ONE - xi) * (ONE - eta)
      N(2) = 0.25_wp * (ONE + xi) * (ONE - eta)
      N(3) = 0.25_wp * (ONE + xi) * (ONE + eta)
      N(4) = 0.25_wp * (ONE - xi) * (ONE + eta)
      
      dN_dxi(1, 1) = -0.25_wp * (ONE - eta)
      dN_dxi(1, 2) = -0.25_wp * (ONE - xi)
      dN_dxi(2, 1) =  0.25_wp * (ONE - eta)
      dN_dxi(2, 2) = -0.25_wp * (ONE + xi)
      dN_dxi(3, 1) =  0.25_wp * (ONE + eta)
      dN_dxi(3, 2) =  0.25_wp * (ONE + xi)
      dN_dxi(4, 1) = -0.25_wp * (ONE + eta)
      dN_dxi(4, 2) =  0.25_wp * (ONE - xi)
    END SUBROUTINE PH_Elem_S4_ShapeFunc_2D
    
    SUBROUTINE PH_El_CP_Ga_Single(igp, xi, eta, wt)
      INTEGER(i4), INTENT(IN)  :: igp
      REAL(wp), INTENT(OUT) :: xi(2), eta, wt
      REAL(wp) :: gp_loc
      
      gp_loc = ONE / SQRT(3.0_wp)
      SELECT CASE (igp)
        CASE (1); xi = (/-gp_loc, -gp_loc/); eta = -gp_loc; wt = ONE
        CASE (2); xi = (/ gp_loc, -gp_loc/); eta = -gp_loc; wt = ONE
        CASE (3); xi = (/ gp_loc,  gp_loc/); eta =  gp_loc; wt = ONE
        CASE (4); xi = (/-gp_loc,  gp_loc/); eta =  gp_loc; wt = ONE
      END SELECT
    END SUBROUTINE PH_Elem_CPS4_GaussPoints_Single
    
  END SUBROUTINE PH_Elem_S4_NL_TL

  SUBROUTINE PH_Elem_S4_NL_UL(arg)
    TYPE(PH_Elem_S4_NL_UL_Arg), INTENT(INOUT) :: arg
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
    USE MD_Mat_Lib, ONLY: MatPropertyDef
    USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_UpdLag
    IMPLICIT NONE
    
    ! Local variables (UL Formul)
    REAL(wp) :: coords_curr(3, 4)
    REAL(wp) :: xi_gp(2), eta_gp, zeta_layer
    REAL(wp) :: wt_gp, wt_layer
    REAL(wp) :: N(4), dN_dxi(4, 2)
    REAL(wp) :: J_prev(2, 2), J_inv(2, 2), det_J
    REAL(wp) :: dN_dx(4, 2)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: F(3, 3), epsilon(3, 3), sigma(3, 3)
    REAL(wp) :: K_mat_gp(24, 24), K_geo_gp(24, 24), R_gp(24)
    INTEGER(i4) :: igp, ilayer, i, gp_id
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
    arg%evo%R_int  = ZERO
    
    ! Step 1: Current mid-surface
    DO i = 1, 4
      coords_curr(1, i) = arg%coords_prev(1, i) + arg%u_incr(6*(i-1) + 1)
      coords_curr(2, i) = arg%coords_prev(2, i) + arg%u_incr(6*(i-1) + 2)
      coords_curr(3, i) = arg%coords_prev(3, i) + arg%u_incr(6*(i-1) + 3)
    END DO
    
    ! Step 2: Allocate RT_LagrCfg (UL uses coords_prev)



    cfg%formulation_typ = 2  ! UL
    
    DO i = 1, 4
      cfg%coords_prev(i, 1:3) = arg%coords_prev(1:3, i)
      cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
    END DO
    
    ! Step 3: Gauss integration (in-plane + through-thickness)
    gp_id = 0
    DO igp = 1, PH_ELEM_S4_NIP
      CALL PH_Elem_CPS4_GaussPoints_Single(igp, xi_gp, eta_gp, wt_gp)
      CALL PH_Elem_S4_ShapeFunc_2D(xi_gp(1), eta_gp, N, dN_dxi)
      
      ! Jacobian at PREVIOUS config
      J_prev = ZERO
      DO i = 1, 4
        J_prev(1, 1) = J_prev(1, 1) + dN_dxi(i, 1) * arg%coords_prev(1, i)
        J_prev(1, 2) = J_prev(1, 2) + dN_dxi(i, 1) * arg%coords_prev(2, i)
        J_prev(2, 1) = J_prev(2, 1) + dN_dxi(i, 2) * arg%coords_prev(1, i)
        J_prev(2, 2) = J_prev(2, 2) + dN_dxi(i, 2) * arg%coords_prev(2, i)
      END DO
      
      CALL Invert2x2(J_prev, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) RETURN
      
      DO i = 1, 4
        dN_dx(i, 1:2) = MATMUL(dN_dxi(i, 1:2), J_inv)
      END DO
      
      ! Through-thickness layers
      DO ilayer = 1, arg%n_layers
        gp_id = gp_id + 1
        zeta_layer = -ONE + (2.0_wp * REAL(ilayer - 1, wp) / REAL(arg%n_layers - 1, wp))
        wt_layer = arg%thickness / REAL(arg%n_layers, wp)
        
        DO i = 1, 4
          cfg%dN_dx(i, 1) = dN_dx(i, 1)
          cfg%dN_dx(i, 2) = dN_dx(i, 2)
          cfg%dN_dx(i, 3) = N(i) * zeta_layer * HALF
        END DO
        
        ! ===== Mat Constitutive Call (UL mode, shell 3D state) =====
        ! Compute 3D deformation gradient F = dx_{n+1}/dx_n
        F = ZERO
        DO i = 1, 4
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
        
        ! Voigt notation [e11, e22, e33, e12, e23, e13]
        E_voigt(1) = e_Almansi(1,1)
        E_voigt(2) = e_Almansi(2,2)
        E_voigt(3) = e_Almansi(3,3)
        E_voigt(4) = e_Almansi(1,2)
        E_voigt(5) = e_Almansi(2,3)
        E_voigt(6) = e_Almansi(1,3)
        
        ! Initialize and call Mat constitutive
        ss_gp%strain = E_voigt
        ss_gp%strain_inc = E_voigt
        ss_gp%sigma = ZERO
        ss_gp%tangent = ZERO
        
        CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(gp_id), ss_gp, mat_status)
        IF (mat_status%status_code /= STATUS_SUCCESS) THEN
          arg%status%status_code = IF_STATUS_ERROR

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
        
        CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
        IF (arg%status%status_code /= STATUS_SUCCESS) RETURN
        
        arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * wt_gp * wt_layer
        arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * wt_gp * wt_layer
        arg%evo%R_int  = arg%evo%R_int  + R_gp * det_J * wt_gp * wt_layer
      END DO
    END DO

  CONTAINS
    ! Reuse helpers from TL
    SUBROUTINE Invert2x2(A, A_inv, det_A, stat)
      REAL(wp), INTENT(IN)  :: A(2,2)
      REAL(wp), INTENT(OUT) :: A_inv(2,2), det_A
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: tol
      
      tol = 1.0e-14_wp
      det_A = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      
      IF (ABS(det_A) < tol) THEN
        stat%code = IF_STATUS_ERROR
        RETURN
      END IF
      
      A_inv(1,1) =  A(2,2) / det_A
      A_inv(1,2) = -A(1,2) / det_A
      A_inv(2,1) = -A(2,1) / det_A
      A_inv(2,2) =  A(1,1) / det_A
      stat%code = STATUS_SUCCESS
    END SUBROUTINE Invert2x2
    
    SUBROUTINE PH_Elem_S4_ShapeFunc_2D(xi, eta, N, dN_dxi)
      REAL(wp), INTENT(IN)  :: xi, eta
      REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4, 2)
      
      N(1) = 0.25_wp * (ONE - xi) * (ONE - eta)
      N(2) = 0.25_wp * (ONE + xi) * (ONE - eta)
      N(3) = 0.25_wp * (ONE + xi) * (ONE + eta)
      N(4) = 0.25_wp * (ONE - xi) * (ONE + eta)
      
      dN_dxi(1, 1) = -0.25_wp * (ONE - eta)
      dN_dxi(1, 2) = -0.25_wp * (ONE - xi)
      dN_dxi(2, 1) =  0.25_wp * (ONE - eta)
      dN_dxi(2, 2) = -0.25_wp * (ONE + xi)
      dN_dxi(3, 1) =  0.25_wp * (ONE + eta)
      dN_dxi(3, 2) =  0.25_wp * (ONE + xi)
      dN_dxi(4, 1) = -0.25_wp * (ONE + eta)
      dN_dxi(4, 2) =  0.25_wp * (ONE - xi)
    END SUBROUTINE PH_Elem_S4_ShapeFunc_2D
    
    SUBROUTINE PH_El_CP_Ga_Single(igp, xi, eta, wt)
      INTEGER(i4), INTENT(IN)  :: igp
      REAL(wp), INTENT(OUT) :: xi(2), eta, wt
      REAL(wp) :: gp_loc
      
      gp_loc = ONE / SQRT(3.0_wp)
      SELECT CASE (igp)
        CASE (1); xi = (/-gp_loc, -gp_loc/); eta = -gp_loc; wt = ONE
        CASE (2); xi = (/ gp_loc, -gp_loc/); eta = -gp_loc; wt = ONE
        CASE (3); xi = (/ gp_loc,  gp_loc/); eta =  gp_loc; wt = ONE
        CASE (4); xi = (/-gp_loc,  gp_loc/); eta =  gp_loc; wt = ONE
      END SELECT
    END SUBROUTINE PH_Elem_CPS4_GaussPoints_Single
    
  END SUBROUTINE PH_Elem_S4_NL_UL

  SUBROUTINE PH_Elem_S4_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    REAL(wp) :: e(3)
    CALL PH_Elem_CPS4_ThermStrainVector(alpha, deltaT, e)
    eps_th = ZERO
    IF (SIZE(eps_th) >= 3) eps_th(1:3) = e(1:3)
  END SUBROUTINE PH_Elem_S4_ThermStrainVector

  SUBROUTINE PH_Shell_BuildGeomCtrl(Formul, formulation_typ, ctrl)
    TYPE(ElemFormul),       INTENT(IN)  :: Formul
    INTEGER(i4),                 INTENT(IN)  :: formulation_typ  ! 1=TL, 2=UL
    TYPE(PH_ShellGeomCtrl_Type), INTENT(OUT) :: ctrl

    INTEGER(i4) :: n_ip
    REAL(wp) :: xi_full(4), eta_full(4), w_full(4)

    ! 1) Set TL/UL mode from formulation_typ
    SELECT CASE (formulation_typ)
    CASE (SHELL_GEOM_TL)
      ctrl%geom_mode = SHELL_GEOM_TL
    CASE (SHELL_GEOM_UL)
      ctrl%geom_mode = SHELL_GEOM_UL
    CASE DEFAULT
      ctrl%geom_mode = SHELL_GEOM_TL
    END SELECT

    ! 2) Decide number of Gauss points from Formul
    IF (Formul%nIntPoints > 0) THEN
      n_ip = Formul%nIntPoints
    ELSE
      IF (Formul%reducedintegrat) THEN
        n_ip = 1
      ELSE
        n_ip = PH_ELEM_S4_NIP
      END IF
    END IF

    ctrl%n_gp = n_ip

    IF (ALLOCATED(ctrl%xi_gp)) DEALLOCATE(ctrl%xi_gp, ctrl%eta_gp, ctrl%w_gp)
    ALLOCATE(ctrl%xi_gp(ctrl%n_gp), ctrl%eta_gp(ctrl%n_gp), ctrl%w_gp(ctrl%n_gp))

    ! 3) Fill Gauss points: full 2x2 or reduced 1-point
    IF (ctrl%n_gp == 1) THEN
      ctrl%xi_gp(1)  = 0.0_wp
      ctrl%eta_gp(1) = 0.0_wp
      ctrl%w_gp(1)   = 4.0_wp
    ELSE
      CALL PH_Elem_CPS4_GaussPoints(xi_full, eta_full, w_full)
      ctrl%xi_gp(1:ctrl%n_gp)  = xi_full(1:ctrl%n_gp)
      ctrl%eta_gp(1:ctrl%n_gp) = eta_full(1:ctrl%n_gp)
      ctrl%w_gp(1:ctrl%n_gp)   = w_full(1:ctrl%n_gp)
    END IF

  END SUBROUTINE PH_Shell_BuildGeomCtrl

  SUBROUTINE PH_ELEM_S4_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac(dNdxi, coords(1:2, 1:4), J, detJ)
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_S4_AreaInt

  SUBROUTINE UF_Elem_S4_Calc(ElemType, Formul, Ctx, state_in, &
                              Mat, state_out, flags)
    TYPE(ElemType),      INTENT(IN)    :: ElemType
    TYPE(ElemFormul),  INTENT(IN)    :: Formul
    TYPE(ElemCtx),   INTENT(IN)    :: Ctx
    TYPE(ElemState),     INTENT(IN)    :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState),     INTENT(INOUT) :: state_out
    TYPE(ElemFlags),     INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_S4_NNODE)
    REAL(wp) :: u(PH_ELEM_S4_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_S4_NDOF, PH_ELEM_S4_NDOF)
    REAL(wp) :: R_int(PH_ELEM_S4_NDOF)
    INTEGER(i4) :: i, j
    INTEGER(i4) :: integration_scheme
    ! TL/UL skeleton-related locals
    TYPE(MatPropertyDef)   :: mat_prop
    TYPE(PH_ShellGeomCtrl_Type) :: shell_ctrl
    TYPE(PH_ShellState_Type)    :: shell_state_in, shell_state_out
    INTEGER(i4) :: formulation_typ, ierr_shell
    LOGICAL :: use_geom_nl
    INTEGER(i4) :: n_ip, ip

    ! Initialize error status
    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Extract coordinates from Ctx
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S4_Calc: coords_ref not allocated'
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_S4_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S4_Calc: insufficient nodes in coords_ref'
      RETURN
    END IF

    DO i = 1, PH_ELEM_S4_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
      IF (SIZE(Ctx%coords_ref, 1) < 3) THEN
        coords(3, i) = 0.0_wp
      END IF
    END DO

    ! Extract displacement from state_in
    u = 0.0_wp
    IF (ALLOCATED(state_in%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S4_NDOF, SIZE(state_in%Re))
        u(i) = state_in%Re(i)
      END DO
    END IF

    ! Extract Mat properties
    E_young = 0.0_wp
    nu = 0.0_wp
    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) E_young = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) nu      = Mat%props%props(2)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S4_Calc: invalid E_young'
      RETURN
    END IF

    !-----------------------------------------------------------------
    ! TL/UL: flags%nlgeom / flags%formulation_typ
    !-----------------------------------------------------------------
    use_geom_nl = (flags%stp%nlgeom == 1)

    IF (use_geom_nl) THEN
      ! TL/UL formulation (0 = TL)
      formulation_typ = flags%formulation_typ
      IF (formulation_typ /= SHELL_GEOM_TL .AND. formulation_typ /= SHELL_GEOM_UL) THEN
        formulation_typ = SHELL_GEOM_TL
      END IF

      ! 1) Build Gauss rule and geometry control
      CALL PH_Shell_BuildGeomCtrl(Formul, formulation_typ, shell_ctrl)

      ! 2) Map MatProperties from MatPropertyDef
      IF (ALLOCATED(Mat%props%props)) THEN
        CALL UF_MatProp_Init(mat_prop,                              &
                             mat_id    = Mat%cfg%id,               &
                             num_props = SIZE(Mat%props%props),&
                             props     = Mat%props%props,      &
                             err_stat  = flags%status)
        IF (flags%status%status_code /= IF_STATUS_OK) THEN
          flags%failed = .TRUE.
          RETURN
        END IF
      ELSE
        flags%failed = .TRUE.
        flags%status%status_code = IF_STATUS_INVALID
        flags%status%message = 'UF_Elem_S4_Calc: Mat properties not allocated'
        RETURN
      END IF

      ! 3) From shell_state_in, state_in%ipStates(:)
      n_ip = shell_ctrl%n_gp
      IF (n_ip <= 0) THEN
        n_ip = MAX(1, SIZE(state_in%ipStates))
      END IF

      IF (ALLOCATED(shell_state_in%mat_state)) THEN
        DEALLOCATE(shell_state_in%mat_state)
      END IF
      IF (ALLOCATED(shell_state_in%mat_ss)) THEN
        DEALLOCATE(shell_state_in%mat_ss)
      END IF
      IF (ALLOCATED(shell_state_out%mat_state)) THEN
        DEALLOCATE(shell_state_out%mat_state)
      END IF
      IF (ALLOCATED(shell_state_out%mat_ss)) THEN
        DEALLOCATE(shell_state_out%mat_ss)
      END IF

      ALLOCATE(shell_state_in%mat_state(n_ip), shell_state_in%mat_ss(n_ip))
      ALLOCATE(shell_state_out%mat_state(n_ip), shell_state_out%mat_ss(n_ip))

      DO ip = 1, n_ip
        shell_state_in%mat_state(ip)%mat_id = Mat%cfg%id
        shell_state_in%mat_state(ip)%nStatev = 0_i4
        shell_state_in%mat_state(ip)%time_step = Ctx%deltaTime
        shell_state_in%mat_state(ip)%total_time = Ctx%currentTime
        shell_state_in%mat_state(ip)%is_initialized = .TRUE.

        IF (ALLOCATED(state_in%ipStates) .AND. ip <= SIZE(state_in%ipStates)) THEN
          shell_state_in%mat_state(ip)%temperature      = state_in%ipStates(ip)%temperature
          shell_state_in%mat_state(ip)%temperature_old  = state_in%ipStates(ip)%temperature

          shell_state_in%mat_ss(ip)%strain(1:6)      = state_in%ipStates(ip)%strain(1:6)
          shell_state_in%mat_ss(ip)%strain_old(1:6)  = state_in%ipStates(ip)%strain(1:6)
          shell_state_in%mat_ss(ip)%sigma(1:6)       = state_in%ipStates(ip)%sigma(1:6)
          shell_state_in%mat_ss(ip)%stress_old(1:6)  = state_in%ipStates(ip)%sigma(1:6)
        ELSE
          shell_state_in%mat_state(ip)%temperature      = 0.0_wp
          shell_state_in%mat_state(ip)%temperature_old  = 0.0_wp
        END IF
      END DO

      ! 4) Assemble SHELL TL/UL stiffness
      CALL PH_Elem_Shell_TLUL_Core(elem_type       = ElemType,             &
                                   mat_prop        = mat_prop,                &
                                   ctrl            = shell_ctrl,              &
                                   n_node          = PH_ELEM_S4_NNODE,                &
                                   n_dof_per_node  = 6_i4,                    &
                                   x_ref           = coords,                  &
                                   u_n             = RESHAPE(u, [6, PH_ELEM_S4_NNODE]), &
                                   u_inc           = 0.0_wp,                  &
                                   state_in        = shell_state_in,          &
                                   K_elem          = Ke,                      &
                                   R_elem          = R_int,                   &
                                   state_out       = shell_state_out,         &
                                   ierr            = ierr_shell)

      IF (ierr_shell /= 0_i4) THEN
        flags%failed = .TRUE.
        flags%status%status_code = IF_STATUS_ERROR
        flags%status%message = 'UF_Elem_S4_Calc: PH_Elem_Shell_TLUL_Core failed'
        RETURN
      END IF

      ! 5) To shell_state_out, state_out%ipStates(:)
      IF (.NOT. ALLOCATED(state_out%ipStates)) THEN
        ALLOCATE(state_out%ipStates(n_ip))
        DO ip = 1, n_ip
          CALL state_out%ipStates(ip)%Init()
        END DO
      END IF

      DO ip = 1, MIN(n_ip, SIZE(state_out%ipStates))
        state_out%ipStates(ip)%sigma(1:6)   = shell_state_out%mat_ss(ip)%sigma(1:6)
        state_out%ipStates(ip)%strain(1:6)  = shell_state_out%mat_ss(ip)%strain(1:6)
        state_out%ipStates(ip)%temperature  = shell_state_out%mat_state(ip)%temperature
      END DO

      RETURN
    END IF

    ! Determine integration scheme (S4R uses reduced, S4 uses full)
    IF (INDEX(TRIM(ElemType%name), 'R') > 0) THEN
      integration_scheme = PH_ELEM_S4_INTEGRATION_REDUCED
    ELSE
      integration_scheme = PH_ELEM_S4_INTEGRATION_FULL
    END IF

    ! Call S4-specific functions
    CALL PH_Elem_S4_FormStiffMatrix_Unified(coords, E_young, nu, integration_scheme, Ke)
    CALL PH_Elem_S4_FormIntForce_Unified(coords, u, E_young, nu, integration_scheme, R_int)

    ! Prepare output storage
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Write results to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_S4_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_S4_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_S4_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    flags%status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_S4_Calc

  !-----------------------------------------------------------------------------
  ! Sect (merged from PH_Elem_S4_Sect)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S4_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_S4_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_S4_GetArea

  SUBROUTINE PH_Elem_S4_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: area, dA
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip, i, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac(dNdxi, coords(1:2, 1:4), J, detJ)
      dA = detJ * weights(ip)
      area = area + dA
      DO i = 1, 3
        DO j = 1, 4
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dA
        END DO
      END DO
    END DO
    IF (area > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / area
      centroid(2) = centroid(2) / area
      centroid(3) = centroid(3) / area
    END IF
  END SUBROUTINE PH_Elem_S4_GetCentroid

  SUBROUTINE PH_Elem_S4_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_S4_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_S4_GetSectProps

  !-----------------------------------------------------------------------------
  ! Constraints (merged from PH_Elem_S4_Constraints)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 24) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_S4_ApplyConstraint

  SUBROUTINE PH_Elem_S4_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(24)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)
    INTEGER(i4) :: i, j
    DO i = 1, 24
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 24
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S4_ApplyMPC

  !-----------------------------------------------------------------------------
  ! Contact (merged from PH_Elem_S4_Cont)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 4
      ia = (a - 1) * 6 + 1
      f_a(1:3) = penalty * gap * N(a) * edge_len * n(1:3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 4
      DO b = 1, 4
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
  END SUBROUTINE PH_Elem_S4_FormContactContrib

  SUBROUTINE PH_Elem_S4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(24, 24)
    REAL(wp), INTENT(OUT) :: F_el(24)
    REAL(wp) :: xi, eta, N(4), n(3), dNdxi(2, 4)
    REAL(wp) :: t(3), len
    INTEGER(i4) :: n1, n2
    K_el = ZERO
    F_el = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_S4_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S4_EDGE_NODES(2, edge_id)
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
    CALL PH_Elem_CPS4_ShapeFunc(xi, eta, N, dNdxi)
    t(1:3) = coords(1:3, n2) - coords(1:3, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2) + t(3)*t(3))
    IF (len < 1.0e-15_wp) RETURN
    n(1) = -t(2) / len
    n(2) =  t(1) / len
    n(3) = 0.0_wp
    CALL PH_Elem_S4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, len, K_el, F_el)
  END SUBROUTINE PH_Elem_S4_FormContactEdgeCtr

  !-----------------------------------------------------------------------------
  ! Loads (merged from PH_Elem_S4_Loads)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_S4_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(24)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), J(2, 2), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS4_Jac(dNdxi, coords(1:2, 1:4), J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 4
        F_eq((i-1)*6+1) = F_eq((i-1)*6+1) + N(i) * bx * detJ * weights(ip)
        F_eq((i-1)*6+2) = F_eq((i-1)*6+2) + N(i) * by * detJ * weights(ip)
        F_eq((i-1)*6+3) = F_eq((i-1)*6+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_S4_FormBodyForce

  SUBROUTINE PH_Elem_S4_FormEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(24)
    REAL(wp) :: v1(3), v2(3), n_el(3), len, t(3)
    INTEGER(i4) :: n1, n2
    F_eq = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_S4_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_S4_EDGE_NODES(2, edge_id)
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
  END SUBROUTINE PH_Elem_S4_FormEdgePressure

  SUBROUTINE PH_Elem_S4_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(24)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 3) THEN
      CALL PH_Elem_S4_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_S4_FormEdgePressure(coords, val(1), edge_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_S4_FormNodalForce

  !-----------------------------------------------------------------------------
  ! Output (merged from PH_Elem_S4_Out)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_ELEM_S4_invert_4x4(A, info)
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
  END SUBROUTINE PH_ELEM_S4_invert_4x4

  SUBROUTINE PH_Elem_S4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 4)
      IF (SIZE(out_vars, 1) >= 3 .AND. SIZE(ip_stress, 1) >= 3) out_vars(1:3, ip) = ip_stress(1:3, ip)
      IF (SIZE(ip_strain, 1) >= 3) out_vars(4:6, ip) = ip_strain(1:3, ip)
      IF (SIZE(ip_peeq) >= ip) out_vars(7, ip) = ip_peeq(ip)
    END DO
  END SUBROUTINE PH_Elem_S4_CollectIPVars

  SUBROUTINE PH_Elem_S4_EvalVonMises(sigma, seq)
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
  END SUBROUTINE PH_Elem_S4_EvalVonMises

  SUBROUTINE PH_Elem_S4_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4)
    INTEGER(i4) :: ip, i, info
    CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
    E = ZERO
    DO ip = 1, 4
      CALL PH_Elem_CPS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 4
        E(i, ip) = N(i)
      END DO
    END DO
    CALL PH_ELEM_S4_invert_4x4(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_S4_GetExtrapMat

  SUBROUTINE PH_Elem_S4_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(4, 4)
    INTEGER(i4) :: nv
    node_vars = ZERO
    CALL PH_Elem_S4_GetExtrapMat(E)
    nv = MIN(SIZE(ip_vars, 1), SIZE(node_vars, 1))
    IF (nv >= 1 .AND. SIZE(ip_vars, 2) >= 4 .AND. SIZE(node_vars, 2) >= 4) &
      node_vars(1:nv, 1:4) = MATMUL(ip_vars(1:nv, 1:4), TRANSPOSE(E))
  END SUBROUTINE PH_Elem_S4_MapToNode

  SUBROUTINE PH_Elem_S4_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
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
  END SUBROUTINE PH_Elem_S4_Material_Update_Membrane_Routed

END MODULE PH_Elem_S4


