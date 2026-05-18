# L3_MD TYPE Inventory Matrix

> Auto-generated | Scope: ufc_core/L3_MD/**/*.f90 | Total TYPE count: 968

## Summary

| Domain | Desc | State | Algo | Ctx | N/A | Total | Has_Def |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| (Root) | 1 | 0 | 0 | 0 | 4 | 5 | No |
| Analysis | 11 | 5 | 4 | 4 | 72 | 96 | Yes |
| Assembly | 1 | 1 | 1 | 1 | 18 | 22 | No |
| Boundary | 17 | 7 | 5 | 5 | 35 | 69 | Yes |
| Bridge | 0 | 0 | 0 | 0 | 17 | 17 | No |
| Constraint | 0 | 1 | 1 | 1 | 13 | 16 | Yes |
| Field | 1 | 1 | 0 | 1 | 7 | 10 | Yes |
| Interaction | 1 | 1 | 1 | 1 | 46 | 50 | Yes |
| KeyWord | 3 | 1 | 0 | 1 | 33 | 38 | Yes |
| Material | 36 | 6 | 2 | 3 | 178 | 225 | Yes |
| Mesh | 15 | 2 | 8 | 1 | 42 | 68 | Yes |
| Model | 5 | 4 | 2 | 2 | 192 | 205 | Yes |
| Output | 3 | 4 | 2 | 2 | 81 | 92 | Yes |
| Part | 3 | 1 | 0 | 1 | 16 | 21 | Yes |
| Section | 2 | 1 | 0 | 1 | 25 | 29 | Yes |
| WriteBack | 0 | 0 | 0 | 0 | 5 | 5 | Yes |
| **TOTAL** | **99** | **35** | **26** | **24** | **784** | **968** | - |

---

## Per-Domain Detail

### (Root)

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Analysis_Group_DESC` | Desc | `MD_Analysis_GroupModule.f90` | No | - |
| `HashNode` | N/A | `MD_Base_HashSetUtil.f90` | No | - |
| `HashSetType` | N/A | `MD_Base_HashSetUtil.f90` | No | - |
| `MD_L3_DomainAssoc` | N/A | `MD_L3_Layer.f90` | No | - |
| `MD_L3_LayerContainer` | N/A | `MD_L3_Layer.f90` | No | - |

### Analysis

> Sub-domains: Amplitude, Coupling, Solver, Step

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Amp_Algo` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Add_Arg` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Desc` | Desc | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_EvalAtTime_Arg` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Get_Arg` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_GetSummary_Arg` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_State` | State | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amplitude_Domain` | N/A | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Modulated_Desc` | Desc | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Periodic_Desc` | Desc | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Tabular_Desc` | Desc | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_User_Desc` | Desc | `Analysis\Amplitude\MD_Amp_Def.f90` | Yes | Amplitude |
| `MD_Amp_Ext_Desc` | N/A | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_Algo` | Algo | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_Ctx` | Ctx | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_Desc` | Desc | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_In` | N/A | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_Out` | N/A | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amplitude_Eval_State` | State | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amp_Slot_Ctx` | N/A | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Amp_Slot_Desc` | N/A | `Analysis\Amplitude\MD_Amp_UF.f90` | No | Amplitude |
| `MD_Coup_PairDef` | N/A | `Analysis\Coupling\MD_Cpl_Def.f90` | Yes | Coupling |
| `MD_Cpl_Algo` | Algo | `Analysis\Coupling\MD_Cpl_Def.f90` | Yes | Coupling |
| `MD_Cpl_Ctx` | Ctx | `Analysis\Coupling\MD_Cpl_Def.f90` | Yes | Coupling |
| `MD_Cpl_Desc` | Desc | `Analysis\Coupling\MD_Cpl_Def.f90` | Yes | Coupling |
| `MD_Cpl_State` | State | `Analysis\Coupling\MD_Cpl_Def.f90` | Yes | Coupling |
| `MD_Ana_Comp_Group_Desc` | N/A | `Analysis\MD_Ana_Comp.f90` | No | 曾用名 `AnalysisGroupDesc` |
| `MD_LinearSolver_Desc` | Desc | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_NR_Algo` | Algo | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Precond_Desc` | Desc | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Solver_Algo` | Algo | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Solver_Ctx` | Ctx | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Solver_Desc` | Desc | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Solver_State` | State | `Analysis\Solver\MD_Solv_Def.f90` | Yes | Solver |
| `MD_Solver_AddConfig_Arg` | N/A | `Analysis\Solver\MD_Solv_Mgr.f90` | No | Solver |
| `MD_Solver_Domain` | N/A | `Analysis\Solver\MD_Solv_Mgr.f90` | No | Solver |
| `MD_Solver_GetConfig_Arg` | N/A | `Analysis\Solver\MD_Solv_Mgr.f90` | No | Solver |
| `MD_Solver_GetConfigForStep_Arg` | N/A | `Analysis\Solver\MD_Solv_Mgr.f90` | No | Solver |
| `MD_Solver_GetSummary_Arg` | N/A | `Analysis\Solver\MD_Solv_Mgr.f90` | No | Solver |
| `MD_Step_Ctx` | Ctx | `Analysis\Step\MD_Step_Def.f90` | Yes | Step |
| `MD_Step_State` | State | `Analysis\Step\MD_Step_Def.f90` | Yes | Step |
| `MD_Step_Desc` | Desc | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `MD_Step_Domain` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `MD_Step_Get_Arg` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `MD_Step_GetByName_Arg` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `MD_Step_GetSummary_Arg` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `MD_Step_WriteBack_Arg` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `StepAlgo` | N/A | `Analysis\Step\MD_Step_Mgr.f90` | No | Step |
| `IncCtx` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `IncState` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_ConvergenceCriteria` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_ConvergenceResult` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_Model_StepConfig` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_NonlinSolv` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_OutCfg` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_OutReq` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_RestartData` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_SolverState` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_TimeIncrementControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `MD_TimeIncrementResult` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `StepCtx` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `StepDesc` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `StepStateData` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_AcousticControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_AnnealControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_BuckleControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ComplexFreqControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_CoupledTESControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_CTDispControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_CTElecControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_DynamicParams` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_DynamicSubspaceControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ElecBCManager` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ElectromagneticControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_GeostaticControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_HeatTransControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_IncrementControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_MassDiffControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ModalControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ModalDynamicControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ModalStepDef` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_PiezoControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_PoreBCManager` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_RandomResponseControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ResponseSpectrumControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_RiksControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_SoilsControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_SolutionControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_SSDControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_StaticPerturbControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_SteadyStateTransportControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_StepDef` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_StepManager` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_SubstructureControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ThermalBCManager` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |
| `UF_ViscoControl` | N/A | `Analysis\Step\MD_Step_Proc.f90` | No | Step |

