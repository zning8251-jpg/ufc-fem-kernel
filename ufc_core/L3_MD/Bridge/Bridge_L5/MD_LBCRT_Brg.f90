!===============================================================================
! MODULE: MD_LBCRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — LoadBC L3→L5 bridge
! BRIEF:  Re-export ThreadWS/DofMap/CSR and wrap thread-WS / eq-ID helpers.
!===============================================================================


MODULE MD_LBCRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Step_WS, ONLY: ThreadWS
  USE RT_Base_Sys, ONLY: UF_WS_GetCurrentThreadWorkspacePtr, ThreadWS_GetBCWorkspace
  USE RT_Asm_DofMapUtils, ONLY: UF_GetEqId, UF_GetEqIdByDofType
  USE RT_Solv_Def, ONLY: RT_Sol_DofMap, RT_CSRMatrix
  IMPLICIT NONE
  PRIVATE
  
  ! --- Re-exported RT types ---
  PUBLIC :: ThreadWS, RT_Sol_DofMap, RT_CSRMatrix

  ! --- Bridge procedures ---
  
  PUBLIC :: MD_RT_LoadBC_GetBCWorkspace
  PUBLIC :: MD_RT_LoadBC_GetEqId
  PUBLIC :: MD_RT_LoadBC_GetEqIdByDofType
  PUBLIC :: MD_RT_LoadBC_GetThreadWS
  ! Re-export RT_Base_Sys functions for convenience
  PUBLIC :: UF_WS_GetCurrentThreadWorkspacePtr, ThreadWS_GetBCWorkspace

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_LoadBC_GetBCWorkspace
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get BC workspace from thread workspace (bridge → RT).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_LoadBC_GetBCWorkspace(thread_ws, nDOF, nFreeDOF, maxNodes, &
                                       bc_map, bc_F_ff, bc_row_nnz, &
                                       bc_coords, bc_localNodes)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: nDOF, nFreeDOF, maxNodes
    INTEGER(i4), POINTER, INTENT(OUT) :: bc_map(:)
    REAL(wp), POINTER, INTENT(OUT) :: bc_F_ff(:)
    INTEGER(i4), POINTER, INTENT(OUT) :: bc_row_nnz(:)
    REAL(wp), POINTER, INTENT(OUT), OPTIONAL :: bc_coords(:,:)
    INTEGER(i4), POINTER, INTENT(OUT), OPTIONAL :: bc_localNodes(:)

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL ThreadWS_GetBCWorkspace(thread_ws, nDOF, nFreeDOF, maxNodes, &
                                  bc_map, bc_F_ff, bc_row_nnz, &
                                  bc_coords, bc_localNodes)

  END SUBROUTINE MD_RT_LoadBC_GetBCWorkspace

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_RT_LoadBC_GetEqId
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get equation ID from DOF map (bridge → UF_GetEqId).
  !---------------------------------------------------------------------------
  FUNCTION MD_RT_LoadBC_GetEqId(dof_map, node_id, dof_type) RESULT(eq_id)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dof_map
    INTEGER(i4), INTENT(IN) :: node_id, dof_type
    INTEGER(i4) :: eq_id

    ! Bridge: Direct call to L5_RT function (same signature)
    eq_id = UF_GetEqId(dof_map, node_id, dof_type)

  END FUNCTION MD_RT_LoadBC_GetEqId

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_RT_LoadBC_GetEqIdByDofType
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get equation ID by DOF type (bridge → UF_GetEqIdByDofType).
  !---------------------------------------------------------------------------
  FUNCTION MD_RT_LoadBC_GetEqIdByDofType(model, dof_map, node_id, dof_type) RESULT(eq_id)
    USE MD_Model_Lib_Core, ONLY: UF_Model
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dof_map
    INTEGER(i4), INTENT(IN) :: node_id, dof_type
    INTEGER(i4) :: eq_id

    ! Bridge: Direct call to L5_RT function (same signature)
    eq_id = UF_GetEqIdByDofType(model, dof_map, node_id, dof_type)

  END FUNCTION MD_RT_LoadBC_GetEqIdByDofType

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_RT_LoadBC_GetThreadWS
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get current thread workspace pointer (bridge → RT).
  !---------------------------------------------------------------------------
  FUNCTION MD_RT_LoadBC_GetThreadWS() RESULT(thread_ws)
    TYPE(ThreadWS), POINTER :: thread_ws

    ! Bridge: Direct call to L5_RT function (same signature)
    thread_ws => UF_WS_GetCurrentThreadWorkspacePtr()

  END FUNCTION MD_RT_LoadBC_GetThreadWS

END MODULE MD_LBCRT_Brg
