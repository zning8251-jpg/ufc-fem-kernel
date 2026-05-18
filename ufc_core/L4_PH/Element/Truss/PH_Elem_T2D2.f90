!===============================================================================
! MODULE: PH_Elem_T2D2
! LAYER:  L4_PH
! DOMAIN: Element/Truss
! ROLE:   Proc
! BRIEF:  T2D2 2-node 2D truss element
!===============================================================================
MODULE PH_Elem_T2D2
!> [CORE] T2D2 2-node 2D truss (merged Defn+Sect+Constraints+Cont+Loads+Out)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, only: MatProperties
  USE UF_Material_Base
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_T2D2_NNODE  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T2D2_NIP   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T2D2_NDOF  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T2D2_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: PH_Elem_T2D2_DefInit
  PUBLIC :: PH_Elem_T2D2_ShapeFunc
  PUBLIC :: PH_Elem_T2D2_BMatrix
  PUBLIC :: PH_Elem_T2D2_FormStiffMatrix
  PUBLIC :: PH_Elem_T2D2_FormIntForce
  PUBLIC :: PH_Elem_T2D2_NL_TL
  PUBLIC :: PH_Elem_T2D2_NL_UL
  PUBLIC :: UF_Elem_T2D2_Calc
  PUBLIC :: PH_Elem_T2D2_GetArea
  PUBLIC :: PH_Elem_T2D2_GetLength
  PUBLIC :: PH_Elem_T2D2_GetSectProps
  PUBLIC :: PH_Elem_T2D2_GetCentroid
  PUBLIC :: PH_Elem_T2D2_ApplyConstraint
  PUBLIC :: PH_Elem_T2D2_ApplyMPC
  PUBLIC :: PH_Elem_T2D2_FormContactContrib
  PUBLIC :: PH_Elem_T2D2_FormContactEdgeCtr
  PUBLIC :: PH_Elem_T2D2_FormNodalForce
  PUBLIC :: PH_Elem_T2D2_FormBodyForce
  PUBLIC :: PH_Elem_T2D2_CollectIPVars
  PUBLIC :: PH_Elem_T2D2_MapToNode
  PUBLIC :: PH_Elem_T2D2_GetExtrapMat
  PUBLIC :: PH_Elem_T2D2_EvalAxialStress
  PUBLIC :: PH_Elem_T2D2_Material_Update_Routed
  PUBLIC :: PH_ELEM_T2D2_NNODE, PH_ELEM_T2D2_NIP, PH_ELEM_T2D2_NDOF, PH_ELEM_T2D2_NEDGE

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Truss_Args
  TYPE :: PH_Elem_Truss_Args
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
  END TYPE PH_Elem_Truss_Args


