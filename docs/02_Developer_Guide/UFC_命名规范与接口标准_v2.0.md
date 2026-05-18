# UFC 命名规范与接口标准 v2.0

> **已整合至 `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`，本文冻结 (2026-04-26)。**

> **版本**: v2.0（对齐仓库实际风格，替代 v1.0）
> **创建日期**: 2026-04-22
> **最后更新**: 2026-04-24（命名文档套件、文档地位与 §11 路径）
> **核心使命**: 基于 UFC 仓库现有代码风格，建立统一的命名规范和接口标准
> **文档地位**: REPORTS 侧「命名与接口」细则与闭集；总则见 **统一命名方案**；仓库检查入口见 **PPLAN `UFC_命名规范_v3.0.md`**；冲突以 **PPLAN + `ufc_core` 代码** 为准。
> **适用范围**: UFC 项目所有 Fortran 代码开发

---

## 文档元数据

| 属性               | 值                                                                                                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **规范简称** | UFC_Naming_Standard_v2                                                                                                                                                                        |
| **上位文档** | `docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`（或当前 v5.x）                                                                                                             |
| **相关文档** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md`；`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`；`UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md`；`UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md`；`UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md`；`UFC/REPORTS/UFC_过程命名规范_v1.0.md` |
| **核心公式** | **层缀_域缩_功能_[后缀]** + **数据四型** + **功能动词**（`[后缀]` 新码可省略，见 §1.3） |

---

## 〇、REPORTS 命名文档套件（交叉索引）

| 文档 | 路径 | 职责 |
|------|------|------|
| **统一命名方案** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` | 三级体系总则；TYPE/MODULE/子程序四场景；**默认无 `_Ops`** 与存量双轨 |
| **本文（命名与接口 v2）** | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` | 层缀/域缩/铁律；**§3.2 后缀闭集（A–H）** 与仓库实证 |
| **过程命名规范** | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` | 子程序动词与对内/对外过程名 |
| **功能模块清单** | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` | 分层模块枚举与后缀角色列 |
| **主责正交矩阵** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` | 四型字面禁作文件名；ProcKind 辅轴 |
| **PPLAN 命名规范** | `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md` | 仓库既有检查入口 |
| **域名压缩权威表** | `UFC/REPORTS/Domain_Compression_Canon.md` | `ufc_core` 各域 `DomainAbbr`（不含 ExternalLibs）；三段/四段命名第二段 |
| **域级模块规范** | `UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` | 域级目录与 SIO 对齐说明 |

**阅读顺序**：统一命名方案（总则）→ 本文（细则+闭集）→ 过程命名规范 → 功能模块清单（查表）；与 `ufc_core` 实现冲突时 **以代码与 PPLAN 为准**，并回写 REPORTS。

---

## 一、设计原则

### 1.1 对齐仓库实际

本规范的所有规则均从仓库现有代码中提炼，而非另起炉灶。仓库中 100+ 模块的命名风格是事实标准，新代码必须与之一致。

### 1.2 核心命名公式

```
MODULE名/文件名: {层缀}_{域缩}_{功能}_{后缀}
TYPE名:          {层缀}_{域缩}_{功能}_{四型后缀}
子程序名:        {层缀}_{域缩}_{功能}_{动词}_{具体}
变量名:          snake_case（局部）/ 四型实例用缩写
```

### 1.3 三条铁律

1. **层缀必填**：所有 MODULE、TYPE、子程序必须以层缀开头（`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`）
2. **PascalCase**：MODULE名、TYPE名、子程序名均用 PascalCase（`PH_Mat_Elas_Init` 而非 `mat_elastic_init`）
3. **四型后缀仅用于 TYPE**：`_Desc`/`_State`/`_Algo`/`_Ctx` 仅出现在 `TYPE` 定义中，**禁止**出现在 `.f90` 文件名或 `MODULE` 名中
4. **后缀双轨制**：
   - **新代码/新域**：默认主计算文件无后缀（如 `PH_Mat_Elastic.f90`）；专用后缀（`_Def`/`_Brg`/`_Idx`/`_Reg`/`_Map`/`_Mgr`/`_API`/`_Ctrl`/`_Proc`）仅在有明确非默认角色时出现
   - **存量代码**：现有 `*_Ops.f90` 长期保留，不强制批量改名
   - **增量代码**：新拆分文件鼓励使用无后缀格式
   - **域内约定**：各域可在 `CONTRACT.md` 中声明「本域主模块无 `_Ops` 后缀」

---

## 二、层缀与域缩

### 2.1 层缀（强制，6 个）

| 层级  | 层缀    | 全称              | 示例                                   |
| ----- | ------- | ----------------- | -------------------------------------- |
| L1_IF | `IF_` | Infrastructure    | `IF_Log_Def`、`IF_Mem_Algo`        |
| L2_NM | `NM_` | Numerical Methods | `NM_Matrix_Ops`（暂无样本，预留）    |
| L3_MD | `MD_` | Model Data        | `MD_Mesh_Ops`、`MD_Out_Def`        |
| L4_PH | `PH_` | Physics           | `PH_ElemContm_Ops`、`PH_Field_Cpl` |
| L5_RT | `RT_` | Runtime           | `RT_SolvProc_Algo`、`RT_Step_Def`  |
| L6_AP | `AP_` | Application       | `AP_Config_Ops`（暂无样本，预留）    |

