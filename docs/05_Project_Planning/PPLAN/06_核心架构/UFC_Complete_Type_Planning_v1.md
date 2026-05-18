# UFC 类型系统完整规划 —— Desc/State/Algo/Ctx 四层架构

**文档版本**: v1.0  
**创建日期**: 2026-03-28  
**设计原则**: 一子程序一 TYPE 组 + 四级嵌套 + 指针关联

---

## 🎯 核心设计理念

### 设计哲学

```
"数据结构先行，算法随后注入"

Step 1: 定义 TYPE（Desc/State/Algo/Ctx）← 数据结构
Step 2: 建立映射关系（L3→L4→L5）        ← 数据链
Step 3: 实现算法子程序（PH_XXX）          ← 计算链
Step 4: 组装调用流程（RT_驱动）           ← 逻辑链
```

---

### 四级命名体系

```
Level 1: Layer（层级）     → L3_MD / L4_PH / L5_RT
Level 2: Domain（域级）    → Material / Element / Load / BC / ...
Level 3: Role（角色）      → Desc / State / Algo / Ctx
Level 4: Subroutine（子程序）→ UMAT / UEL / DLOAD / DISP / ...

示例：
L3_MD + Material + Desc + UMAT = MD_Mat_UMAT_Desc
L4_PH + Material + State + UMAT = PH_Mat_UMAT_State
L5_RT + Material + Ctx + UMAT = RT_Mat_UMAT_Ctx
```

---

## 📊 完整 Abaqus 子程序 ↔ TYPE 映射矩阵

### A.1 直接作用于单元的子程序

#### 1️⃣ UMAT / VUMAT（材料本构）

```fortran
!=================================================================
! L3_MD: 材料参数定义（不可变配置）
!=================================================================
TYPE :: MD_Mat_UMAT_Desc
  !-- 材料标识
  INTEGER(i4) :: mat_id
  CHARACTER(LEN=64) :: mat_name
  INTEGER(i4) :: mat_type  ! 1=弹性，2=塑性，3=超弹性
  
  !-- 材料参数（通用）
  REAL(wp) :: props(:)     ! 材料参数数组
  INTEGER(i4) :: nprops    ! 参数个数
  
  !-- 状态变量定义
  INTEGER(i4) :: nstatev   ! 状态变量个数
  CHARACTER(LEN=32) :: statev_names(:)  ! 状态变量名称
  
  !-- 依赖标志
  LOGICAL :: temp_dependent   ! 温度相关
  LOGICAL :: rate_dependent   ! 率相关
  LOGICAL :: large_strain     ! 大应变
  
END TYPE

!=================================================================
! L4_PH: 材料点状态（解依赖）
!=================================================================
TYPE :: PH_Mat_UMAT_State
  !-- 输入状态（t^n）
  REAL(wp) :: strain_old(6)     ! 旧应变
  REAL(wp) :: stress_old(6)     ! 旧应力
  REAL(wp) :: statev_old(:)     ! 旧状态变量
  
  !-- 输出状态（t^{n+1}）
  REAL(wp) :: stress_new(6)     ! 新应力
  REAL(wp) :: statev_new(:)     ! 新状态变量
  REAL(wp) :: tangent(6,6)      ! 切线模量
  
  !-- 中间变量
  REAL(wp) :: dstrain(6)        ! 应变增量
  REAL(wp) :: eqps              ! 等效塑性应变
  REAL(wp) :: damage            ! 损伤变量
  
END TYPE

!=================================================================
! L4_PH: 材料算法参数（迭代控制）
!=================================================================
TYPE :: PH_Mat_UMAT_Algo
  !-- 本构积分算法
  INTEGER(i4) :: integration_scheme  ! 1=向前 Euler, 2=向后 Euler, 3= midpoint
  
  !-- 屈服判断
  REAL(wp) :: yield_tol      ! 屈服容差
  REAL(wp) :: plastic_tol    ! 塑性修正容差
  
  !-- 返回映射参数
  INTEGER(i4) :: max_iter    ! 最大局部迭代次数
  REAL(wp) :: line_search    ! 线搜索因子
  
  !-- 特殊处理
  LOGICAL :: use_consistent_tangent  ! 使用一致切线
  LOGICAL :: viscous_regularization  ! 粘性正则化
  
END TYPE

!=================================================================
! L5_RT: 材料运行时上下文
!=================================================================
TYPE :: RT_Mat_UMAT_Ctx
  !-- 引用全局上下文（通过 Common Ctx）
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 材料点标识
  INTEGER(i4) :: mat_pt_idx    ! 材料点索引
  INTEGER(i4) :: elem_id       ! 所属单元编号
  INTEGER(i4) :: integ_pt      ! 积分点编号
  
  !-- 历史变量管理
  REAL(wp), ALLOCATABLE :: statev(:)  ! 状态变量（L5 保存）
  LOGICAL :: statev_initialized
  
  !-- 求解器反馈
  REAL(wp) :: pnewdt         ! 步长调整因子
  INTEGER(i4) :: status      ! 计算状态（0=成功，-1=失败）
  
END TYPE
```

