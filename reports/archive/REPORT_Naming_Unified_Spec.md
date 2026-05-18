# UFC 命名规范合订 (Unified Naming Specification)

**报告 ID**: `REP-NAMING-UNIFIED`
**版本**: v1.2 | **日期**: 2026-05-08
**性质**: 合并 `REPORT_Naming_Quad_OnePager_FiveScenes.md` + `FourKind_MasterAux_Nesting_Design_Spec.md` + 现有域合同命名实践，形成统一的 UFC 命名规范。
**覆盖**: 域缩、层缀、四型、文件/模块/子程序/类型命名、五场景(S0-S4)、SIO *_Arg

**域名压缩权威全表**（`ufc_core` 各层目录与 P1–P6/H1–H2、IF/NM/AP 对齐，不含 `ExternalLibs`）：[`Domain_Compression_Canon.md`](Domain_Compression_Canon.md)。本节表格为速查；冲突以 Canon + 域 `CONTRACT.md` 为准。

**SSOT**：编码命名硬约束见仓库 `rules/ufc-naming.mdc`；开发者叙事见 `docs/02_Developer_Guide/`。本文件为命名合订研讨稿；与上两者冲突时以上两者为准。报告与 `docs/` 分工见 [`SSOT_AND_DEDUP_POLICY.md`](SSOT_AND_DEDUP_POLICY.md)。

---

## 1. 域缩与层缀 (Domain Abbreviation + Layer Prefix)

### 1.1 域缩标准表 (R-10 贯彻)

| 域柱 | 中文 | 域缩 | 域柱类型 | L3 示例 | L4 示例 | L5 示例 |
|------|------|------|----------|---------|---------|---------|
| Material | 材料 | **Mat** | 全贯通(P1) | `MD_Mat_Desc` | `PH_Mat_Slot` | `RT_Mat_Algo` |
| Element | 单元 | **Elem** | 全贯通(P2) | `MD_Elem_Desc` | `PH_Elem_Domain` | `RT_Elem_Dispatcher` |
| Contact/Interaction | 接触 | **Cont** | 全贯通(P3) | `MD_Cont_Desc` | `PH_Cont_Domain` | `RT_Cont_Solv` |
| LoadBC | 载荷/BC | **LoadBC** | 全贯通(P4) | `MD_LoadBC_*` / `MD_LBC_*`；分项 `MD_Load_*`、`MD_BC_*` | `PH_Load_*` / `PH_BC_*` / `PH_LoadBC_*` | `RT_Load_*` / `RT_BC_*` / `RT_LoadBC_*` |
| Output | 输出 | **Out** | 半贯通(P5) | `MD_Out_Def` | (无L4独立域) | `RT_Out_Mgr` |
| WriteBack | 写回 | **WB** | 半贯通(P6) | `MD_WB_Desc` | (无L4独立域) | `RT_WB_Domain` |
| Analysis | 分析 | **Step/Solv/Amp/Cpl** | 复合半柱 | `MD_Step_Mgr` | (无L4) | `RT_StepDriver` |
| Section | 截面 | **Sect** | 正交维 | `MD_Sect_Desc` | 嵌入Elem | `RT_Elem_Sect` |
| Constraint | 约束 | **Constr** | 子域 | `MD_Constr_Desc` | `PH_Constr_Domain` | `RT_Constr_Enforce` |
| KeyWord | 关键字 | **KW** | 冷路径 | `MD_KW_Def` | — | — |
| Mesh | 网格 | **Mesh** | 冷路径 | `MD_Mesh_Def` | — | — |
| Coupling | 耦合 | **Cpl** | 子域 | `MD_Cpl_Desc` | — | — |

**规则 R-10a**: 域缩 **全大写开头 + 小写续**（例：`LoadBC` 而非 `LDBC`，`Cont` 而非 `CONTACT`）。

### 1.2 层缀标准

| 层 | 代号 | 文件前缀 | 说明 |
|----|------|----------|------|
| L0_LF | Infrastructure | `LF_` | 基础设施层 |
| L1_IO | I/O | `IO_` | 输入输出 |
| L2_DA | Data | `DA_` | 数据访问 |
| L3_MD | Model | **`MD_`** | 模型定义层（冷真源 SSOT） |
| L4_PH | Physics | **`PH_`** | 物理内核层（热路径） |
| L5_RT | Runtime | **`RT_`** | 运行时编排层 |

---

## 2. 四型命名规则 (Four-Type Naming)

### 2.1 主四型并列 (R-01/R-09)

