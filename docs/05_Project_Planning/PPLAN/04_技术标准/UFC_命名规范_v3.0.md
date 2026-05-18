# UFC 命名规范 v3.0

> **版本**: v3.1 | **日期**: 2026-05-08
> **状态**: 正式规范 (替代 v1.0 及 REPORTS 侧四文档)
> **适用范围**: UFC 六层架构全部模块 (IF/NM/MD/PH/RT/AP)
>
> **整合来源**:
>
> - `REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` (总则)
> - `REPORTS/UFC_命名规范与接口标准_v2.0.md` (细则/闭集)
> - `REPORTS/UFC_过程命名规范_v1.0.md` (过程动词)
> - `PPLAN/06_核心架构/UFC_PhaseVerb_过程双轴体系.md` (双轴设计)
> - ~~`PPLAN/04_技术标准/UFC_命名规范_v1.0.md`~~（已移除；全文见 git 历史）
>
> **权威性**: 与 `ufc_core` 实现冲突时以代码为准并回写本文档。  
> **域名压缩全表**: `UFC/REPORTS/Domain_Compression_Canon.md`（不含 `L2_NM/ExternalLibs`）为各域 `DomainAbbr` 的规范真源；本文 §2.2 为摘要。

---

## 一、核心公式

```
功能模块 = 数据载体 (四型 TYPE) + 过程载体 (Phase x Verb)
         ↕ 天然耦合: Phase 温度 = TYPE 温度
```

### 1.1 统一命名公式

```
{层缀}_{域缩}_{功能}_{场景后缀}
```

### 1.2 五大命名场景


| #   | 场景              | 后缀类型        | 公式                                 | 示例                           |
| --- | --------------- | ----------- | ---------------------------------- | ---------------------------- |
| 1   | **TYPE 定义**     | 四型后缀        | `{层}_{域}_{功能}_{四型}`                | `PH_Mat_Elas_Desc`           |
| 2   | **MODULE / 文件** | 角色后缀        | `{层}_{域}_{功能}[_{角色}].f90`          | `PH_Mat_Elas_Def.f90`        |
| 3   | **过程名**         | Verb+Object | `{层}_{域}[_{功能}]_{Verb}[_{Object}]` | `PH_Mat_Elas_Compute_Stress` |
| 4   | **变量**          | snake_case  | `{描述性名}`                           | `stress_trial`, `n_dof`      |
| 5   | **常量/枚举**       | UPPER_SNAKE | `{层}_{域}_{CONSTANT}`               | `PH_MAT_ELAS_ISOTROPIC`      |


### 1.3 四条铁律

1. **层缀必填**: 所有 MODULE/TYPE/PUBLIC 过程必须以层缀开头 (`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`)
2. **PascalCase**: MODULE 名/TYPE 名/PUBLIC 过程名用 PascalCase
3. **四型后缀仅 TYPE**: `_Desc`/`_State`/`_Algo`/`_Ctx` 仅出现在 TYPE 定义中，禁止出现在文件名或 MODULE 名
4. **MODULE = 文件名**: `MODULE XXX` 对应 `XXX.f90`，新代码严格一致

### 1.4 长度限制

- 总长度 <= 31 字符 (Fortran 2003)
- 域缩 3-6 字符
- 功能位 <= 10 字符
- 角色后缀 <= 6 字符

---

## 二、层缀与域缩

### 2.1 层缀 (6 个，强制)


| 层级    | 层缀    | 全称                | 示例                                  |
| ----- | ----- | ----------------- | ----------------------------------- |
| L1_IF | `IF_` | Infrastructure    | `IF_Log_Def`, `IF_Mem_Mgr`          |
| L2_NM | `NM_` | Numerical Methods | `NM_Solver_Core`, `NM_SpMV_CSR`     |
| L3_MD | `MD_` | Model Data        | `MD_Mat_Def`, `MD_Mesh_Core`        |
| L4_PH | `PH_` | Physics           | `PH_Mat_Elas_Core`, `PH_Elem_Def`   |
| L5_RT | `RT_` | Runtime           | `RT_StepDriver_Core`, `RT_Solv_Def` |
| L6_AP | `AP_` | Application       | `AP_Job_Core`                       |


