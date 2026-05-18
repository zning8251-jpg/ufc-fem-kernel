# L4_PH 四类TYPE全域盘点矩阵

> 生成时间: 2026-04-28
> 扫描范围: `UFC/ufc_core/L4_PH/` 全部7域 + Adapters目录
> 分类依据: TYPE名称后缀 `_Desc/_State/_Algo/_Ctx` + 手动辨识

---

## 总览统计

| 域 | Desc数 | State数 | Algo数 | Ctx数 | 未分类数 | 总计 | _Def.f90存在 |
|:---|:------:|:-------:|:------:|:-----:|:--------:|:----:|:------------:|
| **Element** | 6 | 12 | 5 | 8 | 173 | 204 | ✅ PH_Elem_Def.f90, PH_Physical_Def.f90 |
| **Material** | 1 | 8 | 2 | 3 | 49 | 63 | ✅ PH_Mat_Def.f90 (re-export hub), PH_Mat_Elas_Def.f90, PH_MatConstit_Def.f90, PH_UMAT_Def.f90 |
| **Contact** | 10 | 12 | 10 | 11 | 34 | 77 | ✅ PH_Cont_Def.f90, PH_ThermalCont_Def.f90 |
| **LoadBC** | 4 | 3 | 1 | 4 | 41 | 53 | ✅ PH_LBC_Def.f90, PH_Load_Def.f90, PH_BC_Def.f90 |
| **Field** | 4 | 1 | 4 | 1 | 8 | 18 | ✅ PH_Field_Def.f90 |
| **Constraint** | 2 | 5 | 1 | 3 | 24 | 35 | ✅ PH_Constr_Def.f90, PH_ConstrMPC_Def.f90, PH_ConstrTie_Def.f90, PH_ConstrPeriod_Def.f90 |
| **Bridge** | 5 | 3 | 0 | 1 | 7 | 16 | ❌ 缺失 |
| **合计** | **32** | **44** | **23** | **31** | **336** | **466** | — |

> **说明**: "未分类"包含 `_Arg` 参数包、`_Type` 后缀、辅助计算结构、`_Args` 局部类型等，这些不在四型(Desc/State/Algo/Ctx)体系内。

---

## 逐域详细清单

---

### Element域 (204 TYPE)

#### _Def.f90中的TYPE (PH_Elem_Def.f90)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_ElemConfig | 未分类 | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Base_Desc | **Desc** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Base_State | **State** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Base_Algo | **Algo** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Base_Ctx | **Ctx** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_State | **State** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Desc | **Desc** | PH_Elem_Def.f90 | ✅ | 已定义 |
| PH_Elem_Algo | **Algo** | PH_Elem_Def.f90 | ✅ | 已定义 |

#### PH_Elem_Ctx.f90 (独立模块)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_ElemContext | **Ctx** | PH_Elem_Ctx.f90 | ❌ | 需迁移/保留(避免模块名冲突) |

#### Element根目录散落TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_NLGeom_State | **State** | PH_Elem_NLGeom_Core.f90 | ❌ | 需迁移 |
| PH_Elem_Reg_Entry | 未分类 | PH_Elem_Reg.f90 | ❌ | 注册表辅助 |
| PH_ElemDomain_Algo | **Algo** | PH_Elem_Domain.f90 | ❌ | 需迁移 |
| PH_Contm_Args | 未分类 | PH_Elem_Contm.f90 | ❌ | 局部Arg |
| GaussRule | 未分类 | PH_Elem_GaussInt.f90 | ❌ | 辅助 |
| ShapeFuncResult | 未分类 | PH_Elem_ShapeFunc.f90 | ❌ | 辅助 |
| PH_Nlgeom_Args | 未分类 | PH_Elem_Nlgeom.f90 | ❌ | Arg |
| PH_Mass_Params | 未分类 | PH_Elem_Mass2.f90 | ❌ | 辅助 |
| PH_Mass_Result | 未分类 | PH_Elem_Mass2.f90 | ❌ | 辅助 |
| PH_Elem_Contm_Calc3D_Arg | 未分类 | PH_ElemContm_Ops.f90 | ❌ | Arg |
| RT_DefKin | 未分类 | PH_NLGeomEval.f90 | ❌ | 运行时辅助 |
| RT_LagrCfg | 未分类 | PH_NLGeomEval.f90 | ❌ | 运行时辅助 |
| RT_RotSta | 未分类 | PH_NLGeomEval.f90 | ❌ | 运行时辅助 |
| RT_LinRes | 未分类 | PH_NLGeomEval.f90 | ❌ | 运行时辅助 |
| RT_Asm_NLGeom_Eval_Args | 未分类 | PH_NLGeomEval.f90 | ❌ | Arg |