### 2.2 域缩（常见，非穷举）

| 域缩                    | 全称              | 出现层   | 仓库实例                                  |
| ----------------------- | ----------------- | -------- | ----------------------------------------- |
| `Mat`                 | Material          | L3/L4/L5 | `MD_Mat_*`、`PH_Mat_*`                |
| `Elas`                | Elastic           | L3/L4    | `PH_Mat_Elas_*`                         |
| `Plast`               | Plastic           | L3/L4    | `PH_Mat_Plast_*`                        |
| `Elem`                | Element           | L3/L4/L5 | `MD_Elem_*`、`PH_Elem*_*`             |
| `Contm`               | Continuum         | L4       | `PH_ElemContm_Ops`                      |
| `Sld3D`               | Solid 3D          | L4       | `PH_ElemSld3D*_Ops`                     |
| `Mesh`                | Mesh              | L3       | `MD_Mesh_*`                             |
| `Solv`                | Solver            | L2/L5    | `RT_Solv*_Algo`                         |
| `Step`                | Step Driver       | L5       | `RT_Step*_Algo`                         |
| `WB`                  | WriteBack         | L5       | `RT_WB_*`                               |
| `Cont`                | Contact           | L3/L4/L5 | `PH_Cont_*`                             |
| `Field`               | Field             | L3/L4    | `PH_Field_*`                            |
| `Load`/`BC`/`LBC` | Load/BC           | L3/L4    | `PH_Load_*`、`PH_BC_*`、`PH_Ldbc_*` |
| `Out`                 | Output            | L3       | `MD_Out_Def`                            |
| `Amp`                 | Amplitude         | L5       | `RT_Amp_Algo`                           |
| `DOF`                 | Degree of Freedom | L3       | `MD_DOF_*`                              |
| `Log`                 | Logging           | L1       | `IF_Log_*`                              |
| `Mem`                 | Memory            | L1       | `IF_Mem_*`                              |
| `IO`                  | Input/Output      | L1       | `IF_IO_*`                               |
| `Mon`                 | Monitor           | L1       | `IF_Mon_*`                              |
| `Prec`                | Precision         | L1       | `IF_Prec_*`                             |
| `Err`                 | Error             | L1       | `IF_Err_*`                              |

**原则**：域缩应**简短且可辨识**，3～6 个字符为佳；新增域缩在 `CONTRACT.md` 中登记。

---

## 三、文件与模块命名

### 3.1 命名格式

```
文件名 = MODULE名 + .f90
MODULE名 = {层缀}_{域缩}_{功能}_{后缀}
```

**仓库实例**：

| 层 | 文件名                      | MODULE名                | 拆解                        |
| -- | --------------------------- | ----------------------- | --------------------------- |
| L1 | `IF_Log_Def.f90`          | `IF_Log_Def`          | IF + Log + _ + Def          |
| L1 | `IF_Mem_Chunk_Algo.f90`   | `IF_Mem_Chunk_Algo`   | IF + Mem + Chunk + Algo     |
| L1 | `IF_StructFormat_API.f90` | `IF_StructFormat_API` | IF + StructFormat + _ + API |
| L3 | `MD_Mesh_Ops.f90`         | `MD_Mesh_Ops`         | MD + Mesh + _ + Ops         |
| L3 | `MD_ElemPopulate_Ops.f90` | `MD_ElemPopulate_Ops` | MD + Elem + Populate + Ops  |
| L3 | `MD_DOFMgr_Ops.f90`       | `MD_DOFMgr_Ops`       | MD + DOF + Mgr + Ops        |
| L4 | `PH_ElemContm_Ops.f90`    | `PH_ElemContm_Ops`    | PH + Elem + Contm + Ops     |
| L4 | `PH_Field_Cpl.f90`        | `PH_Field_Cpl`        | PH + Field + _ + Brg        |
| L4 | `PH_Load_Def.f90`         | `PH_Load_Def`         | PH + Load + _ + Def         |
| L4 | `PH_L4Idx_Brg.f90`        | `PH_L4Idx_Brg`        | PH + L4 + Idx + Brg         |
| L5 | `RT_SolvProc_Algo.f90`    | `RT_SolvProc_Algo`    | RT + Solv + Proc + Algo     |
| L5 | `RT_StepDriver_Brg.f90`   | `RT_StepDriver_Brg`   | RT + Step + Driver + Brg    |
| L5 | `RT_WB_Def.f90`           | `RT_WB_Def`           | RT + WB + _ + Def           |
| L5 | `RT_Step_Ctx.f90`         | `RT_Step_Ctx`         | ⚠️ 例外（见下文）         |

### 3.2 后缀闭集（46 项，穷尽仓库实际）

后缀只表达**文件/模块的功能专职**，不表达 ProcKind。
以下 46 项后缀均从仓库 160+ 模块中穷尽提炼，每个有精准语义和仓库实证。

