# Material域二元结构模板规范

> **版本**: v1.0  
> **日期**: 2026-05-11  
> **关联文档**: [Material_Domain_Binary_Structure_Audit.md](./Material_Domain_Binary_Structure_Audit.md)  
> **标杆实现**: `ufc_core/L4_PH/Material/Elas/` (4文件完整参考)

---

## 1. 二元结构定义

Material域每个文件**严格归属**二元之一，不允许混合：

### 1.1 数据结构元 (Data Structure)

定义所有TYPE、枚举、参数常量。**零过程逻辑**（仅TBP的CONTAINS实现允许）。

| 分类 | 内容 | 规则 |
|------|------|------|
| **主四型TYPE** | `Desc` / `State` / `Algo` / `Ctx` | 每族必备，定义在`*_Def.f90` |
| **辅TYPE** | Phase×Verb×DataKind组合 | 嵌套在主TYPE内，Depth≤2 |
| **Args** | SIO统一参数包 `*_Eval_Arg` | 每族必备，[IN]/[OUT]注释 |
| **枚举/常量** | PARAMETER整数/字符 | 域级`*_Enum.f90`或族级Def内 |

### 1.2 过程算法元 (Process Algorithm)

实现所有SUBROUTINE/FUNCTION。**零TYPE定义**（仅USE导入）。

| 维度 | 说明 | 示例 |
|------|------|------|
| **空间(Spatial)** | 计算粒度 | IP / Elem / Domain |
| **时间(Temporal)** | 时间尺度 | Incr / Step / Iter |
| **动作(Action)** | 执行行为 | Eval / Update / Init / Populate / Dispatch |

---

## 2. 文件后缀规范表（Material域适配版）

| 后缀 | 二元归属 | 职责 | 必选/可选 | 命名模板 |
|------|----------|------|-----------|----------|
| `*_Def.f90` | 数据结构 | 主四型TYPE(Desc/State/Algo/Ctx)+Args | **必选** | `PH_Mat_<Fam>_Def.f90` |
| `*_Aux_Def.f90` | 数据结构 | 辅TYPE(Phase×Verb) | 域级必选/族级按需 | `PH_Mat_<Fam>_Aux_Def.f90` |
| `*_Enum.f90` | 数据结构 | 枚举/常量 | 域级必选/族级按需 | `PH_Mat_<Fam>_Enum.f90` |
| `*_KernelDefn.f90` | 数据结构 | 抽象基类/接口定义 | 域级 | `PH_Mat_KernelDefn.f90` |
| `*_Eval.f90` | 过程算法 | 3D入口(空间×时间×动作) | **必选** | `PH_Mat_<Fam>_Eval.f90` |
| `*_Core.f90` | 过程算法 | 族级统一内核 | 必选(当有多模型时) | `PH_Mat_<Fam>_Core.f90` |
| `*_<Model>_Core.f90` | 过程算法 | 模型专属内核 | 按需 | `PH_Mat_<Fam>_<Model>_Core.f90` |
| `*_Proc.f90` | 过程算法 | SIO薄包装(签名适配) | 可选 | `PH_Mat_<Fam>_<Model>_Proc.f90` |
| `*_Brg.f90` | 过程算法 | 跨层桥接(L4↔L5) | 按需(族级跨L5时) | `PH_Mat_<Fam>_Brg.f90` |
| `*_Dsp.f90` | 过程算法 | 分发路由 | 域级 | `PH_Mat_Dsp.f90` |
| `*_Reg.f90` | 过程算法 | 注册表/工厂 | 域级 | `PH_Mat_Reg.f90` |
| `*_Populate.f90` | 过程算法 | L3→L4冷路径填充 | 域级 | `PH_L4_Populate.f90` |

### 后缀闭集约束

以上12种后缀为Material域**封闭集合**，新增文件必须选择其中之一。域级文件命名前缀为`PH_Mat_`或`PH_L4_`，族级文件前缀为`PH_Mat_<Fam>_`。

---

## 3. 族级标准文件集

### 3.1 最小必备集 (2文件)

```
Material/<Family>/
├── PH_Mat_<Fam>_Def.f90          -- [数据结构][必选] 四型TYPE + Args
└── PH_Mat_<Fam>_Eval.f90         -- [过程算法][必选] 3D命名入口
```

适用：单模型族（如User）或算法极简族。

### 3.2 标准集 (3-4文件)