#### Solid3D子域

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Fbar_Ctx | **Ctx** | PH_Elem_Solid3D_Fbar.f90 | ❌ | 需迁移 |
| PH_EAS_Ctx | **Ctx** | PH_Elem_Solid3D_EAS.f90 | ❌ | 需迁移 |
| PH_Elem_C3D8_FBar_Ctx | **Ctx** | PH_Elem_C3D8FBar.f90 | ❌ | 需迁移 |
| PH_Elem_C3D8_EAS_Ctx | **Ctx** | PH_Elem_C3D8EAS.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_ShapeFunc_Algo | **Algo** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_ShapeFunc_State | **State** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_Jac_Desc | **Desc** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_Jac_State | **State** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_BMatrix_State | **State** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_JacB_Desc | **Desc** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_JacB_Algo | **Algo** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_JacB_State | **State** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_Strain_State | **State** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_C3D20_Stress_Desc | **Desc** | PH_Elem_C3D20.f90 | ❌ | 需迁移 |
| PH_Elem_Sld3D_Calc_Arg | 未分类 | PH_Elem_Sld3DDefn.f90 | ❌ | Arg |
| PH_Elem_Sld3D_Args | 未分类 | C3D4/C3D6/C3D10/C3D15/C3D27 | ❌ | 局部Arg(重复定义) |
| PH_Elem_C3D8_ShapeFunc_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_Jac_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_BMatrix_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_JacB_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_Strain_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_Stress_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_StiffMatrix_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_NL_TL_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D8_NL_UL_Arg | 未分类 | PH_Elem_C3D8.f90 | ❌ | Arg |
| PH_Elem_C3D20_ShapeFunc_Arg~Strain_Arg | 未分类 | PH_Elem_C3D20.f90 | ❌ | Arg(7个) |
| PH_Elem_C3D8_EAS_*_Arg (5个) | 未分类 | PH_Elem_C3D8EAS.f90 | ❌ | Arg |

#### Shell子域 (21 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Elem_Shell_Calc_Arg | 未分类 | PH_Elem_ShellDefn.f90 | ❌ | Arg |
| MITC4Params | 未分类 | PH_Elem_ShellMITC.f90 | ❌ | 辅助 |
| PH_Elem_Shell_Args | 未分类 | DS3/DS4/DS6/DS8/S6/S9 | ❌ | 局部Arg(重复) |
| PH_Elem_S3_StiffMatrix_Arg | 未分类 | PH_Elem_S3.f90 | ❌ | Arg |
| PH_Elem_S3_IntForce_Arg | 未分类 | PH_Elem_S3.f90 | ❌ | Arg |
| PH_Elem_S3_NL_TL_Arg | 未分类 | PH_Elem_S3.f90 | ❌ | Arg |
| PH_Elem_S3_NL_UL_Arg | 未分类 | PH_Elem_S3.f90 | ❌ | Arg |
| PH_Elem_S4_*_Arg (4个) | 未分类 | PH_Elem_S4.f90 | ❌ | Arg |
| PH_Elem_S8_*_Arg (4个) | 未分类 | PH_Elem_S8.f90 | ❌ | Arg |

#### Beam子域 (25 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| B31_TL_Desc_Type | **Desc** | PH_Elem_B31TL.f90 | ❌ | 需迁移 |
| B31_TL_State_Type | **State** | PH_Elem_B31TL.f90 | ❌ | 需迁移 |
| B31_TL_Algo_Type | **Algo** | PH_Elem_B31TL.f90 | ❌ | 需迁移 |
| B31_TL_Ctx_Type | **Ctx** | PH_Elem_B31TL.f90 | ❌ | 需迁移 |
| B31_UL_Desc_Type | **Desc** | PH_Elem_B31UL.f90 | ❌ | 需迁移 |
| B31_UL_State_Type | **State** | PH_Elem_B31UL.f90 | ❌ | 需迁移 |
| B31_UL_Algo_Type | **Algo** | PH_Elem_B31UL.f90 | ❌ | 需迁移 |
| B31_UL_Ctx_Type | **Ctx** | PH_Elem_B31UL.f90 | ❌ | 需迁移 |
| B31_Stab_Desc_Type | 未分类(Desc含义) | PH_Elem_B31Stability.f90 | ❌ | 需迁移 |
| B31_Stab_State_Type | 未分类(State含义) | PH_Elem_B31Stability.f90 | ❌ | 需迁移 |
| B31_Stab_AlgoCtx_Type | 未分类(混合) | PH_Elem_B31Stability.f90 | ❌ | 需迁移 |
| B31_Plas_Mat_Desc_Type | 未分类(Desc含义) | PH_Elem_B31Plasticity.f90 | ❌ | 需迁移 |
| FiberState | 未分类 | PH_Elem_B31TP/B33P | ❌ | 局部(重复) |
| FiberState32 | 未分类 | PH_Elem_B32P.f90 | ❌ | 局部 |
| PH_Elem_Beam_Calc_Arg | 未分类 | PH_Elem_BeamDefn.f90 | ❌ | Arg |
| PH_Elem_Beam_Args | 未分类 | PH_Elem_B23.f90 | ❌ | Arg |
| PH_Elem_B31_*_Arg (4个) | 未分类 | PH_Elem_B31.f90 | ❌ | Arg |
| PH_Elem_B32_*_Arg (4个) | 未分类 | PH_Elem_B32.f90 | ❌ | Arg |

