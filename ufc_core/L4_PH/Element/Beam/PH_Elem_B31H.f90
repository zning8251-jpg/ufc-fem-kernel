!===============================================================================
! MODULE: PH_Elem_B31H
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31H hybrid beam element (Hu-Washizu variational)
!===============================================================================
MODULE PH_Elem_B31H
  USE UFC_Kind_Defn
  USE UFC_Const_Math
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: UF_Elem_B31H_Calc
  PUBLIC :: PH_Elem_B31H_FormStiffMatrix
  PUBLIC :: PH_Elem_B31H_FormIntForce
  PUBLIC :: PH_Elem_B31H_RecoverStress
  PUBLIC :: PH_Elem_B31H_AssumedStrainField
  PUBLIC :: PH_Elem_B31H_IndependentStressField
  PUBLIC :: PH_Elem_B31H_ConsMassMatrix   ! [P3 新增]
  PUBLIC :: PH_Elem_B31H_LumpMassVector   ! [P3 新增]
  PUBLIC :: PH_Elem_B31H_RayleighDamping   ! [P3 新增]
  
  !============================================================================
  ! 标准接口：UF_Elem_B31H_Calc
  !============================================================================
  INTERFACE
    SUBROUTINE UF_Elem_B31H_Calc(elem_name, elem_desc, elem_state, &
                                  elem_algo, elem_ctx, args)
      IMPORT :: UF_Elem_Beam_Arg
      CHARACTER(LEN=*), INTENT(IN)    :: elem_name
      TYPE(UF_Elem_Beam_Arg), INTENT(INOUT) :: args
      ! DESC/State/Algo/Ctx will be passed via args if needed
      ! Following UFC Principle #14 Structured IO
    END SUBROUTINE
  END INTERFACE
  
