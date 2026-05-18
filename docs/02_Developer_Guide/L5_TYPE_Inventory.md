# L5_RT 四类TYPE全域盘点矩阵

> 生成时间：2026-04-28  
> 扫描范围：`UFC/ufc_core/L5_RT/` 全部11域（含子域）+ 根级文件  
> 分类规则：按TYPE名称后缀 `_Desc`→Desc, `_State`/`State`→State, `_Algo`→Algo, `_Ctx`/`Ctx`→Ctx, 其余→未分类

---

## 总览统计

| 域 | Desc | State | Algo | Ctx | 未分类 | 总计 | _Def.f90存在 |
|----|------|-------|------|-----|--------|------|-------------|
| Assembly | 1 | 2 | 0 | 2 | 61 | 66 | ✅ RT_Asm_Def.f90 |
| Solver | 1 | 4 | 1 | 3 | 64 | 73 | ✅ RT_Solv_Def.f90 |
| Solver/Coupling | 2 | 1 | 1 | 1 | 1 | 6 | ✅ RT_MF_Def.f90 |
| StepDriver | 1 | 1 | 1 | 1 | 21 | 25 | ✅ RT_Step_Def.f90 |
| Contact | 1 | 1 | 1 | 1 | 25 | 29 | ✅ RT_Cont_Def.f90 |
| Element | 1 | 1 | 1 | 1 | 17 | 21 | ✅ RT_Elem_Def.f90 |
| Element/Mesh | 1 | 3 | 2 | 2 | 14 | 22 | ✅ RT_Mesh_Def.f90 |
| LoadBC | 1 | 1 | 1 | 1 | 17 | 21 | ✅ RT_LBC_Def.f90 |
| Material | 0 | 0 | 0 | 1 | 2 | 3 | ✅ RT_Mat_Def.f90 |
| Output | 1 | 3 | 1 | 4 | 15 | 24 | ✅ RT_Out_Def.f90 |
| WriteBack | 1 | 2 | 1 | 2 | 20 | 26 | ✅ RT_WB_Def.f90 |
| Bridge | 0 | 0 | 0 | 12 | 3 | 15 | ✅ RT_Brg_Def.f90 |
| Bridge/Shared | 0 | 1 | 0 | 0 | 4 | 5 | ✅ RT_Shared_Def.f90 |
| Logging | 1 | 1 | 0 | 1 | 2 | 5 | ✅ RT_Log_Def.f90 |
| 根级文件 | 1 | 0 | 0 | 3 | 9 | 13 | ✅ RT_Global_Def.f90 / RT_Com_Def.f90 |
| **合计** | **12** | **21** | **10** | **35** | **275** | **354** | **全部存在** |

---

## 逐域详细清单