---

#### 2️⃣ UEL / VUEL（用户自定义单元）

```fortran
!=================================================================
! L3_MD: 单元参数定义
!=================================================================
TYPE :: MD_Elem_UEL_Desc
  !-- 单元标识
  INTEGER(i4) :: elem_id
  INTEGER(i4) :: elem_type   ! 1=C3D8, 2=C3D20, 3=S4, ...
  CHARACTER(LEN=64) :: elem_name
  
  !-- 拓扑信息
  INTEGER(i4) :: nnodes      ! 节点数
  INTEGER(i4) :: ndofs       ! 每节点自由度数
  INTEGER(i4) :: nips        ! 积分点数
  
  !-- 截面绑定
  INTEGER(i4) :: section_id  ! 截面号（枢纽）
  INTEGER(i4) :: material_ids(:)  ! 材料 ID 列表
  
  !-- 单元技术
  LOGICAL :: reduced_integration  ! 减缩积分
  LOGICAL :: hourglass_control    ! 沙漏控制
  LOGICAL :: enhanced_assumed_strain  ! EAS 增强
  
END TYPE

!=================================================================
! L4_PH: 单元状态
!=================================================================
TYPE :: PH_Elem_UEL_State
  !-- 输入状态
  REAL(wp) :: coords(:,:)    ! 节点坐标 (ndim × nnode)
  REAL(wp) :: u(:,:)         ! 节点位移 (ndof × nnode)
  REAL(wp) :: du(:,:)        ! 位移增量
  
  !-- 输出状态
  REAL(wp) :: stiffness(:,:) ! 单元刚度 (nlhs × nlhs)
  REAL(wp) :: rhs(:)         ! 右端项 (nlhs)
  REAL(wp) :: mass(:,:)      ! 质量矩阵（动力分析）
  
  !-- 积分点状态
  REAL(wp) :: stress(:,:,:)  ! 应力 (6 × nips × nlayer)
  REAL(wp) :: strain(:,:,:)  ! 应变
  
END TYPE

!=================================================================
! L4_PH: 单元算法参数
!=================================================================
TYPE :: PH_Elem_UEL_Algo
  !-- 数值积分
  INTEGER(i4) :: nips        ! 积分点数
  REAL(wp) :: ip_coords(:,:) ! 积分点自然坐标
  REAL(wp) :: weights(:)     ! 积分权重
  
  !-- B 矩阵计算
  LOGICAL :: use_analytic_deriv  ! 解析导数 vs 数值微分
  
  !-- 非线性处理
  LOGICAL :: geometric_nonlinear ! 几何非线性（NLGEOM）
  LOGICAL :: material_nonlinear  ! 材料非线性
  
  !-- 动力积分
  REAL(wp) :: newmark_beta   ! Newmark β
  REAL(wp) :: newmark_gamma  ! Newmark γ
  REAL(wp) :: hht_alpha      ! HHT-α
  
END TYPE

!=================================================================
! L5_RT: 单元运行时上下文
!=================================================================
TYPE :: RT_Elem_UEL_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 单元定位
  INTEGER(i4) :: elem_id
  INTEGER(i4) :: instance_id  ! 部件实例号
  
  !-- 方程编号
  INTEGER(i4) :: equation_numbers(:)  ! 整体 DOF 编号
  
  !-- 生死单元
  LOGICAL :: is_active       ! 是否激活
  
  !-- 接触绑定
  INTEGER(i4) :: contact_pair_ids(:)  ! 关联的接触对
  
END TYPE
```

