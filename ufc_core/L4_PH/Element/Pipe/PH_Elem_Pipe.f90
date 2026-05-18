!===============================================================================
! MODULE: PH_Elem_Pipe
! LAYER:  L4_PH
! DOMAIN: Element/Pipe
! ROLE:   Proc
! BRIEF:  Pipe element unified interface
!===============================================================================
MODULE PH_Elem_Pipe
!> [CORE] Pipe element unified interface (PIPE21/PIPE22)
!> Merged: Pipe_Defn + PIPE21/PIPE22 Defn/Sect/Constraints/Cont/Loads/Out
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, ONLY: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, ONLY: MatProperties
  USE UF_Material_Base
  USE PH_Elem_T3D2, ONLY: PH_Elem_T3D2_FormStiffMatrix, PH_Elem_T3D2_FormIntForce, &
    PH_Elem_T3D2_ConsMass, PH_Elem_T3D2_LumpMass, PH_Elem_T3D2_ThermStrainVector, &
    PH_Elem_T3D2_GetCentroid, PH_Elem_T3D2_GetSectProps, &
    PH_Elem_T3D2_FormBodyForce, PH_Elem_T3D2_FormNodalForce, PH_Elem_T3D2_CollectIPVars, &
    PH_Elem_T3D2_MapToNode, PH_Elem_T3D2_GetExtrapMat
  IMPLICIT NONE
  PRIVATE

  ! Parameters
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE21_NNODE  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE21_NIP   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE21_NDOF  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE21_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE22_NNODE  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE22_NIP   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE22_NDOF  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_PIPE22_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: UF_Elem_Pipe_Calc
  PUBLIC :: UF_Elem_PIPE21_Calc, UF_Elem_PIPE22_Calc
  PUBLIC :: PH_ELEM_PIPE21_NNODE, PH_ELEM_PIPE21_NIP, PH_ELEM_PIPE21_NDOF, PH_ELEM_PIPE21_NEDGE
  PUBLIC :: PH_ELEM_PIPE22_NNODE, PH_ELEM_PIPE22_NIP, PH_ELEM_PIPE22_NDOF, PH_ELEM_PIPE22_NEDGE
  PUBLIC :: PH_Elem_PIPE21_DefInit, PH_Elem_PIPE21_FormStiffMatrix, PH_Elem_PIPE21_FormIntForce
  PUBLIC :: PH_Elem_PIPE21_ConsMass, PH_Elem_PIPE21_LumpMass, PH_Elem_PIPE21_ThermStrainVector
  PUBLIC :: PH_Elem_PIPE21_NL_TL, PH_Elem_PIPE21_NL_UL
  PUBLIC :: PH_Elem_PIPE22_DefInit, PH_Elem_PIPE22_FormStiffMatrix, PH_Elem_PIPE22_FormIntForce
  PUBLIC :: PH_Elem_PIPE22_ConsMass, PH_Elem_PIPE22_LumpMass, PH_Elem_PIPE22_ThermStrainVector
  PUBLIC :: PH_Elem_PIPE22_NL_TL, PH_Elem_PIPE22_NL_UL
  PUBLIC :: PH_Elem_PIPE21_GetArea, PH_Elem_PIPE21_GetSectProps, PH_Elem_PIPE21_GetCentroid
  PUBLIC :: PH_Elem_PIPE21_ApplyConstraint, PH_Elem_PIPE21_ApplyMPC
  PUBLIC :: PH_Elem_PIPE21_FormContactContrib, PH_Elem_PIPE21_FormContactEdgeCtr
  PUBLIC :: PH_Elem_PIPE21_FormNodalForce, PH_Elem_PIPE21_FormBodyForce
  PUBLIC :: PH_Elem_PIPE21_CollectIPVars, PH_Elem_PIPE21_MapToNode
  PUBLIC :: PH_Elem_PIPE21_GetExtrapMat, PH_Elem_PIPE21_EvalVonMises, PH_Elem_PIPE21_EvalPipeStress
  PUBLIC :: PH_Elem_PIPE21_Material_Update_Routed
  PUBLIC :: PH_Elem_PIPE22_GetArea, PH_Elem_PIPE22_GetSectProps, PH_Elem_PIPE22_GetCentroid
  PUBLIC :: PH_Elem_PIPE22_ApplyConstraint, PH_Elem_PIPE22_ApplyMPC
  PUBLIC :: PH_Elem_PIPE22_FormContactContrib, PH_Elem_PIPE22_FormContactEdgeCtr
  PUBLIC :: PH_Elem_PIPE22_FormNodalForce, PH_Elem_PIPE22_FormBodyForce
  PUBLIC :: PH_Elem_PIPE22_CollectIPVars, PH_Elem_PIPE22_MapToNode
  PUBLIC :: PH_Elem_PIPE22_GetExtrapMat, PH_Elem_PIPE22_EvalVonMises, PH_Elem_PIPE22_EvalPipeStress
  PUBLIC :: PH_Elem_PIPE22_Material_Update_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Pipe_Args
  TYPE :: PH_Elem_Pipe_Args
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
  REAL(wp)              :: k_therm     = 0.0_wp  ! thermal conductivity scale
  REAL(wp)              :: rho_cp      = 0.0_wp  ! density times heat capacity
  REAL(wp), POINTER     :: T_elem(:)   => NULL()  ! element temperature vector ptr
  REAL(wp), POINTER     :: Ktherm(:,:) => NULL()  ! thermal-thermal block ptr
  REAL(wp), POINTER     :: F_heat(:)   => NULL()  ! thermal force / heat flux load ptr
  REAL(wp), POINTER     :: ip_temp(:)  => NULL()  ! IP temperature ptr
  END TYPE PH_Elem_Pipe_Args


