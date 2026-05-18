!===============================================================================
! MODULE: PH_Elem_SPRING2
! LAYER:  L4_PH
! DOMAIN: Element/Spring
! ROLE:   Proc
! BRIEF:  SPRING2 - 2-node 2D spring; merged Defn+Sect+Constraints+Cont+Loads+Out
!===============================================================================
MODULE PH_Elem_SPRING2
!> [CORE] SPRING2 2-node 2D spring (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, init_error_status, IF_STATUS_INVALID
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_SPRING2_NNODE  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_SPRING2_NIP   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_SPRING2_NDOF  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_SPRING2_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: PH_Elem_SPRING2_DefInit
  PUBLIC :: PH_Elem_SPRING2_FormStiffMatrix
  PUBLIC :: PH_Elem_SPRING2_FormIntForce
  PUBLIC :: PH_Elem_SPRING2_NL_TL
  PUBLIC :: PH_Elem_SPRING2_NL_UL
  PUBLIC :: PH_Elem_SPRING2_ConsMass
  PUBLIC :: PH_Elem_SPRING2_LumpMass
  PUBLIC :: PH_Elem_SPRING2_ThermStrainVector
  PUBLIC :: UF_Elem_SPRING2_Calc
  PUBLIC :: PH_Elem_SPRING2_GetArea
  PUBLIC :: PH_Elem_SPRING2_GetSectProps
  PUBLIC :: PH_Elem_SPRING2_GetCentroid
  PUBLIC :: PH_Elem_SPRING2_ApplyConstraint
  PUBLIC :: PH_Elem_SPRING2_ApplyMPC
  PUBLIC :: PH_Elem_SPRING2_FormContactContrib
  PUBLIC :: PH_Elem_SPRING2_FormContactEdgeCtr
  PUBLIC :: PH_Elem_SPRING2_FormNodalForce
  PUBLIC :: PH_Elem_SPRING2_FormBodyForce
  PUBLIC :: PH_Elem_SPRING2_CollectIPVars
  PUBLIC :: PH_Elem_SPRING2_MapToNode
  PUBLIC :: PH_Elem_SPRING2_GetExtrapMat
  PUBLIC :: PH_Elem_SPRING2_EvalVonMises
  PUBLIC :: PH_Elem_SPRING2_Material_Update_Routed
  PUBLIC :: PH_ELEM_SPRING2_NNODE, PH_ELEM_SPRING2_NIP, PH_ELEM_SPRING2_NDOF, PH_ELEM_SPRING2_NEDGE

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Spring_Args
  TYPE :: PH_Elem_Spring_Args
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
  END TYPE PH_Elem_Spring_Args


CONTAINS

  !=============================================================================
  ! DEFINITION
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(4, 4)
    REAL(wp) :: k
    INTEGER(i4) :: i
    k = E_young
    Ke = ZERO
    DO i = 1, 2
      Ke(i, i) =  k
      Ke(i, 2+i) = -k
      Ke(2+i, i) = -k
      Ke(2+i, 2+i) = k
    END DO
  END SUBROUTINE PH_Elem_SPRING2_FormStiffMatrix

  SUBROUTINE PH_Elem_SPRING2_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_SPRING2_ThermStrainVector

  SUBROUTINE PH_Elem_SPRING2_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(4, 4)
    Me = ZERO
  END SUBROUTINE PH_Elem_SPRING2_ConsMass

  SUBROUTINE PH_Elem_SPRING2_DefInit()
  END SUBROUTINE PH_Elem_SPRING2_DefInit

  SUBROUTINE PH_Elem_SPRING2_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: u(4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(4)
    REAL(wp) :: k, f1, f2
    k = E_young
    f1 = k * (u(3) - u(1))
    f2 = k * (u(4) - u(2))
    R_int(1) = -f1
    R_int(2) = -f2
    R_int(3) =  f1
    R_int(4) =  f2
  END SUBROUTINE PH_Elem_SPRING2_FormIntForce

  SUBROUTINE PH_Elem_SPRING2_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(4)
    M_lumped = ZERO
  END SUBROUTINE PH_Elem_SPRING2_LumpMass

  SUBROUTINE PH_Elem_SPRING2_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 2)
    REAL(wp), INTENT(IN)  :: u_elem(4)
    REAL(wp), INTENT(IN)  :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k
    k = D(1, 1)
    Ke_geo = ZERO
    CALL PH_Elem_SPRING2_FormStiffMatrix(coords_ref, k, ZERO, Ke_mat)
    CALL PH_Elem_SPRING2_FormIntForce(coords_ref, u_elem, k, ZERO, R_int)
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_SPRING2_NL_TL

  SUBROUTINE PH_Elem_SPRING2_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 2)
    REAL(wp), INTENT(IN)  :: u_incr(4)
    REAL(wp), INTENT(IN)  :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k
    k = D(1, 1)
    Ke_geo = ZERO
    CALL PH_Elem_SPRING2_FormStiffMatrix(coords_prev, k, ZERO, Ke_mat)
    CALL PH_Elem_SPRING2_FormIntForce(coords_prev, u_incr, k, ZERO, R_int)
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_SPRING2_NL_UL

  SUBROUTINE UF_Elem_SPRING2_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: K_spring
    REAL(wp) :: u_rel(2)
    REAL(wp) :: Ke_loc(4,4), Re_loc(4)
    REAL(wp) :: u(2,2)
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
        message='UF_Elem_SPRING2_Calc: expected 2 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract Mat parameters
    K_spring = 1.0e10_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 1) THEN
        K_spring = Mat%props(1)
      END IF
    END IF

    ! Extract displacements
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 2) THEN
        u(1:2, 1:2) = Ctx%disp_total(1:2, 1:2)
      END IF
    END IF

    ! Relative displacement
    DO i = 1, nDim
      u_rel(i) = u(i, 2) - u(i, 1)
    END DO

    ! Build stiffness matrix (2D spring)
    Ke_loc = 0.0_wp
    DO i = 1, nDim
      Ke_loc(i, i) = K_spring
      Ke_loc(i, nDim + i) = -K_spring
      Ke_loc(nDim + i, i) = -K_spring
      Ke_loc(nDim + i, nDim + i) = K_spring
    END DO

    ! Residual force
    Re_loc = 0.0_wp
    DO i = 1, nDim
      Re_loc(i) = -K_spring * u_rel(i)
      Re_loc(nDim + i) = K_spring * u_rel(i)
    END DO

    ! Store results
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    state_out%Me = 0.0_wp
    state_out%Ce = 0.0_wp

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  END SUBROUTINE UF_Elem_SPRING2_Calc

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: dx, dy, dz
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    dz = coords(3, 2) - coords(3, 1)
    area = SQRT(dx*dx + dy*dy + dz*dz)
    IF (area < 1.0e-30_wp) area = 1.0_wp
  END SUBROUTINE PH_Elem_SPRING2_GetArea

  SUBROUTINE PH_Elem_SPRING2_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(OUT) :: centroid(3)
    INTEGER(i4) :: i
    DO i = 1, 3
      centroid(i) = (coords(i, 1) + coords(i, 2)) * HALF
    END DO
  END SUBROUTINE PH_Elem_SPRING2_GetCentroid

  SUBROUTINE PH_Elem_SPRING2_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_SPRING2_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_SPRING2_GetSectProps

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_SPRING2_ApplyConstraint

  SUBROUTINE PH_Elem_SPRING2_ApplyMPC(c, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_SPRING2_ApplyMPC

  !=============================================================================
  ! CONTACT
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
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
  END SUBROUTINE PH_Elem_SPRING2_FormContactContrib

  SUBROUTINE PH_Elem_SPRING2_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(4, 4)
    REAL(wp), INTENT(OUT) :: F_el(4)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_SPRING2_FormContactEdgeCtr

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
    F_eq(1) = bx
    F_eq(2) = by
    F_eq(3) = bx
    F_eq(4) = by
  END SUBROUTINE PH_Elem_SPRING2_FormBodyForce

  SUBROUTINE PH_Elem_SPRING2_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 2)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 4) THEN
      F_eq(1) = val(1)
      F_eq(2) = val(2)
      F_eq(3) = val(3)
      F_eq(4) = val(4)
    END IF
  END SUBROUTINE PH_Elem_SPRING2_FormNodalForce

  !=============================================================================
  ! OUTPUT
  !=============================================================================
  SUBROUTINE PH_Elem_SPRING2_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
    IF (n_ip >= 1 .AND. SIZE(out_vars, 2) >= 1) THEN
      IF (SIZE(ip_stress, 1) >= 2) out_vars(1:2, 1) = ip_stress(1:2, 1)
      IF (SIZE(ip_strain, 1) >= 2) out_vars(3:4, 1) = ip_strain(1:2, 1)
    END IF
  END SUBROUTINE PH_Elem_SPRING2_CollectIPVars

  SUBROUTINE PH_Elem_SPRING2_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    seq = ZERO
    IF (SIZE(sigma) >= 2) seq = SQRT(sigma(1)*sigma(1) + sigma(2)*sigma(2))
  END SUBROUTINE PH_Elem_SPRING2_EvalVonMises

  SUBROUTINE PH_Elem_SPRING2_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 2)
    E = ZERO
    E(1, 1) = ONE
    E(2, 2) = ONE
    E(3, 1) = ONE
    E(4, 2) = ONE
  END SUBROUTINE PH_Elem_SPRING2_GetExtrapMat

  SUBROUTINE PH_Elem_SPRING2_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
    IF (SIZE(ip_vars, 2) >= 1 .AND. SIZE(node_vars, 2) >= 2) THEN
      node_vars(1:SIZE(ip_vars, 1), 1) = ip_vars(1:SIZE(ip_vars, 1), 1)
      node_vars(1:SIZE(ip_vars, 1), 2) = ip_vars(1:SIZE(ip_vars, 1), 1)
    END IF
  END SUBROUTINE PH_Elem_SPRING2_MapToNode

  SUBROUTINE PH_Elem_SPRING2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticUniaxial

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain
    REAL(wp),                  INTENT(IN)    :: stress_old
    REAL(wp),                  INTENT(OUT)   :: stress_new
    REAL(wp),                  INTENT(OUT)   :: D_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticUniaxial(rt_ctx, mat_slot, dstrain, &
                                          stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_SPRING2_Material_Update_Routed

END MODULE PH_Elem_SPRING2