### Assembly域 (66 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Asm_Desc | Desc | RT_Asm_Def.f90 | ✅ | 正常 |
| RT_Asm_State | State | RT_Asm_Def.f90 | ✅ | 正常 |
| RT_Asm_Ctx | Ctx | RT_Asm_Def.f90 | ✅ | 正常 |
| RT_Asm | 未分类 | RT_Asm_Def.f90 | ✅ | 正常 |
| RT_Assembly_Ctx | Ctx | RT_Asm_Domain.f90 | ❌ | 需迁移 |
| RT_Assembly_State | State | RT_Asm_Domain.f90 | ❌ | 需迁移 |
| RT_Assembly_Ctrl | 未分类 | RT_Asm_Domain.f90 | ❌ | — |
| RT_Asm_BuildPattern_Arg | 未分类 | RT_Asm_Domain.f90 | ❌ | — |
| RT_Asm_GetSummary_Arg | 未分类 | RT_Asm_Domain.f90 | ❌ | — |
| RT_Assembly_Domain | 未分类 | RT_Asm_Domain.f90 | ❌ | — |
| RT_Asm_Cfg | 未分类 | RT_Asm_Solv.f90 | ❌ | — |
| RT_Asm_Solv_Args | 未分类 | RT_Asm_Solv.f90 | ❌ | — |
| RT_Asm_GlobalStiffness_Arg | 未分类 | RT_Asm_Solv.f90 | ❌ | — |
| RT_Asm_ComputeResidual_Arg | 未分类 | RT_Asm_Solv.f90 | ❌ | — |
| RT_Asm_ElemLoop_Info | 未分类 | RT_Asm_Util.f90 | ❌ | — |
| RT_Asm_Init_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_Init_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_BuildPattern_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_BuildPattern_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleK_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleK_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleM_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleM_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleF_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_AssembleF_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_ApplyConstraints_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_ApplyConstraints_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_ComputeResidual_In | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| RT_Asm_ComputeResidual_Out | 未分类 | RT_Asm_Proc.f90 | ❌ | — |
| CSR_Matrix | 未分类 | RT_Asm_Global.f90 | ❌ | — |
| RT_Asm_AssemStiff_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemStiff_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemResid_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemResid_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemMass_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemMass_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemDamp_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemDamp_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AddElemStiff_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AddElemStiff_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AddElemResid_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AddElemResid_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_GetElemDOF_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_GetElemDOF_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_ScatterElemToGlob_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_ScatterElemToGlob_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemStiffSparse_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemStiffSparse_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemMassConsist_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemMassConsist_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemLoadOpt_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemLoadOpt_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemDampRayleigh_In | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_Asm_AssemDampRayleigh_Out | 未分类 | RT_Asm_Mgr.f90 | ❌ | — |
| RT_DefKin | 未分类 | RT_Asm_NLGeomEval.f90 | ❌ | — |
| RT_LagrCfg | 未分类 | RT_Asm_NLGeomEval.f90 | ❌ | — |
| RT_RotSta | 未分类 | RT_Asm_NLGeomEval.f90 | ❌ | — |
| RT_LinRes | 未分类 | RT_Asm_NLGeomEval.f90 | ❌ | — |
| RT_Asm_NLGeom_Eval_Args | 未分类 | RT_Asm_NLGeomEval.f90 | ❌ | — |
| ElemNL_FuncPtr | 未分类 | RT_Asm_NLGeomDispatch.f90 | ❌ | — |
| GaussParams | 未分类 | RT_Asm_MassDamp.f90 | ❌ | — |
| RT_MassConfig | 未分类 | RT_Asm_MassDamp.f90 | ❌ | — |
| RT_DampingConfig | 未分类 | RT_Asm_MassDamp.f90 | ❌ | — |
| RT_MassMatrix | 未分类 | RT_Asm_MassDamp.f90 | ❌ | — |
| RT_DampingMatrix | 未分类 | RT_Asm_MassDamp.f90 | ❌ | — |
| RT_AsmColor_Result | 未分类 | RT_Asm_Color.f90 | ❌ | — |

