# UFC 统一类型系统设计（MD / PH / RT 三层）

**Scope**: UFC Core — MD_ / PH_ / RT_ 三层前缀类型体系  
**Domain**: Element + Section + Material Triad Architecture  
**Version**: 3.1 — 调整命名次序：四大类 Desc/State/Algo/Ctx 统一作为**最终后缀**，即 `MD_Mat_Base_Desc` 而非 `MD_Mat_Desc_Base`  
**Date**: 2026-03-26

---

## 设计演进记录

| 版本 | 变更说明 |
|------|---------|
| v1.0 | 初始三域架构：Elem / Section / Mat 各自持有 `XXX_Types.f90` |
| v2.0 | 用户提出「大一统 MD_Base_Types」方案 → 评估拒绝 → 确立「域分散 + MD_Common_Ctx」最终架构 |
| v3.0 | 废弃 L3/L4/L5 层级前缀 → 统一采用 `MD_`/`PH_`/`RT_` 语义前缀；增补不对称四大类矩阵与三种嵌套关联模式 |
| v3.1 | 命名次序调整：四大类 Desc/State/Algo/Ctx 统一作为**最终后缀**，如 `MD_Mat_Base_Desc`、`PH_Mat_Base_Ctx`、`RT_Common_Ctx` |

---

## Part 0A：用户设计意图（原始问题）

**用户提案**：  
能否创建一个更大的 `MD_Base_Types` 或 `PH_Base_Types`，把每个域（材料、单元、截面、载荷、边界、接触等）的子4大类统一放在这个更大的模块中？

```
MD_Mat/Elem/Sect/Load/BC/Contact_Base_Desc/State/Algo/Ctx
内部嵌套或重叠，各子域不再单独设计 XXX_Types.f90
```

**用户意图本质**：

1. **DRY 原则** — 避免每个域重复定义相似的 Desc/State/Algo/Ctx  
2. **统一管理** — 一个模块 `USE` 即获得所有基础类型  
3. **概念复用** — 4大类模式在所有域都适用

---

## Part 0B：大一统方案评估（五大致命问题）

**评估结论：❌ 不推荐大一统方案**

### 问题 1：4大类语义跨域完全不同，无法共享同一基类型

同名的 Desc/State/Algo/Ctx，各域语义完全不同：

| 域 | Desc | State | Ctx |
|----|------|-------|-----|
| Material | `E, nu, G, K, rho` | `stress(6), ddsdde` | `time, temp, IP` |
| Element | `nnode, ndof_el` | `rhs(:), amatrx(:,:)` | `coords, u, du` |
| Section | `section_id, mat_id` | （无 State） | `thickness, ori` |
| Load | `load_type, dof_set` | `load_val(:)` | `amplitude, curve` |
| BC | `bc_type, node_set` | `disp_val(:)` | `ramp_flag` |
| Contact | `contact_type, fric` | `gap(:), pressure(:)` | `slave/master surf` |

**结论**：强行统一基类 → 基类要么极度臃肿（覆盖所有域），要么极度空洞（只剩空壳），两者都不可用。

### 问题 2：Fortran 编译级联——牵一发动全身

```
大一统模块内任意域改动
  → 重编整个 MD_Base_Types
  → 所有依赖此模块代码全部重编
  → 整个工程重编（100+ 文件）

现有分散方案：
  只改 MD_Mat_Types.f90 → 只有材料相关模块重编
```

### 问题 3：Fortran 限制——同模块内 POINTER 前向引用限制

`MD_Sect_Base_Desc` 内 `mat_desc` 需 `POINTER` 指向 `MD_Mat_Base_Desc`。全在同一模块时，Fortran 无真正前向声明（不像 C++），`CLASS(*)` 方案虽可绕过但丧失类型安全，得不偿失。

### 问题 4：循环依赖风险

```
PH_Mat_Base_Ctx  被  PH_Elem_Base_Ctx CONTAINS
PH_Elem_Base_Ctx 被  MD_Sect_Base_Desc USES
MD_Sect_Base_Desc 含  mat_desc → MD_Mat_Base_Desc
全在一个模块 → 内部自引用，编译器可能拒绝或产生未定义行为
```

### 问题 5：各域 Ctx 的时间粒度完全不同，合并将引发逻辑混乱

| 类型 | 粒度 | 说明 |
|------|------|------|
| `PH_Mat_Base_Ctx` | 积分点级 | 每个 Gauss 点一个实例 |
| `PH_Elem_Base_Ctx` | 单元级 | 每个单元一个实例 |
| `LoadCtx` | 步骤级 | 每个分析步一个实例 |
| `BCCtx` | 步骤级 | 每个分析步一个实例 |
| `ContactCtx` | 接触对级 | 整个接触面一个实例 |

**合并 = 混淆时间粒度 → 逻辑错误根源，调试极难。**

---

## Part 0C：最终决策——域分散 + RT_Common_Ctx

**DECISION**: 保留域分散设计，新增极精简的 `RT_Common_Ctx`

> 命名演进：`MD_Common_Ctx` → `L5_RT_Common_Ctx`（v2.0）→ **`RT_Common_Ctx`**（v3.0）  
> v3.0 彻底废弃 L3/L4/L5 层级前缀，统一采用 `MD_`/`PH_`/`RT_` 语义前缀。

真正跨域通用的字段只有：时间、步号、增量号、迭代号、分析类型  
→ 统一提取到 `RT_Common_Ctx`  
→ 各域的 **PH_ Ctx** 通过组合引入，或直接由 `RT_Common_Ctx` 在调用链中传递  
→ 域内专属字段仍在各自 `XXX_Types.f90`

### 推荐架构（MD/PH/RT 三层×四类共享模型）

```
IF_Prec / IF_Err_API                      ← 精度、错误（纯通用基础层）
        ↓
RT_Common_Ctx.f90                         ← RT运行时公共上下文（极精简）
  ├── time_step, time_total, dtime        ← 全局时间（ABAQUS: TIME/DTIME）
  ├── kstep, kinc, iter                   ← 步/增量/迭代计数
  ├── analysis_type                       ← 分析类型标志
  ├── large_def                           ← 大变形开关
  ├── first_increment                     ← 首增量标志
  └── lflags(5)                           ← 分析阶段控制（ABAQUS: LFLAGS）
        ↓ 在RT调用栈中传递到各域
┌──────────────────────────┬──────────────────────────┐
│  MD_（静态，跨增量持久）         │  PH_（动态，增量内计算）         │
├──────────┬───────────────┼──────────┬───────────────┤
│ MD_Mat   │ MD_Elem       │ PH_Mat   │ PH_Elem       │
│ _Desc    │ _Desc         │ _Ctx     │ _Ctx          │
│ _State   │ _State(局阵) │ _State   │ _State        │
│ _Algo    │ _Algo         │ _Algo    │ _Algo         │
│ MD_Sect  │               │          │               │
│ _Desc    │               │          │               │
└──────────┴───────────────┴──────────┴───────────────┘
```

### 三方案对比

| 方案 | 耦合度 | 可维护性 | Fortran 兼容 | 推荐度 |
|------|--------|---------|--------------|--------|
| 大一统 MD_Base_Types | 极高 | 极差 | 有风险 | ❌ 否 |
| 完全分散（当前） | 低 | 良好 | ✅ 安全 | ⚠️ 可接受 |
| **分散 + MD_Common_Ctx** | **低** | **优秀** | **✅ 安全** | **✅ 推荐** |

---

## Part 0D：RT_Common_Ctx 字段规范（待实现）

> 命名演进：`MD_Common_Ctx` → `L5_RT_Common_Ctx` → **`RT_Common_Ctx`**（v3.0）

```fortran
TYPE :: RT_Common_Ctx
  !-- 全局时间（RT层，所有域通用）
  REAL(wp) :: time_step  = 0.0_wp    ! 当前步起始时间   (ABAQUS UMAT: TIME(1), UEL: TIME(1))
  REAL(wp) :: time_total = 0.0_wp    ! 总分析时间       (ABAQUS UMAT: TIME(2), UEL: TIME(2))
  REAL(wp) :: dtime      = 0.0_wp    ! 时间步长 Δt      (ABAQUS: DTIME)
  !-- 全局步计数（RT层，所有域通用）
  INTEGER(i4) :: kstep   = 0         ! 步号              (ABAQUS: KSTEP)
  INTEGER(i4) :: kinc    = 0         ! 增量号            (ABAQUS: KINC)
  INTEGER(i4) :: iter    = 0         ! 平衡迭代号        (ABAQUS: 内部)
  !-- 分析控制标志（RT层，所有域通用）
  INTEGER(i4) :: analysis_type = 0   ! 1=static/2=dynamic/3=thermal
  LOGICAL :: large_def       = .FALSE.! 大变形 TL/UL 开关
  LOGICAL :: first_increment = .FALSE.! 当前增量是否为步内首增量
  INTEGER(i4) :: lflags(5) = 0       ! 分析阶段控制      (ABAQUS UEL: LFLAGS)
  !-- 运行时标识（RT层，调试/多域路由）
  INTEGER(i4) :: elem_id   = 0       ! 单元号            (ABAQUS UMAT: NOEL, UEL: JELEM)
  INTEGER(i4) :: gauss_pt  = 0       ! 积分点号          (ABAQUS UMAT: NPT)
  INTEGER(i4) :: layer_id  = 0       ! 截面层号          (ABAQUS UMAT: LAYER)
  INTEGER(i4) :: kspt      = 0       ! 截面积分点        (ABAQUS UMAT: KSPT)
END TYPE RT_Common_Ctx
```

**PH_Mat_Base_Ctx**（物理计算驱动量，纯增量内输入）：

```fortran
TYPE :: PH_Mat_Base_Ctx
  !-- 驱动应变（当前增量的激励）
  REAL(wp) :: dstran(6)    = 0.0_wp  ! 应变增量 Δε      (ABAQUS UMAT: DSTRAN)
  REAL(wp) :: drot(3,3)    = 0.0_wp  ! 增量旋转矩阵      (ABAQUS UMAT: DROT)
  REAL(wp) :: dfgrd1(3,3)  = 0.0_wp  ! 增量末变形梯度F₁  (ABAQUS UMAT: DFGRD1)
  !-- 热/场驱动
  REAL(wp) :: temp         = 0.0_wp  ! 增量末温度        (ABAQUS UMAT: TEMP)
  REAL(wp) :: dtemp        = 0.0_wp  ! 温度增量 ΔT       (ABAQUS UMAT: DTEMP)
  REAL(wp), ALLOCATABLE :: predef(:) ! 预定义场（末）    (ABAQUS UMAT: PREDEF)
  REAL(wp), ALLOCATABLE :: dpred(:)  ! 预定义场增量      (ABAQUS UMAT: DPRED)
  !-- 几何
  REAL(wp) :: coords(3)    = 0.0_wp  ! 积分点当前坐标    (ABAQUS UMAT: COORDS)
  REAL(wp) :: celent       = 0.0_wp  ! 单元特征长度      (ABAQUS UMAT: CELENT)
END TYPE PH_Mat_Base_Ctx
```

访问示例（`RT_Common_Ctx` 在调用链中独立传递）：

```fortran
! UFC 调用签名（MD_/PH_/RT_ 三层一体化设计）：
CALL PH_MAT_UMAT(rt_ctx, ph_ctx, ph_state, md_desc, md_algo)
!                RT_     PH_     PH_       MD_      MD_
!                Ctx     Ctx     State     Desc     Algo

! 访问：
rt_ctx%kstep         ! RT_：步号
ph_ctx%dstran        ! PH_：应变驱动增量
ph_state%stress      ! PH_：响应应力
md_desc%E            ! MD_：杨氏模量（静态参数）
```

### Open Questions 状态更新

| 编号 | 问题 | 决策 |
|------|------|------|
| Q1 | `LFLAGS` 归哪里？ | ✅ 已决策：归 `RT_Common_Ctx`，因为它是框架级分析阶段控制信号 |
| Q2 | Load/BC 的 Ctx 是否真的需要公共上下文？ | ✅ 通过 `RT_Common_Ctx` 在调用链中传递，无需 CONTAINS，更清晰 |
| Q3 | 粒度歧义问题 | ✅ `RT_Common_Ctx` 独立传递，各层自己的 Ctx 不混合粒度 |
| Q4 | `pnewdt` 归哪里？ | ✅ `pnewdt` 是 **RT_Algo** 的输出字段（材料/单元→框架的反馈信号） |
| Q5 | `RT_Common_Ctx` 层级归属 | ✅ 归 **RT_ 层**（非 MD_），独立 `RT/RT_Common_Ctx.f90` |

---

## Part 0E：下一步行动（Action Items）

