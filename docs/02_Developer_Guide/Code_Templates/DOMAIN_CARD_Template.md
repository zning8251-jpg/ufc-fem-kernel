# DOMAIN_CARD — {{DOMAIN_NAME}} 域
<!-- 域级合同卡（Domain Contract Card）v1.0 标准模板 -->
<!-- 填写说明：将所有 {{占位符}} 替换为实际内容；删除本行及以下所有注释行 -->
<!-- 适用范围：UFC 六层架构中每一个独立域（Material/Element/LoadBC/Contact/Constraint/Field/Analysis/Output…） -->
<!-- 权威性：本卡是该域开发、评审、验收的唯一依据，所有 f90 实现必须对齐本卡 -->

**版本**：v{{X.Y}}
**域**：{{DOMAIN_NAME}}（{{DOMAIN_ABBR}}）
**层级跨度**：{{L3_MD / L4_PH / L5_RT（删去不涉及的层）}}
**签发日期**：{{YYYY-MM-DD}}
**上次修订**：{{YYYY-MM-DD}}
**状态**：{{草稿 / 评审中 / 已定稿 / 已废弃}}
**关联技能**：`ufc-layer-domain-feature` · `ufc-structured-io`

---

## §1 设计意图（Design Intent）

> 本节是本域存在理由的最高纲领。其他节均从本节推导。

### 1.1 域的职责陈述（One-liner）

```
{{DOMAIN_NAME}} 域负责 {{用一句话说清楚：这个域管什么，不管什么}}。
```

### 1.2 六层定位

| 层级 | 本域在此层的角色 | 核心交付物 |
|------|----------------|-----------|
| L3_MD | {{What — 描述模型是什么}} | {{TYPE 名称，如 MD_XXX_Base_Desc}} |
| L4_PH | {{How — 描述物理计算如何发生}} | {{TYPE 名称 + 关键子程序}} |
| L5_RT | {{When/Where — 描述运行时调度时机}} | {{RT_XXX_Ctx}} |

> 如本域不跨某层，填"N/A（理由）"，勿留空。

### 1.3 上下游边界

```
上游（输入来源）：
  - {{域A / 子程序名}} 提供 {{数据描述}}
  - {{域B}} 提供 {{数据描述}}

本域核心变换：
  {{输入X}} ──▶ [{{DOMAIN_NAME}} 计算核心] ──▶ {{输出Y}}

下游（输出去向）：
  - 产出 {{数据描述}} 交给 {{域C / 求解器}}
  - 产出 {{数据描述}} 交给 {{域D}}
```

### 1.4 明确不负责的事项（Out-of-Scope）

- ❌ {{不属于本域的事项1}}
- ❌ {{不属于本域的事项2}}
- ❌ 本域不跨越 L{{X}} 层直接调用 L{{Y}} 层（依赖铁律）

---

## §2 四类 TYPE 划分

> 命名规范：`{层缀}_{域缩写}_{子模型}_{类型后缀}`
> 层缀：MD_ / PH_ / RT_；类型后缀：Desc / State / Algo / Ctx

### 2.1 TYPE 总览矩阵

| 类型后缀 | 归属层 | 冷/热路径 | 生命周期 | 允许 ALLOCATABLE | 主要 TYPE 名称 |
|---------|--------|---------|---------|----------------|--------------|
| **Desc** | L3_MD | 冷 | 模型加载→析构 | ✅（仅初始化阶段）| `MD_{{Abbr}}_Base_Desc` |
| **State** | L3_MD（或L4_PH） | 热 | 增量步内持久 | ✅ | `MD_{{Abbr}}_Base_State` |
| **Algo** | L4_PH | 冷 | 迭代内只读 | ❌ | `PH_{{Abbr}}_Base_Algo` |
| **Ctx** | L4_PH / L5_RT | 热 | 增量步内临时 | ❌（禁止热路径分配）| `PH_{{Abbr}}_Base_Ctx` |

### 2.2 L3_MD 层 TYPE 定义骨架