#### Solid2D子域 (~46 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Elem_Sld2D_Calc_Arg | 未分类 | PH_Elem_Sld2DDefn.f90 | ❌ | Arg |
| PH_Elem_Sld2D_Args | 未分类 | CPE3/CAX3/CAX6/CAX8/CPS3 | ❌ | 局部Arg(重复) |
| PH_Elem_CPE4_*_Arg (9个) | 未分类 | PH_Elem_CPE4.f90 | ❌ | Arg |
| PH_Elem_CPE6_*_Arg (4个) | 未分类 | PH_Elem_CPE6.f90 | ❌ | Arg |
| PH_Elem_CPE8_*_Arg (9个) | 未分类 | PH_Elem_CPE8.f90 | ❌ | Arg |
| PH_Elem_CPS4_*_Arg (9个) | 未分类 | PH_Elem_CPS4.f90 | ❌ | Arg |
| PH_Elem_CPS6_*_Arg (6个) | 未分类 | PH_Elem_CPS6.f90 | ❌ | Arg |
| PH_Elem_CPS8_*_Arg (9个) | 未分类 | PH_Elem_CPS8.f90 | ❌ | Arg |
| PH_Elem_CAX4_*_Arg (9个) | 未分类 | PH_Elem_CAX4.f90 | ❌ | Arg |

#### Solid2Dt子域 (13 TYPE, 全部 PH_Elem_Sld2DT_Args 重复局部)

#### Solid3Dt子域 (17 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_ELEM_C3D8T_MaterialProperties | 未分类 | PH_Elem_C3D8T.f90 | ❌ | 局部 |
| PH_ELEM_C3D8T_SectionProperties | 未分类 | PH_Elem_C3D8T.f90 | ❌ | 局部 |
| PH_ELEM_C3D*T_OutputData (7个) | 未分类 | C3D4T~C3D27T | ❌ | 局部 |
| PH_Elem_Sld3DT_Args | 未分类 | 各C3D*T+Defn | ❌ | 局部Arg(重复) |

#### Porous子域 (20 TYPE, 全部 PH_Elem_Porous_Args 重复局部)

#### Acoustic子域 (14 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Acoustic_Newmark_Ctx | **Ctx** | PH_Elem_AcousticTransientSolv.f90 | ❌ | 需迁移 |
| PH_Acoustic_Transient_State | **State** | PH_Elem_AcousticTransientSolv.f90 | ❌ | 需迁移 |
| PH_Acoustic_Unified_Analysis_Ctx | **Ctx** | PH_Elem_AcousticTransientSolv.f90 | ❌ | 需迁移 |
| PH_Elem_Acoustic_Args | 未分类 | AC2D4/AC3D20/AcousticDefn | ❌ | 局部Arg(重复) |
| PH_AC*_UEL_Args (8个) | 未分类 | 各AC*元素文件 | ❌ | Arg |

#### Thermal子域 (5 TYPE, 全部_Args未分类)

#### Truss/Dashpot/Spring/Membrane/Infinite子域 (~12 TYPE, 全部_Args/Params未分类)