| 编号 | 任务 | 依赖 | 状态 |
|------|------|------|------|
| AI1 | 创建 `RT/RT_Common_Ctx.f90`（含 14 个字段，见 Part 0D） | Q1-Q5 已决策 | ⏳ |
| AI2 | 修改 `MD_Mat_Types.f90`：拆出并新建 `PH/PH_Mat_Ctx.f90`，保留 `MD_Mat_State_Base`（Type定义归MD） | AI1 完成 | ⏳ |
| AI3 | 修改 `MD_Elem_Types.f90`：将 `ElemCtx` 内容拆分为 `PH_Elem_Ctx` + `MD_Elem_Desc` | AI1 完成 | ⏳ |
| AI4 | 统一 UMAT 调用签名：`PH_MAT_UMAT(rt_ctx, ph_ctx, ph_state, md_desc, md_algo)` | AI1/AI2 完成 | ⏳ |
| AI5 | 统一 UEL 调用签名：`PH_ELEM_UEL(rt_ctx, ph_ctx, ph_state, md_desc, ph_algo, section)` | AI1/AI3 完成 | ⏳ |
| AI6 | 在 RT 层实现 Section 注册表入口 `RT_Get_Section_For_Element` | 独立 | ⏳ |
| AI7 | 更新 ABAQUS 适配层：37/36 平参数 → Pack 为 rt_ctx + ph_ctx + ph_state + md_desc + md_algo | AI4/AI5 完成 | ⏳ |

> ⚠️ AI2/AI3 需评估对现有 PLG/CMP/ELA 等已实现材料模型的影响范围，建议先完成 AI1。

---

## Part I：Material Domain Types（基础层）

Material 域提供被 Element 和 Section 域使用的**基础类型**：

| 类型（v3.1 命名） | 旧名（v3.0） | 职责 | 关键字段 |
|------|------|------|---------|
| `MD_Mat_Base_Desc` | `MD_Mat_Desc_Base` | 材料参数（抽象基类） | `E, nu, G, K, lambda, rho, alpha, mat_id` |
| `MD_Mat_Base_State` | `MD_Mat_State_Base` | 积分点响应（抽象基类） | `stress(6), strain(6), ddsdde(6,6), statev(:)` |
| `MD_Mat_Base_Algo` | `MD_Mat_Algo_Base` | 算法控制（具体类型） | `tolerance, max_iter, integ_scheme, theta` |

> ⚠️ `MD_Mat_Ctx_Base` 已拆分迁移（见 Part 0D）：时间/步号字段 → `RT_Common_Ctx`；增量驱动量 → `PH_Mat_Base_Ctx`。

**扩展模式**（具体材料模型 EXTENDS 基类）：

```fortran
TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_MohrCoulomb_Desc
  REAL(wp) :: cohesion       = 0.0_wp
  REAL(wp) :: friction_angle = 0.0_wp
  REAL(wp) :: dilation_angle = 0.0_wp
END TYPE
```

---

## Part II：Element Domain Types（几何/拓扑）

### 组合模式（CRITICAL）

```fortran
TYPE :: PH_Elem_Base_Ctx
  TYPE(PH_Mat_Base_Ctx) :: mat_ctx    ! ← 组合，非继承
  REAL(wp), ALLOCATABLE :: coords(:,:)
  REAL(wp), ALLOCATABLE :: du(:)
END TYPE
```

**为什么用组合？**

- ✅ 避免复杂继承层次
- ✅ `PH_Elem_Base_Ctx` 直接拥有 `mat_ctx`，无指针开销
- ✅ 访问路径清晰：`elem_ctx%mat_ctx%dstran`
- ✅ 所有权明确：Elem 模块 USE PH_Mat_Base_Ctx

### 字段归属

| 归属 | 字段 | 可见性 |
|------|------|--------|
| `RT_Common_Ctx` | `time_step, dtime, kstep, kinc, elem_id, gauss_pt` | UEL + UMAT |
| `PH_Mat_Base_Ctx` | `dstran, dfgrd1, temp, dtemp, coords, celent` | UMAT only |
| `PH_Elem_Base_Ctx`（直接） | `coords(节点级), du` | UEL only |
| `PH_Elem_Base_State` | `rhs, amatrx, energy, u, v, a` | UEL output |

---

## Part III：Section Domain Types（桥梁层）

Section 是 Element 和 Material 之间的**桥梁**，支持 ABAQUS 的多对多映射。

### MD_Sect_Base_Desc 结构

```fortran
TYPE :: MD_Sect_Base_Desc
  INTEGER(i4)                              :: section_id       ! 唯一 ID
  CHARACTER(LEN=64)                        :: section_name     ! 名称
  INTEGER(i4)                              :: mat_id           ! 引用材料 ID
  CLASS(MD_Mat_Base_Desc), POINTER         :: mat_desc => NULL()! 指向材料的指针
  REAL(wp)                                 :: thickness        ! 壳/梁厚度
  REAL(wp)                                 :: orientation(3)   ! 纤维方向
  REAL(wp)                                 :: offset           ! 截面偏移
  INTEGER(i4)                              :: nlayer           ! 复合层数
  INTEGER(i4)                              :: nintegration_pts ! 厚度方向积分点
  CHARACTER(LEN=16)                        :: integ_rule       ! 积分规则
END TYPE MD_Sect_Base_Desc
```

### 桥梁机制（6步）

1. UEL Wrapper 从 ABAQUS 接收 element ID
2. 查找该单元对应的 `section_id`（用户定义映射）
3. 从注册表获取 `SectionType`
4. 通过 `section%mat_desc` 访问材料（指针）
5. 将 `section` 传入 `PH_XXX_UEL`
6. UEL 内部通过 `section%mat_desc` 调用 UMAT

### 多对多映射示例

**Case 1**：多个单元集合 → 同一材料
```
ELEMENT_SET_E1 → SECTION_101 → MATERIAL_1 (Steel)
ELEMENT_SET_E2 → SECTION_102 → MATERIAL_1 (Steel)
```

**Case 2**：复合层压板
```
ELEMENT_SET_SHELL → SECTION_201 (nlayer=3)
  Layer 1: MATERIAL_10 (Carbon fiber)
  Layer 2: MATERIAL_11 (Glass fiber)
  Layer 3: MATERIAL_10 (Carbon fiber)
```

**Case 3**：参数化研究
```
ELEMENT_SET_BEAM → SECTION_301 → MATERIAL_2 (Aluminum)
ELEMENT_SET_BEAM → SECTION_302 → MATERIAL_3 (Titanium)
```

---

## Part IV：完整数据流

### 调用链（ABAQUS → UFC → UMAT）

```
ABAQUS Solver
  ↓
UEL(...) [用户适配层]
  ↓ Step 1: Pack UEL arrays → UFC structures
  rt_ctx%kstep, rt_ctx%kinc, rt_ctx%dtime
  ph_ctx%du, ph_ctx%coords
  ph_state%rhs, ph_state%amatrx
  ↓ Step 2: Get Section for this element
  CALL RT_Get_Section_For_Element(JELEM, section)
  ↓ Step 3: Verify material association
  IF (.NOT. ASSOCIATED(section%mat_desc)) ERROR
  ↓ Step 4: Call unified interface
  CALL PH_ELEM_UEL(rt_ctx, ph_ctx, ph_state, md_desc, ph_algo, section)
    ↓ [element formulation loop]
    DO ip = 1, nintegration_pts
      ph_ctx%mat_ctx%dstran = B_matrix · du
      mat_desc => section%mat_desc         ! ← 通过 Section 获取材料
      CALL PH_MAT_UMAT(rt_ctx, ph_ctx%mat_ctx, mat_state, mat_desc, md_algo)
      internal_force += Bᵀ · stress · detJ · weight
      amatrx += Bᵀ · ddsdde · B · detJ · weight
    END DO
  ↓ Step 5: Unpack (已通过指针完成)
```

### 内存布局

```
PH_Elem_Base_Ctx（每次 UEL 调用分配一次）
  ├── mat_ctx : PH_Mat_Base_Ctx  ← 直接组合（owned）
  │   ├── dstran(6) = 增量应变
  │   ├── dfgrd1(3,3) = 增量末变形梯度
  │   ├── temp = 298.15
  │   └── celent = 0.01
  ├── coords(:,:)  ← 节点当前坐标
  └── du(:)        ← 位移增量

RT_Common_Ctx（调用链中独立传递）
  ├── kstep = 2, kinc = 15
  ├── dtime = 1.0e-5
  ├── elem_id = 1024, gauss_pt = 3
  └── lflags = [1,0,0,0,0]

MD_Sect_Base_Desc（来自注册表，跨调用持久）
  ├── section_id = 101
  ├── mat_id = 1
  ├── thickness = 0.005
  └── mat_desc ──────────→ MD_Mat_Base_Desc
                              ├── E = 210e9
                              ├── nu = 0.3
                              └── model_name = "LinearElastic"
```

### 内存管理原则

| 对象 | 生命周期 | 说明 |
|------|---------|------|
| `PH_Elem_Base_Ctx` | 每次 UEL 调用 | 栈上分配，自动释放 |
| `PH_Elem_Base_State` | 每次 UEL 调用 | 栈上分配，自动释放 |
| `MD_Sect_Base_Desc` | 注册表持久 | 跨调用存活 |
| `MD_Mat_Base_Desc` | 材料库持久 | 跨调用存活 |
| `mat_desc` 指针 | 非所有权引用 | **不可 DEALLOCATE** |

---

## Part V：实现清单

### 已完成 ✅

| 文件 | 说明 |
|------|------|
| `L3_MD/Material/MD_Mat_Types.f90` | Desc/State/Algo/Ctx 四大基础类型 |
| `docs/templates/MD_Elem_Types.f90` | ElemType/ElemState/ElemCtx |
| `L3_MD/Section/MD_Section_Types.f90` | SectionType/SectionRegistry |
| `docs/templates/PH_XXX_UEL.f90` | UEL 模板（含 section 参数） |
| `docs/templates/MD_Elem_Mat_Coupling_Design.f90` | 数据流设计说明 |

### 待完成 ⏳

| Item | 目标文件 | 说明 |
|------|------|------|
| AI1 | `RT/RT_Common_Ctx.f90` | RT 跨域公共上下文，14 个字段 |
| AI2 | `PH/PH_Mat_Ctx.f90` | 从 MD_Mat_Types 拆出，材料增量驱动量 |
| AI3 | `PH/PH_Elem_Ctx.f90` | ElemCtx 迁移重命名 |
| AI4 | Load/BC/Contact Types | 新建时直接引用 `RT_Common_Ctx` |
| AI5 | L5_RT Section 入口 | `RT_Get_Section_For_Element` 实现 |

### 文件依赖图（目标状态）

```
IF_Prec / IF_Err_API
  └── RT/RT_Common_Ctx.f90      (AI1待创建)
        ├── MD/MD_Mat_Types.f90       (Desc+State+Algo, 现有)
        │     └── MD/MD_Sect_Types.f90   (POINTER → MD_Mat_Desc)
        ├── MD/MD_Elem_Types.f90      (MD_Elem_Desc, 现有)
        ├── PH/PH_Mat_Ctx.f90         (AI2待创建)
        ├── PH/PH_Elem_Ctx.f90        (AI3待创建)
        └── Load/BC/Contact Types     (新建时引用 RT_Common_Ctx)
```

### 接口规范

| 接口 | 状态 | 签名 |
|------|------|------|
| UEL 统一接口 | ✅ 确定 | `PH_ELEM_UEL(rt_ctx, ph_ctx, ph_state, md_desc, ph_algo, section)` |
| UMAT 统一接口 | ✅ 确定 | `PH_MAT_UMAT(rt_ctx, ph_ctx, ph_state, md_desc, md_algo)` |
| Section 查找 | ⏳ 待实现 | `RT_Get_Section_For_Element(elem_id, section)` |
| RT 初始化 | ⏳ 待实现 | `RT_Common_Ctx_Init(rt_ctx, ...)` |

### 兼容性保证

- ✅ 支持 ABAQUS UEL+UMAT 调用规范
- ✅ 兼容独立 UMAT（绕过 Section）
- ✅ 支持 L5_RT 直接类型访问
- ✅ 支持单元-材料多对多映射
- ✅ 零拷贝性能保证

---

---

## Part VI：UMAT/UEL 参数归类矩阵（MD_/PH_/RT_ 一体化设计）

### 核心洞见：三层语义定义

| 前缀 | 名称 | 时间粒度 | Desc | State | Algo | Ctx |
|-----|------|--------|------|-------|------|-----|
| **MD_** | 模型描述 | 跨层持久，分析前确定 | 材料/单元参数，拓扑 | Type定义归MD，计算归PH | 数字方案，分析前配置 | — |
| **PH_** | 物理计算 | 增量级，每增量更新 | — | 应力/内变量/局隃、能量 | Newton 迭代/切线控制 | 增量内驱动量（应变/位移/温度增量） |
| **RT_** | 运行时 | 步级/增量级，框架调度 | — | — | PNEWDT、Newmark参数 | 时间/步号/增量号/分析标志 |

---

### UMAT 参数完整归类（37 个参数）

```
SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,RPL,
     1 DDSDDT,DRPLDE,DRPLDT,STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,
     2 PREDEF,DPRED,CMNAME,NDI,NSHR,NTENS,NSTATV,PROPS,NPROPS,
     3 COORDS,DROT,PNEWDT,CELENT,DFGRD0,DFGRD1,NOEL,NPT,
     4 LAYER,KSPT,KSTEP,KINC)
```