### Assembly

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `UF_InstanceDef` | N/A | `Assembly\MD_Asm_Inst.f90` | No | - |
| `MD_Asm_Algo` | Algo | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_Ctx` | Ctx | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetElemSet_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetElemSetByName_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetInstance_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetNodeSet_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetNodeSetByName_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetSummary_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetSurface_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetSurfaceByName_Arg` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_State` | State | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Assembly_Domain` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_ConstraintDef` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Instance_Desc` | Desc | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_SetDef` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_SurfaceDef` | N/A | `Assembly\MD_Asm_Mgr.f90` | No | - |
| `MD_Asm_GetInstance_Arg` | N/A | `Assembly\MD_Asm_Sync.f90` | No | - |
| `MD_Asm_GetSummary_Arg` | N/A | `Assembly\MD_Asm_Sync.f90` | No | - |
| `MD_Assembly_AddInstance_Arg` | N/A | `Assembly\MD_Asm_Sync.f90` | No | - |
| `UF_AssemblyDef` | N/A | `Assembly\MD_Asm_Sync.f90` | No | - |
| `UF_Constraint` | N/A | `Assembly\MD_Asm_Sync.f90` | No | - |

### Boundary

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_BC_Base_Algo` | Algo | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_Base_Ctx` | Ctx | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_Base_Desc` | Desc | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_Base_State` | State | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_DISP_Desc` | Desc | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_UMASFL_Desc` | Desc | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_UPOT_Desc` | Desc | `Boundary\MD_BC_Def.f90` | Yes | - |
| `MD_BC_UTEMP_Desc` | Desc | `Boundary\MD_BC_Def.f90` | Yes | - |
| `BCDef` | N/A | `Boundary\MD_BC_Mgr.f90` | No | - |
| `BCDef_Init_In` | N/A | `Boundary\MD_BC_Mgr.f90` | No | - |
| `BCDef_Init_Out` | N/A | `Boundary\MD_BC_Mgr.f90` | No | - |
| `BodyForceDef_Init_In` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `BodyForceDef_Init_Out` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `CLoadDef_Init_In` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `CLoadDef_Init_Out` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `DLoadDef_Init_In` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `DLoadDef_Init_Out` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_BCDef` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_BodyForceDef` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_CLoadDef` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_DLoadDef` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_LoadBCManager` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `UF_ThermalLoadDef` | N/A | `Boundary\MD_LBC_Brg.f90` | No | - |
| `LoadB` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_Algo` | Algo | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_Ctx` | Ctx | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_Desc` | Desc | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_Runtime_Domain` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_State` | State | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_TableAlgo` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_TableCtx` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_TableDesc` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_TableDomain` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_LoadBC_TableSta` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `StepDef` | N/A | `Boundary\MD_LBC_Container.f90` | No | - |
| `MD_BC_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_BC_State` | State | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_IC_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_Algo` | Algo | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_Ctx` | Ctx | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetBC_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetBCByName_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetBCsForStep_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetLoad_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetLoadByName_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetLoadsForStep_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LBC_GetSummary_Arg` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_Load_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_Load_State` | State | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_LoadBC_Domain` | N/A | `Boundary\MD_LBC_Domain.f90` | No | - |
| `MD_Field_Predef_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_IC_Def_Type` | N/A | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_IC_State` | State | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_Base_Algo` | Algo | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_Base_Ctx` | Ctx | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_Base_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_Base_State` | State | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_DFLUX_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_Dist_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_DLOAD_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_FILM_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_HETVAL_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_Load_UWAVE_Desc` | Desc | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_LoadBC_Algo` | Algo | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_LoadBC_Ctx` | Ctx | `Boundary\MD_Load_Def.f90` | Yes | - |
| `MD_LoadBC_State` | State | `Boundary\MD_Load_Def.f90` | Yes | - |
| `LoadDef` | N/A | `Boundary\MD_Load_Mgr.f90` | No | - |
| `LoadDef_Init_In` | N/A | `Boundary\MD_Load_Mgr.f90` | No | - |
| `LoadDef_Init_Out` | N/A | `Boundary\MD_Load_Mgr.f90` | No | - |

### Bridge

> Sub-domains: Bridge_L4, Bridge_L5

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `PH_Constraint_Params` | N/A | `Bridge\Bridge_L4\MD_ConstraintPH_Brg.f90` | No | Bridge_L4 |
| `PH_Constraint_Params_Array` | N/A | `Bridge\Bridge_L4\MD_ConstraintPH_Brg.f90` | No | Bridge_L4 |
| `MD_PH_Elem_GetElemCtx_Arg` | N/A | `Bridge\Bridge_L4\MD_ElemPH_Brg.f90` | No | Bridge_L4 |
| `MD_PH_Geom_FillElemCtx_Arg` | N/A | `Bridge\Bridge_L4\MD_GeomPH_Brg.f90` | No | Bridge_L4 |
| `MD_LoadBC_BuildStepBCs_Ctx_Type` | N/A | `Bridge\Bridge_L4\MD_LBCPH_Brg.f90` | No | Bridge_L4 |
| `MD_LoadBC_BuildStepLoads_Ctx_Type` | N/A | `Bridge\Bridge_L4\MD_LBCPH_Brg.f90` | No | Bridge_L4 |
| `MD_LoadBC_StepBCsOut_Type` | N/A | `Bridge\Bridge_L4\MD_LBCPH_Brg.f90` | No | Bridge_L4 |
| `MD_LoadBC_StepLoadsOut_Type` | N/A | `Bridge\Bridge_L4\MD_LBCPH_Brg.f90` | No | Bridge_L4 |
| `MD_RT_Elem_Comp_Idx_Arg` | N/A | `Bridge\Bridge_L5\MD_ElemRT_Brg.f90` | No | Bridge_L5 |
| `MD_IC_ContactAddForce_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_IC_ContactAddK_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_IC_ContactAssemTriplets_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_IC_ContactEvalFace_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_IC_ContactInit_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_IC_ContactUpdateGeom_Arg` | N/A | `Bridge\Bridge_L5\MD_Int_ContactArgs.f90` | No | Bridge_L5 |
| `MD_Mesh_Brg` | N/A | `Bridge\Bridge_L5\MD_Mesh_Brg.f90` | No | Bridge_L5 |
| `RT_Mesh_IDMap` | N/A | `Bridge\Bridge_L5\MD_Mesh_Brg.f90` | No | Bridge_L5 |

### Constraint

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `CplConstraintDef` | N/A | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `MD_Constraint_State` | State | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `MD_ConstraintUnion` | N/A | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `MPCConstraintDef` | N/A | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `RigidBodyDef` | N/A | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `TieConstraintDef` | N/A | `Constraint\MD_Constr_Def.f90` | Yes | - |
| `MD_Constr_Algo` | Algo | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_Ctx` | Ctx | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_GetCpl_Arg` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_GetMPC_Arg` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_GetRigid_Arg` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_GetSummary_Arg` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constr_GetTie_Arg` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `MD_Constraint_Domain` | N/A | `Constraint\MD_Constr_Mgr.f90` | No | - |
| `UF_ContactPropertyDB` | N/A | `Constraint\MD_Constr_Prop.f90` | No | - |
| `UF_ContactPropertyDef` | N/A | `Constraint\MD_Constr_Prop.f90` | No | - |

### Field

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Field_Ctx` | Ctx | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_Field_Desc` | Desc | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_Field_State` | State | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_FieldEntry` | N/A | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_FieldInitCond` | N/A | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_FieldRegionRef` | N/A | `Field\MD_Field_Def.f90` | Yes | - |
| `MD_ElemIPData` | N/A | `Field\MD_Field_Mgr.f90` | No | - |
| `MD_FieldMgr_Type` | N/A | `Field\MD_Field_Mgr.f90` | No | - |
| `MD_NodalField` | N/A | `Field\MD_Field_Mgr.f90` | No | - |
| `MD_NodeDisp` | N/A | `Field\MD_Field_Mgr.f90` | No | - |

