# 层级索引：`L5_RT`（Registry）

- **`.f90` 文件数**: 137

> **命名 / 布局**：`generated/<层>/…/<stem>.md` — **目录树镜像** `ufc_core/<层>/…/*.f90`（仅扩展名改为 `.md`）；按 **域桶**（层下首段目录名）分组索引。**stem**=源码文件名；三段式/四段式见各篇首节。**源码路径**见各篇 `Source`。权威约定见 [CONVENTIONS.md](../CONVENTIONS.md) §0、[UFC_命名与数据结构规范.md](../../UFC_命名与数据结构规范.md) §3。

## 域级 `Assembly`（`ufc_core/L5_RT/Assembly/…` 一级子目录）

- [RT_Asm_Brg.md](Assembly/RT_Asm_Brg.md)
- [RT_Asm_Color.md](Assembly/RT_Asm_Color.md)
- [RT_Asm_Core.md](Assembly/RT_Asm_Core.md)
- [RT_Asm_Def.md](Assembly/RT_Asm_Def.md)
- [RT_Asm_DofMap.md](Assembly/RT_Asm_DofMap.md)
- [RT_Asm_Domain.md](Assembly/RT_Asm_Domain.md)
- [RT_Asm_Execute.md](Assembly/RT_Asm_Execute.md)
- [RT_Asm_Global.md](Assembly/RT_Asm_Global.md)
- [RT_Asm_Impl.md](Assembly/RT_Asm_Impl.md)
- [RT_Asm_MassDamp.md](Assembly/RT_Asm_MassDamp.md)
- [RT_Asm_Mgr.md](Assembly/RT_Asm_Mgr.md)
- [RT_Asm_NLGeomDispatch.md](Assembly/RT_Asm_NLGeomDispatch.md)
- [RT_Asm_NLGeomEval.md](Assembly/RT_Asm_NLGeomEval.md)
- [RT_Asm_Proc.md](Assembly/RT_Asm_Proc.md)
- [RT_Asm_ShapeBeam.md](Assembly/RT_Asm_ShapeBeam.md)
- [RT_Asm_ShapeMech2D.md](Assembly/RT_Asm_ShapeMech2D.md)
- [RT_Asm_ShapeMechanicalField.md](Assembly/RT_Asm_ShapeMechanicalField.md)
- [RT_Asm_ShapeMembrane.md](Assembly/RT_Asm_ShapeMembrane.md)
- [RT_Asm_ShapeScalarField.md](Assembly/RT_Asm_ShapeScalarField.md)
- [RT_Asm_ShapeShell.md](Assembly/RT_Asm_ShapeShell.md)
- [RT_Asm_Solv.md](Assembly/RT_Asm_Solv.md)
- [RT_Asm_Util.md](Assembly/RT_Asm_Util.md)
- [RT_ElemWS_Default.md](Assembly/RT_ElemWS_Default.md)

## 域级 `Bridge`（`ufc_core/L5_RT/Bridge/…` 一级子目录）

- [RT_Brg_Def.md](Bridge/RT_Brg_Def.md)
- [RT_Brg_Mgr.md](Bridge/RT_Brg_Mgr.md)
- [RT_Shared_Def.md](Bridge/Shared/RT_Shared_Def.md)

## 域级 `Contact`（`ufc_core/L5_RT/Contact/…` 一级子目录）

- [RT_Cont_AugLagSolv.md](Contact/RT_Cont_AugLagSolv.md)
- [RT_Cont_Brg.md](Contact/RT_Cont_Brg.md)
- [RT_Cont_Core.md](Contact/RT_Cont_Core.md)
- [RT_Cont_Ctrl.md](Contact/RT_Cont_Ctrl.md)
- [RT_Cont_Def.md](Contact/RT_Cont_Def.md)
- [RT_Cont_Expl.md](Contact/RT_Cont_Expl.md)
- [RT_Cont_Search.md](Contact/RT_Cont_Search.md)
- [RT_Cont_Solv.md](Contact/RT_Cont_Solv.md)

## 域级 `Element`（`ufc_core/L5_RT/Element/…` 一级子目录）

