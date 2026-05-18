# UFC 跨层 Bridge 架构完整设计

## 📊 架构总览：五大跨层 Bridge

```
L6 (Application)
  ↓ Bridge: L6←L5 (分析驱动 Bridge)
L5 (Runtime Solver)
  ↓ Bridge: L5←L4 (物理求解 Bridge)
L4 (Physics)
  ↓ Bridge: L4←L3 (本构与单元调用 Bridge)
L3 (Model Description)
  ↓ Bridge: L3←L2 (稀疏矩阵与线性系统 Bridge)
L2 (Numerical Methods)
  ↓ Bridge: L2←L1 (基础算法 Bridge)
L1 (Foundations)
```

---

## 🌉 Bridge 1: L6←L5 (分析驱动 Bridge)

### 设计目标
将用户分析 **意图** 转化为 **求解器驱动序列**

### 核心职责

| 职能 | 输入 | 处理 | 输出 |
|------|------|------|------|
| **Job 解析** | *.inp 配置文件 | 关键字规范化 | Analysis_Type, Step_Seq |
| **加载序列** | Load/BC/IC 定义 | 时间离散化、非线性步划分 | LoadHistory_Tables |
| **输出策略** | FieldOutput/HistoryOutput | 数据采集点规划 | Output_Schedule |
| **收敛控制** | 全局迭代参数 | max_iter, tolerance, auto_cut | Solver_Config |

### 关键接口

```fortran
!-- INPUT: Application intent
TYPE(Analysis_Spec)
  character(len=256) :: job_name
  integer :: analysis_type           ! 1=static, 2=dynamic, 3=thermal
  TYPE(StepSequence), allocatable :: steps(:)
  TYPE(LoadBC_Cluster) :: boundary_data
END TYPE

!-- BRIDGE: Job → Solver translation
SUBROUTINE L6_Parse_Job_To_SolverConfig(analysis_spec, solver_config)
  TYPE(Analysis_Spec), INTENT(IN) :: analysis_spec
  TYPE(RT_Solver_Config), INTENT(OUT) :: solver_config
  !-- Map: steps(:) → kstep_sequence
  !-- Map: boundary_data → load_tables
  !-- Map: convergence_rules → RT_Com_Algo
END SUBROUTINE

!-- OUTPUT: Solver-ready configuration
TYPE(RT_Solver_Config)
  integer :: analysis_type
  TYPE(Step_Seq_Array), allocatable :: step_sequence(:)
  TYPE(Load_History_Table) :: load_history
  TYPE(RT_Com_Algo) :: global_convergence
  TYPE(Output_Scheduler) :: output_plan
END TYPE
```

### 数据流向

```
User *.inp
    ↓
L6_Parser (关键字规范化)
    ↓
Analysis_Spec TYPE
    ↓
L6←L5 Bridge (Job → SolverConfig translation)
    ↓
RT_Solver_Config (求解器就绪)
    ↓
L5_RT Solver (主控循环)
```

---

## 🌉 Bridge 2: L5←L4 (物理求解 Bridge)

### 设计目标
将 **求解步指令** 转化为 **物理场计算序列**

### 核心职责

| 职能 | 数据结构 | 关键操作 | 约束 |
|------|---------|---------|------|
| **阶段编排** | RT_Step_Sequence | Step → Increment → Iteration | 严格递进 |
| **元件循环** | Element_Array | CALL PH_Elem_UEL_API(elem_i) | 单元独立 |
| **材料积分** | Gauss_Point_Array | CALL PH_Mat_UMAT_API(mat_d) | 隔离热路径 |
| **全局聚合** | Global_K, R | Assembly(K, R) | 原子性 |

### 关键接口

