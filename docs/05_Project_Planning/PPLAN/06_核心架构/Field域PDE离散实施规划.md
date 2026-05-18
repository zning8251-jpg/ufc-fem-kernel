# L4_PH/Field域 PDE离散实施规划

## 📋 任务概览

**目标**: 将Field域从占位符实现升级为完整PDE求解器
**范围**: 温度场/孔隙压力场/浓度场的显式/隐式求解
**依赖**: L4_PH/Element域形函数库、高斯积分库、Jacobian计算

---

## 🎯 P1阶段实施规划 (预计6-10小时)

### P1-1: 形函数库集成 (2-3小时)

#### 依赖分析
L4_PH/Element域已提供以下接口:
- `PH_Elem_C3D8_ShapeFunc`: C3D8单元形函数N(ξ,η,ζ)和dN/dξ
- `PH_Elem_C3D4_ShapeFunc`: C3D4单元形函数
- `PH_Elem_C3D20_ShapeFunc`: C3D20单元形函数
- `PH_Elem_Jacobian_*`: Jacobian计算、逆矩阵、dN/dx变换

#### 实施步骤

**Step 1**: 创建Field域通用形函数适配器
```fortran
! 文件: PH_Field_ShapeFunc.f90
MODULE PH_Field_ShapeFunc
  ! 封装Element域的形函数接口,提供统一调用
  ! 输入: elem_type, coords, gp_coords
  ! 输出: N(:), dN_dx(:,:)
END MODULE
```

**Step 2**: 在Laplacian组装中集成形函数
```fortran
! 修改: PH_Field_Assemble_ThermalLaplacian
! 伪代码:
DO e = 1, nelem
  ! 1. 提取单元节点坐标
  coords_e = coords(:, conn(:, e))
  
  ! 2. 高斯积分循环
  DO gp = 1, n_gp
    ! 3. 调用形函数适配器
    CALL PH_Field_GetShapeFunctionGradient( &
      elem_type, coords_e, xi_gp(gp), eta_gp(gp), zeta_gp(gp), &
      N, dN_dx)
    
    ! 4. 计算单元刚度矩阵
    DO i = 1, npe
      DO j = 1, npe
        K_e(i,j) = K_e(i,j) + w_gp(gp) * conductivity * &
          DOT_PRODUCT(dN_dx(:,i), dN_dx(:,j)) * detJ
      END DO
    END DO
  END DO
  
  ! 5. 组装到全局
  CALL Assemble_Global(K_global, conn(:,e), K_e)
END DO
```

**验收标准**:
- ✅ 形函数调用链路打通(Field→Element)
- ✅ dN/dx计算正确(参考→物理坐标变换)
- ✅ detJ>0检查(网格质量验证)

---

### P1-2: 高斯积分实现 (2-3小时)

#### 数学基础
**体积分**(3D):
```
∫Ω f(x) dΩ = ∑_gp w_gp · f(ξ_gp, η_gp, ζ_gp) · det(J)
```

**面积分**(边界):
```
∫Γ f(x) dΓ = ∑_gp w_gp · f(ξ_gp, η_gp) · ||∂x/∂ξ × ∂x/∂η||
```

**线积分**(2D边界):
```
∫Γ f(x) dΓ = ∑_gp w_gp · f(ξ_gp) · ||∂x/∂ξ||
```

#### 实施步骤

**Step 1**: 创建Field域高斯积分器
```fortran
! 文件: PH_Field_GaussQuadrature.f90
MODULE PH_Field_GaussQuadrature
  ! 提供1D/2D/3D高斯积分点与权重
  ! 接口:
  !   - GetGaussPoints1D(n_gp) → xi(:), w(:)
  !   - GetGaussPoints2D(n_gp) → xi(:), eta(:), w(:)
  !   - GetGaussPoints3D(n_gp) → xi(:), eta(:), zeta(:), w(:)
END MODULE
```

