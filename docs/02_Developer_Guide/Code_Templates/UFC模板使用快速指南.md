# UFC 模板使用快速指南

**版本**：v1.0  
**日期**：2026-04-03  
**对象**：三个核心Fortran模板（UMAT/VUMAT/UEL）

---

## 📚 三大模板一览

| 模板 | 用途 | 行数 | 文件路径 |
|------|------|------|---------|
| **UMAT** | 隐式求解器（Standard） | 597 | `UFC/docs/templates/PH_XXX_UMAT.f90` |
| **VUMAT** | 显式求解器（Explicit） | 436 | `UFC/docs/templates/PH_XXX_VUMAT.f90` |
| **UEL** | 用户单元 | 543 | `UFC/docs/templates/PH_XXX_UEL.f90` |

---

## 1️⃣ UMAT 模板 (隐式求解器)

### 快速识别

```
特征码: SUBROUTINE PH_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, ...)
        ↓ 必须返回
        ddsdde(6,6)  ← 一致切线模量 (Consistent Tangent)
```

### 使用场景

✅ **何时用UMAT**：
- Abaqus/Standard（隐式动静力学、准静态、热分析）
- 需要Newton-Raphson收敛的求解器
- 小应变、准静态或隐式动力问题

❌ **何时不用UMAT**：
- Abaqus/Explicit（显式动力学）→ 用VUMAT
- 用户自定义单元 → 用UEL

### 工作流程

**第1步：复制并重命名**

```bash
# 从模板复制
cp UFC/docs/templates/PH_XXX_UMAT.f90 \
   UFC/ufc_core/L4_PH/Material/[Family]/PH_[Family]_[Model]_UMAT.f90

# 例如：弹塑性J2模型
cp UFC/docs/templates/PH_XXX_UMAT.f90 \
   UFC/ufc_core/L4_PH/Material/Plastic/PH_Pls_J2_UMAT.f90
```

**第2步：全局替换**

在编辑器中执行全局替换（Find & Replace）：
- `XXX` → 你的模型名（如 `Pls_J2`）
- `MD_Mat_XXX_Desc` → 实际Desc类型（如 `MD_Mat_Pls_J2_Desc`）
- `PH_Mat_XXX_State` → 实际State类型（如 `PH_Mat_Pls_J2_State`）

**第3步：填充模型特定内容**

```fortran
! 在模板中找到这几个关键位置：

!-- 位置1：定义State类型（第139-146行）
TYPE, PUBLIC, EXTENDS(MD_Mat_Base_State) :: PH_Mat_XXX_State
  !-- TODO: replace placeholders with actual model ISVs
  REAL(wp) :: peeq       = 0.0_wp    ! 等效塑性应变
  REAL(wp) :: back_stress(6) = 0.0_wp ! 动硬化应力
  ! ... 添加你的内部状态变量
END TYPE

!-- 位置2：弹性刚度矩阵（第313行，XXX_Build_D_el）
SUBROUTINE XXX_Build_D_el(MD_Mat_Desc, D)
  ! 从 MD_Mat_Desc%E, MD_Mat_Desc%nu 构建Voigt 6×6 矩阵
  ! 现在是stub，需要实现
END SUBROUTINE

!-- 位置3：屈服函数（第327行，XXX_Yield_F）
FUNCTION XXX_Yield_F(MD_Mat_Desc, sigma, kappa) RESULT(f)
  ! J2 von Mises: f = q - (sigma_y + H*kappa)
  ! 现在是J2 stub，可按需修改
END FUNCTION

!-- 位置4：返回映射（第336-368行）
! 这是热点路径，实现Newton-Raphson迭代
! 注意：map_ok=.FALSE. 保持到实现完成
```

**第4步：编译检查**

```bash
gfortran -c -std=f2003 -fcheck=all PH_Pls_J2_UMAT.f90
# 应无error（可能有warning）
```

### UMAT 特有约定

#### 返回参数（必须）