```fortran
! 标准四型槽 (Slot/Domain Hub)
TYPE :: {Layer}_{Domain}_Slot
  TYPE({Layer}_{Domain}_Desc)  :: desc   ! 定义/SSOT
  TYPE({Layer}_{Domain}_State) :: state  ! 运行时数据
  TYPE({Layer}_{Domain}_Algo)  :: algo   ! 控制/策略
  TYPE({Layer}_{Domain}_Ctx)   :: ctx    ! 上下文
END TYPE
```

**规则 R-09（去 Base）**: L3/L4 基类四型名 **不** 带 `Base` 后缀。

| 禁止 (BAD) | 正确 (GOOD) |
|-----------|-------------|
| `MD_Elem_Desc` | `MD_Elem_Desc` |
| `MD_Sect_Desc` | `MD_Sect_Desc` |
| `PH_Elem_State` | `PH_Elem_State` |
| `RT_Out_Desc` | `RT_Out_Desc` |

**规则 R-01**: 一个 Hub 内只认一套顶层 `desc/ctx/state/algo` 并列；禁止辅块升格为第五顶层。

### 2.2 辅(嵌套)四型命名 (R-02)

**命名公式**: `{Layer}_{Domain}_{Phase}_{Verb}_{FourKind}`

| Phase | Verb | 语义 | 示例 |
|-------|------|------|------|
| **Cfg** | Init | 配置初始化 | `PH_Mat_Cfg_Init_Desc` |
| **Pop** | Vld | Populate 校验 | `PH_Mat_Pop_Vld_Desc` |
| **Inc** | Evo | 增量演化 | `PH_Mat_Inc_Evo_Ctx` |
| **Itr** | Asm | 迭代组装 | `PH_Elem_Itr_Asm_Ctx` |
| **Lcl** | Comp | 局部计算 | `PH_Mat_Lcl_Comp_Ctx` |
| **Lcl** | Evo | 局部演化 | `PH_Mat_Lcl_Evo_State` |
| **Stp** | Ctl | 步控制 | `PH_Mat_Stp_Ctl_Algo` |

**规则 R-02**: 辅只嵌套；新语义优先落入已有主柱下辅 TYPE，Depth <= 2 cap。

### 2.2.1 Desc 扁平投影 / Pilot View（R-02a，例外）

当 TYPE 表示对 **权威** `{Layer}_{Domain}_Desc` 的 **逻辑扁平切片**（常为 pilot：剔除 `ALLOCATABLE`/变长载荷等，使 DP 固定偏移或分区读写仍锚在同一 Desc 真源），允许采用：

```text
{Layer}_{Domain}_Desc_{Phase}_View
```

- **`Phase`**：与 §2.2 表语义对齐的切片维度（常用 **`Cfg`** / **`Itr`**），表示「从 Desc 上取哪一类字段子集」，**不**再强行填入 **Verb** 槽位。
- **后缀 `View`**：标明 **非** 独立 SSOT，仅是 Desc 的投影；不得与 Hub 顶层四型并列 Writable。
- **配套过程**：建议前缀与 TYPE 一致，例如 `MD_Amp_Desc_Get_Cfg_View`、`MD_Amp_Desc_Apply_Itr_View`。
- **示例**：`MD_Amp_Desc_Cfg_View`、`MD_Amp_Desc_Itr_View`、`MD_Amp_Desc_Pilot_Views`（聚合 cfg∥itr）。

若域柱优先 **Strict R-02（FourKind 殿后）**，可选用 `{Layer}_{Domain}_{Phase}_View_{FourKind}`（如 `MD_Amp_Cfg_View_Desc`）；**同一域柱勿混用两种切片范式**，并在域 `CONTRACT.md` 写明选型。

### 2.3 族扩展命名

**命名公式**: `{Layer}_{Domain}[_{Family}]_{FourKind}` 或 `{Layer}_{Domain}[_{Family}]_{Phase}_{Verb}_{FourKind}`

| 示例 | 说明 |
|------|------|
| `MD_Mat_Elas_Desc` | 材料-弹性族-A Desc |
| `MD_Elem_Solid3D_Desc` | 单元-三维实体族 Desc |
| `PH_Mat_Plast_Execute` | 材料-塑性族-执行子程序 |

---

## 3. 文件与模块命名规则

### 3.1 文件命名模板

```
{层缀}{域缩}_{角色}[_{后缀}].f90
```

**角色（Role）一览**:

