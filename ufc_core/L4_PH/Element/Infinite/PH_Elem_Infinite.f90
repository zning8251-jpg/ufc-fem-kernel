!===============================================================================
! MODULE: PH_Elem_Infinite
! LAYER:  L4_PH
! DOMAIN: Element/Infinite
! ROLE:   Proc
! BRIEF:  Infinite element unified interface (merged Defn+Sect+Kernel+2D+3D)
!===============================================================================
MODULE PH_Elem_Infinite
!> [CORE] Infinite element unified interface (CINPE/CINPS/CINAX/CIN3D families)
!> Merged: Defn + Sect + Kernel + Infinite2D + Infinite3D
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, &
       UF_Mem_AllocReal2D, UF_Mem_FreeReal2D, MEM_DOMAIN_ELEM
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, ONLY: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, ONLY: MatProperties
  USE UF_ShapeFunc, ONLY: shape_quad4, shape_quad8, shape_hex8
  USE UF_GaussQuad, ONLY: gauss_quad, gauss_hexahedron
  USE UF_Material_Base
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: UF_Elem_Infinite_Calc
  PUBLIC :: InfiniteElemParams
  PUBLIC :: PH_Elem_Infinite_GetDecayParams
  PUBLIC :: PH_Elem_Infinite_SetDecayParams
  PUBLIC :: PH_Elem_Infinite_GetDefaultParams
  PUBLIC :: PH_Elem_Infinite_Material_Update_Decay_Routed