CONTAINS

  !> Copy first two nodes into a 3x2 array; ok=.FALSE. if coords too small.
  PURE SUBROUTINE Pipe_CopyCoords12(coords, c12, ok)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(OUT) :: c12(3, 2)
    LOGICAL, INTENT(OUT) :: ok
    IF (SIZE(coords, 1) < 3 .OR. SIZE(coords, 2) < 2) THEN
      ok = .FALSE.
      RETURN
    END IF
    ok = .TRUE.
    c12(1:3, 1) = coords(1:3, 1)
    c12(1:3, 2) = coords(1:3, 2)
  END SUBROUTINE Pipe_CopyCoords12

  PURE SUBROUTINE Pipe_ResolveAreaOpt(area_opt, aout)
    REAL(wp), INTENT(IN), OPTIONAL :: area_opt
    REAL(wp), INTENT(OUT) :: aout
    aout = ONE
    IF (PRESENT(area_opt)) THEN
      IF (area_opt > 0.0_wp) aout = area_opt
    END IF
  END SUBROUTINE Pipe_ResolveAreaOpt

  !=============================================================================
  ! DEFINITION: Unified dispatcher
  !=============================================================================
  SUBROUTINE UF_Elem_Pipe_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=10) :: ename
    INTEGER(i4) :: nNode

    ename = ElemType%name
    CALL UPPER_CASE(ename)
    nNode = ElemType%numNodes

    IF (INDEX(ename, 'PIPE21') > 0) THEN
      CALL UF_Elem_PIPE21_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'PIPE22') > 0) THEN
      CALL UF_Elem_PIPE22_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    END IF

    IF (nNode == 2) THEN
      CALL UF_Elem_PIPE21_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    ELSE
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      state_out%Me = 0.0_wp
      state_out%Ce = 0.0_wp
      flags%failed = .TRUE.
      flags%suggest_cutback = .FALSE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Pipe_Calc: pipe expects 2 nodes (PIPE21/PIPE22 topology)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF
  END SUBROUTINE UF_Elem_Pipe_Calc

  SUBROUTINE UPPER_CASE(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i
    DO i = 1, LEN(str)
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') &
        str(i:i) = CHAR(ICHAR(str(i:i)) - 32)
    END DO
  END SUBROUTINE UPPER_CASE

  !=============================================================================
  ! PIPE21: definition + Calc (legacy names retained for dispatch)
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_DefInit()
  END SUBROUTINE PH_Elem_PIPE21_DefInit

  SUBROUTINE PH_Elem_PIPE21_FormStiffMatrix(coords, E_young, nu, Ke, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    REAL(wp) :: c12(3, 2)
    REAL(wp) :: Asec
    LOGICAL :: ok
    Ke = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL Pipe_ResolveAreaOpt(area, Asec)
    CALL PH_Elem_T3D2_FormStiffMatrix(c12, E_young, Asec, Ke)
  END SUBROUTINE PH_Elem_PIPE21_FormStiffMatrix

  SUBROUTINE PH_Elem_PIPE21_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    REAL(wp) :: e1(1)
    eps_th = ZERO
    CALL PH_Elem_T3D2_ThermStrainVector(alpha, deltaT, e1)
    IF (SIZE(eps_th) >= 1) eps_th(1) = e1(1)
  END SUBROUTINE PH_Elem_PIPE21_ThermStrainVector

  SUBROUTINE PH_Elem_PIPE21_ConsMass(coords, rho, Me, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    REAL(wp) :: c12(3, 2)
    REAL(wp) :: Asec
    LOGICAL :: ok
    Me = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL Pipe_ResolveAreaOpt(area, Asec)
    CALL PH_Elem_T3D2_ConsMass(c12, rho, Asec, Me)
  END SUBROUTINE PH_Elem_PIPE21_ConsMass

  SUBROUTINE PH_Elem_PIPE21_FormIntForce(coords, u, E_young, nu, R_int, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: u(6)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    REAL(wp) :: c12(3, 2)
    REAL(wp) :: Asec
    LOGICAL :: ok
    R_int = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL Pipe_ResolveAreaOpt(area, Asec)
    CALL PH_Elem_T3D2_FormIntForce(c12, u, E_young, Asec, R_int)
  END SUBROUTINE PH_Elem_PIPE21_FormIntForce

  SUBROUTINE PH_Elem_PIPE21_LumpMass(coords, rho, M_lumped, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    REAL(wp) :: c12(3, 2)
    REAL(wp) :: Asec
    LOGICAL :: ok
    M_lumped = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL Pipe_ResolveAreaOpt(area, Asec)
    CALL PH_Elem_T3D2_LumpMass(c12, rho, Asec, M_lumped)
  END SUBROUTINE PH_Elem_PIPE21_LumpMass

  SUBROUTINE PH_Elem_PIPE21_NL_TL(coords_ref, u_elem, D, area, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 2)
    REAL(wp), INTENT(IN) :: u_elem(6)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6), Ke_geo(6, 6), R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 2)
    REAL(wp) :: dx_ref, dy_ref, dz_ref, L_ref
    REAL(wp) :: dx_curr, dy_curr, dz_curr, L_curr
    REAL(wp) :: e_ref(3)
    REAL(wp) :: lambda, E_GL, S_PK2
    REAL(wp) :: dN_dX(2)
    REAL(wp) :: B_mat(1, 6), B_geo(3, 6)
    REAL(wp) :: D_tangent, wt
    REAL(wp) :: E_young
    INTEGER(i4) :: i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    CALL init_error_status(status)

    E_young = D(1, 1)
    IF (E_young <= 0.0_wp) E_young = ONE

    coords_curr(:, 1) = coords_ref(:, 1) + u_elem(1:3)
    coords_curr(:, 2) = coords_ref(:, 2) + u_elem(4:6)

    dx_ref = coords_ref(1, 2) - coords_ref(1, 1)
    dy_ref = coords_ref(2, 2) - coords_ref(2, 1)
    dz_ref = coords_ref(3, 2) - coords_ref(3, 1)
    L_ref = SQRT(dx_ref*dx_ref + dy_ref*dy_ref + dz_ref*dz_ref)

    IF (L_ref <= 1.0e-12_wp) THEN
      CALL init_error_status(status, IF_STATUS_INVALID, message='PH_ELEM_PIPE21_NL_TL: Zero reference length')
      RETURN
    END IF

    e_ref(1) = dx_ref / L_ref
    e_ref(2) = dy_ref / L_ref
    e_ref(3) = dz_ref / L_ref

    dx_curr = coords_curr(1, 2) - coords_curr(1, 1)
    dy_curr = coords_curr(2, 2) - coords_curr(2, 1)
    dz_curr = coords_curr(3, 2) - coords_curr(3, 1)
    L_curr = SQRT(dx_curr*dx_curr + dy_curr*dy_curr + dz_curr*dz_curr)

    lambda = L_curr / L_ref
    E_GL = HALF * (lambda*lambda - ONE)
    S_PK2 = E_young * E_GL
    D_tangent = E_young

    dN_dX(1) = -ONE / L_ref
    dN_dX(2) =  ONE / L_ref

    B_mat(1, 1) = dN_dX(1) * e_ref(1)
    B_mat(1, 2) = dN_dX(1) * e_ref(2)
    B_mat(1, 3) = dN_dX(1) * e_ref(3)
    B_mat(1, 4) = dN_dX(2) * e_ref(1)
    B_mat(1, 5) = dN_dX(2) * e_ref(2)
    B_mat(1, 6) = dN_dX(2) * e_ref(3)

    wt = area * L_ref
    Ke_mat = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

    B_geo = ZERO
    DO i = 1, 2
      B_geo(1, 3*(i-1)+1) = dN_dX(i)
      B_geo(2, 3*(i-1)+2) = dN_dX(i)
      B_geo(3, 3*(i-1)+3) = dN_dX(i)
    END DO

    Ke_geo = S_PK2 * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

    R_int(1) = S_PK2 * B_mat(1, 1) * wt
    R_int(2) = S_PK2 * B_mat(1, 2) * wt
    R_int(3) = S_PK2 * B_mat(1, 3) * wt
    R_int(4) = S_PK2 * B_mat(1, 4) * wt
    R_int(5) = S_PK2 * B_mat(1, 5) * wt
    R_int(6) = S_PK2 * B_mat(1, 6) * wt

    CALL init_error_status(status)
  END SUBROUTINE PH_Elem_PIPE21_NL_TL

  SUBROUTINE PH_Elem_PIPE21_NL_UL(coords_prev, u_incr, D, area, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 2)
    REAL(wp), INTENT(IN) :: u_incr(6)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6), Ke_geo(6, 6), R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 2)
    REAL(wp) :: dx_prev, dy_prev, dz_prev, L_prev
    REAL(wp) :: dx_curr, dy_curr, dz_curr, L_curr
    REAL(wp) :: e_prev(3)
    REAL(wp) :: lambda, e_Almansi, sigma_Cauchy
    REAL(wp) :: dN_dx(2)
    REAL(wp) :: B_mat(1, 6), B_geo(3, 6)
    REAL(wp) :: D_tangent, wt
    REAL(wp) :: E_young
    INTEGER(i4) :: i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    CALL init_error_status(status)

    E_young = D(1, 1)
    IF (E_young <= 0.0_wp) E_young = ONE

    coords_curr(:, 1) = coords_prev(:, 1) + u_incr(1:3)
    coords_curr(:, 2) = coords_prev(:, 2) + u_incr(4:6)

    dx_prev = coords_prev(1, 2) - coords_prev(1, 1)
    dy_prev = coords_prev(2, 2) - coords_prev(2, 1)
    dz_prev = coords_prev(3, 2) - coords_prev(3, 1)
    L_prev = SQRT(dx_prev*dx_prev + dy_prev*dy_prev + dz_prev*dz_prev)

    IF (L_prev <= 1.0e-12_wp) THEN
      CALL init_error_status(status, IF_STATUS_INVALID, message='PH_ELEM_PIPE21_NL_UL: Zero previous length')
      RETURN
    END IF

    e_prev(1) = dx_prev / L_prev
    e_prev(2) = dy_prev / L_prev
    e_prev(3) = dz_prev / L_prev

    dx_curr = coords_curr(1, 2) - coords_curr(1, 1)
    dy_curr = coords_curr(2, 2) - coords_curr(2, 1)
    dz_curr = coords_curr(3, 2) - coords_curr(3, 1)
    L_curr = SQRT(dx_curr*dx_curr + dy_curr*dy_curr + dz_curr*dz_curr)

    lambda = L_curr / L_prev
    e_Almansi = HALF * (ONE - ONE/(lambda*lambda))
    sigma_Cauchy = E_young * e_Almansi
    D_tangent = E_young

    dN_dx(1) = -ONE / L_prev
    dN_dx(2) =  ONE / L_prev

    B_mat(1, 1) = dN_dx(1) * e_prev(1)
    B_mat(1, 2) = dN_dx(1) * e_prev(2)
    B_mat(1, 3) = dN_dx(1) * e_prev(3)
    B_mat(1, 4) = dN_dx(2) * e_prev(1)
    B_mat(1, 5) = dN_dx(2) * e_prev(2)
    B_mat(1, 6) = dN_dx(2) * e_prev(3)

    wt = area * L_prev
    Ke_mat = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

    B_geo = ZERO
    DO i = 1, 2
      B_geo(1, 3*(i-1)+1) = dN_dx(i)
      B_geo(2, 3*(i-1)+2) = dN_dx(i)
      B_geo(3, 3*(i-1)+3) = dN_dx(i)
    END DO

    Ke_geo = sigma_Cauchy * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

    R_int(1) = sigma_Cauchy * B_mat(1, 1) * wt
    R_int(2) = sigma_Cauchy * B_mat(1, 2) * wt
    R_int(3) = sigma_Cauchy * B_mat(1, 3) * wt
    R_int(4) = sigma_Cauchy * B_mat(1, 4) * wt
    R_int(5) = sigma_Cauchy * B_mat(1, 5) * wt
    R_int(6) = sigma_Cauchy * B_mat(1, 6) * wt

    CALL init_error_status(status)
  END SUBROUTINE PH_Elem_PIPE21_NL_UL

  !=============================================================================
  ! PIPE22: definition + Calc (legacy names retained for dispatch)
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_DefInit()
  END SUBROUTINE PH_Elem_PIPE22_DefInit

  SUBROUTINE PH_Elem_PIPE22_FormStiffMatrix(coords, E_young, nu, Ke, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    CALL PH_Elem_PIPE21_FormStiffMatrix(coords, E_young, nu, Ke, area)
  END SUBROUTINE PH_Elem_PIPE22_FormStiffMatrix

  SUBROUTINE PH_Elem_PIPE22_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    CALL PH_Elem_PIPE21_ThermStrainVector(alpha, deltaT, eps_th)
  END SUBROUTINE PH_Elem_PIPE22_ThermStrainVector

  SUBROUTINE PH_Elem_PIPE22_ConsMass(coords, rho, Me, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    CALL PH_Elem_PIPE21_ConsMass(coords, rho, Me, area)
  END SUBROUTINE PH_Elem_PIPE22_ConsMass

  SUBROUTINE PH_Elem_PIPE22_FormIntForce(coords, u, E_young, nu, R_int, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: u(6)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    CALL PH_Elem_PIPE21_FormIntForce(coords, u, E_young, nu, R_int, area)
  END SUBROUTINE PH_Elem_PIPE22_FormIntForce

  SUBROUTINE PH_Elem_PIPE22_LumpMass(coords, rho, M_lumped, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    REAL(wp), INTENT(IN), OPTIONAL :: area
    CALL PH_Elem_PIPE21_LumpMass(coords, rho, M_lumped, area)
  END SUBROUTINE PH_Elem_PIPE22_LumpMass

  SUBROUTINE PH_Elem_PIPE22_NL_TL(coords_ref, u_elem, D, area, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 2)
    REAL(wp), INTENT(IN) :: u_elem(6)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6), Ke_geo(6, 6), R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL PH_Elem_PIPE21_NL_TL(coords_ref, u_elem, D, area, Ke_mat, Ke_geo, R_int, status)
  END SUBROUTINE PH_Elem_PIPE22_NL_TL

  SUBROUTINE PH_Elem_PIPE22_NL_UL(coords_prev, u_incr, D, area, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 2)
    REAL(wp), INTENT(IN) :: u_incr(6)
    REAL(wp), INTENT(IN) :: D(6, 6)
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6), Ke_geo(6, 6), R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL PH_Elem_PIPE21_NL_UL(coords_prev, u_incr, D, area, Ke_mat, Ke_geo, R_int, status)
  END SUBROUTINE PH_Elem_PIPE22_NL_UL

  !=============================================================================
  ! PIPE21: Section
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_GetArea(coords, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(OUT) :: area
    ! Default section area when not supplied by material/section context (see module header).
    REAL(wp) :: c12(3, 2)
    LOGICAL :: ok
    area = ONE
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) area = ZERO
  END SUBROUTINE PH_Elem_PIPE21_GetArea

  SUBROUTINE PH_Elem_PIPE21_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: c12(3, 2)
    LOGICAL :: ok
    centroid = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL PH_Elem_T3D2_GetCentroid(c12, centroid)
  END SUBROUTINE PH_Elem_PIPE21_GetCentroid

  SUBROUTINE PH_Elem_PIPE21_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    REAL(wp) :: c12(3, 2)
    REAL(wp) :: elen
    LOGICAL :: ok
    area = ONE
    mass = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL PH_Elem_T3D2_GetSectProps(c12, density_in, area, elen, mass)
  END SUBROUTINE PH_Elem_PIPE21_GetSectProps

  !=============================================================================
  ! PIPE22: Section
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_GetArea(coords, area)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_Elem_PIPE21_GetArea(coords, area)
  END SUBROUTINE PH_Elem_PIPE22_GetArea

  SUBROUTINE PH_Elem_PIPE22_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(OUT) :: centroid(3)
    CALL PH_Elem_PIPE21_GetCentroid(coords, centroid)
  END SUBROUTINE PH_Elem_PIPE22_GetCentroid

  SUBROUTINE PH_Elem_PIPE22_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN) :: coords(:, :)
    REAL(wp), INTENT(IN) :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_PIPE21_GetSectProps(coords, density_in, area, mass)
  END SUBROUTINE PH_Elem_PIPE22_GetSectProps

  !=============================================================================
  ! PIPE21: Constraints
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 6) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_PIPE21_ApplyConstraint

  SUBROUTINE PH_Elem_PIPE21_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(6)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    INTEGER(i4) :: i, j
    DO i = 1, 6
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 6
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_PIPE21_ApplyMPC

  !=============================================================================
  ! PIPE22: Constraints
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 6) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_PIPE22_ApplyConstraint

  SUBROUTINE PH_Elem_PIPE22_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(6)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
    INTEGER(i4) :: i, j
    DO i = 1, 6
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 6
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_PIPE22_ApplyMPC

  !=============================================================================
  ! PIPE21: Contact
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
  END SUBROUTINE PH_Elem_PIPE21_FormContactContrib

  SUBROUTINE PH_Elem_PIPE21_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(6, 6)
    REAL(wp), INTENT(OUT) :: F_el(6)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_PIPE21_FormContactEdgeCtr

  !=============================================================================
  ! PIPE22: Contact
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(6, 6)
    REAL(wp), INTENT(INOUT) :: F_el(6)
  END SUBROUTINE PH_Elem_PIPE22_FormContactContrib

  SUBROUTINE PH_Elem_PIPE22_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(6, 6)
    REAL(wp), INTENT(OUT) :: F_el(6)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_PIPE22_FormContactEdgeCtr

  !=============================================================================
  ! PIPE21: Loads
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(:, :)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: c12(3, 2)
    LOGICAL :: ok
    F_eq = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL PH_Elem_T3D2_FormNodalForce(load_type, c12, val, edge_id, F_eq)
  END SUBROUTINE PH_Elem_PIPE21_FormNodalForce

  SUBROUTINE PH_Elem_PIPE21_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(:, :)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(6)
    REAL(wp) :: c12(3, 2)
    LOGICAL :: ok
    F_eq = ZERO
    CALL Pipe_CopyCoords12(coords, c12, ok)
    IF (.NOT. ok) RETURN
    CALL PH_Elem_T3D2_FormBodyForce(c12, bx, by, bz, F_eq)
  END SUBROUTINE PH_Elem_PIPE21_FormBodyForce

  !=============================================================================
  ! PIPE22: Loads
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(:, :)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(6)
    CALL PH_Elem_PIPE21_FormNodalForce(load_type, coords, val, edge_id, F_eq)
  END SUBROUTINE PH_Elem_PIPE22_FormNodalForce

  SUBROUTINE PH_Elem_PIPE22_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(:, :)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(6)
    CALL PH_Elem_PIPE21_FormBodyForce(coords, bx, by, bz, F_eq)
  END SUBROUTINE PH_Elem_PIPE22_FormBodyForce

  !=============================================================================
  ! PIPE21: Output
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE21_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    CALL PH_Elem_T3D2_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
  END SUBROUTINE PH_Elem_PIPE21_CollectIPVars

  SUBROUTINE PH_Elem_PIPE21_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    IF (SIZE(sigma) >= 1) THEN
      seq = ABS(sigma(1))
    ELSE
      seq = ZERO
    END IF
  END SUBROUTINE PH_Elem_PIPE21_EvalVonMises

  SUBROUTINE PH_Elem_PIPE21_EvalPipeStress(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    CALL PH_Elem_PIPE21_EvalVonMises(sigma, seq)
  END SUBROUTINE PH_Elem_PIPE21_EvalPipeStress

  SUBROUTINE PH_Elem_PIPE21_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    REAL(wp) :: Et(2, 1)
    INTEGER(i4) :: i, j
    E = ZERO
    CALL PH_Elem_T3D2_GetExtrapMat(Et)
    DO j = 1, 1
      DO i = 1, 2
        E(i, j) = Et(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_PIPE21_GetExtrapMat

  SUBROUTINE PH_Elem_PIPE21_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    CALL PH_Elem_T3D2_MapToNode(ip_vars, weights, node_vars)
  END SUBROUTINE PH_Elem_PIPE21_MapToNode

  !=============================================================================
  ! PIPE22: Output
  !=============================================================================
  SUBROUTINE PH_Elem_PIPE22_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    CALL PH_Elem_PIPE21_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
  END SUBROUTINE PH_Elem_PIPE22_CollectIPVars

  SUBROUTINE PH_Elem_PIPE22_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    CALL PH_Elem_PIPE21_EvalVonMises(sigma, seq)
  END SUBROUTINE PH_Elem_PIPE22_EvalVonMises

  SUBROUTINE PH_Elem_PIPE22_EvalPipeStress(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    CALL PH_Elem_PIPE22_EvalVonMises(sigma, seq)
  END SUBROUTINE PH_Elem_PIPE22_EvalPipeStress

  SUBROUTINE PH_Elem_PIPE22_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    CALL PH_Elem_PIPE21_GetExtrapMat(E)
  END SUBROUTINE PH_Elem_PIPE22_GetExtrapMat

  SUBROUTINE PH_Elem_PIPE22_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    CALL PH_Elem_PIPE21_MapToNode(ip_vars, weights, node_vars)
  END SUBROUTINE PH_Elem_PIPE22_MapToNode

  !=============================================================================
  ! PIPE21: Calc
  !=============================================================================
  SUBROUTINE UF_Elem_PIPE21_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_PIPE21_NNODE)
    REAL(wp) :: u(PH_ELEM_PIPE21_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_PIPE21_NDOF, PH_ELEM_PIPE21_NDOF)
    REAL(wp) :: R_int(PH_ELEM_PIPE21_NDOF)
    REAL(wp) :: dx, dy, dz, L0, A_sec
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE21_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_PIPE21_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE21_Calc: insufficient nodes in coords_ref'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    DO i = 1, PH_ELEM_PIPE21_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= PH_ELEM_PIPE21_NNODE) THEN
        DO i = 1, PH_ELEM_PIPE21_NNODE
          IF (SIZE(Ctx%disp_total, 1) >= 3) THEN
            u(3*(i-1)+1) = Ctx%disp_total(1, i)
            u(3*(i-1)+2) = Ctx%disp_total(2, i)
            u(3*(i-1)+3) = Ctx%disp_total(3, i)
          END IF
        END DO
      END IF
    END IF

    E_young = 0.0_wp
    nu = 0.3_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= UF_MAT_PROP_ELA) E_young = Mat%props(UF_MAT_PROP_ELA)
      IF (SIZE(Mat%props) >= UF_MAT_PROP_NU) nu = Mat%props(UF_MAT_PROP_NU)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE21_Calc: invalid Young modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    dz = coords(3, 2) - coords(3, 1)
    L0 = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L0 <= 1.0e-12_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE21_Calc: zero or degenerate element length'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    A_sec = ONE
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 3_i4) THEN
        IF (Mat%props(3) > 0.0_wp) A_sec = Mat%props(3)
      END IF
    END IF

    CALL PH_Elem_PIPE21_FormStiffMatrix(coords, E_young, nu, Ke, area=A_sec)
    CALL PH_Elem_PIPE21_FormIntForce(coords, u, E_young, nu, R_int, area=A_sec)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_PIPE21_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_PIPE21_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_PIPE21_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_PIPE21_NIP)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  END SUBROUTINE UF_Elem_PIPE21_Calc

  !=============================================================================
  ! PIPE22: Calc
  !=============================================================================
  SUBROUTINE UF_Elem_PIPE22_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_PIPE22_NNODE)
    REAL(wp) :: u(PH_ELEM_PIPE22_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_PIPE22_NDOF, PH_ELEM_PIPE22_NDOF)
    REAL(wp) :: R_int(PH_ELEM_PIPE22_NDOF)
    REAL(wp) :: dx, dy, dz, L0, A_sec
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE22_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_PIPE22_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE22_Calc: insufficient nodes in coords_ref'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    DO i = 1, PH_ELEM_PIPE22_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= PH_ELEM_PIPE22_NNODE) THEN
        DO i = 1, PH_ELEM_PIPE22_NNODE
          IF (SIZE(Ctx%disp_total, 1) >= 3) THEN
            u(3*(i-1)+1) = Ctx%disp_total(1, i)
            u(3*(i-1)+2) = Ctx%disp_total(2, i)
            u(3*(i-1)+3) = Ctx%disp_total(3, i)
          END IF
        END DO
      END IF
    END IF

    E_young = 0.0_wp
    nu = 0.3_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= UF_MAT_PROP_ELA) E_young = Mat%props(UF_MAT_PROP_ELA)
      IF (SIZE(Mat%props) >= UF_MAT_PROP_NU) nu = Mat%props(UF_MAT_PROP_NU)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE22_Calc: invalid Young modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    dx = coords(1, 2) - coords(1, 1)
    dy = coords(2, 2) - coords(2, 1)
    dz = coords(3, 2) - coords(3, 1)
    L0 = SQRT(dx*dx + dy*dy + dz*dz)
    IF (L0 <= 1.0e-12_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_PIPE22_Calc: zero or degenerate element length'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    A_sec = ONE
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 3_i4) THEN
        IF (Mat%props(3) > 0.0_wp) A_sec = Mat%props(3)
      END IF
    END IF

    CALL PH_Elem_PIPE22_FormStiffMatrix(coords, E_young, nu, Ke, area=A_sec)
    CALL PH_Elem_PIPE22_FormIntForce(coords, u, E_young, nu, R_int, area=A_sec)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_PIPE22_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_PIPE22_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_PIPE22_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_PIPE22_NIP)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  END SUBROUTINE UF_Elem_PIPE22_Calc

  SUBROUTINE PH_Elem_PIPE21_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
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
  END SUBROUTINE PH_Elem_PIPE21_Material_Update_Routed

  SUBROUTINE PH_Elem_PIPE22_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
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
  END SUBROUTINE PH_Elem_PIPE22_Material_Update_Routed

END MODULE PH_Elem_Pipe

