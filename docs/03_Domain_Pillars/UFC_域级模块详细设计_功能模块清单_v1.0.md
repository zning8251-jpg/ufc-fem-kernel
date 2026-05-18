# UFC 域级模块详细设计 — 功能模块清单 v1.0

> **版本**: v1.0 | **日期**: 2026-04-23
> **文档地位**: **仓库模块枚举与查表**；命名总则见 **统一命名方案**，细则与后缀闭集见 **命名规范与接口标准 v2.0**。
> **命名约束**: `_Desc/_State/_Algo/_Ctx` **仅用于 TYPE**，禁止用于 MODULE/文件名。**双轨**：新码主模块 **默认无 `_Ops`**；存量 `*_Ops.f90` **保留**；专用角色后缀 `_Def/_Brg/_Proc/_Idx/_Reg/...` 见 **统一命名方案 §3.2–3.4** 与 **命名规范 v2 §3.2**。

---

## 文档元数据

| 属性 | 值 |
|------|-----|
| **规范简称** | UFC_Domain_Module_Inventory_v1 |
| **配套命名** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md`；`UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md`；`UFC/REPORTS/UFC_过程命名规范_v1.0.md` |
| **上位参考** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md`；`UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` |

---

## 〇、REPORTS 命名文档套件（交叉索引）

