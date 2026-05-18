# UFC 过程命名规范 v1.0

> **已整合至 `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`，本文冻结 (2026-04-26)。**

> **版本**: v1.0
> **创建日期**: 2026-04-22
> **核心使命**: 定义 UFC 六层架构中所有内部过程（Subroutine/Function/Procedure）的命名规范
> **适用范围**: UFC 全层级、全域的内部过程命名
> **文档地位**: 子程序层细则；模块/文件总则见 **统一命名方案**，模块与后缀见 **命名规范与接口标准 v2.0**。
> **配套** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md`（总则）；`UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md`（模块/TYPE/文件）；`UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md`（查表）；`UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md`（域级）；`docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md`（四型/ProcKind）

---

## 文档元数据

| 属性 | 值 |
|------|-----|
| **规范简称** | UFC_Procedure_Naming_v1 |
| **上位文档** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md`；`UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` |

---

## 〇、REPORTS 命名文档套件（交叉索引）

| 文档 | 路径 | 职责 |
|------|------|------|
| **统一命名方案** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` | 三级体系与子程序四场景总则 |
| **命名与接口标准 v2** | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` | 层缀/域缩/后缀闭集 |
| **本文（过程命名规范）** | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` | 动词与对内/对外过程名 |
| **功能模块清单** | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` | 模块枚举 |
| **主责正交矩阵** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` | 四型与 ProcKind |

---

## 一、命名公式

### 1.1 对外过程（层间边界）

```
{层缀}_{域缩}_{功能}_{动词}_{具体}
```

**示例**：

- `PH_Mat_Elas_Eval` — L4 材料弹性评估
- `RT_StepDriver_Run` — L5 步进驱动运行
- `MD_Node_Create` — L3 节点创建

### 1.2 内部过程（模块内部）

```
{动词}_{具体}  或  {域缩}_{动词}_{具体}
```

**示例**：

- `ComputeStiffness` — 模块内部计算刚度
- `Elem_AssembleLocal` — 单元域内装配局部矩阵
- `CheckConvergence` — 检查收敛性

---

## 二、过程动词全集（100 项）

从 UFC 六层代码库（L1_IF ~ L6_AP）全量提取，按功能语义分组。

### A. 生命周期管理（12 项）

| 动词                 | 含义             | 层级  | 仓库实例                                                                           |
| -------------------- | ---------------- | ----- | ---------------------------------------------------------------------------------- |
| **Init**       | 初始化           | 全层  | `MD_L3_Init`、`PH_L4_Init`、`RT_L5_Init`、`IF_WS_Mgr_Init`                 |
| **Finalize**   | 终结/清理        | 全层  | `MD_L3_Finalize`、`PH_L4_Finalize`、`RT_L5_Finalize`、`IF_Serial_Finalize` |
| **Create**     | 创建对象         | L3/L5 | `MD_Node_Create`、`IF_WS_Create`                                               |
| **Destroy**    | 销毁对象         | L3/L5 | `MD_Node_Destroy`、`IF_WS_Destroy`                                             |
| **Alloc**      | 分配内存/资源    | L1/L4 | `PH_Mat_AllocSlot_Idx`、`IF_Mem_Alloc`                                    |
| **Dealloc**    | 释放内存/资源    | L1    | `IF_Mem_Dealloc`、`IF_WS_Dealloc`                                              |
| **Build**      | 构建复杂结构     | L3/L5 | `RT_MeshSnapshot_Build`、`MD_Model_Build`                                      |
| **Construct**  | 构造对象实例     | L3    | `MD_Section_Construct`                                                           |
| **Destruct**   | 析构对象实例     | L3    | `MD_Section_Destruct`                                                            |
| **Initialize** | 初始化（长形式） | L4    | `PH_Elem_B31_NL_Initialize`、`MD_KW_Registry_Initialize`                       |
| **Shutdown**   | 关闭/停机        | L3    | `TypeReg_Shutdown`                                                               |
| **Reset**      | 重置到初始态     | L4/L5 | `PH_LoadBC_IncrBegin_Reset`、`IF_WS_Reset`                                     |

### B. 数据操作（12 项）

| 动词                  | 含义          | 层级  | 仓库实例                                                                                 |
| --------------------- | ------------- | ----- | ---------------------------------------------------------------------------------------- |
| **Get**         | 查询/读取     | 全层  | `MD_Node_GetCoords`、`MD_Node_GetDOF`、`IF_Monitor_Mgr_GetLogState`、`IF_WS_Get` |
| **Set**         | 设置/写入     | 全层  | `MD_Node_SetCoords`、`MD_Node_SetDOF`、`PH_Mat_SetCtx_Idx`                    |
| **Update**      | 更新状态      | L4    | `PH_Mat_Elas_Update`、`PH_Mat_SetState_Idx`                                     |
| **Copy**        | 拷贝数据      | L1/L3 | `IF_Mem_Copy`、`MD_Node_Copy`                                                        |
| **Clone**       | 深拷贝对象    | L3    | `MD_Material_Clone`                                                                    |
| **Clear**       | 清空内容      | L4    | `PH_BC_Ctx_Clear`、`PH_Load_Ctx_Clear`、`PH_Mass_Result_Clear`、`IF_WS_Clear`    |
| **Resize**      | 调整大小      | L1    | `IF_WS_Resize`                                                                         |
| **Compact**     | 压缩/整理     | L1    | `IF_WS_Compact`                                                                        |
| **Transform**   | 坐标变换      | L3    | `MD_Node_Transform`                                                                    |
| **Map**         | 映射/索引转换 | L3/L4 | `MAPLOGICALTOIND`、`PH_Elem_AC3D20_Map`                                              |
| **Project**     | 投影/场映射   | L4    | `PH_Field_Project`                                                                     |
| **Interpolate** | 插值          | L4    | `PH_ShapeFunc_Interpolate`                                                             |

| 动词                    | 含义              | 层级  | 仓库实例                                                                                 |
| ----------------------- | ----------------- | ----- | ---------------------------------------------------------------------------------------- |
| **Eval**          | 评估/计算主入口   | L4    | `PH_Mat_Elas_Eval`、`RT_Asm_ShapeScalarField_Eval`、`PH_ShapeMechanicalField_Eval` |
| **Compute**       | 具体计算          | L4    | `PH_PoreField_Compute`、`PH_TempField_Compute`                                       |
| **Calculate**     | 计算数值          | L4    | `PH_Cont_CalculateGap`、`PH_Cont_CalculatePressure`                                  |
| **Assemble**      | 装配（全局/局部） | L4/L5 | `RT_Cont_Assemble`、`PH_LoadBC_Assemble_Fext_Idx`、`Elem_AssembleLocal`            |
| **Solve**         | 求解方程          | L4/L5 | `RT_Cont_AugLag_Solve`、`SOLVE_LINEAR_SYSTEM`、`GAUSSIAN_ELIMINATION`              |
| **Integrate**     | 积分              | L4    | `PH_Elem_Integrate`、`PH_ShapeFunc_Integrate`                                        |
| **Differentiate** | 微分/求导         | L4    | `PH_Mat_Differentiate`                                                                 |
| **Estimate**      | 估算              | L5    | `RT_Dyn_Estimate_omega_max_csr_lumped`                                                 |
| **Clamp**         | 限幅/截断         | L5    | `RT_Dyn_Clamp_dt_cfl_csr`                                                              |
| **Factor**        | 因子计算          | L5    | `RT_Amp_FactorAt`                                                                      |
| **TRACE**         | 矩阵迹            | L4    | `TRACE(A)`                                                                             |
| **CROSS_PRODUCT** | 叉积              | L4    | `CROSS_PRODUCT(a, b)`                                                                  |
| **MatVec**        | 矩阵向量乘        | L5    | `RT_DynImpl_MatVec`                                                                    |
| **CSRToDense**    | 稀疏转稠密        | L5    | `RT_DynImpl_CSRToDense`                                                                |
| **Linearize**     | 线性化            | L4    | `PH_Mat_Linearize`                                                                     |
| **Approximate**   | 近似              | L4    | `PH_Cont_ApproximateGap`                                                               |
| **Evaluate**      | 评估函数值        | L4    | `ConductanceLaw_Evaluate`                                                              |
| **Cap**           | 上限截断          | L4    | `UF_Plastic_Legacy_Cap`                                                                |

### D. 校验与检查（8 项）

| 动词                  | 含义       | 层级  | 仓库实例                                                                                                     |
| --------------------- | ---------- | ----- | ------------------------------------------------------------------------------------------------------------ |
| **Validate**    | 校验正确性 | L3/L4 | `MD_L3_ValidateBindings`、`MD_L3_ValidateModel`、`MD_L3_ValidatePartRefs`、`IF_Monitor_Mgr_Validate` |
| **Check**       | 检查条件   | L4/L5 | `PH_MomentumConservation_Check`、`RT_Solv_CheckRes`、`CheckConvergence`                                |
| **Verify**      | 验证一致性 | L3    | `MD_Material_Verify`                                                                                       |
| **Test**        | 测试/试探  | L4    | `PH_Cont_TestContactStatus`                                                                                |
| **Assert**      | 断言       | L1    | `IF_Err_Assert`                                                                                            |
| **SanityCheck** | 健全性检查 | L3    | `MD_Model_SanityCheck`                                                                                     |
| **Valid**       | 有效性判断 | L3    | `MD_Node_Valid`                                                                                            |
| **IsXXX**       | 布尔判断   | 全层  | `IsConverged`、`IsEmpty`、`IsValid`                                                                    |

### E. 注册与分发（8 项）

| 动词                 | 含义      | 层级  | 仓库实例                                                                                           |
| -------------------- | --------- | ----- | -------------------------------------------------------------------------------------------------- |
| **Register**   | 注册到表  | L3    | `MD_Elem_Solid3D_Register`、`MD_Elem_Beam_Register`、`MD_Material_Register`                  |
| **Unregister** | 注销      | L3    | `MD_Material_Unregister`                                                                         |
| **Dispatch**   | 动态分派  | L4/L5 | `PH_Elem_Dsp`、`RT_Elem_Dispatcher_Run`                                                        |
| **Bind**       | 绑定引用  | L3    | `MD_L3_BindDomains`、`RT_StepDriver_ConfigDomain_BindStepRefs`                                 |
| **Populate**   | 灌入数据  | L4    | `PH_Mat_Populate`、`PH_Elem_Populate`、`PH_L4_Populate_Material`、`PH_L4_Populate_Element` |
| **Select**     | 选择/路由 | L3    | `MD_Solver_Brg_GetConfigForStep_Select`、`MD_Out_Brg_BuildFieldOutTasks_Select`                |

### F. 运行与执行（10 项）

| 动词                 | 含义       | 层级 | 仓库实例                                                                                                             |
| -------------------- | ---------- | ---- | -------------------------------------------------------------------------------------------------------------------- |
| **Run**        | 运行主流程 | L5   | `RT_Elem_Dispatcher_Run`、`RT_StepDriver_Run`、`RT_MF_Coordinator_Run`、`RT_DynExpl_Run`、`RT_DynImpl_Run` |
| **Drive**      | 驱动控制   | L5   | `RT_StepDriver_Brg`                                                                                                |
| **Execute**    | 执行任务   | L5   | `RT_StepDriver_Execute`、`RT_StepDriver_RunDynamicExplicit`、`RT_StepDriver_RunDynamicImplicit`                |
| **Step**       | 步进推进   | L5   | `RT_Step_Advance`                                                                                                  |
| **Apply**      | 应用/施加  | L4   | `PH_LoadBC_Apply_DirichletBC_Idx`、`PH_LoadBC_Apply_DirichletBC_CSR_Idx`、`PH_ObjCorrect_Apply`                |
| **Freeze**     | 冻结状态   | L3   | `MD_L3_Freeze`                                                                                                     |
| **Advance**    | 推进/步进  | L2   | `NM_TimeInt_Advance`、`L2_NM_TimeInt_BEAM_Advance`                                                               |
| **Loop**       | 循环迭代   | L5   | `RT_MF_Oneway_Loop`、`RT_MF_Staggered_Loop`、`RT_MF_PartIter_Loop`、`RT_MF_Monolithic_Loop`                  |
| **Accelerate** | 加速收敛   | L5   | `RT_MF_Aitken_Accelerate`                                                                                          |

### G. I/O 与持久化（13 项）

| 动词                  | 含义        | 层级  | 仓库实例                                    |
| --------------------- | ----------- | ----- | ------------------------------------------- |
| **Read**        | 读取文件/流 | L1/L6 | `IF_IO_Read`、`IF_WS_Load`              |
| **Write**       | 写入文件/流 | L5/L6 | `RT_Writer_ODB`、`IF_IO_Write`          |
| **Save**        | 保存状态    | L1    | `IF_WS_Save`                              |
| **Load**        | 加载状态    | L1    | `IF_WS_Load`                              |
| **Parse**       | 解析输入    | L3/L6 | `MD_KW_Parser_Parse`、`IF_Parser_Parse` |
| **Serialize**   | 序列化      | L1    | `IF_IO_Serialize`                         |
| **Deserialize** | 反序列化    | L1    | `IF_IO_Deserialize`                       |
| **Export**      | 导出格式    | L6    | `MD_OutFieldExport`                       |
| **Import**      | 导入格式    | L6    | `IF_IO_Import`                            |
| **Log**         | 日志记录    | L4    | `PH_UnregElemTypes_Log`、`IF_Log_Write` |
| **Print**       | 打印输出    | L4    | `PH_Mass_Result_Print`                    |
| **Report**      | 生成报告    | L6    | `MD_OutReportPlot`                        |
| **Checkpoint**  | 检查点      | L5    | `RT_WB_Impl_Checkpoint`                   |

### H. 工具与辅助（18 项）

| 动词                     | 含义          | 层级  | 仓库实例                                                                              |
| ------------------------ | ------------- | ----- | ------------------------------------------------------------------------------------- |
| **Convert**        | 格式转换      | L1/L3 | `IF_IO_Convert`、`MD_Unit_Convert`                                                |
| **Normalize**      | 归一化        | L4    | `PH_ShapeFunc_Normalize`                                                            |
| **Scale**          | 缩放          | L3    | `MD_Node_Scale`                                                                     |
| **Rotate**         | 旋转          | L3    | `MD_Node_Rotate`                                                                    |
| **Translate**      | 平移          | L3    | `MD_Node_Translate`                                                                 |
| **Merge**          | 合并          | L3    | `MD_Mesh_Merge`                                                                     |
| **Split**          | 分割          | L3    | `MD_Mesh_Split`                                                                     |
| **Sort**           | 排序          | L1/L3 | `IF_Util_Sort`、`MD_Elem_Sort`                                                    |
| **Filter**         | 过滤          | L3    | `MD_Node_Filter`                                                                    |
| **Search**         | 搜索          | L4    | `PH_Cont_Search`、`IF_Util_Search`                                                |
| **Find**           | 查找          | L1    | `IF_WS_FindById`                                                                    |
| **Count**          | 计数          | L3    | `MD_Mesh_CountElements`                                                             |
| **Statistics**     | 统计          | L3/L1 | `MD_Node_GetStatistics`、`IF_WS_GetStatistics`                                    |
| **UPPER_CASE**     | 转大写        | L4    | `UPPER_CASE(str)`                                                                   |
| **REAL_TO_STRING** | 数值转字符串  | L4    | `REAL_TO_STRING(val)`                                                               |
| **STR**            | 数值转字符串  | L3    | `STR(val)`                                                                          |
| **Pack**           | 打包/序列化   | L3    | `MD_Contract_Pack`                                                                  |
| **Unpack**         | 解包/反序列化 | L3    | `MD_Contract_Unpack`                                                                |
| **Traverse**       | 遍历          | L3/L4 | `MD_ModelTree_BFS_Traverse`、`MD_ModelTree_DFS_Traverse`、`PH_ContBVH_Traverse` |
| **Acquire**        | 获取资源      | L1    | `IF_AI_SessionPool_Acquire`                                                         |
| **Release**        | 释放资源      | L1    | `IF_AI_SessionPool_Release`                                                         |

### I. 预测-校正与迭代（6 项）

| 动词               | 含义      | 层级     | 仓库实例                                                                                                     |
| ------------------ | --------- | -------- | ------------------------------------------------------------------------------------------------------------ |
| **Predict**  | 预测      | L2/L4/L5 | `NM_TimeInt_Predict`、`NM_TimeInt_HHT_Predict`、`NM_Coupling_Pred_Predict`、`AI_ConvPredict_Predict` |
| **Correct**  | 校正      | L2       | `NM_TimeInt_Correct`、`NM_TimeInt_HHT_Correct`、`L2_NM_TimeInt_BEAM_Correct`                           |
| **Iterate**  | 迭代      | L5       | `RT_MF_PartIter_Loop`                                                                                      |
| **Converge** | 收敛判定  | L2/L5    | `NM_Conv_CheckConvergence`、`RT_Solv_CheckConvergence`                                                   |
| **Relax**    | 松弛      | L2       | `NM_Conv_Relaxation`                                                                                       |
| **Smooth**   | 光滑/平滑 | L2       | `NM_MG_Smooth`、`NM_AMG_Smooth`                                                                          |

### J. 数值求解（6 项）

| 动词                  | 含义               | 层级 | 仓库实例                  |
| --------------------- | ------------------ | ---- | ------------------------- |
| **LinearSolve** | 线性求解           | L2   | `NM_LAPACK_LinearSolve` |
| **NonlinSolve** | 非线性求解         | L2   | `NM_Newton_NonlinSolve` |
| **EigenSolve**  | 特征值求解         | L2   | `NM_LAPACK_EigenSolve`  |
| **V_Cycle**     | V 循环（多重网格） | L2   | `NM_AMG_V_Cycle`        |
| **W_Cycle**     | W 循环（多重网格） | L2   | `NM_AMG_W_Cycle`        |
| **Forward**     | 前向（SOR）        | L2   | `NM_SOR_Forward`        |

### K. 错误与异常处理（5 项）

| 动词              | 含义      | 层级 | 仓库实例                                                                   |
| ----------------- | --------- | ---- | -------------------------------------------------------------------------- |
| **Error**   | 错误计算  | L4   | `PH_Acoustic_Compute_Local_Error`、`PH_Elem_AC3D4_Compute_Local_Error` |
| **Abort**   | 中止      | L6   | `AP_Job_Domain_Abort`                                                    |
| **Restore** | 恢复状态  | L3   | `IPState_Restore`、`MD_MatPointSta_Restore`                            |
| **Handle**  | 异常处理  | L1   | `IF_Err_Handle`                                                          |
| **Recover** | 恢复/抢救 | L3   | `IPState_Recover`                                                        |

### L. 时间与性能（4 项）

| 动词              | 含义     | 层级 | 仓库实例                             |
| ----------------- | -------- | ---- | ------------------------------------ |
| **Stop**    | 停止计时 | L3   | `Timer_Stop`、`Stopwatch_Stop`   |
| **Start**   | 开始计时 | L3   | `Timer_Start`、`Stopwatch_Start` |
| **Time**    | 计时     | L1   | `IF_Mon_Time`                      |
| **Measure** | 度量     | L1   | `IF_Mon_Measure`                   |

### P. 优化与自适应（4 项）

| 动词            | 含义      | 层级 | 仓库实例                                                                                        |
| --------------- | --------- | ---- | ----------------------------------------------------------------------------------------------- |
| **Opt**   | 优化      | L4   | `PH_Constr_MPC_Opt`、`PH_Constr_Tie_Opt`、`PH_Cont_Search_Opt`、`PH_Constr_MPCCore_Opt` |
| **Adapt** | 自适应    | L4   | `PH_Elem_AC3D4_Adaptive_TimeStep_Control`                                                     |
| **Guard** | 保护/守卫 | L3   | `WB_Guard`                                                                                    |
| **Cache** | 缓存      | L4   | `PH_L4_WriteBack_BC_From_Cache`                                                               |

### Q. 几何与变换（4 项）

| 动词                      | 含义       | 层级 | 仓库实例                                            |
| ------------------------- | ---------- | ---- | --------------------------------------------------- |
| **Rotate**          | 旋转张量   | L4   | `PH_Tensor_Rotate`                                |
| **Transform**       | 坐标变换   | L3   | `MD_Node_Transform`                               |
| **Get_Gauss_Point** | 获取高斯点 | L4   | `CPS6_Get_Gauss_Point`、`AC2D4_Get_Gauss_Point` |
| **Bound**           | 边界计算   | L3   | `Obj_Bound`                                       |

### M. 通信与并行（预留）

| 动词                | 含义     | 层级 | 仓库实例                               |
| ------------------- | -------- | ---- | -------------------------------------- |
| **Transfer**  | 跨域传输 | L2   | `NM_Coupling_FSI_Interface_Transfer` |
| **Broadcast** | 广播     | L1   | （MPI 预留）                           |
| **Reduce**    | 归约     | L1   | （MPI 预留）                           |
| **Scatter**   | 散播     | L1   | （MPI 预留）                           |
| **Gather**    | 收集     | L1   | （MPI 预留）                           |
| **Barrier**   | 屏障同步 | L1   | （MPI 预留）                           |

### N. 状态管理（6 项）

| 动词                 | 含义             | 层级 | 仓库实例                                                     |
| -------------------- | ---------------- | ---- | ------------------------------------------------------------ |
| **Initialize** | 初始化（长形式） | L4   | `PH_Elem_B31_NL_Initialize`、`MD_KW_Registry_Initialize` |
| **Shutdown**   | 关闭/停机        | L3   | `TypeReg_Shutdown`                                         |
| **Enable**     | 启用             | L4   | `PH_Cont_Enable`                                           |
| **Disable**    | 禁用             | L4   | `PH_Cont_Disable`                                          |
| **Activate**   | 激活             | L4   | `PH_Cont_Activate`                                         |
| **Deactivate** | 停用             | L4   | `PH_Cont_Deactivate`                                       |

### O. 集合操作（6 项）

| 动词             | 含义     | 层级  | 仓库实例                                                                                 |
| ---------------- | -------- | ----- | ---------------------------------------------------------------------------------------- |
| **Add**    | 添加元素 | L3/L4 | `Container_Add`、`PH_Elem_Reg_Add`、`RotInertiaManager_Add`、`VecOps_Add`        |
| **Remove** | 移除元素 | L3    | `Container_Remove`、`MD_Inter_Mgr_Delete`                                            |
| **Insert** | 插入位置 | L3/L4 | `HashTable_Insert`、`SpatialHash_Insert`、`HashSet_Insert`                         |
| **Delete** | 删除记录 | L3    | `MD_Inter_Mgr_Delete`                                                                  |
| **Find**   | 查找元素 | L1/L3 | `IF_WS_FindById`、`RotInertiaManager_Find`、`KW_Registry_Find`、`HashTable_Find` |
| **Batch**  | 批量处理 | L4    | `PH_Load_ApplyConcentrated_Batch`、`UF_Elem_CheckQuality_Batch`                      |

---

## 三、内部过程命名规则

**格式**：`{动词}_{具体}` 或 `{域缩}_{动词}_{具体}`

**规则**：

1. **无需层缀**：已在模块内部，层缀冗余
2. **动词在前**：强调动作语义
3. **具体描述**：说明操作对象或算法

**示例**：

```fortran
! 弹性材料模块内部
SUBROUTINE ComputeStiffness(E, nu, D)        ! 计算刚度矩阵
SUBROUTINE UpdateStress(strain, stress)       ! 更新应力
FUNCTION  CheckYield(stress, yield_stress)    ! 检查屈服

