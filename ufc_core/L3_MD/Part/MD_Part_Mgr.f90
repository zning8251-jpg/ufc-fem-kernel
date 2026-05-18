!===============================================================================
! MODULE:  MD_Part_Mgr
! LAYER:   L3_MD
! DOMAIN:  Part
! ROLE:    _Mgr
! BRIEF:   Part manager — P0 Register/Query via g_ufc_global index API.
!===============================================================================
MODULE MD_Part_Mgr
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,               ONLY: ErrorStatusType, init_error_status, &
                                       IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Part_Def,              ONLY: MD_Part_Desc, MD_Part_Domain, &
                                       MD_Part_Get_Arg, MD_Part_GetByName_Arg, &
                                       UF_PartDef, UF_PartCfg, MAX_PART_NAME
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  ! Re-export for backward compatibility
  PUBLIC :: MD_Part_Desc, MD_Part_Domain
  PUBLIC :: MD_Part_Get_Arg, MD_Part_GetPart_Idx
  PUBLIC :: MD_Part_GetByName_Arg, MD_Part_GetPartByName_Idx
  PUBLIC :: UF_PartDef, UF_PartCfg, MAX_PART_NAME

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_GetPart_Idx
  ! PHASE:      P0
  ! PURPOSE:    Index-based part retrieval via global container
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_GetPart_Idx(part_idx, arg, status)
    INTEGER(i4),           INTENT(IN)    :: part_idx
    TYPE(MD_Part_Get_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ASSOCIATE(dom => g_ufc_global%md_layer%desc%part)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Part domain not initialized"
        RETURN
      END IF
      IF (part_idx < 1_i4 .OR. part_idx > dom%n_parts) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Part index out of range"
        RETURN
      END IF
      arg%desc = dom%desc%parts(part_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Part_GetPart_Idx

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Part_GetPartByName_Idx
  ! PHASE:      P0
  ! PURPOSE:    Name-based part retrieval via global container
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Part_GetPartByName_Idx(name, arg, status)
    CHARACTER(LEN=*),            INTENT(IN)    :: name
    TYPE(MD_Part_GetByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%part_idx = 0_i4
    arg%found    = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%desc%part)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Part domain not initialized"
        RETURN
      END IF
      DO i = 1, dom%n_parts
        IF (TRIM(dom%desc%parts(i)%name) == TRIM(name)) THEN
          arg%found    = .TRUE.
          arg%part_idx = i
          arg%desc     = dom%desc%parts(i)
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    status%message = "Part not found: " // TRIM(name)
  END SUBROUTINE MD_Part_GetPartByName_Idx

END MODULE MD_Part_Mgr
