!===============================================================================
! Module:  RT_Out_Brg
! Layer:   L5_RT - Runtime Layer
! Domain:  Output
! Purpose: Bridge module for the Output domain.
!          Cross-layer type adaptation and data transfer.
!          Provides L3->L5 configuration pull, L5->L4 physics dispatch,
!          and L5->persist result collection interfaces.
!
! Status: ACTIVE | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   AUTHORITY: RT_Out_Def.f90
!   L3 source: MD_Output_Core / MD_Out_Brg (output request schema)
!   L4 source: PH_Out / PH_Out_Brg (physics transforms)
!===============================================================================
MODULE RT_Out_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Out_Def, ONLY: RT_Out_Desc, RT_Out_Ctx, RT_OUT_FMT_VTK
  ! DEPRECATED: RT_Out_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Output_Brg_FromL3
  PUBLIC :: RT_Output_Brg_ToL4
  PUBLIC :: RT_Output_Brg_CollectResults

CONTAINS

  !---------------------------------------------------------------------------
  ! RT_Output_Brg_FromL3: Pull output request configuration from L3_MD
  !   Populates RT_Out_Desc from L3 output request schema.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Output_Brg_FromL3(n_field_reqs, n_hist_reqs, desc, status)
    INTEGER(i4),            INTENT(IN)    :: n_field_reqs
    INTEGER(i4),            INTENT(IN)    :: n_hist_reqs
    TYPE(RT_Out_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_field_reqs < 0 .OR. n_hist_reqs < 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%runtime_id = 1_i4
    desc%output_format = RT_OUT_FMT_VTK
    desc%is_active = (n_field_reqs > 0 .OR. n_hist_reqs > 0)
    desc%is_initialized = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Brg_FromL3

  !---------------------------------------------------------------------------
  ! RT_Output_Brg_ToL4: Push transform parameters to L4 physics layer
  !   Prepares context for L4 PH_Out coordinate/tensor transforms.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Output_Brg_ToL4(ctx, n_nodes, n_elements, status)
    TYPE(RT_Out_Ctx),      INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_nodes
    INTEGER(i4),           INTENT(IN)    :: n_elements
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_nodes <= 0 .OR. n_elements <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ctx%pop%n_nodes = n_nodes
    ctx%pop%n_elements = n_elements

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Brg_ToL4

  !---------------------------------------------------------------------------
  ! RT_Output_Brg_CollectResults: Collect computation results for output
  !   Gathers field/history data from solver state into output context.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Output_Brg_CollectResults(step_id, incr_id, time, ctx, status)
    INTEGER(i4),           INTENT(IN)    :: step_id
    INTEGER(i4),           INTENT(IN)    :: incr_id
    REAL(wp),              INTENT(IN)    :: time
    TYPE(RT_Out_Ctx),      INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    ctx%step_id = step_id
    ctx%incr_id = incr_id
    ctx%total_time = time
    ctx%is_step_end = .FALSE.
    ctx%is_analysis_end = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Brg_CollectResults

END MODULE RT_Out_Brg
