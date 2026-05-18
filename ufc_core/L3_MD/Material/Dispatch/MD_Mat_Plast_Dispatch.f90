!===============================================================================
! MODULE: MD_MatPLM_PlastCall
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Plastic dispatch entry points that pack **MD_Mat_Desc** into
!         **PlastModels_Desc** and forward to L4 **UF_Plastic_Eval_Dispatch**.
! **W1**：**cfg/pop** + **`desc%props`** 为 SSOT；**`material_id`** 与 **`MD_Mat_ValidatePropsForPopulate`**
!         塑性支路一致；**`MD_Mat_Lib`** 再导出 **`UF_Plastic_Eval_Dispatch_FromDesc`**。
!===============================================================================
MODULE MD_Mat_Plast_Dispatch
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, init_error_status
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_Mat_Desc_SyncDeprecatedFlat, MD_MAT_CATEGORY_PL
  USE MD_Mat_Eval_Types, ONLY: MatEval_Ctx, MatAlgo_Algo
  USE PH_MatPLMEval, ONLY: UF_Plastic_Eval_Dispatch
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_Plastic_Eval_Dispatch_FromDesc

CONTAINS

  SUBROUTINE UF_Plastic_Eval_Dispatch_FromDesc(desc, ctx, algo, status)
    TYPE(MD_Mat_Desc), INTENT(INOUT) :: desc
    TYPE(MatEval_Ctx), INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo), INTENT(IN) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PlastModels_Desc) :: plast_desc
    INTEGER(i4) :: material_id, eff_class, np, nprops_eff, k
    INTEGER(i4), PARAMETER :: MD_MAT_PLAST_ID_LO = 201_i4, MD_MAT_PLAST_ID_HI = 299_i4

    CALL init_error_status(status)
    CALL MD_Mat_Desc_SyncDeprecatedFlat(desc)

    eff_class = desc%cfg%class_id
    IF (eff_class == 0_i4) eff_class = desc%class_id

    material_id = desc%cfg%id
    IF (material_id <= 0_i4) material_id = desc%id

    IF (eff_class == MD_MAT_CATEGORY_PL) THEN
      IF (material_id < MD_MAT_PLAST_ID_LO .OR. material_id > MD_MAT_PLAST_ID_HI) material_id = MD_MAT_VONMISES_MAT_ID
    ELSE IF (eff_class /= 0_i4) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = '[UF_Plastic_Eval_Dispatch_FromDesc] material category is not plastic'
      RETURN
    ELSE
      IF (material_id < MD_MAT_PLAST_ID_LO .OR. material_id > MD_MAT_PLAST_ID_HI) THEN
        status%status_code = MD_MAT_STATUS_NOT_FOUND
        status%message = '[UF_Plastic_Eval_Dispatch_FromDesc] cannot infer plastic material_id'
        RETURN
      END IF
    END IF

    IF (.NOT. ALLOCATED(desc%props)) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = '[UF_Plastic_Eval_Dispatch_FromDesc] desc%props not allocated'
      RETURN
    END IF

    nprops_eff = desc%pop%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = desc%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = INT(SIZE(desc%props), KIND=i4)
    np = MIN(nprops_eff, INT(SIZE(desc%props), KIND=i4), MD_MAT_PLAST_MAX_PROPS)
    IF (np < 1_i4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = '[UF_Plastic_Eval_Dispatch_FromDesc] empty props'
      RETURN
    END IF

    plast_desc%nprops = np
    plast_desc%props = 0.0_wp
    DO k = 1, np
      plast_desc%props(k) = desc%props(k)
    END DO

    CALL UF_Plastic_Eval_Dispatch(material_id, plast_desc, ctx, algo, status)
  END SUBROUTINE UF_Plastic_Eval_Dispatch_FromDesc

END MODULE MD_Mat_Plast_Dispatch