| # | ABAQUS 参数 | I/O | 层 | 类型 | UFC 字段 | 语义说明 |
|---|------------|-----|-----|------|---------|--------|
| 1 | STRESS(NTENS) | IO | L4_PH | **State** | `ph_state%stress` | Cauchy 应力（增量始输入，增量末输出） |
| 2 | STATEV(NSTATV) | IO | L4_PH | **State** | `ph_state%statev` | 内变量（解相关，平衡迭代内保持） |
| 3 | DDSDDE(NTENS,NTENS) | O | L4_PH | **State** | `ph_state%ddsdde` | 一致切线局隃度 C_tan |
| 4 | SSE | IO | L4_PH | **State** | `ph_state%elastic_energy` | 比弹性应变能 |
| 5 | SPD | IO | L4_PH | **State** | `ph_state%plastic_work` | 比塑性耗散 |
| 6 | SCD | IO | L4_PH | **State** | `ph_state%creep_dissip` | 比蔑变耗散 |
| 7 | RPL | O | L4_PH | **State** | `ph_state%rpl` | 体积热生成速率（热分析） |
| 8 | DDSDDT(NTENS) | O | L4_PH | **State** | `ph_state%ddsddt` | ∂σ/∂T |
| 9 | DRPLDE(NTENS) | O | L4_PH | **State** | `ph_state%drplde` | ∂RPL/∂ε |
| 10 | DRPLDT | O | L4_PH | **State** | `ph_state%drpldt` | ∂RPL/∂T |
| 11 | **STRAN(NTENS)** | I | L4_PH | **State** | `ph_state%stran` | 增量始**历史应变状态**（输入，非驱动量） |
| 12 | **DSTRAN(NTENS)** | I | L4_PH | **Ctx** | `ph_ctx%dstran` | 应变增量（本增量驱动量） |
| 13 | TIME(2) | I | L5_RT | **Ctx** | `rt_ctx%time_step`, `rt_ctx%time_total` | [步时间, 总时间] |
| 14 | DTIME | I | L5_RT | **Ctx** | `rt_ctx%dtime` | 时间步长 Δt |
| 15 | TEMP | I | L4_PH | **Ctx** | `ph_ctx%temp` | 增量末温度（热驱动场） |
| 16 | DTEMP | I | L4_PH | **Ctx** | `ph_ctx%dtemp` | 温度增量 ΔT |
| 17 | PREDEF(NPREDF) | I | L4_PH | **Ctx** | `ph_ctx%predef` | 预定义场变量（增量末） |
| 18 | DPRED(NPREDF) | I | L4_PH | **Ctx** | `ph_ctx%dpred` | 预定义场增量 |
| 19 | CMNAME | I | L3_MD | **Desc** | `md_desc%model_name` | 材料名称字符串 |
| 20 | NDI | I | L3_MD | **Desc** | `md_desc%ndi` | 法向应力分量数 |
| 21 | NSHR | I | L3_MD | **Desc** | `md_desc%nshr` | 剪切应力分量数 |
| 22 | NTENS | I | L3_MD | **Desc** | `md_desc%ntens` | 应力张量分量总数 = NDI+NSHR |
| 23 | NSTATV | I | L3_MD | **Desc** | `md_desc%nstatv` | 内变量数 |
| 24 | PROPS(NPROPS) | I | L3_MD | **Desc** | `md_desc%props` / 具体字段 | 材料参数数组 |
| 25 | NPROPS | I | L3_MD | **Desc** | `md_desc%nprops` | 参数个数 |
| 26 | COORDS(3) | I | L4_PH | **Ctx** | `ph_ctx%coords` | 积分点当前坐标 |
| 27 | DROT(3,3) | I | L4_PH | **Ctx** | `ph_ctx%drot` | 增量旋转矩阵（有限变形） |
| 28 | **PNEWDT** | O | L5_RT | **Algo** | `rt_algo%pnewdt` | 建议时间步比（材料→框架反馈） |
| 29 | CELENT | I | L4_PH | **Ctx** | `ph_ctx%celent` | 单元特征长度（粘性/正则化用） |
| 30 | **DFGRD0(3,3)** | I | L4_PH | **State** | `ph_state%dfgrd0` | 增量始变形梯度 F₀（历史状态） |
| 31 | **DFGRD1(3,3)** | I | L4_PH | **Ctx** | `ph_ctx%dfgrd1` | 增量末变形梯度 F₁（目标驱动状态） |
| 32 | NOEL | I | L5_RT | **Ctx** | `rt_ctx%elem_id` | 单元号（运行时标识） |
| 33 | NPT | I | L5_RT | **Ctx** | `rt_ctx%gauss_pt` | 积分点号 |
| 34 | LAYER | I | L5_RT | **Ctx** | `rt_ctx%layer_id` | 截面层号 |
| 35 | KSPT | I | L5_RT | **Ctx** | `rt_ctx%kspt` | 截面积分点 |
| 36 | KSTEP | I | L5_RT | **Ctx** | `rt_ctx%kstep` | 步号 |
| 37 | KINC | I | L5_RT | **Ctx** | `rt_ctx%kinc` | 增量号 |

> **关键区分原则**：
> - **STRAN/DFGRD0 → State**：增量始的历史状态，是“已知的过去”  
> - **DSTRAN/DFGRD1 → Ctx**：本增量的驱动目标，是“这次的输入激励”  
> - **PNEWDT → L5_RT Algo**：材料计算→返回给框架的时间控制反馈

---

### UEL 参数完整归类（36 个参数）

```
SUBROUTINE UEL(RHS,AMATRX,SVARS,ENERGY,NDOFEL,NRHS,NSVARS,
     1 PROPS,NPROPS,COORDS,MCRD,NNODE,U,DU,V,A,JTYPE,TIME,
     2 DTIME,KSTEP,KINC,JELEM,PARAMS,NDLOAD,JDLTYP,ADLMAG,
     3 PREDEF,NPREDF,LFLAGS,MLVARX,DDLMAG,MDLOAD,PNEWDT,
     4 JPROPS,NJPROP,PERIOD)
```

| # | ABAQUS 参数 | I/O | 层 | 类型 | UFC 字段 | 语义说明 |
|---|------------|-----|-----|------|---------|--------|
| 1 | RHS(MLVARX,NRHS) | O | L4_PH | **State** | `ph_state%rhs` | 残差/外力向量 |
| 2 | AMATRX(NDOFEL,NDOFEL) | O | L4_PH | **State** | `ph_state%amatrx` | 切线/质量/阻尼矩阵 |
| 3 | SVARS(NSVARS) | IO | L4_PH | **State** | `ph_state%svars` | 单元状态变量 |
| 4 | ENERGY(8) | IO | L4_PH | **State** | `ph_state%energy` | 运动/内/耗散能量数组 |
| 5 | NDOFEL | I | L3_MD | **Desc** | `md_desc%ndofel` | 单元 DOF 总数 |
| 6 | NRHS | I | L5_RT | **Ctx** | `rt_ctx%nrhs` | RHS 列数（由分析类型决定） |
| 7 | NSVARS | I | L3_MD | **Desc** | `md_desc%nsvars` | 状态变量数 |
| 8 | PROPS(NPROPS) | I | L3_MD | **Desc** | `md_desc%props` | 单元参数 |
| 9 | NPROPS | I | L3_MD | **Desc** | `md_desc%nprops` | 参数个数 |
| 10 | COORDS(MCRD,NNODE) | I | L4_PH | **Ctx** | `ph_ctx%coords` | 节点当前坐标（当前构形） |
| 11 | MCRD | I | L3_MD | **Desc** | `md_desc%mcrd` | 坐标分量数（空间维度） |
| 12 | NNODE | I | L3_MD | **Desc** | `md_desc%nnode` | 单元节点数 |
| 13 | **U(NDOFEL)** | I | L4_PH | **State** | `ph_state%u` | 当前总位移（当前构形历史状态） |
| 14 | **DU(MLVARX,*)** | I | L4_PH | **Ctx** | `ph_ctx%du` | 位移增量（本增量驱动量） |
| 15 | V(NDOFEL) | I | L4_PH | **State** | `ph_state%v` | 当前速度（动力学状态） |
| 16 | A(NDOFEL) | I | L4_PH | **State** | `ph_state%a` | 当前加速度（动力学状态） |
| 17 | JTYPE | I | L3_MD | **Desc** | `md_desc%jtype` | 单元类型标识符 |
| 18 | TIME(2) | I | L5_RT | **Ctx** | `rt_ctx%time_step`, `rt_ctx%time_total` | [步时间, 总时间] |
| 19 | DTIME | I | L5_RT | **Ctx** | `rt_ctx%dtime` | 时间步长 Δt |
| 20 | KSTEP | I | L5_RT | **Ctx** | `rt_ctx%kstep` | 步号 |
| 21 | KINC | I | L5_RT | **Ctx** | `rt_ctx%kinc` | 增量号 |
| 22 | JELEM | I | L5_RT | **Ctx** | `rt_ctx%elem_id` | 单元号（运行时标识） |
| 23 | **PARAMS(3)** | I | L4_PH | **Algo** | `ph_algo%params` | Newmark 时间积分参数 (α,β,γ) |
| 24 | NDLOAD | I | L5_RT | **Ctx** | `rt_ctx%ndload` | 当前分布载荷类型数 |
| 25 | JDLTYP(MDLOAD,*) | I | L3_MD | **Desc** | `md_desc%jdltyp` | 分布载荷类型定义（分析前确定） |
| 26 | ADLMAG(MDLOAD,*) | I | L4_PH | **Ctx** | `ph_ctx%adlmag` | 分布载荷幅値（增量末） |
| 27 | PREDEF(2,NPREDF,NNODE) | I | L4_PH | **Ctx** | `ph_ctx%predef` | 预定义场变量 |
| 28 | NPREDF | I | L3_MD | **Desc** | `md_desc%npredf` | 预定义场数量 |
| 29 | **LFLAGS(5)** | I | L5_RT | **Ctx** | `rt_ctx%lflags` | 分析阶段控制标志（框架级） |
| 30 | MLVARX | I | L5_RT | **Ctx** | `rt_ctx%mlvarx` | RHS 存储维度（内存布局） |
| 31 | DDLMAG(MDLOAD,*) | I | L4_PH | **Ctx** | `ph_ctx%ddlmag` | 分布载荷增量（驱动增量） |
| 32 | MDLOAD | I | L3_MD | **Desc** | `md_desc%mdload` | 载荷类型最大数（维度定义） |
| 33 | **PNEWDT** | O | L5_RT | **Algo** | `rt_algo%pnewdt` | 建议时间步比（单元→框架反馈） |
| 34 | JPROPS(NJPROP) | I | L3_MD | **Desc** | `md_desc%jprops` | 整数单元参数 |
| 35 | NJPROP | I | L3_MD | **Desc** | `md_desc%njprop` | 整数参数个数 |
| 36 | PERIOD | I | L5_RT | **Ctx** | `rt_ctx%period` | 分析步周期（周期性分析） |

---

### 归类统计汇总

| 层×类型 | UMAT 参数数 | UEL 参数数 | 主要内容 |
|---------|----------|----------|----------|
| L3_MD Desc | 7 | 13 | 材料参数、单元拓扑、维度定义 |
| L4_PH State | 13 | 7 | 应力/内变量/切线冈度/局阵/位移/速度 |
| L4_PH Ctx | 9 | 7 | 应变增量、变形梯度、温度场、坐标 |
| L4_PH Algo | 0 | 1 | Newmark 参数 |
| L5_RT Ctx | 7 | 8 | 时间、步号、单元号、LFLAGS |
| L5_RT Algo | 1 | 1 | PNEWDT 反馈 |
| **合计** | **37** | **37†** | |

> † UEL 实际 36 个参数，表中 ENERGY/SVARS 合计计入 ph_state。

---

## UFC 接口对比：ABAQUS 原始 vs UFC 结构化

#### 调用签名对比