| 角色 | 命名段 | 说明 | 示例 |
|------|--------|------|------|
| Def | `_Def` | 类型定义(TYPE) | `MD_Mat_Def.f90` |
| Mgr | `_Mgr` | 管理/注册 | `MD_KW_Reg.f90` |
| Proc | `_Proc` | 过程/算法 | `PH_Mat_Execute_Proc.f90` |
| Brg | `_Brg` | 层间桥接 | `MD_MatPH_Brg.f90` |
| Reg | `_Reg` | 注册中心 | `MD_KW_Reg.f90` |
| Ifc | `_Ifc` | 抽象接口 | `PH_Mat_Constitutive_Ifc.f90` |
| Arg | `_Arg` | SIO 参数包 | `PH_Mat_Update_Arg.f90` |
| Ctx | `_Ctx` | 上下文 | `RT_Step_Ctx.f90` |
| Svc | `_Svc` | 服务/工具 | `MD_Mesh_Svc.f90` |

**规则**: 文件名应唯一且自描述。避免使用泛名如 `utils.f90`。

### 3.2 MODULE 命名

MODULE 名 = 文件名（去 `.f90` 扩展），保持 **大写+下划线**：

```fortran
MODULE MD_Mat_Def     ! == MD_Mat_Def.f90
MODULE PH_Elem_Def    ! == PH_Elem_Def.f90
MODULE RT_KW_Reg_Ext  ! == RT_KW_Reg_Ext.f90
```

### 3.3 TYPE 命名

**主四型**: `{Layer}_{Domain}_{FourKind}` — 如 `PH_Mat_Desc`, `MD_Elem_State`

**辅四型**: `{Layer}_{Domain}_{Phase}_{Verb}_{FourKind}` — 如 `PH_Mat_Inc_Evo_Ctx`

**族 TYPE**: `{Layer}_{Domain}_{Family}_{FourKind}` — 如 `MD_Mat_Elas_Desc`

**扩展 TYPE** (EXTENDS): `{Layer}_{Domain}_{Family}_{Specific}_{FourKind}` — 如 `MD_Mat_Elas_Isotrop_Desc`

### 3.4 SUBROUTINE / FUNCTION 命名

**命名公式**: `{层缀}{域缩}_{动词语义}[_{场景}]`

| 场景 | 动词语义 | 示例 |
|------|---------|------|
| S0 注册 | `Register` / `Init` | `MD_KW_Registry_Init` |
| S0 定义 | `Create` / `Set` | `MD_Mat_Create_Desc` |
| S1 Populate | `Populate` / `Fill` | `PH_L4_Populate_Material` |
| S2 局部 | `Get` / `Update` / `Eval` | `PH_Mat_GetCtx_Idx` |
| S3 Dispatch | `Dispatch` | `RT_Mat_Dispatch_Stress` |
| S4 Execute | `Execute` / `Compute` / `Apply` | `PH_Mat_Execute_Flow` |
| W WriteBack | `WriteBack` / `Sync` | `MD_WB_Brg_WriteBack` |

**规则**: 动词在前，名词在后，与 TYPE 命名相反。

---

## 4. 五场景命名 (S0-S4 场景映射)

### 4.1 场景定义 (源自 FiveScenes §3)

| 场景 | 名称 | 一句话 | 典型落点 |
|------|------|--------|----------|
| **S0** | 冷真源/定义与注册 | L3 持 SSOT；步内只读 | `MD_*_Def`, `MD_*_Reg`, 域 Desc |
| **S1** | Populate | L3->L4 灌槽/缓存；不与 Newton 内环混写 | `PH_L4_Populate_*`, `MD_*PH_Brg` |
| **S2** | 热输入/局部上下文 | 步内写 ctx、增量、索引绑定；经窄 *_Arg | `*%ctx%lcl*`, `PH_*_Update_args` |
| **S3** | Dispatch (薄) | L5 校验+查表+路由；不持大数组主源 | `RT_*_Dispatch_*`, `RT_*_Brg_MakeCtx` |
| **S4** | Execute/Hook | L4 物理核或用户子程序；主写入 state/装配缓冲 | `PH_*_Execute*`, `PH_UMAT_*`, `PH_UEL_*` |

### 4.2 场景与文件命名映射

```
S0: MD_{域缩}_Def.f90, MD_{域缩}_Reg.f90
S1: PH_L4_Populate_{域缩}.f90, MD_{域缩}PH_Brg.f90
S2: PH_{域缩}_[Phase]_[Verb]_[FourKind].f90
S3: RT_{域缩}_Dispatch.f90, RT_{域缩}_Brg.f90
S4: PH_{域缩}_Execute*.f90, PH_UMAT_*.f90, PH_UEL_*.f90
W:  MD_WB_Brg.f90, RT_WB_Domain.f90
```

### 4.3 冷热路径对照