**Step 2**: 实现Laplacian体积分
```fortran
! 修改: PH_Field_Assemble_ThermalLaplacian
! 关键代码:
CALL GetGaussPoints3D(2, xi_gp, eta_gp, zeta_gp, w_gp)  ! 2×2×2积分

DO gp = 1, SIZE(w_gp)
  ! 形函数梯度
  CALL GetShapeFunctionGradient(coords_e, xi_gp(gp), eta_gp(gp), zeta_gp(gp), &
                                dN_dx, detJ)
  
  ! K_e(i,j) = ∑ w_gp · k · ∇Nᵢ·∇Nⱼ · detJ
  DO i = 1, npe
    DO j = 1, npe
      grad_dot = DOT_PRODUCT(dN_dx(:,i), dN_dx(:,j))
      K_e(i,j) = K_e(i,j) + w_gp(gp) * conductivity * grad_dot * detJ
    END DO
  END DO
END DO
```

**Step 3**: 实现质量矩阵积分
```fortran
! PH_Field_Assemble_ThermalMass
! M_e(i,j) = ∑ w_gp · ρ·cp · Nᵢ·Nⱼ · detJ
DO gp = 1, n_gp
  CALL GetShapeFunctions(xi_gp(gp), eta_gp(gp), zeta_gp(gp), N)
  DO i = 1, npe
    DO j = 1, npe
      M_e(i,j) = M_e(i,j) + w_gp(gp) * density * heat_capacity * &
                 N(i) * N(j) * detJ
    END DO
  END DO
END DO
```

**验收标准**:
- ✅ 1D/2D/3D高斯积分正确实现
- ✅ 体积分/面积分/线积分区分处理
- ✅ 积分点数可配置(1/2/3点高斯)

---

### P1-3: Neumann/Robin BC实现 (1.5-2小时)

#### 数学表达

**Neumann BC** (固定通量):
```
-k·∂T/∂n = q at Γ_N
F_i += ∫Γ_N Nᵢ·q dΓ = ∑_gp w_gp · Nᵢ(ξ_gp) · q · det(J_face)
```

**Robin BC** (对流换热):
```
-k·∂T/∂n = h·(T - T∞) at Γ_R
K_ij += ∫Γ_R h·Nᵢ·Nⱼ dΓ
F_i  += ∫Γ_R h·T∞·Nᵢ dΓ
```

#### 实施步骤

**Step 1**: 实现Neumann BC面积分
```fortran
! 修改: PH_Field_Apply_ThermalBC_Neumann
SUBROUTINE PH_Field_Apply_ThermalBC_Neumann(F_global, bc_faces, &
                                              flux_values, conn, coords, status)
  ! 对每个边界面积分
  DO f = 1, n_faces
    face_nodes = bc_faces(:, f)
    coords_face = coords(:, face_nodes)
    
    ! 2D面积分(边界是2D面)
    CALL GetGaussPoints2D(2, xi_gp, eta_gp, w_gp)
    
    DO gp = 1, SIZE(w_gp)
      CALL GetShapeFunctions_Face(xi_gp(gp), eta_gp(gp), N_face)
      detJ_face = ComputeFaceJacobian(coords_face, xi_gp(gp), eta_gp(gp))
      
      DO i = 1, n_face_nodes
        F_global(face_nodes(i)) = F_global(face_nodes(i)) + &
          w_gp(gp) * N_face(i) * flux_values(f) * detJ_face
      END DO
    END DO
  END DO
END SUBROUTINE
```

**Step 2**: 实现Robin BC面积分
```fortran
! 修改: PH_Field_Apply_ThermalBC_Robin
! 同时修改K和F
DO gp = 1, n_gp
  CALL GetShapeFunctions_Face(xi_gp, eta_gp, N_face)
  detJ_face = ComputeFaceJacobian(...)
  
  DO i = 1, n_face_nodes
    DO j = 1, n_face_nodes
      K_global(face_nodes(i), face_nodes(j)) = K_global(...) + &
        w_gp * h_coeff * N_face(i) * N_face(j) * detJ_face
    END DO
    F_global(face_nodes(i)) = F_global(...) + &
      w_gp * h_coeff * T_inf * N_face(i) * detJ_face
  END DO
END DO
```