### Interaction

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `ContAlgo` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `ContCtx` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_ContactPairState` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_ContactProperty` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_AddPair_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_AddProperty_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_Domain` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_GetPair_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_GetPairByName_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_GetProperty_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `MD_Interaction_GetSummary_Arg` | N/A | `Interaction\MD_Cont_Mgr.f90` | No | - |
| `HashTableEntry` | N/A | `Interaction\MD_Hash_Table.f90` | No | - |
| `HashTableType` | N/A | `Interaction\MD_Hash_Table.f90` | No | - |
| `ConnPropsMgr` | N/A | `Interaction\MD_Int_Connector.f90` | No | - |
| `ContactPairType` | N/A | `Interaction\MD_Int_Def.f90` | Yes | - |
| `FrictionModelType` | N/A | `Interaction\MD_Int_Def.f90` | Yes | - |
| `MD_Int_Ctx` | Ctx | `Interaction\MD_Int_Def.f90` | Yes | - |
| `MD_Interaction_Algo` | Algo | `Interaction\MD_Int_Def.f90` | Yes | - |
| `MD_Interaction_Desc` | Desc | `Interaction\MD_Int_Def.f90` | Yes | - |
| `MD_Interaction_State` | State | `Interaction\MD_Int_Def.f90` | Yes | - |
| `SurfaceInteractionType` | N/A | `Interaction\MD_Int_Def.f90` | Yes | - |
| `InteractionMappingType` | N/A | `Interaction\MD_Int_Mapper.f90` | No | - |
| `SurfaceSetType` | N/A | `Interaction\MD_Int_Mapper.f90` | No | - |
| `UF_ContProblem` | N/A | `Interaction\MD_Int_Mgr.f90` | No | - |
| `Bucket` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `BucketGrid` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `BVHNode` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `BVHTree` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyFriction_In` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyFriction_Out` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyLagrangeMultiplier_In` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyLagrangeMultiplier_Out` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyPenaltyMethod_In` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_ApplyPenaltyMethod_Out` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_UpdateGeometry_In` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `Cont_UpdateGeometry_Out` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContAlgoCtrl` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContAlgoDesc` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContCandidate` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContContext` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContForceRes` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContForceRes_Init_In` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContForceRes_Init_Out` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContNode` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContPair` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContPairDef` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContSegment` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `ContSurface` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `FrictionParams` | N/A | `Interaction\MD_Int_Types.f90` | No | - |
| `UF_ContactAlgoDesc` | N/A | `Interaction\MD_Int_Types.f90` | No | - |

### KeyWord

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `ParseInpFile_In` | N/A | `KeyWord\MD_Inp_Parse.f90` | No | - |
| `ParseInpFile_Out` | N/A | `KeyWord\MD_Inp_Parse.f90` | No | - |
| `UF_ParsedModel` | N/A | `KeyWord\MD_Inp_Parse.f90` | No | - |
| `KW_ParseState` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `KWAlgo` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `KWCtx` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `KWKeywordDef` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `MD_KeyWord_Domain` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `MD_KeyWord_GetSummary_Arg` | N/A | `KeyWord\MD_KeyWord_Domain.f90` | No | - |
| `ParameterSpec_Type` | N/A | `KeyWord\MD_KeyWord_Validator.f90` | No | - |
| `KeyWord_Node_Type` | N/A | `KeyWord\MD_KeyWordParser_Def.f90` | Yes | - |
| `KeyWord_ParamSpec_Type` | N/A | `KeyWord\MD_KeyWordParser_Def.f90` | Yes | - |
| `KeyWord_ParsingRule_Type` | N/A | `KeyWord\MD_KeyWordParser_Def.f90` | Yes | - |
| `KW_Coverage_Report` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_CoverageAudit_Desc` | Desc | `KeyWord\MD_KW.f90` | No | - |
| `KW_ExtensionManagerType` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_ExtensionPluginType` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_Find_Desc` | Desc | `KeyWord\MD_KW.f90` | No | - |
| `KW_Find_State` | State | `KeyWord\MD_KW.f90` | No | - |
| `KW_HashTableType` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_MetadataType` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_Priority_Check` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_Reg_Desc` | Desc | `KeyWord\MD_KW.f90` | No | - |
| `KW_Registry_Ctx` | Ctx | `KeyWord\MD_KW.f90` | No | - |
| `KW_RegistryType` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `MD_KW_CoverageReportOut_Type` | N/A | `KeyWord\MD_KW.f90` | No | - |
| `KW_ASTNodeType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_DataLineType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_LexerStateType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_MetadataType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_ParamDefType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_ParamValueType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_ParserStateType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_TokenType` | N/A | `KeyWord\MD_KW_Def.f90` | Yes | - |
| `KW_MapperStateType` | N/A | `KeyWord\MD_KW_Mapper.f90` | No | - |
| `IntMemoryPool` | N/A | `KeyWord\MD_KW_MemPool.f90` | No | - |
| `MemPoolManager` | N/A | `KeyWord\MD_KW_MemPool.f90` | No | - |
| `RealMemoryPool` | N/A | `KeyWord\MD_KW_MemPool.f90` | No | - |

### Material

> Sub-domains: Acoustic, Base, Bridge, Contract, Creep, Dispatch, Domain, Plast, Registry, Shared

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `Acoustic_Derived_Props` | N/A | `Material\Acoustic\MD_Mat_AcousticProps.f90` | No | Acoustic |
| `MD_Mat_Ctx` | Ctx | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_DamageProps` | N/A | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_Desc` | Desc | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_ElasticProps` | N/A | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_PlastProps` | N/A | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_State` | State | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_ThermalProps` | N/A | `Material\Base\MD_Mat_BaseDef.f90` | No | Base |
| `MD_Mat_Library` | N/A | `Material\Base\MD_Mat_Reg.f90` | No | Base |
| `MD_Mat_Library` | N/A | `Material\Base\MD_MatStateInit.f90` | No | Base |
| `MD_Mat_PH_UMAT_Algo` | Algo | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `MD_Mat_PH_UMAT_Ctx` | Ctx | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `MD_Mat_PH_UMAT_Desc` | Desc | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `MD_Mat_PH_UMAT_In` | N/A | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `MD_Mat_PH_UMAT_Out` | N/A | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `MD_Mat_PH_UMAT_State` | State | `Material\Bridge\MD_Mat_Brg.f90` | No | Bridge |
| `Desc_MaterialModel` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatCtxLegacy` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatFlags` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatInst` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatOri` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatPoolMgr` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatProps` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatPropValid` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatReg` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MatRes` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MAT_UMAT_Input` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MAT_UMAT_Intf` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MAT_UMAT_Output` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_Material_Desc` | Desc | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MaterialEntry` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MatMeta` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `MD_MatModel` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `State_IntPoint` | N/A | `Material\Contract\MD_Mat_Def.f90` | Yes | Contract |
| `DPPropertiesManager` | N/A | `Material\Contract\MD_MATPLGGEOTECH_Ctx.f90` | No | Contract |
| `MCPropertiesManager` | N/A | `Material\Contract\MD_MATPLGGEOTECH_Ctx.f90` | No | Contract |
| `ComputeDeviatoricStress_In` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `ComputeDeviatoricStress_Out` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `ComputeFlowDirection_In` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `ComputeFlowDirection_Out` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `PlastFlowRule` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `PlastHardeningRule` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `PlastMatBase` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `PlastStateVariables` | N/A | `Material\Contract\MD_MatPLM_DescBase.f90` | No | Contract |
| `GursonMaterial` | N/A | `Material\Creep\MD_MATPORFOAM_Ctx.f90` | No | Creep |
| `ContmMatRes` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `CreepState` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `DampingDef_Set_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `DmgState` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `ExpansionDef_SetIso_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `ExpDataPt` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `ExpDataSet` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `FatigueState` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `HardeningTable_AddPoint_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `HardeningTable_Init_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `HardeningTable_Interpolate_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `HardeningTable_Interpolate_Out` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `Mat_Entry` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_Init_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetDamping_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetElasticAniso_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetElasticIso_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetElasticOrtho_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetElasticTransIso_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetExpansion_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MaterialDef_SetPlasticMises_In` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MatParamId` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MatPropertyDef` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `ParameterValidResult` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `PhaseTransformationState` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_DampingDef` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_ExpansionDef` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_HardeningTable` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_MaterialDB` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_MaterialDef` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UF_MaterialModel` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `UnifMatInfo` | N/A | `Material\Dispatch\MD_Mat_Lib.f90` | No | Dispatch |
| `MD_Mat_Domain` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetByName_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetDesc_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetLegacyView_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetState_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetSummary_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `MD_Mat_GetUMATPropsView_Arg` | N/A | `Material\Domain\MD_MatDomain_Def.f90` | Yes | Domain |
| `CrystalPlasticityProperties` | N/A | `Material\Plast\MD_Mat_Plast_Crystal.f90` | No | Plast |
| `RateDependentPropertiesManager` | N/A | `Material\Plast\MD_Mat_Plast_RateDep.f90` | No | Plast |
| `ViscPlastMat` | N/A | `Material\Plast\MD_Mat_Plast_Viscoplastic.f90` | No | Plast |
| `PlastMat_GetInfo_In` | N/A | `Material\Registry\MD_MatPLM_Reg.f90` | No | Registry |
| `PlastMat_GetInfo_Out` | N/A | `Material\Registry\MD_MatPLM_Reg.f90` | No | Registry |
| `PlastMatInfo` | N/A | `Material\Registry\MD_MatPLM_Reg.f90` | No | Registry |
| `PlastModels_Desc` | Desc | `Material\Registry\MD_MatPLM_Reg.f90` | No | Registry |
| `MatLibModelEntry` | N/A | `Material\Registry\MD_MatReg_Algo.f90` | No | Registry |
| `MD_MatIDCacheEntry` | N/A | `Material\Registry\MD_MatReg_Algo.f90` | No | Registry |
| `Biot_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `CompDmg_State` | State | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `CrushFoam_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `CZM_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `HolzapfelOgden_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `Lamina_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `Multiscale_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `RateFoam_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `SMA_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | No | Shared |
| `MD_L3_to_L4_Contract` | N/A | `Material\Shared\MD_Mat_Contract.f90` | No | Shared |
| `CreepMatBase` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `CreepMatCtx` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `CreepMatInfo` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `CreepMatResult` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `CreepModels_Desc` | Desc | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `GarofaloCreepMat` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `NortonCreepMat` | N/A | `Material\Shared\MD_MAT_CREEP_CORE.f90` | No | Shared |
| `CohesiveBehaviorPropertiesManager` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `CompMatBase` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `CompMatInfo` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `CreepDamageMat` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `CreepDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DmgMatCtx` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DmgMatInfo` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DmgMatResult` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DmgPropertiesManager` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DuctileDamageMat` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DuctileDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `FiberReinfComp_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `FiberReinforcedCompMat` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `LamComp_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `LaminateCompMat` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `ProgDamagePropertiesManager` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `ProgDamageStage` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `TDepDamageProps` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `ThermalDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `ThermDamageMat` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_AnisotropicData` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_CDP_Data` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_ComplexMaterialDef` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_CompositePly_Data` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_MaterialCategory` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `UF_SoilMaterial_Data` | N/A | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | No | Shared |
| `DmgMatBase` | N/A | `Material\Shared\MD_Mat_DMG_LibBase.f90` | No | Shared |
| `CDP_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `CDP_State` | State | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `JointedRock_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `MCC_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `MCC_State` | State | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `SmearedCrack_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | No | Shared |
| `ABHypMat` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypAB_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HyperfoamPropertiesManager` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HyperfoamTerm` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMat_ApplyLagrangeMultiplier_In` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMat_ApplyLagrangeMultiplier_Out` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMat_ApplyPenaltyMethod_In` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMat_ApplyPenaltyMethod_Out` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMatBase` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypMatInfo` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `HypStd_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `IncompressibilityMethod` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `Marlow_Ext_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `MRHypMat` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `Mullins_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `Mullins_State` | State | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `NHHypMat` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `OgdenHypMat` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `VDW_Ext_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `YeohHypMat` | N/A | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | No | Shared |
| `CreepState` | N/A | `Material\Shared\MD_Mat_Legacy_State.f90` | No | Shared |
| `DmgState` | N/A | `Material\Shared\MD_Mat_Legacy_State.f90` | No | Shared |
| `FatigueState` | N/A | `Material\Shared\MD_Mat_Legacy_State.f90` | No | Shared |
| `PhaseTransformationState` | N/A | `Material\Shared\MD_Mat_Legacy_State.f90` | No | Shared |
| `JouleHeatPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `LatentHeatPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `PermeabilityPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `PhaseChangeData` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SorptionPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_ComputeHeat_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_ComputeHeat_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_GetCpAtTemp_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_GetCpAtTemp_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_Init_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatProperties_Init_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `SpecificHeatPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityProperties_GetKAtTemp_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityProperties_GetKAtTemp_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityProperties_Init_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityProperties_Init_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityPropertiesManager` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityPropertiesManager_Add_In` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `ThermConductivityPropertiesManager_Add_Out` | N/A | `Material\Shared\MD_MAT_THERM_CORE.f90` | No | Shared |
| `MD_MAT_UMAT_Ifc` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `MD_MAT_UMAT_In` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `MD_MAT_UMAT_MaterialEntry` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `MD_MAT_UMAT_Out` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UEXPAN_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UHARD_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UMATCallCache` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UMATDebugInfo` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UMATInputType` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UMATOutputType` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `USDFLD_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UserMat_Registry` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UserMaterialProperties_Init_In` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UserMaterialProperties_Init_Out` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UserMatInfo` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `UserMatMgr` | N/A | `Material\Shared\MD_MAT_USER_CORE.f90` | No | Shared |
| `NLVisc_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `PolymerCure_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `PronyTerm` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `PronyVisc_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `PronyViscoelasticMat` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `RateFoam_Ext_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscMatBase` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscMatCtx` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscMatInfo` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscMatResult` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `Viscoplast_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscoplDmg_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscoPropertiesManager` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `ViscosityPropertiesManager` | N/A | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | No | Shared |
| `DampPropertiesManager` | N/A | `Material\Shared\MD_MatELA_Damping.f90` | No | Shared |
| `ElasMatBase` | N/A | `Material\Shared\MD_MatELA_ElasBase.f90` | No | Shared |
| `ElasMatInfo` | N/A | `Material\Shared\MD_MatELA_ElasBase.f90` | No | Shared |
| `PDepElasticProps` | N/A | `Material\Shared\MD_MatELA_ElasBase.f90` | No | Shared |
| `TDepElasticProps` | N/A | `Material\Shared\MD_MatELA_ElasBase.f90` | No | Shared |
| `ExpansionPropertiesManager` | N/A | `Material\Shared\MD_MatELA_Expansion.f90` | No | Shared |
| `MatAlgo_Algo` | Algo | `Material\Shared\MD_MatEval_Def.f90` | Yes | Shared |
| `MatEval_Ctx` | Ctx | `Material\Shared\MD_MatEval_Def.f90` | Yes | Shared |
| `TDepPlasticProps` | N/A | `Material\Shared\MD_MatPLM_TDep.f90` | No | Shared |

### Mesh

> Sub-domains: Element

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Elem_Base_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Base_Ctx` | Ctx | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Base_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Base_State` | State | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Beam_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Beam_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Cohesive_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Cohesive_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Dashpot_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Gasket_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Infinite_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Mass_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Mass_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Shell_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Shell_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Solid2D_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Solid3D_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Solid3D_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Spring_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Surface_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Truss_Algo` | Algo | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_Elem_Truss_Desc` | Desc | `Mesh\Element\MD_Elem_Def.f90` | Yes | Element |
| `MD_ElemDomain_Algo` | Algo | `Mesh\Element\MD_Elem_Domain.f90` | No | Element |
| `MD_Elem_Populate_Arg` | N/A | `Mesh\Element\MD_Elem_Populate.f90` | No | Element |
| `MD_Elem_Validate_Result` | N/A | `Mesh\Element\MD_Elem_Validate.f90` | No | Element |
| `UF_DOFManagerType` | N/A | `Mesh\MD_DOF_Impl.f90` | No | - |
| `UF_NodalDOF` | N/A | `Mesh\MD_DOF_Impl.f90` | No | - |
| `MD_DOFMap` | N/A | `Mesh\MD_DOF_Mgr.f90` | No | - |
| `UF_DOFLabelMapType` | N/A | `Mesh\MD_DOF_Mgr.f90` | No | - |
| `MD_Elem_Base_Desc` | Desc | `Mesh\MD_Elem_Def.f90` | Yes | - |
| `Desc_Element` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ElementCatalog` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ElementMetadata` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ElemFlags` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ElemType_Init_In` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ElemType_Init_Out` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `MD_IntegrationPoint_Type` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `ShapeFuncResult` | N/A | `Mesh\MD_Elem_Mgr.f90` | No | - |
| `Desc_Mesh` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `ElemGlobalMapEntry` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshConnectivity` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshGeometry` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshGlobalNum` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshIO` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshRefinement` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshSmoothing` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshTransform` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `NodeGlobalMapEntry` | N/A | `Mesh\MD_Mesh_API.f90` | No | - |
| `MeshData` | N/A | `Mesh\MD_Mesh_Data.f90` | No | - |
| `MD_ElemSetEntry` | N/A | `Mesh\MD_Mesh_Def.f90` | Yes | - |
| `MD_Mesh_Desc` | Desc | `Mesh\MD_Mesh_Def.f90` | Yes | - |
| `MD_Mesh_State` | State | `Mesh\MD_Mesh_Def.f90` | Yes | - |
| `MD_NodeSetEntry` | N/A | `Mesh\MD_Mesh_Def.f90` | Yes | - |
| `MD_Mesh_Domain` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetDofMap_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetElemConnect_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetElemSection_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetNodeByName_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetNodeCoords_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetSummary_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_GetSurfaceByName_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_WriteBack_ElemStress_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MD_Mesh_WriteBack_NodePos_Arg` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `MeshAlgo` | N/A | `Mesh\MD_Mesh_Domain.f90` | No | - |
| `ElemGlobalMapEntry` | N/A | `Mesh\MD_Mesh_GlobalNum.f90` | No | - |
| `MeshGlobalNum` | N/A | `Mesh\MD_Mesh_GlobalNum.f90` | No | - |
| `NodeGlobalMapEntry` | N/A | `Mesh\MD_Mesh_GlobalNum.f90` | No | - |
| `MeshManager` | N/A | `Mesh\MD_Mesh_Mgr.f90` | No | - |