#### Shared子域 (~25 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Elem_Shared_Args | 未分类 | 多文件重复 | ❌ | 局部Arg |
| PH_Shell_NL_Args | 未分类 | PH_Elem_ShellNLGeom.f90 | ❌ | Arg |
| PH_Elem_C3D8_Data | 未分类 | PH_Elem_DispatchC3D8.f90 | ❌ | 辅助 |
| PH_Elem_C3D8_Output_Data | 未分类 | PH_Elem_DispatchC3D8.f90 | ❌ | 辅助 |
| Coupled_Element_Type | 未分类 | PH_Coupled_Elements_Batch.f90 | ❌ | 辅助 |
| CompLayerInfo | 未分类 | PH_Elem_Comp.f90 | ❌ | 辅助 |
| PH_Beam3DStiffArgs | 未分类 | PH_Elem_Comp.f90 | ❌ | Arg |
| ElemQualMetrics | 未分类 | PH_Elem_Quality.f90 | ❌ | 辅助 |
| PH_ElemQualityArgs | 未分类 | PH_Elem_Utils.f90 | ❌ | Arg |
| PH_Elem_ExtractResults_Arg | 未分类 | PH_Elem_CommonUtil.f90 | ❌ | Arg |
| PH_Elem_ValidateInput_Arg | 未分类 | PH_Elem_CommonUtil.f90 | ❌ | Arg |
| PH_Elem_ComputeEnergy_Arg | 未分类 | PH_Elem_CommonUtil.f90 | ❌ | Arg |
| PH_Mat_Integration_Args | 未分类 | PH_Elem_MatIntegration.f90 | ❌ | Arg |
| PH_Elem_JacobianArgs | 未分类 | PH_Elem_Jacobian.f90 | ❌ | Arg |
| PH_KinematicsArgs | 未分类 | PH_Base_PhysicsUtils.f90 | ❌ | Arg |

---

### Material域 (63 TYPE)

#### _Def.f90中的TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| (PH_Mat_Def.f90 为re-export hub, 不定义新TYPE) | — | PH_Mat_Def.f90 | ✅ | re-export |
| PH_Mat_Elas_Desc | **Desc** | PH_Mat_Elas_Def.f90 | ✅ | 已定义 |
| PH_Mat_Elas_Ctx | **Ctx** | PH_Mat_Elas_Def.f90 | ✅ | 已定义 |
| PH_Mat_Elas_State | **State** | PH_Mat_Elas_Def.f90 | ✅ | 已定义 |
| PH_MatPoint_State | **State** | PH_MatConstit_Def.f90 | ✅ | 已定义 |
| PH_MatPoint_StressStrain | 未分类 | PH_MatConstit_Def.f90 | ✅ | 已定义 |
| MatPointState | **State** | PH_MatConstit_Def.f90 | ✅ | 已定义(Legacy) |
| MatPointStressStrain | 未分类 | PH_MatConstit_Def.f90 | ✅ | 已定义(Legacy) |
| PH_UMAT_Context | **Ctx** | PH_UMAT_Def.f90 | ✅ | 已定义 |

#### PH_Mat_Domain_Core.f90 (核心TYPE定义)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Mat_Ctx | **Ctx** | PH_Mat_Domain_Core.f90 | ❌ | 需迁移(via PH_Mat_Def re-export) |
| PH_Mat_State | **State** | PH_Mat_Domain_Core.f90 | ❌ | 需迁移 |
| PH_Mat_Slot | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | 容器辅助 |
| PH_Mat_Init_Arg | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Arg |
| PH_Mat_GetCtx_Arg | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Arg |
| PH_Mat_GetState_Arg | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Arg |
| PH_Mat_SetCtx_Arg | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Arg |
| PH_Mat_SetState_Arg | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Arg |
| PH_Mat_Domain | 未分类 | PH_Mat_Domain_Core.f90 | ❌ | Domain容器 |

#### 本构族散落TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_J2_Props | 未分类(Desc含义) | PH_Mat_J2_RadialReturn.f90 | ❌ | 需迁移 |
| PH_J2_State | **State** | PH_Mat_J2_RadialReturn.f90 | ❌ | 需迁移 |
| PH_CDM_Props | 未分类(Desc含义) | PH_Mat_Lemaitre_CDM.f90 | ❌ | 需迁移 |
| PH_CDM_State | **State** | PH_Mat_Lemaitre_CDM.f90 | ❌ | 需迁移 |
| PH_NeoHk_Props | 未分类(Desc含义) | PH_Mat_NeoHookean.f90 | ❌ | 需迁移 |
| PH_NeoHk_State | **State** | PH_Mat_NeoHookean.f90 | ❌ | 需迁移 |
| Barlat_Params | 未分类 | PH_MatPlast_Barlat.f90 | ❌ | 需迁移 |
| Barlat_State | **State** | PH_MatPlast_Barlat.f90 | ❌ | 需迁移 |
| Chab_Params | 未分类 | PH_MatPlast_Chaboche.f90 | ❌ | 需迁移 |
| Chab_State | **State** | PH_MatPlast_Chaboche.f90 | ❌ | 需迁移 |
| ChabMat | 未分类 | PH_MatPlast_Chaboche.f90 | ❌ | PRIVATE |
| Hill_Params | 未分类 | PH_MatPlast_Hill.f90 | ❌ | 需迁移 |
| Hill_State | **State** | PH_MatPlast_Hill.f90 | ❌ | 需迁移 |
| HilMat | 未分类 | PH_MatPlast_Hill.f90 | ❌ | PRIVATE |
| CastIronMat | 未分类 | PH_MatComp_Castani.f90 | ❌ | 局部 |
| PH_GTN_UMAT_Args | 未分类 | PH_MatDam_Gurson.f90 | ❌ | Arg |

