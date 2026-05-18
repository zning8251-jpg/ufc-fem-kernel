!===============================================================================
! MODULE: PH_Elem_T3D3
! LAYER:  L4_PH
! DOMAIN: Element/Truss
! ROLE:   Proc
! BRIEF:  T3D3 3-node 3D quadratic truss element
!===============================================================================
MODULE PH_Elem_T3D3
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
  PUBLIC :: PH_Elem_T3D3_DefInit
  PUBLIC :: PH_Elem_T3D3_ShapeFunc
  PUBLIC :: PH_Elem_T3D3_FormStiffMatrix
  PUBLIC :: PH_Elem_T3D3_NL_TL
  PUBLIC :: PH_Elem_T3D3_NL_UL
  PUBLIC :: PH_Elem_T3D3_Material_Update_Routed
  PUBLIC :: UF_Elem_T3D3_Calc
  PUBLIC :: PH_ELEM_T3D3_NNODE
  PUBLIC :: PH_ELEM_T3D3_NIP
  PUBLIC :: PH_ELEM_T3D3_NDOF
  PUBLIC :: PH_ELEM_T3D3_NEDGE

  INTEGER(i4), PARAMETER :: PH_ELEM_T3D3_NNODE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T3D3_NIP   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T3D3_NDOF  = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_T3D3_NEDGE = 0_i4

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

  SUBROUTINE PH_Elem_T3D3_DefInit()
  END SUBROUTINE PH_Elem_T3D3_DefInit

  SUBROUTINE PH_Elem_T3D3_FormStiffMatrix(coords, E_young, area, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: E_young, area
    REAL(wp), INTENT(OUT) :: Ke(9, 9)
    REAL(wp) :: xi_gp(2), wt_gp(2)
    REAL(wp) :: N(3), dN_dxi(3), dN_dX(3)
    REAL(wp) :: J_ref, dx_dxi(3)
    REAL(wp) :: B_mat(1, 9), EA
    INTEGER(i4) :: igp, i, j

    Ke = ZERO

    xi_gp(1) = -SQRT(ONE / 3.0_wp)
    xi_gp(2) =  SQRT(ONE / 3.0_wp)
    wt_gp(1) = ONE
    wt_gp(2) = ONE

    EA = E_young * area

    DO igp = 1, 2
      CALL PH_Elem_T3D3_ShapeFunc(xi_gp(igp), N, dN_dxi)

      dx_dxi = ZERO
      DO i = 1, 3
        dx_dxi(1) = dx_dxi(1) + dN_dxi(i) * coords(1, i)
        dx_dxi(2) = dx_dxi(2) + dN_dxi(i) * coords(2, i)
        dx_dxi(3) = dx_dxi(3) + dN_dxi(i) * coords(3, i)
      END DO

      J_ref = SQRT(dx_dxi(1)**2 + dx_dxi(2)**2 + dx_dxi(3)**2)

      IF (J_ref <= 1.0e-12_wp) CYCLE

      DO i = 1, 3
        dN_dX(i) = dN_dxi(i) / J_ref
      END DO

      B_mat = ZERO
      DO i = 1, 3
        B_mat(1, 3*(i-1)+1) = dN_dX(i) * dx_dxi(1) / J_ref
        B_mat(1, 3*(i-1)+2) = dN_dX(i) * dx_dxi(2) / J_ref
        B_mat(1, 3*(i-1)+3) = dN_dX(i) * dx_dxi(3) / J_ref
      END DO

      Ke = Ke + EA * J_ref * wt_gp(igp) * MATMUL(TRANSPOSE(B_mat), B_mat)
    END DO

  END SUBROUTINE PH_Elem_T3D3_FormStiffMatrix

  SUBROUTINE PH_Elem_T3D3_NL_TL(coords_ref, u_elem, E_young, area, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 3)
    REAL(wp), INTENT(IN) :: u_elem(9)
    REAL(wp), INTENT(IN) :: E_young
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(9, 9)
    REAL(wp), INTENT(OUT) :: Ke_geo(9, 9)
    REAL(wp), INTENT(OUT) :: R_int(9)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 3)
    REAL(wp) :: xi_gp(2), wt_gp(2)
    REAL(wp) :: N(3), dN_dxi(3), dN_dX(3)
    REAL(wp) :: dx_dxi_ref(3), dx_dxi_curr(3)
    REAL(wp) :: J_ref, J_curr
    REAL(wp) :: e_ref(3)
    REAL(wp) :: lambda, E_GL, S_PK2
    REAL(wp) :: B_mat(1, 9), B_geo(3, 9)
    REAL(wp) :: D_tangent, wt
    REAL(wp) :: K_mat_gp(9, 9), K_geo_gp(9, 9), R_gp(9)
    INTEGER(i4) :: igp, i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 3
      coords_curr(1, i) = coords_ref(1, i) + u_elem(3*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(3*(i-1)+2)
      coords_curr(3, i) = coords_ref(3, i) + u_elem(3*(i-1)+3)
    END DO

    xi_gp(1) = -SQRT(ONE / 3.0_wp)
    xi_gp(2) =  SQRT(ONE / 3.0_wp)
    wt_gp(1) = ONE
    wt_gp(2) = ONE

    DO igp = 1, 2
      CALL PH_Elem_T3D3_ShapeFunc(xi_gp(igp), N, dN_dxi)

      dx_dxi_ref = ZERO
      dx_dxi_curr = ZERO
      DO i = 1, 3
        dx_dxi_ref(1) = dx_dxi_ref(1) + dN_dxi(i) * coords_ref(1, i)
        dx_dxi_ref(2) = dx_dxi_ref(2) + dN_dxi(i) * coords_ref(2, i)
        dx_dxi_ref(3) = dx_dxi_ref(3) + dN_dxi(i) * coords_ref(3, i)
        dx_dxi_curr(1) = dx_dxi_curr(1) + dN_dxi(i) * coords_curr(1, i)
        dx_dxi_curr(2) = dx_dxi_curr(2) + dN_dxi(i) * coords_curr(2, i)
        dx_dxi_curr(3) = dx_dxi_curr(3) + dN_dxi(i) * coords_curr(3, i)
      END DO

      J_ref = SQRT(dx_dxi_ref(1)**2 + dx_dxi_ref(2)**2 + dx_dxi_ref(3)**2)
      J_curr = SQRT(dx_dxi_curr(1)**2 + dx_dxi_curr(2)**2 + dx_dxi_curr(3)**2)

      IF (J_ref <= 1.0e-12_wp) CYCLE

      e_ref(1) = dx_dxi_ref(1) / J_ref
      e_ref(2) = dx_dxi_ref(2) / J_ref
      e_ref(3) = dx_dxi_ref(3) / J_ref

      DO i = 1, 3
        dN_dX(i) = dN_dxi(i) / J_ref
      END DO

      lambda = J_curr / J_ref
      E_GL = HALF * (lambda*lambda - ONE)
      S_PK2 = E_young * E_GL
      D_tangent = E_young

      B_mat = ZERO
      DO i = 1, 3
        B_mat(1, 3*(i-1)+1) = dN_dX(i) * e_ref(1)
        B_mat(1, 3*(i-1)+2) = dN_dX(i) * e_ref(2)
        B_mat(1, 3*(i-1)+3) = dN_dX(i) * e_ref(3)
      END DO

      wt = area * J_ref * wt_gp(igp)
      K_mat_gp = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

      B_geo = ZERO
      DO i = 1, 3
        B_geo(1, 3*(i-1)+1) = dN_dX(i)
        B_geo(2, 3*(i-1)+2) = dN_dX(i)
        B_geo(3, 3*(i-1)+3) = dN_dX(i)
      END DO

      K_geo_gp = S_PK2 * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

      R_gp = ZERO
      DO i = 1, 9
        R_gp(i) = S_PK2 * B_mat(1, i) * wt
      END DO

      Ke_mat = Ke_mat + K_mat_gp
      Ke_geo = Ke_geo + K_geo_gp
      R_int = R_int + R_gp
    END DO

  END SUBROUTINE PH_Elem_T3D3_NL_TL

  SUBROUTINE PH_Elem_T3D3_NL_UL(coords_prev, u_incr, E_young, area, &
                                  Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 3)
    REAL(wp), INTENT(IN) :: u_incr(9)
    REAL(wp), INTENT(IN) :: E_young
    REAL(wp), INTENT(IN) :: area
    REAL(wp), INTENT(OUT) :: Ke_mat(9, 9)
    REAL(wp), INTENT(OUT) :: Ke_geo(9, 9)
    REAL(wp), INTENT(OUT) :: R_int(9)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 3)
    REAL(wp) :: xi_gp(2), wt_gp(2)
    REAL(wp) :: N(3), dN_dxi(3), dN_dx(3)
    REAL(wp) :: dx_dxi_prev(3), dx_dxi_curr(3)
    REAL(wp) :: J_prev, J_curr
    REAL(wp) :: e_prev(3)
    REAL(wp) :: lambda, e_Almansi, sigma_Cauchy
    REAL(wp) :: B_mat(1, 9), B_geo(3, 9)
    REAL(wp) :: D_tangent, wt
    REAL(wp) :: K_mat_gp(9, 9), K_geo_gp(9, 9), R_gp(9)
    INTEGER(i4) :: igp, i

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 3
      coords_curr(1, i) = coords_prev(1, i) + u_incr(3*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(3*(i-1)+2)
      coords_curr(3, i) = coords_prev(3, i) + u_incr(3*(i-1)+3)
    END DO

    xi_gp(1) = -SQRT(ONE / 3.0_wp)
    xi_gp(2) =  SQRT(ONE / 3.0_wp)
    wt_gp(1) = ONE
    wt_gp(2) = ONE

    DO igp = 1, 2
      CALL PH_Elem_T3D3_ShapeFunc(xi_gp(igp), N, dN_dxi)

      dx_dxi_prev = ZERO
      dx_dxi_curr = ZERO
      DO i = 1, 3
        dx_dxi_prev(1) = dx_dxi_prev(1) + dN_dxi(i) * coords_prev(1, i)
        dx_dxi_prev(2) = dx_dxi_prev(2) + dN_dxi(i) * coords_prev(2, i)
        dx_dxi_prev(3) = dx_dxi_prev(3) + dN_dxi(i) * coords_prev(3, i)
        dx_dxi_curr(1) = dx_dxi_curr(1) + dN_dxi(i) * coords_curr(1, i)
        dx_dxi_curr(2) = dx_dxi_curr(2) + dN_dxi(i) * coords_curr(2, i)
        dx_dxi_curr(3) = dx_dxi_curr(3) + dN_dxi(i) * coords_curr(3, i)
      END DO

      J_prev = SQRT(dx_dxi_prev(1)**2 + dx_dxi_prev(2)**2 + dx_dxi_prev(3)**2)
      J_curr = SQRT(dx_dxi_curr(1)**2 + dx_dxi_curr(2)**2 + dx_dxi_curr(3)**2)

      IF (J_prev <= 1.0e-12_wp) CYCLE

      e_prev(1) = dx_dxi_prev(1) / J_prev
      e_prev(2) = dx_dxi_prev(2) / J_prev
      e_prev(3) = dx_dxi_prev(3) / J_prev

      DO i = 1, 3
        dN_dx(i) = dN_dxi(i) / J_prev
      END DO

      lambda = J_curr / J_prev
      e_Almansi = HALF * (ONE - ONE/(lambda*lambda))
      sigma_Cauchy = E_young * e_Almansi
      D_tangent = E_young

      B_mat = ZERO
      DO i = 1, 3
        B_mat(1, 3*(i-1)+1) = dN_dx(i) * e_prev(1)
        B_mat(1, 3*(i-1)+2) = dN_dx(i) * e_prev(2)
        B_mat(1, 3*(i-1)+3) = dN_dx(i) * e_prev(3)
      END DO

      wt = area * J_prev * wt_gp(igp)
      K_mat_gp = D_tangent * wt * MATMUL(TRANSPOSE(B_mat), B_mat)

      B_geo = ZERO
      DO i = 1, 3
        B_geo(1, 3*(i-1)+1) = dN_dx(i)
        B_geo(2, 3*(i-1)+2) = dN_dx(i)
        B_geo(3, 3*(i-1)+3) = dN_dx(i)
      END DO

      K_geo_gp = sigma_Cauchy * wt * MATMUL(TRANSPOSE(B_geo), B_geo)

      R_gp = ZERO
      DO i = 1, 9
        R_gp(i) = sigma_Cauchy * B_mat(1, i) * wt
      END DO

      Ke_mat = Ke_mat + K_mat_gp
      Ke_geo = Ke_geo + K_geo_gp
      R_int = R_int + R_gp
    END DO

  END SUBROUTINE PH_Elem_T3D3_NL_UL

  SUBROUTINE PH_Elem_T3D3_ShapeFunc(xi, N, dN_dxi)
    REAL(wp), INTENT(IN)  :: xi
    REAL(wp), INTENT(OUT) :: N(3)
    REAL(wp), INTENT(OUT) :: dN_dxi(3)

    N(1) = -HALF * xi * (ONE - xi)
    N(2) = (ONE - xi) * (ONE + xi)
    N(3) =  HALF * xi * (ONE + xi)

    dN_dxi(1) = -HALF * (ONE - 2.0_wp * xi)
    dN_dxi(2) = -2.0_wp * xi
    dN_dxi(3) =  HALF * (ONE + 2.0_wp * xi)
  END SUBROUTINE PH_Elem_T3D3_ShapeFunc

  SUBROUTINE UF_Elem_T3D3_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: coords(3, 3)
    REAL(wp) :: u(9)
    REAL(wp) :: L0, A
    REAL(wp), allocatable :: Ke_loc(:,:), Re_loc(:)
    TYPE(MatCtxLegacy)  :: material_ctxt
    TYPE(MatRes)  :: material_res
    TYPE(MatProperties) :: props
    REAL(wp) :: stress6(6)
    REAL(wp) :: D11
    INTEGER(i4) :: i, comp, ip
    INTEGER(i4) :: nIP_state

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Basic checks
    nNode = ElemType%numNodes
    IF (nNode /= 3) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_T3D3_Calc: expected 3 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    nDim = ElemType%dim
    IF (nDim < 1 .OR. nDim > 3) nDim = 3
    nDOF = nNode * nDim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_T3D3_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract coordinates
    coords = 0.0_wp
    DO i = 1, MIN(3, SIZE(Ctx%coords_ref, 2))
      DO comp = 1, MIN(3, SIZE(Ctx%coords_ref, 1))
        coords(comp, i) = Ctx%coords_ref(comp, i)
      END DO
    END DO

    ! Extract displacements
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      DO i = 1, MIN(3, SIZE(Ctx%disp_total, 2))
        DO comp = 1, MIN(3, SIZE(Ctx%disp_total, 1))
          u(3*(i-1)+comp) = Ctx%disp_total(comp, i)
        END DO
      END DO
    END IF

    ! Get section area
    A = 1.0_wp
    IF (ALLOCATED(Ctx%section)) THEN
      ! Try to get area from section if available
      ! For now, default to 1.0
    END IF

    ! Compute stiffness matrix using FormStiffMatrix
    ALLOCATE(Ke_loc(nDOF, nDOF))
    Ke_loc = 0.0_wp
    ALLOCATE(Re_loc(nDOF))
    Re_loc = 0.0_wp

    ! Get Mat properties
    D11 = 0.0_wp
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= UF_MAT_PROP_ELA) THEN
        IF (props%props(UF_MAT_PROP_ELA) > 0.0_wp) D11 = props%props(UF_MAT_PROP_ELA)
      END IF
    END IF

    IF (D11 <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_T3D3_Calc: invalid Young modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      DEALLOCATE(Ke_loc, Re_loc)
      RETURN
    END IF

    ! Call FormStiffMatrix
    CALL PH_Elem_T3D3_FormStiffMatrix(coords, D11, A, Ke_loc)

    ! For internal forces, we need to compute strain and stress
    ! This is simplified - for full implementation, we'd need to integrate over IPs
    ! For now, use a simplified approach similar to T2D2/T3D2
    ! Build Mat Ctx and call MatEval at first integration point
    material_ctxt%kin%mech%strain = 0.0_wp
    material_ctxt%kin%mech%dStrain = 0.0_wp
    material_ctxt%kin%time%current = Ctx%currentTime
    material_ctxt%kin%time%total = Ctx%currentTime
    material_ctxt%kin%time%inc = Ctx%deltaTime
    material_ctxt%kin%cfg%id = Ctx%cfg%id
    material_ctxt%kin%ipID = 1_i4

    ! Simplified strain computation (at center point)
    ! For quadratic element, this is approximate
    material_ctxt%kin%mech%strain(1) = 0.0_wp  ! Would need proper B-matrix evaluation

    material_ctxt%ip_state_in%sigma = 0.0_wp
    material_ctxt%ip_state_in%strain = 0.0_wp
    material_ctxt%ip_state_in%dstran = 0.0_wp
    material_ctxt%ip_state_in%pop%nStateV = 0_i4

    IF (ALLOCATED(state_in%ipStates)) THEN
      nIP_state = SIZE(state_in%ipStates)
      IF (nIP_state >= 1) THEN
        CALL IpStateToState(state_in%ipStates(1), material_ctxt%ip_state_in, &
             material_id=Mat%cfg%id, &
             element_id=Ctx%cfg%id, &
             ip_id=1_i4)
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

    ! For T3D3, internal forces would need proper integration
    ! Simplified: Re = Ke * u (for linear case)
    Re_loc = MATMUL(Ke_loc, u)

    ! Prepare output storage
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_T3D3_NIP)
    IF (ALLOCATED(state_out%ipStates)) THEN
      IF (SIZE(state_out%ipStates) >= 1) THEN
        CALL StateToIpState(material_res%ip_state_out, state_out%ipStates(1))
      END IF
    END IF

    flags%failed = material_res%flags%failed
    flags%suggest_cutback = material_res%flags%suggest_cutback
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

    DEALLOCATE(Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_T3D3_Calc

  SUBROUTINE PH_Elem_T3D3_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
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
  END SUBROUTINE PH_Elem_T3D3_Material_Update_Routed

END MODULE PH_Elem_T3D3