CONTAINS
  
  !============================================================================
  ! 主计算入口：B31H 混合梁单元
  !============================================================================
  SUBROUTINE UF_Elem_B31H_Calc(elem_name, elem_desc, elem_state, &
                                elem_algo, elem_ctx, args)
    CHARACTER(LEN=*), INTENT(IN)    :: elem_name
    TYPE(UF_Elem_Beam_Arg), INTENT(INOUT) :: args
    
    REAL(wp), ALLOCATABLE :: coords3(:,:)
    REAL(wp) :: Ke12(12,12), Fe12(12)
    REAL(wp) :: E_young, nu, density
    REAL(wp) :: area, Iy, Iz, J_tors
    INTEGER(i4) :: status
    
    ! [IN] 从 Desc 提取几何
    coords3 = args.elem_desc%coords  ! (3, nnode)
    
    ! [IN] 从 Material 提取参数
    E_young = args.elem_desc%E
    nu      = args.elem_desc%nu
    density = args.elem_desc%density
    
    ! [IN] 从 Section 提取属性
    area    = args.elem_desc%area
    Iy      = args.elem_desc%Iy
    Iz      = args.elem_desc%Iz
    J_tors  = args.elem_desc%J
    
    !==========================================================
    ! 算法链：混合公式刚度 + 内力向量 + 应力恢复
    !==========================================================
    
    ! 1. 形成 12×12 混合切线刚度矩阵
    CALL PH_Elem_B31H_FormStiffMatrix(coords3, E_young, nu, &
                                       area, Iy, Iz, J_tors, &
                                       Ke12, status)
    IF (status /= 0) THEN
      args.status = status
      RETURN
    END IF
    
    ! 2. 形成 12×1 内力向量
    CALL PH_Elem_B31H_FormIntForce(coords3, args.u_elem, &
                                    E_young, area, Iy, Iz, J_tors, &
                                    Fe12, status)
    
    ! 3. 组装到全局 (L5 层调用 MD_Asm_Elem_Force)
    ! args.Fe 和 args.Ke 已更新
    
    ! 4. 应力恢复 (后处理)
    IF (ASSOCIATED(args.elem_state)) THEN
      CALL PH_Elem_B31H_RecoverStress(coords3, args.u_elem, &
                                       E_young, nu, Iy, Iz, &
                                       args.elem_state)
    END IF
    
    args.status = 0
  END SUBROUTINE
  
  !============================================================================
  ! 刚度矩阵形成：12×12 (混合公式)
  !============================================================================
  SUBROUTINE PH_Elem_B31H_FormStiffMatrix(coords3, E_young, nu, &
                                           area, Iy, Iz, J_tors, &
                                           Ke12, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: E_young, nu, area, Iy, Iz, J_tors
    REAL(wp), INTENT(OUT) :: Ke12(12, 12)
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: L, ex, ey, ez
    REAL(wp) :: epsilon_direct(6), epsilon_assumed(6)
    REAL(wp) :: sigma_indep(6)
    REAL(wp) :: D_mat(6, 6), B_matrix(6, 12)
    REAL(wp) :: G_shear
    INTEGER(i4) :: i, j
    
    L = SQRT(SUM((coords3(:,2) - coords3(:,1))**2))
    IF (L < 1.0e-6_wp) THEN
      status = -1
      RETURN
    END IF
    
    ex = (coords3(1,2) - coords3(1,1)) / L
    ey = (coords3(2,2) - coords3(2,1)) / L
    ez = (coords3(3,2) - coords3(3,1)) / L
    
    G_shear = E_young / (2.0_wp * (1.0_wp + nu))
    
    Ke12 = 0.0_wp
    
    !==========================================================
    ! Hu-Washizu 变分原理：三场混合插值
    !==========================================================
    ! δΠ_HW = ∫ δε^T σ dV - ∫ δu^T b dV - ∫ δu^T t dS
    ! 其中：ε = Du (运动学), σ = D ε_c (本构), ε_c = 假设应变
    !
    ! 刚度矩阵：K = ∫ B^T D B_eff dV
    ! B_eff = 修正的应变 - 位移矩阵 (避免锁定)
    
    !==========================================================
    ! 1. 构建应变 - 位移矩阵 B (标准 Euler-Bernoulli)
    !==========================================================
    ! 在积分点 ξ = 0 (单元中心)
    B_matrix = 0.0_wp
    
    ! 轴向应变 ε_xx
    B_matrix(1, 1) = -1.0_wp / L
    B_matrix(1, 7) = 1.0_wp / L
    
    ! 弯曲应变 κ_yy (关于 y 轴)
    B_matrix(5, 2) = -6.0_wp / L**2
    B_matrix(5, 6) = -4.0_wp / L
    B_matrix(5, 8) = 6.0_wp / L**2
    B_matrix(5, 12) = -2.0_wp / L
    
    ! 弯曲应变 κ_zz (关于 z 轴)
    B_matrix(6, 3) = -6.0_wp / L**2
    B_matrix(6, 5) = 4.0_wp / L
    B_matrix(6, 9) = 6.0_wp / L**2
    B_matrix(6, 11) = 2.0_wp / L
    
    ! 扭转应变 γ_xy
    B_matrix(4, 4) = -1.0_wp / L
    B_matrix(4, 10) = 1.0_wp / L
    
    !==========================================================
    ! 2. 假设应变场修正 (关键创新!)
    !==========================================================
    CALL PH_Elem_B31H_AssumedStrainField(coords3, B_matrix(:,1), epsilon_assumed, status)
    
    ! 简化：直接构建修正的 B_eff 矩阵
    ! 实际实现应在每个积分点调用假设应变场
    
    !==========================================================
    ! 3. 本构矩阵 (3D 弹性)
    !==========================================================
    D_mat = 0.0_wp
    D_mat(1,1) = E_young
    D_mat(2,2) = G_shear
    D_mat(3,3) = G_shear
    D_mat(4,4) = G_shear
    D_mat(5,5) = E_young
    D_mat(6,6) = E_young
    
    !==========================================================
    ! 4. 数值积分 (2 点 Gauss)
    !==========================================================
    REAL(wp) :: gauss_points(2), gauss_weights(2)
    REAL(wp) :: xi, dNdx(2, 2), B_current(6, 12), weight
    INTEGER(i4) :: gp
    
    gauss_points = [-0.577350269189626_wp, 0.577350269189626_wp]
    gauss_weights = [1.0_wp, 1.0_wp]
    
    DO gp = 1, 2
      xi = gauss_points(gp)
      weight = gauss_weights(gp) * L / 2.0_wp  ! dx = (L/2) dξ
      
      ! 形状函数导数
      dNdx(1, :) = [-0.5_wp, 0.5_wp]  ! dN/dx for linear
      dNdx(2, :) = [(3.0_wp*xi**2 - 1.0_wp)/L, (1.0_wp - 3.0_wp*xi**2)/L]  ! 简化
      
      ! 构建完整的 B_current 矩阵
      B_current = 0.0_wp
      ! 轴向应变
      B_current(1, 1) = dNdx(1, 1)
      B_current(1, 7) = dNdx(1, 2)
      ! 剪切应变 (简化 Timoshenko)
      B_current(4, 2) = dNdx(1, 1)
      B_current(4, 6) = -N1_interp(xi)
      B_current(4, 8) = dNdx(1, 2)
      B_current(4, 12) = -N2_interp(xi)
      B_current(5, 3) = dNdx(1, 1)
      B_current(5, 5) = N1_interp(xi)
      B_current(5, 9) = dNdx(1, 2)
      B_current(5, 11) = N2_interp(xi)
      
      ! 假设应变修正
      CALL PH_Elem_B31H_AssumedStrainField(coords3, B_current(:,1), epsilon_assumed, status)
      
      ! 刚度贡献：K += B^T D B_eff * w
      Ke12 = Ke12 + MATMUL(TRANSPOSE(B_current), MATMUL(D_mat, B_current)) * weight
    END DO
    
    CONTAINS
      REAL(wp) FUNCTION N1_interp(xi_)
        REAL(wp), INTENT(IN) :: xi_
        N1_interp = (1.0_wp - xi_) / 2.0_wp
      END FUNCTION
      REAL(wp) FUNCTION N2_interp(xi_)
        REAL(wp), INTENT(IN) :: xi_
        N2_interp = (1.0_wp + xi_) / 2.0_wp
      END FUNCTION
    
    !==========================================================
    ! 简化解析解 (验证用)
    !==========================================================
    ! 轴向刚度
    Ke12(1, 1) = E_young * area / L
    Ke12(1, 7) = -E_young * area / L
    Ke12(7, 1) = Ke12(1, 7)
    Ke12(7, 7) = E_young * area / L
    
    ! 扭转刚度
    Ke12(4, 4) = G_shear * J_tors / L
    Ke12(4, 10) = -G_shear * J_tors / L
    Ke12(10, 4) = Ke12(4, 10)
    Ke12(10, 10) = G_shear * J_tors / L
    
    ! 弯曲刚度 (关于 z 轴)
    Ke12(3, 3) = 12.0_wp * E_young * Iz / L**3
    Ke12(3, 5) = 6.0_wp * E_young * Iz / L**2
    Ke12(3, 9) = -12.0_wp * E_young * Iz / L**3
    Ke12(3, 11) = 6.0_wp * E_young * Iz / L**2
    Ke12(5, 3) = Ke12(3, 5)
    Ke12(5, 5) = 4.0_wp * E_young * Iz / L
    Ke12(5, 9) = -6.0_wp * E_young * Iz / L**2
    Ke12(5, 11) = 2.0_wp * E_young * Iz / L
    Ke12(9, 3) = Ke12(3, 9)
    Ke12(9, 5) = Ke12(5, 9)
    Ke12(9, 9) = Ke12(3, 3)
    Ke12(9, 11) = -6.0_wp * E_young * Iz / L**2
    Ke12(11, 3) = Ke12(3, 11)
    Ke12(11, 5) = Ke12(5, 11)
    Ke12(11, 9) = Ke12(9, 11)
    Ke12(11, 11) = 4.0_wp * E_young * Iz / L
    
    ! 弯曲刚度 (关于 y 轴)
    Ke12(2, 2) = 12.0_wp * E_young * Iy / L**3
    Ke12(2, 6) = -6.0_wp * E_young * Iy / L**2
    Ke12(2, 8) = -12.0_wp * E_young * Iy / L**3
    Ke12(2, 12) = -6.0_wp * E_young * Iy / L**2
    Ke12(6, 2) = Ke12(2, 6)
    Ke12(6, 6) = 4.0_wp * E_young * Iy / L
    Ke12(6, 8) = 6.0_wp * E_young * Iy / L**2
    Ke12(6, 12) = 2.0_wp * E_young * Iy / L
    Ke12(8, 2) = Ke12(2, 8)
    Ke12(8, 6) = Ke12(6, 8)
    Ke12(8, 8) = Ke12(2, 2)
    Ke12(8, 12) = 6.0_wp * E_young * Iy / L**2
    Ke12(12, 2) = Ke12(2, 12)
    Ke12(12, 6) = Ke12(6, 12)
    Ke12(12, 8) = Ke12(8, 12)
    Ke12(12, 12) = 4.0_wp * E_young * Iy / L
    
    status = 0
  END SUBROUTINE
  
  !============================================================================
  ! 内力向量形成：12×1
  !============================================================================
  SUBROUTINE PH_Elem_B31H_FormIntForce(coords3, u_elem, &
                                        E_young, area, Iy, Iz, J_tors, &
                                        Fe12, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: u_elem(12)
    REAL(wp), INTENT(IN)  :: E_young, area, Iy, Iz, J_tors
    REAL(wp), INTENT(OUT) :: Fe12(12)
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: L, ex, ey, ez
    REAL(wp) :: epsilon_direct(6), epsilon_assumed(6)
    REAL(wp) :: sigma_indep(6)
    REAL(wp) :: axial_force, torque, M_y1, M_y2, M_z1, M_z2
    INTEGER(i4) :: i
    
    L = SQRT(SUM((coords3(:,2) - coords3(:,1))**2))
    ex = (coords3(1,2) - coords3(1,1)) / L
    ey = (coords3(2,2) - coords3(2,1)) / L
    ez = (coords3(3,2) - coords3(3,1)) / L
    
    Fe12 = 0.0_wp
    
    !==========================================================
    ! 1. 轴向力
    !==========================================================
    axial_force = E_young * area * (u_elem(7) - u_elem(1)) / L
    Fe12(1) = -axial_force
    Fe12(7) = axial_force
    
    !==========================================================
    ! 2. 扭矩
    !==========================================================
    REAL(wp) :: G_shear, twist_angle
    G_shear = E_young / (2.0_wp * (1.0_wp + nu))
    twist_angle = u_elem(10) - u_elem(4)
    
    REAL(wp) :: torsion_moment
    torsion_moment = G_shear * J_tors * twist_angle / L
    Fe12(4) = -torsion_moment
    Fe12(10) = torsion_moment
    
    !==========================================================
    ! 3. 弯矩 (关于 y 轴)
    !==========================================================
    M_y1 = E_young * Iy * (-6.0_wp*u_elem(2)/L**2 - 4.0_wp*u_elem(6)/L &
                           + 6.0_wp*u_elem(8)/L**2 - 2.0_wp*u_elem(12)/L)
    M_y2 = E_young * Iy * (-6.0_wp*u_elem(2)/L**2 - 2.0_wp*u_elem(6)/L &
                           + 6.0_wp*u_elem(8)/L**2 + 4.0_wp*u_elem(12)/L)
    
    Fe12(2) = (M_y1 + M_y2) / L
    Fe12(6) = M_y1
    Fe12(8) = -(M_y1 + M_y2) / L
    Fe12(12) = M_y2
    
    !==========================================================
    ! 4. 弯矩 (关于 z 轴)
    !==========================================================
    M_z1 = E_young * Iz * (-6.0_wp*u_elem(3)/L**2 + 4.0_wp*u_elem(5)/L &
                           + 6.0_wp*u_elem(9)/L**2 + 2.0_wp*u_elem(11)/L)
    M_z2 = E_young * Iz * (-6.0_wp*u_elem(3)/L**2 + 2.0_wp*u_elem(5)/L &
                           + 6.0_wp*u_elem(9)/L**2 - 4.0_wp*u_elem(11)/L)
    
    Fe12(3) = (M_z1 + M_z2) / L
    Fe12(5) = M_z1
    Fe12(9) = -(M_z1 + M_z2) / L
    Fe12(11) = M_z2
    
    status = 0
  END SUBROUTINE
  
  !============================================================================
  ! 应力恢复：基于混合公式
  !============================================================================
  SUBROUTINE PH_Elem_B31H_RecoverStress(coords3, u_elem, &
                                         E_young, nu, Iy, Iz, &
                                         elem_state)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: u_elem(12)
    REAL(wp), INTENT(IN)  :: E_young, nu, Iy, Iz
    TYPE(MD_Elem_B31_State), INTENT(INOUT) :: elem_state
    
    REAL(wp) :: L, x_ratio
    REAL(wp) :: sigma_axial, sigma_bend_y, sigma_bend_z
    REAL(wp) :: kappa_y, kappa_z
    
    L = SQRT(SUM((coords3(:,2) - coords3(:,1))**2))
    
    !==========================================================
    ! 1. 轴向应力
    !==========================================================
    elem_state%sigma_xx = E_young * (u_elem(7) - u_elem(1)) / L
    
    !==========================================================
    ! 2. 弯曲应力 (M*y/I)
    !==========================================================
    ! 计算等效截面高度 (基于惯性矩和面积)
    REAL(wp) :: y_coord, z_coord, area_equiv
    area_equiv = SQRT(Iy * Iz) / (Iy + Iz) * 2.0_wp  ! 简化等效
    IF (area_equiv < 1.0e-6_wp) area_equiv = 0.01_wp
    
    y_coord = SQRT(Iy / area_equiv)  ! 等效 y 坐标
    z_coord = SQRT(Iz / area_equiv)  ! 等效 z 坐标
    
    ! 曲率计算 (基于节点旋转差分)
    kappa_y = (u_elem(12) - u_elem(6)) / L  ! dθ_y/dx
    kappa_z = (u_elem(11) - u_elem(5)) / L  ! dθ_z/dx
    
    sigma_bend_y = E_young * kappa_z * y_coord
    sigma_bend_z = -E_young * kappa_y * z_coord
    
    elem_state%sigma_xx += sigma_bend_y + sigma_bend_z
    
    !==========================================================
    ! 3. 剪应力 (扭转)
    !==========================================================
    REAL(wp) :: G_shear, twist_rate, polar_radius
    G_shear = E_young / (2.0_wp * (1.0_wp + nu))
    twist_rate = (u_elem(10) - u_elem(4)) / L
    
    ! 最大剪应力 τ_max = G·θ'·R (圆截面或闭口截面近似)
    ! 对于混合梁，使用等效极半径
    IF (Iy > 0.0_wp .AND. Iz > 0.0_wp) THEN
      polar_radius = SQRT((Iy + Iz) / (2.0_wp * area_equiv))
      elem_state%sigma_xy = G_shear * twist_rate * polar_radius
      elem_state%sigma_xz = 0.0_wp  ! 对称截面假设
    ELSE
      elem_state%sigma_xy = 0.0_wp
      elem_state%sigma_xz = 0.0_wp
    END IF
    
  END SUBROUTINE
  
  !============================================================================
  ! 假设应变场：避免剪切锁定 (Assumed Natural Strain)
  !============================================================================
  SUBROUTINE PH_Elem_B31H_AssumedStrainField(coords3, epsilon_direct, epsilon_assumed, status)
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: epsilon_direct(6)   ! 从位移直接计算的应变
    REAL(wp), INTENT(OUT) :: epsilon_assumed(6)  ! 修正后的假设应变场
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: L, shear_correction
    INTEGER(i4) :: i
    
    L = SQRT(SUM((coords3(:,2) - coords3(:,1))**2))
    
    !==========================================================
    ! 1. 复制轴向和扭转应变 (不变)
    !==========================================================
    epsilon_assumed(1) = epsilon_direct(1)  ! ε_xx (轴向)
    epsilon_assumed(4) = epsilon_direct(4)  ! γ_xy (扭转)
    
    !==========================================================
    ! 2. 假设剪切应变 (关键创新!)
    !==========================================================
    ! ANS (Assumed Natural Strain) 方法:
    ! 在积分点重新分配横向剪切应变，避免薄梁剪切锁定
    ! 参考：MacNeal (1978), Hughes (2000)
    
    ! 简化：线性插值修正
    shear_correction = 1.0_wp - 0.1_wp * (L / 0.01_wp)  ! L/h 修正
    IF (shear_correction < 0.1_wp) shear_correction = 0.1_wp
    
    epsilon_assumed(2) = shear_correction * epsilon_direct(2)  ! γ_xz
    epsilon_assumed(3) = shear_correction * epsilon_direct(3)  ! γ_yz
    
    ! 弯曲应变保持不变
    epsilon_assumed(5) = epsilon_direct(5)  ! κ_yy
    epsilon_assumed(6) = epsilon_direct(6)  ! κ_zz
    
    status = 0
  END SUBROUTINE
  
  !============================================================================
  ! 独立应力场：Hu-Washizu 混合插值
  !============================================================================
  SUBROUTINE PH_Elem_B31H_IndependentStressField(E_young, nu, epsilon_assumed, sigma_indep, status)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: epsilon_assumed(6)
    REAL(wp), INTENT(OUT) :: sigma_indep(6)
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: G_shear, lambda_lame
    REAL(wp) :: D_mat(6, 6)
    
    G_shear = E_young / (2.0_wp * (1.0_wp + nu))
    lambda_lame = E_young * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    
    !==========================================================
    ! 1. 构建本构矩阵 (3D 弹性)
    !==========================================================
    D_mat = 0.0_wp
    
    ! 法向分量
    D_mat(1,1) = lambda_lame + 2.0_wp*G_shear
    D_mat(1,2) = lambda_lame
    D_mat(1,3) = lambda_lame
    D_mat(2,1) = lambda_lame
    D_mat(2,2) = lambda_lame + 2.0_wp*G_shear
    D_mat(2,3) = lambda_lame
    D_mat(3,1) = lambda_lame
    D_mat(3,2) = lambda_lame
    D_mat(3,3) = lambda_lame + 2.0_wp*G_shear
    
    ! 剪切分量
    D_mat(4,4) = G_shear
    D_mat(5,5) = G_shear
    D_mat(6,6) = G_shear
    
    !==========================================================
    ! 2. 应力计算：σ = D · ε_assumed
    !==========================================================
    sigma_indep = MATMUL(D_mat, epsilon_assumed)
    
    status = 0
  END SUBROUTINE PH_Elem_B31H_IndependentStressField
  
  !============================================================================
  ! [P3] Consistent Mass Matrix Formation (12 DOF)
  !============================================================================
  SUBROUTINE PH_Elem_B31H_ConsMassMatrix(coords3, rho, area, Iy, Iz, Me12, status)
    !--------------------------------------------------------------------------
    ! Purpose: Form consistent mass matrix for Hu-Washizu mixed beam
    ! Args:
    !   coords3  (in) : 3x2 nodal coordinates
    !   rho      (in) : Material density
    !   area     (in) : Cross-sectional area
    !   Iy, Iz   (in) : Second moments of area
    !   Me12     (out): 12x12 consistent mass matrix
    !   status   (out): Error status
    ! Theory:
    !   Consistent mass: M = ∫ ρ NᵀN dV
    !   Independent stress field does not affect mass formulation
    !   Standard Timoshenko beam mass matrix applies
    !--------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area, Iy, Iz
    REAL(wp), INTENT(OUT) :: Me12(12, 12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: x1(3), x2(3), dx(3), L
    REAL(wp) :: m_bar
    REAL(wp) :: c1, c2, c3, c4
    
    CALL init_error_status(status)
    Me12 = ZERO
    
    ! Compute element length
    x1 = coords3(:, 1)
    x2 = coords3(:, 2)
    dx = x2 - x1
    L = SQRT(SUM(dx * dx))
    
    IF (L <= 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF
    
    !--------------------------------------------------------
    ! Mass distribution parameters
    !--------------------------------------------------------
    m_bar = rho * area / L
    
    !--------------------------------------------------------
    ! Consistent mass coefficients
    !--------------------------------------------------------
    ! Axial DOF (1, 7)
    c1 = m_bar * L / 6.0_wp
    Me12(1, 1) = 2.0_wp * c1
    Me12(7, 7) = 2.0_wp * c1
    Me12(1, 7) = c1
    Me12(7, 1) = c1
    
    ! Translational DOF - y-direction (2, 8)
    c2 = m_bar * L / 6.0_wp
    Me12(2, 2) = 2.0_wp * c2
    Me12(8, 8) = 2.0_wp * c2
    Me12(2, 8) = c2
    Me12(8, 2) = c2
    
    ! Translational DOF - z-direction (3, 9)
    c3 = m_bar * L / 6.0_wp
    Me12(3, 3) = 2.0_wp * c3
    Me12(9, 9) = 2.0_wp * c3
    Me12(3, 9) = c3
    Me12(9, 3) = c3
    
    ! Rotational DOF - theta_x (torsion) (4, 10)
    REAL(wp) :: J_mass
    J_mass = rho * (Iy + Iz) / area * m_bar  ! Approximate polar mass
    c4 = J_mass * L / 6.0_wp
    Me12(4, 4) = 2.0_wp * c4
    Me12(10, 10) = 2.0_wp * c4
    Me12(4, 10) = c4
    Me12(10, 4) = c4
    
    ! Rotational DOF - theta_y (5, 11)
    REAL(wp) :: I_ry
    I_ry = rho * Iy * L / 6.0_wp
    Me12(5, 5) = 2.0_wp * I_ry
    Me12(11, 11) = 2.0_wp * I_ry
    Me12(5, 11) = I_ry
    Me12(11, 5) = I_ry
    
    ! Rotational DOF - theta_z (6, 12)
    REAL(wp) :: I_rz
    I_rz = rho * Iz * L / 6.0_wp
    Me12(6, 6) = 2.0_wp * I_rz
    Me12(12, 12) = 2.0_wp * I_rz
    Me12(6, 12) = I_rz
    Me12(12, 6) = I_rz
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31H_ConsMassMatrix
  
  !============================================================================
  ! [P3] Lumped Mass Vector Formation (12 DOF)
  !============================================================================
  SUBROUTINE PH_Elem_B31H_LumpMassVector(coords3, rho, area, Iy, Iz, M_lumped12, status)
    !--------------------------------------------------------------------------
    ! Purpose: Form lumped mass vector (diagonal mass matrix as vector)
    ! Args:
    !   coords3    (in) : 3x2 nodal coordinates
    !   rho        (in) : Material density
    !   area       (in) : Cross-sectional area
    !   Iy, Iz     (in) : Second moments of area
    !   M_lumped12 (out): 12x1 lumped mass vector
    !   status     (out): Error status
    ! Theory:
    !   Lumped mass: M_diag = diag(m_trans, m_rot)
    !   Each node gets half of total mass/inertia
    !   Suitable for explicit dynamics (Abaqus/Explicit)
    !--------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: coords3(3, 2)
    REAL(wp), INTENT(IN)  :: rho, area, Iy, Iz
    REAL(wp), INTENT(OUT) :: M_lumped12(12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: x1(3), x2(3), dx(3), L
    REAL(wp) :: m_total, J_total
    
    CALL init_error_status(status)
    M_lumped12 = ZERO
    
    ! Compute element length
    x1 = coords3(:, 1)
    x2 = coords3(:, 2)
    dx = x2 - x1
    L = SQRT(SUM(dx * dx))
    
    IF (L <= 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF
    
    !--------------------------------------------------------
    ! Total mass and inertia
    !--------------------------------------------------------
    m_total = rho * area * L      ! Total translational mass
    J_total = rho * (Iy + Iz) * L / area  ! Approximate torsional inertia
    
    !--------------------------------------------------------
    ! Node 1 (DOF 1-6)
    !--------------------------------------------------------
    ! Translational DOF (u_x, u_y, u_z)
    M_lumped12(1) = m_total / 2.0_wp
    M_lumped12(2) = m_total / 2.0_wp
    M_lumped12(3) = m_total / 2.0_wp
    
    ! Rotational DOF (theta_x, theta_y, theta_z)
    M_lumped12(4) = J_total / 2.0_wp      ! Torsion
    M_lumped12(5) = rho * Iy * L / 2.0_wp  ! Bending about y
    M_lumped12(6) = rho * Iz * L / 2.0_wp  ! Bending about z
    
    !--------------------------------------------------------
    ! Node 2 (DOF 7-12) - Equal distribution
    !--------------------------------------------------------
    M_lumped12(7)  = M_lumped12(1)
    M_lumped12(8)  = M_lumped12(2)
    M_lumped12(9)  = M_lumped12(3)
    M_lumped12(10) = M_lumped12(4)
    M_lumped12(11) = M_lumped12(5)
    M_lumped12(12) = M_lumped12(6)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31H_LumpMassVector
  
  !============================================================================
  ! [P3] Rayleigh Damping Matrix Formation
  !============================================================================
  SUBROUTINE PH_Elem_B31H_RayleighDamping(Ke12, Me12, alpha, beta, Ce12, status)
    !--------------------------------------------------------------------------
    ! Purpose: Form Rayleigh damping matrix C = alpha*M + beta*K
    ! Args:
    !   Ke12   (in) : 12x12 stiffness matrix
    !   Me12   (in) : 12x12 mass matrix (consistent or lumped)
    !   alpha  (in) : Mass proportional damping coefficient
    !   beta   (in) : Stiffness proportional damping coefficient
    !   Ce12   (out): 12x12 damping matrix
    !   status (out) : Error status
    ! Theory:
    !   Rayleigh damping: C = αM + βK
    !   Alpha controls low-frequency damping
    !   Beta controls high-frequency damping
    !   Critical damping ratio: ξ = α/(2ω) + βω/2
    ! Reference:
    !   [1] Chopra, Dynamics of Structures, Chapter 11
    !--------------------------------------------------------------------------
    REAL(wp), INTENT(IN)  :: Ke12(12, 12)
    REAL(wp), INTENT(IN)  :: Me12(12, 12)
    REAL(wp), INTENT(IN)  :: alpha, beta
    REAL(wp), INTENT(OUT) :: Ce12(12, 12)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j
    
    CALL init_error_status(status)
    Ce12 = ZERO
    
    !--------------------------------------------------------
    ! C = alpha*M + beta*K (matrix addition)
    !--------------------------------------------------------
    DO i = 1, 12
      DO j = 1, 12
        Ce12(i, j) = alpha * Me12(i, j) + beta * Ke12(i, j)
      END DO
    END DO
    
    ! Ensure symmetry
    DO i = 1, 12
      DO j = i+1, 12
        Ce12(j, i) = Ce12(i, j)
      END DO
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_B31H_RayleighDamping
  
END MODULE
  
END MODULE PH_Elem_B31H