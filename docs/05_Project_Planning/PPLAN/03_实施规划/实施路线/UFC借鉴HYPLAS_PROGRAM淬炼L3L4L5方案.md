# UFC 借鉴 HYPLAS PROGRAM 淬炼 L3/L4/L5 完善方案

> **版本**: v1.9  
> **日期**: 2026-03-22  
> **目标**: 保留 UFC 架构优势，借鉴 HYPLAS PROGRAM 组织范式与优点，淬炼/打通 L3_MD、L4_PH、L5_RT 各域各模块；**着重解决域级接口与功能集条理不清、不统一、显杂乱的问题**；**明确 L3/L4/L5 底层算法实现与打通的最优路径（见三附）**  
> **依据**: UFC 六层架构总纲、00-域级划分规范、99-域级深度建模Skill、00-L3L4L5L6 域级统一命名规范、UFC战略架构与领先一代设计、fem-kernel-architecture 技能、HYPLAS PROGRAM 源码分析

---

## 一、方案总览

### 1.1 核心原则

| 原则 | 说明 |
|------|------|
| **保留 UFC 优势** | 六层架构、四型（Desc/State/Ctx/Algo）、四链、Bridge、单向依赖、TYPE 接口 |
| **融合 ABAQUS 风格** | 模型树、KW→Desc 单一映射、数据驱动、UMAT/UEL 契约、验证对照（见 2附） |
| **提炼 HYPLAS 最小核心** | 单入口编排、ALGOR 集中选择、GENERAL 胶水、ELEMLIB/MATLIB 分离（见 2附） |
| **统一域级范式** | 各域遵循 1附 接口分层、功能集划分、命名规范，消除杂乱无章 |
| **不引入反面模式** | 禁止 COMMON、全局变量、单 PROGRAM monolithic、IMPLICIT |
| **增量演进** | 按域级逐步淬炼，不推倒重来 |

### 1.2 目标层级聚焦与三源定位

```
L3_MD ── 模型数据层（纯 Desc 真相源）  ← ABAQUS 模型树 + HYPLAS INOUT
L4_PH ── 物理层（单元/材料/接触）      ← ABAQUS 单元族/本构 + HYPLAS ELEMLIB/MATLIB
L5_RT ── 运行时层（装配/求解/步骤驱动）← ABAQUS 求解器组合 + HYPLAS MAIN/ALGOR/GENERAL
```

---

## 一附、UFC 域级接口与功能集统一规范（新增）

> **动机**：当前 UFC 各域级接口与功能集条理不清晰、不统一，显得杂乱无章。本节基于 UFC 架构设计思路，给出统一的域级范式，作为淬炼与打通的前提。

### 1附.1 现状诊断：域级杂乱表现

| 问题类别 | 表现 | 示例 |
|----------|------|------|
| **结构体封装不一致** | 有的域用 `*_Domain_Core`，有的用 `*_Core`，有的用 `*_Domain`（无 Core） | `PH_Element_Domain_Core` vs `MD_Mesh_Core` vs `PH_Cont_Domain` |
| **接口分层不统一** | 有的域有 Core/Mgr/API/Brg 四层，有的只有 Core，有的混用 | L3_MD Material 有 Core/API/Reg/Lib，L4_PH Element 以 Domain_Core 为主 |
| **命名双轨** | 同一概念在不同文档/代码中命名不同 | LoadBC vs LoadBC，Constraint vs Const，Section vs Sect，KeyWord vs KW |
| **功能集边界模糊** | 层级-域级-功能集三级中，「功能集」无统一定义，与模块/子程序映射不清 | 域内子程序分散在多个文件，无「功能集」索引 |
| **TYPE 绑定 vs 独立子程序** | 有的域用 TYPE 绑定过程，有的用独立 SUBROUTINE | `PH_Constraint_Domain%Init` vs `MD_Geom_Node_Init` |
| **四型使用不一致** | 有的域用 Params，有的用 Algo；Ctx/State 字段命名不统一 | PH_Brg 用 Params，架构总纲定义 Algo |
| **域列表不一致** | 00-域级划分规范与 UFC_完整层级清单的域级列表、缩写不完全对齐 | L3: Geom/Assem vs Model/Mesh/Assembly；L5: Conv/Incr/Iter vs Step/Solver |

### 1附.2 统一域级范式：三级结构

**层级 → 域级 → 功能集** 三级结构，每级有明确职责与命名约束：

```
层级（Layer）     L3_MD / L4_PH / L5_RT
    └── 域级（Domain）  Material / Element / Step / ...
            └── 功能集（Feature Set）  Init / Query / Compute / Bridge / ...
                    └── 模块/子程序    *_Core.f90, *_Mgr.f90, *_API.f90, *_Brg.f90
```

| 级别 | 职责 | 命名约束 |
|------|------|----------|
| **层级** | 依赖方向、生命周期、数据温度 | `L{n}_{IF|NM|MD|PH|RT|AP}` |
| **域级** | 单一功能域，职责边界清晰 | 见「域级统一缩写表」 |
| **功能集** | 域内按职责划分的功能子集 | Init/Query/Compute/Valid/Brg 等 |

### 1附.3 域级接口分层标准（四角色）

每个域级**至少**包含以下角色之一，多则四者齐全；角色与文件后缀一一对应：

| 角色 | 后缀 | 职责 | 典型接口模式 |
|------|------|------|--------------|
| **Core** | `_Core` 或 `_Domain_Core` | 核心数据结构、初始化、校验、主要计算 | TYPE 绑定：`Init`, `Finalize`, `Compute_*` |
| **Mgr** | `_Mgr` | 集合管理、按 ID/名称查询、遍历 | `Add`, `Get`, `GetByIndex`, `Count` |
| **API** | `_API` | 对外业务接口、复杂流程编排 | 独立 SUBROUTINE 或 TYPE 绑定 |
| **Brg** | `_Brg` | 跨层桥接，仅此角色可 USE 其他层 | `*_PH_Brg`, `*_RT_Brg`, `*_L3_Brg` |

**统一约定**：
- 域的主入口统一为 `{Layer}_{Domain}_Domain` 或 `{Layer}_{Domain}_Domain_Core`
- 若域内仅一个核心模块，可用 `{Layer}_{Domain}_Core`，不强制 `Domain`
- Bridge 域：仅含 Brg 角色，不混合 Core

### 1附.4 功能集白名单与职责

功能集是域内的逻辑分组，用于文档索引与实现归类；**不强制对应独立文件**，可多个功能集共处一文件。

| 功能集 | 职责 | 典型子程序/过程 |
|--------|------|----------------|
| **Init** | 初始化、分配、默认值 | `Init`, `Allocate`, `Reset` |
| **Finalize** | 释放、清理 | `Finalize`, `Cleanup`, `Deallocate` |
| **Query** | 只读查询 | `Get`, `GetByIndex`, `Count`, `Has` |
| **Mutate** | 可变写操作（非热路径） | `Add`, `Set`, `Update`, `Remove` |
| **Compute** | 数值计算、热路径 | `Compute_Ke`, `Compute_Fe`, `Eval`, `Integrate` |
| **Valid** | 校验、合法性检查 | `Valid`, `Validate`, `Check` |
| **Brg** | 跨层桥接 | `*_RouteTo*`, `*_GetFrom*`, `*_WriteBack` |
| **Parse** | 输入解析（仅 L3/L6） | `Parse`, `Read`, `Register` |
| **Algo** | 算法选择、参数（对应 Algo 型） | `Select`, `Configure` |

### 1附.5 域级统一缩写表（L3/L4/L5）

**与 00-L3L4L5L6 域级统一命名规范 对齐**：

