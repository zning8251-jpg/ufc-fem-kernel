---
name: ufc-structured-io
description: "UFC Principle #14 结构化 IO 可执行技能。新建/校验 L5_RT _Proc：统一 *_Arg（[IN]/[OUT] 注释）+ 五参 (desc,state,algo,ctx,args) 或六参 (+RT_Com_Base_Ctx,args)；弃用 inp/out 对偶（遗留模块对照 R-01b）。含 INTENT 禁令、*_Arg 禁嵌四类、Harness SIO-01~14 速查、迁移与域推广矩阵。触发：structured-io、Principle #14、_Proc.f90、*_Arg、五参六参、SIO 检查、迁移_Proc。"
---

# UFC Structured IO（Principle #14）可执行技能

## 何时使用

| 场景 | 触发条件 |
|------|----------|
| 新建域 _Proc 模块 | 用户说「为 XX 域生成 _Proc.f90」「新建结构化 IO 接口」 |
| 接口合规校验 | 用户说「检查 _Proc.f90 是否符合规范」「有无违规 INTENT」 |
| 旧接口迁移 | 用户说「两参数 → 四型 + args」「inp/out → *_Arg」「迁移 _Structure 后缀」 |
| Harness 规则查询 | 用户说「SIO 检查清单」「Harness 规则」 |
| 域推广进度 | 用户说「Element/Contact/StepDriver 域推广」 |

---

## 第一步：加载上下文

执行前**必读**以下文档（按需），不得跳过：

1. **规范主文档**：
   [`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md`](../../../docs/05_Project_Planning/PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md)
   > 重点阅读：第 3 章（与 **R-01** 对齐：**五参/六参 + `*_Arg`**）、第 6 章（热路径六禁令）、第 11 章（SIO-01~14）、第 13 章（域推广矩阵）。若主文档仍写 `inp`/`out` 对偶，**新建代码**以本技能 **R-01** 与 **`UFC/docs/templates`** 为准。

2. **已完成基准实现**（对照参考）：
   - Assembly 域：[`UFC/ufc_core/L5_RT/Assembly/RT_Asm_Proc.f90`](../../../UFC/ufc_core/L5_RT/Assembly/RT_Asm_Proc.f90)
   - LoadBC 域：[`UFC/ufc_core/L5_RT/LoadBC/RT_LoadBC_Proc.f90`](../../../UFC/ufc_core/L5_RT/LoadBC/RT_LoadBC_Proc.f90)
   - Solver 域（v2.0）：[`UFC/ufc_core/L5_RT/Solver/RT_Solv_Proc.f90`](../../../UFC/ufc_core/L5_RT/Solver/RT_Solv_Proc.f90)
   - Material 域（v2.0）：[`UFC/ufc_core/L5_RT/Material/RT_Mat_Proc.f90`](../../../UFC/ufc_core/L5_RT/Material/RT_Mat_Proc.f90)

3. **域专属 Types 文件**（生成 _Proc 前确认四大类 TYPE 名）：
   目标域的 `RT_XXX_Types.f90`（同目录）

4. **统一 IO 模板**（与规范一致的首选骨架）：
   [`UFC/docs/templates/`](../../../UFC/docs/templates/) 下 `RT_XXX_Load_Proc.f90`、`RT_XXX_Mat_Proc.f90`、`RT_XXX_Output_Proc.f90`、`RT_XXX_StepDriver_Proc.f90` 等 — **`*_Arg` + `args` 哑元**，非 `inp`/`out`。

---

## 第二步：标准签名与统一 IO 核心规则

### 规则 R-01：标准签名 — 五参 / 六参 + 单一 `args`（`*_Arg`）

**设计哲学**：每次调用的输入与输出集中在**一个**派生类型 `TYPE(RT_XXX_OpName_Arg)`（哑元名常用 `args`）；字段方向用注释 **`[IN]` / `[OUT]` / `[INOUT]`** 标明（**不在 TYPE 体内写 INTENT**）。**新代码禁止** `inp` / `out` **两个 IO 哑元**。