```fortran
!===============================================================================
! L3_MD — {{DOMAIN_NAME}} 域描述符（Descriptor）
!===============================================================================
TYPE, PUBLIC :: MD_{{Abbr}}_Base_Desc
  !-- §2.2.1 标识字段
  INTEGER(i4)            :: id          = 0_i4   ! 唯一 ID（注册表键）
  CHARACTER(LEN=64)      :: name        = ''      ! 名称标签

  !-- §2.2.2 核心参数
  ! TODO: 填入本域特有的静态参数
  ! REAL(wp)             :: param1      = 0.0_wp
  ! INTEGER(i4)          :: flag1       = 0_i4

  !-- §2.2.3 跨域引用（指针，冷路径合法）
  ! TYPE(MD_Other_Base_Desc), POINTER :: other_desc => NULL()
END TYPE MD_{{Abbr}}_Base_Desc

!===============================================================================
! L3_MD — {{DOMAIN_NAME}} 域状态（State）
!===============================================================================
TYPE, PUBLIC :: MD_{{Abbr}}_Base_State
  !-- §2.2.4 热路径状态变量（高频读写）
  ! REAL(wp), ALLOCATABLE :: statev(:)
  LOGICAL                :: converged  = .FALSE.
END TYPE MD_{{Abbr}}_Base_State
```

### 2.3 L4_PH 层 TYPE 定义骨架

```fortran
!===============================================================================
! L4_PH — {{DOMAIN_NAME}} 域算法参数（Algorithm）
!===============================================================================
TYPE, PUBLIC :: PH_{{Abbr}}_Base_Algo
  !-- 求解控制（冷路径，迭代内只读）
  INTEGER(i4) :: max_iter   = 50_i4
  REAL(wp)    :: tolerance  = 1.0e-6_wp
  REAL(wp)    :: pnewdt_min = 0.1_wp
END TYPE PH_{{Abbr}}_Base_Algo

!===============================================================================
! L4_PH — {{DOMAIN_NAME}} 域上下文（Context，热路径）
!===============================================================================
TYPE, PUBLIC :: PH_{{Abbr}}_Base_Ctx
  !-- §2.3.1 增量驱动输入（禁止 ALLOCATABLE）
  REAL(wp) :: time     = 0.0_wp   ! 当前时刻
  REAL(wp) :: dtime    = 0.0_wp   ! 时间增量
  INTEGER(i4) :: kstep = 0_i4     ! 分析步号
  INTEGER(i4) :: kinc  = 0_i4     ! 增量步号

  !-- §2.3.2 本域特有热数据
  ! TODO: 填入本域特有的上下文字段（禁止 ALLOCATABLE）
END TYPE PH_{{Abbr}}_Base_Ctx
```

### 2.4 L5_RT 层 TYPE 定义骨架

```fortran
!===============================================================================
! L5_RT — {{DOMAIN_NAME}} 域运行时上下文
!===============================================================================
TYPE, PUBLIC :: RT_{{Abbr}}_Domain_Ctx
  !-- 聚合 PH 层上下文
  TYPE(PH_{{Abbr}}_Base_Ctx) :: ph_ctx

  !-- 调度信息
  INTEGER(i4) :: domain_id  = 0_i4
  LOGICAL     :: is_active  = .TRUE.
END TYPE RT_{{Abbr}}_Domain_Ctx
```

### 2.5 派生扩展族（可选）

> 基于多态扩展的子类型列表（EXTENDS(MD_{{Abbr}}_Base_Desc)）

| 扩展 TYPE 名 | 对应 ABAQUS 子程序/关键字 | 新增字段摘要 |
|-------------|------------------------|------------|
| `MD_{{Abbr}}_{{Sub1}}_Desc` | {{ABAQUS 子程序名}} | {{新增字段}} |
| `MD_{{Abbr}}_{{Sub2}}_Desc` | {{ABAQUS 子程序名}} | {{新增字段}} |

---

## §3 四链贯通（Four-Chain Mapping）

### 3.1 理论链（Theory Chain）— 物理→数学→离散

```
物理概念：{{本域所基于的物理原理，如"连续介质力学 Cauchy 应力原理"}}
    ↓
数学表述：{{对应的数学方程/变分形式，如"σ = C:ε（广义 Hooke 定律）"}}
    ↓
离散形式：{{有限元离散结果，如"K_e·u_e = F_int_e"}}
    ↓
计算实现：{{对应的 UFC 子程序，如"PH_XXX_UEL_Stiff_Proc"}}
```

**参考文献**：
- {{Zienkiewicz & Taylor, FEM 第X版，第X章}}
- {{ABAQUS Theory Manual §X.X}}

### 3.2 逻辑链（Logic Chain）— 模型→求解→输出

