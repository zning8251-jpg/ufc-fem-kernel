!===============================================================================
! MODULE: MD_ElemRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Element L3→L5 bridge
! BRIEF:  Forward element computation to L5_RT dispatcher.
!===============================================================================


MODULE MD_ElemRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx
  ! RT_Elem_Core eliminated (thin wrapper) - use RT_ElemDispatcher directly
  USE RT_Elem_Dispatcher, ONLY: RT_Elem_Dispatcher_Run => RT_Elem_Dispatcher_Run
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_RT_Elem_Comp
  PUBLIC :: MD_RT_Elem_Comp_Idx
  PUBLIC :: MD_RT_Elem_Comp_Idx_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_RT_Elem_Comp_Idx_Arg
  ! KIND: Arg
  ! DESC: Argument bundle for index-based element compute bridge call.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_RT_Elem_Comp_Idx_Arg
    TYPE(UF_ElemType)    :: ElemType
    TYPE(UF_ElemFormul)  :: Formul
    TYPE(UF_ElemCtx)     :: Ctx
    TYPE(ErrorStatusType) :: status
  END TYPE MD_RT_Elem_Comp_Idx_Arg

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Elem_Comp_Idx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Index-based element compute via PH context → RT dispatcher.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Elem_Comp_Idx(elem_idx, arg, status)
    USE MD_ElemPH_Brg, ONLY: MD_PH_Elem_GetElemCtx_Idx, MD_PH_Elem_GetElemCtx_Arg
    USE MD_Elem_Base, ONLY: UF_Form_UL, UF_Int_Full
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(MD_RT_Elem_Comp_Idx_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_PH_Elem_GetElemCtx_Arg) :: ph_arg
    INTEGER(i4) :: n_dim, n_nodes, n_gp

    CALL init_error_status(status)
    CALL MD_PH_Elem_GetElemCtx_Idx(elem_idx, ph_arg, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    n_nodes = ph_arg%elem_ctx%pop%n_nodes
    n_dim = ph_arg%elem_ctx%n_dim
    n_gp = MAX(ph_arg%elem_ctx%n_gauss, 2_i4)
    IF (n_nodes <= 0_i4 .OR. n_dim <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_RT_Elem_Comp_Idx: Invalid elem_ctx n_nodes/n_dim"
      arg%status = status
      RETURN
    END IF

    ! PH_Elem_Ctx -> UF_ElemCtx conversion
    CALL arg%Ctx%Init(id=ph_arg%elem_ctx%element_id, ElemType=ph_arg%elem_ctx%element_type, &
         numNodes=n_nodes, numIntPoints=n_gp)
    IF (ALLOCATED(ph_arg%elem_ctx%coords)) THEN
      IF (.NOT. ALLOCATED(arg%Ctx%coords_ref)) ALLOCATE(arg%Ctx%coords_ref(n_dim, n_nodes))
      arg%Ctx%coords_ref(1:n_dim, 1:n_nodes) = ph_arg%elem_ctx%coords(1:n_dim, 1:n_nodes)
      IF (.NOT. ALLOCATED(arg%Ctx%coords_prev)) ALLOCATE(arg%Ctx%coords_prev(n_dim, n_nodes))
      arg%Ctx%coords_prev(1:n_dim, 1:n_nodes) = ph_arg%elem_ctx%coords(1:n_dim, 1:n_nodes)
    END IF

    ! Default ElemType and Formul for continuum
    arg%ElemType%pop%n_nodes = n_nodes
    arg%Formul%nIntPoints = n_gp
    arg%Formul%integration_scheme = UF_Int_Full
    arg%Formul%kineFormulation = UF_Form_UL

    status%status_code = IF_STATUS_OK
    status%message = ""
    arg%status = status
  END SUBROUTINE MD_RT_Elem_Comp_Idx

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Elem_Comp
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Calculate element using RT layer (bridge → RT_Elem_Dispatcher).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Elem_Comp(ElemType, Formul, Ctx, state_in, Mat, state_out, flags, status)
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
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_Elem_Comp(ElemType, Formul, Ctx, state_in, Mat, state_out, flags, status)
    
  END SUBROUTINE MD_RT_Elem_Comp

END MODULE MD_ElemRT_Brg
