!===============================================================================
! MODULE: PH_UEL_Brg
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Bridge
! BRIEF:  Bridge routines: L3 MD_Elem_UEL_Desc ↔ L4 PH_UEL_Context.
!   Populate L4 ABI_Flat workspace from L3 cold-path Desc.
!   W2: Does NOT duplicate PH_Elem_* four-kind; only fills ABI_Flat fields.
!===============================================================================
MODULE PH_UEL_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_UEL_Def, ONLY: PH_UEL_Context
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_UEL_Populate_From_L3
  PUBLIC :: PH_UEL_Populate_Ctx_From_L3

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_UEL_Populate_From_L3
  ! PURPOSE:    Populate PH_UEL_Context (ABI_Flat) from L3 MD_Elem_UEL_Desc.
  !             Cold-path data: props, jprops, dimensions.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_UEL_Populate_From_L3(uel_ctx, uel_desc, status)
    TYPE(PH_UEL_Context),    INTENT(INOUT) :: uel_ctx
    TYPE(MD_Elem_UEL_Desc),  INTENT(IN)    :: uel_desc
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Init ABI_Flat workspace with dimensions from L3 Desc
    CALL uel_ctx%Init( &
      ndofel  = uel_desc%ndofel,  &
      nrhs    = 1_i4,             &
      nsvars  = uel_desc%nsvars,  &
      nprops  = uel_desc%nprops,  &
      nnode   = uel_desc%nnode,   &
      njprop  = uel_desc%njprop)

    ! Copy props (SSOT from L3)
    IF (ALLOCATED(uel_desc%props) .AND. ALLOCATED(uel_ctx%props)) THEN
      IF (SIZE(uel_desc%props) <= SIZE(uel_ctx%props)) THEN
        uel_ctx%props(1:SIZE(uel_desc%props)) = uel_desc%props
      END IF
    END IF

    ! Copy jprops
    IF (ALLOCATED(uel_desc%jprops) .AND. ALLOCATED(uel_ctx%jprops)) THEN
      IF (SIZE(uel_desc%jprops) <= SIZE(uel_ctx%jprops)) THEN
        uel_ctx%jprops(1:SIZE(uel_desc%jprops)) = uel_desc%jprops
      END IF
    END IF

    ! Copy scalars
    uel_ctx%jtype = uel_desc%jtype
  END SUBROUTINE PH_UEL_Populate_From_L3

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_UEL_Populate_Ctx_From_L3
  ! PURPOSE:    Lightweight: only update per-increment fields from L3.
  !             Used in step loop when cold-path data is already populated.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_UEL_Populate_Ctx_From_L3(uel_ctx, uel_desc, status)
    TYPE(PH_UEL_Context),    INTENT(INOUT) :: uel_ctx
    TYPE(MD_Elem_UEL_Desc),  INTENT(IN)    :: uel_desc
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Per-increment updates only (if any L3 fields change)
    ! Currently a no-op placeholder for future step-level sync
  END SUBROUTINE PH_UEL_Populate_Ctx_From_L3

END MODULE PH_UEL_Brg