### Solver域 (73 TYPE，不含Coupling子域)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Solv_Base_Desc | Desc | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_NRState | State | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_LinearState | State | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_Ctx | Ctx | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_ConvergenceCtx | Ctx | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_Cfg | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_DofMap | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| SolCfg | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| SolDofMap | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_AdvancedTimeIntegrator | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_AdvancedNLSol | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv | 未分类 | RT_Solv_Def.f90 | ✅ | 正常 |
| RT_Solv_Init_In | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Init_Out | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Equilibrium_In | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Equilibrium_Out | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Linear_In | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Linear_Out | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Convergence_In | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Convergence_Out | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Cutback_In | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_Solv_Cutback_Out | 未分类 | RT_Solv_Proc.f90 | ❌ | — |
| RT_LUHandle | 未分类 | RT_Solv_Sparse.f90 | ❌ | — |
| RT_BlockCSRMatrix | 未分类 | RT_Solv_Sparse.f90 | ❌ | — |
| UF_TimeIntState | State | RT_Solv_TimeInt.f90 | ❌ | 需迁移 |
| RT_NLSolver_Args | 未分类 | RT_Solv_Nonlin.f90 | ❌ | — |
| RT_NLSolver_ArcLen_Args | 未分类 | RT_Solv_Nonlin.f90 | ❌ | — |
| RT_ContactData | 未分类 | RT_Solv_ContResidual.f90 | ❌ | — |
| RT_Solver_State | State | RT_Solv_ContResidual.f90 | ❌ | 需迁移 |
| CMP_Slot_t | 未分类 | RT_Solv_CoreMemPool.f90 | ❌ | — |
| UF_CoreMemPool_t | 未分类 | RT_Solv_CoreMemPool.f90 | ❌ | — |
| ABAQUS_SolverRegistryEntry | 未分类 | RT_Solv_ABAQUSReg.f90 | ❌ | — |
| AI_ConvPredict_Type | Algo | RT_AI_ConvPredictAlgo.f90 | ❌ | — |
| RT_AssemStaticArgs | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ite | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx | Ctx | RT_Solv_Mgr.f90 | ❌ | 需迁移 |
| RT_Sol_Ctx_Init_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Init_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Destroy_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Destroy_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Reset_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Reset_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetStatus_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetStatus_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_SetStatus_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_SetStatus_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_ClearStatus_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_ClearStatus_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_IsOK_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_IsOK_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_IsError_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_IsError_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Bind_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Bind_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Valid_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_Valid_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetModel_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetModel_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetStep_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetStep_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetSolver_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetSolver_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetSolverState_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetSolverState_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetGlobalState_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetGlobalState_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetNodeStates_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetNodeStates_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetElemStates_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetElemStates_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetDofMap_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetDofMap_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetTws_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_Sol_Ctx_GetTws_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Init_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Init_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Final_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Final_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Cfg_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Cfg_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Solv_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_Solv_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_SolveLin_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_SolveLin_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_SolveNonlin_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverSys_SolveNonlin_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetNR_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetNR_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetModNR_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetModNR_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetLBFGS_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetLBFGS_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetArcLen_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetArcLen_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetLinSolv_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverCfg_SetLinSolv_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_IsConv_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_IsConv_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_IsFail_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_IsFail_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_GetSum_In | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolverRes_GetSum_Out | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |
| RT_SolCoordinator | 未分类 | RT_Solv_Mgr.f90 | ❌ | — |

### Solver/Coupling子域 (6 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_MF_FieldPair_Desc | Desc | RT_MF_Def.f90 | ✅ | 正常 |
| RT_MF_Coupling_Desc | Desc | RT_MF_Def.f90 | ✅ | 正常 |
| RT_MF_Coupling_State | State | RT_MF_Def.f90 | ✅ | 正常 |
| RT_MF_Coupling_Algo | Algo | RT_MF_Def.f90 | ✅ | 正常 |
| RT_MF_Coupling_Ctx | Ctx | RT_MF_Def.f90 | ✅ | 正常 |
| RT_MF_InterfaceBuf | 未分类 | RT_MF_Def.f90 | ✅ | 正常 |

### StepDriver域 (25 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_StepDriver_Desc | Desc | RT_Step_Def.f90 | ✅ | 正常 |
| RT_StepDriver_State | State | RT_Step_Def.f90 | ✅ | 正常 |
| RT_StepDriver_Algo | Algo | RT_Step_Def.f90 | ✅ | 正常 |
| RT_Step_Ctx | Ctx | RT_Step_Def.f90 | ✅ | 正常 |
| RT_StepDriver_TimeCfg | 未分类 | RT_Step_Def.f90 | ✅ | 正常 |
| RT_StepDriver_Config | 未分类 | RT_Step_Exec.f90 | ❌ | — |
| StepState | State | RT_Step_Exec.f90 | ❌ | 需迁移 |
| StepDriverContext | Ctx | RT_Step_Exec.f90 | ❌ | 需迁移 |
| RT_StepDriver_ConfigDomain | 未分类 | RT_Step_Exec.f90 | ❌ | — |
| RT_NR_Params | 未分类 | RT_Step_NR_Core.f90 | ❌ | — |
| RT_NR_Status | 未分类 | RT_Step_NR_Core.f90 | ❌ | — |
| RT_NodeDOFMap | 未分类 | RT_Step_Ctx.f90 | ❌ | — |
| RT_MeshSnapshot | 未分类 | RT_Step_Ctx.f90 | ❌ | — |
| RT_MatDescSnapshot | 未分类 | RT_Step_Ctx.f90 | ❌ | — |
| RT_LoadBCDescSnapshot | 未分类 | RT_Step_Ctx.f90 | ❌ | — |
| RT_Step_Ctx (重复) | Ctx | RT_Step_Ctx.f90 | ❌ | 需迁移(重复定义) |
| RT_Inc_Ctx | Ctx | RT_Step_Ctx.f90 | ❌ | 需迁移 |
| RT_Iter_Ctx | Ctx | RT_Step_Ctx.f90 | ❌ | 需迁移 |
| JobMemEstimate | 未分类 | RT_Step_WS.f90 | ❌ | — |
| JobWS | 未分类 | RT_Step_WS.f90 | ❌ | — |
| StructWS | 未分类 | RT_Step_WS.f90 | ❌ | — |
| UelPools | 未分类 | RT_Step_WS.f90 | ❌ | — |
| ThreadWS | 未分类 | RT_Step_WS.f90 | ❌ | — |
| Owners | 未分类 | RT_Step_WS.f90 | ❌ | — |
| Ctx (generic) | Ctx | RT_Step_WS.f90 | ❌ | 需迁移 |
| AI_StepCtr_Type | Algo | RT_AI_StepCtrAlgo.f90 | ❌ | — |

