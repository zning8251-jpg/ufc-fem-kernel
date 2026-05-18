!===============================================================================
! MODULE: PH_Elem_Solid3D_Fbar
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  Unified F-bar kernel for volumetric locking treatment
!===============================================================================
MODULE PH_Elem_Solid3D_Fbar
  !! Element域 F-bar体积锁定治疗统一内核
  !! F̄ = (J̄/J)^{1/3} · F
  !! 设计文档: DESIGN_Elem_Advanced_3D.md §3

  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! PARAMETERS
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FBAR_NSTR  = 6_i4   ! 3D Voigt
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FBAR_NDOF  = 24_i4  ! C3D8: 8*3
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FBAR_MAXGP = 27_i4  ! Max GP count

  REAL(wp), PARAMETER :: TOL_SINGULAR = 1.0E-12_wp
  REAL(wp), PARAMETER :: ONE_THIRD    = 1.0_wp / 3.0_wp

  !===========================================================================
  ! PUBLIC INTERFACES
  !===========================================================================
  PUBLIC :: PH_Fbar_Ctx           ! TYPE: F-bar上下文
  PUBLIC :: PH_Fbar_Init          ! 初始化上下文
  PUBLIC :: PH_Fbar_ComputeJbar   ! 体积平均J̄
  PUBLIC :: PH_Fbar_ModifyF       ! 修正变形梯度F̄
  PUBLIC :: PH_Fbar_ComputeBbar   ! B̄矩阵显式计算 (关键缺口补齐)
  PUBLIC :: PH_Fbar_ComputeKe     ! 完整刚度(含F-bar修正)
  PUBLIC :: PH_Fbar_ComputeFe     ! 完整内力

  !===========================================================================
  ! TYPE: PH_Fbar_Ctx — F-bar上下文 (参考 PH_Elem_C3D8FBar.f90 行86-107)
  !===========================================================================
  TYPE, PUBLIC :: PH_Fbar_Ctx
    REAL(wp) :: Jbar = 1.0_wp             ! 体积平均Jacobian J̄
    REAL(wp) :: volume = 0.0_wp           ! 单元参考体积 V₀

    ! 各GP的det(F)
    REAL(wp), POINTER :: det_F_gp(:) => NULL()  ! [n_gp]
    ! 各GP的 w_i * det(J)
    REAL(wp), POINTER :: wt_detJ(:) => NULL()   ! [n_gp]

    ! 变形梯度
    REAL(wp), POINTER :: F_gp(:,:,:) => NULL()      ! F at GP [n_gp,3,3]
    REAL(wp), POINTER :: F_bar_gp(:,:,:) => NULL()  ! F̄ at GP [n_gp,3,3]

    ! B̄矩阵 (显式计算后存储)
    REAL(wp), POINTER :: B_bar(:,:,:) => NULL()     ! B̄ [n_gp,6,ndof]

    ! 体积平均 B_vol
    REAL(wp) :: B_vol_avg(PH_FBAR_NSTR, PH_FBAR_NDOF) = 0.0_wp

    INTEGER(i4) :: n_gp = 8_i4
    LOGICAL :: is_active = .FALSE.
  END TYPE PH_Fbar_Ctx

