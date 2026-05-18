# `MD_Int_Legacy.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Legacy.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Int_ContClearance_Type`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Legacy`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Legacy`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Legacy.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ContClearanceProperties_Clear` | 40 | `SUBROUTINE ContClearanceProperties_Clear(this)` |
| FUNCTION | `ContClearanceProperties_Valid_Fn` | 48 | `FUNCTION ContClearanceProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ContClearanceProperties_Init` | 55 | `SUBROUTINE ContClearanceProperties_Init(this, name, status)` |
| SUBROUTINE | `ContControlsProperties_Clear` | 93 | `SUBROUTINE ContControlsProperties_Clear(this)` |
| SUBROUTINE | `ContControlsProperties_Validate` | 102 | `SUBROUTINE ContControlsProperties_Validate(this, status)` |
| SUBROUTINE | `ContControlsProperties_Init` | 114 | `SUBROUTINE ContControlsProperties_Init(this, name, status)` |
| SUBROUTINE | `ContInitializationProperties_Clear` | 153 | `SUBROUTINE ContInitializationProperties_Clear(this)` |
| FUNCTION | `ContInitializationProperties_Valid_Fn` | 162 | `FUNCTION ContInitializationProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ContInitializationProperties_Init` | 169 | `SUBROUTINE ContInitializationProperties_Init(this, name, status)` |
| SUBROUTINE | `ContInterferenceProperties_Clear` | 208 | `SUBROUTINE ContInterferenceProperties_Clear(this)` |
| FUNCTION | `ContInterferenceProperties_Valid_Fn` | 217 | `FUNCTION ContInterferenceProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ContInterferenceProperties_Init` | 224 | `SUBROUTINE ContInterferenceProperties_Init(this, name, status)` |
| SUBROUTINE | `ContOutputProperties_Clear` | 264 | `SUBROUTINE ContOutputProperties_Clear(this)` |
| FUNCTION | `ContOutputProperties_Valid_Fn` | 274 | `FUNCTION ContOutputProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ContOutputProperties_Init` | 281 | `SUBROUTINE ContOutputProperties_Init(this, name, status)` |
| SUBROUTINE | `ContStabilizationProperties_Clear` | 321 | `SUBROUTINE ContStabilizationProperties_Clear(this)` |
| FUNCTION | `ContStabilizationProperties_Valid_Fn` | 330 | `FUNCTION ContStabilizationProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ContStabilizationProperties_Init` | 338 | `SUBROUTINE ContStabilizationProperties_Init(this, name, status)` |
| SUBROUTINE | `FrictionProperties_Clear` | 377 | `SUBROUTINE FrictionProperties_Clear(this)` |
| FUNCTION | `FrictionProperties_Valid_Fn` | 386 | `FUNCTION FrictionProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `FrictionProperties_Init` | 394 | `SUBROUTINE FrictionProperties_Init(this, name, status)` |
| SUBROUTINE | `FrictionCoefficientProperties_Clear` | 432 | `SUBROUTINE FrictionCoefficientProperties_Clear(this)` |
| FUNCTION | `FrictionCoefficientProperties_Valid_Fn` | 440 | `FUNCTION FrictionCoefficientProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `FrictionCoefficientProperties_Init` | 448 | `SUBROUTINE FrictionCoefficientProperties_Init(this, name, status)` |
| SUBROUTINE | `FrictionOutputProperties_Clear` | 486 | `SUBROUTINE FrictionOutputProperties_Clear(this)` |
| FUNCTION | `FrictionOutputProperties_Valid_Fn` | 495 | `FUNCTION FrictionOutputProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `FrictionOutputProperties_Init` | 502 | `SUBROUTINE FrictionOutputProperties_Init(this, name, status)` |
| SUBROUTINE | `StickSlipProperties_Clear` | 541 | `SUBROUTINE StickSlipProperties_Clear(this)` |
| FUNCTION | `StickSlipProperties_Valid_Fn` | 550 | `FUNCTION StickSlipProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `StickSlipProperties_Init` | 558 | `SUBROUTINE StickSlipProperties_Init(this, name, status)` |
| SUBROUTINE | `UserContactProperties_Clear` | 596 | `SUBROUTINE UserContactProperties_Clear(this)` |
| FUNCTION | `UserContactProperties_Valid_Fn` | 604 | `FUNCTION UserContactProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `UserContactProperties_Init` | 611 | `SUBROUTINE UserContactProperties_Init(this, interactionName, status)` |
| SUBROUTINE | `Va_CO_CL_Keyword` | 637 | `SUBROUTINE Va_CO_CL_Keyword(contactClearance, status)` |
| SUBROUTINE | `Va_CO_CO_Keyword` | 666 | `SUBROUTINE Va_CO_CO_Keyword(contactControls, status)` |
| SUBROUTINE | `Valid_CONTACT_Init_Keyword` | 695 | `SUBROUTINE Valid_CONTACT_Init_Keyword(contactInit, status)` |
| SUBROUTINE | `Va_CO_IN_Keyword` | 724 | `SUBROUTINE Va_CO_IN_Keyword(contactInterference, status)` |
| SUBROUTINE | `Valid_CONTACT_OUTPUT_Keyword` | 753 | `SUBROUTINE Valid_CONTACT_OUTPUT_Keyword(contactOutput, status)` |
| SUBROUTINE | `Va_CO_ST_Keyword` | 782 | `SUBROUTINE Va_CO_ST_Keyword(contactStab, status)` |
| SUBROUTINE | `Valid_FRICTION_Keyword` | 811 | `SUBROUTINE Valid_FRICTION_Keyword(friction, status)` |
| SUBROUTINE | `Va_FR_CO_Keyword` | 840 | `SUBROUTINE Va_FR_CO_Keyword(frictionCoeff, status)` |
| SUBROUTINE | `Va_FR_OU_Keyword` | 869 | `SUBROUTINE Va_FR_OU_Keyword(frictionOutput, status)` |
| SUBROUTINE | `Valid_STICK_SLIP_Keyword` | 898 | `SUBROUTINE Valid_STICK_SLIP_Keyword(stickSlip, status)` |
| SUBROUTINE | `Valid_USER_CONTACT_Keyword` | 927 | `SUBROUTINE Valid_USER_CONTACT_Keyword(userContact, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 960 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 974 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactClearance, context_name, status)` |
| SUBROUTINE | `Pa_CO_CL_Keyword` | 991 | `SUBROUTINE Pa_CO_CL_Keyword(ast_node, contactClearance, name, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 1030 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 1044 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactControls, context_name, status)` |
| SUBROUTINE | `Pa_CO_CO_Keyword` | 1061 | `SUBROUTINE Pa_CO_CO_Keyword(ast_node, contactControls, name, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 1102 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 1116 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactInit, context_name, status)` |
| SUBROUTINE | `Parse_CONTACT_Init_Keyword` | 1133 | `SUBROUTINE Parse_CONTACT_Init_Keyword(ast_node, contactInit, name, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 1172 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 1186 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactInterference, context_name, status)` |
| SUBROUTINE | `Pa_CO_IN_Keyword` | 1203 | `SUBROUTINE Pa_CO_IN_Keyword(ast_node, contactInterference, name, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 1242 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 1256 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactOutput, context_name, status)` |
| SUBROUTINE | `Parse_CONTACT_OUTPUT_Keyword` | 1273 | `SUBROUTINE Parse_CONTACT_OUTPUT_Keyword(ast_node, contactOutput, name, status)` |
| SUBROUTINE | `MD_In_Co_Un_Configure` | 1309 | `SUBROUTINE MD_In_Co_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Co_Un_Parse` | 1323 | `SUBROUTINE MD_In_Co_Un_Parse(int_type, ast_node, contactStab, context_name, status)` |
| SUBROUTINE | `Pa_CO_ST_Keyword` | 1340 | `SUBROUTINE Pa_CO_ST_Keyword(ast_node, contactStab, name, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Configure` | 1379 | `SUBROUTINE MD_In_Fr_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Parse` | 1393 | `SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, friction, context_name, status)` |
| SUBROUTINE | `Parse_FRICTION_Keyword` | 1410 | `SUBROUTINE Parse_FRICTION_Keyword(ast_node, friction, name, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Configure` | 1449 | `SUBROUTINE MD_In_Fr_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Parse` | 1463 | `SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, frictionCoeff, context_name, status)` |
| SUBROUTINE | `Pa_FR_CO_Keyword` | 1480 | `SUBROUTINE Pa_FR_CO_Keyword(ast_node, frictionCoeff, name, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Configure` | 1520 | `SUBROUTINE MD_In_Fr_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Fr_Un_Parse` | 1534 | `SUBROUTINE MD_In_Fr_Un_Parse(int_type, ast_node, frictionOutput, context_name, status)` |
| SUBROUTINE | `Pa_FR_OU_Keyword` | 1551 | `SUBROUTINE Pa_FR_OU_Keyword(ast_node, frictionOutput, name, status)` |
| SUBROUTINE | `MD_In_St_Un_Configure` | 1587 | `SUBROUTINE MD_In_St_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_St_Un_Parse` | 1601 | `SUBROUTINE MD_In_St_Un_Parse(int_type, ast_node, stickSlip, context_name, status)` |
| SUBROUTINE | `Parse_STICK_SLIP_Keyword` | 1618 | `SUBROUTINE Parse_STICK_SLIP_Keyword(ast_node, stickSlip, name, status)` |
| SUBROUTINE | `MD_In_Us_Un_Configure` | 1659 | `SUBROUTINE MD_In_Us_Un_Configure(operation, status)` |
| SUBROUTINE | `MD_In_Us_Un_Parse` | 1673 | `SUBROUTINE MD_In_Us_Un_Parse(int_type, ast_node, userContact, context_name, status)` |
| SUBROUTINE | `Parse_USER_CONTACT_Keyword` | 1690 | `SUBROUTINE Parse_USER_CONTACT_Keyword(ast_node, userContact, status)` |
| SUBROUTINE | `MD_TieDesc_Ensure` | 1962 | `SUBROUTINE MD_TieDesc_Ensure(this)` |
| SUBROUTINE | `MD_CouplingDesc_Init` | 1972 | `SUBROUTINE MD_CouplingDesc_Init(this, couplingId, name, couplingType, referenceNode, surface)` |
| SUBROUTINE | `MD_TieDesc_RegLayout` | 1985 | `SUBROUTINE MD_TieDesc_RegLayout(this)` |
| SUBROUTINE | `MD_ContDesc_Ensure` | 2016 | `SUBROUTINE MD_ContDesc_Ensure(this)` |
| SUBROUTINE | `MD_TieDesc_Init` | 2026 | `SUBROUTINE MD_TieDesc_Init(this, tieId, name, masterSurface, slaveSurface)` |
| SUBROUTINE | `MD_MPCDesc_RegLayout` | 2038 | `SUBROUTINE MD_MPCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_MPCDesc_Ensure` | 2059 | `SUBROUTINE MD_MPCDesc_Ensure(this)` |
| SUBROUTINE | `MD_MPCDesc_Init` | 2069 | `SUBROUTINE MD_MPCDesc_Init(this, mpcId, name)` |
| SUBROUTINE | `MD_CouplingDesc_RegLayout` | 2079 | `SUBROUTINE MD_CouplingDesc_RegLayout(this)` |
| SUBROUTINE | `MD_CouplingDesc_Ensure` | 2115 | `SUBROUTINE MD_CouplingDesc_Ensure(this)` |
| SUBROUTINE | `MD_ContDesc_RegLayout` | 2125 | `SUBROUTINE MD_ContDesc_RegLayout(this)` |
| SUBROUTINE | `MD_InterSta_Init` | 2160 | `SUBROUTINE MD_InterSta_Init(this, interactionId)` |
| SUBROUTINE | `MD_InterSta_RegLayout` | 2168 | `SUBROUTINE MD_InterSta_RegLayout(this)` |
| SUBROUTINE | `MD_InterDesc_Ensure` | 2188 | `SUBROUTINE MD_InterDesc_Ensure(this)` |
| SUBROUTINE | `MD_InterDesc_Init` | 2198 | `SUBROUTINE MD_InterDesc_Init(this, interactionId, name, interactionType)` |
| SUBROUTINE | `MD_InterDesc_RegLayout` | 2209 | `SUBROUTINE MD_InterDesc_RegLayout(this)` |
| SUBROUTINE | `MD_InterCtx_Ensure` | 2235 | `SUBROUTINE MD_InterCtx_Ensure(this)` |
| SUBROUTINE | `MD_ContDesc_Init` | 2245 | `SUBROUTINE MD_ContDesc_Init(this, contactId, name, masterSurface, slaveSurface, frictionCoeff)` |
| SUBROUTINE | `MD_InterCtx_RegLayout` | 2259 | `SUBROUTINE MD_InterCtx_RegLayout(this)` |
| SUBROUTINE | `MD_InterSta_Ensure` | 2275 | `SUBROUTINE MD_InterSta_Ensure(this)` |
| SUBROUTINE | `MD_InterCtx_Init` | 2285 | `SUBROUTINE MD_InterCtx_Init(this, interactionId)` |
| SUBROUTINE | `UF_Interaction_Delete` | 2495 | `subroutine UF_Interaction_Delete(model, name, ierr)` |
| SUBROUTINE | `UF_Interaction_AddToStep` | 2513 | `subroutine UF_Interaction_AddToStep(model, stepIndex, interactionName, ierr)` |
| SUBROUTINE | `UF_Interaction_Delete` | 2562 | `subroutine UF_Interaction_Delete(model, idx, ierr)` |
| SUBROUTINE | `UF_Interaction_Add` | 2605 | `subroutine UF_Interaction_Add(model, name, intType, masterSurfId, slaveSurfId, &` |
| SUBROUTINE | `UF_Interaction_FindByName` | 2647 | `subroutine UF_Interaction_FindByName(model, name, idx, ierr)` |
| SUBROUTINE | `UF_Interaction_GetPropertyId` | 2675 | `subroutine UF_Interaction_GetPropertyId(model, interactionName, propertyId, ierr)` |
| SUBROUTINE | `UF_Interaction_SetPropertyId` | 2699 | `subroutine UF_Interaction_SetPropertyId(model, interactionName, propertyId, ierr)` |
| SUBROUTINE | `UF_Interaction_SetActive` | 2722 | `subroutine UF_Interaction_SetActive(model, interactionName, isActive, ierr)` |
| SUBROUTINE | `UF_Interact_RemoveFromStep` | 2745 | `subroutine UF_Interact_RemoveFromStep(model, stepIndex, interactionName, ierr)` |
| SUBROUTINE | `UF_Interaction_GetType` | 2805 | `subroutine UF_Interaction_GetType(model, interactionName, interactionType, ierr)` |
| SUBROUTINE | `MD_Inter_Mgr_GetStat` | 2829 | `SUBROUTINE MD_Inter_Mgr_GetStat(this, stats, status)` |
| SUBROUTINE | `MD_Inter_Mgr_Delete` | 2839 | `SUBROUTINE MD_Inter_Mgr_Delete(this, id, status)` |
| FUNCTION | `MD_Inter_Mgr_Find` | 2866 | `FUNCTION MD_Inter_Mgr_Find(this, name) RESULT(id)` |
| SUBROUTINE | `MD_Inter_Mgr_Create` | 2884 | `SUBROUTINE MD_Inter_Mgr_Create(this, id, name, status)` |
| SUBROUTINE | `MD_Inter_Mgr_Init` | 2915 | `SUBROUTINE MD_Inter_Mgr_Init(this, max_capacity, status)` |
| SUBROUTINE | `MD_Inter_Mgr_Final` | 2937 | `SUBROUTINE MD_Inter_Mgr_Final(this, status)` |
| SUBROUTINE | `MD_Inter_Mgr_Valid` | 2953 | `SUBROUTINE MD_Inter_Mgr_Valid(this, id, status)` |
| SUBROUTINE | `MD_Inter_Mgr_ValidCons` | 2976 | `SUBROUTINE MD_Inter_Mgr_ValidCons(this, status)` |
| SUBROUTINE | `MD_Inter_Mgr_List` | 2992 | `SUBROUTINE MD_Inter_Mgr_List(this, names, count, status)` |
| SUBROUTINE | `MD_Inter_Mgr_Get` | 3017 | `SUBROUTINE MD_Inter_Mgr_Get(this, id, status)` |
| FUNCTION | `MD_Inter_Mgr_GetCnt` | 3047 | `FUNCTION MD_Inter_Mgr_GetCnt(this) RESULT(count)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