---

### A.2 载荷子程序

#### 3️⃣ DLOAD / VDLOAD（分布载荷）

```fortran
!=================================================================
! L3_MD: 载荷参数定义
!=================================================================
TYPE :: MD_Load_DLOAD_Desc
  !-- 载荷标识
  INTEGER(i4) :: load_id
  INTEGER(i4) :: load_family   ! 1=DIST (压力), 2=CONC (集中力)
  CHARACTER(LEN=64) :: load_name
  
  !-- 幅值定义
  REAL(wp) :: magnitude        ! 载荷大小
  INTEGER(i4) :: amplitude_id  ! 幅值曲线 ID
  LOGICAL :: time_dependent    ! 时间相关
  
  !-- 空间分布
  INTEGER(i4) :: distribution_type  ! 1=均匀，2=线性，3=用户定义
  REAL(wp) :: spatial_params(:)     ! 空间分布参数
  
  !-- 作用对象
  INTEGER(i4) :: elem_set_id   ! 单元集 ID
  INTEGER(i4) :: face_code     ! 面编号（1-6）
  
END TYPE

!=================================================================
! L4_PH: 载荷状态
!=================================================================
TYPE :: PH_Load_DLOAD_State
  !-- 当前位置
  REAL(wp) :: coords(3)      ! 积分点坐标
  
  !-- 计算结果
  REAL(wp) :: load_value     ! 载荷大小
  REAL(wp) :: load_dir(3)    ! 载荷方向
  
  !-- 中间变量
  REAL(wp) :: time_factor    ! 时间因子
  REAL(wp) :: spatial_factor ! 空间因子
  
END TYPE

!=================================================================
! L4_PH: 载荷算法
!=================================================================
TYPE :: PH_Load_DLOAD_Algo
  !-- 时间插值
  INTEGER(i4) :: interp_method  ! 1=线性，2=样条
  
  !-- 空间插值
  LOGICAL :: use_natural_coords  ! 使用自然坐标
  
END TYPE

!=================================================================
! L5_RT: 载荷运行时上下文
!=================================================================
TYPE :: RT_Load_DLOAD_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 位置标识
  INTEGER(i4) :: elem_id
  INTEGER(i4) :: integ_pt
  
  !-- 跟随力
  LOGICAL :: follower_force  ! 是否随变形转动
  
END TYPE
```

---

#### 4️⃣ DISP / VDISP（位移边界）

```fortran
!=================================================================
! L3_MD: 边界参数定义
!=================================================================
TYPE :: MD_BC_DISPS_Desc
  !-- 边界标识
  INTEGER(i4) :: bc_id
  INTEGER(i4) :: bc_family   ! 1=DISP (位移), 2=VEL (速度), 3=ACC (加速度)
  CHARACTER(LEN=64) :: bc_name
  
  !-- 幅值定义
  REAL(wp) :: magnitude
  INTEGER(i4) :: amplitude_id
  
  !-- 作用对象
  INTEGER(i4) :: node_set_id   ! 节点集 ID
  INTEGER(i4) :: dof_mask(6)   ! 自由度掩码 [1,0,0,0,0,0] = UX only
  
  !-- 约束类型
  LOGICAL :: enforced_displacement  ! 强制位移
  LOGICAL :: spring_boundary        ! 弹簧边界
  
END TYPE

!=================================================================
! L4_PH: 边界状态
!=================================================================
TYPE :: PH_BC_DISP_State
  !-- 当前状态
  REAL(wp) :: time_current   ! 当前时间
  
  !-- 计算结果
  REAL(wp) :: disp_value     ! 位移值
  REAL(wp) :: vel_value      ! 速度值（可选）
  REAL(wp) :: acc_value      ! 加速度值（可选）
  
END TYPE

!=================================================================
! L4_PH: 边界算法
!=================================================================
TYPE :: PH_BC_DISP_Algo
  !-- 插值方法
  INTEGER(i4) :: interp_scheme
  
END TYPE

!=================================================================
! L5_RT: 边界运行时上下文
!=================================================================
TYPE :: RT_BC_DISP_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 节点定位
  INTEGER(i4) :: node_id
  INTEGER(i4) :: dof_number  ! 1-6
  
  !-- 拉格朗日乘子
  REAL(wp) :: lagrange_mult  ! 约束反力
  
END TYPE
```