### 2.2 权威域缩写映射表 (v3.1 摘要；全表见 REPORT)

**规则**: 目录名可为全称 (`Material/`, `Interaction/` 等)；**文件名 / MODULE 第二段**使用下表或 `[Domain_Compression_Canon.md](../../../../REPORTS/Domain_Compression_Canon.md)` 中的 `**DomainAbbr`**（不含 `L2_NM/ExternalLibs`）。


| 概念 / 目录                                 | 域缩写 `DomainAbbr`                                         | 出现层         | 说明                                                     |
| --------------------------------------- | -------------------------------------------------------- | ----------- | ------------------------------------------------------ |
| Material                                | `**Mat**`                                                | L3/L4/L5    | P1                                                     |
| Element                                 | `**Elem**`                                               | L3/L4/L5    | P2                                                     |
| Contact（力学接触柱）                          | `**Cont**`                                               | L3/L4/L5    | L3 目录名 `Interaction`；**勿**与桥接用的 `**Int`** 混淆           |
| LoadBC（柱级文档与索引）                         | `**LoadBC**`                                             | L3/L4/L5    | P4；存量模块常见 `**Load**` / `**BC**` / `**LBC**` 分项，见 Canon |
| Output                                  | `**Out**`                                                | L3/L4/L5    | P5                                                     |
| WriteBack                               | `**WB**`                                                 | L3/L4/L5    | P6                                                     |
| Section                                 | `**Sect**`                                               | L3/L5       | H2                                                     |
| Step / StepDriver                       | `**Step**`                                               | L3/L5       | H1                                                     |
| Solver                                  | `**Solv**`                                               | L2/L3/L5    | 含 `L2_NM/Solver`                                       |
| Amplitude                               | `**Amp**`                                                | L3          | H1                                                     |
| Coupling                                | `**Cpl**`                                                | L3          | H1                                                     |
| Analysis 伞盖桥                            | `**Ana**`                                                | L3          | 如 `MD_Ana_*`                                           |
| Assembly                                | `**Asm**`                                                | L3/L5       |                                                        |
| Constraint                              | `**Constr**`                                             | L3/L4       |                                                        |
| KeyWord                                 | `**KW**`                                                 | L3          |                                                        |
| Mesh（含 DOF 簇）                           | `**Mesh**`                                               | L3          | `MD_Mesh_*`, `MD_DOF_*`                                |
| Model                                   | `**Model**`                                              | L3          | **禁止**新 `MD_Mo_*`（见 Model 域命名规范）                       |
| Part                                    | `**Part`**                                               | L3          |                                                        |
| Field                                   | `**Field**`                                              | L3/L4       |                                                        |
| L3 跨层 interaction 桥                     | `**Int**`                                                | L3          | 仅 `MD_Int_*` 等桥，**不是** P3 `**Cont`** 本体                |
| Bridge（层内桥模块）                           | `**Brg**`                                                | L3/L4/L5/L6 |                                                        |
| Error                                   | `**Err**`                                                | L1          |                                                        |
| Memory                                  | `**Mem**`                                                | L1          |                                                        |
| Monitor                                 | `**Mon**`                                                | L1          |                                                        |
| Registry                                | `**Reg**`                                                | L1/L6       |                                                        |
| Precision                               | `**Prec**`                                               | L1          |                                                        |
| Matrix / LinAlg                         | `**Mtx**`                                                | L2          | 存量 `NM_LinAlg_*`；新代码优先 `Mtx` + 专题段                     |
| Time integration                        | `**TimeInt**`                                            | L2          | `NM_TimeInt_*`                                         |
| BVH                                     | `**BVH**`                                                | L2          | `NM_BVH_*`                                             |
| Logging                                 | `**Log**`                                                | L1/L5       |                                                        |
| Base / IO 等                             | `**Base**`, `**IO**`                                     | L1/L2/L6    | 与目录同名缩写                                                |
| AP: Config / Input / Job / UI / SimData | `**Cfg**`, `**Inp**`, `**Job**`, `**UI**`, `**SimData**` | L6          | 新输入模块优先 `AP_Inp_*`                                     |