#### A. 声明与粘合（3 项）

| 后缀          | 含义                               | 仓库实例                                                                                     |
| ------------- | ---------------------------------- | -------------------------------------------------------------------------------------------- |
| **Def** | TYPE/ENUM/PARAMETER 纯声明         | `IF_Log_Def`、`MD_Mesh_Def`、`RT_WB_Def`、`PH_Field_Def`、`AP_Base_Def`            |
| **Glu** | 纯粘合/薄 accessor                 | （暂无实例，预留）                                                                           |
| **Ctx** | 纯上下文 TYPE 定义（仅遗留文件名） | `RT_Step_Ctx`、`PH_Cont_Ctx`、`IF_Reg_Ctx`（⚠️ 遗留，新文件用 `_Def` 内定义 TYPE） |

#### B. 计算与操作（9 项）

| 后缀           | 含义                                                 | 仓库实例                                                                             |
| -------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Ops**  | **后备后缀**：确实混合操作，无法归入更精确后缀 | `PH_Cont_Ops`（接触核心=搜索+评估+分派）                                           |
| **Eval** | 评估/计算入口（单步主算子）                          | `PH_Mat_Eval`（待迁移）、`PH_NLGeomEval`（待迁移）                               |
| **Impl** | 实现专页（与入口/策略配对）                          | `RT_Step_Impl`、`RT_Solv_Impl`、`RT_WB_Impl`、`RT_Out_Impl`                  |
| **Exec** | 执行专页（与编排/驱动配对）                          | `RT_Step_Exec`                                                                     |
| **Loc**  | 局部算子独占（单元/IP 级）                           | （预留）                                                                             |
| **Glb**  | 全局归约独占（装配级）                               | （预留）                                                                             |
| **Asm**  | 装配流水线                                           | `RT_AsmSolv`、`RT_AsmGlobal`（Asm 在功能位）                                     |
| **Proc** | SIO 过程单元（L5 标准过程）                          | `RT_Solv_Proc`、`RT_Asm_Proc`、`RT_WB_Proc`、`RT_Out_Proc`、`MD_Step_Proc` |
| **Util** | 工具函数集                                           | `NM_Base_Utils`（Util 在功能位）、`RT_Asm_Util`、`RT_DofMapUtils`              |

#### C. 映射、注册与分派（7 项）

| 后缀             | 含义                          | 仓库实例                                                                                            |
| ---------------- | ----------------------------- | --------------------------------------------------------------------------------------------------- |
| **Map**    | 语义映射（关键字→内部 ID）   | `MD_Elem_InpMap`、`MD_KW_Map`、`MD_OutMapper`                                                 |
| **Reg**    | 静态注册表                    | `MD_Elem_Reg`（待迁移）、`PH_ElemReg`（待迁移）、`IF_Err_Reg`、`MD_KWReg`、`MD_OutVarReg` |
| **Dsp**    | 动态分派（vtable/函数指针）   | `PH_Elem_Dsp`（待迁移为 `_Dsp`）、`RT_AsmNLGeomDispatch`（Dsp 在功能位）                      |
| **Facade** | 门面/薄封装（对外统一入口）   | `PH_Elem_StructFac`（待迁移）、`PH_MatPLMLegacyFacadeUMATs`（待迁移）                           |
| **Idx**    | 索引图式（二分查找/ID→偏移） | `PH_L4Idx_Brg`、`MD_LBC_Idx`、`MD_Amplitude_Idx`                                              |
| **Sym**    | 符号与名字空间                | （预留）                                                                                            |
| **Lib**    | 库函数集（静态查表/本构库）   | `MD_Model_Lib`、`MD_Sect_Lib`、`MD_Out_Lib`                                                   |

#### D. 策略、求解、步进与快照（6 项）

| 后缀            | 含义                   | 仓库实例                                                        |
| --------------- | ---------------------- | --------------------------------------------------------------- |
| **Strat** | 策略选择               | （预留）                                                        |
| **Solv**  | 求解内核               | `MD_Solv_Algo`、`MD_Solv_Def`（Solv 在域缩位）              |
| **Step**  | 增量控制               | `MD_Step_Algo`、`MD_Step_Def`（Step 在域缩位）              |
| **Run**   | 运行快照袋             | （预留）                                                        |
| **Crd**   | 协调器（多物理场耦合） | `RT_MF_Coord`（Crd 在功能位）                                 |
| **Conv**  | 收敛判定               | `RT_Solv_CheckRes`（Conv 在功能位）、`RT_AIConvPredictAlgo` |

#### E. 桥接、Populate、写回（5 项）

