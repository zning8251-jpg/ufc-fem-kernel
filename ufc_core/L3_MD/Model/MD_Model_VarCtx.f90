!===============================================================================
! MODULE:  MD_Model_VarCtx
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _VarCtx (variable context)
! BRIEF:   UF_ModelVarContext, Context_Model, Context_Model_State types
!          and all UF_ModelVar* / GetContext* / MV_* procedures.
!          Extracted from MD_Model_Lib per refactoring plan Step 4.
!===============================================================================
MODULE MD_Model_VarCtx
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Base_DP, ONLY: MD_MODEL_DATA_TYPE_DP, MD_MODEL_DATA_TYPE_INT
  USE IF_Mem_Mgr, ONLY: MemView1D_DP, BaseInfra_GetDataPtr
  USE MD_Base_Enums, ONLY: MD_MODEL_UF_MV_LOC_Node, MD_MODEL_UF_MV_LOC_ELEME, MD_MODEL_UF_MV_LOC_GLOBA, MD_MODEL_UF_MV_LOC_Step, &
      MD_MODEL_UF_MV_LOC_INCRE, MD_MODEL_UF_MV_LOC_CONTA
  USE MD_Base_FieldVarMgr, ONLY: InitVars, RegField, FindField
  USE MD_Base_ObjModel, ONLY: VarCtx
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC declarations (extracted from MD_Model_Lib)
    PUBLIC :: UF_ModelVarContext, Context_Model, Context_Model_State
    PUBLIC :: GetCurrentContext, GetReal1D, MV_GetContextOrUseCurrent, MV_GetCurrentContext, MV_GetReal1D
    PUBLIC :: UF_ModelVar_ClearCurrentContext, UF_ModelVarContext_RegisterScalar
    PUBLIC :: UF_ModelVar_InitContext, UF_ModelVar_RegisterField, UF_ModelVar_SetCurrentContext
    PUBLIC :: Context_Model_EnsureStorage

  !---------------------------------------------------------------------------
  ! Context_Model_State
  !---------------------------------------------------------------------------
    TYPE, PUBLIC :: Context_Model_State
        SEQUENCE
        INTEGER(i4) :: nStepsTotal = 0_i4
        INTEGER(i4) :: nStepsCompleted = 0_i4
        INTEGER(i4) :: nIncsTotal = 0_i4
        INTEGER(i4) :: nIncsConverged = 0_i4
        INTEGER(i4) :: totalNewtonIter = 0_i4
        INTEGER(i4) :: maxNewtonIter = 0_i4
        INTEGER(i4) :: totalLinearIter = 0_i4
        INTEGER(i4) :: maxLinearIter = 0_i4
    END TYPE Context_Model_State

  !---------------------------------------------------------------------------
  ! Context_Model
  !---------------------------------------------------------------------------
    TYPE, PUBLIC :: Context_Model
        SEQUENCE
        INTEGER(i4) :: model_id = 0_i4
        INTEGER(i4) :: step_id = 0_i4
        INTEGER(i4) :: inc_id = 0_i4
        TYPE(Context_Model_State) :: state
    CONTAINS
        PROCEDURE :: EnsureStorage => Context_Model_EnsureStorage
    END TYPE Context_Model

  !---------------------------------------------------------------------------
  ! UF_ModelVarContext
  !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ModelVarContext
        TYPE(VarCtx) :: ctx
    END TYPE UF_ModelVarContext

  ! Thread-local variable context storage
    TYPE(UF_ModelVarContext), SAVE :: tl_mv_ctx_
    LOGICAL, SAVE :: tl_mv_ctx_set_ = .FALSE.

