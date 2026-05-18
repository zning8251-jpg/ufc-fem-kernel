# Element 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: Element (单元调度与 UEL 适配)  
**Prefix**: `RT_Elem_*`  
**Version**: v2.2
**Created**: 2026-04-26
**Updated**: 2026-05-03
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 Element 域，运行时单元计算调度与路由
- **职责**:
  - 路由分发：按 family_id 路由单元计算到 L4_PH 内核 (RT_ElemDispatcher)
  - UEL 适配：**`MODULE RT_Elem_UEL`**（`RT_Elem_UEL.f90`）— 默认 **UEL-A**（薄适配材料核）；**UEL-B**（完整用户单元）目标下仍保持 **薄门面**（见 **§3.1**）
  - 截面服务：截面属性注册表查询 (RT_ElemSect)
  - WriteBack 钩子：元素结果 NaN 检测 + 能量聚合 (RT_ElemWB_Brg)
  - Mesh 运行时视图：运行时坐标/DOF 缓存 (Mesh/ 子域，非 SSOT)
  - 热-力耦合单元路由

### 非职责
- 不实现形函数/Jacobian/刚度矩阵 (L4_PH/Element)
- 不存储网格拓扑 SSOT (L3_MD/Element/Mesh)
- 不包含本构计算 (L4_PH/Material)

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Elem_Desc` | `RT_Elem_Def` | wraps PH_Elem_Base_Desc + 域级统计 | 路由描述（Populate 注入） |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Elem_State` | `RT_Elem_Def` | wraps PH_Elem_Base_State + kernel SDV | 运行时状态 |

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Elem_Algo` | `RT_Elem_Def` | wraps PH_Elem_Base_Algo + calc_type | 步级算法配置 |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Elem_Ctx` | `RT_Elem_Def` | wraps PH_Elem_Base_Ctx + DOF scratch | 每元素上下文 |

L5 Element 保留全四型（不同于 Material 域裁剪为纯路由 Ctx）——因为需要管理 DOF 映射、方程编号、单元循环上下文等 L5 固有数据。

**权威 TYPE 模块**: `RT_Elem_Def.f90` (ACTIVE, AUTHORITY)  
**LEGACY wrapper**: `RT_Element_Def.f90` (re-exports RT_Elem_Def)

### 单元类型 ID 两级体系