| 后缀               | 含义                   | 仓库实例                                                                                                                                   |
| ------------------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Brg**      | 跨层桥接               | `PH_Field_Cpl`、`RT_StepDriver_Brg`、`MD_Mesh_API`、`PH_BC_Brg`、`MD_LBC_Brg`、`IF_Err_Brg`、`IF_AI_Brg`、`NM_LAPACK_Brg` |
| **Pop**      | Populate 专页          | `PH_L4Populate_Ops`（Populate 在功能位）、`MD_ElemPopulate_Ops`                                                                        |
| **Wb**       | Write-back 专页        | `PH_WB_Ops`、`PH_WB_Brg`、`PH_WBInit_Ops`                                                                                            |
| **Contract** | 合同/契约检查          | `PH_L4L3Mat_Contract`（待迁移）                                                                                                          |
| **Iface**    | 跨域接口（同层不同域） | `PH_Domain_Intf`（待迁移）                                                                                                               |

#### F. 管理器、域入口、观测与运行时（11 项）

| 后缀               | 含义                                          | 仓库实例                                                                                                                                                        |
| ------------------ | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Algo**     | 算法/策略实现（存量保留，新增优先选精确后缀） | `IF_Mem_Algo`、`RT_Solv_Proc`、`MD_Sect_Algo`                                                                                                             |
| **Mgr**      | 门面管理器                                    | `IF_Mon_Mgr`（Mgr 在功能位）、`IF_Mem_Mgr`、`IF_Device_Mgr`、`IF_UnstructFile_Mgr`、`MD_Mesh_Mgr`（待迁移）、`MD_DOFMgr`（待迁移）、`AP_UIJobMgr` |
| **Domain**   | 域入口薄门面                                  | `MD_Mesh_Domain`（待迁移）、`RT_WBDomain`、`MD_LBC_Domain`、`AP_RegDomain`、`AP_UIDomain`、`MD_SectDomain`、`MD_KeyWordDomain`                    |
| **API**      | 对外稳定 ABI                                  | `IF_StructFormat_API`、`IF_UnstructFormat_API`                                                                                                              |
| **Sync**     | 双域/双缓冲镜像                               | `MD_Mesh_Sync`（待迁移）、`MD_Step_Sync`、`MD_Solv_Sync`、`MD_SectionSync`、`MD_PartSync`、`MD_IntSync`、`MD_OutSync`、`MD_ConstraintSync`      |
| **Validate** | 校验专页                                      | `MD_ElemValidate`（待迁移）                                                                                                                                   |
| **Search**   | 搜索算法专页                                  | `PH_Cont_Search`（待迁移）、`PH_ContCCD`（待迁移）、`PH_ContBVHQuery`（待迁移）、`PH_ContBVHBuilder`（待迁移）                                          |
| **Diag**     | 诊断/探针                                     | （预留）                                                                                                                                                        |
| **Env**      | 执行环境                                      | （预留）                                                                                                                                                        |
| **Wsp**      | Workspace                                     | `RT_StepWS`（WS 在功能位）、`IF_Mem_WS`                                                                                                                     |
| **Pool**     | 内存/资源池                                   | `IF_Mem_Chunk`（Chunk 在功能位）、`IF_StructMemPool`、`IF_UnstructMemPool`、`RT_MemPool_Core`                                                           |

#### G. 解析、构建与 I/O（8 项）

| 后缀              | 含义                       | 仓库实例                                                                                              |
| ----------------- | -------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Parse**   | 输入解析/词法分析          | `MD_KW_Parser`、`MD_OutParser`、`MD_OutParse`、`MD_IntParser`、`MD_InpParse`、`IF_Parser` |
| **Build**   | 构建/生成（模型树/网格等） | `MD_Model_Build`（Build 在功能位）                                                                  |
| **Map**     | 语义映射（KW→内部 ID）    | `MD_Elem_InpMap`、`MD_KW_Map`、`MD_OutMapper`                                                   |
| **Writer**  | 输出写入器                 | `RT_Writer_ODB`、`RT_WriterHDF5`、`IF_Writer`                                                   |
| **Persist** | 持久化/序列化              | `IF_IO_Persist`                                                                                     |
| **Backup**  | 备份/恢复                  | `IF_IO_Backup`                                                                                      |
| **Export**  | 导出                       | `MD_OutFieldExport`（Export 在功能位）                                                              |
| **Report**  | 报告/可视化                | `MD_OutReportPlot`（Report 在功能位）                                                               |

#### H. 物理/算法专域（4 项）

| 后缀               | 含义          | 仓库实例                                                                                                                        |
| ------------------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Thermo**   | 热力学耦合    | `PH_Cont_ThermoMech`（待迁移）、`PH_ThermalCont_Def`                                                                        |
| **Friction** | 摩擦算法      | `PH_Cont_Friction`（待迁移）                                                                                                  |
| **Wear**     | 磨损演化      | `PH_Cont_WearEvol`（待迁移）                                                                                                  |
| **Shape**    | 形函数/场成形 | `PH_Elem_ShapeFunc`（Shape 在功能位）、`PH_ShapeMechanicalField`、`RT_AsmShapeMechanicalField`、`PH_Field_ShapeFunc` |

#### 后缀治理

- **禁止作新建文件后缀**：`_Desc`/`_State`/`_Algo`/`_Ctx`（保留给 TYPE）
- **`_Ops` 降级为后备**：新文件**禁止**默认 `_Ops`；必须先查 §3.4 精确后缀决策表
- **`_Algo` 存量保留**：新文件优先选更精确后缀
- **`_Ctx` 文件名遗留**：存量不强制改名；新文件中 Ctx TYPE 定义在 `_Def` 内
- **新增后缀**：RFC + 表增行 + naming_checker 白名单
- **总量软上限**：50 项
- **数字尾巴**：`*_*1` 仅遗留兼容，新代码不用