| 文档 | 路径 | 职责 |
|------|------|------|
| **统一命名方案** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` | 三级体系总则；默认无 `_Ops` 与双轨 |
| **命名与接口标准 v2** | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` | 细则；§3.2 后缀闭集（A–H） |
| **过程命名规范** | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` | 子程序动词 |
| **本文（功能模块清单）** | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` | 分层模块枚举（表内 `_Ops` 多为 **存量**） |
| **主责正交矩阵** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` | 四型字面禁作文件名 |
| **域级模块规范** | `UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` | 域级目录与 SIO |

---

## 一、L1_IF 基础设施层 (~63个文件)

### Base/ (含 AI/, Parallel/, Symbol/)

| 模块名                        | 职责               | 后缀角色       |
| ----------------------------- | ------------------ | -------------- |
| IF_Base_Ops                   | 基础类型操作       | _Ops           |
| IF_Base_DP_Ops                | 双精度操作         | _Ops           |
| IF_Base_StructMeta_Def        | 结构化元数据定义   | _Def           |
| IF_Base_UnstructMeta_Def      | 非结构化元数据定义 | _Def           |
| IF_Base_SymTbl_Ops            | 符号表操作         | _Ops           |
| IF_Math_Util_Ops              | 数学工具           | _Ops           |
| IF_Step_Def                   | 步定义             | _Def           |
| IF_Device_Mgr_Ops             | 设备管理           | _Mgr           |
| IF_AI_Ops / _Def / _Brg       | AI核心             | _Ops/_Def/_Brg |
| IF_AI_ModelLoader_Ops         | 模型加载           | _Ops           |
| IF_AI_Preprocess_Ops          | 预处理             | _Ops           |
| IF_AI_Runtime_Ops             | 运行时推理         | _Ops           |
| IF_AI_TensorOps_Ops           | 张量运算           | _Ops           |
| IF_ThreadWS_Ops / _Def / _Brg | 并行工作空间       | _Ops/_Def/_Brg |
| IF_Sym_Ops / _Def / _Brg      | 符号处理           | _Ops/_Def/_Brg |
| IF_Sym_Stiffness_Ops          | 刚度符号运算       | _Ops           |
| IF_Sym_Strain_Ops             | 应变符号运算       | _Ops           |
| IF_Sym_Stress_Ops             | 应力符号运算       | _Ops           |

### Error/

| 模块名         | 职责                                | 后缀角色 |
| -------------- | ----------------------------------- | -------- |
| IF_Err_Ops     | 错误处理核心                        | _Ops     |
| IF_Err_Def     | 错误类型定义(TYPE: ErrorStatusType) | _Def     |
| IF_Err_Brg     | 错误桥接                            | _Brg     |
| IF_Err_Reg_Ops | 错误注册                            | _Ops     |

### IO/ (含 Checkpoint/)

| 模块名                | 职责             | 后缀角色  |
| --------------------- | ---------------- | --------- |
| IF_IO_Ops / _Def      | IO核心           | _Ops/_Def |
| IF_IO_File_Ops        | 文件操作         | _Ops      |
| IF_IO_Filters_Ops     | IO过滤           | _Ops      |
| IF_IO_Log_Ops         | IO日志           | _Ops      |
| IF_Parser_Ops         | 解析器           | _Ops      |
| IF_Writer_Ops         | 写入器           | _Ops      |
| IF_IO_Backup_Ops      | 备份             | _Ops      |
| IF_IO_Persist_Ops     | 持久化           | _Ops      |
| IF_IO_StructFile_Ops  | 结构化文件       | _Ops      |
| IF_StructFormat_API   | 结构化格式API    | _API      |
| IF_UnstructFile_Mgr   | 非结构化文件管理 | _Mgr      |
| IF_UnstructFormat_API | 非结构化格式API  | _API      |

### Log/

| 模块名            | 职责       | 后缀角色  |
| ----------------- | ---------- | --------- |
| IF_Log_Ops / _Def | 日志核心   | _Ops/_Def |
| IF_Log_Logger_Ops | 日志记录器 | _Ops      |

### Memory/

| 模块名            | 职责       | 后缀角色 |
| ----------------- | ---------- | -------- |
| IF_Mem_Ops        | 内存操作   | _Ops     |
| IF_Mem_Chunk_Ops  | 内存块     | _Ops     |
| IF_Mem_Mgr_Ops    | 内存管理器 | _Ops     |
| IF_Mem_Serial_Ops | 序列化内存 | _Ops     |

### Monitor/

| 模块名                  | 职责     | 后缀角色 |
| ----------------------- | -------- | -------- |
| IF_Monitor_Timer_Ops    | 计时器   | _Ops     |
| IF_Monitor_Profiler_Ops | 性能分析 | _Ops     |

### Precision/

| 模块名      | 职责                  | 后缀角色 |
| ----------- | --------------------- | -------- |
| IF_Prec_Def | 精度定义 (wp, i4, i8) | _Def     |

### Registry/

| 模块名            | 职责   | 后缀角色  |
| ----------------- | ------ | --------- |
| IF_Reg_Ops / _Def | 注册表 | _Ops/_Def |

---

## 二、L2_NM 数值方法层 (~25个文件)

### Base/ (含 BVH/)

| 模块名               | 职责         | 后缀角色 |
| -------------------- | ------------ | -------- |
| NM_Base_Def          | 数值基础定义 | _Def     |
| NM_Base_ErrCodes_Def | 错误码       | _Def     |
| NM_Base_Utils_Ops    | 数值工具     | _Ops     |
| NM_BVH_Ops           | BVH操作      | _Ops     |

### Bridge/

| 模块名     | 职责       | 后缀角色 |
| ---------- | ---------- | -------- |
| NM_Brg_Ops | 外部库桥接 | _Ops     |

### Matrix/

| 模块名           | 职责     | 后缀角色 |
| ---------------- | -------- | -------- |
| NM_MatDense_Ops  | 稠密矩阵 | _Ops     |
| NM_MatSparse_Ops | 稀疏矩阵 | _Ops     |
| NM_MatCSR_Ops    | CSR格式  | _Ops     |
| NM_MatCOO_Ops    | COO格式  | _Ops     |
| NM_Mat_Util_Ops  | 矩阵工具 | _Ops     |

### Solver/ (LinSolv/, NonlinSolv/, AI/, Conv/, Coupling/, Parallel/)

| 模块名                 | 职责                    | 后缀角色 |
| ---------------------- | ----------------------- | -------- |
| NM_SolvDirect_Ops      | 直接求解 (LU, Cholesky) | _Ops     |
| NM_SolvIter_Ops        | 迭代求解 (CG, GMRES)    | _Ops     |
| NM_SolvPrecond_Ops     | 预处理器                | _Ops     |
| NM_SolvNewton_Ops      | Newton法                | _Ops     |
| NM_SolvQuasiNewton_Ops | 拟Newton法 (BFGS, DFP)  | _Ops     |
| NM_SolvArcLen_Ops      | 弧长法                  | _Ops     |
| NM_SolvAI_Ops          | AI增强求解              | _Ops     |
| NM_SolvConv_Ops        | 收敛性算法              | _Ops     |
| NM_SolvCoupling_Ops    | 耦合求解                | _Ops     |
| NM_SolvParallel_Ops    | 并行求解                | _Ops     |

### TimeInt/

| 模块名              | 职责                  | 后缀角色 |
| ------------------- | --------------------- | -------- |
| NM_TimeExplicit_Ops | 显式积分 (Euler, RK4) | _Ops     |
| NM_TimeImplicit_Ops | 隐式积分 (Newmark)    | _Ops     |
| NM_TimeAdaptive_Ops | 自适应步长            | _Ops     |
| NM_TimeNewmark_Ops  | Newmark-β            | _Ops     |

---

## 三、L3_MD 模型数据层 (~70+个文件)

### Analysis/ (Amplitude/, Solver/, Step/)

| 模块名      | 职责                                    | 后缀角色 |
| ----------- | --------------------------------------- | -------- |
| MD_Step_Def | 分析步定义 (TYPE: MD_Step_Desc, _State) | _Def     |
| MD_Step_Ops | 分析步操作                              | _Ops     |
| MD_Amp_Ops  | 幅值曲线                                | _Ops     |
| MD_Solv_Def | 求解器控制定义                          | _Def     |

### Assembly/

| 模块名          | 职责       | 后缀角色 |
| --------------- | ---------- | -------- |
| MD_Assem_Ops    | 装配体操作 | _Ops     |
| MD_Assem_Domain | 装配体域   | Domain   |
| MD_Instance_Ops | 实例操作   | _Ops     |

### Boundary/

| 模块名        | 职责         | 后缀角色 |
| ------------- | ------------ | -------- |
| MD_BC_Def     | 边界条件定义 | _Def     |
| MD_LBC_Ops    | 载荷边界操作 | _Ops     |
| MD_LBC_Brg    | 载荷边界桥接 | _Brg     |
| MD_LBC_Domain | 载荷边界域   | Domain   |
| MD_LBC_Idx    | 载荷边界索引 | _Idx     |
| MD_Load_Def   | 载荷定义     | _Def     |

### Bridge/ (Bridge_L4/, Bridge_L5/)

| 模块名       | 职责       | 后缀角色 |
| ------------ | ---------- | -------- |
| MD_BrgL4_Ops | L3→L4桥接 | _Ops     |
| MD_BrgL5_Ops | L3→L5桥接 | _Ops     |

### Constraint/

| 模块名                      | 职责       | 后缀角色 |
| --------------------------- | ---------- | -------- |
| MD_Constraint_Def           | 约束定义   | _Def     |
| MD_Const_Ops                | 约束操作   | _Ops     |
| MD_ConstraintPairDef_Ops    | 约束对定义 | _Ops     |
| MD_ConstraintPropDB_Ops     | 约束属性库 | _Ops     |
| MD_ConstraintSurfBridge_Ops | 约束面桥接 | _Ops     |
| MD_ConstraintSync_Ops       | 约束同步   | _Ops     |

### Field/

| 模块名       | 职责                             | 后缀角色 |
| ------------ | -------------------------------- | -------- |
| MD_Field_Def | 场变量定义 (TYPE: MD_Field_Desc) | _Def     |

### Interaction/

| 模块名           | 职责     | 后缀角色 |
| ---------------- | -------- | -------- |
| MD_Int_Def       | 交互定义 | _Def     |
| MD_Int_Ops       | 交互操作 | _Ops     |
| MD_IntMgr_Ops    | 交互管理 | _Ops     |
| MD_IntMapper_Ops | 交互映射 | _Ops     |
| MD_IntParser_Ops | 交互解析 | _Ops     |
| MD_IntSync_Ops   | 交互同步 | _Ops     |
| MD_Cont_Ops      | 接触操作 | _Ops     |
| MD_Connector_Ops | 连接器   | _Ops     |
| MD_HashTable_Ops | 哈希表   | _Ops     |

### KeyWord/

| 模块名                  | 职责       | 后缀角色 |
| ----------------------- | ---------- | -------- |
| MD_KW_Def               | 关键字定义 | _Def     |
| MD_KW_Ops               | 关键字操作 | _Ops     |
| MD_KWParser_Ops         | 解析器     | _Ops     |
| MD_KWLexer_Ops          | 词法分析   | _Ops     |
| MD_KWDispatch_Ops       | 分发       | _Ops     |
| MD_KWReg_Ops            | 注册       | _Ops     |
| MD_KWMapper_Ops         | 映射       | _Ops     |
| MD_KeyWordDomain_Ops    | 关键字域   | _Ops     |
| MD_KeyWordValidator_Ops | 校验       | _Ops     |
| MD_InpParse_Ops         | 输入解析   | _Ops     |

### Material/（11 主族 + legacy 治理）

| 模块名 / 路径 | 职责 | 后缀角色 |
| ------------- | ---- | -------- |
| Contract/MD_Mat_Def | 材料 Desc/State/Algo/Ctx、类别/模型 ID、UMAT/VUMAT 数据合同真源 | _Def |
| Domain/MD_MatDomain_Def | L3 Material 容器生命周期、注册、查询、状态分配 | _Def / Domain |
| Domain/MD_Mat_Mgr | 兼容再导出，不另立真源 | _Mgr |
| Registry/MD_MatReg_Algo | 材料模型注册与默认清单；正在收窄对 legacy lib 的依赖 | _Algo |
| Dispatch/MD_Mat_Lib | legacy aggregate；保留 facade，冻结热路径本构扩展 | Legacy |
| Shared/MD_Mat_Legacy_State | 从 `MD_Mat_Lib` 拆出的 legacy state 数据合同 | _State |
| Bridge/MD_Mat_Brg | UMAT/VUMAT bundle 兼容边界，不扩展本构热路径 | _Brg |
| Bridge/MD_MatRT_Brg | legacy hot-path dispatch，迁移对象 | _Brg |

> 当前 11 主族治理矩阵：`Elas/`、`Plast/`、`Geo/`、`HyperElas/`、`Viscoelas/`、`Creep/`、`Damage/`、`Composite/`、`Thermal/`、`Acoustic/`、`User/`。详见 `ufc_core/L3_MD/Material/GOVERNANCE.md`。

### Mesh/

| 模块名           | 职责         | 后缀角色 |
| ---------------- | ------------ | -------- |
| MD_Mesh_Def      | 网格定义     | _Def     |
| MD_Mesh_Core_Ops | 网格核心操作 | _Ops     |

### Model/

| 模块名            | 职责         | 后缀角色 |
| ----------------- | ------------ | -------- |
| MD_Model_Def      | 模型定义     | _Def     |
| MD_Model_Core_Ops | 模型核心操作 | _Ops     |

### 其他域级

| 模块名           | 域级      | 职责     | 后缀角色 |
| ---------------- | --------- | -------- | -------- |
| MD_Part_Ops      | Part      | 零件管理 | _Ops     |
| MD_Section_Def   | Section   | 截面定义 | _Def     |
| MD_Section_Ops   | Section   | 截面操作 | _Ops     |
| MD_Output_Def    | Output    | 输出配置 | _Def     |
| MD_WriteBack_Ops | WriteBack | 结果写回 | _Ops     |

---

## 四、L4_PH 物理计算层 (~65个文件)

### Bridge/

| 模块名           | 职责   | 后缀角色 |
| ---------------- | ------ | -------- |
| PH_BrgDomain_Ops | 域桥接 | _Ops     |
| PH_BrgL2_Ops     | L2桥接 | _Ops     |
| PH_BrgL3_Ops     | L3桥接 | _Ops     |

### Constraint/

| 模块名                  | 职责         | 后缀角色 |
| ----------------------- | ------------ | -------- |
| PH_ConstrMPC_Ops        | MPC约束计算  | _Ops     |
| PH_ConstrMPC_Def        | MPC约束定义  | _Def     |
| PH_ConstrMPC_Brg        | MPC约束桥接  | _Brg     |
| PH_ConstrTie_Ops        | Tie约束计算  | _Ops     |
| PH_ConstrTie_Def        | Tie约束定义  | _Def     |
| PH_ConstrPeriod_Ops     | 周期约束计算 | _Ops     |
| PH_ConstrPeriod_Def     | 周期约束定义 | _Def     |
| PH_ConstraintDomain_Ops | 约束域管理   | _Ops     |

### Element/

| 模块名                      | 职责                                      | 后缀角色 |
| --------------------------- | ----------------------------------------- | -------- |
| PH_Elem_Def                 | 单元类型定义 (TYPE: PH_Elem_Desc, _State) | _Def     |
| PH_ElemContm_Ops            | 连续体单元计算                            | _Ops     |
| PH_ElemShapeFunc_Ops        | 形函数计算                                | _Ops     |
| PH_ElemGaussInt_Ops         | 高斯积分                                  | _Ops     |
| PH_ElemKeDispatch_Ops       | 刚度矩阵分发                              | _Ops     |
| PH_ElemFeDispatch_Ops       | 内力向量分发                              | _Ops     |
| PH_ElemMassDispatch_Ops     | 质量矩阵分发                              | _Ops     |
| PH_ElemDomain_Ops           | 单元域管理                                | _Ops     |
| PH_ElemReg_Ops              | 单元注册                                  | _Ops     |
| PH_ElemCalcWrapper_Ops      | 单元计算封装                              | _Ops     |
| PH_ElemNlgeom_Ops           | 非线性几何                                | _Ops     |
| PH_ElemStructuralFacade_Ops | 结构单元外观                              | _Ops     |
| PH_Physical_Def             | 物理量定义                                | _Def     |
| PH_MathTensor_Ops           | 张量运算                                  | _Ops     |
| PH_Mass_Ops                 | 质量计算                                  | _Ops     |
| PH_ElemComplexStiff_Ops     | 复刚度计算                                | _Ops     |

### Field/

| 模块名                      | 职责         | 后缀角色 |
| --------------------------- | ------------ | -------- |
| PH_Field_Def                | 场变量定义   | _Def     |
| PH_Field_ComputeTemp        | 温度场计算   | Compute  |
| PH_Field_ComputePore        | 孔压场计算   | Compute  |
| PH_Field_ComputeConc        | 浓度场计算   | Compute  |
| PH_Field_GaussQuadrature    | 场高斯积分   | Support  |
| PH_Field_ShapeFunc          | 场形函数支持 | ShapeFunc |
| PH_Field_Cpl                | 多物理耦合贡献 | Cpl    |

### LoadBC/

| 模块名                 | 职责           | 后缀角色 |
| ---------------------- | -------------- | -------- |
| PH_BC_Def              | 边界条件定义   | _Def     |
| PH_BC_Ops              | 边界条件计算   | _Ops     |
| PH_BC_Brg              | 边界条件桥接   | _Brg     |
| PH_Ldbc_Ops            | 载荷边界操作   | _Ops     |
| PH_FlatToNestedLBC_Ops | 载荷平铺转嵌套 | _Ops     |

### Material/

| 模块名 / 路径 | 职责 | 后缀角色 |
| ------------- | ---- | -------- |
| PH_Mat_Domain_Core | L4 Material slot/container 真源，承载 `PH_Mat_Domain`、`PH_Mat_Slot`、`PH_MAT_*` 枚举与 Idx API | Domain |
| PH_Mat_Core | 当前 Material core/facade 兼容入口 | Core |
| Base/PH_Mat_BaseDefn | Base definition 与通用更新接口 | _Defn |
| Base/PH_Mat_Reg | Kernel registry / lookup 兼容层 | _Reg |
| Base/PH_Mat_Dispatch | Base dispatch 兼容层 | Dispatch |
| Contract/*.f90 | 本构点、UMAT、creep/damage/geotech/hyper/thermal/visc 等接口合同 | Contract |
| Dispatch/*.f90 | Eval facade、PLM dispatch、legacy UMAT facade | Dispatch |
| Elas/、Plast/、Geo/、Damage/、Composite/ | 当前已落盘家族内核目录 | Kernel |
| AI/PH_AI_MatInteg | 可选 AI material integration slot | AI |

> 当前 L4 Material manifest 已按 36 个真实 `.f90` 源文件重建；详见 `ufc_core/L4_PH/Material/GOVERNANCE.md`。旧 `PH_Mat_Reg_Core` / `PH_Mat_Elastic_Ops` 等报告名不再作为文件真源。
> CPE4/CPS4/C3D8 hot-path 首批示范已建立：`PH_Elem_*_Material_Update_Routed` 使用 `RT_Mat_Dispatch_Ctx -> PH_Mat_Slot -> PH_Mat_Elas_Core`；三个结构化入口已通过 `elem_cfg%mat_id` 接入 Section/Element `mat_pt_idx` 真映射。纯机械 continuum helper 已覆盖 CPE/CPS、CAX、C3D 与 C3D8EAS/FBar；Truss/Pipe/Spring/Dashpot/Mass 已覆盖各自 1D 或 scalar route；Beam 已覆盖 `E/nu` elastic constants route；Acoustic 已覆盖 `density/bulk_modulus/sound_speed` route；Porous 已覆盖 two-phase 参数 route；Cohesive/Gasket 已覆盖 interface-law route；Infinite 已覆盖 decay route；Thermal shell 族已覆盖 `DS3/DS4/DS6/DS8` scalar conductivity helper；Membrane/Shell membrane subpath 已覆盖 `M3D9R/S4/S8/S9/S4T/S8RT` plane-stress helper 与 `S3/S6` 当前 CPE-based helper；shared thermo-elastic helper 已锁定 `dstrain_total - thermal_strain` 的 mechanical route 边界，`Solid2Dt` 的 `CPE/CPS/CAX` 与 `Solid3Dt` 的 `C3D` 同族 wrappers 已接入。`Rigid/RotaryInertia` 已归入 Mass/Inertia/Rigid registry family，但不复用 bulk elastic route，属于约束/惯量元数据路径。单元覆盖后，后续计划回到 Material 域：slot contract、Populate material map、kernel facade、family closure tests、L5 material table 和 state update migration。

---

## 五、L5_RT 运行时协调层 (~72个文件)

### Assembly/

| 模块名                         | 职责           | 后缀角色 |
| ------------------------------ | -------------- | -------- |
| RT_Asm_Def                     | 装配定义       | _Def     |
| RT_Asm_Ops                     | 装配核心操作   | _Ops     |
| RT_AsmGlobal_Ops               | 全局装配       | _Ops     |
| RT_AsmDomain_Ops               | 域装配         | _Ops     |
| RT_AsmDofMap_Ops               | 自由度映射     | _Ops     |
| RT_AsmImpl_Ops                 | 装配实现       | _Ops     |
| RT_AsmProc_Ops                 | 装配过程       | _Ops     |
| RT_AsmSolv_Ops                 | 装配求解       | _Ops     |
| RT_AsmUtil_Ops                 | 装配工具       | _Ops     |
| RT_AsmMassDamp_Ops             | 质量阻尼装配   | _Ops     |
| RT_AsmNLGeomDispatch_Ops       | 非线性几何分发 | _Ops     |
| RT_AsmNLGeomEval_Ops           | 非线性几何评估 | _Ops     |
| RT_AsmShapeBeam_Ops            | 梁形状         | _Ops     |
| RT_AsmShapeMech2D_Ops          | 2D机械形状     | _Ops     |
| RT_AsmShapeMechanicalField_Ops | 机械场形状     | _Ops     |
| RT_AsmShapeMembrane_Ops        | 膜形状         | _Ops     |
| RT_AsmShapeScalarField_Ops     | 标量场形状     | _Ops     |
| RT_AsmShapeShell_Ops           | 壳形状         | _Ops     |

### Bridge/

| 模块名     | 职责     | 后缀角色 |
| ---------- | -------- | -------- |
| RT_Brg_Ops | 桥接操作 | _Ops     |
| RT_Brg_Def | 桥接定义 | _Def     |

### Contact/

| 模块名                | 职责             | 后缀角色 |
| --------------------- | ---------------- | -------- |
| RT_Cont_Def           | 接触定义         | _Def     |
| RT_ContactCore_Ops    | 接触核心         | _Ops     |
| RT_ContCtrl_Ops       | 接触控制         | _Ops     |
| RT_ContExpl_Ops       | 显式接触         | _Ops     |
| RT_ContSearch_Ops     | 接触搜索         | _Ops     |
| RT_ContSolv_Ops       | 接触求解         | _Ops     |
| RT_ContAugLagSolv_Ops | 增广拉格朗日求解 | _Ops     |

### Element/

| 模块名                      | 职责         | 后缀角色 |
| --------------------------- | ------------ | -------- |
| RT_Elem_Def                 | 单元定义     | _Def     |
| RT_ElemProc_Ops             | 单元过程     | _Ops     |
| RT_ElemComputeProc_Ops      | 单元计算过程 | _Ops     |
| RT_ElemDispatcher_Ops       | 单元分发     | _Ops     |
| RT_ElemKernelProc_Ops       | 单元核过程   | _Ops     |
| RT_ElemSect_Ops             | 单元截面     | _Ops     |
| RT_ElemUEL_Ops              | 用户单元     | _Ops     |
| RT_ThermalMechanicalCpl_Ops | 热机械耦合   | _Ops     |

### LoadBC/

| 模块名                 | 职责     | 后缀角色 |
| ---------------------- | -------- | -------- |
| RT_LBC_Def             | 载荷定义 | _Def     |
| RT_LBCProc_Ops         | 载荷过程 | _Ops     |
| RT_LBCImpl_Ops         | 载荷实现 | _Ops     |
| RT_BCReactionForce_Ops | 反力计算 | _Ops     |

### Output/

| 模块名            | 职责     | 后缀角色 |
| ----------------- | -------- | -------- |
| RT_Out_Def        | 输出定义 | _Def     |
| RT_Out_Ops        | 输出操作 | _Ops     |
| RT_OutImpl_Ops    | 输出实现 | _Ops     |
| RT_OutRestart_Ops | 重启输出 | _Ops     |
| RT_WriterHDF5_Ops | HDF5输出 | _Ops     |
| RT_WriterODB_Ops  | ODB输出  | _Ops     |

### Solver/

| 模块名              | 职责       | 后缀角色 |
| ------------------- | ---------- | -------- |
| RT_SolvLinear_Ops   | 线性求解   | _Ops     |
| RT_SolvNonlin_Ops   | 非线性求解 | _Ops     |
| RT_SolvDynamic_Ops  | 动态求解   | _Ops     |
| RT_SolvCoupling_Ops | 耦合求解   | _Ops     |

### 其他域级

| 模块名           | 域级       | 职责       | 后缀角色 |
| ---------------- | ---------- | ---------- | -------- |
| RT_Amp_Ops       | Amplitude  | 幅值曲线   | _Ops     |
| RT_StepDrv_Ops   | StepDriver | 步进驱动   | _Ops     |
| RT_StepAdapt_Ops | StepDriver | 步长自适应 | _Ops     |
| RT_LogSys_Ops    | Logging    | 日志系统   | _Ops     |

---

## 六、L6_AP 应用层 (~26个文件)

### Base/

| 模块名      | 职责         | 后缀角色 |
| ----------- | ------------ | -------- |
| AP_Base_Ops | 应用基础操作 | _Ops     |
| AP_Base_Def | 应用基础定义 | _Def     |

### CLI/

| 模块名            | 职责       | 后缀角色 |
| ----------------- | ---------- | -------- |
| AP_CLI_Ops        | 命令行接口 | _Ops     |
| AP_CLI_Def        | CLI定义    | _Def     |
| AP_CLI_Parser_Ops | CLI解析    | _Ops     |

### Config/

| 模块名                  | 职责     | 后缀角色 |
| ----------------------- | -------- | -------- |
| AP_Config_Ops           | 配置管理 | _Ops     |
| AP_Config_Def           | 配置定义 | _Def     |
| AP_Config_Validator_Ops | 配置验证 | _Ops     |

### GUI/

| 模块名     | 职责     | 后缀角色 |
| ---------- | -------- | -------- |
| AP_GUI_Ops | 图形界面 | _Ops     |
| AP_GUI_Def | GUI定义  | _Def     |

### Job/

| 模块名               | 职责     | 后缀角色 |
| -------------------- | -------- | -------- |
| AP_Job_Ops           | 作业管理 | _Ops     |
| AP_Job_Def           | 作业定义 | _Def     |
| AP_Job_Queue_Ops     | 作业队列 | _Ops     |
| AP_Job_Scheduler_Ops | 作业调度 | _Ops     |
| AP_Job_Monitor_Ops   | 作业监控 | _Ops     |

### Output/

| 模块名                  | 职责       | 后缀角色 |
| ----------------------- | ---------- | -------- |
| AP_Output_Ops           | 输出管理   | _Ops     |
| AP_Output_Def           | 输出定义   | _Def     |
| AP_Output_Formatter_Ops | 输出格式化 | _Ops     |

### Plugin/

| 模块名               | 职责     | 后缀角色 |
| -------------------- | -------- | -------- |
| AP_Plugin_Ops        | 插件管理 | _Ops     |
| AP_Plugin_Def        | 插件定义 | _Def     |
| AP_Plugin_Loader_Ops | 插件加载 | _Ops     |

### SimData/

| 模块名         | 职责         | 后缀角色 |
| -------------- | ------------ | -------- |
| AP_SimData_Ops | 仿真数据     | _Ops     |
| AP_SimData_Def | 仿真数据定义 | _Def     |

### Solver/

| 模块名      | 职责           | 后缀角色 |
| ----------- | -------------- | -------- |
| AP_Solv_Ops | 应用求解器     | _Ops     |
| AP_Solv_Def | 应用求解器定义 | _Def     |

### User/

| 模块名      | 职责     | 后缀角色 |
| ----------- | -------- | -------- |
| AP_User_Ops | 用户管理 | _Ops     |
| AP_User_Def | 用户定义 | _Def     |

### Utils/

| 模块名       | 职责     | 后缀角色 |
| ------------ | -------- | -------- |
| AP_Utils_Ops | 应用工具 | _Ops     |
| AP_Utils_Def | 工具定义 | _Def     |

---

## 七、命名规范总结

### 7.1 MODULE/文件名后缀闭集

| 后缀      | 用途           | 示例                        |
| --------- | -------------- | --------------------------- |
| `_Ops`  | 过程主体（**存量/后备**；新码优先无后缀主模块） | `PH_Mat_Elastic_Ops.f90`  |
| `_Def`  | 类型定义       | `PH_Mat_Elastic_Def.f90`  |
| `_Brg`  | 层间桥接       | `PH_BrgL3_Ops.f90`        |
| `_Core` | 核心实现       | `PH_Mat_Reg_Core.f90`     |
| `_Eval` | 求值计算       | `PH_NLGeomEval_Ops.f90`   |
| `_Idx`  | 索引管理       | `PH_L4Idx_Brg.f90`        |
| `_Reg`  | 注册管理       | `PH_ElemReg_Ops.f90`      |
| `_Mgr`  | 管理器         | `IF_Device_Mgr_Ops.f90`   |
| `_API`  | 外部接口       | `IF_StructFormat_API.f90` |
| `_Ctrl` | 控制           | `RT_ContCtrl_Ops.f90`     |

### 7.2 TYPE 四型后缀(仅用于 TYPE 名称)

| 后缀       | 用途       | 示例                     | 承载 MODULE             |
| ---------- | ---------- | ------------------------ | ----------------------- |
| `_Desc`  | 静态描述   | `PH_Mat_Elastic_Desc`  | 定义在 `*_Def.f90` 中 |
| `_State` | 运行时状态 | `PH_Mat_Elastic_State` | 定义在 `*_Def.f90` 中 |
| `_Algo`  | 算法策略   | `PH_Mat_Elastic_Algo`  | 定义在 `*_Def.f90` 中 |
| `_Ctx`   | 上下文     | `PH_Mat_Elastic_Ctx`   | 定义在 `*_Def.f90` 中 |

### 7.3 关键约束

1. **四型后缀仅用于 TYPE**：`_Desc`/`_State`/`_Algo`/`_Ctx` 禁止出现在 `.f90` 文件名或 `MODULE` 名上
2. **MODULE 角色后缀**：非默认主模块时，使用 §7.1 及 **命名规范 v2 §3.2** 中已登记专用后缀；**新码主计算模块可无后缀**；**L5/SIO 保留 `_Proc`**；存量 `*_Ops` **不强制改名**
3. **命名一致性**：同一域内模块命名风格统一；域内约定可写入域 `CONTRACT.md`
4. **层级前缀固定**：`IF_`|`NM_`|`MD_`|`PH_`|`RT_`|`AP_`

---

## 八、统计概览

| 层级            | 文件数         | 主要域级                                                                                                                    | 关键特征                       |
| --------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| **L1_IF** | 63             | Base, Error, IO, Log, Memory, Monitor, Precision, Registry                                                                  | 基础设施，类型定义，工具链     |
| **L2_NM** | 25             | Base, Bridge, Matrix, Solver, TimeInt                                                                                       | 数值算法，矩阵运算，求解器     |
| **L3_MD** | 70+            | Analysis, Assembly, Boundary, Bridge, Constraint, Field, Interaction, KeyWord, Material, Mesh, Model, Part, Section, Output | 模型数据，材料注册，关键字解析 |
| **L4_PH** | 65             | Bridge, Constraint, Element, Field, LoadBC, Material                                                                        | 物理计算，单元计算，材料本构   |
| **L5_RT** | 72             | Assembly, Bridge, Contact, Element, LoadBC, Output, Solver, Amplitude, StepDriver, Logging                                  | 运行时协调，系统装配，求解驱动 |
| **L6_AP** | 26             | Base, CLI, Config, GUI, Job, Output, Plugin, SimData, Solver, User, Utils                                                   | 应用层接口，用户交互，作业管理 |
| **总计**  | **~321** | **51个域级**                                                                                                          | **260个功能模块**        |

---

## 九、参考文档

| 文档 | 路径 |
|------|------|
| 统一命名方案 | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` |
| 命名与接口标准 v2 | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` |
| 过程命名规范 | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` |
| 主责正交矩阵 | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` |
| 域级模块规范 | `UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` |

---

*文档完成时间：2026-04-23*
*最后修订：2026-04-24（命名文档套件；§7 双轨与约束对齐）*
*版本：v1.0*
*状态：架构设计完成，可进入实施阶段*