### Contact域 (29 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Contact_Desc | Desc | RT_Cont_Def.f90 | ✅ | 正常 |
| RT_Contact_State | State | RT_Cont_Def.f90 | ✅ | 正常 |
| RT_Contact_Algo | Algo | RT_Cont_Def.f90 | ✅ | 正常 |
| RT_Contact_Ctx | Ctx | RT_Cont_Def.f90 | ✅ | 正常 |
| RT_Cont_SearchStrategy | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_SpatHashGrid | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_OctreeNode | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_BVHNode | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_BVHTree | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_Search_Core_Args | 未分类 | RT_Cont_Search.f90 | ❌ | — |
| RT_Cont_Pair | 未分类 | RT_Cont_Expl.f90 | ❌ | — |
| RT_Cont_Expl_Cfg | 未分类 | RT_Cont_Expl.f90 | ❌ | — |
| RT_Cont_Expl_State | State | RT_Cont_Expl.f90 | ❌ | 需迁移 |
| RT_Cont_Expl_Solv | 未分类 | RT_Cont_Expl.f90 | ❌ | — |
| RT_ExplicitContactSolver | 未分类 | RT_Cont_Expl.f90 | ❌ | — |
| RT_Cont_AugLag_In | 未分类 | RT_Cont_AugLagSolv.f90 | ❌ | — |
| RT_Cont_AugLag_Out | 未分类 | RT_Cont_AugLagSolv.f90 | ❌ | — |
| RT_Cont_SurfDesc | Desc | RT_Cont_Core.f90 | ❌ | 需迁移 |
| RT_Cont_PairDef | 未分类 | RT_Cont_Core.f90 | ❌ | — |
| RT_Cont_PairBuf | 未分类 | RT_Cont_Core.f90 | ❌ | — |
| RT_Cont_Mgr | 未分类 | RT_Cont_Core.f90 | ❌ | — |
| RT_Cont_Search_In | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Search_Out | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Force_In | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Force_Out | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Assemble_In | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Assemble_Out | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Stats_In | 未分类 | RT_Cont_Solv.f90 | ❌ | — |
| RT_Cont_Stats_Out | 未分类 | RT_Cont_Solv.f90 | ❌ | — |

### Element域 (21 TYPE，不含Mesh子域)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Elem_Desc | Desc | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Elem_State | State | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Elem_Algo | Algo | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Elem_Ctx | Ctx | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Elem_Router_Entry | 未分类 | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Elem_Dispatch_Table | 未分类 | RT_Elem_Def.f90 | ✅ | 正常 |
| RT_Thermal_Load | 未分类 | RT_Elem_ThermalMechCpl.f90 | ❌ | — |
| RT_Elem_Compute_Args | 未分类 | RT_Elem_ComputeProc.f90 | ❌ | — |
| RT_Elem_Assembly_In | 未分类 | RT_Elem_AsmProc.f90 | ❌ | — |
| RT_Elem_Kernel_In | 未分类 | RT_Elem_KernelProc.f90 | ❌ | — |
| RT_Elem_Kernel_Out | 未分类 | RT_Elem_KernelProc.f90 | ❌ | — |
| Elem_Init_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Init_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Ke_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Ke_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Fe_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Fe_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Me_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Me_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Ce_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Ce_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Out_In | 未分类 | RT_Elem_Proc.f90 | ❌ | — |
| Elem_Out_Out | 未分类 | RT_Elem_Proc.f90 | ❌ | — |