---

### A.3 接触子程序

#### 5️⃣ UINTER / VUINTER（接触界面）

```fortran
!=================================================================
! L3_MD: 接触参数定义
!=================================================================
TYPE :: MD_Contact_UINTER_Desc
  !-- 接触对标识
  INTEGER(i4) :: contact_pair_id
  CHARACTER(LEN=64) :: pair_name
  
  !-- 主从面
  INTEGER(i4) :: master_surf_id
  INTEGER(i4) :: slave_surf_id
  
  !-- 接触本构
  INTEGER(i4) :: contact_model  ! 1=硬接触，2=软接触，3=指数
  REAL(wp) :: contact_props(:)  ! 接触参数（如 penalty_stiffness）
  
  !-- 摩擦模型
  INTEGER(i4) :: friction_model  ! 0=无摩擦，1=Coulomb, 2=user-defined
  REAL(wp) :: friction_coef    ! 摩擦系数
  
END TYPE

!=================================================================
! L4_PH: 接触状态
!=================================================================
TYPE :: PH_Contact_UINTER_State
  !-- 几何状态
  REAL(wp) :: gap            ! 法向间隙
  REAL(wp) :: slip1(2)       ! 切向滑移量
  
  !-- 计算结果
  REAL(wp) :: pressure       ! 接触压力
  REAL(wp) :: tau1(2)        ! 摩擦应力
  
  !-- 状态标志
  LOGICAL :: in_contact      ! 是否接触
  LOGICAL :: sticking        ! 粘着 vs 滑动
  
END TYPE

!=================================================================
! L4_PH: 接触算法
!=================================================================
TYPE :: PH_Contact_UINTER_Algo
  !-- 接触检测
  REAL(wp) :: detection_tol   ! 检测容差
  INTEGER(i4) :: detection_freq  ! 检测频次
  
  !-- 约束施加
  INTEGER(i4) :: constraint_method  ! 1=Penalty, 2=Lagrange, 3=Augmented
  
  !-- 摩擦积分
  INTEGER(i4) :: friction_integration  ! 1=Euler, 2=Runge-Kutta
  
END TYPE

!=================================================================
! L5_RT: 接触运行时上下文
!=================================================================
TYPE :: RT_Contact_UINTER_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 接触点定位
  INTEGER(i4) :: slave_node_id
  INTEGER(i4) :: master_elem_id
  REAL(wp) :: master_coords(3)  ! 主面投影点坐标
  
  !-- 整体接触状态
  INTEGER(i4) :: n_active_contacts  ! 活动接触点数
  
END TYPE
```

---

#### 6️⃣ UFRIC / VUFRIC（摩擦）

