!===============================================================================
! MODULE: MD_MatPLM_PlastBase
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Dispatch
! DEPRECATED: 2026-05-08 — R-09 Base suffix removed; module not USE'd by any file.
!   All re-exported symbols are accessible via MD_Mat_Plast_Reg or direct USE.
! BRIEF:  Plastic family unified dispatch facade -- re-exports PlastModels_Desc,
!         UF_Plastic_*Reg, and family ID constants for upstream consumers.
!         **W1**：**PlastModels_Desc** / 注册 API 的上游聚合；金线塑性子求值见
!         **`MD_MatPLM_PlastCall`** / **`UF_Plastic_Eval_Dispatch_FromDesc`**（**MD_Mat_Desc** +
!         **props**），本模块不替代 **Populate** 填 **props**。
!===============================================================================
MODULE MD_Mat_Plast_Dispatch_Base
  USE MD_Mat_Plast_Reg, ONLY: &
      MD_MAT_PLAST_MAX_PROPS, &
      PlastMat_GetInfo_In, &
      PlastMat_GetInfo_Out, &
      PlastMatInfo, &
      PlastModels_Desc, &
      UF_Plastic_GetMaterialInfo, &
      UF_Plastic_InitReg, &
      UF_Plastic_RegAllMats, &
      UF_Plastic_RegisterMaterial, &
      UF_Plastic_ValidMatID, &
      MD_MAT_VONMISES_MAT_ID, &
      MD_MAT_VONMISES_MAT_NA, &
      MD_MAT_CDP, &
      MD_MAT_DRUCKERPRAGER_M, MD_MAT_DRUCKERPRAGER_M_NAME, &
      MD_MAT_CAMCLAY_MAT_ID, MD_MAT_CAMCLAY_MAT_NAME, &
      MD_MAT_MOHRCOULOMB_MAT, MD_MAT_MOHRCOULOMB_MAT_NAME, &
      MD_MAT_GURSON_MAT_ID, MD_MAT_GURSON_MAT_NAME, &
      MD_MAT_VISCOPLASTIC_MAT_ID, MD_MAT_VISCOPLASTIC_MAT_NAME, &
      MD_MAT_SOFTROCK_MAT_ID, SOFTROCK_MAT_NA, &
      MD_MAT_CAP_PLASTICITY, CAP_PLASTICITY_NAME, &
      MD_MAT_CRUSHOAM_MAT_ID, &
      MD_MAT_BIVISC_MAT_ID, &
      MD_MAT_CAST_IRON_MAT_I, MD_MAT_CAST_IRON_MAT_N
  USE MD_Mat_Plast_Contract, ONLY: &
      ComputeDeviatoricStress_In, ComputeDeviatoricStress_Out, &
      ComputeFlowDirection_In, ComputeFlowDirection_Out, &
      MD_MAT_PLASTIC_CAM_CLA, MD_MAT_PLASTIC_CHABOCH, MD_MAT_PLASTIC_DRUCKER, MD_MAT_PLASTIC_GURSON, &
      MD_MAT_PLASTIC_HILL, MD_MAT_PLASTIC_JOHNSON, MD_MAT_PLASTIC_MOHR_CO, MD_MAT_PLASTIC_VON_MIS, &
      PlastFlowRule, PlastHardeningRule, PlastMatBase, PlastStateVariables
  USE MD_Mat_Plast_JohnsonCook, ONLY: MD_MAT_JOHNSONCOOK_MAT, MD_MAT_JOHNSONCOOK_MAT_NAME
  USE MD_Mat_Plast_Chaboche, ONLY: MD_MAT_CHABOCHE_MAT_ID
  USE MD_Mat_Plast_Hill, ONLY: MD_MAT_HILL_MAT_ID, MD_MAT_HILL_MAT_NAME
  USE MD_Mat_Plast_J2, ONLY: UF_VonMises_ValidateProps, UF_VonMises_GetStatistics
  USE MD_Mat_Plast_RateDep, ONLY: MD_MAT_RATE_DEPENDENT_PLAST_MAT_ID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: ComputeDeviatoricStress_In, ComputeDeviatoricStress_Out
  PUBLIC :: ComputeFlowDirection_In, ComputeFlowDirection_Out
  PUBLIC :: MD_MAT_PLASTIC_CAM_CLA, MD_MAT_PLASTIC_CHABOCH, MD_MAT_PLASTIC_DRUCKER, MD_MAT_PLASTIC_GURSON
  PUBLIC :: MD_MAT_PLASTIC_HILL, MD_MAT_PLASTIC_JOHNSON, MD_MAT_PLASTIC_MOHR_CO, MD_MAT_PLASTIC_VON_MIS
  PUBLIC :: PlastFlowRule, PlastHardeningRule, PlastMatBase, PlastStateVariables
  PUBLIC :: MD_MAT_MOHRCOULOMB_MAT, MD_MAT_MOHRCOULOMB_MAT_NAME
  PUBLIC :: MD_MAT_DRUCKERPRAGER_M, MD_MAT_DRUCKERPRAGER_M_NAME
  PUBLIC :: MD_MAT_CHABOCHE_MAT_ID
  PUBLIC :: MD_MAT_CAMCLAY_MAT_ID, MD_MAT_CAMCLAY_MAT_NAME
  PUBLIC :: MD_MAT_CAP_PLASTICITY, CAP_PLASTICITY_NAME
  PUBLIC :: MD_MAT_CAST_IRON_MAT_I, MD_MAT_CAST_IRON_MAT_N
  PUBLIC :: MD_MAT_HILL_MAT_ID, MD_MAT_HILL_MAT_NAME
  PUBLIC :: MD_MAT_JOHNSONCOOK_MAT, MD_MAT_JOHNSONCOOK_MAT_NAME
  PUBLIC :: MD_MAT_RATE_DEPENDENT_PLAST_MAT_ID
  PUBLIC :: MD_MAT_SOFTROCK_MAT_ID, SOFTROCK_MAT_NA
  PUBLIC :: MD_MAT_VISCOPLASTIC_MAT_ID, MD_MAT_VISCOPLASTIC_MAT_NAME
  PUBLIC :: MD_MAT_GURSON_MAT_ID, MD_MAT_GURSON_MAT_NAME
  PUBLIC :: MD_MAT_CRUSHOAM_MAT_ID
  PUBLIC :: MD_MAT_BIVISC_MAT_ID
  PUBLIC :: UF_Plastic_GetMaterialInfo
  PUBLIC :: UF_Plastic_ValidMatID
  PUBLIC :: UF_Plastic_RegisterMaterial
  PUBLIC :: UF_Plastic_InitReg
  PUBLIC :: UF_Plastic_RegAllMats
  PUBLIC :: PlastModels_Desc
  PUBLIC :: MD_MAT_PLAST_MAX_PROPS
  PUBLIC :: PlastMatInfo
  PUBLIC :: PlastMat_GetInfo_In
  PUBLIC :: PlastMat_GetInfo_Out
  PUBLIC :: MD_MAT_CDP
  PUBLIC :: UF_VonMises_ValidateProps
  PUBLIC :: MD_MAT_VONMISES_MAT_ID, MD_MAT_VONMISES_MAT_NA
  PUBLIC :: UF_VonMises_GetStatistics

END MODULE MD_Mat_Plast_Dispatch_Base