### Model

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `DataAccess` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `DataObj` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `FieldMeta` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `ModuleAPI` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `TypeMeta` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `TypeReg` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `UniFrame` | N/A | `Model\MD_Base_DataModMgr.f90` | No | - |
| `MD_AmpCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_AmpDef_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Assembly_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ConstCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Coupling_Constraint_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ElemDef_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ElemDefTbl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ElemSet_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ElemTbl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Eq_Constraint_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Instance_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MatAssign_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MatCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MatDef_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MatLib_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MeshCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_ModelCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_MPC_Constraint_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_NodeSet_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_NodeTbl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Part_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_PartCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_RigidBody_Constraint_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_SectCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_SectDef_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_SetCtrl_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_StepCfg_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_StepDef_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `MD_Surface_Type` | N/A | `Model\MD_Base_Def.f90` | Yes | - |
| `Utils_Error_In` | N/A | `Model\MD_Base_Enums.f90` | No | - |
| `Utils_Error_Out` | N/A | `Model\MD_Base_Enums.f90` | No | - |
| `BinaryReader` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `BinaryWriter` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `FileHandle` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `HDF5Dataset` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `HDF5File` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `HDF5Group` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `RW_Deserializer` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `RW_MemMgr` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `RW_Serializer` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `RW_SymbolTable` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `RW_VariableEntry` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `XMLAttribute` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `XMLDocument` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `XMLElement` | N/A | `Model\MD_Base_IOSerialMgr.f90` | No | - |
| `ArraySizeCache` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `Date` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `GaussQuadrature` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `MathUtils` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `SparseMatrixUtils` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `Stopwatch` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `StringFormatter` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `StringList` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `StringTokenizer` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `Time` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `Timer` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `VecOps` | N/A | `Model\MD_Base_MathUtils.f90` | No | - |
| `BaseAlgo` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseAPI` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseCtx` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseDesc` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseManager` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseRegistry` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseSta` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseState` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `BaseSystem` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `DofLabMap` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `DofMap` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `DofSys` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ElemMatIntf` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ElemSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ElemStepCtx` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `HashEntry` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `IPState` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ModelSys` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `NodeSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ObjBase` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ObjContainer` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `ObjPtr` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `RT_Element` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `RT_Model` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `RT_Node` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `Serializable` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `SurfSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `TreeDeserializer` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `TreeSerializer` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Assem` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Description` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Element` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_ElemHdl` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_ElemSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_FldDesc` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_FldHdl` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_FldRegEnt` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_FldSys` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Instance` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Model` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_ModelDesc` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Node` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_NodeHdl` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_NodeSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_Part` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_SetHdl` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_SurfHdl` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_SurfSet` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_UFCore` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UF_UFField` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `UFView` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `VarCtx` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `VarDesc` | N/A | `Model\MD_Base_ObjModel.f90` | No | - |
| `AbstractPathRes` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `BatchOpMgr` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `IDList` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `LazyIndexMgr` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `MemPool` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `ParentChildEntry` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `ParentChildMap` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `PathComponents` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `TreeNodeType` | N/A | `Model\MD_Base_TreeIndex.f90` | No | - |
| `MD_AmpCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_AmpDef_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_ElemDef_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_ElemDefTbl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_ElemSet_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_ElemTbl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_MatAssign_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_MatCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_MatDef_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_MatLib_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_MeshCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_ModelCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_NodeSet_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_NodeTbl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_SectCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_SectDef_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_SetCtrl_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_StepCfg_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `MD_StepDef_Type` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `ShapeFuncResult` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `State_Instance` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `UF_ElemFormul` | N/A | `Model\MD_BaseTypes.f90` | No | - |
| `KinematicsMech` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `KinematicsMeta` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `KinematicsTemp` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `KinematicsThermal` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `KinematicsTime` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `UF_Kinematics` | N/A | `Model\MD_Kinematics_Def.f90` | Yes | - |
| `MD_ModelBuilder_Build_Algo` | Algo | `Model\MD_Model_Builder.f90` | No | - |
| `MD_ModelBuilder_Build_Ctx` | Ctx | `Model\MD_Model_Builder.f90` | No | - |
| `MD_ModelBuilder_Build_Desc` | Desc | `Model\MD_Model_Builder.f90` | No | - |
| `MD_ModelBuilder_Build_In` | N/A | `Model\MD_Model_Builder.f90` | No | - |
| `MD_ModelBuilder_Build_Out` | N/A | `Model\MD_Model_Builder.f90` | No | - |
| `MD_ModelBuilder_Build_State` | State | `Model\MD_Model_Builder.f90` | No | - |
| `MD_Model_Desc` | Desc | `Model\MD_Model_Def.f90` | Yes | - |
| `MD_Model_State` | State | `Model\MD_Model_Def.f90` | Yes | - |
| `MD_Model_Desc` | Desc | `Model\MD_Model_Domain.f90` | No | - |
| `MD_Model_Domain` | N/A | `Model\MD_Model_Domain.f90` | No | - |
| `MD_Model_GetSummary_Arg` | N/A | `Model\MD_Model_Domain.f90` | No | - |
| `AdvFeatureRegistryEntry` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `AdvPropsMgr` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `Context_Model` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `Context_Model_State` | State | `Model\MD_Model_Lib.f90` | No | - |
| `Desc_Model` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `ImportProperties` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `ImportResults` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_AddMaterial_In` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_AddMaterial_Out` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_AddPart_In` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_AddPart_Out` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_ApplyBC_In` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_ApplyBC_Out` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_ApplyLoads_In` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_ApplyLoads_Out` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_Algo` | Algo | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_Ctx` | Ctx | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_Desc` | Desc | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_In` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_Out` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Init_State` | State | `Model\MD_Model_Lib.f90` | No | - |
| `PrestressProperties` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `PrestressResults` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `SubstructureProperties` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `SubstructureResults` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `UF_ModelDef` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `UF_ModelVarContext` | N/A | `Model\MD_Model_Lib.f90` | No | - |
| `MD_Model_Desc` | Desc | `Model\MD_Model_Mgr.f90` | No | - |
| `MD_Model_Domain` | N/A | `Model\MD_Model_Mgr.f90` | No | - |
| `MD_Model_GetSummary_Arg` | N/A | `Model\MD_Model_Mgr.f90` | No | - |
| `NormalDefinition` | N/A | `Model\MD_ModelCoordSys.f90` | No | - |
| `NormalPropsManager` | N/A | `Model\MD_ModelCoordSys.f90` | No | - |
| `OrientPropsManager` | N/A | `Model\MD_ModelCoordSys.f90` | No | - |
| `TransformPropsMgr` | N/A | `Model\MD_ModelCoordSys.f90` | No | - |
| `DistributionDataEntry` | N/A | `Model\MD_ModelData.f90` | No | - |
| `DistributionPropertiesManager` | N/A | `Model\MD_ModelData.f90` | No | - |
| `FieldDataEntry` | N/A | `Model\MD_ModelData.f90` | No | - |
| `ParameterEntry` | N/A | `Model\MD_ModelData.f90` | No | - |
| `TableEntry` | N/A | `Model\MD_ModelData.f90` | No | - |
| `TablePropertiesManager` | N/A | `Model\MD_ModelData.f90` | No | - |

### Output

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Output_Domain` | N/A | `Output\MD_Out_API.f90` | No | - |
| `MD_Output_GetRequest_Arg` | N/A | `Output\MD_Out_API.f90` | No | - |
| `MD_Output_GetRequestByName_Arg` | N/A | `Output\MD_Out_API.f90` | No | - |
| `MD_Output_GetSummary_Arg` | N/A | `Output\MD_Out_API.f90` | No | - |
| `MD_Output_State` | State | `Output\MD_Out_API.f90` | No | - |
| `MD_OutputRequest_Desc` | Desc | `Output\MD_Out_API.f90` | No | - |
| `OutputAlgo` | N/A | `Output\MD_Out_API.f90` | No | - |
| `ElsetHistScalarEntry` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `FldOutReq` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `HistNodeSetRegionLink` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `HistOutReq` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `HistRegionCatalogEntry` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `NodeSetHistMetaRecord` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `OutField` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `OutFrame` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `OutVarDesc` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `RT_HistReq` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `RT_HistVarDesc` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `RT_StepHistCfg` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `StepHistConfigEntry` | N/A | `Output\MD_Out_Ctx.f90` | No | - |
| `MD_FieldOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_HistOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_BuildFieldOutTasks_Ctx_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_BuildHistOutTasks_Ctx_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_FieldOutOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_HistOutOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_ShouldOutput_Ctx_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_ShouldOutputIn_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_ShouldOutputOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_State` | State | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_StepCtx_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_OutCtrl_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_OutFrequency_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Output_Algo` | Algo | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Output_Ctx` | Ctx | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Output_Desc` | Desc | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Output_State` | State | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_OutputRequest_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_OutputVariable_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_OutVariable_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_RestartOut_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_StepOut_Binding_Type` | N/A | `Output\MD_Out_Def.f90` | Yes | - |
| `MD_Out_AddField_Algo` | Algo | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddField_Ctx` | Ctx | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddField_Desc` | Desc | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddField_In` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddField_Out` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddField_State` | State | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddHistory_In` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_AddHistory_Out` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_ShouldOutput_In` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `MD_Out_ShouldOutput_Out` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `UF_FieldOutputDef` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `UF_HistoryOutputDef` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `UF_HistoryOutputState` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `UF_OutputManager` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `UF_OutputVar` | N/A | `Output\MD_Out_Lib.f90` | No | - |
| `ElementSetType` | N/A | `Output\MD_Out_Mapper.f90` | No | - |
| `NodeSetType` | N/A | `Output\MD_Out_Mapper.f90` | No | - |
| `MD_BiologicalFieldInitDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_BiologicalFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_ChemicalFieldInitDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_ChemicalFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_ElectroMagFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_Field_Mgr` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FieldCpl` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FieldDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FieldInitDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FieldManager` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldCplDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldEq` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldStaHist` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldStaMgr` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldStaSnap` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FldSysType` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_FluidFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_GravitationalFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_QuantumFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_StructFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_ThermalFieldInitDesc` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_ThermalFld` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_UniFldMgr` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_UniFldSta` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_UniFldSys` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `StructMatRes` | N/A | `Output\MD_Out_UniFld.f90` | No | - |
| `MD_BoundaryCondition` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `MD_InitialCondition` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `MD_Load` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `MD_OutReq` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `MD_PostProcessor` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `MD_ShapeFuncResult` | N/A | `Output\MD_Out_UniFldOps.f90` | No | - |
| `OutVarRegistry` | N/A | `Output\MD_Out_VarReg.f90` | No | - |

### Part

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_Elem_Desc` | Desc | `Part\MD_Geom_Def.f90` | Yes | - |
| `MD_Geom_Ctx` | Ctx | `Part\MD_Geom_Def.f90` | Yes | - |
| `MD_Node_Desc` | Desc | `Part\MD_Geom_Def.f90` | Yes | - |
| `MD_Part_Desc` | Desc | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_Part_Domain` | N/A | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_Part_Get_Arg` | N/A | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_Part_GetByName_Arg` | N/A | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_Part_State` | State | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_PartEntry` | N/A | `Part\MD_Part_Def.f90` | Yes | - |
| `MD_SetBoundingBox` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetDistanceResult` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetExportFormat` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetGenerationCriteria` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetOverlapResult` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetStatistics` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SetSymmetryResult` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `MD_SurfFacet` | N/A | `Part\MD_Sets_Ctx.f90` | No | - |
| `UF_ElemSet` | N/A | `Part\MD_Sets_Mgr.f90` | No | - |
| `UF_NodeSet` | N/A | `Part\MD_Sets_Mgr.f90` | No | - |
| `UF_Surface` | N/A | `Part\MD_Sets_Mgr.f90` | No | - |
| `UF_SurfaceFacet` | N/A | `Part\MD_Sets_Mgr.f90` | No | - |

### Section

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `ModelOverrideEntry` | N/A | `Section\MD_Sect_Compat.f90` | No | - |
| `ModelOverrideRegistry` | N/A | `Section\MD_Sect_Compat.f90` | No | - |
| `MD_Sect_Add_Arg` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_Base_Desc` | Desc | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_Get_Arg` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_GetByName_Arg` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_GetSummary_Arg` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_Registry` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Sect_Validate_Arg` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_SectDesc` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Section_Ctx` | Ctx | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Section_Desc` | Desc | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Section_Domain` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `MD_Section_State` | State | `Section\MD_Sect_Def.f90` | Yes | - |
| `SectionAlgo` | N/A | `Section\MD_Sect_Def.f90` | Yes | - |
| `UF_SectionDBType` | N/A | `Section\MD_Sect_Lib.f90` | No | - |
| `UF_SectionDef` | N/A | `Section\MD_Sect_Lib.f90` | No | - |
| `MatDesc` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `MD_SectionCompLayer` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `MD_SectionCompositeProperties` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `MD_SectionOrientation` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `MD_SectionProps` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `SectTypeEntry` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `UF_ELEM_SECTION_MAP` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `UF_SECTION_DATA` | N/A | `Section\MD_Sect_Mgr.f90` | No | - |
| `PtMassManager` | N/A | `Section\MD_Sect_PropMass.f90` | No | - |
| `NonStructMassManager` | N/A | `Section\MD_Sect_PropNonStructMass.f90` | No | - |
| `PtMassAltManager` | N/A | `Section\MD_Sect_PropPtMass.f90` | No | - |
| `RotInertiaManager` | N/A | `Section\MD_Sect_PropRotInertia.f90` | No | - |

### WriteBack

| TYPE Name | Category | File | In_Def | SubDomain |
| :--- | :---: | :--- | :---: | :--- |
| `MD_WriteBack_Entry` | N/A | `WriteBack\MD_WB_Def.f90` | Yes | - |
| `MD_WriteBack_Target` | N/A | `WriteBack\MD_WB_Def.f90` | Yes | - |
| `MD_WriteBack_AddEntry_Arg` | N/A | `WriteBack\MD_WB_Domain.f90` | No | - |
| `MD_WriteBack_GetSummary_Arg` | N/A | `WriteBack\MD_WB_Domain.f90` | No | - |
| `MD_WriteBack_WhiteListDomain` | N/A | `WriteBack\MD_WB_Domain.f90` | No | - |

---

## _Def.f90 Coverage Analysis

### _Def.f90 Files Found

- `Analysis\Amplitude\MD_Amp_Def.f90`
- `Analysis\Coupling\MD_Cpl_Def.f90`
- `Analysis\Solver\MD_Solv_Def.f90`
- `Analysis\Step\MD_Step_Def.f90`
- `Boundary\MD_BC_Def.f90`
- `Boundary\MD_Load_Def.f90`
- `Constraint\MD_Constr_Def.f90`
- `Field\MD_Field_Def.f90`
- `Interaction\MD_Int_Def.f90`
- `KeyWord\MD_KeyWordParser_Def.f90`
- `KeyWord\MD_KW_Def.f90`
- `Material\Contract\MD_Mat_Def.f90`
- `Material\Domain\MD_MatDomain_Def.f90`
- `Material\Shared\MD_MatEval_Def.f90`
- `Mesh\Element\MD_Elem_Def.f90`
- `Mesh\MD_Elem_Def.f90`
- `Mesh\MD_Mesh_Def.f90`
- `Model\MD_Base_Def.f90`
- `Model\MD_Kinematics_Def.f90`
- `Model\MD_Model_Def.f90`
- `Output\MD_Out_Def.f90`
- `Part\MD_Geom_Def.f90`
- `Part\MD_Part_Def.f90`
- `Section\MD_Sect_Def.f90`
- `WriteBack\MD_WB_Def.f90`

### Four-Type TYPEs NOT in _Def (Migration Candidates)

| Domain | TYPE Name | Category | Current File | Note |
| :--- | :--- | :---: | :--- | :--- |
| (Root) | `MD_Analysis_Group_DESC` | Desc | `MD_Analysis_GroupModule.f90` | Migrate to _Def |
| Analysis | `MD_Amplitude_Eval_Algo` | Algo | `Analysis\Amplitude\MD_Amp_UF.f90` | Migrate to _Def |
| Analysis | `MD_Amplitude_Eval_Ctx` | Ctx | `Analysis\Amplitude\MD_Amp_UF.f90` | Migrate to _Def |
| Analysis | `MD_Amplitude_Eval_Desc` | Desc | `Analysis\Amplitude\MD_Amp_UF.f90` | Migrate to _Def |
| Analysis | `MD_Amplitude_Eval_State` | State | `Analysis\Amplitude\MD_Amp_UF.f90` | Migrate to _Def |
| Analysis | `MD_Step_Desc` | Desc | `Analysis\Step\MD_Step_Mgr.f90` | Migrate to _Def |
| Assembly | `MD_Asm_Algo` | Algo | `Assembly\MD_Asm_Mgr.f90` | Migrate to _Def |
| Assembly | `MD_Asm_Ctx` | Ctx | `Assembly\MD_Asm_Mgr.f90` | Migrate to _Def |
| Assembly | `MD_Asm_State` | State | `Assembly\MD_Asm_Mgr.f90` | Migrate to _Def |
| Assembly | `MD_Instance_Desc` | Desc | `Assembly\MD_Asm_Mgr.f90` | Migrate to _Def |
| Boundary | `MD_BC_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_BC_State` | State | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_IC_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_LBC_Algo` | Algo | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_LBC_Ctx` | Ctx | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_Load_Desc` | Desc | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_Load_State` | State | `Boundary\MD_LBC_Domain.f90` | Migrate to _Def |
| Boundary | `MD_LoadBC_Algo` | Algo | `Boundary\MD_LBC_Container.f90` | Migrate to _Def |
| Boundary | `MD_LoadBC_Ctx` | Ctx | `Boundary\MD_LBC_Container.f90` | Migrate to _Def |
| Boundary | `MD_LoadBC_Desc` | Desc | `Boundary\MD_LBC_Container.f90` | Migrate to _Def |
| Boundary | `MD_LoadBC_State` | State | `Boundary\MD_LBC_Container.f90` | Migrate to _Def |
| Constraint | `MD_Constr_Algo` | Algo | `Constraint\MD_Constr_Mgr.f90` | Migrate to _Def |
| Constraint | `MD_Constr_Ctx` | Ctx | `Constraint\MD_Constr_Mgr.f90` | Migrate to _Def |
| KeyWord | `KW_CoverageAudit_Desc` | Desc | `KeyWord\MD_KW.f90` | Migrate to _Def |
| KeyWord | `KW_Find_Desc` | Desc | `KeyWord\MD_KW.f90` | Migrate to _Def |
| KeyWord | `KW_Find_State` | State | `KeyWord\MD_KW.f90` | Migrate to _Def |
| KeyWord | `KW_Reg_Desc` | Desc | `KeyWord\MD_KW.f90` | Migrate to _Def |
| KeyWord | `KW_Registry_Ctx` | Ctx | `KeyWord\MD_KW.f90` | Migrate to _Def |
| Material | `Biot_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `CDP_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `CDP_State` | State | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `CompDmg_State` | State | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `CreepDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | Migrate to _Def |
| Material | `CreepModels_Desc` | Desc | `Material\Shared\MD_MAT_CREEP_CORE.f90` | Migrate to _Def |
| Material | `CrushFoam_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `CZM_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `DuctileDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | Migrate to _Def |
| Material | `FiberReinfComp_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | Migrate to _Def |
| Material | `HolzapfelOgden_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `HypAB_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `HypStd_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `JointedRock_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `LamComp_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | Migrate to _Def |
| Material | `Lamina_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `Marlow_Ext_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `MCC_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `MCC_State` | State | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `MD_Mat_Ctx` | Ctx | `Material\Base\MD_Mat_BaseDef.f90` | Migrate to _Def |
| Material | `MD_Mat_Desc` | Desc | `Material\Base\MD_Mat_BaseDef.f90` | Migrate to _Def |
| Material | `MD_Mat_PH_UMAT_Algo` | Algo | `Material\Bridge\MD_Mat_Brg.f90` | Migrate to _Def |
| Material | `MD_Mat_PH_UMAT_Ctx` | Ctx | `Material\Bridge\MD_Mat_Brg.f90` | Migrate to _Def |
| Material | `MD_Mat_PH_UMAT_Desc` | Desc | `Material\Bridge\MD_Mat_Brg.f90` | Migrate to _Def |
| Material | `MD_Mat_PH_UMAT_State` | State | `Material\Bridge\MD_Mat_Brg.f90` | Migrate to _Def |
| Material | `MD_Mat_State` | State | `Material\Base\MD_Mat_BaseDef.f90` | Migrate to _Def |
| Material | `Mullins_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `Mullins_State` | State | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `Multiscale_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `NLVisc_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Material | `PlastModels_Desc` | Desc | `Material\Registry\MD_MatPLM_Reg.f90` | Migrate to _Def |
| Material | `PolymerCure_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Material | `PronyVisc_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Material | `RateFoam_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `RateFoam_Ext_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Material | `SMA_Desc` | Desc | `Material\Shared\MD_MAT_COMPOSITE_CORE.f90` | Migrate to _Def |
| Material | `SmearedCrack_Desc` | Desc | `Material\Shared\MD_MAT_GEOMAT_CORE.f90` | Migrate to _Def |
| Material | `ThermalDmg_Desc` | Desc | `Material\Shared\MD_MAT_DAMAGE_CORE.f90` | Migrate to _Def |
| Material | `UEXPAN_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | Migrate to _Def |
| Material | `UHARD_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | Migrate to _Def |
| Material | `USDFLD_Desc` | Desc | `Material\Shared\MD_MAT_USER_CORE.f90` | Migrate to _Def |
| Material | `VDW_Ext_Desc` | Desc | `Material\Shared\MD_MAT_HYPERELASTIC_CORE.f90` | Migrate to _Def |
| Material | `Viscoplast_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Material | `ViscoplDmg_Desc` | Desc | `Material\Shared\MD_MAT_VISCOSITY_CORE.f90` | Migrate to _Def |
| Mesh | `MD_ElemDomain_Algo` | Algo | `Mesh\Element\MD_Elem_Domain.f90` | Migrate to _Def |
| Model | `Context_Model_State` | State | `Model\MD_Model_Lib.f90` | Migrate to _Def |
| Model | `MD_Model_Desc` | Desc | `Model\MD_Model_Mgr.f90` | Migrate to _Def |
| Model | `MD_Model_Desc` | Desc | `Model\MD_Model_Domain.f90` | Migrate to _Def |
| Model | `MD_Model_Init_Algo` | Algo | `Model\MD_Model_Lib.f90` | Migrate to _Def |
| Model | `MD_Model_Init_Ctx` | Ctx | `Model\MD_Model_Lib.f90` | Migrate to _Def |
| Model | `MD_Model_Init_Desc` | Desc | `Model\MD_Model_Lib.f90` | Migrate to _Def |
| Model | `MD_Model_Init_State` | State | `Model\MD_Model_Lib.f90` | Migrate to _Def |
| Model | `MD_ModelBuilder_Build_Algo` | Algo | `Model\MD_Model_Builder.f90` | Migrate to _Def |
| Model | `MD_ModelBuilder_Build_Ctx` | Ctx | `Model\MD_Model_Builder.f90` | Migrate to _Def |
| Model | `MD_ModelBuilder_Build_Desc` | Desc | `Model\MD_Model_Builder.f90` | Migrate to _Def |
| Model | `MD_ModelBuilder_Build_State` | State | `Model\MD_Model_Builder.f90` | Migrate to _Def |
| Output | `MD_Out_AddField_Algo` | Algo | `Output\MD_Out_Lib.f90` | Migrate to _Def |
| Output | `MD_Out_AddField_Ctx` | Ctx | `Output\MD_Out_Lib.f90` | Migrate to _Def |
| Output | `MD_Out_AddField_Desc` | Desc | `Output\MD_Out_Lib.f90` | Migrate to _Def |
| Output | `MD_Out_AddField_State` | State | `Output\MD_Out_Lib.f90` | Migrate to _Def |
| Output | `MD_Output_State` | State | `Output\MD_Out_API.f90` | Migrate to _Def |
| Output | `MD_OutputRequest_Desc` | Desc | `Output\MD_Out_API.f90` | Migrate to _Def |

### Domains Without _Def.f90

- **(Root)**: No _Def.f90 — Layer-level utility files (MD_L3_Layer, MD_Base_HashSetUtil), not a domain. No _Def needed.
- **Assembly**: No _Def.f90 — **By design**: CONTRACT.md explicitly records `~~MD_Asm_Def.f90~~` was deleted (duplicate of MD_Asm_Mgr). Four types (Desc/State/Algo/Ctx) consolidated in `MD_Asm_Mgr.f90`.
- **Bridge**: No _Def.f90 — **By design**: Infrastructure domain per CONTRACT.md §2. No substantive four-type definitions; TYPEs are Arg bundles for cross-layer mapping.

### Conclusion: _Def.f90 Skeleton Creation

**No new _Def.f90 files need to be created.** All domains that require four-type definitions already have _Def.f90 files. The three domains without _Def.f90 have explicit design justifications in their CONTRACT.md documents.