CONTAINS

  !===========================================================================
  ! Subroutine: PH_Fbar_Init
  ! Purpose:    初始化F-bar上下文，分配数组
  ! Design doc: §3.5 数据流图 — InitCtx节点
  ! Reference:  PH_Elem_C3D8FBar.f90 行255-296 (InitCtx)
  !===========================================================================
  SUBROUTINE PH_Fbar_Init(ctx, n_gp, status)
    TYPE(PH_Fbar_Ctx),    INTENT(OUT)   :: ctx    ! [OUT] 初始化后上下文
    INTEGER(i4),          INTENT(IN)    :: n_gp   ! [IN]  Gauss点数
    TYPE(ErrorStatusType), INTENT(OUT)  :: status  ! [OUT] 错误状态

    INTEGER(i4) :: igp

    CALL init_error_status(status)

    IF (n_gp <= 0_i4 .OR. n_gp > PH_FBAR_MAXGP) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Fbar_Init] Invalid n_gp"
      RETURN
    END IF

    ctx%n_gp      = n_gp
    ctx%is_active = .TRUE.
    ctx%Jbar      = 1.0_wp
    ctx%volume    = 0.0_wp
    ctx%B_vol_avg = 0.0_wp

    ! 分配数组 (参考行274-284)
    IF (ASSOCIATED(ctx%det_F_gp))  DEALLOCATE(ctx%det_F_gp)
    IF (ASSOCIATED(ctx%wt_detJ))   DEALLOCATE(ctx%wt_detJ)
    IF (ASSOCIATED(ctx%F_gp))      DEALLOCATE(ctx%F_gp)
    IF (ASSOCIATED(ctx%F_bar_gp))  DEALLOCATE(ctx%F_bar_gp)
    IF (ASSOCIATED(ctx%B_bar))     DEALLOCATE(ctx%B_bar)

    ALLOCATE(ctx%det_F_gp(n_gp))
    ALLOCATE(ctx%wt_detJ(n_gp))
    ALLOCATE(ctx%F_gp(n_gp, 3, 3))
    ALLOCATE(ctx%F_bar_gp(n_gp, 3, 3))
    ALLOCATE(ctx%B_bar(n_gp, PH_FBAR_NSTR, PH_FBAR_NDOF))

    ctx%det_F_gp = 1.0_wp
    ctx%wt_detJ  = 0.0_wp
    ctx%F_bar_gp = 0.0_wp
    ctx%B_bar    = 0.0_wp

    ! 初始化F为单位矩阵 (参考行287-292)
    ctx%F_gp = 0.0_wp
    DO igp = 1, n_gp
      ctx%F_gp(igp, 1, 1) = 1.0_wp
      ctx%F_gp(igp, 2, 2) = 1.0_wp
      ctx%F_gp(igp, 3, 3) = 1.0_wp
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_Init

  !===========================================================================
  ! Subroutine: PH_Fbar_ComputeJbar
  ! Purpose:    计算体积平均Jacobian J̄ = Σ(det(F)·w·detJ) / Σ(w·detJ)
  ! Design doc: §3.1.2 体积平均
  ! Formula:    J̄ = (1/V₀) ∫ det(F) dΩ (设计文档公式)
  ! Reference:  PH_Elem_C3D8FBar.f90 行201-253 (ComputeVolumetricStrain)
  !===========================================================================
  SUBROUTINE PH_Fbar_ComputeJbar(ctx, F_gp, weights, det_J_gp, status)
    TYPE(PH_Fbar_Ctx),    INTENT(INOUT) :: ctx          ! [INOUT] F-bar上下文
    REAL(wp),             INTENT(IN)    :: F_gp(:,:,:)  ! [IN]  变形梯度 [n_gp,3,3]
    REAL(wp),             INTENT(IN)    :: weights(:)   ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)  ! [IN]  det(J) [n_gp]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status        ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: det_F, w_detJ
    REAL(wp)    :: J_integral, volume_integral

    CALL init_error_status(status)

    J_integral      = 0.0_wp
    volume_integral = 0.0_wp

    ! --- GP loop: 积分 det(F) (参考行224-249) ---
    DO igp = 1, ctx%n_gp
      ! 存储F
      ctx%F_gp(igp, :, :) = F_gp(igp, :, :)

      ! det(F) — 3×3行列式 (参考 PH_Elem_C3D8FBar.f90 Det3x3, 行161-169)
      det_F = Det3x3_local(F_gp(igp, :, :))
      ctx%det_F_gp(igp) = det_F

      w_detJ = weights(igp) * det_J_gp(igp)
      ctx%wt_detJ(igp) = w_detJ

      ! 积分: ∫det(F) dV 和 ∫dV (§3.1.2)
      J_integral      = J_integral      + det_F * w_detJ
      volume_integral = volume_integral + w_detJ
    END DO

    ctx%volume = volume_integral

    ! J̄ = J_integral / V₀ (参考行244-249)
    IF (ABS(volume_integral) > TOL_SINGULAR) THEN
      ctx%Jbar = J_integral / volume_integral
    ELSE
      ctx%Jbar = 1.0_wp
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_ComputeJbar

  !===========================================================================
  ! Subroutine: PH_Fbar_ModifyF
  ! Purpose:    计算修正变形梯度 F̄ = (J̄/J)^{1/3} · F
  ! Design doc: §3.1.3 修正变形梯度
  ! Reference:  PH_Elem_C3D8FBar.f90 行298-339 (SplitDeviatoric) 行326-331
  !===========================================================================
  SUBROUTINE PH_Fbar_ModifyF(ctx, status)
    TYPE(PH_Fbar_Ctx),    INTENT(INOUT) :: ctx    ! [INOUT] F-bar上下文
    TYPE(ErrorStatusType), INTENT(OUT)  :: status  ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: J, J_ratio, scale_factor

    CALL init_error_status(status)

    IF (.NOT. ctx%is_active) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Fbar_ModifyF] Context not initialized"
      RETURN
    END IF

    DO igp = 1, ctx%n_gp
      J = ctx%det_F_gp(igp)

      IF (ABS(J) < TOL_SINGULAR) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Fbar_ModifyF] Zero det(F) at GP"
        RETURN
      END IF

      ! F̄ = (J̄/J)^{1/3} · F (参考行326-331, §3.1.3)
      J_ratio = ctx%Jbar / J                       ! 行326
      scale_factor = J_ratio ** ONE_THIRD           ! 行327
      ctx%F_bar_gp(igp, :, :) = scale_factor * ctx%F_gp(igp, :, :) ! 行331
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_ModifyF

  !===========================================================================
  ! Subroutine: PH_Fbar_ComputeBbar
  ! Purpose:    B̄矩阵显式计算 (关键缺口补齐)
  !             B̄ = B_dev + (J̄/J)^{1/3} · B̄_vol
  ! Design doc: §3.2 修正B̄矩阵显式公式
  !
  ! Algorithm (补齐 PH_Elem_C3D8FBar.f90 行379-386 的简化 B̄≈B):
  !   Phase 1: 预扫描 — 计算 B_vol 平均
  !     B_diag = B(1,:) + B(2,:) + B(3,:)   (迹)
  !     B_vol(igp) = (1/3) · [1;1;1;0;0;0] · B_diag
  !     B_vol_avg = Σ(B_vol·w·detJ) / V_total
  !   Phase 2: 逐GP修正
  !     B_dev = B - B_vol
  !     scale = (J̄/J)^{1/3}
  !     B̄ = B_dev + scale · B_vol_avg
  !
  ! Reference:  PH_Elem_C3D8FBar.f90 行379-386 (简化版, 现补齐)
  !===========================================================================
  SUBROUTINE PH_Fbar_ComputeBbar(ctx, B_gp, status)
    TYPE(PH_Fbar_Ctx),    INTENT(INOUT) :: ctx          ! [INOUT] F-bar上下文
    REAL(wp),             INTENT(IN)    :: B_gp(:,:,:)  ! [IN]  标准B矩阵 [n_gp,6,ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status        ! [OUT] 错误状态

    INTEGER(i4) :: igp, j
    REAL(wp)    :: B_diag(PH_FBAR_NDOF)                       ! 迹: B(1,:)+B(2,:)+B(3,:)
    REAL(wp)    :: B_vol_gp(PH_FBAR_NSTR, PH_FBAR_NDOF)      ! B_vol at current GP
    REAL(wp)    :: B_dev_gp(PH_FBAR_NSTR, PH_FBAR_NDOF)      ! B_dev at current GP
    REAL(wp)    :: B_vol_avg(PH_FBAR_NSTR, PH_FBAR_NDOF)     ! Volume-averaged B_vol
    REAL(wp)    :: V_total, w_detJ, scale

    CALL init_error_status(status)

    ! ==================================================================
    ! Phase 1: 预扫描 — 计算 B_vol 体积平均 (§3.2.2)
    ! ==================================================================
    B_vol_avg = 0.0_wp
    V_total   = 0.0_wp

    DO igp = 1, ctx%n_gp
      w_detJ = ctx%wt_detJ(igp)
      IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

      ! B_diag = B(1,:) + B(2,:) + B(3,:) — 迹 (§3.2.1)
      B_diag(:) = B_gp(igp, 1, :) + B_gp(igp, 2, :) + B_gp(igp, 3, :)

      ! B_vol = (1/3) · [1;1;1;0;0;0] ⊗ B_diag (§3.2.1)
      B_vol_gp = 0.0_wp
      DO j = 1, PH_FBAR_NDOF
        B_vol_gp(1, j) = ONE_THIRD * B_diag(j)
        B_vol_gp(2, j) = ONE_THIRD * B_diag(j)
        B_vol_gp(3, j) = ONE_THIRD * B_diag(j)
        ! rows 4-6 (shear) remain zero
      END DO

      ! 累加体积平均 (§3.2.2)
      B_vol_avg = B_vol_avg + B_vol_gp * w_detJ
      V_total   = V_total   + w_detJ
    END DO

    ! 平均化
    IF (ABS(V_total) > TOL_SINGULAR) THEN
      B_vol_avg = B_vol_avg / V_total
    END IF
    ctx%B_vol_avg = B_vol_avg

    ! ==================================================================
    ! Phase 2: 逐GP修正 B̄ = B_dev + (J̄/J)^{1/3} · B̄_vol (§3.2.3)
    ! ==================================================================
    DO igp = 1, ctx%n_gp
      ! B_diag at this GP (recompute for dev split)
      B_diag(:) = B_gp(igp, 1, :) + B_gp(igp, 2, :) + B_gp(igp, 3, :)

      ! B_vol at this GP
      B_vol_gp = 0.0_wp
      DO j = 1, PH_FBAR_NDOF
        B_vol_gp(1, j) = ONE_THIRD * B_diag(j)
        B_vol_gp(2, j) = ONE_THIRD * B_diag(j)
        B_vol_gp(3, j) = ONE_THIRD * B_diag(j)
      END DO

      ! B_dev = B - B_vol (§3.2.1)
      B_dev_gp = B_gp(igp, :, :) - B_vol_gp

      ! scale = (J̄/J)^{1/3} (§3.2.3)
      IF (ABS(ctx%det_F_gp(igp)) > TOL_SINGULAR) THEN
        scale = (ctx%Jbar / ctx%det_F_gp(igp)) ** ONE_THIRD
      ELSE
        scale = 1.0_wp
      END IF

      ! B̄ = B_dev + scale · B_vol_avg (§3.2.3)
      ctx%B_bar(igp, :, :) = B_dev_gp + scale * B_vol_avg
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_ComputeBbar

  !===========================================================================
  ! Subroutine: PH_Fbar_ComputeKe
  ! Purpose:    完整刚度矩阵(含F-bar修正 + 可选几何修正项)
  ! Design doc: §3.3 刚度矩阵修正
  ! Formula:    K̄ = Σ B̄ᵀ · D · B̄ · w · detJ + K_geo_vol
  ! Reference:  PH_Elem_C3D8FBar.f90 行171-199 (AssembleStiffness)
  !===========================================================================
  SUBROUTINE PH_Fbar_ComputeKe(ctx, D_tan_gp, stress_gp, weights, det_J_gp, &
                                 Ke, status)
    TYPE(PH_Fbar_Ctx),    INTENT(IN)    :: ctx            ! [IN]  F-bar上下文(含B̄)
    REAL(wp),             INTENT(IN)    :: D_tan_gp(:,:,:)! [IN]  切线D [n_gp,6,6]
    REAL(wp),             INTENT(IN)    :: stress_gp(:,:) ! [IN]  应力σ [n_gp,6] Voigt
    REAL(wp),             INTENT(IN)    :: weights(:)     ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)    ! [IN]  det(J) [n_gp]
    REAL(wp),             INTENT(OUT)   :: Ke(:,:)        ! [OUT] 刚度矩阵 [ndof,ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status          ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: w_detJ
    REAL(wp)    :: B_bar(PH_FBAR_NSTR, PH_FBAR_NDOF)
    REAL(wp)    :: BtD(PH_FBAR_NDOF, PH_FBAR_NSTR)
    REAL(wp)    :: D_tan(PH_FBAR_NSTR, PH_FBAR_NSTR)
    REAL(wp)    :: p_hydro, scale_geo
    REAL(wp)    :: K_geo_vol(PH_FBAR_NDOF, PH_FBAR_NDOF)
    REAL(wp)    :: one_vol(PH_FBAR_NSTR)  ! [1,1,1,0,0,0]
    REAL(wp)    :: f_vol(PH_FBAR_NDOF)    ! B_vol_avg^T · one_vol
    INTEGER(i4) :: ii, jj

    CALL init_error_status(status)

    Ke = 0.0_wp
    K_geo_vol = 0.0_wp
    one_vol = (/ 1.0_wp, 1.0_wp, 1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp /)

    ! =========================================================
    ! IP loop: 组装 K̄ = Σ B̄ᵀ D B̄ w·detJ (参考行184-195, §3.3)
    ! =========================================================
    DO igp = 1, ctx%n_gp
      w_detJ = weights(igp) * det_J_gp(igp)
      IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

      B_bar = ctx%B_bar(igp, :, :)
      D_tan = D_tan_gp(igp, :, :)

      ! Material D矩阵通过外部Material接口获取 (§3.6)
      ! Adapted from PH_Elem_C3D8FBar.f90:405-421 (Material_Update_Routed)
      ! Note: 调用者需基于F̄计算应变后获取D_tan_gp和stress_gp

      ! K̄ = Σ B̄ᵀ · D · B̄ · w·detJ
      BtD = MATMUL(TRANSPOSE(B_bar), D_tan)
      Ke  = Ke + MATMUL(BtD, B_bar) * w_detJ

      ! --- 几何修正项 K_geo_vol (§3.3, Adapted from de Souza Neto F-bar) ---
      ! K_geo_vol = (1/9) Σ (J̄/J)^{2/3} · p · B_vol_avg^T·1_vol ⊗ 1_vol^T·B_vol_avg · w·detJ
      ! p = (1/3) tr(σ) = (σ₁₁+σ₂₂+σ₃₃)/3
      p_hydro = ONE_THIRD * (stress_gp(igp,1) + stress_gp(igp,2) + stress_gp(igp,3))

      IF (ABS(ctx%det_F_gp(igp)) > TOL_SINGULAR) THEN
        scale_geo = (ctx%Jbar / ctx%det_F_gp(igp)) ** (2.0_wp * ONE_THIRD)
      ELSE
        scale_geo = 1.0_wp
      END IF

      ! Step K_geo: 投影到自由度空间 (§3.3)
      ! f_vol = B_vol_avg^T · one_vol (ndof vector)
      f_vol = MATMUL(TRANSPOSE(ctx%B_vol_avg), one_vol)
      ! K_geo_vol += (1/9) * scale_geo * p * outer(f_vol, f_vol) * w·detJ
      DO ii = 1, PH_FBAR_NDOF
        DO jj = 1, PH_FBAR_NDOF
          K_geo_vol(ii, jj) = K_geo_vol(ii, jj) + &
            ONE_THIRD * ONE_THIRD * scale_geo * p_hydro * &
            f_vol(ii) * f_vol(jj) * w_detJ
        END DO
      END DO

    END DO

    ! K_total = K̄ + K_geo_vol (§3.3)
    Ke = Ke + K_geo_vol

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_ComputeKe

  !===========================================================================
  ! Subroutine: PH_Fbar_ComputeFe
  ! Purpose:    完整内力向量 f_int = Σ B̄ᵀ · σ · w · detJ
  ! Design doc: §3.5 数据流图 — 输出f_int
  !===========================================================================
  SUBROUTINE PH_Fbar_ComputeFe(ctx, stress_gp, weights, det_J_gp, &
                                f_int, status)
    TYPE(PH_Fbar_Ctx),    INTENT(IN)    :: ctx            ! [IN]  F-bar上下文(含B̄)
    REAL(wp),             INTENT(IN)    :: stress_gp(:,:) ! [IN]  应力σ [n_gp,6] Voigt
    REAL(wp),             INTENT(IN)    :: weights(:)     ! [IN]  GP权重 [n_gp]
    REAL(wp),             INTENT(IN)    :: det_J_gp(:)    ! [IN]  det(J) [n_gp]
    REAL(wp),             INTENT(OUT)   :: f_int(:)       ! [OUT] 内力向量 [ndof]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status          ! [OUT] 错误状态

    INTEGER(i4) :: igp
    REAL(wp)    :: w_detJ
    REAL(wp)    :: B_bar(PH_FBAR_NSTR, PH_FBAR_NDOF)
    REAL(wp)    :: sigma(PH_FBAR_NSTR)

    CALL init_error_status(status)
    f_int = 0.0_wp

    ! --- IP loop: f_int = Σ B̄ᵀ · σ · w · detJ ---
    DO igp = 1, ctx%n_gp
      w_detJ = weights(igp) * det_J_gp(igp)
      IF (ABS(w_detJ) < TOL_SINGULAR) CYCLE

      B_bar = ctx%B_bar(igp, :, :)
      sigma = stress_gp(igp, :)

      ! 应力基于F̄计算的应变获取 (§3.6)
      ! Adapted from PH_Elem_C3D8FBar.f90:405-421
      ! Note: 调用者需确保 stress_gp 已基于 F̄ 计算的应变通过Material获取

      f_int = f_int + MATMUL(TRANSPOSE(B_bar), sigma) * w_detJ
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Fbar_ComputeFe

  !===========================================================================
  ! Function: Det3x3_local (PRIVATE)
  ! Purpose:  3×3行列式计算
  ! Reference: PH_Elem_C3D8FBar.f90 行161-169 (Det3x3)
  !===========================================================================
  FUNCTION Det3x3_local(A) RESULT(det)
    REAL(wp), INTENT(IN) :: A(3, 3)
    REAL(wp) :: det

    det = A(1,1) * (A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
          A(1,2) * (A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
          A(1,3) * (A(2,1)*A(3,2) - A(2,2)*A(3,1))

  END FUNCTION Det3x3_local

END MODULE PH_Elem_Solid3D_Fbar
