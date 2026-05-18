# UFC L3/L4/L5 二元重构蓝图规范 v1.0

> **版本**: v1.0 | **日期**: 2026-05-06
> **核心公式**: **数据四型(Desc/State/Algo/Ctx + Args) + 过程三维(空间×时间×动作)**
> **适用范围**: L3_MD, L4_PH, L5_RT 全域柱重构
> **对齐规范**: UFC_Naming_Standard_v2, UFC_DomainModule_v2, UFC_Domain_Module_Inventory_v1；**域名压缩真源**：[`Domain_Compression_Canon.md`](Domain_Compression_Canon.md)（`ufc_core` 各层目录与 P1–P6/H1–H2、IF/NM/AP，不含 `ExternalLibs`）。

---

## 目录

1. [二进制结构总纲](#1-二进制结构总纲)
2. [域柱分类矩阵](#2-域柱分类矩阵)
3. [数据结构规范（四型+Args）](#3-数据结构规范四型args)
4. [算法过程规范（三维）](#4-算法过程规范三维)
5. [Module/文件命名规范](#5-module文件命名规范)
6. [TBP 命名规范](#6-tbp-命名规范)
7. [SIO 封装规范](#7-sio-封装规范)
8. [P1 Material 贯通域柱](#8-p1-material-贯通域柱)
9. [P2 Element 贯通域柱](#9-p2-element-贯通域柱)
10. [P3 Contact/Interaction 贯通域柱](#10-p3-contactinteraction-贯通域柱)
11. [P4 LoadBC 贯通域柱](#11-p4-loadbc-贯通域柱)
12. [P5 Output 贯通域柱](#12-p5-output-贯通域柱)
13. [P6 WriteBack 贯通域柱](#13-p6-writeback-贯通域柱)
14. [H1 Analysis/Solver/Step 半贯通域柱](#14-h1-analysissolverstep-半贯通域柱)
15. [H2 Section 半贯通域柱](#15-h2-section-半贯通域柱)
16. [S1 Assembly 层专属](#16-s1-assembly-层专属)
17. [S2 Mesh 层专属](#17-s2-mesh-层专属)
18. [S3 Bridge 层专属](#18-s3-bridge-层专属)
19. [S4 Model 层专属](#19-s4-model-层专属)
20. [S5 KeyWord 层专属](#20-s5-keyword-层专属)
21. [S6 Field 层专属](#21-s6-field-层专属)
22. [S7 Constraint 层专属](#22-s7-constraint-层专属)
23. [S8 Part 层专属](#23-s8-part-层专属)

---

## 1. 二进制结构总纲

每个功能模块（.f90 文件）的二元结构：

```
功能模块 = 数据结构(四型TYPE + Args) + 算法过程(三维后缀)
```

### 1.1 数据结构维度


| 四型    | 后缀       | 角色      | 生命周期              | INTENT        |
| ----- | -------- | ------- | ----------------- | ------------- |
| Desc  | `_Desc`  | 只读配置    | Write-Once        | INTENT(IN)    |
| State | `_State` | 运行时状态   | Step/Increment 可写 | INTENT(INOUT) |
| Algo  | `_Algo`  | 算法描述符   | 偏静态，从 Desc 派生     | INTENT(IN)    |
| Ctx   | `_Ctx`   | 上下文胶水   | 每步可变              | INTENT(INOUT) |
| Args  | `_Args`  | SIO 参数束 | 单次调用              | INTENT(INOUT) |


### 1.2 算法过程三维


| 维度       | 方向     | 典型后缀                                                                                       | 说明               |
| -------- | ------ | ------------------------------------------------------------------------------------------ | ---------------- |
| **空间维度** | 局部→全局  | `_Loc`, `_Glb`, `_Asm`                                                                     | 单元/IP 级 vs 全局装配级 |
| **时间维度** | 初始化→终结 | `_Init`, `_Step`, `_Incr`, `_Iter`, `_Final`                                               | 生命周期阶段           |
| **动作维度** | 计算→更新  | `_Eval`, `_Update`, `_Assemble`, `_Apply`, `_Sync`, `_Populate`, `_Dispatch`, `_WriteBack` | 具体操作类型           |


### 1.3 三维过程后缀组合

三维后缀可通过 `_` 组合用于子程序名：

```
{Layer}_{Domain}_{Func}_{Spatial}_{Temporal}_{Action}
```


| 组合示例                          | 含义                     |
| ----------------------------- | ---------------------- |
| `MD_Mat_Elas_Init`            | 时间:Init，空间/动作默认        |
| `PH_Elem_Contm_Loc_Eval`      | 空间:Loc，动作:Eval         |
| `PH_Elem_Contm_Loc_Eval_Init` | 空间:Loc，动作:Eval，时间:Init |
| `RT_Asm_Glb_Assemble`         | 空间:Glb，动作:Assemble     |
| `RT_Solv_Nonlin_Iter_Solve`   | 时间:Iter，动作:Solve       |


---

## 2. 域柱分类矩阵

**可执行勾选表（PR 自检 / 不编译）**：[`UFC/docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md`](../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md) — 将本节 P1–P6 与 H1 映射为 G1–G6 检查行与文件指针。

### 2.1 贯通域柱（P1-P6，三层贯通）


| #   | 域柱                  | L3_MD 映射域          | L4_PH 映射域  | L5_RT 映射域  | 主文件数 |
| --- | ------------------- | ------------------ | ---------- | ---------- | ---- |
| P1  | Material            | Material/          | Material/  | Material/  | ~90  |
| P2  | Element             | Elem/      | Element/   | Element/   | ~120 |
| P3  | Contact/Interaction | Interaction/       | Contact/   | Contact/   | ~35  |
| P4  | LoadBC              | Boundary/, LoadBC/ | LoadBC/    | LoadBC/    | ~35  |
| P5  | Output              | Output/            | Output/    | Output/    | ~25  |
| P6  | WriteBack           | WriteBack/         | WriteBack/ | WriteBack/ | ~15  |


### 2.2 半贯通域柱（H1-H2，两层贯通）


| #   | 域柱                   | L3_MD     | L4_PH  | L5_RT                | 主文件数 |
| --- | -------------------- | --------- | ------ | -------------------- | ---- |
| H1  | Analysis/Solver/Step | Analysis/ | Bridge | Solver/, StepDriver/ | ~30  |
| H2  | Section              | Section/  | -      | Section/             | ~15  |


### 2.3 层专属域（S1-S8，单层）


| #   | 域          | L3_MD       | L4_PH       | L5_RT         | 主文件数 |
| --- | ---------- | ----------- | ----------- | ------------- | ---- |
| S1  | Assembly   | Assembly/   | -           | Assembly/     | ~25  |
| S2  | Mesh       | Mesh/       | -           | Element/Mesh/ | ~20  |
| S3  | Bridge     | Bridge/     | Bridge/     | Bridge/       | ~25  |
| S4  | Model      | Model/      | -           | -             | ~20  |
| S5  | KeyWord    | KeyWord/    | -           | -             | ~12  |
| S6  | Field      | Field/      | Field/      | -             | ~12  |
| S7  | Constraint | Constraint/ | Constraint/ | -             | ~15  |
| S8  | Part       | Part/       | -           | -             | ~8   |


---

## 3. 数据结构规范（四型+Args）

### 3.1 主 TYPE 四型 (Primary)

每功能模块的核心四型，命名遵守层缀_域缩_功能_四型格式：

```fortran
! 在 *_Def.f90 文件中
TYPE :: MD_Mat_Elas_Desc     ! 材料弹性只读配置
  TYPE(MD_Mat_Cfg_Init_Desc) :: cfg  ! 配置初始化描述符(辅)
  TYPE(MD_Mat_Pop_Vld_Desc)  :: pop  ! 填充验证描述符(辅)
END TYPE

TYPE :: MD_Mat_Elas_State    ! 材料弹性运行时状态
  REAL(wp), ALLOCATABLE :: stress(:)
  REAL(wp), ALLOCATABLE :: strain(:)
END TYPE

TYPE :: MD_Mat_Elas_Algo     ! 材料弹性算法描述符
  INTEGER(i4) :: integration_scheme
END TYPE

TYPE :: MD_Mat_Elas_Ctx      ! 材料弹性上下文
  REAL(wp) :: time_inc
  REAL(wp) :: temperature
END TYPE
```

### 3.2 辅 TYPE (Auxiliary)

用于主 TYPE 嵌套的子分组，按 Phase x Verb 归组：

```fortran
! 在 *_Aux_Def.f90 文件中
! Phase: Init，Verb: Cfg → Cfg_Init_Desc
TYPE :: MD_Mat_Cfg_Init_Desc
  INTEGER(i4) :: material_id
  INTEGER(i4) :: family_id
  CHARACTER(len=32) :: behavior
END TYPE

! Phase: Populate，Verb: Vld → Pop_Vld_Desc
TYPE :: MD_Mat_Pop_Vld_Desc
  INTEGER(i4) :: n_props
  INTEGER(i4) :: n_statev
END TYPE

! Phase: Increment，Verb: Evo → Inc_Evo_Ctx
TYPE :: MD_Mat_Inc_Evo_Ctx
  REAL(wp) :: dstrain(6)
  REAL(wp) :: dtime
END TYPE

! Phase: Increment，Verb: Acc → Inc_Acc_State
TYPE :: MD_Mat_Inc_Acc_State
  REAL(wp) :: stress(6)
  REAL(wp) :: statev(:), ALLOCATABLE
END TYPE
```

### 3.3 辅 TYPE 命名公式

```
辅TYPE名 = {Phase}{Verb}_{DataKind}
```


| Phase | Verb | DataKind | 示例                      |
| ----- | ---- | -------- | ----------------------- |
| Cfg   | Init | Desc     | `MD_Mat_Cfg_Init_Desc`  |
| Pop   | Vld  | Desc     | `MD_Mat_Pop_Vld_Desc`   |
| Inc   | Evo  | Ctx      | `MD_Mat_Inc_Evo_Ctx`    |
| Inc   | Acc  | State    | `MD_Mat_Inc_Acc_State`  |
| Stp   | Ctl  | Algo     | `PH_Elem_Stp_Ctl_Algo`  |
| Stp   | Evo  | State    | `PH_Elem_Stp_Evo_State` |
| Itr   | Asm  | Ctx      | `PH_Elem_Itr_Asm_Ctx`   |
| Itr   | Acc  | State    | `PH_Elem_Itr_Acc_State` |
| Lcl   | Comp | Ctx      | `PH_Elem_Lcl_Comp_Ctx`  |


### 3.4 Args 参数束

统一参数束 TYPE ，替代 inp/out 对偶：

```fortran
! 例：材料弹性评估 Args
TYPE :: PH_Mat_Elas_Eval_Args
  ! [IN] 应变增量
  REAL(wp) :: dstrain(6)
  ! [IN] 时间增量
  REAL(wp) :: dtime
  ! [OUT] 更新应力
  REAL(wp) :: stress_new(6)
  ! [OUT] 切线刚度矩阵
  REAL(wp) :: ddsdde(6,6)
  ! [OUT] 状态变量
  REAL(wp), ALLOCATABLE :: statev(:)
END TYPE
```

---

## 4. 算法过程规范（三维）

### 4.1 动作维度动词全集

按功能分组，从现有仓库中提炼：


| 组     | 动词                              | 适用层      | 说明     |
| ----- | ------------------------------- | -------- | ------ |
| 生命周期  | Init, Finalize, Create, Destroy | 全层       | 初始化/终结 |
| 生命周期  | Build, Construct, Destruct      | L3/L5    | 构建/析构  |
| 数据操作  | Get, Set                        | 全层       | 查询/设置  |
| 数据操作  | Update, Sync                    | L3/L4    | 更新/同步  |
| 数据操作  | Copy, Clone                     | L3       | 拷贝/深拷贝 |
| 计算评估  | Eval, Compute, Calculate        | L4/L5    | 评估/计算  |
| 计算评估  | Assemble, Solve                 | L4/L5    | 装配/求解  |
| 计算评估  | Integrate, Differentiate        | L4       | 积分/微分  |
| 校验检查  | Validate, Check, Verify         | L3/L4    | 校验/检查  |
| 注册分发  | Register, Unregister, Dispatch  | L3/L5    | 注册/分发  |
| 运行执行  | Run, Execute, Drive             | L5       | 运行/执行  |
| 步进控制  | Step, Advance, Loop             | L5       | 步进/循环  |
| IO持久化 | Read, Write, Parse, Serialize   | L1/L3/L6 | IO 操作  |
| 工具辅助  | Convert, Sort, Search, Find     | L1/L3    | 工具函数   |


### 4.2 空间维度约定


| 空间范围 | 后缀             | 典型出现                | 示例                       |
| ---- | -------------- | ------------------- | ------------------------ |
| 积分点级 | `_IP`          | L4 Material/Element | `PH_Mat_Elas_Eval_IP`    |
| 单元级  | `_Loc`(Local)  | L4 单元计算             | `PH_Elem_Contm_Loc_Eval` |
| 全局级  | `_Glb`(Global) | L5 装配               | `RT_Asm_Glb_Assemble`    |
| 域级   | `_Dom`(Domain) | L5 域协调              | `RT_Asm_Dom_Assemble`    |


### 4.3 时间维度约定


| 时间阶段 | 后缀       | 说明       | 示例                     |
| ---- | -------- | -------- | ---------------------- |
| 初始化  | `_Init`  | 模型/步骤开始前 | `PH_Mat_Elas_Init`     |
| 分析步  | `_Step`  | 步级准备/清理  | `PH_Elem_Step_Prepare` |
| 增量步  | `_Incr`  | 增量步级     | `PH_Elem_Incr_Update`  |
| 迭代步  | `_Iter`  | 平衡迭代级    | `PH_Elem_Iter_Compute` |
| 终结   | `_Final` | 清理资源     | `PH_Mat_Elas_Final`    |


### 4.4 贯通域柱过程后缀


| 域柱        | 空间维度   | 时间维度             | 动作维度                  | 典型后缀                  |
| --------- | ------ | ---------------- | --------------------- | --------------------- |
| Material  | `_IP`  | `_Incr`          | `_Eval`, `_Update`    | `_IP_Incr_Eval`       |
| Element   | `_Loc` | `_Incr`, `_Iter` | `_Eval`, `_Assemble`  | `_Loc_Iter_Eval`      |
| Contact   | `_Dom` | `_Iter`          | `_Search`, `_Eval`    | `_Dom_Iter_Search`    |
| LoadBC    | `_Dom` | `_Incr`          | `_Apply`, `_Assemble` | `_Dom_Incr_Apply`     |
| Output    | `_Glb` | `_Step`, `_Incr` | `_Write`, `_Sync`     | `_Glb_Incr_Write`     |
| WriteBack | `_Dom` | `_Step`          | `_WriteBack`, `_Sync` | `_Dom_Step_WriteBack` |


---

## 5. Module/文件命名规范

### 5.1 通用公式

```
文件名 = {层缀}_{域缩}_{功能}[_{角色后缀}].f90
MODULE名 = 文件名 (不含 .f90)
```

### 5.2 层缀


| 层     | 层缀    | 全称         |
| ----- | ----- | ---------- |
| L3_MD | `MD`_ | Model Data |
| L4_PH | `PH`_ | Physics    |
| L5_RT | `RT`_ | Runtime    |


### 5.3 域缩对照表


| 域           | 域缩       | 出现层      |
| ----------- | -------- | -------- |
| Material    | `Mat`    | L3/L4/L5 |
| Element     | `Elem`   | L3/L4/L5 |
| Contact     | `Cont`   | L4/L5    |
| Interaction | `Int`    | L3       |
| LoadBC      | `LBC`    | L3/L4/L5 |
| Boundary    | `BC`     | L3       |
| Load        | `Load`   | L3       |
| Output      | `Out`    | L3/L4/L5 |
| WriteBack   | `WB`     | L3/L4/L5 |
| Assembly    | `Asm`    | L5       |
| Solver      | `Solv`   | L5       |
| StepDriver  | `Step`   | L5       |
| Section     | `Sect`   | L3/L5    |
| Mesh        | `Mesh`   | L3/L5    |
| Model       | `Model`  | L3       |
| KeyWord     | `KW`     | L3       |
| Field       | `Field`  | L3/L4    |
| Constraint  | `Constr` | L3/L4    |
| Part        | `Part`   | L3       |
| Bridge      | `Brg`    | L3/L4/L5 |
| Analysis    | `Ana`    | L3       |
| Amplitude   | `Amp`    | L3/L5    |


### 5.4 角色后缀闭集


| 角色     | 后缀         | 用途                 | 示例                       |
| ------ | ---------- | ------------------ | ------------------------ |
| 类型定义   | `_Def`     | 四型 TYPE 定义(含常量/枚举) | `MD_Mat_Elas_Def.f90`    |
| 辅类型定义  | `_Aux_Def` | 辅 TYPE 定义          | `PH_Elem_Aux_Def.f90`    |
| 核心实现   | `_Core`    | 核心算法实现             | `PH_Mat_Elas_Core.f90`   |
| 评估入口   | `_Eval`    | 评估/计算入口            | `PH_Mat_Elas_Eval.f90`   |
| 层间桥接   | `_Brg`     | 跨层数据桥接             | `MD_ElemPH_Brg.f90`      |
| SIO 过程 | `_Proc`    | L5 标准过程单元          | `RT_Mat_Proc.f90`        |
| 实现专页   | `_Impl`    | 实现子页面              | `RT_Out_Impl.f90`        |
| 执行专页   | `_Exec`    | 执行子页面              | `RT_Step_Exec.f90`       |
| 管理器    | `_Mgr`     | 门面管理器              | `MD_Elem_Mgr.f90`        |
| 域入口    | `_Domain`  | 域入口薄门面             | `MD_LBC_Domain.f90`      |
| 同步     | `_Sync`    | 双缓冲同步              | `MD_Step_Sync.f90`       |
| 注册表    | `_Reg`     | 静态注册表              | `MD_Elem_Reg.f90`        |
| 索引     | `_Idx`     | 索引图式               | `MD_LBC_Idx.f90`         |
| 库函数    | `_Lib`     | 库函数集               | `MD_Model_Lib.f90`       |
| 工具     | `_Util`    | 工具函数集              | `RT_Asm_Util.f90`        |
| 映射     | `_Map`     | 语义映射               | `MD_Elem_InpMap.f90`     |
| 分派     | `_Dsp`     | 动态分派               | `PH_Elem_FeDispatch.f90` |


### 5.5 文件命名示例


| 层   | 文件名                    | MODULE名            | 说明          |
| --- | ---------------------- | ------------------ | ----------- |
| L3  | `MD_Mat_Def.f90`       | `MD_Mat_Def`       | 材料四型定义      |
| L4  | `PH_Mat_Elas_Def.f90`  | `PH_Mat_Elas_Def`  | 弹性材料定义      |
| L4  | `PH_Mat_Elas_Eval.f90` | `PH_Mat_Elas_Eval` | 弹性评估        |
| L4  | `PH_Mat_Elas_Core.f90` | `PH_Mat_Elas_Core` | 弹性核心实现      |
| L5  | `RT_Mat_Proc.f90`      | `RT_Mat_Proc`      | 材料 SIO 过程   |
| L3  | `MD_Elem_Def.f90`      | `MD_Elem_Def`      | 单元定义        |
| L5  | `RT_Elem_Proc.f90`     | `RT_Elem_Proc`     | 单元 SIO 过程   |
| L3  | `MD_LBC_Def.f90`       | `MD_LBC_Def`       | 载荷边界定义      |
| L4  | `PH_LBC_Def.f90`       | `PH_LBC_Def`       | L4 载荷边界定义   |
| L5  | `RT_LoadBC_Proc.f90`   | `RT_LoadBC_Proc`   | 载荷边界 SIO 过程 |


---

## 6. TBP 命名规范

### 6.1 核心规则

TYPE 内的 TBP **绑定名**一律**短动词**（不加层缀、不把完整 `TYPE` 名再塞进绑定名）。调用侧始终为 `obj%Init`、`obj%ValidateProps` 等形式；**`=>` 右侧是实现过程在模块内的名字**，不是调用名。

**单 `MODULE` 内仅一个带该 TBP 的具体 `TYPE` 时（推荐材料叶子等一文件一型）：**

- 绑定与实现同名：只写 `PROCEDURE :: ValidateProps`，**不要**写 `PROCEDURE :: ValidateProps => ValidateProps`（同语反复）。
- 实现子程序在模块内命名为 `ValidateProps`、`InitFromProps` 等短名；**不必**再导出 `PUBLIC :: MD_*_ValidateProps`（除非确有跨模块直接 `CALL` 需求）。

**同一 `MODULE` 内有多个 `TYPE` 各自需要不同实现体时：**

- 使用 **`PROCEDURE :: 短绑定名 => 实现名`**；实现名**省略层/域前缀**，用 **`{四型角色}_{动词}`** 在模块内唯一，例如 `Desc_Init`、`State_Clean`、`Algo_Init`（见 `RT_LoadBC_Def`）。另有 **Impl** 等并行四型套时加 **`Impl_`**：`Impl_Desc_Init`。
- 并列业务族（Load 与 BC）同现时用 **`Load_Desc_Init`** / **`BC_Desc_Init`**（见 `MD_LBC_Def`）。
- 合同/聚合模块仍可出现长实现名（如 `PH_Mat_Elas_Desc_Init`），新代码优先 **`{角色}_{动词}`** 形式。存量材料族 `*_Mat_*_Def.f90`（L3/L4/L5）可用维护脚本 `UFC/tools/tbp_mat_def_short_impl.py` 与仓库对齐（再跑前请 `git diff` 复核）。

```fortran
! ✅ 单型模块：绑定短名，实现同名，无 =>
TYPE :: MD_Mat_AcoAbsorb_Desc
CONTAINS
  PROCEDURE :: ValidateProps
  PROCEDURE :: InitFromProps
END TYPE
! 同一 MODULE CONTAINS 内：SUBROUTINE ValidateProps(self, ...) … END SUBROUTINE

! ✅ 多型同模块：绑定名仍可全是 Init；实现名用 四型角色_动词（无 RT_/PH_ 前缀）
TYPE :: RT_LoadBC_Desc
CONTAINS
  PROCEDURE :: Init  => Desc_Init
  PROCEDURE :: Clean => Desc_Clean
END TYPE
TYPE :: RT_LoadBC_State
CONTAINS
  PROCEDURE :: Init  => State_Init
  PROCEDURE :: Clean => State_Clean
END TYPE

! ✅ 多型同模块（合同侧）：长名仍允许
TYPE :: PH_Mat_Elas_Desc
CONTAINS
  PROCEDURE :: Init       => PH_Mat_Elas_Desc_Init
  PROCEDURE :: Valid      => PH_Mat_Elas_Desc_Valid
END TYPE

! ❌ 禁止：把长前缀放在「绑定名」上
TYPE :: PH_Mat_Elas_Desc
CONTAINS
  PROCEDURE :: PH_Mat_Elas_Desc_Init  ! ❌
END TYPE
```

### 6.2 常用 TBP 短名表

| 四型    | 典型 TBP 绑定名 | 单型模块内实现名（与绑定可相同） | 多型同模块时实现名（推荐） |
| ----- | -------------- | -------------------------------- | -------------------------- |
| Desc  | `Init`, `Valid`, `ValidateProps`, `InitFromProps`, `RegLayout`, `Ensure`, `Destroy` | 同上 | `Desc_Init`, `Desc_Clean`；或合同内 `PH_Mat_Elas_Desc_Init` |
| State | `Init`, `Update`, `Clean`, `Reset`, `Copy` | 同上 | `State_Init`, `State_Clean` |
| Algo  | `Init`, `Config` | 同上 | `Algo_Init`, `Algo_Valid` |
| Ctx   | `Init`, `Clean`, `Reset` | 同上 | `Ctx_Init`, `Ctx_Clean` |
| Args  | `Init`, `Clean`, `Pack`, `Unpack` | 同上 | `Args_Init`（按模块约定） |


---

## 7. SIO 封装规范

### 7.1 核心原则

1. **统一参数束**：使用单一 `*_Arg` TYPE，不拆为 `inp`/`out` 对偶
2. **方向注释**：在 TYPE 内用 `[IN]` / `[OUT]` / `[INOUT]` 注释标注方向
3. **INTENT 在形参**：子程序签名中写 INTENT（而非 TYPE 定义内）
4. **四型分离**：Desc/State/Algo/Ctx 保持独立形参

### 7.2 五参标准形式

```fortran
SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, args, status)
  TYPE(PH_Mat_Elas_Desc),  INTENT(IN)    :: desc
  TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state
  TYPE(PH_Mat_Elas_Algo),  INTENT(IN)    :: algo
  TYPE(PH_Mat_Elas_Ctx),   INTENT(INOUT) :: ctx
  TYPE(PH_Mat_Elas_Args),  INTENT(INOUT) :: args
  INTEGER,                 INTENT(OUT)   :: status
END SUBROUTINE
```

### 7.3 六参标准形式（含 RT_Com_Base_Ctx）

```fortran
SUBROUTINE RT_Mat_Proc(desc, state, algo, ctx, base_ctx, args, status)
  TYPE(MD_Mat_Desc),        INTENT(IN)    :: desc
  TYPE(MD_Mat_State),       INTENT(INOUT) :: state
  TYPE(MD_Mat_Algo),        INTENT(IN)    :: algo
  TYPE(MD_Mat_Ctx),         INTENT(INOUT) :: ctx
  TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: base_ctx
  TYPE(RT_Mat_Args),        INTENT(INOUT) :: args
  INTEGER,                  INTENT(OUT)   :: status
END SUBROUTINE
```

### 7.4 Args TYPE 模板

```fortran
!===============================================================================
! TYPE: {Domain}_{Feature}_Args
! DESC: Unified argument bundle for {Domain} {Feature} evaluation.
! SIO:  [IN]/[OUT] annotated; replaces inp/out pair.
!===============================================================================
TYPE :: PH_Mat_Elas_Eval_Args
  !--- [IN] fields ---
  REAL(wp) :: dstrain(6)            ! [IN]  strain increment
  REAL(wp) :: dtime                  ! [IN]  time increment
  REAL(wp) :: temp                   ! [IN]  temperature at integration point
  REAL(wp) :: dtemp                  ! [IN]  temperature increment
  TYPE(UF_Kinematics) :: kinematics  ! [IN]  deformation kinematics

  !--- [OUT] fields ---
  REAL(wp) :: stress(6)             ! [OUT] updated Cauchy stress
  REAL(wp) :: ddsdde(6,6)           ! [OUT] tangent stiffness matrix
  REAL(wp) :: sse                   ! [OUT] elastic strain energy
  REAL(wp) :: spd                   ! [OUT] plastic dissipation

  !--- [INOUT] fields ---
  REAL(wp), ALLOCATABLE :: statev(:)  ! [INOUT] state variables
END TYPE
```

### 7.5 迁移对照


| 旧模式                                        | 新模式                                            |
| ------------------------------------------ | ---------------------------------------------- |
| `SUBROUTINE foo(inp, out)`                 | `SUBROUTINE foo(desc, state, algo, ctx, args)` |
| `TYPE :: Foo_In` + `TYPE :: Foo_Out`       | `TYPE :: Foo_Args`（[IN]/[OUT] 注释）              |
| `INTENT(IN) :: inp` + `INTENT(OUT) :: out` | `INTENT(INOUT) :: args`                        |
| inp 和 out 分散字段                             | Args 统一字段                                      |


---

## 8. P1 Material 贯通域柱

### 8.1 三层角色定义


| 层   | 角色     | 核心职责                                   | 数据流向               |
| --- | ------ | -------------------------------------- | ------------------ |
| L3  | 材料模型定义 | 定义 Desc/State/Algo/Ctx; 注册材料模型; 管理材料属性 | → L4 (通过 Populate) |
| L4  | 材料本构计算 | 本构 Eval; 应力更新; 切线刚度计算                  | → L5 (通过 Brg)      |
| L5  | 材料调度   | 材料表管理; 分派到 L4; UMAT/VUMAT 路由           | 协调 L3↔L4           |


### 8.2 子域列表


| 子域        | 域缩         | L3 文件前缀               | L4 文件前缀               | L5 文件前缀           |
| --------- | ---------- | --------------------- | --------------------- | ----------------- |
| Elastic   | `Elas`     | `MD_Mat_Elas_*`       | `PH_Mat_Elas_*`       | `RT_Mat_Elas_*`   |
| Plastic   | `Plast`    | `MD_Mat_Plast_*`      | `PH_Mat_Plast_*`      | `RT_Mat_Plast_*`  |
| HyperElas | `Hyper`    | `MD_Mat_Hyper_*`      | `PH_Mat_Hyper_*`      | `RT_Mat_Hyper_*`  |
| Viscoelas | `Visco`    | `MD_Mat_Visco_*`      | `PH_Mat_Visco_*`      | `RT_Mat_Visco_*`  |
| Creep     | `Creep`    | `MD_Mat_Creep_*`      | `PH_Mat_Creep_*`      | `RT_Mat_Creep_*`  |
| Damage    | `Damage`   | `MD_Mat_Damage_*`     | `PH_Mat_Damage_*`     | `RT_Mat_Damage_*` |
| Thermal   | `Therm`    | `MD_Mat_Therm_*`      | `PH_Mat_Therm_*`      | `RT_Mat_Therm_*`  |
| Acoustic  | `Acou`     | `MD_Mat_Acou_*`       | `PH_Mat_Acou_*`       | `RT_Mat_Acou_*`   |
| Geotech   | `Geo`      | `MD_Mat_Geo_*`        | `PH_Mat_Geo_*`        | `RT_Mat_Geo_*`    |
| Composite | `Comp`     | `MD_Mat_Comp_*`       | `PH_Mat_Comp_*`       | `RT_Mat_Comp_*`   |
| User      | `User`     | `MD_Mat_User_*`       | `PH_Mat_User_*`       | `RT_Mat_User_*`   |
| Registry  | `Reg`      | `MD_Mat_Reg_*`        | `PH_Mat_Reg_*`        | -                 |
| Contract  | `Contract` | `MD_Mat_*_Contract.*` | `PH_Mat_*_Contract.*` | -                 |
| Domain    | `Domain`   | `MD_Mat_Domain_*`     | `PH_Mat_Domain_*`     | -                 |
| Bridge    | `Brg`      | `MD_Mat_Brg_*`        | `PH_Mat_Brg_*`        | `RT_Mat_Brg_*`    |


### 8.3 L3 文件清单（Material）


| 文件                      | MODULE              | 角色     | 说明                  |
| ----------------------- | ------------------- | ------ | ------------------- |
| `MD_Mat_Def.f90`        | `MD_Mat_Def`        | Def    | 四型 TYPE 定义，材料族枚举，常量 |
| `MD_Mat_Elas_Core.f90`  | `MD_Mat_Elas_Core`  | Core   | 弹性材料核心              |
| `MD_Mat_Elas_Def.f90`   | `MD_Mat_Elas_Def`   | Def    | 弹性材料专属 TYPE 定义      |
| `MD_Mat_Plast_Core.f90` | `MD_Mat_Plast_Core` | Core   | 塑性材料核心              |
| `MD_Mat_Domain.f90`     | `MD_Mat_Domain`     | Domain | 材料域入口+容器            |
| `MD_Mat_Mgr.f90`        | `MD_Mat_Mgr`        | Mgr    | 材料管理器               |
| `MD_Mat_Reg.f90`        | `MD_Mat_Reg`        | Reg    | 材料模型注册表             |
| `MD_Mat_Brg.f90`        | `MD_Mat_Brg`        | Brg    | L3→L4 材料桥接          |


### 8.4 L4 文件清单（Material）


| 文件                       | MODULE               | 角色      | 说明           |
| ------------------------ | -------------------- | ------- | ------------ |
| `PH_Mat_Def.f90`         | `PH_Mat_Def`         | Def     | L4 材料四型定义    |
| `PH_Mat_Aux_Def.f90`     | `PH_Mat_Aux_Def`     | Aux_Def | L4 辅 TYPE 定义 |
| `PH_Mat_Domain_Core.f90` | `PH_Mat_Domain_Core` | Core    | 材料槽/容器真源     |
| `PH_Mat_Reg.f90`         | `PH_Mat_Reg`         | Reg     | 内核注册/查找      |
| `PH_Mat_Dispatch.f90`    | `PH_Mat_Dispatch`    | Dsp     | 分派器          |
| `PH_Mat_Core.f90`        | `PH_Mat_Core`        | Core    | 材料核心 facade  |
| `PH_Mat_Elas_Def.f90`    | `PH_Mat_Elas_Def`    | Def     | 弹性 TYPE 定义   |
| `PH_Mat_Elas_Eval.f90`   | `PH_Mat_Elas_Eval`   | Eval    | 弹性评估入口       |
| `PH_Mat_Elas_Core.f90`   | `PH_Mat_Elas_Core`   | Core    | 弹性核心实现       |
| `PH_Mat_Elas_Brg.f90`    | `PH_Mat_Elas_Brg`    | Brg     | 弹性桥接         |


### 8.5 L5 文件清单（Material）


| 文件                     | MODULE             | 角色      | 说明              |
| ---------------------- | ------------------ | ------- | --------------- |
| `RT_Mat_Def.f90`       | `RT_Mat_Def`       | Def     | L5 材料四型定义       |
| `RT_Mat_Aux_Def.f90`   | `RT_Mat_Aux_Def`   | Aux_Def | L5 辅 TYPE 定义    |
| `RT_Mat_Core.f90`      | `RT_Mat_Core`      | Core    | L5 材料核心         |
| `RT_Mat_Brg.f90`       | `RT_Mat_Brg`       | Brg     | L5 材料桥接         |
| `RT_Mat_Elas_Core.f90` | `RT_Mat_Elas_Core` | Core    | 弹性材料 L5 核心      |
| `RT_Mat_Elas_Def.f90`  | `RT_Mat_Elas_Def`  | Def     | 弹性材料 L5 TYPE 定义 |


### 8.6 Material 三维过程后缀


| 过程模板                           | 空间  | 时间    | 动作     | 适用        |
| ------------------------------ | --- | ----- | ------ | --------- |
| `PH_Mat_Elas_Init`             | -   | Init  | -      | 初始化       |
| `PH_Mat_Elas_IP_Incr_Eval`     | IP  | Incr  | Eval   | 积分点增量步评估  |
| `PH_Mat_Elas_IP_Incr_Update`   | IP  | Incr  | Update | 积分点增量步更新  |
| `PH_Mat_Elas_Final`            | -   | Final | -      | 终结清理      |
| `PH_Mat_Dispatch_IP_Incr_Eval` | IP  | Incr  | Eval   | 材料分派评估    |
| `RT_Mat_Proc`                  | -   | -     | Proc   | L5 SIO 过程 |


---

## 9. P2 Element 贯通域柱

### 9.1 三层角色定义


| 层   | 角色      | 核心职责                             |
| --- | ------- | -------------------------------- |
| L3  | 单元定义+注册 | 单元几何/拓扑定义; Element 族枚举; Populate |
| L4  | 单元计算    | 形函数; 积分; Ke/Fe 计算; NLGeom        |
| L5  | 单元调度    | Dispatching; 装配编排; Element_Proc  |


### 9.2 子域列表


| 子域        | L4 目录          | 文件前缀                             | 说明                     |
| --------- | -------------- | -------------------------------- | ---------------------- |
| Continuum | (Element root) | `PH_Elem_Contm_*`                | 连续体单元(Solid2D/Solid3D) |
| Beam      | Beam/          | `PH_Elem_B31_*`, `PH_Elem_B32_*` | 梁单元                    |
| Shell     | Shell/         | `PH_Elem_S4_*`, `PH_Elem_S8_*`   | 壳单元                    |
| Truss     | Truss/         | `PH_Elem_T2D2`, `PH_Elem_T3D2`   | 桁架单元                   |
| Membrane  | Membrane/      | `PH_Elem_M3D*`                   | 膜单元                    |
| Acoustic  | Acoustic/      | `PH_Elem_AC3D*`                  | 声学单元                   |
| Thermal   | Thermal/       | `PH_Elem_HeatTransfer`           | 热传导单元                  |
| Special   | Special/       | `PH_Elem_COH*`, `PH_Elem_Rigid*` | 特殊单元(Cohesive/Rigid)   |
| Spring    | Spring/        | `PH_Elem_SPRING*`                | 弹簧单元                   |
| User      | (UEL)          | `PH_UEL_*`                       | 用户定义单元                 |
| Mass      | (root)         | `PH_Elem_Mass*`                  | 质量单元                   |
| Coupler   | (root)         | `PH_Elem_Coupler`                | 耦合器                    |


### 9.3 单元级四型+Args

```fortran
! --- 主四型 ---
TYPE :: PH_Elem_Desc
  TYPE(PH_Elem_Cfg_Init_Desc) :: cfg  ! 配置
  TYPE(PH_Elem_Pop_Vld_Desc)  :: pop  ! 填充验证
END TYPE

TYPE :: PH_Elem_Ctx
  TYPE(PH_Elem_Itr_Asm_Ctx)  :: itr  ! 迭代装配
  TYPE(PH_Elem_Lcl_Comp_Ctx) :: lcl  ! 局部计算
  TYPE(PH_Elem_Lcl_Evo_Ctx)  :: evo  ! 局部演化
END TYPE

TYPE :: PH_Elem_State
  TYPE(PH_Elem_Stp_Evo_State)  :: stp  ! 步级演化
  TYPE(PH_Elem_Itr_Acc_State)  :: itr  ! 迭代累积
END TYPE

TYPE :: PH_Elem_Algo
  TYPE(PH_Elem_Stp_Ctl_Algo)      :: stp    ! 步控制
  TYPE(PH_Elem_Stp_Ctl_Dyn_Algo)  :: stp_dyn ! 动态步控制(可选)
END TYPE

! --- SIO Arg 类型 ---
TYPE :: PH_Elem_Core_Ke_Arg
  ! [IN]
  INTEGER(i4) :: elem_type
  REAL(wp), ALLOCATABLE :: coords(:,:)
  REAL(wp), ALLOCATABLE :: props(:)
  ! [OUT]
  REAL(wp), ALLOCATABLE :: Ke(:,:)
END TYPE

TYPE :: PH_Elem_Core_Fe_Arg
  ! [IN]
  INTEGER(i4) :: elem_type
  REAL(wp), ALLOCATABLE :: coords(:,:)
  REAL(wp) :: load_magn(PH_ELEM_ASSEMBLY_U_MAX)
  ! [OUT]
  REAL(wp), ALLOCATABLE :: Fe(:)
END TYPE
```

### 9.4 Element 三维过程后缀


| 过程模板                          | 空间  | 时间   | 动作   | 适用      |
| ----------------------------- | --- | ---- | ---- | ------- |
| `PH_Elem_Contm_Loc_Eval`      | Loc | -    | Eval | 连续体单元评估 |
| `PH_Elem_Contm_Loc_Iter_Eval` | Loc | Iter | Eval | 连续体迭代评估 |
| `PH_Elem_ShapeFunc_Eval`      | Loc | -    | Eval | 形函数评估   |
| `PH_Elem_GaussInt_Eval`       | Loc | -    | Eval | 高斯积分    |
| `PH_Elem_KeDispatch_Loc_Eval` | Loc | -    | Eval | 刚度矩阵分派  |
| `PH_Elem_FeDispatch_Loc_Eval` | Loc | -    | Eval | 内力向量分派  |
| `PH_Elem_NLGeom_Loc_Eval`     | Loc | -    | Eval | 非线性几何   |
| `RT_Elem_ComputeProc`         | -   | -    | Proc | L5 计算过程 |
| `RT_Elem_Dispatch_Run`        | -   | -    | Run  | L5 分派运行 |


---

## 10. P3 Contact/Interaction 贯通域柱

### 10.1 三层角色定义


| 层   | 角色             | 核心职责                   | 域缩     |
| --- | -------------- | ---------------------- | ------ |
| L3  | Interaction 定义 | 接触对定义; 面定义; 摩擦参数; 交互属性 | `Int`  |
| L4  | Contact 计算     | 搜索; 法向/切向评估; 摩擦; 热接触   | `Cont` |
| L5  | Contact 调度     | 增广拉格朗日求解; 接触控制; 显式接触   | `Cont` |


### 10.2 L3 Interaction 文件清单


| 文件                  | MODULE          | 角色    |
| ------------------- | --------------- | ----- |
| `MD_Int_Def.f90`    | `MD_Int_Def`    | Def   |
| `MD_Int_Core.f90`   | `MD_Int_Core`   | Core  |
| `MD_Int_Mgr.f90`    | `MD_Int_Mgr`    | Mgr   |
| `MD_Int_Sync.f90`   | `MD_Int_Sync`   | Sync  |
| `MD_Int_Mapper.f90` | `MD_Int_Mapper` | Map   |
| `MD_Int_Parser.f90` | `MD_Int_Parser` | Parse |
| `MD_Cont_Mgr.f90`   | `MD_Cont_Mgr`   | Mgr   |
| `MD_Int_Def.f90`    | `MD_Int_Def`    | Def   |


### 10.3 L4 Contact 文件清单


| 文件                          | MODULE                  | 角色       |
| --------------------------- | ----------------------- | -------- |
| `PH_Cont_Def.f90`           | `PH_Cont_Def`           | Def      |
| `PH_Cont_Core.f90`          | `PH_Cont_Core`          | Core     |
| `PH_Cont_Search.f90`        | `PH_Cont_Search`        | Search   |
| `PH_Cont_Friction.f90`      | `PH_Cont_Friction`      | Friction |
| `PH_Cont_ALM_Core.f90`      | `PH_Cont_ALM_Core`      | Core     |
| `PH_Cont_NTS_Eval.f90`      | `PH_Cont_NTS_Eval`      | Eval     |
| `PH_Cont_Penalty_Core.f90`  | `PH_Cont_Penalty_Core`  | Core     |
| `PH_Cont_Domain.f90`        | `PH_Cont_Domain`        | Domain   |
| `PH_Cont_Expl.f90`          | `PH_Cont_Expl`          | Exec     |
| `PH_Cont_ThermoMech.f90`    | `PH_Cont_ThermoMech`    | Thermo   |
| `PH_Cont_WearEvolution.f90` | `PH_Cont_WearEvolution` | Wear     |


### 10.4 L5 Contact 文件清单


| 文件                       | MODULE               | 角色     |
| ------------------------ | -------------------- | ------ |
| `RT_Cont_Def.f90`        | `RT_Cont_Def`        | Def    |
| `RT_Cont_Core.f90`       | `RT_Cont_Core`       | Core   |
| `RT_Cont_Ctrl.f90`       | `RT_Cont_Ctrl`       | Ctrl   |
| `RT_Cont_AugLagSolv.f90` | `RT_Cont_AugLagSolv` | Solv   |
| `RT_Cont_Search.f90`     | `RT_Cont_Search`     | Search |
| `RT_Cont_Expl.f90`       | `RT_Cont_Expl`       | Exec   |
| `RT_Cont_Brg.f90`        | `RT_Cont_Brg`        | Brg    |


### 10.5 Contact 三维过程后缀


| 过程模板                            | 空间  | 时间   | 动作     | 适用         |
| ------------------------------- | --- | ---- | ------ | ---------- |
| `PH_Cont_Search_Dom_Init`       | Dom | Init | Search | 接触搜索初始化    |
| `PH_Cont_Search_Dom_Iter_Eval`  | Dom | Iter | Eval   | 迭代搜索评估     |
| `PH_Cont_NTS_Eval_Loc_Eval`     | Loc | -    | Eval   | 节点-段评估     |
| `PH_Cont_Friction_Loc_Eval`     | Loc | -    | Eval   | 摩擦评估       |
| `RT_Cont_AugLagSolv_Iter_Solve` | -   | Iter | Solve  | 增广拉格朗日迭代求解 |


---

## 11. P4 LoadBC 贯通域柱

### 11.1 三层角色定义


| 层   | 角色         | 核心职责                           |
| --- | ---------- | ------------------------------ |
| L3  | Load/BC 定义 | 载荷类型; 边界条件类型; 幅值映射; 枚举常量       |
| L4  | LoadBC 计算  | 载荷施加; Dirichlet/Neumann; 面力/体力 |
| L5  | LoadBC 调度  | LoadBC_Proc; 反力计算; 载荷协调        |


### 11.2 L3 文件清单


| 文件                     | MODULE             | 角色        |
| ---------------------- | ------------------ | --------- |
| `MD_LBC_Def.f90`       | `MD_LBC_Def`       | Def       |
| `MD_LBC_Core.f90`      | `MD_LBC_Core`      | Core      |
| `MD_LBC_Mgr.f90`       | `MD_LBC_Mgr`       | Mgr       |
| `MD_LBC_Brg.f90`       | `MD_LBC_Brg`       | Brg       |
| `MD_LBC_Domain.f90`    | `MD_LBC_Domain`    | Domain    |
| `MD_LBC_Idx.f90`       | `MD_LBC_Idx`       | Idx       |
| `MD_LBC_Apply.f90`     | `MD_LBC_Apply`     | Apply     |
| `MD_LBC_Query.f90`     | `MD_LBC_Query`     | Query     |
| `MD_LBC_Container.f90` | `MD_LBC_Container` | Container |
| `MD_LBC_Helper.f90`    | `MD_LBC_Helper`    | Util      |
| `MD_BC_Def.f90`        | `MD_BC_Def`        | Def       |
| `MD_BC_Mgr.f90`        | `MD_BC_Mgr`        | Mgr       |
| `MD_Load_Def.f90`      | `MD_Load_Def`      | Def       |
| `MD_Load_Mgr.f90`      | `MD_Load_Mgr`      | Mgr       |


### 11.3 L4 文件清单


| 文件                            | MODULE                    | 角色     |
| ----------------------------- | ------------------------- | ------ |
| `PH_LBC_Def.f90`              | `PH_LBC_Def`              | Def    |
| `PH_LBC_Core.f90`             | `PH_LBC_Core`             | Core   |
| `PH_LBC_Mgr.f90`              | `PH_LBC_Mgr`              | Mgr    |
| `PH_LBC_FlatToNested.f90`     | `PH_LBC_FlatToNested`     | Util   |
| `PH_LBC_GeostaticAlgo.f90`    | `PH_LBC_GeostaticAlgo`    | Algo   |
| `PH_LBC_Legacy.f90`           | `PH_LBC_Legacy`           | Legacy |
| `PH_Ldbc_Def.f90`             | `PH_Ldbc_Def`             | Def    |
| `PH_Ldbc_Brg.f90`             | `PH_Ldbc_Brg`             | Brg    |
| `PH_Ldbc_Mgr.f90`             | `PH_Ldbc_Mgr`             | Mgr    |
| `PH_Ldbc_SurfaceTraction.f90` | `PH_Ldbc_SurfaceTraction` | Eval   |


### 11.4 L5 文件清单


| 文件                            | MODULE                    | 角色   |
| ----------------------------- | ------------------------- | ---- |
| `RT_LoadBC_Def.f90`           | `RT_LoadBC_Def`           | Def  |
| `RT_LoadBC_Core.f90`          | `RT_LoadBC_Core`          | Core |
| `RT_LoadBC_Proc.f90`          | `RT_LoadBC_Proc`          | Proc |
| `RT_LoadBC_Impl.f90`          | `RT_LoadBC_Impl`          | Impl |
| `RT_LoadBC_ReactionForce.f90` | `RT_LoadBC_ReactionForce` | Eval |
| `RT_LoadBC_Brg.f90`           | `RT_LoadBC_Brg`           | Brg  |


### 11.5 LoadBC 三维过程后缀


| 过程模板                                    | 空间      | 时间   | 动作       |
| --------------------------------------- | ------- | ---- | -------- |
| `PH_LBC_Apply_Dom_Incr_Apply`           | Dom     | Incr | Apply    |
| `PH_LBC_Assemble_Dom_Glb_Assemble`      | Dom→Glb | -    | Assemble |
| `PH_LBC_SurfaceTraction_Loc_Eval`       | Loc     | -    | Eval     |
| `RT_LoadBC_Proc`                        | -       | -    | Proc     |
| `RT_LoadBC_ReactionForce_Dom_Step_Eval` | Dom     | Step | Eval     |


---

## 12. P5 Output 贯通域柱

### 12.1 三层角色定义


| 层   | 角色        | 核心职责                       |
| --- | --------- | -------------------------- |
| L3  | Output 定义 | 输出请求; 场变量注册; 输出频率; 历史输出    |
| L4  | Output 桥接 | 场变量收集; L4→L5 数据桥接          |
| L5  | Output 执行 | ODB/HDF5 写入; 输出调度; Restart |


### 12.2 文件清单


| 层   | 文件                       | MODULE               | 角色      |
| --- | ------------------------ | -------------------- | ------- |
| L3  | `MD_Out_Def.f90`         | `MD_Out_Def`         | Def     |
| L3  | `MD_Out_Mgr.f90`         | `MD_Out_Mgr`         | Mgr     |
| L3  | `MD_Out_Lib.f90`         | `MD_Out_Lib`         | Lib     |
| L3  | `MD_Out_Sync.f90`        | `MD_Out_Sync`        | Sync    |
| L3  | `MD_Out_API.f90`         | `MD_Out_API`         | API     |
| L3  | `MD_Out_Parse.f90`       | `MD_Out_Parse`       | Parse   |
| L3  | `MD_Out_FieldExport.f90` | `MD_Out_FieldExport` | Export  |
| L3  | `MD_Out_VarReg.f90`      | `MD_Out_VarReg`      | Reg     |
| L3  | `MD_OutDP_Brg.f90`       | `MD_OutDP_Brg`       | Brg     |
| L4  | `PH_Out_Def.f90`         | `PH_Out_Def`         | Def     |
| L4  | `PH_Out_Core.f90`        | `PH_Out_Core`        | Core    |
| L4  | `PH_Out_Brg.f90`         | `PH_Out_Brg`         | Brg     |
| L4  | `PH_Out_Mgr.f90`         | `PH_Out_Mgr`         | Mgr     |
| L5  | `RT_Out_Def.f90`         | `RT_Out_Def`         | Def     |
| L5  | `RT_Out_Core.f90`        | `RT_Out_Core`        | Core    |
| L5  | `RT_Out_Proc.f90`        | `RT_Out_Proc`        | Proc    |
| L5  | `RT_Out_Impl.f90`        | `RT_Out_Impl`        | Impl    |
| L5  | `RT_Out_Mgr.f90`         | `RT_Out_Mgr`         | Mgr     |
| L5  | `RT_Out_Brg.f90`         | `RT_Out_Brg`         | Brg     |
| L5  | `RT_Out_Restart.f90`     | `RT_Out_Restart`     | Restart |
| L5  | `RT_Writer_HDF5.f90`     | `RT_Writer_HDF5`     | Writer  |
| L5  | `RT_Writer_ODB.f90`      | `RT_Writer_ODB`      | Writer  |


---

## 13. P6 WriteBack 贯通域柱

### 13.1 三层角色定义


| 层   | 角色           | 核心职责                         |
| --- | ------------ | ---------------------------- |
| L3  | WriteBack 定义 | 回写定义; 域管理; 类型/枚举             |
| L4  | WriteBack 桥接 | L4→L5 数据桥接; WB Init/Manager  |
| L5  | WriteBack 执行 | WB_Proc; WB_Impl; Checkpoint |


### 13.2 文件清单


| 层   | 文件                  | MODULE          | 角色      |
| --- | ------------------- | --------------- | ------- |
| L3  | `MD_WB_Def.f90`     | `MD_WB_Def`     | Def     |
| L3  | `MD_WB_Core.f90`    | `MD_WB_Core`    | Core    |
| L3  | `MD_WB_Domain.f90`  | `MD_WB_Domain`  | Domain  |
| L3  | `MD_WB_Mgr.f90`     | `MD_WB_Mgr`     | Mgr     |
| L3  | `MD_WB_Brg.f90`     | `MD_WB_Brg`     | Brg     |
| L4  | `PH_WB_Def.f90`     | `PH_WB_Def`     | Def     |
| L4  | `PH_WB_Core.f90`    | `PH_WB_Core`    | Core    |
| L4  | `PH_WB_Brg.f90`     | `PH_WB_Brg`     | Brg     |
| L4  | `PH_WB_Mgr.f90`     | `PH_WB_Mgr`     | Mgr     |
| L4  | `PH_WB_Init.f90`    | `PH_WB_Init`    | Init    |
| L5  | `RT_WB_Def.f90`     | `RT_WB_Def`     | Def     |
| L5  | `RT_WB_Core.f90`    | `RT_WB_Core`    | Core    |
| L5  | `RT_WB_Proc.f90`    | `RT_WB_Proc`    | Proc    |
| L5  | `RT_WB_Impl.f90`    | `RT_WB_Impl`    | Impl    |
| L5  | `RT_WB_Domain.f90`  | `RT_WB_Domain`  | Domain  |
| L5  | `RT_WB_Brg.f90`     | `RT_WB_Brg`     | Brg     |
| L5  | `RT_WB_Aux_Def.f90` | `RT_WB_Aux_Def` | Aux_Def |


---

## 14. H1 Analysis/Solver/Step 半贯通域柱

### 14.1 半贯通属性


| 层   | 角色                      | 核心职责                     |
| --- | ----------------------- | ------------------------ |
| L3  | Analysis/Step/Solver 定义 | 分析步定义; 求解器控制; 幅值定义; 耦合定义 |
| L5  | Solver/StepDriver 实现    | 非线性求解; 步进驱动; 时间积分        |


L4 不占据独立域空间（通过 Bridge 间接引用）。

### 14.2 文件清单


| 层   | 域          | 文件                   | 角色     |
| --- | ---------- | -------------------- | ------ |
| L3  | Analysis   | `MD_Ana_Brg.f90`     | Brg    |
| L3  | Analysis   | `MD_Ana_Comp.f90`    | Core   |
| L3  | Step       | `MD_Step_Def.f90`    | Def    |
| L3  | Step       | `MD_Step_Proc.f90`   | Proc   |
| L3  | Step       | `MD_Step_Sync.f90`   | Sync   |
| L3  | Step       | `MD_Step_Mgr.f90`    | Mgr    |
| L3  | Solver     | `MD_Solv_Def.f90`    | Def    |
| L3  | Solver     | `MD_Solv_Mgr.f90`    | Mgr    |
| L3  | Solver     | `MD_Solv_Sync.f90`   | Sync   |
| L3  | Amplitude  | `MD_Amp_Def.f90`     | Def    |
| L3  | Amplitude  | `MD_Amp_Mgr.f90`     | Mgr    |
| L3  | Amplitude  | `MD_Amp_Idx.f90`     | Idx    |
| L3  | Coupling   | `MD_Cpl_Def.f90`     | Def    |
| L3  | Coupling   | `MD_Cpl_Core.f90`    | Core   |
| L5  | Solver     | `RT_Solv_Def.f90`    | Def    |
| L5  | Solver     | `RT_Solv_Core.f90`   | Core   |
| L5  | Solver     | `RT_Solv_Impl.f90`   | Impl   |
| L5  | Solver     | `RT_Solv_Proc.f90`   | Proc   |
| L5  | Solver     | `RT_Solv_Nonlin.f90` | Nonlin |
| L5  | Solver     | `RT_Solv_Lin.f90`    | Lin    |
| L5  | Solver     | `RT_Solv_Brg.f90`    | Brg    |
| L5  | StepDriver | `RT_Step_Def.f90`    | Def    |
| L5  | StepDriver | `RT_Step_Core.f90`   | Core   |
| L5  | StepDriver | `RT_Step_Exec.f90`   | Exec   |
| L5  | StepDriver | `RT_Step_Impl.f90`   | Impl   |
| L5  | StepDriver | `RT_Step_WS.f90`     | Wsp    |
| L5  | StepDriver | `RT_Step_Brg.f90`    | Brg    |


---

## 15. H2 Section 半贯通域柱

### 15.1 半贯通属性


| 层   | 角色         | 核心职责                  |
| --- | ---------- | --------------------- |
| L3  | Section 定义 | 截面定义; 属性库; 质量/惯量; 兼容性 |
| L5  | Section 调度 | 截面桥接                  |


### 15.2 文件清单


| 层   | 文件                    | MODULE            | 角色      |
| --- | --------------------- | ----------------- | ------- |
| L3  | `MD_Sect_Def.f90`     | `MD_Sect_Def`     | Def     |
| L3  | `MD_Sect_Core.f90`    | `MD_Sect_Core`    | Core    |
| L3  | `MD_Sect_Mgr.f90`     | `MD_Sect_Mgr`     | Mgr     |
| L3  | `MD_Sect_Domain.f90`  | `MD_Sect_Domain`  | Domain  |
| L3  | `MD_Sect_Lib.f90`     | `MD_Sect_Lib`     | Lib     |
| L3  | `MD_Sect_Brg.f90`     | `MD_Sect_Brg`     | Brg     |
| L3  | `MD_Sect_Sync.f90`    | `MD_Sect_Sync`    | Sync    |
| L3  | `MD_Sect_Compat.f90`  | `MD_Sect_Compat`  | Compat  |
| L5  | `RT_Sect_Def.f90`     | `RT_Sect_Def`     | Def     |
| L5  | `RT_Sect_Aux_Def.f90` | `RT_Sect_Aux_Def` | Aux_Def |


---

## 16. S1 Assembly 层专属


| 层   | 文件                                | MODULE                        | 角色       |
| --- | --------------------------------- | ----------------------------- | -------- |
| L3  | `MD_Asm_Inst.f90`                 | `MD_Asm_Inst`                 | Instance |
| L3  | `MD_Asm_Mgr.f90`                  | `MD_Asm_Mgr`                  | Mgr      |
| L3  | `MD_Asm_Sync.f90`                 | `MD_Asm_Sync`                 | Sync     |
| L5  | `RT_Asm_Def.f90`                  | `RT_Asm_Def`                  | Def      |
| L5  | `RT_Asm_Core.f90`                 | `RT_Asm_Core`                 | Core     |
| L5  | `RT_Asm_Proc.f90`                 | `RT_Asm_Proc`                 | Proc     |
| L5  | `RT_Asm_Impl.f90`                 | `RT_Asm_Impl`                 | Impl     |
| L5  | `RT_Asm_Global.f90`               | `RT_Asm_Global`               | Glb      |
| L5  | `RT_Asm_Domain.f90`               | `RT_Asm_Domain`               | Domain   |
| L5  | `RT_Asm_DofMap.f90`               | `RT_Asm_DofMap`               | Map      |
| L5  | `RT_Asm_Solv.f90`                 | `RT_Asm_Solv`                 | Solv     |
| L5  | `RT_Asm_Mgr.f90`                  | `RT_Asm_Mgr`                  | Mgr      |
| L5  | `RT_Asm_Util.f90`                 | `RT_Asm_Util`                 | Util     |
| L5  | `RT_Asm_MassDamp.f90`             | `RT_Asm_MassDamp`             | MassDamp |
| L5  | `RT_Asm_NLGeomDispatch.f90`       | `RT_Asm_NLGeomDispatch`       | Dsp      |
| L5  | `RT_Asm_NLGeomEval.f90`           | `RT_Asm_NLGeomEval`           | Eval     |
| L5  | `RT_Asm_ShapeBeam.f90`            | `RT_Asm_ShapeBeam`            | Shape    |
| L5  | `RT_Asm_ShapeMech2D.f90`          | `RT_Asm_ShapeMech2D`          | Shape    |
| L5  | `RT_Asm_ShapeMembrane.f90`        | `RT_Asm_ShapeMembrane`        | Shape    |
| L5  | `RT_Asm_ShapeShell.f90`           | `RT_Asm_ShapeShell`           | Shape    |
| L5  | `RT_Asm_ShapeScalarField.f90`     | `RT_Asm_ShapeScalarField`     | Shape    |
| L5  | `RT_Asm_ShapeMechanicalField.f90` | `RT_Asm_ShapeMechanicalField` | Shape    |
| L5  | `RT_Asm_Brg.f90`                  | `RT_Asm_Brg`                  | Brg      |
| L5  | `RT_Asm_Execute.f90`              | `RT_Asm_Execute`              | Exec     |
| L5  | `RT_Asm_Color.f90`                | `RT_Asm_Color`                | Color    |


---

## 17. S2 Mesh 层专属


| 层   | 文件                          | MODULE                  | 角色       |
| --- | --------------------------- | ----------------------- | -------- |
| L3  | `MD_Mesh_Def.f90`           | `MD_Mesh_Def`           | Def      |
| L3  | `MD_Mesh_Core.f90`          | `MD_Mesh_Core`          | Core     |
| L3  | `MD_Mesh_Domain.f90`        | `MD_Mesh_Domain`        | Domain   |
| L3  | `MD_Mesh_Mgr.f90`           | `MD_Mesh_Mgr`           | Mgr      |
| L3  | `MD_Mesh_API.f90`           | `MD_Mesh_API`           | API      |
| L3  | `MD_Mesh_Sync.f90`          | `MD_Mesh_Sync`          | Sync     |
| L3  | `MD_Mesh_Data.f90`          | `MD_Mesh_Data`          | Data     |
| L3  | `MD_Mesh_Node.f90`          | `MD_Mesh_Node`          | Node     |
| L3  | `MD_Mesh_Elem.f90`          | `MD_Mesh_Elem`          | Elem     |
| L3  | `MD_Mesh_Topo.f90`          | `MD_Mesh_Topo`          | Topo     |
| L3  | `MD_Mesh_NodeDef.f90`       | `MD_Mesh_NodeDef`       | Def      |
| L3  | `MD_Mesh_Search.f90`        | `MD_Mesh_Search`        | Search   |
| L3  | `MD_Mesh_GlobalNum.f90`     | `MD_Mesh_GlobalNum`     | Num      |
| L3  | `MD_Elem_Def.f90`           | `MD_Elem_Def`           | Def      |
| L3  | `MD_Elem_Domain.f90`        | `MD_Elem_Domain`        | Domain   |
| L3  | `MD_Elem_Mgr.f90`           | `MD_Elem_Mgr`           | Mgr      |
| L3  | `MD_Elem_Reg.f90`           | `MD_Elem_Reg`           | Reg      |
| L3  | `MD_Elem_Populate.f90`      | `MD_Elem_Populate`      | Pop      |
| L3  | `MD_Elem_Validate.f90`      | `MD_Elem_Validate`      | Validate |
| L3  | `MD_Elem_PHBinding.f90` | `MD_Elem_PHBinding` | Brg      |
| L3  | `MD_Elem_InpMap.f90`        | `MD_Elem_InpMap`        | Map      |
| L3  | `MD_Elem_Family.f90`        | `MD_Elem_Family`        | Family   |
| L3  | `MD_Elem_UEL_Def.f90`       | `MD_Elem_UEL_Def`       | Def      |
| L3  | `MD_DOF_Impl.f90`           | `MD_DOF_Impl`           | Impl     |
| L3  | `MD_DOF_Mgr.f90`            | `MD_DOF_Mgr`            | Mgr      |


---

## 18. S3 Bridge 层专属


| 层   | 文件                        | MODULE                | 角色     | 说明          |
| --- | ------------------------- | --------------------- | ------ | ----------- |
| L3  | `MD_ConstraintPH_Brg.f90` | `MD_ConstraintPH_Brg` | Brg    | L3约束→L4桥接   |
| L3  | `MD_ContPH_Brg.f90`       | `MD_ContPH_Brg`       | Brg    | L3接触→L4桥接   |
| L3  | `MD_ElemPH_Brg.f90`       | `MD_ElemPH_Brg`       | Brg    | L3单元→L4桥接   |
| L3  | `MD_GeomPH_Brg.f90`       | `MD_GeomPH_Brg`       | Brg    | L3几何→L4桥接   |
| L3  | `MD_LBCPH_Brg.f90`        | `MD_LBCPH_Brg`        | Brg    | L3载荷BC→L4桥接 |
| L3  | `MD_MatLibPH_Brg.f90`     | `MD_MatLibPH_Brg`     | Brg    | L3材料→L4桥接   |
| L3  | `MD_AssemRT_Brg.f90`      | `MD_AssemRT_Brg`      | Brg    | L3装配→L5桥接   |
| L3  | `MD_ContRT_Brg.f90`       | `MD_ContRT_Brg`       | Brg    | L3接触→L5桥接   |
| L3  | `MD_ElemRT_Brg.f90`       | `MD_ElemRT_Brg`       | Brg    | L3单元→L5桥接   |
| L3  | `MD_Int_Brg.f90`          | `MD_Int_Brg`          | Brg    | L3交互桥接      |
| L3  | `MD_LBCRT_Brg.f90`        | `MD_LBCRT_Brg`        | Brg    | L3载荷BC→L5桥接 |
| L3  | `MD_Mesh_Brg.f90`         | `MD_Mesh_Brg`         | Brg    | L3网格→L5桥接   |
| L3  | `MD_ModelRT_Brg.f90`      | `MD_ModelRT_Brg`      | Brg    | L3模型→L5桥接   |
| L3  | `MD_Model_Brg.f90`        | `MD_Model_Brg`        | Brg    | L3模型内部桥接    |
| L3  | `MD_Out_Brg.f90`          | `MD_Out_Brg`          | Brg    | L3输出桥接      |
| L3  | `MD_UIRT_Brg.f90`         | `MD_UIRT_Brg`         | Brg    | L3 UI桥接     |
| L3  | `MD_UniFldRT_Brg.f90`     | `MD_UniFldRT_Brg`     | Brg    | L3 统一场桥接    |
| L3  | `MD_KWRT_Brg.f90`         | `MD_KWRT_Brg`         | Brg    | L3 关键字→L5桥接 |
| L4  | `PH_Brg_Def.f90`          | `PH_Brg_Def`          | Def    | L4 桥接定义     |
| L4  | `PH_Brg_Domain.f90`       | `PH_Brg_Domain`       | Domain | L4 桥接域      |
| L4  | `PH_Brg_L2.f90`           | `PH_Brg_L2`           | Brg    | L4→L2桥接     |
| L4  | `PH_Brg_L3.f90`           | `PH_Brg_L3`           | Brg    | L4→L3桥接     |
| L5  | `RT_Brg_Def.f90`          | `RT_Brg_Def`          | Def    | L5 桥接定义     |
| L5  | `RT_Brg_Mgr.f90`          | `RT_Brg_Mgr`          | Mgr    | L5 桥接管理     |
| L5  | `RT_Shared_Def.f90`       | `RT_Shared_Def`       | Def    | 共享类型定义      |


---

## 19. S4 Model 层专属


| 文件                        | MODULE                | 角色       |
| ------------------------- | --------------------- | -------- |
| `MD_Model_Def.f90`        | `MD_Model_Def`        | Def      |
| `MD_Model_Core.f90`       | `MD_Model_Core`       | Core     |
| `MD_Model_Mgr.f90`        | `MD_Model_Mgr`        | Mgr      |
| `MD_Model_Data.f90`       | `MD_Model_Data`       | Data     |
| `MD_Model_Tree.f90`       | `MD_Model_Tree`       | Tree     |
| `MD_Model_Builder.f90`    | `MD_Model_Builder`    | Build    |
| `MD_Model_Access.f90`     | `MD_Model_Access`     | Access   |
| `MD_Model_CoordSys.f90`   | `MD_Model_CoordSys`   | CoordSys |
| `MD_Model_Lib.f90`        | `MD_Model_Lib`        | Lib      |
| `MD_Model_Types.f90`      | `MD_Model_Types`      | Types    |
| `MD_Model_DomBrg.f90`     | `MD_Model_DomBrg`     | Brg      |
| `MD_BaseTypes.f90`        | `MD_BaseTypes`        | Def      |
| `MD_Base_Def.f90`         | `MD_Base_Def`         | Def      |
| `MD_Base_Enums.f90`       | `MD_Base_Enums`       | Def      |
| `MD_Base_ObjModel.f90`    | `MD_Base_ObjModel`    | Core     |
| `MD_Base_DataModMgr.f90`  | `MD_Base_DataModMgr`  | Mgr      |
| `MD_Base_ElemLib.f90`     | `MD_Base_ElemLib`     | Lib      |
| `MD_Base_TreeIndex.f90`   | `MD_Base_TreeIndex`   | Idx      |
| `MD_Base_FieldVarMgr.f90` | `MD_Base_FieldVarMgr` | Mgr      |
| `MD_Base_IOSerialMgr.f90` | `MD_Base_IOSerialMgr` | Mgr      |
| `MD_Base_MathUtils.f90`   | `MD_Base_MathUtils`   | Util     |


---

## 20. S5 KeyWord 层专属


| 文件                               | MODULE                       | 角色       |
| -------------------------------- | ---------------------------- | -------- |
| `MD_KW_Def.f90`                  | `MD_KW_Def`                  | Def      |
| `MD_KW_Core.f90`                 | `MD_KW_Core`                 | Core     |
| `MD_KW_Parser.f90`               | `MD_KW_Parser`               | Parse    |
| `MD_KW_Lexer.f90`                | `MD_KW_Lexer`                | Lexer    |
| `MD_KW_Dispatch.f90`             | `MD_KW_Dispatch`             | Dsp      |
| `MD_KW_Reg.f90`                  | `MD_KW_Reg`                  | Reg      |
| `MD_KW_Mapper.f90`               | `MD_KW_Mapper`               | Map      |
| `MD_KW_MemPool.f90`              | `MD_KW_MemPool`              | Pool     |
| `MD_KW_Abaqus.f90`               | `MD_KW_Abaqus`               | Abaqus   |
| `MD_KeyWord_Def.f90`             | `MD_KeyWord_Def`             | Def      |
| `MD_KeyWord_Domain.f90`          | `MD_KeyWord_Domain`          | Domain   |
| `MD_KeyWord_Validator.f90`       | `MD_KeyWord_Validator`       | Validate |
| `MD_KeyWord_ParserRecursive.f90` | `MD_KeyWord_ParserRecursive` | Parse    |
| `MD_Inp_Parse.f90`               | `MD_Inp_Parse`               | Parse    |
| `MD_KWAP_Brg.f90`                | `MD_KWAP_Brg`                | Brg      |
| `MD_KW_Reg_Ext.f90`              | `MD_KW_Reg_Ext`              | Reg      |


---

## 21. S6 Field 层专属


| 层   | 文件                             | MODULE                     | 角色          |
| --- | ------------------------------ | -------------------------- | ----------- |
| L3  | `MD_Field_Def.f90`             | `MD_Field_Def`             | Def         |
| L3  | `MD_Field_Mgr.f90`             | `MD_Field_Mgr`             | Mgr         |
| L4  | `PH_Field_Def.f90`             | `PH_Field_Def`             | Def         |
| L4  | `PH_Field_Ops.f90`             | `PH_Field_Ops`             | Ops         |
| L4  | `PH_Field_ComputeTemp.f90`     | `PH_Field_ComputeTemp`     | Compute     |
| L4  | `PH_Field_ComputePore.f90`     | `PH_Field_ComputePore`     | Compute     |
| L4  | `PH_Field_ComputeConc.f90`     | `PH_Field_ComputeConc`     | Compute     |
| L4  | `PH_Field_Cpl.f90`             | `PH_Field_Cpl`             | Cpl         |
| L4  | `PH_Field_ShapeFunc.f90`       | `PH_Field_ShapeFunc`       | Shape       |
| L4  | `PH_Field_GaussQuadrature.f90` | `PH_Field_GaussQuadrature` | Gauss       |
| L4  | `PH_Field_Interpolate.f90`     | `PH_Field_Interpolate`     | Interpolate |


---

## 22. S7 Constraint 层专属


| 层   | 文件                          | MODULE                  | 角色       |
| --- | --------------------------- | ----------------------- | -------- |
| L3  | `MD_Constr_Def.f90`         | `MD_Constr_Def`         | Def      |
| L3  | `MD_Constr_Mgr.f90`         | `MD_Constr_Mgr`         | Mgr      |
| L3  | `MD_Constr_Brg.f90`         | `MD_Constr_Brg`         | Brg      |
| L3  | `MD_Constr_Sync.f90`        | `MD_Constr_Sync`        | Sync     |
| L3  | `MD_Constr_Prop.f90`        | `MD_Constr_Prop`        | Prop     |
| L4  | `PH_Constr_Def.f90`         | `PH_Constr_Def`         | Def      |
| L4  | `PH_Constr_Core.f90`        | `PH_Constr_Core`        | Core     |
| L4  | `PH_Constr_Domain.f90`      | `PH_Constr_Domain`      | Domain   |
| L4  | `PH_Constr_MPC.f90`         | `PH_Constr_MPC`         | MPC      |
| L4  | `PH_Constr_Tie.f90`         | `PH_Constr_Tie`         | Tie      |
| L4  | `PH_Constr_Period.f90`      | `PH_Constr_Period`      | Period   |
| L4  | `PH_Constr_Embedded.f90`    | `PH_Constr_Embedded`    | Embedded |
| L4  | `PH_ConstrMPC_Def.f90`      | `PH_ConstrMPC_Def`      | Def      |
| L4  | `PH_ConstrMPC_Brg.f90`      | `PH_ConstrMPC_Brg`      | Brg      |
| L4  | `PH_ConstrTie_Def.f90`      | `PH_ConstrTie_Def`      | Def      |
| L4  | `PH_ConstrTie_Brg.f90`      | `PH_ConstrTie_Brg`      | Brg      |
| L4  | `PH_ConstrPeriod_Def.f90`   | `PH_ConstrPeriod_Def`   | Def      |
| L4  | `PH_ConstrPeriod_Brg.f90`   | `PH_ConstrPeriod_Brg`   | Brg      |
| L4  | `PH_ConstrEmbedded_Def.f90` | `PH_ConstrEmbedded_Def` | Def      |
| L4  | `PH_ConstrEmbedded_Brg.f90` | `PH_ConstrEmbedded_Brg` | Brg      |


---

## 23. S8 Part 层专属


| 文件                 | MODULE         | 角色   |
| ------------------ | -------------- | ---- |
| `MD_Part_Core.f90` | `MD_Part_Core` | Core |
| `MD_Part_Def.f90`  | `MD_Part_Def`  | Def  |
| `MD_Part_Mgr.f90`  | `MD_Part_Mgr`  | Mgr  |
| `MD_Part_Brg.f90`  | `MD_Part_Brg`  | Brg  |
| `MD_Part_Sync.f90` | `MD_Part_Sync` | Sync |
| `MD_Geom_Def.f90`  | `MD_Geom_Def`  | Def  |
| `MD_Sets_Def.f90`  | `MD_Sets_Def`  | Def  |
| `MD_Sets_Mgr.f90`  | `MD_Sets_Mgr`  | Mgr  |


---

## 附录 A：域柱重构执行步骤速查

对每个域柱，按以下 8 步执行：


| 步骤  | 操作      | 产出                                | 检查项                        |
| --- | ------- | --------------------------------- | -------------------------- |
| 1   | 域合同审计   | 四型缺口清单                            | 对照 CONTRACT.md             |
| 2   | 数据结构重设计 | 主/辅四型 + Args TYPE 定义              | 四型完整；Args 无 inp/out        |
| 3   | 算法过程映射  | 三维过程清单                            | 每个子程序有空间×时间×动作             |
| 4   | 文件重构    | 按规范重命名/分割 f90                     | 命名检查器通过                    |
| 5   | TBP 实现  | 单型模块：`PROCEDURE :: ValidateProps` + 同名 `SUBROUTINE`；多型模块：`=>` 唯一实现名 | 禁止绑定名堆长前缀；禁止 `=>` 同语反复 |
| 6   | SIO 迁移  | 用 Args 替换 inp/out 对               | 无 inp/out 哑元               |
| 7   | 三层数据流   | L3→L4→L5 贯通检查                     | Populate/Eval/WriteBack 完整 |
| 8   | 语法验证    | gfortran -std=f2003 -fsyntax-only | 零错误                        |


## 附录 B：命名检查清单

- 所有 MODULE 名以层缀开头 (`MD`*/`PH`*/`RT`_)
- 所有 TYPE 名以层缀开头
- 子程序名以层缀开头（**模块级外部 API**；**TBP 实现体短名**见 §6：单型模块 `ValidateProps`/`Init` 等例外）
- 四型后缀 (`_Desc`/`_State`/`_Algo`/`_Ctx`) **仅用于 TYPE**
- 四型后缀 **不在** `.f90` 文件名或 `MODULE` 名中出现
- `_Ops` 后缀用于存量；新文件用精确后缀
- PascalCase 用于 MODULE/TYPE/PROCEDURE 名
- TBP 短名（不包含层缀_域缩前缀）
- Args TYPE 内使用 `[IN]`/`[OUT]` 注释
- 无 `inp`/`out` 对偶哑元
- 精度声明使用 `USE IF_Prec, ONLY: wp, i4`

---

*冷归档全文：`UFC/REPORTS/archive/UFC_L3L4L5_二元重构蓝图规范_v1.0.md`。入口 stub：`UFC/REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md`。*