### 3.3 `_Algo` 后缀的特殊说明

仓库中 `_Algo` 是**使用频率最高的后缀之一**（L1 和 L5 大量使用），但它与数据四型中的 `TYPE(..._Algo)` 存在字面冲突。

**当前策略（与 v1.8 对齐）**：

- **`_Algo` 作文件后缀**：仓库中已大量存在（如 `IF_Mem_Algo`、`RT_SolvImpl_Algo`），**存量保留**
- **`TYPE(..._Algo)`**：数据四型，含义为"算法描述符"（如 `MD_Output_Algo`）
- **新文件**：优先从 A–F 闭集中选更精确的后缀（如 `Strat`/`Solv`/`Step`/`Proc`），而非默认 `_Algo`
- **消歧**：若同一目录下既有 `*_Algo.f90`（文件）又有 `TYPE(..._Algo)`（类型），在 `CONTRACT.md` 中写清

### 3.4 `_Ops`/`_Algo` 后缀降级与完整迁移决策表

仓库中 60+ 个模块使用 `_Ops` 后缀，50+ 个使用 `_Algo` 后缀，覆盖了注册、分派、管理、校验、搜索、域入口、解析、构建等完全不同的职责——这两个后缀已沦为"什么都是"的空壳。

**核心规则：新文件禁止默认使用 `_Ops` 或 `_Algo`**。必须按以下决策表选择精确后缀：

| 若模块主要做…                   | 精确后缀           | 典型迁移                                                        |
| -------------------------------- | ------------------ | --------------------------------------------------------------- |
| 静态注册表（材料/单元/插件注册） | **Reg**      | `PH_ElemReg_Ops` → `PH_ElemReg`                            |
| 动态分派（vtable/函数指针解析）  | **Dsp**      | `PH_ElemFeDispatch_Ops` → `PH_ElemFeDsp`                   |
| 门面管理器（对外统一入口）       | **Mgr**      | `MD_MeshMgr_Ops` → `MD_MeshMgr`                            |
| 域入口薄门面                     | **Domain**   | `MD_MeshDomain_Ops` → `MD_MeshDomain`                      |
| 对外稳定薄封装                   | **Facade**   | `PH_ElemStructuralFacade_Ops` → `PH_ElemStructuralFacade`  |
| 校验/检查                        | **Validate** | `MD_ElemValidate_Ops` → `MD_ElemValidate`                  |
| 双域/双缓冲镜像同步              | **Sync**     | `MD_MeshSync_Ops` → `MD_MeshSync`                          |
| 搜索算法专页                     | **Search**   | `PH_ContSearch_Ops` → `PH_ContSearch`                      |
| 热力学耦合                       | **Thermo**   | `PH_ContThermoMech_Ops` → `PH_ContThermo`                  |
| 评估/计算入口                    | **Eval**     | `PH_MatEval_Ops` → `PH_MatEval`                            |
| 跨层桥接                         | **Brg**      | `PH_BrgL3_Ops` → `PH_BrgL3`                                |
| Populate 专页                    | **Pop**      | `MD_ElemPopulate_Ops` → `MD_ElemPopulate`                  |
| 合同/契约检查                    | **Contract** | `PH_L4L3MatContract_Ops` → `PH_L4L3MatContract`            |
| 跨域接口（同层不同域）           | **Iface**    | `PH_CrossDomainInterfaces_Ops` → `PH_CrossDomainIface`     |
| 语义映射                         | **Map**      | `MD_ElemInpMap_Ops` → `MD_ElemInpMap`                      |
| 索引图式                         | **Idx**      | `MD_LBC_Idx`（已对齐）                                        |
| 库函数集                         | **Lib**      | `MD_ModelLib_Algo`（已对齐）                                  |
| SIO 过程单元                     | **Proc**     | `MD_Step_Proc`（已对齐）、`RT_WBProc_Algo`（Proc 在功能位） |
| 实现专页                         | **Impl**     | `RT_StepImpl_Algo`（Impl 在功能位）、`RT_WBImpl_Algo`       |
| 执行专页                         | **Exec**     | `RT_StepExec_Algo`（Exec 在功能位）                           |
| 工具函数集                       | **Util**     | `RT_AsmUtil_Algo`（Util 在功能位）                            |
| 装配流水线                       | **Asm**      | `RT_AsmSolv_Algo`（Asm 在功能位）                             |
| 输入解析/词法分析                | **Parse**    | `MD_KWParser_Algo`（Parse 在功能位）                          |
| 构建/生成                        | **Build**    | `MD_ModelBuilder_Algo`（Build 在功能位）                      |
| 输出写入器                       | **Writer**   | `RT_WriterODB_Algo`（Writer 在功能位）                        |
| 持久化/序列化                    | **Persist**  | `IF_IO_Persist_Algo`（Persist 在功能位）                      |
| 备份/恢复                        | **Backup**   | `IF_IO_Backup_Algo`（Backup 在功能位）                        |
| 协调器（多物理场）               | **Crd**      | `RT_MFCoordinator_Algo` → `RT_MFCrd`                       |
| 收敛判定                         | **Conv**     | `RT_SolvContResidual_Algo` → `RT_SolvConv`                 |
| Workspace                        | **Wsp**      | `RT_StepWS_Algo` → `RT_StepWsp`                            |
| 内存/资源池                      | **Pool**     | `RT_CoreMemPool_Algo`（Pool 在功能位）                        |
| 形函数/场成形                    | **Shape**    | `PH_ElemShapeFunc_Ops` → `PH_ElemShape`                    |
| 摩擦算法                         | **Friction** | `PH_ContFriction_Ops` → `PH_ContFriction`                  |
| 磨损演化                         | **Wear**     | `PH_ContWearEvolution_Ops` → `PH_ContWear`                 |
| 本构计算/单元计算（确实混合）    | **Ops**      | `PH_Cont_Ops`、`PH_ElemContm_Ops`（保留——真正混合）       |
| 对外稳定 ABI                     | **API**      | `IF_StructFormat_API`（已对齐）                               |