```
Material/<Family>/
├── PH_Mat_<Fam>_Def.f90          -- [数据结构][必选] 四型TYPE + Args
├── PH_Mat_<Fam>_Eval.f90         -- [过程算法][必选] 3D命名入口
├── PH_Mat_<Fam>_Core.f90         -- [过程算法][必选*] 族级统一内核
└── PH_Mat_<Fam>_Brg.f90          -- [过程算法][按需] 跨层桥接
```

*注：当族仅有单模型时，Core内容可合入Eval；当有多模型时Core为必选。

### 3.3 完整集 (多模型族)

```
Material/<Family>/
├── PH_Mat_<Fam>_Def.f90              -- [数据结构][必选] 四型TYPE + Args
├── PH_Mat_<Fam>_Eval.f90             -- [过程算法][必选] 3D命名入口
├── PH_Mat_<Fam>_Core.f90             -- [过程算法][必选] 族级统一分发
├── PH_Mat_<Fam>_Brg.f90              -- [过程算法][按需] 跨层桥接
├── PH_Mat_<Fam>_<ModelA>_Core.f90    -- [过程算法][按需] 模型A专属
├── PH_Mat_<Fam>_<ModelB>_Core.f90    -- [过程算法][按需] 模型B专属
└── PH_Mat_<Fam>_<ModelC>_Proc.f90    -- [过程算法][可选] 模型C签名适配
```

### 3.4 标杆对照 (Elas族 = 标准集完整版)

```
Material/Elas/
├── PH_Mat_Elas_Def.f90   (320行) -- Desc/State/Algo/Ctx + Eval_Arg + 3辅TYPE + TBP
├── PH_Mat_Elas_Eval.f90  (146行) -- IP_Incr_Eval / IP_Incr_Update / Eval_With_Args
├── PH_Mat_Elas_Core.f90  (10.9KB) -- Build_Stiffness / Compute_Stress / Compute_Tangent / Update_State
└── PH_Mat_Elas_Brg.f90   (2.3KB) -- L5适配(RT层签名转换)
```

---

## 4. 数据结构规范

### 4.1 主TYPE命名

| TYPE名 | 职责 | 生命周期 | 可变性 |
|--------|------|----------|--------|
| `PH_Mat_<Fam>_Desc` | 材料配置描述 | 分析全程 | Immutable(Init后只读) |
| `PH_Mat_<Fam>_State` | 积分点运行态 | 增量步间累积 | Mutable(每步更新) |
| `PH_Mat_<Fam>_Algo` | 算法控制参数 | 分析全程 | 少变(仅Config时改) |
| `PH_Mat_<Fam>_Ctx` | 增量/迭代工作区 | 单增量步 | 易变(每步重置) |

### 4.2 辅TYPE命名

模板：`PH_Mat_<Fam>_<Phase>_<Verb>_<DataKind>`

| Phase | Verb | DataKind | 示例 |
|-------|------|----------|------|
| Cfg (配置) | Init (初始化) | Desc | `PH_Mat_Elas_Cfg_Init_Desc` |
| Pop (填充) | Vld (验证) | Desc | `PH_Mat_Elas_Pop_Vld_Desc` |
| Inc (增量) | Evo (演化) | Ctx | `PH_Mat_Elas_Inc_Evo_Ctx` |
| Stp (步) | Agg (聚合) | State | `PH_Mat_Plast_Stp_Agg_State` |

### 4.3 Args命名

统一SIO参数包：`PH_Mat_<Fam>_Eval_Arg`

```fortran
TYPE, PUBLIC :: PH_Mat_<Fam>_Eval_Arg
  !--- [IN] fields ---
  REAL(wp) :: strain(6)       ! [IN]  当前总应变
  REAL(wp) :: dstrain(6)      ! [IN]  应变增量
  REAL(wp) :: temperature     ! [IN]  当前温度
  REAL(wp) :: dtemp           ! [IN]  温度增量
  !--- [OUT] fields ---
  REAL(wp) :: stress(6)       ! [OUT] 更新后应力
  REAL(wp) :: ddsdde(6,6)     ! [OUT] 切线刚度
  !--- [INOUT] fields ---
  REAL(wp), ALLOCATABLE :: statev(:) ! [INOUT] 状态变量
  !--- [OUT] status ---
  INTEGER(i4)        :: status_code  ! [OUT] 退出码
  CHARACTER(len=256) :: message      ! [OUT] 状态消息
END TYPE
```

### 4.4 嵌套规则

```
主TYPE (Depth 0)
├── 辅TYPE实例 (Depth 1)     -- 允许
│   └── 标量/数组成员         -- Depth 2 = 最大
└── 标量/数组成员             -- 直接成员
```