```fortran
! PH_Mat_State 中必须包含（在PH_Mat_Base_State中）：
TYPE :: PH_Mat_Base_State
  REAL(wp) :: stress(6)         ! [OUT] 更新后的应力 Cauchy σ
  REAL(wp) :: ddsdde(6,6)       ! [OUT] ← 关键！一致切线模量 (Tangent Stiffness)
  REAL(wp) :: statev(:)         ! [IN/OUT] 状态变量
  ! ...
END TYPE
```

#### Newton-Raphson 返回映射框架

```fortran
! 典型流程（弹塑性）
IF (f_yield <= 0.0_wp) THEN
  ! 纯弹性步
  sigma_new = sigma_old + D_el : Delta_eps
  ddsdde = D_el
ELSE
  ! 塑性步：需要迭代
  DO it = 1, max_iter
    ! 一致条件: f(sigma - 2*mu*d_lambda*n, kappa + d_kappa) = 0
    ! 求解 d_lambda（标量 Newton）
    IF (|f_new| / sigma_ref < tolerance) EXIT
  END DO
  ! 计算算法切线 D_alg
  IF (MD_Mat_Algo%compute_tangent) THEN
    ddsdde = D_el - correction  ! Schur补或其他
  END IF
END IF
```

---

## 2️⃣ VUMAT 模板 (显式求解器)

### 快速识别

```
特征码: SUBROUTINE PH_XXX_VUMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, ...)
        ↓ 关键差异
        无需返回 ddsdde  ← 显式求解器不用切线
        应变率 strain_rate(:)  ← 必须处理
        能量 enerinc(nblock,8)  ← 必须跟踪
        CFL 稳定性检查  ← 显式必须
```

### 使用场景

✅ **何时用VUMAT**：
- Abaqus/Explicit（显式动力学）
- 应变率相关材料（如Johnson-Cook）
- 冲击、爆炸、高速变形
- 需要能量平衡验证的问题

❌ **何时不用VUMAT**：
- Abaqus/Standard（隐式）→ 用UMAT
- 需要一致切线的求解器 → 用UMAT

### 工作流程

**第1步：复制并重命名**

```bash
cp UFC/docs/templates/PH_XXX_VUMAT.f90 \
   UFC/ufc_core/L4_PH/Material/[Family]/PH_[Family]_[Model]_VUMAT.f90
```

**第2步：全局替换**

同UMAT的做法。

**第3步：填充模型特定内容**

```fortran
!-- 关键位置1：应变率参数（约第120-135行）
TYPE, PUBLIC :: PH_XXX_VUMAT_Args
  !-- [IN] 显式特定参数
  INTEGER(i4) :: nblock          ! 积分点块数
  REAL(wp), ALLOCATABLE :: strain_rate(:)  ! [nblock] 应变率
  REAL(wp), ALLOCATABLE :: density(:)      ! [nblock] 密度
  REAL(wp), ALLOCATABLE :: celent(:)       ! [nblock] 特征长度
  
  !-- [OUT] 显式输出
  REAL(wp), ALLOCATABLE :: enerinc(:,:)    ! [nblock,8] 能量分解
  REAL(wp), ALLOCATABLE :: cfl_number(:)   ! [nblock] CFL安全系数
END TYPE

!-- 关键位置2：向量化循环（约第200-250行）
DO i = 1, args%nblock
  ! 单个积分点 i 的本构计算
  ! - 从 strain_rate(i) 获取应变率
  ! - 计算 stress_new(i,:)、enerinc(i,:)、cfl_number(i)
  ! - 无需迭代（单步直接返回）
END DO

!-- 关键位置3：应变率效应（约第280-300行）
! Johnson-Cook 模型例子
FUNCTION XXX_Yield_JC(MD_Mat_Desc, sr, temp, D) RESULT(sigma_y)
  REAL(wp) :: sr      ! 应变率 [1/s]
  REAL(wp) :: sigma_y
  
  ! σ_y(sr, T) = (A + B*p^n) * (1 + C*ln(sr/sr_ref)) * (1 - (T*)^m)
  ! sr_ref = 1.0
  sigma_y = (desc%A + desc%B * peq**desc%n) * &
            (1.0_wp + desc%C * LOG(sr / 1.0_wp)) * &
            (1.0_wp - temp_ratio**desc%m)
END FUNCTION

!-- 关键位置4：能量跟踪（约第320-340行）
! 必须填充 args%enerinc(:,:)
DO i = 1, args%nblock
  args%enerinc(i,1) = elastic_energy(i)     ! elastic
  args%enerinc(i,2) = plastic_dissipation(i) ! plastic work
  args%enerinc(i,3) = total_energy_rate(i)  ! total
END DO

!-- 关键位置5：CFL检查（约第350-370行）
! 必须计算并返回 args%cfl_number(:)
DO i = 1, args%nblock
  ! 音速 c = sqrt(K / rho)
  c = SQRT((D_el(1,1) + 2*D_el(1,2)) / (3.0_wp * args%density(i)))
  dt_crit = args%celent(i) / c
  args%cfl_number(i) = dt_crit / current_dt
  
  IF (args%cfl_number(i) < 0.5_wp) THEN
    ! 警告：CFL数太小，可能不稳定
  END IF
END DO
```