**迁移原则**：

- **存量不强制改名**：现有 `_Ops`/`_Algo` 文件保持不变，不阻塞开发
- **新文件强制精确**：新建模块必须先查决策表，不能用 `_Ops`/`_Algo` 逃逸
- **重构时顺便迁移**：修改已有文件时，同时改名为精确后缀
- **真正混合的操作可以保留 `_Ops`**：如 `PH_Cont_Ops`（接触核心既有搜索又有评估又有分派）
- **"功能位"与"后缀位"**：仓库中很多模块把语义词放在功能位（如 `RT_StepImpl_Algo` 中 `Impl` 在功能位、`_Algo` 在后缀位）。新文件若后缀位可精确表达，则语义词不再需要在功能位重复

---

## 四、数据四型 TYPE 命名

### 4.1 四型定义

| DataKind        | 后缀       | 含义       | 生命周期   | 仓库实例            |
| --------------- | ---------- | ---------- | ---------- | ------------------- |
| **Desc**  | `_Desc`  | 只读配置   | Write-Once | `MD_Output_Desc`  |
| **State** | `_State` | 运行时状态 | 可写       | `MD_Output_State` |
| **Algo**  | `_Algo`  | 算法描述符 | 偏静态     | `MD_Output_Algo`  |
| **Ctx**   | `_Ctx`   | 上下文胶水 | 每步可变   | `MD_Output_Ctx`   |

### 4.2 TYPE 命名格式

```
TYPE :: {层缀}_{域缩}_{功能}_{四型后缀}
```

**仓库实例**：

| TYPE 名                    | 拆解                                |
| -------------------------- | ----------------------------------- |
| `MD_Output_Desc`         | MD + Output + _ + Desc              |
| `MD_Output_State`        | MD + Output + _ + State             |
| `MD_Output_Algo`         | MD + Output + _ + Algo              |
| `MD_Output_Ctx`          | MD + Output + _ + Ctx               |
| `PH_Contm_Args`          | PH + Contm + _ + Args（SIO 参数束） |
| `PH_Elem_Truss_Args`     | PH + Elem + Truss + Args            |
| `PH_Geostatic_Algo_Args` | PH + Geostatic + Algo + Args        |

### 4.3 _Args 后缀（SIO 参数束）

`_Args` 不是数据四型之一，而是 SIO（结构化 IO）的**统一参数束**：

```fortran
TYPE :: PH_Contm_Args
  ! [IN]  字段
  ! [OUT] 字段
END TYPE
```

`_Args` 可出现在 TYPE 名和文件名中（如 `PH_MathTensor_Ops.f90` 中定义 `PH_Math_Tensor_Args`）。

### 4.4 四型在 _Def.f90 中的组织

四型 TYPE 定义在 `_Def.f90`（或同文件），**不**与过程混放在 `_Ops.f90` 中：

```
PH_Load_Def.f90   → TYPE :: PH_Load_Desc, PH_Load_State, PH_Load_Algo, PH_Load_Ctx
PH_Load_Ops.f90   → SUBROUTINE PH_Load_Init, PH_Load_Eval, ...
```

---

## 五、子程序命名

### 5.1 命名格式

```
SUBROUTINE {层缀}_{域缩}_{功能}_{动词}_{具体}
```

### 5.2 功能动词集（从仓库提炼，可选）

