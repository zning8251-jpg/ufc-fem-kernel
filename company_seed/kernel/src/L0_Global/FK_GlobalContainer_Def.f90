! FK_GlobalContainer_Def.f90
! L0_Global — Global container module (template)
!
! This is a Clean-Room template. It demonstrates the architectural pattern
! for a global container without implementing specific UFC logic.
!
! Architectural pattern:
!   - Single global container TYPE holding session-wide state
!   - Initialize/Cleanup lifecycle
!   - Upper layers access through context injection, NOT global USE

MODULE FK_GlobalContainer_Def
  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: I4 => INT32, R8 => REAL64

  IMPLICIT NONE
  PRIVATE

  !══════════════════════════════════════════════════════
  ! PUBLIC API
  !══════════════════════════════════════════════════════
  PUBLIC :: FK_GlobalContainer_Type
  PUBLIC :: FK_Global_Init
  PUBLIC :: FK_Global_Cleanup

  !══════════════════════════════════════════════════════
  ! TYPE: Global Container
  !══════════════════════════════════════════════════════
  TYPE :: FK_GlobalContainer_Type
    ! Session identification
    CHARACTER(len=256) :: session_name = ''
    INTEGER(I4)        :: session_id   = 0

    ! Feature flags
    LOGICAL :: is_initialized = .FALSE.
  END TYPE FK_GlobalContainer_Type

  !══════════════════════════════════════════════════════
  ! MODULE-LEVEL INSTANCE (L0 only — other layers use injection)
  !══════════════════════════════════════════════════════
  TYPE(FK_GlobalContainer_Type), SAVE, TARGET :: g_fk_global

CONTAINS

  !────────────────────────────────────────────────────
  SUBROUTINE FK_Global_Init(session_name)
    CHARACTER(len=*), INTENT(IN) :: session_name

    g_fk_global%session_name = session_name
    g_fk_global%is_initialized = .TRUE.
  END SUBROUTINE FK_Global_Init

  !────────────────────────────────────────────────────
  SUBROUTINE FK_Global_Cleanup()
    g_fk_global%is_initialized = .FALSE.
  END SUBROUTINE FK_Global_Cleanup

END MODULE FK_GlobalContainer_Def
