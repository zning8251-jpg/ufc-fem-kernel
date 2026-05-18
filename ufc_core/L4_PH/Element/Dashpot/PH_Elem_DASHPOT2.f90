!===============================================================================
! MODULE: PH_Elem_DASHPOT2
! LAYER:  L4_PH
! DOMAIN: Element/Dashpot
! ROLE:   Proc
! BRIEF:  DASHPOT2 2-node 2D dashpot element
!===============================================================================
MODULE PH_Elem_DASHPOT2
!> [CORE] DASHPOT2 2-node 2D dashpot (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, init_error_status, IF_STATUS_INVALID
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_DASHPOT2_NNODE  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DASHPOT2_NIP   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DASHPOT2_NDOF  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DASHPOT2_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: PH_Elem_DASHPOT2_DefInit
  PUBLIC :: PH_Elem_DASHPOT2_FormStiffMatrix
  PUBLIC :: PH_Elem_DASHPOT2_FormDampMatrix
  PUBLIC :: PH_Elem_DASHPOT2_FormIntForce
  PUBLIC :: PH_Elem_DASHPOT2_NL_TL
  PUBLIC :: PH_Elem_DASHPOT2_NL_UL
  PUBLIC :: PH_Elem_DASHPOT2_ConsMass
  PUBLIC :: PH_Elem_DASHPOT2_LumpMass
  PUBLIC :: PH_Elem_DASHPOT2_ThermStrainVector
  PUBLIC :: UF_Elem_DASHPOT2_Calc
  PUBLIC :: PH_Elem_DASHPOT2_GetArea
  PUBLIC :: PH_Elem_DASHPOT2_GetSectProps
  PUBLIC :: PH_Elem_DASHPOT2_GetCentroid
  PUBLIC :: PH_Elem_DASHPOT2_ApplyConstraint
  PUBLIC :: PH_Elem_DASHPOT2_ApplyMPC
  PUBLIC :: PH_Elem_DASHPOT2_FormContactContrib
  PUBLIC :: PH_Elem_DASHPOT2_FormContactEdgeCtr
  PUBLIC :: PH_Elem_DASHPOT2_FormNodalForce
  PUBLIC :: PH_Elem_DASHPOT2_FormBodyForce
  PUBLIC :: PH_Elem_DASHPOT2_CollectIPVars
  PUBLIC :: PH_Elem_DASHPOT2_MapToNode
  PUBLIC :: PH_Elem_DASHPOT2_GetExtrapMat
  PUBLIC :: PH_Elem_DASHPOT2_EvalVonMises
  PUBLIC :: PH_Elem_DASHPOT2_Material_Update_Routed
  PUBLIC :: PH_ELEM_DASHPOT2_NNODE, PH_ELEM_DASHPOT2_NIP, PH_ELEM_DASHPOT2_NDOF, PH_ELEM_DASHPOT2_NEDGE

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Dashpot_Args
  TYPE :: PH_Elem_Dashpot_Args
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
  END TYPE PH_Elem_Dashpot_Args


CONTAINS

  !=============================================================================
  ! DEFINITION
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_FormDampMatrix(coords, c_damp, Ce)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: c_damp
    REAL(wp), INTENT(OUT) :: Ce(4, 4)
    REAL(wp) :: c
    INTEGER(i4) :: i
    c = c_damp
    Ce = ZERO
    DO i = 1, 2
      Ce(i, i) =  c
      Ce(i, 2+i) = -c
      Ce(2+i, i) = -c
      Ce(2+i, 2+i) = c
    END DO
  END SUBROUTINE PH_Elem_DASHPOT2_FormDampMatrix

  SUBROUTINE PH_Elem_DASHPOT2_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(4)
    R_int = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_FormIntForce

  SUBROUTINE PH_Elem_DASHPOT2_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(4, 4)
    Ke = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_FormStiffMatrix

  SUBROUTINE PH_Elem_DASHPOT2_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_ThermStrainVector

  SUBROUTINE PH_Elem_DASHPOT2_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(4, 4)
    Me = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_ConsMass

  SUBROUTINE PH_Elem_DASHPOT2_DefInit()
  END SUBROUTINE PH_Elem_DASHPOT2_DefInit

  SUBROUTINE PH_Elem_DASHPOT2_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(4)
    M_lumped = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_LumpMass

  SUBROUTINE PH_Elem_DASHPOT2_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 2)
    REAL(wp), INTENT(IN)  :: u_elem(4)
    REAL(wp), INTENT(IN)  :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_DASHPOT2_NL_TL

  SUBROUTINE PH_Elem_DASHPOT2_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 2)
    REAL(wp), INTENT(IN)  :: u_incr(4)
    REAL(wp), INTENT(IN)  :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_DASHPOT2_NL_UL

  SUBROUTINE UF_Elem_DASHPOT2_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: C_dashpot
    REAL(wp) :: v_rel(2)
    REAL(wp) :: Ce_loc(4,4), Re_loc(4)
    INTEGER(i4) :: i

    nNode = ElemType%numNodes
    nDim = 2_i4
    nDOF = 4_i4

    IF (nNode /= 2) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_DASHPOT2_Calc: expected 2 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    C_dashpot = 0.0_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 1) THEN
        C_dashpot = Mat%props(1)
      END IF
    END IF

    v_rel = 0.0_wp
    IF (ALLOCATED(Ctx%disp_incr) .AND. Ctx%dTime > 1.0e-12_wp) THEN
      IF (SIZE(Ctx%disp_incr, 2) >= 2) THEN
        DO i = 1, nDim
          v_rel(i) = (Ctx%disp_incr(i, 2) - Ctx%disp_incr(i, 1)) / Ctx%dTime
        END DO
      END IF
    END IF

    Ce_loc = 0.0_wp
    IF (C_dashpot > 0.0_wp) THEN
      DO i = 1, nDim
        Ce_loc(i, i) = C_dashpot
        Ce_loc(i, nDim + i) = -C_dashpot
        Ce_loc(nDim + i, i) = -C_dashpot
        Ce_loc(nDim + i, nDim + i) = C_dashpot
      END DO
    END IF

    Re_loc = 0.0_wp
    DO i = 1, nDim
      Re_loc(i) = -C_dashpot * v_rel(i)
      Re_loc(nDim + i) = C_dashpot * v_rel(i)
    END DO

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke = 0.0_wp
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    state_out%Me = 0.0_wp
    state_out%Ce(1:nDOF, 1:nDOF) = Ce_loc(1:nDOF, 1:nDOF)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  END SUBROUTINE UF_Elem_DASHPOT2_Calc

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: dx, dy, dz
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    dz = coords(3, 2) - coords(3, 1)
    area = SQRT(dx*dx + dy*dy + dz*dz)
    IF (area < 1.0e-30_wp) area = 1.0_wp
  END SUBROUTINE PH_Elem_DASHPOT2_GetArea

  SUBROUTINE PH_Elem_DASHPOT2_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(OUT) :: centroid(3)
    INTEGER(i4) :: i
    DO i = 1, 3
      centroid(i) = (coords(i, 1) + coords(i, 2)) * HALF
    END DO
  END SUBROUTINE PH_Elem_DASHPOT2_GetCentroid

  SUBROUTINE PH_Elem_DASHPOT2_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_DASHPOT2_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_DASHPOT2_GetSectProps

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 4) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_DASHPOT2_ApplyConstraint

  SUBROUTINE PH_Elem_DASHPOT2_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(4)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    INTEGER(i4) :: i, j
    DO i = 1, 4
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 4
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_DASHPOT2_ApplyMPC

  !=============================================================================
  ! CONTACT
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(2)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    INTEGER(i4) :: a, b, ia, ib
    REAL(wp) :: k_ab
    DO a = 1, 2
      ia = 2 * (a - 1) + 1
      F_el(ia)   = F_el(ia)   + penalty * gap * N(a) * edge_len * n(1)
      F_el(ia+1) = F_el(ia+1) + penalty * gap * N(a) * edge_len * n(2)
    END DO
    DO a = 1, 2
      DO b = 1, 2
        k_ab = penalty * N(a) * N(b) * edge_len
        ia = 2 * (a - 1) + 1
        ib = 2 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
      END DO
    END DO
  END SUBROUTINE PH_Elem_DASHPOT2_FormContactContrib

  SUBROUTINE PH_Elem_DASHPOT2_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(4, 4)
    REAL(wp), INTENT(OUT) :: F_el(4)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_FormContactEdgeCtr

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
    F_eq(1) = bx
    F_eq(2) = by
    F_eq(3) = bx
    F_eq(4) = by
  END SUBROUTINE PH_Elem_DASHPOT2_FormBodyForce

  SUBROUTINE PH_Elem_DASHPOT2_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 4) THEN
      F_eq(1:4) = val(1:4)
    END IF
  END SUBROUTINE PH_Elem_DASHPOT2_FormNodalForce

  !=============================================================================
  ! OUTPUT
  !=============================================================================
  SUBROUTINE PH_Elem_DASHPOT2_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_CollectIPVars

  SUBROUTINE PH_Elem_DASHPOT2_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    seq = ZERO
    IF (SIZE(sigma) >= 2) seq = SQRT(sigma(1)*sigma(1) + sigma(2)*sigma(2))
  END SUBROUTINE PH_Elem_DASHPOT2_EvalVonMises

  SUBROUTINE PH_Elem_DASHPOT2_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 2)
    E = ZERO
    E(1, 1) = ONE
    E(2, 2) = ONE
    E(3, 1) = ONE
    E(4, 2) = ONE
  END SUBROUTINE PH_Elem_DASHPOT2_GetExtrapMat

  SUBROUTINE PH_Elem_DASHPOT2_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
  END SUBROUTINE PH_Elem_DASHPOT2_MapToNode

  SUBROUTINE PH_Elem_DASHPOT2_Material_Update_Routed(rt_ctx, mat_slot, rel_velocity, &
                                                     force_new, C_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_DashpotScalar

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: rel_velocity
    REAL(wp),                  INTENT(OUT)   :: force_new
    REAL(wp),                  INTENT(OUT)   :: C_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_DashpotScalar(rt_ctx, mat_slot, rel_velocity, &
                                        force_new, C_tangent, status)
  END SUBROUTINE PH_Elem_DASHPOT2_Material_Update_Routed

END MODULE PH_Elem_DASHPOT2