| 动词                | 含义           | 仓库实例                                           |
| ------------------- | -------------- | -------------------------------------------------- |
| **Init**      | 初始化         | `MD_L3_Init`、`PH_L4_Init`                     |
| **Finalize**  | 终结/清理      | `MD_L3_Finalize`、`PH_L4_Finalize`             |
| **Populate**  | 灌入/填充      | `PH_Mat_Populate`、`PH_Elem_Populate`          |
| **Eval**      | 评估/计算      | `PH_Mat_Elas_Eval`、`PH_NLGeomEval_*`          |
| **Compute**   | 计算（偏具体） | `PH_PoreField_Compute`、`PH_TempField_Compute` |
| **Update**    | 更新           | `PH_Mat_Elas_Update`                             |
| **Get**       | 查询/读取      | `MD_Node_GetCoords`                              |
| **Set**       | 设置/写入      | `MD_Node_SetCoords`、`MD_Node_SetDOF`          |
| **Validate**  | 校验           | `MD_Bind_Validate`、`MD_ElemValidate_*`        |
| **Sync**      | 同步           | `MD_L3_SyncModelCounts`、`MD_Mesh_Sync`        |
| **Bind**      | 绑定           | `MD_Domains_Bind`                                |
| **Freeze**    | 冻结           | `MD_L3_Freeze`                                   |
| **Create**    | 创建           | `MD_Node_Create`                                 |
| **Destroy**   | 销毁           | `MD_Node_Destroy`                                |
| **Log**       | 日志           | `PH_UnregElemTypes_Log`                          |
| **Check**     | 检查           | `RT_Solv_CheckConvergence`（预留）               |
| **Assemble**  | 装配           | `RT_Assembly_Assemble`（预留）                   |
| **Solve**     | 求解           | `RT_Solver_Solve`（预留）                        |
| **Step**      | 步进           | `RT_StepDriver_Advance`（预留）                  |
| **Config**    | 配置           | `RT_Solver_Config`（预留）                       |
| **WriteBack** | 回写           | `RT_WB_WriteBack`（预留）                        |
| **Output**    | 输出           | `RT_Output_WriteField`（预留）                   |

**注意**：

- 不是每个模块都需要全部动词——**按功能需要选择**
- `Compute` 和 `Eval` 均可使用，`Compute` 偏具体操作名（`ComputePore`），`Eval` 偏评估入口（`Mat_Elas_Eval`）
- 仓库中 `Populate` 是高频词，专门用于 L3→L4 数据灌入

### 5.3 子程序参数签名

标准四型平级传递：

```fortran
SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, status)
  TYPE(PH_Mat_Elas_Desc),  INTENT(IN)    :: desc    ! 只读配置
  TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state   ! 可写状态
  TYPE(PH_Mat_Elas_Algo),  INTENT(IN)    :: algo    ! 算法描述
  TYPE(PH_Mat_Elas_Ctx),   INTENT(IN)    :: ctx     ! 上下文
  INTEGER,                  INTENT(OUT)   :: status  ! 状态码
END SUBROUTINE
```

**关键约束**：

- **Desc 只读**：`INTENT(IN)`，任何层禁止运行时修改
- **State 可写**：`INTENT(INOUT)`，但"写什么"由功能决定
- **Algo 偏静态**：`INTENT(IN)`
- **Ctx 每步可变**：`INTENT(IN)` 或 `INTENT(INOUT)`（视是否修改上下文）

---

## 六、变量命名

### 6.1 四型实例变量

四型 TYPE 的实例变量用**小写+缩写**：

| TYPE        | 实例命名    | 示例                           |
| ----------- | ----------- | ------------------------------ |
| `*_Desc`  | `*_desc`  | `mat_desc`、`elem_desc`    |
| `*_State` | `*_state` | `mat_state`、`elem_state`  |
| `*_Algo`  | `*_algo`  | `mat_algo`、`solv_algo`    |
| `*_Ctx`   | `*_ctx`   | `mat_ctx`、`step_ctx`      |
| `*_Args`  | `*_args`  | `contm_args`、`truss_args` |

### 6.2 普通变量

| 类型              | 风格                 | 示例                                      |
| ----------------- | -------------------- | ----------------------------------------- |
| 局部变量          | snake_case           | `strain_increment`、`young_modulus`   |
| 循环计数          | `i`, `j`, `k`  | `i_elem`, `j_ip`                      |
| 状态标志          | `is_*` / `has_*` | `is_converged`、`has_damage`          |
| 常量（PARAMETER） | UPPER_SNAKE_CASE     | `MAX_ITERATIONS`、`DEFAULT_TOLERANCE` |

### 6.3 禁止

- **禁止**无意义缩写：`val` → `stress_value`；`tmp` → `temp_stress`
- **禁止**全局变量：用 Ctx 传递，不用 `SAVE` + 全局 `MODULE VARIABLE`
- **禁止**单字母变量（循环计数除外）：`n` → `n_elements`；`f` → `internal_force`

---

## 七、错误处理

### 7.1 使用仓库已有基础设施

```fortran
USE IF_Err_Type, ONLY: ErrorStatusType
```

**禁止重新定义** `ErrorStatusType` 或 `error_status`。L1_IF 已有完整错误处理体系：

- `IF_Err_Type`：错误类型定义
- `IF_Err_API`：错误处理接口
- `IF_Err_Brg`：跨层错误桥接

### 7.2 状态码约定

| 约定           | 含义       |
| -------------- | ---------- |
| `status = 0` | 成功       |
| `status > 0` | 非致命警告 |
| `status < 0` | 致命错误   |

