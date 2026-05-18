!===============================================================================
! MODULE: RT_Cont_Brg
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Brg — cross-layer bridge (FromL3 / ToL4 / WriteBack)
! BRIEF:  Domain pillar P3 bridge: L3→Desc populate, Ctx→L4, diagnostics.
!===============================================================================
MODULE RT_Cont_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, &
                          RT_Contact_Ctx, RT_Contact_Algo
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Contact_Brg_FromL3
  PUBLIC :: RT_Contact_Brg_ToL4
  PUBLIC :: RT_Contact_Brg_WriteBack

CONTAINS

  !---------------------------------------------------------------------------
  ! FromL3: Populate RT_Contact_Desc from L3 Interaction definitions.
  !   Called during L5 initialization after L3 FROZEN.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Contact_Brg_FromL3(n_pairs, n_surfaces, desc, status)
    INTEGER(i4),           INTENT(IN)    :: n_pairs     ! [IN] from L3
    INTEGER(i4),           INTENT(IN)    :: n_surfaces  ! [IN] from L3
    TYPE(RT_Contact_Desc), INTENT(INOUT) :: desc        ! [OUT] populated
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    desc%n_contact_pairs = n_pairs
    desc%is_initialized  = .TRUE.

    WRITE(*,'(A,I6,A,I6)') &
      "[RT_Contact_Brg] FromL3: n_pairs=", n_pairs, &
      " n_surfaces=", n_surfaces

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Brg_FromL3

  !---------------------------------------------------------------------------
  ! ToL4: Transfer runtime context to L4 PH_Contact domain.
  !   Called before each contact evaluation cycle.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Contact_Brg_ToL4(desc, algo, ctx, status)
    TYPE(RT_Contact_Desc), INTENT(IN)    :: desc   ! [IN] configuration
    TYPE(RT_Contact_Algo), INTENT(IN)    :: algo   ! [IN] algorithm params
    TYPE(RT_Contact_Ctx),  INTENT(IN)    :: ctx    ! [IN] current context
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. desc%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Contact_Brg_ToL4: desc not initialized"
      RETURN
    END IF

    ! Not yet integrated with L4_PH PH_Cont types
    ! Transfer runtime context to L4_PH:
    !   PH_Cont_Ctx%penetration <- ctx%temp_disp (from current displacement)
    !   PH_Cont_State%contact_force <- ctx%temp_force (from contact solver)
    !   PH_Cont_Ctx%current_pair_idx <- ctx%current_pair_idx
    !
    ! When L4_PH Contact bridge is available, uncomment:
    !   TYPE(PH_Cont_Ctx) :: l4_ctx
    !   l4_ctx%current_pair_idx = ctx%current_pair_idx
    !   l4_ctx%temperature = algo%temperature_dependence
    !   CALL PH_Cont_Brg_SyncFromRT(l4_ctx, status)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Brg_ToL4

  !---------------------------------------------------------------------------
  ! WriteBack: Post-convergence diagnostics collection.
  !   Called after solver convergence to log contact state summary.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Contact_Brg_WriteBack(state, status)
    TYPE(RT_Contact_State), INTENT(IN)  :: state  ! [IN] converged state
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    WRITE(*,'(A,I6,A,L1,A,ES12.4)') &
      "[RT_Contact_Brg] WriteBack: n_active=", state%n_active_pairs, &
      " converged=", state%converged, &
      " max_penetration=", state%max_penetration

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Brg_WriteBack

END MODULE RT_Cont_Brg