**验收标准**:
- ✅ Neumann BC通量守恒验证
- ✅ Robin BC对流换热系数正确应用
- ✅ 边界Jacobian计算准确(`||∂x/∂ξ × ∂x/∂η||`)

---

### P1-4: 质量集中(可选) (0.5-1小时)

#### 方法对比

**行求和技术**(推荐):
```
M_ii = ∑_j M_ij (保守质量)
```

**HRZ集中**(高质量):
```
M_ii = (M_ij_row_sum / trace(M_consistent)) * total_mass
```

#### 实施步骤
```fortran
! 修改: PH_Field_Assemble_ThermalMass (添加质量集中选项)
IF (algo%use_mass_lumping) THEN
  ! 行求和
  DO i = 1, nnode
    M_lumped(i) = SUM(M_consistent(i, :))
  END DO
ELSE
  M_lumped = M_consistent  ! 保持一致质量矩阵
END IF
```

**验收标准**:
- ✅ 质量守恒: ∑M_lumped = ∑M_consistent
- ✅ 显式求解器稳定性提升

---

## 🚀 P2阶段实施规划 (预计12-18小时)

### P2-1: 线性求解器 (6-8小时)

#### 算法选择

| 算法 | 适用场景 | 复杂度 | 实现难度 |
|:-----|:---------|:-------|:---------|
| **共轭梯度(CG)** | 对称正定(K对称) | O(n·√κ) | ⭐⭐⭐ |
| **GMRES** | 非对称/Robin BC | O(n·m) | ⭐⭐⭐⭐ |
| **LU直接法** | 小规模(n<1000) | O(n³) | ⭐⭐ |

#### 实施步骤

**Step 1**: 共轭梯度法
```fortran
! 文件: PH_Field_Solver_CG.f90
SUBROUTINE PH_Field_Solve_CG(A, b, x, tol, max_iter, status)
  ! Ax = b (A对称正定)
  ! 算法:
  !   r₀ = b - Ax₀
  !   p₀ = r₀
  !   FOR k = 0, 1, ...
  !     α_k = (r_k^T·r_k) / (p_k^T·A·p_k)
  !     x_{k+1} = x_k + α_k·p_k
  !     r_{k+1} = r_k - α_k·A·p_k
  !     IF ||r_{k+1}|| < tol, RETURN
  !     β_k = (r_{k+1}^T·r_{k+1}) / (r_k^T·r_k)
  !     p_{k+1} = r_{k+1} + β_k·p_k
END SUBROUTINE
```

**Step 2**: GMRES(带restart)
```fortran
! 文件: PH_Field_Solver_GMRES.f90
SUBROUTINE PH_Field_Solve_GMRES(A, b, x, tol, max_iter, restart, status)
  ! Ax = b (A非对称)
  ! Arnoldi过程 + Givens旋转
END SUBROUTINE
```

**Step 3**: LU直接法(小规模)
```fortran
! 文件: PH_Field_Solver_LU.f90
SUBROUTINE PH_Field_Solve_LU(A, b, x, status)
  ! LAPACK: DGESV
  CALL DGESV(n, 1, A, lda, ipiv, b, ldb, info)
  x = b
END SUBROUTINE
```

**验收标准**:
- ✅ CG: 对称正定测试矩阵收敛
- ✅ GMRES: Robin BC非对称系统收敛
- ✅ LU: 小规模问题精确解

---

### P2-2: 隐式求解器集成 (4-6小时)

#### 求解链路
```
装配K, M, F → 应用BC → 组装系统矩阵A → 求解Ax=b → 后处理
```