```fortran
!=================================================================
! L3_MD: 摩擦参数定义
!=================================================================
TYPE :: MD_Friction_UFRIC_Desc
  !-- 摩擦模型标识
  INTEGER(i4) :: friction_id
  INTEGER(i4) :: friction_type  ! 1=Coulomb, 2=shear, 3=user
  
  !-- 摩擦参数
  REAL(wp) :: mu_static      ! 静摩擦系数
  REAL(wp) :: mu_dynamic     ! 动摩擦系数
  REAL(wp) :: decay_coeff    ! 衰减系数
  
  !-- 软化规律
  INTEGER(i4) :: softening_law  ! 1=指数，2=线性
  
END TYPE

!=================================================================
! L4_PH: 摩擦状态
!=================================================================
TYPE :: PH_Friction_UFRIC_State
  !-- 输入
  REAL(wp) :: pressure       ! 接触压力
  REAL(wp) :: slip_rate      ! 滑移率
  REAL(wp) :: temperature    ! 温度
  
  !-- 输出
  REAL(wp) :: friction_coef  ! 瞬时摩擦系数
  REAL(wp) :: shear_stress   ! 剪切应力
  
END TYPE

!=================================================================
! L4_PH: 摩擦算法
!=================================================================
TYPE :: PH_Friction_UFRIC_Algo
  !-- 摩擦演化
  LOGICAL :: state_variable_friction  ! 状态变量摩擦
  
END TYPE

!=================================================================
! L5_RT: 摩擦运行时上下文
!=================================================================
TYPE :: RT_Friction_UFRIC_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 关联接触对
  INTEGER(i4) :: contact_pair_id
  
END TYPE
```

---

### A.4 约束子程序

#### 7️⃣ UMPC / VUMPC（多点约束）

```fortran
!=================================================================
! L3_MD: 约束参数定义
!=================================================================
TYPE :: MD_Constraint_UMPC_Desc
  !-- 约束标识
  INTEGER(i4) :: mpc_id
  INTEGER(i4) :: mpc_type    ! 1=梁连接，2=壳 - 实体耦合，3=user
  
  !-- 约束方程
  INTEGER(i4) :: n_terms     ! 方程项数
  INTEGER(i4) :: node_ids(:) ! 涉及节点
  INTEGER(i4) :: dof_ids(:)  ! 涉及自由度
  REAL(wp) :: coefficients(:) ! 方程系数
  
  !-- 拉格朗日乘子
  LOGICAL :: use_lagrange_multiplier
  
END TYPE

!=================================================================
! L4_PH: 约束状态
!=================================================================
TYPE :: PH_Constraint_UMPC_State
  !-- 约束残差
  REAL(wp) :: residual       ! 约束方程残差
  
  !-- 拉格朗日乘子
  REAL(wp) :: lambda         ! 乘子值
  
  !-- 雅可比
  REAL(wp) :: jacobian(:)    ! ∂residual/∂DOF
  
END TYPE

!=================================================================
! L4_PH: 约束算法
!=================================================================
TYPE :: PH_Constraint_UMPC_Algo
  !-- 施加方法
  INTEGER(i4) :: enforcement_method  ! 1=Elimination, 2=Lagrange, 3=Penalty
  
END TYPE

!=================================================================
! L5_RT: 约束运行时上下文
!=================================================================
TYPE :: RT_Constraint_UMPC_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 全局方程编号
  INTEGER(i4) :: mpc_equation_id
  
END TYPE
```

---

### A.5 场变量子程序

#### 8️⃣ USDFLD / VUSDFLD（场变量）

```fortran
!=================================================================
! L3_MD: 场变量参数定义
!=================================================================
TYPE :: MD_Field_USDFLD_Desc
  !-- 场变量标识
  INTEGER(i4) :: field_id
  INTEGER(i4) :: field_type  ! 1=损伤，2=温度，3=孔隙率，...
  
  !-- 演化方程参数
  REAL(wp) :: evol_params(:)
  INTEGER(i4) :: n_evolution_params
  
  !-- 耦合方式
  LOGICAL :: coupled_to_material  ! 是否影响材料本构
  LOGICAL :: history_dependent    ! 历史相关
  
END TYPE

!=================================================================
! L4_PH: 场变量状态
!=================================================================
TYPE :: PH_Field_USDFLD_State
  !-- 输入
  REAL(wp) :: stress(6)      ! 当前应力
  REAL(wp) :: strain(6)      ! 当前应变
  REAL(wp) :: statev(:)      ! 材料状态变量
  
  !-- 输出
  REAL(wp) :: field_value    ! 场变量值
  REAL(wp) :: field_rate     ! 场变量变化率
  
  !-- 演化方程
  REAL(wp) :: internal_vars(:)  ! 内部变量
  
END TYPE

!=================================================================
! L4_PH: 场变量算法
!=================================================================
TYPE :: PH_Field_USDFLD_Algo
  !-- 演化方程类型
  INTEGER(i4) :: evolution_law  ! 1=常微分方程，2=偏微分方程
  
  !-- 时间积分
  INTEGER(i4) :: time_integration  ! 1=显式，2=隐式
  
END TYPE

!=================================================================
! L5_RT: 场变量运行时上下文
!=================================================================
TYPE :: RT_Field_USDFLD_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 场变量管理
  INTEGER(i4) :: n_fields    ! 场变量总数
  LOGICAL :: fields_initialized
  
END TYPE
```

