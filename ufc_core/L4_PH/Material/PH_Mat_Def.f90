!===============================================================================
! MODULE: PH_Mat_Def
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Authoritative TYPE re-export hub for L4 Material domain (four-type).
! **W1**：**四型再导出枢纽**；消费侧 **`PH_Mat_Desc`** / **`desc%props`** / **`PH_Mat_Desc_Effective_Model`**；
!         执行链 **`PH_Mat_Core`** / **`PH_Mat_Domain_Core`** / **`RT_Mat_Brg`**。
!--- COLD (Def/Desc/Enum/Contract) vs HOT (Core/Ops/Brg/Proc) ---
!   This hub re-exports TYPE shapes only (cold). Implementations live in
!   PH_Mat_*_Def / PH_Mat_*_Core / Dispatch / RT_Mat_* — keep USE lists grouped that way.
!===============================================================================
! Re-exports all key TYPEs, family-level enum markers, model-ID constants,
! and core interfaces. Symmetric to L3 MD_Mat_Def.f90.
! Downstream code should USE PH_Mat_Def instead of reaching into individual files.
!
! This module is a **re-export hub only** - no TYPE definitions, no logic.
!
! Four-Type mapping:
!   Desc  -> PH_Mat_Desc       (material model type, ID, property array)
!   Ctx   -> PH_Mat_Ctx        (per-IP context: step/incr, temperature, dt)
!   State -> PH_Mat_State      (stress, C_tan, stateVars; nested %comp/%evo + 扁平 DEPRECATED)
!          -> PH_Mat_State_DualWrite_Stress6 / Ctan66 / StateVars 双轨写入口
!   Algo  -> PH_Mat_Algo       (tolerances, max iterations, integration scheme)
! Purpose: Single-public-USE hub for L4 Material four-type carriers and SIO *_Arg bundles.
! Theory: TYPE and procedure bodies live in PH_Mat_Domain_Core and family Def modules; this file re-exports only.
! Status: ACTIVE