```fortran
!-- INPUT: Solver control sequence
TYPE(RT_Step_Instruction)
  integer :: kstep, kinc, iter
  real(wp) :: dtime, time_step, time_total
  logical :: nlgeom, first_increment
  TYPE(Load_Pattern) :: current_load
  TYPE(Boundary_Conditions) :: current_bc
END TYPE

!-- BRIDGE: Step → Physics computation dispatch
SUBROUTINE L5_Execute_Step(step_instr, mesh, model, solver_state, output_writer)
  TYPE(RT_Step_Instruction), INTENT(IN) :: step_instr
  TYPE(Mesh_Base), INTENT(IN) :: mesh
  TYPE(Model_Base), INTENT(INOUT) :: model        ! L3_MD domain
  TYPE(Solver_State), INTENT(INOUT) :: solver_state
  TYPE(Output_Writer) :: output_writer
  
  ! Phase 1: Update loads & BCs
  CALL Update_Loads_And_BCs(step_instr, model)
  
  ! Phase 2: Element loop (L5←L4 Bridge kernel)
  DO elem_id = 1, mesh%n_elements
    TYPE(MD_Elem_Base_Desc) :: elem_d ← mesh%elements(elem_id)
    TYPE(PH_Elem_Base_State) :: elem_s ← solver_state%elem_states(elem_id)
    
    CALL PH_Element_UEL_API(elem_d, elem_s, step_instr%RT_Com_Ctx, ...)
    !  ↓ Inside UEL: PH_Element_UEL_API calls UMAT for each IP
    !      CALL PH_Mat_UMAT_API(material_d, mat_state, ...)
  END DO
  
  ! Phase 3: Global assembly & solve
  CALL Assemble_Global_System(solver_state, model)
  CALL Solve_Linear_System(solver_state)      ! L5←L2 Bridge
  
  ! Phase 4: Convergence check & output
  IF (Converged(solver_state)) THEN
    CALL Output_Results(solver_state, output_writer)
  END IF
END SUBROUTINE

!-- OUTPUT: Updated model state
TYPE(Solver_State)
  TYPE(PH_Elem_Base_State), allocatable :: elem_states(:)
  TYPE(PH_Mat_PLM_State), allocatable :: mat_states(:,:)   ! [elem, ip]
  real(wp), allocatable :: global_displacements(:)
  real(wp) :: residual_norm, step_ratio
END TYPE
```

### 数据流向（关键：IP 循环内嵌套）

```
Step k, Increment n
  ↓
DO elem_id = 1, n_elem
  ├─ LOAD elem_state (PH_Elem_Base_State)
  ├─ DO ip = 1, n_ip
  │  ├─ LOAD svars → PH_Mat_State
  │  ├─ CALL UMAT_API(material_d, mat_state, ...)  ← L5←L4 Bridge
  │  ├─ STORE svars ← PH_Mat_State
  │  └─ Accumulate K, R
  └─ STORE elem_state
  
Global K, R
  ↓ (L5←L2 Bridge)
Linear solver
  ↓
Global u displacement
```

---

## 🌉 Bridge 3: L4←L3 (本构与单元调用 Bridge)

### 设计目标
将 **模型定义 (L3_MD)** 链接到 **计算实例 (L4_PH)**

### 核心职责

| 职能 | L3_MD 来源 | L4_PH 计算层 | Bridge 机制 |
|------|-----------|-----------|-----------|
| **材料多态** | MD_Mat_Base_Desc → MD_Mat_PLM_Desc | SELECT TYPE | 指针别名 |
| **截面绑定** | MD_Sect_Registry | PH_Elem_Base_Ctx%mat_ctx | sect_id lookup |
| **单元拓扑** | MD_Elem_Base_Desc | PH_Elem_Base_State%svars | nsvars 映射 |
| **积分规则** | MD_Elem_Base_Algo%integ_npts | GAUSS_POINT_LOOP | det_J, w_ip |

### 关键接口：多材料分发

```fortran
!-- L3_MD: Material descriptor hierarchy
TYPE(MD_Mat_Base_Desc), ABSTRACT
  integer :: mat_id
  character(len=64) :: material_name
  logical :: is_initialized
END TYPE

TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_PLM_Desc
  real(wp) :: E, nu, sigma_y, H
  real(wp) :: lambda, G
END TYPE

!-- L4_PH: Section registry (Bridge kernel)
TYPE(MD_Sect_Registry)
  TYPE(Section_Entry), allocatable :: sections(:)
END TYPE

TYPE(Section_Entry)
  integer :: sect_id
  CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc    ! Polymorphic pointer
END TYPE

!-- BRIDGE: Material dispatch (L4←L3)
SUBROUTINE PH_Element_UEL_API(sect_registry, MD_Elem_Desc, ...)
  TYPE(MD_Sect_Registry), INTENT(IN), TARGET :: sect_registry
  
  ! Step 1: Lookup material from section registry
  sect_id = MD_Elem_Desc%jprops(1)
  CLASS(MD_Mat_Base_Desc), POINTER :: mat_d ← sect_registry%sections(sect_id)%mat_desc
  
  ! Step 2: Multi-material dispatch
  SELECT TYPE (md => mat_d)
  TYPE IS (MD_Mat_PLM_Desc)
    ! Elastic-plastic material
    CALL PH_PLM_J2_UMAT_API(md, ...)
  TYPE IS (MD_Mat_ELA_Desc)
    ! Pure elastic
    CALL PH_ELA_UMAT_API(md, ...)
  TYPE IS (MD_Mat_DMG_Desc)
    ! Damage model
    CALL PH_DMG_UMAT_API(md, ...)
  CLASS DEFAULT
    ! Error: unknown material
    status = ERROR
  END SELECT
END SUBROUTINE

!-- Data flow: L3_MD → L4_PH
MD_Sect_Registry (static at load time)
  ↓
  sections(sect_id) → mat_desc (CLASS pointer)
  ↓ (L4←L3 Bridge: SELECT TYPE dispatch)
  ↓
MD_Mat_PLM_Desc instance
  ↓
PH_PLM_J2_UMAT_API(md, ...) computation
  ↓
Updated PH_Mat_PLM_State
```