**短域** 保持原样: `DOF`, `IO`, `AI`, `MF` 等；**全量路径对照**以 Canon 为准。

新增域缩须在域 `CONTRACT.md` 中登记。

---

## 三、场景 1 — TYPE 定义 (四型后缀)

### 3.1 公式

```
{层}_{域}_{功能}_{四型}
```

### 3.2 四型后缀


| 四型    | 后缀       | 用途         | 承载 MODULE   | 示例                  |
| ----- | -------- | ---------- | ----------- | ------------------- |
| Desc  | `_Desc`  | 静态描述/只读配置  | `*_Def.f90` | `PH_Mat_Elas_Desc`  |
| State | `_State` | 运行时可变状态    | `*_Def.f90` | `PH_Mat_Elas_State` |
| Algo  | `_Algo`  | 算法描述符/策略   | `*_Def.f90` | `PH_Mat_Elas_Algo`  |
| Ctx   | `_Ctx`   | 运行时上下文/工作区 | `*_Def.f90` | `PH_Mat_Elas_Ctx`   |


### 3.3 辅助类型命名


| 类型    | 公式                 | 示例                        |
| ----- | ------------------ | ------------------------- |
| 子结构   | `{层}_{域}_{子功能}`    | `MD_Mat_ElasticProps`     |
| 入口结构  | `{层}_{域}_{名}Entry` | `MD_KeyWordEntry`         |
| Arg 束 | `{层}_{域}_{功能}_Arg` | `PH_Mat_Compute_Ctan_Arg` |


### 3.4 四型裁剪

并非每域四型齐全。裁剪规则:

- **必有**: Desc (至少有配置)
- **按需**: State (有可变状态时)、Algo (有算法选择时)、Ctx (有运行时工作区时)
- 裁剪决策在域 `CONTRACT.md` 中说明

---

## 四、场景 2 — MODULE / 文件名 (角色后缀)

### 4.1 公式

```
{层}_{域}_{功能}[_{角色}].f90
MODULE名 = 文件名 (不含 .f90)
```

### 4.2 角色后缀闭集 (核心 12 + 扩展 8)

#### 核心 12 (生产必用)


| 角色后缀    | 语义                         | 仓库频率 | 示例                    |
| ------- | -------------------------- | ---- | --------------------- |
| `_Def`  | TYPE/ENUM/PARAMETER 纯声明    | ~116 | `PH_Mat_Elas_Def`     |
| `_Core` | 核心实现 (Init/Finalize + 主算法) | ~53  | `PH_Mat_Elas_Core`    |
| `_Brg`  | 跨层桥接                       | ~82  | `PH_Field_Cpl`        |
| `_Proc` | SIO 过程单元 (L5/Harness)      | ~10  | `RT_Solv_Proc`        |
| `_Impl` | 实现专页 (与策略入口配对)             | ~7   | `RT_Step_Impl`        |
| `_Mgr`  | 管理器/门面入口                   | ~4   | `IF_Mem_Mgr`          |
| `_Reg`  | 静态注册表                      | ~3   | `PH_Elem_Reg`         |
| `_Idx`  | 索引管理 (ID->偏移)              | ~3   | `PH_DOF_Idx`          |
| `_Map`  | 映射转换 (关键字->ID)             | ~3   | `MD_KW_Map`           |
| `_API`  | 对外稳定接口 / FFI 边界            | ~2   | `IF_StructFormat_API` |
| `_Eval` | 求值计算入口 (单步主算子)             | ~2   | `PH_Mat_Eval`         |
| (无后缀)   | 默认主计算模块                    | ~50+ | `PH_Mat_Elastic`      |


#### 扩展 8 (按需使用)


| 角色后缀    | 语义          | 角色后缀          | 语义      |
| ------- | ----------- | ------------- | ------- |
| `_Ops`  | 存量兜底 (混合操作) | `_Ctrl`       | 控制逻辑    |
| `_Util` | 工具函数集       | `_Diag`       | 诊断/探针   |
| `_Sync` | 同步镜像/双缓冲    | `_Pool`       | 内存/资源池  |
| `_Exec` | 执行专页        | `_Loc`/`_Glb` | 局部/全局算子 |