### Element/Mesh子域 (22 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Mesh_Base_Desc | Desc | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_Base_State | State | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_Base_Algo | Algo | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_Base_Ctx | Ctx | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_NodeState | State | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_ElementState | State | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_NumberingAlgo | Algo | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_AssemblyCtx | Ctx | RT_Mesh_Def.f90 | ✅ | 正常 |
| RT_Mesh_Cfg | 未分类 | RT_Mesh_Sys.f90 | ❌ | — |
| RT_MeshSys | 未分类 | RT_Mesh_Sys.f90 | ❌ | — |
| RT_Mesh_Init_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Init_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Clean_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Clean_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Numbering_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Numbering_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_UpdateCoords_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_UpdateCoords_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_GetState_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_GetState_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Assembly_In | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |
| RT_Mesh_Assembly_Out | 未分类 | RT_Mesh_Proc.f90 | ❌ | — |

### LoadBC域 (21 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_LoadBC_Desc | Desc | RT_LBC_Def.f90 | ✅ | 正常 |
| RT_LoadBC_State | State | RT_LBC_Def.f90 | ✅ | 正常 |
| RT_LoadBC_Algo | Algo | RT_LBC_Def.f90 | ✅ | 正常 |
| RT_LoadBC_Ctx | Ctx | RT_LBC_Def.f90 | ✅ | 正常 |
| RT_BC_Apply_In | 未分类 | RT_BC_ReactionForce.f90 | ❌ | — |
| RT_BC_Reaction_Out | 未分类 | RT_BC_ReactionForce.f90 | ❌ | — |
| RT_LoadBC_Init_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_Init_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_Update_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_Update_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyLoads_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyLoads_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyBCs_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyBCs_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ComputeReactions_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ComputeReactions_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_CheckConvergence_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_CheckConvergence_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyCutback_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_ApplyCutback_Out | 未分类 | RT_LBC_Proc.f90 | ❌ | — |
| RT_LoadBC_Finalize_In | 未分类 | RT_LBC_Proc.f90 | ❌ | — |

### Material域 (3 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Mat_Dispatch_Ctx | Ctx | RT_Mat_Def.f90 | ✅ | 正常 |
| RT_Mat_Route_Entry | 未分类 | RT_Mat_Def.f90 | ✅ | 正常 |
| RT_Mat_Dispatch_Table | 未分类 | RT_Mat_Def.f90 | ✅ | 正常 |

> **注**: Material域为纯路由域，Desc/State/Algo全部委托L3/L4，仅保留路由Ctx

### Output域 (24 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Out_Base_Desc | Desc | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_FieldState | State | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_HistState | State | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out | Algo | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_Ctx | Ctx | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_Frame | Ctx | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_Buffer | Ctx | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_TriggerCtx | Ctx | RT_Out_Def.f90 | ✅ | 正常 |
| RT_Out_Frame (重复) | Ctx | RT_Out_Mgr.f90 | ❌ | 需迁移(重复定义) |
| RT_Out_Core_Args | 未分类 | RT_Out_Mgr.f90 | ❌ | — |
| RT_Out_Cfg | 未分类 | RT_Out_Mgr.f90 | ❌ | — |
| RT_Out_State | State | RT_Out_Mgr.f90 | ❌ | 需迁移 |
| RT_Out_Buf | 未分类 | RT_Out_Mgr.f90 | ❌ | — |
| RT_Out_Init_In | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Init_Out | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Collect_In | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Collect_Out | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Write_In | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Write_Out | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_CheckFreq_In | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_CheckFreq_Out | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Finalize_In | 未分类 | RT_Out_Proc.f90 | ❌ | — |
| RT_Out_Finalize_Out | 未分类 | RT_Out_Proc.f90 | ❌ | — |

