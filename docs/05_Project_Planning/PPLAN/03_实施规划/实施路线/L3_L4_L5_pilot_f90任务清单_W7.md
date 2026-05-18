# L3/L4/L5 — pilot 任务清单（W7 筛选）

> **生成日期**：2026-04-30  
> **来源**：[`UFC/tools/gen_l3l4l5_f90_inventory.py`](../../../../tools/gen_l3l4l5_f90_inventory.py)  
> **总清单**：[`L3_L4_L5_pilot_f90任务清单.md`](L3_L4_L5_pilot_f90任务清单.md) — **Txxxx 与总清单一致**

> **波次**：W7（内置前缀；W7/W8 与邻波重叠边界以合同及 EXEC §5–§6 为准） **H7 提示**：`ufc_core/L2_NM/Solver/AI/` 不在本仓库 866 总清单（仅 L3/L4/L5）内；DiffPhys / 伴随相关文件请单独列 Issue 跟踪。

## 本波次文件（勾选覆盖）

- [ ] **T0001** `L3_MD/Analysis/Amplitude/MD_Amp_Def.f90` （约 12 个子程序）
- [ ] **T0002** `L3_MD/Analysis/Amplitude/MD_Amp_Idx.f90` （约 2 个子程序）
- [ ] **T0003** `L3_MD/Analysis/Amplitude/MD_Amp_Mgr.f90` （约 6 个子程序）
- [ ] **T0004** `L3_MD/Analysis/Amplitude/MD_Amp_UF.f90` （约 22 个子程序）
- [ ] **T0005** `L3_MD/Analysis/Coupling/MD_Cpl_Core.f90` （约 7 个子程序）
- [ ] **T0006** `L3_MD/Analysis/Coupling/MD_Cpl_Def.f90` （约 0 个子程序）
- [ ] **T0009** `L3_MD/Analysis/Solver/MD_Solv_Def.f90` （约 3 个子程序）
- [ ] **T0010** `L3_MD/Analysis/Solver/MD_Solv_Mgr.f90` （约 14 个子程序）
- [ ] **T0011** `L3_MD/Analysis/Solver/MD_Solv_Sync.f90` （约 2 个子程序）
- [ ] **T0012** `L3_MD/Analysis/Step/MD_Step_Def.f90` （约 0 个子程序）
- [ ] **T0014** `L3_MD/Analysis/Step/MD_Step_Mgr.f90` （约 19 个子程序）
- [ ] **T0015** `L3_MD/Analysis/Step/MD_Step_Proc.f90` （约 23 个子程序）
- [ ] **T0016** `L3_MD/Analysis/Step/MD_Step_Sync.f90` （约 4 个子程序；含原 `MD_Step_LegacyLoad_Sync` 载荷扁平化）
- [ ] **T0017** `L3_MD/Assembly/MD_Asm_Inst.f90` （约 10 个子程序）
- [ ] **T0018** `L3_MD/Assembly/MD_Asm_Mgr.f90` （约 36 个子程序）
- [ ] **T0019** `L3_MD/Assembly/MD_Asm_Sync.f90` （约 22 个子程序）
- [ ] **T0052** `L3_MD/Constraint/MD_Constr_Brg.f90` （约 7 个子程序）
- [ ] **T0053** `L3_MD/Constraint/MD_Constr_Def.f90` （约 21 个子程序）
- [ ] **T0054** `L3_MD/Constraint/MD_Constr_Mgr.f90` （约 17 个子程序）
- [ ] **T0055** `L3_MD/Constraint/MD_Constr_Prop.f90` （约 4 个子程序）
- [ ] **T0056** `L3_MD/Constraint/MD_Constr_Sync.f90` （约 1 个子程序）
- [ ] **T0057** `L3_MD/Field/MD_Field_Def.f90` （约 0 个子程序）
- [ ] **T0058** `L3_MD/Field/MD_Field_Mgr.f90` （约 27 个子程序）
- [ ] **T0438** `L4_PH/Constraint/PH_ConstrMPC_Brg.f90` （约 13 个子程序）
- [ ] **T0439** `L4_PH/Constraint/PH_ConstrMPC_Def.f90` （约 0 个子程序）
- [ ] **T0440** `L4_PH/Constraint/PH_ConstrPeriod_Brg.f90` （约 6 个子程序）
- [ ] **T0441** `L4_PH/Constraint/PH_ConstrPeriod_Def.f90` （约 0 个子程序）
- [ ] **T0442** `L4_PH/Constraint/PH_ConstrTie_Brg.f90` （约 10 个子程序）
- [ ] **T0443** `L4_PH/Constraint/PH_ConstrTie_Def.f90` （约 0 个子程序）
- [ ] **T0444** `L4_PH/Constraint/PH_Constr_Core.f90` （约 9 个子程序）
- [ ] **T0445** `L4_PH/Constraint/PH_Constr_Def.f90` （约 8 个子程序）
- [ ] **T0446** `L4_PH/Constraint/PH_Constr_Domain.f90` （约 18 个子程序）
- [ ] **T0447** `L4_PH/Constraint/PH_Constr_MPC.f90` （约 6 个子程序）
- [ ] **T0448** `L4_PH/Constraint/PH_Constr_Period.f90` （约 4 个子程序）
- [ ] **T0449** `L4_PH/Constraint/PH_Constr_Tie.f90` （约 6 个子程序）
- [ ] **T0548** `L4_PH/Element/PH_Elem_dRdTheta.f90` （约 2 个子程序）
- [ ] **T0682** `L4_PH/Field/PH_Field_ComputeConc.f90` （约 6 个子程序）
- [ ] **T0683** `L4_PH/Field/PH_Field_ComputePore.f90` （约 7 个子程序）
- [ ] **T0684** `L4_PH/Field/PH_Field_ComputeTemp.f90` （约 8 个子程序）
- [ ] **T0685** `L4_PH/Field/PH_Field_Cpl.f90` （约 9 个子程序）
- [ ] **T0686** `L4_PH/Field/PH_Field_Def.f90` （约 0 个子程序）
- [ ] **T0687** `L4_PH/Field/PH_Field_GaussQuadrature.f90` （约 5 个子程序）
- [ ] **T0688** `L4_PH/Field/PH_Field_Interpolate.f90` （约 9 个子程序）
- [ ] **T0689** `L4_PH/Field/PH_Field_Ops.f90` （约 9 个子程序）
- [ ] **T0690** `L4_PH/Field/PH_Field_ShapeFunc.f90` （约 5 个子程序）
- [ ] **T0757** `L5_RT/Assembly/RT_Asm_Brg.f90` （约 8 个子程序）
- [ ] **T0758** `L5_RT/Assembly/RT_Asm_Color.f90` （约 2 个子程序）
- [ ] **T0759** `L5_RT/Assembly/RT_Asm_Core.f90` （约 16 个子程序）
- [ ] **T0760** `L5_RT/Assembly/RT_Asm_Def.f90` （约 18 个子程序）
- [ ] **T0761** `L5_RT/Assembly/RT_Asm_DofMap.f90` （约 0 个子程序）
- [ ] **T0762** `L5_RT/Assembly/RT_Asm_Domain.f90` （约 7 个子程序）
- [ ] **T0763** `L5_RT/Assembly/RT_Asm_Execute.f90` （约 0 个子程序）
- [ ] **T0764** `L5_RT/Assembly/RT_Asm_Global.f90` （约 7 个子程序）
- [ ] **T0765** `L5_RT/Assembly/RT_Asm_Impl.f90` （约 8 个子程序）
- [ ] **T0766** `L5_RT/Assembly/RT_Asm_MassDamp.f90` （约 3 个子程序）
- [ ] **T0767** `L5_RT/Assembly/RT_Asm_Mgr.f90` （约 28 个子程序）
- [ ] **T0768** `L5_RT/Assembly/RT_Asm_NLGeomDispatch.f90` （约 4 个子程序）
- [ ] **T0769** `L5_RT/Assembly/RT_Asm_NLGeomEval.f90` （约 2 个子程序）
- [ ] **T0770** `L5_RT/Assembly/RT_Asm_Proc.f90` （约 8 个子程序）
- [ ] **T0771** `L5_RT/Assembly/RT_Asm_ShapeBeam.f90` （约 1 个子程序）
- [ ] **T0772** `L5_RT/Assembly/RT_Asm_ShapeMech2D.f90` （约 2 个子程序）
- [ ] **T0773** `L5_RT/Assembly/RT_Asm_ShapeMechanicalField.f90` （约 1 个子程序）
- [ ] **T0774** `L5_RT/Assembly/RT_Asm_ShapeMembrane.f90` （约 1 个子程序）
- [ ] **T0775** `L5_RT/Assembly/RT_Asm_ShapeScalarField.f90` （约 1 个子程序）
- [ ] **T0776** `L5_RT/Assembly/RT_Asm_ShapeShell.f90` （约 1 个子程序）
- [ ] **T0777** `L5_RT/Assembly/RT_Asm_Solv.f90` （约 31 个子程序）
- [ ] **T0778** `L5_RT/Assembly/RT_Asm_Util.f90` （约 6 个子程序）
- [ ] **T0779** `L5_RT/Assembly/RT_ElemWS_Default.f90` （约 2 个子程序）
- [ ] **T0834** `L5_RT/Solver/Coupling/RT_MF_Brg.f90` （约 2 个子程序）
- [ ] **T0835** `L5_RT/Solver/Coupling/RT_MF_Coordinator.f90` （约 13 个子程序）
- [ ] **T0836** `L5_RT/Solver/Coupling/RT_MF_Def.f90` （约 5 个子程序）
- [ ] **T0837** `L5_RT/Solver/RT_AI_ConvPredictAlgo.f90` （约 4 个子程序）
- [ ] **T0838** `L5_RT/Solver/RT_Asm_DofMapUtils.f90` （约 1 个子程序）
- [ ] **T0839** `L5_RT/Solver/RT_Solv_ABAQUSReg.f90` （约 8 个子程序）
- [ ] **T0840** `L5_RT/Solver/RT_Solv_Brg.f90` （约 0 个子程序）
- [ ] **T0841** `L5_RT/Solver/RT_Solv_ContResidual.f90` （约 3 个子程序）
- [ ] **T0842** `L5_RT/Solver/RT_Solv_Core.f90` （约 7 个子程序）
- [ ] **T0843** `L5_RT/Solver/RT_Solv_CoreMemPool.f90` （约 10 个子程序）
- [ ] **T0844** `L5_RT/Solver/RT_Solv_Def.f90` （约 13 个子程序）
- [ ] **T0845** `L5_RT/Solver/RT_Solv_Impl.f90` （约 7 个子程序）
- [ ] **T0846** `L5_RT/Solver/RT_Solv_Lin.f90` （约 0 个子程序）
- [ ] **T0847** `L5_RT/Solver/RT_Solv_Mgr.f90` （约 0 个子程序）
- [ ] **T0848** `L5_RT/Solver/RT_Solv_Nonlin.f90` （约 7 个子程序）
- [ ] **T0849** `L5_RT/Solver/RT_Solv_Proc.f90` （约 5 个子程序）
- [ ] **T0850** `L5_RT/Solver/RT_Solv_Sparse.f90` （约 0 个子程序）
- [ ] **T0851** `L5_RT/Solver/RT_Solv_TimeInt.f90` （约 0 个子程序）
- [ ] **T0852** `L5_RT/StepDriver/RT_AI_StepCtrAlgo.f90` （约 4 个子程序）
- [ ] **T0853** `L5_RT/StepDriver/RT_Step_Brg.f90` （约 1 个子程序）
- [ ] **T0854** `L5_RT/StepDriver/RT_Step_Core.f90` （约 15 个子程序）
- [ ] **T0855** `L5_RT/StepDriver/RT_Step_Ctx.f90` （约 5 个子程序）
- [ ] **T0856** `L5_RT/StepDriver/RT_Step_Def.f90` （约 1 个子程序）
- [ ] **T0857** `L5_RT/StepDriver/RT_Step_Exec.f90` （约 17 个子程序）
- [ ] **T0858** `L5_RT/StepDriver/RT_Step_Impl.f90` （约 7 个子程序）
- [ ] **T0859** `L5_RT/StepDriver/RT_Step_NR_Core.f90` （约 7 个子程序）
- [ ] **T0860** `L5_RT/StepDriver/RT_Step_WS.f90` （约 2 个子程序）

**合计**：96 个 `.f90`，约 700 个子程序。