#### 后缀使用原则

1. **优先无后缀**: 新域主计算模块默认无后缀 (`PH_Mat_Elastic.f90`)
2. **精确优先**: 有明确角色时用核心 12 中的精确后缀
3. **闭集控制**: 超出 20 种后缀时须在域 CONTRACT.md 登记并说明理由
4. **禁止复合后缀**: 如 `_Idx_Brg.f90`，应合成到功能位 (`DOFIdx_Brg.f90`)
5. **禁止两段式**: `PH_Idx.f90` (无域语义)；允许登记过的紧凑 Token

### 4.3 存量双轨制

- **存量 `_Ops`**: 长期保留，不强制批量改名
- **增量代码**: 新拆分文件使用无后缀或核心 12 后缀
- **渐进迁移**: 域级打通时逐步替换 `_Ops` 为精确后缀

### 4.4 特殊文件命名


| 类型    | 公式                                                  | 示例                       |
| ----- | --------------------------------------------------- | ------------------------ |
| 桥接模块  | `{层}_Bridge_{目标层}_Brg.f90` 或 `{层}_{域}_{功能}_Brg.f90` | `PH_Bridge_L3_Brg.f90`   |
| 测试文件  | `{层}_{域}_{功能}_test.f90`                             | `PH_Mat_Elas_test.f90`   |
| 域入口门面 | `{层}_{域}_Domain.f90` 或 `{层}_{域}_Core.f90`           | `PH_Mat_Domain_Core.f90` |


---

## 五、场景 3 — 过程命名 (Phase x Verb 双轴)

### 5.1 设计哲学

数据载体用四型 TYPE (名词) 分类；过程载体用 Phase x Verb (动词) 分类。二者通过温度轴耦合。

### 5.2 公式

```
{层}_{域}[_{功能}]_{Verb}[_{Object}]
```

- Phase 不入过程名 (Verb 已暗示 Phase)
- Phase 以注释标注: `! Phase: {Phase} | Verb: {Verb} | HOT/COLD`

### 5.3 轴一: Phase (时相) — 6 级


| Phase         | 中文  | 温度  | 频率       | 写入数据          | 典型操作             |
| ------------- | --- | --- | -------- | ------------- | ---------------- |
| **Config**    | 配置  | 冷   | 1次/分析    | Desc          | 解析输入、建模型树        |
| **Populate**  | 预填  | 冷   | 1次/分析    | L4/L5 槽位      | Bridge L3->L4/L5 |
| **Step**      | 分析步 | 温   | ~10-100  | State(步级)     | Begin/End Step   |
| **Increment** | 增量步 | 温热  | ~100-10K | State(增量级)    | 时间推进、切回          |
| **Iteration** | 迭代步 | 热   | ~1K-100K | Ctx           | 装配 K/F、求解        |
| **Local**     | 局部  | 最热  | 百万级      | Ctx+State(IP) | 单元 Ke/Fe、本构      |


Phase 退化规则: 显式动力学 (Iteration 单次)、特征值 (Step 单步)、静力 (Increment 可能单增量)。

### 5.4 轴二: Verb (功能动词) — 8 族


| Verb 族       | 含义   | 推荐子动词                                      | 避免                   |
| ------------ | ---- | ------------------------------------------ | -------------------- |
| **Init**     | 生命周期 | Init, Finalize, Reset, Alloc, Dealloc      | Create, Destroy      |
| **Validate** | 合法性  | Validate, Guard                            | Check (与 Control 冲突) |
| **Compute**  | 核心计算 | Compute, Build, Evaluate, Integrate, Solve | Calc, Do, Run        |
| **Evolve**   | 状态演化 | Update, Commit, Revert, Advance            | Modify, Change       |
| **Assemble** | 归约聚合 | Assemble, Reduce, Apply, Impose            | Collect, Gather      |
| **Access**   | 数据存取 | Get, Set, Add, Remove, Find, Count         | Fetch, Put, Insert   |
| **Control**  | 流程判断 | Begin, End, Route, Select, Check, Loop     | Start, Stop          |
| **Bridge**   | 跨层映射 | Bridge, Populate, WriteBack, Pack, Map     | Transfer, Move       |