### 关键：SVARS 持久化（L4←L3）

```fortran
!-- L3_MD: Element topology specification
MD_Elem_Base_Desc
  nnode = 8        ! C3D8
  nip = 8          ! Gauss points
  nsvars = 112     ! Total = 8 ip × 14 svars/ip

!-- L4_PH: State variables persistent storage
PH_Elem_Base_State
  real(wp), allocatable :: svars(:)    ! [nsvars]

!-- BRIDGE: IP ↔ SVARS slot mapping
DO ip = 1, nip
  slot_base = (ip - 1) * NSVARS_PER_IP + 1
  
  ! LOAD (per increment)
  PH_Mat_State%stress(1:6) ← svars(slot_base+0  : slot_base+5)
  PH_Mat_State%stran(1:6)  ← svars(slot_base+6  : slot_base+11)
  PH_Mat_State%ivar1       ← svars(slot_base+12)
  PH_Mat_State%ivar2       ← svars(slot_base+13)
  
  ! [COMPUTE: UMAT]
  
  ! STORE (mirror)
  svars(slot_base+0  : slot_base+5)  ← PH_Mat_State%stress(1:6)
  svars(slot_base+6  : slot_base+11) ← PH_Mat_State%stran(1:6)
  svars(slot_base+12) ← PH_Mat_State%ivar1
  svars(slot_base+13) ← PH_Mat_State%ivar2
END DO
```

---

## 🌉 Bridge 4: L3←L2 (稀疏矩阵与线性系统 Bridge)

### 设计目标
将 **有限元刚度/载荷** 转化为 **可求解线性系统**

### 核心职责

| 职能 | L4_PH 来源 | L2_NM 求解器 | Bridge 职责 |
|------|-----------|-----------|-----------|
| **矩阵组装** | elem K[8×8] (C3D8) | Global K[n_dof × n_dof] | 稀疏格式转换 |
| **向量聚合** | elem R[8] | Global R[n_dof] | DOF 映射 |
| **对称性** | ddsdde(6×6) = symmetric | Skyline/CCS | 存储优化 |
| **约束消除** | Dirichlet BC | Modified K, R | 消元法 |

### 关键接口

```fortran
!-- INPUT: Element assembly matrices
TYPE(PH_Elem_Base_State)
  real(wp), allocatable :: amatrx(:,:)     ! [ndofel, ndofel] local stiffness
  real(wp), allocatable :: rhs(:,:)        ! [ndofel, nrhs]   local force
  integer, allocatable :: node_indices(:)  ! Global DOF mapping
END TYPE

!-- BRIDGE: Assembly (L3←L2)
SUBROUTINE Assemble_Global_System(elem_states, mesh, model, solver_state)
  TYPE(PH_Elem_Base_State), INTENT(IN) :: elem_states(:)
  TYPE(Mesh_Base), INTENT(IN) :: mesh
  TYPE(Model_Base), INTENT(IN) :: model
  TYPE(Solver_State), INTENT(INOUT) :: solver_state
  
  ! Initialize global matrices
  K_global = ZERO
  R_global = ZERO
  
  ! Element loop: aggregate local → global
  DO elem_id = 1, mesh%n_elements
    elem_nodes = mesh%elements(elem_id)%node_indices
    
    ! Map local DOF to global DOF
    glob_dof(1:ndofel) = elem_nodes * ndof_per_node + [1:ndof_per_node]
    
    ! Add to sparse matrix (CCS format)
    DO j = 1, ndofel
      DO i = 1, ndofel
        K_global(glob_dof(i), glob_dof(j)) += elem_states(elem_id)%amatrx(i, j)
      END DO
      R_global(glob_dof(j)) += elem_states(elem_id)%rhs(j, 1)
    END DO
  END DO
  
  ! Apply boundary conditions (Dirichlet)
  DO bc_id = 1, model%n_boundary_conditions
    dof_constrained = model%bcs(bc_id)%dof_index
    K_global(dof_constrained, :) = 0.0_wp
    K_global(dof_constrained, dof_constrained) = 1.0_wp   ! Penalty
    R_global(dof_constrained) = model%bcs(bc_id)%prescribed_value
  END DO
END SUBROUTINE

!-- OUTPUT: Solver-ready linear system
TYPE(Solver_State)
  ! Sparse matrix (CCS format)
  real(wp), allocatable :: K_val(:)          ! Non-zero values
  integer, allocatable :: K_col(:), K_row(:) ! Column & row indices
  real(wp), allocatable :: R_global(:)       ! RHS vector
  real(wp), allocatable :: u_global(:)       ! Solution (displacement)
END TYPE
```