```fortran
! ── UMAT 侧 ──────────────────────────────────────────────────────────────────
! ABAQUS 原始（扁平 37 参数）
SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,RPL,DDSDDT,DRPLDE,DRPLDT,
     &           STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,PREDEF,DPRED,CMNAME,
     &           NDI,NSHR,NTENS,NSTATV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     &           CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,KSPT,KSTEP,KINC)

! UFC 结构化（5 个对象，Pack/Unpack 适配层负责转换）
CALL PH_MAT_UMAT( rt_ctx,    ph_ctx,    ph_state,    md_desc,    md_algo )
!                 RT_Common  PH_Mat_    PH_Mat_      MD_Mat_     MD_Mat_
!                 _Ctx       Base_Ctx   Base_State   Base_Desc   Base_Algo
!                 [7字段]    [9字段]    [13字段]     [7字段]     [附带]

! ── UEL 侧 ───────────────────────────────────────────────────────────────────
! ABAQUS 原始（扁平 36 参数）
SUBROUTINE UEL(RHS,AMATRX,SVARS,ENERGY,NDOFEL,NRHS,NSVARS,PROPS,NPROPS,
     &          COORDS,MCRD,NNODE,U,DU,V,A,JTYPE,TIME,DTIME,KSTEP,KINC,JELEM,
     &          PARAMS,NDLOAD,JDLTYP,ADLMAG,PREDEF,NPREDF,LFLAGS,MLVARX,
     &          DDLMAG,MDLOAD,PNEWDT,JPROPS,NJPROP,PERIOD)

! UFC 结构化（6 个对象，Pack/Unpack 适配层负责转换）
CALL PH_ELEM_UEL( rt_ctx,    ph_ctx,    ph_state,    md_desc,    ph_algo,    section )
!                 RT_Common  PH_Elem_   PH_Elem_     MD_Elem_    PH_Elem_    MD_Sect_
!                 _Ctx       Base_Ctx   Base_State   Base_Desc   Base_Algo   Base_Desc
!                 [8字段]    [7字段]    [7字段]      [13字段]    [1字段]     [桥梁]
```

---

#### 结构体成员完整清单：按层 × 类型分类

**① RT_Common_Ctx**（RT层 · Ctx · 7+4=14字段 · UMAT+UEL 共用）

| 字段名 | 类型 | 来源 UMAT | 来源 UEL | 语义 |
|--------|------|-----------|----------|------|
| `time_step` | REAL(wp) | TIME(1) | TIME(1) | 当前步起始时间 |
| `time_total` | REAL(wp) | TIME(2) | TIME(2) | 总分析时间 |
| `dtime` | REAL(wp) | DTIME | DTIME | 时间步长 Δt |
| `kstep` | INTEGER(i4) | KSTEP | KSTEP | 分析步号 |
| `kinc` | INTEGER(i4) | KINC | KINC | 增量号 |
| `iter` | INTEGER(i4) | —（内部） | —（内部） | 平衡迭代号 |
| `analysis_type` | INTEGER(i4) | —（派生） | LFLAGS(1) | 1=static/2=dyn/3=thermal |
| `large_def` | LOGICAL | —（派生） | LFLAGS(2) | 大变形 TL/UL 开关 |
| `first_increment` | LOGICAL | —（派生） | LFLAGS(3) | 是否步内首增量 |
| `lflags` | INTEGER(i4)(5) | —（UMAT不含） | LFLAGS | 分析阶段控制标志 |
| `elem_id` | INTEGER(i4) | NOEL | JELEM | 单元号 |
| `gauss_pt` | INTEGER(i4) | NPT | —（UEL不含） | 积分点号 |
| `layer_id` | INTEGER(i4) | LAYER | —（UEL不含） | 截面层号 |
| `kspt` | INTEGER(i4) | KSPT | —（UEL不含） | 截面积分点 |

---

**② PH_Mat_Base_Ctx**（PH层 · Ctx · 9字段 · 材料增量驱动量 · UMAT专用）

| 字段名 | 类型 | 来源 UMAT | 语义 |
|--------|------|-----------|------|
| `dstran` | REAL(wp)(6) | DSTRAN | 应变增量 Δε（本增量驱动量） |
| `drot` | REAL(wp)(3,3) | DROT | 增量旋转矩阵（有限变形） |
| `dfgrd1` | REAL(wp)(3,3) | DFGRD1 | 增量末变形梯度 F₁（驱动目标） |
| `temp` | REAL(wp) | TEMP | 增量末温度（热驱动场） |
| `dtemp` | REAL(wp) | DTEMP | 温度增量 ΔT |
| `predef` | REAL(wp)(:) | PREDEF | 预定义场变量（增量末） |
| `dpred` | REAL(wp)(:) | DPRED | 预定义场增量 |
| `coords` | REAL(wp)(3) | COORDS | 积分点当前坐标 |
| `celent` | REAL(wp) | CELENT | 单元特征长度（粘性/正则化） |

---

**③ PH_Mat_Base_State**（PH层 · State · 13字段 · UMAT 输入/输出）

| 字段名 | 类型 | I/O | 来源 UMAT | 语义 |
|--------|------|-----|-----------|------|
| `stress` | REAL(wp)(NTENS) | IO | STRESS | Cauchy 应力（增量始→末） |
| `statev` | REAL(wp)(:) | IO | STATEV | 内变量（解相关） |
| `ddsdde` | REAL(wp)(NTENS,NTENS) | O | DDSDDE | 一致切线刚度 C_tan |
| `stran` | REAL(wp)(NTENS) | I | STRAN | 增量始历史应变（已知过去） |
| `dfgrd0` | REAL(wp)(3,3) | I | DFGRD0 | 增量始变形梯度 F₀（历史状态） |
| `elastic_energy` | REAL(wp) | IO | SSE | 比弹性应变能 |
| `plastic_work` | REAL(wp) | IO | SPD | 比塑性耗散 |
| `creep_dissip` | REAL(wp) | IO | SCD | 比蠕变耗散 |
| `rpl` | REAL(wp) | O | RPL | 体积热生成速率 |
| `ddsddt` | REAL(wp)(NTENS) | O | DDSDDT | ∂σ/∂T |
| `drplde` | REAL(wp)(NTENS) | O | DRPLDE | ∂RPL/∂ε |
| `drpldt` | REAL(wp) | O | DRPLDT | ∂RPL/∂T |

---

**④ MD_Mat_Base_Desc**（MD层 · Desc · 7字段 · 分析前静态 · UMAT专用）

| 字段名 | 类型 | 来源 UMAT | 语义 |
|--------|------|-----------|------|
| `model_name` | CHARACTER(80) | CMNAME | 材料模型名称 |
| `ndi` | INTEGER(i4) | NDI | 法向应力分量数 |
| `nshr` | INTEGER(i4) | NSHR | 剪切应力分量数 |
| `ntens` | INTEGER(i4) | NTENS | 应力张量分量总数 |
| `nstatv` | INTEGER(i4) | NSTATV | 内变量数 |
| `props` | REAL(wp)(:) | PROPS | 材料参数数组 |
| `nprops` | INTEGER(i4) | NPROPS | 参数个数 |

---

**⑤ MD_Mat_Base_Algo**（MD层 · Algo · 附带 · 数字方案配置 · UMAT专用）

| 字段名 | 类型 | 语义 |
|--------|------|------|
| `tolerance` | REAL(wp) | Newton 收敛容差 |
| `max_iter` | INTEGER(i4) | 最大迭代次数 |
| `integ_scheme` | INTEGER(i4) | 积分方案（0=显式/1=隐式/2=RK4） |
| `theta` | REAL(wp) | θ-方法时间积分参数 |

---

**⑥ PH_Elem_Base_Ctx**（PH层 · Ctx · 7字段 · 单元增量驱动量 · UEL专用）

| 字段名 | 类型 | 来源 UEL | 语义 |
|--------|------|----------|------|
| `mat_ctx` | PH_Mat_Base_Ctx | —（组合） | 材料物理计算上下文（CONTAINS） |
| `coords` | REAL(wp)(:,:) | COORDS | 节点当前坐标 (MCRD×NNODE) |
| `du` | REAL(wp)(:,:) | DU | 位移增量 (MLVARX×NDOFEL) |
| `predef` | REAL(wp)(:,:,:) | PREDEF | 预定义场变量 (2×NPREDF×NNODE) |
| `adlmag` | REAL(wp)(:,:) | ADLMAG | 分布载荷幅值（增量末） |
| `ddlmag` | REAL(wp)(:,:) | DDLMAG | 分布载荷增量 |

> ⚠️ `mat_ctx` 为 CONTAINS 组合字段，非 ABAQUS 直接参数，由适配层在 UEL→UMAT 调用时填充。

---

**⑦ PH_Elem_Base_State**（PH层 · State · 7字段 · UEL 输入/输出）

| 字段名 | 类型 | I/O | 来源 UEL | 语义 |
|--------|------|-----|----------|------|
| `rhs` | REAL(wp)(:,:) | O | RHS | 残差/内力向量 (MLVARX×NRHS) |
| `amatrx` | REAL(wp)(:,:) | O | AMATRX | 切线/质量/阻尼矩阵 (NDOFEL²) |
| `svars` | REAL(wp)(:) | IO | SVARS | 单元状态变量 |
| `energy` | REAL(wp)(8) | IO | ENERGY | 各类能量数组 |
| `u` | REAL(wp)(:) | I | U | 当前总位移（历史状态） |
| `v` | REAL(wp)(:) | I | V | 当前速度（动力学） |
| `a` | REAL(wp)(:) | I | A | 当前加速度（动力学） |

---

**⑧ MD_Elem_Base_Desc**（MD层 · Desc · 13字段 · 分析前静态 · UEL专用）

| 字段名 | 类型 | 来源 UEL | 语义 |
|--------|------|----------|------|
| `ndofel` | INTEGER(i4) | NDOFEL | 单元自由度总数 |
| `nsvars` | INTEGER(i4) | NSVARS | 状态变量数 |
| `props` | REAL(wp)(:) | PROPS | 单元参数数组 |
| `nprops` | INTEGER(i4) | NPROPS | 参数个数 |
| `mcrd` | INTEGER(i4) | MCRD | 坐标分量数（空间维度） |
| `nnode` | INTEGER(i4) | NNODE | 单元节点数 |
| `jtype` | INTEGER(i4) | JTYPE | 单元类型标识符 |
| `npredf` | INTEGER(i4) | NPREDF | 预定义场数量 |
| `jdltyp` | INTEGER(i4)(:,:) | JDLTYP | 分布载荷类型定义 |
| `mdload` | INTEGER(i4) | MDLOAD | 载荷类型最大数 |
| `jprops` | INTEGER(i4)(:) | JPROPS | 整数单元参数 |
| `njprop` | INTEGER(i4) | NJPROP | 整数参数个数 |

---

**⑨ PH_Elem_Base_Algo**（PH层 · Algo · 1字段 · UEL专用）

| 字段名 | 类型 | 来源 UEL | 语义 |
|--------|------|----------|------|
| `params` | REAL(wp)(3) | PARAMS | Newmark 时间积分参数 (α, β, γ) |

---

**⑩ MD_Sect_Base_Desc**（MD层 · Section桥梁 · UEL专用 · 来自注册表）

| 字段名 | 类型 | 来源 | 语义 |
|--------|------|------|------|
| `section_id` | INTEGER(i4) | 注册表 | 唯一截面 ID |
| `mat_id` | INTEGER(i4) | 注册表 | 关联材料 ID |
| `mat_desc` | CLASS(MD_Mat_Base_Desc), POINTER | POINTER桥梁 | 指向材料描述（非所有权） |
| `thickness` | REAL(wp) | 注册表 | 壳/梁厚度 |
| `nlayer` | INTEGER(i4) | 注册表 | 复合层数 |
| `nintegration_pts` | INTEGER(i4) | 注册表 | 厚度方向积分点数 |

---

**⑪ RT_Algo**（RT层 · Algo · 反馈输出 · UMAT+UEL 共用）

| 字段名 | 类型 | I/O | 来源 UMAT | 来源 UEL | 语义 |
|--------|------|-----|-----------|----------|------|
| `pnewdt` | REAL(wp) | O | PNEWDT | PNEWDT | 建议时间步比（计算→框架反馈） |

---

#### 内部关联设计：对象间引用关系

```
调用链：ABAQUS → 适配层 → UFC 结构化接口

                    ┌─────────────────────────────────────────────┐
                    │           UMAT 调用路径                      │
                    │                                             │
  RT_Common_Ctx ────┤──→ rt_ctx%kstep / dtime / elem_id          │
  PH_Mat_Base_Ctx ──┤──→ ph_ctx%dstran / dfgrd1 / temp           │
  PH_Mat_Base_State─┤←→ ph_state%stress / statev / ddsdde        │
  MD_Mat_Base_Desc──┤──→ md_desc%E / nu / nprops  (只读)         │
  MD_Mat_Base_Algo──┤──→ md_algo%tolerance / max_iter (只读)      │
  RT_Algo ──────────┤←── rt_algo%pnewdt  (只写，反馈框架)         │
                    └─────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────┐
                    │           UEL 调用路径                       │
                    │                                             │
  RT_Common_Ctx ────┤──→ rt_ctx%kstep / lflags / elem_id         │
  PH_Elem_Base_Ctx──┤──→ ph_ctx%coords / du                      │
  │  └─mat_ctx ─────┤──→ ph_ctx%mat_ctx%dstran  ← 由UEL填充后   │
  │                 │     传递给内嵌 UMAT 调用                    │
  PH_Elem_Base_State┤←→ ph_state%rhs / amatrx                    │
  MD_Elem_Base_Desc─┤──→ md_desc%nnode / ndofel (只读)            │
  PH_Elem_Base_Algo─┤──→ ph_algo%params  (只读)                   │
  MD_Sect_Base_Desc─┤──→ section%mat_desc ──POINTER──→ MD_Mat_Base_Desc
  RT_Algo ──────────┤←── rt_algo%pnewdt  (只写，反馈框架)         │
                    └─────────────────────────────────────────────┘

跨调用关联（持久对象）：
  注册表
  └── MD_Sect_Base_Desc[section_id=101]
        └── mat_desc ──POINTER──→ MD_Mat_Base_Desc[mat_id=1]
                                    └── EXTENDS → MD_Mat_ELA_Desc { E, nu }
                                                  MD_Mat_PLG_Desc { yield, H }
```