| 层 | 域全称 | 统一缩写 | 主模块命名模式 |
|----|--------|----------|----------------|
| **L3** | Model | Model | `MD_Model_*` |
| | Part | Part | `MD_Part_*` |
| | Mesh | Mesh | `MD_Mesh_*` |
| | Section | Sect | `MD_Sect_*` |
| | Material | Mat | `MD_Mat_*` |
| | Assembly | Assem | `MD_Assem_*` |
| | Constraint | Const | `MD_Const_*` |
| | Contact/Interaction | Cont | `MD_Cont_*` |
| | LoadBC | LoadBC | `MD_Ldbc_*` |
| | Step | Step | `MD_Step_*` |
| | Output | Out | `MD_Out_*` |
| | KeyWord | KW | `MD_KW_*` |
| | Bridge | Brg | `MD_*_Brg` |
| **L4** | Element | Elem | `PH_Elem_*` |
| | Material | Mat | `PH_Mat_*` |
| | Contact | Cont | `PH_Cont_*` |
| | Constraint | Constr | `PH_Constr_*` |
| | LoadBC | LoadBC | `PH_Ldbc_*` |
| | Coupling | Cpl | `PH_Cpl_*` |
| | Bridge | Brg | `PH_*_Brg` |
| **L5** | Assembly | Asm | `RT_Asm_*` |
| | Solver | Solv | `RT_Solv_*` |
| | Step | Step | `RT_Step_*` |
| | Element | Elem | `RT_Elem_*` |
| | Contact | Cont | `RT_Cont_*` |
| | Output | Out | `RT_Out_*` |
| | Bridge | Brg | `RT_*_Brg` |
| | Logging | Log | `RT_Log_*` |
| | General（新增） | Gen | `RT_Gen_*` |

### 1附.5.1 三大基础域补全：Mesh · Element · Material

> **目的**：将 **网格（拓扑真相源）**、**单元（数值离散）**、**材料（本构参数 + 步内求值）** 的职责、分层与仓库路径一次性写清，避免 L3/L4 混写形函数或本构、或热路径穿透读 Mesh。

#### （1）总览对照

| 概念 | 主层级 | 前缀 | **真相源 / 运行时** | **禁止** |
|------|--------|------|----------------------|----------|
| **Mesh** | **L3** | `MD_Mesh_*` / `MD_Elem_*`(拓扑) / `MD_DOF_*` | 节点坐标、单元连通、集合、UEL 映射等 **Desc**；Populate 前可 Mutate，步内对金线 **只读** | L3 不写 Gauss 点应力、不组装 Ke |
| **Element** | **L4** | `PH_Elem_*`、`PH_Element_Domain_Core` | 形函数/B 阵/Jacobi/积分、`Compute_Ke`/`Compute_Fe`；读 **L4 slot** 或经 Brg 注入的拓扑摘要 | 热路径内不直接扫 L3 网格库 |
| **Material** | **L3 + L4** | `MD_Mat_*`（Desc）+ `PH_Mat_*`（Eval） | L3：**材料卡、本构类型、参数表**；L4：**Eval/Ctan、状态量、UMAT 桥**；经 Populate 进 slot | L3 不做 IP 上本构积分；L4 不持久化模型树 |

**HYPLAS 映射**：Mesh ≈ INOUT/INDATA 中网格与编号；Element ≈ **ELEMLIB**（ELETYP+ELTOOL）；Material ≈ **MATLIB**（L3 侧材料定义 + L4 侧本构例程，与 HYPLAS 分目录思想一致）。

#### （2）Mesh（L3_MD · `MD_Mesh`）

- **职责**：节点/单元拓扑、全局编号、部件与集合、与 INP/关键字解析的衔接；`MD_DOF_*` 管理自由度与方程映射（**定义层**）。
- **功能集（1附.4）**：Init / Query 为主；Mutate / Valid / Parse（非热路径）；Finalize。
- **接口分层（1附.3）**：`MD_Mesh_Domain_Core`、`MD_Mesh_Core`、`MD_Mesh_Mgr`、`MD_Mesh_API`；拓扑子模块 `MD_Mesh_Node`、`MD_Mesh_Elem`、`MD_Mesh_Data`、`MD_Elem_Core`、`MD_Elem_Family`、`MD_Elem_Inp_Map`；同步/工具 `MD_Mesh_Sync`、`MD_Mesh_Util`、`MD_Mesh_GlobalNum`；场 API `MD_FieldState_API`；用户单元定义 `MD_Elem_UEL`。
- **仓库根路径**：`UFC/ufc_core/L3_MD/Mesh/`。
- **合同卡（代码落点）**：`ufc_core/L3_MD/Element/Mesh/CONTRACT.md`；各模块 `MODULE` 前 `!>>> UFC_L3_CONTRACT | …/Mesh/CONTRACT.md` 或 `Element/Mesh/CONTRACT.md`（与 `MD_Mesh_Domain_Core.f90` 等一致）。
- **下游**：L4 Populate / `MD_Mesh_GetElemConnect_*` 等 **只读** 供组装与单元例程；L5 `RT_Asm_*` 经 dofMap 消费，不反向写 Mesh Desc。

#### （3）Element（L4_PH · `PH_Elem`）

- **职责**：单元族数值核：形函数、Jacobian、B、积分点循环；对外金线 **`Compute_Ke` / `Compute_Fe`**（及注册表 `PH_Elem_Reg_*`）。
- **功能集**：Compute（热路径）、Init/Finalize（域生命周期）、Query（注册查询）；Shared 子目录承载 ELETYP 类共用库（形函数、积分点、派生工具）。
- **子域（族）**：`SLD3D`、`SLD2D`、`SHELL`、`BEAM`、`TRUSS`、`SLD3DT`、`SLD2DT`、`SPRING`、`Thermal`、`User`(UEL)、`SPECIAL` 等；与 1附「Core/Tool」淬炼目标：**Shared + 族内 Core** 偏 ELETYP，**高阶组装胶水** 可逐步归 Tool。
- **主入口**：`PH_Element_Domain_Core.f90`、`PH_Element_Structural_Facade.f90`、`PH_Elem_Reg_Core.f90`。
- **仓库根路径**：`UFC/ufc_core/L4_PH/Element/`。
- **合同卡（代码落点）**：`ufc_core/L4_PH/Element/CONTRACT.md`；主模块 `PH_Element_Domain_Core.f90` 已挂 `!>>> UFC_PH_QUENCH` / `!>>> UFC_PH_CONTRACT`。
- **上游**：L3 Mesh/Material/Section（经 Populate→slot）；**不**在步内持有 Mesh 写权限。

#### （4）Material（L3_MD `MD_Mat` + L4_PH `PH_Mat`）

**L3_MD Material（Desc）**

- **职责**：材料实例、本构关键字参数、类型注册（`MD_Mat_Reg`）、多物理分支（弹性/塑性/粘性/损伤/热等）的 **Desc 类型**（`MD_Mat_Types*`、`MD_Mat_Domain_Types*`）。
- **功能集**：Query、Valid、Parse（L6/L3 KW）；Mutate（建模阶段）；**Brg**：`MD_Mat_Bridge` → L4 Populate。
- **核心文件**：`MD_Mat_Core`、`MD_Mat_API`、`MD_Mat_Lib`；按本构族 `MD_Mat_Elastic_Core`、`MD_Mat_Plastic_Reg`（及分模型塑性模块）、`MD_Mat_HyperElastic_Core`、`MD_Mat_Creep_Core`、`MD_Mat_Damage_Core` 等与 HYPLAS MATLIB 子目录概念对齐。
- **仓库根路径**：`UFC/ufc_core/L3_MD/Material/`。
- **合同卡（代码落点）**：`ufc_core/L3_MD/Material/CONTRACT.md`；`MD_Mat_Core.f90` 等 `!>>> UFC_L3_CONTRACT`。

