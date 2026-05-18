!===============================================================================
! Module: UFC_Memory_Strategy                                         [v1.1]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Common — Memory Management Strategy & Lifecycle Policy
!
! Purpose:
!   Defines the complete memory management strategy for the UFC TYPE system:
!
!   1. ALLOCATION RULES  — where/when to ALLOCATE
!   2. DEALLOCATION RULES — where/when to DEALLOCATE (closed-loop)
!   3. POINTER OWNERSHIP — who owns TARGET vs who holds POINTER
!   4. LIFECYCLE EVENTS  — Step start / Step end / Model unload triggers
!   5. EXCEPTION SAFETY  — leak-free paths under error conditions
!   6. HOT-PATH GUARD    — forbidden allocations inside increment loop
!
! Core principle (from LoadBC container design):
!   "Memory allocation logic MUST be paired with deallocation strategy,
!    forming an end-to-end closed loop."
!
! Status baseline:
!   Concrete IF_Err_Brg bridges initialize structured status via
!   init_error_status(...) and inspect status%status_code after each call.
!
! Changelog:
!   v1.1 (2026-05)  Replace magic numeric status%status_code writes with
!                   init_error_status(...) and IF_STATUS_* bridge constants.
! Note:
!   This comment refresh aligns header/example wording to the
!   IF_Err_Brg + structured status baseline.
!
! Four lifecycle levels:
!   Level A: Analysis lifetime  — allocated once, freed at analysis end
!   Level B: Step lifetime      — allocated per step, freed at step end
!   Level C: Increment lifetime — allocated per increment, freed each inc
!   Level D: Call lifetime      — stack / local, freed on RETURN (no ALLOCATE)
!
!===============================================================================
MODULE UFC_Memory_Strategy
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                        IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  !-- Public strategy constants (lifecycle level codes)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MEM_MEM_LEVEL_ANALYSIS   = 1_i4  ! Level A  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MEM_MEM_LEVEL_STEP       = 2_i4  ! Level B  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MEM_MEM_LEVEL_INCREMENT  = 3_i4  ! Level C  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MEM_MEM_LEVEL_CALL       = 4_i4  ! Level D  ! migrated

  !-- Public allocation registry entry (introspection / debugging)
  PUBLIC :: UFC_Alloc_Record
  PUBLIC :: UFC_Alloc_Registry

  !-- Public strategy subroutines
  PUBLIC :: UFC_Mem_AllocStates
  PUBLIC :: UFC_Mem_FreeStates
  PUBLIC :: UFC_Mem_AllocExplicit
  PUBLIC :: UFC_Mem_FreeExplicit
  PUBLIC :: UFC_Mem_SafeDealloc_R1
  PUBLIC :: UFC_Mem_SafeDealloc_R2
  PUBLIC :: UFC_Mem_SafeDealloc_I1
  PUBLIC :: UFC_Mem_CheckLeaks

  !============================================================================
  ! UFC_Alloc_Record — per-allocation registry entry (for leak detection)
  !============================================================================
  TYPE, PUBLIC :: UFC_Alloc_Record
    CHARACTER(LEN=64) :: var_name   = ' '    ! variable name (for diagnostics)
    CHARACTER(LEN=32) :: module_name = ' '   ! owning module
    INTEGER(i4)       :: lifecycle  = 0_i4   ! MEM_LEVEL_*
    INTEGER(i4)       :: n_bytes    = 0_i4   ! approximate allocation size
    LOGICAL           :: is_allocated = .FALSE.
  END TYPE UFC_Alloc_Record

  !============================================================================
  ! UFC_Alloc_Registry — lightweight allocation tracking table
  !   Max 256 entries; in production replace with a dynamic list.
  !============================================================================
  TYPE, PUBLIC :: UFC_Alloc_Registry
    TYPE(UFC_Alloc_Record) :: entries(256)
    INTEGER(i4)            :: n_entries = 0_i4
  CONTAINS
    PROCEDURE :: Register => UFC_Registry_Register
    PROCEDURE :: Deregister => UFC_Registry_Deregister
    PROCEDURE :: CountActive => UFC_Registry_CountActive
  END TYPE UFC_Alloc_Registry