#### UMAT 专有 vs UEL 专有 vs 共用 —— 快速速查表

| 结构体 | UMAT | UEL | 说明 |
|--------|:----:|:---:|------|
| `RT_Common_Ctx` | ✅ | ✅ | 共用，14字段（部分字段仅一侧赋值） |
| `RT_Algo` | ✅ | ✅ | 共用，pnewdt 输出 |
| `PH_Mat_Base_Ctx` | ✅ | ⚡ | UMAT直接用；UEL通过 `ph_ctx%mat_ctx` 间接访问 |
| `PH_Mat_Base_State` | ✅ | ❌ | UMAT专有（应力/内变量/切线刚度） |
| `MD_Mat_Base_Desc` | ✅ | ⚡ | UMAT直接用；UEL通过 `section%mat_desc` 间接访问 |
| `MD_Mat_Base_Algo` | ✅ | ❌ | UMAT专有（材料数字方案） |
| `PH_Elem_Base_Ctx` | ❌ | ✅ | UEL专有（节点坐标/位移增量） |
| `PH_Elem_Base_State` | ❌ | ✅ | UEL专有（残差/切线矩阵） |
| `MD_Elem_Base_Desc` | ❌ | ✅ | UEL专有（单元拓扑/维度） |
| `PH_Elem_Base_Algo` | ❌ | ✅ | UEL专有（Newmark参数） |
| `MD_Sect_Base_Desc` | ❌ | ✅ | UEL专有（Section桥梁，来自注册表） |

> ⚡ 表示"间接访问"：该结构体本身不作为参数传入，而是通过另一个结构体的成员引用。

---

### 现有代码与目标架构对齐状态

| 现有字段 | 现归属 | 目标归属 | 操作 |
|----------|------|--------|------|
| `MD_Mat_Ctx_Base%kstep` | 旧 MD_ | RT_ | → `RT_Common_Ctx%kstep` |
| `MD_Mat_Ctx_Base%kinc` | 旧 MD_ | RT_ | → `RT_Common_Ctx%kinc` |
| `MD_Mat_Ctx_Base%analysis_type` | 旧 MD_ | RT_ | → `RT_Common_Ctx%analysis_type` |
| `MD_Mat_Ctx_Base%first_increment` | 旧 MD_ | RT_ | → `RT_Common_Ctx%first_increment` |
| `MD_Mat_Ctx_Base%large_def` | 旧 MD_ | RT_ | → `RT_Common_Ctx%large_def` |
| `MD_Mat_Ctx_Base%time_val` | 旧 MD_ | RT_ | → `RT_Common_Ctx%time_step` |
| `MD_Mat_Ctx_Base%dtime` | 旧 MD_ | RT_ | → `RT_Common_Ctx%dtime` |
| `MD_Mat_Ctx_Base%temp` | 旧 MD_ | PH_ | → `PH_Mat_Base_Ctx%temp` |
| `MD_Mat_Ctx_Base%dtemp` | 旧 MD_ | PH_ | → `PH_Mat_Base_Ctx%dtemp` |
| `MD_Mat_Ctx_Base%ntens` | 旧 MD_ | MD_ Desc | → `MD_Mat_Base_Desc%ntens` |
| `MD_Mat_Ctx_Base%elem_id` | 旧 MD_ | RT_ | → `RT_Common_Ctx%elem_id` |
| `MD_Mat_Ctx_Base%gauss_pt` | 旧 MD_ | RT_ | → `RT_Common_Ctx%gauss_pt` |
| `MD_Mat_Ctx_Base%detF` | 旧 MD_ | PH_ Ctx | → `PH_Mat_Base_Ctx%detF` |
| `ElemCtx%first_increment` | 旧 MD_ | RT_ | 删除，改用 `rt_ctx%first_increment` |
| `ElemCtx%large_def` | 旧 MD_ | RT_ | 删除，改用 `rt_ctx%large_def` |

---

---

## Part VII：命名规范 + 不对称矩阵 + 嵌套设计细则（v3.0 新增）

### 1. 命名规范：前缀 + 域 + 限定词 + **四大类后缀**

**命名格式**：`前缀_域_[限定词_]四大类`

```
前缀     域      限定词(可选)  四大类后缀
 MD_   + Mat  + Base       + Desc    → MD_Mat_Base_Desc
 MD_   + Mat  + Base       + State   → MD_Mat_Base_State
 MD_   + Mat  + Base       + Algo    → MD_Mat_Base_Algo
 PH_   + Mat  + Base       + Ctx     → PH_Mat_Base_Ctx
 PH_   + Mat  + Base       + Algo    → PH_Mat_Base_Algo
 PH_   + Elem + Base       + Ctx     → PH_Elem_Base_Ctx
 PH_   + Elem + Base       + State   → PH_Elem_Base_State
 PH_   + Elem + Base       + Algo    → PH_Elem_Base_Algo
 RT_   + Common            + Ctx     → RT_Common_Ctx
 RT_   +                   + Algo    → RT_Algo
```

**规则**：四大类（Desc/State/Algo/Ctx）必须作为**最终后缀**，读到最后一词即知类型语义。

| 前缀 | 语义 | 对应层级（旧） | 典型类型名（v3.1） | 典型文件名 |
|------|------|---------|---------|--------|
| `MD_` | 模型描述 | 原 L3_MD | `MD_Mat_Base_Desc`、`MD_Elem_Base_Desc`、`MD_Sect_Base_Desc` | `MD_Mat_Types.f90`、`MD_Sect_Types.f90` |
| `PH_` | 物理计算 | 原 L4_PH | `PH_Mat_Base_Ctx`、`PH_Mat_Base_Algo`、`PH_Elem_Base_Ctx`、`PH_Elem_Base_State` | `PH_Mat_Ctx.f90`、`PH_Elem_Ctx.f90` |
| `RT_` | 运行时 | 原 L5_RT | `RT_Common_Ctx`、`RT_Algo` | `RT_Common_Ctx.f90`、`RT_Algo.f90` |

**存在一个特例**：`MD_Mat_Base_State` —— State 的 **Type 定义**归 MD_，**计算更新**归 PH_。
这不是矛盾，而是合理的数据结构与计算逻辑分离。

---

### 2. 不对称四大类矩阵：每层不必全有四类

**关键结论：不是每层都有 Desc/State/Algo/Ctx，而是按语义实际需要配置。**

| 类型 | MD_ 层 | PH_ 层 | RT_ 层 | 说明 |
|------|--------|--------|--------|------|
| **Desc** | ✅ 核心 | ❌ 不需要 | ❌ 不需要 | 描述是静态定义，只属于 MD_ |
| **State** | ✅ Type定义 | ✅ 计算更新 | ❌ 不持有 | State 的字段结构定义归 MD_，计算逻辑归 PH_ |
| **Algo** | ✅ 数字方案 | ✅ 迭代控制 | ✅ 时间步控制 | 三层各有 Algo，但内容完全不同 |
| **Ctx** | ❌ 不需要 | ✅ 增量驱动量 | ✅ 框架调度信息 | Ctx 只属于 PH_ 和 RT_，MD_ 无上下文概念 |

```
具体实例（材料域，v3.1 命名）：
  MD_Mat_Base_Desc   ✔ 材料参数（永久静态）
  MD_Mat_Base_State  ✔ 应力/内变量 Type 定义（持久存储结构）
  MD_Mat_Base_Algo   ✔ 数字方案配置（分析前确定）
  ————————————————————————————————
  PH_Mat_Base_Ctx    ✔ 增量驱动量（DSTRAN/DFGRD1/TEMP等）
  PH_Mat_Base_Algo   ✔ Newton 迭代控制（内核算法配置）
  ————————————————————————————————
  RT_Common_Ctx      ✔ TIME/KSTEP/KINC/LFLAGS/ELEM_ID（框架调度）
  RT_Algo            ✔ PNEWDT 反馈（单元/材料 → 框架）
```

---

### 3. 嵌套关联设计：三种模式

#### 模式 A：**EXTENDS**（Fortran 继承）—— 域内具体扩展抽象基类

```fortran
! 适用：同一域内，具体材料/单元模型对基类的扩展
! 最典型场景：具体材料 Desc 扩展抽象基类（四大类作最终后缀）

TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_ELA_Desc   ! 弹性材料 Desc
  REAL(wp) :: E  = 0.0_wp
  REAL(wp) :: nu = 0.0_wp
END TYPE

TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_PLG_Desc   ! 弹塑性材料 Desc
  REAL(wp) :: yield_stress = 0.0_wp
  REAL(wp) :: hardening    = 0.0_wp
END TYPE

TYPE, EXTENDS(MD_Mat_Base_State) :: MD_Mat_PLG_State  ! 弹塑性材料 State
  REAL(wp) :: ep(6) = 0.0_wp   ! 塑性应变
  REAL(wp) :: epeq  = 0.0_wp   ! 等效塑性应变
END TYPE

! 规则：域内才用 EXTENDS，跨域不用 EXTENDS
! 注：具体模型的命名格式：前缀_域_模型名_四大类
!     如 MD_Mat_ELA_Desc、MD_Mat_PLG_State
```

#### 模式 B：**CONTAINS**（组合）—— 跨域跨层组合

```fortran
! 适用：单元域包含材料域的 Ctx（非继承）
! 最典型场景：PH_Elem_Base_Ctx 包含 PH_Mat_Base_Ctx

TYPE :: PH_Elem_Base_Ctx
  TYPE(PH_Mat_Base_Ctx)  :: mat_ctx    ! 组合：包含材料物理计算上下文
  TYPE(MD_Sect_Base_Desc), POINTER :: section => NULL()  ! 指针：截面横向杠接
  REAL(wp), ALLOCATABLE :: coords(:,:)  ! 单元专属（节点坐标）
  REAL(wp), ALLOCATABLE :: du(:)        ! 单元专属（位移增量）
END TYPE PH_Elem_Base_Ctx

! 访问路径：
elem_ctx%mat_ctx%dstran    ! 通过组合读取材料驱动应变
elem_ctx%mat_ctx%temp      ! 通过组合读取温度

! 规则：跨域全用 CONTAINS，禁用 EXTENDS
```

#### 模式 C：**POINTER**（指针桥梁）—— 跨域非所有权引用

```fortran
! 适用：截面指向材料描述（注册表持久，非所有权）
! 最典型场景：MD_Sect_Base_Desc 指针指向 MD_Mat_Base_Desc

TYPE :: MD_Sect_Base_Desc
  INTEGER(i4) :: section_id = 0
  INTEGER(i4) :: mat_id     = 0
  CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc => NULL()  ! 指针桥梁
  REAL(wp) :: thickness = 0.0_wp
END TYPE MD_Sect_Base_Desc

! 使用：不可 DEALLOCATE mat_desc，生命周期属于材料库
! 规则：跨域非所有权引用用 POINTER，内部所有用 ALLOCATABLE
```

#### 三种模式对比

| 模式 | 时机 | 跨域 | 跨层 | 适用场景 |
|------|------|------|------|----------|
| EXTENDS | 域内 | ❌ | ❌ | 具体模型对抽象基类的扩展 |
| CONTAINS | 跨域 | ✅ | ✅ | 单元Ctx包含材料Ctx，所有权明确 |
| POINTER | 跨域 | ✅ | ❌ | 横向桥梁，非所有权引用 |

---

### 4. 公共基类（Base）设置该否设诗问题

**问：能否设置 `MD_Base_Desc`、`PH_Base_State` 这样的跨域公共基类？**

| 候选 | 实际共有字段 | 结论 | 原因 |
|------|------------|------|------|
| `MD_Base_Desc`（跨域） | 几乎没有 | ❌ 无意义 | 材料 Desc 与 单元 Desc 字段完全不同 |
| `PH_Base_State`（跨域） | 几乎没有 | ❌ 无意义 | 材料 State（应力）与 单元 State（局阵）语义完全不同 |
| `RT_Common_Ctx`（跨域） | TIME/KSTEP/KINC等 | ✅ 有意义 | 这些字段对所有域真正相同 |
| `MD_Mat_Base_Algo`（域内） | 材料算法共有 | ✅ 有意义 | 具体材料 EXTENDS 此基类 |

**结论：跨域公共基类几乎无意义（`RT_Common_Ctx` 是少有的例外）；域内基类（如 `MD_Mat_Base_Desc`）非常必要。**

---

### 5. 完整命名清单（所有已确定类型名）