**L4_PH Material（Eval / State）**

- **职责**：积分点上的应力更新与切线、`PH_Mat_Eval`、`PH_Mat_Integ_Core`、状态管理（`PH_Mat_StateManagement`）、算法参数（`PH_Mat_Ctx` / Algo）；UMAT 等用户本构走 `UMAT/`、`PH_UserSub_UMAT`。
- **子目录**：`Elastic/`、`Plastic/`、`HyperElas/`、`Visc/`、`Damage/`、`Coupling/`、`Geotech/`、`Special/`、`Shared/`，与 4.2 节 MATLIB 映射一致。
- **主入口**：`PH_Mat_Domain_Core.f90`、`PH_Mat_Reg_Core.f90`。
- **仓库根路径**：`UFC/ufc_core/L4_PH/Material/`。
- **合同卡（代码落点）**：`ufc_core/L4_PH/Material/CONTRACT.md`；主模块 `PH_Mat_Domain_Core.f90` 已挂 `!>>> UFC_PH_QUENCH` / `!>>> UFC_PH_CONTRACT`。

**数据流（淬炼约束）**：分析步内 **Compute_Ke/Fe** 只触 L4 Material + L4 Element；**禁止**在单元 IP 循环内直接 `USE` L3 `MD_Mat_Get*`（须先 Populate 到 slot / 缓存）。

### 1附.6 四型与域级接口的对应

| 四型 | 域内典型用途 | 接口传参约定 |
|------|--------------|--------------|
| **Desc** | L3 各域；只读模型定义 | 形参 `TYPE(xxx_Desc)` 或 `TYPE(xxx_Desc), POINTER` |
| **State** | L4/L5 各域；运行时状态 | 形参 `state_in`, `state_out` 或 `TYPE(xxx_State)` |
| **Ctx** | 跨调用临时上下文 | 形参 `TYPE(xxx_Ctx)` 或栈上聚合 |
| **Algo** | 算法参数、控制开关 | 形参 `TYPE(xxx_Algo)`；**禁止用 Params 替代 Algo**（与总纲统一） |

### 1附.7 域级合同卡模板（每域必备）

每个域级应有一份**域级合同卡**，明确：

1. **域名**、**层级**、**缩写**
2. **职责**（一句话 + 职责边界）
3. **四型配置**：本域产出/消费的 Desc/State/Ctx/Algo
4. **核心接口清单**：按功能集分组的子程序/TYPE 绑定
5. **依赖**：上游域（本域依赖谁）、下游域（谁依赖本域）
6. **Bridge**：若有 Brg，注明方向与目标层
7. **热路径**：是否涉及热路径，若有则标注 Compute 类接口

### 1附.8 淬炼期执行顺序（针对杂乱治理）

1. **P0**：统一命名——按 1附.5 缩写表，逐步替换不一致的域级名（柱级文档域缩统一为 **LoadBC**，禁止再用旧 **`Ldbc`** 作为文档缩写与新概念混用）
2. **P1**：补齐域级合同卡——每个域至少一份合同卡，缺则补、有则更新
3. **P2**：接口分层归一——每个域明确 Core/Mgr/API/Brg 角色划分，冗余角色合并、缺失角色补齐
4. **P3**：功能集标注——在合同卡和代码注释中标出各子程序所属功能集
5. **P4**：四型统一——Params 统一为 Algo，Ctx/State 字段命名与总纲对齐

---

## 二、HYPLAS PROGRAM 架构精华提取

### 2.1 HYPLAS 目录与职责

```
PROGRAM/
├── MAIN/MAIN.f90              ← 唯一入口，完整控制流
├── GENERAL/                   ← 通用算法与胶水
│   ├── ALGOR.f90              ← 集中算法选择（KRESL/NALGO）
│   ├── INCREM.f90             ← 增量控制
│   ├── CONVER.f90             ← 收敛判断
│   ├── INTFOR.f90             ← 内力组装
│   ├── TANGEN.f90             ← 弧长切向解
│   ├── UPCONF.f90             ← 位移更新
│   ├── UPDATE.f90             ← 状态更新
│   └── SWITCH.f90             ← 状态切换/回滚
├── INOUT/                     ← 输入输出聚合
│   ├── INDATA.f90
│   ├── OUTPUT.f90
│   └── RPIVOT.f90
├── LOAD/INLOAD.f90            ← 载荷施加
├── ELEMLIB/
│   ├── ELETYP/                ← 单元类型（形函数、积分点）
│   └── ELTOOL/                ← 单元工具（Jacobi、内力等）
├── MATLIB/                    ← 材料库按本构分目录
│   ├── ELASTC/, MOHCOU/, DRUPRA/, ...
├── SOLVER/
│   ├── FRONT/                 ← 波前法
│   ├── SOLV/                  ← 迭代求解 ITERM/SOLVE
│   └── LAPACK/                ← 密集线性代数
└── MODULE/                    ← 全局参数与类型
    ├── MAXDIM.f90
    └── MATERIAL.f90
```

### 2.2 HYPLAS 控制流（MAIN.f90）

```
1. GREET, FOPEN
2. RSTCHK → RSTART(重启) 或 INDATA + RPIVOT + INLOAD
3. ININCR（载荷增量参数）
4. INITIA（非重启）
5. DO ICOUNT=1,NINCS (载荷增量循环)
   a. SWITCH(1) 重置
   b. INCREM 更新载荷因子
   c. DO IITER=1,MITER (平衡迭代)
      - ALGOR(IINCS,IITER,KRESL,KUNLD)  ← 集中算法选择
      - TANGEN（弧长时）
      - FRONT / ITERM  ← 求解 K·Δu = R
      - ARCLEN（弧长时）
      - UPCONF / UPDATE
      - INTFOR  ← 内力
      - CONVER(CONVRG,DIVERG)
   d. 输出 / 切步
6. OUTPUT, RSTART(写), FCLOSE
```

### 2.3 可借鉴优点

| 优点 | 说明 | UFC 对应/借鉴方式 |
|------|------|-------------------|
| **单入口控制流** | MAIN 作为唯一编排中心，逻辑一目了然 | 强化 RT_Driver_Core 为「L5 版 MAIN」 |
| **ALGOR 集中算法选择** | NALGO/KRESL 在一个子程序内完成 Newton/Modified Newton/Secant 分支 | 新建 RT_Gen_Algo_Core，集中 NALGO 映射 |
| **GENERAL 胶水层** | 收敛、更新、切步、回滚集中管理 | 在 L5_RT 内建立 General 子域 |
| **ELEMLIB / MATLIB 分离** | 单元库与材料库按功能目录分离 | 与 L4 Element/Material 域对齐，强化子域 |
| **INOUT 聚合** | 输入/输出放在同一逻辑域 | L3 Output、L6 Input 已有，L5 Output 可加强 |
| **LOAD 独立** | 载荷施加独立于通用算法 | L3 LoadBC、L4 LoadBC、L5 Load 职责可更清晰 |

---

## 二附、ABAQUS 设计风格 + HYPLAS 最小核心：双源提炼与 UFC 融合

> **目标**：提炼 ABAQUS 设计风格与 HYPLAS 最小核心优势，补充完善 UFC 架构，形成「UFC 自有六层 + ABAQUS 工程范式 + HYPLAS 计算内核组织」的三源融合。

### 2附.1 ABAQUS 设计风格提炼