**五参形式**（无跨域增量上下文形参时）：

```fortran
SUBROUTINE RT_XXX_OpName_Interface(desc, state, algo, ctx, args)
  TYPE(RT_XXX_Base_Desc),    INTENT(INOUT) :: desc
  TYPE(RT_XXX_Base_State),   INTENT(INOUT) :: state
  TYPE(RT_XXX_Base_Algo),    INTENT(IN)    :: algo
  TYPE(RT_XXX_Base_Ctx),     INTENT(INOUT) :: ctx
  TYPE(RT_XXX_OpName_Arg),   INTENT(INOUT) :: args
END SUBROUTINE
```

**六参形式**（L5_RT 与 `RT_Com_Types` 对齐：第五参为增量/时间簿记）：

```fortran
SUBROUTINE RT_XXX_OpName_Interface(desc, state, algo, ctx, RT_Com_Ctx, args)
  TYPE(RT_XXX_Base_Desc),    INTENT(INOUT) :: desc
  TYPE(RT_XXX_Base_State),   INTENT(INOUT) :: state
  TYPE(RT_XXX_Base_Algo),    INTENT(IN)    :: algo
  TYPE(RT_XXX_Base_Ctx),     INTENT(INOUT) :: ctx
  TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
  TYPE(RT_XXX_OpName_Arg),   INTENT(INOUT) :: args
END SUBROUTINE
```

- `desc` / `state` / `algo` / `ctx`：四类角色，语义不变。
- `RT_Com_Ctx`（仅六参）：`RT_Com_Base_Ctx`，通常 **INTENT(IN)**（只读或读为主）。
- `args`：本操作**唯一** IO bundle；常规 **`INTENT(INOUT)`**（读 [IN] 段、写 [OUT] 段）。`args` 内须含 **`TYPE(ErrorStatusType) :: status`**（见 R-04）。

### 规则 R-01b（遗留对照）：`inp` / `out` 对偶 — 仅存量兼容

**新建模块、新 ABSTRACT INTERFACE、新文档模板不得使用。** 迁移时合并为 `*_Arg` 后删除对偶。

```fortran
! @deprecated — 新代码勿用
SUBROUTINE RT_XXX_OpName_Legacy(desc, state, algo, ctx, inp, out)
  TYPE(RT_XXX_Base_Desc),    INTENT(INOUT) :: desc
  TYPE(RT_XXX_Base_State),   INTENT(INOUT) :: state
  TYPE(RT_XXX_Base_Algo),    INTENT(IN)    :: algo
  TYPE(RT_XXX_Base_Ctx),     INTENT(INOUT) :: ctx
  TYPE(RT_XXX_OpName_In),    INTENT(IN)    :: inp
  TYPE(RT_XXX_OpName_Out),   INTENT(OUT)   :: out
END SUBROUTINE
```

### 规则 R-02：TYPE 成员 INTENT 禁令（P-02）

**Fortran TYPE 定义体内的成员字段不支持 INTENT 属性。** INTENT 仅合法于子程序/函数虚参。

```fortran
! ❌ 违规 — 编译错误
TYPE :: RT_XXX_Init_In
  TYPE(RT_XXX_Base_Desc), INTENT(INOUT) :: desc   ! 非法
  REAL(wp), INTENT(IN) :: val                      ! 非法
END TYPE

! ✅ 合规
TYPE :: RT_XXX_Init_In
  REAL(wp) :: val = 0.0_wp
END TYPE
```

### 规则 R-03：`*_Arg` TYPE 禁止嵌入四大类（P-09）

`RT_XXX_OpName_Arg`（及遗留 `_In`）中**不得**内嵌 Desc/State/Algo/Ctx 四类字段，它们已作为独立形参传递：