#### 算法/AI子域

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| AI_MatInteg_Algo | **Algo** | PH_AI_MatInteg.f90 | ❌ | 需迁移 |
| AI_MatInteg_Ctx | **Ctx** | PH_AI_MatInteg.f90 | ❌ | 需迁移 |
| PH_Mat_Kernel_Entry | 未分类 | PH_Mat_Reg.f90 | ❌ | 注册表辅助 |
| PH_Mat_Update_args | 未分类 | PH_Mat_BaseDefn.f90 | ❌ | Arg |
| PH_Mat_Base | 未分类 | PH_Mat_BaseDefn.f90 | ❌ | ABSTRACT基类 |
| PH_Math_Tensor_Args | 未分类 | PH_Mat_hTensor.f90 | ❌ | Arg |
| PH_MAT_UMAT_MaterialClassifier | 未分类 | PH_Mat_UMATIntfEnhanced.f90 | ❌ | 辅助 |

#### Contract子域

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Mat_Spcl_Defn_Args | 未分类 | Contract/PH_Mat_Spcl_Def.f90 | ❌ | Arg |

#### Dispatch子域 (16 TYPE)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Mat_ElasticIsotropic_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_ElasticOrthotropic_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_PlasticVonMises_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_PlasticHill_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_HyperelasticNeoHookean_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_HyperelasticMooneyRivlin_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_DamageDuctile_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_DamageBrittle_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_CreepNorton_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_ViscoelasticProny_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_ViscoelasticMaxwell_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_CompositeLaminate_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_CompositeFiberReinforced_Eval_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_UMATEnsureWorkspace_Arg | 未分类 | PH_MatEval.f90 | ❌ | Arg |
| PH_Mat_PLM_PlastCall_Args | 未分类 | PH_MatPLM_PlastCall.f90 | ❌ | Arg |

---

### Contact域 (77 TYPE)

#### PH_Cont_Def.f90中的TYPE (AUTHORITY)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Cont_Constr_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Friction_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Search_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Surface_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Pair_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Desc | **Desc** | PH_Cont_Def.f90 | ✅ | 已定义(LEGACY) |
| PH_Cont_Constr_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Friction_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_UINTER_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_VUINTER_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPCON_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPUNIT_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Algo | **Algo** | PH_Cont_Def.f90 | ✅ | 已定义(LEGACY) |
| PH_Contact_Base_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_VUINTER_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPCON_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_UINTER_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPUNIT_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Ctx | **Ctx** | PH_Cont_Def.f90 | ✅ | 已定义(LEGACY) |
| PH_Cont_Geometry_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Force_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Stiffness_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Friction_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Convergence_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_Base_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_UINTER_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_VUINTER_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPCON_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_GAPUNIT_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_State | **State** | PH_Cont_Def.f90 | ✅ | 已定义(LEGACY) |
| PH_Cont_Optimization_Params | 未分类 | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Friction_Model | 未分类 | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Thermal_Properties | 未分类 | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_Dynamic_Properties | 未分类 | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Contact_BVH_Node | 未分类 | PH_Cont_Def.f90 | ✅ | 已定义 |
| PH_Cont_*_Arg (22个) | 未分类 | PH_Cont_Def.f90 | ✅ | Arg包 |

#### PH_ThermalCont_Def.f90

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Thermal_Cont_Desc | **Desc** | PH_ThermalCont_Def.f90 | ✅ | 已定义 |
| PH_Thermal_Cont_State | **State** | PH_ThermalCont_Def.f90 | ✅ | 已定义 |
| PH_Thermal_Cont_Algo | **Algo** | PH_ThermalCont_Def.f90 | ✅ | 已定义 |
| PH_Thermal_Cont_Ctx | **Ctx** | PH_ThermalCont_Def.f90 | ✅ | 已定义 |