#### 实施步骤
```fortran
! 修改: PH_Field_Compute_Temperature_Implicit
SUBROUTINE PH_Field_Compute_Temperature_Implicit(desc, algo, in, out, status)
  ! Step 1: 装配
  CALL PH_Field_Assemble_ThermalLaplacian(..., K, ...)
  CALL PH_Field_Assemble_ThermalMass(..., M, ...)
  CALL PH_Field_Assemble_HeatSource(..., F, ...)
  
  ! Step 2: 应用BC
  CALL PH_Field_Apply_ThermalBC_Dirichlet(K, F, ...)
  CALL PH_Field_Apply_ThermalBC_Neumann(F, ...)
  CALL PH_Field_Apply_ThermalBC_Robin(K, F, ...)
  
  ! Step 3: 组装系统矩阵 A = M + dt·K
  A = M + in%time_step * K
  
  ! Step 4: 组装右端项 b = M·T^n + dt·F
  b = MATMUL(M, in%temperature) + in%time_step * F
  
  ! Step 5: 求解线性系统
  IF (IsSymmetricPositiveDefinite(A)) THEN
    CALL PH_Field_Solve_CG(A, b, out%temperature, algo%tolerance, &
                           algo%max_iterations, status)
  ELSE
    CALL PH_Field_Solve_GMRES(A, b, out%temperature, ...)
  END IF
  
  ! Step 6: 后处理(热通量计算)
  CALL Compute_HeatFlux(out%temperature, out%heat_flux)
END SUBROUTINE
```

**验收标准**:
- ✅ 隐式求解器无条件稳定验证
- ✅ 时间步长无关性测试
- ✅ 能量守恒检查

---

### P2-3: 源项完整集成 (2-4小时)

#### 源项类型

| 场 | 源项 | 数学表达 | 物理意义 |
|:---|:-----|:---------|:---------|
| 温度 | 体热源Q | F_i=∫Ω Nᵢ·Q dΩ | 内部发热 |
| 孔隙压力 | 流体源q | F_i=∫Ω Nᵢ·q/ρ dΩ | 注入/抽出 |
| 浓度 | 反应源S | F_i=∫Ω Nᵢ·S dΩ | 化学反应 |

#### 实施步骤
```fortran
! 修改: PH_Field_Assemble_HeatSource
SUBROUTINE PH_Field_Assemble_HeatSource(coords, conn, heat_gen_rate, &
                                         F_global, status)
  ! 支持空间变化源项
  IF (IS_SCALAR(heat_gen_rate)) THEN
    ! 均匀源项: Q = const
    DO e = 1, nelem
      DO gp = 1, n_gp
        CALL GetShapeFunctions(..., N)
        detJ = ComputeJacobian(...)
        DO i = 1, npe
          F_e(i) = F_e(i) + w_gp * heat_gen_rate * N(i) * detJ
        END DO
      END DO
      CALL Assemble_Global(F_global, conn(:,e), F_e)
    END DO
  ELSE
    ! 空间变化源项: Q = Q(x,y,z)
    DO e = 1, nelem
      coords_e = coords(:, conn(:,e))
      DO gp = 1, n_gp
        xi = xi_gp(gp); eta = eta_gp(gp); zeta = zeta_gp(gp)
        CALL GetShapeFunctions(xi, eta, zeta, N)
        detJ = ComputeJacobian(coords_e, ...)
        
        ! 计算GP物理坐标
        x_gp = MATMUL(coords_e, N)
        
        ! 调用用户自定义源项函数
        Q_gp = UserDefinedHeatSource(x_gp)
        
        DO i = 1, npe
          F_e(i) = F_e(i) + w_gp * Q_gp * N(i) * detJ
        END DO
      END DO
      CALL Assemble_Global(F_global, conn(:,e), F_e)
    END DO
  END IF
END SUBROUTINE
```

**验收标准**:
- ✅ 均匀源项解析解对比
- ✅ 空间变化源项积分精度
- ✅ 源项量纲检查

---

## 📊 实施时间线