MODULE PH_Mat_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Mat_Domain_Core, ONLY: &
    !--- Four-Type TYPEs ---
    PH_Mat_Desc,           &
    PH_Mat_Ctx,            &
    PH_Mat_State,          &
    PH_Mat_Algo,           &
    PH_Mat_Slot,           &
    PH_Mat_Domain,         &
    !--- Arg bundles ---
    PH_Mat_Init_Arg,       &
    PH_Mat_GetCtx_Arg,     &
    PH_Mat_GetState_Arg,   &
    PH_Mat_SetCtx_Arg,     &
    PH_Mat_SetState_Arg,   &
    !--- Phase 6A: Constitutive interface & eval arg ---
    PH_Mat_Eval_Arg,       &
    PH_Mat_Constitutive_Ifc, &
    !--- Slot API procedures ---
    PH_Mat_Apply_Init_Arg,  &
    PH_Mat_AllocSlot_Idx,   &
    PH_Mat_GetCtx_Idx,      &
    PH_Mat_GetState_Idx,    &
    PH_Mat_SetCtx_Idx,      &
    PH_Mat_SetState_Idx,    &
    PH_Mat_State_DualWrite_Stress6, &
    PH_Mat_State_DualWrite_Ctan66, &
    PH_Mat_State_DualWrite_StateVars, &
    !--- Auxiliary TYPEs (Phase x Verb grouping) ---
    PH_Mat_Cfg_Init_Desc,  &
    PH_Mat_Pop_Vld_Desc,   &
    PH_Mat_Inc_Evo_Ctx,    &
    PH_Mat_Lcl_Comp_Ctx,   &
    PH_Mat_Lcl_Comp_State, &
    PH_Mat_Lcl_Evo_State,  &
    PH_Mat_Stp_Ctl_Algo,   &
    PH_Mat_Lcl_Comp_ArgIn, &
    PH_Mat_Lcl_Comp_ArgOut,&
    PH_Mat_Slot_PhaseIdx
  USE PH_Mat_Enum, ONLY: &
    PH_MAT_UNKNOWN,        &
    PH_MAT_ELASTIC,        &
    PH_MAT_ELASTO_PLASTIC, &
    PH_MAT_HYPERELASTIC,   &
    PH_MAT_VISCOELASTIC,   &
    PH_MAT_CREEP,          &
    PH_MAT_DAMAGE,         &
    PH_MAT_GEOTECH,        &
    PH_MAT_COMPOSITE,      &
    PH_MAT_THERMAL,        &
    PH_MAT_ACOUSTIC,       &
    PH_MAT_USER,           &
    PH_MAT_USER_UMAT,      &
    PH_MAT_USER_VUMAT,     &
    PH_MAT_MAX_POOL
  USE PH_Mat_Constit_Def, ONLY: &
    PH_MatPoint_State,         &
    PH_MatPoint_StressStrain
  USE PH_Mat_UMAT_Def, ONLY: &
    PH_UMAT_Context,      &
    PH_UMAT_Intf
  !--- Family-level four-type definitions ---
  USE PH_Mat_Elas_Def, ONLY: &
    PH_Mat_Elas_Desc, PH_Mat_Elas_State, PH_Mat_Elas_Algo, PH_Mat_Elas_Ctx, &
    PH_Mat_Elas_Eval_Arg
  USE PH_Mat_Plast_Def, ONLY: &
    PH_Mat_Plast_Desc, PH_Mat_Plast_State, PH_Mat_Plast_Algo, PH_Mat_Plast_Ctx, &
    PH_Mat_Plast_Eval_Arg
  USE PH_Mat_Geo_Def, ONLY: &
    PH_Mat_Geo_Desc, PH_Mat_Geo_State, PH_Mat_Geo_Algo, PH_Mat_Geo_Ctx, &
    PH_Mat_Geo_Eval_Arg
  USE PH_Mat_Hyper_Def, ONLY: &
    PH_Mat_Hyper_Desc, PH_Mat_Hyper_State, PH_Mat_Hyper_Algo, PH_Mat_Hyper_Ctx, &
    PH_Mat_Hyper_Eval_Arg
  USE PH_Mat_Visco_Def, ONLY: &
    PH_Mat_Visco_Desc, PH_Mat_Visco_State, PH_Mat_Visco_Algo, PH_Mat_Visco_Ctx, &
    PH_Mat_Visco_Eval_Arg
  USE PH_Mat_Creep_Def, ONLY: &
    PH_Mat_Creep_Desc, PH_Mat_Creep_State, PH_Mat_Creep_Algo, PH_Mat_Creep_Ctx, &
    PH_Mat_Creep_Eval_Arg
  USE PH_Mat_Damage_Def, ONLY: &
    PH_Mat_Damage_Desc, PH_Mat_Damage_State, PH_Mat_Damage_Algo, PH_Mat_Damage_Ctx, &
    PH_Mat_Damage_Eval_Arg
  USE PH_Mat_Comp_Def, ONLY: &
    PH_Mat_Comp_Desc, PH_Mat_Comp_State, PH_Mat_Comp_Algo, PH_Mat_Comp_Ctx, &
    PH_Mat_Comp_Eval_Arg
  USE PH_Mat_Therm_Def, ONLY: &
    PH_Mat_Therm_Desc, PH_Mat_Therm_State, PH_Mat_Therm_Algo, PH_Mat_Therm_Ctx, &
    PH_Mat_Therm_Eval_Arg
  USE PH_Mat_Acou_Def, ONLY: &
    PH_Mat_Acou_Desc, PH_Mat_Acou_State, PH_Mat_Acou_Algo, PH_Mat_Acou_Ctx, &
    PH_Mat_Acou_Eval_Arg
  USE PH_Mat_User_Def, ONLY: &
    PH_Mat_User_Desc, PH_Mat_User_State, PH_Mat_User_Algo, PH_Mat_User_Ctx, &
    PH_Mat_User_Eval_Arg
  USE PH_Mat_Reg, ONLY: &
    ! Family 01: Linear Elastic
    MAT_ELAS_ISO, MAT_ELAS_ORTHO, MAT_ELAS_TRANSV_ISO, MAT_ELAS_ANISO, &
    ! Family 02: Rate-Independent Plasticity
    MAT_PLAST_J2_ISO, MAT_PLAST_J2_TAB, MAT_PLAST_KIN_LIN,      &
    MAT_PLAST_KIN_COMB, MAT_PLAST_ANISO_HIL, MAT_PLAST_JOHNSON_C, &
    MAT_PLAST_POROUS, MAT_PLAST_ORNL, MAT_PLAST_AF,              &
    MAT_PLAST_CHABOCHE, MAT_PLAST_BARLAT, MAT_PLAST_CRYSTAL,     &
    ! Family 03: Geomechanics Plasticity
    MAT_GEO_DP_LINEAR, MAT_GEO_DP_CAP, MAT_GEO_MC,              &
    MAT_GEO_CC_CRIT, MAT_GEO_CONCRETE, MAT_GEO_FOAM_CRUSH,      &
    MAT_GEO_CAM_CLAY, MAT_GEO_HOEK_BROWN,                       &
    ! Family 04: Hyperelastic
    MAT_HE_NEOHOOKEAN, MAT_HE_MOONEY2, MAT_HE_MOONEY5,          &
    MAT_HE_OGDEN2, MAT_HE_OGDEN3, MAT_HE_YEOH,                  &
    MAT_HE_ARRUDA_BOYCE, MAT_HE_GENT, MAT_HE_HYPERFOAM,         &
    MAT_HE_MARLOW, MAT_HE_VAN_DW,                                &
    ! Family 05: Viscoelastic
    MAT_VE_PRONY_DEV, MAT_VE_PRONY_VOL, MAT_VE_KELVIN,          &
    MAT_VE_WLF_SHIFT,                                            &
    ! Family 06: Creep / Viscoplastic
    MAT_CREEP_POWER, MAT_CREEP_USER, MAT_VP_TWO_LAYER,           &
    MAT_CREEP_ANNEAL, MAT_CREEP_GAROFALO, MAT_CREEP_PERZYNA,     &
    MAT_CREEP_DUVAUT, MAT_CREEP_BODNER,                          &
    ! Family 07: Damage / Failure
    MAT_DMG_DUCTILE, MAT_DMG_SHEAR, MAT_DMG_BRITTLE,            &
    MAT_DMG_FLD, MAT_DMG_CZM, MAT_DMG_CONCRETE,                 &
    ! Family 08: Composites
    MAT_COMP_CLT, MAT_COMP_HASHIN, MAT_COMP_FABRIC,              &
    MAT_COMP_JOINTED, MAT_COMP_FOAM_VE,                          &
    ! Family 09: Thermal
    MAT_HEAT_ISO, MAT_HEAT_ORTHO, MAT_HEAT_PHASE_CHG,           &
    ! Family 10: Acoustic
    MAT_ACOUSTIC_LINEAR, MAT_ACOUSTIC_ABSORB,                    &
    ! Family 11: User-defined
    MAT_USER_UMAT, MAT_USER_VUMAT,                               &
    ! Registry types & API
    PH_Mat_Kernel_Entry
  USE PH_Mat_Core, ONLY: &
    PH_Mat_Desc_Effective_Model, &
    PH_Mat_Execute_Flow,     &
    PH_Mat_S1_FetchState,    &
    PH_Mat_S2_Dispatch,      &
    PH_Mat_S3_StressUpdate,  &
    PH_Mat_S4_Tangent
  USE PH_Mat_KernelDefn, ONLY: &
    PH_MAT_MAX_NTENS,             &
    PH_MAT_STRESS_STATE_3D,       &
    PH_MAT_STRESS_STATE_CPS,      &
    PH_MAT_STRESS_STATE_CPE,      &
    PH_MAT_STRESS_STATE_CAX,      &
    PH_Mat_Update_Arg

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Desc
  PUBLIC :: PH_Mat_Ctx
  PUBLIC :: PH_Mat_State
  PUBLIC :: PH_Mat_Algo
  PUBLIC :: PH_Mat_Slot
  PUBLIC :: PH_Mat_Domain
  PUBLIC :: PH_Mat_Init_Arg
  PUBLIC :: PH_Mat_GetCtx_Arg
  PUBLIC :: PH_Mat_GetState_Arg
  PUBLIC :: PH_Mat_SetCtx_Arg
  PUBLIC :: PH_Mat_SetState_Arg

  !--- Phase 6A: Constitutive interface & eval arg ---
  PUBLIC :: PH_Mat_Eval_Arg
  PUBLIC :: PH_Mat_Constitutive_Ifc

  !--- Auxiliary TYPEs (Phase x Verb grouping) ---
  PUBLIC :: PH_Mat_Cfg_Init_Desc
  PUBLIC :: PH_Mat_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Inc_Evo_Ctx
  PUBLIC :: PH_Mat_Lcl_Comp_Ctx
  PUBLIC :: PH_Mat_Lcl_Comp_State
  PUBLIC :: PH_Mat_Lcl_Evo_State
  PUBLIC :: PH_Mat_Stp_Ctl_Algo
  PUBLIC :: PH_Mat_Lcl_Comp_ArgIn
  PUBLIC :: PH_Mat_Lcl_Comp_ArgOut
  PUBLIC :: PH_Mat_Krnl_Ctx
  PUBLIC :: PH_Mat_Krnl_Algo
  PUBLIC :: PH_Mat_Slot_PhaseIdx

  !--- Slot API procedures ---
  PUBLIC :: PH_Mat_Apply_Init_Arg
  PUBLIC :: PH_Mat_AllocSlot_Idx
  PUBLIC :: PH_Mat_GetCtx_Idx
  PUBLIC :: PH_Mat_GetState_Idx
  PUBLIC :: PH_Mat_SetCtx_Idx
  PUBLIC :: PH_Mat_SetState_Idx
  PUBLIC :: PH_Mat_State_DualWrite_Stress6
  PUBLIC :: PH_Mat_State_DualWrite_Ctan66
  PUBLIC :: PH_Mat_State_DualWrite_StateVars

  !--- 11-family slot markers ---
  PUBLIC :: PH_MAT_UNKNOWN
  PUBLIC :: PH_MAT_ELASTIC
  PUBLIC :: PH_MAT_ELASTO_PLASTIC
  PUBLIC :: PH_MAT_HYPERELASTIC
  PUBLIC :: PH_MAT_VISCOELASTIC
  PUBLIC :: PH_MAT_CREEP
  PUBLIC :: PH_MAT_DAMAGE
  PUBLIC :: PH_MAT_GEOTECH
  PUBLIC :: PH_MAT_COMPOSITE
  PUBLIC :: PH_MAT_THERMAL
  PUBLIC :: PH_MAT_ACOUSTIC
  PUBLIC :: PH_MAT_USER
  PUBLIC :: PH_MAT_USER_UMAT
  PUBLIC :: PH_MAT_USER_VUMAT
  PUBLIC :: PH_MAT_MAX_POOL

  !--- MatPoint types [DEPRECATED 2026-05] ---
  ! Prefer PH_Mat_State (from PH_Mat_Domain_Core) for new integration-point state.
  ! PH_MatPoint_State is a flat, non-nested type retained for backward compatibility
  ! with ~50 element files. Migration plan: replace subroutine arguments with
  ! PH_Mat_State (nested comp/evo structure). See PH_Mat_Constit_Def.f90 header.
  PUBLIC :: PH_MatPoint_State
  PUBLIC :: PH_MatPoint_StressStrain

  !--- UMAT types & interface ---
  PUBLIC :: PH_UMAT_Context
  PUBLIC :: PH_UMAT_Intf

  !--- Model-ID constants (PH_Mat_Reg discrete MAT_* set) ---
  PUBLIC :: MAT_ELAS_ISO, MAT_ELAS_ORTHO, MAT_ELAS_TRANSV_ISO, MAT_ELAS_ANISO

  !--- Family-level four-type re-exports ---
  PUBLIC :: PH_Mat_Elas_Desc, PH_Mat_Elas_State, PH_Mat_Elas_Algo, PH_Mat_Elas_Ctx
  PUBLIC :: PH_Mat_Elas_Eval_Arg
  PUBLIC :: PH_Mat_Plast_Desc, PH_Mat_Plast_State, PH_Mat_Plast_Algo, PH_Mat_Plast_Ctx
  PUBLIC :: PH_Mat_Plast_Eval_Arg
  PUBLIC :: PH_Mat_Geo_Desc, PH_Mat_Geo_State, PH_Mat_Geo_Algo, PH_Mat_Geo_Ctx
  PUBLIC :: PH_Mat_Geo_Eval_Arg
  PUBLIC :: PH_Mat_Hyper_Desc, PH_Mat_Hyper_State, PH_Mat_Hyper_Algo, PH_Mat_Hyper_Ctx
  PUBLIC :: PH_Mat_Hyper_Eval_Arg
  PUBLIC :: PH_Mat_Visco_Desc, PH_Mat_Visco_State, PH_Mat_Visco_Algo, PH_Mat_Visco_Ctx
  PUBLIC :: PH_Mat_Visco_Eval_Arg
  PUBLIC :: PH_Mat_Creep_Desc, PH_Mat_Creep_State, PH_Mat_Creep_Algo, PH_Mat_Creep_Ctx
  PUBLIC :: PH_Mat_Creep_Eval_Arg
  PUBLIC :: PH_Mat_Damage_Desc, PH_Mat_Damage_State, PH_Mat_Damage_Algo, PH_Mat_Damage_Ctx
  PUBLIC :: PH_Mat_Damage_Eval_Arg
  PUBLIC :: PH_Mat_Comp_Desc, PH_Mat_Comp_State, PH_Mat_Comp_Algo, PH_Mat_Comp_Ctx
  PUBLIC :: PH_Mat_Comp_Eval_Arg
  PUBLIC :: PH_Mat_Therm_Desc, PH_Mat_Therm_State, PH_Mat_Therm_Algo, PH_Mat_Therm_Ctx
  PUBLIC :: PH_Mat_Therm_Eval_Arg
  PUBLIC :: PH_Mat_Acou_Desc, PH_Mat_Acou_State, PH_Mat_Acou_Algo, PH_Mat_Acou_Ctx
  PUBLIC :: PH_Mat_Acou_Eval_Arg
  PUBLIC :: PH_Mat_User_Desc, PH_Mat_User_State, PH_Mat_User_Algo, PH_Mat_User_Ctx
  PUBLIC :: PH_Mat_User_Eval_Arg

  PUBLIC :: MAT_PLAST_J2_ISO, MAT_PLAST_J2_TAB, MAT_PLAST_KIN_LIN
  PUBLIC :: MAT_PLAST_KIN_COMB, MAT_PLAST_ANISO_HIL, MAT_PLAST_JOHNSON_C
  PUBLIC :: MAT_PLAST_POROUS, MAT_PLAST_ORNL, MAT_PLAST_AF
  PUBLIC :: MAT_PLAST_CHABOCHE, MAT_PLAST_BARLAT, MAT_PLAST_CRYSTAL
  PUBLIC :: MAT_GEO_DP_LINEAR, MAT_GEO_DP_CAP, MAT_GEO_MC
  PUBLIC :: MAT_GEO_CC_CRIT, MAT_GEO_CONCRETE, MAT_GEO_FOAM_CRUSH
  PUBLIC :: MAT_GEO_CAM_CLAY, MAT_GEO_HOEK_BROWN
  PUBLIC :: MAT_HE_NEOHOOKEAN, MAT_HE_MOONEY2, MAT_HE_MOONEY5
  PUBLIC :: MAT_HE_OGDEN2, MAT_HE_OGDEN3, MAT_HE_YEOH
  PUBLIC :: MAT_HE_ARRUDA_BOYCE, MAT_HE_GENT, MAT_HE_HYPERFOAM
  PUBLIC :: MAT_HE_MARLOW, MAT_HE_VAN_DW
  PUBLIC :: MAT_VE_PRONY_DEV, MAT_VE_PRONY_VOL, MAT_VE_KELVIN
  PUBLIC :: MAT_VE_WLF_SHIFT
  PUBLIC :: MAT_CREEP_POWER, MAT_CREEP_USER, MAT_VP_TWO_LAYER
  PUBLIC :: MAT_CREEP_ANNEAL, MAT_CREEP_GAROFALO, MAT_CREEP_PERZYNA
  PUBLIC :: MAT_CREEP_DUVAUT, MAT_CREEP_BODNER
  PUBLIC :: MAT_DMG_DUCTILE, MAT_DMG_SHEAR, MAT_DMG_BRITTLE
  PUBLIC :: MAT_DMG_FLD, MAT_DMG_CZM, MAT_DMG_CONCRETE
  PUBLIC :: MAT_COMP_CLT, MAT_COMP_HASHIN, MAT_COMP_FABRIC
  PUBLIC :: MAT_COMP_JOINTED, MAT_COMP_FOAM_VE
  PUBLIC :: MAT_HEAT_ISO, MAT_HEAT_ORTHO, MAT_HEAT_PHASE_CHG
  PUBLIC :: MAT_ACOUSTIC_LINEAR, MAT_ACOUSTIC_ABSORB
  PUBLIC :: MAT_USER_UMAT, MAT_USER_VUMAT
  PUBLIC :: PH_Mat_Kernel_Entry

  !--- Base definition types ---
  PUBLIC :: PH_MAT_MAX_NTENS
  PUBLIC :: PH_MAT_STRESS_STATE_3D, PH_MAT_STRESS_STATE_CPS, PH_MAT_STRESS_STATE_CPE, PH_MAT_STRESS_STATE_CAX
  PUBLIC :: PH_Mat_Update_Arg

  PUBLIC :: PH_Mat_Desc_Effective_Model

  !--- Standardized 4-step Execute pipeline (Phase 5C) ---
  PUBLIC :: PH_Mat_Execute_Flow
  PUBLIC :: PH_Mat_S1_FetchState
  PUBLIC :: PH_Mat_S2_Dispatch
  PUBLIC :: PH_Mat_S3_StressUpdate
  PUBLIC :: PH_Mat_S4_Tangent

END MODULE PH_Mat_Def