```
冷路径 (C*): S0(定义) -> S1(Populate)   -> L4 缓存就绪
热路径 (H*): S2(局部准备) -> S3(Dispatch) -> S4(Execute) -> W(写回)
                         \-> 步末 Output/WriteBack
```

---

## 5. SIO — `*_Arg` 命名规则 (Principle #14)

### 5.1 命名公式

```
{层缀}{域缩}_{动词语义}_Arg
```

| 示例 | 说明 |
|------|------|
| `PH_Mat_Update_Arg` | 材料更新参数包 |
| `PH_Elem_Core_Arg` | 单元核心计算参数包 |
| `PH_Cont_Detect_Arg` | 接触检测参数包 |
| `PH_LoadBC_Apply_Arg`（或存量 `PH_Ldbc_Apply_Arg`） | 载荷施加参数包 |

### 5.2 SIO 子程序签名公式

**五参**（标准 _Proc）:

```fortran
SUBROUTINE {Domain_Verb}_Proc(desc, state, algo, ctx, args)
  TYPE({Domain}_Desc),  INTENT(IN)    :: desc
  TYPE({Domain}_State), INTENT(INOUT) :: state
  TYPE({Domain}_Algo),  INTENT(IN)    :: algo
  TYPE({Domain}_Ctx),   INTENT(INOUT) :: ctx
  TYPE({Domain}_Arg),   INTENT(INOUT) :: args
END SUBROUTINE
```

**六参**（涉及 RT_Com_Base_Ctx 的场景）:

```fortran
SUBROUTINE {Domain_Verb}_Proc(rt_base, desc, state, algo, ctx, args)
  TYPE(RT_Com_Base_Ctx), INTENT(INOUT) :: rt_base
  TYPE({Domain}_Desc),   INTENT(IN)    :: desc
  TYPE({Domain}_State),  INTENT(INOUT) :: state
  TYPE({Domain}_Algo),   INTENT(IN)    :: algo
  TYPE({Domain}_Ctx),    INTENT(INOUT) :: ctx
  TYPE({Domain}_Arg),    INTENT(INOUT) :: args
END SUBROUTINE
```

### 5.3 Arg 内禁嵌四类 (R-03 bis)

*_Arg TYPE **不得** 内嵌完整的 Desc/State/Algo/Ctx 四型，仅可包含 **扁参数 + POINTER 索引**。四类主数据经形参直接传递。

---

## 6. 命名规则汇总 (评审一票否决)

| ID | 规则 | 来源 |
|----|------|------|
| R-01 | 主四型只认一套顶层 `desc/ctx/state/algo` 并列 | OnePager |
| R-02 | 辅只嵌套；新语义优先落入已有主柱下辅 TYPE | OnePager |
| R-03 | 热边界优先 `枢纽+索引`；禁 L4/L5 30+ 扁参 | OnePager |
| R-04 | ABI_Flat != 四型 Ctx | Design Spec |
| R-05 | L5 不持步内大数组主源 | OnePager |
| R-06 | 禁止双主源 | OnePager |
| R-07 | SIO: 跨边界用 `*_Arg`；避免薄 Arg | OnePager |
| R-08 | 截面主挂载二选一写死于合同 | OnePager |
| R-09 | 去 `Base`：L3/L4 基类不带 `Base` 后缀 | Design Spec |
| R-10 | 域缩统一：Sect/Cont/LoadBC/Out/WB | Design Spec |
| R-11 | 截面单类型：L3 截面域只保留一套基类 Desc | Design Spec |
| R-12 | Algo TYPE 双重语义：结构槽+算法容器 | Design Spec |
| R-13 | Procedure Pointer 显式声明 | Design Spec |

---

## 7. 原文档互链

| 原文档 | 关系 | 方向 |
|--------|------|------|
| `REPORT_Naming_Quad_OnePager_FiveScenes.md` | 本规范取代其 §3(场景) + §5(模板) | 旧→新 |
| `FourKind_MasterAux_Nesting_Design_Spec.md` | 本规范吸收其 §2(命名) + §8(规则) | 旧→新 |
| `OnePager_FourKind_MasterAux_Nesting.md` | 本规范扩展其命名模板 | 互补 |
| `Keyword_Parameter_Catalog.md` | 参考本规范 §1 域缩命名 | 本规范→目录 |
| `Domain_Compression_Canon.md` | `ufc_core`（不含 ExternalLibs）各域 **`DomainAbbr`** 全表；文件名第二段真源 | 与本 §1 互链 |

---

> **END** — UFC Unified Naming Specification v1.1

*冷归档全文：`UFC/REPORTS/archive/REPORT_Naming_Unified_Spec.md`。入口 stub：`UFC/REPORTS/REPORT_Naming_Unified_Spec.md`。*