CONTAINS

  !=============================================================================
  ! SECTION: Infinite Element Parameters
  !=============================================================================
  TYPE, PUBLIC :: InfiniteElemParams
    INTEGER(i4) :: decay_type = 1  ! 1=exponential, 2=polynomial, 3=rational
    REAL(wp) :: decay_rate = 1.0_wp
    REAL(wp) :: decay_power = 2.0_wp
    REAL(wp) :: reference_dista = 1.0_wp
    LOGICAL :: use_geometric_m = .TRUE.
  END TYPE InfiniteElemParams

  SUBROUTINE PH_Elem_Infinite_GetDecayParams(Mat, params)
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(InfiniteElemParams), INTENT(OUT) :: params

    params = PH_Elem_Infinite_GetDefaultParams()

    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 1) params%decay_rate = Mat%props(1)
      IF (SIZE(Mat%props) >= 2) params%decay_type = INT(Mat%props(2), i4)
      IF (SIZE(Mat%props) >= 3) params%decay_power = Mat%props(3)
      IF (SIZE(Mat%props) >= 4) params%reference_dista = Mat%props(4)
    END IF

    IF (params%decay_type < 1 .OR. params%decay_type > 3) params%decay_type = 1
    IF (params%decay_rate <= 0.0_wp) params%decay_rate = 1.0_wp
    IF (params%decay_power <= 0.0_wp) params%decay_power = 2.0_wp
    IF (params%reference_dista <= 0.0_wp) params%reference_dista = 1.0_wp
  END SUBROUTINE PH_Elem_Infinite_GetDecayParams

  SUBROUTINE PH_Elem_Infinite_SetDecayParams(decay_type, decay_rate, decay_power, &
                                             reference_dista, use_geometric_m, params)
    INTEGER(i4), INTENT(IN), OPTIONAL :: decay_type
    REAL(wp), INTENT(IN), OPTIONAL :: decay_rate, decay_power, reference_dista
    LOGICAL, INTENT(IN), OPTIONAL :: use_geometric_m
    TYPE(InfiniteElemParams), INTENT(INOUT) :: params

    IF (PRESENT(decay_type)) THEN
      IF (decay_type >= 1 .AND. decay_type <= 3) params%decay_type = decay_type
    END IF
    IF (PRESENT(decay_rate) .AND. decay_rate > 0.0_wp) params%decay_rate = decay_rate
    IF (PRESENT(decay_power) .AND. decay_power > 0.0_wp) params%decay_power = decay_power
    IF (PRESENT(reference_dista) .AND. reference_dista > 0.0_wp) params%reference_dista = reference_dista
    IF (PRESENT(use_geometric_m)) params%use_geometric_m = use_geometric_m
  END SUBROUTINE PH_Elem_Infinite_SetDecayParams

  FUNCTION PH_Elem_Infinite_GetDefaultParams() RESULT(params)
    TYPE(InfiniteElemParams) :: params
    params%decay_type = 1
    params%decay_rate = 1.0_wp
    params%decay_power = 2.0_wp
    params%reference_dista = 1.0_wp
    params%use_geometric_m = .TRUE.
  END FUNCTION PH_Elem_Infinite_GetDefaultParams

  !=============================================================================
  ! DEFINITION: Unified dispatcher
  !=============================================================================
  SUBROUTINE UF_Elem_Infinite_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=32) :: ename
    INTEGER(i4) :: nNode, nDim

    ename = ElemType%name
    CALL UPPER_CASE(ename)
    nNode = ElemType%numNodes
    nDim = ElemType%dim

    IF (INDEX(ename, 'INF2D') > 0 .OR. INDEX(ename, 'CINPE') > 0 .OR. &
        INDEX(ename, 'CINPS') > 0 .OR. INDEX(ename, 'CINAX') > 0 .OR. &
        INDEX(ename, 'ACIN2D') > 0) THEN
      CALL UF_Elem_Infinite2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'INF3D') > 0 .OR. INDEX(ename, 'CIN3D') > 0 .OR. &
             INDEX(ename, 'ACIN3D') > 0) THEN
      CALL UF_Elem_Infinite3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    END IF

    IF (nDim == 2) THEN
      CALL UF_Elem_Infinite2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    ELSE IF (nDim == 3) THEN
      CALL UF_Elem_Infinite3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
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
        message='UF_Elem_Infinite_Calc: unsupported ElemType%dim (expected 2 or 3)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF
  END SUBROUTINE UF_Elem_Infinite_Calc

  SUBROUTINE UPPER_CASE(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i
    DO i = 1, LEN(str)
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') &
        str(i:i) = CHAR(ICHAR(str(i:i)) - 32)
    END DO
  END SUBROUTINE UPPER_CASE

  !=============================================================================
  ! KERNEL: D matrix builders
  !=============================================================================
  SUBROUTINE UF_BuildIsotropic2D_PlaneStrain_Local(Mat, D)
    TYPE(MatProperties), INTENT(IN) :: Mat
    REAL(wp), INTENT(OUT) :: D(3, 3)

    REAL(wp) :: E, nu, denom

    E = 1.0e6_wp
    nu = 0.3_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 1) E = Mat%props(1)
      IF (SIZE(Mat%props) >= 2) nu = Mat%props(2)
    END IF

    denom = (1.0_wp + nu) * (1.0_wp - 2.0_wp * nu)
    IF (ABS(denom) < 1.0e-12_wp) denom = 1.0_wp

    D = 0.0_wp
    D(1, 1) = E * (1.0_wp - nu) / denom
    D(2, 2) = D(1, 1)
    D(1, 2) = E * nu / denom
    D(2, 1) = D(1, 2)
    D(3, 3) = E / (2.0_wp * (1.0_wp + nu))
  END SUBROUTINE UF_BuildIsotropic2D_PlaneStrain_Local

  SUBROUTINE UF_BuildIsotropic3D_Local(Mat, D)
    TYPE(MatProperties), INTENT(IN) :: Mat
    REAL(wp), INTENT(OUT) :: D(6, 6)

    REAL(wp) :: E, nu, lambda, mu, c1, c2

    E = 1.0e6_wp
    nu = 0.3_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 1) E = Mat%props(1)
      IF (SIZE(Mat%props) >= 2) nu = Mat%props(2)
    END IF

    lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E / (2.0_wp * (1.0_wp + nu))

    D = 0.0_wp
    c1 = lambda + 2.0_wp * mu
    c2 = lambda
    D(1,1) = c1; D(2,2) = c1; D(3,3) = c1
    D(1,2) = c2; D(1,3) = c2; D(2,1) = c2; D(2,3) = c2; D(3,1) = c2; D(3,2) = c2
    D(4,4) = mu; D(5,5) = mu; D(6,6) = mu
  END SUBROUTINE UF_BuildIsotropic3D_Local

  !=============================================================================
  ! KERNEL: Decay and mapping
  !=============================================================================
  FUNCTION UF_ComputeDecayFunction(xi, params) RESULT(decay)
    REAL(wp), INTENT(IN) :: xi(:)
    TYPE(InfiniteElemParams), INTENT(IN) :: params
    REAL(wp) :: decay

    REAL(wp) :: xi_norm, alpha, n_power

    xi_norm = SQRT(SUM(xi**2))
    IF (xi_norm < 1.0_wp) THEN
      decay = 1.0_wp
      RETURN
    END IF

    alpha = params%decay_rate
    n_power = params%decay_power

    SELECT CASE (params%decay_type)
    CASE (1)
      decay = EXP(-alpha * (xi_norm - 1.0_wp))
    CASE (2)
      decay = 1.0_wp / (1.0_wp + alpha * (xi_norm - 1.0_wp))**n_power
    CASE (3)
      decay = 1.0_wp / (1.0_wp + alpha * (xi_norm - 1.0_wp)**2)
    CASE DEFAULT
      decay = EXP(-alpha * (xi_norm - 1.0_wp))
    END SELECT

    decay = MAX(1.0e-20_wp, MIN(1.0_wp, decay))
  END FUNCTION UF_ComputeDecayFunction

  SUBROUTINE UF_ComputeInfiniteMapping(coords_ref, xi, x_mapped, detJ, params, status)
    REAL(wp), INTENT(IN) :: coords_ref(:,:)
    REAL(wp), INTENT(IN) :: xi(:)
    REAL(wp), INTENT(OUT) :: x_mapped(:)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(InfiniteElemParams), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim, i
    INTEGER(i4) :: N_id
    REAL(wp), POINTER :: N(:)
    REAL(wp) :: decay, xi_norm
    REAL(wp) :: x_ref(SIZE(coords_ref, 1))
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    N_id = -1
    nNode = SIZE(coords_ref, 2)
    nDim = SIZE(coords_ref, 1)

    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nNode, 'Inf_N_map', N, N_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      GOTO 900
    END IF
    CALL UF_ComputeInfiniteShapeFunctions(coords_ref, xi, N, status)
    IF (status%status_code /= IF_STATUS_OK) GOTO 900

    x_ref = 0.0_wp
    DO i = 1, nNode
      x_ref = x_ref + N(i) * coords_ref(:, i)
    END DO

    decay = UF_ComputeDecayFunction(xi, params)

    IF (params%use_geometric_m) THEN
      xi_norm = SQRT(SUM(xi**2))
      IF (xi_norm > 1.0_wp) THEN
        x_mapped = x_ref + (x_ref - coords_ref(:, 1)) * (xi_norm - 1.0_wp) * decay
      ELSE
        x_mapped = x_ref
      END IF
    ELSE
      x_mapped = x_ref * decay
    END IF

    detJ = decay * params%reference_dista
    status%status_code = IF_STATUS_OK