! 接触算法模块内部
SUBROUTINE Cont_CalculateGap(x1, x2, gap)     ! 计算接触间隙
SUBROUTINE Cont_SearchNeighbors(node, neighbors) ! 搜索邻居节点
FUNCTION  Cont_IsActive(pressure)              ! 判断接触是否激活

! 步进驱动模块内部
SUBROUTINE Driver_AdvanceTime(dt)              ! 推进时间
SUBROUTINE Driver_CheckConvergence(residual)   ! 检查收敛
FUNCTION  Driver_IsStable(dt)                  ! 判断稳定性
```

### 3.2 数学/算法专用函数

**格式**：大写或 PascalCase，直接使用算法名

**示例**：

```fortran
FUNCTION GAUSSIAN_ELIMINATION(A, b, x, info)  ! 高斯消元
FUNCTION CROSS_PRODUCT(a, b) RESULT(c)        ! 向量叉积
FUNCTION TRACE(A) RESULT(tr)                   ! 矩阵迹
SUBROUTINE SOLVE_LINEAR_SYSTEM(A, b, x, status) ! 线性系统求解
```

### 3.3 禁止模式

| 禁止模式    | 原因       | 反例                                    | 正例                    |
| ----------- | ---------- | --------------------------------------- | ----------------------- |
| 层缀 + 层缀 | 冗余       | `MD_L3_BindDomains`                   | `MD_Domains_Bind`     |
| 动词在中缀  | 不符合语义 | `PH_L4_Populate_Material`             | `PH_Mat_Populate`     |
| 冗长描述    | 啰嗦       | `PH_Elem_AC3D20_Infinite_Element_Map` | `PH_Elem_AC3D20_Map`  |
| 缩写不一致  | 混乱       | `PH_ObjectivityCorrection_Apply`      | `PH_ObjCorrect_Apply` |
| 数字尾巴    | 遗留兼容   | `MD_Mesh_API`                        | `MD_Mesh_Brg`         |

---

## 四、动词选用决策树

```
过程做什么？
├─ 创建/销毁对象？
│  ├─ 分配内存 → Alloc/Dealloc
│  ├─ 创建实例 → Create/Destroy
│  └─ 构建结构 → Build
│
├─ 读写数据？
│  ├─ 查询 → Get
│  ├─ 设置 → Set
│  ├─ 更新 → Update
│  └─ 清空 → Clear
│
├─ 计算/评估？
│  ├─ 主入口 → Eval
│  ├─ 具体计算 → Compute/Calculate
│  ├─ 装配 → Assemble
│  ├─ 求解 → Solve
│  └─ 积分 → Integrate
│
├─ 校验/检查？
│  ├─ 正确性 → Validate
│  ├─ 条件 → Check
│  └─ 布尔判断 → IsXXX/Valid
│
├─ 运行流程？
│  ├─ 主流程 → Run
│  ├─ 执行任务 → Execute
│  ├─ 驱动控制 → Drive
│  └─ 步进推进 → Step
│
├─ I/O 操作？
│  ├─ 文件读写 → Read/Write
│  ├─ 保存加载 → Save/Load
│  ├─ 解析 → Parse
│  └─ 日志 → Log/Print
│
└─ 工具辅助？
   ├─ 转换 → Convert
   ├─ 搜索 → Search/Find
   ├─ 排序 → Sort
   └─ 统计 → Count/Statistics