### WriteBack域 (26 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_WB_Base_Desc | Desc | RT_WB_Def.f90 | ✅ | 正常 |
| RT_WB_ProgressState | State | RT_WB_Def.f90 | ✅ | 正常 |
| RT_WB_BufferState | State | RT_WB_Def.f90 | ✅ | 正常 |
| RT_WB_Algo | Algo | RT_WB_Def.f90 | ✅ | 正常 |
| RT_WB_Ctx | Ctx | RT_WB_Def.f90 | ✅ | 正常 |
| RT_WB_TransformCtx | Ctx | RT_WB_Def.f90 | ✅ | 正常 |
| CheckpointStatus | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| WriteBackAuditRecord | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| WriteBackWhitelistEntry | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| WriteBackCtx | Ctx | RT_WB_Domain.f90 | ❌ | 需迁移 |
| RT_WriteBack_Domain | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_Init_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_SaveCheckpoint_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_NodePos_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_NodeDisp_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_NodeDisp_Batch_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_ElemStress_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_ElemStrain_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_ElemEplas_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_NodeAccel_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_GPStateVar_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_CurrentTime_Arg | 未分类 | RT_WB_Domain.f90 | ❌ | — |
| RT_WB_Init_In | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_Init_Out | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_NodePos_In | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_NodePos_Out | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_NodeDisp_In | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_NodeDisp_Out | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_ElemStress_In | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_ElemStress_Out | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_Checkpoint_In | 未分类 | RT_WB_Proc.f90 | ❌ | — |
| RT_WB_Checkpoint_Out | 未分类 | RT_WB_Proc.f90 | ❌ | — |

### Bridge域 (15 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Mat_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Elem_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Load_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_BC_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Contact_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Fric_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Constr_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Field_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Analy_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Mesh_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Step_Bridge_Ctx | Ctx | RT_Brg_Def.f90 | ✅ | 正常 |
| RT_Bridge_Ctx | Ctx | RT_Brg_Mgr.f90 | ❌ | 需迁移 |
| RT_Brg_GetSummary_Arg | 未分类 | RT_Brg_Mgr.f90 | ❌ | — |
| RT_Bridge_Domain | 未分类 | RT_Brg_Mgr.f90 | ❌ | — |

### Bridge/Shared子域 (5 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Sol_Cfg | 未分类 | RT_Shared_Def.f90 | ✅ | 正常 |
| RT_Sol_DofMap | 未分类 | RT_Shared_Def.f90 | ✅ | 正常 |
| RT_CSRMatrix | 未分类 | RT_Shared_Def.f90 | ✅ | 正常 |
| RT_Sol_State | State | RT_Shared_Def.f90 | ✅ | 正常 |
| UF_RT_JobStatus | 未分类 | RT_Shared_Def.f90 | ✅ | 正常 |

### Logging域 (5 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_Log_Desc | Desc | RT_Log_Def.f90 | ✅ | 正常 |
| RT_Log_Ctx | Ctx | RT_Log_Def.f90 | ✅ | 正常 |
| RT_Logging_State | State | RT_Log_Def.f90 | ✅ | 正常 |
| RT_LogConfig | 未分类 | RT_Log_Sys.f90 | ❌ | — |
| RT_Logger | 未分类 | RT_Log_Sys.f90 | ❌ | — |

### 根级文件 (13 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|---------|----------|----------|-------------|------|
| RT_ControlDesc | Desc | RT_Global_Def.f90 | ✅ | 正常 |
| RT_SolverCtx | Ctx | RT_Global_Def.f90 | ✅ | 正常 |
| RT_Global_Ctx | Ctx | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_Mat_Domain_Ctx | Ctx | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_Elem_Domain_Ctx | Ctx | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_Asm_Domain_Ctx | Ctx | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_LoadBC_Domain_Ctx | Ctx | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_BridgeState_Type | State | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_BridgeCtrl_Type | 未分类 | RT_Global_Ctx_Types.f90 | ❌ | — |
| RT_Com_Base_Ctx | Ctx | RT_Com_Def.f90 | ✅ | 正常 |
| RT_Amp_Entry | 未分类 | RT_Amp_Mgr.f90 | ❌ | — |
| RT_Amp_Table | 未分类 | RT_Amp_Mgr.f90 | ❌ | — |
| RT_L5_LayerContainer | 未分类 | RT_L5_Layer.f90 | ❌ | — |