900 CONTINUE
    IF (N_id >= 0) CALL UF_Mem_FreeReal1D(N_id, st)
    RETURN
  END SUBROUTINE UF_ComputeInfiniteMapping

  SUBROUTINE UF_ComputeInfiniteShapeFunctions(coords_ref, xi, N, status, dNdxi)
    REAL(wp), INTENT(IN) :: coords_ref(:,:)
    REAL(wp), INTENT(IN) :: xi(:)
    REAL(wp), INTENT(OUT) :: N(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(OUT), OPTIONAL :: dNdxi(:,:)

    INTEGER(i4) :: nNode, nDim
    INTEGER(i4) :: N_std_id
    REAL(wp), POINTER :: N_std(:)
    REAL(wp) :: dNdxi_vec(8), dNdeta_vec(8), dNdzeta_vec(8)
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    N_std_id = -1
    nNode = SIZE(coords_ref, 2)
    nDim = SIZE(coords_ref, 1)

    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nNode, 'Inf_N_std', N_std, N_std_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      GOTO 900
    END IF

    IF (nDim == 2 .AND. nNode == 4) THEN
      CALL shape_quad4(xi(1), xi(2), N_std, dNdxi_vec(1:4), dNdeta_vec(1:4))
      IF (PRESENT(dNdxi)) THEN
        dNdxi(1:4, 1) = dNdxi_vec(1:4)
        dNdxi(1:4, 2) = dNdeta_vec(1:4)
      END IF
    ELSE IF (nDim == 2 .AND. nNode == 8) THEN
      CALL shape_quad8(xi(1), xi(2), N_std, dNdxi_vec, dNdeta_vec)
      IF (PRESENT(dNdxi)) THEN
        dNdxi(1:8, 1) = dNdxi_vec(1:8)
        dNdxi(1:8, 2) = dNdeta_vec(1:8)
      END IF
    ELSE IF (nDim == 3 .AND. nNode == 8) THEN
      CALL shape_hex8(xi(1), xi(2), xi(3), N_std, dNdxi_vec, dNdeta_vec, dNdzeta_vec)
      IF (PRESENT(dNdxi)) THEN
        dNdxi(1:8, 1) = dNdxi_vec(1:8)
        dNdxi(1:8, 2) = dNdeta_vec(1:8)
        dNdxi(1:8, 3) = dNdzeta_vec(1:8)
      END IF
    ELSE
      N_std = 1.0_wp / REAL(nNode, wp)
      IF (PRESENT(dNdxi)) dNdxi(1:nNode, 1:nDim) = 0.0_wp
    END IF

    N = N_std
    status%status_code = IF_STATUS_OK
900 CONTINUE
    IF (N_std_id >= 0) CALL UF_Mem_FreeReal1D(N_std_id, st)
    RETURN
  END SUBROUTINE UF_ComputeInfiniteShapeFunctions

  !=============================================================================
  ! KERNEL: B matrix
  !=============================================================================
  SUBROUTINE UF_ComputeBMatrix_Infinite2D(coords, N, dNdxi, detJ, B, params, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    REAL(wp), INTENT(IN) :: N(:)
    REAL(wp), INTENT(IN) :: dNdxi(:,:)
    REAL(wp), INTENT(IN) :: detJ
    REAL(wp), INTENT(OUT) :: B(:,:)
    TYPE(InfiniteElemParams), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, i
    INTEGER(i4) :: dNdx_id
    REAL(wp), POINTER :: dNdx(:,:)
    REAL(wp) :: invJ(2, 2)
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    dNdx_id = -1
    nNode = SIZE(N)

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nNode, 2, 'Inf_dNdx_2D', dNdx, dNdx_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      GOTO 900
    END IF

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      invJ(1, 1) = 1.0_wp / detJ
      invJ(2, 2) = 1.0_wp / detJ
      invJ(1, 2) = 0.0_wp
      invJ(2, 1) = 0.0_wp
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))
    ELSE
      dNdx = 0.0_wp
    END IF

    B = 0.0_wp
    DO i = 1, nNode
      B(1, 2*(i-1)+1) = dNdx(i, 1)
      B(2, 2*(i-1)+2) = dNdx(i, 2)
      B(3, 2*(i-1)+1) = dNdx(i, 2)
      B(3, 2*(i-1)+2) = dNdx(i, 1)
    END DO

    status%status_code = IF_STATUS_OK
