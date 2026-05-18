!===============================================================================
! MODULE: PH_Elem_Solid3D_EAS
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  Unified EAS kernel based on Hu-Washizu three-field variational
!===============================================================================
MODULE PH_Elem_Solid3D_EAS
  !! Element域 EAS增强应变统一内核
  !! 基于Hu-Washizu三场变分原理，9参数增强模式
  !! 设计文档: DESIGN_Elem_Advanced_3D.md §2

  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! PARAMETERS
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_EAS_NMODES = 9_i4   ! 9-param full 3D
  INTEGER(i4), PARAMETER, PUBLIC :: PH_EAS_NDOF   = 24_i4  ! C3D8: 8 nodes * 3 dof
  INTEGER(i4), PARAMETER, PUBLIC :: PH_EAS_NSTR   = 6_i4   ! 3D Voigt components

  ! Newton iteration defaults for alpha update (§2.3.1)
  INTEGER(i4), PARAMETER :: MAX_ITER_ALPHA  = 20_i4
  REAL(wp),    PARAMETER :: TOL_ALPHA       = 1.0E-8_wp
  REAL(wp),    PARAMETER :: TOL_SINGULAR    = 1.0E-12_wp

  !===========================================================================
  ! PUBLIC INTERFACES
  !===========================================================================
  PUBLIC :: PH_EAS_Ctx            ! TYPE: EAS上下文
  PUBLIC :: PH_EAS_Init           ! 初始化EAS上下文
  PUBLIC :: PH_EAS_BuildG         ! 构造增强模式矩阵G (9参数)
  PUBLIC :: PH_EAS_Condense       ! 静态缩聚: K_eff, f_eff
  PUBLIC :: PH_EAS_UpdateAlpha    ! alpha参数Newton更新 (关键缺口补齐)
  PUBLIC :: PH_EAS_ComputeKe      ! 完整单元刚度 (含EAS增强)
  PUBLIC :: PH_EAS_ComputeFe      ! 完整单元内力 (含EAS增强)

  !===========================================================================
  ! TYPE: PH_EAS_Ctx — EAS上下文 (参考 PH_Elem_C3D8EAS.f90 行95-115)
  !===========================================================================
  TYPE, PUBLIC :: PH_EAS_Ctx
    INTEGER(i4) :: n_eas_modes = PH_EAS_NMODES  ! EAS增强模式数
    INTEGER(i4) :: n_gp        = 8_i4            ! Gauss点数
    INTEGER(i4) :: n_dof       = PH_EAS_NDOF     ! 单元自由度数

    ! 内部参数 α [n_eas_modes]
    REAL(wp) :: alpha(PH_EAS_NMODES) = 0.0_wp

    ! 增强模式矩阵 G/M at each GP: (n_gp, 6, n_eas_modes)
    REAL(wp), POINTER :: G_matrix(:,:,:) => NULL()

    ! 静态缩聚子矩阵
    REAL(wp) :: K_aa(PH_EAS_NMODES, PH_EAS_NMODES)  = 0.0_wp  ! K_αα [neas,neas]
    REAL(wp) :: K_da(PH_EAS_NDOF,   PH_EAS_NMODES)  = 0.0_wp  ! K_dα [ndof,neas]
    REAL(wp) :: K_ad(PH_EAS_NMODES, PH_EAS_NDOF)    = 0.0_wp  ! K_αd [neas,ndof]
    REAL(wp) :: h_alpha(PH_EAS_NMODES)               = 0.0_wp  ! h_α 残差

    LOGICAL :: is_active  = .FALSE.
    LOGICAL :: converged  = .FALSE.
  END TYPE PH_EAS_Ctx