```fortran
! ❌ 违规
TYPE :: RT_XXX_Init_Arg
  TYPE(RT_XXX_Base_Desc) :: desc    ! 重复传递 → 状态不一致风险
  TYPE(RT_XXX_Base_Algo) :: algo    ! 同上
END TYPE

! ✅ 合规：*_Arg 只含本操作特有标量/标志/小数组 + [OUT] 结果段
TYPE, PUBLIC :: RT_XXX_Init_Arg
  !-- [IN]
  INTEGER(i4) :: mode    = 0_i4
  LOGICAL     :: verbose = .FALSE.
  !-- [OUT]
  LOGICAL               :: initialized = .FALSE.
  TYPE(ErrorStatusType) :: status
END TYPE
```

### 规则 R-04：`*_Arg` 必须含 ErrorStatusType（[OUT] 段）

```fortran
TYPE, PUBLIC :: RT_XXX_OpName_Arg
  !-- [IN]  … 驱动字段 …
  !-- [OUT]
  TYPE(ErrorStatusType) :: status         ! 必须
  LOGICAL               :: success = .FALSE.
  ! CHARACTER 消息可挂在 status%message（IF_Err_API 约定）或域内冗余字段
END TYPE
```

### 规则 R-05：`[IN]` 注释区禁止 ALLOCATABLE；`[OUT]` 区 ALLOCATABLE 慎用

与旧「_In 禁 ALLOCATABLE」一致：标注为输入角色的字段不用 **ALLOCATABLE**；输出区仅在确有必要时使用动态内存（热路径仍应避免）。

---

## 第三步：新建 _Proc 模块——标准骨架（统一 `*_Arg`）

```fortran
!===============================================================================
! Module: RT_XXX_Proc                                                    [v2.1]
! Layer: L5_RT - Runtime Layer
! Domain: XXX
!
! UFC Principle #14：四型 + 单一 args（合并原 inp/out 为 *_Arg）
!   (desc, state, algo, ctx, args)                    ← 默认
!   (desc, state, algo, ctx, RT_Com_Ctx, args)        ← 可选：域规范要增量上下文时
!===============================================================================
MODULE RT_XXX_Proc
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_ERROR
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx    ! 可选；仅六参接口时需要
  USE RT_XXX_Types, ONLY: RT_XXX_Base_Desc, RT_XXX_Base_State, &
                           RT_XXX_Base_Algo, RT_XXX_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  ! Unified IO types (one per operation)
  PUBLIC :: RT_XXX_Init_Arg
  ! ... 其余操作各一个 *_Arg ...
  PUBLIC :: RT_XXX_Init_Interface
  ! ...

  !----------------------------------------------------------------------
  ! RT_XXX_Init_Arg — [IN]/[OUT] 用注释区分；TYPE 体内无 INTENT
  !----------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Init_Arg
    !-- [IN]
    INTEGER(i4) :: mode    = 0_i4
    LOGICAL     :: verbose = .FALSE.
    !-- [OUT]
    LOGICAL               :: initialized = .FALSE.
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success = .FALSE.
  END TYPE RT_XXX_Init_Arg

  !----------------------------------------------------------------------
  ! Abstract interface — 五参为默认；若需 RT_Com_Ctx 则在 ctx 与 args 间插入形参
  !----------------------------------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE RT_XXX_Init_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_XXX_Base_Desc, RT_XXX_Base_State
      IMPORT :: RT_XXX_Base_Algo, RT_XXX_Base_Ctx
      IMPORT :: RT_XXX_Init_Arg
      TYPE(RT_XXX_Base_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_XXX_Base_State), INTENT(INOUT) :: state
      TYPE(RT_XXX_Base_Algo),  INTENT(IN)    :: algo
      TYPE(RT_XXX_Base_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_XXX_Init_Arg),   INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

END MODULE RT_XXX_Proc
```

---

## 第四步：合规性校验流程

对已有 `RT_XXX_Proc.f90` 执行以下检查（按顺序）：

### 检查 C-01：TYPE 体内无 INTENT

