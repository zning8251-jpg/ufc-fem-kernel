!===============================================================================
! MODULE: PH_Brg_L3
! LAYER:  L4_PH
! DOMAIN: Bridge
! ROLE:   Brg
! BRIEF:  L4->L3 bridge (material response, element state, thin assembly glue)
!
! G4-FIX: PH_Brg_ElementStiffAssembly DEPRECATED; use PH_Elem_Domain_Desc%Compute_Ke
! Contract: Bridge/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Bridge | Role:Brg_L3 | FuncSet:Query+ThinGlue
!>>> UFC_PH_CONTRACT | Bridge/CONTRACT.md

MODULE PH_Brg_L3
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatDesc
  USE MD_Mat_Def, ONLY: MD_MAT_DESC_PROPS_MAX
  USE MD_Model_Def, ONLY: MD_Model_Desc
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  USE MD_Model_Access, ONLY: MD_Model_Access_GetMaterial
  USE MD_GeomPH_Brg, ONLY: MD_PH_Geom_FillElemCtx_Idx, MD_PH_Geom_FillElemCtx_Arg
  USE MD_Mesh_API, ONLY: MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Brg_Elem_StiffAsm_Arg
  PUBLIC :: PH_Brg_UpdateElemState_Arg
  PUBLIC :: PH_Brg_GetMatResp_Arg
  ! Note: PH_Brg_ElemStateUpdate_Desc, PH_Brg_MatId_Desc are L3-local types
  ! (distinct from PH_Brg_Def.f90 placeholders which are empty stubs)
  PUBLIC :: PH_BrgL3_ElemStateUpdate_Desc, PH_BrgL3_MatId_Desc
  PUBLIC :: PH_Brg_ElementStiffAssembly, PH_Brg_ElementStiffAssembly_Idx
  PUBLIC :: PH_Brg_UpdateElementState, PH_Brg_UpdateElementState_Idx
  PUBLIC :: PH_Brg_GetMaterialResponse, PH_Brg_GetMaterialResponse_Idx
  PUBLIC :: PH_Brg_GetAmplitudeValue_Idx, PH_Brg_GetNodeCoords_Idx

  TYPE, PUBLIC :: PH_BrgL3_ElemStateUpdate_Desc
    INTEGER(i4) :: elem_id = 0
    REAL(wp), ALLOCATABLE :: stress(:,:)
    REAL(wp), ALLOCATABLE :: strain(:,:)
  END TYPE PH_BrgL3_ElemStateUpdate_Desc

  TYPE, PUBLIC :: PH_BrgL3_MatId_Desc
    INTEGER(i4) :: mat_id = 0
  END TYPE PH_BrgL3_MatId_Desc

  TYPE, PUBLIC :: PH_Brg_Elem_StiffAsm_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx                   ! [IN]
    INTEGER(i4) :: elem_idx = 0_i4                ! [IN]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_Elem_StiffAsm_Arg

  TYPE, PUBLIC :: PH_Brg_UpdateElemState_Arg
    TYPE(MD_Model_Desc) :: model                            ! [IN]
    INTEGER(i4) :: elem_id                          ! [IN]
    REAL(wp), ALLOCATABLE :: stress(:,:)           ! [IN]
    REAL(wp), ALLOCATABLE :: strain(:,:)           ! [IN]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_UpdateElemState_Arg

  TYPE, PUBLIC :: PH_Brg_GetMatResp_Arg
    TYPE(MD_Model_Desc) :: model                            ! [IN]
    INTEGER(i4) :: mat_id                           ! [IN]
    REAL(wp), ALLOCATABLE :: response(:)           ! [OUT]
    INTEGER(i4) :: n_props_filled = 0_i4           ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetMatResp_Arg