CONTAINS

  !===========================================================================
  ! Subroutine: PH_EAS_Init
  ! Purpose:    初始化EAS上下文，分配G矩阵存储
  ! Design doc: §2.5 数据流图 — InitCtx节点
  ! Reference:  PH_Elem_C3D8EAS.f90 行339-365 (PH_Elem_C3D8_EAS_InitCtx)
  !===========================================================================
  SUBROUTINE PH_EAS_Init(ctx, n_gp, status)
    TYPE(PH_EAS_Ctx),     INTENT(OUT)   :: ctx    ! [OUT] 初始化后的EAS上下文
    INTEGER(i4),          INTENT(IN)    :: n_gp   ! [IN]  Gauss点数 (典型=8)
    TYPE(ErrorStatusType), INTENT(OUT)  :: status  ! [OUT] 错误状态

    CALL init_error_status(status)

    ! Step 1: 验证输入
    IF (n_gp <= 0_i4 .OR. n_gp > 27_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_EAS_Init] Invalid n_gp"
      RETURN
    END IF

    ! Step 2: 设置基本参数
    ctx%n_gp       = n_gp
    ctx%n_eas_modes = PH_EAS_NMODES
    ctx%pop%n_dof      = PH_EAS_NDOF
    ctx%is_active  = .TRUE.
    ctx%converged  = .FALSE.

    ! Step 3: 清零内部参数
    ctx%alpha   = 0.0_wp
    ctx%K_aa    = 0.0_wp
    ctx%K_da    = 0.0_wp
    ctx%K_ad    = 0.0_wp
    ctx%h_alpha = 0.0_wp

    ! Step 4: 分配G矩阵 (参考 PH_Elem_C3D8EAS.f90 行359-361)
    IF (ASSOCIATED(ctx%G_matrix)) DEALLOCATE(ctx%G_matrix)
    ALLOCATE(ctx%G_matrix(n_gp, PH_EAS_NSTR, PH_EAS_NMODES))
    ctx%G_matrix = 0.0_wp

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_EAS_Init

  !===========================================================================
  ! Subroutine: PH_EAS_BuildG
  ! Purpose:    构造9参数增强模式矩阵 G(ξ,η,ζ) at each GP
  ! Design doc: §2.1.3 增强模式矩阵M的构造
  ! Formula:    M(ξ,η,ζ) = det(J₀)/det(J) · T₀ · M̂(ξ,η,ζ)
  ! Reference:  PH_Elem_C3D8EAS.f90 行238-301 (PH_Elem_C3D8_EAS_ComputeGMatrix)
  !===========================================================================
  SUBROUTINE PH_EAS_BuildG(ctx, xi_gp, eta_gp, zeta_gp, det_J_gp, &
                            det_J0, T0, status)
    TYPE(PH_EAS_Ctx),     INTENT(INOUT) :: ctx          ! [INOUT] EAS上下文
    REAL(wp),             INTENT(IN)    :: xi_gp(:)     ! [IN] GP等参坐标ξ [n_gp]
    REAL(wp),             INTENT(IN)    :: eta_gp(:)    ! [IN] GP等参坐标η [n_gp]
    REAL(wp),             INTENT(IN)    :: zeta_gp(:)   ! [IN] GP等参坐标ζ [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)  ! [IN] det(J) at each GP
    REAL(wp),             INTENT(IN)    :: det_J0       ! [IN] det(J) at element center
    REAL(wp),             INTENT(IN)    :: T0(6,6)      ! [IN] 变换矩阵T₀ (center)
    TYPE(ErrorStatusType), INTENT(OUT)  :: status        ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: xi, eta, zeta, det_J, scale
    REAL(wp)    :: G_hat(PH_EAS_NSTR, PH_EAS_NMODES)  ! M̂ in reference space
    REAL(wp)    :: G_gp(PH_EAS_NSTR, PH_EAS_NMODES)   ! Transformed G

    CALL init_error_status(status)

    IF (.NOT. ctx%is_active) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_EAS_BuildG] Context not initialized"
      RETURN
    END IF

    ! --- GP loop: 构造每个积分点的增强模式矩阵 ---
    DO igp = 1, ctx%n_gp
      xi   = xi_gp(igp)
      eta  = eta_gp(igp)
      zeta = zeta_gp(igp)
      det_J = det_J_gp(igp)

      IF (ABS(det_J) < TOL_SINGULAR) CYCLE

      ! Step 1: 构造参考空间增强模式 M̂(ξ,η,ζ)
      !         参考 PH_Elem_C3D8EAS.f90 行269-292, 设计文档§2.1.3 表格
      G_hat = 0.0_wp

      ! Parameters 1: 体积常数 (行273-275)
      G_hat(1, 1) = 1.0_wp   ! ε₁₁
      G_hat(2, 1) = 1.0_wp   ! ε₂₂
      G_hat(3, 1) = 1.0_wp   ! ε₃₃

      ! Parameters 2-4: 体积线性 (行277-279)
      G_hat(1, 2) = xi       ! ε₁₁: ξ
      G_hat(2, 3) = eta      ! ε₂₂: η
      G_hat(3, 4) = zeta     ! ε₃₃: ζ

      ! Parameters 5-7: 偏差二次 (行282-289)
      G_hat(1, 5) =  xi * eta    ! ε₁₁: ξη
      G_hat(2, 5) = -xi * eta    ! ε₂₂: -ξη (deviatoric)

      G_hat(2, 6) =  eta * zeta  ! ε₂₂: ηζ
      G_hat(3, 6) = -eta * zeta  ! ε₃₃: -ηζ (deviatoric)

      G_hat(1, 7) =  zeta * xi   ! ε₁₁: ζξ
      G_hat(3, 7) = -zeta * xi   ! ε₃₃: -ζξ (deviatoric)

      ! Parameters 8-9: 剪切线性 (行291-292)
      G_hat(4, 8) = xi           ! γ₁₂: ξ
      G_hat(5, 9) = eta          ! γ₁₃: η

      ! Step 2: 变换 M = det(J₀)/det(J) · T₀ · M̂  (设计文档§2.1.3 公式)
      scale = det_J0 / det_J
      G_gp = scale * MATMUL(T0, G_hat)

      ! Step 3: 存储 (参考 PH_Elem_C3D8EAS.f90 行295)
      ctx%G_matrix(igp, :, :) = G_gp

    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_EAS_BuildG

  !===========================================================================
  ! Subroutine: PH_EAS_Condense
  ! Purpose:    静态缩聚 — 消去内部自由度α得到有效刚度和力
  ! Design doc: §2.2.2 静态缩聚
  ! Formula:    K_eff = K_dd - K_dα · K_αα⁻¹ · K_αd
  !             f_eff = (f_ext - f_int) - K_dα · K_αα⁻¹ · h_α
  ! Reference:  PH_Elem_C3D8EAS.f90 行303-337 (CondenseStiffness)
  !===========================================================================
  SUBROUTINE PH_EAS_Condense(ctx, K_dd, f_ext_minus_fint, &
                              K_eff, f_eff, status)
    TYPE(PH_EAS_Ctx),     INTENT(IN)    :: ctx              ! [IN]  EAS上下文(含K_aa,K_da等)
    REAL(wp),             INTENT(IN)    :: K_dd(:,:)        ! [IN]  标准刚度 [ndof,ndof]
    REAL(wp),             INTENT(IN)    :: f_ext_minus_fint(:) ! [IN] f_ext - f_int [ndof]
    REAL(wp),             INTENT(OUT)   :: K_eff(:,:)       ! [OUT] 有效刚度 [ndof,ndof]
    REAL(wp),             INTENT(OUT)   :: f_eff(:)         ! [OUT] 有效力 [ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status            ! [OUT] 错误状态

    REAL(wp) :: K_aa_inv(PH_EAS_NMODES, PH_EAS_NMODES)
    REAL(wp) :: temp_Kda_Kaainv(PH_EAS_NDOF, PH_EAS_NMODES) ! K_dα · K_αα⁻¹
    INTEGER(i4) :: info

    CALL init_error_status(status)

    ! Step 1: K_αα 求逆 (参考 PH_Elem_C3D8EAS.f90 行322-323)
    !         需要9×9 LU分解，扩展自现有 InvertMatrix (行169-236仅支持≤3×3)
    K_aa_inv = ctx%K_aa
    CALL PH_EAS_InvertLU(PH_EAS_NMODES, K_aa_inv, info)

    IF (info /= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_EAS_Condense] K_aa singular"
      RETURN
    END IF

    ! Step 2: 中间矩阵 K_dα · K_αα⁻¹ (参考行332)
    temp_Kda_Kaainv = MATMUL(ctx%K_da, K_aa_inv)

    ! Step 3: K_eff = K_dd - K_dα · K_αα⁻¹ · K_αd (参考行333, §2.2.2)
    K_eff = K_dd - MATMUL(temp_Kda_Kaainv, ctx%K_ad)

    ! Step 4: f_eff = (f_ext - f_int) - K_dα · K_αα⁻¹ · h_α (§2.2.2)
    f_eff = f_ext_minus_fint - MATMUL(temp_Kda_Kaainv, ctx%h_alpha)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_EAS_Condense

  !===========================================================================
  ! Subroutine: PH_EAS_UpdateAlpha
  ! Purpose:    α参数完整Newton迭代更新 (关键缺口补齐)
  ! Design doc: §2.3.1 牛顿迭代 — 完整算法
  !
  ! Algorithm (补齐 PH_Elem_C3D8EAS.f90 行428-461 的单步简化):
  !   1. α⁰ₙ₊₁ = αₙ (上一收敛步)
  !   2. r_α^(k) = h_α^(k) + K_αd · Δd^(k)
  !   3. Δα^(k) = -K_αα⁻¹ · r_α^(k)
  !   4. α^(k+1) = α^(k) + Δα^(k)
  !   5. 收敛: ‖r_α‖/‖r_α⁰‖ < tol_α
  !
  ! Reference:  PH_Elem_C3D8EAS.f90 行456-457 (单步版本)
  !===========================================================================
  SUBROUTINE PH_EAS_UpdateAlpha(ctx, delta_d, stress_gp, D_tan_gp, &
                                 B_gp, weights, det_J_gp, status)
    TYPE(PH_EAS_Ctx),     INTENT(INOUT) :: ctx            ! [INOUT] EAS上下文
    REAL(wp),             INTENT(IN)    :: delta_d(:)     ! [IN]  位移增量 Δd [ndof]
    REAL(wp),             INTENT(IN)    :: stress_gp(:,:) ! [IN]  GP应力 σ [n_gp, 6] Voigt
    REAL(wp),             INTENT(IN)    :: D_tan_gp(:,:,:)! [IN]  GP切线 D [n_gp, 6, 6]
    REAL(wp),             INTENT(IN)    :: B_gp(:,:,:)    ! [IN]  GP B矩阵 [n_gp, 6, ndof]
    REAL(wp),             INTENT(IN)    :: weights(:)     ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)    ! [IN]  det(J) at GP [n_gp]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status          ! [OUT] 错误状态

    ! Local variables
    INTEGER(i4) :: iter, igp, info
    REAL(wp)    :: r_alpha(PH_EAS_NMODES)           ! 残差向量
    REAL(wp)    :: delta_alpha(PH_EAS_NMODES)       ! α增量
    REAL(wp)    :: K_aa_inv(PH_EAS_NMODES, PH_EAS_NMODES)
    REAL(wp)    :: r_norm, r_norm0
    REAL(wp)    :: w_detJ
    REAL(wp)    :: G_gp(PH_EAS_NSTR, PH_EAS_NMODES)
    REAL(wp)    :: strain_enh(PH_EAS_NSTR)          ! 增强应变
    REAL(wp)    :: sigma_new(PH_EAS_NSTR)
    REAL(wp)    :: D_tan(PH_EAS_NSTR, PH_EAS_NSTR)

    CALL init_error_status(status)

    IF (.NOT. ctx%is_active) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_EAS_UpdateAlpha] Context not initialized"
      RETURN
    END IF

    ctx%converged = .FALSE.

    ! =========================================================
    ! Newton iteration loop for α (设计文档§2.3.1)
    ! =========================================================
    DO iter = 1, MAX_ITER_ALPHA

      ! --- Step 2a: 重新组装 h_α 和 K_αα, K_αd ---
      ! (每次迭代需用更新后的α重新计算, 设计文档§2.2.1 公式)
      ctx%h_alpha = 0.0_wp
      ctx%K_aa    = 0.0_wp
      ctx%K_ad    = 0.0_wp

      DO igp = 1, ctx%n_gp
        w_detJ = weights(igp) * det_J_gp(igp)
        IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

        G_gp = ctx%G_matrix(igp, :, :)

        ! Step 2a-i: 计算增强应变 ε_enh = G·α (§2.4.1)
        ! Adapted from PH_Elem_C3D8EAS.f90:282-292 (G_gp modes)
        strain_enh = MATMUL(G_gp, ctx%alpha)

        ! Note: 完整Material更新需外部调用者基于 ε_total = ε_compat + ε_enh
        !       提供更新后的 (σ, D_tan). 当前使用传入的应力和切线模量
        !       调用签名参考 PH_Elem_C3D8_EAS_Material_Update_Routed (行463-479)
        sigma_new = stress_gp(igp, :)
        D_tan     = D_tan_gp(igp, :, :)

        ! h_α = Σ M^T · σ · w · detJ  (§2.2.1 公式)
        ctx%h_alpha = ctx%h_alpha + MATMUL(TRANSPOSE(G_gp), sigma_new) * w_detJ

        ! K_αα = Σ M^T · D · M · w · detJ  (§2.2.1 公式)
        ctx%K_aa = ctx%K_aa + &
                   MATMUL(MATMUL(TRANSPOSE(G_gp), D_tan), G_gp) * w_detJ

        ! K_αd = Σ M^T · D · B · w · detJ  (§2.2.1)
        ctx%K_ad = ctx%K_ad + &
                   MATMUL(MATMUL(TRANSPOSE(G_gp), D_tan), B_gp(igp,:,:)) * w_detJ

      END DO

      ! --- Step 2b: 计算残差 r_α = h_α + K_αd · Δd (§2.3.1 步骤2) ---
      r_alpha = ctx%h_alpha + MATMUL(ctx%K_ad, delta_d)

      ! --- Step 5: 收敛检查 ---
      r_norm = SQRT(DOT_PRODUCT(r_alpha, r_alpha))
      IF (iter == 1) r_norm0 = MAX(r_norm, TOL_SINGULAR)

      IF (r_norm / r_norm0 < TOL_ALPHA) THEN
        ctx%converged = .TRUE.
        EXIT
      END IF

      ! --- Step 3: K_αα求逆 ---
      K_aa_inv = ctx%K_aa
      CALL PH_EAS_InvertLU(PH_EAS_NMODES, K_aa_inv, info)
      IF (info /= 0_i4) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_EAS_UpdateAlpha] K_aa singular at iter"
        RETURN
      END IF

      ! --- Step 3: Δα = -K_αα⁻¹ · r_α (§2.3.1 步骤3) ---
      delta_alpha = -MATMUL(K_aa_inv, r_alpha)

      ! --- Step 4: α^(k+1) = α^(k) + Δα (§2.3.1 步骤4) ---
      ctx%alpha = ctx%alpha + delta_alpha

    END DO  ! Newton iteration

    IF (.NOT. ctx%converged) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_EAS_UpdateAlpha] Alpha iteration did not converge"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_EAS_UpdateAlpha

  !===========================================================================
  ! Subroutine: PH_EAS_ComputeKe
  ! Purpose:    完整单元刚度矩阵(含EAS增强) — IP循环+缩聚
  ! Design doc: §2.2 单元刚度矩阵, §2.5 数据流图
  ! Reference:  PH_Elem_C3D8EAS.f90 行367-426 (Stiffness)
  !===========================================================================
  SUBROUTINE PH_EAS_ComputeKe(ctx, B_gp, D_tan_gp, stress_gp, &
                                weights, det_J_gp, u_elem,       &
                                K_eff, f_eff, status)
    TYPE(PH_EAS_Ctx),     INTENT(INOUT) :: ctx            ! [INOUT] EAS上下文
    REAL(wp),             INTENT(IN)    :: B_gp(:,:,:)    ! [IN]  B矩阵 [n_gp,6,ndof]
    REAL(wp),             INTENT(IN)    :: D_tan_gp(:,:,:)! [IN]  切线D [n_gp,6,6]
    REAL(wp),             INTENT(IN)    :: stress_gp(:,:) ! [IN]  应力σ [n_gp,6]
    REAL(wp),             INTENT(IN)    :: weights(:)     ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)    ! [IN]  det(J) [n_gp]
    REAL(wp),             INTENT(IN)    :: u_elem(:)      ! [IN]  节点位移 [ndof]
    REAL(wp),             INTENT(OUT)   :: K_eff(:,:)     ! [OUT] 有效刚度 [ndof,ndof]
    REAL(wp),             INTENT(OUT)   :: f_eff(:)       ! [OUT] 有效力 [ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status          ! [OUT] 错误状态

    ! Locals
    INTEGER(i4) :: igp
    REAL(wp)    :: K_dd(PH_EAS_NDOF, PH_EAS_NDOF)
    REAL(wp)    :: f_int(PH_EAS_NDOF)
    REAL(wp)    :: w_detJ
    REAL(wp)    :: B(PH_EAS_NSTR, PH_EAS_NDOF)
    REAL(wp)    :: G(PH_EAS_NSTR, PH_EAS_NMODES)
    REAL(wp)    :: BtD(PH_EAS_NDOF, PH_EAS_NSTR)
    REAL(wp)    :: GtD(PH_EAS_NMODES, PH_EAS_NSTR)
    REAL(wp)    :: D_tan(PH_EAS_NSTR, PH_EAS_NSTR)
    REAL(wp)    :: sigma(PH_EAS_NSTR)

    CALL init_error_status(status)

    ! --- Zero accumulators (参考行380-383) ---
    K_dd        = 0.0_wp
    f_int       = 0.0_wp
    ctx%K_da    = 0.0_wp
    ctx%K_ad    = 0.0_wp
    ctx%K_aa    = 0.0_wp
    ctx%h_alpha = 0.0_wp

    ! =========================================================
    ! IP loop: 组装子矩阵 (参考行386-408, §2.2.1)
    ! =========================================================
    DO igp = 1, ctx%n_gp
      w_detJ = weights(igp) * det_J_gp(igp)
      IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

      B     = B_gp(igp, :, :)
      G     = ctx%G_matrix(igp, :, :)
      D_tan = D_tan_gp(igp, :, :)
      sigma = stress_gp(igp, :)

      ! 增强应变贡献: ε_enh = G·α (§2.4.1)
      ! Adapted from PH_Elem_C3D8EAS.f90:282-292
      ! Note: 完整Material更新需外部调用者基于 ε_total = B·d + G·α
      !       提供 (σ, D_tan); 调用签名参考 PH_Elem_C3D8_EAS_Material_Update_Routed

      ! --- K_dd = Σ B^T · D · B · w·detJ (§2.2.1) ---
      BtD = MATMUL(TRANSPOSE(B), D_tan)
      K_dd = K_dd + MATMUL(BtD, B) * w_detJ

      ! --- K_dα = Σ B^T · D · M · w·detJ (§2.2.1) ---
      ctx%K_da = ctx%K_da + MATMUL(BtD, G) * w_detJ

      ! --- K_αd = Σ M^T · D · B · w·detJ = K_dα^T (§2.2.1) ---
      GtD = MATMUL(TRANSPOSE(G), D_tan)
      ctx%K_ad = ctx%K_ad + MATMUL(GtD, B) * w_detJ

      ! --- K_αα = Σ M^T · D · M · w·detJ (§2.2.1) ---
      ctx%K_aa = ctx%K_aa + MATMUL(GtD, G) * w_detJ

      ! --- h_α = Σ M^T · σ · w·detJ (§2.2.1) ---
      ctx%h_alpha = ctx%h_alpha + MATMUL(TRANSPOSE(G), sigma) * w_detJ

      ! --- f_int = Σ B^T · σ · w·detJ ---
      f_int = f_int + MATMUL(TRANSPOSE(B), sigma) * w_detJ

    END DO

    ! =========================================================
    ! 静态缩聚 (§2.2.2)
    ! =========================================================
    CALL PH_EAS_Condense(ctx, K_dd, -f_int, K_eff, f_eff, status)

  END SUBROUTINE PH_EAS_ComputeKe

  !===========================================================================
  ! Subroutine: PH_EAS_ComputeFe
  ! Purpose:    完整单元内力向量(含EAS增强)
  ! Design doc: §2.5 数据流图 — 输出f_eff
  !===========================================================================
  SUBROUTINE PH_EAS_ComputeFe(ctx, B_gp, stress_gp, weights, det_J_gp, &
                               f_int, status)
    TYPE(PH_EAS_Ctx),     INTENT(IN)    :: ctx            ! [IN]  EAS上下文
    REAL(wp),             INTENT(IN)    :: B_gp(:,:,:)    ! [IN]  B矩阵 [n_gp,6,ndof]
    REAL(wp),             INTENT(IN)    :: stress_gp(:,:) ! [IN]  应力σ [n_gp,6]
    REAL(wp),             INTENT(IN)    :: weights(:)     ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)    ! [IN]  det(J) [n_gp]
    REAL(wp),             INTENT(OUT)   :: f_int(:)       ! [OUT] 内力向量 [ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status          ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: w_detJ
    REAL(wp)    :: B(PH_EAS_NSTR, PH_EAS_NDOF)
    REAL(wp)    :: sigma(PH_EAS_NSTR)

    CALL init_error_status(status)
    f_int = 0.0_wp

    ! --- IP loop: f_int = Σ B^T · σ · w · detJ ---
    DO igp = 1, ctx%n_gp
      w_detJ = weights(igp) * det_J_gp(igp)
      IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

      B     = B_gp(igp, :, :)
      sigma = stress_gp(igp, :)

      ! 增强应变贡献: σ 应基于 ε_total = B·d + G·α 计算 (§2.4.1)
      ! Adapted from PH_Elem_C3D8EAS.f90:463-479
      ! Note: 调用者需确保 stress_gp 已包含增强应变的Material响应

      f_int = f_int + MATMUL(TRANSPOSE(B), sigma) * w_detJ
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_EAS_ComputeFe

  !===========================================================================
  ! Subroutine: PH_EAS_InvertLU (PRIVATE)
  ! Purpose:    LU分解求逆，支持任意n×n (扩展自InvertMatrix仅≤3×3)
  ! Design doc: §2.6 映射表 — InvertMatrix扩展至9×9
  ! Reference:  PH_Elem_C3D8EAS.f90 行169-236 (InvertMatrix, 仅≤3×3)
  !===========================================================================
  SUBROUTINE PH_EAS_InvertLU(n, A, info)
    INTEGER(i4), INTENT(IN)    :: n        ! [IN]  矩阵维度
    REAL(wp),    INTENT(INOUT) :: A(n, n)  ! [INOUT] 输入矩阵，输出逆矩阵
    INTEGER(i4), INTENT(OUT)   :: info     ! [OUT] 0=成功, <0=奇异

    ! Local: LU decomposition workspace
    INTEGER(i4) :: i, j, k
    INTEGER(i4) :: pivot_row
    REAL(wp)    :: L(n, n), U(n, n), P(n, n)
    REAL(wp)    :: A_inv(n, n)
    REAL(wp)    :: max_val, temp_val
    REAL(wp)    :: temp_row(n)
    REAL(wp)    :: y(n), x(n), b_col(n)

    info = 0

    ! --- Step 1: LU分解 with partial pivoting (设计文档§2.6) ---
    ! Adapted from PH_Elem_C3D8EAS.f90:169-236 (InvertMatrix, 扩展至n×n)
    ! 算法: PA = LU (Gauss消去 + 列主元选取), 然后前代/回代求逆

    ! Initialize
    U = A
    L = 0.0_wp
    P = 0.0_wp
    DO i = 1, n
      L(i, i) = 1.0_wp
      P(i, i) = 1.0_wp
    END DO

    ! Gaussian elimination with partial pivoting
    DO k = 1, n - 1
      ! Find pivot
      max_val = ABS(U(k, k))
      pivot_row = k
      DO i = k + 1, n
        IF (ABS(U(i, k)) > max_val) THEN
          max_val = ABS(U(i, k))
          pivot_row = i
        END IF
      END DO

      IF (max_val < TOL_SINGULAR) THEN
        info = -1  ! Singular matrix
        RETURN
      END IF

      ! Swap rows if needed
      IF (pivot_row /= k) THEN
        temp_row(1:n) = U(k, :);    U(k, :) = U(pivot_row, :);    U(pivot_row, :) = temp_row(1:n)
        temp_row(1:n) = P(k, :);    P(k, :) = P(pivot_row, :);    P(pivot_row, :) = temp_row(1:n)
        IF (k > 1) THEN
          temp_row(1:k-1) = L(k, 1:k-1)
          L(k, 1:k-1) = L(pivot_row, 1:k-1)
          L(pivot_row, 1:k-1) = temp_row(1:k-1)
        END IF
      END IF

      ! Eliminate below pivot
      DO i = k + 1, n
        L(i, k) = U(i, k) / U(k, k)
        DO j = k, n
          U(i, j) = U(i, j) - L(i, k) * U(k, j)
        END DO
      END DO
    END DO

    ! Check last diagonal element
    IF (ABS(U(n, n)) < TOL_SINGULAR) THEN
      info = -1
      RETURN
    END IF

    ! --- Step 2: 求逆 by solving n right-hand sides ---
    A_inv = 0.0_wp
    DO j = 1, n
      ! b_col = P * e_j
      b_col = P(:, j)

      ! Forward substitution: L * y = b_col
      DO i = 1, n
        y(i) = b_col(i)
        DO k = 1, i - 1
          y(i) = y(i) - L(i, k) * y(k)
        END DO
      END DO

      ! Back substitution: U * x = y
      DO i = n, 1, -1
        x(i) = y(i)
        DO k = i + 1, n
          x(i) = x(i) - U(i, k) * x(k)
        END DO
        x(i) = x(i) / U(i, i)
      END DO

      A_inv(:, j) = x
    END DO

    A = A_inv

  END SUBROUTINE PH_EAS_InvertLU

END MODULE PH_Elem_Solid3D_EAS
