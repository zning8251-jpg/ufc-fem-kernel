!===============================================================================
! MODULE: IF_ThreadWS_Brg
! LAYER:  L1_IF
! DOMAIN: Parallel
! ROLE:   Brg — thin adapter API for thread workspace management
! BRIEF:  Re-exports ThreadWS types + Init/Destroy/GetLocalArray/Atomic/Critical.
!===============================================================================

MODULE IF_ThreadWS_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE IF_ThreadWS_Def, ONLY: ThreadWS, ThreadWorkspace, &
                               MAX_THREADS, MAX_ARRAYS_PER_THREAD
  USE IF_ThreadWS_Mgr, ONLY: IF_ThreadWS_Init, IF_ThreadWS_Destroy, &
                              IF_ThreadWS_GetLocalArray, IF_ThreadWS_AggregateReal1D, &
                              IF_ThreadWS_AtomicAdd, IF_ThreadWS_AtomicAddInt, &
                              IF_ThreadWS_EnterCritical, IF_ThreadWS_ExitCritical, &
                              IF_ThreadWS_SetCurrentThread, IF_ThreadWS_GetCurrentThread, &
                              ThreadWSCriticalSection
  
  IMPLICIT NONE
  
  PRIVATE
  
  ! Re-export types
  PUBLIC :: ThreadWS, ThreadWorkspace, ThreadWSCriticalSection
  PUBLIC :: MAX_THREADS, MAX_ARRAYS_PER_THREAD
  
  ! Re-export initialization
  PUBLIC :: IF_ThreadWS_Init
  PUBLIC :: IF_ThreadWS_Destroy
  
  ! Re-export workspace access
  PUBLIC :: IF_ThreadWS_GetLocalArray  ! [REMOVED] ThreadWS_GetLocalArray alias — L4 callers migrated to IF_ThreadWS_GetLocalArray
  PUBLIC :: IF_ThreadWS_AggregateReal1D
  
  ! Re-export parallel primitives
  PUBLIC :: IF_ThreadWS_AtomicAdd
  PUBLIC :: IF_ThreadWS_AtomicAddInt
  PUBLIC :: IF_ThreadWS_EnterCritical
  PUBLIC :: IF_ThreadWS_ExitCritical
  
  ! Re-export thread management
  PUBLIC :: IF_ThreadWS_SetCurrentThread
  PUBLIC :: IF_ThreadWS_GetCurrentThread
  
  ! Alternative interfaces
  PUBLIC :: ThreadWS_AllocLocal, ThreadWS_FreeLocal
  
  ! [REMOVED] ThreadWS_GetLocalArray alias interface — callers migrated to IF_ThreadWS_GetLocalArray
  
CONTAINS

  !====================================================================
  ! Convenience Functions
  !====================================================================
  
  SUBROUTINE ThreadWS_AllocLocal(thread_ws, thread_id, array_name, &
                                 array_size, status)
    !! Allocate and register a named local array in thread workspace (STUB)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    CHARACTER(LEN=*), INTENT(IN) :: array_name
    INTEGER(i4), INTENT(IN) :: array_size
    INTEGER(i4), INTENT(OUT) :: status
    
    ! STUB: Implementation requires fixing thread pointer assignment
    status = -99
    
  END SUBROUTINE ThreadWS_AllocLocal
  
  SUBROUTINE ThreadWS_FreeLocal(thread_ws, thread_id, array_name, status)
    !! Free and unregister a named local array (STUB)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    CHARACTER(LEN=*), INTENT(IN) :: array_name
    INTEGER(i4), INTENT(OUT) :: status
    
    ! STUB: Implementation requires fixing thread pointer assignment
    status = -99
    
  END SUBROUTINE ThreadWS_FreeLocal
  
END MODULE IF_ThreadWS_Brg