---

### A.6 分析控制子程序

#### 9️⃣ UEXTERNALDB（外部数据库）

```fortran
!=================================================================
! L3_MD: 外部数据库参数定义
!=================================================================
TYPE :: MD_Analysis_EXTDB_Desc
  !-- 数据库标识
  INTEGER(i4) :: db_id
  INTEGER(i4) :: db_type     ! 1=文件，2=网络，3=内存
  
  !-- 连接参数
  CHARACTER(LEN=256) :: connection_string
  REAL(wp) :: timeout        ! 超时时间 [s]
  
  !-- 读写权限
  LOGICAL :: read_only
  LOGICAL :: parallel_safe   ! 并行安全
  
END TYPE

!=================================================================
! L4_PH: 外部数据库状态
!=================================================================
TYPE :: PH_Analysis_EXTDB_State
  !-- 连接状态
  LOGICAL :: connected
  INTEGER(i4) :: error_code
  
  !-- 数据缓存
  REAL(wp), ALLOCATABLE :: cache(:)
  
END TYPE

!=================================================================
! L4_PH: 外部数据库算法
!=================================================================
TYPE :: PH_Analysis_EXTDB_Algo
  !-- 同步策略
  INTEGER(i4) :: sync_frequency  ! 同步频率
  
END TYPE

!=================================================================
! L5_RT: 外部数据库运行时上下文
!=================================================================
TYPE :: RT_Analysis_EXTDB_Ctx
  !-- 引用全局上下文
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
  
  !-- 数据库句柄
  INTEGER(i4) :: db_handle
  
  !-- 访问计数
  INTEGER(i4) :: read_count
  INTEGER(i4) :: write_count
  
END TYPE
```

---

## 🔧 数据结构实现策略

### 策略 1: 指针关联 vs 值传递

```fortran
!=================================================================
! 方案 A: 指针关联（零拷贝，推荐）
!=================================================================
TYPE :: RT_Mat_UMAT_Ctx
  TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx  ! ← 指针
  TYPE(MD_Mat_UMAT_Desc), POINTER :: md_desc ! ← 指针
END TYPE

SUBROUTINE PH_Mat_UMAT_API(ph_state, ph_algo, rt_ctx)
  ! 通过指针访问全局数据
  time_now = rt_ctx%com_ctx%global_ctx%time_current
  mat_props = rt_ctx%md_desc%props
END SUBROUTINE

优势：
✓ 零内存拷贝
✓ 数据一致性保证
✓ 热路径友好


!=================================================================
! 方案 B: 值传递（深拷贝，不推荐用于热路径）
!=================================================================
TYPE :: RT_Mat_UMAT_Ctx
  TYPE(MD_Mat_UMAT_Desc) :: md_desc  ! ← 完整副本
END TYPE

劣势：
✗ 内存开销大
✗ 同步困难
✗ 性能差
```

---

### 策略 2: Populate 期初始化