#### 散落在非_Def文件中的TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_ContactCtx | **Ctx** | Core/PH_Cont_Ctx.f90 | ❌ | 需迁移 |
| PH_Cont_Time_Desc | **Desc** | Core/PH_Cont_Ctx.f90 | ❌ | 需迁移 |
| PH_Cont_Ctx_*_Arg (4个) | 未分类 | Core/PH_Cont_Ctx.f90 | ❌ | Arg |
| PH_NTS_Pair | 未分类 | Core/PH_Cont_NTS_Eval.f90 | ❌ | 辅助 |
| PH_NTS_Props | 未分类 | Core/PH_Cont_NTS_Eval.f90 | ❌ | 辅助 |
| PH_Cont_SearchArgs等 (4个) | 未分类 | Core/PH_Cont_Mgr.f90 | ❌ | Arg |
| AABB_Type等 (6个) | 未分类 | Core/PH_Cont_Mgr.f90 | ❌ | 搜索辅助 |
| PH_Cont_FrictModel | 未分类 | Friction/PH_Cont_Friction.f90 | ❌ | 辅助 |
| PH_Cont_FrictState | **State** | Friction/PH_Cont_Friction.f90 | ❌ | 需迁移 |
| PH_Contact_*_Arg等 (9个) | 未分类 | Domain/PH_Cont_Domain.f90 | ❌ | Domain+Arg |
| Search/ (11个) | 未分类 | Search子目录 | ❌ | 搜索辅助 |
| Self/ (3个) | 未分类 | Self/PH_Cont_SelfContact.f90 | ❌ | 辅助 |
| Wear/ (3个) | 未分类 | Wear/PH_Cont_WearEvolution.f90 | ❌ | 辅助 |
| Thermal/ (3个) | 未分类 | Thermal/PH_Cont_ThermoMech.f90 | ❌ | 辅助 |
| AI/ (1个) | 未分类 | AI/PH_AI_ContactLaw.f90 | ❌ | 辅助 |

---

### LoadBC域 (53 TYPE)

#### _Def.f90中的TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_LoadBC_Desc | **Desc** | PH_LBC_Def.f90 | ✅ | 已定义 |
| PH_LoadBC_Ctx | **Ctx** | PH_LBC_Def.f90 | ✅ | 已定义 |
| PH_LoadBC_State | **State** | PH_LBC_Def.f90 | ✅ | 已定义 |
| PH_BC_Enforcement_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_Cache_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BCCtrl_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_InitPar_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_MethodPar_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_System_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_SystemAug_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_ApplyBCsIn_Type | 未分类 | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_Dirichlet_Desc | **Desc** | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_BC_Neumann_Desc | **Desc** | PH_BC_Def.f90 | ✅ | 已定义 |
| PH_ElemEquivForce_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_SurfaceTraction_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_Load_Integration_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_Load_Cache_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_LoadCtrl_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_Load_Rhs_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_Load_MassRhs_Type | 未分类 | PH_Load_Def.f90 | ✅ | 已定义 |
| PH_Load_Init_Arg | 未分类 | PH_Load_Def.f90 | ✅ | Arg |
| PH_Load_SetGravity_Arg | 未分类 | PH_Load_Def.f90 | ✅ | Arg |
| PH_Load_ApplyLoads_Arg | 未分类 | PH_Load_Def.f90 | ✅ | Arg |

#### 散落在非_Def文件中的TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_LoadBC_Ctx | **Ctx** | PH_LBC_Legacy.f90 | ❌ | 需迁移(重复定义) |
| PH_LoadBC_State | **State** | PH_LBC_Legacy.f90 | ❌ | 需迁移(重复定义) |
| PH_LoadBC_Params | 未分类 | PH_LBC_Legacy.f90 | ❌ | 需迁移 |
| PH_LoadBC_*_Arg (7个) | 未分类 | PH_LBC_Legacy.f90 | ❌ | Arg |
| PH_LoadBC_Domain | 未分类 | PH_LBC_Legacy.f90 | ❌ | Domain容器 |
| PH_Geostatic_Algo_Args | **Algo** | PH_LBC_GeostaticAlgo.f90 | ❌ | 需迁移 |
| PH_WriteBack_Mask_Type | 未分类 | PH_LBC_FlatToNested.f90 | ❌ | 辅助 |
| PH_WriteBack_Status_Type | 未分类 | PH_LBC_FlatToNested.f90 | ❌ | 辅助 |
| PH_BC_CSR_System_Type | 未分类 | PH_BC_Brg.f90 | ❌ | 辅助 |
| PH_SurfLoad_Data | 未分类 | PH_Load_SurfaceTraction.f90 | ❌ | 辅助 |
| PH_BodyForce_Data | 未分类 | PH_Load_SurfaceTraction.f90 | ❌ | 辅助 |
| PH_Load_Ctx | **Ctx** | PH_Load_Mgr.f90 | ❌ | 需迁移 |
| PH_Load_Ctx_*_Arg (3个) | 未分类 | PH_Load_Mgr.f90 | ❌ | Arg |
| PH_Load_*_Arg (12个) | 未分类 | PH_Load_Mgr.f90 | ❌ | Arg |
| PH_BC_Ctx | **Ctx** | PH_BC_Mgr.f90 | ❌ | 需迁移 |
| PH_BC_Ctx_*_Arg (2个) | 未分类 | PH_BC_Mgr.f90 | ❌ | Arg |