```
输入：{{L3 的 MD_{{Abbr}}_Base_Desc（来自关键字解析）}}
  ↓ Populate（冷路径，一次性）
注册表/槽位指针
  ↓ 热路径触发（每增量步）
PH 层计算（L4）：{{核心计算子程序列表}}
  ↓ 写回白名单
{{L3 State / L5 Output 汇总}}
```

### 3.3 计算链（Computation Chain）— 全局→单元→材料

```
L5_RT（全局驱动）
  ├─ 分析步 (Step) 循环
  │    ├─ 增量步 (Increment) 循环
  │    │    ├─ {{本域顶层计算入口：如"单元循环"}}
  │    │    │    └─ {{本域中层：如"积分点循环"}}
  │    │    │         └─ {{本域底层：如"本构更新"}}
  │    │    └─ {{汇总操作：如"组装总刚"}}
  │    └─ {{收敛判断}}
  └─ {{后处理}}
```

### 3.4 数据链（Data Chain）— 生命周期管理

| 阶段 | 操作 | 负责子程序 | 数据状态 |
|------|------|----------|---------|
| **初始化** | 分配 Desc 字段、零初始化 State | `MD_{{Abbr}}_Init_Proc` | 已分配，未 Populate |
| **Populate** | 从关键字树填写 Desc | `MD_{{Abbr}}_Populate_Proc` | 已 Populate，只读 |
| **热路径** | 读 Desc，读写 State/Ctx | PH 层计算子程序 | 运行时高频访问 |
| **写回** | 将 State 写回持久化存储 | `RT_{{Abbr}}_WriteBack_Proc` | 增量步结束 |
| **析构** | 释放 ALLOCATABLE 字段 | `MD_{{Abbr}}_Finalize_Proc` | 分析结束 |

---

## §4 计算流程图（Mermaid）

> 本图展示本域在一个增量步内的完整执行流程。

```mermaid
graph TB
    A[L5_RT: 增量步驱动] --> B[获取 RT_{{Abbr}}_Domain_Ctx]
    B --> C{域激活？}
    C -- 否 --> Z[跳过]
    C -- 是 --> D[填充 PH_{{Abbr}}_Base_Ctx]
    D --> E[调用 PH_{{Abbr}}_Core_Proc]
    E --> F[核心物理计算]
    F --> G[更新 MD_{{Abbr}}_Base_State]
    G --> H[写回白名单检查]
    H --> I[RT_WriteBack_Proc]
    I --> J[增量步结束]
```

**热路径关键路段**（禁止在此段做以下操作）：
- ❌ ALLOCATE / DEALLOCATE
- ❌ 多级 SELECT TYPE（超过 1 层）
- ❌ 直接访问 L3_MD 注册表（需通过 Populate 结果的缓存指针）
- ❌ 文件 IO

---

## §5 结构体嵌套与扁平存储规则

### 5.1 嵌套策略

```
MD_{{Abbr}}_Base_Desc
  ├── 标识字段（id, name）
  ├── 核心参数（flat — 直接存储，无指针）
  └── 跨域引用（POINTER — 仅冷路径合法）

PH_{{Abbr}}_Base_Ctx
  ├── 共享时间字段（time, dtime, kstep, kinc）
  └── 域特有热数据（flat — 禁止 ALLOCATABLE）
```

### 5.2 扁平化规则（性能约束）

| 规则 | 说明 |
|------|------|
| 热路径结构体 **零 ALLOCATABLE** | Ctx 中所有字段必须是固定大小数组或标量 |
| 跨域引用 **必须用 POINTER** | 不做值拷贝，Desc 通过指针关联其他域 Desc |
| State 数组 **只在初始化分配一次** | `statev(:)` 在 Init 时分配，热路径不重分配 |
| Desc 只读 **不可在热路径修改** | 热路径内修改 Desc 字段视为架构违规 |

### 5.3 ABAQUS 扁平数组 → UFC 结构体映射（Adapter 职责）

```fortran
! Adapter 层（ABAQUS UEL/UMAT 接口入口）负责 pack/unpack
! 内核层只认 TYPE 结构体，永不接触 ABAQUS 原始数组

! [IN] ABAQUS 扁平数组 → UFC Desc/Ctx
desc%{{field1}} = PROPS(1)         ! PROPS → Desc 参数
ctx%{{field2}}  = DSTRAN(1:NTENS)  ! DSTRAN → Ctx 增量应变

! [OUT] UFC State → ABAQUS 扁平数组
STRESS(1:NTENS)        = state%stress(1:ntens)
DDSDDE(1:NTENS,1:NTENS)= state%ddsdde(1:ntens,1:ntens)
STATEV(1:NSTATV)       = state%statev(1:nstatv)
```