```
MD_ 前缀（模型描述层）：
  MD_Mat_Base_Desc    抽象基类，具体材料 EXTENDS （如 MD_Mat_ELA_Desc）
  MD_Mat_Base_State   抽象基类，具体材料状态 EXTENDS （如 MD_Mat_PLG_State）
  MD_Mat_Base_Algo    具体类型，数字方案配置
  MD_Elem_Base_Desc   具体类型，单元拓扑（nnode/ndofel/jtype等）
  MD_Sect_Base_Desc   具体类型，截面参数（含 mat_desc 指针）

PH_ 前缀（物理计算层）：
  PH_Mat_Base_Ctx     具体类型，材料增量驱动量
  PH_Mat_Base_Algo    具体类型，材料迭代算法控制
  PH_Elem_Base_Ctx    具体类型，单元增量驱动量（CONTAINS PH_Mat_Base_Ctx）
  PH_Elem_Base_State  具体类型，单元计算输出（rhs/amatrx/energy）
  PH_Elem_Base_Algo   具体类型，单元时间积分参数（Newmark PARAMS）

RT_ 前缀（运行时层）：
  RT_Common_Ctx       具体类型，跨域公共运行时上下文（14 个字段）
  RT_Algo             具体类型，时间步控制反馈（PNEWDT等）
```

--

## Part VIII：设计漏洞审查与修正（v3.1 后审）

> 本节记录对完整文档（v3.1）进行设计审查后发现的所有漏洞及其决策，是 Part VI 结构体成员清单的质量保障层。

---

### 漏洞1 🔴：`PH_Mat_Base_State` 缺失 `stran` / `dfgrd0` 两个字段

**问题描述**：
Part VI UMAT 参数表第11行（STRAN）和第30行（DFGRD0）明确归类为 `PH_Mat_Base_State`，但 Part VI §结构体清单中 `PH_Mat_Base_State` 仅列出12字段（stress/statev/ddsdde/elastic_energy/plastic_work/creep_dissip/rpl/ddsddt/drplde/drpldt），**缺少 stran 和 dfgrd0**，与参数表自相矛盾。

**根本原因**：
- `STRAN`：增量**始**的历史应变状态，是"已知的过去"，归 State（不是 Ctx）
- `DFGRD0`：增量**始**的变形梯度 F₀，同为历史状态，归 State（对应 `DFGRD1` 归 Ctx）

**修正方案**：
`PH_Mat_Base_State` 应包含 **14 个字段**（原12 + stran + dfgrd0）：

```fortran
TYPE :: PH_Mat_Base_State
  ! ── 输出：本构响应 ─────────────────────────────────────────────
  REAL(wp) :: stress(NTENS)           ! IO  STRESS   Cauchy 应力
  REAL(wp), ALLOCATABLE :: statev(:)  ! IO  STATEV   内变量
  REAL(wp) :: ddsdde(NTENS,NTENS)     ! O   DDSDDE   一致切线刚度
  ! ── 输入：历史状态（增量始，是"已知的过去"）──────────────────────
  REAL(wp) :: stran(NTENS)            ! I   STRAN    增量始历史应变
  REAL(wp) :: dfgrd0(3,3)             ! I   DFGRD0   增量始变形梯度 F₀
  ! ── 能量/热：输入输出 ────────────────────────────────────────────
  REAL(wp) :: elastic_energy          ! IO  SSE
  REAL(wp) :: plastic_work            ! IO  SPD
  REAL(wp) :: creep_dissip            ! IO  SCD
  REAL(wp) :: rpl                     ! O   RPL      热生成速率
  REAL(wp) :: ddsddt(NTENS)           ! O   DDSDDT   ∂σ/∂T
  REAL(wp) :: drplde(NTENS)           ! O   DRPLDE   ∂RPL/∂ε
  REAL(wp) :: drpldt                  ! O   DRPLDT   ∂RPL/∂T
END TYPE PH_Mat_Base_State
```

**关键区分原则**（已在 Part VI 中标注，此处再强调）：

| 参数对 | 归属 | 语义 |
|--------|------|------|
| STRAN / DFGRD0 | **State** | 增量**始**的历史状态 = "已知的过去" |
| DSTRAN / DFGRD1 | **Ctx** | 本增量的驱动目标 = "这次的输入激励" |

---

### 漏洞2 🔴：`MD_Section_Types.f90` 现有代码 `mat_desc` POINTER 类型错误

**问题描述**：
现有代码（`MD_Section_Types.f90` 第46行）：
```fortran
TYPE(MD_Mat_Desc_Base), POINTER :: mat_desc => NULL()  ! ❌ 编译错误
```
`MD_Mat_Desc_Base` 是 **ABSTRACT TYPE**，Fortran 规范明确禁止以 `TYPE(abstract_type)` 声明变量或指针，必须用 `CLASS`：
```fortran
CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc => NULL()  ! ✅ 正确
```

**影响范围**：`MD_Section_Types.f90` → `MD_Sect_Types.f90`（重命名后）

**修正方案**：
- 将 `TYPE(MD_Mat_Desc_Base)` 改为 `CLASS(MD_Mat_Base_Desc)`
- 同时，`Section_AssociateMaterial` 的参数类型也需对应改为 `CLASS`

```fortran
! 原代码（错误）
TYPE(MD_Mat_Desc_Base), POINTER :: mat_desc => NULL()

! 修正后
CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc => NULL()

! 关联子程序参数同步修正
SUBROUTINE Section_AssociateMaterial(self, mat_desc_ptr)
  CLASS(SectionType), INTENT(INOUT) :: self
  CLASS(MD_Mat_Base_Desc), INTENT(INOUT), TARGET :: mat_desc_ptr  ! CLASS, not TYPE
  self%mat_desc => mat_desc_ptr
END SUBROUTINE
```

**设计原则补充**（新增 ⑫）：
> 指向 ABSTRACT TYPE 的指针必须声明为 `CLASS(abstract_base), POINTER`，禁用 `TYPE(abstract_base), POINTER`。

---

### 漏洞3 🟡：`PH_Elem_Base_Ctx` 字段数标注不一致

**问题描述**：
调用签名注释写 `[7字段]`，但成员清单表仅列6条（mat_ctx/coords/du/predef/adlmag/ddlmag），且 `mat_ctx` 是 CONTAINS 组合字段而非直接 ABAQUS 参数，存在歧义。

**修正方案**：
- 字段数统一标注为 `[6字段 + 1组合]`
- 注释格式规范：`[直接字段数 + 组合字段]`

```fortran
CALL PH_ELEM_UEL( rt_ctx,    ph_ctx,          ph_state, ...)
!                 RT_Common  PH_Elem_Base_Ctx  ...
!                 _Ctx       [5直接字段+1组合]
!                 [14字段]
```

---

### 漏洞4 🟡：Part 0E Action Items 文件名未对齐 v3.1 命名

**问题**：

| AI编号 | 当前写法（旧） | v3.1 规范名（正确） |
|--------|-------------|-------------------|
| AI2 | `PH/PH_Mat_Ctx.f90` | `PH/PH_Mat_Base_Ctx.f90` |
| AI3 | `PH/PH_Elem_Ctx.f90` | `PH/PH_Elem_Base_Ctx.f90` |

**修正**：见下方更新后的 Part 0E 表格（已在文档中同步修正）。

---

### 漏洞5 🟡：`MD_Mat_Base_Algo` vs `PH_Mat_Base_Algo` 职责边界模糊

**问题描述**：
两者都含有 `max_iter / tolerance` 等字段，但语义层级完全不同，容易混淆。

**决策**（ALGO SPLIT MD vs PH，新增原则 ⑬）：

| 类型 | 归属层 | 配置时机 | 典型字段 | 语义 |
|------|--------|---------|---------|------|
| `MD_Mat_Base_Algo` | MD_ | 分析**前**，静态配置 | `integ_scheme, theta, compute_tangent, use_algorithmic` | 数字积分方案选择，不随增量变化 |
| `PH_Mat_Base_Algo` | PH_ | 增量**内**，迭代控制 | `max_iter, tolerance, pnewdt_min, pnewdt_max, auto_cut` | Newton-Raphson 收敛控制，可能每增量调整 |

**设计意图**：`MD_Mat_Base_Algo` 告诉算法"用什么方案"，`PH_Mat_Base_Algo` 告诉算法"迭代到什么程度停止"。

---

### 漏洞6 🟡：`RT_Common_Ctx` 中 UEL 专有字段如何处理

**问题**：`nrhs`/`mlvarx`/`ndload`/`period` 4个字段仅 UEL 使用，UMAT 端无需感知。

**决策**（纳入 RT_Common_Ctx，原则 ⑭）：
- **纳入** `RT_Common_Ctx`，不单独分出子类型
- UMAT 端适配层在 Pack 时不填充这4个字段（默认零值），无副作用
- 理由：单独为 UEL 创建 `RT_UEL_Ctx` 会违反 ONLY RT_Common_Ctx SHARED 原则，且4个字段的代价远小于引入新类型的复杂度

```fortran
TYPE :: RT_Common_Ctx
  ! ...（原14字段）
  ! ── UEL 专有 RT 字段（UMAT 端保持默认值，无副作用） ────────────
  INTEGER(i4) :: nrhs   = 0    ! UEL: NRHS   RHS 列数
  INTEGER(i4) :: mlvarx = 0    ! UEL: MLVARX RHS 存储维度
  INTEGER(i4) :: ndload = 0    ! UEL: NDLOAD 当前分布载荷类型数
  REAL(wp)    :: period = 0.0_wp ! UEL: PERIOD 分析步周期
END TYPE RT_Common_Ctx
! ∴ RT_Common_Ctx 总字段数：14（原有）+ 4（UEL专有）= 18 字段
```

---

### 漏洞7 🟢：现有模板文件使用旧命名，待升级

**影响文件**：
- `docs/templates/PH_XXX_UMAT.f90`：使用 `MD_Mat_Ctx_Base`、`Mat_Base_Desc`、`Mat_Base_State` 旧名
- `docs/templates/PH_XXX_UEL.f90`：使用 `ElemCtx`、`ElemState`、`SectionType` 旧名
- `docs/templates/MD_Elem_Mat_Coupling_Design.f90`：注释中出现 `MD_Mat_Desc_Base`、`MD_Mat_Ctx_Base` 旧名

**修正计划**：随 Types 模板文件创建时同步升级，见 Part VIII §Types 文件规划。

---

### 漏洞8 🟢：`MD_Mat_Base_State` 中的 `pnewdt` 字段归属错误

**问题**：现有 `MD_Mat_Types.f90`（Line 72）将 `pnewdt = 1.0_wp` 放在 `MD_Mat_State_Base` 中，但 `pnewdt` 是**材料→框架的反馈信号**，属于 **RT_Algo**，不属于 State。

**修正**：
- `MD_Mat_Base_State` 中移除 `pnewdt` 字段
- `pnewdt` 归属 `RT_Algo%pnewdt`（已在 Part VI 明确）

---

### 漏洞总览

| 编号 | 级别 | 影响文件 | 问题 | 修正状态 |
|------|------|---------|------|--------|
| L1 | 🔴 严重 | `PH_Mat_Base_State` 定义 | 缺失 stran/dfgrd0 两字段 | 已决策，待代码落实 |
| L2 | 🔴 编译错误 | `MD_Section_Types.f90` | `TYPE(ABSTRACT)` 应改为 `CLASS` | 已决策，待代码落实 |（建议命名为MD_Sect_Types.f90）
| L3 | 🟡 注释歧义 | `PH_Elem_Base_Ctx` 字段数标注 | 标注方式统一 | 已决策，文档更正 |
| L4 | 🟡 命名不一致 | Part 0E Action Items | 文件名未对齐 v3.1 | 已同步修正 |
| L5 | 🟡 职责模糊 | MD/PH Algo 边界 | Algo 拆分原则未明确 | 已决策（新原则 ⑬）|
| L6 | 🟡 设计问题 | `RT_Common_Ctx` UEL字段 | 4个UEL专有字段纳入策略 | 已决策（纳入，18字段）|
| L7 | 🟢 待升级 | 现有模板文件 | 旧命名未更新 | 随模板创建同步 |
| L8 | 🟢 字段归属 | `MD_Mat_Base_State.pnewdt` | pnewdt 归 RT_Algo | 已决策，待代码落实 |

---

## Part X：四大类全架构推广设计（L3/L4/L5 × 14 域级）

> 本节将 Material/Element/Section 三域的四大类设计范式**推广到 UFC 全架构**，形成**层级×域级×四大类的三维矩阵**。

---

### 1. 核心洞见：跨域贯穿设计

**关键洞察**：Load/BC/Contact/Constraint等域**不是"属于某一层"**，而是**跨三层存在**，每个域在每层都有四大类的**不同切片**。

```
         层级 (Layer)
           ↑
           │ L5_RT  ──┐
           │ L4_PH  ──┼── 纵向：数据流贯穿（如 Load/BC/Contact）
           │ L3_MD  ──┘
           │
           └────────→ 域级 (Domain)
                      Material | Element | Load | BC | Contact | Constraint | ...
                      ↓
                      四大类 (Desc/State/Algo/Ctx)
```

**四大类精确定义（推广版）**：