---

### Field域 (18 TYPE)

#### PH_Field_Def.f90中的TYPE (全部在_Def中，最规范)

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Field_Desc | **Desc** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Field_Ctx | **Ctx** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Field_State | **State** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Field_Algo | **Algo** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Field_Domain | 未分类 | PH_Field_Def.f90 | ✅ | Domain容器 |
| PH_Temperature_Desc | **Desc** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Temperature_Algo | **Algo** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Temperature_Arg | 未分类 | PH_Field_Def.f90 | ✅ | Arg |
| PH_PorePressure_Desc | **Desc** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_PorePressure_Algo | **Algo** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_PorePressure_In | 未分类 | PH_Field_Def.f90 | ✅ | In/Out |
| PH_PorePressure_Out | 未分类 | PH_Field_Def.f90 | ✅ | In/Out |
| PH_Concentration_Desc | **Desc** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Concentration_Algo | **Algo** | PH_Field_Def.f90 | ✅ | 已定义 |
| PH_Concentration_In | 未分类 | PH_Field_Def.f90 | ✅ | In/Out |

#### 散落TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Field_ShapeFunc_Arg | 未分类 | PH_Field_ShapeFunc.f90 | ❌ | Arg |
| PH_Field_Gradient_Arg | 未分类 | PH_Field_ShapeFunc.f90 | ❌ | Arg |
| PH_Field_GaussPt_Arg | 未分类 | PH_Field_GaussQuadrature.f90 | ❌ | Arg |

---

### Constraint域 (35 TYPE)

#### _Def.f90中的TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Constraint_Desc | **Desc** | PH_Constr_Def.f90 | ✅ | 已定义 |
| PH_Constraint_Algo | **Algo** | PH_Constr_Def.f90 | ✅ | 已定义 |
| PH_Constraint_Ctx | **Ctx** | PH_Constr_Def.f90 | ✅ | 已定义 |
| PH_Constraint_State | **State** | PH_Constr_Def.f90 | ✅ | 已定义 |
| MPC_Term | 未分类 | PH_ConstrMPC_Def.f90 | ✅ | 已定义 |
| MPC_Constraint | 未分类 | PH_ConstrMPC_Def.f90 | ✅ | 已定义 |
| MPC_Params | 未分类 | PH_ConstrMPC_Def.f90 | ✅ | 已定义 |
| MPC_State | **State** | PH_ConstrMPC_Def.f90 | ✅ | 已定义 |
| PH_Constr_MPC_Def | 未分类 | PH_ConstrMPC_Def.f90 | ✅ | 已定义 |
| Tie_Constraint_Params | 未分类 | PH_ConstrTie_Def.f90 | ✅ | 已定义 |
| Tie_Constraint_State | **State** | PH_ConstrTie_Def.f90 | ✅ | 已定义 |
| Tie_Node_Pair | 未分类 | PH_ConstrTie_Def.f90 | ✅ | 已定义 |
| Tie_Surface_Pair | 未分类 | PH_ConstrTie_Def.f90 | ✅ | 已定义 |
| Period_BC_Params | 未分类 | PH_ConstrPeriod_Def.f90 | ✅ | 已定义 |

#### 散落TYPE

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Constraint_Ctx | **Ctx** | PH_Constr_Domain.f90 | ❌ | 重复定义/需迁移 |
| PH_Constraint_State | **State** | PH_Constr_Domain.f90 | ❌ | 重复定义/需迁移 |
| PH_Constraint_Params | 未分类 | PH_Constr_Domain.f90 | ❌ | 需迁移 |
| PH_Constraint_Domain | 未分类 | PH_Constr_Domain.f90 | ❌ | Domain容器 |
| PH_Constr_*_Arg (8个) | 未分类 | PH_Constr_Domain.f90 | ❌ | Arg |
| PH_Constr_Ctx | **Ctx** | PH_Constr_Ctx.f90 | ❌ | 需迁移 |
| PH_Constr_Ctx_*_Arg (4个) | 未分类 | PH_Constr_Ctx.f90 | ❌ | Arg |
| PH_Constr_PeriodCore_BoundaryArgs | 未分类 | PH_Constr_Period.f90 | ❌ | Arg |
| PH_Constr_TieCore_FindNearestArgs | 未分类 | PH_Constr_Tie.f90 | ❌ | Arg |
| PH_Constr_MPCCore_PenaltyArgs | 未分类 | PH_Constr_MPC.f90 | ❌ | Arg |