CONTAINS

    SUBROUTINE Context_Model_EnsureStorage(this, status)
        CLASS(Context_Model), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE Context_Model_EnsureStorage

    SUBROUTINE GetCurrentContext(ctx, has_ctx)
        TYPE(UF_ModelVarContext), INTENT(OUT) :: ctx
        LOGICAL, INTENT(OUT) :: has_ctx
        has_ctx = tl_mv_ctx_set_
        IF (has_ctx) ctx = tl_mv_ctx_
    END SUBROUTINE GetCurrentContext

    SUBROUTINE GetReal1D(ctx, name, ptr, status)
        TYPE(UF_ModelVarContext), INTENT(IN) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: name
        REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, n
        CHARACTER(LEN=256) :: dp_name
        CALL init_error_status(status)
        ptr => NULL()
        idx = FindField(ctx%ctx, name)
        IF (idx <= 0) RETURN
        n = ctx%ctx%vars(idx)%dims(1)
        IF (n <= 0) RETURN
        dp_name = ctx%ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real1d=ptr, status=status)
    END SUBROUTINE GetReal1D

    SUBROUTINE MV_GetContextOrUseCurrent(ctx_out, has_ctx, override)
        TYPE(UF_ModelVarContext), INTENT(OUT) :: ctx_out
        LOGICAL, INTENT(OUT) :: has_ctx
        TYPE(UF_ModelVarContext), INTENT(IN), OPTIONAL :: override
        IF (PRESENT(override)) THEN
            has_ctx = .TRUE.
            ctx_out = override
        ELSE
            has_ctx = tl_mv_ctx_set_
            IF (has_ctx) ctx_out = tl_mv_ctx_
        END IF
    END SUBROUTINE MV_GetContextOrUseCurrent

    SUBROUTINE MV_GetCurrentContext(ctx, has_ctx)
        TYPE(UF_ModelVarContext), INTENT(OUT) :: ctx
        LOGICAL, INTENT(OUT) :: has_ctx
        has_ctx = tl_mv_ctx_set_
        IF (has_ctx) ctx = tl_mv_ctx_
    END SUBROUTINE MV_GetCurrentContext

    SUBROUTINE MV_GetReal1D(ctx, name, ptr, status)
        TYPE(UF_ModelVarContext), INTENT(IN) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: name
        REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL GetReal1D(ctx, name, ptr, status)
    END SUBROUTINE MV_GetReal1D

    SUBROUTINE UF_ModelVar_ClearCurrentContext()
        tl_mv_ctx_set_ = .FALSE.
    END SUBROUTINE UF_ModelVar_ClearCurrentContext

    SUBROUTINE UF_ModelVarContext_RegisterScalar(ctx, name, default_val, ierr)
        TYPE(UF_ModelVarContext), INTENT(INOUT) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: name
        REAL(wp), INTENT(IN) :: default_val
        INTEGER(i4), INTENT(OUT) :: ierr
        INTEGER(i4) :: dims(1)
        ierr = 0_i4
        dims(1) = 1_i4
        CALL RegField(ctx%ctx, name, MD_MODEL_UF_MV_LOC_GLOBA, MD_MODEL_DATA_TYPE_DP, 1_i4, dims)
    END SUBROUTINE UF_ModelVarContext_RegisterScalar

    SUBROUTINE UF_ModelVar_InitContext(ctx, model_name, max_vars)
        TYPE(UF_ModelVarContext), INTENT(INOUT) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: model_name
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_vars
        CALL InitVars(model_name, ctx%ctx, max_vars)
    END SUBROUTINE UF_ModelVar_InitContext

    SUBROUTINE UF_ModelVar_RegisterField(ctx, name, location, dType, rank, dims, is_persistent, ierr)
        TYPE(UF_ModelVarContext), INTENT(INOUT) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: location, dType, rank
        INTEGER(i4), INTENT(IN) :: dims(:)
        LOGICAL, INTENT(IN), OPTIONAL :: is_persistent
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: dims4(4), i
        IF (PRESENT(ierr)) ierr = 0_i4
        dims4 = 0_i4
        DO i = 1, MIN(rank, 4)
            dims4(i) = dims(i)
        END DO
        CALL RegField(ctx%ctx, name, location, dType, rank, dims4, is_persistent=.TRUE.)
    END SUBROUTINE UF_ModelVar_RegisterField

    SUBROUTINE UF_ModelVar_SetCurrentContext(ctx)
        TYPE(UF_ModelVarContext), INTENT(IN) :: ctx
        tl_mv_ctx_ = ctx
        tl_mv_ctx_set_ = .TRUE.
    END SUBROUTINE UF_ModelVar_SetCurrentContext

END MODULE MD_Model_VarCtx
