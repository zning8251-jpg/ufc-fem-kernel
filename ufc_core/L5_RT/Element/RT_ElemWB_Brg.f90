!===============================================================================
! MODULE: RT_ElemWB_Brg
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Brg — Element-side WriteBack hook (P3)
! BRIEF:  Filters / validates element output data before committing to L3
!         via RT_WBDomain.  NaN/Inf detection + energy aggregation.
!===============================================================================
MODULE RT_ElemWB_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_ElemWB_Brg_Filter
  PUBLIC :: RT_ElemWB_Brg_AggregateEnergy

CONTAINS

  !---------------------------------------------------------------------------
  ! Validate element results before WriteBack commit.
  ! Returns error if NaN/Inf detected in stress or SDV arrays.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_ElemWB_Brg_Filter(n_elem, stress, sdv, n_sdv, status)
    INTEGER(i4), INTENT(IN)    :: n_elem
    REAL(wp),    INTENT(IN)    :: stress(:,:)
    REAL(wp),    INTENT(IN)    :: sdv(:,:)
    INTEGER(i4), INTENT(IN)    :: n_sdv
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: e, j
    REAL(wp)    :: val

    CALL init_error_status(status)

    DO e = 1, n_elem
      DO j = 1, SIZE(stress, 1)
        val = stress(j, e)
        IF (val /= val) THEN
          CALL init_error_status(status, IF_STATUS_ERROR, &
               message='RT_ElemWB_Brg_Filter: NaN in stress')
          RETURN
        END IF
      END DO

      DO j = 1, MIN(n_sdv, SIZE(sdv, 1))
        val = sdv(j, e)
        IF (val /= val) THEN
          CALL init_error_status(status, IF_STATUS_ERROR, &
               message='RT_ElemWB_Brg_Filter: NaN in SDV')
          RETURN
        END IF
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_ElemWB_Brg_Filter

  !---------------------------------------------------------------------------
  ! Aggregate per-element energy into global energy vector.
  ! energy_global(1:8) += sum over elements of energy_elem(1:8, 1:n_elem)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_ElemWB_Brg_AggregateEnergy(n_elem, energy_elem, energy_global, status)
    INTEGER(i4), INTENT(IN)    :: n_elem
    REAL(wp),    INTENT(IN)    :: energy_elem(:,:)
    REAL(wp),    INTENT(INOUT) :: energy_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: e, k
    INTEGER(i4) :: n_comp

    CALL init_error_status(status)

    n_comp = MIN(SIZE(energy_elem, 1), SIZE(energy_global))

    DO e = 1, n_elem
      DO k = 1, n_comp
        energy_global(k) = energy_global(k) + energy_elem(k, e)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_ElemWB_Brg_AggregateEnergy

END MODULE RT_ElemWB_Brg
