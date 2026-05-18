!===============================================================================
! MODULE: PH_WB_Core
! LAYER:  L4_PH
! DOMAIN: WriteBack
! ROLE:   Core — format preparation engine
! BRIEF:  Prepares physics results for write-back into write-back format.
!         - Node data: displacement/velocity/acceleration → formatted buffer
!         - Element data: stress/strain → formatted buffer
!
! CONSTRAINT (WB-02): L4 must NOT write L3 directly.
!   This module prepares data to be sent to L5 via PH_WB_Brg.
!   L5's WB_Guard performs the actual L3 write-back.
!===============================================================================
MODULE PH_WB_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_WB_Def, ONLY: PH_WB_Desc, PH_WB_State, PH_WB_Algo, PH_WB_Ctx, PH_WB_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_WB_PrepareNodeDisp
  PUBLIC :: PH_WB_PrepareNodeVel
  PUBLIC :: PH_WB_PrepareNodeAccel
  PUBLIC :: PH_WB_PrepareElemStress
  PUBLIC :: PH_WB_PrepareElemStrain

CONTAINS

  !=============================================================================
  !> Prepare nodal displacement for write-back
  !=============================================================================
  SUBROUTINE PH_WB_PrepareNodeDisp(node_idx, disp, buffer, buf_pos, status)
    INTEGER(i4),        INTENT(IN)    :: node_idx
    REAL(wp),           INTENT(IN)    :: disp(3)
    REAL(wp),           INTENT(INOUT) :: buffer(:)
    INTEGER(i4),        INTENT(INOUT) :: buf_pos
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (buf_pos < 1 .OR. buf_pos + 2 > SIZE(buffer)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_PrepareNodeDisp: buffer overflow'
      RETURN
    END IF
    buffer(buf_pos)     = REAL(node_idx, wp)
    buffer(buf_pos + 1) = disp(1)
    buffer(buf_pos + 2) = disp(2)
    buffer(buf_pos + 3) = disp(3)
    buf_pos = buf_pos + 4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_PrepareNodeDisp

  !=============================================================================
  !> Prepare nodal velocity for write-back
  !=============================================================================
  SUBROUTINE PH_WB_PrepareNodeVel(node_idx, vel, buffer, buf_pos, status)
    INTEGER(i4),        INTENT(IN)    :: node_idx
    REAL(wp),           INTENT(IN)    :: vel(3)
    REAL(wp),           INTENT(INOUT) :: buffer(:)
    INTEGER(i4),        INTENT(INOUT) :: buf_pos
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (buf_pos < 1 .OR. buf_pos + 2 > SIZE(buffer)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_PrepareNodeVel: buffer overflow'
      RETURN
    END IF
    buffer(buf_pos)     = REAL(node_idx, wp)
    buffer(buf_pos + 1) = vel(1)
    buffer(buf_pos + 2) = vel(2)
    buffer(buf_pos + 3) = vel(3)
    buf_pos = buf_pos + 4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_PrepareNodeVel

  !=============================================================================
  !> Prepare nodal acceleration for write-back
  !=============================================================================
  SUBROUTINE PH_WB_PrepareNodeAccel(node_idx, accel, buffer, buf_pos, status)
    INTEGER(i4),        INTENT(IN)    :: node_idx
    REAL(wp),           INTENT(IN)    :: accel(3)
    REAL(wp),           INTENT(INOUT) :: buffer(:)
    INTEGER(i4),        INTENT(INOUT) :: buf_pos
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (buf_pos < 1 .OR. buf_pos + 2 > SIZE(buffer)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_PrepareNodeAccel: buffer overflow'
      RETURN
    END IF
    buffer(buf_pos)     = REAL(node_idx, wp)
    buffer(buf_pos + 1) = accel(1)
    buffer(buf_pos + 2) = accel(2)
    buffer(buf_pos + 3) = accel(3)
    buf_pos = buf_pos + 4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_PrepareNodeAccel

  !=============================================================================
  !> Prepare element stress for write-back
  !=============================================================================
  SUBROUTINE PH_WB_PrepareElemStress(elem_idx, stress_voigt, buffer, buf_pos, status)
    INTEGER(i4),        INTENT(IN)    :: elem_idx
    REAL(wp),           INTENT(IN)    :: stress_voigt(6)
    REAL(wp),           INTENT(INOUT) :: buffer(:)
    INTEGER(i4),        INTENT(INOUT) :: buf_pos
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (buf_pos < 1 .OR. buf_pos + 6 > SIZE(buffer)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_PrepareElemStress: buffer overflow'
      RETURN
    END IF
    buffer(buf_pos) = REAL(elem_idx, wp)
    DO i = 1, 6
      buffer(buf_pos + i) = stress_voigt(i)
    END DO
    buf_pos = buf_pos + 7
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_PrepareElemStress

  !=============================================================================
  !> Prepare element strain for write-back
  !=============================================================================
  SUBROUTINE PH_WB_PrepareElemStrain(elem_idx, strain_voigt, buffer, buf_pos, status)
    INTEGER(i4),        INTENT(IN)    :: elem_idx
    REAL(wp),           INTENT(IN)    :: strain_voigt(6)
    REAL(wp),           INTENT(INOUT) :: buffer(:)
    INTEGER(i4),        INTENT(INOUT) :: buf_pos
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (buf_pos < 1 .OR. buf_pos + 6 > SIZE(buffer)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_PrepareElemStrain: buffer overflow'
      RETURN
    END IF
    buffer(buf_pos) = REAL(elem_idx, wp)
    DO i = 1, 6
      buffer(buf_pos + i) = strain_voigt(i)
    END DO
    buf_pos = buf_pos + 7
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_PrepareElemStrain

END MODULE PH_WB_Core
