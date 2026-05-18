!===============================================================================
! MODULE:  MD_LBC_Idx
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Impl
! BRIEF:   Single Idx entry for LoadBC domain — pointer-bound delegation.
!          No circular USE; Bind called at UFC_Global_Init.
!===============================================================================

MODULE MD_LBC_Idx
  USE IF_Prec_Core,    ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID, IF_STATUS_OK, &
    IF_STATUS_MEM_ERROR
  USE MD_LBC_Domain, ONLY: MD_LoadBC_Domain, MD_LBC_GetLoadsForStep_Arg, &
    MD_LBC_GetBCsForStep_Arg, MD_LBC_GetBC_Arg, MD_LBC_GetLoad_Arg, &
    MD_LBC_GetLoadByName_Arg, MD_LBC_GetBCByName_Arg
  ! Idx path does not USE MD_BC_Def (domain TBP returns Desc via MD_LoadBC_Domain).
  USE MD_Load_Def, ONLY: MD_Load_Base_Desc, MD_Load_Base_State
  IMPLICIT NONE
  PRIVATE

  TYPE(MD_LoadBC_Domain), POINTER, SAVE :: ldbc_idx_dom => NULL()

  PUBLIC :: MD_LoadBC_Idx_Bind, MD_LoadBC_Idx_Reset
  PUBLIC :: MD_LoadBC_GetLoadsForStep_Idx, MD_LoadBC_GetBCsForStep_Idx
  PUBLIC :: MD_LoadBC_GetBC_Idx, MD_LoadBC_GetLoad_Idx
  PUBLIC :: MD_LoadBC_GetLoadByName_Idx, MD_LoadBC_GetBCByName_Idx