### VUMAT 特有约定

#### 向量化处理

```fortran
! VUMAT 的核心特色：NBLOCK个积分点同时处理（性能）
! 所有数组第一维 = nblock

SUBROUTINE PH_XXX_VUMAT_Impl(..., args)
  TYPE(PH_XXX_VUMAT_Args), INTENT(INOUT) :: args
  
  ! NBLOCK个积分点同时循环
  DO i = 1, args%nblock
    ! 应变
    dstran_i(1:ntens) = PH_Mat_Ctx%dstran(i,1:ntens)  ! ← 第一维是nblock
    
    ! 应力返回
    sigma_new_i(1:ntens) = return_mapping(sigma_old_i(1:ntens), dstran_i)
    
    ! 更新输出（enerinc, cfl_number等）
    args%enerinc(i,:) = compute_energy(...)
    args%cfl_number(i) = compute_cfl(...)
  END DO
END SUBROUTINE
```

#### 应变率依赖性

```fortran
! 显式求解器使用中心差分积分，应变率自然出现
! sr = strain / time_step

! Johnson-Cook 型材料的典型处理
REAL(wp) :: sr_log     ! log10(strain_rate)
REAL(wp) :: temp_factor, sr_factor

sr_log = LOG10(strain_rate(i))
sr_factor = 1.0_wp + C * sr_log  ! ← strain_rate dependent

! 屈服应力 = base * strain_rate_factor
sigma_yield = sigma_yield_0 * sr_factor
```

#### CFL 稳定性

```fortran
! Explicit 显式求解器的稳定性条件
! Δt_critical = celent / c_sound
! 其中 c_sound = sqrt(K/ρ)

! VUMAT 必须检查并返回 cfl_number
cfl_number = Δt_critical / Δt_actual

IF (cfl_number < 1.0) THEN
  ! 不稳定 → 自动cut step (pnewdt < 1)
END IF
```

---

## 3️⃣ UEL 模板 (用户单元)

### 快速识别

```
特征码: SUBROUTINE PH_XXX_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, ...)
        ↓ 核心
        计算单元刚度矩阵 amatrx(:,:)
        计算单元残差向量 rhs(:,:)
        调用材料子程序 (UMAT)
```

### 使用场景

✅ **何时用UEL**：
- 特殊单元（不在ABAQUS标准库中）
- 复杂单元行为（如裂纹、接触、特殊几何）
- 单元与材料的深度耦合

❌ **何时不用UEL**：
- 标准单元（C3D8, S4R, B31等）→ 用内置单元
- 简单材料修改 → 用UMAT/VUMAT

### 工作流程

**第1步：复制并重命名**

