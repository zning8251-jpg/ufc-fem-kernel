!===============================================================================
! MODULE: MD_ElemPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — Element L3→L4 bridge
! BRIEF:  Bridge element computation from L3_MD to L4_PH.
!===============================================================================

MODULE MD_ElemPH_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
  USE MD_GeomPH_Brg, ONLY: MD_PH_Geom_FillElemCtx_Idx, MD_PH_Geom_FillElemCtx_Arg
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  USE PH_ElemContm_Ops, ONLY: Calc_Continuum2D, Calc_Continuum3D
  USE PH_Elem_Contm_Brg, ONLY: CompPoro, CompThm, CompTHM
  USE PH_Elem_Porous, ONLY: Calc_Pore_Saturated, Calc_Pore_TwoPhase
  USE PH_Elem_Thermal_Def, ONLY: UF_Elem_Therm_Calc
  IMPLICIT NONE
  PRIVATE
  !---------------------------------------------------------------------------
  ! TYPE: MD_PH_Elem_GetElemCtx_Arg
  ! KIND: Arg
  ! DESC: Arg bundle for MD_PH_Elem_GetElemCtx_Idx (Phase 4 Bridge)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_PH_Elem_GetElemCtx_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx
  END TYPE MD_PH_Elem_GetElemCtx_Arg
  PUBLIC :: MD_PH_Elem_CalcContinuum2D
  PUBLIC :: MD_PH_Elem_CalcContinuum3D
  PUBLIC :: MD_PH_Elem_CalcPoro
  PUBLIC :: MD_PH_Elem_CalcPoroSaturated
  PUBLIC :: MD_PH_Elem_CalcPoroTwoPhase
  PUBLIC :: MD_PH_Elem_CalcThermal
  PUBLIC :: MD_PH_Elem_CalcThm
  PUBLIC :: MD_PH_Elem_CalcTHM
  PUBLIC :: MD_PH_Elem_GetElemCtx_Idx
  PUBLIC :: MD_PH_Elem_GetElemCtx_Arg

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_GetElemCtx_Idx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get element context by index (delegates to Geom bridge)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_GetElemCtx_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(MD_PH_Elem_GetElemCtx_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_PH_Geom_FillElemCtx_Arg) :: geom_arg
    CALL MD_PH_Geom_FillElemCtx_Idx(elem_idx, geom_arg)
    arg%elem_ctx = geom_arg%elem_ctx
    status = geom_arg%status
  END SUBROUTINE MD_PH_Elem_GetElemCtx_Idx

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcContinuum2D
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge 2D continuum element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcContinuum2D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL Calc_Continuum2D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcContinuum2D

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcContinuum3D
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge 3D continuum element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcContinuum3D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL Calc_Continuum3D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcContinuum3D

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcPoroSaturated
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge saturated porous element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcPoroSaturated(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcPoroSaturated

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcPoroTwoPhase
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge two-phase porous element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcPoroTwoPhase(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL Calc_Pore_TwoPhase(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcPoroTwoPhase

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcThermal
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge thermal element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcThermal(ElemType, Formul, Ctx, state_in, Mat, state_out, flags, status)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    USE IF_Err_Brg, ONLY: ErrorStatusType
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: Mat
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL UF_Elem_Therm_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags, status)
    
  END SUBROUTINE MD_PH_Elem_CalcThermal

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcTHM
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge THM coupled element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcTHM(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL CompTHM(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcTHM

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcPoro
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge poro element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcPoro(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL CompPoro(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcPoro

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Elem_CalcThm
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Bridge thermal-structural element calc to L4_PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Elem_CalcThm(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags
    
    ! Bridge: Direct call to L4_PH function (same signature)
    CALL CompThm(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    
  END SUBROUTINE MD_PH_Elem_CalcThm

END MODULE MD_ElemPH_Brg