---

## 八、代码格式

### 8.1 缩进与行宽

- 缩进：2 个空格（不用 Tab）
- 行宽：不超过 120 字符
- 续行：`&` 对齐

### 8.2 注释

```fortran
!===============================================================================
! Module:  PH_Mat_Elas_Ops
! Layer:   L4_PH — Physics Computation Layer
! Domain:  Material — Elastic Constitutive
! Purpose: 弹性材料本构评估
!
! 功能流程:
!   Step 1: Init    — 校验参数、构建合法 Desc
!   Step 2: Eval    — 给定应变增量，计算应力与切线
!   Step 3: Update  — 推进 State 到下一增量
!
! 依赖:
!   - L3_MD/Material/Elas: 材料参数 (MD_Mat_Elas_Desc)
!   - L1_IF/Err: 错误处理 (IF_Err_Brg)
!===============================================================================
```

### 8.3 INTENT 声明

**每个哑参必须显式声明 INTENT**：

```fortran
! ✅ 正确
SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, status)
  TYPE(PH_Mat_Elas_Desc),  INTENT(IN)    :: desc
  TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state
  ...

! ❌ 错误：缺少 INTENT
SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, status)
  TYPE(PH_Mat_Elas_Desc)  :: desc
  TYPE(PH_Mat_Elas_State) :: state
  ...
```

---

## 九、命名检查清单

### 9.1 文件/模块命名

- [ ] MODULE 名以层缀开头（`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`）
- [ ] MODULE 名与文件名一致（不含 `.f90`）
- [ ] 后缀使用 **§3.2** 闭集（A–H）中已登记项，或采用 **§1.3 新码无后缀** 主模块策略并在 `CONTRACT.md` 说明
- [ ] 无 `_Desc`/`_State`/`_Algo`/`_Ctx` 作文件后缀（四型仅用于 TYPE）
- [ ] 无数字尾巴 `*_*1`（新文件）

### 9.2 TYPE 命名

- [ ] TYPE 名以层缀开头
- [ ] 四型后缀正确（`_Desc`/`_State`/`_Algo`/`_Ctx`）
- [ ] `_Args` 仅用于 SIO 参数束
- [ ] 四型 TYPE 定义在 `_Def.f90` 中（不与过程混放）

### 9.3 子程序命名

- [ ] 子程序名以层缀开头
- [ ] 功能动词在可选集中（或新增已登记）
- [ ] 参数签名使用四型平级传递
- [ ] 每个哑参显式声明 INTENT

### 9.4 变量命名

- [ ] 四型实例用小写缩写（`mat_desc`、`elem_state`）
- [ ] 局部变量用 snake_case
- [ ] PARAMETER 用 UPPER_SNAKE_CASE
- [ ] 无全局变量（用 Ctx 传递）

---

## 十、v1.0 → v2.0 迁移对照

| v1.0 提法                                              | v2.0 修正                                    | 原因                                      |
| ------------------------------------------------------ | -------------------------------------------- | ----------------------------------------- |
| `mod_mat_elastic.f90`                                | `PH_Mat_Elas_Ops.f90`                      | `mod_` 前缀不存在于仓库                 |
| `mat_elastic_desc`（snake_case）                     | `PH_Mat_Elas_Desc`（PascalCase）           | 仓库用 PascalCase                         |
| `mat_elastic_init`（snake_case）                     | `PH_Mat_Elas_Init`（PascalCase）           | 仓库用 PascalCase                         |
| `ErrorStatusType`（自定义）                          | `IF_Err_Type`（仓库已有）                  | 不重新定义                                |
| Ctx 持有 State 指针                                    | 四型平级传递                                 | Ctx 不"拥有"State                         |
| `init→compute→update→validate→finalize` 五步强制 | 功能动词可选集                               | 不是所有模块都需要五步                    |
| `compute` 统一动词                                   | `Eval`/`Compute`/`Populate`/... 按需选 | 仓库实际更丰富                            |
| 后缀只列 7 项                                          | 后缀闭集 46 项（8 组 A-H）                   | 与 v1.8 对齐 + 从 `_Ops`/`_Algo` 拆出 |
| `_Algo` 完全禁止作文件后缀                           | 存量保留，新增优先选更精确后缀               | 仓库中 `_Algo` 后缀大量存在             |
| `_Ops` 作为默认后缀                                  | `_Ops` 降级为后备后缀                      | 60+ 文件全用 `_Ops`，后缀无信息量       |

---

## 十一、参考文档

| 文档             | 路径                                                         | 用途               |
| ---------------- | ------------------------------------------------------------ | ------------------ |
| 架构总纲 v5.0    | `docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md` | 上位设计指导 |
| 主责正交矩阵     | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` | 四型字面、ProcKind、扩展后缀 |
| 统一命名方案     | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` | 三级体系总则 |
| 功能模块清单     | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` | 分层查表 |
| 过程命名规范     | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` | 子程序动词 |
| 目录权威分类     | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md` | 目录结构 |

---

*最后更新：2026-04-24（套件交叉索引与清单 §9 对齐）*
*文档版本：v2.0*