```bash
cp UFC/docs/templates/PH_XXX_UEL.f90 \
   UFC/ufc_core/L4_PH/Element/[Family]/PH_[ElemType]_UEL.f90

# 例如：自定义四面体单元
cp UFC/docs/templates/PH_XXX_UEL.f90 \
   UFC/ufc_core/L4_PH/Element/Solid3D/PH_C3D4_Custom_UEL.f90
```

**第2步：全局替换**

- `XXX` → `C3D4_Custom` 或你的单元类型

**第3步：填充单元特定内容**

```fortran
!-- 关键位置1：积分点和形函数（约第150-200行）
SUBROUTINE XXX_Shape_Functions(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
  REAL(wp), INTENT(IN)  :: xi, eta, zeta  ! 局部坐标 [-1,1]
  REAL(wp), INTENT(OUT) :: N(nnodes)
  REAL(wp), INTENT(OUT) :: dN_dxi(nnodes), dN_deta(nnodes), dN_dzeta(nnodes)
  
  ! 四节点四面体的线性形函数
  ! N(1) = (1-xi)*(1-eta)*(1-zeta) / 8
  ! ... （标准形函数库）
END SUBROUTINE

!-- 关键位置2：Jacobian矩阵（约第220-250行）
SUBROUTINE XXX_Jacobian(dN_dxi, coords, J, dN_dx, dN_dy, dN_dz, det_J)
  REAL(wp), INTENT(IN)  :: dN_dxi(:,:), coords(:,:)  ! [3, nnodes]
  REAL(wp), INTENT(OUT) :: J(3,3), det_J
  REAL(wp), INTENT(OUT) :: dN_dx(:), dN_dy(:), dN_dz(:)
  
  ! J = dN/dxi * coords^T
  ! dN/dx = J^{-1} * dN/dxi
END SUBROUTINE

!-- 关键位置3：应变-位移矩阵B（约第270-300行）
SUBROUTINE XXX_B_Matrix(dN_dx, dN_dy, dN_dz, B)
  REAL(wp), INTENT(IN)  :: dN_dx(:), dN_dy(:), dN_dz(:)  ! [nnodes]
  REAL(wp), INTENT(OUT) :: B(:,:)  ! [6, ndofel]
  
  ! 标准应变-位移矩阵
  ! B = [dN_dx    0      0   ]
  !     [  0    dN_dy    0   ]
  !     [  0      0    dN_dz ]
  !     [dN_dy  dN_dx    0   ]  ← 剪应变耦合
  !     [dN_dz    0    dN_dx ]
  !     [  0    dN_dz  dN_dy ]
END SUBROUTINE

!-- 关键位置4：材料调用（约第350-400行）
! 对每个积分点 ip：
DO ip = 1, nip
  ! 获取该积分点的材料状态
  CALL Load_MatPoint_State(PH_Elem_State%svars, ip, PH_Mat_State)
  
  ! 调用UMAT计算本构关系
  CALL PH_[Family]_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, ...)
  
  ! 存回svars
  CALL Store_MatPoint_State(PH_Elem_State%svars, ip, PH_Mat_State)
  
  ! 提取应力用于积分
  sigma_gp(ip,:) = PH_Mat_State%stress(:)
  D_gp(ip,:,:) = PH_Mat_State%ddsdde(:,:)
END DO

!-- 关键位置5：刚度矩阵组装（约第420-450行）
! K = ∫ B^T D B dΩ （数值积分）
amatrx(:,:) = 0.0_wp
DO ip = 1, nip
  ! 获取该IP的体积权重、Jacobian
  wip = w(ip) * det_J(ip)
  
  ! 累加到全局刚度
  amatrx(:,:) = amatrx(:,:) + &
    wip * MATMUL(MATMUL(TRANSPOSE(B(ip,:,:)), D_gp(ip,:,:)), B(ip,:,:))
END DO

!-- 关键位置6：残差向量组装（约第460-480行）
! R = ∫ B^T σ dΩ - f_ext
rhs(:,:) = 0.0_wp
DO ip = 1, nip
  wip = w(ip) * det_J(ip)
  rhs(:,:) = rhs(:,:) + wip * MATMUL(TRANSPOSE(B(ip,:,:)), sigma_gp(ip,:))
END DO
rhs(:,:) = rhs(:,:) - external_force(:,:)
```