CONTAINS

  SUBROUTINE PH_Brg_ElementStiffAssembly(arg)
    TYPE(PH_Brg_Elem_StiffAsm_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%status%status_code = IF_STATUS_INVALID
    arg%status%message = &
      "PH_Brg_ElementStiffAssembly DEPRECATED (G4): " // &
      "migrate caller to PH_Elem_Domain_Desc%Compute_Ke"
  END SUBROUTINE PH_Brg_ElementStiffAssembly

  SUBROUTINE PH_Brg_GetMaterialResponse(arg)
    TYPE(PH_Brg_GetMatResp_Arg), INTENT(INOUT) :: arg
    TYPE(MatDesc), POINTER :: mat_ptr
    INTEGER(i4) :: n_props, n_copy
    CALL init_error_status(arg%status)
    arg%n_props_filled = 0_i4
    mat_ptr => MD_Model_Access_GetMaterial(arg%model, material_id=arg%mat_id, status=arg%status)
    IF (.NOT. ASSOCIATED(mat_ptr)) THEN
      IF (arg%status%status_code == IF_STATUS_OK) arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. ALLOCATED(mat_ptr%props)) THEN
      IF (ALLOCATED(arg%response)) DEALLOCATE(arg%response)
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    n_props = SIZE(mat_ptr%props)
    IF (n_props > MD_MAT_DESC_PROPS_MAX) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Brg_GetMaterialResponse: props length exceeds MD_MAT_DESC_PROPS_MAX"
      RETURN
    END IF
    n_copy = n_props
    IF (ALLOCATED(arg%response)) THEN
      IF (SIZE(arg%response) < n_copy) THEN
        DEALLOCATE(arg%response)
        ALLOCATE(arg%response(n_copy))
      END IF
    ELSE
      ALLOCATE(arg%response(n_copy))
    END IF
    arg%response(1:n_copy) = mat_ptr%props(1:n_copy)
    arg%n_props_filled = n_copy
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_GetMaterialResponse

  SUBROUTINE PH_Brg_UpdateElementState(arg)
    TYPE(PH_Brg_UpdateElemState_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_UpdateElementState

  SUBROUTINE PH_Brg_GetMaterialResponse_Idx(mat_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: mat_idx
    TYPE(PH_Brg_GetMatResp_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Mat_GetDesc_Arg) :: arg_mat
    INTEGER(i4) :: n_props, n_copy
    CALL init_error_status(status)
    arg%status = status
    arg%n_props_filled = 0_i4
    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "g_ufc_global not ready"
      arg%status = status
      RETURN
    END IF
    CALL MD_Mat_GetDesc_Idx(mat_idx, arg_mat, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      arg%status = status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg_mat%desc%props)) THEN
      IF (ALLOCATED(arg%response)) DEALLOCATE(arg%response)
      status%status_code = IF_STATUS_OK
      arg%status = status
      RETURN
    END IF
    n_props = SIZE(arg_mat%desc%props)
    IF (n_props > MD_MAT_DESC_PROPS_MAX) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Brg_GetMaterialResponse_Idx: props length exceeds MD_MAT_DESC_PROPS_MAX"
      arg%status = status
      RETURN
    END IF
    n_copy = n_props
    IF (ALLOCATED(arg%response)) THEN
      IF (SIZE(arg%response) < n_copy) THEN
        DEALLOCATE(arg%response)
        ALLOCATE(arg%response(n_copy))
      END IF
    ELSE
      ALLOCATE(arg%response(n_copy))
    END IF
    arg%response(1:n_copy) = arg_mat%desc%props(1:n_copy)
    arg%n_props_filled = n_copy
    status%status_code = IF_STATUS_OK
    arg%status = status
  END SUBROUTINE PH_Brg_GetMaterialResponse_Idx

  SUBROUTINE PH_Brg_UpdateElementState_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(PH_Brg_UpdateElemState_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    arg%status = status
    IF (elem_idx < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid elem_idx"
      arg%status = status
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
    arg%status = status
  END SUBROUTINE PH_Brg_UpdateElementState_Idx

  SUBROUTINE PH_Brg_GetAmplitudeValue_Idx(amp_ref, time, value, status)
    INTEGER(i4), INTENT(IN) :: amp_ref
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(OUT) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    value = 1.0_wp
    IF (amp_ref < 1) RETURN
    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "g_ufc_global not ready"
      RETURN
    END IF
    IF (.NOT. g_ufc_global%md_layer%amplitude%initialized) RETURN
    CALL g_ufc_global%md_layer%amplitude%EvalAtTime(amp_ref, time, value, status)
    IF (status%status_code /= IF_STATUS_OK) value = 1.0_wp
  END SUBROUTINE PH_Brg_GetAmplitudeValue_Idx

  SUBROUTINE PH_Brg_GetNodeCoords_Idx(node_idx, coords, status)
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(OUT) :: coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    CALL init_error_status(status)
    coords = 0.0_wp
    CALL MD_Mesh_GetNodeCoords_Idx(node_idx, arg_coords, status)
    IF (status%status_code == IF_STATUS_OK) coords = arg_coords%coords
  END SUBROUTINE PH_Brg_GetNodeCoords_Idx

  SUBROUTINE PH_Brg_ElementStiffAssembly_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(PH_Brg_Elem_StiffAsm_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PH_Brg_Elem_StiffAsm_Arg) :: work
    CALL init_error_status(status)
    ! Legacy Idx path only supplied elem_idx; elem_ctx stayed default-initialized.
    work%elem_idx = elem_idx
    CALL PH_Brg_ElementStiffAssembly(work)
    arg%status = work%status
    status = arg%status
  END SUBROUTINE PH_Brg_ElementStiffAssembly_Idx
END MODULE PH_Brg_L3