---

## 需迁移TYPE汇总

以下TYPE属于四型(Desc/State/Algo/Ctx)但散落在非_Def文件中，建议迁移至对应域的_Def.f90：

| TYPE名 | 四型分类 | 当前文件 | 应迁移至 |
|---------|----------|----------|----------|
| RT_Assembly_Ctx | Ctx | RT_Asm_Domain.f90 | RT_Asm_Def.f90 |
| RT_Assembly_State | State | RT_Asm_Domain.f90 | RT_Asm_Def.f90 |
| UF_TimeIntState | State | RT_Solv_TimeInt.f90 | RT_Solv_Def.f90 |
| RT_Solver_State | State | RT_Solv_ContResidual.f90 | RT_Solv_Def.f90 |
| RT_Sol_Ctx | Ctx | RT_Solv_Mgr.f90 | RT_Solv_Def.f90 |
| StepState | State | RT_Step_Exec.f90 | RT_Step_Def.f90 |
| StepDriverContext | Ctx | RT_Step_Exec.f90 | RT_Step_Def.f90 |
| RT_Step_Ctx (重复) | Ctx | RT_Step_Ctx.f90 | 合并至RT_Step_Def.f90 |
| RT_Inc_Ctx | Ctx | RT_Step_Ctx.f90 | RT_Step_Def.f90 |
| RT_Iter_Ctx | Ctx | RT_Step_Ctx.f90 | RT_Step_Def.f90 |
| Ctx (generic) | Ctx | RT_Step_WS.f90 | RT_Step_Def.f90 |
| RT_Cont_Expl_State | State | RT_Cont_Expl.f90 | RT_Cont_Def.f90 |
| RT_Cont_SurfDesc | Desc | RT_Cont_Core.f90 | RT_Cont_Def.f90 |
| RT_Out_State | State | RT_Out_Mgr.f90 | RT_Out_Def.f90 |
| RT_Out_Frame (重复) | Ctx | RT_Out_Mgr.f90 | 合并至RT_Out_Def.f90 |
| WriteBackCtx | Ctx | RT_WB_Domain.f90 | RT_WB_Def.f90 |
| RT_Bridge_Ctx | Ctx | RT_Brg_Mgr.f90 | RT_Brg_Def.f90 |

---

## _Def.f90 状态总结

| 域 | _Def.f90文件 | 存在 | 四型覆盖 |
|----|-------------|------|----------|
| Assembly | RT_Asm_Def.f90 | ✅ | Desc✅ State✅ Ctx✅ (缺Algo) |
| Solver | RT_Solv_Def.f90 | ✅ | Desc✅ State✅ Ctx✅ (缺Algo) |
| Solver/Coupling | RT_MF_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| StepDriver | RT_Step_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| Contact | RT_Cont_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| Element | RT_Elem_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| Element/Mesh | RT_Mesh_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| LoadBC | RT_LBC_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| Material | RT_Mat_Def.f90 | ✅ | Ctx✅ (纯路由域,Desc/State/Algo委托) |
| Output | RT_Out_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| WriteBack | RT_WB_Def.f90 | ✅ | Desc✅ State✅ Algo✅ Ctx✅ |
| Bridge | RT_Brg_Def.f90 | ✅ | Ctx✅ (桥接域，以Ctx为主) |
| Bridge/Shared | RT_Shared_Def.f90 | ✅ | State✅ (共享类型) |
| Logging | RT_Log_Def.f90 | ✅ | Desc✅ State✅ Ctx✅ (缺Algo) |

**结论：全部11域（含3个子域）的 `_Def.f90` 文件均已存在，无需创建新骨架文件。**