```bash
# 扫描 TYPE 定义体内的 INTENT（合规应为 0 结果，除 ABSTRACT INTERFACE 内）
grep -n "INTENT(" RT_XXX_Proc.f90
# 然后确认所有 INTENT( 行均在 SUBROUTINE/ABSTRACT INTERFACE 块内，不在 TYPE...END TYPE 内
```

**判定**：在 `TYPE, PUBLIC :: ...` 到 `END TYPE` 之间出现 `INTENT(` → 违规 P-02

### 检查 C-02：`*_Arg`（或遗留 `_In`）未嵌入四大类

```bash
grep -A 40 "TYPE.*_Arg" RT_XXX_Proc.f90 | grep -E "Base_Desc|Base_State|Base_Algo|Base_Ctx"
# 遗留模块可并行扫 _In
grep -A 30 "TYPE.*_In$" RT_XXX_Proc.f90 | grep -E "Base_Desc|Base_State|Base_Algo|Base_Ctx"
```

**判定**：任何结果 → 违规 P-09

### 检查 C-03：抽象接口为五参或六参，且末参为 `args`

```bash
grep -A 12 "ABSTRACT INTERFACE" RT_XXX_Proc.f90 | grep "SUBROUTINE.*Interface"
```

**判定**：

- **新规范**：接口须为 **`desc, state, algo, ctx, args`**（五参）或 **`desc, state, algo, ctx, RT_Com_Ctx, args`**（六参）；**不得**再以 `inp, out` 收尾。
- **遗留**：仍可见 `inp, out` 的模块 → 标记为待迁移（R-01b）。

### 检查 C-04：`*_Arg`（或遗留 `_Out`）含 ErrorStatusType

```bash
grep -B 30 "END TYPE.*_Arg" RT_XXX_Proc.f90 | grep "ErrorStatusType"
grep -B 20 "END TYPE.*_Out" RT_XXX_Proc.f90 | grep "ErrorStatusType"
```

**判定**：每个操作的 IO TYPE 块无 `ErrorStatusType` → 违规

---

## 第五步：迁移操作

### 路径 A：旧两参数 → 四型 + `args`（推荐终点）

**Step A1 — 剥离输入 TYPE 中的四大类字段**（若曾塞进 `_In`）

```fortran
! 修复前
TYPE :: RT_XXX_Init_In
  TYPE(RT_XXX_Base_Desc), INTENT(INOUT) :: desc   ! 移出为形参
  INTEGER(i4) :: mode = 0_i4
END TYPE

! 修复后（合并为 *_Arg 前可先保留 _In 字段集）
TYPE, PUBLIC :: RT_XXX_Init_Arg
  !-- [IN]
  INTEGER(i4) :: mode = 0_i4
  !-- [OUT] 见 A3
END TYPE
```

**Step A2 — 清除 TYPE 体内所有 INTENT**（P-02）

**Step A3 — 合并 `_In` + `_Out` → `RT_XXX_OpName_Arg`**

- 原 `_In` 字段 → 标 `[IN]`；原 `_Out` 字段 → 标 `[OUT]`；**`status` / `success` 放在 [OUT] 段**。

**Step A4 — 用 `args` 替换 `inp`/`out` 对偶（升级 `ABSTRACT INTERFACE`）**

迁移的**本质**是：旧版 **`inp` + `out` 两个哑元** → **一个 `args`（`*_Arg`）**；形参个数仍是 **四型 + IO**，只是把「两半 IO」收成 **一块**。**不必**为了合并 IO 而强行改成六参；**五参 `(desc, state, algo, ctx, args)`** 就是最常见的落点。

