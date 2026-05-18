! Harness-only MD_Mat_Def subset: MD_MatState Snapshot/RestoreInto (Phase6 PR3a).
MODULE MD_Mat_Def
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_MatState, MD_MatState_Init_Base, MD_MatState_Snapshot, MD_MatState_RestoreInto
  PUBLIC :: MD_MAT_STATUS_OK

  INTEGER(i4), PARAMETER :: MD_MAT_STATUS_OK = 0_i4

  TYPE :: MD_Mat_Cfg_Init_Desc
    INTEGER(i4) :: id = 0_i4
  END TYPE MD_Mat_Cfg_Init_Desc

  TYPE :: MD_MatState
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    INTEGER(i4) :: nIntPoints = 0_i4
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: strain(:)
    REAL(wp), ALLOCATABLE :: stateV(:)
  END TYPE MD_MatState

CONTAINS

  SUBROUTINE MD_MatState_Init_Base(this, n)
    CLASS(MD_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    this%cfg%id = 0_i4
    this%nIntPoints = 0_i4
    IF (ALLOCATED(this%stress)) DEALLOCATE(this%stress)
    IF (ALLOCATED(this%strain)) DEALLOCATE(this%strain)
    IF (ALLOCATED(this%stateV)) DEALLOCATE(this%stateV)
  END SUBROUTINE MD_MatState_Init_Base

  SUBROUTINE MD_MatState_Snapshot(from_obj, snap, status)
    CLASS(MD_MatState), INTENT(IN) :: from_obj
    TYPE(MD_MatState), INTENT(INOUT) :: snap
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (ALLOCATED(snap%stress)) DEALLOCATE(snap%stress)
    IF (ALLOCATED(snap%strain)) DEALLOCATE(snap%strain)
    IF (ALLOCATED(snap%stateV)) DEALLOCATE(snap%stateV)
    snap%nIntPoints = from_obj%nIntPoints
    snap%cfg = from_obj%cfg
    IF (ALLOCATED(from_obj%stress)) THEN
      ALLOCATE(snap%stress(SIZE(from_obj%stress)))
      snap%stress(:) = from_obj%stress(:)
    END IF
    IF (ALLOCATED(from_obj%strain)) THEN
      ALLOCATE(snap%strain(SIZE(from_obj%strain)))
      snap%strain(:) = from_obj%strain(:)
    END IF
    IF (ALLOCATED(from_obj%stateV)) THEN
      ALLOCATE(snap%stateV(SIZE(from_obj%stateV)))
      snap%stateV(:) = from_obj%stateV(:)
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatState_Snapshot

  SUBROUTINE MD_MatState_RestoreInto(to_obj, snap, status)
    CLASS(MD_MatState), INTENT(INOUT) :: to_obj
    TYPE(MD_MatState), INTENT(IN) :: snap
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (ALLOCATED(to_obj%stress)) DEALLOCATE(to_obj%stress)
    IF (ALLOCATED(to_obj%strain)) DEALLOCATE(to_obj%strain)
    IF (ALLOCATED(to_obj%stateV)) DEALLOCATE(to_obj%stateV)
    to_obj%nIntPoints = snap%nIntPoints
    to_obj%cfg = snap%cfg
    IF (ALLOCATED(snap%stress)) THEN
      ALLOCATE(to_obj%stress(SIZE(snap%stress)))
      to_obj%stress(:) = snap%stress(:)
    END IF
    IF (ALLOCATED(snap%strain)) THEN
      ALLOCATE(to_obj%strain(SIZE(snap%strain)))
      to_obj%strain(:) = snap%strain(:)
    END IF
    IF (ALLOCATED(snap%stateV)) THEN
      ALLOCATE(to_obj%stateV(SIZE(snap%stateV)))
      to_obj%stateV(:) = snap%stateV(:)
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatState_RestoreInto

END MODULE MD_Mat_Def