- [RT_Mesh_Def.md](Element/Mesh/RT_Mesh_Def.md)
- [RT_Mesh_Impl.md](Element/Mesh/RT_Mesh_Impl.md)
- [RT_Mesh_Proc.md](Element/Mesh/RT_Mesh_Proc.md)
- [RT_Mesh_Sys.md](Element/Mesh/RT_Mesh_Sys.md)
- [RT_ElemDispatch_Brg.md](Element/RT_ElemDispatch_Brg.md)
- [RT_ElemWB_Brg.md](Element/RT_ElemWB_Brg.md)
- [RT_Elem_AsmProc.md](Element/RT_Elem_AsmProc.md)
- [RT_Elem_ComputeProc.md](Element/RT_Elem_ComputeProc.md)
- [RT_Elem_Core.md](Element/RT_Elem_Core.md)
- [RT_Elem_Def.md](Element/RT_Elem_Def.md)
- [RT_Elem_Dispatcher.md](Element/RT_Elem_Dispatcher.md)
- [RT_Elem_KernelProc.md](Element/RT_Elem_KernelProc.md)
- [RT_Elem_Proc.md](Element/RT_Elem_Proc.md)
- [RT_Elem_Sect.md](Element/RT_Elem_Sect.md)
- [RT_Elem_ThermalMechCpl.md](Element/RT_Elem_ThermalMechCpl.md)
- [RT_Elem_UEL.md](Element/RT_Elem_UEL.md)

## 域级 `LoadBC`（`ufc_core/L5_RT/LoadBC/…` 一级子目录）

- [RT_BC_Brg.md](LoadBC/RT_BC_Brg.md)
- [RT_BC_Def.md](LoadBC/RT_BC_Def.md)
- [RT_BC_Impl.md](LoadBC/RT_BC_Impl.md)
- [RT_BC_Impl_Def.md](LoadBC/RT_BC_Impl_Def.md)
- [RT_BC_ReactionForce.md](LoadBC/RT_BC_ReactionForce.md)
- [RT_LoadBC_ConstApply.md](LoadBC/RT_LoadBC_ConstApply.md)
- [RT_LoadBC_Core.md](LoadBC/RT_LoadBC_Core.md)
- [RT_LoadBC_Proc.md](LoadBC/RT_LoadBC_Proc.md)
- [RT_Load_Brg.md](LoadBC/RT_Load_Brg.md)
- [RT_Load_Def.md](LoadBC/RT_Load_Def.md)
- [RT_Load_Impl.md](LoadBC/RT_Load_Impl.md)
- [RT_Load_Impl_Def.md](LoadBC/RT_Load_Impl_Def.md)

## 域级 `Logging`（`ufc_core/L5_RT/Logging/…` 一级子目录）

- [RT_Log_Brg.md](Logging/RT_Log_Brg.md)
- [RT_Log_Core.md](Logging/RT_Log_Core.md)
- [RT_Log_Def.md](Logging/RT_Log_Def.md)
- [RT_Log_Sys.md](Logging/RT_Log_Sys.md)

## 域级 `Material`（`ufc_core/L5_RT/Material/…` 一级子目录）

- [RT_Mat_Acou_Core.md](Material/RT_Mat_Acou_Core.md)
- [RT_Mat_Acou_Def.md](Material/RT_Mat_Acou_Def.md)
- [RT_Mat_Aux_Def.md](Material/RT_Mat_Aux_Def.md)
- [RT_Mat_Brg.md](Material/RT_Mat_Brg.md)
- [RT_Mat_Comp_Core.md](Material/RT_Mat_Comp_Core.md)
- [RT_Mat_Comp_Def.md](Material/RT_Mat_Comp_Def.md)
- [RT_Mat_Core.md](Material/RT_Mat_Core.md)
- [RT_Mat_Creep_Core.md](Material/RT_Mat_Creep_Core.md)
- [RT_Mat_Creep_Def.md](Material/RT_Mat_Creep_Def.md)
- [RT_Mat_Damage_Core.md](Material/RT_Mat_Damage_Core.md)
- [RT_Mat_Damage_Def.md](Material/RT_Mat_Damage_Def.md)
- [RT_Mat_Def.md](Material/RT_Mat_Def.md)
- [RT_Mat_Elas_Core.md](Material/RT_Mat_Elas_Core.md)
- [RT_Mat_Elas_Def.md](Material/RT_Mat_Elas_Def.md)
- [RT_Mat_Geo_Core.md](Material/RT_Mat_Geo_Core.md)
- [RT_Mat_Geo_Def.md](Material/RT_Mat_Geo_Def.md)
- [RT_Mat_Hyper_Core.md](Material/RT_Mat_Hyper_Core.md)
- [RT_Mat_Hyper_Def.md](Material/RT_Mat_Hyper_Def.md)
- [RT_Mat_Plast_Core.md](Material/RT_Mat_Plast_Core.md)
- [RT_Mat_Plast_Def.md](Material/RT_Mat_Plast_Def.md)
- [RT_Mat_Therm_Core.md](Material/RT_Mat_Therm_Core.md)
- [RT_Mat_Therm_Def.md](Material/RT_Mat_Therm_Def.md)
- [RT_Mat_User_Core.md](Material/RT_Mat_User_Core.md)
- [RT_Mat_User_Def.md](Material/RT_Mat_User_Def.md)
- [RT_Mat_Visco_Core.md](Material/RT_Mat_Visco_Core.md)
- [RT_Mat_Visco_Def.md](Material/RT_Mat_Visco_Def.md)