900 CONTINUE
    IF (dNdx_id >= 0) CALL UF_Mem_FreeReal2D(dNdx_id, st)
    RETURN
  END SUBROUTINE UF_ComputeBMatrix_Infinite2D

  SUBROUTINE UF_ComputeBMatrix_Infinite3D(coords, N, dNdxi, detJ, B, params, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    REAL(wp), INTENT(IN) :: N(:)
    REAL(wp), INTENT(IN) :: dNdxi(:,:)
    REAL(wp), INTENT(IN) :: detJ
    REAL(wp), INTENT(OUT) :: B(:,:)
    TYPE(InfiniteElemParams), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, i
    INTEGER(i4) :: dNdx_id
    REAL(wp), POINTER :: dNdx(:,:)
    REAL(wp) :: invJ(3, 3)
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    dNdx_id = -1
    nNode = SIZE(N)

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nNode, 3, 'Inf_dNdx_3D', dNdx, dNdx_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      GOTO 900
    END IF

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      invJ(1, 1) = 1.0_wp / detJ
      invJ(2, 2) = 1.0_wp / detJ
      invJ(3, 3) = 1.0_wp / detJ
      invJ(1, 2) = 0.0_wp
      invJ(1, 3) = 0.0_wp
      invJ(2, 1) = 0.0_wp
      invJ(2, 3) = 0.0_wp
      invJ(3, 1) = 0.0_wp
      invJ(3, 2) = 0.0_wp
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))
    ELSE
      dNdx = 0.0_wp
    END IF

    B = 0.0_wp
    DO i = 1, nNode
      B(1, 3*(i-1)+1) = dNdx(i, 1)
      B(2, 3*(i-1)+2) = dNdx(i, 2)
      B(3, 3*(i-1)+3) = dNdx(i, 3)
      B(4, 3*(i-1)+2) = dNdx(i, 3)
      B(4, 3*(i-1)+3) = dNdx(i, 2)
      B(5, 3*(i-1)+1) = dNdx(i, 3)
      B(5, 3*(i-1)+3) = dNdx(i, 1)
      B(6, 3*(i-1)+1) = dNdx(i, 2)
      B(6, 3*(i-1)+2) = dNdx(i, 1)
    END DO

    status%status_code = IF_STATUS_OK