---

### Bridge域 (16 TYPE)

> **注意: Bridge域没有 _Def.f90 文件**

| TYPE名 | 四型分类 | 所在文件 | 是否在_Def中 | 状态 |
|:-------|:-------:|:--------|:----------:|:----:|
| PH_Brg_Ctx | **Ctx** | PH_Brg_Domain.f90 | ❌ | 需迁移→Def |
| PH_Brg_State | **State** | PH_Brg_Domain.f90 | ❌ | 需迁移→Def |
| PH_Brg_Params | **State**(Algo含义) | PH_Brg_Domain.f90 | ❌ | 需迁移→Def |
| PH_Brg_RegisterLib_Arg | 未分类 | PH_Brg_Domain.f90 | ❌ | Arg |
| PH_Brg_GetSummary_Arg | 未分类 | PH_Brg_Domain.f90 | ❌ | Arg |
| PH_Brg_Domain | 未分类 | PH_Brg_Domain.f90 | ❌ | Domain容器 |
| PH_Brg_ElemStateUpdate_Desc | **Desc** | PH_Brg_L3.f90 | ❌ | 需迁移→Def |
| PH_Brg_MatId_Desc | **Desc** | PH_Brg_L3.f90 | ❌ | 需迁移→Def |
| PH_Brg_ElemId_Desc | **Desc** | PH_Brg_L2.f90 | ❌ | 需迁移→Def |
| PH_Brg_Elem_StiffAsm_Arg | 未分类 | PH_Brg_L3.f90 | ❌ | Arg |
| PH_Brg_UpdateElemState_Arg | 未分类 | PH_Brg_L3.f90 | ❌ | Arg |
| PH_Brg_GetMatResp_Arg | 未分类 | PH_Brg_L3.f90 | ❌ | Arg |
| PH_Brg_GetElemConnectivity_Arg | 未分类 | PH_Brg_L2.f90 | ❌ | Arg |
| PH_Brg_GetNodeCoords_Arg | 未分类 | PH_Brg_L2.f90 | ❌ | Arg |
| PH_Brg_GetGauss_Pts1D/2D/3D_Arg | 未分类 | PH_Brg_L2.f90 | ❌ | Arg |
| PH_WriteBack_Desc | **Desc** | WriteBack/PH_WB_Mgr.f90 | ❌ | 需迁移→Def |
| PH_WriteBack_State | **State** | WriteBack/PH_WB_Mgr.f90 | ❌ | 需迁移→Def |
| PH_WriteBack_Args | 未分类 | WriteBack/PH_WB_Mgr.f90 | ❌ | Arg |
| PH_Output_Params | 未分类 | Output/PH_Out_Mgr.f90 | ❌ | 辅助 |
| PH_Output_State | **State** | Output/PH_Out_Mgr.f90 | ❌ | 需迁移→Def |

---

### Adapters目录 (无新TYPE定义)

> Adapters目录下的.f90文件仅使用 `TYPE(xxx) :: var` 形式引用已有TYPE，不定义新TYPE声明。

---

## 缺失_Def.f90清单

| 域 | 缺失文件 | CONTRACT要求 | 需创建 |
|:---|:---------|:------------|:------:|
| **Bridge** | PH_Brg_Def.f90 | Ctx/State/Algo 三型 (CONTRACT §3) | ✅ |

> Element/Material/Contact/LoadBC/Field/Constraint 各域均已存在 `*_Def.f90`。

---

## 关键发现

1. **Field域**是四型规范度最高的域，所有TYPE集中在 `PH_Field_Def.f90` 中
2. **Contact域**TYPE数量最多(77个)，`PH_Cont_Def.f90` 单文件957行，包含大量 Arg 参数包
3. **Element域**TYPE最分散(204个)，大量散落在各子族元素文件中，以 `_Arg` 为主
4. **Bridge域**是唯一缺少 `_Def.f90` 的域，需新建骨架
5. **Material域**的 `PH_Mat_Def.f90` 是 re-export hub，不含TYPE定义本体
6. **未分类TYPE**占总量的72%(336/466)，其中绝大多数为 `_Arg` 参数包，属于正常设计模式