## 域级 `Output`（`ufc_core/L5_RT/Output/…` 一级子目录）

- [RT_Out_Aux_Def.md](Output/RT_Out_Aux_Def.md)
- [RT_Out_Brg.md](Output/RT_Out_Brg.md)
- [RT_Out_Core.md](Output/RT_Out_Core.md)
- [RT_Out_Def.md](Output/RT_Out_Def.md)
- [RT_Out_Impl.md](Output/RT_Out_Impl.md)
- [RT_Out_Mgr.md](Output/RT_Out_Mgr.md)
- [RT_Out_Proc.md](Output/RT_Out_Proc.md)
- [RT_Out_Restart.md](Output/RT_Out_Restart.md)
- [RT_Writer_HDF5.md](Output/RT_Writer_HDF5.md)
- [RT_Writer_ODB.md](Output/RT_Writer_ODB.md)

## 域级 `Section`（`ufc_core/L5_RT/Section/…` 一级子目录）

- [RT_Sect_Aux_Def.md](Section/RT_Sect_Aux_Def.md)
- [RT_Sect_Def.md](Section/RT_Sect_Def.md)

## 域级 `Solver`（`ufc_core/L5_RT/Solver/…` 一级子目录）

- [RT_MF_Brg.md](Solver/Coupling/RT_MF_Brg.md)
- [RT_MF_Coordinator.md](Solver/Coupling/RT_MF_Coordinator.md)
- [RT_MF_Def.md](Solver/Coupling/RT_MF_Def.md)
- [RT_AI_ConvPredictAlgo.md](Solver/RT_AI_ConvPredictAlgo.md)
- [RT_Asm_DofMapUtils.md](Solver/RT_Asm_DofMapUtils.md)
- [RT_Solv_ABAQUSReg.md](Solver/RT_Solv_ABAQUSReg.md)
- [RT_Solv_Brg.md](Solver/RT_Solv_Brg.md)
- [RT_Solv_ContResidual.md](Solver/RT_Solv_ContResidual.md)
- [RT_Solv_Core.md](Solver/RT_Solv_Core.md)
- [RT_Solv_CoreMemPool.md](Solver/RT_Solv_CoreMemPool.md)
- [RT_Solv_Def.md](Solver/RT_Solv_Def.md)
- [RT_Solv_Impl.md](Solver/RT_Solv_Impl.md)
- [RT_Solv_Lin.md](Solver/RT_Solv_Lin.md)
- [RT_Solv_Mgr.md](Solver/RT_Solv_Mgr.md)
- [RT_Solv_Nonlin.md](Solver/RT_Solv_Nonlin.md)
- [RT_Solv_Proc.md](Solver/RT_Solv_Proc.md)
- [RT_Solv_Sparse.md](Solver/RT_Solv_Sparse.md)
- [RT_Solv_TimeInt.md](Solver/RT_Solv_TimeInt.md)

## 域级 `StepDriver`（`ufc_core/L5_RT/StepDriver/…` 一级子目录）

- [RT_AI_StepCtrAlgo.md](StepDriver/RT_AI_StepCtrAlgo.md)
- [RT_Step_Brg.md](StepDriver/RT_Step_Brg.md)
- [RT_Step_Core.md](StepDriver/RT_Step_Core.md)
- [RT_Step_Def.md](StepDriver/RT_Step_Def.md)
- [RT_Step_Exec.md](StepDriver/RT_Step_Exec.md)
- [RT_Step_Impl.md](StepDriver/RT_Step_Impl.md)
- [RT_Step_NR_Core.md](StepDriver/RT_Step_NR_Core.md)
- [RT_Step_WS.md](StepDriver/RT_Step_WS.md)

## 域级 `WriteBack`（`ufc_core/L5_RT/WriteBack/…` 一级子目录）

- [RT_WB_Aux_Def.md](WriteBack/RT_WB_Aux_Def.md)
- [RT_WB_Brg.md](WriteBack/RT_WB_Brg.md)
- [RT_WB_Core.md](WriteBack/RT_WB_Core.md)
- [RT_WB_Def.md](WriteBack/RT_WB_Def.md)
- [RT_WB_Domain.md](WriteBack/RT_WB_Domain.md)
- [RT_WB_Impl.md](WriteBack/RT_WB_Impl.md)
- [RT_WB_Proc.md](WriteBack/RT_WB_Proc.md)