### UEL 特有约定

#### 状态变量管理（SVARS）

```fortran
! 所有材料积分点的状态存储在 PH_Elem_Base_State%svars(:)
! 须遵循固定的存储布局

! 典型布局（per IP）：
! svars(1:6) = σ (stress)
! svars(7:12) = ε (strain)
! svars(13:18) = 内部变量 (ISV)
! ...
! stride = 18 (per IP)

SUBROUTINE Load_MatPoint_State(svars, ip, PH_Mat_State)
  INTEGER, INTENT(IN) :: ip
  REAL(wp), INTENT(IN) :: svars(:)
  TYPE(PH_Mat_XXX_State), INTENT(OUT) :: PH_Mat_State
  
  INTEGER :: offset
  offset = (ip - 1) * STRIDE + 1
  
  PH_Mat_State%stress(1:6) = svars(offset:offset+5)
  PH_Mat_State%stran(1:6) = svars(offset+6:offset+11)
  PH_Mat_State%ivar1 = svars(offset+12)
  ! ...
END SUBROUTINE

SUBROUTINE Store_MatPoint_State(svars, ip, PH_Mat_State)
  ! 反向操作
  INTEGER :: offset
  offset = (ip - 1) * STRIDE + 1
  
  svars(offset:offset+5) = PH_Mat_State%stress(1:6)
  svars(offset+6:offset+11) = PH_Mat_State%stran(1:6)
  svars(offset+12) = PH_Mat_State%ivar1
END SUBROUTINE
```

#### Section-Material 路由

```fortran
! UEL 使用 Section 注册表来获取材料描述
! sect_registry 由 L5_RT 传入，包含所有可用的材料和截面

SUBROUTINE PH_XXX_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, ...)
  TYPE(MD_Sect_Registry), INTENT(IN) :: sect_registry
  INTEGER :: mat_id, sect_id
  CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc
  
  ! 从单元属性获取截面ID
  sect_id = jprops(1)  ! ← user-defined property 1
  
  ! 从注册表查询材料描述
  mat_desc => sect_registry%get_material(sect_id)
  
  ! 多态调用 SELECT TYPE
  SELECT TYPE(mat_desc)
    TYPE IS (MD_Mat_Pls_J2_Desc)
      CALL PH_Pls_J2_UMAT_API(mat_desc, PH_Mat_Ctx, ...)
    TYPE IS (MD_Mat_Ela_Iso_Desc)
      CALL PH_Ela_Iso_UMAT_API(mat_desc, PH_Mat_Ctx, ...)
    CLASS DEFAULT
      ! 错误处理
  END SELECT
END SUBROUTINE
```

---

## 📋 快速检查清单

### 所有三个模板通用检查

- [ ] **模块名/子程序名** 正确替换（XXX → 实际名）
- [ ] **USE 语句** 指向正确的 MD 和 PH 类型
- [ ] **TYPE 定义** 继承自正确的 Base TYPE
- [ ] **热点代码** 标记 `!$UFC HOT_PATH`（如需）
- [ ] **错误处理** init_error_status 调用正确
- [ ] **编译** `gfortran -c -std=f2003 -fcheck=all` 无error

### UMAT 特定检查

- [ ] `ddsdde(6,6)` 初始化和返回
- [ ] Newton-Raphson 返回映射逻辑完整
- [ ] `MD_Mat_Algo%ntens` 检查（活跃Voigt分量）
- [ ] 能量跟踪字段填充（可选）
- [ ] pnewdt 反馈机制（cutback处理）

### VUMAT 特定检查

