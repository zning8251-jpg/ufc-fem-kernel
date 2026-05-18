!===============================================================================
! MODULE: IF_Mem_Algo
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Phase6 Track21 — algorithm / Populate-time scratch allocation facade.
! BRIEF:  Thin wrappers over IF_Mem_Mgr so L4 Populate can avoid raw ALLOCATE
!         at call sites incrementally. Full slot TYPE migration stays separate.
!===============================================================================
MODULE IF_Mem_Algo
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, IF_MEM_DOMAIN_MAT
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: IF_Mem_Algo_Scratch_Real1D
  PUBLIC :: IF_Mem_Algo_Release_Real1D

CONTAINS

  SUBROUTINE IF_Mem_Algo_Scratch_Real1D(n, name, ptr, pointer_id, status)
    INTEGER(i4), INTENT(IN) :: n
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_MAT, 0_i4, n, name, ptr, pointer_id, status)
  END SUBROUTINE IF_Mem_Algo_Scratch_Real1D

  SUBROUTINE IF_Mem_Algo_Release_Real1D(pointer_id, status)
    INTEGER(i4), INTENT(IN) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL UF_Mem_FreeReal1D(pointer_id, status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_Algo_Release_Real1D

END MODULE IF_Mem_Algo