```fortran
! 目标形态（五参 — 与「inp/out → args」直接对应）
ABSTRACT INTERFACE
  SUBROUTINE RT_XXX_Init_Interface(desc, state, algo, ctx, args)
    IMPORT :: RT_XXX_Base_Desc, RT_XXX_Base_State, RT_XXX_Base_Algo, RT_XXX_Base_Ctx
    IMPORT :: RT_XXX_Init_Arg
    TYPE(RT_XXX_Base_Desc),  INTENT(INOUT) :: desc
    TYPE(RT_XXX_Base_State), INTENT(INOUT) :: state
    TYPE(RT_XXX_Base_Algo),  INTENT(IN)    :: algo
    TYPE(RT_XXX_Base_Ctx),   INTENT(INOUT) :: ctx
    TYPE(RT_XXX_Init_Arg),   INTENT(INOUT) :: args
  END SUBROUTINE
END INTERFACE
```

若**同一域**的规范还要求传入 **`RT_Com_Base_Ctx`**（例如 L5_RT 与 StepDriver/载荷等对齐），再在 **`ctx` 与 `args` 之间**插入第五哑元 **`RT_Com_Ctx`**，得到 **六参** —— 这是**额外上下文**，不是合并 `inp`/`out` 所必需的：

```fortran
! 可选：六参（四型 + RT_Com_Ctx + args）
SUBROUTINE RT_XXX_Init_Interface(desc, state, algo, ctx, RT_Com_Ctx, args)
  ...
END SUBROUTINE
```

### 路径 B：已四型 + `inp`/`out` → 四型 + `args`（去掉对偶）

将 `inp%*` / `out%*` 访问改为 **`args%*`**；删除 `RT_XXX_OpName_In` / `_Out` TYPE 定义；接口**至少**变为 **四型 + `args`（五参）**；需要时再按上节加 **`RT_Com_Ctx`**。

### 路径 C（遗留对照）：两参数 → 四型 + `inp`/`out`

仅当**短期无法合并 Arg** 时作为过渡；随后仍应执行路径 B。

```fortran
! 过渡：六参数 + inp/out（R-01b）— 新模块勿新增
SUBROUTINE RT_XXX_Init_Interface(desc, state, algo, ctx, inp, out)
  ...
END SUBROUTINE
```

### 迁移检查清单

- [ ] TYPE 体内无任何 `INTENT(...)` 属性
- [ ] `*_Arg`（或过渡 `_In`）不含 Desc/State/Algo/Ctx 字段
- [ ] `*_Arg`（或 `_Out`）含 `TYPE(ErrorStatusType) :: status`
- [ ] `[IN]` 段无 ALLOCATABLE（R-05）
- [ ] 所有 `ABSTRACT INTERFACE` 为 **五参或六参**，末参为 **`args`**（非 `inp`/`out`，除非遗留待迁）
- [ ] `USE` 含 `RT_Com_Types`（若采用六参）
- [ ] `PUBLIC` 导出各操作的 `*_Arg` 与接口名
- [ ] 调用方已改为传入 `args`（及可选 `RT_Com_Ctx`）

---

## 第六步：SIO Harness 检查规则速查（SIO-01~14）