CONTAINS

  !=============================================================================
  ! DEFINITION
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_BMatrix(coords, L, e_dir, B)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: L
    REAL(wp), INTENT(OUT) :: e_dir(2)
    REAL(wp), INTENT(OUT) :: B(1, 4)
    REAL(wp) :: invL
    B = ZERO
    IF (L <= 1.0e-12_wp) RETURN
    invL = ONE / L
    e_dir(1) = (coords(1, 2) - coords(1, 1)) * invL
    e_dir(2) = (coords(2, 2) - coords(2, 1)) * invL
    B(1, 1) = -e_dir(1) * invL
    B(1, 2) = -e_dir(2) * invL
    B(1, 3) =  e_dir(1) * invL
    B(1, 4) =  e_dir(2) * invL
  END SUBROUTINE PH_Elem_T2D2_BMatrix

  SUBROUTINE PH_Elem_T2D2_DefInit()
  END SUBROUTINE PH_Elem_T2D2_DefInit

  SUBROUTINE PH_Elem_T2D2_FormIntForce(coords, u, E_young, area, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: u(4)
    REAL(wp), INTENT(IN)  :: E_young, area
    REAL(wp), INTENT(OUT) :: R_int(4)
    REAL(wp) :: L, e_dir(2), B(1, 4), strain, sigma, vol
    REAL(wp) :: dx, dy
    R_int = ZERO
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    L = SQRT(dx*dx + dy*dy)
    IF (L <= 1.0e-12_wp) RETURN
    CALL PH_Elem_T2D2_BMatrix(coords, L, e_dir, B)
    strain = MATMUL(B, u)
    sigma = E_young * strain
    vol = area * L
    R_int = MATMUL(TRANSPOSE(B), [sigma]) * vol
  END SUBROUTINE PH_Elem_T2D2_FormIntForce

  SUBROUTINE PH_Elem_T2D2_FormStiffMatrix(coords, E_young, area, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: E_young, area
    REAL(wp), INTENT(OUT) :: Ke(4, 4)
    REAL(wp) :: dx, dy, L, e_dir(2), B(1, 4), EA_L
    Ke = ZERO
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    L = SQRT(dx*dx + dy*dy)
    IF (L <= 1.0e-12_wp) RETURN
    CALL PH_Elem_T2D2_BMatrix(coords, L, e_dir, B)
    EA_L = E_young * area / L
    Ke = EA_L * MATMUL(TRANSPOSE(B), B)
  END SUBROUTINE PH_Elem_T2D2_FormStiffMatrix

  SUBROUTINE PH_Elem_T2D2_NL_TL(coords_ref, u_elem, E_young, area, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(2, 2)
    REAL(wp), INTENT(IN) :: u_elem(4)
    REAL(wp), INTENT(IN) :: E_young, area
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 2)
    REAL(wp) :: dx_ref, dy_ref, L_ref
    REAL(wp) :: dx_curr, dy_curr, L_curr
    REAL(wp) :: e_ref(2)
    REAL(wp) :: lambda, E_GL, S_PK2
    REAL(wp) :: dN_dX(2)
    REAL(wp) :: B_mat(1, 4), B_geo(2, 4)
    REAL(wp) :: D_tangent, wt
    INTEGER(i4) :: i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 2
      coords_curr(1, i) = coords_ref(1, i) + u_elem(2*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(2*(i-1)+2)
    END DO

    dx_ref = coords_ref(1, 2) - coords_ref(1, 1)
    dy_ref = coords_ref(2, 2) - coords_ref(2, 1)
    L_ref = SQRT(dx_ref*dx_ref + dy_ref*dy_ref)

    IF (L_ref <= 1.0e-12_wp) THEN
      status%code = IF_STATUS_ERROR
      status%msg = "PH_ELEM_T2D2_NL_TL: Zero reference length"
      RETURN
    END IF

    e_ref(1) = dx_ref / L_ref
    e_ref(2) = dy_ref / L_ref

    dx_curr = coords_curr(1, 2) - coords_curr(1, 1)
    dy_curr = coords_curr(2, 2) - coords_curr(2, 1)
    L_curr = SQRT(dx_curr*dx_curr + dy_curr*dy_curr)

    lambda = L_curr / L_ref
    E_GL = HALF * (lambda*lambda - ONE)
    S_PK2 = E_young * E_GL
    D_tangent = E_young

    dN_dX(1) = -ONE / L_ref
    dN_dX(2) =  ONE / L_ref

    B_mat(1, 1) = dN_dX(1) * e_ref(1)
    B_mat(1, 2) = dN_dX(1) * e_ref(2)
    B_mat(1, 3) = dN_dX(2) * e_ref(1)
    B_mat(1, 4) = dN_dX(2) * e_ref(2)

    wt = area * L_ref
    Ke_mat = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

    DO i = 1, 2
      B_geo(1, 2*(i-1)+1) = dN_dX(i)
      B_geo(1, 2*(i-1)+2) = ZERO
      B_geo(2, 2*(i-1)+1) = ZERO
      B_geo(2, 2*(i-1)+2) = dN_dX(i)
    END DO

    Ke_geo = S_PK2 * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

    R_int(1) = S_PK2 * B_mat(1, 1) * wt
    R_int(2) = S_PK2 * B_mat(1, 2) * wt
    R_int(3) = S_PK2 * B_mat(1, 3) * wt
    R_int(4) = S_PK2 * B_mat(1, 4) * wt

  END SUBROUTINE PH_Elem_T2D2_NL_TL

  SUBROUTINE PH_Elem_T2D2_NL_UL(coords_prev, u_incr, E_young, area, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(2, 2)
    REAL(wp), INTENT(IN) :: u_incr(4)
    REAL(wp), INTENT(IN) :: E_young, area
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(2, 2)
    REAL(wp) :: dx_prev, dy_prev, L_prev
    REAL(wp) :: dx_curr, dy_curr, L_curr
    REAL(wp) :: e_prev(2)
    REAL(wp) :: lambda, e_Almansi, sigma_Cauchy
    REAL(wp) :: dN_dx(2)
    REAL(wp) :: B_mat(1, 4), B_geo(2, 4)
    REAL(wp) :: D_tangent, wt
    INTEGER(i4) :: i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 2
      coords_curr(1, i) = coords_prev(1, i) + u_incr(2*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(2*(i-1)+2)
    END DO

    dx_prev = coords_prev(1, 2) - coords_prev(1, 1)
    dy_prev = coords_prev(2, 2) - coords_prev(2, 1)
    L_prev = SQRT(dx_prev*dx_prev + dy_prev*dy_prev)

    IF (L_prev <= 1.0e-12_wp) THEN
      status%code = IF_STATUS_ERROR
      status%msg = "PH_ELEM_T2D2_NL_UL: Zero previous length"
      RETURN
    END IF

    e_prev(1) = dx_prev / L_prev
    e_prev(2) = dy_prev / L_prev

    dx_curr = coords_curr(1, 2) - coords_curr(1, 1)
    dy_curr = coords_curr(2, 2) - coords_curr(2, 1)
    L_curr = SQRT(dx_curr*dx_curr + dy_curr*dy_curr)

    lambda = L_curr / L_prev
    e_Almansi = HALF * (ONE - ONE/(lambda*lambda))
    sigma_Cauchy = E_young * e_Almansi
    D_tangent = E_young

    dN_dx(1) = -ONE / L_prev
    dN_dx(2) =  ONE / L_prev

    B_mat(1, 1) = dN_dx(1) * e_prev(1)
    B_mat(1, 2) = dN_dx(1) * e_prev(2)
    B_mat(1, 3) = dN_dx(2) * e_prev(1)
    B_mat(1, 4) = dN_dx(2) * e_prev(2)

    wt = area * L_prev
    Ke_mat = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

    DO i = 1, 2
      B_geo(1, 2*(i-1)+1) = dN_dx(i)
      B_geo(1, 2*(i-1)+2) = ZERO
      B_geo(2, 2*(i-1)+1) = ZERO
      B_geo(2, 2*(i-1)+2) = dN_dx(i)
    END DO

    Ke_geo = sigma_Cauchy * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

    R_int(1) = sigma_Cauchy * B_mat(1, 1) * wt
    R_int(2) = sigma_Cauchy * B_mat(1, 2) * wt
    R_int(3) = sigma_Cauchy * B_mat(1, 3) * wt
    R_int(4) = sigma_Cauchy * B_mat(1, 4) * wt

  END SUBROUTINE PH_Elem_T2D2_NL_UL

  SUBROUTINE PH_Elem_T2D2_ShapeFunc(xi, N)
    REAL(wp), INTENT(IN)  :: xi
    REAL(wp), INTENT(OUT) :: N(2)
    N(1) = (ONE - xi) * HALF
    N(2) = (ONE + xi) * HALF
  END SUBROUTINE PH_Elem_T2D2_ShapeFunc

  SUBROUTINE UF_Elem_T2D2_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: coords(2, 2)
    REAL(wp) :: u(4)
    REAL(wp) :: x1(2), x2(2), dx(2)
    REAL(wp) :: u1(2), u2(2)
    REAL(wp) :: L0, invL0, dV, A
    REAL(wp) :: e_dir(2)
    REAL(wp), allocatable :: u_loc(:)
    REAL(wp), allocatable :: B1(:)
    REAL(wp), allocatable :: Ke_loc(:,:), Re_loc(:)
    TYPE(MatCtxLegacy)  :: material_ctxt
    TYPE(MatRes)  :: material_res
    TYPE(MatProperties) :: props
    REAL(wp) :: stress6(6)
    REAL(wp) :: D11
    INTEGER(i4) :: i, comp, nIP_state

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    nNode = ElemType%numNodes
    IF (nNode /= 2) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_T2D2_Calc: expected 2 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    nDim = ElemType%dim
    IF (nDim < 1 .OR. nDim > 3) nDim = 2
    nDOF = nNode * nDim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_T2D2_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    coords = 0.0_wp
    DO comp = 1, MIN(2, SIZE(Ctx%coords_ref, 1))
      coords(comp, 1) = Ctx%coords_ref(comp, 1)
      coords(comp, 2) = Ctx%coords_ref(comp, 2)
    END DO

    x1 = coords(:, 1)
    x2 = coords(:, 2)
    dx = x2 - x1
    CALL PH_Elem_T2D2_GetLength(coords, L0)

    IF (L0 <= 1.0e-12_wp) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .FALSE.
      flags%stableDt = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    invL0 = ONE / L0
    e_dir = dx * invL0

    u1 = 0.0_wp
    u2 = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      DO comp = 1, MIN(2, SIZE(Ctx%disp_total, 1))
        u1(comp) = Ctx%disp_total(comp, 1)
        u2(comp) = Ctx%disp_total(comp, 2)
      END DO
    END IF

    ALLOCATE(u_loc(nDOF))
    u_loc = 0.0_wp
    u_loc(1:2) = u1
    u_loc(3:4) = u2

    ALLOCATE(B1(nDOF))
    B1 = 0.0_wp
    B1(1) = -e_dir(1) * invL0
    B1(2) = -e_dir(2) * invL0
    B1(3) =  e_dir(1) * invL0
    B1(4) =  e_dir(2) * invL0

    ALLOCATE(Ke_loc(nDOF, nDOF))
    Ke_loc = 0.0_wp
    ALLOCATE(Re_loc(nDOF))
    Re_loc = 0.0_wp

    A = 1.0_wp
    IF (ALLOCATED(Ctx%section)) THEN
      CALL PH_Elem_T2D2_GetArea(A, A)
    END IF
    dV = A * L0

    material_ctxt%kin%mech%strain = 0.0_wp
    material_ctxt%kin%mech%dStrain = 0.0_wp
    material_ctxt%kin%time%current = Ctx%currentTime
    material_ctxt%kin%time%total = Ctx%currentTime
    material_ctxt%kin%time%inc = Ctx%deltaTime
    material_ctxt%kin%cfg%id = Ctx%cfg%id
    material_ctxt%kin%ipID = 1_i4

    material_ctxt%kin%mech%strain(1) = SUM(B1(1:nDOF) * u_loc(1:nDOF))

    material_ctxt%ip_state_in%sigma = 0.0_wp
    material_ctxt%ip_state_in%strain = 0.0_wp
    material_ctxt%ip_state_in%dstran = 0.0_wp
    material_ctxt%ip_state_in%pop%nStateV = 0_i4

    IF (ALLOCATED(state_in%ipStates)) THEN
      nIP_state = SIZE(state_in%ipStates)
      IF (nIP_state >= 1) THEN
        CALL IpStateToState(state_in%ipStates(1), material_ctxt%ip_state_in, &
             material_id=Mat%cfg%id, element_id=Ctx%cfg%id, ip_id=1_i4)
      END IF
    END IF

    material_ctxt%material_id = Mat%cfg%id
    material_ctxt%element_id = Ctx%cfg%id
    material_ctxt%ip_id = 1_i4

    material_res%ip_state_out = material_ctxt%ip_state_in
    material_res%flags%failed = .FALSE.
    material_res%flags%suggest_cutback = .FALSE.
    material_res%flags%is_plastic = .FALSE.
    material_res%flags%pnewdt_factor = 1.0_wp
    material_res%D_alg = 0.0_wp

    CALL MatEval(Mat, material_ctxt, material_res)

    stress6 = 0.0_wp
    stress6(1:6) = material_res%ip_state_out%sigma(1:6)

    D11 = 0.0_wp
    IF (ANY(material_res%D_alg /= 0.0_wp)) THEN
      D11 = material_res%D_alg(1, 1)
    END IF

    props = Mat%props
    IF (D11 <= 0.0_wp) THEN
      IF (ALLOCATED(props%props)) THEN
        IF (SIZE(props%props) >= UF_MAT_PROP_ELA) THEN
          IF (props%props(UF_MAT_PROP_ELA) > 0.0_wp) D11 = props%props(UF_MAT_PROP_ELA)
        END IF
      END IF
    END IF

    DO i = 1, nDOF
      Re_loc(i) = Re_loc(i) + B1(i) * stress6(1) * dV
    END DO

    IF (D11 > 0.0_wp) THEN
      DO i = 1, nDOF
        DO comp = 1, nDOF
          Ke_loc(i, comp) = Ke_loc(i, comp) + D11 * B1(i) * B1(comp) * dV
        END DO
      END DO
    END IF

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, 1)
    IF (ALLOCATED(state_out%ipStates)) THEN
      CALL StateToIpState(material_res%ip_state_out, state_out%ipStates(1))
    END IF

    flags%failed = material_res%flags%failed
    flags%suggest_cutback = material_res%flags%suggest_cutback
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

    DEALLOCATE(u_loc, B1, Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_T2D2_Calc

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_GetArea(area_in, area)
    REAL(wp), INTENT(IN)  :: area_in
    REAL(wp), INTENT(OUT) :: area
    area = area_in
  END SUBROUTINE PH_Elem_T2D2_GetArea

  SUBROUTINE PH_Elem_T2D2_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(OUT) :: centroid(2)
    centroid(1) = (coords(1, 1) + coords(1, 2)) * HALF
    centroid(2) = (coords(2, 1) + coords(2, 2)) * HALF
  END SUBROUTINE PH_Elem_T2D2_GetCentroid

  SUBROUTINE PH_Elem_T2D2_GetLength(coords, length)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(OUT) :: length
    REAL(wp) :: dx, dy
    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    length = SQRT(dx*dx + dy*dy)
  END SUBROUTINE PH_Elem_T2D2_GetLength

  SUBROUTINE PH_Elem_T2D2_GetSectProps(coords, density_in, area_in, length, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: density_in, area_in
    REAL(wp), INTENT(OUT) :: length, mass
    CALL PH_Elem_T2D2_GetLength(coords, length)
    mass = density_in * area_in * length
  END SUBROUTINE PH_Elem_T2D2_GetSectProps

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_T2D2_ApplyConstraint

  SUBROUTINE PH_Elem_T2D2_ApplyMPC(c, val, penalty, K_el, F_el)
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
  END SUBROUTINE PH_Elem_T2D2_ApplyMPC

  !=============================================================================
  ! CONTACT
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_FormContactContrib(edge_id, xi, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi
    REAL(wp), INTENT(IN)  :: N(2)
    REAL(wp), INTENT(IN)  :: n(2)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
  END SUBROUTINE PH_Elem_T2D2_FormContactContrib

  SUBROUTINE PH_Elem_T2D2_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(4, 4)
    REAL(wp), INTENT(OUT) :: F_el(4)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_T2D2_FormContactEdgeCtr

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_FormBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(4)
    REAL(wp) :: L, N(2), xip(1), w(1)
    INTEGER(i4) :: ip
    F_eq = ZERO
    L = SQRT((coords(1,2)-coords(1,1))**2 + (coords(2,2)-coords(2,1))**2)
    IF (L <= 1.0e-12_wp) RETURN
    xip(1) = 0.0_wp
    w(1) = 2.0_wp
    DO ip = 1, 1
      CALL PH_Elem_T2D2_ShapeFunc(xip(ip), N)
      F_eq(1) = F_eq(1) + N(1) * bx * L * HALF * w(ip)
      F_eq(2) = F_eq(2) + N(1) * by * L * HALF * w(ip)
      F_eq(3) = F_eq(3) + N(2) * bx * L * HALF * w(ip)
      F_eq(4) = F_eq(4) + N(2) * by * L * HALF * w(ip)
    END DO
  END SUBROUTINE PH_Elem_T2D2_FormBodyForce

  SUBROUTINE PH_Elem_T2D2_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 2)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_T2D2_FormBodyForce(coords, val(1), val(2), F_eq)
    END IF
  END SUBROUTINE PH_Elem_T2D2_FormNodalForce

  !=============================================================================
  ! OUTPUT
  !=============================================================================
  SUBROUTINE PH_Elem_T2D2_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
    IF (n_ip >= 1 .AND. SIZE(ip_stress, 1) >= 1) out_vars(1, 1) = ip_stress(1, 1)
    IF (SIZE(ip_strain, 1) >= 1) out_vars(2, 1) = ip_strain(1, 1)
    IF (SIZE(ip_peeq) >= 1) out_vars(3, 1) = ip_peeq(1)
  END SUBROUTINE PH_Elem_T2D2_CollectIPVars

  SUBROUTINE PH_Elem_T2D2_EvalAxialStress(strain, E_young, sigma)
    REAL(wp), INTENT(IN)  :: strain
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(OUT) :: sigma
    sigma = E_young * strain
  END SUBROUTINE PH_Elem_T2D2_EvalAxialStress

  SUBROUTINE PH_Elem_T2D2_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(2, 1)
    E(1, 1) = ONE
    E(2, 1) = ONE
  END SUBROUTINE PH_Elem_T2D2_GetExtrapMat

  SUBROUTINE PH_Elem_T2D2_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
    IF (SIZE(ip_vars, 2) >= 1) THEN
      node_vars(1, 1) = ip_vars(1, 1)
      node_vars(2, 1) = ip_vars(1, 1)
    END IF
  END SUBROUTINE PH_Elem_T2D2_MapToNode

  SUBROUTINE PH_Elem_T2D2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
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
  END SUBROUTINE PH_Elem_T2D2_Material_Update_Routed

END MODULE PH_Elem_T2D2