### 矩阵结构（稀疏格式）

```
Element Level:
  amatrx (8×8) - C3D8 local stiffness

Global Assembly (L3←L2 Bridge):
  Global K[n_dof × n_dof]    ← sum amatrx over all elements
  Global R[n_dof]            ← sum rhs over all elements
  
Sparse storage (CCS):
  K_val(*)     = non-zero values
  K_row(*)     = row indices
  K_col(*)     = column indices for row starts
  
Linear system:
  K · u = R
  (Pass to L2 solver: GMRES, PARDISO, etc.)
```

---

## 🌉 Bridge 5: L2←L1 (基础算法 Bridge)

### 设计目标
将 **数值求解器** 链接到 **基础线性代数运算**

### 核心职责

| 职能 | L2_NM 算法 | L1_IF 基础库 | Bridge 职责 |
|------|-----------|-----------|-----------|
| **矩阵操作** | SpMV, A·x | BLAS-3 DGEMM | 格式适配 |
| **向量操作** | norm, dot | BLAS-1 | 数值精度 |
| **预处理** | ILU, Jacobi | Factorization | 收敛加速 |
| **求解** | GMRES, CG | Backsolve | 迭代控制 |

### 关键接口

```fortran
!-- INPUT: L2_NM linear system
TYPE(Linear_System_L2)
  TYPE(Sparse_Matrix_CCS) :: K          ! Coefficient matrix
  real(wp), allocatable :: R(:)         ! RHS vector [n_dof]
  real(wp), allocatable :: u(:)         ! Solution (initialized to 0)
  integer :: n_dof
END TYPE

!-- BRIDGE: L2 Solver ← L1 BLAS/LAPACK
SUBROUTINE L2_Solve_GMRES(lin_sys, solver_config, solution, converged)
  TYPE(Linear_System_L2), INTENT(INOUT) :: lin_sys
  TYPE(Solver_Config_L2), INTENT(IN) :: solver_config
  real(wp), INTENT(OUT) :: solution(:)
  logical, INTENT(OUT) :: converged
  
  ! GMRES iteration
  DO iter = 1, max_iter
    ! Sparse matrix-vector product (L2←L1 Bridge)
    CALL SpMV_CCS(lin_sys%K, lin_sys%u, y)    ! y = K · u (BLAS-3 adapted)
    
    ! Residual
    residual = lin_sys%R - y                   ! r = b - A·x (BLAS-1)
    
    ! BLAS-1 operations
    rk_norm = DNRM2(lin_sys%n_dof, residual, 1)  ! L2 norm
    
    ! Orthogonalization (Gram-Schmidt)
    CALL DGEMM('T', 'N', m, 1, n_dof, 1.0_wp, basis_matrix, n_dof, &
               residual, n_dof, 0.0_wp, proj_coeffs, m)  ! BLAS-3
    
    ! Update solution
    CALL DAXPY(n_dof, 1.0_wp, correction_vector, 1, lin_sys%u, 1)  ! BLAS-1
    
    ! Convergence check
    IF (rk_norm < tolerance * rhs_norm) THEN
      converged = .TRUE.
      EXIT
    END IF
  END DO
  
  solution = lin_sys%u
END SUBROUTINE

!-- OUTPUT: Solved displacement vector
real(wp), allocatable :: u_solution(:)  ! [n_dof] displacement
```

### 算法栈：L2←L1

