!===============================================================================
! MODULE: RT_MF_Brg
! LAYER:  L5_RT
! DOMAIN: Coupling
! ROLE:   Brg
! BRIEF:  Bridge L3 MD_Cpl_Desc -> L5 RT_MF_Coupling_Desc (Populate channel)
!===============================================================================
!
! Process族:
!   P1: Populate (transfer L3 coupling config to L5 runtime types) [COLD_PATH]
!   P1: Sync (state update at step transitions)                     [HOT_PATH]
!
! Status: ACTIVE | PLACEHOLDER | Last verified: 2026-04-28
!===============================================================================

MODULE RT_MF_Brg
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_MF_Def,       ONLY: RT_MF_Coupling_Desc, RT_MF_Coupling_Algo, &
                             RT_MF_FieldPair_Desc, RT_MF_MAX_FIELDS
  USE MD_Cpl_Def, ONLY: MD_Cpl_Desc, MD_Coup_PairDef, &
                             MD_COUP_MAX_PAIRS
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_MF_Brg_Populate
  PUBLIC :: RT_MF_Brg_SyncState

CONTAINS

  !---------------------------------------------------------------------------
  ! RT_MF_Brg_Populate — transfer L3 coupling config to L5 runtime types
  !   Called once before first coupled step (Setup phase).
  !---------------------------------------------------------------------------
  SUBROUTINE RT_MF_Brg_Populate(md_desc, rt_desc, rt_algo, status)
    TYPE(MD_Cpl_Desc),    INTENT(IN)    :: md_desc
    TYPE(RT_MF_Coupling_Desc), INTENT(INOUT) :: rt_desc
    TYPE(RT_MF_Coupling_Algo), INTENT(INOUT) :: rt_algo
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    INTEGER(i4) :: ip

    CALL init_error_status(status)

    IF (.NOT. md_desc%ctl%is_configured) THEN
      status%status_code = IF_STATUS_ERROR
      status%message     = 'MD_Cpl_Desc not configured (Validate not called)'
      RETURN
    END IF

    rt_desc%global_strategy = md_desc%ctl%strategy
    rt_desc%n_pairs         = md_desc%n_pairs

    IF (ALLOCATED(rt_desc%pairs)) DEALLOCATE(rt_desc%pairs)
    ALLOCATE(rt_desc%pairs(md_desc%n_pairs))

    DO ip = 1, md_desc%n_pairs
      rt_desc%pairs(ip)%src_field_id      = md_desc%pairs(ip)%src_field_id
      rt_desc%pairs(ip)%dst_field_id      = md_desc%pairs(ip)%dst_field_id
      rt_desc%pairs(ip)%qty_type          = md_desc%pairs(ip)%qty_type
      rt_desc%pairs(ip)%interface_surf_id = md_desc%pairs(ip)%interface_surf_id
      rt_desc%pairs(ip)%scale_factor      = md_desc%pairs(ip)%scale_factor
      rt_desc%pairs(ip)%active            = md_desc%pairs(ip)%is_active
      rt_desc%pairs(ip)%label             = md_desc%pairs(ip)%label(1:32)
    END DO

    rt_algo%max_coup_iter = md_desc%ctl%max_coupling_iter
    rt_algo%eps_coup_rel  = md_desc%ctl%coupling_tol
    rt_algo%interp_method = md_desc%ctl%interp_method

    rt_desc%is_valid = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_MF_Brg_Populate

  !---------------------------------------------------------------------------
  ! RT_MF_Brg_SyncState — sync coupling state at step boundaries
  !   Called by StepDriver when transitioning between steps.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_MF_Brg_SyncState(md_desc, step_id, is_coupled_step, status)
    TYPE(MD_Cpl_Desc), INTENT(IN)  :: md_desc
    INTEGER(i4),            INTENT(IN)  :: step_id
    LOGICAL,                INTENT(OUT) :: is_coupled_step
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    is_coupled_step = (md_desc%ctl%is_configured .AND. md_desc%n_pairs > 0_i4)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_MF_Brg_SyncState

END MODULE RT_MF_Brg