---

## §6 公开 API（子程序接口规范）

> 本节列出本域对外暴露的所有公开子程序。所有接口必须遵循 SIO Principle #14（统一 `*_Arg` + 五参/六参形式）。

### 6.1 子程序总览

| 子程序名 | 类型 | 热/冷路径 | 调用者 | 功能摘要 |
|---------|------|---------|--------|---------|
| `MD_{{Abbr}}_Init_Proc` | SUBROUTINE | 冷 | L5_RT 初始化 | 分配 + 零初始化 |
| `MD_{{Abbr}}_Populate_Proc` | SUBROUTINE | 冷 | L3 关键字解析后 | 从关键字树填写 Desc |
| `PH_{{Abbr}}_Core_Proc` | SUBROUTINE | 热 | L5_RT 每增量步 | 核心物理计算 |
| `RT_{{Abbr}}_WriteBack_Proc` | SUBROUTINE | 冷 | L5_RT 增量步结束 | 状态写回 |
| `MD_{{Abbr}}_Finalize_Proc` | SUBROUTINE | 冷 | L5_RT 析构 | 释放内存 |

### 6.2 核心子程序接口（五参形式 SIO）

```fortran
!===============================================================================
! PH_{{Abbr}}_Core_Proc — 本域热路径核心计算入口
! 签名：五参形式（desc, state, algo, ctx, args）
!===============================================================================
SUBROUTINE PH_{{Abbr}}_Core_Proc(desc, state, algo, ctx, args)
  USE MD_{{Abbr}}_Types_Mod, ONLY: MD_{{Abbr}}_Base_Desc, MD_{{Abbr}}_Base_State
  USE PH_{{Abbr}}_Types_Mod, ONLY: PH_{{Abbr}}_Base_Algo, PH_{{Abbr}}_Base_Ctx
  USE PH_{{Abbr}}_Arg_Mod,   ONLY: PH_{{Abbr}}_Core_Arg
  IMPLICIT NONE

  TYPE(MD_{{Abbr}}_Base_Desc),  INTENT(IN)    :: desc   ![IN]  静态描述符
  TYPE(MD_{{Abbr}}_Base_State), INTENT(INOUT) :: state  ![OUT] 运行时状态
  TYPE(PH_{{Abbr}}_Base_Algo),  INTENT(IN)    :: algo   ![IN]  算法参数
  TYPE(PH_{{Abbr}}_Base_Ctx),   INTENT(IN)    :: ctx    ![IN]  增量上下文
  TYPE(PH_{{Abbr}}_Core_Arg),   INTENT(INOUT) :: args   ![IN/OUT] 扩展参数包

  !-- TODO: 实现核心物理计算

END SUBROUTINE PH_{{Abbr}}_Core_Proc

!===============================================================================
! MD_{{Abbr}}_Populate_Proc — 冷路径 Populate
!===============================================================================
SUBROUTINE MD_{{Abbr}}_Populate_Proc(desc, state, algo, ctx, args)
  !-- 从关键字解析树填写 desc 的所有字段
  !-- 调用时机：模型加载阶段（一次性）
  !-- 调用后：desc 转为只读，不可再修改
END SUBROUTINE MD_{{Abbr}}_Populate_Proc
```

### 6.3 禁止跨域直接调用规则

| 禁止调用关系 | 原因 | 正确替代 |
|------------|------|---------|
| L4_PH 直接访问 L3_MD 注册表 | 破坏层级依赖铁律 | 通过 Populate 后的指针/槽位 |
| L5_RT 直接修改 L4 State | 破坏写回白名单 | 通过 RT_WriteBack 白名单机制 |
| 热路径内调用 Populate | 性能违规 | Populate 只在冷路径执行 |

---

## §7 热路径隔离约束（Hot-Path Contract）

> 以下约束具有**硬性强制力**，违反即为架构 BUG。

### 7.1 禁止清单

```fortran
! ❌ 禁止：热路径内内存分配
ALLOCATE(tmp_arr(n))  ! FORBIDDEN in hot path

! ❌ 禁止：热路径内多级 SELECT TYPE
SELECT TYPE(desc)
  CLASS IS (MD_{{Abbr}}_Sub1_Desc)
    SELECT TYPE(sub_desc)   ! FORBIDDEN：第二层 SELECT TYPE
    END SELECT
END SELECT

! ❌ 禁止：热路径内值拷贝多态 Desc
local_desc = desc  ! FORBIDDEN：多态类型值拷贝未定义

! ❌ 禁止：热路径内访问 L1 文件 IO
WRITE(unit, *) ...  ! FORBIDDEN in hot path
```