CONTAINS

  SUBROUTINE MD_LoadBC_Idx_Bind(dom)
    TYPE(MD_LoadBC_Domain), INTENT(IN), TARGET :: dom
    ldbc_idx_dom => dom
  END SUBROUTINE MD_LoadBC_Idx_Bind

  SUBROUTINE MD_LoadBC_Idx_Reset()
    IF (ASSOCIATED(ldbc_idx_dom)) NULLIFY(ldbc_idx_dom)
  END SUBROUTINE MD_LoadBC_Idx_Reset

  LOGICAL FUNCTION idx_dom_ok() RESULT(ok)
    ok = ASSOCIATED(ldbc_idx_dom)
    IF (ok) ok = ldbc_idx_dom%initialized
  END FUNCTION idx_dom_ok

  SUBROUTINE MD_LoadBC_GetLoadsForStep_Idx(step_idx, arg, status)
    INTEGER(i4),                          INTENT(IN)    :: step_idx
    TYPE(MD_LBC_GetLoadsForStep_Arg),  INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),                INTENT(OUT)   :: status
    INTEGER(i4) :: n_found, nmax, ierr
    INTEGER(i4), ALLOCATABLE :: work(:)

    CALL init_error_status(status)
    arg%n_found = 0_i4
    IF (ALLOCATED(arg%load_indices)) DEALLOCATE(arg%load_indices)
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetLoadsForStep_Idx: Idx not bound (call MD_LoadBC_Idx_Bind after L3 Init)"
      RETURN
    END IF
    nmax = MAX(1_i4, ldbc_idx_dom%n_loads)
    ALLOCATE(work(nmax), stat=ierr)
    IF (ierr /= 0_i4) THEN
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_LoadBC_GetLoadsForStep_Idx: ALLOCATE(work) failed"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetLoadsForStep(step_idx, work, n_found, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      IF (ALLOCATED(work)) DEALLOCATE(work)
      RETURN
    END IF
    IF (n_found > 0) THEN
      ALLOCATE(arg%load_indices(n_found), stat=ierr)
      IF (ierr /= 0_i4) THEN
        IF (ALLOCATED(work)) DEALLOCATE(work)
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_LoadBC_GetLoadsForStep_Idx: ALLOCATE(load_indices) failed"
        RETURN
      END IF
      arg%load_indices(1:n_found) = work(1:n_found)
    ELSE
      ALLOCATE(arg%load_indices(0), stat=ierr)
      IF (ierr /= 0_i4) THEN
        IF (ALLOCATED(work)) DEALLOCATE(work)
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_LoadBC_GetLoadsForStep_Idx: ALLOCATE(load_indices(0)) failed"
        RETURN
      END IF
    END IF
    arg%n_found = n_found
    IF (ALLOCATED(work)) DEALLOCATE(work)
  END SUBROUTINE MD_LoadBC_GetLoadsForStep_Idx

  SUBROUTINE MD_LoadBC_GetBCsForStep_Idx(step_idx, arg, status)
    INTEGER(i4),                         INTENT(IN)    :: step_idx
    TYPE(MD_LBC_GetBCsForStep_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),               INTENT(OUT)   :: status
    INTEGER(i4) :: n_found, nmax, ierr
    INTEGER(i4), ALLOCATABLE :: work(:)

    CALL init_error_status(status)
    arg%n_found = 0_i4
    IF (ALLOCATED(arg%bc_indices)) DEALLOCATE(arg%bc_indices)
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetBCsForStep_Idx: Idx not bound"
      RETURN
    END IF
    nmax = MAX(1_i4, ldbc_idx_dom%n_bcs)
    ALLOCATE(work(nmax), stat=ierr)
    IF (ierr /= 0_i4) THEN
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_LoadBC_GetBCsForStep_Idx: ALLOCATE(work) failed"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetBCsForStep(step_idx, work, n_found, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      IF (ALLOCATED(work)) DEALLOCATE(work)
      RETURN
    END IF
    IF (n_found > 0) THEN
      ALLOCATE(arg%bc_indices(n_found), stat=ierr)
      IF (ierr /= 0_i4) THEN
        IF (ALLOCATED(work)) DEALLOCATE(work)
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_LoadBC_GetBCsForStep_Idx: ALLOCATE(bc_indices) failed"
        RETURN
      END IF
      arg%bc_indices(1:n_found) = work(1:n_found)
    ELSE
      ALLOCATE(arg%bc_indices(0), stat=ierr)
      IF (ierr /= 0_i4) THEN
        IF (ALLOCATED(work)) DEALLOCATE(work)
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_LoadBC_GetBCsForStep_Idx: ALLOCATE(bc_indices(0)) failed"
        RETURN
      END IF
    END IF
    arg%n_found = n_found
    IF (ALLOCATED(work)) DEALLOCATE(work)
  END SUBROUTINE MD_LoadBC_GetBCsForStep_Idx

  SUBROUTINE MD_LoadBC_GetBC_Idx(bc_idx, arg, status)
    INTEGER(i4),                    INTENT(IN)    :: bc_idx
    TYPE(MD_LBC_GetBC_Arg),      INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetBC_Idx: Idx not bound"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetBC(bc_idx, arg%desc, status)
  END SUBROUTINE MD_LoadBC_GetBC_Idx

  SUBROUTINE MD_LoadBC_GetLoad_Idx(load_idx, arg, status)
    INTEGER(i4),                     INTENT(IN)    :: load_idx
    TYPE(MD_LBC_GetLoad_Arg),     INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetLoad_Idx: Idx not bound"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetLoad(load_idx, arg%desc, status)
  END SUBROUTINE MD_LoadBC_GetLoad_Idx

  SUBROUTINE MD_LoadBC_GetLoadByName_Idx(name, arg, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(MD_LBC_GetLoadByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    arg%load_idx = 0_i4
    arg%found = .FALSE.
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetLoadByName_Idx: Idx not bound"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetLoadByName(name, arg%load_idx, arg%found, status)
  END SUBROUTINE MD_LoadBC_GetLoadByName_Idx

  SUBROUTINE MD_LoadBC_GetBCByName_Idx(name, arg, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(MD_LBC_GetBCByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    arg%bc_idx = 0_i4
    arg%found = .FALSE.
    IF (.NOT. idx_dom_ok()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_GetBCByName_Idx: Idx not bound"
      RETURN
    END IF
    CALL ldbc_idx_dom%GetBCByName(name, arg%bc_idx, arg%found, status)
  END SUBROUTINE MD_LoadBC_GetBCByName_Idx

END MODULE MD_LBC_Idx
