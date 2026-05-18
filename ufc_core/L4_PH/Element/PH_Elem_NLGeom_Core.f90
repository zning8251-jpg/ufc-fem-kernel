!===============================================================================
! MODULE: PH_Elem_NLGeom_Core
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Core
! BRIEF:  Unified TL/UL geometric nonlinearity framework (deformation gradient,
!         strain measures, stress transforms, geometric stiffness).
! **W2**：**TL/UL** 几何非线性内核；与 **`PH_Elem_Core`** 强耦合，输入几何/位移取自槽侧 **`PH_Elem_*`** 上下文。
!===============================================================================
MODULE PH_Elem_NLGeom_Core
  !! 几何非线性核心算法 - TL/UL统一框架
  !! 提炼自 PH_Elem_Nlgeom.f90 + PH_NLGeomEval.f90
  !! 设计文档: DESIGN_Elem_Advanced_3D.md §4

  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !--- SECTION 2: MODULE CONSTANTS --- TL/UL framework flags
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_NLGEOM_NONE = 0_i4  ! small deformation
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_NLGEOM_TL   = 1_i4  ! Total Lagrangian
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_NLGEOM_UL   = 2_i4  ! Updated Lagrangian
  ! Legacy aliases removed — all references migrated to PH_ELEM_NLGEOM_*

  REAL(wp), PARAMETER :: PH_ELEM_TOL_DET      = 1.0E-12_wp
  REAL(wp), PARAMETER :: PH_ELEM_TOL_SINGULAR = 1.0E-12_wp

  !===========================================================================
  ! PUBLIC INTERFACES
  !===========================================================================
  PUBLIC :: PH_NLGeom_State           ! TYPE: 几何非线性状态
  PUBLIC :: PH_NLGeom_DeformGrad      ! 变形梯度 F = I + du/dX
  PUBLIC :: PH_NLGeom_GreenLagrange   ! E = 0.5(F^TF - I)
  PUBLIC :: PH_NLGeom_Almansi         ! e = 0.5(I - b⁻¹) (精确化)
  PUBLIC :: PH_NLGeom_StressPush      ! S → σ (PK2 → Cauchy)
  PUBLIC :: PH_NLGeom_StressPull      ! σ → S (Cauchy → PK2)
  PUBLIC :: PH_NLGeom_GeoStiff        ! 几何刚度矩阵 Kg
  PUBLIC :: PH_NLGeom_SelectFrame     ! TL/UL框架选择 (补齐)
  PUBLIC :: PH_NLGeom_TangentPush     ! C → c (物质→空间切线推前)

  !---------------------------------------------------------------------------
  ! AUXILIARY STATE TYPES (Depth 2 cap — nested auxiliary types)
  !---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_NLGeom_Cfg_Frame
    INTEGER(i4) :: frame = PH_ELEM_NLGEOM_TL  ! TL/UL/NONE current frame
    LOGICAL     :: large_strain = .TRUE.       ! 大应变标志
  END TYPE PH_NLGeom_Cfg_Frame

  TYPE, PUBLIC :: PH_NLGeom_Itr_Kinematics
    REAL(wp) :: F(3,3)    = 0.0_wp   ! 变形梯度
    REAL(wp) :: Finv(3,3) = 0.0_wp   ! F的逆
    REAL(wp) :: detF      = 1.0_wp   ! det(F) = J
    REAL(wp) :: C_rg(3,3) = 0.0_wp   ! Right Cauchy-Green C = F^TF
    REAL(wp) :: b_lg(3,3) = 0.0_wp   ! Left Cauchy-Green b = FF^T
  END TYPE PH_NLGeom_Itr_Kinematics

  TYPE, PUBLIC :: PH_NLGeom_Itr_Strain
    REAL(wp) :: E_gl(6)  = 0.0_wp   ! Green-Lagrange strain (Voigt)
    REAL(wp) :: e_alm(6) = 0.0_wp   ! Almansi strain (Voigt)
  END TYPE PH_NLGeom_Itr_Strain

  !---------------------------------------------------------------------------
  ! TYPE: PH_NLGeom_State
  ! KIND: State
  ! DESC: Geometric nonlinearity state — deformation gradient, strain measures.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_NLGeom_State
    TYPE(PH_NLGeom_Cfg_Frame)      :: cfg_frame
    TYPE(PH_NLGeom_Itr_Kinematics) :: itr_kinematics
    TYPE(PH_NLGeom_Itr_Strain)     :: itr_strain
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_NLGeom_State

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_DeformGrad
  ! PHASE:      P2
  ! PURPOSE:    Compute deformation gradient F = I + du/dX, det(F), F^{-1}.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_DeformGrad(state, coords_ref, coords_cur, &
                                   dN_dX, n_nodes, status)
    TYPE(PH_NLGeom_State), INTENT(INOUT) :: state          ! [INOUT] 几何状态
    REAL(wp),              INTENT(IN)    :: coords_ref(:,:) ! [IN] 参考坐标 [3,n_nodes]
    REAL(wp),              INTENT(IN)    :: coords_cur(:,:) ! [IN] 当前坐标 [3,n_nodes]
    REAL(wp),              INTENT(IN)    :: dN_dX(:,:)      ! [IN] 形函数导数 [n_nodes,3]
    INTEGER(i4),           INTENT(IN)    :: n_nodes         ! [IN] 节点数
    TYPE(ErrorStatusType), INTENT(OUT)   :: status           ! [OUT] 错误状态

    INTEGER(i4) :: i, j, node
    REAL(wp)    :: dudX(3,3)
    REAL(wp)    :: F_loc(3,3)

    CALL init_error_status(status)

    ! Step 1: F = I (参考 PH_Elem_Nlgeom.f90 行107-111)
    state%itr_kinematics%F = 0.0_wp
    state%itr_kinematics%F(1,1) = 1.0_wp
    state%itr_kinematics%F(2,2) = 1.0_wp
    state%itr_kinematics%F(3,3) = 1.0_wp

    ! Step 2: du/dX = Σ_node dN/dX ⊗ u_node (参考行113-123)
    dudX = 0.0_wp
    DO node = 1, n_nodes
      DO i = 1, 3
        DO j = 1, 3
          dudX(i,j) = dudX(i,j) + dN_dX(node, j) * &
                      (coords_cur(i, node) - coords_ref(i, node))
        END DO
      END DO
    END DO

    ! Step 3: F = I + du/dX (参考行125-130)
    state%itr_kinematics%F = state%itr_kinematics%F + dudX

    ! Step 4: det(F) (参考行132-139)
    ! F_loc: 缓存以避免嵌套长字段名导致的行截断 (>132 col)，非循环热路径优化
    F_loc = state%itr_kinematics%F
    state%itr_kinematics%detF = F_loc(1,1)*(F_loc(2,2)*F_loc(3,3) - F_loc(2,3)*F_loc(3,2)) &
               - F_loc(1,2)*(F_loc(2,1)*F_loc(3,3) - F_loc(2,3)*F_loc(3,1)) &
               + F_loc(1,3)*(F_loc(2,1)*F_loc(3,2) - F_loc(2,2)*F_loc(3,1))

    ! Step 5: 正性检查 (参考行141-145, PH_NLGeomEval.f90 行880-906)
    IF (state%itr_kinematics%detF <= PH_ELEM_TOL_DET) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_NLGeom_DeformGrad] detF non-positive or below tolerance"
      RETURN
    END IF

    ! Step 6: F⁻¹ (参考 PH_Elem_Nlgeom.f90 行147-151, 行386-433)
    CALL Invert3x3(state%itr_kinematics%F, state%itr_kinematics%Finv, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Step 7: C = F^T·F 和 b = F·F^T
    state%itr_kinematics%C_rg = MATMUL(TRANSPOSE(state%itr_kinematics%F), state%itr_kinematics%F)
    state%itr_kinematics%b_lg = MATMUL(state%itr_kinematics%F, TRANSPOSE(state%itr_kinematics%F))

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_DeformGrad

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_GreenLagrange
  ! PHASE:      P2
  ! PURPOSE:    Green-Lagrange strain E = 0.5*(C - I).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_GreenLagrange(state, status)
    TYPE(PH_NLGeom_State), INTENT(INOUT) :: state   ! [INOUT] 几何状态
    TYPE(ErrorStatusType), INTENT(OUT)   :: status   ! [OUT] 错误状态

    REAL(wp) :: E_tensor(3,3)
    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    ! E = 0.5*(C - I) (参考行174-184)
    E_tensor = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        E_tensor(i,j) = 0.5_wp * state%itr_kinematics%C_rg(i,j)
      END DO
      E_tensor(i,i) = E_tensor(i,i) - 0.5_wp
    END DO

    ! Voigt记法: {E11, E22, E33, 2E12, 2E13, 2E23} (§4.1.3)
    state%itr_strain%E_gl(1) = E_tensor(1,1)
    state%itr_strain%E_gl(2) = E_tensor(2,2)
    state%itr_strain%E_gl(3) = E_tensor(3,3)
    state%itr_strain%E_gl(4) = 2.0_wp * E_tensor(1,2)  ! 工程应变 2ε₁₂
    state%itr_strain%E_gl(5) = 2.0_wp * E_tensor(1,3)  ! 2ε₁₃
    state%itr_strain%E_gl(6) = 2.0_wp * E_tensor(2,3)  ! 2ε₂₃

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_GreenLagrange

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_Almansi
  ! PHASE:      P2
  ! PURPOSE:    Almansi strain e = 0.5*(I - b^{-1}) (exact formulation).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_Almansi(state, status)
    TYPE(PH_NLGeom_State), INTENT(INOUT) :: state   ! [INOUT] 几何状态
    TYPE(ErrorStatusType), INTENT(OUT)   :: status   ! [OUT] 错误状态

    REAL(wp) :: b_inv(3,3)     ! b⁻¹ = F⁻ᵀ · F⁻¹
    REAL(wp) :: e_tensor(3,3)
    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    ! Step 1: b⁻¹ = F⁻ᵀ · F⁻¹ (精确公式, 补齐§4.2.2)
    !         注: 现有PH_Elem_Nlgeom.f90行213-223使用 b = F·F^T (近似)
    !         此处使用精确的 b⁻¹
    b_inv = MATMUL(TRANSPOSE(state%itr_kinematics%Finv), state%itr_kinematics%Finv)

    ! Step 2: e = 0.5*(I - b⁻¹) (§4.2.2 精确公式)
    e_tensor = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        e_tensor(i,j) = -0.5_wp * b_inv(i,j)
      END DO
      e_tensor(i,i) = e_tensor(i,i) + 0.5_wp
    END DO

    ! Voigt记法: {e11, e22, e33, 2e12, 2e13, 2e23}
    state%itr_strain%e_alm(1) = e_tensor(1,1)
    state%itr_strain%e_alm(2) = e_tensor(2,2)
    state%itr_strain%e_alm(3) = e_tensor(3,3)
    state%itr_strain%e_alm(4) = 2.0_wp * e_tensor(1,2)
    state%itr_strain%e_alm(5) = 2.0_wp * e_tensor(1,3)
    state%itr_strain%e_alm(6) = 2.0_wp * e_tensor(2,3)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_Almansi

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_StressPush
  ! PHASE:      P2
  ! PURPOSE:    PK2->Cauchy push-forward: sigma = (1/J) F S F^T.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_StressPush(state, S_voigt, sigma_voigt, status)
    TYPE(PH_NLGeom_State), INTENT(IN)    :: state        ! [IN]  几何状态(含F, detF)
    REAL(wp),              INTENT(IN)    :: S_voigt(6)   ! [IN]  PK2应力 Voigt
    REAL(wp),              INTENT(OUT)   :: sigma_voigt(6) ! [OUT] Cauchy应力 Voigt
    TYPE(ErrorStatusType), INTENT(OUT)   :: status        ! [OUT] 错误状态

    REAL(wp) :: S_tensor(3,3), sigma_tensor(3,3)
    REAL(wp) :: F_loc(3,3), invJ
    INTEGER(i4) :: i, j, k, l

    CALL init_error_status(status)

    ! Step 1: Voigt → 张量 (参考行306-307)
    CALL Voigt_to_Tensor(S_voigt, S_tensor)

    ! Cache nested fields for hot-path access
    IF (state%itr_kinematics%detF <= PH_ELEM_TOL_DET) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_NLGeom_StressPush] detF non-positive or too small"
      RETURN
    END IF
    F_loc = state%itr_kinematics%F
    invJ  = 1.0_wp / state%itr_kinematics%detF

    ! Step 2: σ = (1/J) F·S·F^T (参考行313-325, §4.3.3)
    sigma_tensor = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          DO l = 1, 3
            sigma_tensor(i,j) = sigma_tensor(i,j) + &
                                F_loc(i,k) * S_tensor(k,l) * F_loc(j,l)
          END DO
        END DO
        sigma_tensor(i,j) = sigma_tensor(i,j) * invJ
      END DO
    END DO

    ! Step 3: 张量 → Voigt (参考行328-329)
    CALL Tensor_to_Voigt(sigma_tensor, sigma_voigt)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_StressPush

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_StressPull
  ! PHASE:      P2
  ! PURPOSE:    Cauchy->PK2 pull-back: S = J F^{-1} sigma F^{-T}.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_StressPull(state, sigma_voigt, S_voigt, status)
    TYPE(PH_NLGeom_State), INTENT(IN)    :: state          ! [IN]  几何状态
    REAL(wp),              INTENT(IN)    :: sigma_voigt(6) ! [IN]  Cauchy应力 Voigt
    REAL(wp),              INTENT(OUT)   :: S_voigt(6)     ! [OUT] PK2应力 Voigt
    TYPE(ErrorStatusType), INTENT(OUT)   :: status          ! [OUT] 错误状态

    REAL(wp) :: S_tensor(3,3), sigma_tensor(3,3)
    REAL(wp) :: Finv_loc(3,3), detJ
    INTEGER(i4) :: i, j, k, l

    CALL init_error_status(status)

    ! Step 1: Voigt → 张量
    CALL Voigt_to_Tensor(sigma_voigt, sigma_tensor)

    ! Cache nested fields for hot-path access
    Finv_loc = state%itr_kinematics%Finv
    detJ     = state%itr_kinematics%detF

    ! Step 2: S = J · F⁻¹ · σ · F⁻ᵀ (参考行360-371, §4.3.3)
    S_tensor = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          DO l = 1, 3
            S_tensor(i,j) = S_tensor(i,j) + &
                            Finv_loc(i,k) * sigma_tensor(k,l) * Finv_loc(j,l)
          END DO
        END DO
        S_tensor(i,j) = S_tensor(i,j) * detJ
      END DO
    END DO

    ! Step 3: 张量 → Voigt
    CALL Tensor_to_Voigt(S_tensor, S_voigt)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_StressPull

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_GeoStiff
  ! PHASE:      P2
  ! PURPOSE:    Geometric stiffness Kg with full off-diagonal sigma terms.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_GeoStiff(sigma_voigt, dN_dx, n_nodes, w_detJ, Kg, status)
    REAL(wp),              INTENT(IN)    :: sigma_voigt(6) ! [IN]  应力 Voigt
    REAL(wp),              INTENT(IN)    :: dN_dx(:,:)     ! [IN]  dN/dx [n_nodes,3]
    INTEGER(i4),           INTENT(IN)    :: n_nodes        ! [IN]  节点数
    REAL(wp),              INTENT(IN)    :: w_detJ         ! [IN]  w * det(J)
    REAL(wp),              INTENT(INOUT) :: Kg(:,:)        ! [INOUT] 几何刚度 [ndof,ndof]
    TYPE(ErrorStatusType), INTENT(OUT)   :: status          ! [OUT] 错误状态

    INTEGER(i4) :: a, b, i, j
    REAL(wp)    :: sigma_tensor(3,3)
    REAL(wp)    :: val

    CALL init_error_status(status)

    ! Step 1: Voigt → 应力张量
    CALL Voigt_to_Tensor(sigma_voigt, sigma_tensor)

    ! Step 2: Kg(ia, jb) += dN_a/dx_k · σ_kl · dN_b/dx_l · δ_ij · w·detJ
    !         即对每对节点(a,b)和方向(i,j): 仅i=j有贡献
    !         Kg((a-1)*3+i, (b-1)*3+i) += Σ_k Σ_l dN_a/dx_k · σ_kl · dN_b/dx_l
    !
    ! 补齐: 完整off-diagonal σ项 (现有PH_NLGeomEval.f90行931-937仅对角)
    ! 设计文档§4.4.1: σ̃为9×9分块矩阵

    DO a = 1, n_nodes
      DO b = 1, n_nodes
        ! 计算标量: Σ_k Σ_l dN_a/dx_k · σ_kl · dN_b/dx_l
        val = 0.0_wp
        DO i = 1, 3
          DO j = 1, 3
            val = val + dN_dx(a, i) * sigma_tensor(i, j) * dN_dx(b, j)
          END DO
        END DO
        val = val * w_detJ

        ! 贡献到对角块: Kg(3(a-1)+d, 3(b-1)+d) for d=1,2,3
        DO i = 1, 3
          Kg((a-1)*3 + i, (b-1)*3 + i) = Kg((a-1)*3 + i, (b-1)*3 + i) + val
        END DO
      END DO
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_GeoStiff

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_SelectFrame
  ! PHASE:      P1
  ! PURPOSE:    TL/UL frame selection logic.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_SelectFrame(state, nlgeom_type, status)
    TYPE(PH_NLGeom_State), INTENT(INOUT) :: state         ! [INOUT] 几何状态
    INTEGER(i4),           INTENT(IN)    :: nlgeom_type   ! [IN]  PH_ELEM_NLGEOM_NONE/TL/UL
    TYPE(ErrorStatusType), INTENT(OUT)   :: status         ! [OUT] 错误状态

    CALL init_error_status(status)

    SELECT CASE (nlgeom_type)
    CASE (PH_ELEM_NLGEOM_NONE)
      ! 小变形: 不需几何非线性处理 (§4.3.2)
      state%cfg_frame%frame = PH_ELEM_NLGEOM_NONE
      state%cfg_frame%large_strain = .FALSE.

    CASE (PH_ELEM_NLGEOM_TL)
      ! Total Lagrangian (§4.3.2 IF nlgeom_type == PH_ELEM_NLGEOM_TL)
      ! 1. F = I + ∂u/∂X (参考构型形函数导数)
      ! 2. E = 0.5*(F^T·F - I)
      ! 3. Material: (S, C_mat) = Material_TL(E, state)
      ! 4. K_mat = ∫ B_NL^T · C_mat · B_NL dΩ₀
      ! 5. K_geo = ∫ G^T · S̃ · G dΩ₀
      state%cfg_frame%frame = PH_ELEM_NLGEOM_TL
      state%cfg_frame%large_strain = .TRUE.

    CASE (PH_ELEM_NLGEOM_UL)
      ! Updated Lagrangian (§4.3.2 ELSE IF nlgeom_type == PH_ELEM_NLGEOM_UL)
      ! 1. F = ∂x/∂X
      ! 2. 推送形函数导数: dN/dx = dN/dX · F⁻¹
      ! 3. e_alm 或 D_rate
      ! 4. Material: (σ, c_spatial) = Material_UL(D_rate, state)
      ! 5. K_mat = ∫ B_L^T · c · B_L dΩ_t
      ! 6. K_geo = ∫ G^T · σ̃ · G dΩ_t
      state%cfg_frame%frame = PH_ELEM_NLGEOM_UL
      state%cfg_frame%large_strain = .TRUE.

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_NLGeom_SelectFrame] Unknown nlgeom_type"
      RETURN
    END SELECT

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_SelectFrame

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_NLGeom_TangentPush
  ! PHASE:      P2
  ! PURPOSE:    Material tangent -> spatial tangent push-forward C -> c.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NLGeom_TangentPush(state, C_mat, c_spatial, status)
    TYPE(PH_NLGeom_State), INTENT(IN)    :: state         ! [IN]  几何状态
    REAL(wp),              INTENT(IN)    :: C_mat(6,6)    ! [IN]  物质切线 Voigt
    REAL(wp),              INTENT(OUT)   :: c_spatial(6,6) ! [OUT] 空间切线 Voigt
    TYPE(ErrorStatusType), INTENT(OUT)   :: status         ! [OUT] 错误状态

    ! Voigt index pairs: (1,1),(2,2),(3,3),(1,2),(1,3),(2,3)
    INTEGER(i4) :: voigt_i(6), voigt_j(6)
    INTEGER(i4) :: ab, cd, ii, jj, kk, ll
    INTEGER(i4) :: I_idx, J_idx, K_idx, L_idx
    REAL(wp)    :: C_tensor(3,3,3,3)
    REAL(wp)    :: c_spat_t(3,3,3,3)
    REAL(wp)    :: invJ
    REAL(wp)    :: sum_val
    REAL(wp)    :: F_loc(3,3)

    CALL init_error_status(status)

    ! Voigt mapping: index → (i,j)
    voigt_i = (/ 1, 2, 3, 1, 1, 2 /)
    voigt_j = (/ 1, 2, 3, 2, 3, 3 /)

    IF (state%itr_kinematics%detF <= PH_ELEM_TOL_DET) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_NLGeom_TangentPush] detF non-positive or too small"
      RETURN
    END IF
    invJ = 1.0_wp / state%itr_kinematics%detF
    F_loc = state%itr_kinematics%F

    ! Step 1: Voigt → 4阶张量 C_IJKL
    C_tensor = 0.0_wp
    DO ab = 1, 6
      DO cd = 1, 6
        ii = voigt_i(ab); jj = voigt_j(ab)
        kk = voigt_i(cd); ll = voigt_j(cd)
        C_tensor(ii,jj,kk,ll) = C_mat(ab,cd)
        C_tensor(jj,ii,kk,ll) = C_mat(ab,cd)  ! 小对称
        C_tensor(ii,jj,ll,kk) = C_mat(ab,cd)
        C_tensor(jj,ii,ll,kk) = C_mat(ab,cd)
      END DO
    END DO

    ! Step 2: 推前 c_ijkl = (1/J) F_iI F_jJ C_IJKL F_kK F_lL (§4.2.3)
    ! Adapted from PH_Elem_Nlgeom.f90:313-372 (应力推前逻辑, 扩展至4阶张量)
    ! 8重循环实现: O(3^8)=6561次乘法, 对3D问题可接受
    c_spat_t = 0.0_wp
    DO ii = 1, 3
      DO jj = 1, 3
        DO kk = 1, 3
          DO ll = 1, 3
            sum_val = 0.0_wp
            DO I_idx = 1, 3
              DO J_idx = 1, 3
                DO K_idx = 1, 3
                  DO L_idx = 1, 3
                    sum_val = sum_val + &
                      F_loc(ii, I_idx) * F_loc(jj, J_idx) * &
                      C_tensor(I_idx, J_idx, K_idx, L_idx) * &
                      F_loc(kk, K_idx) * F_loc(ll, L_idx)
                  END DO
                END DO
              END DO
            END DO
            c_spat_t(ii, jj, kk, ll) = invJ * sum_val
          END DO
        END DO
      END DO
    END DO

    ! Step 3: 4阶张量 → Voigt
    c_spatial = 0.0_wp
    DO ab = 1, 6
      DO cd = 1, 6
        c_spatial(ab,cd) = c_spat_t(voigt_i(ab), voigt_j(ab), &
                                     voigt_i(cd), voigt_j(cd))
      END DO
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_NLGeom_TangentPush

  !===========================================================================
  ! PRIVATE HELPERS
  !===========================================================================

  !---------------------------------------------------------------------------
  ! Invert3x3: 3×3矩阵求逆
  ! Reference: PH_Elem_Nlgeom.f90 行386-433
  !---------------------------------------------------------------------------
  SUBROUTINE Invert3x3(A, Ainv, status)
    REAL(wp),              INTENT(IN)    :: A(3,3)     ! [IN]  输入矩阵
    REAL(wp),              INTENT(OUT)   :: Ainv(3,3)  ! [OUT] 逆矩阵
    TYPE(ErrorStatusType), INTENT(OUT)   :: status      ! [OUT] 错误状态

    REAL(wp) :: detA, inv_det

    CALL init_error_status(status)

    detA = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) &
         - A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) &
         + A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))

    IF (ABS(detA) < PH_ELEM_TOL_SINGULAR) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[Invert3x3] Singular matrix"
      RETURN
    END IF

    inv_det = 1.0_wp / detA

    Ainv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) * inv_det
    Ainv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) * inv_det
    Ainv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) * inv_det
    Ainv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) * inv_det
    Ainv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) * inv_det
    Ainv(2,3) = (A(2,1)*A(1,3) - A(1,1)*A(2,3)) * inv_det
    Ainv(3,1) = (A(2,1)*A(3,2) - A(3,1)*A(2,2)) * inv_det
    Ainv(3,2) = (A(3,1)*A(1,2) - A(1,1)*A(3,2)) * inv_det
    Ainv(3,3) = (A(1,1)*A(2,2) - A(2,1)*A(1,2)) * inv_det

    status%status_code = IF_STATUS_OK

  END SUBROUTINE Invert3x3

  !---------------------------------------------------------------------------
  ! Voigt_to_Tensor: 6-component Voigt → 3×3 symmetric tensor
  ! Convention: {11, 22, 33, 12, 13, 23}
  !---------------------------------------------------------------------------
  SUBROUTINE Voigt_to_Tensor(v, T)
    REAL(wp), INTENT(IN)  :: v(6)     ! [IN]  Voigt vector
    REAL(wp), INTENT(OUT) :: T(3,3)   ! [OUT] Symmetric tensor

    T(1,1) = v(1);  T(2,2) = v(2);  T(3,3) = v(3)
    T(1,2) = v(4);  T(2,1) = v(4)
    T(1,3) = v(5);  T(3,1) = v(5)
    T(2,3) = v(6);  T(3,2) = v(6)

  END SUBROUTINE Voigt_to_Tensor

  !---------------------------------------------------------------------------
  ! Tensor_to_Voigt: 3×3 symmetric tensor → 6-component Voigt
  !---------------------------------------------------------------------------
  SUBROUTINE Tensor_to_Voigt(T, v)
    REAL(wp), INTENT(IN)  :: T(3,3)   ! [IN]  Symmetric tensor
    REAL(wp), INTENT(OUT) :: v(6)     ! [OUT] Voigt vector

    v(1) = T(1,1);  v(2) = T(2,2);  v(3) = T(3,3)
    v(4) = T(1,2);  v(5) = T(1,3);  v(6) = T(2,3)

  END SUBROUTINE Tensor_to_Voigt

END MODULE PH_Elem_NLGeom_Core