| 级别 | 权威 | 模块 | 示例 |
|------|------|------|------|
| 细粒度 elem_type_id | L3 SSOT | `MD_Elem` (L3) | PH_ELEM_C3D8, PH_ELEM_CPS4R |
| 族级 family_id | L4 AUTHORITY | `PH_ElemReg` (L4) | PH_ELEM_FAMILY_SOLID_3D=1 |
| L5 消费 | 通过 Bridge | `RT_Elem_Dispatch_Table` | 不透明整数，由 Bridge 填入 |

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_Elem_Def.f90` | `RT_Elem_Def` | `_Def` (TYPE) | 统一四型 + Dispatch Table 类型定义 | **ACTIVE** (AUTHORITY) |
| `RT_Elem_Dispatcher.f90` | `RT_ElemDispatcher` | 特化(Router) | 主路由 — family_id → L4 kernel dispatch | **ACTIVE** |
| `RT_ElemDispatch_Brg.f90` | `RT_ElemDispatch_Brg` | `_Brg` (桥接) | L5→L4 Bridge (Ke/Fe/Me/Ce 计算路由) | **ACTIVE** |
| `RT_ElemWB_Brg.f90` | `RT_ElemWB_Brg` | `_Brg` (桥接) | WriteBack 钩子 (NaN 检测 + 能量聚合) | **ACTIVE** |
| `RT_Elem_UEL.f90` | **`RT_Elem_UEL`** | 特化(Adapter) | **`RT_Elem_UEL_API`** / **`RT_Elem_UEL_Probe`**：UEL 用户单元 API 薄适配 | **ACTIVE** |
| `RT_Elem_Sect.f90` | `RT_ElemSect` | 特化(Registry) | 截面属性注册表服务 | **ACTIVE** |
| `RT_Elem_Proc.f90` | `RT_ElemProc` | `_Proc` (SIO) | SIO 抽象接口 + I/O 类型 | **SKELETON** |
| `RT_Elem_Core.f90` | `RT_Element_Core` | `_Core` | 回调式单元循环（仅测试用） | **LEGACY** |
| `RT_Elem_KernelProc.f90` | `RT_ElemKernelProc` | 特化 | UEL 内核包装 | **SKELETON** |
| `RT_Elem_ComputeProc.f90` | `RT_ElemComputeProc` | 特化 | 计算调度（有参数不匹配 bug） | **SKELETON** |
| `RT_Elem_AsmProc.f90` | `RT_ElemAsmProc` | 特化 | 装配入口（生产路径用 RT_AsmSolv） | **SKELETON** |
| `RT_Elem_ThermalMechCpl.f90` | `RT_ThermalMechanicalCpl` | 特化(Coupling) | 热-力耦合单元路由 | **ACTIVE** |
| `Mesh/RT_Mesh_Def.f90` | `RT_Mesh_Def` | `_Def` | Mesh 运行时视图四型定义 | **ACTIVE** |
| `Mesh/RT_MeshSys.f90` | `RT_MeshSys` | 特化 | Mesh 系统管理 | **ACTIVE** |
| `Mesh/RT_MeshProc.f90` | `RT_MeshProc` | `_Proc` | Mesh SIO 过程接口 | **ACTIVE** |
| `Mesh/RT_MeshImpl.f90` | `RT_MeshImpl` | `_Impl` | Mesh 内部实现 | **ACTIVE** |

### 3.1 `RT_Elem_UEL`（`RT_Elem_UEL.f90`）与 **UEL-A / UEL-B** 逐字交叉索引

**定义真源（与下列文档用词须逐字一致）**：**`L4_PH/Element/CONTRACT.md` v2.2** — **「UEL 子模式与分阶段清单（U0）」**；**`UFC/REPORTS/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` §14.4**；**`UFC/REPORTS/Element_L3L4L5_four_type_UEL_discussion_synthesis.md`**。

| 子模式 ID | 名称（与 L4 合同 **同一字串**） | 本层 **`RT_Elem_UEL.f90` / `RT_Elem_UEL_API` / `RT_Elem_UEL_Probe`** |
|-----------|----------------------------------|---------------------------------------------------------------------|
| **UEL-A** | **薄适配（材料核）** | **当前默认**：校验 **`elem_desc`**、**截面注册表** → **`mat_desc`** → **`PH_*_UMAT_API`**；**不**在 L5 展开 Abaqus UEL 扁参列表；与 **`RT_Elem_UEL` W2**（**禁止**在 RT 内发明与 **`MD_Elem_Base_Desc`** 同义并行 Desc）一致 |
| **UEL-B** | **完整用户单元（目标）** | **仍为薄门面**：校验 + 索引 + **调 L4**；完整 **K/RHS / `PH_UEL_Context`** 权威在 **L4**（**`PH_UEL_Def.f90`** 等，见 L4 合同 **UEL-B** 与 **U2**）；**U3** 交付：**`RT_Elem_UEL_API`** **仅材料** / **单元+材料** 两分支（材料 **§14.4**） |

**与 §6 R5**：**UEL-A** 下 **R5** 表述为 **UEL 门面 → L4 UMAT 材料核**；**UEL-B** 下 **R5** 扩展为 **经 `RT_Elem_UEL_API` 分支** 可调 **L4 单元 UEL 路径** 或 **材料槽**（以合同与实现头注释为准，**不得**在 L5 新建第二套单元 Desc）。

**维护**：**UEL-A/B** 默认、**`RT_Elem_UEL_*` 签名** 或 **W2** 变更时，须 **同批次** 更新：**本节**、**`L4_PH/Element/CONTRACT.md` U0 节**、**材料合订 §14.2–§14.5**、**Element 合订本**。

---

## 4. 对外接口（公开 API）

### 核心调度接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_ElemDispatcher.Run` | `RT_ElemDispatcher` | 按 family_id 路由到 L4 内核 |
| `RT_ElemDispatch_Brg.ComputeKe` | `RT_ElemDispatch_Brg` | L5→L4 Bridge: 单元刚度计算路由 |
| `RT_ElemDispatch_Brg.ComputeFe` | `RT_ElemDispatch_Brg` | L5→L4 Bridge: 单元载荷计算路由 |
| `RT_ElemWB_Brg.Filter` | `RT_ElemWB_Brg` | WriteBack NaN 检测 + 能量聚合 |

### 金线调用链
```
RT_StepExec (步执行)
  └─ RT_AsmSolv (装配编排)
       ├─ Element loop (per element):
       │    ├─ RT_ElemDispatcher.Run(family_id)     ← L5 路由
       │    │    └─ registered_kernel(state, ctx)    ← L4 内核回调
       │    ├─ RT_ElemDispatch_Brg.ComputeKe(...)   ← L5→L4 Bridge
       │    │    └─ PH_ElemKeDispatch.Compute_Ke()  ← L4 刚度计算
       │    └─ RT_ElemDispatch_Brg.ComputeFe(...)   ← L5→L4 Bridge
       │         └─ PH_ElemFeDispatch.Compute_Fe()  ← L4 载荷计算
       ├─ Assembly: global_K += Ke, global_F += Fe
       └─ Post-convergence:
            └─ RT_ElemWB_Brg.Filter(stress, sdv)    ← WriteBack 钩子
```