**来源**：UFC战略架构与领先一代设计、六层架构根本性完善计划、UFC_架构介绍文档

| 维度 | ABAQUS 设计特征 | UFC 融合方式 |
|------|-----------------|--------------|
| **模型树** | 树形嵌套、One root 结构，Step/Load/BC/Material 分层清晰 | L3_MD 已实现树形；强化 **KW→Desc 单一映射**，每关键字对应唯一 Desc 类型 |
| **数据驱动** | INP 文件驱动，CAE 模型树与输入一致 | L6 Input + L3 KeyWord 解析 → L3 Desc；确保 **输入即模型**，无隐式全局状态 |
| **模块化** | 功能模块独立，通过统一接口连接 | 与 1附.3 四角色（Core/Mgr/API/Brg）对齐；每域**单一职责**，接口仅传 TYPE |
| **求解器组合** | Standard（隐式）/Explicit（显式）分离，线性/非线性/特征值 | L5 StepDriver 按 PROC_* 分发；**统一场论**（C·φ̇+K·φ=f）下用不同时间积分策略，非两套路径 |
| **单元与本构** | 单元族 + 本构库 + 截面 + 材料 组合完整 | L4 Element/Material 与 L3 Section/Material 对齐；**TL/UL 与单元族范式**（99 文档） |
| **用户子程序** | UMAT/UEL/UVARM 标准接口 | fem-kernel-extensibility；Bridge 封装，**不泄漏内核类型** |
| **验证与基准** | 验证手册、NAFEMS、ABAQUS Benchmark | 02-07 验证体系 + fem-kernel-verification；标准题与 ABAQUS 结果对照 |
| **Theory 可追溯** | Theory Manual 与实现对应 | 四链之**理论链**：公式、本构、单元理论在文档与类型定义中可追溯 |

**UFC 需补强（对齐 ABAQUS）**：
- INP 解析完整性：关键字覆盖度与 ABAQUS 2020 对标
- 求解器选择器：类似 ABAQUS 的 Solver 自动推荐（刚度主导/质量主导/接触主导）

### 2附.2 HYPLAS 最小核心优势提炼

> **原则**：只取 HYPLAS 的**最小必要**优势，避免引入 COMMON、全局变量、单 PROGRAM 等与 UFC 冲突的设计。

| 最小核心 | 本质 | UFC 落地 |
|----------|------|----------|
| **单入口编排** | MAIN.f90 是唯一控制流入口，逻辑线性可读 | RT_Driver_Core / RT_StepDriver_Core 作为「L5 版 MAIN」；顶部注释绘制完整流程图 |
| **ALGOR 集中选择** | 算法分支（KRESL/NALGO）在一处完成 | RT_Gen_Algo_Core 集中 NALGO→切线/初刚度/修正 Newton 映射 |
| **GENERAL 胶水** | 收敛、更新、切步、回滚集中 | RT_Gen 域：Conv、IncrCut、Algo |
| **ELEMLIB/MATLIB 分离** | 单元类型(ELETYP)与单元工具(ELTOOL)分目录；材料按本构分子目录 | L4 Element：Core(形函数/Jacobi/积分) + Tool(内力/刚度)；Material 按 Elastic/Plastic/Visc 分 |
| **INOUT/LOAD 聚合** | 输入输出、载荷施加逻辑集中 | L3 Out/LoadBC 定义集中；L5 Output 执行集中 |
| **扁平淡化调用链** | 无过度抽象，子程序直接调用 | 热路径避免多余间接层；Bridge 仅用于跨层，层内直接调用 |

**明确不采用**：
- ❌ COMMON 块 / 全局数组
- ❌ 单 PROGRAM  monolithic
- ❌ IMPLICIT 类型
- ❌ 固定维数参数（MAXDIM 等）硬编码

### 2附.3 三源融合：UFC + ABAQUS + HYPLAS 最小核心

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    UFC 三源融合架构                                      │
├─────────────────────────────────────────────────────────────────────────┤
│  UFC 底座（不变）                                                        │
│    六层 + 四型 + 四链 + Bridge + 单向依赖 + TYPE 接口                     │
├─────────────────────────────────────────────────────────────────────────┤
│  + ABAQUS 风格（工程范式）                                                │
│    模型树、KW→Desc 单一映射、数据驱动、UMAT/UEL 契约、验证对照             │
├─────────────────────────────────────────────────────────────────────────┤
│  + HYPLAS 最小核心（计算内核组织）                                        │
│    单入口编排、ALGOR 集中选择、GENERAL 胶水、ELEMLIB/MATLIB 分离、扁平淡化│
└─────────────────────────────────────────────────────────────────────────┘
```

| 层级 | ABAQUS 对应 | HYPLAS 最小核心对应 |
|------|-------------|---------------------|
| **L3_MD** | 模型树、KW 解析、Desc 定义 | INOUT 聚合（Out/LoadBC 职责清晰） |
| **L4_PH** | 单元族、本构、截面组合 | ELEMLIB（Core+Tool）、MATLIB（按本构分） |
| **L5_RT** | 求解器分发、Step 驱动 | MAIN 式单入口、ALGOR、GENERAL 胶水 |
| **L6_AP** | INP 解析、Job 生命周期 | 数据驱动入口 |

### 2附.4 补充完善 UFC 架构的检查清单

淬炼与打通时，逐项自检：

- [ ] **ABAQUS**：KW→Desc 是否单一映射？模型树是否与 INP 一致？UMAT/UEL 接口是否契约化？
- [ ] **ABAQUS**：是否建立了与 ABAQUS 验证手册/NAFEMS 的对照表？
- [ ] **HYPLAS**：L5 是否有清晰的「MAIN 式」控制流注释？算法选择是否集中在 RT_Gen？
- [ ] **HYPLAS**：L4 Element 是否明确 Core(ELETYP)/Tool(ELTOOL)？Material 是否按本构分目录？
- [ ] **UFC**：是否满足 1附 域级统一规范？域级合同卡是否齐全？

---

## 三、UFC 保留优势（不削弱）

| 优势 | 保留方式 |
|------|----------|
| 六层单向依赖 | 严格 L6→L5→L4→L3→L2→L1，不反向 |
| 四型（Desc/State/Ctx/Algo） | 继续作为层间/域间传递的契约 |
| 四链（理论/逻辑/计算/数据） | 作为设计评审与一致性检查视角 |
| Bridge 显式跨层 | 所有跨层访问仅通过 Bridge，不引入 COMMON |
| TYPE 接口 | 形参以 TYPE 为主，不暴露散列成员 |
| WriteBack 白名单 | L5→L3 写回仅限白名单，L4 不写 L3 |
| 三步状态机 | Step → Increment → Iteration 保持不变 |

---

## 三附、L3/L4/L5 算法打通最优方案

> **定位**：在六层/四型/四链之上，聚焦 **L3/L4/L5 底层算法实现与打通** 的可执行最优路径；偏工程落地，与 `UFC_三层联通总规范`、`L3_MD_L4_PH_联通契约与缺陷分析` 互补。

> **代码映射（仓库内落实对照）**：[`L3_L4_L5_二元结构主轴与波次路线图.md`](./L3_L4_L5_二元结构主轴与波次路线图.md)（三条硬线、静力 NR 主路径、`Compute_Ke`/`RT_Asm_*`/`RT_NLSolver_NewtonRaph` 等子程序落点）

### 三附.1 打通三条硬线

| 线 | 含义 | 最优做法 |
|----|------|----------|
| **计算链** | 谁算 K、谁算 R、谁解 Δu | L5：`Asm` 调 L4 `Compute_Ke` / `Compute_Fe` → L2 `Solve`；L5 **不**手写本构/单元公式 |
| **数据链** | 只读/可写边界 | L3 在分析中 **只读**（Desc）；L4 **Step 级**状态（Populate→slot）；L5 **Incr/Iter** 全局向量与矩阵；**仅 L5 WriteBack 白名单** 回写 L3 |
| **生命周期** | Init / Populate / Finalize | **Step 开始**：`PH_L4_Init` + Populate（L3→L4 缓存）；**每 Incr/Iter**：只碰 L4 slot + L5 全局量；**Step 结束**：`PH_L4_Finalize` |

**结论**：打通 = **计算链不断 + 数据链权限不越界 + 生命周期三拍子对齐**。

### 三附.2 三层算法职责边界（避免抢活）

| 层 | 应承担的算法 | 不应承担 |
|----|----------------|----------|
| **L3_MD** | 模型一致性、索引、PROC/步元数据；**不**做 Gauss 积分/本构 | 不组装全局 K、不实现 Newton 迭代体 |
| **L4_PH** | 形函数、B、D、单元 Ke/Fe、本构 σ 与 C_tan、接触/约束的**单元侧**贡献 | 不组装全局 CSR、不解方程、**不写 L3** |
| **L5_RT** | DOF 映射、组装、边界处理、线性/非线性求解驱动、收敛与切步、WriteBack | 不实现具体本构与单元族公式（只调度） |

### 三附.3 主路径与热路径：「一条金线 + 热路径零 L3」

#### 三附.3.1 P0 金线（先打通再扩展）

以 **静力隐式 Newton–Raphson** 为唯一 P0 金线：

```
StepDriver
  → Incr: 更新载荷/时间（仅 L5 + L3 Desc 只读查询若必须）
  → Iter:
       RT_Asm: 组装 K（L4 Compute_Ke 逐元）
       RT_Asm: 组装 R（L4 Compute_Fe 逐元 + L5 外力）
       L2: 解 K·Δu = R
       L5: 更新位移/状态 + 收敛判据
  → 收敛后 WriteBack（白名单）