### 7.2 允许清单（热路径合法操作）

```fortran
! ✅ 合法：访问已 Populate 的 Desc 字段
E  = desc%E
nu = desc%nu

! ✅ 合法：读写 State 数组（已分配）
state%stress(1:ntens) = ...

! ✅ 合法：单层 SELECT TYPE（最多 1 级）
SELECT TYPE(desc)
  CLASS IS (MD_{{Abbr}}_Base_Desc)
    CALL compute_core(desc, state, ctx)
END SELECT

! ✅ 合法：指针解引用（无分配开销）
CALL do_work(desc%other_desc)  ! 通过 POINTER 访问
```

### 7.3 性能基准（参考）

| 操作 | 目标耗时 | 测量方法 |
|------|---------|---------|
| 单积分点核心计算 | < {{X}} μs | {{测量工具/方法}} |
| 增量步总 {{DOMAIN_NAME}} 计算 | < {{Y}} ms | {{测量工具/方法}} |

---

## §8 扩展点（Extension Points）

> 本节定义本域支持的多态扩展机制，允许二次开发而不修改内核。

### 8.1 可被派生覆盖的基类

| 基类 TYPE | 可覆盖能力 | 典型扩展场景 |
|----------|----------|------------|
| `MD_{{Abbr}}_Base_Desc` | 扩展静态参数字段 | 用户自定义{{域}}参数 |
| `MD_{{Abbr}}_Base_State` | 扩展内部状态变量 | 增加用户自定义历史变量 |

### 8.2 UEL/UMAT 等效扩展接口

```fortran
! 若本域对应 ABAQUS 用户子程序，此处列出标准接口签名
! 参考：UFC/docs/templates/PH_XXX_{{UMAT|UEL|UINTER|...}}.f90

SUBROUTINE PH_{{Abbr}}_{{UMAT/UEL}}_API(...)
  !-- 遵循 ABAQUS 标准接口参数顺序（向外兼容层）
  !-- 内部立即 pack → UFC TYPE → 调用 PH_{{Abbr}}_Core_Proc
END SUBROUTINE
```

### 8.3 注册机制

```fortran
! 二次开发注册新{{域}}模型的标准流程：
! 1. 派生 MD_{{Abbr}}_Base_Desc，添加专有字段
! 2. 实现 PH_{{Abbr}}_Core_Proc（覆盖或新建）
! 3. 在 {{域}}注册表中注册（ID → Desc 指针映射）
! 4. 在 ABAQUS inp 文件中通过 *User{{Domain}} 关键字引用
```

---

## §9 数据流转简图（Data Flow）

> 本图展示本域的数据在三层之间的完整流转路径。

