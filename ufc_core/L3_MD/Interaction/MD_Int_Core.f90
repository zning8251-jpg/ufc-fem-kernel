!======================================================================
! MODULE:  MD_Int_Core
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Core
! BRIEF:   Core initialization, finalization, and CRUD operations
!          for contact surfaces and pairs. P0 phase routines.
!          Four-type signature: (desc, state, status).
! STATUS:  FOUR-TYPE-REFACTORED
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Int_Def,   ONLY: MD_Int_Desc, MD_Int_State,           &
                           MD_Int_SurfEntry_Desc,               &
                           MD_Int_PairEntry_Desc,               &
                           MD_INT_MAX_SURFACES,                 &
                           MD_INT_MAX_PAIR_ENTRIES
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Int_CoreInit
  PUBLIC :: MD_Int_CoreFinalize
  PUBLIC :: MD_Int_AddSurface
  PUBLIC :: MD_Int_AddPairEntry
  PUBLIC :: MD_Int_SetFriction
  PUBLIC :: MD_Int_GetPairEntry
  PUBLIC :: MD_Int_GetNPairs
  PUBLIC :: MD_Int_Validate

CONTAINS

  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CoreInit
  ! PHASE:      P0
  ! PURPOSE:    Initialize interaction descriptor and state
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CoreInit(desc, state, status)
    TYPE(MD_Int_Desc),     INTENT(INOUT) :: desc                  ! [inout] Descriptor
    TYPE(MD_Int_State),    INTENT(OUT)   :: state                 ! [out]   State
    TYPE(ErrorStatusType), INTENT(OUT)   :: status                ! [out]   Error status

    CALL init_error_status(status)
    desc%cfg_api%n_surfaces            = 0_i4
    desc%cfg_api%n_pairs               = 0_i4
    state%is_active            = .TRUE.
    state%contact_status       = 0_i4
    state%itr_whitelist%contact_pressure     = 0.0_wp
    state%contact_area         = 0.0_wp
    state%itr_whitelist%slip_distance        = 0.0_wp
    state%itr_whitelist%total_contact_points = 0_i4
    status%status_code         = IF_STATUS_OK
  END SUBROUTINE MD_Int_CoreInit


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CoreFinalize
  ! PHASE:      P0
  ! PURPOSE:    Finalize interaction descriptor and deactivate state
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CoreFinalize(desc, state, status)
    TYPE(MD_Int_Desc),     INTENT(INOUT) :: desc                  ! [inout] Descriptor
    TYPE(MD_Int_State),    INTENT(INOUT) :: state                 ! [inout] State
    TYPE(ErrorStatusType), INTENT(OUT)   :: status                ! [out]   Error status

    CALL init_error_status(status)
    desc%cfg_api%n_surfaces    = 0_i4
    desc%cfg_api%n_pairs       = 0_i4
    state%is_active    = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Int_CoreFinalize


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_AddSurface
  ! PHASE:      P0
  ! PURPOSE:    Register a new surface entry in the descriptor
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_AddSurface(desc, id, name, surface_type, status)
    TYPE(MD_Int_Desc),     INTENT(INOUT) :: desc                  ! [inout] Descriptor
    INTEGER(i4),           INTENT(IN)    :: id                    ! [in]    Surface ID
    CHARACTER(LEN=*),      INTENT(IN)    :: name                  ! [in]    Surface name
    INTEGER(i4),           INTENT(IN)    :: surface_type          ! [in]    Surface type
    TYPE(ErrorStatusType), INTENT(OUT)   :: status                ! [out]   Error status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    IF (desc%cfg_api%n_surfaces >= MD_INT_MAX_SURFACES) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_Int_AddSurface]: max surfaces exceeded"
      RETURN
    END IF

    desc%cfg_api%n_surfaces = desc%cfg_api%n_surfaces + 1_i4
    idx = desc%cfg_api%n_surfaces

    desc%cfg_api%surfaces(idx)%id           = id
    desc%cfg_api%surfaces(idx)%name         = name
    desc%cfg_api%surfaces(idx)%surface_type = surface_type
    desc%cfg_api%surfaces(idx)%valid        = .TRUE.
    status%status_code              = IF_STATUS_OK
  END SUBROUTINE MD_Int_AddSurface


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_AddPairEntry
  ! PHASE:      P0
  ! PURPOSE:    Register a new pair entry in the descriptor
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_AddPairEntry(desc, pair_id, master_id, slave_id, status)
    TYPE(MD_Int_Desc),     INTENT(INOUT) :: desc                  ! [inout] Descriptor
    INTEGER(i4),           INTENT(IN)    :: pair_id               ! [in]    Pair ID
    INTEGER(i4),           INTENT(IN)    :: master_id             ! [in]    Master surface ID
    INTEGER(i4),           INTENT(IN)    :: slave_id              ! [in]    Slave surface ID
    TYPE(ErrorStatusType), INTENT(OUT)   :: status                ! [out]   Error status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    IF (desc%cfg_api%n_pairs >= MD_INT_MAX_PAIR_ENTRIES) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_Int_AddPairEntry]: max pairs exceeded"
      RETURN
    END IF

    desc%cfg_api%n_pairs = desc%cfg_api%n_pairs + 1_i4
    idx = desc%cfg_api%n_pairs

    desc%cfg_api%pairs(idx)%pair_id   = pair_id
    desc%cfg_api%pairs(idx)%master_id = master_id
    desc%cfg_api%pairs(idx)%slave_id  = slave_id
    desc%cfg_api%pairs(idx)%valid     = .TRUE.
    status%status_code        = IF_STATUS_OK
  END SUBROUTINE MD_Int_AddPairEntry


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_SetFriction
  ! PHASE:      P0
  ! PURPOSE:    Set friction coefficient for a pair by ID
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_SetFriction(desc, pair_id, mu, status)
    TYPE(MD_Int_Desc),     INTENT(INOUT) :: desc                  ! [inout] Descriptor
    INTEGER(i4),           INTENT(IN)    :: pair_id               ! [in]    Pair ID
    REAL(wp),              INTENT(IN)    :: mu                    ! [in]    Friction coeff
    TYPE(ErrorStatusType), INTENT(OUT)   :: status                ! [out]   Error status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, desc%cfg_api%n_pairs
      IF (desc%cfg_api%pairs(i)%pair_id == pair_id .AND. desc%cfg_api%pairs(i)%valid) THEN
        desc%cfg_api%pairs(i)%mu_friction = mu
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "[MD_Int_SetFriction]: pair not found"
  END SUBROUTINE MD_Int_SetFriction


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_GetPairEntry
  ! PHASE:      P0
  ! PURPOSE:    Retrieve a pair entry by index
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_GetPairEntry(desc, idx, pair, status)
    TYPE(MD_Int_Desc),          INTENT(IN)  :: desc               ! [in]  Descriptor
    INTEGER(i4),                INTENT(IN)  :: idx                ! [in]  Pair index
    TYPE(MD_Int_PairEntry_Desc), INTENT(OUT) :: pair              ! [out] Pair entry
    TYPE(ErrorStatusType),      INTENT(OUT) :: status             ! [out] Error status

    CALL init_error_status(status)
    IF (idx < 1_i4 .OR. idx > desc%cfg_api%n_pairs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_Int_GetPairEntry]: index out of range"
      RETURN
    END IF
    pair = desc%cfg_api%pairs(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Int_GetPairEntry


  !--------------------------------------------------------------------
  ! FUNCTION: MD_Int_GetNPairs
  ! PHASE:    P0
  ! PURPOSE:  Return number of registered pairs
  !--------------------------------------------------------------------
  FUNCTION MD_Int_GetNPairs(desc) RESULT(n)
    TYPE(MD_Int_Desc), INTENT(IN) :: desc                         ! [in] Descriptor
    INTEGER(i4) :: n
    n = desc%cfg_api%n_pairs
  END FUNCTION MD_Int_GetNPairs


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate all pairs reference valid surfaces
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_Validate(desc, status)
    TYPE(MD_Int_Desc),     INTENT(IN)  :: desc                    ! [in]  Descriptor
    TYPE(ErrorStatusType), INTENT(OUT) :: status                  ! [out] Error status

    INTEGER(i4) :: i, j
    LOGICAL     :: master_ok, slave_ok

    CALL init_error_status(status)
    DO i = 1, desc%cfg_api%n_pairs
      IF (.NOT. desc%cfg_api%pairs(i)%valid) CYCLE
      master_ok = .FALSE.
      slave_ok  = .FALSE.
      DO j = 1, desc%cfg_api%n_surfaces
        IF (desc%cfg_api%surfaces(j)%valid) THEN
          IF (desc%cfg_api%surfaces(j)%id == desc%cfg_api%pairs(i)%master_id) master_ok = .TRUE.
          IF (desc%cfg_api%surfaces(j)%id == desc%cfg_api%pairs(i)%slave_id)  slave_ok  = .TRUE.
        END IF
      END DO
      IF (.NOT. master_ok .OR. .NOT. slave_ok) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_Int_Validate]: pair has invalid surface ref"
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Int_Validate

END MODULE MD_Int_Core
