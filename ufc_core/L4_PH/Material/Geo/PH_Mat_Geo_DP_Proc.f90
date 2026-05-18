!===============================================================================
! MODULE: PH_Mat_Geo_DP_Proc
! Layer:  L4_PH / Material / Geo / Drucker–Prager
! Role:   Proc — thin SIO wrappers over PH_Mat_Geo_DP_Core (Principle #14).
!===============================================================================
MODULE PH_Mat_Geo_DP_Proc
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE PH_Mat_Geo_DP_Core, ONLY: PH_Mat_Geo_DP_Core_Init, PH_Mat_Geo_DP_Core_Update, &
                                PH_Mat_DP_Init_Arg, PH_Mat_DP_Update_Arg, &
                                PH_Mat_PLM_DP_State, PH_Mat_PLM_DP_Algo
  USE MD_Geo_DruckerPrager, ONLY: MD_Mat_DP_Desc
  USE PH_Mat_Aux_Def, ONLY: PH_Mat_Krnl_Ctx  ! formerly PH_Mat_Base_Ctx, renamed per R-09
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Geo_DP_Proc_Init
  PUBLIC :: PH_Mat_Geo_DP_Proc_Update

CONTAINS

  SUBROUTINE PH_Mat_Geo_DP_Proc_Init(desc, state, algo, ctx, args)
    TYPE(MD_Mat_DP_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_PLM_DP_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_PLM_DP_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Krnl_Ctx), INTENT(IN) :: ctx
    TYPE(PH_Mat_DP_Init_Arg), INTENT(INOUT) :: args

    CALL PH_Mat_Geo_DP_Core_Init(desc, state, algo, ctx, args)
  END SUBROUTINE PH_Mat_Geo_DP_Proc_Init

  SUBROUTINE PH_Mat_Geo_DP_Proc_Update(desc, state, algo, ctx, args)
    TYPE(MD_Mat_DP_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_PLM_DP_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_PLM_DP_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Krnl_Ctx), INTENT(IN) :: ctx
    TYPE(PH_Mat_DP_Update_Arg), INTENT(INOUT) :: args

    CALL PH_Mat_Geo_DP_Core_Update(desc, state, algo, ctx, args)
  END SUBROUTINE PH_Mat_Geo_DP_Proc_Update

END MODULE PH_Mat_Geo_DP_Proc

