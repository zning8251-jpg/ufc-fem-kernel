!===============================================================================
! MODULE: MD_ContRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Contact L3→L5 bridge
! BRIEF:  Re-export RT triplet/DOF-map and wrap RT_Triplet_Add / RT_GetEqId.
!===============================================================================


MODULE MD_ContRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Solv_Def, ONLY: RT_TripletList, RT_Triplet_Add, RT_Sol_DofMap
  USE RT_Asm_DofMapUtils, ONLY: RT_GetEqId
  IMPLICIT NONE
  PRIVATE
  
  ! --- Re-exported RT types ---
  PUBLIC :: RT_TripletList, RT_Sol_DofMap

  ! --- Bridge procedures ---
  
  PUBLIC :: MD_RT_Cont_TripletAdd
  PUBLIC :: MD_RT_Cont_GetEqId

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Cont_TripletAdd
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Add triplet to sparse matrix (bridge → RT_Triplet_Add)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Cont_TripletAdd(triplets, row, col, val)
    TYPE(RT_TripletList), INTENT(INOUT) :: triplets
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_Triplet_Add(triplets, row, col, val)
    
  END SUBROUTINE MD_RT_Cont_TripletAdd

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_RT_Cont_GetEqId
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get equation ID from DOF map (bridge → RT_GetEqId)
  !---------------------------------------------------------------------------
  FUNCTION MD_RT_Cont_GetEqId(dof_map, node_id, dof_type) RESULT(eq_id)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dof_map
    INTEGER(i4), INTENT(IN) :: node_id, dof_type
    INTEGER(i4) :: eq_id
    
    ! Bridge: Direct call to L5_RT function (same signature)
    eq_id = RT_GetEqId(dof_map, node_id, dof_type)
    
  END FUNCTION MD_RT_Cont_GetEqId

END MODULE MD_ContRT_Brg