```

其它 PROC（显式、弧长、耦合等）均为 **在此金线上的分支或第二条金线**，避免并行第三条混乱路径。

#### 三附.3.2 热路径契约（Populate + slot_pool，对齐 D2）

- **Step 级 Populate**：从 L3 拉 E、ν、截面、几何等 → 写入 L4 **slot_pool**（`C_tan`、`props`、几何缓存）。
- **单元循环内**：`Compute_Ke` / `Compute_Fe` **默认只读 L4 slot**；仅在 Populate 未覆盖或调试时 fallback L3。
- **原则**：热路径 **0 次 L3 USE**；L3 仅在 Populate 与（必要时）解析阶段出现。

### 三附.4 Bridge 最优形态（减双轨）

- **原则**：同一条数据流 **只保留一条主导 Bridge 方向**（避免 L3 侧推 + L4 侧拉职责重叠）。
- **推荐**：
  - **L5 → L4**：直接调 `PH_*_Domain` 的 TYPE 接口（组装循环）。
  - **L4 → L3**：仅 **只读 Get**（几何/Desc）；经 **单一**主导路径（如 `UF_Brg_L4_TO_L3` 或约定域内 `MD_*_PH_Brg`），避免重复封装。
  - **L3 → L5**：仅 **配置类**（网格拓扑、输出请求、载荷定义），不经热路径。

### 三附.5 接口最小稳定集

| 层 | 对上层建议稳定暴露的形态 |
|----|--------------------------|
| **L4** | `Compute_Ke(arg)`、`Compute_Fe(arg)`、本构 `Eval` / `Update`、（可选）`IncrBegin` / `Rollback`；参数以 **Ctx + 索引** 为主 |
| **L5** | `RT_Asm_AssembleK`、`RT_Asm_ComputeResidual`、`RT_Solv_*`、`RT_StepDriver_Execute`、WriteBack API |
| **L3** | `Get*Desc_Idx`、`Validate*`、Step/Mesh/Mat 查询；分析步内 **无** 物理写接口（除白名单写回路径） |

### 三附.6 验收标准（可量化）

1. **编译与符号**：P0 金线全链路 `gfortran -c` / 工程构建无未解析符号。
2. **Patch / 单元**：线弹一单元或小块体 **Ke/Fe** 与手算或 FEAP/HYPLAS 一致（量级、对称性）。
3. **静力题**：简支梁/悬臂等 **位移误差** 在工程容差内。
4. **性能探针**：单元循环内 **无 L3 模块 USE**（或静态计数为 0）。
5. **数据**：抽查 **L4 无写 L3**、**WriteBack 仅在白名单**。

### 三附.7 一句话最优方案

**以静力隐式 NR 为唯一金线打通计算链；用 Step 级 Populate + L4 slot 保证热路径零 L3；L5 只做组装/求解/收敛/写回；Bridge 收敛为单向主导、接口收敛为 Ke/Fe/Solve/WriteBack 四类。**

---

## 四、淬炼方案（按域级落地）

> **约束**：本节所有实施必须符合「一附、UFC 域级接口与功能集统一规范」；**算法打通须符合「三附、L3/L4/L5 算法打通最优方案」**；新建域/模块需先填域级合同卡。

### 4.1 L5_RT：引入「General」组织范式

**借鉴**: HYPLAS GENERAL 目录——收敛、算法选择、切步、回滚集中管理。

**域级合同卡（RT_Gen）**：
- 域名：General（胶水逻辑）
- 缩写：Gen
- 职责：算法选择、收敛判断、增量切步、状态回滚——与 HYPLAS GENERAL 对应
- 四型：消费 Step_Ctx、Step_Algo；产出（通过 status）收敛标志、切步建议
- 功能集：Algo（Select）、Compute（Conv_Check）、Compute（IncrCut）

**实施**:

1. **新建 RT_General 域**（按 1附.3 接口分层）：
   - `RT_Gen_Algo_Core.f90`（功能集：Algo）
     - 职责：类似 ALGOR，根据 PROC_*、RT_STEP_TYPE、iter 序号，返回 KRESL
     - 接口示例：
       ```fortran
       SUBROUTINE RT_Gen_Algo_Select(step_ctx, incr, iter, kresl, status)
         ! kresl: 1=切线刚度, 2=初刚度, 3=修正Newton-KT1, ...
       ```
   - `RT_Gen_Conv_Core.f90`（功能集：Compute）
   - `RT_Gen_IncrCut_Core.f90`（功能集：Compute）

2. **收敛/切步统一入口**：集中到 RT_Gen 域，避免散落。

3. **控制流文档化**：在 `RT_Driver_Core.f90` 顶部增加「L5 版 MAIN」流程图注释。

**目录建议**（与 1附.5 对齐）:
```
L5_RT/
├── General/              ← 新增，RT_Gen 域
│   ├── RT_Gen_Algo_Core.f90
│   ├── RT_Gen_Conv_Core.f90
│   └── RT_Gen_IncrCut_Core.f90
├── Physics/Assembly/
├── Physics/Solver/
├── StepDriver/
└── ...
```

---

### 4.2 L4_PH：强化 ELEMLIB / MATLIB 子域分组

**借鉴**: HYPLAS ELEMLIB（ELETYP+ELTOOL）、MATLIB（按本构分子目录）。

**对齐 1附**：Element/Mat/LoadBC 域需补齐域级合同卡，功能集标注到 Init/Compute/Query。

**与 Mesh 关系**：**网格拓扑仅在 L3 `MD_Mesh`**（见 **1附.5.1**、本节目录树不重复建 Mesh 域）；L4 Element 只消费 Populate 后的拓扑/材料摘要。

**实施**:

1. **Element 域**（PH_Elem）：
   - 功能集划分：`Core`（形函数、Jacobi、积分）← ELETYP；`Tool`（内力、刚度组装）← ELTOOL
   - 主入口：`PH_Element_Domain_Core`（符合 1附.3 的 Domain_Core 约定）
   - 子目录：Solid/Shell/Beam 为单元族子域，每族可再有 Core+Tool 功能集

2. **Material 域**（PH_Mat）：
   - 按本构分目录：Elastic/Plastic/HyperElas/Visc/Damage/Coupling/Geotech/Special/UMAT 等（与仓库 `L4_PH/Material/` 一致），与 HYPLAS MATLIB 建立映射表
   - 统一接口：`PH_Mat_Eval`、`PH_Mat_Integ_Core`、`Compute_Ctan`（各本构 Core）、`IncrBegin`/`Rollback`（状态管理）等归入 **Compute** 功能集
   - L3 侧材料 **Desc** 仍归 `MD_Mat_*`；Populate 后 L4 **禁止**步内回读 L3（见 **1附.5.1**）

3. **LoadBC 域**（PH_Ldbc）：
   - 载荷施加集中，不散落在 Element；与 HYPLAS INLOAD 职责对齐
   - 功能集：Compute（施加）、Query（幅值查询）

**目录建议**（与 1附.5 + 仓库现状一致；`Core/`、`Tool/` 为淬炼目标子目录，可与现有 `Shared/`、族目录并存迁移）:
```
L4_PH/
├── Element/
│   ├── PH_Element_Domain_Core.f90, PH_Element_Structural_Facade.f90, PH_Elem_Reg_Core.f90
│   ├── Shared/        ← 形函数、Jacobi、B、积分点、Dispatch（当前 ELETYP 共用体）
│   ├── Core/          ← （目标）与 Shared 归并或上移，对应 ELETYP 纯核
│   ├── Tool/          ← （目标）对应 ELTOOL：单元层胶水/派生装配辅助
│   ├── SLD3D/, SLD2D/, SHELL/, BEAM/, TRUSS/, SLD3DT/, SLD2DT/, SPRING/, Thermal/, User/, SPECIAL/
│   └── ...
├── Material/
│   ├── PH_Mat_Domain_Core.f90, PH_Mat_Reg_Core.f90, PH_Mat_Eval.f90, PH_Mat_Integ_Core.f90
│   ├── Shared/
│   ├── Elastic/, Plastic/, HyperElas/, Visc/, Damage/, Coupling/, Geotech/, Special/, UMAT/
│   └── ...            ← 与 HYPLAS MATLIB 子目录映射
├── LoadBC/             ← PH_Ldbc，载荷施加集中
├── Contact/
├── Coupling/
└── ...
```

---

### 4.3 L3_MD：INOUT 与 Load 职责清晰化

**借鉴**: HYPLAS INOUT（INDATA+OUTPUT+RPIVOT）、LOAD（INLOAD）。

**对齐 1附**：L3 各域统一使用缩写（LoadBC/Out/KW/Assem），域级合同卡明确「仅 Desc，不写文件」。

**实施**:

1. **Mesh 域**（MD_Mesh）：
   - 职责：**网格与拓扑 Desc**（节点、单元连通、集合、UEL 映射、DOF 定义）；与 HYPLAS INDATA 中网格读入/编号职责对齐
   - 功能集：Init、Query、Mutate（仅建模/Parse 阶段）、Valid、Finalize；**不含** IP 应力与 Ke 组装
   - 主模块：见 **1附.5.1（2）**；合同卡：`contracts/CONTRACT_Mesh.md`（若已有则随迭代更新）

2. **Material 域**（MD_Mat）：
   - 职责：**材料卡与本构参数 Desc**；注册与类型分发（`MD_Mat_Reg`、`MD_Mat_Types*`）；**不**在 L3 做步内本构积分
   - 功能集：Query、Valid、Parse；Brg：`MD_Mat_Bridge` → L4 Populate
   - 与 L4：`PH_Mat_Domain_Core` / `PH_Mat_*` 消费 Populate 后数据（**1附.5.1（4）**）；合同卡：`contracts/CONTRACT_Mat.md`

3. **Output 域**（MD_Out）：
   - 职责：仅定义输出请求（Schema），不执行写文件
   - 功能集：Query、Mutate（AddOutputRequest）；Parse（若从 inp 解析）

4. **LoadBC 域**（MD_Ldbc）：
   - 职责：仅模型定义（幅值、加载面、边界条件定义）
   - 对应 HYPLAS INLOAD 的输入侧；施加算法在 L4 PH_Ldbc

5. **Step 域**（MD_Step）：
   - 职责：分析步元数据、增量控制参数（对应 ININCR）

6. **KeyWord 域**（MD_KW）：
   - 功能集：Parse；建立 INDATA 对应表

**代码落地（L3_MD）**：域级合同卡入口见 `ufc_core/L3_MD/<域>/CONTRACT.md`（各域一份；跨域契约见 `ufc_core/L3_MD/Contracts/CONTRACT.md`）。各 `.f90` 在 `!>>> 依据:` 行后维护 `!>>> UFC_L3_CONTRACT | <域>/CONTRACT.md`。淬炼与 Populate 口径以 **本文件 1附** 与 [`UFC_DEVELOPER_GUIDE.md`](../04_技术标准/UFC_DEVELOPER_GUIDE.md) 为准。

**目录建议**（与 1附.5 + 仓库一致）:
```
L3_MD/
├── Model/
├── Part/
├── Mesh/               ← MD_Mesh_*、MD_Mesh_Domain_Core、MD_Mesh_Core/Mgr/API、MD_Mesh_Node/Elem/Data、MD_Elem_*、MD_DOF_*、MD_FieldState_API …
├── Section/
├── Material/           ← MD_Mat_Core、MD_Mat_API、MD_Mat_Reg、MD_Mat_Bridge、MD_Mat_Types*、各本构 MD_Mat_*_Core …
├── LoadBC/             ← MD_Ldbc，定义层
├── Step/               ← MD_Step，对应 ININCR
├── Output/             ← MD_Out，定义层
├── KeyWord/            ← MD_KW，对应 INDATA
├── Bridge/
└── ...
```

---

### 4.4 打通 L3↔L4↔L5：契约与 Bridge 强化

**基于**: 现有 L3_MD_L4_PH_联通契约、UFC_三层联通总规范；**Bridge 纳入 1附.3 的 Brg 角色**。

**实施**:

1. **统一 Bridge 索引**（纳入域级合同卡）:
   - 维护 `BRIDGE_INDEX.md`，列出 L3→L4、L3→L5、L5→L4 桥接
   - 每个 Bridge：方向、职责、调用方、被调用方、所属域
   - 符合 1附.3：Brg 仅负责跨层，不混合 Core

2. **数据链显式化**:
   - Step 级数据流：L3 Desc（只读）→ L4 Ctx（Populate）→ L5 State → WriteBack（白名单）→ L3 更新
   - 在域级合同卡中标注「数据链角色」

3. **热路径零 L3 访问**:
   - Compute_Ke/Compute_Fe 优先读 slot_pool；禁止热路径内直接访问 L3_MD

4. **ALGOR 映射表**:
   - UFC NALGO/PROC_* ↔ RT_Gen_Algo_Select 映射表

---

## 五、实施路线图

### 5.0 L3/L4/L5 算法打通（对齐三附，可与 5.1 并行）

| 阶段 | 内容 | 产出 | 预估 |
|------|------|------|------|
| **P0′** | 静力隐式 NR 金线贯通：Asm→Compute_Ke/Fe→L2 Solve→收敛→WriteBack | 符号全解析、最小可运行步 | 持续迭代 |
| **P1′** | Populate + slot_pool 覆盖主单元族；热路径零 L3 | D2 对齐报告、探针或静态检查 | 与 P0′ 同步 |
| **P2′** | Bridge 双轨收敛为单向主导（L4→L3 只读） | Bridge 变更说明、调用图 | 0.5–1 周 |
| **P3′** | 三附.6 五项验收全部达标 | 验收记录、回归用例入库 | 里程碑 |

#### 5.0.1 金线优先域（架构落地推荐顺序）

> **目标**：对齐 **三附 P0′ 金线**（静力隐式 NR：`Populate → Ke/Fe → Asm → Solve → Conv → WriteBack`），**热路径零 L3**。下列顺序兼顾 **依赖先后** 与 **可测性**；合同卡/注释随域迭代同步。

| 优先级 | UFC 域 / 目录 | 典型模块（示例） | 本阶段要落地的架构要点 |
|--------|----------------|------------------|------------------------|
| **P-A1** | **L4_PH · Element** | `L4_PH/Element/PH_Element_Domain_Core.f90`、Solid 金线单元（如 C3D8 路径） | `Compute_Ke`/`Compute_Fe` **只读 L4 slot**；形函数/B/本构调用边界清晰；与 **1附** Core/Tool 划分一致 |
| **P-A2** | **L5_RT · Assembly** | `L5_RT/Physics/Assembly/RT_Asm_Solv.f90` 等 | 全局 K/R 组装 **不调 L3**；CSR/带宽与 **L2** 契约稳定；残差与外力路径可追踪 |
| **P-A3** | **L5_RT · StepDriver** | `StepDriver/*`（如 `RT_CTE_Runner`、静力主 Driver） | **步/增量循环** 唯一编排；`PROC_*` 与 NR 收敛门控集中；为 **RT_Gen**（方案 P5）预留 Algo/Conv 挂钩 |
| **P-B1** | **L2_NM + L5 Bridge 求解** | `L2_NM`、`RT_Bridge_NM_Solver`、与 `RT_Asm_Solv` 衔接 | `Solve(Δu)` 接口稳定；不反向写 L3/L4 Desc |
| **P-B2** | **L4_PH · Material + Populate** | `L4_PH/Material/*`、`Populate` 链（L3→L4） | **Step 级** 材料进 slot；单元侧禁止步内回读 L3 |
| **P-C1** | **L4_PH · LoadBC** | `L4_PH/LoadBC/*` | 与 **L3 LoadBC** Bridge 单向；步内施加载荷不穿透 L3 |
| **P-C2** | **L5_RT · Output** | `L5_RT` 输出执行、与 `L3_MD/Out` 请求对齐 | 定义在 L3、执行在 L5；不写乱 L3 |

**执行建议**：以 **P-A1→A2→A3** 为第一个 **冲刺里程碑**（2～4 周量级，视人力）；每域合并前检查 **Bridge 索引**、`contracts`（或等价合同卡）及 **热路径 USE 探针**（三附.6）。

### 5.1 域级杂乱治理（优先，对齐 1附.8）

| 阶段 | 内容 | 产出 | 预估 |
|------|------|------|------|
| **P0** | 统一命名：按 1附.5 缩写表替换不一致域级名 | 命名变更清单、PR | 1 周 |
| **P1** | 补齐域级合同卡：L3/L4/L5 各域至少一份 | 合同卡文档集 | 1–2 周 |
| **P2** | 接口分层归一：Core/Mgr/API/Brg 角色划分 | 各域角色表、冗余合并 | 1 周 |
| **P3** | 功能集标注：合同卡+代码注释 | 功能集索引 | 0.5 周 |
| **P4** | 四型统一：Params→Algo，Ctx/State 命名对齐 | 类型定义更新 | 0.5 周 |

### 5.1.1 子程序标准化（贯穿多轮改造）

> **规范全文**：[`UFC_DEVELOPER_GUIDE.md`](../04_技术标准/UFC_DEVELOPER_GUIDE.md)（过程级注释与检查口径；原子程序独立规范未随库时以此为准）  
> **次级任务矩阵**：[`L3_L4_L5_二元结构主轴与波次路线图.md`](./L3_L4_L5_二元结构主轴与波次路线图.md)（波次 0–2、域门闩与 CI 渐进对齐）  
> **CI 脚本**：`scripts/ci/check_f90_sub_std.py`（`PUBLIC` 过程上方须含 `功能集:` / `功能集：` / `UFC_SUB_STD`；支持 `--git-merge-base`、`--warn-only`）  
> **要点**：所有 **SUBROUTINE/FUNCTION** 在新增与修改时统一 **命名前缀、INTENT、错误 status、注释头（层级/域/功能集/四型/热路径）**；**金线优先域（§5.0.1）** 先达标，再扩展到全 L4/L5/L2。  
> **与 P3 关系**：P3 侧重「合同卡与模块级注释」；本子程序规范落到 **过程级**，二者同时作为 PR 检查项。

### 5.2 HYPLAS 借鉴落地

| 阶段 | 内容 | 产出 | 预估 |
|------|------|------|------|
| **P5** | RT_Gen 域建立（Algo/Conv/IncrCut） | RT_Gen_*_Core.f90、合同卡 | 1–2 周 |
| **P6** | L4 Element Core/Tool 子域重组 | 目录调整、ELETYP/ELTOOL 映射 | 1–2 周 |
| **P7** | L3 Output/LoadBC/Step 职责梳理 | 职责表、INDATA 对应表（落地：`ufc_core/L3_MD/Analysis/Step/CONTRACT.md` 及 **§5.2** 叙述真源；`CONTRACT_KW`/`Out`/`LoadBC`/`Step` 内 P7 子表） | 1 周 |
| **P8** | Bridge 索引与数据链图更新 | BRIDGE_INDEX、数据流图 | 0.5 周 |
| **P9** | 端到端验证（静态/弧长/显式） | 验证报告、回归用例 | 持续 |
| **P10** | 2附.4 三源融合检查 | ABAQUS 对照表、HYPLAS 对齐报告 | 贯穿各阶段 |

---

## 六、对照表：HYPLAS ↔ UFC

| HYPLAS | UFC 对应 |
|--------|----------|
| MAIN.f90 | RT_Driver_Core / RT_StepDriver_Core |
| ALGOR | RT_Gen_Algo_Core（新建） |
| INCREM | RT_Step 增量控制、RT_Increment_Cut |
| CONVER | RT_Conv_Check、MD_Conv_Check |
| INTFOR | PH_Element::Compute_Fe、RT_Asm_ComputeResidual |
| TANGEN | RT_NLSolver_ArcLen 相关 |
| UPCONF / UPDATE | RT_WriteBack、PH_*_IncrBegin/Update |
| SWITCH | RT_State 回滚、PH_*_Rollback |
| INDATA | L3 KeyWord、L6 Input 解析 |
| OUTPUT | L5 Output、L6 Output |
| INLOAD | L3 LoadBC、L4 LoadBC |
| ELEMLIB | L4_PH Element |
| MATLIB | L4_PH Material、L3_MD Material |
| FRONT/ITERM | L2_NM Solver、L5 RT_Bridge_NM_Solver |

---

## 附录 B：ADINAM（`ADINAM.for` / `IND`）↔ UFC L4/L5 简表

> **完整对照**（主流程分段、调用链、`IND` 说明）：`CodeLib/代码库/ADINAM0121/ADINAM_UFC_L4L5_对照表.md`  
> **定位**：与 **§六 HYPLAS** 相同，仅作 **算法与流程** 参考；**禁止**引入 ADINAM 的 COMMON/全局池组织方式（见 **§七**）。

### B.1 `IND` 语义（摘自 `ADINAM.for` 注释）

| `IND` | ADINAM 含义（归纳） |
|-------|---------------------|
| 0 | 读入 / 输入阶段 |
| 1 | 组装线性刚度矩阵 |
| 2 / 3 | 质量矩阵相关；**3** 亦用于频率/模态路径 |
| 4 | 非线性分析（时间步内更新刚度与不平衡力） |

### B.2 主流程 → UFC 映射（简表）

| ADINAM 阶段 / 调用 | UFC 层级 | UFC 对应（示例） |
|--------------------|----------|------------------|
| `ADINI`、`ELCAL`、输入 | L3、L6 | `L3_MD` Desc；`L6_AP` 输入；Populate 前准备 |
| `ADDRES`/`ADDRES_CSRM`、`STORE` | L5、L2 | `RT_Asm_*` 结构；`L2_NM` 稀疏模式 |
| `IND=1` + `ASSEM`/`ASSEM_CSRM` | L4、L5 | `PH_Element` Ke；`RT_Asm_*` 组 K |
| `LOAD` | L4、L5 | `PH_Ldbc` 等；`RT_Asm_*` 组 R |
| `WRITE` 初值、`TIMINC`、`IND=4` 步循环 | L5 | `RT_StepDriver`、增量/时间 |
| `LOADMS` | L5 | 隐式动力 **有效荷载**（Newmark） |
| 步内 `ASSEM` | L4、L5 | K_t、内力；组装 |
| `COLSOL` / `SOLVEM` | L2、L5 | `L2_NM`；`RT_Bridge_NM_Solver` / `RT_Asm_Solv` |
| `EQUIT` | L5 | Newton/平衡迭代、收敛 |
| `STRESS` | L4（L5 调度） | 单元应力更新 / 后处理 |
| `FREQS`、`RESPAN`、`MODSUP` | L5、L2 | 特征/响应谱/模态叠加 |
| `METHOD=4` 弧长分支 | L5 | 弧长法（如 `RT_NLSolver_ArcLen`） |

---

## 附录 A：域级合同卡模板

```markdown
## {域名} 域级合同卡

- **层级**：L{n}_{IF|NM|MD|PH|RT|AP}
- **域名**：{Domain 全称}
- **缩写**：{1附.5 规定}
- **职责**：{一句话 + 职责边界}
- **四型配置**：
  - Desc：{本域产出/消费}
  - State：{本域产出/消费}
  - Ctx：{本域产出/消费}
  - Algo：{本域产出/消费}
- **核心接口**（按功能集）：
  | 功能集 | 子程序/TYPE 绑定 | 说明 |
  |--------|------------------|------|
  | Init   | Init, ...        |      |
  | Compute| Compute_*, ...   |      |
  | Query  | Get, ...         |      |
  | ...    | ...              |      |
- **依赖**：上游 {域}，下游 {域}
- **Bridge**：{若有，方向与目标层}
- **热路径**：{是/否}，若有则列出接口
```

---

## 七、风险与约束

| 风险 | 缓解措施 |
|------|----------|
| 引入 HYPLAS COMMON 风格 | 明确禁止，只借鉴目录与逻辑组织 |
| 过度集中导致单点故障 | RT_Gen_Algo 保持无状态，可测试、可替换 |
| 目录重组影响编译 | 分阶段迁移，保持向后兼容，优先文档与接口 |
| 与现有 Bridge 冲突 | 先梳理再实施，不动已有稳定 Bridge 接口 |

---

## 八、总结

本方案在**保留 UFC 六层、四型、四链、Bridge、TYPE 接口**的前提下：

### 8.1 解决域级杂乱：统一范式

- **三级结构**：层级 → 域级 → 功能集
- **四角色**：Core / Mgr / API / Brg 明确分工
- **功能集白名单**：Init / Query / Compute / Valid / Brg 等
- **域级合同卡**：每域必备，接口清单与依赖可追溯
- **命名统一**：按 1附.5 缩写表，消除 LoadBC/LoadBC、Constraint/Const 等双轨

### 8.2 融合 ABAQUS 设计风格（2附.1）

- 模型树、KW→Desc 单一映射、数据驱动
- UMAT/UEL 契约化、验证与 ABAQUS 对照
- 单元族+本构+截面组合、Theory 可追溯

### 8.3 提炼 HYPLAS 最小核心（2附.2）

1. **单入口编排** → RT_Driver 为「L5 版 MAIN」
2. **ALGOR 集中选择** → RT_Gen_Algo_Core
3. **GENERAL 胶水** → RT_Gen 域
4. **ELEMLIB/MATLIB 分离** → L4 Element Core/Tool、Material 按本构分
5. **INOUT/LOAD 聚合** → L3 Out/LoadBC 职责清晰

### 8.4 L3/L4/L5 算法打通（三附）

- 三条硬线：计算链、数据链、生命周期
- P0 金线：静力隐式 NR；热路径零 L3；Bridge 单向主导；接口四类 Ke/Fe/Solve/WriteBack
- 验收按三附.6

### 8.5 实施顺序

先完成**域级杂乱治理**（1附.8 的 P0–P4），同步以 **三附** 打通 P0 金线；再推进 **HYPLAS 借鉴落地**（P5–P9），并贯穿 **2附.4 三源融合检查清单**。均以域级合同卡、1附 与 **三附** 为约束。

---

**文档版本**: v1.9  
**状态**: 建议稿，待评审后进入实施  

**变更记录**:
- v1.1：新增「一附、UFC 域级接口与功能集统一规范」
- v1.2：新增「二附、ABAQUS 设计风格 + HYPLAS 最小核心」，三源融合架构与检查清单
- v1.3：新增「三附、L3/L4/L5 算法打通最优方案」；更新四/八节与版本信息
- v1.4：新增「附录 B、ADINAM（`IND`/主流程）↔ UFC L4/L5 简表」；详表见 `CodeLib/代码库/ADINAM0121/ADINAM_UFC_L4L5_对照表.md`
- v1.5：新增「§5.0.1 金线优先域」—— Element + Asm + StepDriver 为 P-A1～A3，并扩展 P-B/P-C 次序
- v1.6：新增「§5.1.1 子程序标准化」；独立规范曾拟于 `PLAN/03_技术规范与标准/…`（未随库）；现行入口为 `PPLAN/04_技术标准/UFC_DEVELOPER_GUIDE.md` + `scripts/ci/check_f90_sub_std.py`（过程级 INTENT/status/注释头/多轮销项）
- v1.7：§5.1.1 补充 CI 脚本 `scripts/ci/check_f90_sub_std.py`；`scripts/ci/README.md`
- v1.8：新增 **1附.5.1** 补全 **Mesh / Element / Material**（职责、功能集、HYPLAS 映射、`L3_MD`/`L4_PH` 路径）；扩展 **§4.2 / §4.3** 实施项与目录树
- v1.9：**落实到代码**：新增 L4 合同卡（`CONTRACT_Element.md`、`CONTRACT_Material.md`、`README.md`）；`PH_Element_Domain_Core` / `PH_Mat_Domain_Core` 增加 `UFC_PH_*` 三行；强化 `CONTRACT_Mesh.md` / `CONTRACT_Mat.md` 与 `MD_*_Core` 依据行及 1附.5.1 互链
- v1.10：L4 合同卡 **唯一落点** 迁至 `ufc_core/L4_PH/<域>/CONTRACT.md`（与 L3/L5 域合同卡并列）；`ufc_core` 内不再保留 `L4_PH/contracts/` 树