- [ ] `strain_rate(:)` 应变率参数处理
- [ ] `nblock` 向量化循环实现
- [ ] `enerinc(nblock,8)` 能量分解计算
- [ ] `cfl_number(:)` CFL稳定性检查
- [ ] ddsdde **不**返回（显式忽略）

### UEL 特定检查

- [ ] 形函数 `N()` 、导数 `dN_d*()` 定义
- [ ] Jacobian 矩阵计算和求逆
- [ ] 应变-位移矩阵 `B(:,:)` 正确
- [ ] 材料调用循环完整（Load → UMAT → Store）
- [ ] 刚度矩阵 `amatrx(:,:)` 数值积分正确
- [ ] 残差向量 `rhs(:,:)` 包含内外力

---

## 🚀 完整工作示例

### 例子：线性弹性材料

```fortran
! 文件：PH_Ela_Iso_UMAT.f90
MODULE PH_Ela_Iso_UMAT
  USE IF_Prec, ONLY: wp
  ! ... USE语句
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Mat_Ela_Iso_State, PH_Ela_Iso_UMAT_API
  
  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_State) :: PH_Mat_Ela_Iso_State
    ! 弹性材料无内部变量 → 空或仅继承基类
  END TYPE
  
CONTAINS
  
  SUBROUTINE PH_Ela_Iso_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, ...)
    TYPE(MD_Mat_Ela_Iso_Desc), INTENT(IN) :: MD_Mat_Desc
    TYPE(PH_Mat_Ctx), INTENT(IN) :: PH_Mat_Ctx
    TYPE(PH_Mat_Ela_Iso_State), INTENT(INOUT) :: PH_Mat_State
    
    TYPE(PH_Ela_Iso_UMAT_Args) :: args
    
    args%success = .FALSE.
    CALL PH_Ela_Iso_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, args)
    
  END SUBROUTINE
  
  SUBROUTINE PH_Ela_Iso_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, args)
    !$UFC HOT_PATH
    REAL(wp) :: D_el(6,6), lam, mu
    INTEGER :: ntens
    
    ntens = MD_Mat_Algo%ntens
    
    ! 从Desc提取参数
    lam = MD_Mat_Desc%lambda
    mu = MD_Mat_Desc%mu
    
    ! 构建弹性刚度
    D_el(1,1) = lam + 2*mu
    D_el(2,2) = lam + 2*mu
    D_el(3,3) = lam + 2*mu
    D_el(1,2) = lam
    D_el(2,3) = lam
    D_el(3,1) = lam
    D_el(4,4) = mu
    D_el(5,5) = mu
    D_el(6,6) = mu
    ! ... (对称性)
    
    ! 应力更新：σ = σ_old + D_el : Δε
    PH_Mat_State%stress(1:ntens) = PH_Mat_State%stress(1:ntens) &
      + MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))
    
    ! 切线（弹性 = D_el）
    PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)
    
    ! 应变更新
    PH_Mat_State%stran(1:ntens) = PH_Mat_State%stran(1:ntens) &
      + PH_Mat_Ctx%dstran(1:ntens)
    
    args%success = .TRUE.
    
  END SUBROUTINE
  
END MODULE PH_Ela_Iso_UMAT
```

---

## 📖 参考链接

- **设计文档**：`docs/05_Project_Planning/PPLAN/03_实施规划/单元域改造/UFC-UMAT-VUMAT-UEL架构决策文档.md`
- **分类论证**：`docs/05_Project_Planning/PPLAN/03_实施规划/单元域改造/材料-单元域联合分类论证.md`
- **执行清单**：`docs/05_Project_Planning/PPLAN/03_实施规划/单元域改造/UFC架构决策执行清单.md`
- **契约** (合同)：`UFC/ufc_core/L4_PH/contracts/CONTRACT_UMAT_Implicit.md` 等
- **SIO规范**：`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md` §Principle #14

---

**版本**：v1.0  
**日期**：2026-04-03  
**作者**：UFC架构团队