| ID | 规则 | 检查方式 |
|----|------|----------|
| SIO-01 | _Proc 模块存在 | `search_file RT_XXX_Proc.f90` |
| SIO-02 | 每操作有 **`*_Arg`**（新）；遗留可为 _In/_Out 对 | grep `TYPE.*_Arg`；遗留 grep _In/_Out |
| SIO-03 | `*_Arg`（或 _Out）含 ErrorStatusType | grep ErrorStatusType in *_Arg / _Out |
| SIO-04 | ABSTRACT INTERFACE 完整 | grep ABSTRACT INTERFACE 计数 == 操作数 |
| SIO-05 | `*_Arg` 的 **[IN] 段**无 ALLOCATABLE | grep ALLOCATABLE in 对应 TYPE 块 |
| SIO-06 | Ctx 无 ALLOCATABLE | grep ALLOCATABLE in Ctx 字段 |
| SIO-07 | 热路径无 I/O | grep WRITE/READ in hot-path subroutines |
| SIO-08 | 热路径无 ALLOCATE | grep ALLOCATE in hot-path |
| SIO-09 | 命名含操作词 | **`RT_XXX_OpName_Arg`**（新）；遗留 `OpName_In/Out` |
| SIO-10 | IMPORT 完整 | ABSTRACT INTERFACE 内 IMPORT 含所有类型 |
| SIO-11 | TYPE 体内无 INTENT | grep INTENT( 后验证均在 SUBROUTINE 块内 |
| SIO-12 | 接口为 **五参或六参** | **末参 `args`**；六参时第五参 **`RT_Com_Base_Ctx`**；遗留 `inp,out` 标待迁移 |
| SIO-13 | `*_Arg` / `_In` 无四大类内嵌 | grep Base_* in 对应 TYPE 块 → 应为 0 |
| SIO-14 | 版本注释更新 | 头部注释含 **[v2.1]** 或更高 / 注明统一 `*_Arg` |

---

## 第七步：域推广优先级与状态矩阵

当前 L5_RT 全域合规状态（更新至 2026-03-28；**新口径**：五参/六参末参 `args` + `*_Arg`）：

| 域 | _Proc 文件 | 五/六参+args* | 无非法INTENT | Arg/_Out 含 status | 状态 |
|----|-----------|---------------|------------|------------------|------|
| Assembly | RT_Asm_Proc.f90 | ✅ / 存量 | ✅ | ✅ | ✅ 完成 |
| LoadBC | RT_LoadBC_Proc.f90 | ✅ / 存量 | ✅ | ✅ | ✅ 完成 |
| Solver | RT_Solv_Proc.f90 | ✅ v2.0 | ✅ v2.0 | ✅ | ✅ 完成 |
| Material | RT_Mat_Proc.f90 | ✅ v2.0 | ✅ v2.0 | ✅ | ✅ 完成 |
| Element | — | ❌ 待建 | — | — | ❌ 未开始 |
| Contact | — | ❌ 待建 | — | — | ❌ 未开始 |
| StepDriver | RT_StepDriver_Impl.f90 | ❌ 待对齐 | — | — | ❌ 未开始 |
| Output | — | ❌ 待建 | — | — | ❌ 未开始 |
| WriteBack | — | ❌ 待建 | — | — | ❌ 未开始 |
| Mesh | — | ❌ 待建 | — | — | ❌ 未开始 |

\* **存量**模块可能仍为 `inp`/`out`（R-01b），新建域应直接 `*_Arg`。

**推进顺序（建议）**：Element → Contact → StepDriver → Output → WriteBack → Mesh

---

## 附：常见违规模式速查

| 违规编号 | 描述 | 症状 | 修复动作 |
|---------|------|------|---------|
| P-02 | TYPE 成员有 INTENT | 编译报错 `attribute ... cannot be used` | 删除所有 TYPE 体内 INTENT |
| P-08 | 抽象接口参数错误 | 非五参/六参，或末参不是 `args` | 按 R-01 修正；遗留 `inp,out` 计划迁移 |
| P-09 | `*_Arg`/_In 内嵌四大类 | IO TYPE 含 Desc/State/Algo/Ctx | 剥离为独立形参 |
| P-10 | `*_Arg`/_Out 缺 ErrorStatusType | 错误信息无法传播 | 在 [OUT] 段添加 `status` |
| P-12 | 新模块仍用 `inp`/`out` | 新代码使用 R-01b | 合并为 `*_Arg`，改接口与调用方 |
| P-11 | Ctx 有 ALLOCATABLE | 热路径动态内存分配 | 改为预分配数组或指针 |

---

**技能版本**: v2.1.1 | **日期**: 2026-03-28  
**升级说明**: v2.1.1 明确 **inp/out → `args` 与形参个数解耦**：五参（四型+`args`）为合并对偶后的默认落点；**六参**仅在域规范需要 **`RT_Com_Base_Ctx`** 时追加。v2.1 起其余约定不变。