- **Depth ≤ 2**: 主TYPE→辅TYPE→标量，不允许更深嵌套
- **方向约束**: 主TYPE聚合辅TYPE（has-a），辅TYPE不反向引用主TYPE
- **跨族禁止**: 族A的TYPE不嵌入族B的TYPE实例

### 4.5 TBP (Type-Bound Procedures) 规范

| TBP名 | 职责 | 所属TYPE |
|--------|------|----------|
| `Init` | 初始化TYPE实例 | Desc/State/Algo/Ctx |
| `Clean` | 释放ALLOCATABLE成员 | Desc/State/Ctx |
| `Valid` | 自验证 | Desc |
| `Copy` | 深拷贝 | Desc |
| `Update` | 状态更新 | State |
| `Reset` | 状态重置(保留strain) | State |
| `Config` | 修改算法参数 | Algo |
| `CacheStif` | 缓存刚度矩阵 | Ctx |

---

## 5. 过程算法规范

### 5.1 3D命名模板

```
PH_Mat_<Fam>_<Spatial>_<Temporal>_<Action>
```

| 维度 | 取值 | 含义 |
|------|------|------|
| **Spatial** | `IP` | 积分点级 |
| | `Elem` | 单元级 |
| | `Domain` | 域级(批量) |
| **Temporal** | `Incr` | 增量步 |
| | `Step` | 分析步 |
| | `Iter` | 迭代 |
| **Action** | `Eval` | 评估(应力+切线) |
| | `Update` | 状态更新(仅) |
| | `Init` | 初始化 |
| | `Populate` | 数据填充 |
| | `Dispatch` | 分发路由 |

**示例**:
- `PH_Mat_Elas_IP_Incr_Eval` — 积分点级、增量步、评估
- `PH_Mat_Plast_IP_Incr_Update` — 积分点级、增量步、状态更新
- `PH_Mat_Domain_Step_Init` — 域级、分析步、初始化

### 5.2 SIO签名规范

**6参数规范形式**（首选）:

```fortran
SUBROUTINE PH_Mat_<Fam>_IP_Incr_Eval(desc, state, algo, ctx, args, status)
  TYPE(PH_Mat_<Fam>_Desc),     INTENT(IN)    :: desc
  TYPE(PH_Mat_<Fam>_State),    INTENT(INOUT) :: state
  TYPE(PH_Mat_<Fam>_Algo),     INTENT(IN)    :: algo
  TYPE(PH_Mat_<Fam>_Ctx),      INTENT(INOUT) :: ctx
  TYPE(PH_Mat_<Fam>_Eval_Arg), INTENT(INOUT) :: args
  TYPE(ErrorStatusType),        INTENT(OUT)   :: status
END SUBROUTINE
```

**4参数简化形式**（当Algo/Ctx不需要时）:

```fortran
SUBROUTINE PH_Mat_<Fam>_IP_Incr_Eval(desc, state, args, status)
  TYPE(PH_Mat_<Fam>_Desc),     INTENT(IN)    :: desc
  TYPE(PH_Mat_<Fam>_State),    INTENT(INOUT) :: state
  TYPE(PH_Mat_<Fam>_Eval_Arg), INTENT(INOUT) :: args
  TYPE(ErrorStatusType),        INTENT(OUT)   :: status
END SUBROUTINE
```

**INTENT约定**:
| 参数 | INTENT | 说明 |
|------|--------|------|
| `desc` | IN | 只读描述符 |
| `state` | INOUT | 可更新状态 |
| `algo` | IN | 只读算法参数 |
| `ctx` | INOUT | 可写工作区 |
| `args` | INOUT | SIO包([IN]读/[OUT]写) |
| `status` | OUT | 错误状态 |

### 5.3 Core文件内子程序命名

族级Core内的子程序使用功能动词命名（无3D前缀）:

```fortran
! PH_Mat_Elas_Core.f90 内的子程序
PH_Mat_Elas_Build_Stiffness   -- 构建刚度矩阵
PH_Mat_Elas_Compute_Stress    -- 计算应力
PH_Mat_Elas_Compute_Tangent   -- 计算切线
PH_Mat_Elas_Update_State      -- 更新状态
```

模板：`PH_Mat_<Fam>_<Verb>_<Object>`

---

## 6. 关键决策

### 决策1: `*_Proc.f90` 定位

