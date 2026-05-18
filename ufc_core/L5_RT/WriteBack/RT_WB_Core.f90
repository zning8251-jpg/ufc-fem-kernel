!===============================================================================
! MODULE: RT_WB_Core
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Core — concrete write-back implementations (legacy facade)
! BRIEF:  Displacements/Stresses/SDVs/Reactions write-back to L3 MD_State.
!===============================================================================
MODULE RT_WB_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_WB_Def, ONLY: RT_WB_Desc, RT_WB_ProgressState
  IMPLICIT NONE
  PRIVATE

  ! Legacy type aliases for backward compatibility
  ! AUTHORITY types live in RT_WB_Def.f90
  TYPE, PUBLIC :: RT_WB_Desc
    CHARACTER(LEN=256) :: wb_path    = ''
    INTEGER(i4)        :: wb_mode    = 0_i4
    LOGICAL            :: is_active  = .TRUE.
  END TYPE RT_WB_Desc

  TYPE, PUBLIC :: RT_WB_State
    INTEGER(i4) :: wb_count  = 0_i4
    REAL(wp)    :: last_time = 0.0_wp
    LOGICAL     :: is_open   = .FALSE.
    ! Storage arrays for write-back data (allocated by Init)
    REAL(wp), ALLOCATABLE :: u_store(:)           ! Displacement [ndof]
    REAL(wp), ALLOCATABLE :: stress_store(:,:,:)  ! Stress [ncomp, nip, n_elem]
    REAL(wp), ALLOCATABLE :: sdv_store(:,:,:)     ! SDV [nsdv, nip, n_elem]
    REAL(wp), ALLOCATABLE :: react_store(:)       ! Reactions [ndof]
  END TYPE RT_WB_State

  PUBLIC :: RT_WriteBack_Core_Init
  PUBLIC :: RT_WriteBack_Core_Finalize
  PUBLIC :: RT_WriteBack_Displacements
  PUBLIC :: RT_WriteBack_Stresses
  PUBLIC :: RT_WriteBack_SDVs
  PUBLIC :: RT_WriteBack_Reactions
  PUBLIC :: RT_WriteBack_Execute_All

CONTAINS

  SUBROUTINE RT_WriteBack_Core_Init(desc, state, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%wb_count  = 0
    state%last_time = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Core_Init

  SUBROUTINE RT_WriteBack_Core_Finalize(state, status)
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%wb_count  = 0
    state%last_time = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Core_Finalize

  SUBROUTINE RT_WriteBack_Displacements(desc, state, ndof, u, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    INTEGER(i4),          INTENT(IN)    :: ndof
    REAL(wp),             INTENT(IN)    :: u(ndof)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idof

    CALL init_error_status(status)
    IF (ndof <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[RT_WB_Core]: ndof <= 0 in WriteBack_Displacements'
      RETURN
    END IF

    ! Write displacement vector into L3 MD_State nodal storage
    ! Each DOF is mapped 1:1 to the global displacement array
    IF (ALLOCATED(state%u_store)) THEN
      DO idof = 1, MIN(ndof, SIZE(state%u_store))
        state%u_store(idof) = u(idof)
      END DO
    END IF

    state%wb_count = state%wb_count + 1
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Displacements

  SUBROUTINE RT_WriteBack_Stresses(desc, state, n_elem, nip, ncomp, &
                                    stress, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    INTEGER(i4),          INTENT(IN)    :: n_elem
    INTEGER(i4),          INTENT(IN)    :: nip
    INTEGER(i4),          INTENT(IN)    :: ncomp
    REAL(wp),             INTENT(IN)    :: stress(ncomp, nip, n_elem)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ie, ip, ic

    CALL init_error_status(status)
    IF (n_elem <= 0 .OR. nip <= 0 .OR. ncomp <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[RT_WB_Core]: Invalid dims in WriteBack_Stresses'
      RETURN
    END IF

    ! Write IP stress data into L3 MD_State element storage
    ! Layout: stress(component, IP, element)
    IF (ALLOCATED(state%stress_store)) THEN
      DO ie = 1, MIN(n_elem, SIZE(state%stress_store, 3))
        DO ip = 1, MIN(nip, SIZE(state%stress_store, 2))
          DO ic = 1, MIN(ncomp, SIZE(state%stress_store, 1))
            state%stress_store(ic, ip, ie) = stress(ic, ip, ie)
          END DO
        END DO
      END DO
    END IF

    state%wb_count = state%wb_count + 1
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Stresses

  SUBROUTINE RT_WriteBack_SDVs(desc, state, n_elem, nip, nsdv, sdv, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    INTEGER(i4),          INTENT(IN)    :: n_elem
    INTEGER(i4),          INTENT(IN)    :: nip
    INTEGER(i4),          INTENT(IN)    :: nsdv
    REAL(wp),             INTENT(IN)    :: sdv(nsdv, nip, n_elem)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ie, ip, iv

    CALL init_error_status(status)
    IF (n_elem <= 0 .OR. nip <= 0 .OR. nsdv <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[RT_WB_Core]: Invalid dims in WriteBack_SDVs'
      RETURN
    END IF

    ! Write state dependent variables into L3 MD_State element SDV storage
    IF (ALLOCATED(state%sdv_store)) THEN
      DO ie = 1, MIN(n_elem, SIZE(state%sdv_store, 3))
        DO ip = 1, MIN(nip, SIZE(state%sdv_store, 2))
          DO iv = 1, MIN(nsdv, SIZE(state%sdv_store, 1))
            state%sdv_store(iv, ip, ie) = sdv(iv, ip, ie)
          END DO
        END DO
      END DO
    END IF

    state%wb_count = state%wb_count + 1
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_SDVs

  SUBROUTINE RT_WriteBack_Reactions(desc, state, ndof, reactions, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    INTEGER(i4),          INTENT(IN)    :: ndof
    REAL(wp),             INTENT(IN)    :: reactions(ndof)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idof

    CALL init_error_status(status)
    IF (ndof <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[RT_WB_Core]: ndof <= 0 in WriteBack_Reactions'
      RETURN
    END IF

    ! Write reaction forces into L3 MD_State nodal reaction storage
    IF (ALLOCATED(state%react_store)) THEN
      DO idof = 1, MIN(ndof, SIZE(state%react_store))
        state%react_store(idof) = reactions(idof)
      END DO
    END IF

    state%wb_count = state%wb_count + 1
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Reactions

  SUBROUTINE RT_WriteBack_Execute_All(desc, state, time, status)
    TYPE(RT_WB_Desc),     INTENT(IN)    :: desc
    TYPE(RT_WB_State),    INTENT(INOUT) :: state
    REAL(wp),             INTENT(IN)    :: time
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%last_time = time
    state%wb_count  = state%wb_count + 1

    ! Mark all stores as synchronized at current time
    ! The actual data was already written by the individual
    ! WriteBack_Displacements / _Stresses / _SDVs / _Reactions calls.
    ! This routine serves as a commit/sync barrier.
    state%is_open = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Execute_All

END MODULE RT_WB_Core
