!===============================================================================
! MODULE: PH_Elem_C3D20
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D20 element definition (20-node quadratic hexahedron)
!===============================================================================
MODULE PH_Elem_C3D20
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE
  
  ! Public structured interfaces
  PUBLIC :: PH_Elem_C3D20_ShapeFunc
  PUBLIC :: PH_Elem_C3D20_Jac
  PUBLIC :: PH_Elem_C3D20_BMatrix
  PUBLIC :: PH_Elem_C3D20_JacB
  PUBLIC :: PH_Elem_C3D20_Strain
  PUBLIC :: PH_Elem_C3D20_Stress
  PUBLIC :: PH_Elem_C3D20_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D20_FormIntForce
  PUBLIC :: PH_Elem_C3D20_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D20_NL_TL
  PUBLIC :: PH_Elem_C3D20_NL_UL
  
  ! Public structured types
  PUBLIC :: PH_Elem_C3D20_ShapeFunc_Arg
  PUBLIC :: PH_Elem_C3D20_Jac_Arg
  PUBLIC :: PH_Elem_C3D20_BMatrix_Arg
  PUBLIC :: PH_Elem_C3D20_JacB_Arg
  PUBLIC :: PH_Elem_C3D20_Strain_Arg
  PUBLIC :: PH_Elem_C3D20_Stress_Arg
  PUBLIC :: PH_Elem_C3D20_StiffMatrix_Arg
  PUBLIC :: PH_Elem_C3D20_IntForce_Arg
  PUBLIC :: PH_Elem_C3D20_NL_TL_Arg
  PUBLIC :: PH_Elem_C3D20_NL_UL_Arg
  
  ! Legacy interfaces (kept for backward compatibility)
  PUBLIC :: PH_Elem_C3D20_DefInit
  PUBLIC :: PH_Elem_C3D20_ShapeFunc
  PUBLIC :: PH_Elem_C3D20_Jac
  PUBLIC :: PH_Elem_C3D20_BMatrix
  PUBLIC :: PH_Elem_C3D20_GaussPoints
  PUBLIC :: PH_Elem_C3D20_GaussPointsReduced
  PUBLIC :: PH_Elem_C3D20_JacB
  PUBLIC :: PH_Elem_C3D20_Strain
  PUBLIC :: PH_Elem_C3D20_Stress
  PUBLIC :: PH_Elem_C3D20_ConstMatrix
  PUBLIC :: PH_Elem_C3D20_StiffMatrix
  PUBLIC :: PH_Elem_C3D20_StiffMatrixFromD
  PUBLIC :: PH_Elem_C3D20_StiffMatrixSelective
  PUBLIC :: PH_Elem_C3D20_StiffMatrixReduced
  PUBLIC :: PH_Elem_C3D20_StiffMatrixIncompatible
  PUBLIC :: PH_Elem_C3D20_StiffMatrix27
  PUBLIC :: PH_Elem_C3D20_IntForce
  PUBLIC :: PH_Elem_C3D20_IntForceSelective
  PUBLIC :: PH_Elem_C3D20_IntForceReduced
  PUBLIC :: PH_Elem_C3D20_IntForceIncompatible
  PUBLIC :: PH_Elem_C3D20_IntForce27
  PUBLIC :: PH_Elem_C3D20_ConsMass
  PUBLIC :: PH_Elem_C3D20_LumpMass
  PUBLIC :: PH_Elem_C3D20_LumpMassReduced
  PUBLIC :: PH_Elem_C3D20_LumpMass27
  PUBLIC :: PH_Elem_C3D20_ThermStrainVector
  PUBLIC :: PH_Elem_C3D20_GaussPoints27
  PUBLIC :: PH_Elem_C3D20_Volume27
  PUBLIC :: PH_Elem_C3D20_StiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D20_IntForceByVariant
  PUBLIC :: PH_Elem_C3D20_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D20_FormIntForce
  PUBLIC :: PH_Elem_C3D20_FormStiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D20_FormIntForceByVariant
  PUBLIC :: PH_Elem_C3D20_FormGeomStiff
  PUBLIC :: PH_Elem_C3D20_NL_TL
  PUBLIC :: PH_Elem_C3D20_NL_UL
  PUBLIC :: PH_ELEM_GAUSS_PT
  PUBLIC :: PH_ELEM_C3D20_NNODE
  PUBLIC :: PH_ELEM_C3D20_NIP
  PUBLIC :: PH_ELEM_C3D20_NDOF
  PUBLIC :: PH_ELEM_C3D20_NFACE
  PUBLIC :: PH_ELEM_C3D20_FACE_NODES
  PUBLIC :: PH_ELEM_C3D20_VARIANT_STANDARD
  PUBLIC :: PH_ELEM_C3D20_VARIANT_REDUCED
  PUBLIC :: PH_ELEM_C3D20_VARIANT_HYBRID
  PUBLIC :: PH_ELEM_C3D20_VARIANT_INCOMPAT
  PUBLIC :: PH_ELEM_C3D20_VARIANT_MODIFIED
  PUBLIC :: PH_ELEM_C3D20_VARIANT_27PT
  PUBLIC :: PH_Elem_C3D20_GetVolume, PH_Elem_C3D20_GetSectProps, PH_Elem_C3D20_GetCentroid
  PUBLIC :: PH_Elem_C3D20_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D20_ApplyConstraint, PH_Elem_C3D20_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_C3D20_FormContactContrib, PH_Elem_C3D20_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D20_FormNodalForce, PH_Elem_C3D20_FormBodyForce, PH_Elem_C3D20_FormFacePressure
  PUBLIC :: PH_Elem_C3D20_CollectIPVars, PH_Elem_C3D20_MapToNode, PH_Elem_C3D20_GetExtrapMat
  PUBLIC :: PH_Elem_C3D20_EvalVonMises, PH_Elem_C3D20_EvalPrincStress
  PUBLIC :: PH_Elem_C3D20_EvalStressInvar, PH_Elem_C3D20_EvalStrainInvar, PH_Elem_C3D20_EvalTriaxiality
  PUBLIC :: PH_Elem_C3D20_Material_Update_Routed
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_NNODE = 20_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_NIP   = 27_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_NDOF  = 60_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_NFACE  = 6_i4
  ! Variant indices for unified API (C3D20/C3D20R/C3D20H/C3D20I/C3D20M/C3D20S)
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_STANDARD  = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_REDUCED   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_HYBRID   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_INCOMPAT = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_MODIFIED = 5_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_VARIANT_27PT    = 6_i4
  ! 2x2x2 Gauss: 1/sqrt(3), weight 1 per dim -> weight = 1 per IP
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp  ! 1/sqrt(3)
  ! Face topology: face k has nodes PH_ELEM_C3D20_FACE_NODES(1:4, k). Order for outward normal.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20_FACE_NODES(4, 6) = RESHAPE([ &
    1,2,3,4, 5,8,7,6, 1,2,6,5, 4,3,7,8, 1,4,8,5, 2,6,7,3 ], [4, 6])
  ! C3D20R: hourglass (Flanagan-Belytschko)
  REAL(wp), PARAMETER :: GAMMA8(8, 4) = RESHAPE([ &
    1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp, &
    1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, &
    1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, &
    1.0_wp,  1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp ], [8, 4])
  REAL(wp), PARAMETER :: HG_COEFF = 0.10_wp
  REAL(wp), PARAMETER :: W1 = 8.0_wp
  ! C3D20S: 3-point Gauss ?(3/5), 0; weights 5/9, 8/9, 5/9
  REAL(wp), PARAMETER :: GP3(3) = [-0.774596669241483_wp, 0.0_wp, 0.774596669241483_wp]
  REAL(wp), PARAMETER :: W3(3)  = [5.0_wp/9.0_wp, 8.0_wp/9.0_wp, 5.0_wp/9.0_wp]

  !=============================================================================
  ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
  !=============================================================================
  ! All data structures are organized into four categories:
  !   - Desc: Descriptor (configuration, immutable properties)
  !   - Algo: Algorithm (algorithm parameters, integration points)
  !   - Ctx:  Context (global environment, context information)
  !   - State: State (runtime mutable data, results)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! Shape Function Types
  !-----------------------------------------------------------------------------
  
  !> @brief Algorithm parameters for shape function computation
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_Algo
    REAL(wp) :: xi  ! Natural coordinate ? ? [-1, 1]
    REAL(wp) :: eta  ! Natural coordinate ? ? [-1, 1]
    REAL(wp) :: zeta  ! Natural coordinate ? ? [-1, 1]
  END TYPE PH_Elem_C3D20_ShapeFunc_Algo
  
  !> @brief State data for shape function computation
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_State
    REAL(wp) :: N(20)  ! Shape functions N_i(?,?,?)
    REAL(wp) :: dNdxi(3, 20)  ! Shape function derivatives ?N_i/??_j
  END TYPE PH_Elem_C3D20_ShapeFunc_State
  
  !> @brief Input structure for shape function computation
  
  !> @brief Output structure for shape function computation
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_Arg
    TYPE(PH_Elem_C3D20_ShapeFunc_Algo) :: algo                   ! [IN]
    TYPE(PH_Elem_C3D20_ShapeFunc_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_ShapeFunc_Arg


  !-----------------------------------------------------------------------------
  ! Jacobian Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for Jacobian computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates x_i
  END TYPE PH_Elem_C3D20_Jac_Desc
  
  !> @brief State data for Jacobian computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_State
    REAL(wp) :: dNdxi(3, 20)  ! Shape function derivatives ?N/?? (input)
    REAL(wp) :: J(3, 3)  ! Jacobian matrix J = ?x/??
    REAL(wp) :: detJ  ! Jacobian determinant |J|
  END TYPE PH_Elem_C3D20_Jac_State
  
  !> @brief Input structure for Jacobian computation
  
  !> @brief Output structure for Jacobian computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_Arg
    TYPE(PH_Elem_C3D20_Jac_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_Jac_State) :: state  ! Contains dNdxi as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Jac_Arg


  !-----------------------------------------------------------------------------
  ! B-Matrix Types
  !-----------------------------------------------------------------------------
  
  !> @brief State data for B-matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D20_BMatrix_State
    REAL(wp) :: dNdx(3, 20)  ! Shape function derivatives ?N/?x (input)
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix (output)
  END TYPE PH_Elem_C3D20_BMatrix_State
  
  !> @brief Input structure for B-matrix computation
  
  !> @brief Output structure for B-matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D20_BMatrix_Arg
    TYPE(PH_Elem_C3D20_BMatrix_State) :: state  ! Contains dNdx as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_BMatrix_Arg


  !-----------------------------------------------------------------------------
  ! Combined Jacobian and B-Matrix Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for combined JacB computation
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates x_i
  END TYPE PH_Elem_C3D20_JacB_Desc
  
  !> @brief Algorithm parameters for combined JacB computation
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Algo
    REAL(wp) :: xi  ! Natural coordinate ?
    REAL(wp) :: eta  ! Natural coordinate ?
    REAL(wp) :: zeta  ! Natural coordinate ?
  END TYPE PH_Elem_C3D20_JacB_Algo
  
  !> @brief State data for combined JacB computation
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_State
    REAL(wp) :: N(20)  ! Shape functions
    REAL(wp) :: dNdx(3, 20)  ! Shape function derivatives ?N/?x
    REAL(wp) :: J(3, 3)  ! Jacobian matrix
    REAL(wp) :: detJ  ! Jacobian determinant
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix
  END TYPE PH_Elem_C3D20_JacB_State
  
  !> @brief Input structure for combined JacB computation
  
  !> @brief Output structure for combined JacB computation
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Arg
    TYPE(PH_Elem_C3D20_JacB_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_JacB_Algo) :: algo                   ! [IN]
    TYPE(PH_Elem_C3D20_JacB_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_JacB_Arg


  !-----------------------------------------------------------------------------
  ! Strain Types
  !-----------------------------------------------------------------------------
  
  !> @brief State data for strain computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Strain_State
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix (input)
    REAL(wp) :: u(60)  ! Displacement vector (input)
    REAL(wp) :: strain(6)  ! Strain vector [?xx, ?yy, ?zz, ?xy, ?yz, ?zx]^T (output)
  END TYPE PH_Elem_C3D20_Strain_State
  
  !> @brief Input structure for strain computation
  
  !> @brief Output structure for strain computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Strain_Arg
    TYPE(PH_Elem_C3D20_Strain_State) :: state  ! Contains B and u as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Strain_Arg


  !-----------------------------------------------------------------------------
  ! Stress Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for stress computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_Desc
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_Stress_Desc
  
  !> @brief State data for stress computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_State
    REAL(wp) :: epsilon(6)  ! Strain vector (input)
    REAL(wp) :: sigma(6)  ! Stress vector [?xx, ?yy, ?zz, ?xy, ?yz, ?zx]^T (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_Stress_State
  
  !> @brief Input structure for stress computation
  
  !> @brief Output structure for stress computation
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_Arg
    TYPE(PH_Elem_C3D20_Stress_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_Stress_State) :: state  ! Contains epsilon and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Stress_Arg


  !-----------------------------------------------------------------------------
  ! Stiffness Matrix Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_StiffMatrix_Desc
  
  !> @brief State data for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_State
    REAL(wp) :: Ke(60, 60)  ! Element stiffness matrix K = ? B^TDB dV
  END TYPE PH_Elem_C3D20_StiffMatrix_State
  
  !> @brief Input structure for stiffness matrix computation
  
  !> @brief Output structure for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_Arg
    TYPE(PH_Elem_C3D20_StiffMatrix_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_StiffMatrix_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_StiffMatrix_Arg


  !-----------------------------------------------------------------------------
  ! Internal Force Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for internal force computation
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_IntForce_Desc
  
  !> @brief State data for internal force computation
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_State
    REAL(wp) :: u(60)  ! Displacement vector (input)
    REAL(wp) :: R_int(60)  ! Internal force vector R = ? B^T? dV (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_IntForce_State
  
  !> @brief Input structure for internal force computation
  
  !> @brief Output structure for internal force computation
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_Arg
    TYPE(PH_Elem_C3D20_IntForce_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_IntForce_State) :: state  ! Contains u and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_IntForce_Arg


  !-----------------------------------------------------------------------------
  ! Total Lagrangian Geometric Nonlinear Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_Desc
    REAL(wp) :: coords_ref(3, 20)  ! Reference coordinates X
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_NL_TL_Desc
  
  !> @brief State data for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_State
    REAL(wp) :: u_elem(60)  ! Displacement vector u (input)
    REAL(wp) :: Ke_mat(60, 60)  ! Material stiffness matrix K_mat (output)
    REAL(wp) :: Ke_geo(60, 60)  ! Geometric stiffness matrix K_geo (output)
    REAL(wp) :: R_int(60)  ! Internal force vector R_int (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_NL_TL_State
  
  !> @brief Input structure for Total Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_Arg
    TYPE(PH_Elem_C3D20_NL_TL_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_NL_TL_State) :: state  ! Contains u_elem and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_NL_TL_Arg


  !-----------------------------------------------------------------------------
  ! Updated Lagrangian Geometric Nonlinear Types
  !-----------------------------------------------------------------------------
  
  !> @brief Descriptor for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_Desc
    REAL(wp) :: coords_prev(3, 20)  ! Previous coordinates x_n
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_NL_UL_Desc
  
  !> @brief State data for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_State
    REAL(wp) :: u_incr(60)  ! Incremental displacement ?u (input)
    REAL(wp) :: Ke_mat(60, 60)  ! Material stiffness matrix K_mat (output)
    REAL(wp) :: Ke_geo(60, 60)  ! Geometric stiffness matrix K_geo (output)
    REAL(wp) :: R_int(60)  ! Internal force vector R_int (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_NL_UL_State
  
  !> @brief Input structure for Updated Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_Arg
    TYPE(PH_Elem_C3D20_NL_UL_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_NL_UL_State) :: state  ! Contains u_incr and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_NL_UL_Arg


CONTAINS

  SUBROUTINE PH_ELEM_C3D20_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
    REAL(wp), INTENT(IN)  :: dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp), INTENT(IN)  :: J_inv(3, 3)
    REAL(wp), INTENT(OUT) :: B_enh(6, 3)
    INTEGER(i4) :: i
    REAL(wp) :: dx(3), dy(3), dz(3)
    DO i = 1, 3
      dx(i) = J_inv(1,1)*dN_xi(i) + J_inv(1,2)*dN_eta(i) + J_inv(1,3)*dN_zeta(i)
      dy(i) = J_inv(2,1)*dN_xi(i) + J_inv(2,2)*dN_eta(i) + J_inv(2,3)*dN_zeta(i)
      dz(i) = J_inv(3,1)*dN_xi(i) + J_inv(3,2)*dN_eta(i) + J_inv(3,3)*dN_zeta(i)
    END DO
    B_enh = ZERO
    DO i = 1, 3
      B_enh(1, i) = dx(i)
      B_enh(2, i) = dy(i)
      B_enh(3, i) = dz(i)
      B_enh(4, i) = dy(i) + dx(i)
      B_enh(5, i) = dz(i) + dy(i)
      B_enh(6, i) = dx(i) + dz(i)
    END DO
  END SUBROUTINE PH_ELEM_C3D20_BEnhanced

  SUBROUTINE PH_ELEM_C3D20_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N_enh(3), dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp) :: oxi, oeta, ozeta
    oxi   = ONE - xi*xi
    oeta  = ONE - eta*eta
    ozeta = ONE - zeta*zeta
    N_enh(1) = oxi * oeta * ozeta
    N_enh(2) = xi * oeta * ozeta
    N_enh(3) = eta * oxi * ozeta
    dN_xi(1)  = -2.0_wp*xi * oeta * ozeta
    dN_xi(2)  = oeta * ozeta
    dN_xi(3)  = -2.0_wp*eta*xi * ozeta
    dN_eta(1) = -2.0_wp*eta * oxi * ozeta
    dN_eta(2) = -2.0_wp*xi*eta * ozeta
    dN_eta(3) = oxi * ozeta
    dN_zeta(1)= -2.0_wp*zeta * oxi * oeta
    dN_zeta(2)= -2.0_wp*xi*zeta * oeta
    dN_zeta(3)= -2.0_wp*eta*zeta * oxi
  END SUBROUTINE PH_ELEM_C3D20_IncompatibleShapeFunc

  SUBROUTINE PH_ELEM_C3D20_Inv3x3(A, Ainv, detA)
    REAL(wp), INTENT(IN)  :: A(3, 3)
    REAL(wp), INTENT(OUT) :: Ainv(3, 3)
    REAL(wp), INTENT(OUT) :: detA
    REAL(wp) :: c11, c12, c13, c21, c22, c23, c31, c32, c33
    c11 = A(2,2)*A(3,3) - A(2,3)*A(3,2)
    c12 = -(A(2,1)*A(3,3) - A(2,3)*A(3,1))
    c13 = A(2,1)*A(3,2) - A(2,2)*A(3,1)
    c21 = -(A(1,2)*A(3,3) - A(1,3)*A(3,2))
    c22 = A(1,1)*A(3,3) - A(1,3)*A(3,1)
    c23 = -(A(1,1)*A(3,2) - A(1,2)*A(3,1))
    c31 = A(1,2)*A(2,3) - A(1,3)*A(2,2)
    c32 = -(A(1,1)*A(2,3) - A(1,3)*A(2,1))
    c33 = A(1,1)*A(2,2) - A(1,2)*A(2,1)
    detA = A(1,1)*c11 + A(1,2)*c12 + A(1,3)*c13
    IF (ABS(detA) <= 1.0e-20_wp) THEN
      Ainv = ZERO
      RETURN
    END IF
    Ainv(1,1) = c11/detA
    Ainv(1,2) = c21/detA
    Ainv(1,3) = c31/detA
    Ainv(2,1) = c12/detA
    Ainv(2,2) = c22/detA
    Ainv(2,3) = c32/detA
    Ainv(3,1) = c13/detA
    Ainv(3,2) = c23/detA
    Ainv(3,3) = c33/detA
  END SUBROUTINE PH_ELEM_C3D20_Inv3x3

  SUBROUTINE PH_ELEM_C3D20_Volume_27pt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_C3D20_Volume_27pt

  SUBROUTINE PH_El_C3_FormIntForceByVaria(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(60)
    CALL PH_Elem_C3D20_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
  END SUBROUTINE PH_Elem_C3D20_FormIntForceByVariant

  SUBROUTINE PH_El_C3_FormStiffMatrixByVa(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    CALL PH_Elem_C3D20_StiffMatrixByVariant(coords, E_young, nu, variant, Ke)
  END SUBROUTINE PH_Elem_C3D20_FormStiffMatrixByVariant

  SUBROUTINE PH_El_C3_GaussPointsReduced(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: p(2), w1d(2)
    INTEGER(i4) :: i, j, k, idx
    p(1)  = -PH_ELEM_GAUSS_PT  ! -1/sqrt(3)
    p(2)  =  PH_ELEM_GAUSS_PT  !  1/sqrt(3)
    w1d(1)= ONE
    w1d(2)= ONE
    idx = 0
    DO i = 1, 2
      DO j = 1, 2
        DO k = 1, 2
          idx = idx + 1
          xi(idx) = p(i)
          eta(idx) = p(j)
          zeta(idx) = p(k)
          weights(idx) = w1d(i) * w1d(j) * w1d(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_GaussPointsReduced

  SUBROUTINE PH_El_C3_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(60)
    IF (variant == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D20_IntForceReduced(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D20_IntForceSelective(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D20_IntForceIncompatible(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_27PT) THEN
      CALL PH_Elem_C3D20_IntForce27(coords, u, E_young, nu, R_int)
    ELSE
      CALL PH_Elem_C3D20_IntForce(coords, u, E_young, nu, R_int)
    END IF
  END SUBROUTINE PH_Elem_C3D20_IntForceByVariant

  SUBROUTINE PH_El_C3_IntForceIncompatibl(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(60)
    REAL(wp) :: Ke(60, 60)
    CALL PH_Elem_C3D20_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D20_IntForceIncompatible

  SUBROUTINE PH_El_C3_IntForceReduced(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(60)
    CALL PH_Elem_C3D20_IntForce(coords, u, E_young, nu, R_int)
  END SUBROUTINE PH_Elem_C3D20_IntForceReduced

  SUBROUTINE PH_El_C3_IntForceSelective(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: B_vol(60), B_vol_avg(60), B_mod(6, 60)
    REAL(wp) :: strain(6), sigma(6), dV, volume
    INTEGER(i4) :: ip

    R_int = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:60) = (B(1,1:60) + B(2,1:60) + B(3,1:60)) / 3.0_wp
      B_vol_avg(1:60) = B_vol_avg(1:60) + B_vol(1:60) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:60) = B_vol_avg(1:60) / volume

    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:60) = (B(1,1:60) + B(2,1:60) + B(3,1:60)) / 3.0_wp
      B_mod(1, 1:60) = B(1, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(2, 1:60) = B(2, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(3, 1:60) = B(3, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(4:6, 1:60) = B(4:6, 1:60)
      CALL PH_Elem_C3D20_Strain(B_mod, u, strain)
      CALL PH_Elem_C3D20_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B_mod), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D20_IntForceSelective

  SUBROUTINE PH_El_C3_LumpMassReduced(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(60)
    CALL PH_Elem_C3D20_LumpMass(coords, rho, M_lumped)
  END SUBROUTINE PH_Elem_C3D20_LumpMassReduced

  SUBROUTINE PH_El_C3_StiffMatrixByVarian(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    IF (variant == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D20_StiffMatrixReduced(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D20_StiffMatrixSelective(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D20_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D20_VARIANT_27PT) THEN
      CALL PH_Elem_C3D20_StiffMatrix27(coords, E_young, nu, Ke)
    ELSE
      CALL PH_Elem_C3D20_StiffMatrix(coords, E_young, nu, Ke)
    END IF
  END SUBROUTINE PH_Elem_C3D20_StiffMatrixByVariant

  SUBROUTINE PH_El_C3_StiffMatrixIncompat(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: J_inv(3, 3)
    REAL(wp) :: N_enh(3), dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp) :: B_enh(6, 3)
    REAL(wp) :: Ke_uu(60, 60), Ke_ua(60, 3), Ke_aa(3, 3)
    REAL(wp) :: Ke_aa_inv(3, 3), tmp(60, 3), det_aa
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_uu = ZERO
    Ke_ua = ZERO
    Ke_aa = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      J_inv(1,1) = (J(2,2)*J(3,3)-J(2,3)*J(3,2))/detJ
      J_inv(1,2) = -(J(1,2)*J(3,3)-J(1,3)*J(3,2))/detJ
      J_inv(1,3) = (J(1,2)*J(2,3)-J(1,3)*J(2,2))/detJ
      J_inv(2,1) = -(J(2,1)*J(3,3)-J(2,3)*J(3,1))/detJ
      J_inv(2,2) = (J(1,1)*J(3,3)-J(1,3)*J(3,1))/detJ
      J_inv(2,3) = -(J(1,1)*J(2,3)-J(1,3)*J(2,1))/detJ
      J_inv(3,1) = (J(2,1)*J(3,2)-J(2,2)*J(3,1))/detJ
      J_inv(3,2) = -(J(1,1)*J(3,2)-J(1,2)*J(3,1))/detJ
      J_inv(3,3) = (J(1,1)*J(2,2)-J(1,2)*J(2,1))/detJ
      CALL PH_ELEM_C3D20_IncompatibleShapeFunc(xi(ip), eta(ip), zeta(ip), N_enh, dN_xi, dN_eta, dN_zeta)
      CALL PH_ELEM_C3D20_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
      Ke_uu = Ke_uu + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B)
      Ke_ua = Ke_ua + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B_enh)
      Ke_aa = Ke_aa + dV * MATMUL(MATMUL(TRANSPOSE(B_enh), D), B_enh)
    END DO
    CALL PH_ELEM_C3D20_Inv3x3(Ke_aa, Ke_aa_inv, det_aa)
    IF (ABS(det_aa) <= 1.0e-20_wp) THEN
      Ke = Ke_uu
      RETURN
    END IF
    tmp = MATMUL(Ke_ua, Ke_aa_inv)
    Ke = Ke_uu - MATMUL(tmp, TRANSPOSE(Ke_ua))
  END SUBROUTINE PH_Elem_C3D20_StiffMatrixIncompatible

  SUBROUTINE PH_El_C3_StiffMatrixReduced(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    CALL PH_Elem_C3D20_StiffMatrix(coords, E_young, nu, Ke)
  END SUBROUTINE PH_Elem_C3D20_StiffMatrixReduced

  SUBROUTINE PH_El_C3_StiffMatrixSelectiv(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(60, 60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: B_vol(60), B_vol_avg(60), B_mod(6, 60)
    REAL(wp) :: dV, volume, BTD(60, 6)
    INTEGER(i4) :: ip

    Ke = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:60) = (B(1,1:60) + B(2,1:60) + B(3,1:60)) / 3.0_wp
      B_vol_avg(1:60) = B_vol_avg(1:60) + B_vol(1:60) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:60) = B_vol_avg(1:60) / volume

    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:60) = (B(1,1:60) + B(2,1:60) + B(3,1:60)) / 3.0_wp
      B_mod(1, 1:60) = B(1, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(2, 1:60) = B(2, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(3, 1:60) = B(3, 1:60) + (B_vol_avg(1:60) - B_vol(1:60))
      B_mod(4:6, 1:60) = B(4:6, 1:60)
      BTD = MATMUL(TRANSPOSE(B_mod), D)
      Ke = Ke + dV * MATMUL(BTD, B_mod)
    END DO
  END SUBROUTINE PH_Elem_C3D20_StiffMatrixSelective

  SUBROUTINE PH_El_C3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1:3) = alpha * deltaT
    eps_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D20_ThermStrainVector

  SUBROUTINE PH_Elem_C3D20_BMatrix(arg)
    TYPE(PH_Elem_C3D20_BMatrix_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: i, c
    
    CALL init_error_status(arg%status)
    
    arg%state%B = ZERO
    DO i = 1, 20
      c = 3 * (i - 1) + 1
      arg%state%B(1, c)     = arg%state%dNdx(1, i)  ! ?xx component
      arg%state%B(2, c+1)   = arg%state%dNdx(2, i)  ! ?yy component
      arg%state%B(3, c+2)   = arg%state%dNdx(3, i)  ! ?zz component
      arg%state%B(4, c)     = arg%state%dNdx(2, i)  ! ?xy component (shear)
      arg%state%B(4, c+1)   = arg%state%dNdx(1, i)  ! ?xy component (shear)
      arg%state%B(5, c+1)   = arg%state%dNdx(3, i)  ! ?yz component (shear)
      arg%state%B(5, c+2)   = arg%state%dNdx(2, i)  ! ?yz component (shear)
      arg%state%B(6, c)     = arg%state%dNdx(3, i)  ! ?zx component (shear)
      arg%state%B(6, c+2)   = arg%state%dNdx(1, i)  ! ?zx component (shear)
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D20_BMatrix

  SUBROUTINE PH_Elem_C3D20_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(60, 60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: dV, M_scalar
    INTEGER(i4) :: ip, i, j, d

    Me = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 20
        DO j = 1, 20
          M_scalar = N(i) * N(j) * dV
          DO d = 1, 3
            Me(3*(i-1)+d, 3*(j-1)+d) = Me(3*(i-1)+d, 3*(j-1)+d) + M_scalar
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_ConsMass

  SUBROUTINE PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: lambda, mu, c1, c2
    lambda = E_young * nu / ((ONE + nu) * (ONE - 2.0_wp * nu))
    mu = E_young / (2.0_wp * (ONE + nu))
    c1 = lambda + 2.0_wp * mu
    c2 = lambda
    D = ZERO
    D(1,1) = c1
    D(2,2) = c1
    D(3,3) = c1
    D(1,2) = c2
    D(1,3) = c2
    D(2,1) = c2
    D(2,3) = c2
    D(3,1) = c2
    D(3,2) = c2
    D(4,4) = mu
    D(5,5) = mu
    D(6,6) = mu
  END SUBROUTINE PH_Elem_C3D20_ConstMatrix

  SUBROUTINE PH_Elem_C3D20_DefInit()
    !! No-op: C3D20 has fixed topology (20 nodes, 27 IPs).
  END SUBROUTINE PH_Elem_C3D20_DefInit

  SUBROUTINE PH_Elem_C3D20_FormGeomStiff(coords, sigma, Kg)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: Kg(60, 60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), dNdx(3, 20), J(3, 3), J_inv(3, 3), detJ
    REAL(wp) :: S(3, 3), GtS(60, 3)
    INTEGER(i4) :: ip, i, j, k, node_i, node_j

    Kg = ZERO
    S(1, 1) = sigma(1)
    S(1, 2) = sigma(4)
    S(1, 3) = sigma(6)
    S(2, 1) = sigma(4)
    S(2, 2) = sigma(2)
    S(2, 3) = sigma(5)
    S(3, 1) = sigma(6)
    S(3, 2) = sigma(5)
    S(3, 3) = sigma(3)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_ELEM_C3D20_Inv3x3(J, J_inv, detJ)
      dNdx = MATMUL(J_inv, dNdxi)
      ! GtS(i,k) = (G^T S)(i,k); G(i,:)=dNdx at node_i => GtS(i,k)= sum_j dNdx(j,node_i)*S(j,k)
      GtS = ZERO
      DO i = 1, 60
        node_i = (i + 2) / 3
        DO k = 1, 3
          DO j = 1, 3
            GtS(i, k) = GtS(i, k) + dNdx(j, node_i) * S(j, k)
          END DO
        END DO
      END DO
      DO j = 1, 60
        node_j = (j + 2) / 3
        DO i = 1, 60
          Kg(i, j) = Kg(i, j) + (GtS(i, 1)*dNdx(1, node_j) + GtS(i, 2)*dNdx(2, node_j) + GtS(i, 3)*dNdx(3, node_j)) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_FormGeomStiff

  SUBROUTINE PH_Elem_C3D20_FormIntForce(arg)
    TYPE(PH_Elem_C3D20_IntForce_Arg), INTENT(INOUT) :: arg

    TYPE(PH_Elem_C3D20_JacB_Arg) :: jb
    TYPE(PH_Elem_C3D20_Strain_Arg) :: st
    TYPE(PH_Elem_C3D20_Stress_Arg) :: sg

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: dV
    INTEGER(i4) :: ip

    CALL init_error_status(arg%status)

    IF (.NOT. ALLOCATED(arg%state%mat_state)) THEN
      ALLOCATE(arg%state%mat_state(27))
    END IF

    IF (.NOT. ALLOCATED(sg%state%mat_state)) THEN
      ALLOCATE(sg%state%mat_state(SIZE(arg%state%mat_state)))
    ELSE IF (SIZE(sg%state%mat_state) /= SIZE(arg%state%mat_state)) THEN
      DEALLOCATE(sg%state%mat_state)
      ALLOCATE(sg%state%mat_state(SIZE(arg%state%mat_state)))
    END IF

    arg%state%evo%R_int = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)

    DO ip = 1, 27
      jb%desc%coords = arg%desc%coords
      jb%algo%xi = xi(ip)
      jb%algo%eta = eta(ip)
      jb%algo%zeta = zeta(ip)
      CALL PH_Elem_C3D20_JacB_Struct(jb)

      IF (jb%status%status_code /= IF_STATUS_OK .OR. ABS(jb%state%detJ) <= 1.0e-12_wp) CYCLE

      dV = jb%state%detJ * weights(ip)

      st%state%B = jb%state%B
      st%state%u = arg%state%u
      CALL PH_Elem_C3D20_Strain(st)

      sg%desc%mat_prop = arg%desc%mat_prop
      sg%state%epsilon = st%state%strain
      sg%state%mat_state = arg%state%mat_state
      CALL PH_Elem_C3D20_Stress(sg)
      IF (sg%status%status_code /= IF_STATUS_OK) THEN
        arg%status = sg%status
        RETURN
      END IF
      arg%state%mat_state = sg%state%mat_state

      arg%state%evo%R_int = arg%state%evo%R_int + dV * MATMUL(TRANSPOSE(jb%state%B), sg%state%sigma)
    END DO

    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Elem_C3D20_FormIntForce

  SUBROUTINE PH_Elem_C3D20_FormStiffMatrix(arg)
    TYPE(PH_Elem_C3D20_StiffMatrix_Arg), INTENT(INOUT) :: arg

    TYPE(PH_Elem_C3D20_JacB_Arg) :: jb

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: D(6, 6)
    REAL(wp) :: E_young, nu
    REAL(wp) :: BTD(60, 6), dV
    INTEGER(i4) :: ip
    
    CALL init_error_status(arg%status)
    
    ! Isotropic elastic constants from MatPropertyDef (props(1)=E, props(2)=nu typical)
    E_young = 2.0e11_wp
    nu = 0.3_wp
    IF (ALLOCATED(arg%desc%mat_prop%props)) THEN
      IF (arg%desc%mat_prop%num_props >= 1 .AND. SIZE(arg%desc%mat_prop%props) >= 1) &
        E_young = arg%desc%mat_prop%props(1)
      IF (arg%desc%mat_prop%num_props >= 2 .AND. SIZE(arg%desc%mat_prop%props) >= 2) &
        nu = arg%desc%mat_prop%props(2)
    END IF
    IF (E_young <= 1.0e-12_wp .OR. nu <= -ONE + 1.0e-6_wp .OR. nu >= HALF - 1.0e-6_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    
    arg%state%evo%Ke = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    
    DO ip = 1, 27
      jb%desc%coords = arg%desc%coords
      jb%algo%xi = xi(ip)
      jb%algo%eta = eta(ip)
      jb%algo%zeta = zeta(ip)
      CALL PH_Elem_C3D20_JacB_Struct(jb)

      IF (jb%status%status_code /= IF_STATUS_OK .OR. ABS(jb%state%detJ) <= 1.0e-12_wp) CYCLE

      dV = jb%state%detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(jb%state%B), D)
      arg%state%evo%Ke = arg%state%evo%Ke + dV * MATMUL(BTD, jb%state%B)
    END DO

    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Elem_C3D20_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: i, j, k, idx
    idx = 0
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          idx = idx + 1
          xi(idx) = GP3(i)
          eta(idx) = GP3(j)
          zeta(idx) = GP3(k)
          weights(idx) = W3(i) * W3(j) * W3(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_GaussPoints

  SUBROUTINE PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: i, j, k, idx
    idx = 0
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          idx = idx + 1
          xi(idx) = GP3(i)
          eta(idx) = GP3(j)
          zeta(idx) = GP3(k)
          weights(idx) = W3(i) * W3(j) * W3(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_GaussPoints27

  SUBROUTINE PH_Elem_C3D20_IntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip

    R_int = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D20_Strain(B, u, strain)
      CALL PH_Elem_C3D20_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D20_IntForce

  SUBROUTINE PH_Elem_C3D20_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma6)
    END DO
  END SUBROUTINE PH_Elem_C3D20_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D20_IntForce27(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D20_Strain(B, u, strain)
      CALL PH_Elem_C3D20_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D20_IntForce27

  ! Scalar wrapper for Sect/Cont/Loads/Out
  SUBROUTINE PH_Elem_C3D20_Jac_Scalar(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 20)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(PH_Elem_C3D20_Jac_Arg) :: jac
    jac%state%dNdxi = dNdxi
    jac%desc%coords = coords
    CALL PH_Elem_C3D20_Jac_Struct(jac)
    J = jac%state%J
    detJ = jac%state%detJ
  END SUBROUTINE PH_Elem_C3D20_Jac_Scalar

  SUBROUTINE PH_Elem_C3D20_Jac_Struct(arg)
    TYPE(PH_Elem_C3D20_Jac_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: i, j, k
    
    CALL init_error_status(arg%status)
    
    arg%state%J = ZERO
    DO j = 1, 3
      DO k = 1, 3
        DO i = 1, 20
          arg%state%J(j, k) = arg%state%J(j, k) + arg%state%dNdxi(k, i) * arg%desc%coords(j, i)
        END DO
      END DO
    END DO
    
    arg%state%detJ = arg%state%J(1,1)*(arg%state%J(2,2)*arg%state%J(3,3) - arg%state%J(2,3)*arg%state%J(3,2)) &
             - arg%state%J(1,2)*(arg%state%J(2,1)*arg%state%J(3,3) - arg%state%J(2,3)*arg%state%J(3,1)) &
             + arg%state%J(1,3)*(arg%state%J(2,1)*arg%state%J(3,2) - arg%state%J(2,2)*arg%state%J(3,1))
    
    IF (ABS(arg%state%detJ) < 1.0e-12_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "C3D20 Jac: Jacobian determinant too small"
      RETURN
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D20_Jac_Struct

  ! Generic interface for Jac: scalar and structured
  INTERFACE PH_Elem_C3D20_Jac
    MODULE PROCEDURE PH_Elem_C3D20_Jac_Scalar
    MODULE PROCEDURE PH_Elem_C3D20_Jac_Struct
  END INTERFACE PH_Elem_C3D20_Jac

  ! Scalar wrapper for Sect/Cont/Loads/Out
  SUBROUTINE PH_Elem_C3D20_JacB_Scalar(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt, zeta_pt
    REAL(wp), INTENT(OUT) :: N(20)
    REAL(wp), INTENT(OUT) :: dNdx(3, 20)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 60)
    TYPE(PH_Elem_C3D20_JacB_Arg) :: jb
    jb%desc%coords = coords
    jb%algo%xi = xi_pt
    jb%algo%eta = eta_pt
    jb%algo%zeta = zeta_pt
    CALL PH_Elem_C3D20_JacB_Struct(jb)
    N = jb%state%N
    dNdx = jb%state%dNdx
    J = jb%state%J
    detJ = jb%state%detJ
    B = jb%state%B
  END SUBROUTINE PH_Elem_C3D20_JacB_Scalar

  SUBROUTINE PH_Elem_C3D20_JacB_Struct(arg)
    TYPE(PH_Elem_C3D20_JacB_Arg), INTENT(INOUT) :: arg

    TYPE(PH_Elem_C3D20_ShapeFunc_Arg) :: sf
    TYPE(PH_Elem_C3D20_Jac_Arg) :: jac
    TYPE(PH_Elem_C3D20_BMatrix_Arg) :: bm

    REAL(wp) :: dNdxi(3, 20), J_inv(3, 3)
    INTEGER(i4) :: i, j, k

    CALL init_error_status(arg%status)

    ! Compute shape functions
    sf%algo%xi = arg%algo%xi
    sf%algo%eta = arg%algo%eta
    sf%algo%zeta = arg%algo%zeta
    CALL PH_Elem_C3D20_ShapeFunc_Struct(sf)
    IF (sf%status%status_code /= IF_STATUS_OK) THEN
      arg%status = sf%status
      RETURN
    END IF
    arg%state%N = sf%state%N
    dNdxi = sf%state%dNdxi

    ! Compute Jacobian
    jac%state%dNdxi = dNdxi
    jac%desc%coords = arg%desc%coords
    CALL PH_Elem_C3D20_Jac_Struct(jac)
    IF (jac%status%status_code /= IF_STATUS_OK) THEN
      arg%status = jac%status
      RETURN
    END IF
    arg%state%J = jac%state%J
    arg%state%detJ = jac%state%detJ
    
    ! Compute dN/dx = J^(-1)dN/d?
    IF (ABS(arg%state%detJ) > 1.0e-20_wp) THEN
      J_inv(1,1) = (arg%state%J(2,2)*arg%state%J(3,3) - arg%state%J(2,3)*arg%state%J(3,2)) / arg%state%detJ
      J_inv(1,2) = -(arg%state%J(1,2)*arg%state%J(3,3) - arg%state%J(1,3)*arg%state%J(3,2)) / arg%state%detJ
      J_inv(1,3) = (arg%state%J(1,2)*arg%state%J(2,3) - arg%state%J(1,3)*arg%state%J(2,2)) / arg%state%detJ
      J_inv(2,1) = -(arg%state%J(2,1)*arg%state%J(3,3) - arg%state%J(2,3)*arg%state%J(3,1)) / arg%state%detJ
      J_inv(2,2) = (arg%state%J(1,1)*arg%state%J(3,3) - arg%state%J(1,3)*arg%state%J(3,1)) / arg%state%detJ
      J_inv(2,3) = -(arg%state%J(1,1)*arg%state%J(2,3) - arg%state%J(1,3)*arg%state%J(2,1)) / arg%state%detJ
      J_inv(3,1) = (arg%state%J(2,1)*arg%state%J(3,2) - arg%state%J(2,2)*arg%state%J(3,1)) / arg%state%detJ
      J_inv(3,2) = -(arg%state%J(1,1)*arg%state%J(3,2) - arg%state%J(1,2)*arg%state%J(3,1)) / arg%state%detJ
      J_inv(3,3) = (arg%state%J(1,1)*arg%state%J(2,2) - arg%state%J(1,2)*arg%state%J(2,1)) / arg%state%detJ
      DO i = 1, 20
        DO j = 1, 3
          arg%state%dNdx(j, i) = ZERO
          DO k = 1, 3
            arg%state%dNdx(j, i) = arg%state%dNdx(j, i) + J_inv(j, k) * dNdxi(k, i)
          END DO
        END DO
      END DO
    ELSE
      arg%state%dNdx = ZERO
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "C3D20 JacB: Jacobian determinant too small"
      RETURN
    END IF
    
    ! Compute B-matrix
    bm%state%dNdx = arg%state%dNdx
    CALL PH_Elem_C3D20_BMatrix(bm)
    IF (bm%status%status_code /= IF_STATUS_OK) THEN
      arg%status = bm%status
      RETURN
    END IF
    arg%state%B = bm%state%B

    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Elem_C3D20_JacB_Struct

  ! Generic interface for JacB: scalar and structured
  INTERFACE PH_Elem_C3D20_JacB
    MODULE PROCEDURE PH_Elem_C3D20_JacB_Scalar
    MODULE PROCEDURE PH_Elem_C3D20_JacB_Struct
  END INTERFACE PH_Elem_C3D20_JacB

  SUBROUTINE PH_Elem_C3D20_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d

    M_lumped = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 20
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_LumpMass

  SUBROUTINE PH_Elem_C3D20_LumpMass27(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d
    M_lumped = ZERO
    CALL PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 20
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_LumpMass27

  SUBROUTINE PH_Elem_C3D20_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
    USE MD_Mat_Lib, ONLY: MatPropertyDef
    USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag
    IMPLICIT NONE
    
    REAL(wp), INTENT(IN)  :: coords_ref(3, 20)
    REAL(wp), INTENT(IN)  :: u_elem(60)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(60, 60)
    REAL(wp), INTENT(OUT) :: Ke_geo(60, 60)
    REAL(wp), INTENT(OUT) :: R_int(60)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant  ! Variant: STANDARD(1), REDUCED(2), etc.
    
    REAL(wp) :: coords_curr(3, 20)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(27), eta_gp(27), zeta_gp(27), wt_gp(27)
    REAL(wp) :: xi_gp8(8), eta_gp8(8), zeta_gp8(8), wt_gp8(8)  ! For REDUCED (222)
    REAL(wp) :: N(20), dN_dxi(3, 20), J_ref(3, 3), J_inv(3, 3), det_J
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: K_mat_gp(60, 60), K_geo_gp(60, 60), R_gp(60)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: i, igp, variant_use, n_gp, j
    
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS
    
    ! Determine variant (default to STANDARD)
    IF (PRESENT(variant)) THEN
      variant_use = variant
    ELSE
      variant_use = PH_ELEM_C3D20_VARIANT_STANDARD
    END IF
    
    DO i = 1, 20
      coords_curr(:, i) = coords_ref(:, i) + u_elem(3*(i-1)+1:3*i)
    END DO

    cfg%formulation_typ = 1
    DO i = 1, 20
      cfg%coords_ref(i, :) = coords_ref(:, i)
      cfg%coords_curr(i, :) = coords_curr(:, i)
    END DO
    
    ! Select Gauss points based on variant
    IF (variant_use == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
      ! REDUCED: 222 = 8 points
      CALL PH_Elem_C3D20_GaussPointsReduced(xi_gp8, eta_gp8, zeta_gp8, wt_gp8)
      n_gp = 8
    ELSE
      ! STANDARD: 333 = 27 points
      CALL PH_Elem_C3D20_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)
      n_gp = 27
    END IF
    
    DO igp = 1, n_gp
      IF (variant_use == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
        CALL PH_Elem_C3D20_ShapeFunc(xi_gp8(igp), eta_gp8(igp), zeta_gp8(igp), N, dN_dxi)
        CALL PH_Elem_C3D20_Jac(dN_dxi, coords_ref, J_ref, det_J)
        IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
        CALL PH_ELEM_C3D20_Inv3x3(J_ref, J_inv, det_J)
        
        DO i = 1, 20
          cfg%lcl%dN_dX(i, :) = MATMUL(J_inv, dN_dxi(:, i))
        END DO
        
        ! Compute 3D deformation gradient F
        F = ZERO
        DO i = 1, 20
          DO j = 1, 3
            F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 1)
            F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 2)
            F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 3)
          END DO
        END DO

        ! Green-Lagrange strain E = 0.5*(F^T*F - I)
        E(1,1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
        E(2,2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
        E(3,3) = HALF * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
        E(1,2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2))
        E(2,3) = HALF * (F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3))
        E(1,3) = HALF * (F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3))
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
        CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
        IF (mat_status%status_code /= 0) THEN
          status%code = IF_STATUS_ERROR

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
        
        CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
        IF (status%code /= STATUS_SUCCESS) THEN

          RETURN
        END IF
        
        Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp8(igp)
        Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp8(igp)
        R_int = R_int + R_gp * det_J * wt_gp8(igp)
      ELSE
        CALL PH_Elem_C3D20_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
        CALL PH_Elem_C3D20_Jac(dN_dxi, coords_ref, J_ref, det_J)
        IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
        CALL PH_ELEM_C3D20_Inv3x3(J_ref, J_inv, det_J)
        
        DO i = 1, 20
          cfg%lcl%dN_dX(i, :) = MATMUL(J_inv, dN_dxi(:, i))
        END DO
        
        ! Compute 3D deformation gradient F
        F = ZERO
        DO i = 1, 20
          DO j = 1, 3
            F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 1)
            F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 2)
            F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 3)
          END DO
        END DO

        ! Green-Lagrange strain E = 0.5*(F^T*F - I)
        E(1,1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
        E(2,2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
        E(3,3) = HALF * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
        E(1,2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2))
        E(2,3) = HALF * (F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3))
        E(1,3) = HALF * (F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3))
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
        CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
        IF (mat_status%status_code /= 0) THEN
          status%code = IF_STATUS_ERROR

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
        
        CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
        IF (status%code /= STATUS_SUCCESS) THEN

          RETURN
        END IF
        
        Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
        Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
        R_int = R_int + R_gp * det_J * wt_gp(igp)
      END IF
    END DO

  END SUBROUTINE PH_Elem_C3D20_NL_TL

  SUBROUTINE PH_Elem_C3D20_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
    USE MD_Mat_Lib, ONLY: MatPropertyDef
    USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_UpdLag
    IMPLICIT NONE
    
    REAL(wp), INTENT(IN)  :: coords_prev(3, 20), u_incr(60)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(60, 60), Ke_geo(60, 60), R_int(60)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant  ! Variant: STANDARD(1), REDUCED(2), etc.
    
    REAL(wp) :: coords_curr(3, 20)
    TYPE(RT_LagrCfg) :: cfg
    REAL(wp) :: xi_gp(27), eta_gp(27), zeta_gp(27), wt_gp(27)
    REAL(wp) :: xi_gp8(8), eta_gp8(8), zeta_gp8(8), wt_gp8(8)  ! For REDUCED
    REAL(wp) :: N(20), dN_dxi(3, 20), J_prev(3, 3), J_inv(3, 3), det_J
    REAL(wp) :: F(3,3), epsilon(3,3), sigma(3,3)
    REAL(wp) :: b(3,3), b_inv(3,3), det_b  ! Left Cauchy-Green tensor for UL
    REAL(wp) :: e_Almansi(3,3)  ! Almansi strain tensor
    REAL(wp) :: K_mat_gp(60,60), K_geo_gp(60,60), R_gp(60)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: i, igp, variant_use, n_gp, j
    
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS
    
    ! Determine variant (default to STANDARD)
    IF (PRESENT(variant)) THEN
      variant_use = variant
    ELSE
      variant_use = PH_ELEM_C3D20_VARIANT_STANDARD
    END IF
    
    DO i = 1, 20
      coords_curr(:, i) = coords_prev(:, i) + u_incr(3*(i-1)+1:3*i)
    END DO

    cfg%formulation_typ = 2
    DO i = 1, 20
      cfg%coords_prev(i,:) = coords_prev(:,i)
      cfg%coords_curr(i,:) = coords_curr(:,i)
    END DO
    
    ! Select Gauss points based on variant
    IF (variant_use == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
      ! REDUCED: 222 = 8 points
      CALL PH_Elem_C3D20_GaussPointsReduced(xi_gp8, eta_gp8, zeta_gp8, wt_gp8)
      n_gp = 8
    ELSE
      ! STANDARD: 333 = 27 points
      CALL PH_Elem_C3D20_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)
      n_gp = 27
    END IF
    
    DO igp = 1, n_gp
      IF (variant_use == PH_ELEM_C3D20_VARIANT_REDUCED) THEN
        CALL PH_Elem_C3D20_ShapeFunc(xi_gp8(igp), eta_gp8(igp), zeta_gp8(igp), N, dN_dxi)
        CALL PH_Elem_C3D20_Jac(dN_dxi, coords_prev, J_prev, det_J)
        IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
        CALL PH_ELEM_C3D20_Inv3x3(J_prev, J_inv, det_J)
        
        DO i = 1, 20
          cfg%dN_dx(i,:) = MATMUL(J_inv, dN_dxi(:,i))
        END DO
        
        ! Compute 3D deformation gradient F = ?x/?X_prev
        F = ZERO
        DO i = 1, 20
          DO j = 1, 3
            F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%dN_dx(i, 1)
            F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%dN_dx(i, 2)
            F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%dN_dx(i, 3)
          END DO
        END DO
        
        ! Left Cauchy-Green tensor b = F*F^T
        b(1,1) = F(1,1)*F(1,1) + F(1,2)*F(1,2) + F(1,3)*F(1,3)
        b(2,2) = F(2,1)*F(2,1) + F(2,2)*F(2,2) + F(2,3)*F(2,3)
        b(3,3) = F(3,1)*F(3,1) + F(3,2)*F(3,2) + F(3,3)*F(3,3)
        b(1,2) = F(1,1)*F(2,1) + F(1,2)*F(2,2) + F(1,3)*F(2,3)
        b(2,3) = F(2,1)*F(3,1) + F(2,2)*F(3,2) + F(2,3)*F(3,3)
        b(1,3) = F(1,1)*F(3,1) + F(1,2)*F(3,2) + F(1,3)*F(3,3)
        b(2,1) = b(1,2); b(3,2) = b(2,3); b(3,1) = b(1,3)
        
        ! Compute b^{-1}
        det_b = b(1,1)*(b(2,2)*b(3,3) - b(2,3)*b(3,2)) - b(1,2)*(b(2,1)*b(3,3) - b(2,3)*b(3,1)) + b(1,3)*(b(2,1)*b(3,2) - b(2,2)*b(3,1))
        IF (ABS(det_b) <= 1.0e-14_wp) CYCLE
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
        e_Almansi(1,2) = -0.5_wp * b_inv(1,2)
        e_Almansi(2,3) = -0.5_wp * b_inv(2,3)
        e_Almansi(1,3) = -0.5_wp * b_inv(1,3)
        e_Almansi(2,1) = e_Almansi(1,2); e_Almansi(3,2) = e_Almansi(2,3); e_Almansi(3,1) = e_Almansi(1,3)
        
        ! Voigt notation
        E_voigt(1) = e_Almansi(1,1); E_voigt(2) = e_Almansi(2,2); E_voigt(3) = e_Almansi(3,3)
        E_voigt(4) = e_Almansi(1,2); E_voigt(5) = e_Almansi(2,3); E_voigt(6) = e_Almansi(1,3)
        
        ! Call Mat constitutive (UL mode)
        ss_gp%strain = E_voigt; ss_gp%strain_inc = E_voigt
        CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
        IF (mat_status%status_code /= 0) THEN
          status%code = IF_STATUS_ERROR

          RETURN
        END IF
        
        ! Extract Cauchy stress
        sigma(1,1) = ss_gp%sigma(1); sigma(2,2) = ss_gp%sigma(2); sigma(3,3) = ss_gp%sigma(3)
        sigma(1,2) = ss_gp%sigma(4); sigma(2,3) = ss_gp%sigma(5); sigma(1,3) = ss_gp%sigma(6)
        sigma(2,1) = sigma(1,2); sigma(3,2) = sigma(2,3); sigma(3,1) = sigma(1,3)
        
        CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
        IF (status%code /= STATUS_SUCCESS) RETURN
        
        Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp8(igp)
        Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp8(igp)
        R_int = R_int + R_gp * det_J * wt_gp8(igp)
      ELSE
        CALL PH_Elem_C3D20_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
        CALL PH_Elem_C3D20_Jac(dN_dxi, coords_prev, J_prev, det_J)
        IF (ABS(det_J) <= 1.0e-12_wp) CYCLE
        CALL PH_ELEM_C3D20_Inv3x3(J_prev, J_inv, det_J)
        
        DO i = 1, 20
          cfg%dN_dx(i,:) = MATMUL(J_inv, dN_dxi(:,i))
        END DO
        
        ! Compute 3D deformation gradient F = ?x/?X_prev (STANDARD)
        F = ZERO
        DO i = 1, 20
          DO j = 1, 3
            F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%dN_dx(i, 1)
            F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%dN_dx(i, 2)
            F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%dN_dx(i, 3)
          END DO
        END DO
        
        ! Left Cauchy-Green tensor b = F*F^T
        b(1,1) = F(1,1)*F(1,1) + F(1,2)*F(1,2) + F(1,3)*F(1,3)
        b(2,2) = F(2,1)*F(2,1) + F(2,2)*F(2,2) + F(2,3)*F(2,3)
        b(3,3) = F(3,1)*F(3,1) + F(3,2)*F(3,2) + F(3,3)*F(3,3)
        b(1,2) = F(1,1)*F(2,1) + F(1,2)*F(2,2) + F(1,3)*F(2,3)
        b(2,3) = F(2,1)*F(3,1) + F(2,2)*F(3,2) + F(2,3)*F(3,3)
        b(1,3) = F(1,1)*F(3,1) + F(1,2)*F(3,2) + F(1,3)*F(3,3)
        b(2,1) = b(1,2); b(3,2) = b(2,3); b(3,1) = b(1,3)
        
        ! Compute b^{-1}
        det_b = b(1,1)*(b(2,2)*b(3,3) - b(2,3)*b(3,2)) - b(1,2)*(b(2,1)*b(3,3) - b(2,3)*b(3,1)) + b(1,3)*(b(2,1)*b(3,2) - b(2,2)*b(3,1))
        IF (ABS(det_b) <= 1.0e-14_wp) CYCLE
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
        e_Almansi(1,2) = -0.5_wp * b_inv(1,2)
        e_Almansi(2,3) = -0.5_wp * b_inv(2,3)
        e_Almansi(1,3) = -0.5_wp * b_inv(1,3)
        e_Almansi(2,1) = e_Almansi(1,2); e_Almansi(3,2) = e_Almansi(2,3); e_Almansi(3,1) = e_Almansi(1,3)
        
        ! Voigt notation
        E_voigt(1) = e_Almansi(1,1); E_voigt(2) = e_Almansi(2,2); E_voigt(3) = e_Almansi(3,3)
        E_voigt(4) = e_Almansi(1,2); E_voigt(5) = e_Almansi(2,3); E_voigt(6) = e_Almansi(1,3)
        
        ! Call Mat constitutive (UL mode)
        ss_gp%strain = E_voigt; ss_gp%strain_inc = E_voigt
        CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
        IF (mat_status%status_code /= 0) THEN
          status%code = IF_STATUS_ERROR

          RETURN
        END IF
        
        ! Extract Cauchy stress
        sigma(1,1) = ss_gp%sigma(1); sigma(2,2) = ss_gp%sigma(2); sigma(3,3) = ss_gp%sigma(3)
        sigma(1,2) = ss_gp%sigma(4); sigma(2,3) = ss_gp%sigma(5); sigma(1,3) = ss_gp%sigma(6)
        sigma(2,1) = sigma(1,2); sigma(3,2) = sigma(2,3); sigma(3,1) = sigma(1,3)
        
        CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
        IF (status%code /= STATUS_SUCCESS) RETURN
        
        Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
        Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
        R_int = R_int + R_gp * det_J * wt_gp(igp)
      END IF
    END DO

  END SUBROUTINE PH_Elem_C3D20_NL_UL

  ! Generic interface: scalar (xi,eta,zeta,N,dNdxi) and structured (in,out)
  INTERFACE PH_Elem_C3D20_ShapeFunc
    MODULE PROCEDURE PH_Elem_C3D20_ShapeFunc_Scalar
    MODULE PROCEDURE PH_Elem_C3D20_ShapeFunc_Struct
  END INTERFACE PH_Elem_C3D20_ShapeFunc

  ! Scalar wrapper for Sect/Cont/Loads/Out (calls structured interface)
  SUBROUTINE PH_Elem_C3D20_ShapeFunc_Scalar(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(20)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 20)
    TYPE(PH_Elem_C3D20_ShapeFunc_Arg) :: arg
    arg%algo%xi = xi
    arg%algo%eta = eta
    arg%algo%zeta = zeta
    CALL PH_Elem_C3D20_ShapeFunc_Struct(arg)
    N = arg%state%N
    dNdxi = arg%state%dNdxi
  END SUBROUTINE PH_Elem_C3D20_ShapeFunc_Scalar

  SUBROUTINE PH_Elem_C3D20_ShapeFunc_Struct(arg)
    TYPE(PH_Elem_C3D20_ShapeFunc_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: xi, eta, zeta
    REAL(wp) :: N(20), dNdxi(3, 20)

    REAL(wp) :: xi_p(8), eta_p(8), zeta_p(8)
    REAL(wp) :: s, t, u, ds, dt, du, sum_lin
    INTEGER(i4) :: i

    CALL init_error_status(arg%status)
    
    xi = arg%algo%xi
    eta = arg%algo%eta
    zeta = arg%algo%zeta

    ! Corner node natural coordinates (bottom 1-4, top 5-8)
    xi_p(1:8)   = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
    eta_p(1:8)  = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
    zeta_p(1:8) = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]

    ! Corners 1..8
    DO i = 1, 8
      s = ONE + xi_p(i)*xi
      t = ONE + eta_p(i)*eta
      u = ONE + zeta_p(i)*zeta
      sum_lin = xi_p(i)*xi + eta_p(i)*eta + zeta_p(i)*zeta - 2.0_wp
      N(i) = 0.125_wp * s * t * u * sum_lin
      ds = xi_p(i)
      dt = eta_p(i)
      du = zeta_p(i)
      dNdxi(1, i) = 0.125_wp * (ds*t*u*sum_lin + s*t*u*xi_p(i))
      dNdxi(2, i) = 0.125_wp * (s*dt*u*sum_lin + s*t*u*eta_p(i))
      dNdxi(3, i) = 0.125_wp * (s*t*du*sum_lin + s*t*u*zeta_p(i))
    END DO
    ! Edge midpoints: 9(1-2),10(2-3),11(3-4),12(4-1), 13(1-5),14(2-6),15(3-7),16(4-8), 17(5-6),18(6-7),19(7-8),20(8-5)
    N(9)  = QUARTER * (ONE - xi*xi) * (ONE - eta) * (ONE - zeta)
    N(10) = QUARTER * (ONE + xi) * (ONE - eta*eta) * (ONE - zeta)
    N(11) = QUARTER * (ONE - xi*xi) * (ONE + eta) * (ONE - zeta)
    N(12) = QUARTER * (ONE - xi) * (ONE - eta*eta) * (ONE - zeta)
    N(13) = QUARTER * (ONE - xi) * (ONE - eta) * (ONE - zeta*zeta)
    N(14) = QUARTER * (ONE + xi) * (ONE - eta) * (ONE - zeta*zeta)
    N(15) = QUARTER * (ONE + xi) * (ONE + eta) * (ONE - zeta*zeta)
    N(16) = QUARTER * (ONE - xi) * (ONE + eta) * (ONE - zeta*zeta)
    N(17) = QUARTER * (ONE - xi*xi) * (ONE - eta) * (ONE + zeta)
    N(18) = QUARTER * (ONE + xi) * (ONE - eta*eta) * (ONE + zeta)
    N(19) = QUARTER * (ONE - xi*xi) * (ONE + eta) * (ONE + zeta)
    N(20) = QUARTER * (ONE - xi) * (ONE - eta*eta) * (ONE + zeta)
    dNdxi(1, 9)  = -HALF*xi * (ONE-eta)*(ONE-zeta)
    dNdxi(2, 9)  = -QUARTER*(ONE-xi*xi)*(ONE-zeta)
    dNdxi(3, 9)  = -QUARTER*(ONE-xi*xi)*(ONE-eta)
    dNdxi(1, 10) =  QUARTER*(ONE-eta*eta)*(ONE-zeta)
    dNdxi(2, 10) = -HALF*eta*(ONE+xi)*(ONE-zeta)
    dNdxi(3, 10) = -QUARTER*(ONE+xi)*(ONE-eta*eta)
    dNdxi(1, 11) = -HALF*xi*(ONE+eta)*(ONE-zeta)
    dNdxi(2, 11) =  QUARTER*(ONE-xi*xi)*(ONE-zeta)
    dNdxi(3, 11) = -QUARTER*(ONE-xi*xi)*(ONE+eta)
    dNdxi(1, 12) = -QUARTER*(ONE-eta*eta)*(ONE-zeta)
    dNdxi(2, 12) = -HALF*eta*(ONE-xi)*(ONE-zeta)
    dNdxi(3, 12) = -QUARTER*(ONE-xi)*(ONE-eta*eta)
    dNdxi(1, 13) = -QUARTER*(ONE-eta)*(ONE-zeta*zeta)
    dNdxi(2, 13) = -QUARTER*(ONE-xi)*(ONE-zeta*zeta)
    dNdxi(3, 13) = -HALF*zeta*(ONE-xi)*(ONE-eta)
    dNdxi(1, 14) =  QUARTER*(ONE-eta)*(ONE-zeta*zeta)
    dNdxi(2, 14) = -QUARTER*(ONE+xi)*(ONE-zeta*zeta)
    dNdxi(3, 14) = -HALF*zeta*(ONE+xi)*(ONE-eta)
    dNdxi(1, 15) =  QUARTER*(ONE+eta)*(ONE-zeta*zeta)
    dNdxi(2, 15) =  QUARTER*(ONE+xi)*(ONE-zeta*zeta)
    dNdxi(3, 15) = -HALF*zeta*(ONE+xi)*(ONE+eta)
    dNdxi(1, 16) = -QUARTER*(ONE+eta)*(ONE-zeta*zeta)
    dNdxi(2, 16) =  QUARTER*(ONE-xi)*(ONE-zeta*zeta)
    dNdxi(3, 16) = -HALF*zeta*(ONE-xi)*(ONE+eta)
    dNdxi(1, 17) = -HALF*xi*(ONE-eta)*(ONE+zeta)
    dNdxi(2, 17) = -QUARTER*(ONE-xi*xi)*(ONE+zeta)
    dNdxi(3, 17) =  QUARTER*(ONE-xi*xi)*(ONE-eta)
    dNdxi(1, 18) =  QUARTER*(ONE-eta*eta)*(ONE+zeta)
    dNdxi(2, 18) = -HALF*eta*(ONE+xi)*(ONE+zeta)
    dNdxi(3, 18) =  QUARTER*(ONE+xi)*(ONE-eta*eta)
    dNdxi(1, 19) = -HALF*xi*(ONE+eta)*(ONE+zeta)
    dNdxi(2, 19) =  QUARTER*(ONE-xi*xi)*(ONE+zeta)
    dNdxi(3, 19) =  QUARTER*(ONE-xi*xi)*(ONE+eta)
    dNdxi(1, 20) = -QUARTER*(ONE-eta*eta)*(ONE+zeta)
    dNdxi(2, 20) = -HALF*eta*(ONE-xi)*(ONE+zeta)
    dNdxi(3, 20) =  QUARTER*(ONE-xi)*(ONE-eta*eta)
    
    arg%state%N = N
    arg%state%dNdxi = dNdxi
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D20_ShapeFunc_Struct

  SUBROUTINE PH_Elem_C3D20_StiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(60, 60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: BTD(60, 6), dV
    INTEGER(i4) :: ip

    Ke = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      ! Ke += B^T D B * dV
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D20_StiffMatrix

  !> Stiffness from caller-supplied 6x6 tangent (e.g. C_tan from material slot).
  SUBROUTINE PH_Elem_C3D20_StiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(60, 60)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: BTD(60, 6), dV
    INTEGER(i4) :: ip

    Ke = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D6)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D20_StiffMatrixFromD

  SUBROUTINE PH_Elem_C3D20_StiffMatrix27(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60), D(6, 6)
    REAL(wp) :: BTD(60, 6), dV
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D20_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D20_StiffMatrix27

  SUBROUTINE PH_Elem_C3D20_Strain(arg)
    TYPE(PH_Elem_C3D20_Strain_Arg), INTENT(INOUT) :: arg
    
    CALL init_error_status(arg%status)
    
    arg%state%strain = MATMUL(arg%state%B, arg%state%u)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D20_Strain

  SUBROUTINE PH_Elem_C3D20_Stress(arg)
    TYPE(PH_Elem_C3D20_Stress_Arg), INTENT(INOUT) :: arg
    
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    
    CALL init_error_status(arg%status)

    IF (.NOT. ALLOCATED(arg%state%mat_state)) THEN
      ALLOCATE(arg%state%mat_state(1))
    END IF

    ! Prepare strain for material evaluation (3D)
    ss_gp%strain(1:6) = arg%state%epsilon
    ss_gp%strain_inc = ss_gp%strain
    ss_gp%sigma = ZERO
    ss_gp%tangent = ZERO
    
    ! Call material constitutive model
    CALL PH_UpdateStress(arg%desc%mat_prop, arg%state%mat_state(1), ss_gp, mat_status)
    IF (mat_status%status_code /= IF_STATUS_OK) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "C3D20 Stress: Material constitutive failed"
      RETURN
    END IF
    
    ! Extract stress components (3D)
    arg%state%sigma = ss_gp%sigma(1:6)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D20_Stress

  SUBROUTINE PH_Elem_C3D20_Volume27(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D20_Volume27

  ! ---- Sect ----
  SUBROUTINE PH_Elem_C3D20_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 20
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
      centroid(3) = centroid(3) / volume
    END IF
  END SUBROUTINE PH_Elem_C3D20_GetCentroid

  SUBROUTINE PH_Elem_C3D20_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x(1) = ZERO
      x(2) = ZERO
      x(3) = ZERO
      DO k = 1, 20
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
  END SUBROUTINE PH_Elem_C3D20_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D20_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_C3D20_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D20_GetSectProps

  SUBROUTINE PH_Elem_C3D20_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D20_GetVolume

  ! ---- Constraints ----
  SUBROUTINE PH_Elem_C3D20_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(60, 60)
    REAL(wp), INTENT(INOUT) :: F_el(60)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 60) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D20_ApplyConstraint

  SUBROUTINE PH_Elem_C3D20_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(60)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(60, 60)
    REAL(wp), INTENT(INOUT) :: F_el(60)
    INTEGER(i4) :: i, j
    DO i = 1, 60
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 60
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_ApplyMPC

  ! ---- Cont ----
  SUBROUTINE PH_Elem_C3D20_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(20)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(60, 60)
    REAL(wp), INTENT(INOUT) :: F_el(60)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 20
      ia = 3 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * n(1)
      f_a(2) = penalty * gap * N(a) * n(2)
      f_a(3) = penalty * gap * N(a) * n(3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 20
      DO b = 1, 20
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
  END SUBROUTINE PH_Elem_C3D20_FormContactContrib

  SUBROUTINE PH_Elem_C3D20_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(60, 60)
    REAL(wp), INTENT(INOUT) :: F_el(60)
    REAL(wp) :: xi, eta, zeta, N(20), n(3), dNdxi(3, 20)
    REAL(wp) :: r(3), dr_dxi(3), dr_deta(3)
    INTEGER(i4) :: nodes(4), i
    SELECT CASE (face_id)
    CASE (1)
      xi = 0.0_wp
      eta = 0.0_wp
      zeta = -ONE
      nodes(1) = 1
      nodes(2) = 2
      nodes(3) = 3
      nodes(4) = 4
    CASE (2)
      xi = 0.0_wp
      eta = 0.0_wp
      zeta = ONE
      nodes(1) = 5
      nodes(2) = 8
      nodes(3) = 7
      nodes(4) = 6
    CASE (3)
      xi = 0.0_wp
      eta = -ONE
      zeta = 0.0_wp
      nodes(1) = 1
      nodes(2) = 2
      nodes(3) = 6
      nodes(4) = 5
    CASE (4)
      xi = 0.0_wp
      eta = ONE
      zeta = 0.0_wp
      nodes(1) = 4
      nodes(2) = 3
      nodes(3) = 7
      nodes(4) = 8
    CASE (5)
      xi = -ONE
      eta = 0.0_wp
      zeta = 0.0_wp
      nodes(1) = 1
      nodes(2) = 4
      nodes(3) = 8
      nodes(4) = 5
    CASE (6)
      xi = ONE
      eta = 0.0_wp
      zeta = 0.0_wp
      nodes(1) = 2
      nodes(2) = 6
      nodes(3) = 7
      nodes(4) = 3
    CASE DEFAULT
      RETURN
    END SELECT
    CALL PH_Elem_C3D20_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r(1) = ZERO
    r(2) = ZERO
    r(3) = ZERO
    dr_dxi(1) = ZERO
    dr_dxi(2) = ZERO
    dr_dxi(3) = ZERO
    dr_deta(1) = ZERO
    dr_deta(2) = ZERO
    dr_deta(3) = ZERO
    IF (face_id <= 2) THEN
      DO i = 1, 4
        r(1) = r(1) + N(nodes(i)) * coords(1, nodes(i))
        r(2) = r(2) + N(nodes(i)) * coords(2, nodes(i))
        r(3) = r(3) + N(nodes(i)) * coords(3, nodes(i))
        dr_dxi(1) = dr_dxi(1) + dNdxi(1, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(1, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(1, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(2, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(2, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(2, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 1) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    ELSE IF (face_id <= 4) THEN
      DO i = 1, 4
        dr_dxi(1) = dr_dxi(1) + dNdxi(1, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(1, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(1, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(3, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(3, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(3, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 3) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    ELSE
      DO i = 1, 4
        dr_dxi(1) = dr_dxi(1) + dNdxi(2, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(2, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(2, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(3, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(3, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(3, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 5) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    END IF
    IF (SUM(n**2) > 1.0e-20_wp) THEN
      r(1) = SQRT(SUM(n**2))
      n(1) = n(1) / r(1)
      n(2) = n(2) / r(1)
      n(3) = n(3) / r(1)
    END IF
    CALL PH_Elem_C3D20_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D20_FormContactFaceCtr

  ! ---- Loads ----
  SUBROUTINE PH_Elem_C3D20_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(60)
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: r(3), dr_dxi(3), dr_deta(3), nvec(3), dA
    REAL(wp) :: xi_f(4), eta_f(4), w_f(4)
    INTEGER(i4) :: ip, i, nodes(4)
    REAL(wp) :: u, v, xi, et, zet
    F_eq = ZERO
    xi_f(1) = -PH_ELEM_GAUSS_PT
    xi_f(2) = PH_ELEM_GAUSS_PT
    xi_f(3) = -PH_ELEM_GAUSS_PT
    xi_f(4) = PH_ELEM_GAUSS_PT
    eta_f(1) = -PH_ELEM_GAUSS_PT
    eta_f(2) = -PH_ELEM_GAUSS_PT
    eta_f(3) = PH_ELEM_GAUSS_PT
    eta_f(4) = PH_ELEM_GAUSS_PT
    w_f(1) = ONE
    w_f(2) = ONE
    w_f(3) = ONE
    w_f(4) = ONE
    SELECT CASE (face_id)
    CASE (1)
      nodes = [1, 2, 3, 4]
      zet = -ONE
      DO ip = 1, 4
        u = xi_f(ip)
        v = eta_f(ip)
        xi = u
        et = v
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        r = ZERO
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          r = r + N(nodes(i)) * coords(:, nodes(i))
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(nvec(1)**2 + nvec(2)**2 + nvec(3)**2)
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (2)
      nodes = [5, 8, 7, 6]
      zet = ONE
      DO ip = 1, 4
        u = xi_f(ip)
        v = eta_f(ip)
        xi = u
        et = v
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        r = ZERO
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          r = r + N(nodes(i)) * coords(:, nodes(i))
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(nvec(1)**2 + nvec(2)**2 + nvec(3)**2)
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (3)
      nodes = [1, 2, 6, 5]
      et = -ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (4)
      nodes = [4, 3, 7, 8]
      et = ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (5)
      nodes = [1, 4, 8, 5]
      xi = -ONE
      DO ip = 1, 4
        et = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (6)
      nodes = [2, 6, 7, 3]
      xi = ONE
      DO ip = 1, 4
        et = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE DEFAULT
    END SELECT
  END SUBROUTINE PH_Elem_C3D20_FormFacePressure

  SUBROUTINE PH_Elem_C3D20_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(60)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 20
        F_eq(3*(i-1)+1) = F_eq(3*(i-1)+1) + N(i) * bx * detJ * weights(ip)
        F_eq(3*(i-1)+2) = F_eq(3*(i-1)+2) + N(i) * by * detJ * weights(ip)
        F_eq(3*(i-1)+3) = F_eq(3*(i-1)+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_FormBodyForce

  SUBROUTINE PH_Elem_C3D20_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(60)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D20_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D20_FormFacePressure(coords, val(1), face_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D20_FormNodalForce

  ! ---- Out ----
  SUBROUTINE invert_20x20(A, Ainv, info)
    REAL(wp), INTENT(IN)  :: A(20, 20)
    REAL(wp), INTENT(OUT) :: Ainv(20, 20)
    INTEGER(i4), INTENT(OUT) :: info
    REAL(wp) :: B(20, 20)
    INTEGER(i4) :: i, k
    REAL(wp) :: fac
    B = A
    Ainv = ZERO
    DO i = 1, 20
      Ainv(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 20
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, 1:20) = B(k, 1:20) * fac
      Ainv(k, 1:20) = Ainv(k, 1:20) * fac
      DO i = 1, 20
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, 1:20) = B(i, 1:20) - fac * B(k, 1:20)
        Ainv(i, 1:20) = Ainv(i, 1:20) - fac * Ainv(k, 1:20)
      END DO
    END DO
  END SUBROUTINE invert_20x20

  SUBROUTINE PH_Elem_C3D20_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_C3D20_EvalPrincStress

  SUBROUTINE PH_Elem_C3D20_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e
    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (edev(1)*edev(1) + edev(2)*edev(2) + edev(3)*edev(3)) &
          + edev(4)*edev(4) + edev(5)*edev(5) + edev(6)*edev(6)
  END SUBROUTINE PH_Elem_C3D20_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D20_EvalStressInvar(sigma, I1, J2, J3)
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
  END SUBROUTINE PH_Elem_C3D20_EvalStressInvar

  SUBROUTINE PH_Elem_C3D20_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax
    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D20_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    IF (seq > 1.0e-20_wp) THEN
      triax = p / seq
    ELSE
      triax = ZERO
    END IF
  END SUBROUTINE PH_Elem_C3D20_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D20_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 13
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 27)
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
  END SUBROUTINE PH_Elem_C3D20_CollectIPVars

  SUBROUTINE PH_Elem_C3D20_EvalVonMises(sigma, seq)
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
  END SUBROUTINE PH_Elem_C3D20_EvalVonMises

  SUBROUTINE PH_Elem_C3D20_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(20, 27)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: A(27, 20), ATA(20, 20), ATA_inv(20, 20)
    INTEGER(i4) :: ip, i, j
    INTEGER(i4) :: info
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    A = ZERO
    DO ip = 1, 27
      CALL PH_Elem_C3D20_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      DO i = 1, 20
        A(ip, i) = N(i)
      END DO
    END DO
    ATA = MATMUL(TRANSPOSE(A), A)
    CALL invert_20x20(ATA, ATA_inv, info)
    IF (info /= 0) THEN
      E = ZERO
      RETURN
    END IF
    E = MATMUL(ATA_inv, TRANSPOSE(A))
  END SUBROUTINE PH_Elem_C3D20_GetExtrapMat

  SUBROUTINE PH_Elem_C3D20_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(20, 27)
    INTEGER(i4) :: ic, i, j
    INTEGER(i4) :: n_comp
    node_vars = ZERO
    CALL PH_Elem_C3D20_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 20
        DO j = 1, 27
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20_MapToNode

  SUBROUTINE PH_Elem_C3D20_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_C3D20_Material_Update_Routed
END MODULE PH_Elem_C3D20