```fortran
SUBROUTINE UFC_Populate_All()
  
  ! Step 1: 读取 INP，填充 L3 Desc
  CALL MD_Mat_ReadFromINP(mat_lib, n_mats)
  CALL MD_Elem_ReadFromINP(elem_lib, n_elems)
  
  ! Step 2: 分配 L4 State 和 L5 Ctx
  ALLOCATE(PH_Mat_State(n_mats))
  ALLOCATE(RT_Mat_Ctx(n_mats))
  
  ! Step 3: 建立指针关联（关键！）
  DO i = 1, n_mats
    ! L5 Ctx → L3 Desc
    RT_Mat_Ctx(i)%md_desc => mat_lib(i)
    
    ! L5 Ctx → L2 Com Ctx
    RT_Mat_Ctx(i)%com_ctx => global_com_ctx
    
    ! L4 State 初始化
    PH_Mat_State(i)%stress_old = 0.0_wp
    PH_Mat_State(i)%statev_old = 0.0_wp
  END DO
  
  ! Step 4: 验证所有指针有效
  DO i = 1, n_mats
    IF (.NOT. ASSOCIATED(RT_Mat_Ctx(i)%md_desc)) THEN
      CALL Log_Error("Material pointer not associated!")
    END IF
  END DO
  
END SUBROUTINE
```

---

### 策略 3: 热路径访问模式

```fortran
!=================================================================
! 热路径子程序（增量步循环内）
!=================================================================
DO kinc = 1, nincs
  DO mat_pt = 1, n_mat_points
    
    ! ✅ 正确：通过指针链访问（零拷贝）
    CALL PH_Mat_UMAT_API( &
         ph_state = PH_Mat_State(mat_pt), &
         ph_algo = PH_Mat_Algo, &
         rt_ctx = RT_Mat_Ctx(mat_pt))
    
    ! 内部访问：
    ! time = rt_ctx%com_ctx%global_ctx%time_current  ✓
    ! props = rt_ctx%md_desc%props                   ✓
    
  END DO
END DO


!=================================================================
! ❌ 错误：重复查询 L3（热路径禁止）
!=================================================================
SUBROUTINE PH_Mat_UMAT_WRONG(rt_ctx)
  ! 每次调用都扫描全模型查找材料参数
  mat_id = rt_ctx%mat_id
  CALL MD_Mat_GetById(mat_id, mat_desc)  ← 禁止！
END SUBROUTINE
```

---

## 📊 四链贯通检查清单

### ✅ 理论链

- [ ] 每个 TYPE 都有明确的物理意义
- [ ] 变分原理清晰（如 Hu-Washizu）
- [ ] 控制方程完整（平衡 + 本构 + 相容）

---

### ✅ 逻辑链

- [ ] L3→L4→L5数据流明确
- [ ] 调用时序清晰（Populate → Step-Init → Incremental）
- [ ] 接口契约固定（INTENT IN/OUT/INOUT）

---

### ✅ 计算链

- [ ] 算法流程图完整
- [ ] 数值积分方案明确
- [ ] 收敛判据具体

---

### ✅ 数据链

- [ ] 生命周期管理（分配→初始化→更新→销毁）
- [ ] 指针关联图完整
- [ ] 历史变量管理策略清晰

---

## 🎯 下一步行动

### Phase 1: 完成所有 TYPE 定义（本周）

**任务清单**：
1. [ ] 整理上述 9 大类子程序的 TYPE 定义
2. [ ] 统一命名规范（层级 - 域级 - 功能集）
3. [ ] 建立指针关联模板

**交付物**：
- `RT_Layer_Complete_Types.f90`
- `Type_Definition_Guide.md`

---

### Phase 2: 实现 Populate 期初始化（下周）

**任务清单**：
1. [ ] 编写 Populate 子程序族
2. [ ] 实现指针关联逻辑
3. [ ] 添加验证检查

**交付物**：
- `RT_Populate_All.f90`
- `Pointer_Association_Test.f90`

---

### Phase 3: 注入算法流程（第 3 周）

**任务清单**：
1. [ ] 实现 PH_Mat_UMAT_API
2. [ ] 实现 PH_Elem_UEL_API
3. [ ] 集成所有子程序

**交付物**：
- `PH_Mat_UMAT.f90`
- `PH_Elem_UEL.f90`
- `Integration_Test.f90`

---

**文档维护者**: UFC 架构团队  
**审核状态**: 草案（待技术评审）  
**下次更新**: 完成 Phase 1 后