```
┌─────────────────────────────────────────────────────────────────┐
│                    {{DOMAIN_NAME}} 域数据流转图                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ABAQUS .inp ──[Parser]──▶ MD_{{Abbr}}_Base_Desc (L3, 只读)      │
│                                    │                             │
│                            [Populate 冷路径]                     │
│                                    │                             │
│                                    ▼                             │
│           ┌──────────────── 注册表/槽位指针 ────────────────┐    │
│           │                                               │    │
│           ▼                                               ▼    │
│  PH_{{Abbr}}_Base_Ctx (L4)                   PH_{{Abbr}}_Base_Algo │
│  （增量驱动，热路径）                          （迭代控制，冷路径）│
│           │                                               │    │
│           └──────────────[PH_{{Abbr}}_Core_Proc]──────────┘    │
│                                    │                             │
│                                    ▼                             │
│                   MD_{{Abbr}}_Base_State (L3, 读写)              │
│                   （应力/状态变量，热路径输出）                    │
│                                    │                             │
│                            [RT_WriteBack]                        │
│                                    │                             │
│                                    ▼                             │
│                   RT_{{Abbr}}_Domain_Ctx (L5)                    │
│                   （运行时汇总，传递给求解器/Output域）             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## §10 与其他域的依赖边界（Domain Boundary）

> 本节列出本域与其他域的所有数据交换接口。所有跨域交换**必须通过 CONTRACT.md 接口契约**。

### 10.1 依赖矩阵

| 依赖关系 | 被依赖域 | 交换数据 | 方向 | 路径类型 | CONTRACT 文件 |
|---------|---------|---------|------|---------|--------------|
| {{本域}} 读取 | Section 域 | `MD_Sect_Base_Desc`（截面号→材料指针） | IN | 冷（Populate） | `{{Abbr}}_Section_CONTRACT.md` |
| {{本域}} 写出 | Output 域 | 计算结果（应力/状态变量）| OUT | 热（增量步末） | `{{Abbr}}_Output_CONTRACT.md` |
| {{本域}} 读取 | Bridge 域 | L3→L4 数据桥接 Ctx | IN | 冷 | `Bridge_{{Abbr}}_CONTRACT.md` |

### 10.2 禁止直接依赖

| 禁止依赖的域 | 原因 |
|------------|------|
| L1_IF 以外的基础设施细节 | 只通过 L1 接口访问基础能力 |
| {{高层域（如 L6_AP）}} | 违反依赖铁律（只能向下依赖） |
| {{同层竞争域}} | 同层横向依赖需通过 Bridge 域 |

---

## §11 接口契约索引（CONTRACT.md 链接）

> 与本域相关的所有跨域 CONTRACT.md 文件清单（每条跨域路径独立一份）。

| CONTRACT 文件 | 描述 | 状态 |
|--------------|------|------|
| [`{{Abbr}}_Section_CONTRACT.md`](../contracts/{{Abbr}}_Section_CONTRACT.md) | 本域 ↔ Section 域的数据桥接合同 | {{草稿/定稿}} |
| [`{{Abbr}}_Output_CONTRACT.md`](../contracts/{{Abbr}}_Output_CONTRACT.md) | 本域 → Output 域的结果传递合同 | {{草稿/定稿}} |

---

## §12 验收检查清单（Acceptance Checklist）

> 本域实现合并（Merge）前，所有检查项必须通过。

### 12.1 架构合规

- [ ] §2 中所有 TYPE 已在对应 `*_Types.f90` 中实现
- [ ] §6 中所有公开子程序已实现并符合五参/六参 SIO 签名
- [ ] 热路径子程序无 ALLOCATE/DEALLOCATE
- [ ] Ctx TYPE 无 ALLOCATABLE 字段
- [ ] Desc 只在冷路径（Populate）写入，热路径只读
- [ ] 无跨层违规（如 L4 直接访问 L3 注册表）

### 12.2 命名规范

- [ ] 所有 MODULE 名以层缀（`MD_` / `PH_` / `RT_`）开头
- [ ] 所有 TYPE 名符合 `{层缀}_{域缩写}_{子模型}_{类型后缀}` 规范
- [ ] 无 TODO/FIXME/XXX 残留（或已登记 Issue）

### 12.3 四链完整性

- [ ] §3.1 理论链：物理→数学→离散→计算 完整填写
- [ ] §3.2 逻辑链：Populate → 热路径 → 写回 完整
- [ ] §3.3 计算链：全局→单元→材料 调用层次明确
- [ ] §3.4 数据链：Init → Populate → 热路径 → WriteBack → Finalize 无泄漏

### 12.4 测试

- [ ] 单元测试（Test_MD_{{Abbr}}_Types）通过
- [ ] Patch test 通过（见 `fem-kernel-verification` 技能）
- [ ] 命名规范检查（`ufc-naming-checker`）零错误

---

## 附录 A — 关键词索引

| ABAQUS 关键字 | 对应 UFC 域 TYPE | 对应子程序 |
|-------------|----------------|----------|
| `*{{Keyword1}}` | `MD_{{Abbr}}_Base_Desc%{{field}}` | `MD_{{Abbr}}_Populate_Proc` |
| `*{{Keyword2}}` | `MD_{{Abbr}}_Base_Desc%{{field}}` | `MD_{{Abbr}}_Populate_Proc` |

## 附录 B — 修订历史

| 版本 | 日期 | 修订人 | 主要变更 |
|------|------|-------|---------|
| v{{X.Y}} | {{YYYY-MM-DD}} | {{Name}} | 初始版本 |

---

<!-- 模板版本：DOMAIN_CARD_Template v1.0 | 签发：2026-04-13 -->
<!-- 更新本模板时请同步修订 docs/05_Project_Planning/PPLAN/06_核心架构/ABAQUS_Subroutine_UFC_TYPE_Mapping.md -->