### 5.5 48 格覆盖矩阵


| Phase \ Verb  | Init  | Validate | Compute | Evolve | Assemble | Access | Control | Bridge |
| ------------- | ----- | -------- | ------- | ------ | -------- | ------ | ------- | ------ |
| **Config**    | **Y** | **Y**    | **Y**   | -      | -        | **Y**  | -       | -      |
| **Populate**  | **Y** | y        | y       | -      | -        | -      | -       | **Y**  |
| **Step**      | **Y** | -        | y       | **Y**  | -        | **Y**  | **Y**   | **Y**  |
| **Increment** | y     | -        | y       | **Y**  | -        | **Y**  | **Y**   | -      |
| **Iteration** | -     | -        | **Y**   | **Y**  | **Y**    | -      | **Y**   | y      |
| **Local**     | -     | -        | **Y**   | **Y**  | y        | y      | -       | -      |


**Y** = 常见, **y** = 少见但合法, **-** = 不自然。约 29/48 格有实际 FEM 过程。

### 5.6 过程命名规则速查


| 规则               | 内容                                                    |
| ---------------- | ----------------------------------------------------- |
| P1 公式            | `{L}_{D}[_{F}]_{Verb}[_{Obj}]`, <= 31 字符              |
| P2 Phase 注释      | `! Phase: {Phase} | Verb: {Verb} | HOT/COLD [O(?)]`   |
| P3 Init/Finalize | `{L}_{D}_Core_Init` / `{L}_{D}_Core_Finalize`         |
| P4 Bridge 方向     | `{L}_{D}_Brg_From{Source}` / `{L}_{D}_Brg_To{Target}` |


### 5.7 Verb-Phase 对照速查


| 过程名中动词          | Verb 族   | 典型 Phase       | 示例                            |
| --------------- | -------- | -------------- | ----------------------------- |
| Init/Finalize   | Init     | Config         | `MD_Mat_Core_Init`            |
| Validate        | Validate | Config         | `PH_Mat_Elas_Validate_Props`  |
| Compute/Build   | Compute  | Local          | `PH_Mat_Elas_Compute_Stress`  |
| Solve           | Compute  | Iteration      | `NM_Solver_Solve`             |
| Update/Commit   | Evolve   | Step/Increment | `RT_Step_Commit_State`        |
| Assemble/Apply  | Assemble | Iteration      | `RT_Asm_Assemble_Ke`          |
| Get/Set/Add     | Access   | (any)          | `MD_Material_Get_By_ID`       |
| Begin/End       | Control  | Step/Increment | `RT_StepDriver_Begin_Step`    |
| Check           | Control  | Iteration      | `RT_Solver_Check_Convergence` |
| Bridge/Populate | Bridge   | Populate       | `PH_Mat_Elas_Brg_FromL3Desc`  |
| WriteBack       | Bridge   | Step           | `MD_WriteBack_Execute`        |


---

## 六、场景 4/5 — 变量、常量、接口

### 6.1 局部变量

```
snake_case: stress_trial, n_dof, elem_id, mat_idx
```

### 6.2 模块常量 / 枚举

```fortran
INTEGER(i4), PARAMETER :: PH_MAT_ELAS_ISOTROPIC = 1
INTEGER(i4), PARAMETER :: RT_STEP_STATIC = 0
```

公式: `{层}_{域}_{UPPER_SNAKE}`

### 6.3 INTERFACE / ABSTRACT INTERFACE

```fortran
ABSTRACT INTERFACE
  SUBROUTINE PH_Mat_Compute_Ctan_Interface(...)
END INTERFACE
```

公式: 与绑定过程同名或 `{层}_{域}_{功能}_Interface`

### 6.4 四型实例变量


| 四型    | 推荐实例名                          | 示例                                 |
| ----- | ------------------------------ | ---------------------------------- |
| Desc  | `desc`, `mat_desc`, `{域}_desc` | `TYPE(PH_Mat_Elas_Desc) :: desc`   |
| State | `state`, `mat_state`           | `TYPE(PH_Mat_Elas_State) :: state` |
| Algo  | `algo`, `mat_algo`             | `TYPE(PH_Mat_Elas_Algo) :: algo`   |
| Ctx   | `ctx`, `mat_ctx`               | `TYPE(PH_Mat_Elas_Ctx) :: ctx`     |