| 类型 | 归属层 | 职责 | 访问模式 | 典型生命周期 |
|------|--------|------|---------|-------------|
| **Desc（描述型）** | L3_MD（冷路径） | 存储模型元信息、拓扑、配置参数 | 只读（热路径期间冻结） | 整个分析存活 |
| **State（状态型）** | L4_PH（热路径） | 存储计算过程的中间结果、历史变量 | 读写（每增量更新） | 单个增量步或内变量持久 |
| **Algo（算法型）** | L3_MD + L4_PH + L5_RT | 存储求解器参数、超参数 | L3: 分析前配置<br>L4: 迭代内只读<br>L5: 步间可调整 | 分析前/步间/增量内 |
| **Ctx（上下文型）** | L4_PH + L5_RT | 热路径临时缓冲，传递运行时信息 | 读写（栈上分配） | 单次调用或增量步 |

---

### 2. UFC 全域级清单（14 个域）

| 域级编号 | 域名 | 说明 | 跨越层级 |
|---------|------|------|---------||
| D01 | **Material** | 材料本构 | L3_MD + L4_PH |
| D02 | **Element** | 单元公式 | L3_MD + L4_PH |
| D03 | **Section** | 截面桥梁 | L3_MD only |
| D04 | **Part** | 部件几何 | L3_MD only |
| D05 | **Assembly** | 装配体 | L3_MD only |
| D06 | **Step** | 分析步配置 | L3_MD + L5_RT |
| D07 | **Load** | 载荷 | L3_MD + L4_PH + L5_RT |
| D08 | **BC** | 边界条件 | L3_MD + L4_PH + L5_RT |
| D09 | **Constraint** | 约束方程 | L3_MD + L4_PH + L5_RT |
| D10 | **Contact** | 接触对 | L3_MD + L4_PH + L5_RT |
| D11 | **Interaction** | 相互作用 | L3_MD + L4_PH |
| D12 | **Output** | 输出请求 | L3_MD + L5_RT |
| D13 | **Solver** | 求解器配置 | L5_RT + L4_PH |
| D14 | **Mesh** | 网格拓扑 | L3_MD only |

---

### 3. 完整矩阵：14 域 × 3 层 × 4 类型

#### 3.1 Material 域（已完成）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Mat_Base_Desc`<br>(E,nu,rho,mat_id,model_name) | `MD_Mat_Base_State`<br>(stress,stran,statev,dfgrd0) | — | `MD_Mat_Base_Algo`<br>(integ_scheme,theta) |
| **L4_PH** | — | (Type 定义归 MD_) | `PH_Mat_Base_Ctx`<br>(dstran,dfgrd1,temp,dtemp) | `PH_Mat_Base_Algo`<br>(max_iter,tolerance,pnewdt_min) |
| **L5_RT** | — | — | `RT_Common_Ctx`<br>(time,kstep,elem_id,gauss_pt) | `RT_Algo`<br>(pnewdt) |

#### 3.2 Element 域（已完成）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Elem_Base_Desc`<br>(nnode,ndofel,mcrd,jtype,nprops,props) | — | — | — |
| **L4_PH** | — | `PH_Elem_Base_State`<br>(rhs,amatrx,svars,energy,u,v,a) | `PH_Elem_Base_Ctx`<br>(coords,du,predef,adlmag,ddlmag)<br>+ mat_ctx 组合 | `PH_Elem_Base_Algo`<br>(params(3) Newmark) |
| **L5_RT** | — | — | `RT_Common_Ctx`<br>(同上) | — |

#### 3.3 Section 域（已完成）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Sect_Base_Desc`<br>(section_id,mat_id,thickness,<br>nlayer,mat_desc 指针) | — | — | — |
| **L4_PH** | — | — | — | — |
| **L5_RT** | — | — | — | — |

#### 3.4 Load 域（新增设计）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Load_Base_Desc`<br>(load_id,load_name,load_type,<br>region_type,region_id,dof_idx,<br>amplitude_id,direction(3)) | — | — | `MD_Load_Base_Algo`<br>(load_category:<br>CONCENTRATED/PRESSURE/BODY) |
| **L4_PH** | — | `PH_Load_Base_State`<br>(current_magnitude,<br>delta_magnitude,<br>follower_dir(:,:),<br>cycle_count,<br>accumulated_work) | `PH_Load_Base_Ctx`<br>(prescribed_value,<br>prescribed_delta,<br>rotation_matrix(3,3)) | `PH_Load_Base_Algo`<br>(apply_method:<br>1=RAMP, 2=STEP,<br>penalty_stiff) |
| **L5_RT** | — | — | `RT_Load_Base_Ctx`<br>(step_time,total_time,<br>time_increment,<br>step_number,increment_number,<br>analysis_type,nlgeom) | `RT_Load_Base_Algo`<br>(auto_stabilize:<br>粘性正则化开关) |

**设计说明**：
- **Desc**: 一次写入，存储载荷类型、作用区域、幅值曲线引用
- **State**: 每增量更新当前幅值、跟随力方向、疲劳循环计数
- **Ctx**: 传递时间、步号、分析类型等框架上下文
- **Algo**: 分层配置——L3 选载荷类别，L4 控制施加方式，L5 管理稳定性

#### 3.5 BC 域（新增设计）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_BC_Base_Desc`<br>(bc_id,bc_name,bc_type,<br>dof_set_id,value_reference,<br>amplitude_id) | — | — | `MD_BC_Base_Algo`<br>(constraint_formulation:<br>1=PENALTY, 2=LAGRANGE) |
| **L4_PH** | — | `PH_BC_Base_State`<br>(current_value,<br>reaction_force,<br>penetration_gap) | `PH_BC_Base_Ctx`<br>(prescribed_value,<br>prescribed_delta,<br>rotation_matrix(3,3)) | `PH_BC_Base_Algo`<br>(tolerance,penalty_factor) |
| **L5_RT** | — | — | `RT_BC_Base_Ctx`<br>(step_time,kstep,kinc,<br>analysis_type,nlgeom) | `RT_BC_Base_Algo`<br>(adjust_initial_bc:<br>初始过盈调整) |

#### 3.6 Contact 域（新增设计）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Contact_Base_Desc`<br>(contact_id,master_surf_id,<br>slave_surf_id,friction_coeff,<br>contact_type) | — | — | `MD_Contact_Base_Algo`<br>(formulation:<br>1=PENALTY, 2=AUG_LAGRANGE,<br>3=MORTAR) |
| **L4_PH** | — | `PH_Contact_Base_State`<br>(gap(:),pressure(:),<br>slip_distance(:),<br>bond_damage(:)) | `PH_Contact_Base_Ctx`<br>(normal_vec(:,:),<br>tangent_vec(:,:)) | `PH_Contact_Base_Algo`<br>(penalty_stiffness,<br>tolerance,max_augmentations) |
| **L5_RT** | — | — | `RT_Contact_Base_Ctx`<br>(contact_status(:),<br>global_iter) | `RT_Contact_Base_Algo`<br>(overclosure_tolerance,<br>auto_adjust_gap) |

#### 3.7 Constraint 域（新增设计）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Constraint_Base_Desc`<br>(constraint_id,constraint_type,<br>ref_node_id,member_nodes(:)) | — | — | `MD_Constraint_Base_Algo`<br>(method:<br>1=RBE2, 2=RBE3,<br>3=MPC) |
| **L4_PH** | — | `PH_Constraint_Base_State`<br>(lagrange_mult(:),<br>constraint_force(:)) | `PH_Constraint_Base_Ctx`<br>(current_jacobian(:,:)) | `PH_Constraint_Base_Algo`<br>(tolerance,weight_factor) |
| **L5_RT** | — | — | `RT_Constraint_Base_Ctx`<br>(active_flag,is_broken) | `RT_Constraint_Base_Algo`<br>(failure_criterion) |

#### 3.8 Step 域（新增设计）

| 层级 | Desc | State | Ctx | Algo |
|------|------|-------|-----|------|
| **L3_MD** | `MD_Step_Base_Desc`<br>(step_id,step_name,step_type,<br>time_period,nlgeom_flag) | — | — | `MD_Step_Base_Algo`<br>(solver_type:<br>1=DIRECT, 2=ITERATIVE) |
| **L4_PH** | — | — | — | — |
| **L5_RT** | — | — | `RT_Step_Base_Ctx`<br>(current_step_idx,<br>is_first_increment,<br>is_last_increment) | `RT_Step_Base_Algo`<br>(time_auto_cut:<br>自适应时间步) |

#### 3.9～3.14 其他域（规划中）

| 域名 | L3_MD Desc | L4_PH State | L5_RT Ctx | 备注 |
|------|-----------|-----------|----------|------|
| **Part** | `MD_Part_Base_Desc`<br>(part_name,elem_range,<br>node_range,sect_ids) | — | — | 部件几何容器 |
| **Assembly** | `MD_Assembly_Base_Desc`<br>(part_ids(:),total_dofs) | — | — | 最高层容器 |
| **Mesh** | `MD_Mesh_Base_Desc`<br>(elem_connectivity(:,:),<br>node_coords(:,:)) | — | — | 网格拓扑 |
| **Output** | `MD_Output_Base_Desc`<br>(output_vars(:),request_freq) | — | `RT_Output_Base_Ctx`<br>(current_frame,write_flag) | 输出请求 |
| **Solver** | — | `PH_Solver_Base_State`<br>(residual_norm,eigenvalues) | `RT_Solver_Base_Ctx`<br>(global_iter,converged) | 求解器状态 |
| **Interaction** | `MD_Interact_Base_Desc`<br>(inter_type,property_id) | `PH_Interact_Base_State`<br>(bond_damage,wear_depth) | — | 多物理交互 |

---

### 4. 数据流示例：Load 域的完整生命周期

```
┌─────────────────────────────────────────────────────────────┐
│  L3_MD (冷路径 · 分析前配置)                                  │
│                                                              │
│  MD_Load_Base_Desc[load_id=101]                             │
│    ├─ load_type = 'PRESSURE'                                │
│    ├─ region_type = ELEM_SET, region_id = 5                 │
│    ├─ amplitude_id = 3 → MD_Amplitude_Desc[amp_id=3]        │
│    └─ direction = [0,0,1]                                   │
│                                                              │
│  MD_Amplitude_Desc[amp_id=3]                                │
│    └─ curve_type = 'TABULAR', points = [(0,0),(10,1),...]   │
└─────────────────────────────────────────────────────────────┘
                            ↓ FlattenAll() 投影变换
┌─────────────────────────────────────────────────────────────┐
│  L5_RT (步级调度 · 框架上下文)                               │
│                                                              │
│  RT_Load_Base_Ctx                                           │
│    ├─ step_time = 5.0, total_time = 15.0                    │
│    ├─ kstep = 2, kinc = 10, iter = 3                        │
│    └─ analysis_type = STATIC, nlgeom = .TRUE.               │
│                                                              │
│  RT_Amplitude_Ctx                                           │
│    └─ current_scale = 0.5  ! 从幅值曲线插值得到             │
└─────────────────────────────────────────────────────────────┘
                            ↓ 进入增量步
┌─────────────────────────────────────────────────────────────┐
│  L4_PH (热路径 · 增量计算)                                    │
│                                                              │
│  PH_Load_Base_Ctx (增量驱动)                                │
│    ├─ prescribed_value = 0.5 * 100.0 = 50.0 MPa            │
│    └─ prescribed_delta = 50.0 - 45.0 = 5.0 MPa             │
│                                                              │
│  PH_Load_Base_State (动态演化)                              │
│    ├─ current_magnitude = 50.0 MPa                          │
│    ├─ delta_magnitude = 5.0 MPa                             │
│    ├─ follower_dir(:,1) = [0.98, 0.01, 0.19]  ! 随变形更新  │
│    └─ accumulated_work = 1250.0 J                           │
│                                                              │
│  ↓ 组装到全局残差                                            │
│  CALL AssembleLoadContribution(load_state, elem_ctx, rhs)   │
└─────────────────────────────────────────────────────────────┘
```

---

### 5. 最佳实践原则

#### ✅ DO（推荐做法）

**1. Desc 要尽可能精简**
```fortran
! ✅ 好：只含必要元信息
TYPE :: MD_BC_Base_Desc
  INTEGER(i4) :: bc_type
  INTEGER(i4) :: dof_set_id
  REAL(wp)    :: reference_value
END TYPE

! ❌ 坏：混入计算相关字段
TYPE :: MD_BC_Base_Desc_Bad
  ... 
  REAL(wp) :: current_value  ! 错！这是 State
  REAL(wp) :: tangent_stiff  ! 错！这是 Ctx/Algo
END TYPE
```

**2. State 要支持回溯**
```fortran
! ✅ 提供快照/恢复接口
TYPE :: PH_Contact_Base_State
  REAL(wp), ALLOCATABLE :: snapshot(:)
CONTAINS
  PROCEDURE :: SaveSnapshot => Contact_SaveSnapshot
  PROCEDURE :: RestoreFromSnapshot => Contact_Restore
END TYPE
```