---

## 5. 跨层数据流

### Populate 数据流（冷路径）
```
L3_MD/Element/Elem (elem_type, topology)
  → Populate                            ← 获取单元类型/拓扑
    → RT_Elem_Desc (路由描述)           ← L5 Populate 后只读
```

### 计算数据流（热路径）
```
RT_Elem_Ctx (DOF scratch)
  → RT_ElemDispatcher (family_id 路由)
    → L4 PH_ElemKeDispatch / PH_ElemFeDispatch  ← L4 内核计算
      → Ke, Fe                                  ← 返回刚度/载荷
        → Assembly: global_K += Ke, global_F += Fe
```

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Element/Elem | S (Populate) | Populate 获取单元类型/拓扑 |
| R2 | L4_PH/Element | B (Bridge) | Dispatcher 路由到 L4 形函数/Ke/Fe 内核 |
| R3 | L5_RT/Assembly | T (提供) | 向 Assembly 提供单元 Ke/Fe 贡献 |
| R4 | L5_RT/StepDriver | S (被调度) | StepDriver 在 NR 迭代内调度单元循环 |
| R5 | L4_PH/Material；L4_PH/Element（**UEL-B**） | B (Bridge) | **UEL-A**：`RT_Elem_UEL` → L4 **UMAT** 材料核；**UEL-B**（目标）：`RT_Elem_UEL_API` 分支 → L4 **单元 UEL 主链** 或材料核（**§3.1**） |
| R6 | L3_MD/Section | S (消费) | 截面属性查询 (via RT_ElemSect) |
| R7 | L5_RT/WriteBack | B (Bridge) | RT_ElemWB_Brg 提供元素级 WriteBack 钩子 |

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| 热路径零 L3 | **硬** | 高斯点循环仅消费 Populate 后的 slot |
| 不使用 STOP | **硬** | 错误通过 ErrorStatusType 传播 |
| Dispatcher 纯调度 | **硬** | 不含物理计算，委托 L4 |
| 统一四型定义 | **硬** | 所有消费方 USE RT_Elem_Def |
| Mesh 子域非 SSOT | **硬** | 运行时视图，不修改 L3 网格定义 |

### 错误处理

| 错误码范围 | 错误场景 | 严重级 |
|------------|----------|--------|
| 50300 | 未知单元族 ID（路由失败） | ERROR |
| 50301 | UEL API 参数校验失败 | ERROR |
| 50302 | L4 PH 内核返回错误 | ERROR |
| 50303 | 截面属性 ID 未注册 | ERROR |
| 50304 | WriteBack NaN 检测 | ERROR |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 四型定义完整 | RT_Elem_Def 包含 Desc/State/Algo/Ctx | ✅ 已实现 |
| A2 | Dispatcher 路由可用 | family_id → L4 kernel 正确分发 | ✅ 已实现 |
| A3 | Bridge 链完整 | ComputeKe/Fe → L4 PH 内核 | ✅ 已实现 |
| A4 | UEL 适配器（**UEL-A** 默认） | **`RT_Elem_UEL`**：**UEL-A** 薄适配可调；**UEL-B** 目标路径见 **§3.1** 与 L4 **U3** | ✅ 已实现（UEL-A）；UEL-B 分期 |
| A5 | WriteBack 钩子 | NaN 检测 + 能量聚合 | ✅ 已实现 |
| A6 | Mesh 运行时视图 | 坐标/DOF 缓存可用 | ✅ 已实现 |
| A7 | 截面注册表 | RT_ElemSect 查询可用 | ✅ 已实现 |
| A8 | 热-力耦合 | 热-力耦合单元路由可用 | ✅ 已实现 |
| A9 | 错误传播 | ErrorStatusType，不使用 STOP | ✅ 已实现 |
| A10 | 单元测试 | RT_Element_test.f90 覆盖核心路径 | ✅ 已实现 |

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.1 | 2026-04-30 | 初版：四型、模块表、金线、R1–R7、验收 A1–A10 |
| v2.2 | 2026-05-03 | 新增 **§3.1**：**`RT_Elem_UEL` 与 UEL-A / UEL-B 逐字交叉索引**；修订 **R5**、**A4**；与 **`L4_PH/Element/CONTRACT.md` v2.2 U0**、材料 **§14.4** 对齐 |