900 CONTINUE
    IF (dNdx_id >= 0) CALL UF_Mem_FreeReal2D(dNdx_id, st)
    RETURN
  END SUBROUTINE UF_ComputeBMatrix_Infinite3D

  !=============================================================================
  ! INFINITE2D: 2D infinite element (CINPE4, CINPS4, CINAX4, ACIN2D2)
  !=============================================================================
  SUBROUTINE UF_Elem_Infinite2D_Calc(ElemType, Formul, Ctx, state_in, &
                                     Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDOF, nInt, ip
    INTEGER(i4) :: Ke_loc_id, Re_loc_id, B_id, D_id, N_id, dNdxi_id, gaussCoords_id, weights_id
    REAL(wp) :: xi(2), weight, detJ, dV
    REAL(wp), POINTER :: gaussCoords(:,:), weights(:)
    REAL(wp), POINTER :: N(:), dNdxi(:,:)
    REAL(wp), POINTER :: B(:,:), D(:,:)
    REAL(wp), POINTER :: Ke_loc(:,:), Re_loc(:)
    REAL(wp) :: x_mapped(2), decay
    TYPE(InfiniteElemParams) :: inf_params
    TYPE(ErrorStatusType) :: status
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(flags%status)
    Ke_loc_id = -1
    Re_loc_id = -1
    B_id = -1
    D_id = -1
    N_id = -1
    dNdxi_id = -1
    gaussCoords_id = -1
    weights_id = -1
    nNode = ElemType%numNodes
    nDOF = nNode * 2_i4

    IF (nNode /= 4 .AND. nNode /= 8) THEN
      flags%failed = .TRUE.
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Infinite2D_Calc: requires 4 or 8 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Infinite2D_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    CALL PH_Elem_Infinite_GetDecayParams(Mat, inf_params)

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nDOF, nDOF, 'Inf_Ke_2D', Ke_loc, Ke_loc_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nDOF, 'Inf_Re_2D', Re_loc, Re_loc_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 3, nDOF, 'Inf_B_2D', B, B_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 3, 3, 'Inf_D_2D', D, D_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nNode, 'Inf_N_2D', N, N_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nNode, 2, 'Inf_dNdxi_2D', dNdxi, dNdxi_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    CALL UF_BuildIsotropic2D_PlaneStrain_Local(Mat, D)

    nInt = 4
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 2, nInt, 'Inf_gauss_2D', gaussCoords, gaussCoords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nInt, 'Inf_w_2D', weights, weights_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL gauss_quad(2, gaussCoords(1,:), gaussCoords(2,:), weights)

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, nInt)

    DO ip = 1, nInt
      xi(1) = gaussCoords(1, ip)
      xi(2) = gaussCoords(2, ip)
      weight = weights(ip)

      decay = UF_ComputeDecayFunction(xi, inf_params)

      CALL UF_ComputeInfiniteMapping(Ctx%coords_ref, xi, x_mapped, detJ, inf_params, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      CALL UF_ComputeInfiniteShapeFunctions(Ctx%coords_ref, xi, N, status, dNdxi)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      CALL UF_ComputeBMatrix_Infinite2D(Ctx%coords_ref, N, dNdxi, detJ, B, inf_params, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      dV = detJ * weight * decay
      Ke_loc(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF) + &
        MATMUL(MATMUL(TRANSPOSE(B), D), B) * dV
    END DO

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    CALL init_error_status(flags%status, IF_STATUS_OK)
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

900 CONTINUE
    IF (weights_id >= 0) CALL UF_Mem_FreeReal1D(weights_id, st)
    IF (gaussCoords_id >= 0) CALL UF_Mem_FreeReal2D(gaussCoords_id, st)
    IF (dNdxi_id >= 0) CALL UF_Mem_FreeReal2D(dNdxi_id, st)
    IF (N_id >= 0) CALL UF_Mem_FreeReal1D(N_id, st)
    IF (D_id >= 0) CALL UF_Mem_FreeReal2D(D_id, st)
    IF (B_id >= 0) CALL UF_Mem_FreeReal2D(B_id, st)
    IF (Re_loc_id >= 0) CALL UF_Mem_FreeReal1D(Re_loc_id, st)
    IF (Ke_loc_id >= 0) CALL UF_Mem_FreeReal2D(Ke_loc_id, st)
    IF (flags%failed) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF
    RETURN
  END SUBROUTINE UF_Elem_Infinite2D_Calc

  !=============================================================================
  ! INFINITE3D: 3D infinite element (CIN3D8, ACIN3D4)
  !=============================================================================
  SUBROUTINE UF_Elem_Infinite3D_Calc(ElemType, Formul, Ctx, state_in, &
                                     Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDOF, nInt, ip
    INTEGER(i4) :: Ke_loc_id, Re_loc_id, B_id, D_id, N_id, dNdxi_id, gaussCoords_id, weights_id
    REAL(wp) :: xi(3), weight, detJ, dV
    REAL(wp), POINTER :: gaussCoords(:,:), weights(:)
    REAL(wp), POINTER :: N(:), dNdxi(:,:)
    REAL(wp), POINTER :: B(:,:), D(:,:)
    REAL(wp), POINTER :: Ke_loc(:,:), Re_loc(:)
    REAL(wp) :: x_mapped(3), decay
    TYPE(InfiniteElemParams) :: inf_params
    TYPE(ErrorStatusType) :: status
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(flags%status)
    Ke_loc_id = -1
    Re_loc_id = -1
    B_id = -1
    D_id = -1
    N_id = -1
    dNdxi_id = -1
    gaussCoords_id = -1
    weights_id = -1
    nNode = ElemType%numNodes
    nDOF = nNode * 3_i4

    IF (nNode /= 8) THEN
      flags%failed = .TRUE.
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Infinite3D_Calc: requires 8 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Infinite3D_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    CALL PH_Elem_Infinite_GetDecayParams(Mat, inf_params)

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nDOF, nDOF, 'Inf_Ke_3D', Ke_loc, Ke_loc_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nDOF, 'Inf_Re_3D', Re_loc, Re_loc_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 6, nDOF, 'Inf_B_3D', B, B_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 6, 6, 'Inf_D_3D', D, D_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nNode, 'Inf_N_3D', N, N_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nNode, 3, 'Inf_dNdxi_3D', dNdxi, dNdxi_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    CALL UF_BuildIsotropic3D_Local(Mat, D)

    nInt = 8
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, 3, nInt, 'Inf_gauss_3D', gaussCoords, gaussCoords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL UF_Mem_AllocReal1D(MEM_DOMAIN_ELEM, 0_i4, nInt, 'Inf_w_3D', weights, weights_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN; flags%failed = .TRUE.; flags%status = st; GOTO 900; END IF
    CALL gauss_hexahedron(2, gaussCoords(1,:), gaussCoords(2,:), gaussCoords(3,:), weights)

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, nInt)

    DO ip = 1, nInt
      xi(1) = gaussCoords(1, ip)
      xi(2) = gaussCoords(2, ip)
      xi(3) = gaussCoords(3, ip)
      weight = weights(ip)

      decay = UF_ComputeDecayFunction(xi, inf_params)

      CALL UF_ComputeInfiniteMapping(Ctx%coords_ref, xi, x_mapped, detJ, inf_params, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      CALL UF_ComputeInfiniteShapeFunctions(Ctx%coords_ref, xi, N, status, dNdxi)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      CALL UF_ComputeBMatrix_Infinite3D(Ctx%coords_ref, N, dNdxi, detJ, B, inf_params, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        flags%failed = .TRUE.
        flags%status = status
        GOTO 900
      END IF

      dV = detJ * weight * decay
      Ke_loc(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF) + &
        MATMUL(MATMUL(TRANSPOSE(B), D), B) * dV
    END DO

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    CALL init_error_status(flags%status, IF_STATUS_OK)
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

900 CONTINUE
    IF (weights_id >= 0) CALL UF_Mem_FreeReal1D(weights_id, st)
    IF (gaussCoords_id >= 0) CALL UF_Mem_FreeReal2D(gaussCoords_id, st)
    IF (dNdxi_id >= 0) CALL UF_Mem_FreeReal2D(dNdxi_id, st)
    IF (N_id >= 0) CALL UF_Mem_FreeReal1D(N_id, st)
    IF (D_id >= 0) CALL UF_Mem_FreeReal2D(D_id, st)
    IF (B_id >= 0) CALL UF_Mem_FreeReal2D(B_id, st)
    IF (Re_loc_id >= 0) CALL UF_Mem_FreeReal1D(Re_loc_id, st)
    IF (Ke_loc_id >= 0) CALL UF_Mem_FreeReal2D(Ke_loc_id, st)
    IF (flags%failed) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF
    RETURN
  END SUBROUTINE UF_Elem_Infinite3D_Calc

  SUBROUTINE PH_Elem_Infinite_Material_Update_Decay_Routed(rt_ctx, mat_slot, &
                                                           decay_rate, decay_type, &
                                                           decay_power, reference_dista, &
                                                           status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_InfiniteDecay

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: decay_rate
    INTEGER(i4),               INTENT(OUT)   :: decay_type
    REAL(wp),                  INTENT(OUT)   :: decay_power
    REAL(wp),                  INTENT(OUT)   :: reference_dista
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_InfiniteDecay(rt_ctx, mat_slot, decay_rate, decay_type, &
                                        decay_power, reference_dista, status)
  END SUBROUTINE PH_Elem_Infinite_Material_Update_Decay_Routed

END MODULE PH_Elem_Infinite