**3. Ctx 要固定大小**
```fortran
! ✅ 编译期可知大小
TYPE :: PH_BC_Base_Ctx
  REAL(wp) :: value = 0.0_wp
  REAL(wp) :: delta = 0.0_wp
  REAL(wp) :: rot_matrix(3,3) = 0.0_wp
END TYPE

! ❌ 运行时分配
TYPE :: PH_BC_Base_Ctx_Bad
  REAL(wp), ALLOCATABLE :: values(:)  ! 禁止！
END TYPE
```

**4. Algo 要分层清晰**
```fortran
! L3_MD: 方案选择（分析前）
TYPE :: MD_Contact_Algo
  INTEGER(i4) :: formulation = PENALTY
END TYPE

! L4_PH: 迭代控制（增量内）
TYPE :: PH_Contact_Algo
  REAL(wp) :: tolerance = 1.0e-6_wp
  INTEGER(i4) :: max_iter = 20
END TYPE

! L5_RT: 步级调度（步间）
TYPE :: RT_Contact_Algo
  LOGICAL :: auto_adjust_gap = .TRUE.
END TYPE
```

#### ❌ DON'T（禁止做法）

1. **不要在 Desc 中包含 ALLOCATABLE**（除非是 Props 这种参数数组）
2. **不要在 Ctx 中包含 POINTER**（破坏连续性）
3. **不要在 State 中混入 Desc 字段**（混淆静态/动态）
4. **不要跨域 EXTENDS**（只在域内继承）

---

### 6. 下一步行动计划

| Phase | 任务 | 周期 | 产出 |
|-------|------|------|------|
| **P1** | 完成 Load/BC 域四大类设计 | 1 周 | `MD_Load_Types.f90`, `PH_Load_Types.f90`, `RT_Load_Types.f90`<br>`MD_BC_Types.f90`, `PH_BC_Types.f90`, `RT_BC_Types.f90` |
| **P2** | 完成 Contact/Constraint 域 | 1 周 | `MD_Contact_Types.f90`, `PH_Contact_Types.f90`, `RT_Contact_Types.f90`<br>`MD_Constraint_Types.f90`, `PH_Constraint_Types.f90` |
| **P3** | 完成 Step/Solver/Output域 | 1 周 | `MD_Step_Types.f90`, `RT_Step_Types.f90`<br>`PH_Solver_Types.f90`, `RT_Solver_Types.f90`<br>`MD_Output_Types.f90` |
| **P4** | 整合测试：单步非线性静力 | 2 周 | 端到端验证：Load+BC+Contact 协同 |

---

## Part XI：设计原则汇总（全架构版）

> 本节是在漏洞审查（Part VIII）完成后，针对材料域与单元域确定的 Types 文件清单与字段规划。  
> **状态**：分析确认阶段 → 确认后生成模板代码。

### 1. 文件清单与四大类分配矩阵

| 文件 | Desc | State | Algo | Ctx | 备注 |
|------|:----:|:-----:|:----:|:---:|------|
| `MD_Mat_Types.f90` | ✅ `MD_Mat_Base_Desc` | ✅ `MD_Mat_Base_State` | ✅ `MD_Mat_Base_Algo` | ❌ | 升级现有，Ctx 已迁出 |
| `MD_Elem_Types.f90` | ✅ `MD_Elem_Base_Desc` | ❌ | ❌ | ❌ | 新建，单元仅需 Desc |
| `MD_Sect_Types.f90` | ✅ `MD_Sect_Base_Desc` | ❌ | ❌ | ❌ | 修复 CLASS 漏洞 + 重命名 |
| `PH_Mat_Types.f90` | ❌ | ❌ | ✅ `PH_Mat_Base_Algo` | ✅ `PH_Mat_Base_Ctx` | 新建，材料增量驱动量 |
| `PH_Elem_Types.f90` | ❌ | ✅ `PH_Elem_Base_State` | ✅ `PH_Elem_Base_Algo` | ✅ `PH_Elem_Base_Ctx` | 新建，单元物理计算层 |
| `RT_Common_Types.f90` | ❌ | ❌ | ✅ `RT_Algo` | ✅ `RT_Common_Ctx` | 新建，RT层2类共18+1字段 |

### 2. 模块间编译依赖顺序

```
IF_Prec / IF_Err_API
    │
    ├─→ [1] MD_Mat_Types.f90          (独立，无上层依赖)
    │         └─→ [2] MD_Sect_Types.f90  (USE MD_Mat_Types: MD_Mat_Base_Desc)
    │
    ├─→ [3] MD_Elem_Types.f90         (独立)
    │
    ├─→ [4] PH_Mat_Types.f90          (独立)
    │
    ├─→ [5] RT_Common_Types.f90       (独立)
    │
    └─→ [6] PH_Elem_Types.f90         (USE PH_Mat_Types: PH_Mat_Base_Ctx)
                                       (USE MD_Sect_Types: MD_Sect_Base_Desc)
```

### 3. 各文件核心字段规划

#### [1] MD_Mat_Types.f90（升级现有）

**变更**：移除 `MD_Mat_Ctx_Base`（已迁出），移除 `MD_Mat_State_Base.pnewdt`，补入 `stran/dfgrd0`，类型名统一到 v3.1。

| 类型 | 关键字段 | 说明 |
|------|---------|------|
| `MD_Mat_Base_Desc`（ABSTRACT） | E/nu/G/K/lambda/rho/alpha/mat_id/mat_family/model_name + DEFERRED ValidateProps/InitFromProps | 具体材料模型 EXTENDS |
| `MD_Mat_Base_State`（ABSTRACT） | stress(6)/statev(:)/ddsdde(6,6) + **stran(6)/dfgrd0(3,3)** + sse/spd/scd/rpl/ddsddt/drpldt + converged/iterations | 14字段，补入L1漏洞修正 |
| `MD_Mat_Base_Algo`（具体） | integ_scheme/theta/compute_tangent/use_algorithmic + 仅方案配置字段 | **迭代控制字段移至 PH_Mat_Base_Algo** |

#### [2] MD_Sect_Types.f90（修复 + 重命名）

**变更**：`SectionType` → `MD_Sect_Base_Desc`，`TYPE(MD_Mat_Desc_Base)` → `CLASS(MD_Mat_Base_Desc)`，`SectionRegistryType` → `MD_Sect_Registry`。

| 类型 | 关键字段 | 说明 |
|------|---------|------|
| `MD_Sect_Base_Desc`（具体） | section_id/section_name/mat_id/`CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc`/thickness/orientation/nlayer/nintegration_pts/integ_rule/section_family | 修复 L2 CLASS 漏洞 |
| `MD_Sect_Registry`（具体） | sections(:)/nsections + AddSection/GetSection/FindByMaterial | 注册表管理器 |

#### [3] MD_Elem_Types.f90（新建）

| 类型 | 关键字段 | 说明 |
|------|---------|------|
| `MD_Elem_Base_Desc`（具体） | ndofel/nsvars/nnode/mcrd/jtype/nprops/props(:)/npredf/jdltyp(:,:)/mdload/jprops(:)/njprop | 来自 ABAQUS UEL 13个参数 |

#### [4] PH_Mat_Types.f90（新建）

| 类型 | 关键字段 | 说明 |
|------|---------|------|
| `PH_Mat_Base_Ctx`（具体） | dstran(6)/drot(3,3)/dfgrd1(3,3)/temp/dtemp/predef(:)/dpred(:)/coords(3)/celent | 9字段，纯增量内输入激励 |
| `PH_Mat_Base_Algo`（具体） | max_iter/tolerance/pnewdt_min/pnewdt_max/auto_cut/line_search | L5漏洞修正：迭代控制字段专属PH_层 |

#### [5] RT_Common_Types.f90（新建）

| 类型 | 关键字段 | 说明 |
|------|---------|------|
| `RT_Common_Ctx`（具体） | time_step/time_total/dtime/kstep/kinc/iter/analysis_type/large_def/first_increment/lflags(5)/elem_id/gauss_pt/layer_id/kspt **+ nrhs/mlvarx/ndload/period** | 18字段（原14 + L6漏洞修正4个UEL专有） |
| `RT_Algo`（具体） | pnewdt | 1字段，计算→框架时间步反馈 |

#### [6] PH_Elem_Types.f90（新建）

| 类型 | 关键字段 | 依赖 | 说明 |
|------|---------|------|------|
| `PH_Elem_Base_Ctx`（具体） | **mat_ctx (TYPE PH_Mat_Base_Ctx, CONTAINS组合)** + coords(:,:)/du(:,:)/predef(:,:,:)/adlmag(:,:)/ddlmag(:,:) | USE PH_Mat_Types | 5直接字段 + 1组合 |
| `PH_Elem_Base_State`（具体） | rhs(:,:)/amatrx(:,:)/svars(:)/energy(8)/u(:)/v(:)/a(:) | 独立 | 7字段 |
| `PH_Elem_Base_Algo`（具体） | params(3) [Newmark α/β/γ] | 独立 | 1字段 |

### 4. 目标模板文件路径（templates 阶段）

```
docs/templates/
    MD_Mat_Types.f90        ← 升级版本，对比后替换 L3_MD/Material/
    MD_Elem_Types.f90       ← 新建，验证后移入 L3_MD/Mesh/
    MD_Sect_Types.f90       ← 修复版本，替换 L3_MD/Section/MD_Section_Types.f90
    PH_Mat_Types.f90        ← 新建，验证后移入 L4_PH/Material/
    PH_Elem_Types.f90       ← 新建，验证后移入 L4_PH/Element/
    RT_Common_Types.f90     ← 新建，验证后移入 L5_RT/ 或新建 RT/ 目录
```

### 5. 确认项（代码生成前需要用户确认）

| 确认项 | 问题 | 默认决策 |
|--------|------|--------|
| C1 | `MD_Mat_Base_Algo` 是否保留 `max_iter/tolerance`？ | **否**，迭代控制字段仅在 `PH_Mat_Base_Algo` 中，MD_Algo 仅保留方案配置 |
| C2 | `RT_Common_Ctx` 纳入 4 个 UEL 专有字段？ | **是**，总计 18 字段，UMAT 端零填充，无副作用 |
| C3 | 模板文件是否直接覆盖现有同名文件？ | **否**，先在 `docs/templates/` 创建新文件，审查通过后再替换 |
| C4 | `PH_Mat_Base_State` 是否命名为 `PH_Mat_Base_State` 还是用 `MD_Mat_Base_State`？ | **沿用 `MD_Mat_Base_State`**（State Type定义归MD_，原则⑦），仅在计算层通过PH_层子程序更新其内容 |

---

| 编号 | 原则 | 说明 |
|------|------|------|
| ① | SEMANTIC PREFIX | MD_/PH_/RT_ 语义前缀，禁用 L3/L4/L5层级前缀 |
| ② | SUFFIX IS TYPE | 四大类（Desc/State/Algo/Ctx）作为**最终后缀**，读末尾知类型 |
| ③ | ASYMMETRIC MATRIX | 四大类不对称：MD_无 Ctx，PH_无 Desc，RT_无 Desc/State |
| ④ | EXTENDS WITHIN DOMAIN | 域内具体扩展用 Fortran EXTENDS（继承） |
| ⑤ | CONTAINS ACROSS DOMAIN | 跨域包含用 CONTAINS（组合） |
| ⑥ | POINTER for BRIDGE | 跨域非所有权引用用 POINTER |
| ⑦ | STATE DEFINITION IN MD | State 的 Type 定义归 MD_，计算更新归 PH_ |
| ⑧ | ONLY RT_Common_Ctx SHARED | 跨域公共基类只有 RT_Common_Ctx，其他域不设公共基类 |
| ⑨ | DOMAIN ISOLATION | 每个域保留自己的 XXX_Types.f90 |
| ⑩ | ZERO-COPY ACCESS | 指针关联避免数据拷贝 |
| ⑪ | NO BIG-BANG MODULE | 已拒绝——语义分歧 + 编译级联 |
| ⑫ | CLASS FOR ABSTRACT POINTER | 指向 ABSTRACT TYPE 的指针必须用 CLASS，不可用 TYPE |
| ⑬ | ALGO SPLIT MD vs PH | MD_Algo = 分析前配置；PH_Algo = 增量内迭代控制，二者不可混用 |
| ⑭ | RT_CTX UEL-ONLY FIELDS | nrhs/mlvarx/ndload/period 四个 UEL 专有字段纳入 RT_Common_Ctx，UMAT 端忽略 |
| ⑮ | **DESC COLD PATH** | Desc 专属冷路径，热路径期间冻结只读 |
| ⑯ | **STATE HOT PATH** | State 专属热路径，每增量步更新 |
| ⑰ | **CTX STACK ALLOCATION** | Ctx 禁止 HEAP 分配，全部栈上分配 |
| ⑱ | **ALGO LAYERED** | Algo 分三层：L3 方案/L4 迭代/L5 调度 |
| ⑲ | **CROSS_LAYER_DOMAIN** | Load/BC/Contact 等域跨三层存在，每层有不同切片 |
| ⑳ | **FLATTENALL PROJECTION** | FlattenAll 是唯一冷→热投影点，WriteBack 是唯一热→冷反投影点 |