```

---

## 五、典型模块过程命名示例

### 5.1 L4_PH/Material/Elas（弹性材料）

```fortran
MODULE PH_Mat_Elas_Eval
  ! 对外过程
  SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, status)
  
  ! 内部过程
  SUBROUTINE ComputeStiffness(E, nu, D)
  SUBROUTINE ComputeStrain(displacement, strain)
  SUBROUTINE UpdateStress(strain, stress, D)
  FUNCTION  CheckLinearElastic(stress) RESULT(is_linear)
END MODULE
```

### 5.2 L5_RT/StepDriver（步进驱动）

```fortran
MODULE RT_StepDriver_Brg
  ! 对外过程
  SUBROUTINE RT_StepDriver_Run(job_desc, job_state, job_ctx, status)
  
  ! 内部过程
  SUBROUTINE Driver_AdvanceTime(dt)
  SUBROUTINE Driver_CheckConvergence(residual, tol)
  SUBROUTINE Driver_ClampTimeStep(dt_max, dt_out)
  FUNCTION  Driver_IsStable(cfl_number) RESULT(is_stable)
  SUBROUTINE Driver_ExecuteImplicit(model, step)
  SUBROUTINE Driver_ExecuteExplicit(model, step)
END MODULE
```

### 5.3 L3_MD/Mesh/Node（节点管理）

```fortran
MODULE MD_Node_Ops
  ! 对外过程
  SUBROUTINE MD_Node_Create(node, id, coords, name, status)
  SUBROUTINE MD_Node_Destroy(node, status)
  
  ! 内部过程
  SUBROUTINE TransformCoords(coords, matrix, new_coords)
  SUBROUTINE ValidateCoords(coords, status)
  FUNCTION  IsWithinBounds(coords, bounds) RESULT(is_valid)
  SUBROUTINE CopyNode(src, dst)
END MODULE
```

---

## 六、验收清单

- [ ] 所有对外过程以层缀开头（`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`）
- [ ] 动词在可选集中（60 项全集）
- [ ] 内部过程无冗余层缀
- [ ] 动词位置正确（末尾或开头，不夹在中缀）
- [ ] 无冗长命名（使用缩写如 `ObjCorrect` 而非 `ObjectivityCorrection`）
- [ ] 无数字尾巴（`*_*1`）
- [ ] INTENT 显式声明（对外过程）
- [ ] 四型平级传递（`desc, state, algo, ctx, status`）

---

## 七、参考文档

| 文档 | 路径 |
|------|------|
| 统一命名方案 | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` |
| 命名与接口标准 v2 | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` |
| 功能模块清单 | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` |
| 主责正交矩阵 | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` |
| PPLAN 命名规范 | `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md` |

---

*最后更新：2026-04-24（命名文档套件；配套链接；示例笔误修正）*
*文档版本：v1.0*