CONTAINS

  !============================================================================
  ! UFC_Mem_AllocStates — Level A allocation: per-domain State arrays
  !
  !   Called ONCE in the Populate Phase.
  !   ALLOCATES the PH_XXX_State arrays needed by physics subroutines.
  !
  !   Ownership rule:
  !     The caller (e.g. RT_StepDriver) owns the TARGET arrays.
  !     RT_XXX_Domain_Ctx holds only non-owning POINTER references.
  !
  !   Bridge usage pattern (adapt TYPE names for each domain):
  !     CALL init_error_status(status)
  !     CALL UFC_Mem_AllocStates(n_items, alloc_size_hint, status)
  !     IF (status%status_code /= IF_STATUS_OK) THEN
  !       ! bridge handles teardown / escalation
  !     END IF
  !============================================================================
  SUBROUTINE UFC_Mem_AllocStates(n_items, alloc_size_hint, status)
    INTEGER(i4),           INTENT(IN)  :: n_items        ! number of instances
    INTEGER(i4),           INTENT(IN)  :: alloc_size_hint ! bytes per item (hint)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    !-- Validate inputs
    IF (n_items <= 0) THEN
      CALL init_error_status(status, IF_STATUS_INVALID, &
          message='UFC_Mem_AllocStates: n_items must be > 0')
      RETURN
    END IF

    !-- Actual ALLOCATE of concrete TYPE arrays is done in the caller
    !   because Fortran requires a concrete TYPE for ALLOCATE.
    !   This subroutine provides the strategy template only.
    !
    !   Caller pattern:
    !     ALLOCATE(mat_states(n_mats), STAT=ierr)
    !     IF (ierr /= 0) CALL Handle_Alloc_Error(...)
    !
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE UFC_Mem_AllocStates

  !============================================================================
  ! UFC_Mem_FreeStates — Level A deallocation: per-domain State arrays
  !
  !   Called at analysis end or model unload.
  !   MUST be called even on error paths (exception safety).
  !
  !   Deallocation trigger events:
  !     - Normal analysis end:  CALL UFC_Mem_FreeStates(...)
  !     - Step abort / error:   CALL UFC_Mem_FreeStates(...)  ← same call
  !     - Restart file write:   State arrays remain alive (Level A)
  !
  !   Bridge teardown pattern:
  !     CALL init_error_status(status)
  !     CALL UFC_Mem_FreeStates(ALLOCATED(mat_states), status)
  !     IF (status%status_code /= IF_STATUS_OK) THEN
  !       ! bridge decides warn vs error handling
  !     END IF
  !============================================================================
  SUBROUTINE UFC_Mem_FreeStates(is_allocated, status)
    LOGICAL,               INTENT(IN)  :: is_allocated
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (.NOT. is_allocated) THEN
      CALL init_error_status(status, IF_STATUS_WARN, &
          message='UFC_Mem_FreeStates: array was not allocated')
      RETURN
    END IF
    !-- Actual DEALLOCATE done in caller:
    !   IF (ALLOCATED(array)) DEALLOCATE(array, STAT=ierr)
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE UFC_Mem_FreeStates

  !============================================================================
  ! UFC_Mem_AllocExplicit — Level B/C: Explicit solver nblock arrays
  !
  !   Explicit Ctx types carry [nblock, ...] POINTER arrays.
  !   These are sized at increment start and freed at increment end.
  !
  !   Strategy:
  !     - ALLOCATE at increment start (before calling VDISP / VUMAT / etc.)
  !     - DEALLOCATE at increment end (after last Explicit subroutine call)
  !     - NEVER re-ALLOCATE if nblock unchanged (reuse existing arrays)
  !
  !   Bridge pattern:
  !     CALL init_error_status(status)
  !     CALL UFC_Mem_AllocExplicit(nblock, ndof, is_realloc, status)
  !     IF (status%status_code /= IF_STATUS_OK) RETURN
  !     IF (.NOT. ALLOCATED(ctx%velold) .OR. SIZE(ctx%velold,1) /= nblock) THEN
  !       IF (ALLOCATED(ctx%velold)) DEALLOCATE(ctx%velold)
  !       ALLOCATE(ctx%velold(nblock, ndof))
  !     END IF
  !============================================================================
  SUBROUTINE UFC_Mem_AllocExplicit(nblock, ndof, is_realloc, status)
    INTEGER(i4),           INTENT(IN)  :: nblock
    INTEGER(i4),           INTENT(IN)  :: ndof
    LOGICAL,               INTENT(OUT) :: is_realloc  ! .TRUE. if realloc needed
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (nblock <= 0 .OR. ndof <= 0) THEN
      CALL init_error_status(status, IF_STATUS_INVALID, &
          message='UFC_Mem_AllocExplicit: nblock/ndof must be > 0')
      is_realloc = .FALSE.
      RETURN
    END IF
    !-- Caller checks SIZE and decides; this template returns advisory flag
    is_realloc = .TRUE.  ! always recommend recheck in template
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE UFC_Mem_AllocExplicit

  !============================================================================
  ! UFC_Mem_FreeExplicit — Level B/C: Free Explicit nblock arrays
  !
  !   Called at Step end or before resizing (nblock changed).
  !   Bridge teardown checks status%status_code after local DEALLOCATE work.
  !============================================================================
  SUBROUTINE UFC_Mem_FreeExplicit(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    !-- Caller DEALLOCATEs each component:
    !   IF (ALLOCATED(ctx%velold)) DEALLOCATE(ctx%velold)
    !   IF (ALLOCATED(ctx%accold)) DEALLOCATE(ctx%accold)
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE UFC_Mem_FreeExplicit

  !============================================================================
  ! UFC_Mem_SafeDealloc_* — Exception-safe deallocation helpers
  !
  !   Wraps DEALLOCATE with ALLOCATED guard and STAT check.
  !   Use in all error-path teardown to prevent double-free or leak.
  !   Concrete bridges typically call init_error_status(...) before teardown
  !   and inspect status%status_code after each helper returns.
  !============================================================================
  SUBROUTINE UFC_Mem_SafeDealloc_R1(arr, status)
    REAL(wp), POINTER, INTENT(INOUT) :: arr(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER :: ierr
    CALL init_error_status(status, IF_STATUS_OK)
    IF (ASSOCIATED(arr)) THEN
      DEALLOCATE(arr, STAT=ierr)
      IF (ierr /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
            message='UFC_Mem_SafeDealloc_R1: DEALLOCATE failed')
      END IF
    END IF
  END SUBROUTINE UFC_Mem_SafeDealloc_R1

  SUBROUTINE UFC_Mem_SafeDealloc_R2(arr, status)
    REAL(wp), POINTER, INTENT(INOUT) :: arr(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER :: ierr
    CALL init_error_status(status, IF_STATUS_OK)
    IF (ASSOCIATED(arr)) THEN
      DEALLOCATE(arr, STAT=ierr)
      IF (ierr /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
            message='UFC_Mem_SafeDealloc_R2: DEALLOCATE failed')
      END IF
    END IF
  END SUBROUTINE UFC_Mem_SafeDealloc_R2

  SUBROUTINE UFC_Mem_SafeDealloc_I1(arr, status)
    INTEGER(i4), POINTER, INTENT(INOUT) :: arr(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    INTEGER :: ierr
    CALL init_error_status(status, IF_STATUS_OK)
    IF (ASSOCIATED(arr)) THEN
      DEALLOCATE(arr, STAT=ierr)
      IF (ierr /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
            message='UFC_Mem_SafeDealloc_I1: DEALLOCATE failed')
      END IF
    END IF
  END SUBROUTINE UFC_Mem_SafeDealloc_I1

  !============================================================================
  ! UFC_Mem_CheckLeaks — Scan registry for un-freed Level B/C allocations
  !
  !   Called at Step end to validate all transient arrays were released.
  !   Returns n_leaks > 0 if any Level B/C entries are still marked allocated.
  !============================================================================
  SUBROUTINE UFC_Mem_CheckLeaks(registry, n_leaks, status)
    TYPE(UFC_Alloc_Registry), INTENT(IN)  :: registry
    INTEGER(i4),              INTENT(OUT) :: n_leaks
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER :: i
    n_leaks = 0
    DO i = 1, registry%n_entries
      IF (registry%entries(i)%is_allocated .AND. &
          registry%entries(i)%lifecycle >= RT_MEM_MEM_LEVEL_STEP) THEN
        n_leaks = n_leaks + 1
      END IF
    END DO
    IF (n_leaks > 0) THEN
      CALL init_error_status(status, IF_STATUS_WARN, &
          message='UFC_Mem_CheckLeaks: transient allocations not freed')
    ELSE
      CALL init_error_status(status, IF_STATUS_OK)
    END IF
  END SUBROUTINE UFC_Mem_CheckLeaks

  !-- Registry helper implementations
  SUBROUTINE UFC_Registry_Register(this, var_name, module_name, lifecycle, n_bytes)
    CLASS(UFC_Alloc_Registry), INTENT(INOUT) :: this
    CHARACTER(LEN=*),          INTENT(IN)    :: var_name
    CHARACTER(LEN=*),          INTENT(IN)    :: module_name
    INTEGER(i4),               INTENT(IN)    :: lifecycle
    INTEGER(i4),               INTENT(IN)    :: n_bytes
    INTEGER(i4) :: idx
    IF (this%n_entries >= 256) RETURN
    this%n_entries = this%n_entries + 1
    idx = this%n_entries
    this%entries(idx)%var_name     = var_name
    this%entries(idx)%module_name  = module_name
    this%entries(idx)%lifecycle    = lifecycle
    this%entries(idx)%n_bytes      = n_bytes
    this%entries(idx)%is_allocated = .TRUE.
  END SUBROUTINE UFC_Registry_Register

  SUBROUTINE UFC_Registry_Deregister(this, var_name)
    CLASS(UFC_Alloc_Registry), INTENT(INOUT) :: this
    CHARACTER(LEN=*),          INTENT(IN)    :: var_name
    INTEGER :: i
    DO i = 1, this%n_entries
      IF (TRIM(this%entries(i)%var_name) == TRIM(var_name)) THEN
        this%entries(i)%is_allocated = .FALSE.
        RETURN
      END IF
    END DO
  END SUBROUTINE UFC_Registry_Deregister

  FUNCTION UFC_Registry_CountActive(this) RESULT(n)
    CLASS(UFC_Alloc_Registry), INTENT(IN) :: this
    INTEGER(i4) :: n
    INTEGER :: i
    n = 0
    DO i = 1, this%n_entries
      IF (this%entries(i)%is_allocated) n = n + 1
    END DO
  END FUNCTION UFC_Registry_CountActive

END MODULE UFC_Memory_Strategy


!===============================================================================
! MEMORY LIFECYCLE REFERENCE TABLE
!===============================================================================
!
!  TYPE Category       | Lifecycle | ALLOCATE trigger        | DEALLOCATE trigger
! ─────────────────────┼───────────┼─────────────────────────┼────────────────────
!  MD_XXX_Desc         | Level A   | Populate phase (INP)    | Analysis end
!  PH_XXX_State        | Level A   | Populate phase          | Analysis end
!  PH_XXX_Algo         | Level A   | Populate phase (config) | Analysis end
!  RT_Domain_Ctx       | Level A   | Populate phase          | Analysis end
!  RT_Com_Base_Ctx     | Level A   | Populate phase          | Analysis end
!  RT_Global_Ctx       | Level A   | Analysis init           | Analysis end
! ─────────────────────┼───────────┼─────────────────────────┼────────────────────
!  Explicit [nblock,*] | Level B/C | Increment start         | Increment end
!  POINTER props   | Level B   | Step start              | Step end
!  Temp work arrays    | Level D   | (stack only, no ALLOC)  | AUTO on RETURN
! ─────────────────────┼───────────┼─────────────────────────┼────────────────────
!
! POINTER OWNERSHIP RULES:
!   - Vars declared with TARGET :: foo  → OWNER (must DEALLOCATE)
!   - Vars declared with POINTER :: bar → BORROWER (must NULLIFY on teardown)
!   - RT_Domain_Ctx%com_ctx POINTER → borrows from caller's TARGET com_ctx
!   - RT_Com_Base_Ctx%global_ctx POINTER → borrows from singleton TARGET
!   - PH_Mat_Base_State arrays → owned by caller (e.g. RT_StepDriver)
!
! HOT-PATH GUARD (FORBIDDEN inside increment loop):
!   ✗ ALLOCATE(any_array(...))    ← use pre-allocated pool
!   ✗ MD_Mat_GetById(id, desc)    ← use pre-associated pointer
!   ✗ OPEN/CLOSE file units       ← use UEXTERNALDB for file I/O
!   ✓ mat_ctx%com_ctx%global_ctx%time_current  ← O(1) pointer chain
!   ✓ mat_state%stress(1:6)       ← direct field access
!
!===============================================================================