| 阶段 | 任务 | 工时 | 依赖 | 优先级 |
|:-----|:-----|:----:|:-----|:------:|
| **P1-1** | 形函数库集成 | 2-3h | Element域接口 | 🔴 P0 |
| **P1-2** | 高斯积分实现 | 2-3h | P1-1 | 🔴 P0 |
| **P1-3** | Neumann/Robin BC | 1.5-2h | P1-2 | 🟡 P1 |
| **P1-4** | 质量集中 | 0.5-1h | P1-2 | 🟢 P2 |
| **P2-1** | 线性求解器 | 6-8h | P1 | 🔴 P0 |
| **P2-2** | 隐式求解器集成 | 4-6h | P2-1 | 🔴 P0 |
| **P2-3** | 源项完整集成 | 2-4h | P1-2 | 🟡 P1 |
| **总计** | - | **18-27h** | - | - |

---

## ✅ 验收标准

### Patch Test验证

**1D热传导Patch Test**:
```
域: [0, L], T(0)=T₀, T(L)=T₁, Q=0
解析解: T(x) = T₀ + (T₁-T₀)·x/L
验收: ||T_FEM - T_exact||_∞ < 1e-6
```

**2D稳态热传导**:
```
域: [0,1]×[0,1], T(x,0)=0, T(x,1)=100, 绝热侧面
解析解: T(x,y) = 100·y
验收: 最大误差 < 0.01%
```

### 收敛性验证

**时间收敛**(隐式):
```
dt → dt/2, 误差减半 → O(dt)一阶收敛
```

**空间收敛**:
```
h → h/2, 误差减半 → O(h)一阶(线性单元)
h → h/2, 误差减1/4 → O(h²)二阶(二次单元)
```

### 物理守恒验证

**能量守恒**:
```
∫Ω ρ·cp·∂T/∂t dΩ + ∫Γ q·n dΓ = ∫Ω Q dΩ
```

**质量守恒**(浓度场):
```
d/dt ∫Ω c dΩ + ∫Γ J·n dΓ = ∫Ω S dΩ
```

---

## 🔧 关键技术难点

### 难点1: 边界Jacobian计算
**问题**: 边界积分的detJ_face计算
**解决方案**: 
```fortran
! 3D单元的面边界(2D积分)
detJ_face = NORM2(CROSS_PRODUCT(dx_dxi, dx_deta))

! 2D单元的边边界(1D积分)
detJ_edge = NORM2(dx_dxi)
```

### 难点2: 非对称系统求解
**问题**: Robin BC导致K非对称,CG不适用
**解决方案**: 使用GMRES或BiCGSTAB

### 难点3: 大规模求解器效率
**问题**: 直接法O(n³)不可接受(n>10000)
**解决方案**: 
- 预处理共轭梯度(PCG): ILU/AMG预处理
- 并行求解器: PETSc/Trilinos集成(远期)

---

## 📝 实施检查清单

### P1阶段检查
- [ ] 形函数适配器编译通过
- [ ] dN/dx变换正确(J_inv验证)
- [ ] 1D/2D/3D高斯积分点正确
- [ ] Laplacian矩阵对称正定
- [ ] 质量矩阵正定
- [ ] Dirichlet BC消元正确
- [ ] Neumann BC通量守恒
- [ ] Robin BC对流系数正确

### P2阶段检查
- [ ] CG求解器对称正定测试通过
- [ ] GMRES求解器非对称测试通过
- [ ] LU直接法小规模测试通过
- [ ] 隐式求解器时间步长无关性
- [ ] 源项积分精度验证
- [ ] 1D/2D Patch Test通过
- [ ] 能量/质量守恒验证

---

## 🎯 下一步行动

1. **立即执行**: P1-1形函数库集成(2-3小时)
2. **依赖确认**: 检查Element域形函数接口稳定性
3. **单元测试**: 为每个子程序编写测试用例
4. **集成测试**: 1D热传导Patch Test验证
5. **性能测试**: 大规模问题(n=10000)求解时间

**预计完成时间**: P1阶段3-4天, P2阶段5-7天(全职开发)