| 属性 | 说明 |
|------|------|
| **定义** | Proc = Eval的薄代理（仅做类型转换和参数打包） |
| **不含** | 业务逻辑、计算代码 |
| **使用场景** | 模型有独立Desc TYPE（来自L3）且需适配到域级签名时 |
| **典型案例** | Geo族的DP模型：L3的`MD_Geo_DP_Desc`需转换到`PH_Mat_Geo_Desc` |
| **结论** | **非必备**，仅Geo等有复杂L3映射时使用 |

### 决策2: `*_Brg.f90` 按需原则

| 属性 | 说明 |
|------|------|
| **定义** | Brg = L4→L5签名转换薄层 |
| **创建条件** | 族需要直接暴露接口给L5_RT |
| **当前状态** | 仅Elas有族级Brg（L5路由最频繁） |
| **其他族** | 通过域级`PH_Mat_Core`的S2_Dispatch间接桥接 |
| **结论** | **可选**，不强制每族必备 |

### 决策3: Dispatch文件夹处置

| 文件 | 决策 | 理由 |
|------|------|------|
| `PH_MatPLM_LegacyFacadeUMATs.f90` | **FROZEN** | 229KB，不改不删，等L5全切 |
| `PH_MatEval.f90` | **STAGING** | 随族Eval完善渐进削减 |
| 其他4文件 | **Legacy→合并** | 保留为过渡，后续合入族Core/Eval |

### 决策4: 域级`Domain_Core`命名

| 属性 | 说明 |
|------|------|
| **现状** | `PH_Mat_Domain_Core.f90` |
| **决策** | 保持不改名 |
| **理由** | 其`_Core`表达"核心定义"（混合域级TYPE+过程），与族级`_Core`(纯计算)语义不同 |
| **消歧义** | 头部注释标注 `! ROLE: Domain-Def (not compute kernel)` |

---

## 7. 域级文件组织总览

```
Material/
├── [数据结构] PH_Mat_Def.f90           -- 再导出枢纽(USE all族Def)
├── [数据结构] PH_Mat_Aux_Def.f90       -- 域级辅TYPE集合
├── [数据结构] PH_Mat_Enum.f90          -- 枚举常量
├── [数据结构] PH_Mat_KernelDefn.f90    -- 抽象基类
├── [混合/域级] PH_Mat_Domain_Core.f90  -- 域核心定义
├── [过程算法] PH_Mat_Core.f90          -- S1-S4执行主流
├── [过程算法] PH_Mat_Dsp.f90           -- 分发路由(原Dispatch)
├── [过程算法] PH_Mat_Reg.f90           -- 注册表/工厂
├── [过程算法] PH_Mat_Interp.f90        -- 插值工具(目标名)
├── [过程算法] PH_L4_L3MatContract.f90  -- L3-L4映射桥接
├── [过程算法] PH_L4_Populate.f90       -- 冷路径填充
├── [DEPRECATED] PH_Mat_Core_Types.f90  -- 废弃(待移除)
│
├── Elas/       -- 标杆(4文件: Def/Eval/Core/Brg)
├── Plast/      -- 多模型(9文件: Def/Eval/Core + 5模型Core)
├── Geo/        -- 多模型+Proc(7文件)
├── Damage/     -- 多模型(4文件)
├── Hyper/      -- 标准(3文件)
├── Creep/      -- 标准(3文件)
├── Composite/  -- 多模型(4文件)
├── Thermal/    -- 多模型(3文件)
├── Acoustic/   -- 多模型(3文件)
├── Viscoelas/  -- 标准(3文件)
├── User/       -- 最小(2文件)
├── Dispatch/   -- [FROZEN/STAGING] Legacy过渡区
└── Shared/     -- 跨族共享工具
```

---

## 8. 新族创建Checklist

创建新族`<NewFam>`时，按以下顺序：

- [ ] 1. 创建目录 `Material/<NewFam>/`
- [ ] 2. 创建 `PH_Mat_<NewFam>_Def.f90` — 定义四型TYPE + Args
- [ ] 3. 创建 `PH_Mat_<NewFam>_Eval.f90` — 实现3D命名入口
- [ ] 4. (可选) 创建 `PH_Mat_<NewFam>_Core.f90` — 如有多模型
- [ ] 5. (可选) 创建 `PH_Mat_<NewFam>_Brg.f90` — 如需直连L5
- [ ] 6. 在 `PH_Mat_Def.f90` 添加 USE re-export
- [ ] 7. 在 `PH_Mat_Enum.f90` 添加族ID常量
- [ ] 8. 在 `PH_Mat_Reg.f90` 注册族工厂
- [ ] 9. 在 `PH_L4_Populate.f90` 添加填充分支

---

*END OF TEMPLATE*