```
L2 (Numerical Methods)
  GMRES Solver
    ├─ SpMV: A·x (sparse matrix-vector)
    │  ├─ CCS format indexing
    │  └─ BLAS-3 DGEMM (dense block multiply)  ← L2←L1 Bridge
    │
    ├─ Gram-Schmidt orthogonalization
    │  └─ BLAS-3 DGEMM, BLAS-1 DNRM2  ← L2←L1 Bridge
    │
    └─ Convergence test
       └─ BLAS-1 DNRM2, DDOT  ← L2←L1 Bridge

L1 (Foundations)
  ├─ BLAS-1: Vector ops (DOT, AXPY, SCAL, NRM2)
  ├─ BLAS-2: Matrix-vector ops (GEMV, SYMV)
  ├─ BLAS-3: Matrix-matrix ops (GEMM, SYMM)
  └─ LAPACK: Linear system solving (DGESV, DSYMEV)
```

---

## 📈 完整数据流图

```
L6: User Application
┌─────────────────────────────┐
│ *.inp Job specification     │
│ Analysis_Spec TYPE         │
└──────────────┬──────────────┘
               │ L6←L5 Bridge
               ▼
L5: Runtime Solver (Main Loop)
┌─────────────────────────────┐
│ DO kstep = 1, n_steps       │
│   DO kinc = 1, n_increments │
│     DO iter = 1, max_iter   │
└──────────────┬──────────────┘
               │ L5←L4 Bridge
               ▼
L4: Physics (Element & Material)
┌─────────────────────────────┐
│ DO elem = 1, n_elements     │
│   DO ip = 1, n_gauss_pts    │
│     CALL PH_UMAT_API        │
│   END DO                    │
│   Assemble elem K, R        │
│ END DO                      │
│                             │
│ ↑ Uses L4←L3 Bridge         │
│   (Material dispatch)       │
└──────────────┬──────────────┘
               │ L3←L2 Bridge
               ▼
L3: Model Description → L2
┌─────────────────────────────┐
│ Global K assembly           │
│ Global R aggregation        │
│ BC enforcement              │
│ Format: CCS sparse matrix   │
└──────────────┬──────────────┘
               │ L2←L1 Bridge
               ▼
L2: Numerical Methods
┌─────────────────────────────┐
│ GMRES solver                │
│ SpMV operation              │
│ Convergence test            │
│ Update u displacement       │
└──────────────┬──────────────┘
               │ L2←L1 Bridge
               ▼
L1: Foundations (BLAS/LAPACK)
┌─────────────────────────────┐
│ BLAS-1: DNRM2, DDOT, DAXPY  │
│ BLAS-3: DGEMM               │
│ LAPACK: Dense factorization │
└─────────────────────────────┘
```

---

## 🔗 Bridge 设计原则

| 原则 | 说明 | 实现 |
|------|------|------|
| **单向流** | 严格向下流向，禁止反向 | L6→L1 通道，L1 无感知上层 |
| **契约隔离** | 各层接口定义明确 | TYPE 定义在 `*_Types.f90` |
| **数据映射** | Bridge ≠ 数据复制，而是索引/指针转换 | CLASS 指针、slot_base 计算 |
| **性能隔离** | 热路径与冷路径分离 | L4_PH 内 IP 循环隔离，禁止 ALLOCATE |
| **多态支持** | SELECT TYPE 实现运行时分发 | L4←L3 多材料无开销分发 |

---

## 📋 Bridge 清单

| # | 源 | 目标 | 类型 | 关键机制 |
|---|----|----|------|---------|
| 1 | L6 | L5 | 意图→序列 | Job 解析、Step 编排 |
| 2 | L5 | L4 | 序列→计算 | Element 循环、UMAT 调用 |
| 3 | L4 | L3 | 计算→模型 | SELECT TYPE、sect_id lookup、SVARS 映射 |
| 4 | L3 | L2 | 模型→系统 | Assembly、稀疏格式、BC 消元 |
| 5 | L2 | L1 | 系统→算法 | SpMV、BLAS 适配、迭代控制 |

---

## ✅ 验证清单

- [x] 每个 Bridge 有明确的**输入/输出 TYPE**
- [x] 数据流向**单向递进**（L6→L1）
- [x] 各层通过**接口契约**而非直接调用
- [x] **多态机制**（SELECT TYPE）零成本分发
- [x] **SVARS 持久化**机制清晰（L4←L3）
- [x] **热路径**（IP 循环内）与冷路径隔离
- [x] 每个 Bridge 都有**对应的 Fortran 子程序签名**示例

