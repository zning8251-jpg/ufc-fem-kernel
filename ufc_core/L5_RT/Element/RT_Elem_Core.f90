!===============================================================================
! MODULE: RT_Elem_Core
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Core — Callback-based element loop utilities (test-oriented path)
! BRIEF:  Standalone callback loop for unit tests / prototyping.  LEGACY.
!         Production routing uses RT_ElemDispatcher → L4.
! **W2**：**LEGACY** 试验回调环；生产 **`RT_ElemDispatcher`/`RT_Elem_Proc`** → **`PH_Elem_Core`**；
!         勿当主装配唯一热路径。
!===============================================================================
MODULE RT_Elem_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Elem_Def, ONLY: RT_Elem_Desc, RT_Elem_Ctx, RT_Elem_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Element_Core_Init
  PUBLIC :: RT_Element_Core_Finalize
  PUBLIC :: RT_Element_Loop_Ke
  PUBLIC :: RT_Element_Loop_Fe
  PUBLIC :: RT_Element_Loop_Mass
  PUBLIC :: RT_Element_Loop_Stress
  PUBLIC :: RT_Element_Loop_Internal_Force
  PUBLIC :: RT_Element_Get_DOF_Map

  ABSTRACT INTERFACE
    SUBROUTINE elem_callback_iface(e, status)
      IMPORT :: i4, ErrorStatusType
      INTEGER(i4),          INTENT(IN)    :: e
      TYPE(ErrorStatusType), INTENT(OUT)   :: status
    END SUBROUTINE elem_callback_iface
  END INTERFACE

CONTAINS

  SUBROUTINE RT_Element_Core_Init(desc, state, ctx, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_State),  INTENT(OUT)   :: state
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%elem_id   = 0
    ctx%nn        = 0
    ctx%ndof_elem = 0
    ctx%conn      = 0
    ctx%dof_map   = 0
    state%base%initialized   = .TRUE.
    state%base%stiffness_built = .FALSE.
    state%base%n_active_elems  = 0
    state%base%current_step    = 0
    state%is_active = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Core_Init

  SUBROUTINE RT_Element_Core_Finalize(state, ctx, status)
    TYPE(RT_Elem_State),  INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%elem_id   = 0
    ctx%nn        = 0
    ctx%ndof_elem = 0
    ctx%conn      = 0
    ctx%dof_map   = 0
    state%base%initialized = .FALSE.
    state%is_active = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Core_Finalize

  SUBROUTINE RT_Element_Loop_Ke(desc, ctx, elem_compute, Ke_callback, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    PROCEDURE(elem_callback_iface)       :: elem_compute
    PROCEDURE(elem_callback_iface)       :: Ke_callback
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: e
    TYPE(ErrorStatusType) :: elem_status

    CALL init_error_status(status)
    DO e = 1, desc%n_elem
      ctx%elem_id = e
      CALL init_error_status(elem_status)
      CALL elem_compute(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
      CALL Ke_callback(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Loop_Ke

  SUBROUTINE RT_Element_Loop_Fe(desc, ctx, elem_compute_F, Fe_callback, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    PROCEDURE(elem_callback_iface)       :: elem_compute_F
    PROCEDURE(elem_callback_iface)       :: Fe_callback
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: e
    TYPE(ErrorStatusType) :: elem_status

    CALL init_error_status(status)
    DO e = 1, desc%n_elem
      ctx%elem_id = e
      CALL init_error_status(elem_status)
      CALL elem_compute_F(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
      CALL Fe_callback(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Loop_Fe

  SUBROUTINE RT_Element_Loop_Mass(desc, ctx, elem_compute_M, Me_callback, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    PROCEDURE(elem_callback_iface)       :: elem_compute_M
    PROCEDURE(elem_callback_iface)       :: Me_callback
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: e
    TYPE(ErrorStatusType) :: elem_status

    CALL init_error_status(status)
    DO e = 1, desc%n_elem
      ctx%elem_id = e
      CALL init_error_status(elem_status)
      CALL elem_compute_M(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
      CALL Me_callback(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Loop_Mass

  SUBROUTINE RT_Element_Loop_Stress(desc, ctx, compute_stress, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    PROCEDURE(elem_callback_iface)       :: compute_stress
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: e
    TYPE(ErrorStatusType) :: elem_status

    CALL init_error_status(status)
    DO e = 1, desc%n_elem
      ctx%elem_id = e
      CALL init_error_status(elem_status)
      CALL compute_stress(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Loop_Stress

  SUBROUTINE RT_Element_Loop_Internal_Force(desc, ctx, compute_fint, &
                                             assemble_fint, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    PROCEDURE(elem_callback_iface)       :: compute_fint
    PROCEDURE(elem_callback_iface)       :: assemble_fint
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: e
    TYPE(ErrorStatusType) :: elem_status

    CALL init_error_status(status)
    DO e = 1, desc%n_elem
      ctx%elem_id = e
      CALL init_error_status(elem_status)
      CALL compute_fint(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
      CALL assemble_fint(e, elem_status)
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = elem_status%status_code
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Loop_Internal_Force

  SUBROUTINE RT_Element_Get_DOF_Map(desc, ctx, status)
    TYPE(RT_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(RT_Elem_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, base_dof

    CALL init_error_status(status)
    IF (ctx%nn <= 0 .OR. ctx%nn > desc%max_nn) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ctx%ndof_elem = ctx%nn * desc%ndof_per_node
    ctx%dof_map   = 0
    DO i = 1, ctx%nn
      base_dof = (ctx%conn(i) - 1) * desc%ndof_per_node
      DO j = 1, desc%ndof_per_node
        ctx%dof_map((i - 1) * desc%ndof_per_node + j) = base_dof + j
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Element_Get_DOF_Map

END MODULE RT_Elem_Core