---

## 七、精度声明

所有 UFC 代码必须使用统一精度声明:

```fortran
USE IF_Prec, ONLY: wp, i4
```

禁止 `ISO_FORTRAN_ENV`、自定义 KIND 参数。详见 `.cursor/rules/ufc-fortran-syntax.mdc`。

---

## 八、与 UFC 其他体系的关系


| UFC 体系                        | 回答的问题   | 与命名的关系                                             |
| ----------------------------- | ------- | -------------------------------------------------- |
| 六层 (L1-L6)                    | 在哪里     | 层缀 (场景 1-5 公式首段)                                   |
| 四类 TYPE                       | 袋里装什么   | 四型后缀 (场景 1)                                        |
| Phase x Verb                  | 过程何时做什么 | 过程命名 (场景 3)                                        |
| SIO / *_Arg                   | 签名形态    | 不替代: SIO 管参数, 命名管名称                                |
| ProcKind (Cval/Kern/Redu/Drv) | 主数据流    | 降级为可选审计标签 `@ProcKind`                              |
| 三步状态机                         | 求解器嵌套   | Phase 对齐: Step/Increment/Iteration                 |
| CONTRACT.md                   | 域做什么    | 从 CONTRACT 推演意图 -> 映射到命名公式                         |
| 域柱架构                          | 跨层投影    | 命名映射表 (见 `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §3.2) |


---

## 九、合规验收清单

- MODULE 名 = 文件名 (不含 .f90)
- 所有 PUBLIC 符号带层缀
- TYPE 名带四型后缀 (`_Desc`/`_State`/`_Algo`/`_Ctx`)
- 四型后缀不出现在文件名/MODULE 名
- 角色后缀在核心 12 + 扩展 8 闭集内 (或域 CONTRACT 登记)
- 过程名符合 `{L}_{D}[_{F}]_{Verb}[_{Object}]`
- 每个过程头部有 Phase 注释
- 常量用 `UPPER_SNAKE` 且带层缀
- `USE IF_Prec_Core, ONLY: wp, i4`

---

## 十、迁移策略

### 10.1 存量代码


| 类型                                      | 策略                    |
| --------------------------------------- | --------------------- |
| `_Ops` 后缀                               | 长期保留，新代码不使用，渐进替换      |
| 无层缀 (如 `ModuleBlas`)                    | LEGACY 标注，新代码不模仿      |
| MODULE != 文件名                           | 优先改 MODULE 名对齐文件名     |
| 多缩写并存 (如 `PH_Cont_`* vs `PH_Contact_*`) | 在 CONTRACT.md 中登记两者等价 |


### 10.2 新代码

所有新代码严格遵循本规范。违规项在 PR 审查中阻断。

### 10.3 工具链


| 工具                         | 路径                                        | 功能                |
| -------------------------- | ----------------------------------------- | ----------------- |
| `naming_checker.py`        | `UFC/ufc_harness/tools/code_development/` | 前缀/后缀/四型/模式扫描     |
| `check_naming_l3l4l5l6.py` | `UFC/tools/`                              | L3-L6 层前缀/域缩检查    |
| `ufc-naming.mdc`           | `.cursor/rules/`                          | Cursor agent 命名规则 |


---

## 附录 A: 后缀词汇参考 (非生产必建)

以下后缀仅作命名碰撞时的参考词汇表，不要求每域都建对应文件:

`_Fact` (工厂) / `_Builder` (构建器) / `_Adapter` (适配器) / `_Parser` (解析器) /
`_Validator` (验证器) / `_Handler` (处理器) / `_Filter` (过滤器) / `_Converter` (转换器) /
`_Integrator` (积分器) / `_Solver` (求解器) / `_Predictor` (预测器) / `_Corrector` (校正器) /
`_Updater` (更新器) / `_Scheduler` (调度器) / `_Dispatcher` (分发器) / `_Cache` (缓存) /
`_Buffer` (缓冲区) / `_Queue` (队列)

---

## 附录 B: LEGACY 遗留清单 (MODULE != Filename)

以下文件经审计确认存在命名遗留问题（MODULE!=Filename 或两段式命名），均已标注 `NAMING NOTE` 或 `LEGACY`，保留不改。


| 文件                                          | MODULE                   | 原因                            |
| ------------------------------------------- | ------------------------ | ----------------------------- |
| `L1_IF/Base/RT_SolverType_Def.f90`          | `RT_SolverType_Def`      | 跨层共享枚举，放置 L1 是架构设计            |
| `L3_MD/Bridge/Bridge_L5/MD_Mesh_Brg.f90`    | `RT_Mesh_Brg`            | 桥接文件用目标层前缀                    |
| `L3_MD/Interaction/MD_Int_Ctx.f90`          | (35 modules)             | 多模块文件                         |
| `L3_MD/KeyWord/MD_KW.f90`                   | (6 modules)              | 多模块文件；末尾 `MODULE MD_KW` 门面再导出 |
| `L3_MD/Mesh/MD_Elem_Def.f90`                | `MD_Elem_Def_Legacy`     | MODULE 自带 Legacy 后缀           |
| `L3_MD/Model/MD_BaseTypes.f90`              | (5 modules)              | 多模块文件                         |
| `L3_MD/Model/MD_ModelCoordSys.f90`          | (12 modules)             | 多模块文件                         |
| `L3_MD/Model/MD_ModelData.f90`              | (21 modules)             | 多模块文件                         |
| `L4_PH/Element/PH_NLGeomEval.f90`           | `RT_AsmNLGeomEval`       | 跨层共享 NL 几何评估器                 |
| `L4_PH/Element/PH_ShapeScalarField.f90`     | `RT_AsmShapeScalarField` | 跨层共享形函数模块                     |
| `L4_PH/Element/Shared/PH_ElemDiffUtils.f90` | `RT_Elem_Diff_Utils`     | 跨层共享微分工具                      |
| `L6_AP/Input/Parser/AP_InpDomain.f90`       | `AP_Inp`                 | 重复 MODULE，域解析器                |
| `L4_PH/Element/PH_ElemFeDispatch.f90`       | `PH_ElemFeDispatch`      | 两段式 LEGACY，FE 分发              |
| `L4_PH/Element/PH_ElemKeDispatch.f90`       | `PH_ElemKeDispatch`      | 两段式 LEGACY，KE 分发              |
| `L4_PH/Element/Shared/PH_ElemShapeFunc.f90` | `PH_ElemShapeFunc`       | 两段式 LEGACY，形函数                |
| `L4_PH/Material/Dispatch/PH_MatEval.f90`    | `PH_MatEval`             | 两段式 LEGACY，材料求值               |
| `L4_PH/Material/Dispatch/PH_MatPLMEval.f90` | `PH_MatPLMEval`          | 两段式 LEGACY，塑性材料求值             |


---

## 附录 C: 变更记录


| 版本   | 日期         | 变更                                                                                                           |
| ---- | ---------- | ------------------------------------------------------------------------------------------------------------ |
| v1.0 | 2026-04-03 | 初版: 层缀/域/PhysType/后缀                                                                                         |
| v2.0 | 2026-04-22 | 命名与接口标准: 46 项闭集 A-H                                                                                          |
| v3.0 | 2026-04-26 | 整合 4 文档为一; 场景 5 化; 后缀精简为核心 12+扩展 8; Phase×Verb 内嵌; 迁移策略统一                                                    |
| v3.1 | 2026-04-26 | 全仓库 f90 三段式整顿: 删除 17 壳文件、重命名 94 文件 (含 83 Material 子族)、标注 13 LEGACY; MODULE==Filename 合规率 100% (excl. LEGACY) |
| v3.2 | 2026-04-26 | 二轮整治 (两段式→三段式全覆盖): 重命名 657 文件、更新 646 MODULE + 1495 USE 引用; 三段式合规率 98.5% (1054/1070), 仅 16 个 LEGACY 两段式保留     |


